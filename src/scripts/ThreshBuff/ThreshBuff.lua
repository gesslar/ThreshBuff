-- ThreshBuff

ThreshBuff = ThreshBuff or {}
ThreshBuff.appName = "ThreshBuff"
ThreshBuff.Timer = nil
ThreshBuff.Buffs = ThreshBuff.Buffs or {}
ThreshBuff.Debuffs = ThreshBuff.Debuffs or {}
ThreshBuff.Afflictions = ThreshBuff.Afflictions or {}
ThreshBuff.Running = false
ThreshBuff.Timers = ThreshBuff.Timers or {}
ThreshBuff.CopyTable =
  function(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
      copy = {}
      for orig_key, orig_value in pairs(orig) do
        copy[orig_key] = orig_value
      end
    else
      -- number, string, boolean, etc
      copy = orig
    end
    return copy
  end
ThreshBuff.UpperGutter = 0
ThreshBuff.EventHandlers =
  {
    {"gmcp.Char.Afflictions.Add", "ThreshBuff.Add", nil},
    {"gmcp.Char.Afflictions.Remove", "ThreshBuff.Remove", nil},
    {"gmcp.Char.Afflictions.List", "ThreshBuff.List", nil},
    {"gmcp.Char.Buffs.Add", "ThreshBuff.Add", nil},
    {"gmcp.Char.Buffs.Remove", "ThreshBuff.Remove", nil},
    {"gmcp.Char.Buffs.List", "ThreshBuff.List", nil},
    {"gmcp.Char.Debuffs.Add", "ThreshBuff.Add", nil},
    {"gmcp.Char.Debuffs.Remove", "ThreshBuff.Remove", nil},
    {"gmcp.Char.Debuffs.List", "ThreshBuff.List", nil},
  }
ThreshBuff.Colors =
  {buff = "<0,137,0:0,0,0,0>", debuff = "<255,59,59:0,0,0,0>", affliction = "<147,112,219:0,0,0,0>"}

function ThreshBuff.RegisterEventHandlers()
  for i, v in ipairs(ThreshBuff.EventHandlers) do
    ThreshBuff.EventHandlers[i][3] = registerAnonymousEventHandler(v[1], v[2])
  end
end

function ThreshBuff.DeregisterEventHandlers()
  for i, v in ipairs(ThreshBuff.EventHandlers) do
    if v[3] ~= nil then
      killAnonymousEventHandler(v[3])
    end
  end
end

function ThreshBuff.Capitalize(str)
  return (str:gsub("^%l", string.upper))
end

ThreshBuff.MainWindow =
  ThreshBuff.MainWindow or
  Adjustable.Container:new(
    {
      name = "ThreshBuff.MainWindow",
      x = 15,
      y = 15,
      width = "57c",
      height = "3c",
      padding = 0,
      fontSize = 10,
      titleText = "",
      adjLabelstyle =
        "background-color: rgba(50,50,50,100%); border: 0px; border-radius: 5px;",
      buttonstyle =
        [[
      QLabel{ border-radius: 1px; background-color: rgba(0,0,0,0%);}
      QLabel::hover{ background-color: rgba(0,0,0,0%);}
      ]],
    }
  )
ThreshBuff.MainWindow:show()
ThreshBuff.Container =
  ThreshBuff.Container or
  Geyser.Container:new(
    {name = "ThreshBuff.Container", x = "0%", y = "0%", width = "100%", height = "100%"},
    ThreshBuff.MainWindow
  )
ThreshBuff.BorderLabel =
  ThreshBuff.BorderLabel or
  Geyser.Label:new(
    {name = "ThreshBuff.BorderLabel", x = 1, y = 1, width = -1, height = -1}, ThreshBuff.Container
  )
ThreshBuff.BorderLabel:setStyleSheet(
  [[
  background-color: rgba(50,50,50,100%);border: 1px solid grey;border-radius:5px;
]]
)
ThreshBuff.BorderLabel:enableClickthrough()
ThreshBuff.Display =
  ThreshBuff.Display or
  Geyser.MiniConsole:new(
    {
      name = "ThreshBuff.Display",
      x = 7,
      y = 27,
      autoWrap = false,
      color = "black",
      scrollBar = false,
      fontSize = 10,
      width = -7,
      height = -2,
      font = "Fixedsys",
    },
    ThreshBuff.Container
  )
ThreshBuff.Display:setColor(50, 50, 50)
-- ThreshBuff.Display =
-- ThreshBuff.Display or
-- Geyser.Label:new(
-- {
-- name = "ThreshBuff.Display",
-- x = 7,
-- y = 27,
-- fontSize = 10,
-- width = -7,
-- height = -2,
-- font = "Fixedsys",
-- },
-- ThreshBuff.Container
-- )
-- ThreshBuff.Display:setColor(50, 50, 50)
ThreshBuff.TitleLabel =
  ThreshBuff.TitleLabel or
  Geyser.Label:new(
    {
      name = "ThreshBuff.TitleLabel",
      x = 8,
      y = 8,
      width = "100%-100",
      height = 18,
      fgColor = "ansiLightBlack",
      font = "Lucida Console",
      fontSize = 10,
      message = [[THRESHOLD BUFFS AND DEBUFFS]],
    },
    ThreshBuff.Container
  )
ThreshBuff.TitleLabel:enableClickthrough()
ThreshBuff.TitleLabel:setStyleSheet(
  [[
    background-color: rgba(0,0,0,0%);
    qproperty-alignment: AlignVCenter;
]]
)

function ThreshBuff.Stringify(buff)
  -- for indefinite expirations
  local name = buff.name
  name = ThreshBuff.Capitalize(name)
  -- for definite expirations
  if buff.expires == math.huge then
    return name .. " (???)"
  end
  local remaining = buff.expires - os.time()
  local result
  local minute = 60
  local hour = minute * 60
  local day = hour * 24
  if (remaining < 0) then
    result = "(0s)"
  elseif (remaining < minute) then
    result = "(" .. tostring(remaining) .. "s)"
  elseif remaining < hour then
    result = "(" .. tostring(math.ceil(remaining / minute)) .. "m)"
  elseif remaining < day then
    result = "(" .. tostring(math.ceil(remaining / hour)) .. "h)"
  else
    result = "(" .. tostring(math.ceil(remaining / day)) .. "d)"
  end
  return name .. " " .. result
end

function ThreshBuff.ToggleUpdater()
  if #ThreshBuff.Buffs == 0 and #ThreshBuff.Debuffs == 0 and #ThreshBuff.Afflictions == 0 then
    if ThreshBuff.Timers.UpdateTimer then
      killTimer(ThreshBuff.Timers.UpdateTimer)
      ThreshBuff.Timers.UpdateTimer = nil
    end
  else
    if not ThreshBuff.Timers.UpdateTimer then
      ThreshBuff.Timers.UpdateTimer = tempTimer(0.25, ThreshBuff.UpdateDisplay, true)
    end
  end
  ThreshBuff.UpdateDisplay()
end

function ThreshBuff.ResizeConsole(num)
  if num == 0 or num == nil then
    num = 2
  else
    num = 2 + num
  end
  local height = tostring(num) .. "c"
  ThreshBuff.MainWindow:resize(nil, height)
end

function ThreshBuff.UpdateDisplay()
  ThreshBuff.Display:clear()
  local now = os.time()
  local num = 0
  for k, v in pairs(ThreshBuff.Buffs) do
    if v.expires ~= -1 and v.expires >= now then
      ThreshBuff.Display:decho(
        f("{ThreshBuff.Colors[v.btype]} ") .. ThreshBuff.Stringify(v) .. "\n"
      )
      num = num + 1
    end
  end
  for k, v in pairs(ThreshBuff.Debuffs) do
    if v.expires ~= -1 and v.expires >= now then
      ThreshBuff.Display:decho(
        f("{ThreshBuff.Colors[v.btype]} ") .. ThreshBuff.Stringify(v) .. "\n"
      )
      num = num + 1
    end
  end
  for k, v in pairs(ThreshBuff.Afflictions) do
    if v.expires ~= -1 and v.expires >= now then
      ThreshBuff.Display:decho(
        f("{ThreshBuff.Colors[v.btype]} ") .. ThreshBuff.Stringify(v) .. "\n"
      )
      num = num + 1
    end
  end
  ThreshBuff.ResizeConsole(num)
end

-- function ThreshBuff.UpdateDisplay()
-- ThreshBuff.Display:clear()
-- local now = os.time()
-- local num = 0
-- local height = ThreshBuff.BorderLabel.get_height()
-- local width = ThreshBuff.Container.get_width()
-- local text = ""
-- for k, v in pairs(ThreshBuff.Buffs) do
-- if v.expires ~= -1 and v.expires >= now then
-- text = text .. f("{ThreshBuff.Colors[v.btype]} ") .. ThreshBuff.Stringify(v) .. "\n"
-- num = num + 1
-- end
-- end
-- for k, v in pairs(ThreshBuff.Debuffs) do
-- if v.expires ~= -1 and v.expires >= now then
-- text = text .. f("{ThreshBuff.Colors[v.btype]} ") .. ThreshBuff.Stringify(v) .. "\n"
-- num = num + 1
-- end
-- end
-- for k, v in pairs(ThreshBuff.Afflictions) do
-- if v.expires ~= -1 and v.expires >= now then
-- text = text .. f("{ThreshBuff.Colors[v.btype]} ") .. ThreshBuff.Stringify(v) .. "\n"
-- num = num + 1
-- end
-- end
-- ThreshBuff.Display:decho(text)
-- local displayWidth, displayHeight = getLabelSizeHint("ThreshBuff.Display")
-- height = height + displayHeight
-- resizeWindow("ThreshBuff.Container", width, height)
-- end

function ThreshBuff.Sorter(elem1, elem2)
  return elem1.expires < elem2.expires
end

function ThreshBuff.Add(package)
  local class, label, storage, packageTable, temp, btype
  if package == "gmcp.Char.Buffs.Add" then
    class = "Buffs"
    label = "buff_id"
    btype = "buff"
  elseif package == "gmcp.Char.Debuffs.Add" then
    class = "Debuffs"
    label = "debuff_id"
    btype = "debuff"
  elseif package == "gmcp.Char.Afflictions.Add" then
    class = "Afflictions"
    label = "name"
    btype = "affliction"
  else
    return
  end
  packageTable = gmcp.Char[class].Add
  if btype == "affliction" then
    temp =
      {
        name = packageTable[1],
        id = packageTable[1],
        expires = tonumber(packageTable[2]),
        btype = btype,
      }
  else
    temp =
      {
        name = packageTable.name,
        id = packageTable[label],
        expires = tonumber(packageTable["expires"]),
        btype = btype,
      }
  end
  if temp.expires == -1 then
    temp.expires = math.huge
  end
  storage = ThreshBuff[class]
  storage[#storage + 1] = temp
  if #storage > 1 then
    table.sort(storage, ThreshBuff.Sorter)
  end
  ThreshBuff.ToggleUpdater()
end

function ThreshBuff.Remove(package)
  local id, class, storage
  if package == "gmcp.Char.Buffs.Remove" then
    class = "Buffs"
  elseif package == "gmcp.Char.Debuffs.Remove" then
    class = "Debuffs"
  elseif package == "gmcp.Char.Afflictions.Remove" then
    class = "Afflictions"
  else
    return
  end
  storage = ThreshBuff[class]
  id = gmcp.Char[class].Remove
  for remove_package, v in pairs(storage) do
    if v.id == id then
      table.remove(storage, remove_package)
      break
    end
  end
  if #storage > 1 then
    table.sort(storage, ThreshBuff.Sorter)
  end
  ThreshBuff.ToggleUpdater()
end

function ThreshBuff.List(package)
  local class, storage, label, btype
  ThreshBuff.Running = false
  if package == "gmcp.Char.Buffs.List" then
    class = "Buffs"
    btype = "buff"
    label = "buff_id"
  elseif package == "gmcp.Char.Debuffs.List" then
    class = "Debuffs"
    btype = "debuff"
    label = "debuff_id"
  elseif package == "gmcp.Char.Afflictions.List" then
    class = "Afflictions"
    btype = "affliction"
    label = name
  else
    return
  end
  packageTable = gmcp.Char[class].List
  ThreshBuff[class] = {}
  storage = ThreshBuff[class]
  if btype == "affliction" then
    for name, expires in pairs(packageTable) do
      storage[#storage + 1] = {id = name, name = name, expires = tonumber(expires), btype = btype}
      if storage[#storage].expires == -1 then
        storage[#storage].expires = math.huge
      end
    end
  else
    for id, details in pairs(packageTable) do
      storage[#storage + 1] =
        {id = id, name = details.name, expires = tonumber(details.expires), btype = btype}
      if storage[#storage].expires == -1 then
        storage[#storage].expires = math.huge
      end
    end
  end
  if #storage > 1 then
    table.sort(storage, ThreshBuff.Sorter)
  end
  ThreshBuff.ToggleUpdater()
end

-- This connection handler announces to Threshold that we would like to receive Char.Buffs and Char.Debuffs
ThreshBuff.ConnectionTimer = nil

function ThreshBuff.ConnectionScript()
  ThreshBuff.DeregisterEventHandlers()
  ThreshBuff.RegisterEventHandlers()
  if ThreshBuff.ConnectionTimer == nil then
    ThreshBuff.ConnectionTimer = tempTimer(1, [[ ThreshBuff.AnnounceGMCP() ]])
  end
end

function ThreshBuff.AnnounceGMCP()
  sendGMCP(
    [[Core.Supports.Add ["Char 1", "Char.Buffs 1", "Char.Debuffs 1", "Char.Afflictions 1", "Char.Reset 1"] ]]
  )
  ThreshBuff.ConnectionTimer = nil
end

registerAnonymousEventHandler("sysConnectionEvent", ThreshBuff.ConnectionScript)
-- This is the install routine

function ThreshBuff.Install(_, package)
  if package == ThreshBuff.appName then
    if ThreshBuff.installHandler ~= nil then
      killAnonymousEventHandler(ThreshBuff.installHandler)
    end
    ThreshBuff.ConnectionScript()
    print(
      "Thank you for installing ThreshBuff!\nInitializing GMCP in Threshold. 💪💪🏻💪🏼💪🏽💪🏾💪🏿\n"
    )
    tempTimer(
      1,
      function()
        send("gmcp reset", false)
      end
    )
  end
end

ThreshBuff.installHandler = registerAnonymousEventHandler("sysInstallPackage", ThreshBuff.Install)
-- This is the uninstall routine. Cleans everything up!

function ThreshBuff.KillTimers()
  if ThreshBuff.Timers then
    for k, v in pairs(ThreshBuff.Timers) do
      if v then
        killTimer(v)
      end
    end
  end
end

function ThreshBuff.Uninstall(event, package)
  ThreshBuff.DeregisterEventHandlers()
  if package == "ThreshBuff" then
    if ThreshBuff.uninstallHandler ~= nil then
      killAnonymousEventHandler(ThreshBuff.uninstallHandler)
    end
    ThreshBuff.KillTimers()
    ThreshBuff.MainWindow:hide()
    ThreshBuff.Timer = false
    ThreshBuff = {}
    cecho("\n<red>You have uninstalled ThreshBuff. 😔️😥😢\n")
  end
end

ThreshBuff.uninstallHandler =
  registerAnonymousEventHandler("sysUninstallPackage", ThreshBuff.Uninstall)
