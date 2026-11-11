-- Zekio | Terbang TEST r1 | standalone Growblox client experiment
local G = (getgenv and getgenv()) or _G
for _, name in ipairs({ "__ZekioFlyOnly", "__ZekioRockOnly" }) do
    local previous = G[name]
    if previous and type(previous.Cleanup) == "function" then
        local ok, result = pcall(previous.Cleanup)
        assert(ok and result ~= false, "Kontrol lama belum dapat dilepas; tutup panel lama dahulu")
    end
end
local Session = { Connections = {} }
G.__ZekioFlyOnly = Session
local function alive() return G.__ZekioFlyOnly == Session and not Session.Closed end
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
assert(LocalPlayer, "Masuk game terlebih dahulu")
local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 15)
assert(PlayerGui, "PlayerGui belum tersedia; masuk world lalu execute ulang")
local Refs, UI = {}, {}
local AutoInput = { active = false, left = false, right = false, jump = false, down = false }
local Fly = { Active = false, Busy = false, Token = 0, Pointers = {}, Moved = false }
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
local function listen(signal, fn)
    if not signal then return end
    local ok, connection = pcall(function() return signal:Connect(fn) end)
    if ok and connection then Session.Connections[#Session.Connections + 1] = connection end
end
local function status(message)
    Session.Status = tostring(message or "")
    if alive() and UI.Status then UI.Status.Text = Session.Status end
end

local function gameFunction(fn)
    if type(fn) ~= "function" then return false end
    if type(isexecutorclosure) == "function" then
        local ok, own = pcall(isexecutorclosure, fn)
        if ok and own then return false end
    end
    return true
end
local function discover(cancel)
    local queue, seen, cursor = {}, {}, 1
    local worldScore, stateScore = -1, -1
    Refs.World, Refs.State, Refs.StateOwner, Refs.Menu = nil, nil, nil, nil
    local function push(value, depth, score)
        local kind = type(value)
        if (kind ~= "table" and kind ~= "function") or seen[value] or #queue >= 3000 then return end
        if value == G or value == _G or value == Session or value == UI or value == Refs
            or value == AutoInput or value == Fly then return end
        if kind == "function" and not gameFunction(value) then return end
        seen[value] = true
        queue[#queue + 1] = { value = value, depth = depth, score = score }
    end
    local function consider(value, score)
        if type(value) ~= "table" or value == G or value == _G or value == Session or value == Refs then return end
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
            if Refs.World and Refs.State then break end
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
            if depth < 5 then
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
    if cancel() then return false, "Dibatalkan" end
    if not Refs.World then return false, "Data world belum terbaca. Masuk world lalu coba lagi." end
    if not Refs.State then return false, "Posisi karakter belum terbaca oleh executor." end
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
    local original = OrigIsDown and OrigIsDown(...) or false
    if key then
        AutoInput.Reads = (AutoInput.Reads or 0) + 1
        AutoInput.LastRead = os.clock()
        if AutoInput.active then
            if not AutoInput.KeyReads then AutoInput.resetTelemetry() end
            AutoInput.KeyReads[key] = (AutoInput.KeyReads[key] or 0) + 1
            local result = Fly.resolve(key, original)
            if result then AutoInput.TrueReturns[key] = (AutoInput.TrueReturns[key] or 0) + 1 end
            return result
        end
    end
    return original
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
            or value == Refs or value == Fly or value == Session then return end
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
    elseif menu and key then
        if rawget(menu, key) == isDownWrapper then
            local restored = pcall(rawset, menu, key, AutoInput.OwnValue)
            if not restored or rawget(menu, key) ~= AutoInput.OwnValue then
                AutoInput.active = false
                AutoInput.Error = "Pembaca tombol belum dapat dipulihkan; kontrol manual dipertahankan"
                return false
            end
        elseif AutoInput.member(menu, key) ~= AutoInput.Function then
            -- A later wrapper may still call ours. Keep its original delegate
            -- intact instead of breaking the other owner's manual input.
            AutoInput.active = false
            AutoInput.Error = "Pembaca tombol sudah berubah; kontrol manual dipertahankan"
            return false
        end
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






-- A custom held direction owns its axis; otherwise native game input is used.
function Fly.resolve(key, original)
    local first, second
    if key == "left" or key == "right" then first, second = AutoInput.left, AutoInput.right
    else first, second = AutoInput.jump, AutoInput.down end
    if first or second then
        if first and second then return false end
        if key == "left" or key == "jump" then return first == true end
        return second == true
    end
    return original
end

local function readState()
    if not Refs.State then return nil end
    local ok, state = pcall(Refs.State)
    if ok and type(state) == "table" and type(state.x) == "number" and type(state.y) == "number" then return state end
end
local function clearHeld()
    Fly.Pointers = {}
    AutoInput.left, AutoInput.right, AutoInput.jump, AutoInput.down = false, false, false, false
end
local function updateButtons()
    if UI.Toggle then UI.Toggle.Text = Fly.Busy and "BATALKAN" or (Fly.Active and "MATIKAN TERBANG" or "AKTIFKAN TERBANG") end
    for _, button in pairs(UI.Directions or {}) do
        button.BackgroundColor3 = Fly.Active and Color3.fromRGB(76, 58, 135) or Color3.fromRGB(52, 50, 66)
    end
end
local function capture()
    local s = readState()
    Session.LastDiagnostic = {
        Active = Fly.Active, Moved = Fly.Moved, Input = AutoInput.Source,
        x = s and s.x, y = s and s.y, Reads = AutoInput.Reads or 0,
        KeyReads = {}, TrueReturns = {},
    }
    for _, key in ipairs({ "left", "right", "jump", "down" }) do
        Session.LastDiagnostic.KeyReads[key] = (AutoInput.KeyReads and AutoInput.KeyReads[key]) or 0
        Session.LastDiagnostic.TrueReturns[key] = (AutoInput.TrueReturns and AutoInput.TrueReturns[key]) or 0
    end
end
local function restoreWorldMode()
    if not Fly.Saved then return true end
    local w, previous = Fly.World, Fly.PreviousGhost
    local ok, err = pcall(function()
        -- Do not replace a new value supplied by the game or another controller.
        if rawget(w, "ghost") == true then w.ghost = previous end
    end)
    if not ok then Fly.RestoreError = tostring(err); return false end
    Fly.Saved, Fly.PreviousGhost, Fly.RestoreError = false, nil, nil
    return true
end
function Fly.stop(message)
    Fly.Token = Fly.Token + 1
    capture()
    Fly.Active, Fly.Busy, AutoInput.active = false, false, false
    clearHeld()
    local restored = restoreWorldMode()
    local unbound, result = pcall(AutoInput.unbindMenu)
    Session.Objects, Session.ScanCancel = nil, nil
    updateButtons()
    if not restored then
        status("Kontrol dilepas; mode lokal belum dapat dipulihkan: " .. tostring(Fly.RestoreError))
        return false
    end
    if not unbound or result == false then
        status("Terbang nonaktif; pembaca tombol belum dapat dipulihkan. Tekan X untuk mencoba lagi.")
        return false
    end
    Fly.World, Fly.Grid = nil, nil
    status(message or "Terbang nonaktif. Kontrol sudah dilepas.")
    return true
end

function Fly.report()
    local s = readState()
    local position = s and ("(%.2f, %.2f)"):format(s.x, s.y) or "belum terbaca"
    local reads = AutoInput.TrueReturns or {}
    return (Fly.Moved and "Mode lokal aktif; perubahan posisi terdeteksi." or "Mode lokal aktif; gerakan belum terkonfirmasi.")
        .. "\nPosisi: " .. position .. " | mode world: " .. tostring(Fly.World and Fly.World.ghost)
        .. "\nInput aktif Ki/Ka/Naik/Turun: " .. tostring(reads.left or 0) .. "/" .. tostring(reads.right or 0)
        .. "/" .. tostring(reads.jump or 0) .. "/" .. tostring(reads.down or 0)
        .. "\nTahan arah di panel atau gunakan tombol game."
end

function Fly.start()
    if Fly.Active or Fly.Busy or Fly.Saved or not alive() then return false end
    Fly.Token = Fly.Token + 1
    local token, deadline = Fly.Token, os.clock() + 15
    Fly.Busy, Fly.Moved = true, false
    clearHeld()
    status("Menghubungkan kontrol terbang...")
    updateButtons()
    local function cancelled()
        return not alive() or Fly.Token ~= token or os.clock() >= deadline
    end
    Session.ScanCancel = cancelled
    task.spawn(function()
        local ok, connected, reason = pcall(function()
            local found, err = discover(cancelled)
            if cancelled() then return false, "Penghubungan dibatalkan atau waktu habis." end
            if not found then return false, err end
            if not AutoInput.bindMenu() then return false, AutoInput.Error or "Kontrol gerak belum terbaca." end
            if cancelled() then return false, "Penghubungan dibatalkan atau waktu habis." end
            local state = readState()
            if not state or state.dead or state.active == false then return false, "Karakter belum siap." end
            Fly.World, Fly.Grid = Refs.World, Refs.World.fg
            Fly.PreviousGhost, Fly.Saved = rawget(Fly.World, "ghost"), true
            local written, writeError = pcall(function() Fly.World.ghost = true end)
            if not written then return false, "Mode world tidak bisa dipasang: " .. tostring(writeError) end
            if Fly.World.ghost ~= true then return false, "Mode world tidak bertahan aktif." end
            Fly.Active, Fly.Busy, AutoInput.active = true, false, true
            Fly.StartX, Fly.StartY, Fly.WorldName = state.x, state.y, Fly.World.name
            Fly.LastX, Fly.LastY = state.x, state.y
            Session.Objects, Session.ScanCancel = nil, nil
            updateButtons()
            status(Fly.report())
            return true
        end)
        if Fly.Token ~= token then return end
        if not ok or not connected then
            Fly.stop("Tidak aktif: " .. tostring(ok and reason or connected))
            return
        end
        while alive() and Fly.Active and Fly.Token == token do
            task.wait(0.1)
            if not alive() or not Fly.Active or Fly.Token ~= token then return end
            local monitored, monitorError = pcall(function()
                if Refs.World ~= Fly.World or Fly.World.fg ~= Fly.Grid or Fly.World.name ~= Fly.WorldName then
                    Fly.stop("Terbang nonaktif: data world berubah."); return
                end
                if Fly.World.ghost ~= true then
                    Fly.stop("Terbang nonaktif: mode lokal berubah oleh game."); return
                end
                if AutoInput.Menu and AutoInput.member(AutoInput.Menu, AutoInput.Key) ~= (AutoInput.Hooked and AutoInput.Function or isDownWrapper) then
                    Fly.stop("Terbang nonaktif: kontrol dipakai pembaca lain."); return
                end
                local state = readState()
                if not state or state.dead or state.active == false then
                    Fly.stop("Terbang nonaktif: karakter tidak siap."); return
                end
                if math.abs(state.x - Fly.StartX) > 0.08 or math.abs(state.y - Fly.StartY) > 0.08 then Fly.Moved = true end
                Fly.LastX, Fly.LastY = state.x, state.y
                status(Fly.report())
            end)
            if not monitored then Fly.stop("Terbang dihentikan: " .. tostring(monitorError)); return end
        end
    end)
    return true
end

-- Small touch panel; no target coordinate or automatic movement loop.
do
    local gui = Instance.new("ScreenGui")
    gui.Name, gui.ResetOnSpawn, gui.IgnoreGuiInset, gui.DisplayOrder = "ZekioFlyOnly", false, true, 1501
    local parent = PlayerGui
    if type(gethui) == "function" then
        local ok, value = pcall(gethui)
        if ok and value then parent = value end
    end
    local ok = pcall(function() gui.Parent = parent end)
    if not ok then gui.Parent = PlayerGui end
    Session.Gui = gui
    local panel = Instance.new("Frame")
    panel.AnchorPoint, panel.Position = Vector2.new(0, 0), UDim2.fromOffset(12, 72)
    panel.Size, panel.BackgroundColor3, panel.BorderSizePixel = UDim2.new(0.90, 0, 0, 238), Color3.fromRGB(23, 22, 32), 0
    panel.Parent = gui
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)
    local constraint = Instance.new("UISizeConstraint")
    constraint.MaxSize, constraint.Parent = Vector2.new(360, 238), panel
    local title = Instance.new("TextLabel")
    title.Position, title.Size = UDim2.fromOffset(14, 10), UDim2.new(1, -60, 0, 25)
    title.BackgroundTransparency, title.TextXAlignment = 1, Enum.TextXAlignment.Left
    title.Text, title.Font, title.TextSize = "Zekio | Terbang TEST r1", Enum.Font.GothamBold, 17
    title.TextColor3, title.Parent = Color3.fromRGB(245, 242, 252), panel
    local close = Instance.new("TextButton")
    close.Position, close.Size = UDim2.new(1, -42, 0, 9), UDim2.fromOffset(30, 28)
    close.Text, close.TextSize, close.BackgroundTransparency = "X", 17, 1
    close.TextColor3, close.Parent = Color3.fromRGB(222, 215, 235), panel
    UI.Close = close
    local label = Instance.new("TextLabel")
    label.Position, label.Size = UDim2.fromOffset(14, 43), UDim2.new(1, -28, 0, 80)
    label.BackgroundTransparency, label.TextWrapped = 1, true
    label.Font, label.TextSize, label.TextColor3 = Enum.Font.Gotham, 11, Color3.fromRGB(205, 199, 220)
    label.TextXAlignment, label.TextYAlignment = Enum.TextXAlignment.Left, Enum.TextYAlignment.Top
    label.Text, label.Parent = "Terbang nonaktif.", panel
    UI.Status = label
    local function makeButton(text, position, size, color)
        local b = Instance.new("TextButton")
        b.Text, b.Position, b.Size = text, position, size
        b.BackgroundColor3, b.BorderSizePixel = color, 0
        b.Font, b.TextSize, b.TextColor3 = Enum.Font.GothamBold, 13, Color3.new(1, 1, 1)
        b.Parent = panel
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
        return b
    end
    UI.Toggle = makeButton("AKTIFKAN TERBANG", UDim2.new(0, 14, 0, 125), UDim2.new(1, -28, 0, 40), Color3.fromRGB(120, 78, 199))
    UI.Directions = {}
    for index, entry in ipairs({ {"Kiri", "left"}, {"Naik", "jump"}, {"Turun", "down"}, {"Kanan", "right"} }) do
        UI.Directions[entry[2]] = makeButton(entry[1], UDim2.new((index - 1) / 4, 12, 0, 179), UDim2.new(0.25, -16, 0, 44), Color3.fromRGB(52, 50, 66))
    end
end

local function pointerType(input)
    local ok, kind = pcall(function() return input.UserInputType end)
    return ok and kind or nil
end
local function refreshHeld()
    AutoInput.left, AutoInput.right, AutoInput.jump, AutoInput.down = false, false, false, false
    for _, entry in pairs(Fly.Pointers) do AutoInput[entry.key] = true end
end
local function releasePointer(input)
    if Fly.Pointers[input] then Fly.Pointers[input] = nil
    elseif pointerType(input) == Enum.UserInputType.MouseButton1 then
        for pointer, entry in pairs(Fly.Pointers) do
            if entry.kind == Enum.UserInputType.MouseButton1 then Fly.Pointers[pointer] = nil end
        end
    end
    refreshHeld()
end
for key, button in pairs(UI.Directions) do
    local direction = key
    listen(button.InputBegan, function(input)
        if not alive() or not Fly.Active then return end
        local kind = pointerType(input)
        if kind ~= Enum.UserInputType.Touch and kind ~= Enum.UserInputType.MouseButton1 then return end
        Fly.Pointers[input] = { key = direction, kind = kind }
        refreshHeld()
    end)
    listen(button.InputEnded, releasePointer)
end
listen(UserInputService.InputEnded, releasePointer)
listen(AutoInput.member(UserInputService, "WindowFocusReleased"), clearHeld)
listen(UI.Toggle.MouseButton1Click, function()
    if Fly.Active or Fly.Busy or Fly.Saved then Fly.stop()
    else Fly.start() end
end)
function Session.Cleanup()
    if not Fly.stop() then return false end
    Session.Closed = true
    for _, connection in ipairs(Session.Connections) do pcall(function() connection:Disconnect() end) end
    if Session.Gui then pcall(function() Session.Gui:Destroy() end) end
    if G.__ZekioFlyOnly == Session then G.__ZekioFlyOnly = nil end
    return true
end
listen(UI.Close.MouseButton1Click, Session.Cleanup)
status("Terbang nonaktif. Aktifkan lalu tahan arah. Tombol game tetap bisa dipakai.\nMatikan setelah berada di tempat kosong.")
