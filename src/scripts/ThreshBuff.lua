-- Uninstall empties this table rather than dropping it, and the auto-updater
-- installs the new version in the same session, so a table left without an ID
-- manager gets its defaults back just as a missing one would. This keys off
-- the ID manager because 1.x never had one: its one-shot uninstall handler
-- could be used up by another package's uninstall, which left its whole table
-- behind, AppName and old-format entries included, for this version to find.
__PKGNAME__ = __PKGNAME__ or {}

if __PKGNAME__.idm == nil then
  -- What such a 1.x left behind is still going: its window on screen, its update
  -- timer, and its GMCP handlers, which would handle every event a second time.
  -- Its widgets are deleted, not just hidden, so that their names are free for
  -- this version's. 1.x added parents first, so going backwards takes children
  -- before the containers they're in.
  local legacy = __PKGNAME__.Widgets or {}
  for i = #legacy, 1, -1 do
    legacy[i]:delete()
  end
  deleteAllNamedTimers("__PKGNAME__")
  deleteAllNamedEventHandlers("__PKGNAME__")

  for key, value in pairs({
    AppName = "__PKGNAME__",
    Buffs = {},
    Debuffs = {},
    Afflictions = {},
    EventHandlers = {
      { "gmcp.Char.Afflictions.Add",    "__PKGNAME__:Add" },
      { "gmcp.Char.Afflictions.Remove", "__PKGNAME__:Remove" },
      { "gmcp.Char.Afflictions.List",   "__PKGNAME__:List" },
      { "gmcp.Char.Buffs.Add",          "__PKGNAME__:Add" },
      { "gmcp.Char.Buffs.Remove",       "__PKGNAME__:Remove" },
      { "gmcp.Char.Buffs.List",         "__PKGNAME__:List" },
      { "gmcp.Char.Debuffs.Add",        "__PKGNAME__:Add" },
      { "gmcp.Char.Debuffs.Remove",     "__PKGNAME__:Remove" },
      { "gmcp.Char.Debuffs.List",       "__PKGNAME__:List" },
    },
    Colors = {
      buff = "chartreuse",
      debuff = "tomato",
      affliction = "orchid"
    },
    Widgets = {},
    Items = {},
    ItemSerial = 0,
    UpdaterRunning = false,
    idm = getNewIDManager()
  }) do
    __PKGNAME__[key] = value
  end
end

---@return Glu
function __PKGNAME__:SetupGlu()
  local instance = self.glu or require("__PKGNAME__/vendor/Glu-single")("__PKGNAME__")

  self.glu = instance

  return instance
end

---@type Glu
local glu = __PKGNAME__:SetupGlu()

local PanelStyle = [[
    background-color: "#333";
  ]]

-- Transparent so the panel shows through, leaving the fade only the text.
local RowStyle = [[
    background-color: transparent;
  ]]

local NameStyle = [[
    background-color: transparent;
    padding-left: 4px;
  ]]

local TimeStyle = [[
    background-color: transparent;
    padding-left: 4px;
  ]]

local ItemFont = "Ubuntu"
local ItemFontSize = 11

-- The GMCP packages, by the name their events carry, with where each one's
-- entries are stored and what their ids are called.
local PackageInfo = {
  Buffs = { class = "Buffs", label = "buff_id", buff_type = "buff" },
  Debuffs = { class = "Debuffs", label = "debuff_id", buff_type = "debuff" },
  Afflictions = { class = "Afflictions", buff_type = "affliction" },
}

local Classes = { "Buffs", "Debuffs", "Afflictions" }

--- The file whose existence says a build has happened, so that the saved layout
--- knows the window.
local function layoutMarker()
  return getMudletHomeDir() .. "/__PKGNAME__.layout"
end

function __PKGNAME__:AddWidget(widget)
  if not table.index_of(self.Widgets, widget) then
    table.insert(self.Widgets, widget)
  end
end

