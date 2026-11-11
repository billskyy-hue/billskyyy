-- Zekio | Lewati Batu r1 | standalone
local G = (getgenv and getgenv()) or _G
if G.__ZekioRockOnly and G.__ZekioRockOnly.Cleanup then pcall(G.__ZekioRockOnly.Cleanup) end
local Session = { Connections = {} }
G.__ZekioRockOnly = Session
local function alive() return G.__ZekioRockOnly == Session and not Session.Closed end
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
assert(LocalPlayer, "Masuk game terlebih dahulu")
local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 15)
assert(PlayerGui, "PlayerGui belum tersedia; masuk world lalu execute ulang")
local Refs, UI = {}, {}
local AutoInput = { active = false, left = false, right = false, jump = false, down = false }
local Move = { Rock = { Busy = false, Running = false, Cancelled = false, Token = 0, Status = "Siap. Pilih arah tujuan." } }
local Rock = Move.Rock
local BadEdge = {}
local floor, abs = math.floor, math.abs
local ItemDB
local MenuModOk, MenuModule = false, nil
local nativeGC = getgc
local function getgc(...)
    if Session.Objects then return Session.Objects end
    if type(nativeGC) == "function" then return nativeGC(...) end
    return {}
end
local getconsts = (debug and debug.getconstants) or getconstants
local function getUpvalues(fn)
    local all = (debug and debug.getupvalues) or getupvalues
    if type(all) == "function" then
        local ok, values = pcall(all, fn)
        if ok and type(values) == "table" then return values end
    end
    local one, result = (debug and debug.getupvalue) or getupvalue, {}
    if type(one) == "function" then
        for i = 1, 60 do
            local r = table.pack(pcall(one, fn, i))
            if not r[1] or r.n < 2 then break end
            if r.n >= 3 and type(r[2]) == "string" then result[i] = r[3]
            else result[i] = r[2] end
        end
    end
    return result
end
local function releaseInput()
    AutoInput.left, AutoInput.right, AutoInput.jump, AutoInput.down = false, false, false, false
end
function Rock.status(message)
    Rock.Status = tostring(message or "")
    if alive() and UI.Status then pcall(function() UI.Status.Text = Rock.Status end) end
end
local function setMoveStatus(message) Rock.status(message) end

-- Small native panel: left, right, cancel, close.
do
    local gui = Instance.new("ScreenGui")
    gui.Name, gui.ResetOnSpawn, gui.IgnoreGuiInset, gui.DisplayOrder = "ZekioRockOnly", false, true, 1500
    local parent = PlayerGui
    if type(gethui) == "function" then
        local ok, value = pcall(gethui)
        if ok and value then parent = value end
    end
    local ok = pcall(function() gui.Parent = parent end)
    if not ok then gui.Parent = PlayerGui end
    Session.Gui = gui
    local panel = Instance.new("Frame")
    panel.AnchorPoint, panel.Position = Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 105)
    panel.Size = UDim2.new(0.9, 0, 0, 172)
    panel.BackgroundColor3, panel.BorderSizePixel = Color3.fromRGB(23, 25, 33), 0
    panel.Parent = gui
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)
    local constraint = Instance.new("UISizeConstraint")
    constraint.MaxSize, constraint.Parent = Vector2.new(420, 172), panel
    local title = Instance.new("TextLabel")
    title.Position, title.Size = UDim2.fromOffset(14, 10), UDim2.new(1, -60, 0, 25)
    title.BackgroundTransparency, title.TextXAlignment = 1, Enum.TextXAlignment.Left
    title.Text, title.Font, title.TextSize = "Zekio | Lewati Batu r1", Enum.Font.GothamBold, 17
    title.TextColor3, title.Parent = Color3.fromRGB(245, 245, 250), panel
    local close = Instance.new("TextButton")
    close.Position, close.Size = UDim2.new(1, -42, 0, 9), UDim2.fromOffset(30, 28)
    close.Text, close.TextSize, close.BackgroundTransparency = "X", 17, 1
    close.TextColor3, close.Parent = Color3.fromRGB(220, 220, 230), panel
    local status = Instance.new("TextLabel")
    status.Position, status.Size = UDim2.fromOffset(14, 44), UDim2.new(1, -28, 0, 65)
    status.BackgroundTransparency, status.TextWrapped = 1, true
    status.Font, status.TextSize, status.TextColor3 = Enum.Font.Gotham, 13, Color3.fromRGB(200, 205, 220)
    status.TextXAlignment, status.TextYAlignment = Enum.TextXAlignment.Left, Enum.TextYAlignment.Top
    status.Text, status.Parent = Rock.Status, panel
    UI.Status = status
    local function button(text, index, color)
        local b = Instance.new("TextButton")
        b.Position, b.Size = UDim2.new((index - 1) / 3, 12, 1, -51), UDim2.new(1 / 3, -16, 0, 38)
        b.BackgroundColor3, b.BorderSizePixel = color, 0
        b.Text, b.TextSize, b.Font = text, 14, Enum.Font.GothamBold
        b.TextColor3, b.Parent = Color3.new(1, 1, 1), panel
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
        return b
    end
    UI.Left = button("Kiri", 1, Color3.fromRGB(65, 99, 210))
    UI.Right = button("Kanan", 2, Color3.fromRGB(65, 99, 210))
    UI.Cancel = button("Batal", 3, Color3.fromRGB(150, 57, 67))
    UI.Close = close
end

-- READ-ONLY GAME DISCOVERY
local function catalog(value)
    if type(value) ~= "table" then return false end
    local good, checked = 0, 0
    for id, entry in next, value do
        checked += 1
        if type(id) == "number" and type(entry) == "table" and type(rawget(entry, "name")) == "string"
            and (type(rawget(entry, "solid")) == "boolean" or type(rawget(entry, "hits")) == "number"
                or type(rawget(entry, "grow")) == "number") then
            good += 1
            if good >= 3 then return true end
        end
        if checked >= 64 then break end
    end
    return false
end
local function gameFunction(fn)
    if type(fn) ~= "function" then return false end
    if type(isexecutorclosure) == "function" then
        local ok, own = pcall(isexecutorclosure, fn)
        if ok and own then return false end
    end
    return true
