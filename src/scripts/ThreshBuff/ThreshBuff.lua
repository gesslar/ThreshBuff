-- ThreshBuff

ThreshBuff = ThreshBuff or {}
ThreshBuff.AppName = "ThreshBuff"
ThreshBuff.Buffs = ThreshBuff.Buffs or {}
ThreshBuff.Debuffs = ThreshBuff.Debuffs or {}
ThreshBuff.Afflictions = ThreshBuff.Afflictions or {}
ThreshBuff.UpperGutter = 0
ThreshBuff.EventHandlers = {
    {"gmcp.Char.Afflictions.Add", "ThreshBuff:Add", nil},
    {"gmcp.Char.Afflictions.Remove", "ThreshBuff:Remove", nil},
    {"gmcp.Char.Afflictions.List", "ThreshBuff:List", nil},
    {"gmcp.Char.Buffs.Add", "ThreshBuff:Add", nil},
    {"gmcp.Char.Buffs.Remove", "ThreshBuff:Remove", nil},
    {"gmcp.Char.Buffs.List", "ThreshBuff:List", nil},
    {"gmcp.Char.Debuffs.Add", "ThreshBuff:Add", nil},
    {"gmcp.Char.Debuffs.Remove", "ThreshBuff:Remove", nil},
    {"gmcp.Char.Debuffs.List", "ThreshBuff:List", nil},
}
ThreshBuff.Colors = {
    buff = "<0,137,0:0,0,0,0>", debuff = "<255,59,59:0,0,0,0>", affliction = "<147,112,219:0,0,0,0>"
}

function ThreshBuff:CopyTable(orig)
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

function ThreshBuff:RegisterEventHandlers()
    for i, v in ipairs(self.EventHandlers) do
        self.EventHandlers[i][3] = registerNamedEventHandler(self.AppName, v[1], v[1], v[2], false)
    end
end

function ThreshBuff:DeregisterEventHandlers()
    for i, v in ipairs(self.EventHandlers) do
        if v[3] ~= nil then
            deleteNamedEventHandler(self.AppName, v[1])
        end
    end
end

function ThreshBuff:Capitalize(str)
    return (str:gsub("^%l", string.upper))
end

ThreshBuff.MainWindow = ThreshBuff.MainWindow or Adjustable.Container:new({
    name = "ThreshBuff.MainWindow",
    x = 15, y = 15, width = "57c", height = "3c",
    padding = 0, fontSize = 10, titleText = "",
    adjLabelstyle = "background-color: rgba(50,50,50,100%); border: 0px; border-radius: 5px;",
    buttonstyle = [[
        QLabel{ border-radius: 1px; background-color: rgba(0,0,0,0%);}
        QLabel::hover{ background-color: rgba(0,0,0,0%);}
    ]],
})

ThreshBuff.MainWindow:show()
ThreshBuff.Container = ThreshBuff.Container or Geyser.Container:new({
    name = "ThreshBuff.Container",
    x = "0%", y = "0%", width = "100%", height = "100%"
}, ThreshBuff.MainWindow)

ThreshBuff.BorderLabel = ThreshBuff.BorderLabel or Geyser.Label:new({
    name = "ThreshBuff.BorderLabel",
    x = 1, y = 1, width = -1, height = -1
}, ThreshBuff.Container)

ThreshBuff.BorderLabel:setStyleSheet([[
    background-color: rgba(50,50,50,100%);border: 1px solid grey;border-radius:5px;
]])

ThreshBuff.BorderLabel:enableClickthrough()
ThreshBuff.Display = ThreshBuff.Display or Geyser.MiniConsole:new({
    name = "ThreshBuff.Display",
    x = 7, y = 27, width = -7, height = -2,
    autoWrap = false,
    color = "black",
    scrollBar = false,
    fontSize = 10,
    font = "Fixedsys",
}, ThreshBuff.Container)