function __PKGNAME__:RegisterEventHandlers()
  for _, v in ipairs(self.EventHandlers) do
    self.idm:registerEvent(v[1], v[1], v[2], false)
  end
end

function __PKGNAME__:DeregisterEventHandlers()
  for _, v in ipairs(self.EventHandlers) do
    self.idm:deleteEvent(v[1])
  end
end

--- Builds the UI. The window goes where it was last saved, once there has been
--- a build for there to be a saved layout from. Restoring a layout that doesn't
--- know the window would leave it where Mudlet puts new windows, on the right,
--- and would move every other window back to the last save for nothing, so the
--- first build, and a reset, dock it on the left instead.
---
---@param useDefaults boolean? Ignore the saved layout.
function __PKGNAME__:BuildUI(useDefaults)
  local marker = layoutMarker()
  local restore = not useDefaults and (self.LayoutSaved or io.exists(marker))

  self.MainWindow = self.MainWindow or Geyser.UserWindow:new({
    name = "__PKGNAME__.MainWindow",
    docked = true,
    dockPosition = "left",
    restoreLayout = restore,
    titleText = "__PKGNAME__ - " .. getProfileName(),
  })
  self:AddWidget(self.MainWindow)

  self.LayoutSaved = nil

  if not io.exists(marker) then
    local file = io.open(marker, "w")
    if file then file:close() end
  end

  self.Container = self.Container or Geyser.Container:new({
    name = "__PKGNAME__.Container",
    x = 0,
    y = 0,
    width = "100%",
    height = "100%",
  }, self.MainWindow)
  self:AddWidget(self.Container)

  -- Not named BorderLabel: 1.x only ever hid its widgets, so during an in-session
  -- upgrade a label of that name is still sitting in the main window, and Mudlet
  -- would hand this one that widget instead of making a new one in the dock.
  self.BorderLabel = self.BorderLabel or Geyser.Label:new({
    name = "__PKGNAME__.PanelLabel",
    x = 1,
    y = 1,
    width = -1,
    height = -1
  }, self.Container)

  self.BorderLabel:setStyleSheet(PanelStyle)
  self.BorderLabel:enableClickthrough()
  self:AddWidget(self.BorderLabel)

  self.ItemList = self.ItemList or Geyser.List:new({
    name = "__PKGNAME__.ItemList",
    x = 1,
    y = 1,
    width = -1,
    height = -1,
    sortBy = self.CompareItems,
  }, self.BorderLabel)
  self:AddWidget(self.ItemList)
end

--- Deletes the UI and forgets it, so the next BuildUI makes it afresh rather
--- than picking up widgets that no longer exist. Widgets were added parent
--- first, so going backwards deletes each child before its parent.
function __PKGNAME__:DismantleUI()
  for i = #self.Widgets, 1, -1 do
    self.Widgets[i]:delete()
  end

  self.Widgets = {}
  self.Items = {}
  self.MainWindow = nil
  self.Container = nil
  self.BorderLabel = nil
  self.ItemList = nil
end

--- Puts the window back on the left at its default size. Mudlet has no call to
--- size a docked window, so the dock is made anew. That waits for the old one to
--- go, which only happens once Mudlet is back in its event loop: a dock that
--- arrives while the old one is there inherits its width when it leaves.
function __PKGNAME__:ResetLayout()
  self:DismantleUI()

  tempTimer(0, function()
    -- Uninstall empties this table, methods included.
    if not self.BuildUI then return end

    self:BuildUI(true)
    self:UpdateDisplay()
    cecho("\n<chartreuse>__PKGNAME__ window reset.\n")
  end)
end

--- The time left on a buff, as it shows in its row.
function __PKGNAME__:TimeLeft(buff)
  if buff.expires == math.huge then return "(???)" end

  -- UpdateDisplay read the clock earlier, so this one can be a second past
  -- the expiry, and shms wraps negative seconds round to "23h 59m 59s".
  return glu.date.shms(math.max(buff.expires - os.time(), 0), true)