end
local function loadCatalog(cancel)
    local candidates, seen = {}, {}
    local function inspect(node)
        if seen[node] then return end
        seen[node] = true
        local ok, matches = pcall(function()
            return node:IsA("ModuleScript") and node.Name:lower() == "itemdb"
        end)
        if ok and matches and #candidates < 3 then candidates[#candidates + 1] = node end
    end
    for _, root in ipairs({ ReplicatedStorage, PlayerGui, LocalPlayer:FindFirstChild("PlayerScripts") or false }) do
        if root then
            local ok, nodes = pcall(function() return root:GetDescendants() end)
            if ok then
                for i, node in ipairs(nodes) do
                    inspect(node)
                    if i % 400 == 0 then task.wait(); if cancel() then return end end
                end
            end
        end
    end
    for _, list in ipairs({ getloadedmodules or false, getnilinstances or false }) do
        if type(list) == "function" then
            local ok, nodes = pcall(list)
            if ok and type(nodes) == "table" then for _, node in pairs(nodes) do inspect(node) end end
        end
    end
    for _, node in ipairs(candidates) do
        if cancel() then return end
        local job = { done = false }
        local thread = task.spawn(function() job.ok, job.value = pcall(require, node); job.done = true end)
        local untilAt = os.clock() + 3
        while not job.done and not cancel() and os.clock() < untilAt do task.wait(0.05) end
        if not job.done and type(task.cancel) == "function" then pcall(task.cancel, thread) end
        if cancel() then return end
        if job.ok and catalog(job.value) then ItemDB = job.value; return end
    end
