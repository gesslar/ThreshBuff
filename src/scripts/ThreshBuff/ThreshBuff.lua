__PKGNAME__ = __PKGNAME__ or {}
__PKGNAME__.AppName = "__PKGNAME__"
__PKGNAME__.Buffs = __PKGNAME__.Buffs or {}
__PKGNAME__.Debuffs = __PKGNAME__.Debuffs or {}
__PKGNAME__.Afflictions = __PKGNAME__.Afflictions or {}
__PKGNAME__.UpperGutter = 0
__PKGNAME__.EventHandlers = {
    {"gmcp.Char.Afflictions.Add", "__PKGNAME__:Add", nil},
    {"gmcp.Char.Afflictions.Remove", "__PKGNAME__:Remove", nil},
    {"gmcp.Char.Afflictions.List", "__PKGNAME__:List", nil},
    {"gmcp.Char.Buffs.Add", "__PKGNAME__:Add", nil},
    {"gmcp.Char.Buffs.Remove", "__PKGNAME__:Remove", nil},
    {"gmcp.Char.Buffs.List", "__PKGNAME__:List", nil},
    {"gmcp.Char.Debuffs.Add", "__PKGNAME__:Add", nil},
    {"gmcp.Char.Debuffs.Remove", "__PKGNAME__:Remove", nil},
    {"gmcp.Char.Debuffs.List", "__PKGNAME__:List", nil},
}
__PKGNAME__.Colors = {
    buff = "<0,137,0:0,0,0,0>", debuff = "<255,59,59:0,0,0,0>", affliction = "<147,112,219:0,0,0,0>"
}