end

function __PKGNAME__:ItemTag(id, expires)
  local newExpires = expires == math.huge and 999999999999 or expires

  -- %d goes through a C long, which is 32 bits on Windows and can't hold the
  -- stand-in for "never", so the number is formatted as a float instead.
  return string.format("__PKGNAME__.Item.%012.0f.%s", newExpires, id)
end

--- Fades both of a row's labels to transparent, each from its own colour, then
--- calls `done`. Each step sets a label's stylesheet to its own followed by the
--- faded text colour, so the rest of it, background included, stays as it is.
---
---@param item table The Geyser.ListItem to fade, with its `nameLabel` and `timeLabel`.
---@param done function Called with no arguments once the fade completes.
local function fadeOutItem(item, done)
  local fades = {}

  for _, label in ipairs({ item.nameLabel, item.timeLabel }) do
    local base = label.stylesheet or ""
    if base ~= "" and not base:match(";%s*$") then
      base = base .. ";"
    end

    fades[#fades + 1] = { label = label, base = base, fg = { Geyser.Color.parse(label.fgColor) } }
  end

  local function set_alpha(alpha)
    for _, fade in ipairs(fades) do
      fade.fg[4] = alpha
      fade.label:setStyleSheet(fade.base .. "color: rgba(" .. table.concat(fade.fg, ",") .. ");")
    end
  end

  -- The stylesheet takes over the colour before the text stops carrying its
  -- own, so the text never shows in the label's default colour.
  set_alpha(255)
  for _, fade in ipairs(fades) do
    fade.label:echo(nil, "nocolor", nil)
  end

  local steps = 20
  local duration = 0.3
  local step = 0
  local timer_id

  -- A plain temp timer: a named one would leave Mudlet holding an ID manager
  -- for every fade's throwaway user name.
  timer_id = tempTimer(
    duration / steps,
    function()
      -- The UI can come down mid-fade, taking the item with it.
      if item.deleted then
        killTimer(timer_id)
        return
      end

      step = step + 1

      set_alpha(math.floor(255 * (1 - step / steps) + 0.5))

      if step >= steps then
        killTimer(timer_id)
        done()
      end
    end,
    true
  )
end

--- The width a label needs for the text it is showing, its stylesheet's padding
--- included.
---
---@param label table The Geyser.Label to measure.
---@return number width The width in pixels.
local function textWidth(label)
  return (label:getSizeHint())
end

--- Resizes a label to a width, unless it is that wide already.
---
---@param label table The Geyser.Label to resize.
---@param width number The width in pixels.
local function setWidth(label, width)
  if label:get_width() ~= width then
    label:resize(width, nil)
  end
end

--- Builds the row for a buff: the name and then the time, each as wide as its
--- text. The time always gets its full width, so the name is what gets cut off
--- when the row runs out of room.
---
---@return table? item The new row, or nil if Geyser refused its name.
function __PKGNAME__:MakeItem(buff)
  -- The unique suffix keeps a re-added buff's labels from sharing names with
  -- its predecessor's while those are still fading out.
  self.ItemSerial = self.ItemSerial + 1
  local name = buff.tag .. "." .. self.ItemSerial

  local item = Geyser.ListItem:new({
    name = name,
    fontSize = ItemFontSize,
    height = "1c",
    expires = buff.expires,
    stylesheet = RowStyle,
    onDismiss = fadeOutItem,
  }, self.ItemList)

  if not item then return nil end

  local row = Geyser.HBox:new({
    name = name .. ".Row",
    x = 0,
    y = 0,
    width = "100%",
    height = "100%",
  }, item)
  item.row = row

  -- Everything that lays the row out comes through here, a resized window
  -- included, so the widths are always worked out against the row's current one.
  -- The labels aren't there yet for the layouts their own creation sets off.
  function row:organize()
    if item.nameLabel and item.timeLabel then
      local time_width = textWidth(item.timeLabel)
      local room = math.max(self:get_width() - time_width, 1)

      setWidth(item.timeLabel, time_width)
      setWidth(item.nameLabel, math.min(textWidth(item.nameLabel), room))
    end

    Geyser.HBox.organize(self)
  end

  local nameLabel = Geyser.Label:new({
    name = name .. ".Name",
    message = buff.name,
    fgColor = self.Colors[buff.btype],
    font = ItemFont,
    fontSize = ItemFontSize,
    format = "l",
    stylesheet = NameStyle,
    width = 1,
    h_policy = Geyser.Fixed,
  }, row)

  local timeLabel = Geyser.Label:new({
    name = name .. ".Time",
    message = self:TimeLeft(buff),
    fgColor = "white",
    font = ItemFont,
    fontSize = ItemFontSize,
    format = "l",
    stylesheet = TimeStyle,
    width = 1,
    h_policy = Geyser.Fixed,
  }, row)

  item.nameLabel = nameLabel
  item.timeLabel = timeLabel
  row:organize()

  return item
end

--- Puts rows in expiry order, with the names settling any ties.
---
---@param a table A row.
---@param b table Another row.
---@return boolean first Whether `a` goes before `b`.
function __PKGNAME__.CompareItems(a, b)
  if a.expires ~= b.expires then
    return a.expires < b.expires
  end

  return a.name < b.name
end

--- Creates the row for a buff if it has none, then brings its time up to date.
function __PKGNAME__:AddItem(buff)
  local item = self.Items[buff.tag]

  if not item then
    item = self:MakeItem(buff)

    -- Geyser has reported the refused name. The next update tries a new one.
    if not item then return end

    self.Items[buff.tag] = item
  end

  local time = self:TimeLeft(buff)

  if time ~= item.timeLabel.message then
    item.timeLabel:echo(time)
    item.row:organize()
  end
end

--- Fades out and forgets the item widget for a tag, if there is one.
function __PKGNAME__:RemoveItem(tag)
  local item = self.Items[tag]
  if not item then return end

  self.Items[tag] = nil
  item:dismiss()
end

function __PKGNAME__:ToggleUpdater()
  local wanted = next(self.Afflictions) ~= nil or next(self.Buffs) ~= nil or next(self.Debuffs) ~= nil

  if wanted == self.UpdaterRunning then return end
  self.UpdaterRunning = wanted

  if not wanted then
    self.idm:stopTimer("UpdateTimer")
  elseif not self.idm:resumeTimer("UpdateTimer") then
    self.idm:registerTimer(
      "UpdateTimer",
      0.25,
      function() if self.Tick then self:Tick() end end,
      true
    )
  end
end

--- Runs for the update timer. The display only has whole seconds to show and
--- os.time() only has whole seconds to compare, so ticks within the same second
--- have nothing to do. Gmcp events go straight to UpdateDisplay.
function __PKGNAME__:Tick()
  local now = os.time()

  if now == self.LastTick then return end
  self.LastTick = now

  self:UpdateDisplay()
end

function __PKGNAME__:UpdateDisplay()
  -- ResetLayout has taken the UI down and is due to put it back. What arrives
  -- until then stays stored, and its pass on rebuilding draws it.
  if not self.ItemList then return end

  local now = os.time()

  for _, class in ipairs(Classes) do
    local storage = self[class]

    for id, v in pairs(storage) do
      if v.expires >= now then
        self:AddItem(v)
      else
        self:RemoveItem(v.tag)
        storage[id] = nil
      end
    end
  end

  self:ToggleUpdater()
end

function __PKGNAME__:GetPackageInfo(pkg)
  return PackageInfo[string.match(pkg, "gmcp%.Char%.(%a+)%.")]
end

--- The string an id is stored under. Ids are kept as strings, since a List
--- carries them as JSON object keys while Add and Remove may carry them as
--- numbers, and all three have to find the same entry. tostring would put a
--- number of 15 digits or more in exponent form, which is neither the key a List
--- has for it nor unique to it.
---
---@param id any The id, as it came.
---@return string id The id to store it under.
local function entryId(id)
  if type(id) == "number" then
    return string.format("%.0f", id) --[[@as string]]
  end

  return tostring(id)
end

--- Whether a new entry can keep the row an old one has. A row's tag covers its
--- expiry, and it shows the name it was made with.
local function sameRow(old, new)
  return old.tag == new.tag and old.name == new.name
end

--- Builds the stored entry for one buff, debuff or affliction. The display name
--- is worked out once here rather than on every tick.
function __PKGNAME__:MakeEntry(info, id, name, expires)
  id = entryId(id)

  if type(name) ~= "string" or name == "" then
    name = id
  end

  if info.buff_type == "affliction" then
    name = glu.string.replace(name, "_", " ")
  end

  if name ~= "" then
    name = glu.string.capitalize(name)
  end

  -- The name goes into a label's rich text, where these would read as markup.
  name = name:gsub("&", "&amp;"):gsub("<", "&lt;")

  expires = tonumber(expires)
  if expires == nil or expires == -1 then
    expires = math.huge
  end

  return {
    id = id,
    name = name,
    expires = expires,
    btype = info.buff_type,
    tag = self:ItemTag(info.buff_type .. "." .. id, expires),
  }
end

function __PKGNAME__:Add(event, _)
  local packageTable, work

  local info = self:GetPackageInfo(event)
  if info == nil then return end

  packageTable = gmcp.Char[info.class].Add or {}

  if info.buff_type == "affliction" then
    if not packageTable[1] then return end

    work = self:MakeEntry(info, packageTable[1], packageTable[1], packageTable[2])
  else
    if not packageTable[info.label] then return end

    work = self:MakeEntry(info, packageTable[info.label], packageTable.name, packageTable.expires)
  end

  -- A renewal comes in with a new expiry, so its tag changes and the old item
  -- has to go. An identical re-add keeps its tag and its item.
  local old = self[info.class][work.id]
  if old and not sameRow(old, work) then
    self:RemoveItem(old.tag)
  end

  self[info.class][work.id] = work

  self:UpdateDisplay()
end

function __PKGNAME__:Remove(event, _)
  local info = self:GetPackageInfo(event)
  if info == nil then return end

  local id = entryId(gmcp.Char[info.class].Remove)

  local old = self[info.class][id]
  if old then
    self:RemoveItem(old.tag)
  end

  self[info.class][id] = nil

  self:UpdateDisplay()
end

--- Replaces everything stored for one class with the server's full list of
--- it. Entries the list carries with an unchanged expiry keep their items; the
--- rest fade out, and UpdateDisplay makes items for whatever is new.
function __PKGNAME__:List(event, _)
  local info = self:GetPackageInfo(event)
  if info == nil then return end

  local packageTable = gmcp.Char[info.class].List or {}
  local storage = {}

  for key, value in pairs(packageTable) do
    local work

    if info.buff_type == "affliction" then
      work = self:MakeEntry(info, key, key, value)
    elseif type(value) == "table" then
      work = self:MakeEntry(info, key, value.name, value.expires)
    end

    if work then
      storage[work.id] = work
    end
  end

  for id, old in pairs(self[info.class]) do
    local new = storage[id]
    if not new or not sameRow(old, new) then
      self:RemoveItem(old.tag)
    end
  end

  self[info.class] = storage

  -- A List can bring every row at once, as it does on logging in.
  local list = self.ItemList

  if list then list:begin_update() end
  self:UpdateDisplay()
  if list then list:end_update() end
end

--- Forgets everything stored, for when what the server says has started over.
function __PKGNAME__:ClearEntries()
  for _, class in ipairs(Classes) do
    for _, entry in pairs(self[class]) do
      self:RemoveItem(entry.tag)
    end

    self[class] = {}
  end

  self:ToggleUpdater()
end

function __PKGNAME__:ConnectionScript()
  -- This connection's Lists only say what this login has, and a server with
  -- nothing to list needn't send one, so nothing from the last login can stay.
  self:ClearEntries()
  self:RegisterEventHandlers()

  registerNamedTimer(__PKGNAME__.AppName, "AnnounceGMCP", 1, function()
    sendGMCP([[Core.Supports.Add ["Char 1", "Char.Buffs 1", "Char.Debuffs 1", "Char.Afflictions 1", "Char.Reset 1"]])

    deleteNamedTimer(__PKGNAME__.AppName, "AnnounceGMCP")
  end)
end

registerNamedEventHandler(__PKGNAME__.AppName,
  "__PKGNAME__Connect",
  "sysConnectionEvent",
  function()
    __PKGNAME__:ConnectionScript()
  end,
  false
)

function __PKGNAME__:Install(_, package)
  if package == self.AppName then
    self:ConnectionScript()
    self:DismantleUI()
    self:BuildUI()
    echo("Thank you for installing __PKGNAME__!\n")
    echo("Initializing GMCP in Threshold.\n")
    tempTimer(1, function() send("gmcp reset", false) end)
  end
end

registerNamedEventHandler(
  __PKGNAME__.AppName,
  "__PKGNAME__InstallHandler",
  "sysInstallPackage",
  function(_, package)
    __PKGNAME__:Install(_, package)
  end,
  true
)

function __PKGNAME__:Uninstall(event, name)
  if name == self.AppName then
    -- The GMCP handlers and the update timer live in the package's own ID
    -- manager; the lifecycle handlers, this one included, and the GMCP
    -- announcement live under its name.
    self:DeregisterEventHandlers()
    self.idm:deleteAllTimers()
    deleteAllNamedEventHandlers(self.AppName)
    deleteAllNamedTimers(self.AppName)
    -- The updater installs the new version in this same session, and the layout
    -- it restores is the saved one, so anything moved since the last save has to
    -- be in it, this window's place included. It has to go in before the window
    -- is deleted: a save only records the windows that exist.
    saveWindowLayout()
    self:DismantleUI()
    self:ClearSelf()

    -- That save is good for this session. The one Mudlet makes on closing won't
    -- have the window in it, so a later install is a first build again, and only
    -- this table, which outlives the uninstall but not the session, can say so.
    os.remove(layoutMarker())
    self.LayoutSaved = true

    -- The updater installs the new version in this same session. Left cached,
    -- require would hand back this Glu, with the old vendored code.
    package.loaded["__PKGNAME__/vendor/Glu-single"] = nil
    Geyser.List = nil
    Geyser.ListItem = nil

    cecho("\n<tomato>You have uninstalled __PKGNAME__.\n")
  end
end

function __PKGNAME__:ClearSelf()
  for k in pairs(self) do
    self[k] = nil
  end
end

registerNamedEventHandler(
  __PKGNAME__.AppName,
  "__PKGNAME__UninstallHandler",
  "sysUninstallPackage",
  function(event, package)
    __PKGNAME__:Uninstall(event, package)
  end,
  -- Not one-shot: uninstalling any other package raises this event too, and
  -- would use the handler up. Uninstall deletes it once it is this package's.
  false
)

registerNamedEventHandler(
  __PKGNAME__.AppName,
  "__PKGNAME__Load",
  "sysLoadEvent",
  function(_, freshLoad)
    __PKGNAME__:DismantleUI()
    __PKGNAME__:BuildUI()
    -- A profile reset raises this while still connected, with no connection
    -- event to follow, and it wiped the handlers along with everything else,
    -- what was stored included, which the server won't send again unprompted.
    __PKGNAME__:RegisterEventHandlers()

    local _, _, connected = getConnectionInfo()
    if not freshLoad and connected then
      tempTimer(0.5, function() send("gmcp reset", false) end)
    end
  end,
  true
)
