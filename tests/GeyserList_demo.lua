-- A window for trying Geyser.List and Geyser.ListItem by hand. It needs the classes
-- loaded, which having this package installed sees to. In Mudlet:
--
--   lua dofile("/projects/git/ThreshBuff/tests/GeyserList_demo.lua")
--
-- Running it again replaces the window, and GeyserListDemo.close() closes it.

if GeyserListDemo then GeyserListDemo.close() end

GeyserListDemoRun = (GeyserListDemoRun or 0) + 1
local prefix = "GLDemo" .. GeyserListDemoRun .. "."

local PANEL = "background-color: #222;"
local TITLE = "background-color: #222; color: #ccc; font-weight: bold; padding-left: 4px;"
local STATUS = "background-color: #222; color: #9c9; padding-left: 4px;"
local BUTTON = [[
  QLabel { background-color: #444; color: white; border: 1px solid #666; }
  QLabel::hover { background-color: #666; }
]]
local ZEBRA = { "background-color: #2b2b2b; color: white;", "background-color: #3a3a3a; color: white;" }
local SELECTED = "background-color: #2d6cdf; color: white;"
local PLAIN = "background-color: #2b2b2b; color: white;"

local window = Geyser.UserWindow:new({
  name = prefix .. "Window",
  titleText = "Geyser.List demo",
  docked = false,
  x = 100,
  y = 100,
  width = 900,
  height = 500,
})

local columns = Geyser.HBox:new({
  name = prefix .. "Columns",
  x = 0,
  y = 0,
  width = "100%",
  height = "100%",
}, window)

local serial = 0

local function nextName()
  serial = serial + 1
  return string.format("%sRow%03d", prefix, serial)
end

--- A fade of the text, for rows that have an onDismiss.
local function fadeOut(item, done)
  local steps, step, timer = 10, 0, nil
  local base = item.ownStyleSheet or ""

  timer = tempTimer(0.03, function()
    if item.deleted then
      killTimer(timer)
      return
    end

    step = step + 1
    item:setStyleSheet(base .. "color: rgba(255,255,255," .. math.floor(255 * (1 - step / steps)) .. ");")

    if step >= steps then
      killTimer(timer)
      done()
    end
  end, true)
end

--- A column: a title, a list, what is selected in it, and buttons.
local function panel(key, title, listCons, makeRow)
  local box = Geyser.VBox:new({ name = prefix .. key }, columns)

  local fixed = function(name, height, css, message)
    local label = Geyser.Label:new({
      name = prefix .. key .. name,
      height = height,
      v_policy = Geyser.Fixed,
      message = message,
      stylesheet = css,
      fgColor = "white",
    }, box)
    return label
  end

  fixed("Title", 24, TITLE, title)

  local status

  local function showSelected(list)
    local names = {}

    for _, item in ipairs(list:getSelected()) do
      names[#names + 1] = "#" .. list:indexOf(item)
    end

    status:echo(#list:getItems() .. " rows, selected: " .. (#names > 0 and table.concat(names, " ") or "none"))
  end

  listCons.name = prefix .. key .. "List"
  listCons.onSelectionChange = function(list, item, selected)
    item:setStyleSheet(selected and SELECTED or (item.restStyle or ""))
    showSelected(list)
  end

  local list = Geyser.List:new(listCons, box)

  status = fixed("Status", 24, STATUS, "")

  local function add(count)
    list:begin_update()

    for _ = 1, count do
      makeRow(list, nextName())
    end

    list:end_update()
    showSelected(list)
  end

  local buttons = {
    { "+1",  function() add(1) end },
    { "+20", function() add(20) end },
    { "Top", function()
      local first = list:getSelected()[1]
      if first then
        list:moveItem(first, 1)
      end
    end },
    { "Fade", function()
      for _, item in ipairs(list:getSelected()) do
        if item.dismiss then item:dismiss() end
      end
    end },
    { "Del", function()
      for _, item in ipairs(list:getSelected()) do
        item:delete()
      end
      showSelected(list)
    end },
    { "Clear", function()
      list:clear()
      showSelected(list)
    end },
    { "Stripes", function()
      list:setStripes(not list.stripes and ZEBRA or nil)
    end },
    { "Sort", function()
      list:setSortBy(not list.sortBy and function(a, b) return a.name > b.name end or nil)
      status:echo("sortBy " .. (list.sortBy and "on (newest first)" or "off"))
    end },
  }

  local row = Geyser.HBox:new({
    name = prefix .. key .. "Buttons",
    height = 28,
    v_policy = Geyser.Fixed,
  }, box)

  for _, button in ipairs(buttons) do
    Geyser.Label:new({
      name = prefix .. key .. "Button" .. button[1],
      message = "<center>" .. button[1] .. "</center>",
      stylesheet = BUTTON,
      fgColor = "white",
      fontSize = 9,
      clickCallback = button[2],
    }, row)
  end

  add(6)

  return list
end

--- A row that is just a label.
local function plainRow(rest)
  return function(list, name)
    return list:addItem({
      name = name,
      message = "Row " .. name:match("%d+$"),
      fgColor = "white",
      fontSize = 11,
      height = 22,
      stylesheet = rest,
      restStyle = rest,
      onDismiss = fadeOut,
    })
  end
end

--- A row covered by two child labels, which have to be clickthrough for the click to
--- reach the row. This is the shape ThreshBuff's rows have.
local function coveredRow(list, name)
  local item = list:addItem({
    name = name,
    fontSize = 11,
    height = 22,
    onDismiss = function(row, done) tempTimer(0.3, done) end,
  })

  local hbox = Geyser.HBox:new({ name = name .. ".Row", x = 0, y = 0, width = "100%", height = "100%" }, item)

  for _, part in ipairs({ { ".Name", "Covered " .. name:match("%d+$"), "chartreuse" }, { ".Time", "12m 34s", "white" } }) do
    Geyser.Label:new({
      name = name .. part[1],
      message = part[2],
      fgColor = part[3],
      fontSize = 11,
      stylesheet = "background-color: transparent; padding-left: 4px;",
      clickthrough = true,
    }, hbox)
  end

  return item
end

GeyserListDemo = {
  window = window,
  single = panel("Single", "single, zebra", { selectionMode = "single", stripes = ZEBRA }, plainRow(nil)),
  multi = panel("Multi", "multi, plain", { selectionMode = "multi" }, plainRow(PLAIN)),
  covered = panel("Covered", "multi, child labels, zebra", { selectionMode = "multi", stripes = ZEBRA }, coveredRow),
}

function GeyserListDemo.close()
  GeyserListDemo.window:delete()
  GeyserListDemo = nil
end

cecho("\n<chartreuse>Geyser.List demo open. GeyserListDemo.close() closes it.\n")
