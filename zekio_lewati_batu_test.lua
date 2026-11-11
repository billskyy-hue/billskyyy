-- Zekio | Batu TEST r4.1 DIAG | standalone
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
    panel.Size = UDim2.new(0.9, 0, 0, 244)
    panel.BackgroundColor3, panel.BorderSizePixel = Color3.fromRGB(23, 25, 33), 0
    panel.Parent = gui
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)
    local constraint = Instance.new("UISizeConstraint")
    constraint.MaxSize, constraint.Parent = Vector2.new(420, 244), panel
    local title = Instance.new("TextLabel")
    title.Position, title.Size = UDim2.fromOffset(14, 10), UDim2.new(1, -60, 0, 25)
    title.BackgroundTransparency, title.TextXAlignment = 1, Enum.TextXAlignment.Left
    title.Text, title.Font, title.TextSize = "Zekio | Batu TEST r4.1 DIAG", Enum.Font.GothamBold, 17
    title.TextColor3, title.Parent = Color3.fromRGB(245, 245, 250), panel
    local close = Instance.new("TextButton")
    close.Position, close.Size = UDim2.new(1, -42, 0, 9), UDim2.fromOffset(30, 28)
    close.Text, close.TextSize, close.BackgroundTransparency = "X", 17, 1
    close.TextColor3, close.Parent = Color3.fromRGB(220, 220, 230), panel
    local status = Instance.new("TextLabel")
    status.Position, status.Size = UDim2.fromOffset(14, 44), UDim2.new(1, -28, 0, 144)
    status.BackgroundTransparency, status.TextWrapped = 1, true
    status.Font, status.TextSize, status.TextColor3 = Enum.Font.Gotham, 11, Color3.fromRGB(200, 205, 220)
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
function AutoInput.resetTelemetry()
    AutoInput.KeyReads, AutoInput.TrueReturns = {}, {}
    AutoInput.OtherKeys, AutoInput.OtherSeen = {}, {}
end