end
local function discover(cancel)
    local queue, seen, cursor = {}, {}, 1
    local worldScore, stateScore = -1, -1
    Refs.World, Refs.State, Refs.StateOwner, Refs.Menu, ItemDB = nil, nil, nil, nil, nil
    local function push(value, depth, score)
        local kind = type(value)
        if (kind ~= "table" and kind ~= "function") or seen[value] or #queue >= 3000 then return end
        if value == G or value == _G or value == Session or value == UI or value == Refs
            or value == AutoInput or value == Move or value == Rock or value == ItemDB then return end
        if kind == "function" and not gameFunction(value) then return end
        seen[value] = true
        queue[#queue + 1] = { value = value, depth = depth, score = score }
    end
    local function consider(value, score)
        if type(value) ~= "table" or value == G or value == _G or value == Session or value == Refs then return end
        if not ItemDB and catalog(value) then ItemDB = value end
        if score > worldScore and type(rawget(value, "fg")) == "table"
            and type(rawget(value, "bg")) == "table" and type(rawget(value, "w")) == "number"
            and type(rawget(value, "h")) == "number" and rawget(value, "spawn") ~= nil
            and value.w > 0 and value.h > 0 then Refs.World, worldScore = value, score end
        local fn = rawget(value, "state")
        if score > stateScore and gameFunction(fn) then
            local ok, s = pcall(fn)
            if ok and type(s) == "table" and type(s.x) == "number" and type(s.y) == "number"
                and s.vx ~= nil and s.facing ~= nil then
                Refs.State, Refs.StateOwner, stateScore = fn, value, score
            end
        end
    end
    if type(getconnections) == "function" then
        for _, entry in ipairs({ { RunService, { "RenderStepped", "Heartbeat", "PreRender", "Stepped" } },
            { UserInputService, { "InputBegan", "InputEnded" } } }) do
            for _, name in ipairs(entry[2]) do
                local ok, connections = pcall(function() return getconnections(entry[1][name]) end)
                if ok and type(connections) == "table" then
                    for _, connection in pairs(connections) do
                        local got, fn = pcall(function() return connection.Function end)
                        if got then push(fn, 0, 100) end
                    end
                end
            end
        end
    end
    local ok, objects = pcall(getgc, true)
    if ok and type(objects) == "table" then
        Session.Objects = objects
        local checked = 0
        for _, value in pairs(objects) do
            if cancel() then return false, "Dibatalkan" end
            if type(value) == "table" then
                consider(value, 50)
            elseif gameFunction(value) then
                for _, child in pairs(getUpvalues(value)) do consider(child, 45); push(child, 1, 45) end
            end
            checked += 1
            if Refs.World and Refs.State and ItemDB then break end
            if checked % 300 == 0 then task.wait() end
        end
    end
    while cursor <= #queue do
        if cancel() then return false, "Dibatalkan" end
        local entry = queue[cursor]
        cursor += 1
        local value, depth, score = entry.value, entry.depth, entry.score
        if type(value) == "table" then
            consider(value, score)
            if depth < 5 and value ~= ItemDB then
                for _, key in ipairs({ "world", "World", "state", "State", "controller", "Controller", "input", "Input" }) do
                    push(rawget(value, key), depth + 1, score - 1)
                end
                local checked = 0
                for key, child in next, value do
                    checked += 1
                    if checked > 48 then break end
                    if key ~= "fg" and key ~= "bg" and key ~= "_G" and key ~= "_ENV" then
                        push(child, depth + 1, score - 1)
                    end
                end
            end
        elseif depth < 5 then
            for _, child in pairs(getUpvalues(value)) do push(child, depth + 1, score - 1) end
        end
        if cursor % 100 == 0 then task.wait() end
    end
    if not ItemDB then loadCatalog(cancel) end
    if cancel() then return false, "Dibatalkan" end
    if not Refs.World then return false, "Data world belum terbaca. Masuk world lalu coba lagi." end
    if not Refs.State then return false, "Posisi karakter belum terbaca oleh executor." end
    if not ItemDB then return false, "Data block belum terbaca oleh executor." end
    return true
end

-- INPUT BINDING

-- Kontrol gerak dicari terpisah dari UI tas; getter boleh diwariskan lewat __index.
local OrigIsDown = nil
function AutoInput.member(value, key)
    local ok, result = pcall(function() return value[key] end)
    if ok then return result end
end
function AutoInput.method(value)
    if type(value) ~= "table" then return nil end
    for _, key in ipairs({ "isDown", "isKeyDown" }) do
        local fn = AutoInput.member(value, key)
        if type(fn) == "function" then return fn, key end
    end
end
function AutoInput.key(first, second)
    local key = second ~= nil and second or first
    if type(key) ~= "string" then key = AutoInput.member(key, "Name") end
    if type(key) ~= "string" then return nil end
    key = string.lower(key)
    if key == "keyleft" or key == "left" or key == "a" then return "left" end
    if key == "keyright" or key == "right" or key == "d" then return "right" end
    if key == "keyjump" or key == "jump" or key == "space" or key == "up" or key == "w" then return "jump" end
    if key == "keydown" or key == "down" or key == "s" then return "down" end
end
local function isDownWrapper(...)
    local first, second = ...
    local key = AutoInput.key(first, second)
    if key then
        AutoInput.Reads = (AutoInput.Reads or 0) + 1
        AutoInput.LastRead = os.clock()
        if AutoInput.active then return AutoInput[key] == true end

    end
    if OrigIsDown then return OrigIsDown(...) end
    return false
end

function AutoInput.findInput()
    local best, bestFn, bestKey, bestSource, bestScore = nil, nil, nil, nil, -1
    local function candidate(value, source, score)
        local fn, key = AutoInput.method(value)
        if not fn then return end
        local ours = value == AutoInput.Menu and (fn == isDownWrapper or fn == AutoInput.Function)
        if not ours and type(isexecutorclosure) == "function" and value ~= MenuModule and value ~= Refs.Menu then
            local ok, owned = pcall(isexecutorclosure, fn)
            if ok and owned then return end
        end
        if type(AutoInput.member(value, "openBackpack")) == "function" then score = score + 25 end
        if type(AutoInput.member(value, "ui")) == "table" then score = score + 10 end
        if ours and AutoInput.World ~= Refs.World then
            score = score - 30
        elseif ours and (AutoInput.Reads or 0) > 0 and os.clock() - (AutoInput.LastRead or 0) < 2 then
            score = score + 35
        end
        if score > bestScore then
            best, bestFn, bestKey, bestSource, bestScore = value, fn, key, source, score
        end
    end
    local roots = {}
    for _, entry in ipairs({ { AutoInput.World == Refs.World and Refs.Input or false, "kontrol sebelumnya", 15 }, { Refs.Menu, "menu game", 65 },
        { Refs.StateOwner, "pemilik posisi", 60 }, { Refs.World, "world", 45 },
        { MenuModOk and MenuModule or false, "modul WorldMenu", 10 } }) do
        if type(entry[1]) == "table" then
            candidate(entry[1], entry[2], entry[3])
            roots[#roots + 1] = { value = entry[1], source = entry[2], score = entry[3], depth = 0 }
        end
    end
    if type(getconnections) == "function" then
        for _, entry in ipairs({
            { RunService, { "RenderStepped", "Heartbeat", "PreRender", "PreSimulation", "Stepped" } },
            { UserInputService, { "InputBegan", "InputEnded" } },
        }) do
            for _, name in ipairs(entry[2]) do
                local signal = AutoInput.member(entry[1], name)
                if signal then
                    local ok, connections = pcall(getconnections, signal)
                    if ok and type(connections) == "table" then
                        for _, connection in pairs(connections) do
                            local fn = AutoInput.member(connection, "Function")
                            if type(fn) == "function" and #roots < 120 then
                                roots[#roots + 1] = { value = fn, source = "callback " .. name, score = 85, depth = 0 }
                            end
                        end
                    end
                end
            end
        end
    end
    local queue, seen, cursor = roots, {}, 1
    local function push(value, source, score, depth)
        if #queue >= 1200 or seen[value] or (type(value) ~= "table" and type(value) ~= "function") then return end
        if value == G or value == _G or value == UI or value == AutoInput
            or value == Refs or value == ItemDB or value == Session then return end
        seen[value] = true
        queue[#queue + 1] = { value = value, source = source, score = score, depth = depth }
    end
    if type(getgc) == "function" then
        local ok, values = pcall(getgc, true)
        if ok and type(values) == "table" then
            local n = 0
            for _, value in pairs(values) do
                if type(value) == "table" then
                    candidate(value, "getgc", value == MenuModule and 10 or 50)
                elseif type(value) == "function" and type(getUpvalues) == "function" then
                    local own = false
                    if type(isexecutorclosure) == "function" then
                        local checked, result = pcall(isexecutorclosure, value)
                        own = checked and result
                    end
                    if not own then
                        local got, ups = pcall(getUpvalues, value)
                        if got and type(ups) == "table" then
                            for _, child in pairs(ups) do
                                if type(child) == "table" then
                                    candidate(child, "getgc.upvalue", 50)
                                    if AutoInput.method(child) or AutoInput.member(child, "input")
                                        or AutoInput.member(child, "Input") or AutoInput.member(child, "controls")
                                        or AutoInput.member(child, "Controller") then
                                        push(child, "getgc.upvalue", 45, 0)
                                    end
                                end
                            end
                        end
                    end
                end
                n = n + 1
                if n % 300 == 0 then task.wait(); if Session.ScanCancel and Session.ScanCancel() then return end end
            end
        end
    end
    while cursor <= #queue do
        local entry = queue[cursor]
        cursor = cursor + 1
        local value = entry.value
        if type(value) == "table" then
            candidate(value, entry.source, entry.score)
            if entry.depth < 4 then
                for _, key in ipairs({ "input", "Input", "controls", "Controls", "keys", "Keys",
                    "menu", "Menu", "controller", "Controller", "worldMenu", "state", "State" }) do
                    push(AutoInput.member(value, key), entry.source .. "." .. key, entry.score, entry.depth + 1)
                end
                local n = 0
                for key, child in next, value do
                    n = n + 1
                    if n > 40 then break end
                    if key ~= "fg" and key ~= "bg" and key ~= "slots" and key ~= "_G" and key ~= "_ENV" then
                        push(child, entry.source, entry.score - 1, entry.depth + 1)
                    end
                end
                local ok, mt = pcall(getmetatable, value)
                if ok and type(mt) == "table" then push(rawget(mt, "__index"), entry.source, entry.score - 5, entry.depth + 1) end
            end
        elseif type(value) == "function" and entry.depth < 4 and type(getUpvalues) == "function" then
            local score = entry.score
            if type(getconsts) == "function" then
                local ok, constants = pcall(getconsts, value)
                if ok and type(constants) == "table" then
                    local keys = 0
                    for _, constant in pairs(constants) do
                        if constant == "keyLeft" or constant == "keyRight" or constant == "keyJump" then keys = keys + 1 end
                    end
                    if keys >= 2 then score = score + 30 end
                end
            end
            local ok, values = pcall(getUpvalues, value)
            if ok and type(values) == "table" then
                for _, child in pairs(values) do push(child, entry.source .. ".upvalue", score, entry.depth + 1) end
            end
        end
        if cursor % 120 == 0 then task.wait(); if Session.ScanCancel and Session.ScanCancel() then return end end
    end
    AutoInput.ScanInfo = "objek " .. tostring(cursor - 1) .. " | skor " .. tostring(bestScore)
    return best, bestFn, bestKey, bestSource
end

function AutoInput.unbindMenu()
    local menu, key = AutoInput.Menu, AutoInput.Key
    if AutoInput.Hooked and OrigIsDown then
        local restored = false
        if type(hookfunction) == "function" then restored = pcall(hookfunction, AutoInput.Function, OrigIsDown) end
        if not restored and type(restorefunction) == "function" then restored = pcall(restorefunction, AutoInput.Function) end
        if not restored then
            AutoInput.active = false
            AutoInput.Error = "Kontrol lama belum bisa dilepas; kontrol manual dipertahankan"
            return false
        end
    elseif menu and key and rawget(menu, key) == isDownWrapper then
        pcall(rawset, menu, key, AutoInput.OwnValue)
    end
    if Refs.Input == menu then Refs.Input, Refs.InputSource = nil, nil end
    AutoInput.Menu, AutoInput.Key, AutoInput.Function, AutoInput.Hooked = nil, nil, nil, nil
    AutoInput.OwnValue, AutoInput.World, AutoInput.Source, AutoInput.Error, OrigIsDown = nil, nil, nil, nil, nil
    AutoInput.Reads = 0
    return true
end

function AutoInput.bindMenu(quick)
    local menu, fn, key, source
    if quick then
        menu, source = Refs.Menu, "menu game"
        fn, key = AutoInput.method(menu)
        if not fn then
            menu, source = MenuModOk and MenuModule or nil, "modul WorldMenu"
            fn, key = AutoInput.method(menu)
        end
    else
        menu, fn, key, source = AutoInput.findInput()
    end
    if menu == AutoInput.Menu and menu and key == AutoInput.Key
        and (fn == isDownWrapper or (AutoInput.Hooked and fn == AutoInput.Function)) then
        AutoInput.World = Refs.World
        Refs.Input, Refs.InputSource = menu, AutoInput.Source
        return true
    end
    if AutoInput.unbindMenu() == false then return false end
    if not menu then
        AutoInput.Source, AutoInput.Error = nil, "Pembaca tombol gerak belum ditemukan (" .. tostring(AutoInput.ScanInfo) .. ")"
        return false
    end
    OrigIsDown = fn
    local own = rawget(menu, key)
    local ok = pcall(rawset, menu, key, isDownWrapper)
    if not ok or AutoInput.member(menu, key) ~= isDownWrapper then
        if type(hookfunction) == "function" then
            local replacement = isDownWrapper
            if type(newcclosure) == "function" then
                local made, closure = pcall(newcclosure, isDownWrapper)
                if made and type(closure) == "function" then replacement = closure end
            end
            local hooked, original = pcall(hookfunction, fn, replacement)
            if hooked and type(original) == "function" then
                OrigIsDown, AutoInput.Hooked = original, true
            else
                OrigIsDown = nil
            end
        else
            OrigIsDown = nil
        end
        if not OrigIsDown then
            AutoInput.Error = "Kontrol ditemukan tetapi tidak bisa dipasang: " .. tostring(source) .. "." .. key
            return false
        end
    end
    AutoInput.Menu, AutoInput.Key, AutoInput.OwnValue = menu, key, own
    AutoInput.Function, AutoInput.Source, AutoInput.Error = fn, source .. "." .. key, nil
    AutoInput.World = Refs.World
    AutoInput.Reads = 0
    Refs.Input, Refs.InputSource = menu, AutoInput.Source
    return true
end
function AutoInput.status()
    return AutoInput.Error or ((AutoInput.Source or "belum terhubung") .. " | bacaan " .. tostring(AutoInput.Reads or 0))
end
-- Pemindaian penuh dijalankan oleh reconnect setelah jendela utama terbentuk.
Session.UnbindInput = AutoInput.unbindMenu



-- WORLD GEOMETRY AND NATIVE MOVEMENT
local function autoOn()
    return alive() and Rock.Running and not Rock.Cancelled and Refs.World == Rock.World
        and Refs.World.fg == Rock.Grid and os.clock() < Rock.Deadline
end
local function frame() task.wait(); return autoOn() end

local function playerState()
    if not Refs.State then return nil end
    local ok, s = pcall(Refs.State)
    if ok and type(s) == "table" and type(s.x) == "number" and type(s.y) == "number" and s.active ~= false then
        return s
    end
    return nil
end

local function fgIdAt(x, y)
    local w = Refs.World
    local row = w and w.fg[y]
    return (row and row[x]) or 0
end

local function fgItemAt(x, y)
    local id = fgIdAt(x, y)
    if id ~= 0 then return ItemDB[id] end
    return nil
end

-- Tile padat? (sama dengan cek tabrakan game)
local function solidAt(x, y)
    local w = Refs.World
    if not w then return true end
    if x < 0 or x >= w.w or y >= w.h then return true end
    if y < 0 then return false end
    local it = fgItemAt(x, y)
    if not it then return false end
    if it.combiner then
        local ok, shut = pcall(w.combinerShut, x, y)
        return (not ok) or (shut and true or false)
    end
    if it.vip then -- pintu VIP: padat kalau kamu tidak punya akses
        local ok, may = pcall(w.vipMay, x, y)
        return not (ok and may)
    end
    if it.entrance then
        local sw = w.switches and w.switches[y * w.w + x]
        if it.gate then
            return not (sw and sw.off == true)
        end
        if sw and sw.public then return false end
        local ok, may = pcall(function() return w.areas.mayBuild(w.lock, x, y) end)
        return not (ok and may)
    end
    return it.solid and true or false
end

-- Tile berbahaya (lava, duri, laser)
local function hazardAt(x, y)
    local it = fgItemAt(x, y)
    return it ~= nil and (it.deadly or it.hurts or it.laser) and true or false
end

local function platformAt(x, y)
    local it = fgItemAt(x, y)
    return it ~= nil and it.platform and true or false
end

local function openAt(x, y)
    return not solidAt(x, y) and not hazardAt(x, y)
end

-- Ada pijakan aman di bawah tile ini?
local function realSupport(x, y)
    return not hazardAt(x, y + 1) and (solidAt(x, y + 1) or platformAt(x, y + 1))
end


local function startNode(s)
    local ny = floor(s.y - 0.475)
    local nx = floor(s.x)
    if realSupport(nx, ny) then return nx, ny end
    local a, b = floor(s.x - 0.3), floor(s.x + 0.3 - 0.0001)
    for _, c in ipairs({ a, b }) do
        if c ~= nx and realSupport(c, ny) then return c, ny end
    end
    return nx, ny
end


local function heapPush(hf, hi, n, f, i)
    n += 1
    local k = n
    while k > 1 do
        local p = k // 2
        if hf[p] <= f then break end
        hf[k], hi[k] = hf[p], hi[p]
        k = p
    end
    hf[k], hi[k] = f, i
    return n
end

local function heapPop(hf, hi, n)
    local top = hi[1]
    local lf, li = hf[n], hi[n]
    hf[n], hi[n] = nil, nil
    n -= 1
    if n > 0 then
        local k = 1
        while true do
            local c = k * 2
            if c > n then break end
            if c < n and hf[c + 1] < hf[c] then c += 1 end
            if lf <= hf[c] then break end
            hf[k], hi[k] = hf[c], hi[c]
            k = c
        end
        hf[k], hi[k] = lf, li
    end
    return top, n
end

-- A*: jalan, jatuh, lompat dan tangga yang sudah ada.
local MAX_EXPAND = 8000

local function reachOffsets(R)
    return floor(R), math.ceil(-R + 0.025), floor(R + 0.025)
end

local function astar(sx, sy, goals, gx, gy, R, useBlock)
    local w = Refs.World
    if not w then return nil, false, {} end
    local W, H = w.w, w.h
    local WH = W * H
    local dxm, dyLo, dyHi = reachOffsets(R)
    local oC, sC = {}, {}

    local function open(x, y)
        if x < 0 or x >= W or y >= H then return false end
        if y < 0 then return true end
        local i = y * W + x
        local v = oC[i]
        if v == nil then
            v = openAt(x, y)
            oC[i] = v
        end
        return v
    end

    local function sup(x, y)
        if x < 0 or x >= W or y < 0 or y >= H then return false end
        local i = y * W + x
        local v = sC[i]
        if v == nil then
            v = realSupport(x, y)
            sC[i] = v
        end
        return v
    end

    local function h(x, y)
        local dx = abs(gx - x) - R
        local dyRaw = gy - y
        local dy = abs(dyRaw) - R
        local vw = (dyRaw < 0) and 1.5 or 0.5
        return (dx > 0 and dx or 0) + vw * (dy > 0 and dy or 0)
    end

    local function isGoal(nx, ny)
        -- goals.maxY: tempat berdiri tidak boleh lebih bawah dari ini
        if goals.maxY and ny > goals.maxY then return false end
        for ty = ny + dyLo, ny + dyHi do
            if ty >= 0 and ty < H then
                local base = ty * W
                for tx = nx - dxm, nx + dxm do
                    -- jangan berdiri tepat di atas target (noSelf: juga jangan di dalam tile target)
                    if tx >= 0 and tx < W and goals[base + tx] and not (tx == nx and ty == ny + 1)
                        and not (goals.noSelf and tx == nx and ty == ny)
                        and not (goals.los and ty - ny >= 2 and not open(tx, ny + 1))
                        and not (goals.los and ny - ty >= 2 and not open(tx, ny - 1)) then
                        return true
                    end
                end
            end
        end
        return false
    end

    local ex, ey, ek, ec, eb = {}, {}, {}, {}, {}
    local n = 0
    local function add(x, y, kind, cost, build)
        n += 1
        ex[n], ey[n], ek[n], ec[n], eb[n] = x, y, kind, cost, build
    end

    local function expand(x, y)
        n = 0
        for s = -1, 1, 2 do
            local ax = x + s
            if open(ax, y) then
                if sup(ax, y) then
                    add(ax, y, "walk", 1, false)
                else
                    -- jatuh sampai ketemu pijakan
                    local fy = y + 1
                    while fy < H and fy - y <= 40 and open(ax, fy) and not sup(ax, fy) do
                        fy += 1
                    end
                    if fy < H and open(ax, fy) and sup(ax, fy) then
                        add(ax, fy, "fall", 1 + 0.5 * (fy - y), false)
                    end
                    -- lompati lubang 1-2 tile
                    if open(x, y - 1) and open(x, y - 2) then
                        for dist = 2, 3 do
                            local mx = x + (dist - 1) * s
                            if not (open(mx, y) and open(mx, y - 1) and open(mx, y - 2)) then break end
                            if dist == 3 and sup(mx, y) then break end
                            local bx = x + dist * s
                            if open(bx, y - 1) and open(bx, y - 2) then
                                for k = 0, 2 do
                                    if not open(bx, y + k) then break end
                                    if sup(bx, y + k) then
                                        add(bx, y + k, "gap", dist + 0.5 + 0.5 * k, false)
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end
            -- lompat naik (atas kepala harus kosong)
            for dy = 1, 3 do
                if not open(x, y - dy) then break end
                if open(x, y - dy - 1) and open(ax, y - dy) and sup(ax, y - dy) and open(ax, y - dy - 1) then
                    add(ax, y - dy, "jump", 1 + 1.5 * dy, false)
                end
            end
            -- tangga: naik 1-2 tile ke lorong setinggi 1 tile (atapnya pas di atas kepala,
            -- jadi lompat biasa tidak muat). Rapat ke dinding, lompat, geser masuk di puncak.
            for dy = 1, 2 do
                if open(x, y - 1) and (dy == 1 or open(x, y - 2)) and open(ax, y - dy) and sup(ax, y - dy)
                    and not (open(x, y - dy - 1) and open(ax, y - dy - 1)) then
                    add(ax, y - dy, "stair", 3 + 1.5 * dy, false)
                end
            end
        end
        return n
    end

    local startI = sy * W + sx
    local g, came, kind, buildOf, closed = { [startI] = 0 }, {}, {}, {}, {}
    local hf, hi, hn = {}, {}, 0
    hn = heapPush(hf, hi, hn, h(sx, sy), startI)
    local expanded = 0
    local now = os.clock()

    while hn > 0 do
        local cur
        cur, hn = heapPop(hf, hi, hn)
        if not closed[cur] then
            closed[cur] = true
            local cx, cy = cur % W, cur // W
            if isGoal(cx, cy) then
                local path = {}
                local i = cur
                while i ~= startI do
                    local p = came[i]
                    table.insert(path, 1, {
                        fx = p % W, fy = p // W, x = i % W, y = i // W,
                        kind = kind[i], build = buildOf[i], key = p * WH + i,
                    })
                    i = p
                end
                return path, false, closed
            end
            expanded += 1
            if expanded > (goals.maxExpand or MAX_EXPAND) then return nil, false, closed end
            if expanded % 400 == 0 then
                task.wait()
                if not autoOn() then return nil, false, closed end
            end
            local gc = g[cur]
            local cnt = expand(cx, cy)
            for k = 1, cnt do
                local ni = ey[k] * W + ex[k]
                if not closed[ni] then
                    local bad = BadEdge[cur * WH + ni]
                    if not (bad and bad > now) then
                        local ng = gc + ec[k]
                        local old = g[ni]
                        if old == nil or ng < old then
                            g[ni], came[ni], kind[ni], buildOf[ni] = ng, cur, ek[k], eb[k]
                            hn = heapPush(hf, hi, hn, ng + h(ex[k], ey[k]), ni)
                        end
                    end
                end
            end
        end
    end
    return nil, true, closed -- tidak ada jalan sama sekali
end


local function steerX(s, targetX, tol)
    local dx = targetX - s.x
    local vx = s.vx or 0
    local decel = s.grounded and 48 or 17
    local dir = 0
    if abs(dx) > tol then
        dir = dx > 0 and 1 or -1
        if vx * dir > 0 and (vx * vx) / (2 * decel) >= abs(dx) - tol * 0.5 then
            dir = 0
        end
    end
    AutoInput.left = dir < 0
    AutoInput.right = dir > 0
end

-- Jalan sampai berdiri di tengah tile tujuan
local function execWalk(tx, ty)
    local cx = tx + 0.5
    local s0 = playerState()
    if not s0 then return false end
    local limit = 1.5 + abs(cx - s0.x) * 0.35
    local t0 = os.clock()
    while frame() do
        local s = playerState()
        if not s or s.dead then return false end
        local nx, ny = floor(s.x), floor(s.y - 0.475)
        if s.grounded and ny ~= ty then return false end
        steerX(s, cx, 0.1)
        if nx == tx and abs(s.x - cx) <= 0.2 and s.grounded and abs(s.vx or 0) < 2 then
            AutoInput.left, AutoInput.right = false, false
            return true
        end
        if os.clock() - t0 > limit then return false end
    end
    return false
end

-- Jalan ke pinggir lalu jatuh ke tile tujuan
local function execFall(e)
    local cx = e.x + 0.5
    local limit = 1.5 + 0.3 * (e.y - e.fy)
    local t0 = os.clock()
    while frame() do
        local s = playerState()
        if not s or s.dead then return false end
        steerX(s, cx, 0.1)
        if s.grounded then
            local nx, ny = floor(s.x), floor(s.y - 0.475)
            if ny == e.y then
                if nx == e.x and abs(s.x - cx) <= 0.25 then return true end
            elseif ny ~= e.fy then
                return false
            end
        end
        if os.clock() - t0 > limit then return false end
    end
    return false
end

-- Lompat naik ke tile sebelah
local function execJump(e)
    if not execWalk(e.fx, e.fy) then return false end
    local dy = e.fy - e.y
    local top = e.y + 1                               -- tinggi kaki di tujuan
    local releaseY = top - ((dy == 1) and 0 or 0.4)   -- lepas lompat di sini (kepala tidak kebentur)
    local cx = e.x + 0.5
    releaseInput()
    if not frame() then return false end              -- lepas 1 frame supaya lompat terbaca
    AutoInput.jump = true
    local t0 = os.clock()
    local airborne = false
    while frame() do
        local s = playerState()
        if not s or s.dead then return false end
        if not s.grounded then airborne = true end
        if AutoInput.jump and (s.y <= releaseY or (airborne and (s.vy or 0) >= 0)) then
            AutoInput.jump = false
        end
        if s.y <= top + 0.25 then
            steerX(s, cx, 0.1)
        else
            steerX(s, e.fx + 0.5, 0.15)
        end
        if airborne and s.grounded then
            local nx, ny = floor(s.x), floor(s.y - 0.475)
            if ny == e.y then
                if nx == e.x and abs(s.x - cx) <= 0.25 then
                    AutoInput.jump = false
                    return true
                end
            else
                return false
            end
        end
        if not airborne and os.clock() - t0 > 0.35 then return false end
        if os.clock() - t0 > 1.8 then return false end
    end
    return false
end

-- Lompati lubang: ancang-ancang, lompat di ujung, rem di udara
local function execGap(e)
    if not execWalk(e.fx, e.fy) then return false end
    local s0 = playerState()
    if not s0 then return false end
    local dir = (e.x > e.fx) and 1 or -1
    local takeoff = e.fx + 0.5 + dir * 0.6
    local startY = s0.y
    local cx = e.x + 0.5
    releaseInput()
    local t0 = os.clock()
    local jumped, airborne, jumpAt = false, false, 0
    while frame() do
        local s = playerState()
        if not s or s.dead then return false end
        if not jumped then
            AutoInput.left, AutoInput.right = dir < 0, dir > 0
            if (s.x - takeoff) * dir >= 0 or not s.grounded then
                jumped, jumpAt = true, os.clock()
                AutoInput.jump = s.grounded
            end
        else
            if not s.grounded then airborne = true end
            if AutoInput.jump and (s.y <= startY - 1 or (airborne and (s.vy or 0) >= 0)) then
                AutoInput.jump = false
            end
            steerX(s, cx, 0.1)
            if airborne and s.grounded then
                local nx, ny = floor(s.x), floor(s.y - 0.475)
                if ny == e.y then
                    if nx == e.x and abs(s.x - cx) <= 0.25 then return true end
                else
                    return false
                end
            end
            if not airborne and os.clock() - jumpAt > 0.35 then return false end
        end
        if os.clock() - t0 > 2.2 then return false end
    end
    return false
end

-- Tangga lahan: naik 1-2 tile ke lorong setinggi 1 tile (lewat lubang tangga / keluar dari lubang).
-- Cara main manual: berdiri rapat ke sisi tujuan, lompat, tekan arah tujuan SETELAH badan naik
-- (kalau ditekan terlalu cepat badan masuk ke bawah block tujuan -> kepala kebentur -> jatuh),
-- saat kepala menempel atap lorong kaki sudah di atas block tujuan -> geser masuk. 3 cara dicoba.
function Move.execStair(e)
    if not execWalk(e.fx, e.fy) then return false end
    local dir = (e.x > e.fx) and 1 or -1
    local top = e.y + 1 -- tinggi kaki di tujuan (atas block pijakan)
    local hug = e.fx + 0.5 + dir * 0.17
    for try = 1, 3 do
        -- rapat ke dinding sisi tujuan
        local t0 = os.clock()
        while frame() do
            local s = playerState()
            if not s or s.dead then return false end
            steerX(s, hug, 0.03)
            if abs(s.x - hug) <= 0.06 and abs(s.vx or 0) < 1 then break end
            if os.clock() - t0 > 0.8 then break end
        end
        releaseInput()
        if not frame() then return false end
        local s0 = playerState()
        if not s0 then return false end
        local y0 = s0.y
        AutoInput.jump = true
        t0 = os.clock()
        local airborne, landed = false, nil
        while frame() do
            local s = playerState()
            if not s or s.dead then return false end
            if not s.grounded then airborne = true end
            if AutoInput.jump and (s.y <= top - 0.1 or (airborne and (s.vy or 0) >= 0)) then
                AutoInput.jump = false -- sudah setinggi tujuan / kena atap
            end
            -- Saat lompat di bawah atap lorong, kepala menempel di atap +-0.18 dtk dan kaki sudah di atas block
            -- tujuan: tekan arah di saat itu -> badan langsung masuk lorong (tidak perlu diangkat game).
            -- Tombol arah JANGAN ditekan di lantai: badan masuk ke bawah block tujuan -> kepala kebentur -> jatuh.
            -- coba 1: saat kaki sudah setinggi atas block tujuan (menempel atap)
            -- coba 2: setelah naik 0.15 tile (menempel sisi block, game mengangkat badan s/d 0.3 tile)
            -- coba 3: saat kaki 0.25 tile di bawah atas block
            local press = (try == 1 and s.y <= top + 0.02) or (try == 2 and s.y <= y0 - 0.15) or (try == 3 and s.y <= top + 0.25)
            if airborne and press then
                AutoInput.right, AutoInput.left = dir > 0, dir < 0
            else
                steerX(s, hug, 0.03)
            end
            if airborne and s.grounded then
                landed = floor(s.y - 0.475)
                break
            end
            if not airborne and os.clock() - t0 > 0.35 then break end
            if os.clock() - t0 > 1.8 then break end
        end
        releaseInput()
        if landed == e.y then
            return execWalk(e.x, e.y) -- sudah di lorong atas: ke tengah tile tujuan
        end
        if landed ~= nil and landed ~= e.fy then return false end -- jatuh ke tempat lain
        if not execWalk(e.fx, e.fy) then return false end
    end
    return false
end



local function followPath(path, cancel)
    local i = 1
    while i <= #path do
        if cancel() or not autoOn() then releaseInput(); return false, "cancelled" end
        local e, last = path[i], i
        if e.build or e.kind == "pillar" then return false, "unsupported" end
        local ok
        if e.kind == "walk" then
            local dir = e.x - e.fx
            while path[last + 1] and path[last + 1].kind == "walk" and not path[last + 1].build
                and path[last + 1].y == e.y and path[last + 1].x - path[last + 1].fx == dir do last += 1 end
            ok = execWalk(path[last].x, path[last].y)
        elseif e.kind == "fall" then ok = execFall(e)
        elseif e.kind == "jump" then ok = execJump(e)
        elseif e.kind == "gap" then ok = execGap(e)
        elseif e.kind == "stair" then ok = Move.execStair(e)
        else return false, "unsupported" end
        releaseInput()
        if cancel() then return false, "cancelled" end
        if not ok then
            if e.key then BadEdge[e.key] = os.clock() + 3 end
            return false
        end
        i = last + 1
    end
    return true
end

-- ROCK CROSSING

function Move.Rock.plan(s, dir, cancel)
    local w = Refs.World
    if not w or not s or not s.grounded then return nil, "Berdiri di atas pijakan dulu" end
    local sx, sy = startNode(s)
    local edge, found = sx + dir, false
    for distance = 1, 3 do
        local x = sx + distance * dir
        if x < 0 or x >= w.w then break end
        if not openAt(x, sy) then edge, found = x, true; break end
    end
    if found then
        -- Tujuan harus melewati seluruh lebar batu, bukan berhenti di atasnya.
        while edge + dir >= 0 and edge + dir < w.w and abs(edge + dir - sx) <= 8
            and not openAt(edge + dir, sy) do edge += dir end
    end
    local goals = {}
    for distance = math.max(2, (edge - sx) * dir + 1), 12 do
        local x = sx + distance * dir
        if x >= 0 and x < w.w then
            for y = math.max(0, sy - 3), math.min(w.h - 2, sy + 5) do
                if openAt(x, y) and realSupport(x, y) then
                    goals[#goals + 1] = { x = x, y = y, idx = y * w.w + x,
                        score = abs(y - sy) * 3 + distance }
                end
            end
        end
    end
    table.sort(goals, function(a, b)
        if a.score ~= b.score then return a.score < b.score end
        if a.y ~= b.y then return a.y < b.y end
        return a.idx < b.idx
    end)
    for i = 1, math.min(#goals, 24) do
        if cancel() or Refs.World ~= w then return nil, "Gerakan dibatalkan" end
        local t = goals[i]
        local path = astar(sx, sy, { [t.idx] = true, maxExpand = 1200 }, t.x, t.y, 0.5, false)
        if cancel() or Refs.World ~= w then return nil, "Gerakan dibatalkan" end
        if path and #path > 0 then return path, t, edge end
    end
    return nil, "Belum ada jalur lompat yang bisa dilalui ke sisi itu; coba sisi lain"
end

function Move.Rock.perform(dir, cancel)
    local s = playerState()
    if not s or s.dead then return false, "Karakter belum siap" end
    local path, target, edge = Move.Rock.plan(s, dir, cancel)
    if not path then return false, target end
    if cancel() then return false, "Gerakan dibatalkan" end
    Move.Rock.status(dir > 0 and "Melewati batu ke kanan..." or "Melewati batu ke kiri...")
    local ok, reason = followPath(path, cancel)
    releaseInput()
    if cancel() or reason == "cancelled" then return false, "Gerakan dibatalkan" end
    if not ok then return false, "Belum berhasil melewati batu; coba sisi lain" end
    -- Tunggu pembaruan posisi game agar gerakan yang dikembalikan tidak
    -- dilaporkan berhasil hanya karena controller sempat mencapai tujuan.
    local untilAt = os.clock() + 0.35
    repeat
        task.wait(0.05)
        if cancel() then return false, "Gerakan dibatalkan" end
    until os.clock() >= untilAt
    local cur = playerState()
    if cur and not cur.dead and cur.grounded and (floor(cur.x) - edge) * dir >= 1 then
        return true, ("Sudah lewat ke %s (%d,%d)"):format(dir > 0 and "kanan" or "kiri",
            floor(cur.x), floor(cur.y - 0.475))
    end
    return false, "Posisi belum melewati batu atau dikembalikan game; coba sisi lain"
end



function Rock.cancel()
    if not Rock.Busy then return end
    Rock.Cancelled, Rock.Running = true, false
    AutoInput.active = false
    releaseInput()
    Rock.status("Membatalkan gerakan...")
end
function Rock.start(dir)
    if Rock.Busy or not alive() then return false end
    Rock.Busy, Rock.Cancelled, Rock.Running = true, false, false
    Rock.Token = Rock.Token + 1
    local token = Rock.Token
    Rock.Deadline = os.clock() + 20
    dir = dir == -1 and -1 or 1
    Rock.status("Menghubungkan ke kontrol game...")
    task.spawn(function()
        local function cancelled()
            return not alive() or Rock.Cancelled or Rock.Token ~= token or os.clock() >= Rock.Deadline
        end
        Session.ScanCancel = cancelled
        local ok, passed, message = pcall(function()
            local connected, err = discover(cancelled)
            if cancelled() then return false, "Gerakan dibatalkan" end
            if not connected then return false, err end
            if not AutoInput.bindMenu() then return false, AutoInput.Error or "Kontrol gerak belum terbaca" end
            if cancelled() then return false, "Gerakan dibatalkan" end
            local s = playerState()
            if not s or s.dead then return false, "Karakter belum siap" end
            if not s.grounded then return false, "Berdiri di atas pijakan dulu" end
            Rock.World, Rock.Grid = Refs.World, Refs.World.fg
            Rock.Deadline, Rock.Running = os.clock() + 20, true
            table.clear(BadEdge)
            AutoInput.active = true
            releaseInput()
            local function cancel()
                return cancelled() or not Rock.Running or Refs.World ~= Rock.World
                    or Refs.World.fg ~= Rock.Grid
            end
            return Rock.perform(dir, cancel)
        end)
        if Rock.Token ~= token then return end
        Rock.Busy, Rock.Running, AutoInput.active = false, false, false
        releaseInput()
        AutoInput.unbindMenu()
        Session.Objects, Session.ScanCancel = nil, nil
        if not alive() then return end
        if Rock.Cancelled then message = "Gerakan dibatalkan"
        elseif not ok then message = "Gagal: " .. tostring(passed)
        elseif os.clock() >= Rock.Deadline then message = "Waktu habis; coba arah lain" end
        Rock.status(message or "Selesai")
    end)
    return true
end
function Session.Cleanup()
    Session.Closed = true
    Rock.Cancelled, Rock.Running, AutoInput.active = true, false, false
    releaseInput()
    pcall(AutoInput.unbindMenu)
    for _, connection in ipairs(Session.Connections) do pcall(function() connection:Disconnect() end) end
    if Session.Gui then pcall(function() Session.Gui:Destroy() end) end
    if G.__ZekioRockOnly == Session then G.__ZekioRockOnly = nil end
end
local function listen(signal, fn)
    Session.Connections[#Session.Connections + 1] = signal:Connect(fn)
end
listen(UI.Left.MouseButton1Click, function() Rock.start(-1) end)
listen(UI.Right.MouseButton1Click, function() Rock.start(1) end)
listen(UI.Cancel.MouseButton1Click, Rock.cancel)
listen(UI.Close.MouseButton1Click, Session.Cleanup)
Rock.status("Siap. Berdiri dekat batu lalu pilih kiri atau kanan.")
