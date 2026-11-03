-- Uninstall empties this table rather than dropping it, and the auto-updater
-- installs the new version in the same session, so a table left without an
-- AppName gets its defaults back just as a missing one would.
__PKGNAME__ = __PKGNAME__ or {}

if __PKGNAME__.AppName == nil then
  for key, value in pairs({
    AppName = "__PKGNAME__",
    Buffs = {},
    Debuffs = {},
    Afflictions = {},
    UpperGutter = 0,
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
      buff = "<chartreuse>",
      debuff = "<tomato>",
      affliction = "<orchid>"
    },
    Widgets = {},
    Items = {},
    ItemSerial = 0,
    glu = nil,
    idm = getNewIDManager() or {}
  }) do
    __PKGNAME__[key] = value
  end
end

---@return Glu
function __PKGNAME__:SetupGlu()
  local instance = self.glu or require("__PKGNAME__/vendor/Glu-single")("__PKGNAME__")

  instance.register(BuffItem)
  self.glu = instance

  return instance
end

---@type Glu
local glu = __PKGNAME__:SetupGlu()

local PanelStyle = [[
    background-color: "#333";
  ]]

-- Transparent so the panel shows through, leaving the fade only the text.
local ItemStyle = [[
    background-color: transparent;
    padding-left: 4px;
  ]]

function __PKGNAME__:AddWidget(widget)
  for _, v in ipairs(self.Widgets) do
    if v == widget then
      return
    end
  end

  table.insert(self.Widgets, widget)
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

function __PKGNAME__:BuildUI()
  self.MainWindow = self.MainWindow or Geyser.UserWindow:new({
    name = "__PKGNAME__.MainWindow",
    docked = true,
    dockPosition = "left",
    titleText = "__PKGNAME__ - " .. getProfileName(),
    width = "50c"
  })
  self:AddWidget(self.MainWindow)

  self.Container = self.Container or Geyser.Container:new({
    name = "__PKGNAME__.Container",
    x = 0,
    y = 0,
    width = "100%",
    height = "100%",
    stylesheet = "background-color: red;"
  }, self.MainWindow)
  self:AddWidget(__PKGNAME__.Container)

  self.BorderLabel = self.BorderLabel or Geyser.Label:new({
    name = "__PKGNAME__.BorderLabel",
    x = 1,
    y = 1,
    width = -1,
    height = -1
  }, self.Container)

  self.BorderLabel:setStyleSheet(PanelStyle)
  self.BorderLabel:enableClickthrough()
  self:AddWidget(self.BorderLabel)

  self.ScrollBox = self.ScrollBox or Geyser.ScrollBox:new({
    name = "__PKGNAME__.ScrollBox",
    x = 1,
    y = 1,
    width = -1,
    height = -1,
  }, self.BorderLabel)
  self:AddWidget(self.ScrollBox)

  -- Mudlet's scroll box starts its content at the size of its parent window
  -- and only re-fits it when a child moves, resizes, shows or hides. A Geyser
  -- container has no widget to trigger that, so this invisible label does,
  -- and keeps the content from being left at the old size once the last item
  -- is deleted.
  self.ScrollSpacer = self.ScrollSpacer or Geyser.Label:new({
    name = "__PKGNAME__.ScrollSpacer",
    x = 0,
    y = 0,
    width = 1,
    height = 1,
  }, self.ScrollBox)
  self.ScrollSpacer:setStyleSheet("background-color: transparent;")
  self.ScrollSpacer:enableClickthrough()

  -- Sized to its items by FitItemBox rather than to the scroll box, so that
  -- the scroll box gets something taller than itself to scroll. It stops
  -- short of the right edge by a scrollbar's width, so the vertical scrollbar
  -- never makes it too wide and brings in a horizontal one.
  self.ItemBox = self.ItemBox or Geyser.VBox:new({
    name = "__PKGNAME__.ItemBox",
    x = 0,
    y = 0,
    width = -20,
    height = 1,
  }, self.ScrollBox)
  self:AddWidget(self.ItemBox)
  -- self.Display = self.Display or Geyser.MiniConsole:new({
  --   name = "__PKGNAME__.Display",
  --   x = 2,
  --   y = 2,
  --   width = -2,
  --   height = -2,
  --   autoWrap = false,
  --   color = "black",
  --   scrollBar = false,
  --   fontSize = 12,
  --   font = "Ubuntu Mono",
  -- }, self.Container)

  -- __PKGNAME__.Display:setColor(50, 50, 50)
  -- self:AddWidget(self.Display)
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
  self.ScrollBox = nil
  self.ScrollSpacer = nil
  self.ItemBox = nil