function __PKGNAME__:CopyTable(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else
        copy = orig
    end
    return copy
end

function __PKGNAME__:RegisterEventHandlers()
    for _, v in ipairs(self.EventHandlers) do
        registerNamedEventHandler(self.AppName, v[1], v[1], v[2], false)
    end
end

function __PKGNAME__:DeregisterEventHandlers()
    for _, v in ipairs(self.EventHandlers) do
        deleteNamedEventHandler(self.AppName, v[1])
    end
end

function __PKGNAME__:Capitalize(str)
    return (str:gsub("^%l", string.upper))
end

__PKGNAME__.MainWindow = __PKGNAME__.MainWindow or Adjustable.Container:new({
    name = "__PKGNAME__.MainWindow",
    x = 15, y = 15, width = "57c", height = "3c",
    padding = 0, fontSize = 10, titleText = "",
    adjLabelstyle = "background-color: rgba(50,50,50,100%); border: 0px; border-radius: 5px;",
    buttonstyle = [[
        QLabel{ border-radius: 1px; background-color: rgba(0,0,0,0%);}
        QLabel::hover{ background-color: rgba(0,0,0,0%);}
    ]],
})

__PKGNAME__.MainWindow:show()
__PKGNAME__.Container = __PKGNAME__.Container or Geyser.Container:new({
    name = "__PKGNAME__.Container",
    x = "0%", y = "0%", width = "100%", height = "100%"
}, __PKGNAME__.MainWindow)

__PKGNAME__.BorderLabel = __PKGNAME__.BorderLabel or Geyser.Label:new({
    name = "__PKGNAME__.BorderLabel",
    x = 1, y = 1, width = -1, height = -1
}, __PKGNAME__.Container)

__PKGNAME__.BorderLabel:setStyleSheet([[
    background-color: rgba(50,50,50,100%);border: 1px solid grey;border-radius:5px;
]])

__PKGNAME__.BorderLabel:enableClickthrough()
__PKGNAME__.Display = __PKGNAME__.Display or Geyser.MiniConsole:new({
    name = "__PKGNAME__.Display",
    x = 7, y = 27, width = -7, height = -2,
    autoWrap = false,
    color = "black",
    scrollBar = false,
    fontSize = 10,
    font = "Fixedsys",
}, __PKGNAME__.Container)

__PKGNAME__.Display:setColor(50, 50, 50)

__PKGNAME__.TitleLabel = __PKGNAME__.TitleLabel or Geyser.Label:new({
    name = "__PKGNAME__.TitleLabel",
    x = 8, y = 8, width = "100%-100", height = 18,
    fgColor = "ansiLightBlack",
    font = "Lucida Console",
    fontSize = 10,
    message = [[THRESHOLD BUFFS AND DEBUFFS]],
}, __PKGNAME__.Container)

__PKGNAME__.TitleLabel:enableClickthrough()
__PKGNAME__.TitleLabel:setStyleSheet([[
    background-color: rgba(0,0,0,0%);
    qproperty-alignment: AlignVCenter;
]])

function __PKGNAME__:Stringify(buff)
    local name = buff.name
    name = self:Capitalize(name)
    if buff.expires == math.huge then
        return f"{name} (???)"
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

function __PKGNAME__:ToggleUpdater()
    if #self.Buffs == 0 and #self.Debuffs == 0 and #self.Afflictions == 0 then
        stopNamedTimer(self.AppName, "UpdateTimer")
    else
        if not resumeNamedTimer(self.AppName, "UpdateTimer") then
            registerNamedTimer(self.AppName, "UpdateTimer", 0.25, function() self:UpdateDisplay() end, true)
        end
    end

    self:UpdateDisplay()
end

function __PKGNAME__:ResizeConsole(num)
    if num == 0 or num == nil then
        num = 2
    else
        num = 2 + num
    end
    local height = tostring(num) .. "c"
    self.MainWindow:resize(nil, height)
end

function __PKGNAME__:UpdateDisplay()
    self.Display:clear()

    local tables = { self.Buffs, self.Debuffs, self.Afflictions }
    local now = os.time()
    local num = 0

    for _, table in ipairs(tables) do
        for k, v in pairs(table) do
            if v.expires ~= -1 and v.expires >= now then
                self.Display:decho(self.Colors[v.btype] .. " " .. self:Stringify(v) .. "\n")
                num = num + 1
            end
        end
    end

    self:ResizeConsole(num)
end

function __PKGNAME__:Sorter(elem1, elem2)
    return elem1.expires < elem2.expires
end

function __PKGNAME__:Add(ev,pkg)
    local class, label, storage, packageTable, temp, btype

    if pkg == "gmcp.Char.Buffs.Add" then
        class = "Buffs"
        label = "buff_id"
        btype = "buff"
    elseif pkg == "gmcp.Char.Debuffs.Add" then
        class = "Debuffs"
        label = "debuff_id"
        btype = "debuff"
    elseif pkg == "gmcp.Char.Afflictions.Add" then
        class = "Afflictions"
        label = "name"
        btype = "affliction"
    else
        return
    end

    packageTable = gmcp.Char[class].Add
    if btype == "affliction" then
        temp = {
            name = packageTable[1],
            id = packageTable[1],
            expires = tonumber(packageTable[2]),
            btype = btype,
        }
    else
        temp = {
            name = packageTable.name,
            id = packageTable[label],
            expires = tonumber(packageTable["expires"]),
            btype = btype,
        }
    end

    if temp.expires == -1 then
        temp.expires = math.huge
    end
    storage = self[class]

    storage[#storage + 1] = temp
    if #storage > 1 then
        table.sort(storage, function(a, b) return self:Sorter(a, b) end)
    end

    self:ToggleUpdater()
end

function __PKGNAME__:Remove(evt,pkg)
    local id, class, storage

    if pkg == "gmcp.Char.Buffs.Remove" then
        class = "Buffs"
    elseif pkg == "gmcp.Char.Debuffs.Remove" then
        class = "Debuffs"
    elseif pkg == "gmcp.Char.Afflictions.Remove" then
        class = "Afflictions"
    else
        return
    end

    storage = self[class]
    id = gmcp.Char[class].Remove
    for remove_package, v in pairs(storage) do
        if v.id == id then
            table.remove(storage, remove_package)
            break
        end
    end

    if #storage > 1 then
        table.sort(storage, function(a, b) return self:Sorter(a, b) end)
    end

    self:ToggleUpdater()
end

function __PKGNAME__:List(evt,pkg)
    local class, storage, label, btype, packageTable

    if pkg == "gmcp.Char.Buffs.List" then
        class = "Buffs"
        label = "buff_id"
        btype = "buff"
    elseif pkg == "gmcp.Char.Debuffs.List" then
        class = "Debuffs"
        label = "debuff_id"
        btype = "debuff"
    elseif pkg == "gmcp.Char.Afflictions.List" then
        class = "Afflictions"
        label = "name"
        btype = "affliction"
    else
        return
    end

    packageTable = gmcp.Char[class].List
    self[class] = {}
    storage = self[class]

    if btype == "affliction" then
        for name, expires in pairs(packageTable) do
            storage[#storage + 1] = {id = name, name = name, expires = tonumber(expires), btype = btype}
            if storage[#storage].expires == -1 then
                storage[#storage].expires = math.huge
            end
        end
    else
        for id, details in pairs(packageTable) do
            storage[#storage + 1] = {id = id, name = details.name, expires = tonumber(details.expires), btype = btype}
            if storage[#storage].expires == -1 then
                storage[#storage].expires = math.huge
            end
        end
    end

    if #storage > 1 then
        table.sort(storage, function(a, b) return self:Sorter(a, b) end)
    end

    self:ToggleUpdater()
end

function __PKGNAME__:ConnectionScript()
    self:DeregisterEventHandlers()
    self:RegisterEventHandlers()

    if self.ConnectionTimer == nil then
        registerNamedTimer(self.AppName, "AnnounceGMCP", 1, function() self:AnnounceGMCP() end)
    end
end

function __PKGNAME__:AnnounceGMCP()
    sendGMCP([[
        Core.Supports.Add ["Char 1", "Char.Buffs 1", "Char.Debuffs 1", "Char.Afflictions 1", "Char.Reset 1"]
    ]])
    deleteNamedTimer(__PKGNAME__.AppName, "AnnounceGMCP")
end

registerNamedEventHandler(__PKGNAME__.AppName, "__PKGNAME__Connect", "sysConnectionEvent", function() __PKGNAME__:ConnectionScript() end, false)

function __PKGNAME__:Install(_, package)
    if package == self.AppName then
        self:ConnectionScript()
        print("Thank you for installing __PKGNAME__!\nInitializing GMCP in Threshold.\n")
        tempTimer(1, function() send("gmcp reset", false) end)
    end
end
__PKGNAME__.installHandler = registerNamedEventHandler(__PKGNAME__.AppName, "__PKGNAME__InstallHandler", "sysInstallPackage", function(_, package) __PKGNAME__:Install(_, package) end, true)

function __PKGNAME__:Uninstall(event, package)
    self:DeregisterEventHandlers()
    if package == self.AppName then
        deleteNamedTimer(__PKGNAME__.AppName, "UpdateTimer")
        self.MainWindow:hide()
        self.Timer = false
        self:ClearSelf()

        cecho("\n<red>You have uninstalled __PKGNAME__.\n")
    end
end

function __PKGNAME__:ClearSelf()
    for k in pairs(self) do
        self[k] = nil
    end
end

__PKGNAME__.uninstallHandler = registerNamedEventHandler(
    __PKGNAME__.AppName, "__PKGNAME__UninstallHandler", "sysUninstallPackage", function(event, package) __PKGNAME__:Uninstall(event, package) end, true)