local function isDownWrapper(...)
    local first, second = ...
    local key = AutoInput.key(first, second)
    if key then
        AutoInput.Reads = (AutoInput.Reads or 0) + 1
        AutoInput.LastRead = os.clock()
        if AutoInput.active then
            if not AutoInput.KeyReads then AutoInput.resetTelemetry() end
            AutoInput.KeyReads[key] = (AutoInput.KeyReads[key] or 0) + 1
            local pressed = AutoInput[key] == true
            if pressed then AutoInput.TrueReturns[key] = (AutoInput.TrueReturns[key] or 0) + 1 end
            return pressed
        end
    elseif AutoInput.active then
        if not AutoInput.OtherKeys then AutoInput.resetTelemetry() end
        local raw = second ~= nil and second or first
        if type(raw) ~= "string" then raw = AutoInput.member(raw, "Name") end
        if type(raw) == "string" and not AutoInput.OtherSeen[raw] and #AutoInput.OtherKeys < 4 then
            AutoInput.OtherSeen[raw] = true
            AutoInput.OtherKeys[#AutoInput.OtherKeys + 1] = raw:sub(1, 24)
        end
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
    AutoInput.resetTelemetry()
    Refs.Input, Refs.InputSource = menu, AutoInput.Source
    return true
end
function AutoInput.status()
    return AutoInput.Error or ((AutoInput.Source or "belum terhubung") .. " | bacaan " .. tostring(AutoInput.Reads or 0))
end
-- Pemindaian penuh dijalankan oleh reconnect setelah jendela utama terbentuk.
Session.UnbindInput = AutoInput.unbindMenu




-- WORLD GEOMETRY

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





-- CROSS, BRAKE ABOVE THE FLOOR, THEN LAND WITH COLLISION RESTORED.
local function autoOn()
    return alive() and Rock.Running and not Rock.Cancelled and Refs.World == Rock.World
        and Refs.World.fg == Rock.Grid and os.clock() < Rock.Deadline
end

-- Experimental backend: player attribute, independent of the world table flag.
local function readPlayerGhost()
    return LocalPlayer:GetAttribute("Ghost")
end

function Rock.enablePhase()
    local ok, previous = pcall(readPlayerGhost)
    if not ok then return false, "Atribut Ghost pemain belum dapat dibaca: " .. tostring(previous) end
    Rock.GhostPrevious, Rock.GhostSaved = previous, true
    Rock.RestoreError = nil
    if Rock.Diagnostic then Rock.Diagnostic.GhostBefore = tostring(previous) end
    local enabled, err = pcall(function() LocalPlayer:SetAttribute("Ghost", true) end)
    if not enabled then return false, "Atribut Ghost pemain gagal diaktifkan: " .. tostring(err) end
    local verified, value = pcall(readPlayerGhost)
    if Rock.Diagnostic then Rock.Diagnostic.GhostDuring = verified and tostring(value) or "tidak terbaca" end
    if not verified or value ~= true then
        return false, "Atribut Ghost tidak tetap aktif setelah dipasang"
    end
    return true, previous
end

function Rock.checkPhase()
    local ok, value = pcall(readPlayerGhost)
    if Rock.Diagnostic then Rock.Diagnostic.GhostDuring = ok and tostring(value) or "tidak terbaca" end
    if not ok then return false, "Atribut Ghost tidak dapat dibaca saat bergerak" end
    if value ~= true then return false, "Atribut Ghost dinonaktifkan saat bergerak; percobaan dihentikan" end
    return true
end

function Rock.restorePhase()
    if not Rock.GhostSaved then return true end
    local previous = Rock.GhostPrevious
    local ok, err = pcall(function()
        -- Preserve a new value supplied by the game or another controller.
        if readPlayerGhost() == true then LocalPlayer:SetAttribute("Ghost", previous) end
    end)
    if ok then
        Rock.GhostSaved, Rock.GhostPrevious = nil, nil
        Rock.RestoreError = nil
    else
        Rock.RestoreError = tostring(err)
    end
    return ok
end

-- Coordinates describe the feet, not the centre of the player. Inspect the
-- whole 0.6 x 0.95 body so collision is never restored with feet in a block.
local function bodyClear(x, feet)
    for bx = floor(x - 0.3 + 0.0001), floor(x + 0.3 - 0.0001) do
        for by = floor(feet - 0.95 + 0.0001), floor(feet - 0.0001) do
            if not openAt(bx, by) then return false end
        end
    end
    return true
end

local function supported(x, row)
    for bx = floor(x - 0.3 + 0.0001), floor(x + 0.3 - 0.0001) do
        if not realSupport(bx, row) then return false end
    end
    return true
end

function Rock.phaseTarget(s, dir)
    local w = Refs.World
    local sx, sy = floor(s.x), floor(s.y - 0.475)
    local edge, found = sx, false
    for distance = 1, 3 do
        local x = sx + distance * dir
        if x < 0 or x >= w.w then break end
        if solidAt(x, sy) then edge, found = x, true; break end
    end
    if found then
        while edge + dir >= 0 and edge + dir < w.w and abs(edge + dir - sx) <= 8
            and solidAt(edge + dir, sy) do edge += dir end
    end
    local best, bestScore
    for distance = math.max(2, (edge - sx) * dir + 1), 12 do
        local x = sx + distance * dir
        if x >= 0 and x < w.w then
            for y = math.max(0, sy - 3), math.min(w.h - 2, sy + 5) do
                -- Hover 0.35 tile above the floor, leaving room to coast without
                -- entering the support. Normal gravity completes the landing.
                if bodyClear(x + 0.5, y + 0.65) and supported(x + 0.5, y) then
                    local score = abs(y - sy) * 5 + distance
                    if not bestScore or score < bestScore then
                        best, bestScore = { x = x, y = y }, score
                    end
                end
            end
        end
    end
    if not best then return nil, "Tidak ada tempat mendarat kosong di sisi itu" end
    return best, edge
end

local function axisInput(delta, velocity, tolerance, dt)
    if abs(delta) <= tolerance then return 0 end
    local dir = delta > 0 and 1 or -1
    local stopDistance = velocity * velocity / 34 + abs(velocity) * dt
    if velocity * dir > 0 and stopDistance >= abs(delta) - tolerance * 0.5 then return 0 end
    return dir
end

function Rock.captureDiagnostic()
    local d = Rock.Diagnostic
    if not d then return end
    d.InputSource = AutoInput.Source or d.InputSource or "belum terhubung"
    d.KeyReads, d.TrueReturns = {}, {}
    for _, key in ipairs({ "left", "right", "jump", "down" }) do
        d.KeyReads[key] = (AutoInput.KeyReads and AutoInput.KeyReads[key]) or 0
        d.TrueReturns[key] = (AutoInput.TrueReturns and AutoInput.TrueReturns[key]) or 0
    end
    d.OtherKeys = table.concat(AutoInput.OtherKeys or {}, ", ")
    d.InputCaptured = true
    Session.LastDiagnostic = d
end

function Rock.report(message)
    local d = Rock.Diagnostic
    if not d then return message end
    local s = playerState()
    local current = s and ("(%.2f,%.2f)"):format(s.x, s.y) or "tidak terbaca"
    local ok, value = pcall(readPlayerGhost)
    local attribute = ok and tostring(value) or "tidak terbaca"
    local reads = d.InputCaptured and d.KeyReads or AutoInput.KeyReads or {}
    local returns = d.InputCaptured and d.TrueReturns or AutoInput.TrueReturns or {}
    local function count(key) return tostring(reads[key] or 0) .. "/" .. tostring(returns[key] or 0) end
    local other = d.InputCaptured and d.OtherKeys or table.concat(AutoInput.OtherKeys or {}, ", ")
    return tostring(message) .. ("\nAwal (%.1f,%.1f) > tujuan (%d,%d) | maju maks %.2f"):format(d.x, d.y, d.tx, d.ty, d.Furthest or 0)
        .. "\nPosisi " .. current .. " | " .. tostring(d.stage or "-")
        .. "\nInput: " .. tostring(d.InputSource or AutoInput.Source or "belum terhubung"):sub(1, 50)
        .. "\nBaca/aktif: Ki " .. count("left") .. " Ka " .. count("right")
        .. " J " .. count("jump") .. " D " .. count("down")
        .. "\nGhost gerak: " .. tostring(d.GhostDuring or "belum aktif")
        .. (d.InputCaptured and " | sesudah: " or " | kini: ") .. attribute
        .. " | world: " .. tostring(Refs.World and Refs.World.ghost)
        .. (other ~= "" and ("\nTombol lain: " .. other) or "")
end

function Rock.perform(dir, cancel)
    local w, s = Refs.World, playerState()
    if not s or s.dead then return false, "Karakter belum siap" end
    local target, edge = Rock.phaseTarget(s, dir)
    if not target then return false, edge end
    if cancel() then return false, "Gerakan dibatalkan" end
    local d = { x = s.x, y = s.y, tx = target.x, ty = target.y, stage = "mencoba bergerak" }
    Rock.Diagnostic = d
    local enabled, previousGhost = Rock.enablePhase()
    if not enabled then return false, previousGhost end
    local cx, hoverY, floorY = target.x + 0.5, target.y + 0.65, target.y + 1
    local sample = { x = s.x, y = s.y, t = os.clock() }
    local function velocity(cur)
        local now = os.clock()
        local dt = math.max(0.001, now - sample.t)
        local vx, vy = tonumber(cur.vx) or 0, tonumber(cur.vy) or 0
        if now > sample.t then vx, vy = (cur.x - sample.x) / dt, (cur.y - sample.y) / dt end
        local previousX = sample.x
        sample = { x = cur.x, y = cur.y, t = now }
        return vx, vy, math.min(dt, 0.15), previousX
    end
    local bestDistance = abs(cx - s.x) + abs(hoverY - s.y)
    local progressAt, settledAt, nearAt, lastStatus = os.clock(), nil, nil, 0
    local reached, furthest = false, 0
    while autoOn() and not cancel() do
        local phaseOK, phaseError = Rock.checkPhase()
        if not phaseOK then return false, phaseError end
        local cur = playerState()
        if not cur or cur.dead then return false, "Karakter tidak siap saat tembus" end
        local vx, vy, dt, previousX = velocity(cur)
        local projection = (cur.x - d.x) * dir
        if furthest > 1 and (previousX - cur.x) * dir > 1.2 then
            return false, "Posisi dikembalikan game saat mencoba tembus"
        end
        furthest = math.max(furthest, projection)
        d.Furthest = furthest
        local dx, dy = cx - cur.x, hoverY - cur.y
        local distance = abs(dx) + abs(dy)
        if distance < bestDistance - 0.04 then bestDistance, progressAt = distance, os.clock() end
        if distance < 0.8 and not nearAt then nearAt = os.clock() end
        local ready = abs(dx) <= 0.17 and abs(dy) <= 0.13 and abs(vx) <= 0.45 and abs(vy) <= 0.45
            and floorY - cur.y >= 0.1 and bodyClear(cur.x, cur.y) and supported(cur.x, target.y)
        if ready then
            releaseInput()
            settledAt = settledAt or os.clock()
            if os.clock() - settledAt >= 0.25 then reached = true; break end
        else
            settledAt = nil
            local horizontal = axisInput(dx, vx, 0.15, dt)
            local vertical = axisInput(dy, vy, 0.11, dt)
            AutoInput.left, AutoInput.right = horizontal < 0, horizontal > 0
            AutoInput.jump, AutoInput.down = vertical < 0, vertical > 0
        end
        if (not nearAt and os.clock() - progressAt > 2.5) or (nearAt and os.clock() - nearAt > 5) then
            if (AutoInput.Reads or 0) == 0 then
                if AutoInput.OtherKeys and #AutoInput.OtherKeys > 0 then
                    return false, "Pembaca dipanggil, tetapi nama tombol belum dikenali"
                end
                return false, "Kontrol terpasang tetapi belum dibaca game"
            end
            if not nearAt then
                local key = dir < 0 and "left" or "right"
                if ((AutoInput.TrueReturns and AutoInput.TrueReturns[key]) or 0) == 0 then
                    return false, "Bacaan kontrol ada, tetapi perintah arah belum dikonfirmasi"
                end
            end
            return false, nearAt and "Belum bisa berhenti di atas pijakan; gerakan dihentikan"
                or "Input arah terbaca, tetapi posisi belum maju melewati batu"
        end
        d.stage = nearAt and "mengerem sebelum mendarat" or "mencoba bergerak"
        if os.clock() - lastStatus > 0.25 then
            Rock.status(Rock.report(dir > 0 and "Bergerak ke kanan..." or "Bergerak ke kiri..."))
            lastStatus = os.clock()
        end
        task.wait()
    end
    releaseInput()
    if cancel() then return false, "Gerakan dibatalkan" end
    if not reached then return false, "Tujuan tembus belum tercapai" end
    if not Rock.restorePhase() then return false, "Mode tembus belum dapat dipulihkan: " .. Rock.RestoreError end
    d.stage = previousGhost == true and "memeriksa posisi terbang" or "mendarat"
    Rock.status(Rock.report("Memeriksa posisi akhir..."))
    local untilAt, landedAt = os.clock() + 3, nil
    local maxXDrift = 0
    repeat
        task.wait()
        if cancel() then return false, "Gerakan dibatalkan" end
        local cur = playerState()
        if not cur or cur.dead then return false, "Karakter tidak siap setelah tembus" end
        local vx, vy, dt = velocity(cur)
        if (floor(cur.x) - edge) * dir < 1 then
            return false, "Posisi kembali ke sisi awal setelah atribut Ghost dipulihkan"
        end
        if not bodyClear(cur.x, cur.y) then return false, "Karakter menyentuh block saat mendarat" end
        if cur.y > floorY + 0.2 then return false, "Pijakan terlewati saat mendarat; posisi belum aman" end
        maxXDrift = math.max(maxXDrift, abs(cur.x - cx))
        if maxXDrift > 0.7 then return false, "Posisi bergeser terlalu jauh setelah atribut Ghost dipulihkan" end
        local horizontal = axisInput(cx - cur.x, vx, 0.15, dt)
        AutoInput.left, AutoInput.right = horizontal < 0, horizontal > 0
        AutoInput.jump, AutoInput.down = false, false
        local onFloor = cur.grounded == true and abs(cur.y - floorY) <= 0.15
        local stable = abs(cur.x - cx) <= 0.18 and abs(vx) <= 0.45 and abs(vy) <= 0.45
            and supported(cur.x, target.y) and (onFloor or (previousGhost == true and abs(cur.y - hoverY) <= 0.15))
        if stable then
            releaseInput()
            landedAt = landedAt or os.clock()
            if os.clock() - landedAt >= 1.2 then
                d.stage = previousGhost == true and "mode terbang awal tetap aktif" or "sudah berpijak"
                return true, ("Sudah tembus ke %s (%d,%d)"):format(dir > 0 and "kanan" or "kiri",
                    floor(cur.x), floor(cur.y - 0.475))
            end
        else landedAt = nil end
    until os.clock() >= untilAt
    return false, "Posisi belum menetap di pijakan; gerakan dihentikan"
end

function Rock.cancel()
    if not Rock.Busy then return end
    Rock.Cancelled, Rock.Running = true, false
    AutoInput.active = false
    releaseInput()
    Rock.restorePhase()
    Rock.status("Membatalkan gerakan...")
end
function Rock.start(dir)
    if Rock.Busy or not alive() then return false end
    Rock.Diagnostic, Rock.RestoreError = nil, nil
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
            Rock.World, Rock.Grid = Refs.World, Refs.World.fg
            Rock.Deadline, Rock.Running = os.clock() + 20, true
            AutoInput.active = true
            releaseInput()
            local function cancel()
                return cancelled() or not Rock.Running or Refs.World ~= Rock.World
                    or Refs.World.fg ~= Rock.Grid
            end
            return Rock.perform(dir, cancel)
        end)
        if Rock.Token ~= token then return end
        Rock.captureDiagnostic()
        Rock.Busy, Rock.Running, AutoInput.active = false, false, false
        releaseInput()
        Rock.restorePhase()
        AutoInput.unbindMenu()
        Session.Objects, Session.ScanCancel = nil, nil
        if not alive() then return end
        if Rock.Cancelled then message = "Gerakan dibatalkan"
        elseif not ok then message = "Gagal: " .. tostring(passed)
        elseif os.clock() >= Rock.Deadline then message = "Waktu habis; coba arah lain" end
        if Rock.RestoreError then message = tostring(message or "Selesai") .. " | pemulihan: " .. Rock.RestoreError end
        Session.LastReport = Rock.report(message or "Selesai")
        Rock.status(Session.LastReport)
    end)
    return true
end
function Session.Cleanup()
    Session.Closed = true
    Rock.Cancelled, Rock.Running, AutoInput.active = true, false, false
    releaseInput()
    pcall(Rock.restorePhase)
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
Rock.status("r4.1 DIAG: pilih kiri/kanan. Baca/aktif = jumlah tombol dibaca / aktif. Ki=kiri, Ka=kanan, J=lompat, D=turun.")