end

function __PKGNAME__:Stringify(buff)
  local name = buff.name
  local time = "(???)"

  if buff.expires ~= math.huge then
    time = glu.date.shms(buff.expires - os.time(), true)
  end

  return name .. ' <span style="color: white;">' .. time .. "</span>"
end

function __PKGNAME__:ItemTag(id, expires)
  local newExpires = expires == math.huge and 999999999999 or expires

  -- %d goes through a C long, which is 32 bits on Windows and can't hold the
  -- stand-in for "never", so the number is formatted as a float instead.
  return string.format("__PKGNAME__.Item.%012.0f.%s", newExpires, id)
end

--- Creates the item widget for a buff, or updates the text of the one it
--- already has, then re-sorts the box so items stay in expiry order.
function __PKGNAME__:AddItem(buff)
  local item = self.Items[buff.tag]

  if not item then
    local color = self.Colors[buff.btype]:match("^<(.-)>$")

    -- The unique suffix keeps a re-added buff's label from sharing a name with
    -- its predecessor while that one is still fading out.
    self.ItemSerial = self.ItemSerial + 1
    ---@type BuffItemInstance
    item = glu.buff_item({
      name = buff.tag .. "." .. self.ItemSerial,
      fgColor = color,
      font = "Ubuntu",
      fontSize = 11,
      height = "1c",
    }, self.ItemBox)
    item:setStyleSheet(ItemStyle)
    self.Items[buff.tag] = item

    -- Names start with a zero-padded expiry, so sorting the names sorts by expiry.
    table.sort(self.ItemBox.windows)
    self:FitItemBox()
  end

  item:set(self:Stringify(buff))
end

--- Resizes the item box to the total height of its items and lays them out
--- again. Once that is taller than the scroll box, the scroll box scrolls.
function __PKGNAME__:FitItemBox()
  local box = self.ItemBox
  local height = 0

  for _, name in ipairs(box.windows) do
    height = height + box.windowList[name]:get_height()
  end

  box:resize(nil, math.max(height, 1))
  box:organize()
end

--- Fades out and forgets the item widget for a tag, if there is one.
function __PKGNAME__:RemoveItem(tag)
  local item = self.Items[tag]
  if not item then return end

  self.Items[tag] = nil
  -- The fade outlives the call, and by its end the UI may be gone or this
  -- table emptied by an uninstall.
  item:delete(function() if self.ItemBox then self:FitItemBox() end end)
end

function __PKGNAME__:ToggleUpdater()
  local timer = self.idm.timers["UpdateTimer"]
  -- isActive answers with a count, and 0 is true in Lua, so it has to be
  -- compared. A stopped timer's handler ID is -1, which isActive rejects.
  local active = timer ~= nil and timer.handlerID ~= -1 and isActive(timer.handlerID, "timer") > 0

  if next(self.Afflictions) == nil and next(self.Buffs) == nil and next(self.Debuffs) == nil then
    if active then
      self.idm:stopTimer("UpdateTimer")
    end
  else
    if not active then
      if not self.idm:resumeTimer("UpdateTimer") then
        self.idm:registerTimer(
          "UpdateTimer",
          0.25,
          function() if self and self.UpdateDisplay then self:UpdateDisplay() end end,
          true
        )
      end
    end
  end
