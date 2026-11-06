-- /tbuff <command> [<args>], dispatched from the single /tbuff alias

--- The colour commands, one per thing that can be coloured.
local ColorTargets = {
  buff = "buff names",
  debuff = "debuff names",
  affliction = "affliction names",
  time = "times",
}

--- The Mudlet colour name `name` stands for, matched as typed first and then
--- in lowercase, or nil when there's no such colour.
---
---@param name string The colour as typed.
---@return string? color The name as Mudlet knows it.
local function colorName(name)
  if color_table[name] then return name end

  local lower = string.lower(name)
  if color_table[lower] then return lower end
end

--- Shows, sets, or resets the colour for `kind`.
---
---@param kind string buff, debuff, affliction, or time.
---@param arg string? A Mudlet colour name, "default", or nil to show it.
function __PKGNAME__:SetColor(kind, arg)
  local colors = self.Prefs.Colors
  local default = self.PrefsDefaults.Colors[kind]
  local what = ColorTargets[kind]

  if arg == nil then
    cecho(string.format("Colour for %s is <%s>%s<r> (default <%s>%s<r>).\n",
      what, colors[kind], colors[kind], default, default))
    return
  end

  local color

  if string.lower(arg) == "default" then
    color = default
  else
    color = colorName(arg)

    if color == nil then
      cecho("<tomato>[__PKGNAME__]<r> No Mudlet colour named '" .. arg ..
        "'. See /tbuff palette for the names.\n")
      return
    end
  end

  colors[kind] = color
  self:SavePrefs()
  self:RecolorItems(kind)

  cecho(string.format("Colour for %s set to <%s>%s<r>.\n", what, color, color))
end

local function colorCommand(kind)
  return {
    help = "<h2>/tbuff " .. kind .. "</h2> [<colour>|default] - Set the colour for " ..
        ColorTargets[kind] .. ". Shows the current colour with no argument.",
    run = function(self, arg) self:SetColor(kind, arg) end,
  }
end

__PKGNAME__.Commands = {
  buff = colorCommand("buff"),
  debuff = colorCommand("debuff"),
  affliction = colorCommand("affliction"),
  time = colorCommand("time"),
  palette = {
    help = "<h2>/tbuff palette</h2> - Show the Mudlet colour names.",
    run = function() showColors(3) end,
  },
  reset = {
    help = "<h2>/tbuff reset</h2> - Put the window back on the left at its default size.",
    run = function(self) self:ResetLayout() end,
  },
}

__PKGNAME__.CommandOrder = { "buff", "debuff", "affliction", "time", "palette", "reset" }

__PKGNAME__.HelpStyles = {
  h1 = "royal_blue",
  h2 = "sky_blue",
}

--- Prints the /tbuff help, through Helper when it's installed and as plain
--- text when it isn't (yet).
function __PKGNAME__:ShowHelp()
  local lines = {
    "<h1>__PKGNAME__ __VERSION__</h1>",
    "",
    "  <h2>/tbuff</h2> - See this help.",
  }

  for _, key in ipairs(self.CommandOrder) do
    table.insert(lines, "  " .. self.Commands[key].help)
  end

  local text = table.concat(lines, "\n") .. "\n"

  echo("\n")
  ---@diagnostic disable-next-line: undefined-global
  if helper and helper.print then
    ---@diagnostic disable-next-line: undefined-global
    helper.print({ text = text, styles = self.HelpStyles })
  else
    echo((string.gsub(text, "</?%w+>", "")))
  end
end

function __PKGNAME__:Command(input)
  local name, arg = string.match(input or "", "^%s*(%S*)%s*(%S*)")
  local command = self.Commands[string.lower(name or "")]

  if command == nil then
    self:ShowHelp()
    return
  end

  -- Not lowercased: colour names are matched as typed first
  if arg == "" then arg = nil end

  command.run(self, arg)
end