ThreshBuff.Display:setColor(50, 50, 50)

ThreshBuff.TitleLabel = ThreshBuff.TitleLabel or Geyser.Label:new({
    name = "ThreshBuff.TitleLabel",
    x = 8, y = 8, width = "100%-100", height = 18,
    fgColor = "ansiLightBlack",
    font = "Lucida Console",
    fontSize = 10,
    message = [[THRESHOLD BUFFS AND DEBUFFS]],
}, ThreshBuff.Container)

ThreshBuff.TitleLabel:enableClickthrough()
ThreshBuff.TitleLabel:setStyleSheet([[
    background-color: rgba(0,0,0,0%);
    qproperty-alignment: AlignVCenter;
]])

function ThreshBuff:Stringify(buff)
    local name = buff.name
    name = self:Capitalize(name)
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

function ThreshBuff:ToggleUpdater()
    if #self.Buffs == 0 and #self.Debuffs == 0 and #self.Afflictions == 0 then
        stopNamedTimer(self.AppName, "UpdateTimer")
    else
        if not resumeNamedTimer(self.AppName, "UpdateTimer") then
            registerNamedTimer(self.AppName, "UpdateTimer", 0.25, function() self:UpdateDisplay() end, true)
        end
    end

    self:UpdateDisplay()
end

function ThreshBuff:ResizeConsole(num)
    if num == 0 or num == nil then
        num = 2
    else
        num = 2 + num
    end
    local height = tostring(num) .. "c"
    self.MainWindow:resize(nil, height)
end

function ThreshBuff:UpdateDisplay()
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

function ThreshBuff:Sorter(elem1, elem2)
    return elem1.expires < elem2.expires
end

function ThreshBuff:Add(ev,pkg)
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

function ThreshBuff:Remove(evt,pkg)
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

function ThreshBuff:List(evt,pkg)
    local class, storage, label, btype

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

function ThreshBuff:ConnectionScript()
    self:DeregisterEventHandlers()
    self:RegisterEventHandlers()

    if self.ConnectionTimer == nil then
        registerNamedTimer(self.AppName, "AnnounceGMCP", 1, function() self:AnnounceGMCP() end)
    end
end

function ThreshBuff:AnnounceGMCP()
    sendGMCP([[
        Core.Supports.Add ["Char 1", "Char.Buffs 1", "Char.Debuffs 1", "Char.Afflictions 1", "Char.Reset 1"]
    ]])
    deleteNamedTimer(ThreshBuff.AppName, "AnnounceGMCP")
end

registerNamedEventHandler(ThreshBuff.AppName, "ThreshBuffConnect", "sysConnectionEvent", function() ThreshBuff:ConnectionScript() end, false)

function ThreshBuff:Install(_, package)
    if package == self.AppName then
        self:ConnectionScript()
        print("Thank you for installing ThreshBuff!\nInitializing GMCP in Threshold.\n")
        tempTimer(1, function() send("gmcp reset", false) end)
    end
end
ThreshBuff.installHandler = registerNamedEventHandler(ThreshBuff.AppName, "ThreshBuffInstallHandler", "sysInstallPackage", function(_, package) ThreshBuff:Install(_, package) end, true)

function ThreshBuff:Uninstall(event, package)
    self:DeregisterEventHandlers()
    if package == self.AppName then
        deleteNamedTimer(ThreshBuff.AppName, "UpdateTimer")
        self.MainWindow:hide()
        self.Timer = false
        self:ClearSelf()

        cecho("\n<red>You have uninstalled ThreshBuff.\n")
    end
end

function ThreshBuff:ClearSelf()
    for k in pairs(self) do
        self[k] = nil
    end
end

ThreshBuff.uninstallHandler = registerNamedEventHandler(ThreshBuff.AppName, "ThreshBuffUninstallHandler", "sysUninstallPackage", function(event, package) ThreshBuff:Uninstall(event, package) end, true)
