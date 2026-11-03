---@class BuffItemClass
---@field new fun(opts: table?, parent: table?): BuffItemInstance

---@class Glu
---@field buff_item BuffItemClass

---@class BuffItemInstance
---@field label table? The Geyser.Label this item displays in; nil once deleted.
---@field deleting boolean? True once delete() has been called.
---@field stylesheet string The stylesheet last set with setStyleSheet(); "" if none.
---@field text string? The text last set with set(); nil if none.
---@field setStyleSheet fun(self: BuffItemInstance, stylesheet: string) Sets the label's stylesheet.
---@field set fun(self: BuffItemInstance, text: string) Sets the item's text.
---@field delete fun(self: BuffItemInstance, cb: function?) Fades the item out, then deletes its label.

--- Glass definition for a single buff/debuff/affliction widget. Registered
--- with Glu as `buff_item`; calling the glass (`glu.buff_item(opts, parent)`)
--- creates a new item.
BuffItem = {
  name = "buff_item",
  class_name = "BuffItemClass",
  call = "new",
  setup = function(___, self)
    --- Fades a label's text to transparent, then calls the callback. The
    --- label's current `fgColor` is the starting colour. Each step sets the
    --- stylesheet to `base` followed by the faded text colour, so the rest of
    --- `base`, background included, stays as it is.
    ---
    ---@param widget table The Geyser.Label to fade.
    ---@param base string The stylesheet to keep while fading.
    ---@param cb function Called with no arguments once the fade completes.
    local function fade(widget, base, cb)
      if base ~= "" and not base:match(";%s*$") then
        base = base .. ";"
      end

      local curr_fg = { Geyser.Color.parse(widget.fgColor) }

      local function with_alpha(alpha)
        curr_fg[4] = alpha

        return base .. "color: rgba(" .. table.concat(curr_fg, ",") .. ");"
      end

      -- The stylesheet takes over the colour before the text stops carrying
      -- its own, so the text never shows in the label's default colour.
      widget:setStyleSheet(with_alpha(255))
      -- Spans carry their own colour, which the fading stylesheet can't reach.
      local plain = widget.message:gsub("</?span[^>]*>", "")
      widget:echo(plain, "nocolor", nil)

      local steps = 20
      local duration = 0.3
      local delay_per_step = duration / steps
      local step = 0
      local timer_id

      -- A plain temp timer: a named one would leave Mudlet holding an ID
      -- manager for every fade's throwaway user name.
      timer_id = tempTimer(
        delay_per_step,
        function()
          step = step + 1

          local t = step / steps
          local alpha = ___.number.round(___.number.lerp(255, 0, t), 0)

          widget:setStyleSheet(with_alpha(alpha))

          if step >= steps then
            killTimer(timer_id)
            cb()
          end
        end,
        true
      )
    end

    --- Creates a new buff item backed by a Geyser.Label. Unless `opts` says
    --- otherwise, the label is a fixed 1.5 characters tall, so a VBox stacks
    --- items from the top instead of stretching them to fill it.
    ---
    ---@param opts table? Constraints passed straight to `Geyser.Label:new`, such as `name`, `height`, `fgColor`, `font` and `fontSize`.
    ---@param parent table? The Geyser container to put the label in.
    ---@return BuffItemInstance item The new buff item.
    function self.new(opts, parent)
      local instance = {}
      opts = opts or {}
      opts.height = opts.height or "1c"
      opts.v_policy = opts.v_policy or Geyser.Fixed

      instance.label = Geyser.Label:new(opts, parent)
      instance.stylesheet = ""

      --- Sets the label's stylesheet. The fade on delete keeps it, overriding
      --- only the colours.
      ---
      ---@param stylesheet string The Qt stylesheet to apply.
      function instance:setStyleSheet(stylesheet)
        if self.deleting then return end

        self.stylesheet = stylesheet
        self.label:setStyleSheet(stylesheet)
      end

      --- Sets the item's text. Does nothing once the item is being deleted, or
      --- when the text is what it already shows.
      ---
      ---@param text string The text to display.
      function instance:set(text)
        if self.deleting or text == self.text then return end

        self.text = text
        self.label:echo(text)
      end

      --- Fades the item out, then deletes its label. Calling it again while
      --- the fade runs does nothing.
      ---
      ---@param cb function? Called with no arguments once the label is deleted.
      function instance:delete(cb)
        if self.deleting then return end
        self.deleting = true

        fade(self.label, self.stylesheet, function()
          -- deleteLabel only schedules the widget's removal, which a scroll
          -- box doesn't notice; hiding it first makes the scroll box re-fit.
          instance.label:hide()
          instance.label:delete()
          instance.label = nil

          if cb then cb() end
        end)
      end

      return instance
    end
  end
}