end

function __PKGNAME__:UpdateDisplay()
  local classes = { "Buffs", "Debuffs", "Afflictions" }

  local now = os.time()

  for _, class in ipairs(classes) do
    local storage = self[class]

    if type(storage) == "table" then
      for id, v in pairs(storage) do
        if v.expires ~= -1 and v.expires >= now then
          self:AddItem(v)
        else
          self:RemoveItem(v.tag)
          storage[id] = nil
        end
      end
    end
  end

  self:ToggleUpdater()
end

function __PKGNAME__:GetPackageInfo(pkg)
  local info
  local package_type = string.match(pkg, "gmcp%.Char%.(%a+)%.")

  if package_type == "Buffs" then
    info = {
      class = "Buffs",
      label = "buff_id",
      buff_type = "buff",
    }
  elseif package_type == "Debuffs" then
    info = {
      class = "Debuffs",
      label = "debuff_id",
      buff_type = "debuff",
    }
  elseif package_type == "Afflictions" then
    info = {
      class = "Afflictions",
      label = "name",
      buff_type = "affliction",
    }
  else
    return nil
  end

  return info
end

--- Builds the stored entry for one buff, debuff or affliction. Ids are kept
--- as strings, since a List carries them as JSON object keys while Add and
--- Remove may carry them as numbers, and all three have to find the same
--- entry. The display name is worked out once here rather than on every tick.
function __PKGNAME__:MakeEntry(info, id, name, expires)
  id = tostring(id)

  if type(name) ~= "string" or name == "" then
    name = id
  end

  if info.buff_type == "affliction" then
    name = glu.string.replace(name, "_", " ")
  end

  if name ~= "" then
    name = glu.string.capitalize(name)
  end

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

  packageTable = gmcp.Char[info.class].Add

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
  if old and old.tag ~= work.tag then
    self:RemoveItem(old.tag)
  end

  self[info.class][work.id] = work

  self:UpdateDisplay()
end

function __PKGNAME__:Remove(event, _)
  local id, info

  info = self:GetPackageInfo(event)
  if info == nil then return end

  id = tostring(gmcp.Char[info.class].Remove)

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
    if not new or new.tag ~= old.tag then
      self:RemoveItem(old.tag)
    end
  end

  self[info.class] = storage

  self:UpdateDisplay()
end

function __PKGNAME__:ConnectionScript()
  self:DeregisterEventHandlers()
  self:RegisterEventHandlers()

  if self.ConnectionTimer == nil then
    registerNamedTimer(__PKGNAME__.AppName, "AnnounceGMCP", 1, function()
      sendGMCP([[
        Core.Supports.Add ["Char 1", "Char.Buffs 1", "Char.Debuffs 1", "Char.Afflictions 1", "Char.Reset 1"]
      ]])

      deleteNamedTimer(__PKGNAME__.AppName, "AnnounceGMCP")
    end)
  end
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

__PKGNAME__.installHandler = registerNamedEventHandler(
  __PKGNAME__.AppName,
  "__PKGNAME__InstallHandler",
  "sysInstallPackage",
  function(_, package)
    __PKGNAME__:Install(_, package)
  end,
  true
)

function __PKGNAME__:Uninstall(event, package)
  if package == self.AppName then
    -- The GMCP handlers and the update timer live in the package's own ID
    -- manager; the lifecycle handlers, this one included, and the GMCP
    -- announcement live under its name.
    self:DeregisterEventHandlers()
    self.idm:deleteAllTimers()
    deleteAllNamedEventHandlers(self.AppName)
    deleteAllNamedTimers(self.AppName)
    self:DismantleUI()
    self.Timer = false
    self:ClearSelf()

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
  function()
    __PKGNAME__:DismantleUI()
    __PKGNAME__:BuildUI()
  end,
  true
)
