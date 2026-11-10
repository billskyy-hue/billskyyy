-- ANCH Hub GrowBlox V1.3: startup compatibility build for Delta.
-- Original feature bodies are retained; this wrapper handles loading and UI failures.
local Boot = {
    SourceUrl = "https://raw.githubusercontent.com/billskyy-hue/billskyyy/main/anchhub_delta.lua",
    WindUrl = "https://raw.githubusercontent.com/Footagesus/WindUI/d2c9bac5f96f997418d680d19cb759892542e492/dist/main.lua",
    WindRevision = "d21ff4f2309cb337ca34affcae8755c373985731",
    Stage = "Menyiapkan ANCH Hub",
    UiErrors = {},
}

function Boot.Trace(message)
    if debug and type(debug.traceback) == "function" then
        local ok, result = pcall(debug.traceback, tostring(message), 2)
        if ok then return result end
    end
    return tostring(message)
end

function Boot.Clone(instance)
    local copy = cloneref or clonereference
    if type(copy) == "function" then
        local ok, result = pcall(copy, instance)
        if ok and result then return result end
    end
    return instance
end

function Boot.Await(callback, seconds)
    local complete, result = false, nil
    local thread = task.spawn(function()
        result = table.pack(pcall(callback))
        complete = true
    end)
    local deadline = os.clock() + (seconds or 15)
    while not complete and os.clock() < deadline do task.wait(0.05) end
    if not complete then
        if task.cancel and thread then pcall(task.cancel, thread) end
        return false, "Waktu tunggu habis pada: " .. Boot.Stage
    end
    return table.unpack(result, 1, result.n)
end

function Boot.Service(name, optional)
    local ok, service = pcall(game.GetService, game, name)
    if ok and service then return Boot.Clone(service) end
    if optional then return nil end
    error("Service Roblox tidak tersedia: " .. tostring(name), 0)
end

function Boot.Assign(target, key, value)
    if type(target) ~= "table" then return false end
    return pcall(rawset, target, key, value)
end

function Boot.Require(module)
    if not module then error("Modul game belum tersedia", 0) end
    local ok, value = Boot.Await(function() return require(module) end, 8)
    if not ok then error(value, 0) end
    return value
end

function Boot.SetStatus(text)
    Boot.Stage = text
    if Boot.StatusLabel then pcall(function() Boot.StatusLabel.Text = "ANCH Hub • " .. text end) end
end

function Boot.New(class, values, parent)
    local object = Instance.new(class)
    for key, value in pairs(values) do object[key] = value end
    object.Parent = parent
    return object
end

function Boot.ResolveGuiParent()
    local candidates = {}
    if type(gethui) == "function" then
        local ok, parent = pcall(gethui)
        if ok and parent then table.insert(candidates, parent) end
    end
    local core = Boot.Service("CoreGui", true)
    if core then table.insert(candidates, core) end
    table.insert(candidates, Boot.PlayerGui)
    for _, candidate in ipairs(candidates) do
        local probe
        local ok = pcall(function()
            probe = Instance.new("ScreenGui")
            probe.Parent = candidate
        end)
        if probe then pcall(function() probe:Destroy() end) end
        if ok then return candidate end
    end
    error("Tidak dapat memasang antarmuka pada sesi Roblox ini", 0)
end

function Boot.Prepare()
    local ok, env = pcall(function() return getgenv and getgenv() end)
    Boot.Env = ok and type(env) == "table" and env or _G
    local players = Boot.Service("Players")
    local deadline = os.clock() + 30
    while not players.LocalPlayer and os.clock() < deadline do task.wait(0.1) end
    Boot.Player = assert(players.LocalPlayer, "LocalPlayer belum tersedia")
    Boot.PlayerGui = Boot.Player:FindFirstChildOfClass("PlayerGui") or Boot.Player:WaitForChild("PlayerGui", 30)
    assert(Boot.PlayerGui, "PlayerGui belum tersedia")
    Boot.GuiParent = Boot.ResolveGuiParent()
    local old = Boot.GuiParent:FindFirstChild("ANCHHubLoading")
    if old then old:Destroy() end
    Boot.StatusGui = Boot.New("ScreenGui", {
        Name = "ANCHHubLoading", ResetOnSpawn = false, IgnoreGuiInset = true,
        DisplayOrder = 1000100, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, Boot.GuiParent)
    Boot.StatusLabel = Boot.New("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 70),
        Size = UDim2.new(0.86, 0, 0, 38), BorderSizePixel = 0,
        BackgroundColor3 = Color3.fromRGB(24, 27, 36), TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamMedium, TextSize = 14, TextWrapped = true,
        Text = "ANCH Hub • Menunggu game siap",
    }, Boot.StatusGui)
    Boot.New("UICorner", {CornerRadius = UDim.new(0, 9)}, Boot.StatusLabel)
    deadline = os.clock() + 45
    while not game:IsLoaded() and os.clock() < deadline do task.wait(0.1) end
    assert(game:IsLoaded(), "Game belum selesai dimuat")
end

function Boot.HttpGet(url)
    local ok, body = Boot.Await(function() return game:HttpGet(url) end, 18)
    if ok and type(body) == "string" and #body > 0 then return body end
    local requestFn = (syn and syn.request) or (http and http.request) or http_request or request
    if type(requestFn) == "function" then
        local requested, response = Boot.Await(function()
            return requestFn({Url = url, Method = "GET"})
        end, 18)
        if requested and type(response) == "table" then
            local code = tonumber(response.StatusCode or response.Status) or 200
            if code >= 200 and code < 300 and type(response.Body) == "string" then return response.Body end
        end
    end
    error("Unduhan WindUI gagal. " .. tostring(body), 0)
end

function Boot.UiEnvironment()
    local base = getfenv and getfenv(0) or Boot.Env
    local environment = setmetatable({}, {__index = base})
    environment.gethui = function() return Boot.GuiParent end
    environment.protectgui = function(gui)
        if type(protectgui) == "function" then pcall(protectgui, gui) end
    end
    if type(isfolder) ~= "function" then environment.isfolder = function() return false end end
    if type(makefolder) ~= "function" then environment.makefolder = function() end end
    return environment
end

function Boot.BringUiToFront(ui)
    if type(ui.SetParent) == "function" then pcall(ui.SetParent, ui, Boot.GuiParent) end
    for index, key in ipairs({"ScreenGui", "NotificationGui", "DropdownGui", "TooltipGui"}) do
        local gui = ui[key]
        if gui then pcall(function()
            gui.Parent = Boot.GuiParent
            gui.Enabled = true
            gui.ResetOnSpawn = false
            gui.DisplayOrder = 1000000 + index * 10
        end) end
    end
end

function Boot.LoadWindUI()
    Boot.SetStatus("Memuat tampilan")
    local errors = {}
    local function attempt(source)
        if type(source) ~= "string" or #source < 1000 then return nil end
        local compiled, chunk, compileError = pcall(loadstring, source, "ANCHHub_WindUI")
        if not compiled or type(chunk) ~= "function" then
            table.insert(errors, tostring(compiled and compileError or chunk)); return nil
        end
        if type(setfenv) == "function" then pcall(setfenv, chunk, Boot.UiEnvironment()) end
        local ok, ui = Boot.Await(chunk, 20)
        if not ok or type(ui) ~= "table" or type(ui.CreateWindow) ~= "function" then
            table.insert(errors, tostring(ui)); return nil
        end
        Boot.BringUiToFront(ui)
        return ui
    end
    local cache = "ANCHHub_WindUI_Delta_d21ff4f2.lua"
    local source
    if Boot.Env.__ANCH_DeltaWindRevision == Boot.WindRevision then source = Boot.Env.__ANCH_DeltaWindSource end
    local ui = attempt(source)
    if ui then return ui end
    if type(isfile) == "function" and type(readfile) == "function" then
        local ok, exists = pcall(isfile, cache)
        if ok and exists then
            local read, text = pcall(readfile, cache)
            if read then source = text; ui = attempt(source) end
            if ui then return ui end
        end
    end
    for _ = 1, 2 do
        local fetched, text = pcall(Boot.HttpGet, Boot.WindUrl)
        if fetched then
            source = text
            ui = attempt(source)
            if ui then
                Boot.Env.__ANCH_DeltaWindRevision = Boot.WindRevision
                Boot.Env.__ANCH_DeltaWindSource = source
                if type(writefile) == "function" then pcall(writefile, cache, source) end
                return ui
            end
        else table.insert(errors, tostring(text)) end
        task.wait(0.3)
    end
    error("Tampilan ANCH Hub gagal dimuat:\n" .. table.concat(errors, "\n"), 0)
end

function Boot.UiError(name, message)
    table.insert(Boot.UiErrors, tostring(name))
    warn("[ANCHHub UI] " .. tostring(name) .. ": " .. tostring(message))
end

function Boot.ReportError(message)
    local report = "Tahap: " .. tostring(Boot.Stage) .. "\n\n" .. tostring(message)
    warn("[ANCH Hub Delta] " .. report)
    if Boot.Env then Boot.Env.__ANCHHub_LoadingAt = nil end
    if Boot.Session and type(Boot.Session.Cleanup) == "function" then pcall(Boot.Session.Cleanup) end
    if Boot.StatusGui then pcall(function() Boot.StatusGui:Destroy() end) end
    local ok = pcall(function()
        local parent = Boot.GuiParent or Boot.PlayerGui
        if not parent then return end
        local screen = Boot.New("ScreenGui", {Name = "ANCHHubStartupError", ResetOnSpawn = false,
            IgnoreGuiInset = true, DisplayOrder = 1000200}, parent)
        local frame = Boot.New("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.new(0.9, 0, 0, 280), BackgroundColor3 = Color3.fromRGB(25, 27, 36), BorderSizePixel = 0}, screen)
        Boot.New("UISizeConstraint", {MaxSize = Vector2.new(600, 280)}, frame)
        Boot.New("UICorner", {CornerRadius = UDim.new(0, 10)}, frame)
        Boot.New("TextLabel", {Position = UDim2.fromOffset(14, 10), Size = UDim2.new(1, -28, 0, 32),
            BackgroundTransparency = 1, Text = "ANCH Hub belum berhasil dimuat", TextSize = 17,
            Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(255, 145, 145), TextWrapped = true}, frame)
        local scroll = Boot.New("ScrollingFrame", {Position = UDim2.fromOffset(14, 50), Size = UDim2.new(1, -28, 1, -110),
            BackgroundTransparency = 1, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 4, BorderSizePixel = 0}, frame)
        Boot.New("TextLabel", {Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1, Text = report, TextSize = 12, Font = Enum.Font.Code,
            TextColor3 = Color3.fromRGB(230, 233, 240), TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top}, scroll)
        local copy = Boot.New("TextButton", {Position = UDim2.new(0, 14, 1, -47), Size = UDim2.new(0.5, -21, 0, 33),
            BackgroundColor3 = Color3.fromRGB(50, 95, 180), Text = "Salin error", TextSize = 13,
            Font = Enum.Font.GothamBold, TextColor3 = Color3.new(1, 1, 1)}, frame)
        copy.Activated:Connect(function()
            local clipboard = setclipboard or toclipboard
            if type(clipboard) == "function" then pcall(clipboard, report) end
        end)
        local close = Boot.New("TextButton", {Position = UDim2.new(0.5, 7, 1, -47), Size = UDim2.new(0.5, -21, 0, 33),
            BackgroundColor3 = Color3.fromRGB(65, 69, 83), Text = "Tutup", TextSize = 13,
            Font = Enum.Font.GothamBold, TextColor3 = Color3.new(1, 1, 1)}, frame)
        close.Activated:Connect(function() screen:Destroy() end)
    end)
    return ok
end

function Boot.Task(callback)
    return task.spawn(function()
        local ok, problem = xpcall(callback, Boot.Trace)
        if not ok then Boot.ReportError(problem) end
    end)
end

function Boot.Finish()
    if Boot.Skipped then
        if Boot.StatusGui then Boot.StatusGui:Destroy() end
        return
    end
    assert(Boot.WindowReady, "Jendela ANCH Hub belum dibuat")
    Boot.SetStatus("Menu siap")
    if Boot.StatusGui then Boot.StatusGui:Destroy() end
end

local function StartHub()
-- [01] BOOTSTRAP: sesi, pembersihan sesi sebelumnya, identitas thread.
local Env = Boot.Env
if Env.__ANCHHub_LoadingAt and (os.clock() - Env.__ANCHHub_LoadingAt) < 4.5 then
    Boot.Skipped = true
    return
end
Env.__ANCHHub_LoadingAt = os.clock()
for _b, _c in ipairs({
    "__ANCHHubSession",
    "__Tadonoki",
    "__Alfian",
    "__GTFarm"
}) do
    if Env[_c] then
        Env[_c].Alive = false
        if Env[_c].Cleanup then
            pcall(Env[_c].Cleanup)
        end
    end
    Env[_c] = nil
end
local Session = {
    Alive = true,
    Connections = {}
}
Session.Cleanup = function()
    Session.Alive = false
end
Env.__ANCHHubSession = Session
Boot.Session = Session
Env.ANCHHubGB_Loaded = os.clock()
local function IsSessionAlive()
    return Session.Alive and Env.__ANCHHubSession == Session
end
local function TrackConnection(_g)
    if _g then
        table.insert(Session.Connections, _g)
    end
    return _g
end
do
    local _h = getthreadidentity or get_thread_identity or getidentity or (syn and syn.get_thread_identity)
    if type(_h) == "function" then
        pcall(function()
            Session.Ident = _h()
        end)
    end
    Session.Exec = coroutine.create(function(_i)
        while true do
            local _j, _k = pcall(_i)
            _i = coroutine.yield(_j, _k)
        end
    end)
end
local function RunWithIdentity(_m)
    local _n = setthreadidentity or set_thread_identity or setidentity or (syn and syn.set_thread_identity)
    local function _o()
        if Session.Ident and type(_n) == "function" then
            pcall(_n, Session.Ident)
        end
    end
    local _p = Session.Exec
    if _p and coroutine.status(_p) == "suspended" then
        local _q, _r = coroutine.resume(_p, function()
            _o()
            _m()
        end)
        if _q and _r ~= false then
            return true
        end
    end
    _o()
    return pcall(_m)
end
local CloneReference = Boot.Clone
-- [02] SERVICE ROBLOX DAN REFERENSI REMOTE.
local Players = CloneReference(game:GetService("Players"))
local ReplicatedStorage = CloneReference(game:GetService("ReplicatedStorage"))
local StarterGui = CloneReference(game:GetService("StarterGui"))
local GuiService = CloneReference(game:GetService("GuiService"))
local UserInputService = CloneReference(game:GetService("UserInputService"))
local HttpService = CloneReference(game:GetService("HttpService"))
local RunService = CloneReference(game:GetService("RunService"))
local TeleportService = CloneReference(game:GetService("TeleportService"))
local VirtualUser = CloneReference(game:GetService("VirtualUser"))
local TextChatService = CloneReference(game:GetService("TextChatService"))
local TextService = CloneReference(game:GetService("TextService"))
local ClientPlayer = Boot.Player
local PlayerGui = Boot.PlayerGui
local SharedFolder = ReplicatedStorage:FindFirstChild("Shared") or ReplicatedStorage:WaitForChild("Shared", 3)
local WorldRemotes = ReplicatedStorage:FindFirstChild("WorldRemotes") or ReplicatedStorage:WaitForChild("WorldRemotes", 1)
local DropItemRemote = WorldRemotes and WorldRemotes:FindFirstChild("DropItem")
local SetTileRemote = WorldRemotes and WorldRemotes:FindFirstChild("SetTile")
local TakeDropRemote = WorldRemotes and WorldRemotes:FindFirstChild("TakeDrop")
local PickTitleRemote = WorldRemotes and WorldRemotes:FindFirstChild("PickTitle")
local WorldClosedRemote = WorldRemotes and WorldRemotes:FindFirstChild("WorldClosed")
local ItemDatabase = type(Env.__ANCH_ItemDBCache) == "table" and Env.__ANCH_ItemDBCache or {}
-- [03] DATABASE ITEM: nama, jenis, seed, waktu tumbuh, dan properti item.
local function LoadItemDatabase()
    if next(ItemDatabase) ~= nil then
        return ItemDatabase
    end
    pcall(function()
        local _R = game:GetService("ReplicatedStorage")
        local _S = _R:FindFirstChild("Shared") or SharedFolder
        local _T = _S and _S:FindFirstChild("ItemDB")
        if _T then
            local _U, _V = pcall(Boot.Require, _T)
            if _U and type(_V) == "table" then
                if type(rawget(_V, 2)) == "table" or type(_V[2]) == "table" then
                    ItemDatabase = _V
                else
                    for _W, _X in ipairs({
                        "items",
                        "Items",
                        "list",
                        "byId",
                        "data",
                        "db"
                    }) do
                        local _Y = rawget(_V, _X)
                        if type(_Y) == "table" and (type(_Y[2]) == "table" or type(_Y["2"]) == "table") then
                            ItemDatabase = _Y
                            break
                        end
                    end
                    if next(ItemDatabase) == nil then
                        ItemDatabase = _V
                    end
                end
                Env.__ANCH_ItemDBCache = ItemDatabase
            end
        end
    end)
    return ItemDatabase
end
LoadItemDatabase()
local HasInventoryModule, InventoryModule = pcall(function()
    return SharedFolder and Boot.Require(SharedFolder:FindFirstChild("Inventory"))
end)
local HasNetModule, NetModule = pcall(function()
    return SharedFolder and Boot.Require(SharedFolder:FindFirstChild("Net"))
end)
local HasRolesModule, RolesModule = pcall(function()
    return SharedFolder and Boot.Require(SharedFolder:FindFirstChild("Roles"))
end)
local HasSfxModule, SfxModule = pcall(function()
    return SharedFolder and Boot.Require(SharedFolder:FindFirstChild("Sfx"))
end)
local HasSpliceModule, SpliceModule = pcall(function()
    return SharedFolder and Boot.Require(SharedFolder:FindFirstChild("Splice"))
end)
local GameGui = PlayerGui and (PlayerGui:FindFirstChild("GameGui") or PlayerGui:WaitForChild("GameGui", 2))
local HasParticlesModule, ParticlesModule = pcall(function()
    return GameGui and Boot.Require(GameGui:FindFirstChild("Particles"))
end)
local HasWorldMenuModule, WorldMenuModule = pcall(function()
    return GameGui and Boot.Require(GameGui:FindFirstChild("WorldMenu"))
end)
-- [04] BERKAS KONFIGURASI DAN NILAI DEFAULT SEMUA FITUR.
local ConfigFile = "ANCHHub_GrowBlox.json"
local RejoinStateFile = "ANCHHub_Rejoin_" .. tostring(ClientPlayer.UserId) .. ".json"
local FactoryStateFile = "ANCHHub_Pabrik_" .. tostring(ClientPlayer.UserId) .. ".json"
local AutoMoveStateFile = "ANCHHub_AutoMove_" .. tostring(ClientPlayer.UserId) .. ".json"
local MainScriptFile = "ANCHHub_GrowBlox.lua"
local MaxDropAmount = 10000
local DropCooldownSeconds = 0.3
local TilePlaceCooldownSeconds = 0.34
local Config = {
    prefix = "/",
    dropId = 242,
    longhandRange = 3,
    blinkMin = 0.2,
    blinkMax = 0.5,
    winDrop = 0,
    pos1 = {},
    pos2 = {},
    fastPull = false,
    fastKick = false,
    fastBan = false,
    fastDrop = false,
    fastDropCount = 0,
    fastRecycle = false,
    fastRecycleCount = 0,
    autoRestore = true,
    autoReload = true,
    autoWarp = false,
    launcher = true,
    lastWorld = "",
    scriptUrl = "",
    session = {},
    reconnectOn = false,
    reconnectWorld = true,
    reconnectServer = true,
    reconnectKeep = false,
    reconnectDelay = 5,
    targetWorld = "",
    walkSpeed = 100,
    mutePunch = true,
    visualAnim = true,
    liteMode = false,
    customWatermark = true,
    watermarkText = "ANCH HUB",
    selectedRole = "none",
    calibX = 0,
    calibY = 0,
    collectMode = "Legit",
    collectAround = false,
    collectRadius = 3,
    vendMode = "Isi stock dari drop",
    vendPoint = "",
    vendDropX = -1,
    vendDropY = -1,
    vendItems = {},
    farmMode = "Place + Break",
    farmPlaceMs = 250,
    farmDelay = 0.22,
    farmAfterBreakMs = 300,
    farmMultiTarget = 1,
    farmHitsOverride = 0,
    farmBreakBg = true,
    farmPlaceId = 2,
    farmGrid = { ["1,0"] = true },
    farmTake = true,
    farmAutoDropSeed = false,
    farmSeedDropAt = 200,
    farmSeedKeep = 0,
    farmDropWorld = "",
    farmDropX = -1,
    farmDropY = -1,
    clearSweep = "Zig-zag",
    clearIncludeBg = true,
    clearBreakDelay = 0.16,
    clearTpDelay = 0.22,
    clearTake = true,
    clearModFly = true,
    harvestDoHarvest = true,
    harvestDoPlant = false,
    harvestSeedId = 3,
    harvestUseBlock = false,
    harvestScaffoldId = 2,
    harvestDelay = 0.22,
    harvestPlantDelay = 0.25,
    harvestTpDelay = 0.30,
    harvestTake = true,
    harvestModFly = false,
    dfBreakDelay = 0.15,
    dfTpDelay = 0.28,
    dfTake = true,
    dfModFly = true,
    dfReplacePlatform = true,
    spliceA = 3,
    spliceB = 5,
    spliceRoam = true,
    spliceMs = 300,
    pabrikSeedId = 3,
    pabrikMaxSeed = 100,
    pabrikWholeWorld = true,
    pabrikTiles = { ["1,0"] = true },
    pabrikBreakX = -1,
    pabrikBreakY = -1,
    pabrikBreakSec = 120,
    pabrikDrop = true,
    pabrikDropWorld = "",
    pabrikDropX = -1,
    pabrikDropY = -1,
    trashOn = false,
    trashList = {},
    trashAt = 150,
    trashKeep = 0,
    convertLockOn = false,
    moveMode = "legit",
    moveMethod = "Legit Walking",
    navSpeed = 1,
    moveStepDelay = 0.28,
    clickTpShift = false,
    guardWho = "Staff (Mod/Dev)",
    guardStopAll = true,
    guardLeave = false,
    guardAutoBack = true,
    guardBackSec = 60,
    guardCalmSec = 5,
    chatText = "",
    chatInterval = 6,
    bonusAutoQuest = false,
    bonusAutoRedeem = false,
    scanAuto = false,
    scanLayer = "Semua",
    scanFilter = "",
    moveWorld1 = "",
    moveWorld2 = "",
    moveDropX = -1,
    moveDropY = -1,
    moveItemId = 2,
    webhookOn = false,
    webhookUrl = "",
    webhookReportMin = 0,
    whPenjaga = true,
    whStop = true,
    whFull = true,
    whBonus = true,
    whRejoin = true,
    whPabrik = true,
}
-- Memuat pengaturan tersimpan; hanya kunci dan tipe yang cocok diterima.
local function LoadConfig()
    pcall(function()
        if isfile and readfile and isfile(ConfigFile) then
            local _by = HttpService:JSONDecode(readfile(ConfigFile))
            for _bz, _bA in pairs(_by) do
                if Config[_bz] ~= nil and type(_bA) == type(Config[_bz]) then
                    Config[_bz] = _bA
                end
            end
        end
    end)
end
local IsBooting = true
-- Menyimpan pengaturan saat startup sudah selesai.
local function SaveConfig()
    if IsBooting then
        return
    end
    pcall(function()
        if writefile then
            writefile(ConfigFile, HttpService:JSONEncode(Config))
        end
    end)
end
LoadConfig()
if Config.scriptUrl == "" then Config.scriptUrl = Boot.SourceUrl end
Boot.SetStatus("Menyiapkan fitur")
local GetGC = getgc or (debug and debug.getgc)
do
    local originalGC = GetGC
    if type(originalGC) == "function" then
        GetGC = function(...)
            local ok, objects = pcall(originalGC, ...)
            return ok and type(objects) == "table" and objects or {}
        end
    end
end
local GetUpvalue = (debug and debug.getupvalue) or getupvalue
local SetUpvalue = (debug and debug.setupvalue) or setupvalue
local GetConstants = (debug and debug.getconstants) or getconstants
local function GetFunctionUpvalues(_bI)
    if debug and debug.getupvalues then
        local _bJ, _bK = pcall(debug.getupvalues, _bI)
        if _bJ and type(_bK) == "table" then
            return _bK
        end
    end
    local _bL = {}
    if GetUpvalue then
        for _bM = 1, 255 do
            local _bN, _bO = pcall(GetUpvalue, _bI, _bM)
            if not _bN then
                break
            end
            _bL[_bM] = _bO
        end
    end
    return _bL
end
local function TrimText(_bQ)
    return (tostring(_bQ or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end
local NotifyWithWindUI = nil
local function ShowNotification(_bT, _bU, _bV, _bW)
    if IsBooting and not _bW then
        return
    end
    if NotifyWithWindUI then
        local _bX = pcall(NotifyWithWindUI, tostring(_bT), _bU, _bV)
        if _bX then
            return
        end
    end
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = _bU or "ANCH HUB | GrowBlox",
            Text = tostring(_bT),
            Duration = _bV or 4,
        })
    end)
end
-- [05] REFERENSI GAME YANG DITEMUKAN DARI MODUL, KONEKSI, DAN UPVALUE.
local Refs = {
    World = nil,
    Inv = nil,
    InvTable = nil,
    SetTile = nil,
    Punch = nil,
    State = nil,
    Menu = nil,
    Gems = nil,
    Hud = nil,
    Trees = nil,
    Others = nil,
    Rigs = nil,
    Particles = {},
}
local Drops = {
    list = nil,
    update = nil,
    brokeAt = {},
    seen = {},
    nextTick = 0
}
local ArmAnimation = {
    fn = nil,
    idx = nil,
    set = nil,
    Particles = nil
}
local PickupCooldowns = {}
local TilePlacedAt = {}
local _cd = {}
local InventoryChangedConnection = nil
local _cf = nil
local SessionStats = {
    T0 = os.clock(),
    Gems0 = nil,
    Placed = 0,
    Broken = 0,
    Collected = 0,
    Harvested = 0,
    Planted = 0,
    Items = {},
}
-- [06] ANTREAN PEMBERITAHUAN DISCORD.
local Webhook = {
    Queue = {},
    LastFull = {},
    Status = "-",
}
do
    (function()
        local function _ci()
            return (syn and syn.request) or (http and http.request) or http_request or request or (fluxus and fluxus.request)
        end
        function Webhook.Valid(_cj)
            _cj = tostring(_cj or "")
            for _ck, _cl in ipairs({
                "discord.com",
                "discordapp.com",
                "ptb.discord.com",
                "canary.discord.com"
            }) do
                if string.sub(_cj, 1, #_cl + 22) == "https://" .. _cl .. "/api/webhooks/" then
                    return true
                end
            end
            return false
        end
        function Webhook.Send(_cm, _cn)
            if not Config.webhookOn or not Webhook.Valid(Config.webhookUrl) then
                return
            end
            local _co = _cm == "test" or _cm == "report" or (_cm == "penjaga" and Config.whPenjaga) or (_cm == "stop" and Config.whStop) or (_cm == "full" and Config.whFull) or (_cm == "bonus" and Config.whBonus) or (_cm == "rejoin" and Config.whRejoin) or (_cm == "pabrik" and Config.whPabrik)
            if not _co or #Webhook.Queue >= 20 then
                return
            end
            table.insert(Webhook.Queue, tostring(_cn))
        end
        task.spawn(function()
            while IsSessionAlive() do
                local _cp = table.remove(Webhook.Queue, 1)
                if not _cp then
                    task.wait(0.5)
                else
                    local _cq = _ci()
                    if not _cq then
                        Webhook.Status = "Executor tidak mendukung request HTTP"
                    else
                        local _cr = HttpService:JSONEncode({
                            username = "ANCH Hub | GrowBlox",
                            content = string.format("**[%s]** %s", ClientPlayer.Name, _cp),
                        })
                        local _cs, _ct = pcall(_cq, {
                            Url = Config.webhookUrl,
                            Method = "POST",
                            Headers = { ["Content-Type"] = "application/json" },
                            Body = _cr,
                        })
                        local _cu = _cs and type(_ct) == "table" and tonumber(_ct.StatusCode or _ct.Status) or nil
                        if _cs and (_cu == nil or _cu < 300) then
                            Webhook.Status = "Terkirim " .. os.date("%H:%M:%S")
                        else
                            Webhook.Status = "Gagal kirim (" .. tostring(_cu or _ct) .. ")"
                        end
                    end
                    task.wait(2.5)
                end
            end
        end)
    end)()
end
-- [07] INPUT BUATAN: A, D, lompat, turun, dan pemulihan tombol.
local MovementInput = {
    active = false,
    left = false,
    right = false,
    jump = false,
    down = false
}
local FlyInput = {
    up = false,
    down = false
}
local OriginalIsDown = Env.__ANCH_TrueOrigIsDown
local ApplyMovementKeys, ReleaseMovementKeys
do
    (function()
        local _cA = Boot.Service("VirtualInputManager", true)
        local _cB = {
            left = false,
            right = false,
            jump = false
        }
        local function _cC(_cD, _cE, _cF)
            if _cB[_cD] == _cF then
                return
            end
            _cB[_cD] = _cF
            pcall(function()
                if _cA and _cA.SendKeyEvent then
                    _cA:SendKeyEvent(_cF, _cE, false, game)
                end
            end)
        end
        ApplyMovementKeys = function()
            if not MovementInput.active then
                _cC("left", Enum.KeyCode.A, false)
                _cC("right", Enum.KeyCode.D, false)
                _cC("jump", Enum.KeyCode.Space, false)
                return
            end
            _cC("left", Enum.KeyCode.A, MovementInput.left == true)
            _cC("right", Enum.KeyCode.D, MovementInput.right == true)
            _cC("jump", Enum.KeyCode.Space, MovementInput.jump == true)
        end
        ReleaseMovementKeys = function()
            MovementInput.left, MovementInput.right, MovementInput.jump, MovementInput.down = false, false, false, false
            _cC("left", Enum.KeyCode.A, false)
            _cC("right", Enum.KeyCode.D, false)
            _cC("jump", Enum.KeyCode.Space, false)
        end
        local function _cG(_cH, _cI, ...)
            if IsSessionAlive() then
                if MovementInput.active then
                    if _cI == "keyLeft" then
                        return MovementInput.left
                    end
                    if _cI == "keyRight" then
                        return MovementInput.right
                    end
                    if _cI == "keyJump" then
                        return MovementInput.jump
                    end
                    if _cI == "keyDown" then
                        return MovementInput.down
                    end
                end
                if FlyInput.up and _cI == "keyJump" then
                    return true
                end
                if FlyInput.down and _cI == "keyDown" then
                    return true
                end
            end
            if OriginalIsDown then
                return OriginalIsDown(_cH, _cI, ...)
            end
            return false
        end
        local function _cJ()
            if HasWorldMenuModule and type(WorldMenuModule) == "table" and type(rawget(WorldMenuModule, "isDown")) == "function" then
                local _cK = rawget(WorldMenuModule, "isDown")
                if not OriginalIsDown and not (isexecutorclosure and pcall(isexecutorclosure, _cK) and isexecutorclosure(_cK)) then
                    OriginalIsDown = _cK
                    Env.__ANCH_TrueOrigIsDown = _cK
                end
                Boot.Assign(WorldMenuModule, "isDown", _cG)
                return
            end
            if GetGC then
                task.spawn(function()
                    for _cL, _cM in ipairs(GetGC(true)) do
                        if type(_cM) == "table" then
                            local _cN = rawget(_cM, "isDown")
                            if type(_cN) == "function" then
                                if not OriginalIsDown and not (isexecutorclosure and pcall(isexecutorclosure, _cN) and isexecutorclosure(_cN)) then
                                    OriginalIsDown = _cN
                                    Env.__ANCH_TrueOrigIsDown = _cN
                                end
                                Boot.Assign(_cM, "isDown", _cG)
                            end
                        end
                    end
                end)
            end
        end
        _cJ()
    end)()
end
do
    (function()
        local function _cO(_cP)
            if not GetConstants or (islclosure and not islclosure(_cP)) then
                return false
            end
            local _cQ, _cR = pcall(GetConstants, _cP)
            if not _cQ or type(_cR) ~= "table" then
                return false
            end
            local _cS, _cT, _cU = false, false, false
            for _cV, _cW in pairs(_cR) do
                if _cW == "tile" or _cW == "SetTile" then
                    _cS = true
                elseif _cW == "placedAt" then
                    _cT = true
                elseif _cW == "flips" then
                    _cU = true
                end
            end
            return _cS and _cT and _cU
        end
        local function _cX(_cY)
            if not GetConstants or (islclosure and not islclosure(_cY)) then
                return false
            end
            local _cZ, _da = pcall(GetConstants, _cY)
            if not _cZ or type(_da) ~= "table" then
                return false
            end
            local _db, _dc = false, false
            for _dd, _de in pairs(_da) do
                if _de == "Empty the Vending Machine first!" then
                    _db = true
                elseif _de == "newCrack" or _de == "HarvestProvider" then
                    _dc = true
                end
            end
            return _db and _dc
        end
        local function _df(_dg)
            local _dh = rawget(_dg, "state")
            if type(_dh) ~= "function" then
                return false
            end
            local _di, _dj = pcall(_dh)
            return _di and type(_dj) == "table" and type(_dj.x) == "number" and type(_dj.y) == "number" and _dj.facing ~= nil and _dj.vx ~= nil
        end
        local function _dk(_dl)
            if _dl == _cO or _dl == _cX then
                return false
            end
            if isexecutorclosure then
                local _dm, _dn = pcall(isexecutorclosure, _dl)
                if _dm and _dn then
                    return false
                end
            end
            return true
        end
        local function _do(_dp)
            if type(_dp) ~= "table" or _dp == Refs.World then
                return false
            end
            local _dq = rawget(_dp, 1)
            if _dq == nil then
                return next(_dp) == nil
            end
            return type(_dq) == "table" and rawget(_dq, "uid") ~= nil and rawget(_dq, "frame") ~= nil
        end
        function ArmAnimation.isArmFn(_dr)
            if not GetConstants or (islclosure and not islclosure(_dr)) then
                return false
            end
            local _ds, _dt = pcall(GetConstants, _dr)
            if not _ds or type(_dt) ~= "table" then
                return false
            end
            local _du, _dv, _dw = false, false, false
            for _dx, _dy in pairs(_dt) do
                if _dy == "forearm" then
                    _du = true
                elseif _dy == "heldReach" then
                    _dv = true
                elseif _dy == "punchReach" then
                    _dw = true
                end
            end
            return _du and _dv and _dw
        end
        function ArmAnimation.bind(_dz)
            if not (GetUpvalue and SetUpvalue) then
                return false
            end
            local _dA, _dB = {}, 0
            for _dC = 1, 16 do
                local _dD, _dE = pcall(GetUpvalue, _dz, _dC)
                if not _dD then
                    break
                end
                _dA[_dC] = _dE
                if _dE ~= nil then
                    _dB = _dC
                end
            end
            for _dF = 1, _dB - 1 do
                local _dG = _dA[_dF]
                if _dG == nil or (type(_dG) == "table" and rawget(_dG, "t") ~= nil and rawget(_dG, "facing") ~= nil) then
                    ArmAnimation.fn, ArmAnimation.idx, ArmAnimation.set = _dz, _dF, SetUpvalue
                    return true
                end
            end
            return false
        end
        local function _dH()
            if not getconnections then
                return
            end
            local _dI, _dJ, _dK = {}, {}, 0
            for _dL, _dM in ipairs({
                "RenderStepped",
                "Heartbeat",
                "Stepped"
            }) do
                local _dN, _dO = pcall(function()
                    return RunService[_dM]
                end)
                if _dN and _dO then
                    local _dP, _dQ = pcall(getconnections, _dO)
                    if _dP and type(_dQ) == "table" then
                        for _dR, _dS in ipairs(_dQ) do
                            local _dT, _dU = pcall(function()
                                return _dS.Function
                            end)
                            if _dT and type(_dU) == "function" then
                                table.insert(_dI, _dU)
                            end
                        end
                    end
                end
            end
            local _dV = 1
            while _dV <= #_dI and _dK < 450 do
                local _dW = _dI[_dV]
                _dV = _dV + 1
                if not _dJ[_dW] then
                    _dJ[_dW] = true
                    _dK = _dK + 1
                    if not ArmAnimation.fn and ArmAnimation.isArmFn(_dW) then
                        ArmAnimation.bind(_dW)
                    end
                    for _dX, _dY in pairs(GetFunctionUpvalues(_dW)) do
                        local _dZ = type(_dY)
                        if _dZ == "table" then
                            if not Refs.World then
                                local _ea, _eb = pcall(function()
                                    return type(rawget(_dY, "fg")) == "table" and type(rawget(_dY, "bg")) == "table" and type(rawget(_dY, "w")) == "number" and rawget(_dY, "w") > 0 and rawget(_dY, "spawn") ~= nil
                                end)
                                if _ea and _eb then
                                    Refs.World = _dY
                                end
                            end
                            if not Refs.Inv and HasInventoryModule and InventoryModule then
                                local _ec, _ed = pcall(function()
                                    return getmetatable(_dY) == InventoryModule and type(rawget(_dY, "slots")) == "table"
                                end)
                                if _ec and _ed then
                                    Refs.Inv = _dY
                                end
                            end
                            if not Refs.State then
                                local _ee, _ef = pcall(_df, _dY)
                                if _ee and _ef then
                                    Refs.State = rawget(_dY, "state")
                                end
                            end
                        elseif _dZ == "function" and not _dJ[_dY] then
                            if not ArmAnimation.fn and ArmAnimation.isArmFn(_dY) then
                                ArmAnimation.bind(_dY)
                            end
                            table.insert(_dI, _dY)
                        end
                    end
                end
            end
        end
        local function _eg()
            local _eh = Refs.World
            if not _eh then
                return false
            end
            for _ei, _ej in ipairs({
                "tileChanged",
                "treeChanged",
                "setTree"
            }) do
                local _ek = rawget(_eh, _ej)
                if type(_ek) == "function" then
                    local _el = GetFunctionUpvalues(_ek)
                    local _em = {}
                    for _en, _eo in pairs(_el) do
                        if type(_eo) == "table" and _eo ~= _eh then
                            _em[_eo] = true
                        end
                    end
                    for _ep, _eq in pairs(_el) do
                        if type(_eq) == "function" then
                            local _er = GetFunctionUpvalues(_eq)
                            local _es, _et, _eu = false, 0, {}
                            for _ev, _ew in pairs(_er) do
                                if rawequal(_ew, _eh) then
                                    _es = true
                                elseif type(_ew) == "table" then
                                    _et = _et + 1
                                    if _em[_ew] then
                                        table.insert(_eu, _ew)
                                    end
                                end
                            end
                            if _es and _et <= 3 and #_eu == 1 then
                                Refs.Trees = _eu[1]
                                return true
                            end
                        end
                    end
                end
            end
            return false
        end
        local _ex = 0
        function Refs.Scan(_ey)
            local _ez = os.clock()
            if not _ey and (_ez - _ex) < 2.5 and Refs.World then
                return true
            end
            _ex = _ez
            LoadItemDatabase()
            Refs.World, Refs.Inv, Refs.InvTable, Refs.SetTile, Refs.Punch, Refs.State, Refs.Menu, Refs.Gems, Refs.Hud, Refs.Others = nil, nil, nil, nil, nil, nil, nil, nil, nil, nil
            Refs.Particles = {}
            _dH()
            if GetGC then
                for _eA, _eB in ipairs(GetGC(true)) do
                    local _eC = type(_eB)
                    if _eC == "table" then
                        if next(ItemDatabase) == nil or type(ItemDatabase[2]) ~= "table" then
                            local _eF, _eG = pcall(function()
                                local _eD = rawget(_eB, 2)
                                local _eE = rawget(_eB, 242)
                                return type(_eD) == "table" and type(_eE) == "table" and (type(rawget(_eD, "name")) == "string" or type(rawget(_eD, "hits")) == "number")
                            end)
                            if _eF and _eG then
                                ItemDatabase = _eB
                            end
                        end
                        if not Refs.World then
                            local _eH, _eI = pcall(function()
                                return type(rawget(_eB, "fg")) == "table" and type(rawget(_eB, "bg")) == "table" and type(rawget(_eB, "w")) == "number" and type(rawget(_eB, "h")) == "number" and rawget(_eB, "spawn") ~= nil
                            end)
                            if _eH and _eI then
                                Refs.World = _eB
                            end
                        end
                        if not Refs.InvTable then
                            local _eJ, _eK = pcall(function()
                                return type(rawget(_eB, "onDrop")) == "function" and type(rawget(_eB, "canDrop")) == "function" and type(rawget(_eB, "isWorn")) == "function"
                            end)
                            if _eJ and _eK then
                                Refs.InvTable = _eB
                                Refs.Hud = Refs.Hud or _eB
                            end
                        end
                        if not Refs.Inv and HasInventoryModule and InventoryModule then
                            local _eL, _eM = pcall(function()
                                return getmetatable(_eB) == InventoryModule and type(rawget(_eB, "slots")) == "table"
                            end)
                            if _eL and _eM then
                                Refs.Inv = _eB
                            end
                        end
                        if not Refs.State then
                            local _eN, _eO = pcall(_df, _eB)
                            if _eN and _eO then
                                Refs.State = rawget(_eB, "state")
                            end
                        end
                        if not Refs.Menu then
                            local _eP, _eQ = pcall(function()
                                return type(rawget(_eB, "openBackpack")) == "function" and type(rawget(_eB, "ui")) == "table"
                            end)
                            if _eP and _eQ then
                                Refs.Menu = _eB
                            end
                        end
                        if not Refs.Gems then
                            local _eR, _eS = pcall(function()
                                return type(rawget(_eB, "addGems")) == "function"
                            end)
                            if _eR and _eS then
                                Refs.Gems = _eB
                            end
                        end
                        if not Refs.Hud then
                            local _eT, _eU = pcall(function()
                                return type(rawget(_eB, "punchRange")) == "function" and type(rawget(_eB, "buildRange")) == "function"
                            end)
                            if _eT and _eU then
                                Refs.Hud = _eB
                            end
                        end
                        if not Refs.Others then
                            local _eV, _eW = pcall(function()
                                return type(rawget(_eB, "list")) == "function" and type(rawget(_eB, "where")) == "function" and type(rawget(_eB, "playerAt")) == "function"
                            end)
                            if _eV and _eW then
                                Refs.Others = _eB
                            end
                        end
                        if not Refs.Rigs then
                            local _eZ, _fa = pcall(function()
                                local _eX, _eY = rawget(_eB, 1), rawget(_eB, -1)
                                return type(_eX) == "table" and type(_eY) == "table" and typeof(rawget(_eX, "body")) == "Instance" and typeof(rawget(_eY, "head")) == "Instance"
                            end)
                            if _eZ and _fa then
                                Refs.Rigs = _eB
                            end
                        end
                        if HasParticlesModule and ParticlesModule then
                            local _fb, _fc = pcall(function()
                                return getmetatable(_eB) == ParticlesModule and type(rawget(_eB, "live")) == "table"
                            end)
                            if _fb and _fc then
                                table.insert(Refs.Particles, _eB)
                            end
                        end
                    elseif _eC == "function" and _dk(_eB) then
                        if not Refs.SetTile and _cO(_eB) then
                            Refs.SetTile = _eB
                        elseif not Refs.Punch and _cX(_eB) then
                            Refs.Punch = _eB
                        end
                    end
                end
            end
            if Refs.World and (not Refs.SetTile or not Refs.Punch) and debug and debug.info then
                for _fd, _fe in ipairs(GetGC(true)) do
                    if type(_fe) == "function" then
                        local _ff, _fg = pcall(debug.info, _fe, "n")
                        if _ff and (_fg == "setTile" or _fg == "hit") then
                            for _fh, _fi in pairs(GetFunctionUpvalues(_fe)) do
                                if _fi == Refs.World then
                                    if _fg == "setTile" and not Refs.SetTile then
                                        Refs.SetTile = _fe
                                    end
                                    if _fg == "hit" and not Refs.Punch then
                                        Refs.Punch = _fe
                                    end
                                end
                            end
                        end
                    end
                end
            end
            if not Refs.Inv and Refs.World and type(rawget(Refs.World, "backpackNow")) == "function" then
                for _fj, _fk in pairs(GetFunctionUpvalues(Refs.World.backpackNow)) do
                    if type(_fk) == "table" and type(_fk.slots) == "table" then
                        Refs.Inv = _fk
                        break
                    end
                end
            end
            if InventoryChangedConnection then
                pcall(function()
                    InventoryChangedConnection:Disconnect()
                end);
                InventoryChangedConnection = nil
            end
            if Refs.Inv and typeof(Refs.Inv.changed) == "Instance" then
                InventoryChangedConnection = TrackConnection(Refs.Inv.changed.Event:Connect(function()
                    if IsSessionAlive() and _cf then
                        pcall(_cf)
                    end
                end))
            end
            function Drops.findUpdate()
                local _fl, _fm = Refs.World, Drops.list
                local _fn = _fl and rawget(_fl, "dropTaken")
                if type(_fn) ~= "function" or not _fm then
                    return false
                end
                for _fo, _fp in pairs(GetFunctionUpvalues(_fn)) do
                    if type(_fp) == "function" then
                        for _fq, _fr in pairs(GetFunctionUpvalues(_fp)) do
                            if rawequal(_fr, _fm) then
                                Drops.update = _fp
                                return true
                            end
                        end
                    end
                end
                return false
            end
            function Drops.findRefs()
                local _fs = Refs.World
                local _ft = _fs and rawget(_fs, "dropList")
                if type(_ft) == "function" then
                    local _fu, _fv = pcall(_ft)
                    if _fu and _do(_fv) then
                        if Drops.list ~= _fv then
                            Drops.update = nil
                        end
                        Drops.list = _fv
                        if not Drops.update then
                            Drops.findUpdate()
                        end
                        return true
                    end
                end
                Drops.list, Drops.update = nil, nil
                local _fw = _fs and rawget(_fs, "dropTaken")
                if type(_fw) == "function" then
                    for _fx, _fy in pairs(GetFunctionUpvalues(_fw)) do
                        if not Drops.list and _do(_fy) then
                            Drops.list = _fy
                        elseif not Drops.update and type(_fy) == "function" then
                            Drops.update = _fy
                        end
                    end
                    if Drops.list and not Drops.update then
                        Drops.findUpdate()
                    end
                end
                local _fz = WorldRemotes and WorldRemotes:FindFirstChild("DropTaken")
                if not Drops.list and _fz and getconnections then
                    local _fA, _fB = pcall(getconnections, _fz.OnClientEvent)
                    if _fA and type(_fB) == "table" then
                        for _fC, _fD in ipairs(_fB) do
                            local _fE, _fF = pcall(function()
                                return _fD.Function
                            end)
                            if _fE and type(_fF) == "function" then
                                for _fG, _fH in pairs(GetFunctionUpvalues(_fF)) do
                                    if not Drops.list and _do(_fH) then
                                        Drops.list = _fH
                                    elseif not Drops.update and type(_fH) == "function" then
                                        Drops.update = _fH
                                    end
                                end
                            end
                            if Drops.list then
                                break
                            end
                        end
                    end
                end
                return Drops.list ~= nil
            end
            Drops.findRefs()
            Refs.Trees = nil
            if not Refs.Trees then
                _eg()
            end
            if Refs.World and type(rawget(Refs.World, "treeLook")) == "function" and GetUpvalue then
                local _fI, _fJ = pcall(GetUpvalue, Refs.World.treeLook, 8)
                if _fI and type(_fJ) == "table" then
                    Refs.Trees = _fJ
                end
            end
            local _fK = WorldRemotes and WorldRemotes:FindFirstChild("TreeChanged")
            if not Refs.Trees and _fK and getconnections then
                local _fL, _fM = pcall(getconnections, _fK.OnClientEvent)
                if _fL and type(_fM) == "table" then
                    for _fN, _fO in ipairs(_fM) do
                        local _fP, _fQ = pcall(function()
                            return _fO.Function
                        end)
                        if _fP and type(_fQ) == "function" then
                            for _fR, _fS in pairs(GetFunctionUpvalues(_fQ)) do
                                if type(_fS) == "table" and _fS ~= Refs.World and rawget(_fS, "fg") == nil then
                                    local _fT, _fU = next(_fS)
                                    if _fU == nil or (type(_fU) == "table" and type(rawget(_fU, "p")) == "number") then
                                        Refs.Trees = _fS
                                        break
                                    end
                                end
                            end
                        end
                        if Refs.Trees then
                            break
                        end
                    end
                end
            end
            return Refs.World ~= nil
        end
    end)()
end
-- [08] HELPER WORLD, INVENTORY, ITEM, DAN POSISI KARAKTER.
local function GetWorld()
    if Refs.World and type(rawget(Refs.World, "fg")) == "table" then
        return Refs.World
    end
    Refs.Scan()
    return Refs.World
end
local function GetInventoryHud()
    if Refs.InvTable then
        return Refs.InvTable
    end
    Refs.Scan()
    return Refs.InvTable
end
local function GetPlayerRigs()
    if Refs.Rigs then
        return Refs.Rigs
    end
    Refs.Scan()
    return Refs.Rigs
end
local function GetItemInfo(_fZ)
    if not _fZ then
        return nil
    end
    if next(ItemDatabase) == nil then
        LoadItemDatabase()
    end
    local _ga = tonumber(_fZ)
    local _gb = (_ga and (rawget(ItemDatabase, _ga) or ItemDatabase[_ga])) or rawget(ItemDatabase, tostring(_fZ)) or ItemDatabase[tostring(_fZ)]
    if type(_gb) == "table" then
        return _gb
    end
    if type(ItemDatabase.get) == "function" then
        local _gc, _gd = pcall(ItemDatabase.get, _ga or _fZ)
        if _gc and type(_gd) == "table" then
            return _gd
        end
    end
    return nil
end
local function GetItemName(_gf)
    local _gg = GetItemInfo(_gf)
    if type(_gg) == "table" then
        local _gh = rawget(_gg, "name") or _gg.name or rawget(_gg, "title") or rawget(_gg, "itemName") or rawget(_gg, 1)
        if type(_gh) == "string" and _gh ~= "" then
            return _gh
        end
    end
    return "Item #" .. tostring(_gf)
end
local function CountInventoryItem(_gj)
    if not _gj then
        return 0
    end
    if not Refs.Inv then
        Refs.Scan()
    end
    local _gk = Refs.Inv
    if not _gk then
        return 0
    end
    if type(_gk.count) == "function" then
        local _gl, _gm = pcall(function()
            return _gk:count(_gj)
        end)
        if _gl and type(_gm) == "number" then
            return _gm
        end
    end
    local _gn = 0
    if type(_gk.slots) == "table" then
        for _go, _gp in pairs(_gk.slots) do
            if type(_gp) == "table" and _gp.id == _gj then
                _gn += (_gp.n or 0)
            end
        end
    end
    return _gn
end
local function GetSeedIdFromBlock(_gr)
    local _gs = _gr and ItemDatabase[_gr]
    if not _gs then
        return nil
    end
    local _gt = _gs.seedId or (_gr + 1)
    local _gu = ItemDatabase[_gt]
    return (_gu and _gu.kind == "seed") and _gt or nil
end
local function GetBlockIdFromSeed(_gw)
    if not _gw then
        return nil
    end
    local _gx = _gw - 1
    local _gy = ItemDatabase[_gx]
    if _gy and _gy.kind ~= "seed" and (_gy.seedId == nil or _gy.seedId == _gw) then
        return _gx
    end
    return nil
end
local _gz = nil
local function GetDirtId()
    if _gz then
        return _gz
    end
    if ItemDatabase[2] and type(ItemDatabase[2].name) == "string" and ItemDatabase[2].name:lower() == "dirt" then
        _gz = 2
        return 2
    end
    for _gB, _gC in pairs(ItemDatabase) do
        if type(_gB) == "number" and type(_gC) == "table" and type(_gC.name) == "string" and _gC.name:lower() == "dirt" then
            _gz = _gB
            return _gB
        end
    end
    return 2
end
local _gD = nil
local function GetDirtSeedId()
    if _gD then
        return _gD
    end
    local _gF = GetSeedIdFromBlock(GetDirtId())
    if _gF then
        _gD = _gF
        return _gF
    end
    return 3
end
local function ReadCharacterPositionFromGui()
    local _gH = PlayerGui:FindFirstChild("GameGui")
    local _gI = _gH and _gH:FindFirstChild("World")
    local _gJ = _gI and _gI:FindFirstChild("Camera")
    local _gK = _gJ and _gJ:FindFirstChild("Tiles")
    local _gL = _gJ and _gJ:FindFirstChild("PlayerView")
    if not (_gK and _gL and _gK:IsA("GuiObject") and _gL:IsA("GuiObject")) then
        return nil
    end
    local _gM = _gK:FindFirstChildWhichIsA("ImageLabel")
    local _gN = (_gM and _gM.AbsoluteSize.X > 0) and _gM.AbsoluteSize.X or 64
    local _gO = _gL.AbsolutePosition + (_gL.AbsoluteSize / 2)
    local _gP = _gO - _gK.AbsolutePosition
    return {
        x = _gP.X / _gN,
        y = (_gP.Y / _gN) + 0.475,
        vx = 0,
        vy = 0,
        facing = 1,
        grounded = true,
        dead = false,
        active = true,
    }
end
local function GetCharacterState()
    if not Refs.State then
        Refs.Scan()
    end
    if Refs.State then
        local _gR, _gS = pcall(Refs.State)
        if _gR and type(_gS) == "table" and type(_gS.x) == "number" and type(_gS.y) == "number" and _gS.active ~= false then
            return _gS
        end
    end
    return ReadCharacterPositionFromGui()
end
local function GetCalibratedPosition()
    local _gU = GetCharacterState()
    if _gU then
        return _gU.x + Config.calibX, _gU.y + Config.calibY, (_gU.facing and _gU.facing < 0) and -1 or 1
    end
    return nil, "Karakter belum berada di world"
end
function ArmAnimation.Swing(_gV, _gW, _gX)
    if not Config.visualAnim or not (ArmAnimation.fn and ArmAnimation.idx and ArmAnimation.set) then
        return
    end
    local _gY = GetCharacterState()
    local _gZ = (_gY and _gV + 0.5 < _gY.x) and -1 or 1
    pcall(ArmAnimation.set, ArmAnimation.fn, ArmAnimation.idx, {
        t = os.clock(),
        x = _gV + 0.5,
        y = _gW + 0.5,
        facing = _gZ,
        kind = _gX
    })
end
function ArmAnimation.Place(_ha, _hb, _hc)
    if not Config.visualAnim then
        return
    end
    ArmAnimation.Swing(_ha, _hb, "build")
    local _hd = ItemDatabase[_hc]
    if _hd and _hd.kind ~= "seed" and Refs.Particles and #Refs.Particles > 0 then
        local _he = ArmAnimation.Particles or Refs.Particles[1]
        ArmAnimation.Particles = _he
        pcall(function()
            _he:place(_ha + 0.5, _hb + 0.5)
        end)
    end
end
local function GetCurrentTile()
    local _hg, _hh = GetCalibratedPosition()
    if not _hg then
        return nil
    end
    return math.floor(_hg), math.floor(_hh - 0.475)
end
local function GetWorldName()
    local _hj = GetWorld()
    local _hk = _hj and rawget(_hj, "name")
    return type(_hk) == "string" and _hk or ""
end
local function ReadTile(_hm, _hn, _ho, _hp)
    local _hq = _hm or GetWorld()
    if not _hq or _ho < 0 or _hp < 0 or _ho >= _hq.w or _hp >= _hq.h then
        return nil
    end
    local _hr = rawget(_hq, _hn)
    local _hs = _hr and _hr[_hp]
    return _hs and (_hs[_ho] or 0) or nil
end
local function IsTileInWorld(_hu, _hv, _hw)
    local _hx = _hu or GetWorld()
    return _hx and type(_hx.w) == "number" and _hv >= 0 and _hw >= 0 and _hv < _hx.w and _hw < _hx.h
end
local function GetItemLayer(_hz)
    local _hA = ItemDatabase and ItemDatabase[_hz]
    return (type(_hA) == "table" and _hA.background) and "bg" or "fg"
end
local function GetPunchRange()
    local _hC = Refs.Hud or GetInventoryHud()
    if _hC and type(_hC.punchRange) == "function" then
        local _hD, _hE = pcall(_hC.punchRange)
        if _hD and type(_hE) == "number" and _hE > 0 then
            return _hE
        end
    end
    return 2.5
end
local function GetBuildRange()
    local _hG = Refs.Hud or GetInventoryHud()
    if _hG and type(_hG.buildRange) == "function" then
        local _hH, _hI = pcall(_hG.buildRange)
        if _hH and type(_hI) == "number" and _hI > 0 then
            return _hI
        end
    end
    return 2.5
end
local function SendTileChange(_hK, _hL, _hM, _hN, _hO)
    if _hN ~= 0 and ArmAnimation.Place then
        ArmAnimation.Place(_hL, _hM, _hN)
    end
    if not Refs.SetTile then
        Refs.Scan()
    end
    if Refs.SetTile then
        local _hP = pcall(Refs.SetTile, _hK, _hL, _hM, _hN, false, _hO == true)
        if _hP then
            TilePlacedAt[_hL .. "," .. _hM] = os.clock()
            return true
        end
    end
    if HasNetModule and type(NetModule) == "table" and type(NetModule.tile) == "table" then
        local _hQ = pcall(NetModule.tile.send, {
            layer = (_hK == "bg") and 2 or 1,
            x = _hL,
            y = _hM,
            id = _hN,
            flip = _hO == true,
        })
        if _hQ then
            local _hR = GetWorld()
            if _hR and _hR[_hK] and _hR[_hK][_hM] then
                _hR[_hK][_hM][_hL] = _hN
            end
            TilePlacedAt[_hL .. "," .. _hM] = os.clock()
            return true
        end
    elseif SetTileRemote then
        pcall(function()
            SetTileRemote:FireServer(_hK, _hL, _hM, _hN, _hO == true)
        end)
        local _hS = GetWorld()
        if _hS and _hS[_hK] and _hS[_hK][_hM] then
            _hS[_hK][_hM][_hL] = _hN
        end
        TilePlacedAt[_hL .. "," .. _hM] = os.clock()
        return true
    end
    return false
end
-- Menempatkan item dari inventory pada koordinat tile.
local function PlaceInventoryItem(_hU, _hV, _hW)
    if not _hU or _hU <= 0 then
        return false
    end
    if CountInventoryItem(_hU) <= 0 then
        return false
    end
    local _hX = GetItemLayer(_hU)
    local _hY = SendTileChange(_hX, _hV.x, _hV.y, _hU, (_hW or 1) < 0)
    if not _hY then
        return false
    end
    if Refs.Inv and type(Refs.Inv.remove) == "function" then
        pcall(function()
            Refs.Inv:remove(_hU, 1)
        end)
    end
    SessionStats.Placed += 1
    return true
end
local function WaitAfterPlacement(_ia, _ib)
    local _ic = _ia .. "," .. _ib
    local _id = TilePlacedAt[_ic]
    if _id then
        local _ie = os.clock() - _id
        if _ie < TilePlaceCooldownSeconds then
            task.wait(TilePlaceCooldownSeconds - _ie)
        end
        TilePlacedAt[_ic] = nil
    end
end
local _if = {
    [6] = true,
    [8] = true,
    [202] = true,
    [204] = true,
    [206] = true,
    [242] = true,
    [1796] = true,
    [4994] = true,
    [5814] = true,
    [7188] = true,
}
local function IsBreakableItem(_ih, _ii, _ij)
    if not _ih or _ih == 0 or _if[_ih] then
        return false
    end
    local _ik = GetWorld()
    if _ik and _ii and _ij then
        if typeof(_ik.spawn) == "Vector2" and _ii == math.floor(_ik.spawn.X) and _ij == math.floor(_ik.spawn.Y) then
            return false
        end
        if type(_ik.lock) == "table" and _ik.lock.x == _ii and _ik.lock.y == _ij then
            return false
        end
    end
    local _il = GetItemInfo(_ih)
    if not _il then
        if _ik and _ij and _ij >= _ik.h - 6 then
            return false
        end
        return true
    end
    if _il.lock or _il.area or _il.guildLock or _il.vend or _il.display or _il.bedrock or _il.unbreakable or _il.door or _il.entrance then
        return false
    end
    local _im = tostring(rawget(_il, "name") or _il.name or ""):lower()
    if _im:find("bedrock", 1, true) or _im:find("lock", 1, true) or _im:find("main door", 1, true) or _im:find("white door", 1, true) or _im:find("vending", 1, true) then
        return false
    end
    local _in = (_il.kind == "seed") and 20 or _il.hits
    if type(_in) == "number" then
        return _in > 0
    end
    if _il.staffHits then
        return false
    end
    return true
end
-- Memukul tile dan mencatat hasil hit/broke.
local function PunchTile(_ip, _iq, _ir)
    if _ir == nil then
        _ir = true
    end
    local _is = GetWorld()
    if not _is then
        return nil
    end
    local _it = ReadTile(_is, "fg", _ip, _iq)
    if _it == nil then
        return nil
    end
    local _iu = ReadTile(_is, "bg", _ip, _iq)
    local _iv, _iw
    if _it ~= 0 then
        _iv, _iw = "fg", _it
    elseif _ir and _iu and _iu ~= 0 then
        _iv, _iw = "bg", _iu
    end
    if not _iv or not IsBreakableItem(_iw, _ip, _iq) then
        return nil
    end
    WaitAfterPlacement(_ip, _iq)
    if not Refs.Punch then
        Refs.Scan()
    end
    if Refs.Punch then
        local _ix = pcall(Refs.Punch, _ip, _iq, Config.mutePunch or nil, nil)
        if not _ix then
            return nil
        end
        ArmAnimation.Swing(_ip, _iq, "punch")
        if ReadTile(_is, _iv, _ip, _iq) ~= _iw then
            SessionStats.Broken += 1
            Drops.brokeAt[_ip .. "," .. _iq] = os.clock()
            return "broke", _iw, _iv
        end
        return "hit", _iw, _iv
    end
    return nil
end
-- [09] PENGELOLAAN NOCLIP / GHOST.
local ManualNoclipEnabled = false
local NoclipOwners = {}
local FlyPadGui = nil
local function IsNoclipRequested()
    if ManualNoclipEnabled then
        return true
    end
    for _iC, _iD in pairs(NoclipOwners) do
        if _iD then
            return true
        end
    end
    return false
end
local function UpdateNoclip()
    local _iF = GetWorld()
    if not _iF then
        return
    end
    if IsNoclipRequested() then
        _iF.ghost = true
    else
        FlyInput.up, FlyInput.down = false, false
        _iF.ghost = (ClientPlayer:GetAttribute("Ghost") == true)
    end
    if FlyPadGui then
        FlyPadGui.Enabled = ManualNoclipEnabled
    end
end
local function SetNoclipOwner(_iH, _iI)
    NoclipOwners[_iH] = _iI and true or nil
    UpdateNoclip()
end
local function EnableManualNoclip()
    ManualNoclipEnabled = true
    UpdateNoclip()
    return true
end
local function DisableManualNoclip()
    ManualNoclipEnabled = false
    UpdateNoclip()
    return true
end
TrackConnection(RunService.Heartbeat:Connect(function()
    if not IsSessionAlive() then
        return
    end
    local _iL = Refs.World
    if not _iL then
        return
    end
    if Drops.collecting then
        _iL.speedScale = 1
    elseif Config.walkSpeed ~= 100 then
        _iL.speedScale = Config.walkSpeed / 100
    end
    if IsNoclipRequested() and _iL.ghost ~= true then
        _iL.ghost = true
    end
end))
-- [10] NAVIGASI: A*, jalan, jatuh, lompat, scaffold, fly, dan Click TP.
local Navigation = {
    clickOn = false,
    token = 0,
    conn = nil,
    last = "-",
    BadEdge = {},
    PlacedScaffolds = 0,
}
do
    (function()
        local _iN, _iO = math.floor, math.abs
        local function _iP(_iQ, _iR)
            local _iS = GetWorld()
            local _iT = _iS and _iS.fg and _iS.fg[_iR]
            return (_iT and _iT[_iQ]) or 0
        end
        local function _iU(_iV, _iW)
            local _iX = _iP(_iV, _iW)
            if _iX ~= 0 then
                return ItemDatabase[_iX]
            end
            return nil
        end
        local function _iY(_iZ, _ja)
            local _jb = GetWorld()
            if not _jb then
                return true
            end
            if _iZ < 0 or _iZ >= _jb.w or _ja >= _jb.h then
                return true
            end
            if _ja < 0 then
                return false
            end
            local _jc = _iU(_iZ, _ja)
            if not _jc then
                return false
            end
            if _jc.combiner then
                local _jd, _je = pcall(_jb.combinerShut, _iZ, _ja)
                return (not _jd) or (_je and true or false)
            end
            if _jc.vip then
                local _jf, _jg = pcall(_jb.vipMay, _iZ, _ja)
                return not (_jf and _jg)
            end
            if _jc.entrance then
                local _jh = _jb.switches and _jb.switches[_ja * _jb.w + _iZ]
                if _jc.gate then
                    return not (_jh and _jh.off == true)
                end
                if _jh and _jh.public then
                    return false
                end
                local _ji, _jj = pcall(function()
                    return _jb.areas.mayBuild(_jb.lock, _iZ, _ja)
                end)
                return not (_ji and _jj)
            end
            return _jc.solid and true or false
        end
        local function _jk(_jl, _jm)
            local _jn = _iU(_jl, _jm)
            return _jn ~= nil and (_jn.deadly or _jn.hurts or _jn.laser) and true or false
        end
        local function _jo(_jp, _jq)
            local _jr = _iU(_jp, _jq)
            return _jr ~= nil and _jr.platform and true or false
        end
        local function _js(_jt, _ju)
            return not _iY(_jt, _ju) and not _jk(_jt, _ju)
        end
        local function _jv(_jw, _jx)
            return not _jk(_jw, _jx + 1) and (_iY(_jw, _jx + 1) or _jo(_jw, _jx + 1))
        end
        local function _jy(_jz, _jA, _jB, _jC)
            return _iO(_jA + 0.5 - _jz.x) <= _jC and _iO(_jB + 0.5 - (_jz.y - 0.475)) <= _jC
        end
        local function _jD(_jE, _jF)
            local _jG = GetWorld()
            if not _jG or _jE < 0 or _jF < 0 or _jE >= _jG.w or _jF >= _jG.h then
                return false
            end
            if _iP(_jE, _jF) ~= 0 then
                return false
            end
            local _jH, _jI = pcall(function()
                if _jG.areas and type(_jG.areas.canEdit) == "function" and not _jG.areas.canEdit(_jE, _jF) then
                    return false
                end
                if type(_jG.builderOk) == "function" and not _jG.builderOk(_jE, _jF, true) then
                    return false
                end
                return true
            end)
            return (not _jH) or _jI
        end
        local function _jJ()
            local _jK = {
                Config.harvestScaffoldId,
                GetDirtId(),
                Config.farmPlaceId,
            }
            for _jL, _jM in ipairs(_jK) do
                if type(_jM) == "number" and _jM > 0 and CountInventoryItem(_jM) > 0 then
                    local _jN = ItemDatabase[_jM]
                    if _jN and _jN.solid and _jN.kind ~= "seed" then
                        return _jM
                    end
                end
            end
            if Refs.Inv and type(Refs.Inv.slots) == "table" then
                for _jO, _jP in ipairs(Refs.Inv.slots) do
                    local _jQ = _jP.id and ItemDatabase[_jP.id]
                    if _jQ and _jQ.solid and _jQ.kind ~= "seed" and not _jQ.lock and (_jP.n or 0) > 0 then
                        return _jP.id
                    end
                end
            end
            return GetDirtId()
        end
        local function _jR(_jS, _jT)
            local _jU = _jJ()
            if not _jU or CountInventoryItem(_jU) <= 0 or not _jD(_jS, _jT) then
                return false
            end
            local _jV = GetCharacterState()
            if _jV and not _jy(_jV, _jS, _jT, GetBuildRange() + 0.5) then
                return false
            end
            if PlaceInventoryItem(_jU, {
                x = _jS,
                y = _jT
            }, 1) then
                Navigation.PlacedScaffolds += 1
                return true
            end
            return false
        end
        Navigation.SolidAt = _iY
        Navigation.OpenAt = _js
        Navigation.RealSupport = _jv
        Navigation.PlaceScaffold = _jR
        Navigation.StateReaches = _jy
        Navigation.PlaceOk = _jD
        function Navigation.Los(_jW, _jX, _jY, _jZ)
            if _jZ - _jX >= 2 then
                for _ka = _jX + 1, _jZ - 1 do
                    if _iY(_jY, _ka) then
                        return false
                    end
                end
            elseif _jX - _jZ >= 2 then
                for _kb = _jZ + 1, _jX - 1 do
                    if _iY(_jY, _kb) then
                        return false
                    end
                end
            end
            return true
        end
        function Navigation.AirCheck(_kc)
            if not _kc or _kc.grounded then
                Navigation.AirAt = nil
                return
            end
            if not Navigation.AirAt then
                Navigation.AirAt = os.clock()
            elseif os.clock() - Navigation.AirAt > 3 then
                Navigation.AirAt = nil
                local _kd = (_kc.facing or 1) < 0
                MovementInput.active = true
                MovementInput.right, MovementInput.left = _kd, not _kd
                task.wait(0.2)
                MovementInput.right, MovementInput.left = false, false
            end
        end
        local function _ke(_kf, _kg, _kh, _ki, _kj)
            _kh += 1
            local _kk = _kh
            while _kk > 1 do
                local _kl = _kk // 2
                if _kf[_kl] <= _ki then
                    break
                end
                _kf[_kk], _kg[_kk] = _kf[_kl], _kg[_kl]
                _kk = _kl
            end
            _kf[_kk], _kg[_kk] = _ki, _kj
            return _kh
        end
        local function _km(_kn, _ko, _kp)
            local _kq = _ko[1]
            local _kr, _ks = _kn[_kp], _ko[_kp]
            _kn[_kp], _ko[_kp] = nil, nil
            _kp -= 1
            if _kp > 0 then
                local _kt = 1
                while true do
                    local _ku = _kt * 2
                    if _ku > _kp then
                        break
                    end
                    if _ku < _kp and _kn[_ku + 1] < _kn[_ku] then
                        _ku += 1
                    end
                    if _kr <= _kn[_ku] then
                        break
                    end
                    _kn[_kt], _ko[_kt] = _kn[_ku], _ko[_ku]
                    _kt = _ku
                end
                _kn[_kt], _ko[_kt] = _kr, _ks
            end
            return _kq, _kp
        end
        function Navigation.AStar(_kv, _kw, _kx, _ky, _kz, _kA, _kB, _kC)
            local _kD = GetWorld()
            if not _kD then
                return nil, false, {}
            end
            local _kE, _kF = _kD.w, _kD.h
            local _kG = _kE * _kF
            _kA = _kA or 0.4
            local _kH = _iN(_kA)
            local _kI = math.ceil(-_kA + 0.025)
            local _kJ = _iN(_kA + 0.025)
            local _kK, _kL, _kM = {}, {}, {}
            local function _kN(_kO, _kP)
                if _kO < 0 or _kO >= _kE or _kP >= _kF then
                    return false
                end
                if _kP < 0 then
                    return true
                end
                local _kQ = _kP * _kE + _kO
                local _kR = _kK[_kQ]
                if _kR == nil then
                    _kR = _js(_kO, _kP);
                    _kK[_kQ] = _kR
                end
                return _kR
            end
            local function _kS(_kT, _kU)
                if _kT < 0 or _kT >= _kE or _kU < 0 or _kU >= _kF then
                    return false
                end
                local _kV = _kU * _kE + _kT
                local _kW = _kL[_kV]
                if _kW == nil then
                    _kW = _jv(_kT, _kU);
                    _kL[_kV] = _kW
                end
                return _kW
            end
            local function _kX(_kY, _kZ)
                if not _kB or _kY < 0 or _kY >= _kE or _kZ < 0 or _kZ >= _kF then
                    return false
                end
                local _la = _kZ * _kE + _kY
                local _lb = _kM[_la]
                if _lb == nil then
                    _lb = _jD(_kY, _kZ);
                    _kM[_la] = _lb
                end
                return _lb
            end
            local function _lc(_ld, _le)
                local _lf = _iO(_ky - _ld) - _kA
                local _lg = _kz - _le
                local _lh = _iO(_lg) - _kA
                local _li = (_lg < 0) and 1.5 or 0.5
                return (_lf > 0 and _lf or 0) + _li * (_lh > 0 and _lh or 0)
            end
            local function _lj(_lk, _ll)
                if _kx[_ll * _kE + _lk] then
                    return true
                end
                if _kA >= 1 then
                    for _lm = _ll + _kI, _ll + _kJ do
                        if _lm >= 0 and _lm < _kF then
                            local _ln = _lm * _kE
                            for _lo = _lk - _kH, _lk + _kH do
                                if _lo >= 0 and _lo < _kE and _kx[_ln + _lo] and not (_lo == _lk and _lm == _ll + 1) then
                                    return true
                                end
                            end
                        end
                    end
                end
                return false
            end
            local _lp, _lq, _lr, _ls, _lt = {}, {}, {}, {}, {}
            local _lu = 0
            local function _lv(_lw, _lx, _ly, _lz, _lA)
                _lu += 1
                _lp[_lu], _lq[_lu], _lr[_lu], _ls[_lu], _lt[_lu] = _lw, _lx, _ly, _lz, _lA
            end
            local function _lB(_lC, _lD)
                _lu = 0
                for _lE = -1, 1, 2 do
                    local _lF = _lC + _lE
                    if _kN(_lF, _lD) then
                        if _kS(_lF, _lD) then
                            _lv(_lF, _lD, "walk", 1, false)
                        else
                            if _kX(_lF, _lD + 1) then
                                _lv(_lF, _lD, "walk", 3, true)
                            end
                            local _lG = _lD + 1
                            while _lG < _kF and _lG - _lD <= 40 and _kN(_lF, _lG) and not _kS(_lF, _lG) do
                                _lG += 1
                            end
                            if _lG < _kF and _kN(_lF, _lG) and _kS(_lF, _lG) then
                                _lv(_lF, _lG, "fall", 1 + 0.5 * (_lG - _lD), false)
                            end
                            if _kN(_lC, _lD - 1) and _kN(_lC, _lD - 2) then
                                for _lH = 2, 3 do
                                    local _lI = _lC + (_lH - 1) * _lE
                                    if not (_kN(_lI, _lD) and _kN(_lI, _lD - 1) and _kN(_lI, _lD - 2)) then
                                        break
                                    end
                                    if _lH == 3 and _kS(_lI, _lD) then
                                        break
                                    end
                                    local _lJ = _lC + _lH * _lE
                                    if _kN(_lJ, _lD - 1) and _kN(_lJ, _lD - 2) then
                                        for _lK = 0, 2 do
                                            if not _kN(_lJ, _lD + _lK) then
                                                break
                                            end
                                            if _kS(_lJ, _lD + _lK) then
                                                _lv(_lJ, _lD + _lK, "gap", _lH + 0.5 + 0.5 * _lK, false)
                                                break
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                    for _lL = 1, 3 do
                        if not _kN(_lC, _lD - _lL) then
                            break
                        end
                        if _kN(_lC, _lD - _lL - 1) and _kN(_lF, _lD - _lL) and _kS(_lF, _lD - _lL) and _kN(_lF, _lD - _lL - 1) then
                            _lv(_lF, _lD - _lL, "jump", 1 + 1.5 * _lL, false)
                        end
                    end
                    for _lM = 1, 2 do
                        if _kN(_lC, _lD - 1) and (_lM == 1 or _kN(_lC, _lD - 2)) and _kN(_lF, _lD - _lM) and _kS(_lF, _lD - _lM) and not (_kN(_lC, _lD - _lM - 1) and _kN(_lF, _lD - _lM - 1)) then
                            _lv(_lF, _lD - _lM, "stair", 3 + 1.5 * _lM, false)
                        end
                    end
                end
                if _kB and _kN(_lC, _lD - 1) and _kN(_lC, _lD - 2) and _kN(_lC, _lD - 3) and _kX(_lC, _lD) then
                    _lv(_lC, _lD - 1, "pillar", 4, true)
                end
                return _lu
            end
            local _lN = _kw * _kE + _kv
            local _lO, _lP, _lQ, _lR, _lS = { [_lN] = 0 }, {}, {}, {}, {}
            local _lT, _lU, _lV = {}, {}, 0
            _lV = _ke(_lT, _lU, _lV, _lc(_kv, _kw), _lN)
            local _lW = 0
            local _lX = os.clock()
            while _lV > 0 do
                local _lY
                _lY, _lV = _km(_lT, _lU, _lV)
                if not _lS[_lY] then
                    _lS[_lY] = true
                    local _lZ, _ma = _lY % _kE, _lY // _kE
                    if _lj(_lZ, _ma) then
                        local _mb = {}
                        local _mc = _lY
                        while _mc ~= _lN do
                            local _md = _lP[_mc]
                            table.insert(_mb, 1, {
                                fx = _md % _kE,
                                fy = _md // _kE,
                                x = _mc % _kE,
                                y = _mc // _kE,
                                kind = _lQ[_mc],
                                build = _lR[_mc],
                                key = _md * _kG + _mc,
                            })
                            _mc = _md
                        end
                        return _mb, false, _lS
                    end
                    _lW += 1
                    if _lW > 6500 then
                        return nil, false, _lS
                    end
                    if _lW % 400 == 0 then
                        task.wait()
                        if _kC and _kC() then
                            return nil, false, _lS
                        end
                    end
                    local _me = _lO[_lY]
                    local _mf = _lB(_lZ, _ma)
                    for _mg = 1, _mf do
                        local _mh = _lq[_mg] * _kE + _lp[_mg]
                        if not _lS[_mh] then
                            local _mi = Navigation.BadEdge[_lY * _kG + _mh]
                            if not (_mi and _mi > _lX) then
                                local _mj = _me + _ls[_mg]
                                local _mk = _lO[_mh]
                                if _mk == nil or _mj < _mk then
                                    _lO[_mh], _lP[_mh], _lQ[_mh], _lR[_mh] = _mj, _lY, _lr[_mg], _lt[_mg]
                                    _lV = _ke(_lT, _lU, _lV, _mj + _lc(_lp[_mg], _lq[_mg]), _mh)
                                end
                            end
                        end
                    end
                end
            end
            return nil, true, _lS
        end
        local function _ml(_mm, _mn, _mo)
            local _mp = _mn - _mm.x
            local _mq = _mm.vx or 0
            local _mr = _mm.grounded and 48 or 17
            local _ms = 0
            if _iO(_mp) > _mo then
                _ms = _mp > 0 and 1 or -1
                if _mq * _ms > 0 and (_mq * _mq) / (2 * _mr) >= _iO(_mp) - _mo * 0.5 then
                    _ms = 0
                end
            end
            MovementInput.left = _ms < 0
            MovementInput.right = _ms > 0
        end
        local function _mt(_mu, _mv, _mw)
            local _mx = GetWorld()
            if not OriginalIsDown or not GetCharacterState() then
                if _mx and _mx.goTo then
                    pcall(_mx.goTo, _mu, _mv)
                    task.wait(math.max(0.25, Config.moveStepDelay))
                    return true
                end
                return false
            end
            MovementInput.active = true
            local _my = _mu + 0.5
            local _mz = GetCharacterState()
            if not _mz then
                ReleaseMovementKeys();
                return false
            end
            local _mA = 1.6 + _iO(_my - _mz.x) * 0.38
            local _mB = os.clock()
            while os.clock() - _mB <= _mA and IsSessionAlive() do
                if _mw and _mw() then
                    ReleaseMovementKeys();
                    return false
                end
                local _mC = GetCharacterState()
                if not _mC or _mC.dead then
                    ReleaseMovementKeys();
                    return false
                end
                local _mD, _mE = _iN(_mC.x), _iN(_mC.y - 0.475)
                if _mC.grounded and _mE ~= _mv then
                    ReleaseMovementKeys();
                    return false
                end
                _ml(_mC, _my, 0.1)
                if _mD == _mu and _iO(_mC.x - _my) <= 0.22 and _mC.grounded and _iO(_mC.vx or 0) < 2.2 then
                    ReleaseMovementKeys()
                    return true
                end
                task.wait()
            end
            ReleaseMovementKeys()
            return false
        end
        local function _mF(_mG, _mH)
            MovementInput.active = true
            local _mI = _mG.x + 0.5
            local _mJ = 1.6 + 0.3 * (_mG.y - _mG.fy)
            local _mK = os.clock()
            while os.clock() - _mK <= _mJ and IsSessionAlive() do
                if _mH and _mH() then
                    ReleaseMovementKeys();
                    return false
                end
                local _mL = GetCharacterState()
                if not _mL or _mL.dead then
                    ReleaseMovementKeys();
                    return false
                end
                _ml(_mL, _mI, 0.1)
                if _mL.grounded then
                    local _mM, _mN = _iN(_mL.x), _iN(_mL.y - 0.475)
                    if _mN == _mG.y then
                        if _mM == _mG.x and _iO(_mL.x - _mI) <= 0.25 then
                            ReleaseMovementKeys()
                            return true
                        end
                    elseif _mN ~= _mG.fy then
                        ReleaseMovementKeys()
                        return false
                    end
                end
                task.wait()
            end
            ReleaseMovementKeys()
            return false
        end
        local function _mO(_mP, _mQ)
            if not _mt(_mP.fx, _mP.fy, _mQ) then
                return false
            end
            MovementInput.active = true
            local _mR = _mP.fy - _mP.y
            local _mS = _mP.y + 1
            local _mT = _mS - ((_mR == 1) and 0 or 0.4)
            local _mU = _mP.x + 0.5
            ReleaseMovementKeys()
            task.wait()
            MovementInput.jump = true
            local _mV = os.clock()
            local _mW = false
            while os.clock() - _mV <= 1.8 and IsSessionAlive() do
                if _mQ and _mQ() then
                    ReleaseMovementKeys();
                    return false
                end
                local _mX = GetCharacterState()
                if not _mX or _mX.dead then
                    ReleaseMovementKeys();
                    return false
                end
                if not _mX.grounded then
                    _mW = true
                end
                if MovementInput.jump and (_mX.y <= _mT or (_mW and (_mX.vy or 0) >= 0)) then
                    MovementInput.jump = false
                end
                if _mX.y <= _mS + 0.25 then
                    _ml(_mX, _mU, 0.1)
                else
                    _ml(_mX, _mP.fx + 0.5, 0.15)
                end
                if _mW and _mX.grounded then
                    local _mY, _mZ = _iN(_mX.x), _iN(_mX.y - 0.475)
                    ReleaseMovementKeys()
                    return (_mZ == _mP.y and _mY == _mP.x and _iO(_mX.x - _mU) <= 0.26)
                end
                if not _mW and os.clock() - _mV > 0.38 then
                    break
                end
                task.wait()
            end
            ReleaseMovementKeys()
            return false
        end
        local function _na(_nb, _nc)
            if not _mt(_nb.fx, _nb.fy, _nc) then
                return false
            end
            MovementInput.active = true
            local _nd = GetCharacterState()
            if not _nd then
                ReleaseMovementKeys();
                return false
            end
            local _ne = (_nb.x > _nb.fx) and 1 or -1
            local _nf = _nb.fx + 0.5 + _ne * 0.6
            local _ng = _nd.y
            local _nh = _nb.x + 0.5
            ReleaseMovementKeys()
            local _ni = os.clock()
            local _nj, _nk, _nl = false, false, 0
            while os.clock() - _ni <= 2.2 and IsSessionAlive() do
                if _nc and _nc() then
                    ReleaseMovementKeys();
                    return false
                end
                local _nm = GetCharacterState()
                if not _nm or _nm.dead then
                    ReleaseMovementKeys();
                    return false
                end
                if not _nj then
                    MovementInput.left, MovementInput.right = _ne < 0, _ne > 0
                    if (_nm.x - _nf) * _ne >= 0 or not _nm.grounded then
                        _nj, _nl = true, os.clock()
                        MovementInput.jump = _nm.grounded
                    end
                else
                    if not _nm.grounded then
                        _nk = true
                    end
                    if MovementInput.jump and (_nm.y <= _ng - 1 or (_nk and (_nm.vy or 0) >= 0)) then
                        MovementInput.jump = false
                    end
                    _ml(_nm, _nh, 0.1)
                    if _nk and _nm.grounded then
                        local _nn, _no = _iN(_nm.x), _iN(_nm.y - 0.475)
                        ReleaseMovementKeys()
                        return (_no == _nb.y and _nn == _nb.x and _iO(_nm.x - _nh) <= 0.26)
                    end
                    if not _nk and os.clock() - _nl > 0.38 then
                        break
                    end
                end
                task.wait()
            end
            ReleaseMovementKeys()
            return false
        end
        local function _np(_nq, _nr)
            if not _mt(_nq.fx, _nq.fy, _nr) then
                return false
            end
            MovementInput.active = true
            local _ns = (_nq.x > _nq.fx) and 1 or -1
            local _nt = _nq.y + 1
            local _nu = _nq.fx + 0.5 + _ns * 0.17
            for _nv = 1, 3 do
                local _nw = os.clock()
                while os.clock() - _nw <= 0.8 and IsSessionAlive() do
                    if _nr and _nr() then
                        ReleaseMovementKeys();
                        return false
                    end
                    local _nx = GetCharacterState()
                    if not _nx or _nx.dead then
                        ReleaseMovementKeys();
                        return false
                    end
                    _ml(_nx, _nu, 0.03)
                    if _iO(_nx.x - _nu) <= 0.06 and _iO(_nx.vx or 0) < 1 then
                        break
                    end
                    task.wait()
                end
                ReleaseMovementKeys()
                task.wait()
                local _ny = GetCharacterState()
                if not _ny then
                    return false
                end
                local _nz = _ny.y
                MovementInput.jump = true
                _nw = os.clock()
                local _nA, _nB = false, nil
                while os.clock() - _nw <= 1.8 and IsSessionAlive() do
                    if _nr and _nr() then
                        ReleaseMovementKeys();
                        return false
                    end
                    local _nC = GetCharacterState()
                    if not _nC or _nC.dead then
                        ReleaseMovementKeys();
                        return false
                    end
                    if not _nC.grounded then
                        _nA = true
                    end
                    if MovementInput.jump and (_nC.y <= _nt - 0.1 or (_nA and (_nC.vy or 0) >= 0)) then
                        MovementInput.jump = false
                    end
                    local _nD = (_nv == 1 and _nC.y <= _nt + 0.02) or (_nv == 2 and _nC.y <= _nz - 0.15) or (_nv == 3 and _nC.y <= _nt + 0.25)
                    if _nA and _nD then
                        MovementInput.right, MovementInput.left = _ns > 0, _ns < 0
                    else
                        _ml(_nC, _nu, 0.03)
                    end
                    if _nA and _nC.grounded then
                        _nB = _iN(_nC.y - 0.475)
                        break
                    end
                    if not _nA and os.clock() - _nw > 0.35 then
                        break
                    end
                    task.wait()
                end
                ReleaseMovementKeys()
                if _nB == _nq.y then
                    return _mt(_nq.x, _nq.y, _nr)
                end
                if _nB ~= nil and _nB ~= _nq.fy then
                    return false
                end
                if not _mt(_nq.fx, _nq.fy, _nr) then
                    return false
                end
            end
            return false
        end
        local function _nE(_nF, _nG)
            if not _mt(_nF.fx, _nF.fy, _nG) then
                return false
            end
            if _iP(_nF.fx, _nF.fy) ~= 0 then
                return false
            end
            MovementInput.active = true
            ReleaseMovementKeys()
            task.wait()
            MovementInput.jump = true
            local _nH = os.clock()
            local _nI, _nJ = false, false
            while os.clock() - _nH <= 1.8 and IsSessionAlive() do
                if _nG and _nG() then
                    ReleaseMovementKeys();
                    return false
                end
                local _nK = GetCharacterState()
                if not _nK or _nK.dead then
                    ReleaseMovementKeys();
                    return false
                end
                if not _nK.grounded then
                    _nJ = true
                end
                _ml(_nK, _nF.fx + 0.5, 0.12)
                if MovementInput.jump and (_nK.y < _nF.fy - 0.9 or (_nJ and (_nK.vy or 0) >= 0)) then
                    MovementInput.jump = false
                end
                if not _nI and _nJ and _nK.y < _nF.fy - 0.25 and ((_nK.vy or 0) > -6 or _nK.y < _nF.fy - 0.8) then
                    _nI = _jR(_nF.fx, _nF.fy)
                    if not _nI then
                        ReleaseMovementKeys();
                        return false
                    end
                end
                if _nK.grounded and _nJ then
                    ReleaseMovementKeys()
                    local _nL, _nM = _iN(_nK.x), _iN(_nK.y - 0.475)
                    return _nI and _nL == _nF.x and _nM == _nF.y
                end
                if not _nJ and os.clock() - _nH > 0.38 then
                    break
                end
                task.wait()
            end
            ReleaseMovementKeys()
            return false
        end
        Navigation.ExecWalk = _mt
        Navigation.ExecPillar = _nE
        function Navigation.FollowPath(_nN, _nO)
            local _nP = {}
            for _nQ, _nR in pairs(NoclipOwners) do
                _nP[_nQ] = _nR
            end
            table.clear(NoclipOwners)
            local _nS = ManualNoclipEnabled
            ManualNoclipEnabled = false
            UpdateNoclip()
            MovementInput.active = true
            local _nT = {}
            local function _nU()
                if #_nT == 0 then
                    return
                end
                for _nV = #_nT, 1, -1 do
                    local _nW = _nT[_nV]
                    local _nX, _nY = GetCurrentTile()
                    if not (_nX == _nW.x and _nY == _nW.y - 1) then
                        local _nZ = GetCharacterState()
                        if _nZ and _jy(_nZ, _nW.x, _nW.y, GetPunchRange() - 0.1) and _iP(_nW.x, _nW.y) ~= 0 and IsBreakableItem(_iP(_nW.x, _nW.y)) then
                            WaitAfterPlacement(_nW.x, _nW.y)
                            local _oa = os.clock()
                            while _iP(_nW.x, _nW.y) ~= 0 and os.clock() - _oa < 3.0 and IsSessionAlive() do
                                if _nO and _nO() then
                                    break
                                end
                                PunchTile(_nW.x, _nW.y, false)
                                task.wait(0.15)
                            end
                        end
                        if _iP(_nW.x, _nW.y) == 0 then
                            table.remove(_nT, _nV)
                        end
                    end
                end
            end
            local function _ob(_oc)
                _nU()
                ReleaseMovementKeys()
                MovementInput.active = false
                ManualNoclipEnabled = _nS
                for _od, _oe in pairs(_nP) do
                    NoclipOwners[_od] = _oe
                end
                UpdateNoclip()
                return _oc
            end
            local _of = 1
            while _of <= #_nN and IsSessionAlive() do
                if _nO and _nO() then
                    return _ob(false)
                end
                local _og = _nN[_of]
                local _oh, _oi = _of, false
                if _og.kind == "walk" then
                    local _oj = _og.x - _og.fx
                    while _nN[_oh + 1] and _nN[_oh + 1].kind == "walk" and (_nN[_oh + 1].x - _nN[_oh + 1].fx) == _oj do
                        _oh += 1
                    end
                    local _ok = false
                    for _ol = _of, _oh do
                        if _nN[_ol].build then
                            _ok = true;
                            break
                        end
                    end
                    if _ok then
                        _oi = true
                        for _om = _of, _oh do
                            if _nO and _nO() then
                                return _ob(false)
                            end
                            local _on = _nN[_om]
                            if _on.build and not _jv(_on.x, _on.y) then
                                if not _jR(_on.x, _on.y + 1) then
                                    _oi = false;
                                    break
                                end
                                table.insert(_nT, {
                                    x = _on.x,
                                    y = _on.y + 1
                                })
                                task.wait(0.14)
                            end
                            if not _mt(_on.x, _on.y, _nO) then
                                _oi = false;
                                break
                            end
                            _nU()
                        end
                    else
                        _oi = _mt(_nN[_oh].x, _nN[_oh].y, _nO)
                        _nU()
                    end
                elseif _og.kind == "pillar" then
                    _oi = _nE(_og, _nO)
                    if _oi then
                        table.insert(_nT, {
                            x = _og.fx,
                            y = _og.fy
                        })
                        task.wait(0.08)
                        _nU()
                    end
                elseif _og.kind == "fall" then
                    _oi = _mF(_og, _nO)
                    _nU()
                elseif _og.kind == "jump" then
                    _oi = _mO(_og, _nO)
                    _nU()
                elseif _og.kind == "gap" then
                    _oi = _na(_og, _nO)
                    _nU()
                elseif _og.kind == "stair" then
                    _oi = _np(_og, _nO)
                    _nU()
                end
                ReleaseMovementKeys()
                if not _oi then
                    Navigation.BadEdge[_og.key] = os.clock() + 20
                    return _ob(false)
                end
                _of = _oh + 1
            end
            return _ob(true)
        end
        function Navigation.ClimbUpWithDirt(_oo, _op, _oq, _or, _os, _ot)
            local _ou = GetWorld()
            if not _ou then
                return false
            end
            if _or == nil then
                _or = true
            end
            if _ot == nil then
                _ot = false
            end
            local _ov = math.max(0.24, tonumber(_os) or tonumber(Config.moveStepDelay) or 0.28)
            local _ow = {}
            for _ox, _oy in pairs(NoclipOwners) do
                _ow[_ox] = _oy
            end
            table.clear(NoclipOwners)
            local _oz = ManualNoclipEnabled
            local _oA = Drops.collecting
            ManualNoclipEnabled = false
            Drops.collecting = true
            _ou.speedScale = 1
            UpdateNoclip()
            MovementInput.active = true
            ReleaseMovementKeys()
            local _oB = {}
            local function _oC(_oD)
                if not _or then
                    return
                end
                local _oE = {}
                for _oF in pairs(_oB) do
                    if _oF >= _oD then
                        table.insert(_oE, _oF)
                    end
                end
                table.sort(_oE, function(_oG, _oH)
                    return _oG > _oH
                end)
                for _oI, _oJ in ipairs(_oE) do
                    if _oq and _oq() then
                        return
                    end
                    local _oK = _iP(_oo, _oJ)
                    if _oK ~= 0 and IsBreakableItem(_oK, _oo, _oJ) then
                        WaitAfterPlacement(_oo, _oJ)
                        local _oL = os.clock()
                        while _iP(_oo, _oJ) ~= 0 and (os.clock() - _oL) < 3.5 and IsSessionAlive() do
                            if _oq and _oq() then
                                break
                            end
                            local _oM = GetCharacterState()
                            if _oM and math.abs((_oJ + 0.5) - (_oM.y - 0.475)) > GetPunchRange() - 0.1 then
                                _ou.ghost = true
                                pcall(_ou.goTo, _oo, math.max(0, _oJ - 2))
                                task.wait(0.06)
                            end
                            PunchTile(_oo, _oJ, false)
                            task.wait(0.14)
                        end
                    end
                    if _iP(_oo, _oJ) == 0 then
                        _oB[_oJ] = nil
                    end
                end
            end
            local function _oN()
                if not _or or next(_oB) == nil then
                    return
                end
                local _oO = (_oo <= 2) and {
                    _oo + 1,
                    _oo + 2
                } or ((_oo >= _ou.w - 3) and {
                    _oo - 1,
                    _oo - 2
                } or {
                    _oo + 1,
                    _oo - 1
                })
                for _oP, _oQ in ipairs(_oO) do
                    if IsTileInWorld(_ou, _oQ, _op) and _js(_oQ, _op) and _jv(_oQ, _op) then
                        _mt(_oQ, _op, _oq)
                        task.wait(0.12)
                        break
                    end
                end
                _ou.ghost = true
                local _oR = {}
                for _oS in pairs(_oB) do
                    table.insert(_oR, _oS)
                end
                table.sort(_oR)
                for _oT, _oU in ipairs(_oR) do
                    if _oq and _oq() then
                        break
                    end
                    if _iP(_oo, _oU) ~= 0 and IsBreakableItem(_iP(_oo, _oU), _oo, _oU) then
                        local _oV = math.max(0, _oU - 1)
                        local _oW, _oX = GetCurrentTile()
                        if _oW and _oX and (math.abs(_oW - _oo) > 2 or math.abs(_oX - _oU) > 2) then
                            _ou.ghost = true
                            pcall(_ou.goTo, _oo, _oV)
                            task.wait(0.08)
                        end
                        WaitAfterPlacement(_oo, _oU)
                        local _oY = os.clock()
                        while _iP(_oo, _oU) ~= 0 and (os.clock() - _oY) < 3.5 and IsSessionAlive() do
                            if _oq and _oq() then
                                break
                            end
                            _ou.ghost = true
                            PunchTile(_oo, _oU, false)
                            task.wait(0.14)
                        end
                    end
                    if _iP(_oo, _oU) == 0 then
                        _oB[_oU] = nil
                    end
                end
            end
            local function _oZ(_pa)
                pcall(_oN)
                ReleaseMovementKeys()
                MovementInput.active = false
                Drops.collecting = _oA
                if Config.walkSpeed ~= 100 and Refs.World and not _oA then
                    Refs.World.speedScale = Config.walkSpeed / 100
                end
                ManualNoclipEnabled = _oz
                for _pb, _pc in pairs(_ow) do
                    NoclipOwners[_pb] = _pc
                end
                UpdateNoclip()
                return _pa
            end
            local _pd, _pe = GetCurrentTile()
            if not _pd then
                return _oZ(false)
            end
            if _pd ~= _oo then
                if not _mt(_oo, _pe, _oq) then
                    pcall(_ou.goTo, _oo, _pe)
                    task.wait(_ov)
                end
                _pd, _pe = GetCurrentTile()
                if not _pd then
                    return _oZ(false)
                end
            end
            local _pf = _jJ()
            if IsTileInWorld(_ou, _oo, _pe + 1) and not _jv(_oo, _pe) then
                if _iP(_oo, _pe + 1) == 0 and _jR(_oo, _pe + 1) then
                    _oB[_pe + 1] = _pf
                    task.wait(TilePlaceCooldownSeconds)
                end
            end
            local _pg = 0
            while _pe > _op and IsSessionAlive() do
                if _oq and _oq() then
                    return _oZ(false)
                end
                local _ph = _pe - 1
                if not _ot and _iP(_oo, _ph) ~= 0 and _iY(_oo, _ph) then
                    return _oZ(false)
                end
                if _ot then
                    for _pi = _ph, math.max(0, _ph - 2), -1 do
                        local _pj = _iP(_oo, _pi)
                        if _pj ~= 0 and IsBreakableItem(_pj, _oo, _pi) then
                            local _pk = os.clock()
                            while _iP(_oo, _pi) ~= 0 and (os.clock() - _pk) < 4 and IsSessionAlive() do
                                if _oq and _oq() then
                                    return _oZ(false)
                                end
                                PunchTile(_oo, _pi, false)
                                task.wait(0.15)
                            end
                        end
                    end
                end
                if Drops.walkToX then
                    Drops.walkToX(_oo + 0.5, 0.6)
                end
                local _pl = _pe
                local _pm = (_iP(_oo, _pe) == 0)
                local _pn = _nE({
                    fx = _oo,
                    fy = _pe,
                    x = _oo,
                    y = _ph
                }, _oq)
                if _pn or (_pm and _iP(_oo, _pe) ~= 0) then
                    _oB[_pe] = _pf
                elseif _iP(_oo, _pe) == 0 then
                    if _jR(_oo, _pe) then
                        _oB[_pe] = _pf
                    end
                    task.wait(0.14)
                    pcall(_ou.goTo, _oo, _ph)
                end
                task.wait(math.max(TilePlaceCooldownSeconds, _ov))
                local _po, _pp = GetCurrentTile()
                if _pp and _pp < _pl then
                    _pe = _pp
                    _pg = 0
                else
                    if _iP(_oo, _pl) ~= 0 and _js(_oo, _ph) then
                        pcall(_ou.goTo, _oo, _ph)
                        task.wait(0.18)
                        _po, _pp = GetCurrentTile()
                    end
                    if _pp and _pp < _pl then
                        _pe = _pp
                        _pg = 0
                    else
                        _pg = _pg + 1
                        if _pg >= 3 then
                            return _oZ(false)
                        end
                    end
                end
                _oC(_pe + 2)
            end
            return _oZ(true)
        end
        local function _pq(_pr, _ps, _pt, _pu, _pv)
            local _pw, _px = _pr.w, _pr.h
            local _py = _pt * _pw + _ps
            local _pz = _pv * _pw + _pu
            if _py == _pz then
                return {}
            end
            local _pA = { _py }
            local _pB = { [_py] = -1 }
            local _pC = 1
            local _pD = {
                {
                    0,
                    -1
                },
                {
                    1,
                    0
                },
                {
                    -1,
                    0
                },
                {
                    0,
                    1
                }
            }
            while _pC <= #_pA and _pC <= 3500 do
                local _pE = _pA[_pC]
                _pC = _pC + 1
                if _pE == _pz then
                    local _pF = {}
                    local _pG = _pE
                    while _pG ~= _py do
                        table.insert(_pF, 1, {
                            x = _pG % _pw,
                            y = math.floor(_pG / _pw)
                        })
                        _pG = _pB[_pG]
                    end
                    return _pF
                end
                local _pH, _pI = _pE % _pw, math.floor(_pE / _pw)
                for _pJ, _pK in ipairs(_pD) do
                    local _pL, _pM = _pH + _pK[1], _pI + _pK[2]
                    if _pL >= 0 and _pL < _pw and _pM >= 0 and _pM < _px then
                        local _pN = _pM * _pw + _pL
                        if _pB[_pN] == nil and (_pN == _pz or _js(_pL, _pM)) then
                            _pB[_pN] = _pE
                            table.insert(_pA, _pN)
                        end
                    end
                end
            end
            return nil
        end
        function Navigation.FlyTo(_pO, _pP, _pQ, _pR, _pS)
            local _pT = GetWorld()
            if not _pT or type(_pT.goTo) ~= "function" then
                return false
            end
            local _pU = math.max(0.16, tonumber(_pR) or tonumber(Config.moveStepDelay) or 0.22)
            for _pV = 1, 3 do
                if _pQ and _pQ() then
                    return false
                end
                local _pW, _pX = GetCurrentTile()
                if not _pW then
                    return false
                end
                if _pW == _pO and _pX == _pP then
                    return true
                end
                _pT.ghost = true
                local _pY = _pq(_pT, _pW, _pX, _pO, _pP)
                if _pY and #_pY > 0 then
                    local _pZ = false
                    for _qa, _qb in ipairs(_pY) do
                        if _pQ and _pQ() then
                            return false
                        end
                        _pT.ghost = true
                        pcall(_pT.goTo, _qb.x, _qb.y)
                        task.wait(_pU)
                        local _qc, _qd = GetCurrentTile()
                        if not _qc or (math.abs(_qc - _qb.x) > 2 or math.abs(_qd - _qb.y) > 2) then
                            _pZ = true
                            break
                        end
                    end
                    local _qe, _qf = GetCurrentTile()
                    if not _pZ and _qe == _pO and _qf == _pP then
                        return true
                    end
                end
                local _qg = 0
                local _qh = 160
                while (_pW ~= _pO or _pX ~= _pP) and _qh > 0 and IsSessionAlive() do
                    _qh = _qh - 1
                    if _pQ and _pQ() then
                        return false
                    end
                    _pT.ghost = true
                    local _qi, _qj = GetCurrentTile()
                    if not _qi then
                        return false
                    end
                    _pW, _pX = _qi, _qj
                    if _pW == _pO and _pX == _pP then
                        return true
                    end
                    local _qk = (_pO > _pW and 1) or (_pO < _pW and -1) or 0
                    local _ql = (_pP > _pX and 1) or (_pP < _pX and -1) or 0
                    local _qm, _qn = _pW, _pX
                    if _ql < 0 and _js(_pW, _pX - 1) then
                        _qm, _qn = _pW, _pX - 1
                    elseif _qk ~= 0 and _js(_pW + _qk, _pX) then
                        _qm, _qn = _pW + _qk, _pX
                    elseif _ql ~= 0 and _js(_pW, _pX + _ql) then
                        _qm, _qn = _pW, _pX + _ql
                    elseif _pX > 0 and _js(_pW, _pX - 1) then
                        _qm, _qn = _pW, _pX - 1
                    elseif _pS then
                        _qm, _qn = _pW + _qk, _pX + _ql
                    else
                        break
                    end
                    pcall(_pT.goTo, _qm, _qn)
                    task.wait(_pU)
                    local _qo, _qp = GetCurrentTile()
                    if _qo == _pW and _qp == _pX then
                        _qg = _qg + 1
                        if _qg >= 3 then
                            break
                        end
                    else
                        _qg = 0
                    end
                end
                local _qq, _qr = GetCurrentTile()
                if _qq == _pO and _qr == _pP then
                    return true
                end
            end
            return false
        end
        function Navigation.LegitTo(_qs, _qt, _qu, _qv, _qw)
            local _qx = os.clock()
            local _qy = GetWorld()
            if not _qy then
                return false, "world"
            end
            if _qw == nil then
                _qw = false
            end
            local _qz = _qv or 0.4
            for _qA = 1, 3 do
                if _qu and _qu() then
                    return false, "cancel"
                end
                local _qB, _qC = GetCurrentTile()
                if not _qB then
                    return false, "pos"
                end
                if _qB == _qs and _qC == _qt then
                    return true, os.clock() - _qx
                end
                local _qD = GetCharacterState()
                if _qD and _qz >= 1 and _jy(_qD, _qs, _qt, _qz) then
                    return true, os.clock() - _qx
                end
                local _qE = { [_qt * _qy.w + _qs] = true }
                local _qF = Navigation.AStar(_qB, _qC, _qE, _qs, _qt, _qz, _qw, _qu)
                if _qF and #_qF > 0 then
                    if Navigation.FollowPath(_qF, _qu) then
                        local _qG, _qH = GetCurrentTile()
                        local _qI = GetCharacterState()
                        if (_qG == _qs and _qH == _qt) or (_qI and _jy(_qI, _qs, _qt, _qz + 0.35)) then
                            return true, os.clock() - _qx
                        end
                    end
                else
                    if _qC ~= _qt then
                        local _qJ = (math.abs(_qB - 1) <= math.abs(_qB - (_qy.w - 2))) and 1 or (_qy.w - 2)
                        local _qK = { [_qt * _qy.w + _qJ] = true }
                        local _qL = Navigation.AStar(_qB, _qC, _qK, _qJ, _qt, 0.5, _qw, _qu)
                        if _qL and #_qL > 0 then
                            Navigation.FollowPath(_qL, _qu)
                        end
                    end
                end
                task.wait(0.15)
            end
            return false, "nopath"
        end
        function Navigation.StepGoTo(_qM, _qN, _qO, _qP)
            local _qQ = Navigation.FlyTo(_qM, _qN, _qO, Config.moveStepDelay, _qP == true)
            UpdateNoclip()
            return _qQ, _qQ and 0 or "stuck"
        end
        function Navigation.Go(_qR, _qS, _qT, _qU, _qV)
            local _qW = (Config.moveMethod == "Teleport Mode") or (Config.moveMode == "fly") or (Config.moveMode == "teleport")
            if not _qW then
                local _qX = GetWorld()
                if _qX and not ManualNoclipEnabled then
                    _qX.ghost = false
                end
                local _qY, _qZ = Navigation.LegitTo(_qR, _qS, _qT, _qU, _qV)
                return _qY, _qZ
            end
            return Navigation.StepGoTo(_qR, _qS, _qT, false)
        end
        function Navigation.To(_ra, _rb, _rc, _rd, _re)
            local _rf = Navigation.Go(_ra, _rb, _rc, _rd, _re)
            return _rf
        end
        local _rg = nil
        local function _rh()
            if not _rg and GetGC and debug and debug.info then
                for _ri, _rj in ipairs(GetGC(true)) do
                    if type(_rj) == "function" then
                        local _rk, _rl = pcall(debug.info, _rj, "n")
                        if _rk and _rl == "act" and GetUpvalue then
                            local _rm, _rn = pcall(GetUpvalue, _rj, 1)
                            local _ro, _rp = pcall(GetUpvalue, _rj, 2)
                            local _rq, _rr = pcall(GetUpvalue, _rj, 4)
                            local _rs, _rt = pcall(GetUpvalue, _rj, 5)
                            if _rm and typeof(_rn) == "Instance" and _rn.ClassName == "Players" and _ro and type(_rp) == "number" and _rq and type(_rr) == "number" and _rs and type(_rt) == "number" then
                                _rg = _rj
                                break
                            end
                        end
                    end
                end
            end
            if _rg and GetUpvalue then
                local _ru, _rv = pcall(GetUpvalue, _rg, 2)
                local _rw, _rx = pcall(GetUpvalue, _rg, 4)
                local _ry, _rz = pcall(GetUpvalue, _rg, 5)
                if _ru and _rw and _ry and type(_rv) == "number" and type(_rx) == "number" and type(_rz) == "number" and _rx > 0 then
                    return _rv, _rz, _rx
                end
            end
            local _rA = PlayerGui:FindFirstChild("GameGui")
            local _rB = _rA and _rA:FindFirstChild("World")
            local _rC = _rB and _rB:FindFirstChild("Camera")
            local _rD = _rC and _rC:FindFirstChild("Tiles")
            if _rD and _rD:IsA("GuiObject") then
                local _rE = 64
                local _rF = -_rD.Position.X.Offset / _rE
                local _rG = -_rD.Position.Y.Offset / _rE
                return _rF, _rG, _rE
            end
            return nil
        end
        function Navigation.ScreenToTile(_rH)
            local _rI, _rJ, _rK = _rh()
            if not _rI then
                return nil
            end
            local _rL = PlayerGui:FindFirstChild("GameGui")
            local _rM = (_rL and _rL:FindFirstChild("World")) or PlayerGui:FindFirstChild("World", true)
            if not _rM or not _rM:IsA("GuiObject") then
                return nil
            end
            local _rN = _rM:FindFirstChildWhichIsA("UIScale", true)
            local _rO = _rN and _rN.Scale or 1
            local _rP = (Vector2.new(_rH.X, _rH.Y) - _rM.AbsolutePosition) / _rO
            return _iN(_rI + _rP.X / _rK), _iN(_rJ + _rP.Y / _rK)
        end
        local function _rQ(_rR, _rS)
            if _rS or not Navigation.clickOn then
                return
            end
            if _rR.UserInputType ~= Enum.UserInputType.MouseButton1 and _rR.UserInputType ~= Enum.UserInputType.Touch then
                return
            end
            if Config.clickTpShift and not (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)) then
                return
            end
            local _rT, _rU = Navigation.ScreenToTile(_rR.Position)
            if not _rT then
                ShowNotification("Click TP: posisi klik tidak terbaca.")
                return
            end
            Navigation.token += 1
            local _rV = Navigation.token
            task.spawn(function()
                local _rW = os.clock()
                local _rX, _rY = Navigation.Go(_rT, _rU, function()
                    return Navigation.token ~= _rV or not Navigation.clickOn or not IsSessionAlive()
                end, 0.4, true)
                if _rX then
                    Navigation.last = string.format("Sampai (%d,%d) dalam %.2fs", _rT, _rU, os.clock() - _rW)
                    ShowNotification(Navigation.last)
                elseif _rY ~= "cancel" then
                    Navigation.last = "Gagal (" .. tostring(_rY) .. ")"
                    ShowNotification("Click TP gagal: " .. tostring(_rY))
                end
            end)
        end
        function Navigation.StartClick()
            if Navigation.clickOn then
                return true
            end
            if not _rh() then
                ShowNotification("Click TP: data kamera game tidak ditemukan.")
                return false
            end
            Navigation.clickOn = true
            Navigation.conn = TrackConnection(UserInputService.InputBegan:Connect(_rQ))
            return true
        end
        function Navigation.StopClick()
            if not Navigation.clickOn then
                return false
            end
            Navigation.clickOn = false
            Navigation.token += 1
            if Navigation.conn then
                Navigation.conn:Disconnect()
                Navigation.conn = nil
            end
            ReleaseMovementKeys()
            return true
        end
    end)()
end
local LastDropTime = 0
-- [11] DROP LOCK, WARP WORLD, REJOIN, DAN POSISI TERSIMPAN.
local function DropLocks(_sb)
    _sb = math.floor(tonumber(_sb) or 0)
    if _sb < 1 or _sb > MaxDropAmount then
        ShowNotification("Jumlah WL tidak valid!")
        return false
    end
    local _sc = os.clock()
    if _sc - LastDropTime < DropCooldownSeconds then
        task.wait(DropCooldownSeconds - (_sc - LastDropTime))
    end
    LastDropTime = os.clock()
    local _sd = Config.dropId or 242
    if DropItemRemote then
        pcall(function()
            DropItemRemote:FireServer(_sd, _sb)
        end)
        ShowNotification(string.format("Drop %d %s dikirim!", _sb, GetItemName(_sd)))
        return true
    elseif HasNetModule and type(NetModule) == "table" and NetModule.drop then
        pcall(NetModule.drop.send, {
            id = _sd,
            n = _sb
        })
        ShowNotification(string.format("Drop %d %s dikirim!", _sb, GetItemName(_sd)))
        return true
    end
    ShowNotification("Remote DropItem tidak ditemukan!")
    return false
end
local QueueReloadOnTeleport
local function WarpToWorld(_sg)
    _sg = TrimText(_sg):upper()
    if _sg == "" then
        ShowNotification("Nama world tidak boleh kosong!")
        return false
    end
    Config.lastWorld = _sg
    SaveConfig()
    if QueueReloadOnTeleport then
        pcall(QueueReloadOnTeleport)
    end
    local _sh = Refs.Menu
    if _sh and type(rawget(_sh, "enter")) == "function" then
        pcall(_sh.enter, _sg)
        ShowNotification("Memasuki world: " .. _sg)
        return true
    end
    local _si = GetWorld()
    if _si and type(rawget(_si, "enter")) == "function" then
        pcall(_si.enter, _sg)
        ShowNotification("Memasuki world: " .. _sg)
        return true
    end
    ShowNotification("Fungsi enter world tidak ditemukan.")
    return false
end
local function RejoinCurrentServer()
    local _sk = GetWorldName()
    if _sk ~= "" then
        Config.lastWorld = _sk
        SaveConfig()
    end
    if QueueReloadOnTeleport then
        pcall(QueueReloadOnTeleport)
    end
    pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, ClientPlayer)
    end)
end
local function SavePosition(_sm)
    local _sn, _so = GetCurrentTile()
    if not _sn then
        ShowNotification("Posisi karakter belum terbaca!")
        return false
    end
    local _sp = "pos" .. tostring(_sm)
    Config[_sp] = {
        x = _sn,
        y = _so,
        world = GetWorldName()
    }
    SaveConfig()
    ShowNotification(string.format("Pos %d disimpan di (%d, %d) [%s]", _sm, _sn, _so, GetWorldName()))
    return true
end
local function ShowPositions()
    local _sr, _ss = GetCurrentTile()
    local _st, _su = Config.pos1 or {}, Config.pos2 or {}
    local _sv = string.format("Sekarang: (%s, %s) | Pos1: (%s, %s) | Pos2: (%s, %s)", _sr and tostring(_sr) or "-", _ss and tostring(_ss) or "-", _st.x and tostring(_st.x) or "-", _st.y and tostring(_st.y) or "-", _su.x and tostring(_su.x) or "-", _su.y and tostring(_su.y) or "-")
    ShowNotification(_sv, "Info Posisi")
end
local function GoToSavedPosition(_sx, _sy)
    local _sz = "pos" .. tostring(_sx)
    local _sA = Config[_sz]
    if type(_sA) ~= "table" or type(_sA.x) ~= "number" or type(_sA.y) ~= "number" then
        ShowNotification("Pos " .. tostring(_sx) .. " belum disimpan!")
        return false
    end
    local _sB = Navigation.To(_sA.x, _sA.y, nil, 0.3, true)
    if _sB then
        local _sC = tonumber(_sy) or tonumber(Config.winDrop) or 0
        if _sC >= 1 then
            task.wait(0.15)
            DropLocks(_sC)
        end
    end
    return _sB
end
local SyncFeatureControls
local FloatingGridGui = nil
local GridMode = "farm"
local RefreshGridGui = nil
local SetGridMode = nil
-- [12] STATE SEMUA BOT: Farm, Clear, Farmer, DF, Splice, Factory, Move, Guard.
local AutoFarm = {
    on = false,
    token = 0,
    Override = nil,
    Quiet = false,
    stats = {
        status = "Mati",
        placed = 0,
        broken = 0,
        picked = 0,
        fail = 0,
        cycles = 0
    },
}
local AutoClear = {
    on = false,
    token = 0,
    status = "Mati",
    stats = {
        scanned = 0,
        broken = 0,
        picked = 0,
        skipped = 0,
        left = 0,
        pass = 0,
        row = -1
    },
}
local Farmer = {
    on = false,
    token = 0,
    status = "Mati",
    stats = {
        totalTrees = 0,
        ready = 0,
        harvested = 0,
        planted = 0,
        skipped = 0,
        picked = 0
    },
}
local DirtFarm = {
    on = false,
    token = 0,
    status = "Mati",
    stats = {
        topDirtY = 0,
        bedrockY = 0,
        broken = 0,
        placed = 0,
        picked = 0,
        step = "-"
    },
}
local AutoSplice = {
    on = false,
    roaming = false,
    token = 0,
    status = "Mati",
    made = 0,
    planted = 0,
    fail = {},
    skip = {},
}
local SeedFactory = {
    on = false,
    token = 0,
    phase = "-",
    status = "Mati",
    harvested = 0,
    planted = 0,
    dropped = 0,
    traveling = false,
    home = "",
    Zone = nil,
    skip = {},
}
local AutoMove = {
    on = false,
    token = 0,
    phase = "-",
    status = "Mati",
    collected = 0,
    dropped = 0,
    traveling = false,
    pauseCollect = false,
}
local BackpackManager = {
    recycled = 0,
    converted = 0,
    status = "-",
}
local Guard = {
    on = false,
    mode = "idle",
    allow = {},
    alerted = {},
    saved = nil,
    token = 0,
    backAt = 0,
    calmAt = nil,
    leftFg = nil,
    status = "Mati",
    detected = 0,
    hereText = "tidak ada",
    staffServerText = "tidak ada",
}
local Reconnect = {
    busy = false,
    leaving = false,
    last = nil,
    lastAt = 0,
    count = 0,
    status = "-",
}
local AutoChat = {
    on = false,
    sent = 0,
    last = "-",
    nextAt = 0
}
local function IsTreeItem(_sU)
    local _sV = ItemDatabase and ItemDatabase[_sU]
    return type(_sV) == "table" and (_sV.kind == "seed" or type(_sV.tree) == "table" or type(_sV.grow) == "number")
end
-- [13] WAKTU SIAP PANEN BERDASARKAN DATA POHON / WAKTU PENANAMAN.
local function GetTreeReadyAt(_sX, _sY, _sZ, _ta)
    _sX = _sX or GetWorld()
    if not _sX then
        return nil
    end
    local _tb = ItemDatabase[_ta]
    if not _tb then
        return nil
    end
    local _tc = tonumber(_tb.grow) or tonumber(_tb.baseGrow) or 31
    local _td = _sZ * _sX.w + _sY
    if type(_sX.treeLook) == "function" then
        pcall(_sX.treeLook, _sY, _sZ)
    end
    if not Refs.Trees then
        Refs.Scan()
    end
    local _te = Refs.Trees and Refs.Trees[_td]
    if type(_te) == "table" then
        if _te.ripe == true or _te.fruitMade == true or _te.step == 1 then
            return 0
        end
        if type(_te.tree) == "table" and type(_te.tree.p) == "number" then
            return _te.tree.p + _tc
        end
        if type(_te.p) == "number" then
            return _te.p + _tc
        end
    end
    local _tf = _sX.placedAt and _sX.placedAt.fg
    if _tf and type(_tf[_td]) == "number" then
        return workspace:GetServerTimeNow() - (os.clock() - _tf[_td]) + _tc
    end
    return nil
end
local function IsTreeReady(_th, _ti, _tj, _tk)
    local _tl = GetTreeReadyAt(_th, _ti, _tj, _tk)
    if not _tl then
        return false
    end
    return workspace:GetServerTimeNow() >= _tl
end
-- Memeriksa tile kosong, penopang, izin edit, dan jalur tanam.
local function CanPlantSeedAt(_tn, _to, _tp, _tq)
    _tn = _tn or GetWorld()
    if not IsTileInWorld(_tn, _to, _tp) or _tp + 1 >= _tn.h then
        return false
    end
    if (ReadTile(_tn, "fg", _to, _tp) or 0) ~= 0 then
        return false
    end
    local _tr = ReadTile(_tn, "fg", _to, _tp + 1) or 0
    if _tr == 0 then
        return false
    end
    local _ts = ItemDatabase[_tr]
    if not _ts or _ts.kind == "seed" then
        return false
    end
    if not (Navigation.SolidAt(_to, _tp + 1) or _ts.platform) then
        return false
    end
    local _tu, _tv = pcall(function()
        if _tn.areas and type(_tn.areas.canEdit) == "function" and not _tn.areas.canEdit(_to, _tp) then
            return false
        end
        if type(_tn.builderOk) == "function" and not _tn.builderOk(_to, _tp, true) then
            return false
        end
        local _tt = _tq and ItemDatabase[_tq]
        if _tt and type(_tn.needsWay) == "function" and _tn.needsWay(_tt) and type(_tn.wayBlocked) == "function" and _tn.wayBlocked(_to, _tp) then
            return false
        end
        return true
    end)
    return (not _tu) or _tv
end
do
    (function()
        local function _tw(_tx, _ty, _tz)
            return _ty >= _tx.x - 0.15 and _ty < _tx.x + 1.15 and _tz >= _tx.y - 0.15 and _tz < _tx.y + 1.15
        end
        local function _tA(_tB, _tC)
            if type(_tB) ~= "table" or _tB.taking or _tB.pending or _tB.display or (_tB.n or 0) <= 0 or type(_tB.x) ~= "number" then
                return false
            end
            if _tB.armed == false and _tB.id ~= 112 then
                return false
            end
            local _tD = _tB.uid and PickupCooldowns[_tB.uid]
            return not (_tD and _tC < _tD)
        end
        -- [14] PENGAMBILAN DROP DAN PEMBARUAN INVENTORY / STATISTIK.
        function Drops.applyTaken(_tE, _tF)
            local _tG = Drops.list
            if not _tG or not table.find(_tG, _tE) then
                return
            end
            if not Drops.update and Drops.findUpdate then
                Drops.findUpdate()
            end
            if Drops.update then
                local _tH = pcall(Drops.update, _tE, _tF)
                if _tH then
                    if _tF > 0 then
                        _tE.flown = nil
                        if typeof(_tE.frame) == "Instance" then
                            pcall(function()
                                _tE.frame.Visible = not _tE.culled
                            end)
                        end
                    end
                    return
                end
            end
            _tE.n = _tF
            if _tF > 0 then
                _tE.flown = nil
                if typeof(_tE.frame) == "Instance" then
                    pcall(function()
                        _tE.frame.Visible = not _tE.culled
                    end)
                end
            else
                local _tI = table.find(_tG, _tE)
                if _tI then
                    table.remove(_tG, _tI)
                end
                if typeof(_tE.frame) == "Instance" then
                    pcall(function()
                        _tE.frame:Destroy()
                    end)
                end
            end
        end
        function Drops.waitNearDrops(_tJ)
            local _tK = Drops.list
            if not _tK then
                return
            end
            task.wait(0.15)
            local _tL = os.clock()
            while os.clock() - _tL < (_tJ or 0.45) and IsSessionAlive() do
                local _tM = GetCharacterState()
                if not _tM or not _tM.x then
                    return
                end
                local _tN = false
                for _tO, _tP in ipairs(_tK) do
                    if type(_tP) == "table" and type(_tP.x) == "number" and (_tP.n or 0) > 0 and _tP.armed ~= false and math.abs(_tP.x - _tM.x) < 0.6 and _tP.y + 0.3 > _tM.y - 0.95 and _tP.y - 0.3 < _tM.y then
                        local _tQ = true
                        if _tP.id ~= 112 and Refs.Inv and type(Refs.Inv.room) == "function" then
                            local _tR, _tS = pcall(function()
                                return Refs.Inv:room(_tP.id)
                            end)
                            if _tR and type(_tS) == "number" and _tS <= 0 then
                                _tQ = false
                            end
                        end
                        if _tQ then
                            _tN = true;
                            break
                        end
                    end
                end
                if not _tN then
                    return
                end
                task.wait()
            end
        end
        function Drops.waitSpawn(_tT)
            if not Drops.list and Drops.findRefs then
                Drops.findRefs()
            end
            local _tU = 0.1
            pcall(function()
                _tU = ClientPlayer:GetNetworkPing()
            end)
            local _tV = math.clamp(0.15 + 2.5 * _tU, 0.25, 0.85)
            local _tW = nil
            for _tX, _tY in ipairs(_tT) do
                local _tZ = Drops.brokeAt[_tY.x .. "," .. _tY.y]
                if _tZ and os.clock() - _tZ < _tV and (not _tW or _tZ > _tW) then
                    _tW = _tZ
                end
            end
            if not _tW then
                return
            end
            local _ua = Drops.list
            while os.clock() - _tW < _tV and IsSessionAlive() do
                if _ua then
                    for _ub, _uc in ipairs(_ua) do
                        if type(_uc) == "table" and type(_uc.x) == "number" and (_uc.born or 0) >= _tW - 0.2 then
                            for _ud, _ue in ipairs(_tT) do
                                if _tw(_ue, _uc.x, _uc.y) then
                                    task.wait(0.05)
                                    return
                                end
                            end
                        end
                    end
                end
                task.wait()
            end
        end
        local function _uf(_ug)
            local _uh = GetWorld()
            local _ui = _uh and rawget(_uh, "takeDrop")
            if type(_ui) ~= "function" and not TakeDropRemote then
                return false
            end
            local _uj = os.clock()
            if not _tA(_ug, _uj) then
                return false
            end
            local _uk = _ug.n
            if _ug.id ~= 112 and Refs.Inv and type(Refs.Inv.room) == "function" then
                local _ul, _um = pcall(function()
                    return Refs.Inv:room(_ug.id)
                end)
                if _ul and type(_um) == "number" then
                    _uk = math.min(_uk, _um)
                end
            end
            if _uk <= 0 then
                if _ug.uid then
                    PickupCooldowns[_ug.uid] = _uj + 1
                end
                local _un = Webhook.LastFull[_ug.id]
                if not _un or _uj - _un > 120 then
                    Webhook.LastFull[_ug.id] = _uj
                    Webhook.Send("full", "Inventori penuh: " .. GetItemName(_ug.id) .. " tidak bisa diambil lagi")
                end
                return false
            end
            _ug.taking = true
            if typeof(_ug.frame) == "Instance" then
                pcall(function()
                    _ug.frame.Visible = false
                end)
            end
            local _uo, _up
            if type(_ui) == "function" then
                _uo, _up = pcall(_ui, _ug.uid, _uk)
            else
                _uo, _up = pcall(TakeDropRemote.InvokeServer, TakeDropRemote, _ug.uid, _uk)
            end
            _ug.taking = false
            if not (_uo and type(_up) == "number" and _up > 0) then
                AutoFarm.stats.fail = AutoFarm.stats.fail + 1
                _ug.refused = os.clock()
                _ug.failN = (_ug.failN or 0) + 1
                if _ug.uid then
                    PickupCooldowns[_ug.uid] = os.clock() + math.min(8, _ug.failN)
                end
                _ug.flown = nil
                if typeof(_ug.frame) == "Instance" then
                    pcall(function()
                        _ug.frame.Visible = not _ug.culled
                    end)
                end
                return false
            end
            if _ug.uid then
                PickupCooldowns[_ug.uid] = nil
            end
            if _ug.id == 112 then
                if Refs.Gems and type(Refs.Gems.addGems) == "function" then
                    pcall(Refs.Gems.addGems, _up)
                end
            elseif Refs.Inv and type(Refs.Inv.add) == "function" then
                pcall(function()
                    Refs.Inv:add(_ug.id, _up)
                end)
            end
            Drops.applyTaken(_ug, math.max(0, (_ug.n or 0) - _up))
            SessionStats.Collected = SessionStats.Collected + _up
            SessionStats.Items[_ug.id] = (SessionStats.Items[_ug.id] or 0) + _up
            AutoFarm.stats.picked = AutoFarm.stats.picked + _up
            if AutoClear.on then
                AutoClear.stats.picked = AutoClear.stats.picked + _up
            end
            if Farmer.on then
                Farmer.stats.picked = Farmer.stats.picked + _up
            end
            if DirtFarm.on then
                DirtFarm.stats.picked = DirtFarm.stats.picked + _up
            end
            return true
        end
        function Drops.walkToX(_uq, _ur)
            local _us = GetCharacterState()
            if not _us or _us.dead then
                return false
            end
            if math.abs(_uq - _us.x) <= 0.18 and math.abs(_us.vx or 0) < 2.0 then
                ReleaseMovementKeys()
                return true
            end
            MovementInput.active = true
            local _ut = 0.14
            local _uu = os.clock()
            while IsSessionAlive() and (AutoFarm.on or AutoFarm.Override ~= nil) and (os.clock() - _uu) < (_ur or 1.6) do
                local _uv = GetCharacterState()
                if not _uv or _uv.dead then
                    break
                end
                local _uw = _uq - _uv.x
                local _ux = _uv.vx or 0
                local _uy = _uv.grounded and 48 or 17
                local _uz = 0
                if math.abs(_uw) > _ut then
                    _uz = (_uw > 0) and 1 or -1
                    if _ux * _uz > 0 and (_ux * _ux) / (2 * _uy) >= math.abs(_uw) - _ut * 0.5 then
                        _uz = 0
                    end
                end
                MovementInput.left = (_uz < 0)
                MovementInput.right = (_uz > 0)
                if math.abs(_uw) <= 0.18 and _uv.grounded and math.abs(_ux) < 2.2 then
                    ReleaseMovementKeys()
                    return true
                end
                task.wait()
            end
            ReleaseMovementKeys()
            return false
        end
        function Drops.touchAll(_uA, _uB, _uC)
            if type(_uA) ~= "table" or #_uA == 0 then
                return false
            end
            local _uD = GetWorld()
            if not _uD then
                return false
            end
            local _uE, _uF = _uB, _uB
            local _uG = {}
            for _uH, _uI in ipairs(_uA) do
                if not Navigation.SolidAt(_uI.x, _uI.y) then
                    if _uI.y == _uC and math.abs(_uI.x - _uB) <= 3 then
                        if _uI.x < _uE then
                            _uE = _uI.x
                        end
                        if _uI.x > _uF then
                            _uF = _uI.x
                        end
                    elseif _uI.y < _uC and math.abs(_uI.x - _uB) <= 2 then
                        if not _uG[_uI.x] or _uI.y < _uG[_uI.x] then
                            _uG[_uI.x] = _uI.y
                        end
                    end
                end
            end
            local _uJ = MovementInput.active
            MovementInput.active = true
            Drops.collecting = true
            _uD.speedScale = 1
            local function _uK(_uL)
                ReleaseMovementKeys()
                local _uM = (_uL <= _uC - 2)
                MovementInput.jump = true
                local _uN = os.clock()
                local _uO = false
                while IsSessionAlive() and (AutoFarm.on or AutoFarm.Override ~= nil) and (os.clock() - _uN) < 1.1 do
                    local _uP = GetCharacterState()
                    if not _uP or _uP.dead then
                        break
                    end
                    if not _uP.grounded then
                        _uO = true
                        if not _uM or _uP.y <= (_uL + 0.6) or (_uP.vy or 0) >= 0 then
                            MovementInput.jump = false
                        end
                    end
                    if _uO and _uP.grounded then
                        break
                    end
                    if not _uO and (os.clock() - _uN) > 0.32 then
                        break
                    end
                    task.wait()
                end
                ReleaseMovementKeys()
            end
            pcall(function()
                if _uE < _uB then
                    Drops.walkToX(_uE + 0.5, 1.5)
                    if _uG[_uE] then
                        _uK(_uG[_uE])
                        _uG[_uE] = nil
                    else
                        task.wait(0.06)
                    end
                end
                if _uF > _uB then
                    Drops.walkToX(_uF + 0.5, 1.8)
                    if _uG[_uF] then
                        _uK(_uG[_uF])
                        _uG[_uF] = nil
                    else
                        task.wait(0.06)
                    end
                end
                for _uQ, _uR in pairs(_uG) do
                    if not IsSessionAlive() or not (AutoFarm.on or AutoFarm.Override ~= nil) then
                        break
                    end
                    Drops.walkToX(_uQ + 0.5, 1.4)
                    _uK(_uR)
                end
                if IsSessionAlive() and (AutoFarm.on or AutoFarm.Override ~= nil) then
                    Drops.walkToX(_uB + 0.5, 1.6)
                end
            end)
            ReleaseMovementKeys()
            Drops.collecting = false
            if Config.walkSpeed ~= 100 and Refs.World then
                Refs.World.speedScale = Config.walkSpeed / 100
            end
            MovementInput.active = _uJ
            return true
        end
        local _uS = 0
        TrackConnection(RunService.Heartbeat:Connect(function()
            if not IsSessionAlive() then
                return
            end
            if AutoMove and AutoMove.pauseCollect then
                return
            end
            local _uT = (AutoFarm.Override and AutoFarm.Override.offsets) or Config.farmGrid
            local _uU = (AutoFarm.on and Config.farmTake) or (AutoFarm.Override ~= nil)
            local _uV = Config.collectAround or (AutoClear.on and Config.clearTake) or (Farmer.on and Config.harvestTake) or (DirtFarm.on and Config.dfTake) or AutoSplice.on or SeedFactory.on
            if not _uU and not _uV then
                return
            end
            local _uW = os.clock()
            if _uW < (Drops.nextTick or 0) then
                return
            end
            Drops.nextTick = _uW + ((Config.collectMode == "Remote") and 0.1 or 0.2)
            local _uX = Drops.list
            if not _uX then
                if _uW >= _uS then
                    _uS = _uW + 5
                    if Drops.findRefs then
                        Drops.findRefs()
                    else
                        Refs.Scan()
                    end
                end
                return
            end
            local _uY = GetCharacterState()
            if not _uY or type(_uY.x) ~= "number" then
                return
            end
            local _uZ, _va = _uY.x, _uY.y - 0.475
            if Config.collectMode ~= "Remote" then
                local _vb = {}
                for _vc, _vd in ipairs(_uX) do
                    if type(_vd) == "table" and type(_vd.x) == "number" and math.abs(_vd.x - _uZ) <= 1.5 and math.abs(_vd.y - _va) <= 1.5 then
                        _vb[_vd] = _vd.n or 0
                    end
                end
                for _ve, _vf in pairs(Drops.seen or {}) do
                    if _vb[_ve] == nil and not table.find(_uX, _ve) and _ve.id and _vf > 0 then
                        SessionStats.Collected = SessionStats.Collected + _vf
                        SessionStats.Items[_ve.id] = (SessionStats.Items[_ve.id] or 0) + _vf
                        AutoFarm.stats.picked = AutoFarm.stats.picked + _vf
                        if AutoClear.on then
                            AutoClear.stats.picked = AutoClear.stats.picked + _vf
                        end
                        if Farmer.on then
                            Farmer.stats.picked = Farmer.stats.picked + _vf
                        end
                        if DirtFarm.on then
                            DirtFarm.stats.picked = DirtFarm.stats.picked + _vf
                        end
                    end
                end
                Drops.seen = _vb
                return
            end
            if #_uX == 0 then
                return
            end
            local _vg, _vh = math.floor(_uZ), math.floor(_va)
            local _vi = (tonumber(Config.collectRadius) or 3) + 0.25
            local _vj = SeedFactory.Zone
            if _vj and _vj.world ~= GetWorldName() then
                _vj = nil
            end
            for _vk = #_uX, 1, -1 do
                local _vl = _uX[_vk]
                if _tA(_vl, _uW) and not (_vj and math.abs(_vl.x - _vj.x) <= 2.5 and math.abs(_vl.y - _vj.y) <= 2.5) then
                    local _vm = _uV and math.abs(_vl.x - _uZ) <= _vi and math.abs(_vl.y - _va) <= _vi
                    if not _vm and _uU then
                        for _vn, _vo in pairs(_uT) do
                            if _vo then
                                local _vp, _vq = tostring(_vn):match("^(-?%d+),(-?%d+)$")
                                if _vp and _vq then
                                    local _vr, _vs = _vg + tonumber(_vp), _vh + tonumber(_vq)
                                    if _tw({
                                        x = _vr,
                                        y = _vs
                                    }, _vl.x, _vl.y) then
                                        _vm = true
                                        break
                                    end
                                end
                            end
                        end
                    end
                    if _vm then
                        task.spawn(_uf, _vl)
                    end
                end
            end
        end))
    end)()
end
-- [15] AUTO FARM: penempatan, pukulan, multitarget, dan pengambilan hasil.
local StartAutoFarm, StopAutoFarm, RunAutoFarmCycle
do
    (function()
        local _vw = {
            {
                1,
                0
            },
            {
                -1,
                0
            },
            {
                0,
                1
            },
            {
                0,
                -1
            },
            {
                1,
                1
            },
            {
                1,
                -1
            },
            {
                -1,
                1
            },
            {
                -1,
                -1
            }
        }
        local function _vx()
            local _vy = GetWorld()
            local _vz = _vy and rawget(_vy, "raymanOn")
            if type(_vz) ~= "function" then
                return false
            end
            local _vA, _vB = pcall(_vz)
            return _vA and _vB == true
        end
        local function _vC(_vD, _vE, _vF)
            local _vG = {}
            for _vH, _vI in ipairs(_vF) do
                _vG[_vI.x .. "," .. _vI.y] = _vI
            end
            local _vJ, _vK = nil, nil
            for _vL, _vM in ipairs(_vw) do
                local _vN = {}
                for _vO = 1, 3 do
                    local _vP = _vG[(_vD + _vM[1] * _vO) .. "," .. (_vE + _vM[2] * _vO)]
                    if _vP then
                        _vN[#_vN + 1] = _vP
                    end
                end
                if #_vN >= 2 and #_vN > (_vJ and #_vJ or 0) then
                    _vJ, _vK = _vN, _vM
                end
            end
            return _vJ, _vK
        end
        local function _vQ(_vR)
            local _vS = GetCharacterState()
            if not _vS or not _vS.x then
                return
            end
            if HasNetModule and type(NetModule) == "table" and NetModule.act then
                pcall(NetModule.act.send, {
                    kind = 4,
                    x = _vS.x + _vR[1],
                    y = _vS.y - 0.475 + _vR[2]
                })
            end
        end
        local function _vT()
            local _vU = (AutoFarm.Override and AutoFarm.Override.offsets) or Config.farmGrid
            local _vV = {}
            for _vW, _vX in pairs(_vU) do
                if _vX then
                    local _vY, _vZ = tostring(_vW):match("^(-?%d+),(-?%d+)$")
                    _vY, _vZ = tonumber(_vY), tonumber(_vZ)
                    if _vY and _vZ and not (_vY == 0 and _vZ == 0) then
                        table.insert(_vV, {
                            dx = _vY,
                            dy = _vZ
                        })
                    end
                end
            end
            table.sort(_vV, function(_wa, _wb)
                if _wa.dy ~= _wb.dy then
                    return _wa.dy < _wb.dy
                end
                return _wa.dx < _wb.dx
            end)
            return _vV
        end
        local function _wc(_wd, _we, _wf)
            local _wg = ReadTile(_wd, "fg", _we, _wf)
            if _wg == nil then
                return false
            end
            if _wg ~= 0 then
                return IsBreakableItem(_wg)
            end
            local _wh = ReadTile(_wd, "bg", _we, _wf)
            return Config.farmBreakBg and _wh ~= nil and _wh ~= 0 and IsBreakableItem(_wh)
        end
        local function _wi(_wj, _wk)
            while AutoFarm.on and AutoFarm.token == _wj and IsSessionAlive() do
                local _wl = GetWorld()
                if not _wl or GetWorldName() ~= _wk.world then
                    AutoFarm.stats.status = "World berubah, berhenti"
                    break
                end
                local _wm = (AutoFarm.Override and AutoFarm.Override.mode) or Config.farmMode
                local _wn = _wm ~= "Break saja"
                local _wo = _wm ~= "Place saja"
                local _wp = (AutoFarm.Override and AutoFarm.Override.block) or Config.farmPlaceId
                if not AutoFarm.Override and Config.farmAutoDropSeed then
                    local _wq = IsTreeItem(_wp) and _wp or GetSeedIdFromBlock(_wp)
                    local _wr = tonumber(Config.farmSeedDropAt) or 200
                    if _wq and CountInventoryItem(_wq) >= _wr then
                        local _ws = tonumber(Config.farmSeedKeep) or 0
                        local _wt = CountInventoryItem(_wq) - _ws
                        if _wt > 0 and SeedFactory and type(SeedFactory.ExternalDropSeed) == "function" then
                            AutoFarm.stats.status = string.format("Auto Drop Seed %s x%d...", GetItemName(_wq), _wt)
                            SeedFactory.ExternalDropSeed(_wq, _wt, Config.farmDropWorld, Config.farmDropX, Config.farmDropY, _wk.world, _wk.x, _wk.y, function()
                                return AutoFarm.on and AutoFarm.token == _wj and IsSessionAlive()
                            end)
                            _wl = GetWorld()
                        end
                    end
                end
                local _wu = _vT()
                if #_wu == 0 then
                    AutoFarm.stats.status = "Pilih kotak di Grid 5x5 dulu"
                    if not AutoFarm.Quiet then
                        ShowNotification("Auto Farm: pilih minimal 1 kotak di Grid 5x5.")
                    end
                    break
                end
                local _wv = GetCharacterState()
                local _ww, _wx = GetCurrentTile()
                if not _ww then
                    break
                end
                local _wy = (_wx ~= _wk.y) or (not _wv) or (math.abs(_wv.x - (_wk.x + 0.5)) > 0.38)
                if not AutoFarm.Override and _wy then
                    if _wx == _wk.y and math.abs(_ww - _wk.x) <= 4 and Drops.walkToX then
                        local _wz = MovementInput.active
                        MovementInput.active = true
                        Drops.collecting = true
                        Drops.walkToX(_wk.x + 0.5, 1.5)
                        Drops.collecting = false
                        MovementInput.active = _wz
                    else
                        Navigation.To(_wk.x, _wk.y, function()
                            return AutoFarm.token ~= _wj
                        end, 0.2, false)
                    end
                    _ww, _wx = _wk.x, _wk.y
                end
                local _wA = {}
                for _wB, _wC in ipairs(_wu) do
                    local _wD, _wE = _wk.x + _wC.dx, _wk.y + _wC.dy
                    if IsTileInWorld(_wl, _wD, _wE) then
                        table.insert(_wA, {
                            x = _wD,
                            y = _wE
                        })
                    end
                end
                local _wF, _wG = false, false
                if _wn then
                    AutoFarm.stats.status = "Place " .. GetItemName(_wp)
                    local _wH = GetItemLayer(_wp)
                    for _wI, _wJ in ipairs(_wA) do
                        if not AutoFarm.on or AutoFarm.token ~= _wj then
                            break
                        end
                        local _wK = ReadTile(_wl, "fg", _wJ.x, _wJ.y)
                        local _wL = ReadTile(_wl, _wH, _wJ.x, _wJ.y)
                        if _wL == 0 and (_wH == "bg" or _wK == 0) then
                            if CountInventoryItem(_wp) <= 0 then
                                _wG = true
                                break
                            end
                            if PlaceInventoryItem(_wp, _wJ, _wk.facing) then
                                AutoFarm.stats.placed += 1
                                _wF = true
                                task.wait(math.max(0.05, Config.farmPlaceMs / 1000))
                            end
                        end
                    end
                end
                if not AutoFarm.on or AutoFarm.token ~= _wj then
                    break
                end
                local _wM = {}
                local _wN = {}
                if _wo then
                    AutoFarm.stats.status = "Break (" .. (_vx() and "Rayman" or ("Multi " .. Config.farmMultiTarget)) .. ")"
                    local _wO = math.clamp(math.floor(Config.farmMultiTarget or 1), 1, 5)
                    local _wP, _wQ = 1, {}
                    while AutoFarm.on and AutoFarm.token == _wj and IsSessionAlive() do
                        while #_wQ < _wO and _wP <= #_wA do
                            local _wR = _wA[_wP]
                            _wP += 1
                            if _wc(_wl, _wR.x, _wR.y) then
                                _wQ[#_wQ + 1] = {
                                    x = _wR.x,
                                    y = _wR.y,
                                    n = 0
                                }
                                local _wS = _wR.x .. "," .. _wR.y
                                if not _wN[_wS] then
                                    _wN[_wS] = true
                                    table.insert(_wM, {
                                        x = _wR.x,
                                        y = _wR.y
                                    })
                                end
                            end
                        end
                        if #_wQ == 0 then
                            break
                        end
                        local _wT, _wU = nil, nil
                        if _wO > 1 and _vx() then
                            _wT, _wU = _vC(_wk.x, _wk.y, _wQ)
                        end
                        if not _wU then
                            _wT = { _wQ[1] }
                        end
                        local _wV = os.clock()
                        if _wU then
                            _vQ(_wU)
                        end
                        local _wW, _wX = false, false
                        for _wY, _wZ in ipairs(_wT) do
                            if not AutoFarm.on or AutoFarm.token ~= _wj then
                                break
                            end
                            if _wY > 1 then
                                task.wait(0.05)
                            end
                            local _xa = PunchTile(_wZ.x, _wZ.y, Config.farmBreakBg)
                            _wZ.n += 1
                            if _xa then
                                _wW, _wF = true, true
                            end
                            if _xa == "broke" then
                                AutoFarm.stats.broken += 1
                                _wX = true
                            end
                            if _xa == nil or _wZ.n > 80 or not _wc(_wl, _wZ.x, _wZ.y) then
                                _wZ.done = true
                            end
                            _wZ.used = true
                        end
                        local _xb = {}
                        for _xc, _xd in ipairs(_wQ) do
                            if not _xd.done and not _xd.used then
                                _xb[#_xb + 1] = _xd
                            end
                        end
                        for _xe, _xf in ipairs(_wT) do
                            _xf.used = nil
                            if not _xf.done then
                                _xb[#_xb + 1] = _xf
                            end
                        end
                        _wQ = _xb
                        if _wW then
                            local _xg = math.max(0.04, Config.farmDelay)
                            if _wU then
                                _xg = math.max(_xg, 0.35)
                            end
                            local _xh = _xg - (os.clock() - _wV)
                            if _xh > 0.005 then
                                task.wait(_xh)
                            end
                        end
                        if _wX and #_wQ > 0 and Config.farmAfterBreakMs > 0 then
                            task.wait(Config.farmAfterBreakMs / 1000)
                        end
                    end
                end
                if #_wM > 0 and (Config.farmTake or AutoFarm.Override) and Config.collectMode == "Legit" then
                    AutoFarm.stats.status = "Bergerak ambil drop..."
                    task.wait(0.18)
                    if Drops.touchAll then
                        Drops.touchAll(_wM, _wk.x, _wk.y)
                    end
                end
                if not _wF then
                    if _wG then
                        AutoFarm.stats.status = "Item " .. GetItemName(_wp) .. " habis"
                        if not AutoFarm.Quiet then
                            ShowNotification("Auto Farm berhenti: " .. GetItemName(_wp) .. " habis di inventori.")
                            Webhook.Send("stop", "Auto Farm berhenti: " .. GetItemName(_wp) .. " habis")
                        end
                        break
                    end
                    task.wait(math.max(0.1, Config.farmDelay))
                end
                AutoFarm.stats.cycles += 1
            end
        end
        RunAutoFarmCycle = _wi
        StopAutoFarm = function()
            if not AutoFarm.on then
                return false
            end
            AutoFarm.token = AutoFarm.token + 1
            AutoFarm.on = false
            ReleaseMovementKeys()
            MovementInput.active = false
            AutoFarm.stats.status = "Mati"
            if RefreshGridGui then
                pcall(RefreshGridGui)
            end
            return true
        end
        StartAutoFarm = function()
            if AutoFarm.on then
                return true
            end
            if AutoClear.on then
                AutoClear.Stop()
            end
            if Farmer.on then
                Farmer.Stop()
            end
            if DirtFarm.on then
                DirtFarm.Stop()
            end
            if AutoSplice.on then
                AutoSplice.Stop()
            end
            if SeedFactory.on then
                SeedFactory.Stop()
            end
            local _xi = Config.farmMode ~= "Break saja"
            if _xi and (type(Config.farmPlaceId) ~= "number" or Config.farmPlaceId <= 0) then
                ShowNotification("Pilih block dulu di tab Auto Farm.")
                return false
            end
            local _xj, _xk, _xl = GetCalibratedPosition()
            if not _xj then
                ShowNotification("Posisi karakter belum terdeteksi.")
                return false
            end
            local _xm = {
                x = math.floor(_xj),
                y = math.floor(_xk - 0.475),
                facing = _xl,
                world = GetWorldName(),
            }
            AutoFarm.Override = nil
            AutoFarm.Quiet = false
            AutoFarm.token += 1
            local _xn = AutoFarm.token
            AutoFarm.on = true
            AutoFarm.stats.status = "Berjalan"
            if RefreshGridGui then
                pcall(RefreshGridGui)
            end
            task.spawn(function()
                local _xo, _xp = pcall(_wi, _xn, _xm)
                ReleaseMovementKeys()
                MovementInput.active = false
                if not _xo then
                    warn("[ANCHHub] Auto Farm error: " .. tostring(_xp))
                end
                if AutoFarm.token == _xn then
                    AutoFarm.on = false
                    if AutoFarm.stats.status == "Berjalan" then
                        AutoFarm.stats.status = "Mati"
                    end
                    if RefreshGridGui then
                        pcall(RefreshGridGui)
                    end
                    if SyncFeatureControls then
                        SyncFeatureControls()
                    end
                end
            end)
            return true
        end
    end)()
end
do
    (function()
        local _xq = 3.5
        local function _xr(_xs, _xt, _xu)
            local _xv = ReadTile(_xs, "fg", _xt, _xu)
            if _xv == nil then
                return nil
            end
            if _xv ~= 0 then
                if IsBreakableItem(_xv, _xt, _xu) then
                    return "fg", _xv
                end
                return nil
            end
            if Config.clearIncludeBg then
                local _xw = ReadTile(_xs, "bg", _xt, _xu)
                if _xw and _xw ~= 0 and IsBreakableItem(_xw, _xt, _xu) then
                    return "bg", _xw
                end
            end
            return nil
        end
        local function _xx(_xy, _xz)
            local _xA = {}
            local _xB = 1
            for _xC = 0, _xy.h - 1 do
                local _xD = {}
                for _xE = 0, _xy.w - 1 do
                    local _xF, _xG = _xr(_xy, _xE, _xC)
                    if _xF then
                        local _xH = _xE .. "," .. _xC
                        if not _xz[_xH] then
                            table.insert(_xD, {
                                x = _xE,
                                y = _xC,
                                id = _xG,
                                layer = _xF,
                                key = _xH
                            })
                        end
                    end
                end
                if #_xD > 0 then
                    if Config.clearSweep == "Zig-zag" and _xB == -1 then
                        table.sort(_xD, function(_xI, _xJ)
                            return _xI.x > _xJ.x
                        end)
                    else
                        table.sort(_xD, function(_xK, _xL)
                            return _xK.x < _xL.x
                        end)
                    end
                    for _xM, _xN in ipairs(_xD) do
                        table.insert(_xA, _xN)
                    end
                    if Config.clearSweep == "Zig-zag" then
                        _xB = -_xB
                    end
                end
            end
            return _xA
        end
        local function _xO(_xP, _xQ, _xR)
            local _xS = _xR - 1
            if _xS >= 0 and Navigation.OpenAt(_xQ, _xS) then
                return _xQ, _xS, 0.45
            end
            local _xT = math.max(1.8, GetPunchRange() - 0.35)
            return _xQ, _xR, _xT
        end
        local function _xU(_xV, _xW)
            SetNoclipOwner("autoclear", false)
            ReleaseMovementKeys()
            MovementInput.active = false
            local _xX = {}
            local _xY = 0
            while AutoClear.on and AutoClear.token == _xV and IsSessionAlive() do
                _xY += 1
                local _xZ = GetWorld()
                if not _xZ or GetWorldName() ~= _xW.world then
                    AutoClear.status = "World berubah, berhenti"
                    break
                end
                AutoClear.status = "Scan objek di world..."
                AutoClear.stats.pass = _xY
                local _ya = _xx(_xZ, _xX)
                AutoClear.stats.scanned = #_ya
                AutoClear.stats.left = #_ya
                if #_ya == 0 then
                    break
                end
                if _xY == 1 then
                    local _yb = _ya[1]
                    ShowNotification(string.format("Auto Clear: %d blok ditemukan. Mulai dari (%d, %d).", #_ya, _yb.x, _yb.y))
                end
                local _yc = false
                local _yd = GetPunchRange() - 0.15
                for _ye, _yf in ipairs(_ya) do
                    if not AutoClear.on or AutoClear.token ~= _xV or not IsSessionAlive() then
                        return
                    end
                    _xZ = GetWorld()
                    if not _xZ or GetWorldName() ~= _xW.world then
                        return
                    end
                    local _yg, _yh = _xr(_xZ, _yf.x, _yf.y)
                    if _yg then
                        AutoClear.stats.row = _yf.y
                        local _yi = function()
                            return not AutoClear.on or AutoClear.token ~= _xV or not IsSessionAlive()
                        end
                        local _yj = GetCharacterState()
                        local _yk, _yl = GetCurrentTile()
                        local _ym = (_yk == _yf.x and _yl == _yf.y - 1) or (_yj and Navigation.StateReaches(_yj, _yf.x, _yf.y, _yd))
                        local _yn = true
                        if not _ym then
                            SetNoclipOwner("autoclear", false)
                            if _xZ and not ManualNoclipEnabled then
                                _xZ.ghost = false
                            end
                            local _yo = os.clock()
                            while IsSessionAlive() and not _yi() and (os.clock() - _yo) < 0.45 do
                                local _yp = GetCharacterState()
                                if _yp and _yp.grounded then
                                    break
                                end
                                task.wait(0.03)
                            end
                            local _yq, _yr, _ys = _xO(_xZ, _yf.x, _yf.y)
                            AutoClear.status = string.format("Jalan ke (%d,%d) [%d/%d]", _yf.x, _yf.y, _ye, #_ya)
                            _yk, _yl = GetCurrentTile()
                            if _yl and _yr < _yl and _yk and math.abs(_yk - _yq) <= 2 then
                                Navigation.ClimbUpWithDirt(_yq, _yr, _yi, true, Config.clearTpDelay, true)
                            end
                            _yj = GetCharacterState()
                            _yk, _yl = GetCurrentTile()
                            _ym = (_yk == _yf.x and _yl == _yf.y - 1) or (_yj and Navigation.StateReaches(_yj, _yf.x, _yf.y, _yd))
                            if not _ym then
                                _yn = Navigation.LegitTo(_yq, _yr, _yi, _ys, true)
                                if not _yn and _ys < 1.5 then
                                    _yn = Navigation.LegitTo(_yf.x, _yf.y, _yi, math.max(1.8, _yd), true)
                                end
                            end
                        end
                        local _yt = GetCharacterState()
                        local _yu, _yv = GetCurrentTile()
                        local _yw = _yn and ((_yu == _yf.x and _yv == _yf.y - 1) or (_yt and Navigation.StateReaches(_yt, _yf.x, _yf.y, _yd + 0.35)))
                        if not _yw then
                            _xX[_yf.key] = true
                            AutoClear.stats.skipped += 1
                            AutoClear.stats.left = math.max(0, AutoClear.stats.left - 1)
                            AutoClear.status = string.format("Skip (%d,%d) belum terjangkau", _yf.x, _yf.y)
                        else
                            SetNoclipOwner("autoclear", true)
                            _xZ.ghost = true
                            ReleaseMovementKeys()
                            local _yx = os.clock()
                            local _yy = false
                            while AutoClear.on and AutoClear.token == _xV and IsSessionAlive() do
                                _xZ.ghost = true
                                local _yz, _yA = _xr(_xZ, _yf.x, _yf.y)
                                if not _yz then
                                    break
                                end
                                if os.clock() - _yx >= _xq then
                                    _yy = true
                                    break
                                end
                                AutoClear.status = string.format("Break %s (%d,%d) [%d/%d]", GetItemName(_yA), _yf.x, _yf.y, _ye, #_ya)
                                local _yB = PunchTile(_yf.x, _yf.y, Config.clearIncludeBg)
                                if _yB == nil then
                                    _yy = true
                                    break
                                elseif _yB == "broke" then
                                    _yc = true
                                    AutoClear.stats.broken += 1
                                    _yx = os.clock()
                                end
                                task.wait(math.max(0.04, Config.clearBreakDelay))
                            end
                            if not _xr(_xZ, _yf.x, _yf.y) then
                                AutoClear.stats.left = math.max(0, AutoClear.stats.left - 1)
                            elseif _yy then
                                _xX[_yf.key] = true
                                AutoClear.stats.skipped += 1
                                AutoClear.stats.left = math.max(0, AutoClear.stats.left - 1)
                                AutoClear.status = string.format("Skip (%d,%d) tidak bisa hancur", _yf.x, _yf.y)
                            end
                        end
                    else
                        AutoClear.stats.left = math.max(0, AutoClear.stats.left - 1)
                    end
                end
                if not _yc then
                    break
                end
                table.clear(_xX)
            end
            SetNoclipOwner("autoclear", false)
            ReleaseMovementKeys()
            MovementInput.active = false
            AutoClear.status = "Selesai"
            local _yC = string.format("Auto Clear selesai! Hancur: %d | Diambil: %d | Skip: %d", AutoClear.stats.broken, AutoClear.stats.picked, AutoClear.stats.skipped)
            ShowNotification(_yC)
            Webhook.Send("stop", _yC)
        end
        -- [16] KONTROL AUTO CLEAR. Algoritme scan dan break berada tepat di atasnya.
        function AutoClear.Stop()
            if not AutoClear.on then
                return false
            end
            AutoClear.token += 1
            AutoClear.on = false
            SetNoclipOwner("autoclear", false)
            ReleaseMovementKeys()
            MovementInput.active = false
            AutoClear.status = "Mati"
            return true
        end
        function AutoClear.Start()
            if AutoClear.on then
                return true
            end
            if AutoFarm.on then
                StopAutoFarm()
            end
            if Farmer.on then
                Farmer.Stop()
            end
            if DirtFarm.on then
                DirtFarm.Stop()
            end
            if AutoSplice.on then
                AutoSplice.Stop()
            end
            if SeedFactory.on then
                SeedFactory.Stop()
            end
            local _yD, _yE = GetCalibratedPosition()
            if not _yD then
                ShowNotification("Posisi belum terdeteksi.");
                return false
            end
            local _yF = {
                x = math.floor(_yD),
                y = math.floor(_yE - 0.475),
                world = GetWorldName()
            }
            AutoClear.token += 1
            local _yG = AutoClear.token
            AutoClear.on = true
            AutoClear.status = "Mulai"
            AutoClear.stats = {
                scanned = 0,
                broken = 0,
                picked = 0,
                skipped = 0,
                left = 0,
                pass = 0,
                row = -1
            }
            task.spawn(function()
                local _yH, _yI = pcall(_xU, _yG, _yF)
                if not _yH then
                    warn("[ANCHHub] Auto Clear error: " .. tostring(_yI))
                end
                SetNoclipOwner("autoclear", false)
                ReleaseMovementKeys()
                MovementInput.active = false
                if AutoClear.token == _yG then
                    AutoClear.on = false
                    if AutoClear.status ~= "Selesai" then
                        AutoClear.status = "Mati"
                    end
                    if SyncFeatureControls then
                        SyncFeatureControls()
                    end
                end
            end)
            return true
        end
    end)()
end
do
    (function()
        local function _yJ(_yK, _yL)
            if Config.harvestModFly then
                SetNoclipOwner("autoharvest", true)
            end
            local _yM = {}
            local _yN = 0
            while Farmer.on and Farmer.token == _yK and IsSessionAlive() do
                _yN += 1
                local _yO = GetWorld()
                if not _yO or GetWorldName() ~= _yL.world then
                    Farmer.status = "World berubah, berhenti"
                    break
                end
                Farmer.status = "Scan pohon & lahan tanam..."
                local _yP = {}
                local _yQ = {}
                local _yR = 0
                local _yS = 0
                local _yT = Config.harvestDoPlant and Config.harvestSeedId and CountInventoryItem(Config.harvestSeedId) > 0
                local _yU = 1
                for _yV = 0, _yO.h - 1 do
                    local _yW, _yX = {}, {}
                    for _yY = 0, _yO.w - 1 do
                        local _yZ = ReadTile(_yO, "fg", _yY, _yV) or 0
                        if _yZ ~= 0 and IsTreeItem(_yZ) then
                            _yR = _yR + 1
                            if Config.harvestDoHarvest and not _yM[_yY .. "," .. _yV] then
                                if IsTreeReady(_yO, _yY, _yV, _yZ) then
                                    table.insert(_yW, {
                                        x = _yY,
                                        y = _yV,
                                        id = _yZ
                                    })
                                else
                                    _yS = _yS + 1
                                end
                            end
                        elseif _yT and _yZ == 0 and CanPlantSeedAt(_yO, _yY, _yV, Config.harvestSeedId) then
                            table.insert(_yX, {
                                x = _yY,
                                y = _yV
                            })
                        end
                    end
                    if #_yW > 0 or #_yX > 0 then
                        if _yU == -1 then
                            table.sort(_yW, function(_za, _zb)
                                return _za.x > _zb.x
                            end)
                            table.sort(_yX, function(_zc, _zd)
                                return _zc.x > _zd.x
                            end)
                        else
                            table.sort(_yW, function(_ze, _zf)
                                return _ze.x < _zf.x
                            end)
                            table.sort(_yX, function(_zg, _zh)
                                return _zg.x < _zh.x
                            end)
                        end
                        for _zi, _zj in ipairs(_yW) do
                            table.insert(_yP, _zj)
                        end
                        for _zk, _zl in ipairs(_yX) do
                            table.insert(_yQ, _zl)
                        end
                        _yU = -_yU
                    end
                end
                Farmer.stats.totalTrees = _yR
                Farmer.stats.ready = #_yP
                if _yN == 1 then
                    Farmer.stats.skipped = _yS
                    ShowNotification(string.format(("Farmer Scan: %d pohon (%d siap panen, %d belum siap) | %d lahan " .. "kosong."), _yR, #_yP, _yS, #_yQ))
                end
                if #_yP == 0 and #_yQ == 0 then
                    break
                end
                local _zm = false
                local _zn = math.min(GetPunchRange(), GetBuildRange()) - 0.15
                for _zo, _zp in ipairs(_yP) do
                    if not Farmer.on or Farmer.token ~= _yK or not IsSessionAlive() then
                        return
                    end
                    _yO = GetWorld()
                    if not _yO or GetWorldName() ~= _yL.world then
                        return
                    end
                    if ReadTile(_yO, "fg", _zp.x, _zp.y) == _zp.id then
                        local _zq = GetCharacterState()
                        if not (_zq and Navigation.StateReaches(_zq, _zp.x, _zp.y, _zn)) then
                            Farmer.status = string.format("Jalan Zig-Zag ke pohon (%d,%d) [%d/%d]", _zp.x, _zp.y, _zo, #_yP)
                            local _zr = Navigation.To(_zp.x, _zp.y, function()
                                return Farmer.token ~= _yK or not Farmer.on
                            end, _zn, Config.harvestUseBlock)
                            if not _zr then
                                _yM[_zp.x .. "," .. _zp.y] = true
                                Farmer.stats.skipped = Farmer.stats.skipped + 1
                            end
                            task.wait(math.max(0.10, Config.harvestTpDelay))
                        end
                        local _zs = GetCharacterState()
                        if _zs and Navigation.StateReaches(_zs, _zp.x, _zp.y, _zn + 0.5) then
                            Farmer.status = string.format("Panen %s (%d,%d) [%d/%d]", GetItemName(_zp.id), _zp.x, _zp.y, _zo, #_yP)
                            local _zt = os.clock()
                            while Farmer.on and Farmer.token == _yK and ReadTile(_yO, "fg", _zp.x, _zp.y) == _zp.id and os.clock() - _zt < 3.5 do
                                PunchTile(_zp.x, _zp.y, false)
                                task.wait(math.max(0.05, Config.harvestDelay))
                            end
                            if ReadTile(_yO, "fg", _zp.x, _zp.y) ~= _zp.id then
                                _zm = true
                                Farmer.stats.harvested = Farmer.stats.harvested + 1
                                SessionStats.Harvested = SessionStats.Harvested + 1
                                Farmer.stats.ready = math.max(0, Farmer.stats.ready - 1)
                                if Config.harvestDoPlant and Config.harvestSeedId and CountInventoryItem(Config.harvestSeedId) > 0 and CanPlantSeedAt(_yO, _zp.x, _zp.y, Config.harvestSeedId) then
                                    task.wait(0.08)
                                    if PlaceInventoryItem(Config.harvestSeedId, {
                                        x = _zp.x,
                                        y = _zp.y
                                    }, 1) then
                                        Farmer.stats.planted = Farmer.stats.planted + 1
                                        SessionStats.Planted = SessionStats.Planted + 1
                                        task.wait(math.max(0.05, Config.harvestPlantDelay))
                                    end
                                end
                            else
                                _yM[_zp.x .. "," .. _zp.y] = true
                                Farmer.stats.skipped = Farmer.stats.skipped + 1
                            end
                        end
                    end
                end
                if Config.harvestDoPlant and Config.harvestSeedId and CountInventoryItem(Config.harvestSeedId) > 0 then
                    for _zu, _zv in ipairs(_yQ) do
                        if not Farmer.on or Farmer.token ~= _yK or not IsSessionAlive() then
                            return
                        end
                        if CountInventoryItem(Config.harvestSeedId) <= 0 then
                            break
                        end
                        _yO = GetWorld()
                        if not _yO or GetWorldName() ~= _yL.world then
                            return
                        end
                        if CanPlantSeedAt(_yO, _zv.x, _zv.y, Config.harvestSeedId) then
                            local _zw = GetCharacterState()
                            if not (_zw and Navigation.StateReaches(_zw, _zv.x, _zv.y, _zn)) then
                                Farmer.status = string.format("Jalan Zig-Zag ke tanam (%d,%d) [%d/%d]", _zv.x, _zv.y, _zu, #_yQ)
                                Navigation.To(_zv.x, _zv.y, function()
                                    return Farmer.token ~= _yK or not Farmer.on
                                end, _zn, Config.harvestUseBlock)
                                task.wait(math.max(0.10, Config.harvestTpDelay))
                            end
                            local _zx = GetCharacterState()
                            if _zx and Navigation.StateReaches(_zx, _zv.x, _zv.y, _zn + 0.5) and CanPlantSeedAt(_yO, _zv.x, _zv.y, Config.harvestSeedId) then
                                if PlaceInventoryItem(Config.harvestSeedId, _zv, 1) then
                                    _zm = true
                                    Farmer.stats.planted = Farmer.stats.planted + 1
                                    SessionStats.Planted = SessionStats.Planted + 1
                                    Farmer.status = string.format("Tanam %s (%d,%d)", GetItemName(Config.harvestSeedId), _zv.x, _zv.y)
                                    task.wait(math.max(0.05, Config.harvestPlantDelay))
                                end
                            end
                        end
                    end
                end
                if not _zm then
                    break
                end
            end
            SetNoclipOwner("autoharvest", false)
            ReleaseMovementKeys()
            MovementInput.active = false
            Farmer.status = "Selesai"
            local _zy = string.format("Farmer selesai! Panen: %d | Tanam: %d | Drop: %d", Farmer.stats.harvested, Farmer.stats.planted, Farmer.stats.picked)
            ShowNotification(_zy)
            Webhook.Send("stop", _zy)
        end
        -- [17] KONTROL FARMER. Algoritme harvest/plant berada tepat di atasnya.
        function Farmer.Stop()
            if not Farmer.on then
                return false
            end
            Farmer.token += 1
            Farmer.on = false
            SetNoclipOwner("autoharvest", false)
            ReleaseMovementKeys()
            MovementInput.active = false
            Farmer.status = "Mati"
            return true
        end
        function Farmer.Start()
            if Farmer.on then
                return true
            end
            if AutoFarm.on then
                StopAutoFarm()
            end
            if AutoClear.on then
                AutoClear.Stop()
            end
            if DirtFarm.on then
                DirtFarm.Stop()
            end
            if AutoSplice.on then
                AutoSplice.Stop()
            end
            if SeedFactory.on then
                SeedFactory.Stop()
            end
            local _zz, _zA = GetCalibratedPosition()
            if not _zz then
                ShowNotification("Posisi belum terdeteksi.");
                return false
            end
            local _zB = {
                x = math.floor(_zz),
                y = math.floor(_zA - 0.475),
                world = GetWorldName()
            }
            Farmer.token += 1
            local _zC = Farmer.token
            Farmer.on = true
            Farmer.status = "Mulai"
            Farmer.stats = {
                totalTrees = 0,
                ready = 0,
                harvested = 0,
                planted = 0,
                skipped = 0,
                picked = 0
            }
            task.spawn(function()
                local _zD, _zE = pcall(_yJ, _zC, _zB)
                if not _zD then
                    warn("[ANCHHub] Farmer error: " .. tostring(_zE))
                end
                SetNoclipOwner("autoharvest", false)
                ReleaseMovementKeys()
                MovementInput.active = false
                if Farmer.token == _zC then
                    Farmer.on = false
                    if Farmer.status ~= "Selesai" then
                        Farmer.status = "Mati"
                    end
                    if SyncFeatureControls then
                        SyncFeatureControls()
                    end
                end
            end)
            return true
        end
    end)()
end
do
    (function()
        local _zF = 5.0
        local function _zG(_zH)
            local _zI = ItemDatabase and ItemDatabase[_zH]
            return type(_zI) == "table" and type(_zI.name) == "string" and _zI.name:lower():find("bedrock", 1, true) ~= nil
        end
        local function _zJ(_zK)
            local _zL = GetDirtId()
            local _zM, _zN = nil, nil
            for _zO = 0, _zK.h - 1 do
                local _zP, _zQ = 0, 0
                for _zR = 0, _zK.w - 1 do
                    local _zS = ReadTile(_zK, "fg", _zR, _zO) or 0
                    if _zS ~= 0 then
                        if _zG(_zS) then
                            _zQ += 1
                        elseif _zS == _zL or IsBreakableItem(_zS) then
                            _zP += 1
                        end
                    end
                end
                if not _zM and _zP >= math.floor(_zK.w * 0.25) then
                    _zM = _zO
                end
                if _zM and _zO > _zM and _zQ >= math.floor(_zK.w * 0.4) then
                    _zN = _zO
                    break
                end
            end
            if not _zM then
                _zM = (typeof(_zK.spawn) == "Vector2") and (math.floor(_zK.spawn.Y) + 1) or 37
            end
            if not _zN then
                _zN = _zK.h - 6
            end
            return _zM, _zN
        end
        local function _zT(_zU, _zV, _zW)
            local _zX = function()
                return DirtFarm.token ~= _zW or not DirtFarm.on or not IsSessionAlive()
            end
            local _zY, _zZ = GetCurrentTile()
            if not _zY or (_zY == _zU and _zZ == _zV) then
                return true
            end
            if Config.moveMethod == "Teleport Mode" then
                return Navigation.FlyTo(_zU, _zV, _zX, Config.dfTpDelay, false)
            end
            if _zZ == _zV and math.abs(_zY - _zU) <= 2 then
                if Navigation.ExecWalk(_zU, _zV, _zX) then
                    return true
                end
            elseif _zZ and _zV < _zZ and math.abs(_zY - _zU) <= 1 then
                if Navigation.ClimbUpWithDirt(_zU, _zV, _zX, true, Config.dfTpDelay, true) then
                    return true
                end
            end
            if Navigation.To(_zU, _zV, _zX, 0.3, true) then
                return true
            end
            return Navigation.FlyTo(_zU, _zV, _zX, Config.dfTpDelay, false)
        end
        local function _Aa(_Ab, _Ac, _Ad, _Ae, _Af, _Ag)
            if not IsTileInWorld(_Ab, _Ac, _Ad) then
                return false
            end
            local _Ah = ReadTile(_Ab, "fg", _Ac, _Ad) or 0
            local _Ai = ReadTile(_Ab, "bg", _Ac, _Ad) or 0
            if (_Ah == 0 or not IsBreakableItem(_Ah)) and (_Ai == 0 or not IsBreakableItem(_Ai)) then
                return true
            end
            _zT(_Ae, _Af, _Ag)
            local _Aj = os.clock()
            while DirtFarm.on and DirtFarm.token == _Ag and IsSessionAlive() do
                local _Ak = ReadTile(_Ab, "fg", _Ac, _Ad) or 0
                local _Al = ReadTile(_Ab, "bg", _Ac, _Ad) or 0
                local _Am = _Ak ~= 0 and IsBreakableItem(_Ak)
                local _An = _Al ~= 0 and IsBreakableItem(_Al)
                if Config.dfModFly then
                    _Ab.ghost = true
                end
                if not _Am and not _An then
                    break
                end
                if os.clock() - _Aj >= _zF then
                    break
                end
                local _Ao = PunchTile(_Ac, _Ad, true)
                if _Ao == "broke" then
                    DirtFarm.stats.broken += 1
                    _Aj = os.clock()
                end
                task.wait(math.max(0.04, Config.dfBreakDelay))
            end
            return true
        end
        local function _Ap(_Aq, _Ar)
            local _As = Drops.list
            if not _As then
                Refs.Scan();
                _As = Drops.list
            end
            if type(_As) ~= "table" then
                return nil
            end
            local _At, _Au = GetCurrentTile()
            _At, _Au = _At or 50, _Au or 30
            local _Av, _Aw = nil, math.huge
            for _Ax, _Ay in ipairs(_As) do
                if type(_Ay) == "table" and (_Ay.id == _Aq or _Ay.id == _Ar) and (_Ay.n or 0) > 0 and type(_Ay.x) == "number" then
                    local _Az = math.abs(_Ay.x - _At) + math.abs(_Ay.y - _Au)
                    if _Az < _Aw then
                        _Av, _Aw = _Ay, _Az
                    end
                end
            end
            return _Av
        end
        local function _AA(_AB, _AC, _AD, _AE)
            local _AF = GetDirtId()
            local _AG = GetDirtSeedId()
            local _AH = _AC - 1
            if _AH < 0 then
                return false
            end
            local _AI = {}
            local _AJ = 0
            for _AK = 3, _AB.w - 4 do
                if not DirtFarm.on or DirtFarm.token ~= _AD then
                    break
                end
                if CountInventoryItem(_AG) <= 0 or _AJ >= (_AE or 20) then
                    break
                end
                if (ReadTile(_AB, "fg", _AK, _AC) or 0) == _AF and (ReadTile(_AB, "fg", _AK, _AH) or 0) == 0 then
                    _zT(_AK, _AH, _AD)
                    if PlaceInventoryItem(_AG, {
                        x = _AK,
                        y = _AH
                    }, 1) then
                        SessionStats.Planted += 1
                        table.insert(_AI, {
                            x = _AK,
                            y = _AH,
                            plantedTime = os.clock()
                        })
                        _AJ += 1
                        task.wait(0.18)
                    end
                end
            end
            for _AL = 2, _AB.w - 3 do
                if (ReadTile(_AB, "fg", _AL, _AH) or 0) == _AG then
                    local _AM = false
                    for _AN, _AO in ipairs(_AI) do
                        if _AO.x == _AL and _AO.y == _AH then
                            _AM = true;
                            break
                        end
                    end
                    if not _AM then
                        table.insert(_AI, {
                            x = _AL,
                            y = _AH,
                            plantedTime = os.clock() - 25
                        })
                    end
                end
            end
            if #_AI == 0 then
                return false
            end
            local _AP = ItemDatabase[_AG]
            local _AQ = (_AP and (tonumber(_AP.grow) or tonumber(_AP.baseGrow))) or 31
            for _AR, _AS in ipairs(_AI) do
                if not DirtFarm.on or DirtFarm.token ~= _AD then
                    return false
                end
                while DirtFarm.on and DirtFarm.token == _AD and IsSessionAlive() do
                    if (ReadTile(_AB, "fg", _AS.x, _AS.y) or 0) ~= _AG then
                        break
                    end
                    local _AT = os.clock() - _AS.plantedTime
                    if IsTreeReady(_AB, _AS.x, _AS.y, _AG) or _AT >= (_AQ + 1.5) then
                        break
                    end
                    local _AU = math.max(0, math.ceil(_AQ - _AT))
                    DirtFarm.status = string.format("Menunggu Dirt Tree matang (%ds) [%d/%d]...", _AU, _AR, #_AI)
                    task.wait(0.5)
                end
                if (ReadTile(_AB, "fg", _AS.x, _AS.y) or 0) == _AG then
                    DirtFarm.status = string.format("Harvest Dirt Tree (%d,%d) [%d/%d]", _AS.x, _AS.y, _AR, #_AI)
                    _zT(_AS.x, _AS.y, _AD)
                    local _AV = os.clock()
                    while DirtFarm.on and DirtFarm.token == _AD and (ReadTile(_AB, "fg", _AS.x, _AS.y) or 0) == _AG and os.clock() - _AV < 3.5 do
                        local _AW = PunchTile(_AS.x, _AS.y, false)
                        if _AW == "broke" then
                            SessionStats.Harvested += 1
                        end
                        task.wait(math.max(0.05, Config.dfBreakDelay))
                    end
                    task.wait(0.25)
                end
            end
            return true
        end
        local function _AX(_AY, _AZ, _Ba)
            local _Bb = GetDirtId()
            for _Bc = _AZ, _Ba - 1, 2 do
                local _Bd = 0
                for _Be = 3, _AY.w - 4 do
                    if (ReadTile(_AY, "fg", _Be, _Bc) or 0) == _Bb and (ReadTile(_AY, "fg", _Be, _Bc - 1) or 0) == 0 then
                        _Bd += 1
                        if _Bd >= 12 then
                            return _Bc
                        end
                    end
                end
            end
            return _AZ
        end
        local function _Bf(_Bg, _Bh, _Bi, _Bj, _Bk, _Bl, _Bm)
            local _Bn = GetDirtId()
            local _Bo = GetDirtSeedId()
            if CountInventoryItem(_Bn) > 0 then
                return true
            end
            DirtFarm.stats.step = "Restock Dirt"
            local _Bp = _AX(_Bg, _Bk, _Bl)
            while DirtFarm.on and DirtFarm.token == _Bm and IsSessionAlive() and CountInventoryItem(_Bn) < 15 do
                if CountInventoryItem(_Bo) > 0 then
                    DirtFarm.status = "Stok Dirt habis! Menanam & memanen Dirt Seed..."
                    _AA(_Bg, _Bp, _Bm, 20)
                    if CountInventoryItem(_Bn) >= 15 then
                        break
                    end
                end
                local _Bq = _Ap(_Bn, _Bo)
                if _Bq then
                    local _Br, _Bs = math.floor(_Bq.x), math.floor(_Bq.y)
                    DirtFarm.status = string.format("Mengambil drop Dirt/Seed di (%d, %d)...", _Br, _Bs)
                    _zT(_Br, _Bs, _Bm)
                    task.wait(0.5)
                    if CountInventoryItem(_Bn) >= 15 then
                        break
                    end
                    if CountInventoryItem(_Bo) > 0 then
                        _AA(_Bg, _Bp, _Bm, 20)
                        if CountInventoryItem(_Bn) >= 15 then
                            break
                        end
                    end
                end
                if CountInventoryItem(_Bn) == 0 and CountInventoryItem(_Bo) == 0 then
                    DirtFarm.status = "Break Dirt di world untuk mencari Seed..."
                    local _Bt = {}
                    for _Bu = 4, _Bg.w - 5 do
                        if not DirtFarm.on or DirtFarm.token ~= _Bm then
                            break
                        end
                        if #_Bt >= 14 or CountInventoryItem(_Bo) >= 6 then
                            break
                        end
                        if (ReadTile(_Bg, "fg", _Bu, _Bp) or 0) == _Bn and (ReadTile(_Bg, "fg", _Bu - 1, _Bp) or 0) == _Bn then
                            local _Bv, _Bw = _Bu - 1, _Bp - 1
                            _zT(_Bv, _Bw, _Bm)
                            _Aa(_Bg, _Bu, _Bp, _Bv, _Bw, _Bm)
                            if (ReadTile(_Bg, "fg", _Bu, _Bp) or 0) == 0 then
                                table.insert(_Bt, {
                                    x = _Bu,
                                    y = _Bp,
                                    standX = _Bv,
                                    standY = _Bw
                                })
                            end
                            task.wait(0.2)
                        end
                    end
                    if CountInventoryItem(_Bo) > 0 then
                        _AA(_Bg, _Bp, _Bm, 20)
                    end
                    for _Bx, _By in ipairs(_Bt) do
                        if not DirtFarm.on or DirtFarm.token ~= _Bm then
                            break
                        end
                        while DirtFarm.on and DirtFarm.token == _Bm and CountInventoryItem(_Bn) == 0 and CountInventoryItem(_Bo) > 0 do
                            _AA(_Bg, _Bp, _Bm, 15)
                        end
                        if (ReadTile(_Bg, "fg", _By.x, _By.y) or 0) == 0 and CountInventoryItem(_Bn) > 0 then
                            _zT(_By.standX, _By.standY, _Bm)
                            if PlaceInventoryItem(_Bn, {
                                x = _By.x,
                                y = _By.y
                            }, 1) then
                                DirtFarm.stats.placed += 1
                                task.wait(0.14)
                            end
                        end
                    end
                elseif CountInventoryItem(_Bn) > 0 and CountInventoryItem(_Bn) < 15 and CountInventoryItem(_Bo) == 0 then
                    local _Bz = 5
                    local _BA, _BB = 4, _Bp - 1
                    _zT(_BA, _BB, _Bm)
                    while DirtFarm.on and DirtFarm.token == _Bm and CountInventoryItem(_Bo) < 4 and CountInventoryItem(_Bn) > 0 do
                        if (ReadTile(_Bg, "fg", _Bz, _BB) or 0) == 0 then
                            PlaceInventoryItem(_Bn, {
                                x = _Bz,
                                y = _BB
                            }, 1)
                            task.wait(TilePlaceCooldownSeconds)
                        end
                        _Aa(_Bg, _Bz, _BB, _BA, _BB, _Bm)
                        task.wait(0.2)
                    end
                else
                    break
                end
            end
            if _Bh and _Bi then
                _zT(_Bh, _Bi, _Bm)
            end
            return CountInventoryItem(_Bn) > 0
        end
        local function _BC(_BD, _BE, _BF, _BG, _BH, _BI, _BJ, _BK)
            if not IsTileInWorld(_BD, _BE, _BF) then
                return
            end
            local _BL = GetDirtId()
            local _BM = ReadTile(_BD, "fg", _BE, _BF) or 0
            if _BM == _BL then
                return
            end
            if _BM ~= 0 and not IsBreakableItem(_BM) then
                return
            end
            _zT(_BG, _BH, _BK)
            if _BM ~= 0 and _BM ~= _BL then
                local _BN = os.clock()
                while DirtFarm.on and DirtFarm.token == _BK and (ReadTile(_BD, "fg", _BE, _BF) or 0) ~= 0 and os.clock() - _BN < _zF do
                    local _BO = PunchTile(_BE, _BF, false)
                    if _BO == "broke" then
                        DirtFarm.stats.broken += 1
                    end
                    task.wait(math.max(0.04, Config.dfBreakDelay))
                end
            end
            if DirtFarm.on and DirtFarm.token == _BK and (ReadTile(_BD, "fg", _BE, _BF) or 0) == 0 then
                if CountInventoryItem(_BL) <= 0 then
                    _Bf(_BD, _BG, _BH, _BF, _BI, _BJ, _BK)
                end
                if CountInventoryItem(_BL) > 0 then
                    if PlaceInventoryItem(_BL, {
                        x = _BE,
                        y = _BF
                    }, (_BE >= _BG) and 1 or -1) then
                        DirtFarm.stats.placed += 1
                        task.wait(0.14)
                    end
                end
            end
        end
        local function _BP(_BQ, _BR, _BS, _BT, _BU)
            for _BV = _BT, _BU - 1 do
                local _BW, _BX = ReadTile(_BQ, "fg", _BR, _BV) or 0, ReadTile(_BQ, "bg", _BR, _BV) or 0
                local _BY, _BZ = ReadTile(_BQ, "fg", _BS, _BV) or 0, ReadTile(_BQ, "bg", _BS, _BV) or 0
                if _zG(_BW) and _zG(_BY) then
                    break
                end
                if (_BW ~= 0 and IsBreakableItem(_BW)) or (_BX ~= 0 and IsBreakableItem(_BX)) or (_BY ~= 0 and IsBreakableItem(_BY)) or (_BZ ~= 0 and IsBreakableItem(_BZ)) then
                    return _BV
                end
            end
            return nil
        end
        local function _Ca(_Cb, _Cc, _Cd, _Ce, _Cf, _Cg, _Ch)
            local _Ci = _BP(_Cb, _Cc, _Cd, _Ce, _Cf)
            if not _Ci then
                DirtFarm.status = "Kolom vertikal " .. _Cg .. " sudah bersih, lanjut..."
                return true
            end
            DirtFarm.stats.step = "Clear Vertikal " .. _Cg
            local _Cj = math.max(0, _Ci - 1)
            DirtFarm.status = string.format("Lanjut vertikal %s dari Y=%d...", _Cg, _Ci)
            _zT(_Cd, _Cj, _Ch)
            task.wait(math.max(0.20, Config.dfTpDelay))
            local _Ck = _Cj
            for _Cl = _Ci, _Cf - 1 do
                if not DirtFarm.on or DirtFarm.token ~= _Ch or not IsSessionAlive() then
                    return false
                end
                _Cb = GetWorld()
                if not _Cb then
                    return false
                end
                if _zG(ReadTile(_Cb, "fg", _Cc, _Cl)) and _zG(ReadTile(_Cb, "fg", _Cd, _Cl)) then
                    break
                end
                local _Cm = math.max(0, _Cl - 1)
                DirtFarm.status = string.format("Vertikal %s: Break Y=%d", _Cg, _Cl)
                _Aa(_Cb, _Cc, _Cl, _Cd, _Cm, _Ch)
                if not DirtFarm.on or DirtFarm.token ~= _Ch then
                    return false
                end
                _Aa(_Cb, _Cd, _Cl, _Cd, _Cm, _Ch)
                _Ck = _Cm
            end
            if DirtFarm.on and DirtFarm.token == _Ch and _Ck > math.max(0, _Ce - 1) then
                DirtFarm.status = string.format("Naik kembali dari ujung %s...", _Cg)
                Navigation.ClimbUpWithDirt(_Cd, math.max(0, _Ce - 1), function()
                    return DirtFarm.token ~= _Ch
                end, true, Config.dfTpDelay, true)
            end
            return true
        end
        local function _Cn(_Co, _Cp, _Cq, _Cr)
            local _Cs = GetDirtId()
            local _Ct = _Cp - 1
            local _Cu = _Cp + 1
            for _Cv = 2, _Co.w - 3 do
                local _Cw = ReadTile(_Co, "fg", _Cv, _Cp) or 0
                local _Cx = ReadTile(_Co, "bg", _Cv, _Cp) or 0
                if (_Cw ~= 0 and IsBreakableItem(_Cw)) or (_Cx ~= 0 and IsBreakableItem(_Cx)) then
                    return false
                end
                if Config.dfReplacePlatform then
                    if _Ct >= _Cq and (ReadTile(_Co, "fg", _Cv, _Ct) or 0) ~= _Cs then
                        return false
                    end
                    if _Cu < _Cr and (ReadTile(_Co, "fg", _Cv, _Cu) or 0) ~= _Cs then
                        return false
                    end
                end
            end
            return true
        end
        local function _Cy(_Cz, _CA)
            local _CB = GetDirtId()
            local _CC = _CA - 1
            for _CD = 2, _Cz.w - 3 do
                if (ReadTile(_Cz, "fg", _CD, _CA) or 0) ~= _CB then
                    return false
                end
                if (ReadTile(_Cz, "fg", _CD, _CC) or 0) ~= 0 then
                    return false
                end
            end
            return true
        end
        local function _CE(_CF, _CG)
            local _CH = Session.IsGodModeEnabled and Session.IsGodModeEnabled()
            if not _CH and Session.StartGodMode then
                pcall(Session.StartGodMode)
            end
            SetNoclipOwner("autodf", Config.dfModFly)
            local _CI = GetWorld()
            if not _CI then
                return
            end
            local _CJ, _CK = _zJ(_CI)
            DirtFarm.stats.topDirtY = _CJ
            DirtFarm.stats.bedrockY = _CK
            ShowNotification(string.format(("Auto DF Scan: Melanjutkan progres Dirt Farm (Dirt Y=%d, Bedrock " .. "Y=%d)."), _CJ, _CK))
            local _CL = _CI.w
            if not _Ca(_CI, 0, 1, _CJ, _CK, "Kiri (1-2)", _CF) then
                return
            end
            if not DirtFarm.on or DirtFarm.token ~= _CF then
                return
            end
            if not _Ca(_CI, _CL - 2, _CL - 1, _CJ, _CK, "Kanan (99-100)", _CF) then
                return
            end
            if not DirtFarm.on or DirtFarm.token ~= _CF then
                return
            end
            local _CM = false
            for _CN = _CJ + 1, _CK - 1, 2 do
                if not DirtFarm.on or DirtFarm.token ~= _CF or not IsSessionAlive() then
                    return
                end
                _CI = GetWorld()
                if not _CI or GetWorldName() ~= _CG.world then
                    return
                end
                if _Cn(_CI, _CN, _CJ, _CK) then
                    DirtFarm.status = string.format("Baris Y=%d sudah selesai, lanjut ke baris berikutnya...", _CN)
                else
                    local _CO = _CN - 1
                    local _CP = _CN + 1
                    DirtFarm.stats.step = string.format("Bawah: Baris Y=%d", _CN)
                    local _CQ = _CM and 2 or (_CL - 3)
                    local _CR = _CM and (_CL - 3) or 2
                    local _CS = _CM and 1 or -1
                    local _CT = _CM and 1 or (_CL - 2)
                    _zT(_CT, _CN, _CF)
                    for _CU = _CQ, _CR, _CS do
                        if not DirtFarm.on or DirtFarm.token ~= _CF or not IsSessionAlive() then
                            return
                        end
                        _CI = GetWorld()
                        if not _CI or GetWorldName() ~= _CG.world then
                            return
                        end
                        local _CV = _CU - _CS
                        local _CW = _CN
                        if Config.dfReplacePlatform and _CP < _CK then
                            _BC(_CI, _CV, _CP, _CV, _CW, _CJ, _CK, _CF)
                        end
                        if Config.dfReplacePlatform and _CO >= _CJ then
                            _BC(_CI, _CV, _CO, _CV, _CW, _CJ, _CK, _CF)
                        end
                        DirtFarm.status = string.format("Bawah Y=%d | Break (%d,%d)", _CN, _CU, _CN)
                        _Aa(_CI, _CU, _CN, _CV, _CW, _CF)
                        if Config.dfReplacePlatform then
                            if _CO >= _CJ then
                                _BC(_CI, _CU, _CO, _CV, _CW, _CJ, _CK, _CF)
                            end
                            if _CP < _CK then
                                _BC(_CI, _CU, _CP, _CV, _CW, _CJ, _CK, _CF)
                            end
                        end
                        _zT(_CU, _CN, _CF)
                    end
                    _CM = not _CM
                end
            end
            for _CX = 2, _CL - 3 do
                if not DirtFarm.on or DirtFarm.token ~= _CF then
                    return
                end
                if (ReadTile(_CI, "fg", _CX, _CJ) or 0) ~= GetDirtId() then
                    _BC(_CI, _CX, _CJ, _CX, _CJ - 1, _CJ, _CK, _CF)
                end
            end
            local _CY = true
            for _CZ = _CJ - 2, 2, -2 do
                if not DirtFarm.on or DirtFarm.token ~= _CF or not IsSessionAlive() then
                    return
                end
                _CI = GetWorld()
                if not _CI or GetWorldName() ~= _CG.world then
                    return
                end
                if _Cy(_CI, _CZ) then
                    DirtFarm.status = string.format("Platform Atas Y=%d sudah selesai, skip...", _CZ)
                else
                    local _Da = _CZ - 1
                    DirtFarm.stats.step = string.format("Atas: Platform Y=%d", _CZ)
                    local _Db = _CY and 2 or (_CL - 3)
                    local _Dc = _CY and (_CL - 3) or 2
                    local _Dd = _CY and 1 or -1
                    local _De = _CZ + 1
                    _zT(_Db, _De, _CF)
                    _BC(_CI, _Db, _CZ, _Db, _De, _CJ, _CK, _CF)
                    local _Df = _CY and 1 or (_CL - 2)
                    Navigation.ClimbUpWithDirt(_Df, _Da, function()
                        return DirtFarm.token ~= _CF
                    end, true, Config.dfTpDelay, true)
                    _zT(_Db, _Da, _CF)
                    for _Dg = _Db + _Dd, _Dc, _Dd do
                        if not DirtFarm.on or DirtFarm.token ~= _CF or not IsSessionAlive() then
                            return
                        end
                        _CI = GetWorld()
                        if not _CI or GetWorldName() ~= _CG.world then
                            return
                        end
                        local _Dh = _Dg - _Dd
                        if (ReadTile(_CI, "fg", _Dg, _Da) or 0) ~= 0 or (ReadTile(_CI, "bg", _Dg, _Da) or 0) ~= 0 then
                            _Aa(_CI, _Dg, _Da, _Dh, _Da, _CF)
                        end
                        DirtFarm.status = string.format("Atas Y=%d | Pasang Dirt (%d,%d)", _CZ, _Dg, _CZ)
                        _BC(_CI, _Dg, _CZ, _Dh, _Da, _CJ, _CK, _CF)
                        _zT(_Dg, _Da, _CF)
                    end
                    _CY = not _CY
                end
            end
            if not _CH and Session.StopGodMode then
                pcall(Session.StopGodMode)
            end
            SetNoclipOwner("autodf", false)
            ReleaseMovementKeys()
            MovementInput.active = false
            DirtFarm.stats.step = "Selesai"
            DirtFarm.status = "Selesai"
            local _Di = string.format(("Full World Dirt Farm selesai! Hancur: %d | Dirt dipasang: %d | D" .. "rop: %d"), DirtFarm.stats.broken, DirtFarm.stats.placed, DirtFarm.stats.picked)
            ShowNotification(_Di)
            Webhook.Send("pabrik", _Di)
        end
        -- [18] KONTROL DIRT FARM. Pembangunan platform berada tepat di atasnya.
        function DirtFarm.Stop()
            if not DirtFarm.on then
                return false
            end
            DirtFarm.token += 1
            DirtFarm.on = false
            SetNoclipOwner("autodf", false)
            ReleaseMovementKeys()
            MovementInput.active = false
            DirtFarm.status = "Mati"
            DirtFarm.stats.step = "-"
            return true
        end
        function DirtFarm.Start()
            if DirtFarm.on then
                return true
            end
            if AutoFarm.on then
                StopAutoFarm()
            end
            if AutoClear.on then
                AutoClear.Stop()
            end
            if Farmer.on then
                Farmer.Stop()
            end
            if AutoSplice.on then
                AutoSplice.Stop()
            end
            if SeedFactory.on then
                SeedFactory.Stop()
            end
            local _Dj, _Dk = GetCalibratedPosition()
            if not _Dj then
                ShowNotification("Posisi belum terdeteksi.");
                return false
            end
            local _Dl = {
                x = math.floor(_Dj),
                y = math.floor(_Dk - 0.475),
                world = GetWorldName()
            }
            DirtFarm.token += 1
            local _Dm = DirtFarm.token
            DirtFarm.on = true
            DirtFarm.status = "Mulai"
            DirtFarm.stats = {
                topDirtY = 0,
                bedrockY = 0,
                broken = 0,
                placed = 0,
                picked = 0,
                step = "Inisialisasi"
            }
            task.spawn(function()
                local _Dn, _Do = pcall(_CE, _Dm, _Dl)
                if not _Dn then
                    warn("[ANCHHub] Auto DF error: " .. tostring(_Do))
                end
                SetNoclipOwner("autodf", false)
                ReleaseMovementKeys()
                MovementInput.active = false
                if DirtFarm.token == _Dm then
                    DirtFarm.on = false
                    if DirtFarm.status ~= "Selesai" then
                        DirtFarm.status = "Mati"
                    end
                    if SyncFeatureControls then
                        SyncFeatureControls()
                    end
                end
            end)
            return true
        end
    end)()
end
do
    (function()
        -- [19] AUTO SPLICE: kombinasi seed, penanaman, dan jelajah tile.
        function AutoSplice.Result(_Dp, _Dq)
            if not (HasSpliceModule and type(SpliceModule) == "table" and type(SpliceModule.result) == "function") then
                return nil
            end
            if not (_Dp and _Dq) then
                return nil
            end
            local _Dr, _Ds = pcall(SpliceModule.result, _Dp, _Dq)
            return _Dr and _Ds or nil
        end
        function AutoSplice.ResultText()
            local _Dt, _Du = Config.spliceA, Config.spliceB
            if not (_Dt and _Du) then
                return "Pilih Seed A dan Seed B"
            end
            local _Dv = AutoSplice.Result(_Dt, _Du)
            if not _Dv then
                return "Hasil: Kombinasi ini tidak bisa di-splice"
            end
            return "Hasil Splice: " .. GetItemName(_Dv) .. " [" .. tostring(_Dv) .. "]"
        end
        local function _Dw(_Dx, _Dy, _Dz)
            if not Refs.Trees then
                Refs.Scan()
            end
            local _DA = Refs.Trees and Refs.Trees[_Dz * _Dx.w + _Dy]
            return type(_DA) == "table" and _DA.s == true
        end
        local function _DB(_DC, _DD, _DE, _DF)
            local _DG = _DC and rawget(_DC, "spliceSeed")
            if type(_DG) ~= "function" then
                return false, "fungsi spliceSeed tidak ditemukan"
            end
            local _DH, _DI = pcall(_DG, _DD, _DE, _DF)
            if _DH and _DI and ItemDatabase[_DI] then
                if Refs.Inv and type(Refs.Inv.remove) == "function" then
                    pcall(function()
                        Refs.Inv:remove(_DF, 1)
                    end)
                end
                if Refs.SetTile then
                    pcall(Refs.SetTile, "fg", _DD, _DE, _DI, true)
                end
                AutoSplice.made += 1
                AutoSplice.status = string.format("Splice jadi %s (%d,%d)", GetItemName(_DI), _DD, _DE)
                return true
            end
            return false, "ditolak server"
        end
        local function _DJ(_DK, _DL)
            local _DM = math.min(GetPunchRange(), GetBuildRange()) - 0.15
            while AutoSplice.on and AutoSplice.token == _DK and IsSessionAlive() do
                local _DN = GetWorld()
                if not _DN or GetWorldName() ~= _DL.world then
                    AutoSplice.status = "World berubah, berhenti"
                    break
                end
                local _DO, _DP = Config.spliceA, Config.spliceB
                local _DQ, _DR = CountInventoryItem(_DO), CountInventoryItem(_DP)
                if _DR <= 0 then
                    AutoSplice.status = "Seed B habis!"
                    ShowNotification("Auto Splice berhenti: " .. GetItemName(_DP) .. " habis.")
                    break
                end
                local _DS = false
                if Config.spliceRoam then
                    local _DT = {}
                    local _DU = os.clock()
                    for _DV = 0, _DN.h - 1 do
                        for _DW = 0, _DN.w - 1 do
                            local _DX = _DW .. "," .. _DV
                            if not (AutoSplice.skip[_DX] and AutoSplice.skip[_DX] > _DU) then
                                local _DY = ReadTile(_DN, "fg", _DW, _DV) or 0
                                if _DY == 0 and _DQ > 0 and CanPlantSeedAt(_DN, _DW, _DV, _DO) then
                                    table.insert(_DT, {
                                        x = _DW,
                                        y = _DV,
                                        key = _DX
                                    })
                                elseif _DY == _DO and not _Dw(_DN, _DW, _DV) and not IsTreeReady(_DN, _DW, _DV, _DO) then
                                    table.insert(_DT, {
                                        x = _DW,
                                        y = _DV,
                                        key = _DX
                                    })
                                end
                            end
                        end
                    end
                    if #_DT == 0 then
                        AutoSplice.status = (_DQ <= 0) and "Seed A habis & tidak ada pohon A" or "Tidak ada lahan kosong untuk tanam/splice"
                        break
                    end
                    for _DZ, _Ea in ipairs(_DT) do
                        if not AutoSplice.on or AutoSplice.token ~= _DK or not IsSessionAlive() then
                            break
                        end
                        if CountInventoryItem(_DP) <= 0 then
                            break
                        end
                        local _Eb = GetCharacterState()
                        local _Ec, _Ed = GetCurrentTile()
                        if not (_Eb and Navigation.StateReaches(_Eb, _Ea.x, _Ea.y, _DM)) then
                            AutoSplice.status = string.format("Menuju (%d,%d) [%d/%d]", _Ea.x, _Ea.y, _DZ, #_DT)
                            if _Ed and _Ea.y < _Ed then
                                Navigation.ClimbUpWithDirt(_Ec, _Ea.y, function()
                                    return AutoSplice.token ~= _DK
                                end, true, Config.moveStepDelay)
                            end
                            Navigation.To(_Ea.x, _Ea.y, function()
                                return AutoSplice.token ~= _DK
                            end, _DM, true)
                            task.wait(0.2)
                        end
                        if (ReadTile(_DN, "fg", _Ea.x, _Ea.y) or 0) == 0 and CountInventoryItem(_DO) > 0 then
                            if PlaceInventoryItem(_DO, {
                                x = _Ea.x,
                                y = _Ea.y
                            }, 1) then
                                AutoSplice.planted += 1
                                SessionStats.Planted += 1
                                _DS = true
                                task.wait(math.max(0.14, Config.spliceMs / 1000))
                            end
                        end
                        if (ReadTile(_DN, "fg", _Ea.x, _Ea.y) or 0) == _DO and CountInventoryItem(_DP) > 0 and not _Dw(_DN, _Ea.x, _Ea.y) then
                            local _Ee, _Ef = _DB(_DN, _Ea.x, _Ea.y, _DP)
                            if not _Ee then
                                AutoSplice.skip[_Ea.key] = os.clock() + 45
                                AutoSplice.status = string.format("Gagal splice (%d,%d): %s", _Ea.x, _Ea.y, tostring(_Ef))
                            else
                                _DS = true
                            end
                            task.wait(math.max(0.14, Config.spliceMs / 1000))
                        end
                    end
                else
                    local _Eg, _Eh = GetCurrentTile()
                    if not _Eg then
                        break
                    end
                    local _Ei = os.clock()
                    for _Ej, _Ek in pairs(Config.farmGrid) do
                        if _Ek then
                            local _El, _Em = tostring(_Ej):match("^(-?%d+),(-?%d+)$")
                            if _El and _Em then
                                local _En, _Eo = _Eg + tonumber(_El), _Eh + tonumber(_Em)
                                local _Ep = _En .. "," .. _Eo
                                if IsTileInWorld(_DN, _En, _Eo) and not (AutoSplice.fail[_Ep] and AutoSplice.fail[_Ep] > _Ei) then
                                    local _Eq = ReadTile(_DN, "fg", _En, _Eo) or 0
                                    if _Eq == 0 and CountInventoryItem(_DO) > 0 and CountInventoryItem(_DP) > 0 and CanPlantSeedAt(_DN, _En, _Eo, _DO) then
                                        if PlaceInventoryItem(_DO, {
                                            x = _En,
                                            y = _Eo
                                        }, 1) then
                                            AutoSplice.planted += 1
                                            SessionStats.Planted += 1
                                            _DS = true
                                            task.wait(math.max(0.14, Config.spliceMs / 1000))
                                        end
                                    end
                                    if (ReadTile(_DN, "fg", _En, _Eo) or 0) == _DO and CountInventoryItem(_DP) > 0 and not _Dw(_DN, _En, _Eo) then
                                        local _Er, _Es = _DB(_DN, _En, _Eo, _DP)
                                        if not _Er then
                                            AutoSplice.fail[_Ep] = os.clock() + 30
                                            AutoSplice.status = string.format("Gagal splice (%d,%d): %s", _En, _Eo, tostring(_Es))
                                        end
                                        _DS = true
                                        task.wait(math.max(0.14, Config.spliceMs / 1000))
                                    end
                                end
                            end
                        end
                    end
                    if not _DS then
                        if CountInventoryItem(_DO) <= 0 or CountInventoryItem(_DP) <= 0 then
                            AutoSplice.status = "Seed habis"
                            break
                        end
                        AutoSplice.status = "Menunggu tile Grid kosong..."
                        task.wait(1)
                    end
                end
                if not _DS and Config.spliceRoam then
                    break
                end
                task.wait(0.2)
            end
        end
        function AutoSplice.Stop()
            if not AutoSplice.on then
                return false
            end
            AutoSplice.token += 1
            AutoSplice.on = false
            AutoSplice.roaming = false
            ReleaseMovementKeys()
            MovementInput.active = false
            AutoSplice.status = "Mati"
            return true
        end
        function AutoSplice.Start()
            if AutoSplice.on then
                return true
            end
            if not (Config.spliceA and Config.spliceB) or Config.spliceA == Config.spliceB then
                ShowNotification("Auto Splice: Pilih Seed A dan Seed B yang berbeda!")
                return false
            end
            if HasSpliceModule and type(SpliceModule) == "table" and not AutoSplice.Result(Config.spliceA, Config.spliceB) then
                ShowNotification("Kombinasi Seed A & Seed B ini tidak bisa di-splice!")
                return false
            end
            if AutoFarm.on then
                StopAutoFarm()
            end
            if AutoClear.on then
                AutoClear.Stop()
            end
            if Farmer.on then
                Farmer.Stop()
            end
            if DirtFarm.on then
                DirtFarm.Stop()
            end
            if SeedFactory.on then
                SeedFactory.Stop()
            end
            local _Et, _Eu = GetCalibratedPosition()
            if not _Et then
                ShowNotification("Posisi belum terdeteksi.");
                return false
            end
            local _Ev = {
                x = math.floor(_Et),
                y = math.floor(_Eu - 0.475),
                world = GetWorldName()
            }
            table.clear(AutoSplice.fail)
            table.clear(AutoSplice.skip)
            AutoSplice.token += 1
            local _Ew = AutoSplice.token
            AutoSplice.on = true
            AutoSplice.roaming = Config.spliceRoam
            AutoSplice.status = "Mulai..."
            task.spawn(function()
                local _Ex, _Ey = pcall(_DJ, _Ew, _Ev)
                if not _Ex then
                    warn("[ANCHHub] Auto Splice error: " .. tostring(_Ey))
                end
                ReleaseMovementKeys()
                MovementInput.active = false
                if AutoSplice.token == _Ew then
                    AutoSplice.on = false
                    AutoSplice.roaming = false
                    if AutoSplice.status == "Mulai..." then
                        AutoSplice.status = "Mati"
                    end
                    if SyncFeatureControls then
                        SyncFeatureControls()
                    end
                end
            end)
            return true
        end
    end)()
end
do
    (function()
        local function _Ez(_EA)
            if writefile then
                _EA.updatedAt = os.time()
                pcall(writefile, FactoryStateFile, HttpService:JSONEncode(_EA))
            end
        end
        local function _EB()
            if isfile and delfile and isfile(FactoryStateFile) then
                pcall(delfile, FactoryStateFile)
            end
        end
        function SeedFactory.ParseDropTarget()
            local _EC = tostring(Config.pabrikDropWorld or ""):gsub("%s", "")
            local _ED, _EE = string.match(_EC, "^([^:]*):(.+)$")
            if not _ED then
                _ED = _EC
            end
            _ED = string.upper(_ED):gsub("[^A-Z0-9]", "")
            if _EE == "" then
                _EE = nil
            end
            return _ED, _EE
        end
        local function _EF()
            local _EG = Refs.Menu
            if _EG and type(rawget(_EG, "openPicker")) == "function" and pcall(_EG.openPicker) then
                return true
            end
            local _EH = GetWorld()
            if _EH and type(rawget(_EH, "call")) == "function" then
                return pcall(_EH.call, "LeaveWorld")
            end
            return false
        end
        local function _EI(_EJ, _EK)
            _EJ = TrimText(_EJ):upper()
            if _EJ == "" then
                return false, "nama world kosong"
            end
            if GetWorldName():upper() == _EJ then
                return true
            end
            if QueueReloadOnTeleport then
                pcall(QueueReloadOnTeleport)
            end
            local _EL = GetWorld()
            if GetWorldName() ~= "" then
                _EF()
                task.wait(1.8)
            end
            _EL = GetWorld()
            if _EK and _EL then
                rawset(_EL, "arriveDoor", _EK)
            end
            local _EM = _EL and rawget(_EL, "fg")
            local _EN = Refs.Menu
            if _EN and type(rawget(_EN, "enter")) == "function" then
                pcall(_EN.enter, _EJ)
            elseif _EL and type(rawget(_EL, "enter")) == "function" then
                pcall(_EL.enter, _EJ)
            else
                return false, "fungsi enter tidak ditemukan"
            end
            local _EO = os.clock()
            while IsSessionAlive() and os.clock() - _EO < 10 do
                local _EP = GetWorld()
                if _EP and rawget(_EP, "fg") ~= _EM and GetWorldName():upper() == _EJ then
                    Refs.Scan()
                    task.wait(1.2)
                    return true
                end
                task.wait(0.25)
            end
            return false, "sedang teleport / terkunci"
        end
        local function _EQ(_ER)
            local _ES = Drops.list
            if not _ES then
                Refs.Scan();
                _ES = Drops.list
            end
            if type(_ES) ~= "table" then
                return nil
            end
            local _ET, _EU = GetCurrentTile()
            _ET, _EU = _ET or 50, _EU or 30
            local _EV = SeedFactory.Zone
            if _EV and _EV.world ~= GetWorldName() then
                _EV = nil
            end
            local _EW, _EX = nil, math.huge
            for _EY, _EZ in ipairs(_ES) do
                if type(_EZ) == "table" and _EZ.id == _ER and (_EZ.n or 0) > 0 and type(_EZ.x) == "number" then
                    if not (_EV and math.abs(_EZ.x - _EV.x) <= 2.5 and math.abs(_EZ.y - _EV.y) <= 2.5) then
                        local _Fa = math.abs(_EZ.x - _ET) + math.abs(_EZ.y - _EU)
                        if _Fa < _EX then
                            _EW, _EX = _EZ, _Fa
                        end
                    end
                end
            end
            return _EW
        end
        local function _Fb(_Fc, _Fd)
            local _Fe = false
            while _Fd() and CountInventoryItem(_Fc) < 200 do
                local _Ff = _EQ(_Fc)
                if not _Ff then
                    break
                end
                local _Fg, _Fh = math.floor(_Ff.x), math.floor(_Ff.y)
                SeedFactory.phase = "COLLECT BLOCK"
                SeedFactory.status = string.format("Mengambil drop %s di (%d,%d)...", GetItemName(_Fc), _Fg, _Fh)
                Navigation.To(_Fg, _Fh, function()
                    return not _Fd()
                end, 0.5, false)
                _Fe = true
                task.wait(0.45)
            end
            return _Fe
        end
        local function _Fi(_Fj, _Fk, _Fl)
            local _Fm = Refs.Hud or GetInventoryHud()
            local _Fn = _Fm and rawget(_Fm, "onDrop")
            local _Fo = _Fk
            local _Fp = false
            while _Fo > 0 and _Fl() and CountInventoryItem(_Fj) > 0 do
                local _Fq = CountInventoryItem(_Fj)
                local _Fr = math.min(_Fo, _Fq, 200)
                if type(_Fn) == "function" then
                    pcall(_Fn, _Fj, _Fr)
                elseif DropItemRemote then
                    pcall(function()
                        DropItemRemote:FireServer(_Fj, _Fr)
                    end)
                end
                task.wait(0.8)
                local _Fs = _Fq - CountInventoryItem(_Fj)
                if _Fs > 0 then
                    _Fo = _Fo - _Fs
                    SeedFactory.dropped = SeedFactory.dropped + _Fs
                elseif not _Fp then
                    _Fp = true
                    local _Ft = GetCharacterState()
                    local _Fu = _Ft and (_Ft.facing or 1) < 0
                    MovementInput.active = true
                    MovementInput.right, MovementInput.left = _Fu, not _Fu
                    task.wait(0.08)
                    ReleaseMovementKeys()
                    MovementInput.active = false
                    task.wait(0.35)
                else
                    return _Fk - _Fo, "tile drop penuh"
                end
            end
            return _Fk - _Fo, nil
        end
        local function _Fv(_Fw, _Fx, _Fy)
            local _Fz, _FA = SeedFactory.ParseDropTarget()
            local _FB = SeedFactory.home ~= "" and SeedFactory.home or GetWorldName()
            if _Fz == "" then
                _Fz = _FB
            end
            if Config.pabrikDropX < 0 and not _FA and _Fz == _FB then
                SeedFactory.status = "Posisi drop belum diatur (drop dilewati)"
                SeedFactory.dropOffUntil = os.clock() + 60
                return
            end
            SeedFactory.traveling = true
            local _FC = _Fz:upper() ~= GetWorldName():upper()
            _Ez({
                active = true,
                stage = "dropping",
                homeWorld = _FB,
                targetWorld = _Fz,
                doorId = _FA,
                seedId = _Fw,
                dropAmount = _Fx,
            })
            local _FD, _FE = true, nil
            if _FC or _FA then
                SeedFactory.status = "Menuju world penyimpanan " .. _Fz .. (_FA and (":" .. _FA) or "") .. "..."
                local _FF, _FG = _EI(_Fz, _FA)
                if not _FF then
                    _FD, _FE = false, "Gagal masuk " .. _Fz .. " (" .. tostring(_FG) .. ")"
                end
            end
            if _FD and _Fy() and Config.pabrikDropX >= 0 and Config.pabrikDropY >= 0 then
                SeedFactory.status = string.format("Jalan A* ke posisi drop (%d,%d)...", Config.pabrikDropX, Config.pabrikDropY)
                local _FH = false
                for _FI = 1, 3 do
                    if not _Fy() then
                        break
                    end
                    if Navigation.To(Config.pabrikDropX, Config.pabrikDropY, function()
                        return not _Fy()
                    end, 0.5, false) then
                        _FH = true
                        break
                    end
                    task.wait(0.3)
                end
                if not _FH then
                    _FD, _FE = false, ("Tidak bisa jalan ke posisi drop (pastikan tidak terhalang tembok" .. ")")
                end
            end
            if _FD and _Fy() then
                local _FJ = GetCharacterState()
                if _FJ then
                    SeedFactory.Zone = {
                        world = GetWorldName(),
                        x = _FJ.x,
                        y = _FJ.y - 0.475
                    }
                end
                local _FK, _FL = _Fi(_Fw, _Fx, _Fy)
                if _FK > 0 then
                    local _FM = string.format("Berhasil Drop %s x%d di %s", GetItemName(_Fw), _FK, GetWorldName())
                    SeedFactory.status = _FM
                    ShowNotification(_FM, "Pabrik ANCH")
                    Webhook.Send("pabrik", _FM)
                end
                if _FL then
                    _FD, _FE = false, _FL
                end
            end
            if not _FD then
                SeedFactory.dropOffUntil = os.clock() + 90
                SeedFactory.status = "Drop gagal: " .. tostring(_FE)
            end
            _Ez({
                active = true,
                stage = "farming",
                homeWorld = _FB,
                targetWorld = _Fz,
                seedId = _Fw,
            })
            if _FB ~= "" and GetWorldName():upper() ~= _FB:upper() and _Fy() then
                SeedFactory.status = "Kembali ke world pabrik " .. _FB .. "..."
                if not _EI(_FB, nil) and _Fy() then
                    task.wait(4)
                    _EI(_FB, nil)
                end
            end
            SeedFactory.traveling = false
        end
        -- [20] SEED FACTORY: penyimpanan seed dan perpindahan world.
        function SeedFactory.ExternalDropSeed(_FN, _FO, _FP, _FQ, _FR, _FS, _FT, _FU, _FV)
            local _FW, _FX, _FY, _FZ = Config.pabrikDropWorld, Config.pabrikDropX, Config.pabrikDropY, SeedFactory.home
            Config.pabrikDropWorld = _FP or ""
            Config.pabrikDropX = _FQ or -1
            Config.pabrikDropY = _FR or -1
            SeedFactory.home = _FS or GetWorldName()
            _Fv(_FN, _FO, _FV)
            Config.pabrikDropWorld, Config.pabrikDropX, Config.pabrikDropY, SeedFactory.home = _FW, _FX, _FY, _FZ
            if _FT and _FU and _FV() then
                Navigation.To(_FT, _FU, function()
                    return not _FV()
                end, 0.3, false)
            end
        end
        local function _Ga(_Gb, _Gc)
            if not Config.pabrikDrop then
                return false
            end
            local _Gd = CountInventoryItem(_Gb)
            local _Ge = math.max(1, tonumber(Config.pabrikMaxSeed) or 100)
            if _Gd > _Ge and os.clock() >= (SeedFactory.dropOffUntil or 0) then
                local _Gf = _Gd - _Ge
                if _Gf > 0 then
                    SeedFactory.phase = "DROP KELEBIHAN SEED"
                    SeedFactory.status = string.format("Seed %d > Max (%d)! Drop %d seed...", _Gd, _Ge, _Gf)
                    _Fv(_Gb, _Gf, _Gc)
                    return true
                end
            end
            return false
        end
        local function _Gg(_Gh, _Gi, _Gj)
            if Config.pabrikBreakX < 0 or Config.pabrikBreakY < 0 then
                SeedFactory.status = "Posisi Break belum diatur! Tekan tombol SetPos Break dulu."
                ShowNotification(("Pabrik: Tekan tombol 'SetPos Break' di tab Pabrik terlebih dahul" .. "u!"))
                task.wait(2.5)
                return false
            end
            if next(Config.pabrikTiles) == nil then
                Config.pabrikTiles = { ["1,0"] = true }
            end
            while _Gj() do
                _Ga(_Gh, _Gj)
                if not _Gj() then
                    break
                end
                if CountInventoryItem(_Gi) <= 0 then
                    if not _Fb(_Gi, _Gj) or CountInventoryItem(_Gi) <= 0 then
                        break
                    end
                end
                SeedFactory.phase = "BREAK BLOCK"
                local _Gk, _Gl = GetCurrentTile()
                if _Gk ~= Config.pabrikBreakX or _Gl ~= Config.pabrikBreakY then
                    SeedFactory.status = string.format("Menuju Posisi Break (%d,%d)...", Config.pabrikBreakX, Config.pabrikBreakY)
                    if not Navigation.To(Config.pabrikBreakX, Config.pabrikBreakY, function()
                        return not _Gj()
                    end, 0.5, false) then
                        SeedFactory.status = "Gagal jalan ke Posisi Break, mencoba ulang..."
                        task.wait(2)
                        break
                    end
                end
                if not _Gj() then
                    break
                end
                local _Gm, _Gn, _Go = GetCalibratedPosition()
                if not _Gm then
                    break
                end
                local _Gp = {
                    x = Config.pabrikBreakX,
                    y = Config.pabrikBreakY,
                    facing = _Go,
                    world = GetWorldName(),
                }
                AutoFarm.Override = {
                    offsets = Config.pabrikTiles,
                    block = _Gi,
                    mode = "Place + Break"
                }
                AutoFarm.Quiet = true
                AutoFarm.token = AutoFarm.token + 1
                local _Gq = AutoFarm.token
                AutoFarm.on = true
                local _Gr = SessionStats.Placed + SessionStats.Broken
                local _Gs = os.clock()
                task.spawn(function()
                    while AutoFarm.on and AutoFarm.token == _Gq do
                        task.wait(0.4)
                        local _Gt = SessionStats.Placed + SessionStats.Broken
                        if _Gt ~= _Gr then
                            _Gr, _Gs = _Gt, os.clock()
                        end
                        local _Gu = CountInventoryItem(_Gh)
                        local _Gv = CountInventoryItem(_Gi)
                        local _Gw = math.max(1, tonumber(Config.pabrikMaxSeed) or 100)
                        if not _Gj() or _Gv <= 0 or (Config.pabrikDrop and _Gu > _Gw and _Gu >= 180) or (os.clock() - _Gs > 8) then
                            AutoFarm.on = false
                        end
                    end
                end)
                SeedFactory.status = string.format("Break %s di (%d,%d) [Sisa: %d]...", GetItemName(_Gi), _Gp.x, _Gp.y, CountInventoryItem(_Gi))
                pcall(RunAutoFarmCycle, _Gq, _Gp)
                AutoFarm.on = false
                AutoFarm.Override = nil
                AutoFarm.Quiet = false
                task.wait(0.3)
            end
            return true
        end
        local function _Gx(_Gy, _Gz)
            if Config.pabrikBreakX < 0 or Config.pabrikBreakY < 0 then
                return false
            end
            if _Gy == Config.pabrikBreakX and _Gz == Config.pabrikBreakY then
                return true
            end
            for _GA, _GB in pairs(Config.pabrikTiles) do
                if _GB then
                    local _GC, _GD = tostring(_GA):match("^(-?%d+),(-?%d+)$")
                    if _GC and _GD then
                        if _Gy == (Config.pabrikBreakX + tonumber(_GC)) and _Gz == (Config.pabrikBreakY + tonumber(_GD)) then
                            return true
                        end
                    end
                end
            end
            return false
        end
        local function _GE(_GF, _GG)
            local _GH = {}
            local _GI = 0
            local _GJ = nil
            local _GK = workspace:GetServerTimeNow()
            local _GL = ItemDatabase[_GG]
            local _GM = (_GL and (tonumber(_GL.grow) or tonumber(_GL.baseGrow))) or 31
            local _GN = 1
            for _GO = 0, _GF.h - 1 do
                local _GP = {}
                for _GQ = 0, _GF.w - 1 do
                    local _GR = ReadTile(_GF, "fg", _GQ, _GO) or 0
                    if _GR == _GG then
                        local _GS = GetTreeReadyAt(_GF, _GQ, _GO, _GR)
                        if _GS then
                            if _GK >= _GS then
                                table.insert(_GP, {
                                    x = _GQ,
                                    y = _GO
                                })
                            else
                                _GI = _GI + 1
                                local _GT = _GS - _GK
                                if not _GJ or _GT < _GJ then
                                    _GJ = _GT
                                end
                            end
                        else
                            _GI = _GI + 1
                            if not _GJ or _GM < _GJ then
                                _GJ = _GM
                            end
                        end
                    end
                end
                if #_GP > 0 then
                    if _GN == -1 then
                        table.sort(_GP, function(_GU, _GV)
                            return _GU.x > _GV.x
                        end)
                    else
                        table.sort(_GP, function(_GW, _GX)
                            return _GW.x < _GX.x
                        end)
                    end
                    for _GY, _GZ in ipairs(_GP) do
                        table.insert(_GH, _GZ)
                    end
                    _GN = -_GN
                end
            end
            return _GH, _GI, _GJ
        end
        local function _Ha(_Hb, _Hc)
            local function _Hd()
                return SeedFactory.on and SeedFactory.token == _Hb and IsSessionAlive()
            end
            local _He = math.min(GetPunchRange(), GetBuildRange()) - 0.15
            while _Hd() do
                local _Hf = GetWorld()
                while not _Hf and _Hd() do
                    task.wait(1)
                    _Hf = GetWorld()
                end
                if not _Hd() then
                    break
                end
                local _Hg = Config.pabrikSeedId
                local _Hh = math.max(1, tonumber(Config.pabrikMaxSeed) or 100)
                if CountInventoryItem(_Hc) > 0 or _EQ(_Hc) ~= nil then
                    _Gg(_Hg, _Hc, _Hd)
                    if not _Hd() then
                        break
                    end
                    _Hf = GetWorld()
                end
                _Ga(_Hg, _Hd)
                if not _Hd() then
                    break
                end
                _Hf = GetWorld()
                local _Hi, _Hj = _GE(_Hf, _Hg)
                local _Hk = #_Hi + _Hj
                local _Hl = math.max(0, _Hh - _Hk)
                if CountInventoryItem(_Hg) > 0 and _Hl > 0 then
                    SeedFactory.phase = "TANAM SEED"
                    local _Hm = {}
                    local _Hn = 1
                    for _Ho = 0, _Hf.h - 1 do
                        local _Hp = {}
                        for _Hq = 0, _Hf.w - 1 do
                            if (ReadTile(_Hf, "fg", _Hq, _Ho) or 0) == 0 and CanPlantSeedAt(_Hf, _Hq, _Ho, _Hg) and not _Gx(_Hq, _Ho) then
                                table.insert(_Hp, {
                                    x = _Hq,
                                    y = _Ho
                                })
                            end
                        end
                        if #_Hp > 0 then
                            if _Hn == -1 then
                                table.sort(_Hp, function(_Hr, _Hs)
                                    return _Hr.x > _Hs.x
                                end)
                            else
                                table.sort(_Hp, function(_Ht, _Hu)
                                    return _Ht.x < _Hu.x
                                end)
                            end
                            for _Hv, _Hw in ipairs(_Hp) do
                                table.insert(_Hm, _Hw)
                            end
                            _Hn = -_Hn
                        end
                    end
                    local _Hx = 0
                    for _Hy, _Hz in ipairs(_Hm) do
                        if not _Hd() or CountInventoryItem(_Hg) <= 0 or _Hx >= _Hl then
                            break
                        end
                        if CanPlantSeedAt(_Hf, _Hz.x, _Hz.y, _Hg) then
                            local _HA = GetCharacterState()
                            if not (_HA and Navigation.StateReaches(_HA, _Hz.x, _Hz.y, _He)) then
                                SeedFactory.status = string.format("Jalan Zig-Zag tanam (%d,%d) [%d/%d]", _Hz.x, _Hz.y, _Hx + 1, _Hl)
                                Navigation.To(_Hz.x, _Hz.y, function()
                                    return not _Hd()
                                end, _He, false)
                            end
                            local _HB = GetCharacterState()
                            if _HB and Navigation.StateReaches(_HB, _Hz.x, _Hz.y, _He + 0.5) and CanPlantSeedAt(_Hf, _Hz.x, _Hz.y, _Hg) and PlaceInventoryItem(_Hg, _Hz, 1) then
                                _Hx = _Hx + 1
                                SeedFactory.planted = SeedFactory.planted + 1
                                SessionStats.Planted = SessionStats.Planted + 1
                                SeedFactory.status = string.format("Menanam %s (%d/%d Max Seed)", GetItemName(_Hg), _Hk + _Hx, _Hh)
                                task.wait(math.max(0.05, Config.harvestPlantDelay))
                            end
                        end
                    end
                end
                if not _Hd() then
                    break
                end
                _Hf = GetWorld()
                local _HC, _HD, _HE = _GE(_Hf, _Hg)
                if #_HC == 0 and _HD > 0 then
                    SeedFactory.phase = "TUNGGU TUMBUH"
                    while _Hd() do
                        _Hf = GetWorld()
                        if not _Hf then
                            break
                        end
                        _HC, _HD, _HE = _GE(_Hf, _Hg)
                        if #_HC > 0 or _HD == 0 then
                            break
                        end
                        local _HF = math.max(1, math.ceil(_HE or 15))
                        SeedFactory.status = string.format("Menunggu %d pohon siap panen (±%ds)...", _HD, _HF)
                        task.wait(1)
                    end
                end
                if not _Hd() then
                    break
                end
                if #_HC > 0 then
                    SeedFactory.phase = "PANEN ZIG-ZAG"
                    for _HG, _HH in ipairs(_HC) do
                        if not _Hd() then
                            break
                        end
                        if CountInventoryItem(_Hc) >= 200 then
                            SeedFactory.status = "Blok mencapai 200! Menuju Posisi Break..."
                            _Gg(_Hg, _Hc, _Hd)
                            if not _Hd() then
                                break
                            end
                            _Ga(_Hg, _Hd)
                            if not _Hd() then
                                break
                            end
                        end
                        _Hf = GetWorld()
                        if _Hf and (ReadTile(_Hf, "fg", _HH.x, _HH.y) or 0) == _Hg then
                            local _HI = GetCharacterState()
                            if not (_HI and Navigation.StateReaches(_HI, _HH.x, _HH.y, _He)) then
                                SeedFactory.status = string.format("Panen Zig-Zag (%d,%d) [%d/%d]", _HH.x, _HH.y, _HG, #_HC)
                                Navigation.To(_HH.x, _HH.y, function()
                                    return not _Hd()
                                end, _He, false)
                            end
                            local _HJ = GetCharacterState()
                            if _HJ and Navigation.StateReaches(_HJ, _HH.x, _HH.y, _He + 0.5) then
                                local _HK = os.clock()
                                while _Hd() and (ReadTile(_Hf, "fg", _HH.x, _HH.y) or 0) == _Hg and os.clock() - _HK < 3.5 do
                                    local _HL = PunchTile(_HH.x, _HH.y, false)
                                    if _HL == "broke" then
                                        SeedFactory.harvested = SeedFactory.harvested + 1
                                        SessionStats.Harvested = SessionStats.Harvested + 1
                                    end
                                    task.wait(math.max(0.05, Config.harvestDelay))
                                end
                                task.wait(0.20)
                            end
                        end
                    end
                    _Fb(_Hc, _Hd)
                    if CountInventoryItem(_Hc) > 0 then
                        _Gg(_Hg, _Hc, _Hd)
                    end
                    _Ga(_Hg, _Hd)
                else
                    if CountInventoryItem(_Hg) <= 0 and CountInventoryItem(_Hc) <= 0 and _EQ(_Hc) == nil then
                        SeedFactory.status = "Selesai: Seed, blok, dan pohon sudah habis."
                        _EB()
                        break
                    end
                end
                task.wait(0.3)
            end
        end
        function SeedFactory.Stop()
            _EB()
            if not SeedFactory.on then
                return false
            end
            SeedFactory.token = SeedFactory.token + 1
            SeedFactory.on = false
            SeedFactory.traveling = false
            if AutoFarm.Override then
                AutoFarm.on = false
                AutoFarm.Override = nil
                AutoFarm.Quiet = false
            end
            ReleaseMovementKeys()
            MovementInput.active = false
            SeedFactory.phase = "-"
            SeedFactory.status = "Mati"
            if RefreshGridGui then
                pcall(RefreshGridGui)
            end
            return true
        end
        function SeedFactory.Start(_HM)
            if SeedFactory.on then
                return true
            end
            local _HN = Config.pabrikSeedId
            local _HO = GetBlockIdFromSeed(_HN)
            if not _HN or not _HO then
                ShowNotification("Pabrik: Pilih seed pabrik yang valid terlebih dahulu!")
                return false
            end
            if AutoFarm.on then
                StopAutoFarm()
            end
            if AutoClear.on then
                AutoClear.Stop()
            end
            if Farmer.on then
                Farmer.Stop()
            end
            if DirtFarm.on then
                DirtFarm.Stop()
            end
            if AutoSplice.on then
                AutoSplice.Stop()
            end
            SeedFactory.home = _HM or GetWorldName()
            SeedFactory.dropOffUntil = 0
            SeedFactory.token = SeedFactory.token + 1
            local _HP = SeedFactory.token
            SeedFactory.on = true
            SeedFactory.phase = "MULAI"
            SeedFactory.status = "Inisialisasi Pabrik..."
            _Ez({
                active = true,
                stage = "farming",
                homeWorld = SeedFactory.home,
                seedId = _HN,
            })
            if RefreshGridGui then
                pcall(RefreshGridGui)
            end
            if SyncFeatureControls then
                SyncFeatureControls()
            end
            task.spawn(function()
                local _HQ, _HR = pcall(_Ha, _HP, _HO)
                if not _HQ then
                    warn("[ANCHHub] Pabrik error: " .. tostring(_HR))
                end
                ReleaseMovementKeys()
                MovementInput.active = false
                if SeedFactory.token == _HP then
                    SeedFactory.on = false
                    SeedFactory.traveling = false
                    SeedFactory.phase = "-"
                    if SeedFactory.status == "Inisialisasi Pabrik..." then
                        SeedFactory.status = "Mati"
                    end
                    if RefreshGridGui then
                        pcall(RefreshGridGui)
                    end
                    if SyncFeatureControls then
                        SyncFeatureControls()
                    end
                end
            end)
            return true
        end
        function SeedFactory.CheckStartup()
            pcall(function()
                if not (isfile and readfile and isfile(FactoryStateFile)) then
                    return
                end
                local _HS = readfile(FactoryStateFile)
                local _HT = HttpService:JSONDecode(_HS)
                if type(_HT) ~= "table" or not _HT.active then
                    return
                end
                if os.time() - (tonumber(_HT.updatedAt) or 0) > 1800 then
                    _EB()
                    return
                end
                local _HU = os.clock()
                while IsSessionAlive() and os.clock() - _HU < 30 do
                    if GetWorldName() ~= "" and GetCurrentTile() then
                        break
                    end
                    task.wait(1)
                end
                if not IsSessionAlive() or GetWorldName() == "" then
                    return
                end
                Refs.Scan()
                task.wait(1.2)
                local _HV = GetWorldName():upper()
                local _HW = tostring(_HT.homeWorld or ""):upper()
                local _HX = tostring(_HT.targetWorld or ""):upper()
                if _HT.stage == "dropping" and _HX ~= "" and _HV == _HX then
                    ShowNotification("Melanjutkan proses Drop Seed Pabrik di " .. _HV .. "...", "Pabrik ANCH")
                    SeedFactory.home = _HT.homeWorld
                    SeedFactory.on = true
                    SeedFactory.token = SeedFactory.token + 1
                    local _HY = SeedFactory.token
                    _Fv(_HT.seedId or Config.pabrikSeedId, _HT.dropAmount or Config.pabrikDropAmount or 100, function()
                        return SeedFactory.on and SeedFactory.token == _HY and IsSessionAlive()
                    end)
                    SeedFactory.on = false
                    if GetWorldName():upper() == _HW then
                        SeedFactory.Start(_HT.homeWorld)
                    end
                elseif _HW ~= "" and _HV == _HW then
                    ShowNotification("Melanjutkan siklus Pabrik otomatis di " .. _HV .. "!", "Pabrik ANCH")
                    SeedFactory.Start(_HT.homeWorld)
                elseif _HW ~= "" and _HV ~= _HW then
                    ShowNotification("Kembali ke world Pabrik: " .. _HW .. "...", "Pabrik ANCH")
                    if _EI(_HW, nil) then
                        SeedFactory.Start(_HT.homeWorld)
                    end
                end
            end)
        end
    end)()
end
do
    (function()
        local function _HZ(_Ia)
            if writefile then
                _Ia.updatedAt = os.time()
                pcall(writefile, AutoMoveStateFile, HttpService:JSONEncode(_Ia))
            end
        end
        local function _Ib()
            if isfile and delfile and isfile(AutoMoveStateFile) then
                pcall(delfile, AutoMoveStateFile)
            end
        end
        function AutoMove.ParseWorld(_Ic)
            local _Id = tostring(_Ic or ""):gsub("%s", "")
            local _Ie, _If = string.match(_Id, "^([^:]*):(.+)$")
            if not _Ie then
                _Ie = _Id
            end
            _Ie = string.upper(_Ie):gsub("[^A-Z0-9]", "")
            if _If == "" then
                _If = nil
            end
            return _Ie, _If
        end
        local function _Ig()
            local _Ih = Refs.Menu
            if _Ih and type(rawget(_Ih, "openPicker")) == "function" and pcall(_Ih.openPicker) then
                return true
            end
            local _Ii = GetWorld()
            if _Ii and type(rawget(_Ii, "call")) == "function" then
                return pcall(_Ii.call, "LeaveWorld")
            end
            return false
        end
        local function _Ij(_Ik, _Il)
            _Ik = TrimText(_Ik):upper()
            if _Ik == "" then
                return false, "nama world kosong"
            end
            if GetWorldName():upper() == _Ik and not _Il then
                return true
            end
            if QueueReloadOnTeleport then
                pcall(QueueReloadOnTeleport)
            end
            if GetWorldName() ~= "" then
                _Ig()
                task.wait(1.8)
            end
            local _Im = GetWorld()
            if _Il and _Im then
                rawset(_Im, "arriveDoor", _Il)
            end
            local _In = _Im and rawget(_Im, "fg")
            local _Io = Refs.Menu
            if _Io and type(rawget(_Io, "enter")) == "function" then
                pcall(_Io.enter, _Ik)
            elseif _Im and type(rawget(_Im, "enter")) == "function" then
                pcall(_Im.enter, _Ik)
            else
                return false, "fungsi enter world tidak ditemukan"
            end
            local _Ip = os.clock()
            while IsSessionAlive() and (os.clock() - _Ip) < 12 do
                local _Iq = GetWorld()
                if _Iq and rawget(_Iq, "fg") ~= _In and GetWorldName():upper() == _Ik then
                    Refs.Scan()
                    task.wait(1.2)
                    return true
                end
                task.wait(0.25)
            end
            return false, "timeout masuk world " .. _Ik
        end
        local function _Ir(_Is)
            if not Drops.list and Drops.findRefs then
                Drops.findRefs()
            end
            local _It = Drops.list
            if type(_It) ~= "table" then
                return nil, 0
            end
            local _Iu, _Iv = GetCurrentTile()
            _Iu, _Iv = _Iu or 50, _Iv or 30
            local _Iw, _Ix = nil, math.huge
            local _Iy = 0
            for _Iz, _IA in ipairs(_It) do
                if type(_IA) == "table" and _IA.id == _Is and (_IA.n or 0) > 0 and not _IA.display and type(_IA.x) == "number" then
                    _Iy = _Iy + (_IA.n or 0)
                    local _IB = math.abs(_IA.x - _Iu) + math.abs(_IA.y - _Iv)
                    if _IB < _Ix then
                        _Iw, _Ix = _IA, _IB
                    end
                end
            end
            return _Iw, _Iy
        end
        local function _IC(_ID, _IE, _IF, _IG)
            local _IH = Refs.Hud or GetInventoryHud()
            local _II = _IH and rawget(_IH, "onDrop")
            local _IJ, _IK = _IE, _IF
            local _IL = 0
            while _IG() and CountInventoryItem(_ID) > 0 and _IL < 25 do
                local _IM = CountInventoryItem(_ID)
                local _IN = math.min(_IM, 200)
                AutoMove.status = string.format("Drop %s x%d di (%d,%d)...", GetItemName(_ID), _IN, _IJ, _IK)
                if type(_II) == "function" then
                    pcall(_II, _ID, _IN)
                elseif DropItemRemote then
                    pcall(function()
                        DropItemRemote:FireServer(_ID, _IN)
                    end)
                elseif HasNetModule and type(NetModule) == "table" and NetModule.drop then
                    pcall(NetModule.drop.send, {
                        id = _ID,
                        n = _IN
                    })
                end
                task.wait(0.85)
                local _IO = CountInventoryItem(_ID)
                local _IP = _IM - _IO
                if _IP > 0 then
                    AutoMove.dropped = AutoMove.dropped + _IP
                end
                if CountInventoryItem(_ID) > 0 and _IG() then
                    _IL = _IL + 1
                    _IJ = _IJ + 1
                    local _IQ = GetWorld()
                    if _IQ and _IJ >= _IQ.w - 1 then
                        return false, "Mentok ujung kanan world!"
                    end
                    AutoMove.status = string.format("Tile penuh! Geser kanan 1 langkah ke (%d,%d)...", _IJ, _IK)
                    if not Navigation.SolidAt(_IJ, _IK) and Drops.walkToX then
                        local _IR = MovementInput.active
                        MovementInput.active = true
                        Drops.collecting = true
                        Drops.walkToX(_IJ + 0.5, 1.5)
                        Drops.collecting = false
                        MovementInput.active = _IR
                    else
                        Navigation.To(_IJ, _IK, function()
                            return not _IG()
                        end, 0.3, false)
                    end
                    task.wait(0.25)
                end
            end
            return CountInventoryItem(_ID) == 0, nil
        end
        local function _IS(_IT)
            local function _IU()
                return AutoMove.on and AutoMove.token == _IT and IsSessionAlive()
            end
            local _IV = tonumber(Config.moveItemId) or 0
            local _IW, _IX = AutoMove.ParseWorld(Config.moveWorld1)
            local _IY, _IZ = AutoMove.ParseWorld(Config.moveWorld2)
            while _IU() do
                local _Ja = CountInventoryItem(_IV)
                if _Ja < 200 then
                    AutoMove.pauseCollect = false
                    AutoMove.phase = "TAKE (WORLD 1)"
                    _HZ({
                        active = true,
                        stage = "taking",
                        w1 = Config.moveWorld1,
                        w2 = Config.moveWorld2,
                        dropX = Config.moveDropX,
                        dropY = Config.moveDropY,
                        itemId = _IV,
                    })
                    if GetWorldName():upper() ~= _IW then
                        AutoMove.traveling = true
                        AutoMove.status = "Pindah ke World 1: " .. _IW .. (_IX and (":" .. _IX) or "") .. "..."
                        local _Jb, _Jc = _Ij(_IW, _IX)
                        AutoMove.traveling = false
                        if not _Jb then
                            AutoMove.status = "Gagal masuk World 1 (" .. tostring(_Jc) .. "), coba lagi..."
                            task.wait(4)
                            continue
                        end
                    end
                    if not _IU() then
                        break
                    end
                    Refs.Scan()
                    if Drops.findRefs then
                        Drops.findRefs()
                    end
                    task.wait(0.8)
                    local _Jd, _Je = _Ir(_IV)
                    if not _Jd then
                        if CountInventoryItem(_IV) > 0 then
                            AutoMove.status = "Drop di World 1 habis, mengantar sisa tas ke World 2..."
                        else
                            _Ib()
                            AutoMove.pauseCollect = false
                            AutoMove.phase = "SELESAI"
                            local _Jf = string.format("Auto Move Selesai! %s habis di %s. Total dipindahkan: %d", GetItemName(_IV), _IW, AutoMove.dropped)
                            AutoMove.status = _Jf
                            ShowNotification(_Jf, "Auto Move Selesai", 6)
                            Webhook.Send("pabrik", _Jf)
                            break
                        end
                    else
                        while _IU() and CountInventoryItem(_IV) < 200 do
                            local _Jg = _Ir(_IV)
                            if not _Jg then
                                break
                            end
                            local _Jh, _Ji = math.floor(_Jg.x), math.floor(_Jg.y)
                            AutoMove.status = string.format("Ambil %s di (%d,%d) [Tas: %d/200]...", GetItemName(_IV), _Jh, _Ji, CountInventoryItem(_IV))
                            local _Jj = CountInventoryItem(_IV)
                            Navigation.To(_Jh, _Ji, function()
                                return not _IU()
                            end, 0.35, false)
                            if Drops.walkToX then
                                local _Jk = MovementInput.active
                                MovementInput.active = true
                                Drops.collecting = true
                                Drops.walkToX(_Jg.x, 1.0)
                                Drops.collecting = false
                                MovementInput.active = _Jk
                            end
                            local _Jl = GetWorld()
                            local _Jm = _Jl and rawget(_Jl, "takeDrop")
                            if type(_Jm) == "function" and _Jg.uid then
                                local _Jn = 200 - CountInventoryItem(_IV)
                                if _Jn > 0 then
                                    pcall(_Jm, _Jg.uid, math.min(_Jg.n or 1, _Jn))
                                end
                            end
                            task.wait(0.35)
                            local _Jo = CountInventoryItem(_IV)
                            if _Jo > _Jj then
                                AutoMove.collected = AutoMove.collected + (_Jo - _Jj)
                            end
                        end
                    end
                end
                if not _IU() then
                    break
                end
                if CountInventoryItem(_IV) > 0 then
                    AutoMove.phase = "DROP (WORLD 2)"
                    AutoMove.pauseCollect = true
                    _HZ({
                        active = true,
                        stage = "dropping",
                        w1 = Config.moveWorld1,
                        w2 = Config.moveWorld2,
                        dropX = Config.moveDropX,
                        dropY = Config.moveDropY,
                        itemId = _IV,
                    })
                    if GetWorldName():upper() ~= _IY or _IZ then
                        AutoMove.traveling = true
                        AutoMove.status = "Pindah ke World 2: " .. _IY .. (_IZ and (":" .. _IZ) or "") .. "..."
                        local _Jp, _Jq = _Ij(_IY, _IZ)
                        AutoMove.traveling = false
                        if not _Jp then
                            AutoMove.status = "Gagal masuk World 2 (" .. tostring(_Jq) .. "), coba lagi..."
                            task.wait(4)
                            continue
                        end
                    end
                    if not _IU() then
                        break
                    end
                    local _Jr, _Js = tonumber(Config.moveDropX) or -1, tonumber(Config.moveDropY) or -1
                    if _Jr >= 0 and _Js >= 0 then
                        AutoMove.status = string.format("Menuju Pos Drop (%d,%d) di %s...", _Jr, _Js, _IY)
                        local _Jt = false
                        for _Ju = 1, 3 do
                            if not _IU() then
                                break
                            end
                            if Navigation.To(_Jr, _Js, function()
                                return not _IU()
                            end, 0.35, false) then
                                _Jt = true
                                break
                            end
                            task.wait(0.3)
                        end
                        if not _Jt then
                            AutoMove.status = "Gagal jalan ke Pos Drop di World 2, coba ulang..."
                            task.wait(2)
                            continue
                        end
                    else
                        local _Jv, _Jw = GetCurrentTile()
                        _Jr, _Js = _Jv or 50, _Jw or 30
                    end
                    local _Jx = GetCharacterState()
                    if _Jx and (_Jx.facing or 1) < 0 then
                        MovementInput.active = true
                        MovementInput.right = true
                        task.wait(0.06)
                        ReleaseMovementKeys()
                        MovementInput.active = false
                    end
                    local _Jy, _Jz = _IC(_IV, _Jr, _Js, _IU)
                    if not _Jy and _Jz then
                        AutoMove.status = "Peringatan Drop: " .. tostring(_Jz)
                        task.wait(2)
                    end
                    _HZ({
                        active = true,
                        stage = "taking",
                        w1 = Config.moveWorld1,
                        w2 = Config.moveWorld2,
                        dropX = Config.moveDropX,
                        dropY = Config.moveDropY,
                        itemId = _IV,
                    })
                end
                task.wait(0.3)
            end
            AutoMove.pauseCollect = false
        end
        -- [21] KONTROL AUTO MOVE ITEM. Siklus pindah item berada tepat di atasnya.
        function AutoMove.Stop()
            _Ib()
            if not AutoMove.on then
                return false
            end
            AutoMove.token = AutoMove.token + 1
            AutoMove.on = false
            AutoMove.traveling = false
            AutoMove.pauseCollect = false
            ReleaseMovementKeys()
            MovementInput.active = false
            AutoMove.phase = "-"
            AutoMove.status = "Mati"
            if SyncFeatureControls then
                SyncFeatureControls()
            end
            return true
        end
        function AutoMove.Start()
            if AutoMove.on then
                return true
            end
            local _JA = AutoMove.ParseWorld(Config.moveWorld1)
            local _JB = AutoMove.ParseWorld(Config.moveWorld2)
            local _JC = tonumber(Config.moveItemId) or 0
            if _JA == "" or _JB == "" then
                ShowNotification("Auto Move: Isi nama World 1 dan World 2 terlebih dahulu!")
                return false
            end
            if Config.moveDropX < 0 or Config.moveDropY < 0 then
                ShowNotification("Auto Move: SetPos Drop di World 2 terlebih dahulu!")
                return false
            end
            if _JC <= 0 or not ItemDatabase[_JC] then
                ShowNotification("Auto Move: ID Item tidak valid!")
                return false
            end
            if AutoFarm.on then
                StopAutoFarm()
            end
            if AutoClear.on then
                AutoClear.Stop()
            end
            if Farmer.on then
                Farmer.Stop()
            end
            if DirtFarm.on then
                DirtFarm.Stop()
            end
            if AutoSplice.on then
                AutoSplice.Stop()
            end
            if SeedFactory.on then
                SeedFactory.Stop()
            end
            AutoMove.token = AutoMove.token + 1
            local _JD = AutoMove.token
            AutoMove.on = true
            AutoMove.phase = "MULAI"
            AutoMove.status = "Inisialisasi Auto Move..."
            if SyncFeatureControls then
                SyncFeatureControls()
            end
            task.spawn(function()
                local _JE, _JF = pcall(_IS, _JD)
                if not _JE then
                    warn("[ANCHHub] AutoMove error: " .. tostring(_JF))
                end
                AutoMove.pauseCollect = false
                ReleaseMovementKeys()
                MovementInput.active = false
                if AutoMove.token == _JD then
                    AutoMove.on = false
                    AutoMove.traveling = false
                    if AutoMove.phase ~= "SELESAI" then
                        AutoMove.status = "Mati"
                    end
                    if SyncFeatureControls then
                        SyncFeatureControls()
                    end
                end
            end)
            return true
        end
        function AutoMove.CheckStartup()
            pcall(function()
                if not (isfile and readfile and isfile(AutoMoveStateFile)) then
                    return
                end
                local _JG = readfile(AutoMoveStateFile)
                local _JH = HttpService:JSONDecode(_JG)
                if type(_JH) ~= "table" or not _JH.active then
                    return
                end
                if os.time() - (tonumber(_JH.updatedAt) or 0) > 1800 then
                    _Ib()
                    return
                end
                local _JI = os.clock()
                while IsSessionAlive() and (os.clock() - _JI) < 30 do
                    if GetWorldName() ~= "" and GetCurrentTile() then
                        break
                    end
                    task.wait(1)
                end
                if not IsSessionAlive() or GetWorldName() == "" then
                    return
                end
                Refs.Scan()
                task.wait(1.2)
                if _JH.w1 then
                    Config.moveWorld1 = _JH.w1
                end
                if _JH.w2 then
                    Config.moveWorld2 = _JH.w2
                end
                if _JH.dropX then
                    Config.moveDropX = _JH.dropX
                end
                if _JH.dropY then
                    Config.moveDropY = _JH.dropY
                end
                if _JH.itemId then
                    Config.moveItemId = _JH.itemId
                end
                ShowNotification("Melanjutkan progres Auto Move (" .. tostring(_JH.stage or "aktif") .. ")...", "Auto Move ANCH")
                AutoMove.Start()
            end)
        end
    end)()
end
do
    (function()
        local _JJ = {
            [242] = true,
            [1796] = true,
            [7188] = true
        }
        local _JK = {
            {
                from = 242,
                to = 1796,
                name = "Diamond Lock"
            },
            {
                from = 1796,
                to = 7188,
                name = "Blue Gem Lock"
            },
        }
        local function _JL(...)
            local _JM = GetWorld()
            local _JN = _JM and rawget(_JM, "call")
            if type(_JN) ~= "function" then
                return false
            end
            return pcall(_JN, ...)
        end
        local function _JO(_JP)
            local _JQ = ItemDatabase[_JP]
            return _JQ ~= nil and _JQ.kind ~= "tool" and not _JQ.lock and not _JJ[_JP]
        end
        function BackpackManager.Recycle(_JR, _JS)
            if not Refs.Inv or _JS <= 0 or not _JO(_JR) then
                return false
            end
            _JS = math.min(_JS, CountInventoryItem(_JR))
            if _JS <= 0 then
                return false
            end
            pcall(function()
                Refs.Inv:remove(_JR, _JS)
            end)
            local _JT = _JL("Recycle", _JR, _JS)
            if _JT then
                BackpackManager.recycled += _JS
                BackpackManager.status = string.format("Recycle %s x%d", GetItemName(_JR), _JS)
            end
            return _JT
        end
        local function _JU(_JV)
            local _JW = Refs.Inv
            if not _JW or CountInventoryItem(_JV.from) < 100 then
                return false
            end
            if CountInventoryItem(_JV.to) + 1 > 200 then
                return false
            end
            pcall(function()
                _JW:remove(_JV.from, 100)
                _JW:add(_JV.to, 1)
            end)
            local _JX = _JL("ConvertLock", _JV.from, _JV.to)
            if _JX then
                BackpackManager.converted += 1
                BackpackManager.status = "Convert ke " .. _JV.name
            end
            return _JX
        end
        task.spawn(function()
            while IsSessionAlive() do
                pcall(function()
                    if Config.trashOn and type(Config.trashList) == "table" then
                        for _JY, _JZ in ipairs(Config.trashList) do
                            local _Ka = CountInventoryItem(_JZ)
                            if _Ka >= Config.trashAt and _Ka > Config.trashKeep then
                                BackpackManager.Recycle(_JZ, _Ka - Config.trashKeep)
                                task.wait(0.5)
                            end
                        end
                    end
                    if Config.convertLockOn then
                        for _Kb, _Kc in ipairs(_JK) do
                            if _JU(_Kc) then
                                task.wait(0.5)
                            end
                        end
                    end
                end)
                task.wait(2.5)
            end
        end)
    end)()
end
-- [22] BOT VENDING MACHINE.
local VendingBot = {
    on = false,
    token = 0,
    status = "Mati",
    stocked = 0,
    taken = 0,
    dropped = 0,
    picked = {},
    carry = {}
}
do
    (function()
        function VendingBot.ParsePoint()
            local _Ke = tostring(Config.vendPoint or ""):gsub("%s", "")
            local _Kf, _Kg = string.match(_Ke, "^([^:|]*)[:|](.+)$")
            if not _Kf then
                _Kf = _Ke
            end
            _Kf = string.upper(_Kf):gsub("[^A-Z0-9]", "")
            if _Kg == "" then
                _Kg = nil
            end
            return _Kf, _Kg
        end
        function VendingBot.Sellable(_Kh)
            if type(_Kh) ~= "number" or _Kh == 112 then
                return false
            end
            local _Ki = ItemDatabase[_Kh]
            if not _Ki or _Ki.kind == "tool" then
                return false
            end
            if _Ki.lock or _Ki.area or _Ki.guildLock or _Ki.untradeable or _Ki.vend or _Ki.hub then
                return false
            end
            return true
        end
        function VendingBot.Allow(_Kj)
            if not VendingBot.Sellable(_Kj) then
                return false
            end
            if type(Config.vendItems) == "table" and #Config.vendItems > 0 and not table.find(Config.vendItems, _Kj) then
                return false
            end
            return true
        end
        function VendingBot.Machines()
            local _Kk = GetWorld()
            local _Kl = {}
            if not _Kk then
                return _Kl
            end
            local _Km = rawget(_Kk, "vends")
            local _Kn = rawget(_Kk, "vendOwner")
            for _Ko = 0, _Kk.h - 1 do
                local _Kp = _Kk.fg[_Ko]
                if _Kp then
                    for _Kq = 0, _Kk.w - 1 do
                        local _Kr = _Kp[_Kq] or 0
                        local _Ks = _Kr ~= 0 and ItemDatabase[_Kr]
                        if _Ks and _Ks.vend then
                            local _Kt, _Ku = true, true
                            if type(_Kn) == "function" then
                                _Kt, _Ku = pcall(_Kn, _Kq, _Ko)
                            end
                            if _Kt and _Ku then
                                local _Kv = nil
                                if type(_Km) == "table" and type(_Km.get) == "function" then
                                    local _Kw, _Kx = pcall(_Km.get, _Kq, _Ko)
                                    if _Kw and type(_Kx) == "table" then
                                        _Kv = _Kx
                                    end
                                end
                                _Kv = _Kv or {}
                                if not _Kv.shop then
                                    table.insert(_Kl, {
                                        x = _Kq,
                                        y = _Ko,
                                        fg = _Kr,
                                        id = _Kv.id,
                                        stock = tonumber(_Kv.stock) or 0,
                                        cap = (_Kr == 9268) and 10398 or 5199,
                                    })
                                end
                            end
                        end
                    end
                end
            end
            return _Kl
        end
        function VendingBot.Call(...)
            local _Ky = GetWorld()
            local _Kz = _Ky and rawget(_Ky, "vendCall")
            if type(_Kz) ~= "function" then
                return false
            end
            local _KA, _KB = pcall(_Kz, ...)
            return _KA and _KB == true
        end
        local function _KC(_KD, _KE)
            local function _KF()
                return VendingBot.on and VendingBot.token == _KD and IsSessionAlive()
            end
            while _KF() do
                local _KG = VendingBot.Machines()
                if #_KG == 0 then
                    VendingBot.status = "Tidak ada Vending milikmu di world ini!"
                    break
                end
                if Config.vendMode == "Kosongkan sampai habis" then
                    local _KH = false
                    for _KI, _KJ in ipairs(_KG) do
                        if not _KF() then
                            break
                        end
                        if _KJ.id and _KJ.stock > 0 and VendingBot.Allow(_KJ.id) then
                            VendingBot.status = string.format("Mengambil %s dari Vending (%d,%d)...", GetItemName(_KJ.id), _KJ.x, _KJ.y)
                            Navigation.To(_KJ.x, _KJ.y, function()
                                return not _KF()
                            end, 0.4, false)
                            local _KK = CountInventoryItem(_KJ.id)
                            VendingBot.Call("empty", _KJ.x, _KJ.y)
                            task.wait(0.45)
                            local _KL = CountInventoryItem(_KJ.id) - _KK
                            if _KL > 0 then
                                VendingBot.taken = VendingBot.taken + _KL
                                _KH = true
                            end
                            if CountInventoryItem(_KJ.id) >= 190 and SeedFactory and SeedFactory.ExternalDropSeed then
                                SeedFactory.ExternalDropSeed(_KJ.id, CountInventoryItem(_KJ.id), Config.vendPoint, Config.vendDropX, Config.vendDropY, _KE, _KJ.x, _KJ.y, _KF)
                            end
                        end
                    end
                    if not _KH then
                        VendingBot.status = "Semua Vending sudah kosong!"
                        break
                    end
                else
                    local _KM = false
                    for _KN, _KO in ipairs(_KG) do
                        if not _KF() then
                            break
                        end
                        local _KP = (_KO.id and _KO.stock > 0) and _KO.id or nil
                        if _KP and VendingBot.Allow(_KP) then
                            local _KQ = math.min(CountInventoryItem(_KP), _KO.cap - _KO.stock)
                            if _KQ > 0 then
                                VendingBot.status = string.format("Mengisi %s +%d ke Vending (%d,%d)...", GetItemName(_KP), _KQ, _KO.x, _KO.y)
                                Navigation.To(_KO.x, _KO.y, function()
                                    return not _KF()
                                end, 0.4, false)
                                if VendingBot.Call("stock", _KO.x, _KO.y, _KP, _KQ) then
                                    VendingBot.stocked = VendingBot.stocked + _KQ
                                    _KM = true
                                    task.wait(0.35)
                                end
                            end
                        end
                    end
                    if not _KM then
                        VendingBot.status = "Menunggu item di tas / drop untuk dimasukkan ke Vending..."
                        task.wait(2)
                    end
                end
                task.wait(0.5)
            end
        end
        function VendingBot.Stop()
            if not VendingBot.on then
                return false
            end
            VendingBot.token = VendingBot.token + 1
            VendingBot.on = false
            VendingBot.status = "Mati"
            return true
        end
        function VendingBot.Start()
            if VendingBot.on then
                return true
            end
            VendingBot.token = VendingBot.token + 1
            local _KR = VendingBot.token
            VendingBot.on = true
            VendingBot.status = "Mulai..."
            local _KS = GetWorldName()
            task.spawn(function()
                pcall(_KC, _KR, _KS)
                if VendingBot.token == _KR then
                    VendingBot.on = false
                    if SyncFeatureControls then
                        SyncFeatureControls()
                    end
                end
            end)
            return true
        end
    end)()
end
do
    (function()
        local function _KT(_KU)
            return (tostring(_KU or ""):gsub("`.", ""))
        end
        local function _KV(_KW)
            if not (HasRolesModule and type(RolesModule) == "table") then
                return nil
            end
            local _KX, _KY = pcall(RolesModule.isDeveloper, _KW)
            if _KX and _KY then
                return "Developer"
            end
            local _KZ, _La = pcall(RolesModule.isModerator, _KW)
            if _KZ and _La then
                return "Moderator"
            end
            return nil
        end
        local function _Lb()
            local _Lc = {}
            local _Ld = Refs.Others
            if not _Ld or type(rawget(_Ld, "list")) ~= "function" then
                return _Lc
            end
            local _Le, _Lf = pcall(_Ld.list)
            if not _Le or type(_Lf) ~= "table" then
                return _Lc
            end
            for _Lg, _Lh in ipairs(_Lf) do
                local _Li = type(_Lh) == "table" and tonumber(_Lh[1] or _Lh.userId)
                if _Li and _Li ~= ClientPlayer.UserId then
                    _Lc[#_Lc + 1] = {
                        id = _Li,
                        name = _KT(_Lh[2] or _Lh.name or _Li),
                        role = _KV(_Li)
                    }
                end
            end
            return _Lc
        end
        local function _Lj(_Lk)
            local _Ll = {}
            for _Lm, _Ln in ipairs(_Lk) do
                if _Ln.role or (Config.guardWho == "Semua pemain" and not Guard.allow[_Ln.id]) then
                    _Ll[#_Ll + 1] = _Ln
                end
            end
            return _Ll
        end
        local function _Lo(_Lp)
            local _Lq = false
            if _Lp.role and HasRolesModule and type(RolesModule.isUndercover) == "function" then
                local _Lr, _Ls = pcall(RolesModule.isUndercover, _Lp.id)
                _Lq = _Lr and _Ls == true
            end
            return _Lp.name .. " (" .. (_Lp.role or "Pemain") .. (_Lq and ", undercover" or "") .. ")"
        end
        local function _Lt(_Lu)
            local _Lv = {}
            for _Lw, _Lx in ipairs(_Lu) do
                if _Lw > 5 then
                    _Lv[#_Lv + 1] = "+" .. (#_Lu - _Lw + 1) .. " lagi"
                    break
                end
                _Lv[#_Lv + 1] = _Lo(_Lx)
            end
            return #_Lv > 0 and table.concat(_Lv, ", ") or "tidak ada"
        end
        local function _Ly()
            return (AutoFarm.on and not AutoFarm.Override) or AutoClear.on or Farmer.on or DirtFarm.on or AutoSplice.on or SeedFactory.on or AutoChat.on
        end
        local function _Lz()
            local _LA, _LB = GetCurrentTile()
            return {
                farm = AutoFarm.on and not AutoFarm.Override,
                clear = AutoClear.on,
                farmer = Farmer.on,
                df = DirtFarm.on,
                splice = AutoSplice.on,
                pabrik = SeedFactory.on,
                spam = AutoChat.on,
                world = GetWorldName(),
                tx = _LA,
                ty = _LB,
            }
        end
        local function _LC()
            if SeedFactory.on then
                SeedFactory.Stop()
            end
            if AutoSplice.on then
                AutoSplice.Stop()
            end
            if AutoFarm.on then
                StopAutoFarm()
            end
            if AutoClear.on then
                AutoClear.Stop();
                AutoClear.status = "Dijeda Penjaga"
            end
            if Farmer.on then
                Farmer.Stop();
                Farmer.status = "Dijeda Penjaga"
            end
            if DirtFarm.on then
                DirtFarm.Stop();
                DirtFarm.status = "Dijeda Penjaga"
            end
            if AutoChat.on then
                AutoChat.on = false
            end
            ReleaseMovementKeys()
            if SyncFeatureControls then
                SyncFeatureControls()
            end
        end
        local function _LD()
            local _LE = Refs.Menu
            if _LE and type(rawget(_LE, "openPicker")) == "function" and pcall(_LE.openPicker) then
                return true
            end
            local _LF = GetWorld()
            if _LF and type(rawget(_LF, "call")) == "function" then
                return pcall(_LF.call, "LeaveWorld")
            end
            return false
        end
        local function _LG(_LH)
            local _LI = GetWorld()
            if not _LI or _LH == "" then
                return false
            end
            local _LJ = rawget(_LI, "fg")
            local _LK = Refs.Menu
            if _LK and type(rawget(_LK, "enter")) == "function" then
                pcall(_LK.enter, _LH)
            elseif type(rawget(_LI, "enter")) == "function" then
                pcall(_LI.enter, _LH)
            else
                return false
            end
            local _LL = os.clock()
            while IsSessionAlive() and os.clock() - _LL < 8 do
                local _LM = GetWorld()
                if _LM and rawget(_LM, "fg") ~= _LJ then
                    return true
                end
                task.wait(0.25)
            end
            return false
        end
        local function _LN(_LO, _LP)
            if not _LO then
                return
            end
            if _LO.world ~= "" and GetWorldName() ~= _LO.world then
                return
            end
            if _LO.spam then
                AutoChat.on = true
            end
            if _LO.tx and _LO.ty then
                local _LQ, _LR = GetCurrentTile()
                if _LQ and (_LQ ~= _LO.tx or _LR ~= _LO.ty) then
                    Guard.status = string.format("Jalan balik ke (%d,%d)...", _LO.tx, _LO.ty)
                    Navigation.To(_LO.tx, _LO.ty, function()
                        return (_LP and Guard.token ~= _LP) or not IsSessionAlive()
                    end, 0.3, true)
                end
            end
            if _LP and Guard.token ~= _LP then
                return
            end
            if _LO.farm then
                StartAutoFarm()
            elseif _LO.clear then
                AutoClear.Start()
            elseif _LO.farmer then
                Farmer.Start()
            elseif _LO.df then
                DirtFarm.Start()
            elseif _LO.splice then
                AutoSplice.Start()
            elseif _LO.pabrik then
                SeedFactory.Start()
            end
            if SyncFeatureControls then
                SyncFeatureControls()
            end
        end
        Guard.Snapshot = _Lz
        Guard.StopAllBots = _LC
        Guard.LeaveWorld = _LD
        Guard.EnterWorld = _LG
        Guard.ResumeSaved = _LN
        Guard.AnyRunning = _Ly
        function Guard.AllowCurrentPlayers()
            local _LS = 0
            for _LT, _LU in ipairs(_Lb()) do
                if not _LU.role then
                    Guard.allow[_LU.id] = true
                    _LS += 1
                end
            end
            return _LS
        end
        function Guard.Set(_LV)
            Guard.on = _LV
            Guard.token += 1
            Guard.mode, Guard.saved, Guard.calmAt = "idle", nil, nil
            table.clear(Guard.alerted)
            table.clear(Guard.allow)
            if _LV then
                Guard.AllowCurrentPlayers()
                Guard.status = "Aman (Memantau)"
            else
                Guard.status = "Mati"
            end
        end
        task.spawn(function()
            while IsSessionAlive() do
                pcall(function()
                    local _LW = {}
                    for _LX, _LY in ipairs(Players:GetPlayers()) do
                        if _LY ~= ClientPlayer then
                            local _LZ = _KV(_LY.UserId)
                            if _LZ then
                                table.insert(_LW, (_LY.DisplayName or _LY.Name) .. " (" .. _LZ .. ")")
                            end
                        end
                    end
                    Guard.staffServerText = #_LW > 0 and table.concat(_LW, ", ") or "tidak ada"
                    local _Ma = (Guard.mode ~= "away" and Guard.mode ~= "out") and _Lb() or {}
                    Guard.hereText = _Lt(_Ma)
                    if not Guard.on then
                        Guard.status = "Mati"
                        return
                    end
                    local _Mb = os.clock()
                    if Guard.mode == "away" or Guard.mode == "out" then
                        local _Mc = Guard.saved and Guard.saved.world or ""
                        if Guard.mode == "out" or _Mc == "" then
                            Guard.status = "Sudah keluar world"
                            return
                        end
                        local _Md = Guard.backAt - _Mb
                        if _Md > 0 then
                            Guard.status = string.format("Di luar world. Masuk %s dlm %ds", _Mc, math.ceil(_Md))
                            return
                        end
                        Guard.status = "Masuk kembali ke " .. _Mc .. "..."
                        if _LG(_Mc) then
                            Refs.Scan()
                            task.wait(1.5)
                            local _Me = _Lj(_Lb())
                            if #_Me > 0 then
                                ShowNotification("Masih ada " .. _Lt(_Me) .. "! Keluar lagi.", "Penjaga ANCH")
                                _LD()
                                Guard.backAt = os.clock() + Config.guardBackSec
                            else
                                ShowNotification("World sudah aman, melanjutkan aktivitas!", "Penjaga ANCH")
                                Webhook.Send("penjaga", "World " .. _Mc .. " aman, lanjut aktivitas")
                                local _Mf = Guard.saved
                                Guard.mode, Guard.saved = "idle", nil
                                Guard.token += 1
                                local _Mg = Guard.token
                                task.spawn(_LN, _Mf, _Mg)
                            end
                        else
                            Guard.backAt = os.clock() + math.max(15, Config.guardBackSec)
                        end
                        return
                    end
                    local _Mh = {}
                    for _Mi, _Mj in ipairs(_Ma) do
                        _Mh[_Mj.id] = true
                    end
                    for _Mk in pairs(Guard.alerted) do
                        if not _Mh[_Mk] then
                            Guard.alerted[_Mk] = nil
                        end
                    end
                    local _Ml = _Lj(_Ma)
                    local _Mm = {}
                    for _Mn, _Mo in ipairs(_Ml) do
                        if not Guard.alerted[_Mo.id] then
                            Guard.alerted[_Mo.id] = true
                            _Mm[#_Mm + 1] = _Mo
                        end
                    end
                    if #_Mm > 0 then
                        Guard.detected += #_Mm
                        local _Mp = "Terdeteksi masuk world " .. GetWorldName() .. ": " .. _Lt(_Mm)
                        ShowNotification(_Mp, "PERINGATAN PENJAGA", 6)
                        Webhook.Send("penjaga", _Mp)
                        if Config.guardStopAll or Config.guardLeave then
                            if not Guard.saved then
                                Guard.saved = _Lz()
                            end
                            Guard.token += 1
                            _LC()
                            Guard.calmAt = nil
                            if Config.guardLeave then
                                if _LD() then
                                    Guard.backAt = os.clock() + Config.guardBackSec
                                    Guard.mode = Config.guardAutoBack and "away" or "out"
                                    Guard.status = "Keluar world"
                                    return
                                end
                            end
                            Guard.mode = "pause"
                        end
                    end
                    if #_Ml > 0 then
                        Guard.calmAt = nil
                        Guard.status = (Guard.mode == "pause" and "Dijeda! Ada: " or "Waspada! Ada: ") .. _Lt(_Ml)
                    elseif Guard.mode == "pause" then
                        Guard.calmAt = Guard.calmAt or _Mb
                        local _Mq = Config.guardCalmSec - (_Mb - Guard.calmAt)
                        if _Mq > 0 then
                            Guard.status = string.format("Sudah sepi. Lanjut dlm %ds...", math.ceil(_Mq))
                        else
                            Guard.calmAt = nil
                            local _Mr = Guard.saved
                            Guard.mode, Guard.saved = "idle", nil
                            if Config.guardAutoBack and _Mr then
                                ShowNotification("World aman, melanjutkan aktivitas!", "Penjaga ANCH")
                                Guard.token += 1
                                local _Ms = Guard.token
                                task.spawn(_LN, _Mr, _Ms)
                            end
                        end
                    else
                        Guard.status = "Aman (Memantau)"
                    end
                end)
                task.wait(0.5)
            end
        end)
        function Reconnect.TargetWorld()
            local _Mt = tostring(Config.targetWorld or ""):upper():gsub("[^A-Z0-9]", "")
            if _Mt ~= "" then
                return _Mt
            end
            return Config.lastWorld or ""
        end
        task.spawn(function()
            while IsSessionAlive() do
                local _Mu = GetWorldName()
                if _Mu ~= "" and not SeedFactory.traveling then
                    Config.lastWorld = _Mu
                end
                if _Ly() and Guard.mode == "idle" then
                    Reconnect.last = _Lz()
                    Reconnect.lastAt = os.clock()
                end
                task.wait(1)
            end
        end)
        local function _Mv(_Mw)
            if not (Config.reconnectOn and Config.reconnectWorld) or Reconnect.busy or SeedFactory.traveling then
                return
            end
            if Guard.mode == "away" or Guard.mode == "out" then
                return
            end
            local _Mx = Reconnect.last
            if not _Mx or _Mx.world == "" or os.clock() - Reconnect.lastAt > 15 then
                return
            end
            Reconnect.busy = true
            task.spawn(function()
                _LC()
                Reconnect.status = "Terlempar dari " .. _Mx.world .. ". Masuk lagi..."
                Webhook.Send("rejoin", "Terlempar dari world " .. _Mx.world .. " (" .. _KT(_Mw) .. ")")
                task.wait(Config.reconnectDelay + 1.5)
                for _My = 1, 3 do
                    if not IsSessionAlive() or not Config.reconnectOn then
                        break
                    end
                    if _LG(_Mx.world) then
                        Refs.Scan()
                        task.wait(1.5)
                        Reconnect.count += 1
                        Reconnect.status = "Berhasil masuk lagi ke " .. _Mx.world
                        Webhook.Send("rejoin", "Berhasil masuk kembali ke " .. _Mx.world)
                        _LN(_Mx, nil)
                        Reconnect.busy = false
                        return
                    end
                    Reconnect.status = string.format("Gagal masuk (%d/3), coba lagi...", _My)
                    task.wait(8)
                end
                Reconnect.busy = false
            end)
        end
        if WorldClosedRemote and WorldClosedRemote:IsA("RemoteEvent") then
            TrackConnection(WorldClosedRemote.OnClientEvent:Connect(function(_Mz)
                if IsSessionAlive() then
                    _Mv(_Mz)
                end
            end))
        end
        task.spawn(function()
            local _MA = nil
            while IsSessionAlive() do
                task.wait(2)
                local _MB = GetWorldName() == ""
                local _MC = Config.reconnectOn and Config.reconnectKeep and not Reconnect.busy and not Reconnect.leaving and not SeedFactory.traveling and Guard.mode == "idle"
                if not (_MB and _MC) then
                    _MA = nil
                else
                    _MA = _MA or os.clock()
                    local _MD = Reconnect.TargetWorld()
                    if _MD ~= "" and os.clock() - _MA >= Config.reconnectDelay then
                        _MA = nil
                        Reconnect.busy = true
                        Reconnect.status = "Di luar world, masuk ke " .. _MD .. "..."
                        if _LG(_MD) then
                            Refs.Scan()
                            task.wait(1.5)
                            Reconnect.count += 1
                            Reconnect.status = "Kembali otomatis ke " .. _MD
                            if Reconnect.last and Reconnect.last.world == _MD then
                                _LN(Reconnect.last, nil)
                            end
                        end
                        Reconnect.busy = false
                    end
                end
            end
        end)
        pcall(function()
            TrackConnection(GuiService.ErrorMessageChanged:Connect(function(_ME)
                if not IsSessionAlive() or type(_ME) ~= "string" or _ME == "" then
                    return
                end
                if not (Config.reconnectOn and Config.reconnectServer) or Reconnect.leaving then
                    return
                end
                Reconnect.leaving = true
                local _MF = Reconnect.last or (_Ly() and _Lz()) or nil
                local _MG = (_MF and _MF.world) or GetWorldName()
                if writefile and _MF then
                    _MF.at = os.time()
                    pcall(writefile, RejoinStateFile, HttpService:JSONEncode(_MF))
                end
                if QueueReloadOnTeleport then
                    pcall(QueueReloadOnTeleport)
                end
                Webhook.Send("rejoin", "Disconnect dari server (" .. _ME .. "). Rejoin otomatis...")
                task.spawn(function()
                    task.wait(Config.reconnectDelay)
                    while IsSessionAlive() do
                        pcall(function()
                            TeleportService:Teleport(game.PlaceId, ClientPlayer, (_MG ~= "") and { world = _MG } or nil)
                        end)
                        task.wait(12)
                    end
                end)
            end))
        end)
        function Reconnect.CheckStartup()
            pcall(function()
                if not (isfile and readfile and isfile(RejoinStateFile)) then
                    return
                end
                local _MH = readfile(RejoinStateFile)
                if delfile then
                    pcall(delfile, RejoinStateFile)
                end
                local _MI = HttpService:JSONDecode(_MH)
                if type(_MI) ~= "table" or type(_MI.world) ~= "string" or _MI.world == "" then
                    return
                end
                if os.time() - (tonumber(_MI.at) or 0) > 900 then
                    return
                end
                Reconnect.busy = true
                Reconnect.status = "Pulihkan sesi setelah Rejoin Server: " .. _MI.world
                local _MJ = os.clock()
                local _MK = false
                while IsSessionAlive() and os.clock() - _MJ < 50 do
                    if GetWorldName() == _MI.world and GetCurrentTile() then
                        break
                    end
                    if GetWorldName() == "" and not _MK and os.clock() - _MJ > 8 then
                        _MK = true
                        _LG(_MI.world)
                    end
                    task.wait(2)
                end
                if IsSessionAlive() and GetWorldName() == _MI.world then
                    Refs.Scan()
                    task.wait(1.5)
                    Reconnect.count += 1
                    Webhook.Send("rejoin", "Berhasil rejoin server ke world " .. _MI.world .. ", melanjutkan bot!")
                    _LN(_MI, nil)
                end
                Reconnect.busy = false
            end)
        end
    end)()
end
-- [23] BONUS / QUEST / REDEEM, STATISTIK SESI, AUTO CHAT, DAN VISUAL.
local BonusManager = {
    claimed = 0,
    redeemed = 0,
    tried = {},
    questFail = {},
    questText = "-",
    codeText = "-",
    nextQuest = 0,
    nextCode = 0,
}
local LiteMode = {
    saved = {}
}
do
    (function()
        local function _MN(_MO)
            local _MP = tostring(math.floor(tonumber(_MO) or 0))
            local _MQ = _MP:sub(1, 1) == "-"
            if _MQ then
                _MP = _MP:sub(2)
            end
            local _MR = _MP:reverse():gsub("(%d%d%d)", "%1."):reverse():gsub("^%.", "")
            return (_MQ and "-" or "") .. _MR
        end
        local function _MS(_MT)
            _MT = math.max(0, math.floor(_MT or 0))
            return string.format("%dj %dm %dd", _MT // 3600, (_MT % 3600) // 60, _MT % 60)
        end
        function SessionStats.GemsNow()
            local _MU = Refs.Gems
            local _MV = _MU and rawget(_MU, "addGems")
            if type(_MV) ~= "function" then
                return nil
            end
            for _MW, _MX in pairs(GetFunctionUpvalues(_MV)) do
                if type(_MX) == "number" then
                    return _MX
                end
            end
            return nil
        end
        function SessionStats.Reset()
            SessionStats.T0 = os.clock()
            SessionStats.Gems0 = SessionStats.GemsNow()
            SessionStats.Placed = 0
            SessionStats.Broken = 0
            SessionStats.Collected = 0
            SessionStats.Harvested = 0
            SessionStats.Planted = 0
            table.clear(SessionStats.Items)
        end
        function SessionStats.Text()
            local _MY = math.max((os.clock() - SessionStats.T0) / 3600, 1 / 3600)
            local function _MZ(_Na, _Nb)
                return string.format("%s: %s (%s/hr)", _Na, _MN(_Nb), _MN(_Nb / _MY))
            end
            local _Nc = SessionStats.GemsNow()
            if _Nc and not SessionStats.Gems0 then
                SessionStats.Gems0 = _Nc
            end
            local _Nd = "Gems: -"
            if _Nc and SessionStats.Gems0 then
                local _Ne = _Nc - SessionStats.Gems0
                _Nd = string.format("Gems: %s (%s%s, %s/hr)", _MN(_Nc), _Ne >= 0 and "+" or "", _MN(_Ne), _MN(_Ne / _MY))
            end
            local _Nf = {}
            for _Ng, _Nh in pairs(SessionStats.Items) do
                table.insert(_Nf, {
                    id = _Ng,
                    n = _Nh
                })
            end
            table.sort(_Nf, function(_Ni, _Nj)
                return _Ni.n > _Nj.n
            end)
            local _Nk = {}
            for _Nl = 1, math.min(5, #_Nf) do
                _Nk[_Nl] = GetItemName(_Nf[_Nl].id) .. " x" .. _MN(_Nf[_Nl].n)
            end
            return table.concat({
                "Session Time: " .. _MS(os.clock() - SessionStats.T0),
                _Nd,
                _MZ("Blocks Broken", SessionStats.Broken),
                _MZ("Blocks Placed", SessionStats.Placed),
                _MZ("Drops Collected", SessionStats.Collected),
                _MZ("Trees Harvested", SessionStats.Harvested),
                _MZ("Seeds Planted", SessionStats.Planted),
                "Top Collected: " .. (#_Nk > 0 and table.concat(_Nk, ", ") or "-"),
            }, "\n")
        end
        task.spawn(function()
            local _Nm = os.clock()
            while IsSessionAlive() do
                if Config.webhookReportMin > 0 and (os.clock() - _Nm) >= Config.webhookReportMin * 60 then
                    _Nm = os.clock()
                    local _Nn, _No = pcall(SessionStats.Text)
                    if _Nn then
                        Webhook.Send("report", "Laporan Statistik Sesi\n```\n" .. _No .. "\n```")
                    end
                elseif Config.webhookReportMin <= 0 then
                    _Nm = os.clock()
                end
                task.wait(2)
            end
        end)
        local function _Np()
            local _Nq = TextChatService:FindFirstChild("WorldChannels")
            if not _Nq then
                return nil
            end
            local _Nr = GetWorldName()
            if _Nr ~= "" and _Nq:FindFirstChild(_Nr) then
                return _Nq:FindFirstChild(_Nr)
            end
            for _Ns, _Nt in ipairs(_Nq:GetChildren()) do
                if _Nt:IsA("TextChannel") then
                    for _Nu, _Nv in ipairs(_Nt:GetChildren()) do
                        if _Nv:IsA("TextSource") and _Nv.UserId == ClientPlayer.UserId then
                            return _Nt
                        end
                    end
                end
            end
            return nil
        end
        function AutoChat.SendNext()
            local _Nw = TrimText(Config.chatText)
            if _Nw == "" then
                AutoChat.last = "Pesan chat belum diisi"
                return false
            end
            local _Nx = _Np()
            if not _Nx then
                AutoChat.last = "Channel chat belum ada"
                return false
            end
            local _Ny, _Nz = pcall(_Nx.SendAsync, _Nx, _Nw)
            if _Ny then
                AutoChat.sent += 1
                AutoChat.last = _Nw
            else
                AutoChat.last = "Gagal: " .. tostring(_Nz)
            end
            return _Ny
        end
        task.spawn(function()
            while IsSessionAlive() do
                if AutoChat.on and os.clock() >= AutoChat.nextAt then
                    AutoChat.SendNext()
                    AutoChat.nextAt = os.clock() + math.max(3, Config.chatInterval)
                end
                task.wait(0.3)
            end
        end)
        local function _NA(_NB)
            return (tostring(_NB or ""):gsub("`.", ""))
        end
        local function _NC(...)
            if HasNetModule and type(NetModule) == "table" and type(NetModule.call) == "function" then
                return pcall(NetModule.call, ...)
            end
            return false, "Net.call tidak tersedia"
        end
        function BonusManager.CheckQuests()
            local _ND, _NE, _NF = _NC("Quests", "list")
            if not _ND or not _NE or type(_NF) ~= "table" or type(_NF.quests) ~= "table" then
                BonusManager.questText = "Quest belum terbaca dari server"
                return
            end
            local _NG, _NH = 0, 0
            local _NI = os.clock()
            for _NJ, _NK in ipairs(_NF.quests) do
                _NG += 1
                local _NL, _NM = tonumber(_NK.have) or 0, tonumber(_NK.need) or math.huge
                if _NK.claimed then
                    _NH += 1
                elseif _NL >= _NM and not ((BonusManager.questFail[_NK.id] or 0) > _NI) then
                    local _NN, _NO, _NP, _NQ, _NR = _NC("Quests", "claim", _NK.id)
                    if _NN and _NO then
                        _NH += 1
                        BonusManager.claimed += 1
                        local _NS = _NA(_NK.text or _NK.id)
                        ShowNotification("Quest diklaim: " .. _NS, "Bonus ANCH")
                        Webhook.Send("bonus", "Quest diklaim: " .. _NS)
                        if type(_NR) == "number" and Refs.Gems and type(Refs.Gems.setGems) == "function" then
                            pcall(Refs.Gems.setGems, _NR)
                        end
                    else
                        BonusManager.questFail[_NK.id] = _NI + 120
                    end
                    task.wait(0.5)
                end
            end
            BonusManager.questText = string.format("Selesai: %d/%d | Diklaim script: %d", _NH, _NG, BonusManager.claimed)
        end
        function BonusManager.RedeemSingle(_NT)
            local _NU, _NV = _NC("ModCommand", "redeemcode", _NT)
            if not _NU then
                return nil, "Gagal menghubungi server"
            end
            local _NW = type(_NV) == "table" and type(_NV.lines) == "table" and _NV.lines or nil
            if not _NW then
                return false, "Balasan kosong"
            end
            local _NX = tostring(_NW[1] or "")
            local _NY = {}
            for _NZ, _Oa in ipairs(_NW) do
                table.insert(_NY, _NA(_Oa))
            end
            return string.sub(_NX, 1, 2) == "`2", table.concat(_NY, " ")
        end
        function BonusManager.CheckCodes()
            local _Ob, _Oc = _NC("ActiveCodes")
            if not _Ob or type(_Oc) ~= "table" then
                BonusManager.codeText = "Gagal mengambil ActiveCodes"
                return
            end
            if _Oc.note ~= nil then
                BonusManager.codeText = "Redeem ditutup: " .. _NA(_Oc.note)
                return
            end
            local _Od, _Oe = 0, 0
            for _Of, _Og in ipairs(_Oc) do
                _Od += 1
                local _Oh = _Og.code and tostring(_Og.code)
                if _Og.done then
                    _Oe += 1
                elseif _Oh and not BonusManager.tried[_Oh] and not (type(_Og.uses) == "number" and _Og.uses == 0) then
                    local _Oi, _Oj = BonusManager.RedeemSingle(_Oh)
                    if _Oi ~= nil then
                        BonusManager.tried[_Oh] = true
                    end
                    if _Oi then
                        _Oe += 1
                        BonusManager.redeemed += 1
                        ShowNotification(_Oh .. " -> " .. tostring(_Oj), "Redeem Berhasil!")
                        Webhook.Send("bonus", "Redeem berhasil " .. _Oh .. ": " .. tostring(_Oj))
                    end
                    task.wait(0.8)
                end
            end
            BonusManager.codeText = string.format("Code aktif: %d | Sudah ditukar: %d | Baru: %d", _Od, _Oe, BonusManager.redeemed)
        end
        task.spawn(function()
            while IsSessionAlive() do
                local _Ok = os.clock()
                if Config.bonusAutoQuest and _Ok >= BonusManager.nextQuest then
                    BonusManager.nextQuest = _Ok + 30
                    pcall(BonusManager.CheckQuests)
                end
                if Config.bonusAutoRedeem and _Ok >= BonusManager.nextCode then
                    BonusManager.nextCode = _Ok + 300
                    pcall(BonusManager.CheckCodes)
                end
                task.wait(1)
            end
        end)
        local _Ol = setmetatable({}, {
            __index = function()
                return 0
            end,
            __newindex = function()
            end
        })
        local _Om = setmetatable({
            l = _Ol,
            k = {}
        }, {
            __index = function()
                return 0
            end,
            __newindex = function()
            end
        })
        local _On
        _On = setmetatable({}, {
            __index = function()
                return _On
            end,
            __newindex = function()
            end,
            __call = function()
                return _On
            end,
        })
        local function _Oo(_Op, _Oq, _Or)
            if type(_Op) == "table" and type(rawget(_Op, _Oq)) == "function" then
                table.insert(LiteMode.saved, {
                    _Op,
                    _Oq,
                    rawget(_Op, _Oq)
                })
                _Op[_Oq] = _Or
            end
        end
        function LiteMode.Set(_Os)
            Config.liteMode = _Os
            if _Os then
                if #LiteMode.saved == 0 then
                    if HasParticlesModule and ParticlesModule then
                        _Oo(ParticlesModule, "spawn", function()
                            return _Om
                        end)
                    end
                    if HasSfxModule and SfxModule then
                        _Oo(SfxModule, "play", function()
                            return _On
                        end)
                        _Oo(SfxModule, "playAt", function()
                            return _On
                        end)
                    end
                end
                for _Ot, _Ou in ipairs(Refs.Particles) do
                    pcall(function()
                        for _Ov, _Ow in ipairs(_Ou.live) do
                            if typeof(_Ow.l) == "Instance" then
                                _Ow.l.Visible = false
                            end
                        end
                    end)
                end
            else
                for _Ox, _Oy in ipairs(LiteMode.saved) do
                    pcall(function()
                        _Oy[1][_Oy[2]] = _Oy[3]
                    end)
                end
                table.clear(LiteMode.saved)
            end
        end
        local _Oz = {
            t0 = os.clock(),
            tag = nil,
            panel = nil
        }
        local _OA = ColorSequence.new({
            ColorSequenceKeypoint.new(0.00, Color3.fromRGB(48, 255, 106)),
            ColorSequenceKeypoint.new(0.25, Color3.fromRGB(60, 205, 255)),
            ColorSequenceKeypoint.new(0.50, Color3.fromRGB(231, 255, 47)),
            ColorSequenceKeypoint.new(0.75, Color3.fromRGB(60, 205, 255)),
            ColorSequenceKeypoint.new(1.00, Color3.fromRGB(48, 255, 106)),
        })
        local _OB = Enum.Font.FredokaOne
        local function _OC()
            local _OD = PlayerGui:FindFirstChild("GameGui")
            local _OE = _OD and _OD:FindFirstChild("World")
            local _OF = _OE and _OE:FindFirstChild("Camera")
            local _OG = PlayerGui:FindFirstChild("ChatGui")
            local _OH = _OG and _OG:FindFirstChild("HUD")
            local _OI = _OH and _OH:FindFirstChild("PlayerPanel")
            return _OF and _OF:FindFirstChild("NameTag"), _OI and _OI:FindFirstChild("Name")
        end
        local function _OJ(_OK, _OL)
            local _OM, _ON = pcall(TextService.GetTextSize, TextService, _OK, _OL, _OB, Vector2.new(2000, 200))
            return (_OM and _ON.X or #_OK * _OL * 0.55) + 6
        end
        local function _OO(_OP, _OQ, _OR)
            local _OS = Instance.new("TextLabel")
            _OS.Name = "ANCHWatermark"
            _OS.BackgroundTransparency = 1
            _OS.Font = _OB
            _OS.TextSize = _OQ
            _OS.TextColor3 = Color3.new(1, 1, 1)
            _OS.Text = Config.watermarkText
            _OS.ZIndex = _OR and 1017 or 10
            if _OR then
                _OS.AnchorPoint = Vector2.new(0.5, 0.5)
                _OS.Position = UDim2.fromScale(0.5, 0.5)
            else
                _OS.AnchorPoint = Vector2.new(0, 0.5)
                _OS.Position = UDim2.new(0, 3, 0.5, 0)
                _OS.TextXAlignment = Enum.TextXAlignment.Left
            end
            local _OT = Instance.new("UIStroke", _OS)
            _OT.Thickness = 2
            _OT.Color = Color3.fromRGB(18, 28, 20)
            local _OU = Instance.new("UIGradient", _OS)
            _OU.Color = _OA
            _OU.Rotation = 12
            local _OV = Instance.new("UIScale", _OS)
            _OS.Parent = _OP
            return {
                holder = _OP,
                bitmap = _OP:FindFirstChild("BitmapText"),
                label = _OS,
                gr = _OU,
                sc = _OV,
                size = _OQ,
                isTag = _OR,
                text = nil,
                w = 0
            }
        end
        local function _OW(_OX)
            if not _OX then
                return
            end
            pcall(function()
                _OX.label:Destroy()
            end)
            if _OX.bitmap then
                pcall(function()
                    _OX.bitmap.Visible = true
                end)
            end
        end
        function Session.RestoreWatermark()
            _OW(_Oz.tag)
            _OW(_Oz.panel)
            _Oz.tag, _Oz.panel = nil, nil
        end
        local function _OY(_OZ, _Pa, _Pb, _Pc)
            if not _Pa then
                _OW(_OZ);
                return nil
            end
            if not _OZ or _OZ.holder ~= _Pa or not _OZ.label.Parent then
                _OW(_OZ)
                _OZ = _OO(_Pa, _Pb, _Pc)
            end
            if _OZ.text ~= Config.watermarkText then
                _OZ.text = Config.watermarkText
                _OZ.label.Text = Config.watermarkText
                _OZ.w = _OJ(Config.watermarkText, _Pb)
            end
            if _OZ.bitmap and _OZ.bitmap.Visible then
                _OZ.bitmap.Visible = false
            end
            if _Pc then
                local _Pd = math.max(_Pa.Size.Y.Offset, _Pb + 6)
                _OZ.label.Size = UDim2.fromOffset(_OZ.w, _Pd)
                _Pa.Size = UDim2.fromOffset(_OZ.w, _Pa.Size.Y.Offset)
            else
                _OZ.label.Size = UDim2.new(1, -6, 1, 0)
            end
            return _OZ
        end
        TrackConnection(RunService.RenderStepped:Connect(function()
            if not IsSessionAlive() then
                return
            end
            if not Config.customWatermark then
                if _Oz.tag or _Oz.panel then
                    Session.RestoreWatermark()
                end
                return
            end
            local _Pe, _Pf = _OC()
            _Oz.tag = _OY(_Oz.tag, _Pe, 22, true)
            _Oz.panel = _OY(_Oz.panel, _Pf, 21, false)
            local _Pg = os.clock() - _Oz.t0
            local _Ph = Vector2.new(((_Pg * 0.45) % 2) - 1, 0)
            local _Pi = 1 + 0.045 * math.sin(_Pg * 3.2)
            if _Oz.tag then
                _Oz.tag.gr.Offset = _Ph;
                _Oz.tag.sc.Scale = _Pi
            end
            if _Oz.panel then
                _Oz.panel.gr.Offset = _Ph;
                _Oz.panel.sc.Scale = _Pi
            end
        end))
    end)()
end
-- [24] HELPER KARAKTER: Blink, Longhand, Jump, Anti-AFK, God, Fast Wrench.
local SkinBlinkEnabled, LonghandEnabled, UnlimitedJumpEnabled, AntiAfkEnabled, AutoReconnectEnabled, GodModeEnabled, AutoQuestEnabled = false, false, false, false, false, false, false
local StartSkinBlink, StopSkinBlink, StartLonghand, StopLonghand, StartUnlimitedJump, StopUnlimitedJump
local StartAntiAfk, StopAntiAfk, StartAutoReconnect, StopAutoReconnect, StartGodMode, StopGodMode
local StartAutoQuest, StopAutoQuest, ShowQuestInfo, OpenNativeGrowScan, BuildWorldScanReport, SearchBlocks
local IsVisualItemEquipped, ToggleVisualItem, ResetVisualItems, GetWearableCatalog, GetOwnedRoles, PickRole
do
    (function()
        local _PO = {}
        local function _PP()
            local _PQ = {}
            local _PR = GetPlayerRigs()
            if not _PR then
                return _PQ
            end
            for _PS, _PT in ipairs({
                1,
                -1,
                0
            }) do
                local _PU = rawget(_PR, _PT)
                if type(_PU) == "table" then
                    for _PV, _PW in ipairs({
                        "body",
                        "head",
                        "eyelids",
                        "blink",
                        "forearm",
                        "fist"
                    }) do
                        local _PX = _PU[_PW]
                        if typeof(_PX) == "Instance" then
                            table.insert(_PQ, {
                                part = _PX,
                                face = false
                            })
                        end
                    end
                    for _PY, _PZ in ipairs({
                        "armBack",
                        "armFront"
                    }) do
                        local _Qa = _PU[_PZ]
                        local _Qb = (typeof(_Qa) == "Instance" and _Qa:FindFirstChild("Sprite")) or (type(_Qa) == "table" and _Qa.Sprite)
                        if typeof(_Qb) == "Instance" then
                            table.insert(_PQ, {
                                part = _Qb,
                                face = false
                            })
                        end
                    end
                    if typeof(_PU.face) == "Instance" then
                        table.insert(_PQ, {
                            part = _PU.face,
                            face = true
                        })
                    end
                end
            end
            return _PQ
        end
        function StopSkinBlink()
            if not SkinBlinkEnabled then
                return false
            end
            SkinBlinkEnabled = false
            for _Qc, _Qd in pairs(_PO) do
                pcall(function()
                    _Qc.ImageColor3 = _Qd
                end)
            end
            table.clear(_PO)
            return true
        end
        function StartSkinBlink()
            if SkinBlinkEnabled then
                return true
            end
            if not GetPlayerRigs() then
                ShowNotification("Rig karakter tidak ditemukan!");
                return false
            end
            SkinBlinkEnabled = true
            table.clear(_PO)
            for _Qe, _Qf in ipairs(_PP()) do
                _PO[_Qf.part] = _Qf.part.ImageColor3
            end
            task.spawn(function()
                while SkinBlinkEnabled and IsSessionAlive() do
                    local _Qg = Color3.fromHSV(math.random(), 0.55 + math.random() * 0.4, 1)
                    local _Qh = Color3.new(_Qg.R * 0.38, _Qg.G * 0.35, _Qg.B * 0.3)
                    for _Qi, _Qj in ipairs(_PP()) do
                        if _PO[_Qj.part] == nil then
                            _PO[_Qj.part] = _Qj.part.ImageColor3
                        end
                        pcall(function()
                            _Qj.part.ImageColor3 = _Qj.face and _Qh or _Qg
                        end)
                    end
                    local _Qk = math.min(Config.blinkMin, Config.blinkMax)
                    local _Ql = math.max(Config.blinkMin, Config.blinkMax)
                    task.wait(_Qk + math.random() * (_Ql - _Qk))
                end
            end)
            return true
        end
        local _Qm = nil
        function StartLonghand()
            local _Qn = GetInventoryHud()
            if not _Qn then
                ShowNotification("Inventory belum ditemukan!");
                return false
            end
            if not _Qm then
                _Qm = {
                    build = _Qn.buildRange,
                    punch = _Qn.punchRange
                }
            end
            local _Qo = 2.5 + Config.longhandRange
            _Qn.buildRange = function()
                return math.max(_Qm.build(), _Qo)
            end
            _Qn.punchRange = function()
                return math.max(_Qm.punch(), _Qo)
            end
            LonghandEnabled = true
            return true
        end
        function StopLonghand()
            if not LonghandEnabled then
                return false
            end
            local _Qp = GetInventoryHud()
            if _Qp and _Qm then
                _Qp.buildRange = _Qm.build
                _Qp.punchRange = _Qm.punch
            end
            LonghandEnabled = false
            return true
        end
        local _Qq = nil
        local function _Qr(_Qs, ...)
            if UnlimitedJumpEnabled and _Qs == 4992 and not MovementInput.active then
                return true
            end
            if _Qq then
                return _Qq(_Qs, ...)
            end
            return false
        end
        function StartUnlimitedJump()
            if UnlimitedJumpEnabled then
                return true
            end
            UnlimitedJumpEnabled = true
            local _Qt = GetWorld()
            if _Qt and type(rawget(_Qt, "jammerOn")) == "function" and rawget(_Qt, "jammerOn") ~= _Qr then
                _Qq = rawget(_Qt, "jammerOn")
                _Qt.jammerOn = _Qr
            end
            return true
        end
        function StopUnlimitedJump()
            if not UnlimitedJumpEnabled then
                return false
            end
            UnlimitedJumpEnabled = false
            local _Qu = GetWorld()
            if _Qu and _Qq and rawget(_Qu, "jammerOn") == _Qr then
                _Qu.jammerOn = _Qq
            end
            return true
        end
        local _Qv = nil
        local _Qw = Boot.Service("VirtualInputManager", true)
        local function _Qx()
            if getconnections then
                pcall(function()
                    for _Qy, _Qz in ipairs(getconnections(ClientPlayer.Idled)) do
                        if _Qz.Function == nil then
                            if _Qz.Disable then
                                _Qz:Disable()
                            elseif _Qz.Disconnect then
                                _Qz:Disconnect()
                            end
                        end
                    end
                end)
            end
        end
        local function _QA()
            pcall(function()
                VirtualUser:CaptureController()
                local _QB = workspace.CurrentCamera
                local _QC = _QB and _QB.CFrame or CFrame.new()
                VirtualUser:Button2Down(Vector2.new(0, 0), _QC)
                task.wait(0.08)
                VirtualUser:Button2Up(Vector2.new(0, 0), _QC)
                VirtualUser:ClickButton2(Vector2.new(0, 0))
            end)
        end
        function StartAntiAfk()
            if AntiAfkEnabled then
                return true
            end
            AntiAfkEnabled = true
            _Qx()
            _Qv = TrackConnection(ClientPlayer.Idled:Connect(function()
                if AntiAfkEnabled and IsSessionAlive() then
                    _Qx()
                    _QA()
                end
            end))
            task.spawn(function()
                while AntiAfkEnabled and IsSessionAlive() do
                    _Qx()
                    _QA()
                    task.wait(60)
                end
            end)
            return true
        end
        function StopAntiAfk()
            if not AntiAfkEnabled then
                return false
            end
            AntiAfkEnabled = false
            if _Qv then
                _Qv:Disconnect();
                _Qv = nil
            end
            return true
        end
        local _QD, _QE = nil, nil
        local _QF = nil
        TrackConnection(UserInputService.InputBegan:Connect(function(_QG)
            if not IsSessionAlive() then
                return
            end
            if _QG.UserInputType == Enum.UserInputType.MouseButton1 or _QG.UserInputType == Enum.UserInputType.Touch then
                local _QH, _QI = Navigation.ScreenToTile(_QG.Position)
                if _QH and _QI then
                    _QD, _QE = _QH, _QI
                end
            end
        end))
        local function _QJ()
            if Config.fastPull then
                return "pull", "Fast Pull"
            end
            if Config.fastKick then
                return "kick", "Fast Kick"
            end
            if Config.fastBan then
                return "ban", "Fast Ban"
            end
            return nil, nil
        end
        local function _QK(_QL)
            local _QM = _QL or _QF
            if type(_QM) == "table" then
                _QF = _QM
                local _QN = rawget(_QM, "close")
                if type(_QN) == "function" then
                    pcall(_QN)
                end
                local _QO = rawget(_QM, "box")
                if typeof(_QO) == "Instance" and _QO:IsA("GuiObject") then
                    pcall(function()
                        _QO.Visible = false
                    end)
                end
            end
            pcall(function()
                local _QP = PlayerGui:FindFirstChild("MenuGui")
                local _QQ = _QP and _QP:FindFirstChild("Player")
                if _QQ and _QQ:IsA("GuiObject") then
                    _QQ.Visible = false
                end
            end)
        end
        local function _QR(_QS)
            local _QT, _QU, _QV = nil, nil, nil
            if not (debug and debug.info and GetUpvalue) then
                return nil, nil, nil
            end
            for _QW = 2, 10 do
                local _QX, _QY = pcall(debug.info, _QW, "f")
                if not _QX or type(_QY) ~= "function" then
                    break
                end
                for _QZ = 1, 20 do
                    local _Ra, _Rb = pcall(GetUpvalue, _QY, _QZ)
                    if not _Ra then
                        break
                    end
                    if type(_Rb) == "table" then
                        if not _QV and type(rawget(_Rb, "close")) == "function" and type(rawget(_Rb, "isOpen")) == "function" and rawget(_Rb, "box") ~= nil then
                            _QV = _Rb
                            _QF = _Rb
                        end
                        local _Rc = tonumber(rawget(_Rb, "userId"))
                        local _Rd = tonumber(rawget(_Rb, "id"))
                        local _Re = rawget(_Rb, "name")
                        if _Rc and _Rc > 1000 and _Rc ~= ClientPlayer.UserId then
                            if not _QT or (_QS ~= nil and _Rd == tonumber(_QS)) then
                                _QT = _Rc
                                _QU = type(_Re) == "string" and _Re:gsub("`.", "") or tostring(_Rc)
                            end
                        end
                    end
                end
            end
            return _QT, _QU, _QV
        end
        local function _Rf(_Rg)
            local _Rh, _Ri, _Rj = _QR(_Rg)
            if _Rh then
                return _Rh, _Ri, _Rj
            end
            local _Rk = Refs.Others
            if not _Rk then
                Refs.Scan();
                _Rk = Refs.Others
            end
            local _Rl = {}
            if _Rk and type(rawget(_Rk, "list")) == "function" then
                local _Rm, _Rn = pcall(_Rk.list)
                if _Rm and type(_Rn) == "table" then
                    for _Ro, _Rp in pairs(_Rn) do
                        if type(_Rp) == "table" then
                            local _Rq = tonumber(_Rp[1] or _Rp.userId)
                            local _Rr = tostring(_Rp[2] or _Rp.name or _Rq or ""):gsub("`.", "")
                            if _Rq and _Rq ~= ClientPlayer.UserId then
                                if _Rg ~= nil and (_Ro == _Rg or _Rp.id == _Rg or _Rp.pid == _Rg) then
                                    return _Rq, _Rr, _Rj
                                end
                                table.insert(_Rl, {
                                    uid = _Rq,
                                    name = _Rr
                                })
                            end
                        end
                    end
                end
            end
            if _Rk and _QD and _QE and type(rawget(_Rk, "where")) == "function" and #_Rl > 0 then
                local _Rs, _Rt, _Ru = nil, nil, math.huge
                for _Rv, _Rw in ipairs(_Rl) do
                    local _Rx, _Ry, _Rz = pcall(_Rk.where, _Rw.uid)
                    if _Rx and type(_Ry) == "table" then
                        _Ry, _Rz = _Ry.x or _Ry[1], _Ry.y or _Ry[2]
                    end
                    if _Rx and type(_Ry) == "number" and type(_Rz) == "number" then
                        local _RA = math.abs(_Ry - _QD) + math.abs(_Rz - _QE)
                        if _RA < _Ru then
                            _Rs, _Rt, _Ru = _Rw.uid, _Rw.name, _RA
                        end
                    end
                end
                if _Rs and _Ru <= 6 then
                    return _Rs, _Rt, _Rj
                end
            end
            if #_Rl >= 1 then
                return _Rl[1].uid, _Rl[1].name, _Rj
            end
            for _RB, _RC in ipairs(Players:GetPlayers()) do
                if _RC ~= ClientPlayer then
                    return _RC.UserId, _RC.DisplayName or _RC.Name, _Rj
                end
            end
            return nil, nil, _Rj
        end
        pcall(function()
            local _RD = PlayerGui:FindFirstChild("MenuGui")
            local _RE = _RD and _RD:FindFirstChild("Player")
            if _RE and _RE:IsA("GuiObject") then
                TrackConnection(_RE:GetPropertyChangedSignal("Visible"):Connect(function()
                    if IsSessionAlive() and _RE.Visible and _QJ() then
                        if os.clock() - (Env.__ANCH_LastFastWrench or 0) < 0.8 then
                            _QK(_QF)
                        end
                    end
                end))
            end
        end)
        if not Env.__ANCH_TrueOrigNetCall and HasNetModule and type(NetModule) == "table" and type(NetModule.call) == "function" then
            local _RF = NetModule.call
            if isexecutorclosure and pcall(isexecutorclosure, _RF) and isexecutorclosure(_RF) then
                for _RG, _RH in pairs(GetFunctionUpvalues(_RF)) do
                    if type(_RH) == "function" and not (pcall(isexecutorclosure, _RH) and isexecutorclosure(_RH)) then
                        Env.__ANCH_TrueOrigNetCall = _RH
                        break
                    end
                end
            else
                Env.__ANCH_TrueOrigNetCall = _RF
            end
        end
        local _RI = Env.__ANCH_TrueOrigNetCall or (HasNetModule and type(NetModule) == "table" and NetModule.call) or nil
        local _RJ = {}
        local _RK = 0
        local _RL
        local function _RM(_RN, _RO, _RP, _RQ, _RR, _RS)
            _RK = os.clock()
            Env.__ANCH_LastFastWrench = _RK
            _QK(_RS)
            task.defer(function()
                _QK(_RS)
            end)
            task.spawn(function()
                pcall(_RN, "WorldCommand", _RO, "#" .. tostring(_RQ))
                pcall(_RN, "SetBusy", 0)
                task.wait(0.04)
                _QK(_RS)
                ShowNotification(string.format("%s -> %s (#%s)", _RP, tostring(_RR or "Player"), tostring(_RQ)), _RP, 2)
            end)
        end
        local function _RT(_RU, _RV, _RW, ...)
            local _RX, _RY = _QJ()
            if _RX then
                if _RV == "GetPlayerLevel" or _RV == "WrenchPlayer" or _RV == "PlayerInfo" then
                    local _RZ, _Sa, _Sb = _Rf(_RW)
                    if _RZ then
                        if os.clock() - _RK > 0.15 then
                            _RM(_RU, _RX, _RY, _RZ, _Sa, _Sb)
                        else
                            _QK(_Sb)
                        end
                        return nil
                    end
                elseif _RV == "SetBusy" and _RW == 2 then
                    if os.clock() - _RK < 1.0 then
                        _QK(_QF)
                        return false
                    end
                end
            end
            return _RU(_RV, _RW, ...)
        end
        if _RI then
            _RL = function(_Sc, _Sd, ...)
                if not IsSessionAlive() then
                    return _RI(_Sc, _Sd, ...)
                end
                return _RT(_RI, _Sc, _Sd, ...)
            end
            Boot.Assign(NetModule, "call", _RL)
            if Refs.World and type(rawget(Refs.World, "call")) == "function" then
                rawset(Refs.World, "call", _RL)
            end
            if GetGC and GetUpvalue and SetUpvalue then
                task.spawn(function()
                    for _Se, _Sf in ipairs(GetGC(false)) do
                        if type(_Sf) == "function" and _Sf ~= _RL and _Sf ~= _RT then
                            if not (isexecutorclosure and pcall(isexecutorclosure, _Sf) and isexecutorclosure(_Sf)) then
                                for _Sg = 1, 30 do
                                    local _Sh, _Si = pcall(GetUpvalue, _Sf, _Sg)
                                    if not _Sh then
                                        break
                                    end
                                    if type(_Si) == "function" then
                                        local _Sj = false
                                        if isexecutorclosure and pcall(isexecutorclosure, _Si) and isexecutorclosure(_Si) then
                                            for _Sk, _Sl in pairs(GetFunctionUpvalues(_Si)) do
                                                if _Sl == _RI then
                                                    _Sj = true
                                                    break
                                                end
                                            end
                                        end
                                        if _Si == _RI or _Sj then
                                            pcall(SetUpvalue, _Sf, _Sg, _RL)
                                            table.insert(_RJ, {
                                                fn = _Sf,
                                                idx = _Sg,
                                                orig = _RI
                                            })
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
            end
        end
        function Session.RestoreFastWrench()
            if _RI and HasNetModule and type(NetModule) == "table" then
                Boot.Assign(NetModule, "call", _RI)
            end
            if _RI and Refs.World and rawget(Refs.World, "call") == _RL then
                pcall(rawset, Refs.World, "call", _RI)
            end
            if SetUpvalue then
                for _Sm, _Sn in ipairs(_RJ) do
                    pcall(SetUpvalue, _Sn.fn, _Sn.idx, _Sn.orig)
                end
            end
            table.clear(_RJ)
        end
        local _So = nil
        local _Sp = nil
        local _Sq = {}
        local function _Sr()
            pcall(function()
                local _Ss = PlayerGui:FindFirstChild("InventoryGui")
                local _St = _Ss and _Ss:FindFirstChild("InfoDialog")
                if _St and _St:IsA("GuiObject") then
                    _St.Visible = false
                end
            end)
        end
        local function _Su()
            local _Sv = _So or Refs.Inv
            if _Sv then
                local _Sw = rawget(_Sv, "selected")
                if type(_Sw) == "number" and _Sw > 0 then
                    if CountInventoryItem(_Sw) > 0 then
                        return _Sw
                    end
                    local _Sx = rawget(_Sv, "slots")
                    if type(_Sx) == "table" and type(_Sx[_Sw]) == "table" and tonumber(_Sx[_Sw].id) then
                        return tonumber(_Sx[_Sw].id)
                    end
                    if ItemDatabase[_Sw] then
                        return _Sw
                    end
                end
            end
            if type(_Sp) == "table" then
                for _Sy, _Sz in pairs(_Sp) do
                    if type(_Sz) == "table" and typeof(_Sz.sel) == "Instance" and _Sz.sel.Visible and tonumber(_Sz.id) then
                        return tonumber(_Sz.id)
                    end
                end
            end
            return nil
        end
        local function _SA()
            _Sr()
            local _SB = _Su()
            if not _SB then
                ShowNotification("Pilih item di Backpack terlebih dahulu!", "Fast Drop", 2)
                return
            end
            local _SC = CountInventoryItem(_SB)
            if _SC <= 0 then
                ShowNotification("Item sudah habis di tas!", "Fast Drop", 2)
                return
            end
            local _SD = math.floor(tonumber(Config.fastDropCount) or 0)
            local _SE = (_SD <= 0) and _SC or math.min(_SD, _SC)
            task.spawn(function()
                local _SF = Refs.Hud or GetInventoryHud()
                local _SG = _SF and rawget(_SF, "onDrop")
                if type(_SG) == "function" then
                    pcall(_SG, _SB, _SE)
                elseif DropItemRemote then
                    pcall(function()
                        DropItemRemote:FireServer(_SB, _SE)
                    end)
                elseif HasNetModule and type(NetModule) == "table" and NetModule.drop then
                    pcall(NetModule.drop.send, {
                        id = _SB,
                        n = _SE
                    })
                end
                _Sr()
                ShowNotification(string.format("Fast Drop: %s x%d", GetItemName(_SB), _SE), "Fast Drop", 2)
            end)
        end
        local function _SH()
            _Sr()
            local _SI = _Su()
            if not _SI then
                ShowNotification("Pilih item di Backpack terlebih dahulu!", "Fast Recycle", 2)
                return
            end
            local _SJ = CountInventoryItem(_SI)
            if _SJ <= 0 then
                ShowNotification("Item sudah habis di tas!", "Fast Recycle", 2)
                return
            end
            local _SK = math.floor(tonumber(Config.fastRecycleCount) or 0)
            local _SL = (_SK <= 0) and _SJ or math.min(_SK, _SJ)
            task.spawn(function()
                if BackpackManager and type(BackpackManager.Recycle) == "function" then
                    local _SM = BackpackManager.Recycle(_SI, _SL)
                    _Sr()
                    if _SM then
                        local _SN = GetInventoryHud()
                        if _SN and type(rawget(_SN, "refresh")) == "function" then
                            pcall(_SN.refresh)
                        end
                        ShowNotification(string.format("Fast Recycle: %s x%d", GetItemName(_SI), _SL), "Fast Recycle", 2)
                    else
                        ShowNotification(GetItemName(_SI) .. " tidak bisa di-recycle!", "Fast Recycle", 2)
                    end
                end
            end)
        end
        local _SO = nil
        local _SP = nil
        local _SQ = nil
        local _SR = 0
        local function _SS()
            local _ST = PlayerGui:FindFirstChild("InventoryGui")
            local _SU = _ST and _ST:FindFirstChild("Holder")
            local _SV = _SU and _SU:FindFirstChild("Backpack")
            local _SW = _SV and _SV:FindFirstChild("Actions")
            if not _SW or not getconnections or not GetUpvalue or not SetUpvalue then
                return
            end
            for _SX, _SY in ipairs(_SW:GetChildren()) do
                if _SY:IsA("GuiButton") then
                    for _SZ, _Ta in ipairs({
                        _SY.Activated,
                        _SY.MouseButton1Click
                    }) do
                        local _Tb, _Tc = pcall(getconnections, _Ta)
                        if _Tb and type(_Tc) == "table" then
                            for _Td, _Te in ipairs(_Tc) do
                                local _Tf = _Te.Function
                                if type(_Tf) == "function" and not (isexecutorclosure and pcall(isexecutorclosure, _Tf) and isexecutorclosure(_Tf)) then
                                    local _Tg, _Th = pcall(GetUpvalue, _Tf, 1)
                                    local _Ti, _Tj = pcall(GetUpvalue, _Tf, 2)
                                    local _Tk, _Tl = pcall(GetUpvalue, _Tf, 3)
                                    local _Tm, _Tn = pcall(GetUpvalue, _Tf, 5)
                                    if _Ti and type(_Tj) == "table" and rawget(_Tj, "drop") and rawget(_Tj, "recycle") and _Tm and type(_Tn) == "function" then
                                        _So = (_Tg and type(_Th) == "table") and _Th or _So
                                        _Sp = (_Tk and type(_Tl) == "table") and _Tl or _Sp
                                        local _To = rawget(_Tj, "drop")
                                        local _Tp = rawget(_Tj, "recycle")
                                        if _SY == _To then
                                            _SO = _Tf
                                            if not _To:GetAttribute("ANCHDropHook") then
                                                _To:SetAttribute("ANCHDropHook", true)
                                                TrackConnection(_To.InputBegan:Connect(function(_Tq)
                                                    if _Tq.UserInputType == Enum.UserInputType.MouseButton1 or _Tq.UserInputType == Enum.UserInputType.Touch then
                                                        _SQ = "drop"
                                                        _SR = os.clock()
                                                    end
                                                end))
                                            end
                                        elseif _SY == _Tp then
                                            _SP = _Tf
                                            if not _Tp:GetAttribute("ANCHRecHook") then
                                                _Tp:SetAttribute("ANCHRecHook", true)
                                                TrackConnection(_Tp.InputBegan:Connect(function(_Tr)
                                                    if _Tr.UserInputType == Enum.UserInputType.MouseButton1 or _Tr.UserInputType == Enum.UserInputType.Touch then
                                                        _SQ = "recycle"
                                                        _SR = os.clock()
                                                    end
                                                end))
                                            end
                                        end
                                        if not Env.__ANCH_TrueOrigOpenDialog then
                                            if isexecutorclosure and pcall(isexecutorclosure, _Tn) and isexecutorclosure(_Tn) then
                                                for _Ts, _Tt in pairs(GetFunctionUpvalues(_Tn)) do
                                                    if type(_Tt) == "function" and not (pcall(isexecutorclosure, _Tt) and isexecutorclosure(_Tt)) then
                                                        Env.__ANCH_TrueOrigOpenDialog = _Tt
                                                        break
                                                    end
                                                end
                                            else
                                                Env.__ANCH_TrueOrigOpenDialog = _Tn
                                            end
                                        end
                                        local _Tu = Env.__ANCH_TrueOrigOpenDialog
                                        if _Tu and _Tn ~= Session.SharedDialogWrapper then
                                            Session.SharedDialogWrapper = function(...)
                                                if IsSessionAlive() then
                                                    local _Tv = (debug and debug.info and debug.info(2, "f")) or nil
                                                    local _Tw = (_Tv and _SO and _Tv == _SO) or (_SQ == "drop" and (os.clock() - _SR) < 0.5)
                                                    local _Tx = (_Tv and _SP and _Tv == _SP) or (_SQ == "recycle" and (os.clock() - _SR) < 0.5)
                                                    if _Tw and not _Tx then
                                                        _SQ = nil
                                                        if Config.fastDrop then
                                                            _SA()
                                                            return
                                                        end
                                                    elseif _Tx and not _Tw then
                                                        _SQ = nil
                                                        if Config.fastRecycle then
                                                            _SH()
                                                            return
                                                        end
                                                    end
                                                end
                                                return _Tu(...)
                                            end
                                            pcall(SetUpvalue, _Tf, 5, Session.SharedDialogWrapper)
                                            table.insert(_Sq, {
                                                fn = _Tf,
                                                idx = 5,
                                                orig = _Tu
                                            })
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        task.spawn(function()
            while IsSessionAlive() do
                pcall(_SS)
                task.wait(1.5)
            end
        end)
        function Session.RestoreFastBackpack()
            if SetUpvalue then
                for _Ty, _Tz in ipairs(_Sq) do
                    pcall(SetUpvalue, _Tz.fn, _Tz.idx, _Tz.orig)
                end
            end
            table.clear(_Sq)
        end
        function StartAutoReconnect()
            AutoReconnectEnabled = true
            Config.reconnectOn = true
            SaveConfig()
            return true
        end
        function StopAutoReconnect()
            AutoReconnectEnabled = false
            Config.reconnectOn = false
            SaveConfig()
            return true
        end
        local _TA, _TB = {}, {}
        function StartGodMode()
            if GodModeEnabled then
                return true
            end
            _TA = {}
            for _TC, _TD in pairs(ItemDatabase) do
                if type(_TD) == "table" then
                    for _TE, _TF in ipairs({
                        "hurts",
                        "deadly"
                    }) do
                        if _TD[_TF] then
                            table.insert(_TA, {
                                item = _TD,
                                key = _TF,
                                value = rawget(_TD, _TF)
                            })
                            pcall(function()
                                if setreadonly then
                                    setreadonly(_TD, false)
                                end
                                rawset(_TD, _TF, false)
                            end)
                        end
                    end
                end
            end
            local _TG = WorldRemotes and WorldRemotes:FindFirstChild("Burned")
            if _TG and getconnections then
                local _TH, _TI = pcall(getconnections, _TG.OnClientEvent)
                if _TH and type(_TI) == "table" then
                    for _TJ, _TK in ipairs(_TI) do
                        if pcall(function()
                            _TK:Disable()
                        end) then
                            table.insert(_TB, _TK)
                        end
                    end
                end
            end
            GodModeEnabled = true
            return true
        end
        function StopGodMode()
            if not GodModeEnabled then
                return false
            end
            for _TL, _TM in ipairs(_TA) do
                pcall(function()
                    rawset(_TM.item, _TM.key, _TM.value)
                end)
            end
            _TA = {}
            for _TN, _TO in ipairs(_TB) do
                pcall(function()
                    _TO:Enable()
                end)
            end
            _TB = {}
            GodModeEnabled = false
            return true
        end
        local _TP = {}
        local _TQ = nil
        local function _TR()
            local _TS = GetInventoryHud()
            if not _TS then
                return nil
            end
            local _TT = GetFunctionUpvalues(_TS.isWorn)[1]
            return type(_TT) == "table" and _TT or nil
        end
        function IsVisualItemEquipped(_TU)
            local _TV = _TR()
            return _TV and ItemDatabase[_TU] and _TV[ItemDatabase[_TU].slot] == _TU or false
        end
        function ToggleVisualItem(_TW)
            local _TX, _TY = GetInventoryHud(), _TR()
            if not _TX or not _TY or not ItemDatabase[_TW] then
                return false
            end
            local _TZ = ItemDatabase[_TW].slot
            if type(_TZ) ~= "string" then
                return false
            end
            if _TY[_TZ] == _TW then
                _TY[_TZ] = _TP[_TZ] or nil
            else
                if _TP[_TZ] == nil then
                    _TP[_TZ] = _TY[_TZ] or false
                end
                _TY[_TZ] = _TW
            end
            pcall(_TX.refresh)
            return true
        end
        function ResetVisualItems()
            local _Ua, _Ub = GetInventoryHud(), _TR()
            if not _Ua or not _Ub then
                return
            end
            for _Uc, _Ud in pairs(_TP) do
                _Ub[_Uc] = _Ud or nil
            end
            table.clear(_TP)
            pcall(_Ua.refresh)
            ShowNotification("Item visual dikembalikan.")
        end
        function GetWearableCatalog()
            if _TQ then
                return _TQ
            end
            local _Ue = {}
            for _Uf, _Ug in pairs(ItemDatabase) do
                if type(_Uf) == "number" and type(_Ug) == "table" and type(_Ug.slot) == "string" and type(_Ug.name) == "string" then
                    local _Uh = {}
                    local _Ui = _Ug.name:lower()
                    if _Ug.kuyang then
                        table.insert(_Uh, "Kuyang")
                    end
                    if _Ug.bot then
                        table.insert(_Uh, "LegendBot")
                    end
                    if _Uf == 5480 or _Ui:find("rayman", 1, true) then
                        table.insert(_Uh, "Rayman")
                    end
                    table.insert(_Ue, {
                        id = _Uf,
                        name = _Ug.name,
                        lower = _Ui,
                        slot = _Ug.slot,
                        tags = _Uh
                    })
                end
            end
            table.sort(_Ue, function(_Uj, _Uk)
                return _Uj.name < _Uk.name
            end)
            _TQ = _Ue
            return _Ue
        end
        local _Ul = nil
        local function _Um()
            if _Ul then
                return _Ul
            end
            local _Un = {}
            for _Uo, _Up in pairs(ItemDatabase) do
                if type(_Uo) == "number" and type(_Up) == "table" and type(_Up.name) == "string" and type(_Up.slot) ~= "string" then
                    table.insert(_Un, {
                        id = _Uo,
                        name = _Up.name,
                        lower = _Up.name:lower(),
                        kind = _Up.kind or "block"
                    })
                end
            end
            table.sort(_Un, function(_Uq, _Ur)
                return _Uq.name < _Ur.name
            end)
            _Ul = _Un
            return _Un
        end
        function SearchBlocks(_Us, _Ut)
            local _Uu = _Um()
            _Us = TrimText(_Us):lower()
            if _Us == "" then
                return {}
            end
            local _Uv = tonumber(_Us)
            local _Uw = {}
            for _Ux, _Uy in ipairs(_Uu) do
                local _Uz = nil
                if _Uv and _Uy.id == _Uv then
                    _Uz = 0
                elseif _Uy.lower == _Us then
                    _Uz = 1
                elseif _Uy.lower:sub(1, #_Us) == _Us then
                    _Uz = 2
                elseif _Uy.lower:find(_Us, 1, true) then
                    _Uz = 3
                end
                if _Uz then
                    table.insert(_Uw, {
                        entry = _Uy,
                        rank = _Uz
                    })
                end
            end
            table.sort(_Uw, function(_UA, _UB)
                if _UA.rank ~= _UB.rank then
                    return _UA.rank < _UB.rank
                end
                return _UA.entry.name < _UB.entry.name
            end)
            local _UC = {}
            for _UD = 1, math.min(_Ut or 25, #_Uw) do
                _UC[_UD] = _Uw[_UD].entry
            end
            return _UC
        end
        function OpenNativeGrowScan()
            local _UE = GetWorld()
            local _UF = _UE and rawget(_UE, "growScan")
            if type(_UF) ~= "table" or type(_UF.open) ~= "function" then
                return false
            end
            local _UG = 0
            for _UH, _UI in pairs(ItemDatabase) do
                if type(_UH) == "number" and type(_UI) == "table" and _UI.growscan then
                    _UG = _UH;
                    break
                end
            end
            local _UJ = pcall(_UF.open, {
                item = _UG,
                owner = true,
                blocksPublic = false,
                floatingPublic = false
            }, function()
            end)
            return _UJ
        end
        function BuildWorldScanReport()
            local _UK = GetWorld()
            if not _UK or type(rawget(_UK, "w")) ~= "number" then
                return nil
            end
            local _UL = {
                fg = {},
                bg = {},
                drops = {},
                trees = {},
                w = _UK.w,
                h = _UK.h,
                totalFg = 0,
                totalBg = 0,
                totalDrops = 0,
                piles = 0,
                readyTrees = 0,
                growingTrees = 0,
            }
            local _UM = workspace:GetServerTimeNow()
            for _UN = 0, _UK.h - 1 do
                local _UO, _UP = _UK.fg[_UN], _UK.bg and _UK.bg[_UN]
                for _UQ = 0, _UK.w - 1 do
                    local _UR = _UO and _UO[_UQ] or 0
                    if _UR ~= 0 then
                        _UL.fg[_UR] = (_UL.fg[_UR] or 0) + 1
                        _UL.totalFg += 1
                        if IsTreeItem(_UR) then
                            local _US = GetTreeReadyAt(_UK, _UQ, _UN, _UR)
                            local _UT = _UL.trees[_UR]
                            if not _UT then
                                _UT = {
                                    ready = 0,
                                    growing = 0,
                                    nextIn = nil
                                }
                                _UL.trees[_UR] = _UT
                            end
                            if _US and _UM >= _US then
                                _UT.ready += 1
                                _UL.readyTrees += 1
                            else
                                _UT.growing += 1
                                _UL.growingTrees += 1
                                if _US then
                                    local _UU = _US - _UM
                                    if not _UT.nextIn or _UU < _UT.nextIn then
                                        _UT.nextIn = _UU
                                    end
                                end
                            end
                        end
                    end
                    local _UV = _UP and _UP[_UQ] or 0
                    if _UV ~= 0 then
                        _UL.bg[_UV] = (_UL.bg[_UV] or 0) + 1;
                        _UL.totalBg += 1
                    end
                end
            end
            local _UW = Drops.list
            if not _UW and type(_UK.dropList) == "function" then
                local _UX, _UY = pcall(_UK.dropList)
                if _UX then
                    _UW = _UY
                end
            end
            if type(_UW) == "table" then
                for _UZ, _Va in pairs(_UW) do
                    if type(_Va) == "table" and type(_Va.id) == "number" and (_Va.n or 0) > 0 then
                        _UL.drops[_Va.id] = (_UL.drops[_Va.id] or 0) + (_Va.n or 1)
                        _UL.totalDrops += (_Va.n or 1)
                        _UL.piles += 1
                    end
                end
            end
            return _UL
        end
        function GetOwnedRoles()
            local _Vb, _Vc = { "none" }, { none = true }
            if HasRolesModule and type(RolesModule) == "table" and type(RolesModule.titlesOf) == "function" then
                local _Vd, _Ve = pcall(RolesModule.titlesOf, ClientPlayer.UserId)
                if _Vd and type(_Ve) == "table" then
                    for _Vf, _Vg in ipairs(_Ve) do
                        if type(_Vg) == "string" and not _Vc[_Vg] then
                            _Vc[_Vg] = true
                            local _Vh = _Vg
                            if type(RolesModule.titleName) == "function" then
                                local _Vi, _Vj = pcall(RolesModule.titleName, _Vg)
                                if _Vi and type(_Vj) == "string" and _Vj ~= "" and _Vj ~= _Vg then
                                    _Vh = _Vj .. " [" .. _Vg .. "]"
                                end
                            end
                            table.insert(_Vb, _Vh)
                        end
                    end
                end
            end
            return _Vb
        end
        function PickRole(_Vk)
            local _Vl = string.match(_Vk or "", "%[(.-)%]$") or _Vk or "none"
            if _Vl == "" then
                _Vl = "none"
            end
            if HasNetModule and type(NetModule) == "table" and type(NetModule.call) == "function" then
                task.spawn(function()
                    local _Vm, _Vn = pcall(NetModule.call, "PickTitle", _Vl)
                    ShowNotification(_Vm and ("Role dipasang: " .. _Vl) or ("Gagal pasang role: " .. tostring(_Vn)))
                end)
            elseif PickTitleRemote then
                pcall(function()
                    PickTitleRemote:FireServer(_Vl)
                end)
                ShowNotification("Role dikirim: " .. _Vl)
            else
                ShowNotification("Fungsi PickTitle tidak ditemukan.")
            end
        end
        function ShowQuestInfo()
            BonusManager.CheckQuests()
            ShowNotification(BonusManager.questText, "Info Quest")
        end
        function StartAutoQuest()
            if AutoQuestEnabled then
                return true
            end
            AutoQuestEnabled = true
            Config.bonusAutoQuest = true
            BonusManager.nextQuest = 0
            return true
        end
        function StopAutoQuest()
            if not AutoQuestEnabled then
                return false
            end
            AutoQuestEnabled = false
            Config.bonusAutoQuest = false
            return true
        end
    end)()
end
-- [25] REGISTRY FITUR: menghubungkan tombol/toggle dengan fungsi Start/Stop.
Session.IsGodModeEnabled = function() return GodModeEnabled end
Session.StartGodMode = function() return StartGodMode() end
Session.StopGodMode = function() return StopGodMode() end
local FeatureRegistry = {
    blink = {
        label = "Skin Blink",
        get = function()
            return SkinBlinkEnabled
        end,
        set = function(_Vo)
            return _Vo and StartSkinBlink() or StopSkinBlink()
        end
    },
    longhand = {
        label = "Longhand Reach",
        get = function()
            return LonghandEnabled
        end,
        set = function(_Vp)
            return _Vp and StartLonghand() or StopLonghand()
        end
    },
    noclip = {
        label = "Noclip / ModFly",
        get = function()
            return ManualNoclipEnabled
        end,
        set = function(_Vq)
            return _Vq and EnableManualNoclip() or DisableManualNoclip()
        end
    },
    ujump = {
        label = "Unlimited Jump",
        get = function()
            return UnlimitedJumpEnabled
        end,
        set = function(_Vr)
            return _Vr and StartUnlimitedJump() or StopUnlimitedJump()
        end
    },
    antiafk = {
        label = "Anti-AFK",
        get = function()
            return AntiAfkEnabled
        end,
        set = function(_Vs)
            return _Vs and StartAntiAfk() or StopAntiAfk()
        end
    },
    autorejoin = {
        label = "Auto Reconnect",
        get = function()
            return Config.reconnectOn
        end,
        set = function(_Vt)
            return _Vt and StartAutoReconnect() or StopAutoReconnect()
        end
    },
    god = {
        label = "God Mode",
        get = function()
            return GodModeEnabled
        end,
        set = function(_Vu)
            return _Vu and StartGodMode() or StopGodMode()
        end
    },
    clicktp = {
        label = "Click TP",
        get = function()
            return Navigation.clickOn
        end,
        set = function(_Vv)
            return _Vv and Navigation.StartClick() or Navigation.StopClick()
        end
    },
    lite = {
        label = "Lite Mode (FPS Boost)",
        get = function()
            return Config.liteMode
        end,
        set = function(_Vw)
            LiteMode.Set(_Vw);
            return true
        end
    },
    guard = {
        label = "Anti-Mod Guard",
        get = function()
            return Guard.on
        end,
        set = function(_Vx)
            Guard.Set(_Vx);
            return true
        end
    },
    autochat = {
        label = "Auto Chat",
        noSession = true,
        get = function()
            return AutoChat.on
        end,
        set = function(_Vy)
            AutoChat.on = _Vy;
            if _Vy then
                AutoChat.nextAt = 0
            end;
            return true
        end
    },
    autoclear = {
        label = "Auto Clear World",
        noSession = true,
        get = function()
            return AutoClear.on
        end,
        set = function(_Vz)
            return _Vz and AutoClear.Start() or AutoClear.Stop()
        end
    },
    autoharvest = {
        label = "Farmer (Harvest/Plant)",
        noSession = true,
        get = function()
            return Farmer.on
        end,
        set = function(_VA)
            return _VA and Farmer.Start() or Farmer.Stop()
        end
    },
    automove = {
        label = "Auto Move Item",
        noSession = true,
        get = function()
            return AutoMove.on
        end,
        set = function(_VB)
            return _VB and AutoMove.Start() or AutoMove.Stop()
        end
    },
    autodf = {
        label = "Auto Dirt Farm",
        noSession = true,
        get = function()
            return DirtFarm.on
        end,
        set = function(_VC)
            return _VC and DirtFarm.Start() or DirtFarm.Stop()
        end
    },
    autosplice = {
        label = "Auto Splice",
        noSession = true,
        get = function()
            return AutoSplice.on
        end,
        set = function(_VD)
            return _VD and AutoSplice.Start() or AutoSplice.Stop()
        end
    },
    pabrik = {
        label = "Seed Factory",
        noSession = true,
        get = function()
            return SeedFactory.on
        end,
        set = function(_VE)
            return _VE and SeedFactory.Start() or SeedFactory.Stop()
        end
    },
    autofarm = {
        label = "Auto Farm",
        noSession = true,
        get = function()
            return AutoFarm.on and not AutoFarm.Override
        end,
        set = function(_VF)
            return _VF and StartAutoFarm() or StopAutoFarm()
        end
    },
    autoquest = {
        label = "Auto Quest",
        get = function()
            return AutoQuestEnabled
        end,
        set = function(_VG)
            return _VG and StartAutoQuest() or StopAutoQuest()
        end
    },
}
local function SetFeatureEnabled(_VJ, _VK)
    local _VL = FeatureRegistry[_VJ]
    if not _VL then
        return
    end
    _VL.set(_VK)
    if _VL.get() == _VK then
        ShowNotification(_VL.label .. (_VK and " enabled." or " disabled."))
        if not _VL.noSession then
            Config.session[_VJ] = _VK or nil
        end
        SaveConfig()
    end
    if SyncFeatureControls then
        SyncFeatureControls()
    end
end
local _VM = 0
-- [26] AUTO RELOAD PADA TELEPORT DAN PEMBUATAN LOADER AUTOEXEC.
local function GetReloadCode()
    if Config.scriptUrl == Boot.SourceUrl then
        return string.format("loadstring(game:HttpGet(%q))()", Boot.SourceUrl)
    end
    if type(Env.ANCHHub_ReloadCode) == "string" and Env.ANCHHub_ReloadCode ~= "" then
        return Env.ANCHHub_ReloadCode
    end
    local _VO = Config.scriptUrl
    if type(_VO) ~= "string" or _VO == "" then
        _VO = Env.ANCHHubURL
    end
    if type(_VO) == "string" and _VO ~= "" then
        return string.format("loadstring(game:HttpGet(%q))()", _VO)
    end
    if isfile and readfile then
        for _VP, _VQ in ipairs({
            MainScriptFile,
            "ANCHHub-Test.lua",
            "ANCHHub.lua",
            "ANCHHub_Loader.lua"
        }) do
            local _VR, _VS = pcall(isfile, _VQ)
            if _VR and _VS then
                return string.format("loadstring(readfile(%q))()", _VQ)
            end
        end
    end
    return nil
end
local function GetTeleportQueueFunction()
    return queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport) or (getgenv and getgenv().queue_on_teleport)
end
QueueReloadOnTeleport = function()
    if not Config.autoReload or Env.__ANCHHub_TeleportQueued then
        return false
    end
    local _VU, _VV = GetTeleportQueueFunction(), GetReloadCode()
    if not _VU or not _VV then
        return false
    end
    local _VW = ("local g=(getgenv and getgenv()) or _G; if g.__ANCH_TpLock and (o" .. "s.clock()-g.__ANCH_TpLock)<6 then return end; g.__ANCH_TpLock=os" .. ".clock(); ") .. _VV
    local _VX = pcall(_VU, _VW)
    if _VX then
        Env.__ANCHHub_TeleportQueued = true
    end
    return _VX
end
local function InstallAutoexecLoader()
    if not writefile then
        ShowNotification("Executor tidak punya writefile.");
        return
    end
    local _VZ = GetReloadCode()
    if not _VZ then
        ShowNotification("Simpan skrip sebagai " .. MainScriptFile .. " di workspace atau isi URL dulu.");
        return
    end
    local _Wa = "-- ANCH HUB | GrowBlox auto-loader\n" .. _VZ .. "\n"
    pcall(writefile, "ANCHHub_Loader.lua", _Wa)
    for _Wb, _Wc in ipairs({
        "../autoexec/ANCHHub_Loader.lua",
        "../Autoexec/ANCHHub_Loader.lua"
    }) do
        local _Wd = pcall(writefile, _Wc, _Wa)
        local _We, _Wf = pcall(function()
            return isfile and isfile(_Wc)
        end)
        if _Wd and _We and _Wf then
            ShowNotification("Auto-execute berhasil dipasang!")
            return
        end
    end
    ShowNotification(("Salin ANCHHub_Loader.lua dari workspace ke folder autoexec execu" .. "tor."))
end
do
    (function()
        local _Wg = Boot.GuiParent
        local function _Wh(_Wi)
            local _Wj = Instance.new("ScreenGui")
            _Wj.Name = _Wi
            _Wj.ResetOnSpawn = false
            _Wj.IgnoreGuiInset = true
            _Wj.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            _Wj.DisplayOrder = 999
            _Wj.Enabled = false
            _Wj.Parent = _Wg
            return _Wj
        end
        FloatingGridGui = _Wh("ANCHGridGui")
        local _Wk, _Wl, _Wm = 38, 4, 2
        local _Wn = _Wm * 2 + 1
        local _Wo = _Wn * _Wk + (_Wn - 1) * _Wl
        local _Wp = Instance.new("Frame", FloatingGridGui)
        _Wp.Size = UDim2.fromOffset(_Wo + 20, _Wo + 96)
        _Wp.Position = UDim2.fromOffset(24, 90)
        _Wp.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
        _Wp.BorderSizePixel = 0
        Instance.new("UICorner", _Wp).CornerRadius = UDim.new(0, 10)
        local _Wq = Instance.new("UIStroke", _Wp)
        _Wq.Color = Color3.fromRGB(48, 255, 106)
        local _Wr = Instance.new("TextLabel", _Wp)
        _Wr.Size = UDim2.new(1, -106, 0, 28)
        _Wr.Position = UDim2.fromOffset(10, 4)
        _Wr.BackgroundTransparency = 1
        _Wr.Font = Enum.Font.GothamBold
        _Wr.TextSize = 12
        _Wr.TextXAlignment = Enum.TextXAlignment.Left
        _Wr.TextColor3 = Color3.fromRGB(235, 235, 245)
        _Wr.Text = "ANCH Grid (Farm)"
        _Wr.Active = true
        local _Ws = Instance.new("TextButton", _Wp)
        _Ws.Size = UDim2.fromOffset(62, 22)
        _Ws.Position = UDim2.new(1, -98, 0, 7)
        _Ws.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
        _Ws.Text = "Farm"
        _Ws.Font = Enum.Font.GothamBold
        _Ws.TextSize = 11
        _Ws.TextColor3 = Color3.new(1, 1, 1)
        Instance.new("UICorner", _Ws).CornerRadius = UDim.new(0, 6)
        local _Wt = Instance.new("TextButton", _Wp)
        _Wt.Size = UDim2.fromOffset(24, 24)
        _Wt.Position = UDim2.new(1, -30, 0, 6)
        _Wt.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
        _Wt.Text = "X"
        _Wt.Font = Enum.Font.GothamBold
        _Wt.TextSize = 12
        _Wt.TextColor3 = Color3.new(1, 1, 1)
        Instance.new("UICorner", _Wt).CornerRadius = UDim.new(0, 6)
        _Wt.MouseButton1Click:Connect(function()
            FloatingGridGui.Enabled = false
        end)
        local _Wu = Instance.new("Frame", _Wp)
        _Wu.Size = UDim2.fromOffset(_Wo, _Wo)
        _Wu.Position = UDim2.fromOffset(10, 36)
        _Wu.BackgroundTransparency = 1
        local _Wv = Color3.fromRGB(48, 48, 60)
        local _Ww = Color3.fromRGB(46, 160, 90)
        local _Wx = Color3.fromRGB(60, 110, 220)
        local _Wy = {}
        local function _Wz()
            return (GridMode == "pabrik") and Config.pabrikTiles or Config.farmGrid
        end
        local _WA = Instance.new("TextButton", _Wp)
        _WA.Size = UDim2.new(1, -20, 0, 30)
        _WA.Position = UDim2.new(0, 10, 1, -54)
        _WA.BackgroundColor3 = _Ww
        _WA.Font = Enum.Font.GothamBold
        _WA.TextSize = 13
        _WA.TextColor3 = Color3.new(1, 1, 1)
        _WA.Text = "START FARM"
        Instance.new("UICorner", _WA).CornerRadius = UDim.new(0, 8)
        _WA.MouseButton1Click:Connect(function()
            if GridMode == "pabrik" then
                SetFeatureEnabled("pabrik", not SeedFactory.on)
            else
                SetFeatureEnabled("autofarm", not (AutoFarm.on and not AutoFarm.Override))
            end
        end)
        RefreshGridGui = function()
            local _WB = _Wz()
            local _WC = GridMode == "pabrik"
            _Ws.Text = _WC and "Factory" or "Farm"
            _Ws.BackgroundColor3 = _WC and Color3.fromRGB(200, 120, 40) or Color3.fromRGB(60, 60, 75)
            _Wr.Text = _WC and "Factory Break Tiles" or "ANCH Grid (Farm)"
            for _WD, _WE in pairs(_Wy) do
                _WE.BackgroundColor3 = _WB[_WD] and _Ww or _Wv
            end
            if _WC then
                _WA.Text = SeedFactory.on and "STOP FACTORY" or "START FACTORY"
                _WA.BackgroundColor3 = SeedFactory.on and Color3.fromRGB(200, 60, 60) or _Ww
            else
                local _WF = AutoFarm.on and not AutoFarm.Override
                _WA.Text = _WF and "STOP FARM" or "START FARM"
                _WA.BackgroundColor3 = _WF and Color3.fromRGB(200, 60, 60) or _Ww
            end
        end
        SetGridMode = function(_WG)
            GridMode = _WG
            RefreshGridGui()
        end
        _Ws.MouseButton1Click:Connect(function()
            SetGridMode(GridMode == "pabrik" and "farm" or "pabrik")
        end)
        for _WH = 0, _Wn - 1 do
            for _WI = 0, _Wn - 1 do
                local _WJ, _WK = _WI - _Wm, _WH - _Wm
                local _WL = _WJ .. "," .. _WK
                local _WM = Instance.new("TextButton", _Wu)
                _WM.Size = UDim2.fromOffset(_Wk, _Wk)
                _WM.Position = UDim2.fromOffset(_WI * (_Wk + _Wl), _WH * (_Wk + _Wl))
                _WM.Font = Enum.Font.GothamBold
                _WM.TextSize = 11
                _WM.TextColor3 = Color3.new(1, 1, 1)
                Instance.new("UICorner", _WM).CornerRadius = UDim.new(0, 6)
                if _WJ == 0 and _WK == 0 then
                    _WM.Text = "ME"
                    _WM.BackgroundColor3 = _Wx
                    _WM.AutoButtonColor = false
                else
                    _WM.Text = ""
                    _WM.BackgroundColor3 = _Wz()[_WL] and _Ww or _Wv
                    _Wy[_WL] = _WM
                    _WM.MouseButton1Click:Connect(function()
                        local _WN = _Wz()
                        _WN[_WL] = (not _WN[_WL]) or nil
                        SaveConfig()
                        RefreshGridGui()
                    end)
                end
            end
        end
        local _WO = Instance.new("TextButton", _Wp)
        _WO.Size = UDim2.new(1, -20, 0, 18)
        _WO.Position = UDim2.new(0, 10, 1, -22)
        _WO.BackgroundTransparency = 1
        _WO.Font = Enum.Font.Gotham
        _WO.TextSize = 12
        _WO.TextColor3 = Color3.fromRGB(180, 180, 195)
        _WO.Text = "Clear Selection"
        _WO.MouseButton1Click:Connect(function()
            if GridMode == "pabrik" then
                Config.pabrikTiles = {}
            else
                Config.farmGrid = {}
            end
            SaveConfig()
            RefreshGridGui()
        end)
        local _WP, _WQ, _WR
        _Wr.InputBegan:Connect(function(_WS)
            if _WS.UserInputType == Enum.UserInputType.MouseButton1 or _WS.UserInputType == Enum.UserInputType.Touch then
                _WP, _WQ, _WR = true, _WS.Position, _Wp.Position
                _WS.Changed:Connect(function()
                    if _WS.UserInputState == Enum.UserInputState.End then
                        _WP = false
                    end
                end)
            end
        end)
        TrackConnection(UserInputService.InputChanged:Connect(function(_WT)
            if _WP and (_WT.UserInputType == Enum.UserInputType.MouseMovement or _WT.UserInputType == Enum.UserInputType.Touch) then
                local _WU = _WT.Position - _WQ
                _Wp.Position = UDim2.new(_WR.X.Scale, _WR.X.Offset + _WU.X, _WR.Y.Scale, _WR.Y.Offset + _WU.Y)
            end
        end))
        FlyPadGui = _Wh("ANCHFlyPad")
        local function _WV(_WW, _WX, _WY)
            local _WZ = Instance.new("TextButton", FlyPadGui)
            _WZ.Size = UDim2.fromOffset(60, 60)
            _WZ.AnchorPoint = Vector2.new(1, 0.5)
            _WZ.Position = UDim2.new(1, -24, 0.5, _WX)
            _WZ.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
            _WZ.BackgroundTransparency = 0.2
            _WZ.Text = _WW
            _WZ.Font = Enum.Font.GothamBold
            _WZ.TextSize = 26
            _WZ.TextColor3 = Color3.new(1, 1, 1)
            Instance.new("UICorner", _WZ).CornerRadius = UDim.new(1, 0)
            local _Xa = Instance.new("UIStroke", _WZ)
            _Xa.Color = Color3.fromRGB(48, 255, 106)
            _Xa.Thickness = 2
            local _Xb = nil
            _WZ.InputBegan:Connect(function(_Xc)
                if _Xc.UserInputType == Enum.UserInputType.Touch or _Xc.UserInputType == Enum.UserInputType.MouseButton1 then
                    _Xb = _Xc
                    _WY(true)
                end
            end)
            TrackConnection(UserInputService.InputEnded:Connect(function(_Xd)
                if _Xb and (_Xd == _Xb or _Xd.UserInputType == Enum.UserInputType.MouseButton1) then
                    _Xb = nil
                    _WY(false)
                end
            end))
        end
        _WV("▲", -38, function(_Xe)
            FlyInput.up = _Xe
        end)
        _WV("▼", 38, function(_Xf)
            FlyInput.down = _Xf
        end)
    end)()
end
-- [27] ANTARMUKA WINDUI: berikutnya berisi seluruh 19 tab menu.
local HubWindow
do
    (function()
        local WindUI = Boot.LoadWindUI()
        NotifyWithWindUI = function(_Xq, _Xr, _Xs)
            WindUI:Notify({
                Title = _Xr or "ANCH HUB | GrowBlox",
                Content = tostring(_Xq),
                Icon = "solar:bell-bold",
                Duration = _Xs or 4,
            })
        end
        local _Xt = Color3.fromHex("#7775F2")
        local _Xu = Color3.fromHex("#ECA201")
        local _Xv = Color3.fromHex("#10C550")
        local _Xw = Color3.fromHex("#257AF7")
        local _Xx = Color3.fromHex("#EF4F1D")
        Boot.SetStatus("Membuka menu")
        HubWindow = WindUI:CreateWindow({
            Title = "ANCH Hub  |  GrowBlox Beta",
            Folder = "ANCHHub_GrowBlox",
            Icon = "solar:folder-2-bold-duotone",
            NewElements = true,
            HideSearchBar = false,
            Theme = "Indigo",
            OpenButton = {
                Title = "ANCH Hub",
                CornerRadius = UDim.new(1, 0),
                StrokeThickness = 3,
                Enabled = Config.launcher,
                Draggable = true,
                OnlyMobile = false,
                Scale = 0.5,
                Color = ColorSequence.new(Color3.fromHex("#30FF6A"), Color3.fromHex("#e7ff2f")),
            },
        })
        assert(HubWindow, "WindUI tidak mengembalikan jendela")
        Boot.BringUiToFront(WindUI)
        pcall(function() HubWindow:DisableTopbarButtons({ "Fullscreen" }) end)
        pcall(function()
            HubWindow:Tag({
                Title = "V1.3 EN",
                Icon = "github",
                Color = Color3.fromHex("#1c1c1c"),
                Border = true,
            })
        end)
        local UiState = {
            tabs = {},
            refreshers = {},
            syncing = false,
            active = "features",
        }
        SyncFeatureControls = function()
            UiState.syncing = true
            for _Xz, _XA in ipairs(UiState.refreshers) do
                pcall(_XA)
            end
            UiState.syncing = false
        end
        local function BuildUiSection(_XC, _XD)
            local _XE, _XF = pcall(_XD)
            if not _XE then
                Boot.UiError(_XC, _XF)
            end
        end
        local function UpdateUiText(_XH, _XI, _XJ)
            if not _XH then
                return
            end
            pcall(function()
                if _XI and _XH.SetTitle then
                    _XH:SetTitle(_XI)
                end
                if _XJ and _XH.SetDesc then
                    _XH:SetDesc(_XJ)
                elseif _XJ and _XH.SetContent then
                    _XH:SetContent(_XJ)
                end
            end)
        end
        local function AddFeatureToggle(_XL, _XM, _XN, _XO)
            local _XP = FeatureRegistry[_XO]
            if not _XP then
                return nil
            end
            local _XQ
            BuildUiSection("Toggle:" .. tostring(_XO), function()
                _XQ = _XL:Toggle({
                    Title = _XM,
                    Desc = _XN,
                    Value = _XP.get(),
                    Callback = function(_XR)
                        if UiState.syncing then
                            return
                        end
                        if _XP.get() ~= _XR then
                            SetFeatureEnabled(_XO, _XR)
                        end
                    end,
                })
                table.insert(UiState.refreshers, function()
                    if _XQ and _XQ.Set then
                        _XQ:Set(_XP.get())
                    end
                end)
            end)
            return _XQ
        end
        local MainSection = HubWindow:Section({
            Title = "Main Section",
            Opened = true
        })
        local AutomationSection = HubWindow:Section({
            Title = "Automation",
            Opened = true
        })
        local FastHelpersSection = HubWindow:Section({
            Title = "Fast Helpers",
            Opened = true
        })
        local InventoryWorldSection = HubWindow:Section({
            Title = "Inventory & World",
            Opened = true
        })
        local SafetyUtilitySection = HubWindow:Section({
            Title = "Safety & Utility",
            Opened = true
        })
        local SystemSettingsSection = HubWindow:Section({
            Title = "System & Settings",
            Opened = true
        })
        -- MENU 01: Dashboard & Stats
        BuildUiSection("Tab:Dashboard", function()
            local _XY = MainSection:Tab({
                Title = "Dashboard & Stats",
                Icon = "solar:home-2-bold",
                IconColor = _Xv,
                IconShape = "Square",
                Border = true,
            })
            UiState.tabs.features = _XY
            local _XZ = _XY:Paragraph({
                Title = "Character & Game Connection Status",
                Desc = "Detecting position...",
            })
            local _Ya = _XY:Paragraph({
                Title = "Real-Time Session Statistics",
                Desc = "Loading stats...",
            })
            task.spawn(function()
                while IsSessionAlive() and task.wait(0.6) do
                    pcall(function()
                        local _Yb, _Yc = GetCurrentTile()
                        local _Yd = GetWorldName()
                        local _Ye = string.format(("World: %s | Inv: %s | State: %s | Punch: %s | Drop: %s | Trees: " .. "%s"), Refs.World and "OK" or "-", Refs.Inv and "OK" or "-", Refs.State and "OK" or "-", Refs.Punch and "OK" or "-", Drops.list and "OK" or "-", Refs.Trees and "OK" or "-")
                        if _Yb then
                            UpdateUiText(_XZ, string.format("World: %s  |  Tile Position: (%d, %d)", _Yd ~= "" and _Yd or "-", _Yb, _Yc), _Ye)
                        else
                            UpdateUiText(_XZ, "Character Status: Outside World", _Ye)
                        end
                        UpdateUiText(_Ya, "Real-Time Session Statistics", SessionStats.Text())
                    end)
                end
            end)
            _XY:Button({
                Title = "Rescan Game References (Reconnect Refs)",
                Color = Color3.fromHex("#305dff"),
                Justify = "Center",
                Callback = function()
                    Refs.Scan(true)
                    ShowNotification("Game references refreshed!")
                end,
            })
            local _Yf = _XY:Group({})
            _Yf:Button({
                Title = "Reset Stats",
                Justify = "Center",
                Callback = function()
                    SessionStats.Reset();
                    ShowNotification("Session statistics reset.")
                end,
            })
            _Yf:Button({
                Title = "Send Stats to Discord",
                Justify = "Center",
                Callback = function()
                    if not (Config.webhookOn and Webhook.Valid(Config.webhookUrl)) then
                        ShowNotification(("Enable & set your Discord Webhook URL in System & Settings first" .. "!"))
                    else
                        Webhook.Send("report", "Session Statistics Report\n```\n" .. SessionStats.Text() .. "\n```")
                        ShowNotification("Statistics report queued for Discord!")
                    end
                end,
            })
        end)
        -- MENU 02: Character & Movement
        BuildUiSection("Tab:Character", function()
            local _Yg = MainSection:Tab({
                Title = "Character & Movement",
                Icon = "solar:square-transfer-horizontal-bold",
                IconColor = _Xw,
                IconShape = "Square",
                Border = true,
            })
            UiState.tabs.nav = _Yg
            local _Yh = _Yg:Paragraph({
                Title = "Universal Navigation Status",
                Desc = "Last: -"
            })
            _Yg:Dropdown({
                Title = "Universal Movement Method (DF / Farmer / Factory / Clear)",
                Desc = ("Legit Walking = Physical A* pathfinding | Teleport Mode = Tile-b" .. "y-tile real-time stepper."),
                Values = {
                    "Legit Walking",
                    "Teleport Mode"
                },
                Value = Config.moveMethod or "Legit Walking",
                Callback = function(_Yi)
                    Config.moveMethod = _Yi or "Legit Walking"
                    Config.moveMode = (Config.moveMethod == "Teleport Mode") and "fly" or "legit"
                    SaveConfig()
                    ShowNotification("Movement method set to: " .. Config.moveMethod)
                end,
            })
            _Yg:Space()
            task.spawn(function()
                while IsSessionAlive() and task.wait(0.6) do
                    pcall(function()
                        UpdateUiText(_Yh, "Movement Mode: " .. Config.moveMode:upper(), "Click TP Status: " .. tostring(Navigation.last) .. " | Scaffolds Placed: " .. Navigation.PlacedScaffolds)
                    end)
                end
            end)
            AddFeatureToggle(_Yg, "Click TP (Legit A* Pathfinding)", ("Tap/click anywhere on screen to automatically walk & climb to th" .. "at tile."), "clicktp")
            AddFeatureToggle(_Yg, "Noclip + FlyPad (▲/▼)", "Fly through blocks and display on-screen Up/Down buttons.", "noclip")
            AddFeatureToggle(_Yg, "Unlimited Jump (Air Jump)", "Jump infinitely in mid-air.", "ujump")
            AddFeatureToggle(_Yg, "God Mode (Hazard Immunity)", "Immune to lava, spikes, fire, and deadly obstacles.", "god")
            AddFeatureToggle(_Yg, "Longhand (Extended Reach)", "Extend your punch and build range.", "longhand")
            AddFeatureToggle(_Yg, "Lite Mode (FPS Boost)", "Disable particles & punch sound effects for higher FPS.", "lite")
            AddFeatureToggle(_Yg, "Skin Blink", "Automatically cycle character skin colors.", "blink")
            AddFeatureToggle(_Yg, "Anti-AFK", "Prevent idle disconnection.", "antiafk")
            _Yg:Space()
            _Yg:Section({ Title = "Speed & Auto Collect Radius" })
            _Yg:Slider({
                Title = "Character Walkspeed (%)",
                Desc = "100% = normal game speed.",
                IsTooltip = true,
                Step = 10,
                Value = {
                    Min = 50,
                    Max = 400,
                    Default = math.clamp(Config.walkSpeed, 50, 400)
                },
                Callback = function(_Yj)
                    Config.walkSpeed = tonumber(_Yj) or 100
                    if Config.walkSpeed == 100 and Refs.World then
                        Refs.World.speedScale = 1
                    end
                    SaveConfig()
                end,
            })
            _Yg:Toggle({
                Title = "Always Collect Nearby Drops",
                Value = Config.collectAround,
                Callback = function(_Yk)
                    Config.collectAround = _Yk;
                    SaveConfig()
                end,
            })
            _Yg:Slider({
                Title = "Auto Collect Radius (Tiles)",
                IsTooltip = true,
                Step = 1,
                Value = {
                    Min = 1,
                    Max = 8,
                    Default = math.clamp(Config.collectRadius, 1, 8)
                },
                Callback = function(_Yl)
                    Config.collectRadius = math.floor(tonumber(_Yl) or 3);
                    SaveConfig()
                end,
            })
            _Yg:Toggle({
                Title = "Require Holding Shift for Click TP (PC)",
                Value = Config.clickTpShift,
                Callback = function(_Ym)
                    Config.clickTpShift = _Ym;
                    SaveConfig()
                end,
            })
        end)
        -- MENU 03: Auto Farm
        BuildUiSection("Tab:AutoFarm", function()
            local _Yn = AutomationSection:Tab({
                Title = "Auto Farm",
                Icon = "solar:check-square-bold",
                IconColor = _Xu,
                IconShape = "Square",
                Border = true,
            })
            UiState.tabs.farm = _Yn
            local _Yo = _Yn:Paragraph({
                Title = "Auto Farm Status",
                Desc = "Loading..."
            })
            task.spawn(function()
                while IsSessionAlive() and task.wait(0.5) do
                    pcall(function()
                        local _Yp = Config.farmPlaceId
                        UpdateUiText(_Yo, "Status: " .. AutoFarm.stats.status .. " (" .. Config.farmMode .. ")", string.format(("Block: %s [ID %d] (In Bag: %d)\nPlaced: %d | Broken: %d | Collect" .. "ed: %d | Cycles: %d"), GetItemName(_Yp), _Yp, CountInventoryItem(_Yp), AutoFarm.stats.placed, AutoFarm.stats.broken, AutoFarm.stats.picked, AutoFarm.stats.cycles))
                    end)
                end
            end)
            AddFeatureToggle(_Yn, "Enable Auto Farm", "Automatically place & break blocks based on the 5x5 Grid.", "autofarm")
            _Yn:Dropdown({
                Title = "Auto Collect Mode (Legit Physical / Remote)",
                Desc = ("Legit = Physical sweep & small jump (anti-reject). Remote = Coll" .. "ect from range."),
                Values = {
                    "Legit",
                    "Remote"
                },
                Value = (Config.collectMode == "Remote") and "Remote" or "Legit",
                Callback = function(_Yq)
                    Config.collectMode = (_Yq == "Remote") and "Remote" or "Legit"
                    SaveConfig()
                    ShowNotification("Auto Collect Mode: " .. Config.collectMode)
                end,
            })
            _Yn:Toggle({
                Title = "Hand Swing & Place Visual Effects",
                Desc = "Show arm swing animation and particle effects locally.",
                Value = Config.visualAnim,
                Callback = function(_Yr)
                    Config.visualAnim = _Yr;
                    SaveConfig()
                end,
            })
            _Yn:Button({
                Title = "Open 5x5 Floating Grid (Farm Mode)",
                Color = Color3.fromHex("#305dff"),
                Justify = "Center",
                Callback = function()
                    if SetGridMode then
                        SetGridMode("farm")
                    end
                    if FloatingGridGui then
                        FloatingGridGui.Enabled = not FloatingGridGui.Enabled
                    end
                end,
            })
            _Yn:Space()
            _Yn:Section({ Title = "Farm Mode & Speed" })
            local _Ys = {
                ["Place + Break"] = "Place + Break",
                ["Break Only"] = "Break saja",
                ["Place Only"] = "Place saja",
            }
            local _Yt = {
                ["Place + Break"] = "Place + Break",
                ["Break saja"] = "Break Only",
                ["Place saja"] = "Place Only",
            }
            _Yn:Dropdown({
                Title = "Auto Farm Mode",
                Values = {
                    "Place + Break",
                    "Break Only",
                    "Place Only"
                },
                Value = _Yt[Config.farmMode] or "Place + Break",
                Callback = function(_Yu)
                    Config.farmMode = _Ys[_Yu] or "Place + Break"
                    SaveConfig()
                end,
            })
            _Yn:Slider({
                Title = "Multi-Target Break (1 - 5 Tiles)",
                Desc = ("Hit multiple tiles in rotation. Automatically uses Rayman Fist i" .. "f equipped!"),
                IsTooltip = true,
                Step = 1,
                Value = {
                    Min = 1,
                    Max = 5,
                    Default = math.clamp(Config.farmMultiTarget, 1, 5)
                },
                Callback = function(_Yv)
                    Config.farmMultiTarget = math.clamp(math.floor(tonumber(_Yv) or 1), 1, 5);
                    SaveConfig()
                end,
            })
            _Yn:Input({
                Title = "Farm Block ID",
                Value = tostring(Config.farmPlaceId),
                Placeholder = "e.g. 2 (Dirt)",
                Callback = function(_Yw)
                    local _Yx = tonumber(_Yw)
                    if _Yx and _Yx > 0 then
                        Config.farmPlaceId = math.floor(_Yx)
                        SaveConfig()
                        ShowNotification("Farm Block: " .. GetItemName(Config.farmPlaceId) .. " [" .. Config.farmPlaceId .. "]")
                    end
                end,
            })
            local _Yy = {}
            local _Yz
            _Yn:Input({
                Title = "Search Block in Database",
                Placeholder = "Type block name...",
                Callback = function(_YA)
                    _Yy = {}
                    local _YB = {}
                    if TrimText(_YA) ~= "" then
                        for _YC, _YD in ipairs(SearchBlocks(_YA, 25)) do
                            local _YE = string.format("%s [%d]", _YD.name, _YD.id)
                            _Yy[_YE] = _YD.id
                            table.insert(_YB, _YE)
                        end
                    end
                    if #_YB == 0 then
                        _YB = { "No results" }
                    end
                    if _Yz and _Yz.Refresh then
                        pcall(function()
                            _Yz:Refresh(_YB)
                        end)
                    end
                end,
            })
            _Yz = _Yn:Dropdown({
                Title = "Select Search Result",
                Values = { "Type a block name above..." },
                Callback = function(_YF)
                    local _YG = _Yy[_YF]
                    if _YG then
                        Config.farmPlaceId = _YG
                        SaveConfig()
                        ShowNotification("Block set to: " .. GetItemName(_YG) .. " [" .. _YG .. "]")
                    end
                end,
            })
            _Yn:Slider({
                Title = "Place Delay (ms)",
                IsTooltip = true,
                Step = 10,
                Value = {
                    Min = 50,
                    Max = 1000,
                    Default = math.clamp(Config.farmPlaceMs, 50, 1000)
                },
                Callback = function(_YH)
                    Config.farmPlaceMs = tonumber(_YH) or 250;
                    SaveConfig()
                end,
            })
            _Yn:Input({
                Title = "Break Delay (seconds)",
                Value = tostring(Config.farmDelay),
                Placeholder = "0.22",
                Callback = function(_YI)
                    local _YJ = tonumber(_YI)
                    if _YJ and _YJ >= 0.03 and _YJ <= 5 then
                        Config.farmDelay = _YJ;
                        SaveConfig()
                    end
                end,
            })
            _Yn:Toggle({
                Title = "Auto Collect Drops",
                Value = Config.farmTake,
                Callback = function(_YK)
                    Config.farmTake = _YK;
                    SaveConfig()
                end,
            })
            _Yn:Space()
            _Yn:Section({ Title = "Auto Save / Drop Seeds (When Seeds >= Threshold)" })
            _Yn:Toggle({
                Title = "Enable Auto Drop Seeds When Full",
                Desc = ("Automatically pause farming, drop seeds at target world/pos, and" .. " return to resume Auto Farm."),
                Value = Config.farmAutoDropSeed,
                Callback = function(_YL)
                    Config.farmAutoDropSeed = _YL;
                    SaveConfig()
                end,
            })
            _Yn:Slider({
                Title = "Drop When Seed Count Reaches >=",
                IsTooltip = true,
                Step = 5,
                Value = {
                    Min = 20,
                    Max = 200,
                    Default = math.clamp(Config.farmSeedDropAt or 200, 20, 200)
                },
                Callback = function(_YM)
                    Config.farmSeedDropAt = math.floor(tonumber(_YM) or 200);
                    SaveConfig()
                end,
            })
            _Yn:Slider({
                Title = "Keep Seeds in Backpack",
                IsTooltip = true,
                Step = 5,
                Value = {
                    Min = 0,
                    Max = 190,
                    Default = math.clamp(Config.farmSeedKeep or 0, 0, 190)
                },
                Callback = function(_YN)
                    Config.farmSeedKeep = math.floor(tonumber(_YN) or 0);
                    SaveConfig()
                end,
            })
            _Yn:Input({
                Title = "Seed Drop World (Empty = Current World | WORLD | WORLD:DOOR)",
                Value = Config.farmDropWorld,
                Placeholder = "e.g. STORAGE or STORAGE:1",
                Callback = function(_YO)
                    Config.farmDropWorld = TrimText(_YO or "");
                    SaveConfig()
                end,
            })
            _Yn:Button({
                Title = "SetPos Seed Drop (Save Current Position)",
                Color = Color3.fromHex("#10C550"),
                Justify = "Center",
                Callback = function()
                    local _YP, _YQ = GetCurrentTile()
                    if not _YP then
                        ShowNotification("Character position not detected!");
                        return
                    end
                    Config.farmDropX, Config.farmDropY = _YP, _YQ
                    SaveConfig()
                    ShowNotification(string.format("Auto Farm Seed Drop position saved at (%d, %d)!", _YP, _YQ))
                end,
            })
        end)
        -- MENU 04: Auto Clear
        BuildUiSection("Tab:AutoClear", function()
            local _YR = AutomationSection:Tab({
                Title = "Auto Clear",
                Icon = "solar:cursor-square-bold",
                IconColor = _Xx,
                IconShape = "Square",
                Border = true,
            })
            UiState.tabs.clear = _YR
            local _YS = _YR:Paragraph({
                Title = "Auto Clear World Status",
                Desc = "Loading..."
            })
            task.spawn(function()
                while IsSessionAlive() and task.wait(0.5) do
                    pcall(function()
                        local _YT = AutoClear.stats
                        UpdateUiText(_YS, string.format("Status: %s (Pass %d | Row Y=%s)", AutoClear.status, _YT.pass, _YT.row >= 0 and tostring(_YT.row) or "-"), string.format(("Targets: %d | Remaining: %d | Skipped: %d\nBroken: %d | Drops Pic" .. "ked: %d"), _YT.scanned, _YT.left, _YT.skipped, _YT.broken, _YT.picked))
                    end)
                end
            end)
            AddFeatureToggle(_YR, "Auto Clear World (Legit Walk + Hover Break)", ("Walks via A* pathfinding between blocks and enables ModFly hover" .. " while breaking blocks underneath."), "autoclear")
            _YR:Dropdown({
                Title = "Sweep Direction",
                Values = {
                    "Zig-zag",
                    "Left -> Right"
                },
                Value = (Config.clearSweep == "Zig-zag") and "Zig-zag" or "Left -> Right",
                Callback = function(_YU)
                    Config.clearSweep = (_YU == "Zig-zag") and "Zig-zag" or "Kiri → Kanan"
                    SaveConfig()
                end,
            })
            _YR:Toggle({
                Title = "Include Background Blocks",
                Value = Config.clearIncludeBg,
                Callback = function(_YV)
                    Config.clearIncludeBg = _YV;
                    SaveConfig()
                end,
            })
            _YR:Input({
                Title = "Break Punch Delay (seconds)",
                Value = tostring(Config.clearBreakDelay),
                Callback = function(_YW)
                    local _YX = tonumber(_YW)
                    if _YX and _YX >= 0.03 and _YX <= 5 then
                        Config.clearBreakDelay = _YX;
                        SaveConfig()
                    end
                end,
            })
            _YR:Input({
                Title = "Move Step Delay (seconds)",
                Value = tostring(Config.clearTpDelay),
                Callback = function(_YY)
                    local _YZ = tonumber(_YY)
                    if _YZ and _YZ >= 0.05 and _YZ <= 5 then
                        Config.clearTpDelay = _YZ;
                        SaveConfig()
                    end
                end,
            })
            _YR:Toggle({
                Title = "Auto Collect Drops",
                Value = Config.clearTake,
                Callback = function(_Za)
                    Config.clearTake = _Za;
                    SaveConfig()
                end,
            })
        end)
        -- MENU 05: Farmer (Harvest/Plant)
        BuildUiSection("Tab:Farmer", function()
            local _Zb = AutomationSection:Tab({
                Title = "Farmer (Harvest/Plant)",
                Icon = "solar:check-square-bold",
                IconColor = _Xv,
                IconShape = "Square",
                Border = true,
            })
            UiState.tabs.harvest = _Zb
            local _Zc = _Zb:Paragraph({
                Title = "Farmer Status",
                Desc = "Loading..."
            })
            task.spawn(function()
                while IsSessionAlive() and task.wait(0.5) do
                    pcall(function()
                        local _Zd = Farmer.stats
                        UpdateUiText(_Zc, "Status: " .. Farmer.status, string.format(("Total Trees: %d | Ready: %d | Growing: %d\nHarvested: %d | Plante" .. "d: %d | Drops Picked: %d\nPlant Seed: %s [ID %d] (In Bag: %d)"), _Zd.totalTrees, _Zd.ready, _Zd.skipped, _Zd.harvested, _Zd.planted, _Zd.picked, GetItemName(Config.harvestSeedId), Config.harvestSeedId, CountInventoryItem(Config.harvestSeedId)))
                    end)
                end
            end)
            AddFeatureToggle(_Zb, "Enable Farmer", ("Automatically harvest ready trees & plant seeds using Zig-Zag A*" .. " walking."), "autoharvest")
            _Zb:Toggle({
                Title = "Auto Harvest (Break Ready Trees)",
                Value = Config.harvestDoHarvest,
                Callback = function(_Ze)
                    Config.harvestDoHarvest = _Ze;
                    SaveConfig()
                end,
            })
            _Zb:Toggle({
                Title = "Auto Plant Seeds",
                Value = Config.harvestDoPlant,
                Callback = function(_Zf)
                    Config.harvestDoPlant = _Zf;
                    SaveConfig()
                end,
            })
            _Zb:Input({
                Title = "Seed ID for Auto Plant",
                Desc = "e.g. 3 = Dirt Seed, 5 = Lava Seed",
                Value = tostring(Config.harvestSeedId),
                Placeholder = "3",
                Callback = function(_Zg)
                    local _Zh = tonumber(_Zg)
                    if _Zh and _Zh > 0 then
                        Config.harvestSeedId = math.floor(_Zh)
                        SaveConfig()
                        ShowNotification("Plant Seed set to: " .. GetItemName(Config.harvestSeedId))
                    end
                end,
            })
            _Zb:Toggle({
                Title = "Use Scaffold Blocks When Climbing",
                Value = Config.harvestUseBlock,
                Callback = function(_Zi)
                    Config.harvestUseBlock = _Zi;
                    SaveConfig()
                end,
            })
            _Zb:Toggle({
                Title = "Auto Collect Harvest Drops",
                Value = Config.harvestTake,
                Callback = function(_Zj)
                    Config.harvestTake = _Zj;
                    SaveConfig()
                end,
            })
        end)
        -- MENU 06: Auto DF (Full World)
        BuildUiSection("Tab:AutoDF", function()
            local _Zk = AutomationSection:Tab({
                Title = "Auto DF (Full World)",
                Icon = "solar:hamburger-menu-bold",
                IconColor = _Xu,
                IconShape = "Square",
                Border = true,
            })
            UiState.tabs.df = _Zk
            local _Zl = _Zk:Paragraph({
                Title = "Auto Dirt Farm Status",
                Desc = "Loading..."
            })
            task.spawn(function()
                while IsSessionAlive() and task.wait(0.5) do
                    pcall(function()
                        local _Zm = DirtFarm.stats
                        local _Zn = GetDirtId()
                        local _Zo = GetDirtSeedId()
                        UpdateUiText(_Zl, "Status: " .. DirtFarm.status .. " (" .. tostring(_Zm.step) .. ")", string.format(("Top Dirt Row: Y=%d | Bedrock: Y=%d\nDirt in Bag: %d | Dirt Seeds:" .. " %d\nBroken: %d | Dirt Placed: %d | Drops Picked: %d"), _Zm.topDirtY, _Zm.bedrockY, CountInventoryItem(_Zn), CountInventoryItem(_Zo), _Zm.broken, _Zm.placed, _Zm.picked))
                    end)
                end
            end)
            AddFeatureToggle(_Zk, "Enable Auto Dirt Farm (Full World)", ("Automatically build lower & upper Dirt Farm platforms + Smart Di" .. "rt Restock."), "autodf")
            _Zk:Toggle({
                Title = "Replace Lava/Rock with Dirt on Platforms",
                Value = Config.dfReplacePlatform,
                Callback = function(_Zp)
                    Config.dfReplacePlatform = _Zp;
                    SaveConfig()
                end,
            })
            _Zk:Toggle({
                Title = "Auto Collect Drops",
                Value = Config.dfTake,
                Callback = function(_Zq)
                    Config.dfTake = _Zq;
                    SaveConfig()
                end,
            })
            _Zk:Toggle({
                Title = "Enable ModFly During Auto DF (Anti-Lava)",
                Desc = "Hover & stay immune to lava while breaking blocks.",
                Value = Config.dfModFly,
                Callback = function(_Zr)
                    Config.dfModFly = _Zr
                    SaveConfig()
                    if DirtFarm.on then
                        SetNoclipOwner("autodf", _Zr)
                    end
                end,
            })
            _Zk:Input({
                Title = "Break Punch Delay (seconds)",
                Value = tostring(Config.dfBreakDelay),
                Callback = function(_Zs)
                    local _Zt = tonumber(_Zs)
                    if _Zt and _Zt >= 0.03 and _Zt <= 5 then
                        Config.dfBreakDelay = _Zt;
                        SaveConfig()
                    end
                end,
            })
            _Zk:Input({
                Title = "Move Step Delay (seconds)",
                Value = tostring(Config.dfTpDelay),
                Callback = function(_Zu)
                    local _Zv = tonumber(_Zu)
                    if _Zv and _Zv >= 0.05 and _Zv <= 5 then
                        Config.dfTpDelay = _Zv;
                        SaveConfig()
                    end
                end,
            })
        end)
        -- MENU 07: Auto Splice
        BuildUiSection("Tab:AutoSplice", function()
            local _Zw = AutomationSection:Tab({
                Title = "Auto Splice",
                Icon = "solar:square-transfer-horizontal-bold",
                IconColor = _Xt,
                IconShape = "Square",
                Border = true,
            })
            UiState.tabs.splice = _Zw
            local _Zx = _Zw:Paragraph({
                Title = "Auto Splice Status",
                Desc = "Loading..."
            })
            task.spawn(function()
                while IsSessionAlive() and task.wait(0.6) do
                    pcall(function()
                        UpdateUiText(_Zx, "Status: " .. AutoSplice.status, string.format(("%s\nSeed A: %s [%d] (x%d) | Seed B: %s [%d] (x%d)\nPlanted: %d | S" .. "pliced: %d"), AutoSplice.ResultText(), GetItemName(Config.spliceA), Config.spliceA, CountInventoryItem(Config.spliceA), GetItemName(Config.spliceB), Config.spliceB, CountInventoryItem(Config.spliceB), AutoSplice.planted, AutoSplice.made))
                    end)
                end
            end)
            AddFeatureToggle(_Zw, "Enable Auto Splice", "Plant Seed A and splice it with Seed B.", "autosplice")
            _Zw:Input({
                Title = "Seed A ID (Planted First)",
                Value = tostring(Config.spliceA),
                Placeholder = "3 (Dirt Seed)",
                Callback = function(_Zy)
                    local _Zz = tonumber(_Zy)
                    if _Zz and _Zz > 0 then
                        Config.spliceA = math.floor(_Zz);
                        SaveConfig()
                    end
                end,
            })
            _Zw:Input({
                Title = "Seed B ID (Spliced onto Seed A)",
                Value = tostring(Config.spliceB),
                Placeholder = "5 (Lava Seed)",
                Callback = function(_ZA)
                    local _ZB = tonumber(_ZA)
                    if _ZB and _ZB > 0 then
                        Config.spliceB = math.floor(_ZB);
                        SaveConfig()
                    end
                end,
            })
            _Zw:Toggle({
                Title = "Roam Entire World (A*)",
                Desc = ("ON = Find empty tiles across the world. OFF = Only splice within" .. " 5x5 Grid."),
                Value = Config.spliceRoam,
                Callback = function(_ZC)
                    Config.spliceRoam = _ZC;
                    SaveConfig()
                end,
            })
            _Zw:Slider({
                Title = "Plant / Splice Delay (ms)",
                IsTooltip = true,
                Step = 10,
                Value = {
                    Min = 140,
                    Max = 2000,
                    Default = math.clamp(Config.spliceMs, 140, 2000)
                },
                Callback = function(_ZD)
                    Config.spliceMs = math.floor(tonumber(_ZD) or 300);
                    SaveConfig()
                end,
            })
        end)
        -- MENU 08: Seed Factory
        BuildUiSection("Tab:Pabrik", function()
            local _ZE = AutomationSection:Tab({
                Title = "Seed Factory",
                Icon = "solar:folder-with-files-bold",
                IconColor = _Xw,
                IconShape = "Square",
                Border = true,
            })
            UiState.tabs.pabrik = _ZE
            local _ZF = _ZE:Paragraph({
                Title = "Seed Factory Status",
                Desc = "Loading..."
            })
            task.spawn(function()
                while IsSessionAlive() and task.wait(0.6) do
                    pcall(function()
                        local _ZG = Config.pabrikSeedId
                        local _ZH = GetBlockIdFromSeed(_ZG)
                        local _ZI, _ZJ = SeedFactory.ParseDropTarget()
                        local _ZK = (_ZI ~= "" and _ZI or "Current World") .. (_ZJ and (" Door:" .. _ZJ) or "") .. (Config.pabrikDropX >= 0 and string.format(" (%d,%d)", Config.pabrikDropX, Config.pabrikDropY) or "")
                        UpdateUiText(_ZF, string.format("Status: %s (Phase: %s)", SeedFactory.status, SeedFactory.phase), string.format(("Seed: %s [%d] x%d | Block: %s x%d\nBreak Pos: %s\nDrop Target: %s " .. "(Max Seed Cap: %d)\nTotals: Harvested %d | Planted %d | Dropped %" .. "d"), GetItemName(_ZG), _ZG, CountInventoryItem(_ZG), _ZH and GetItemName(_ZH) or "-", _ZH and CountInventoryItem(_ZH) or 0, Config.pabrikBreakX >= 0 and string.format("Tile (%d, %d)", Config.pabrikBreakX, Config.pabrikBreakY) or "Not set!", Config.pabrikDrop and _ZK or "Disabled", Config.pabrikMaxSeed or 100, SeedFactory.harvested, SeedFactory.planted, SeedFactory.dropped))
                    end)
                end
            end)
            AddFeatureToggle(_ZE, "Enable Seed Factory", ("Full Cycle: Break Blocks -> Drop Excess Seeds -> Plant -> Wait -" .. "> Harvest -> Repeat."), "pabrik")
            _ZE:Input({
                Title = "Factory Seed ID",
                Desc = ("Block ID is detected automatically (e.g. 3 = Dirt Seed -> Block " .. "ID 2 = Dirt)."),
                Value = tostring(Config.pabrikSeedId),
                Callback = function(_ZL)
                    local _ZM = tonumber(_ZL)
                    if _ZM and _ZM > 0 then
                        Config.pabrikSeedId = math.floor(_ZM);
                        SaveConfig()
                    end
                end,
            })
            _ZE:Input({
                Title = "Max Seed Cap (Plant & Rotation Limit)",
                Desc = ("e.g. 100 = Only plant up to 100 seeds. Any extra seeds above 100" .. " after breaking are automatically dropped at storage."),
                Value = tostring(Config.pabrikMaxSeed or 100),
                Placeholder = "100",
                Callback = function(_ZN)
                    local _ZO = tonumber(_ZN)
                    if _ZO and _ZO >= 1 then
                        Config.pabrikMaxSeed = math.floor(_ZO)
                        SaveConfig()
                        ShowNotification("Factory Max Seed set to: " .. tostring(Config.pabrikMaxSeed))
                    end
                end,
            })
            _ZE:Space()
            _ZE:Section({ Title = "Factory Break Position (SetPos Break)" })
            local _ZP = _ZE:Group({})
            _ZP:Button({
                Title = "SetPos Break (Save Position)",
                Color = Color3.fromHex("#10C550"),
                Justify = "Center",
                Callback = function()
                    local _ZQ, _ZR = GetCurrentTile()
                    if not _ZQ then
                        ShowNotification("Character position not detected!");
                        return
                    end
                    Config.pabrikBreakX, Config.pabrikBreakY = _ZQ, _ZR
                    SaveConfig()
                    ShowNotification(string.format("Factory Break Position saved at (%d, %d)!", _ZQ, _ZR))
                end,
            })
            _ZP:Button({
                Title = "Go to Break Pos",
                Justify = "Center",
                Callback = function()
                    if Config.pabrikBreakX < 0 or Config.pabrikBreakY < 0 then
                        ShowNotification("Break Position is not set yet!")
                        return
                    end
                    task.spawn(function()
                        Navigation.To(Config.pabrikBreakX, Config.pabrikBreakY, nil, 0.3, true)
                    end)
                end,
            })
            _ZE:Button({
                Title = "Select Break Tiles (Open 5x5 Grid in Factory Mode)",
                Color = Color3.fromHex("#305dff"),
                Justify = "Center",
                Callback = function()
                    if SetGridMode then
                        SetGridMode("pabrik")
                    end
                    if FloatingGridGui then
                        FloatingGridGui.Enabled = true
                    end
                end,
            })
            _ZE:Space()
            _ZE:Section({ Title = "Seed Storage / Auto Drop Settings" })
            _ZE:Toggle({
                Title = "Enable Auto Drop Excess Seeds to Storage",
                Value = Config.pabrikDrop,
                Callback = function(_ZS)
                    Config.pabrikDrop = _ZS;
                    SaveConfig()
                end,
            })
            _ZE:Input({
                Title = "Seed Storage World (WORLD or WORLD:DOOR_ID)",
                Value = Config.pabrikDropWorld,
                Placeholder = "e.g. STORAGE or STORAGE:1",
                Callback = function(_ZT)
                    Config.pabrikDropWorld = TrimText(_ZT or "");
                    SaveConfig()
                end,
            })
            _ZE:Button({
                Title = "SetPos Seed Drop (Save Current Tile)",
                Justify = "Center",
                Callback = function()
                    local _ZU, _ZV = GetCurrentTile()
                    if not _ZU then
                        ShowNotification("Position not detected!");
                        return
                    end
                    Config.pabrikDropX, Config.pabrikDropY = _ZU, _ZV
                    SaveConfig()
                    ShowNotification(string.format("Seed Drop Position saved at (%d, %d)", _ZU, _ZV))
                end,
            })
        end)
        -- MENU 09: Auto Move Item
        BuildUiSection("Tab:AutoMove", function()
            local _ZW = AutomationSection:Tab({
                Title = "Auto Move Item",
                Icon = "solar:square-transfer-horizontal-bold",
                IconColor = _Xv,
                IconShape = "Square",
                Border = true,
            })
            UiState.tabs.automove = _ZW
            local _ZX = _ZW:Paragraph({
                Title = "Auto Move Item Status",
                Desc = "Loading..."
            })
            task.spawn(function()
                while IsSessionAlive() and task.wait(0.6) do
                    pcall(function()
                        local _ZY = tonumber(Config.moveItemId) or 0
                        UpdateUiText(_ZX, string.format("Status: %s (Phase: %s)", AutoMove.status, AutoMove.phase), string.format(("Item: %s [ID %d] (In Bag: %d)\nWorld 1 (Take): %s  ->  World 2 (D" .. "rop): %s\nWorld 2 Drop Pos: %s\nTotal Picked: %d | Total Dropped: " .. "%d"), GetItemName(_ZY), _ZY, CountInventoryItem(_ZY), Config.moveWorld1 ~= "" and Config.moveWorld1 or "(Not set)", Config.moveWorld2 ~= "" and Config.moveWorld2 or "(Not set)", (Config.moveDropX >= 0 and Config.moveDropY >= 0) and string.format("(%d, %d)", Config.moveDropX, Config.moveDropY) or "(Not set)", AutoMove.collected, AutoMove.dropped))
                    end)
                end
            end)
            AddFeatureToggle(_ZW, "Enable Auto Move (World 1 -> World 2)", ("Take dropped items in World 1 -> Warp & Drop in World 2 (steps r" .. "ight 1 tile if full) -> Loop until empty."), "automove")
            _ZW:Input({
                Title = "World 1 - Source World (WORLD or WORLD:DOOR_ID)",
                Value = Config.moveWorld1,
                Placeholder = "e.g. FARM1 or FARM1:DOOR1",
                Callback = function(_ZZ)
                    Config.moveWorld1 = TrimText(_ZZ or "");
                    SaveConfig()
                end,
            })
            _ZW:Input({
                Title = "World 2 - Drop World (WORLD or WORLD:DOOR_ID)",
                Value = Config.moveWorld2,
                Placeholder = "e.g. STORAGE1 or STORAGE1:DOOR2",
                Callback = function(_baa)
                    Config.moveWorld2 = TrimText(_baa or "");
                    SaveConfig()
                end,
            })
            _ZW:Button({
                Title = "SetPos Drop in World 2 (Save Current Position)",
                Color = Color3.fromHex("#10C550"),
                Justify = "Center",
                Callback = function()
                    local _bab, _bac = GetCurrentTile()
                    if not _bab then
                        ShowNotification("Position not detected!");
                        return
                    end
                    Config.moveDropX, Config.moveDropY = _bab, _bac
                    SaveConfig()
                    ShowNotification(string.format("World 2 Drop Position saved at (%d, %d)!", _bab, _bac))
                end,
            })
            _ZW:Input({
                Title = "Item ID to Move",
                Value = tostring(Config.moveItemId),
                Placeholder = "e.g. 2 (Dirt) or 3 (Dirt Seed)",
                Callback = function(_bad)
                    local _bae = tonumber(_bad)
                    if _bae and _bae > 0 then
                        Config.moveItemId = math.floor(_bae)
                        SaveConfig()
                        ShowNotification("Auto Move Item set to: " .. GetItemName(Config.moveItemId) .. " [" .. Config.moveItemId .. "]")
                    end
                end,
            })
        end)
        -- MENU 10: Fast Wrench
        BuildUiSection("Tab:FastWrench", function()
            local _baf = FastHelpersSection:Tab({
                Title = "Fast Wrench",
                Icon = "solar:square-transfer-horizontal-bold",
                IconColor = _Xt,
                IconShape = "Square",
                Border = true,
            })
            UiState.tabs.fastwrench = _baf
            _baf:Section({ Title = "Fast Wrench Actions (0ms Modal Bypass)" })
            local _bag, _bah, _bai
            _bag = _baf:Toggle({
                Title = "Fast Pull (Wrench Player = Instant Pull)",
                Desc = ("Bypass the wrench dialog and immediately pull the wrenched playe" .. "r."),
                Value = Config.fastPull,
                Callback = function(_baj)
                    Config.fastPull = _baj
                    if _baj then
                        Config.fastKick, Config.fastBan = false, false
                        if _bah and _bah.Set then
                            pcall(function()
                                _bah:Set(false)
                            end)
                        end
                        if _bai and _bai.Set then
                            pcall(function()
                                _bai:Set(false)
                            end)
                        end
                        ShowNotification("Fast Pull ENABLED! Wrench a player to pull them instantly.")
                    end
                    SaveConfig()
                end,
            })
            _bah = _baf:Toggle({
                Title = "Fast Kick (Wrench Player = Instant Kick)",
                Desc = ("Bypass the wrench dialog and immediately kick the wrenched playe" .. "r."),
                Value = Config.fastKick,
                Callback = function(_bak)
                    Config.fastKick = _bak
                    if _bak then
                        Config.fastPull, Config.fastBan = false, false
                        if _bag and _bag.Set then
                            pcall(function()
                                _bag:Set(false)
                            end)
                        end
                        if _bai and _bai.Set then
                            pcall(function()
                                _bai:Set(false)
                            end)
                        end
                        ShowNotification("Fast Kick ENABLED! Wrench a player to kick them instantly.")
                    end
                    SaveConfig()
                end,
            })
            _bai = _baf:Toggle({
                Title = "Fast Ban (Wrench Player = Instant Ban)",
                Desc = ("Bypass the wrench dialog and immediately ban the wrenched player" .. "."),
                Value = Config.fastBan,
                Callback = function(_bal)
                    Config.fastBan = _bal
                    if _bal then
                        Config.fastPull, Config.fastKick = false, false
                        if _bag and _bag.Set then
                            pcall(function()
                                _bag:Set(false)
                            end)
                        end
                        if _bah and _bah.Set then
                            pcall(function()
                                _bah:Set(false)
                            end)
                        end
                        ShowNotification("Fast Ban ENABLED! Wrench a player to ban them instantly.")
                    end
                    SaveConfig()
                end,
            })
        end)
        -- MENU 11: Fast Drop & Recycle
        BuildUiSection("Tab:FastDropRecycle", function()
            local _bam = FastHelpersSection:Tab({
                Title = "Fast Drop & Recycle",
                Icon = "solar:square-transfer-horizontal-bold",
                IconColor = _Xt,
                IconShape = "Square",
                Border = true,
            })
            UiState.tabs.fastdroprecycle = _bam
            _bam:Section({ Title = "Fast Drop & Fast Recycle / Trash (0ms Dialog Bypass)" })
            _bam:Toggle({
                Title = "Fast Drop (Click Drop = Instant Drop Without Dialog)",
                Desc = ("Automatically bypass the quantity popup when clicking Drop in yo" .. "ur Backpack."),
                Value = Config.fastDrop,
                Callback = function(_ban)
                    Config.fastDrop = _ban
                    SaveConfig()
                    ShowNotification("Fast Drop " .. (_ban and "ENABLED!" or "DISABLED."))
                end,
            })
            _bam:Input({
                Title = "Fast Drop Amount (0 = Drop All)",
                Desc = ("Set to 0 to instantly drop the entire stack of the selected item" .. "."),
                Value = tostring(Config.fastDropCount or 0),
                Placeholder = "0 = All",
                Callback = function(_bao)
                    local _bap = tonumber(_bao)
                    Config.fastDropCount = (_bap and _bap >= 0) and math.floor(_bap) or 0
                    SaveConfig()
                    ShowNotification("Fast Drop Amount set to: " .. (Config.fastDropCount == 0 and "ALL" or tostring(Config.fastDropCount)))
                end,
            })
            _bam:Space()
            _bam:Toggle({
                Title = "Fast Recycle / Trash (Click Recycle = Instant Trash)",
                Desc = ("Automatically bypass the confirmation popup when clicking Recycl" .. "e in your Backpack."),
                Value = Config.fastRecycle,
                Callback = function(_baq)
                    Config.fastRecycle = _baq
                    SaveConfig()
                    ShowNotification("Fast Recycle " .. (_baq and "ENABLED!" or "DISABLED."))
                end,
            })
            _bam:Input({
                Title = "Fast Recycle Amount (0 = Recycle All)",
                Desc = ("Set to 0 to instantly recycle the entire stack of the selected i" .. "tem."),
                Value = tostring(Config.fastRecycleCount or 0),
                Placeholder = "0 = All",
                Callback = function(_bar)
                    local _bas = tonumber(_bar)
                    Config.fastRecycleCount = (_bas and _bas >= 0) and math.floor(_bas) or 0
                    SaveConfig()
                    ShowNotification("Fast Recycle Amount set to: " .. (Config.fastRecycleCount == 0 and "ALL" or tostring(Config.fastRecycleCount)))
                end,
            })
        end)
        -- MENU 12: Backpack (Recycle & Locks)
        BuildUiSection("Tab:Bag", function()
            local _bat = InventoryWorldSection:Tab({
                Title = "Backpack (Recycle & Locks)",
                Icon = "solar:check-square-bold",
                IconColor = _Xv,
                IconShape = "Square",
                Border = true,
            })
            UiState.tabs.bag = _bat
            local _bau = _bat:Paragraph({
                Title = "Backpack Management Status",
                Desc = "Loading..."
            })
            task.spawn(function()
                while IsSessionAlive() and task.wait(0.8) do
                    pcall(function()
                        local _bav = {}
                        for _baw, _bax in ipairs(Config.trashList or {}) do
                            table.insert(_bav, GetItemName(_bax) .. " [" .. _bax .. "]")
                        end
                        UpdateUiText(_bau, "Last Action: " .. BackpackManager.status, string.format(("Total Recycled: %d items | Locks Converted: %d times\nAuto-Recycl" .. "e List: %s"), BackpackManager.recycled, BackpackManager.converted, #_bav > 0 and table.concat(_bav, ", ") or "(None)"))
                    end)
                end
            end)
            _bat:Toggle({
                Title = "Enable Auto Recycle (Auto Trash Items)",
                Value = Config.trashOn,
                Callback = function(_bay)
                    Config.trashOn = _bay;
                    SaveConfig()
                end,
            })
            _bat:Input({
                Title = "Add / Remove Item ID from Auto-Recycle",
                Desc = ("Enter an Item ID (e.g. 2 for Dirt) to toggle it in the Auto-Recy" .. "cle list."),
                Placeholder = "Enter Item ID...",
                Callback = function(_baz)
                    local _baA = tonumber(_baz)
                    if not _baA or _baA <= 0 then
                        return
                    end
                    _baA = math.floor(_baA)
                    local _baB = table.find(Config.trashList, _baA)
                    if _baB then
                        table.remove(Config.trashList, _baB)
                        ShowNotification(GetItemName(_baA) .. " removed from Auto-Recycle list.")
                    else
                        table.insert(Config.trashList, _baA)
                        ShowNotification(GetItemName(_baA) .. " added to Auto-Recycle list.")
                    end
                    SaveConfig()
                end,
            })
            _bat:Slider({
                Title = "Recycle When Count >=",
                IsTooltip = true,
                Step = 5,
                Value = {
                    Min = 5,
                    Max = 200,
                    Default = math.clamp(Config.trashAt, 5, 200)
                },
                Callback = function(_baC)
                    Config.trashAt = math.floor(tonumber(_baC) or 150);
                    SaveConfig()
                end,
            })
            _bat:Slider({
                Title = "Keep Amount in Backpack",
                IsTooltip = true,
                Step = 5,
                Value = {
                    Min = 0,
                    Max = 195,
                    Default = math.clamp(Config.trashKeep, 0, 195)
                },
                Callback = function(_baD)
                    Config.trashKeep = math.floor(tonumber(_baD) or 0);
                    SaveConfig()
                end,
            })
            _bat:Space()
            _bat:Section({ Title = "Locks & Quick Drop" })
            _bat:Toggle({
                Title = "Auto Convert Locks (100 WL -> 1 DL, 100 DL -> 1 BGL)",
                Value = Config.convertLockOn,
                Callback = function(_baE)
                    Config.convertLockOn = _baE;
                    SaveConfig()
                end,
            })
            local _baF = "100"
            _bat:Input({
                Title = "World Lock Drop Amount",
                Value = "100",
                Placeholder = "Amount (1-10000)",
                Callback = function(_baG)
                    _baF = _baG
                end,
            })
            _bat:Button({
                Title = "Drop World Locks Now",
                Color = Color3.fromHex("#305dff"),
                Justify = "Center",
                Callback = function()
                    local _baH = tonumber(_baF)
                    if _baH and _baH >= 1 and _baH <= MaxDropAmount then
                        task.spawn(DropLocks, math.floor(_baH))
                    else
                        ShowNotification("Invalid WL amount!")
                    end
                end,
            })
        end)
        -- MENU 13: GrowScan 9000
        BuildUiSection("Tab:GrowScan", function()
            local _baI = InventoryWorldSection:Tab({
                Title = "GrowScan 9000",
                Icon = "solar:info-square-bold",
                IconColor = _Xw,
                IconShape = "Square",
                Border = true,
            })
            UiState.tabs.scan = _baI
            local _baJ = _baI:Paragraph({
                Title = "GrowScan 9000",
                Desc = ("Click the button below to scan all blocks, trees, and floating d" .. "rops in the world.")
            })
            local function _baK()
                local _baL = BuildWorldScanReport()
                if not _baL then
                    UpdateUiText(_baJ, "GrowScan", "World not detected.")
                    return
                end
                local function _baM(_baN, _baO)
                    local _baP = {}
                    for _baQ, _baR in pairs(_baN) do
                        table.insert(_baP, {
                            id = _baQ,
                            n = _baR
                        })
                    end
                    table.sort(_baP, function(_baS, _baT)
                        return _baS.n > _baT.n
                    end)
                    local _baU = {}
                    for _baV = 1, math.min(_baO or 12, #_baP) do
                        table.insert(_baU, string.format("• %s [%d] x%d", GetItemName(_baP[_baV].id), _baP[_baV].id, _baP[_baV].n))
                    end
                    return #_baU > 0 and table.concat(_baU, "\n") or "Empty"
                end
                local _baW = {}
                for _baX, _baY in pairs(_baL.trees) do
                    local _baZ = _baY.nextIn and string.format(" (ready in %ds)", math.max(0, math.ceil(_baY.nextIn))) or ""
                    table.insert(_baW, string.format("• %s: %d ready | %d growing%s", GetItemName(_baX), _baY.ready, _baY.growing, _baZ))
                end
                local _bba = table.concat({
                    string.format("World: %s (%dx%d)", GetWorldName(), _baL.w, _baL.h),
                    string.format("FG: %d | BG: %d | Floating: %d (%d stacks)", _baL.totalFg, _baL.totalBg, _baL.totalDrops, _baL.piles),
                    string.format("Trees: %d ready | %d growing", _baL.readyTrees, _baL.growingTrees),
                    "\n[TREES IN WORLD]:\n" .. (#_baW > 0 and table.concat(_baW, "\n") or "No trees"),
                    "\n[FLOATING DROPS]:\n" .. _baM(_baL.drops, 10),
                    "\n[WORLD BLOCKS]:\n" .. _baM(_baL.fg, 12),
                }, "\n")
                UpdateUiText(_baJ, "GrowScan Results (" .. os.date("%H:%M:%S") .. ")", _bba)
            end
            _baI:Button({
                Title = "Scan World Now",
                Color = Color3.fromHex("#305dff"),
                Justify = "Center",
                Callback = _baK,
            })
            _baI:Button({
                Title = "Open Native In-Game GrowScan UI",
                Justify = "Center",
                Callback = function()
                    if not OpenNativeGrowScan() then
                        ShowNotification("Native GrowScan UI is unavailable.")
                    end
                end,
            })
        end)
        -- MENU 14: Teleport & Positions
        BuildUiSection("Tab:Pos", function()
            local _bbb = InventoryWorldSection:Tab({
                Title = "Teleport & Positions",
                Icon = "solar:hamburger-menu-bold",
                IconColor = _Xu,
                IconShape = "Square",
                Border = true,
            })
            UiState.tabs.pos = _bbb
            local _bbc = ""
            _bbb:Input({
                Title = "Target World Name",
                Placeholder = "Enter world name...",
                Callback = function(_bbd)
                    _bbc = TrimText(_bbd or "")
                end,
            })
            _bbb:Button({
                Title = "Warp to World",
                Color = Color3.fromHex("#305dff"),
                Justify = "Center",
                Callback = function()
                    if _bbc ~= "" then
                        task.spawn(WarpToWorld, _bbc)
                    else
                        ShowNotification("Enter a world name first!")
                    end
                end,
            })
            _bbb:Space()
            _bbb:Section({ Title = "Saved Positions (Pos 1 / Pos 2)" })
            for _bbe = 1, 2 do
                local _bbf = _bbb:Paragraph({
                    Title = "Position " .. _bbe,
                    Desc = "Not set"
                })
                local function _bbg()
                    local _bbh = Config["pos" .. _bbe]
                    if type(_bbh) == "table" and type(_bbh.x) == "number" then
                        UpdateUiText(_bbf, "Saved Pos " .. _bbe, string.format("Tile (%d, %d) in World %s", _bbh.x, _bbh.y, _bbh.world or "-"))
                    else
                        UpdateUiText(_bbf, "Position " .. _bbe, "Not set")
                    end
                end
                table.insert(UiState.refreshers, _bbg)
                _bbg()
                local _bbi = _bbb:Group({})
                _bbi:Button({
                    Title = "Save Pos " .. _bbe,
                    Justify = "Center",
                    Callback = function()
                        SavePosition(_bbe);
                        SyncFeatureControls()
                    end
                })
                _bbi:Button({
                    Title = "Teleport (win" .. _bbe .. ")",
                    Justify = "Center",
                    Callback = function()
                        task.spawn(GoToSavedPosition, _bbe)
                    end
                })
            end
        end)
        -- MENU 15: Vending Machine
        BuildUiSection("Tab:Vending", function()
            local _bbj = InventoryWorldSection:Tab({
                Title = "Vending Machine",
                Icon = "solar:folder-with-files-bold",
                IconColor = _Xt,
                IconShape = "Square",
                Border = true,
            })
            UiState.tabs.vending = _bbj
            local _bbk = _bbj:Paragraph({
                Title = "Vending Bot Status",
                Desc = "Loading..."
            })
            task.spawn(function()
                while IsSessionAlive() and task.wait(0.8) do
                    pcall(function()
                        UpdateUiText(_bbk, "Status: " .. VendingBot.status, string.format("Mode: %s\nStocked: %d | Emptied: %d", Config.vendMode, VendingBot.stocked, VendingBot.taken))
                    end)
                end
            end)
            _bbj:Toggle({
                Title = "Enable Vending Machine Bot",
                Value = VendingBot.on,
                Callback = function(_bbl)
                    if _bbl then
                        VendingBot.Start()
                    else
                        VendingBot.Stop()
                    end
                end,
            })
            local _bbm = {
                ["Restock from Backpack/Drops"] = "Isi stock dari drop",
                ["Empty Until Depleted"] = "Kosongkan sampai habis",
            }
            local _bbn = {
                ["Isi stock dari drop"] = "Restock from Backpack/Drops",
                ["Kosongkan sampai habis"] = "Empty Until Depleted",
            }
            _bbj:Dropdown({
                Title = "Vending Mode",
                Values = {
                    "Restock from Backpack/Drops",
                    "Empty Until Depleted"
                },
                Value = _bbn[Config.vendMode] or "Restock from Backpack/Drops",
                Callback = function(_bbo)
                    Config.vendMode = _bbm[_bbo] or "Isi stock dari drop"
                    SaveConfig()
                end,
            })
            _bbj:Input({
                Title = "Drop World When Emptying (WORLD or WORLD:DOOR)",
                Value = Config.vendPoint,
                Placeholder = "e.g. STORAGE or STORAGE:1",
                Callback = function(_bbp)
                    Config.vendPoint = TrimText(_bbp or "");
                    SaveConfig()
                end,
            })
            _bbj:Button({
                Title = "SetPos Drop for Emptied Vending Items",
                Justify = "Center",
                Callback = function()
                    local _bbq, _bbr = GetCurrentTile()
                    if not _bbq then
                        ShowNotification("Position not detected!");
                        return
                    end
                    Config.vendDropX, Config.vendDropY = _bbq, _bbr
                    SaveConfig()
                    ShowNotification(string.format("Vending Drop Position saved at (%d, %d)", _bbq, _bbr))
                end,
            })
        end)
        -- MENU 16: Guard & Reconnect
        BuildUiSection("Tab:Guard", function()
            local _bbs = SafetyUtilitySection:Tab({
                Title = "Guard & Reconnect",
                Icon = "solar:info-square-bold",
                IconColor = _Xx,
                IconShape = "Square",
                Border = true,
            })
            UiState.tabs.guard = _bbs
            local _bbt = _bbs:Paragraph({
                Title = "Guard & Reconnect Status",
                Desc = "Idle"
            })
            task.spawn(function()
                while IsSessionAlive() and task.wait(0.6) do
                    pcall(function()
                        UpdateUiText(_bbt, "Guard: " .. Guard.status .. " | Reconnect: " .. Reconnect.status, string.format(("Players in World: %s\nStaff in Server: %s\nDetections: %d | Rejoin" .. "s: %d"), Guard.hereText, Guard.staffServerText, Guard.detected, Reconnect.count))
                    end)
                end
            end)
            AddFeatureToggle(_bbs, "Enable Anti-Mod Guard", ("Monitor Moderators / Developers (including undercover) or other " .. "players entering the world."), "guard")
            local _bbu = {
                ["Staff Only (Mod/Dev)"] = "Staff (Mod/Dev)",
                ["All Players"] = "Semua pemain",
            }
            local _bbv = {
                ["Staff (Mod/Dev)"] = "Staff Only (Mod/Dev)",
                ["Semua pemain"] = "All Players",
            }
            _bbs:Dropdown({
                Title = "Detection Target",
                Values = {
                    "Staff Only (Mod/Dev)",
                    "All Players"
                },
                Value = _bbv[Config.guardWho] or "Staff Only (Mod/Dev)",
                Callback = function(_bbw)
                    Config.guardWho = _bbu[_bbw] or "Staff (Mod/Dev)"
                    SaveConfig()
                end,
            })
            _bbs:Toggle({
                Title = "Pause All Active Bots on Detection",
                Value = Config.guardStopAll,
                Callback = function(_bbx)
                    Config.guardStopAll = _bbx;
                    SaveConfig()
                end,
            })
            _bbs:Toggle({
                Title = "Immediately Leave World on Detection",
                Value = Config.guardLeave,
                Callback = function(_bby)
                    Config.guardLeave = _bby;
                    SaveConfig()
                end,
            })
            _bbs:Toggle({
                Title = "Auto Resume When Safe",
                Value = Config.guardAutoBack,
                Callback = function(_bbz)
                    Config.guardAutoBack = _bbz;
                    SaveConfig()
                end,
            })
            _bbs:Slider({
                Title = "Return Wait Time (seconds)",
                IsTooltip = true,
                Step = 5,
                Value = {
                    Min = 15,
                    Max = 300,
                    Default = math.clamp(Config.guardBackSec, 15, 300)
                },
                Callback = function(_bbA)
                    Config.guardBackSec = tonumber(_bbA) or 60;
                    SaveConfig()
                end,
            })
            _bbs:Button({
                Title = "Whitelist Players Currently in World",
                Justify = "Center",
                Callback = function()
                    local _bbB = Guard.AllowCurrentPlayers()
                    ShowNotification(_bbB .. " players in this world added to whitelist.")
                end,
            })
            _bbs:Space()
            _bbs:Section({ Title = "Auto Reconnect (World Closed & Server Disconnect)" })
            AddFeatureToggle(_bbs, "Enable Auto Reconnect", ("Re-enter the world & resume bot activities if kicked or disconne" .. "cted."), "autorejoin")
            _bbs:Toggle({
                Title = "Re-Enter When World Closes / Kicked",
                Value = Config.reconnectWorld,
                Callback = function(_bbC)
                    Config.reconnectWorld = _bbC;
                    SaveConfig()
                end,
            })
            _bbs:Toggle({
                Title = "Always Stay in World (Auto Enter from Menu)",
                Value = Config.reconnectKeep,
                Callback = function(_bbD)
                    Config.reconnectKeep = _bbD;
                    SaveConfig()
                end,
            })
            _bbs:Toggle({
                Title = "Auto Teleport on Server Disconnect",
                Value = Config.reconnectServer,
                Callback = function(_bbE)
                    Config.reconnectServer = _bbE;
                    SaveConfig()
                end,
            })
            _bbs:Input({
                Title = "Reconnect Target World (Empty = Last World)",
                Placeholder = "WORLDNAME",
                Callback = function(_bbF)
                    Config.targetWorld = TrimText(_bbF or "");
                    SaveConfig()
                end,
            })
        end)
        -- MENU 17: Auto Chat & Bonus
        BuildUiSection("Tab:Bonus", function()
            local _bbG = SafetyUtilitySection:Tab({
                Title = "Auto Chat & Bonus",
                Icon = "solar:file-text-bold",
                IconColor = _Xt,
                IconShape = "Square",
                Border = true,
            })
            UiState.tabs.bonus = _bbG
            local _bbH = _bbG:Paragraph({
                Title = "Auto Chat & Bonus Status",
                Desc = "Loading..."
            })
            task.spawn(function()
                while IsSessionAlive() and task.wait(0.8) do
                    pcall(function()
                        UpdateUiText(_bbH, string.format("Auto Chat: %s (Sent: %d)", AutoChat.on and "ACTIVE" or "OFF", AutoChat.sent), string.format("Configured Message: %s\nLast Sent: %s\nQuests: %s\nRedeem: %s", Config.chatText ~= "" and Config.chatText or "(Not set)", AutoChat.last, BonusManager.questText, BonusManager.codeText))
                    end)
                end
            end)
            _bbG:Section({ Title = "Auto Chat / Spammer (Single Message)" })
            AddFeatureToggle(_bbG, "Enable Auto Chat", ("Automatically send your configured message to the world chat cha" .. "nnel."), "autochat")
            _bbG:Input({
                Title = "Auto Chat Message",
                Value = Config.chatText,
                Placeholder = "Type the message to send...",
                Callback = function(_bbI)
                    Config.chatText = TrimText(_bbI or "")
                    SaveConfig()
                end,
            })
            _bbG:Slider({
                Title = "Chat Interval (seconds)",
                IsTooltip = true,
                Step = 1,
                Value = {
                    Min = 3,
                    Max = 120,
                    Default = math.clamp(Config.chatInterval, 3, 120)
                },
                Callback = function(_bbJ)
                    Config.chatInterval = tonumber(_bbJ) or 6;
                    SaveConfig()
                end,
            })
            _bbG:Button({
                Title = "Send Chat Message Once Now",
                Justify = "Center",
                Callback = function()
                    AutoChat.SendNext()
                end,
            })
            _bbG:Space()
            _bbG:Section({ Title = "Quests & Promo Codes" })
            AddFeatureToggle(_bbG, "Auto Claim Completed Quests", "Automatically check and claim finished quests every 30s.", "autoquest")
            _bbG:Toggle({
                Title = "Auto Redeem Active Promo Codes",
                Value = Config.bonusAutoRedeem,
                Callback = function(_bbK)
                    Config.bonusAutoRedeem = _bbK
                    if _bbK then
                        BonusManager.nextCode = 0
                    end
                    SaveConfig()
                end,
            })
            local _bbL = _bbG:Group({})
            _bbL:Button({
                Title = "Check Quests Now",
                Justify = "Center",
                Callback = function()
                    task.spawn(ShowQuestInfo)
                end,
            })
            _bbL:Button({
                Title = "Redeem All Active Codes",
                Justify = "Center",
                Callback = function()
                    task.spawn(function()
                        BonusManager.CheckCodes()
                        ShowNotification(BonusManager.codeText, "Promo Codes")
                    end)
                end,
            })
        end)
        -- MENU 18: Cosmetics & Roles
        BuildUiSection("Tab:Visual", function()
            local _bbM = SafetyUtilitySection:Tab({
                Title = "Cosmetics & Roles",
                Icon = "solar:check-square-bold",
                IconColor = _Xw,
                IconShape = "Square",
                Border = true,
            })
            UiState.tabs.visual = _bbM
            _bbM:Section({ Title = "Client-Side Visual Wearables" })
            local _bbN = {}
            local _bbO
            _bbM:Input({
                Title = "Search Wearable / Cosmetic",
                Placeholder = "e.g. Rayman, Wings,Katana...",
                Callback = function(_bbP)
                    _bbN = {}
                    local _bbQ = {}
                    local _bbR = TrimText(_bbP):lower()
                    for _bbS, _bbT in ipairs(GetWearableCatalog()) do
                        if _bbR == "" or _bbT.lower:find(_bbR, 1, true) then
                            local _bbU = string.format("%s [%d] (%s)", _bbT.name, _bbT.id, _bbT.slot)
                            _bbN[_bbU] = _bbT.id
                            table.insert(_bbQ, _bbU)
                            if #_bbQ >= 30 then
                                break
                            end
                        end
                    end
                    if #_bbQ == 0 then
                        _bbQ = { "No matching items" }
                    end
                    if _bbO and _bbO.Refresh then
                        pcall(function()
                            _bbO:Refresh(_bbQ)
                        end)
                    end
                end,
            })
            _bbO = _bbM:Dropdown({
                Title = "Equip / Unequip Visual Item",
                Values = { "Search for an item above..." },
                Callback = function(_bbV)
                    local _bbW = _bbN[_bbV]
                    if _bbW then
                        ToggleVisualItem(_bbW)
                        ShowNotification("Toggled visual item: " .. GetItemName(_bbW))
                    end
                end,
            })
            _bbM:Button({
                Title = "Reset All Visual Wearables",
                Justify = "Center",
                Callback = ResetVisualItems,
            })
            _bbM:Space()
            _bbM:Section({ Title = "Watermark & Title Role" })
            _bbM:Toggle({
                Title = "Custom Animated NameTag Watermark",
                Value = Config.customWatermark,
                Callback = function(_bbX)
                    Config.customWatermark = _bbX;
                    SaveConfig()
                end,
            })
            _bbM:Input({
                Title = "Custom Watermark Text",
                Value = Config.watermarkText,
                Placeholder = "ANCH HUB",
                Callback = function(_bbY)
                    local _bbZ = TrimText(_bbY or "")
                    if _bbZ ~= "" then
                        Config.watermarkText = _bbZ;
                        SaveConfig()
                    end
                end,
            })
            local _bcb = _bbM:Dropdown({
                Title = "Select Owned Title / Role",
                Values = GetOwnedRoles(),
                Value = Config.selectedRole or "none",
                Callback = function(_bca)
                    Config.selectedRole = _bca or "none"
                    SaveConfig()
                    PickRole(Config.selectedRole)
                end,
            })
            _bbM:Button({
                Title = "Refresh Owned Roles",
                Justify = "Center",
                Callback = function()
                    if _bcb and _bcb.Refresh then
                        pcall(function()
                            _bcb:Refresh(GetOwnedRoles())
                        end)
                        ShowNotification("Owned roles list refreshed!")
                    end
                end,
            })
        end)
        -- MENU 19: Webhook & Settings
        BuildUiSection("Tab:Settings", function()
            local _bcc = SystemSettingsSection:Tab({
                Title = "Webhook & Settings",
                Icon = "solar:folder-with-files-bold",
                IconColor = _Xv,
                IconShape = "Square",
                Border = true,
            })
            UiState.tabs.settings = _bcc
            local _bcd = _bcc:Paragraph({
                Title = "Discord Webhook Status",
                Desc = "Last Status: -"
            })
            task.spawn(function()
                while IsSessionAlive() and task.wait(1) do
                    pcall(function()
                        UpdateUiText(_bcd, "Discord Webhook: " .. (Config.webhookOn and "ENABLED" or "DISABLED"), "Delivery Status: " .. tostring(Webhook.Status))
                    end)
                end
            end)
            _bcc:Toggle({
                Title = "Enable Discord Webhook Notifications",
                Value = Config.webhookOn,
                Callback = function(_bce)
                    Config.webhookOn = _bce;
                    SaveConfig()
                end,
            })
            _bcc:Input({
                Title = "Discord Webhook URL",
                Value = Config.webhookUrl,
                Placeholder = "https://discord.com/api/webhooks/...",
                Callback = function(_bcf)
                    Config.webhookUrl = TrimText(_bcf or "");
                    SaveConfig()
                end,
            })
            _bcc:Slider({
                Title = "Periodic Session Report Interval (minutes, 0 = Off)",
                IsTooltip = true,
                Step = 5,
                Value = {
                    Min = 0,
                    Max = 120,
                    Default = math.clamp(Config.webhookReportMin, 0, 120)
                },
                Callback = function(_bcg)
                    Config.webhookReportMin = tonumber(_bcg) or 0;
                    SaveConfig()
                end,
            })
            _bcc:Button({
                Title = "Send Test Webhook",
                Color = Color3.fromHex("#305dff"),
                Justify = "Center",
                Callback = function()
                    if not Webhook.Valid(Config.webhookUrl) then
                        ShowNotification("Invalid Discord Webhook URL!")
                    else
                        local _bch = Config.webhookOn
                        Config.webhookOn = true
                        Webhook.Send("test", "Test connection from **ANCH Hub | GrowBlox**! World: `" .. GetWorldName() .. "`")
                        Config.webhookOn = _bch
                        ShowNotification("Test message queued!")
                    end
                end,
            })
            _bcc:Space()
            _bcc:Section({ Title = "Session & Auto-Execute on Teleport" })
            _bcc:Toggle({
                Title = "Auto-Restore Enabled Features on Startup",
                Value = Config.autoRestore,
                Callback = function(_bci)
                    Config.autoRestore = _bci;
                    SaveConfig()
                end,
            })
            _bcc:Toggle({
                Title = "Auto-Reload Script on World Teleport",
                Value = Config.autoReload,
                Callback = function(_bcj)
                    Config.autoReload = _bcj;
                    SaveConfig()
                end,
            })
            _bcc:Input({
                Title = "Script Reload URL (Optional for queue_on_teleport)",
                Value = Config.scriptUrl,
                Placeholder = "https://raw.githubusercontent.com/...",
                Callback = function(_bck)
                    Config.scriptUrl = TrimText(_bck or "");
                    SaveConfig()
                end,
            })
            local _bcl = _bcc:Group({})
            _bcl:Button({
                Title = "Install Loader to Autoexec",
                Justify = "Center",
                Callback = InstallAutoexecLoader,
            })
            _bcl:Button({
                Title = "Rejoin Current Server",
                Justify = "Center",
                Callback = RejoinCurrentServer,
            })
        end)
        Boot.WindowReady = true
        Boot.BringUiToFront(WindUI)
        if type(HubWindow.Open) == "function" then pcall(HubWindow.Open, HubWindow) end
        pcall(function()
            HubWindow:SetToggleKey(Enum.KeyCode.RightControl)
        end)
        do
            (function()
                local function _bcm(_bcn, _bco)
                    if not _bcn or _bcn == "" then
                        return not _bco
                    end
                    _bcn = _bcn:lower()
                    if _bcn == "on" or _bcn == "1" or _bcn == "true" then
                        return true
                    end
                    if _bcn == "off" or _bcn == "0" or _bcn == "false" then
                        return false
                    end
                    return not _bco
                end
                -- [29] PERINTAH CHAT: /af, /ah, /adf, /factory, /tp, /pos, dan lainnya.
                local function HandleChatCommand(_bcq)
                    if type(_bcq) ~= "string" then
                        return false
                    end
                    local _bcr = Config.prefix or "/"
                    if _bcq:sub(1, #_bcr) ~= _bcr then
                        return false
                    end
                    local _bcs = TrimText(_bcq:sub(#_bcr + 1))
                    if _bcs == "" then
                        return false
                    end
                    local _bct, _bcu = _bcs:match("^(%S+)%s*(.*)$")
                    if not _bct then
                        return false
                    end
                    _bct = _bct:lower()
                    if _bct == "wld" or _bct == "wd" then
                        task.spawn(DropLocks, tonumber(_bcu))
                        return true
                    elseif _bct == "tp" or _bct == "warp" then
                        task.spawn(WarpToWorld, _bcu)
                        return true
                    elseif _bct == "pos1" then
                        SavePosition(1);
                        return true
                    elseif _bct == "pos2" then
                        SavePosition(2);
                        return true
                    elseif _bct == "win1" or _bct == "w1" then
                        task.spawn(GoToSavedPosition, 1, tonumber(_bcu));
                        return true
                    elseif _bct == "win2" or _bct == "w2" then
                        task.spawn(GoToSavedPosition, 2, tonumber(_bcu));
                        return true
                    elseif _bct == "pos" then
                        ShowPositions();
                        return true
                    elseif _bct == "rejoin" or _bct == "rj" then
                        RejoinCurrentServer();
                        return true
                    elseif _bct == "noclip" then
                        SetFeatureEnabled("noclip", _bcm(_bcu, ManualNoclipEnabled));
                        return true
                    elseif _bct == "unlimitedjump" or _bct == "uj" then
                        SetFeatureEnabled("ujump", _bcm(_bcu, UnlimitedJumpEnabled));
                        return true
                    elseif _bct == "blink" then
                        SetFeatureEnabled("blink", _bcm(_bcu, SkinBlinkEnabled));
                        return true
                    elseif _bct == "longhand" or _bct == "lh" then
                        local _bcv = tonumber(_bcu)
                        if _bcv then
                            Config.longhandRange = _bcv;
                            SaveConfig();
                            SetFeatureEnabled("longhand", true)
                        else
                            SetFeatureEnabled("longhand", _bcm(_bcu, LonghandEnabled))
                        end
                        return true
                    elseif _bct == "afk" then
                        SetFeatureEnabled("antiafk", _bcm(_bcu, AntiAfkEnabled));
                        return true
                    elseif _bct == "autorejoin" or _bct == "arj" then
                        SetFeatureEnabled("autorejoin", _bcm(_bcu, Config.reconnectOn));
                        return true
                    elseif _bct == "af" or _bct == "autofarm" then
                        SetFeatureEnabled("autofarm", _bcm(_bcu, AutoFarm.on));
                        return true
                    elseif _bct == "ac" or _bct == "autoclear" then
                        SetFeatureEnabled("autoclear", _bcm(_bcu, AutoClear.on));
                        return true
                    elseif _bct == "ah" or _bct == "autoharvest" then
                        SetFeatureEnabled("autoharvest", _bcm(_bcu, Farmer.on));
                        return true
                    elseif _bct == "adf" or _bct == "autodf" then
                        SetFeatureEnabled("autodf", _bcm(_bcu, DirtFarm.on));
                        return true
                    elseif _bct == "as" or _bct == "autosplice" then
                        SetFeatureEnabled("autosplice", _bcm(_bcu, AutoSplice.on));
                        return true
                    elseif _bct == "pabrik" or _bct == "factory" then
                        SetFeatureEnabled("pabrik", _bcm(_bcu, SeedFactory.on));
                        return true
                    elseif _bct == "guard" or _bct == "penjaga" then
                        SetFeatureEnabled("guard", _bcm(_bcu, Guard.on));
                        return true
                    elseif _bct == "chat" or _bct == "autochat" then
                        SetFeatureEnabled("autochat", _bcm(_bcu, AutoChat.on));
                        return true
                    elseif _bct == "ctp" or _bct == "clicktp" then
                        SetFeatureEnabled("clicktp", _bcm(_bcu, Navigation.clickOn));
                        return true
                    elseif _bct == "god" then
                        SetFeatureEnabled("god", _bcm(_bcu, GodModeEnabled));
                        return true
                    elseif _bct == "lite" then
                        SetFeatureEnabled("lite", _bcm(_bcu, Config.liteMode));
                        return true
                    elseif _bct == "gs" or _bct == "growscan" then
                        OpenNativeGrowScan();
                        return true
                    elseif _bct == "blockid" or _bct == "bid" then
                        local _bcw = SearchBlocks(_bcu, 5)
                        if #_bcw == 0 then
                            ShowNotification("No blocks matching: " .. tostring(_bcu))
                        else
                            local _bcx = {}
                            for _bcy, _bcz in ipairs(_bcw) do
                                table.insert(_bcx, _bcz.name .. " [" .. _bcz.id .. "]")
                            end
                            ShowNotification(table.concat(_bcx, ", "), "Block ID Search")
                        end
                        return true
                    end
                    return false
                end
                local _bcA = {}
                local function _bcB(_bcC)
                    if _bcC:IsA("TextBox") and not _bcA[_bcC] then
                        _bcA[_bcC] = true
                        TrackConnection(_bcC.FocusLost:Connect(function(_bcD)
                            if _bcD and IsSessionAlive() then
                                HandleChatCommand(_bcC.Text)
                            end
                        end))
                    end
                end
                for _bcE, _bcF in ipairs(PlayerGui:GetDescendants()) do
                    _bcB(_bcF)
                end
                TrackConnection(PlayerGui.DescendantAdded:Connect(_bcB))
                TrackConnection(ClientPlayer.Chatted:Connect(HandleChatCommand))
            end)()
        end
    end)()
end
-- [28] PEMBERSIHAN: menghentikan bot, memulihkan hook, dan menghapus UI.
Session.Cleanup = function()
    Session.Alive = false
    ReleaseMovementKeys()
    MovementInput.active = false
    if AutoFarm.on then
        pcall(StopAutoFarm)
    end
    if AutoClear.on then
        pcall(AutoClear.Stop)
    end
    if Farmer.on then
        pcall(Farmer.Stop)
    end
    if DirtFarm.on then
        pcall(DirtFarm.Stop)
    end
    if AutoSplice.on then
        pcall(AutoSplice.Stop)
    end
    if SeedFactory.on then
        pcall(SeedFactory.Stop)
    end
    if AutoMove and AutoMove.Stop then
        pcall(AutoMove.Stop)
    end
    if VendingBot and VendingBot.Stop then
        pcall(VendingBot.Stop)
    end
    if Navigation.clickOn then
        pcall(Navigation.StopClick)
    end
    if SkinBlinkEnabled then
        pcall(StopSkinBlink)
    end
    if LonghandEnabled then
        pcall(StopLonghand)
    end
    if ManualNoclipEnabled then
        pcall(DisableManualNoclip)
    end
    if UnlimitedJumpEnabled then
        pcall(StopUnlimitedJump)
    end
    if GodModeEnabled then
        pcall(StopGodMode)
    end
    if AntiAfkEnabled then
        pcall(StopAntiAfk)
    end
    if Config.liteMode then
        pcall(LiteMode.Set, false)
    end
    if Session.RestoreWatermark then
        pcall(Session.RestoreWatermark)
    end
    if Session.RestoreFastWrench then
        pcall(Session.RestoreFastWrench)
    end
    if Session.RestoreFastBackpack then
        pcall(Session.RestoreFastBackpack)
    end
    for _bcG, _bcH in ipairs(Session.Connections) do
        pcall(function()
            _bcH:Disconnect()
        end)
    end
    table.clear(Session.Connections)
    if FloatingGridGui then
        pcall(function()
            FloatingGridGui:Destroy()
        end)
    end
    if FlyPadGui then
        pcall(function()
            FlyPadGui:Destroy()
        end)
    end
    if HubWindow and HubWindow.Destroy then
        pcall(function()
            HubWindow:Destroy()
        end)
    end
end
Boot.Task(function()
    Env.__ANCHHub_LoadingAt = nil
    IsBooting = false
    ShowNotification("ANCH HUB V1.3 Loaded! All features are ready.", "ANCH HUB", 4, true)
    StartAntiAfk()
    Refs.Scan(true)
    SessionStats.Reset()
    if Config.liteMode then
        LiteMode.Set(true)
    end
    TrackConnection(ClientPlayer.OnTeleport:Connect(function()
        IsBooting = false
        SaveConfig()
        pcall(QueueReloadOnTeleport)
    end))
    if Config.autoRestore then
        for _bcI, _bcJ in pairs(FeatureRegistry) do
            if Config.session[_bcI] and not _bcJ.noSession and not _bcJ.get() then
                pcall(_bcJ.set, true)
            end
        end
        if SyncFeatureControls then
            SyncFeatureControls()
        end
    end
    task.spawn(Reconnect.CheckStartup)
    task.spawn(SeedFactory.CheckStartup)
    task.spawn(AutoMove.CheckStartup)
    local _bcK = GetWorldName()
    while IsSessionAlive() do
        task.wait(1.5)
        local _bcL = GetWorldName()
        if _bcL ~= "" and _bcL ~= _bcK then
            _bcK = _bcL
            Refs.Scan(true)
        end
    end
end)

end

local ok, problem = xpcall(function()
    Boot.Prepare()
    StartHub()
    Boot.Finish()
end, Boot.Trace)
if not ok then Boot.ReportError(problem) end
