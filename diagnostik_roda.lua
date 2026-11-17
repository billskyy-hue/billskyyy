-- Zekio: diagnostik lokal roulette, bukan fitur penebak angka.
-- Tidak mengirim permintaan, pesan, webhook, atau data keluar.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Input = game:GetService("UserInputService")
local player = Players.LocalPlayer
if not player then error("Masuk ke game sebelum menjalankan diagnostik.") end

local environment = _G
if type(getgenv) == "function" then
    local ok, result = pcall(getgenv)
    if ok and type(result) == "table" then environment = result end
end
local previous = environment.__ZekioWheelDiagnostic
if type(previous) == "table" and type(previous.Cleanup) == "function" then pcall(previous.Cleanup) end
local session = {closed=false, connections={}, remotes={}, records={}, names={}, ready=false, recording=false, generation=0}
environment.__ZekioWheelDiagnostic = session

local function make(class, props, parent)
    local instance = Instance.new(class)
    for key, value in pairs(props or {}) do instance[key] = value end
    instance.Parent = parent
    return instance
end
local function listen(signal, fn)
    local connection = signal:Connect(fn)
    session.connections[#session.connections+1] = connection
    return connection
end
local playerGui = player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui", 15)
if not playerGui then error("PlayerGui belum tersedia.") end
local gui = make("ScreenGui", {Name="ZekioWheelDiagnostic", ResetOnSpawn=false, IgnoreGuiInset=true, DisplayOrder=2000})
local guiParent = playerGui
if type(gethui) == "function" then
    local ok, result = pcall(gethui)
    if ok and result then guiParent = result end
end
local parentOK = pcall(function() gui.Parent=guiParent end)
if not parentOK then gui.Parent=playerGui end

local panel = make("Frame", {Name="Panel", Size=UDim2.new(.92,0,0,410), AnchorPoint=Vector2.new(.5,.5),
    Position=UDim2.fromScale(.5,.5), BackgroundColor3=Color3.fromRGB(25,23,34), BorderSizePixel=0, Active=true}, gui)
make("UISizeConstraint", {MaxSize=Vector2.new(390,410), MinSize=Vector2.new(260,410)}, panel)
local panelScale = 1
local viewportOK, viewport = pcall(function() return workspace.CurrentCamera.ViewportSize end)
if viewportOK and viewport.Y > 0 then panelScale = math.min(1, viewport.Y * .90 / 410) end
make("UIScale", {Scale=panelScale}, panel)
make("UICorner", {CornerRadius=UDim.new(0,12)}, panel)
local reopen = make("TextButton", {Name="Reopen", Text="BUKA DIAG", Visible=false,
    Size=UDim2.fromOffset(112,34), Position=UDim2.fromOffset(12,72),
    BackgroundColor3=Color3.fromRGB(104,76,156), TextColor3=Color3.fromRGB(255,255,255),
    Font=Enum.Font.GothamBold, TextSize=12, BorderSizePixel=0}, gui)
make("UICorner", {CornerRadius=UDim.new(0,7)}, reopen)
local function text(parent, name, value, pos, size, color, textSize)
    return make("TextLabel", {Name=name, BackgroundTransparency=1, Text=value, Position=pos, Size=size,
        TextColor3=color or Color3.fromRGB(245,242,255), Font=Enum.Font.Gotham, TextSize=textSize or 14,
        TextWrapped=true, TextXAlignment=Enum.TextXAlignment.Left, TextYAlignment=Enum.TextYAlignment.Center}, parent)
end
local function button(name, label, pos, size)
    local b = make("TextButton", {Name=name, Text=label, Position=pos, Size=size,
        BackgroundColor3=Color3.fromRGB(104,76,156), TextColor3=Color3.fromRGB(255,255,255),
        Font=Enum.Font.GothamBold, TextSize=13, TextWrapped=true, BorderSizePixel=0}, panel)
    make("UICorner", {CornerRadius=UDim.new(0,7)}, b)
    return b
end
text(panel, "Title", "Diagnostik Roda", UDim2.fromOffset(12,8), UDim2.new(1,-64,0,28), nil, 18)
local close = button("Close", "X", UDim2.new(1,-45,0,8), UDim2.fromOffset(33,28))
local status = text(panel, "Status", "Menyiapkan pemantau...", UDim2.fromOffset(12,38), UDim2.new(1,-24,0,36), Color3.fromRGB(190,180,215), 12)
local recordButton = button("Record", "MENYIAPKAN", UDim2.fromOffset(12,78), UDim2.new(.40,-16,0,36))
local numberBox = make("TextBox", {Name="Number", PlaceholderText="Angka roda", Text="", ClearTextOnFocus=false,
    Position=UDim2.new(.40,0,0,78), Size=UDim2.new(.27,-8,0,36), BackgroundColor3=Color3.fromRGB(55,50,69),
    TextColor3=Color3.fromRGB(255,255,255), PlaceholderColor3=Color3.fromRGB(190,185,200),
    Font=Enum.Font.Gotham, TextSize=13, BorderSizePixel=0}, panel)
make("UICorner", {CornerRadius=UDim.new(0,7)}, numberBox)
local analyseButton = button("Analyse", "ANALISA", UDim2.new(.67,0,0,78), UDim2.new(.33,-12,0,36))
local scroll = make("ScrollingFrame", {Name="ReportScroll", BackgroundColor3=Color3.fromRGB(18,17,24), BorderSizePixel=0,
    Position=UDim2.fromOffset(12,122), Size=UDim2.new(1,-24,0,228), ScrollBarThickness=5, CanvasSize=UDim2.fromOffset(0,0)}, panel)
make("UICorner", {CornerRadius=UDim.new(0,7)}, scroll)
local reportLabel = text(scroll, "Report", "1. Tekan REKAM.\n2. Pukul roulette sekali.\n3. Isi angka yang muncul.\n4. Tekan ANALISA, lalu SALIN.",
    UDim2.fromOffset(8,6), UDim2.new(1,-16,0,0), nil, 12)
reportLabel.TextYAlignment = Enum.TextYAlignment.Top
reportLabel.AutomaticSize = Enum.AutomaticSize.Y
local copyButton = button("Copy", "SALIN HASIL", UDim2.fromOffset(12,360), UDim2.new(1,-24,0,36))

local report = reportLabel.Text
local function setReport(value)
    report = value
    reportLabel.Text = value
    task.defer(function()
        if session.closed then return end
        local height = reportLabel.TextBounds.Y + 18
        scroll.CanvasSize = UDim2.fromOffset(0, math.max(228, height))
    end)
end
function session.Cleanup()
    if session.closed then return end
    session.closed = true
    session.recording = false
    session.generation += 1
    for _, connection in ipairs(session.connections) do pcall(function() connection:Disconnect() end) end
    table.clear(session.records)
    pcall(function() gui:Destroy() end)
    if environment.__ZekioWheelDiagnostic == session then environment.__ZekioWheelDiagnostic = nil end
end
listen(close.MouseButton1Click, session.Cleanup)
listen(gui.Destroying, session.Cleanup)
listen(reopen.MouseButton1Click, function() panel.Visible=true; reopen.Visible=false end)
listen(reportLabel:GetPropertyChangedSignal("TextBounds"), function()
    if not session.closed then scroll.CanvasSize=UDim2.fromOffset(0,math.max(228,reportLabel.TextBounds.Y+18)) end
end)

local function getPath(instance)
    local ok, value = pcall(instance.GetFullName, instance)
    return ok and tostring(value):sub(1,100) or tostring(instance.Name):sub(1,100)
end
local function getByteSnapshot(value)
    if type(buffer) ~= "table" or type(buffer.len) ~= "function" or type(buffer.readu8) ~= "function" then return nil end
    local ok, length = pcall(buffer.len, value)
    if not ok or type(length) ~= "number" then return nil end
    local result = {kind="buf", length=length, bytes={}}
    for offset=0,math.min(length,256)-1 do
        local readOK, byte = pcall(buffer.readu8, value, offset)
        if not readOK then break end
        result.bytes[#result.bytes+1] = byte
    end
    return result
end
local function getStringSnapshot(value)
    local result = {kind="str", length=#value, bytes={}}
    for i=1,math.min(#value,256) do result.bytes[i]=string.byte(value,i) end
    return result
end
local resultFields = {"result", "Result", "number", "Number", "outcome", "Outcome", "roll", "Roll", "wheel", "Wheel"}
local function capture(id, path, ...)
    if session.closed or not session.recording or os.clock() > session.deadline then return end
    local args = table.pack(...)
    local entry = {id=id, path=path, time=os.clock()-session.started, buffers={}, fields={}, types={}}
    for i=1,math.min(args.n,8) do
        local value = args[i]
        local kind = typeof(value)
        entry.types[#entry.types+1] = kind
        if kind == "buffer" and #entry.buffers < 2 then
            local snap = getByteSnapshot(value)
            if snap then entry.buffers[#entry.buffers+1] = snap end
        elseif type(value) == "string" and #entry.buffers < 2 then
            entry.buffers[#entry.buffers+1] = getStringSnapshot(value)
        elseif type(value) == "number" and value == math.floor(value) and value >= 0 and value <= 255 then
            entry.fields[#entry.fields+1] = {key="arg" .. i, value=value}
        elseif type(value) == "table" then
            for _, key in ipairs(resultFields) do
                local v = rawget(value, key)
                if type(v) == "number" and v == math.floor(v) and v >= 0 and v <= 255 then
                    entry.fields[#entry.fields+1] = {key=key, value=v}
                end
            end
        end
    end
    if #session.records >= 80 then table.remove(session.records,1) end
    session.records[#session.records+1] = entry
end
local remoteCount = 0
local function watchRemote(remote)
    if session.closed or session.remotes[remote] or remoteCount >= 80 then return end
    local ok, valid = pcall(function() return remote:IsA("RemoteEvent") or remote:IsA("UnreliableRemoteEvent") end)
    if not ok or not valid then return end
    local path = getPath(remote)
    local id = remoteCount + 1
    local attached, connection = pcall(function()
        return remote.OnClientEvent:Connect(function(...) capture(id, path, ...) end)
    end)
    if attached then
        remoteCount = id
        session.remotes[remote] = id
        session.connections[#session.connections+1] = connection
    end
end
listen(ReplicatedStorage.DescendantAdded, watchRemote)
listen(Input.InputBegan, function(input)
    if not session.recording or session.tapAt then return end
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        session.tapAt = os.clock()-session.started
    end
end)

local function netNames()
    if type(getgc) ~= "function" then return "getgc tidak tersedia" end
    local ok, objects = pcall(getgc, true)
    if not ok or type(objects) ~= "table" then return "getgc gagal" end
    local seen, names, count = {}, {}, 0
    for _, value in pairs(objects) do
        if session.closed then return "ditutup" end
        if type(value) == "table" then
            local events = rawget(value,"EVENTS")
            if type(events) == "table" and type(rawget(value,"tile")) == "table" and type(rawget(value,"act")) == "table" then
                for key in pairs(events) do
                    if type(key) == "string" and #key <= 60 and not seen[key] then
                        seen[key] = true; names[#names+1] = key
                    end
                end
            end
        end
        count += 1
        if count % 400 == 0 then task.wait() end
    end
    table.sort(names)
    if #names == 0 then return "Daftar Net.EVENTS belum ditemukan" end
    local priority = {"wheel", "spin", "roll", "roulette", "chat", "message", "text", "bubble", "system", "notice", "notify"}
    table.sort(names, function(a,b)
        local function relevant(value)
            local lower = string.lower(value)
            for _, term in ipairs(priority) do if lower:find(term,1,true) then return true end end
            return false
        end
        local aa, bb = relevant(a), relevant(b)
        if aa ~= bb then return aa end
        return a < b
    end)
    local output = {}
    for i=1,math.min(#names,40) do output[#output+1] = names[i] end
    return table.concat(output, ", ") .. (#names > 40 and (" (dan " .. (#names-40) .. " lainnya)") or "")
end
task.spawn(function()
    session.netInfo = netNames()
    if not session.closed and report:find("Net.EVENTS: masih diperiksa", 1, true) then
        setReport((report:gsub("Net%.EVENTS: masih diperiksa", function() return "Net.EVENTS: " .. session.netInfo end)))
    end
end)
task.spawn(function()
    local ok, nodes = pcall(ReplicatedStorage.GetDescendants, ReplicatedStorage)
    if ok then
        for i,node in ipairs(nodes) do
            if session.closed then return end
            watchRemote(node)
            if i % 150 == 0 then task.wait() end
        end
    end
    if session.closed then return end
    session.ready = true
    recordButton.Text = "REKAM"
    status.Text = remoteCount > 0 and ("Siap • " .. remoteCount .. " jalur. Tekan REKAM lalu pukul roda.")
        or "Tidak menemukan RemoteEvent. Hasil diagnostik mungkin kosong."
end)

listen(recordButton.MouseButton1Click, function()
    if not session.ready or session.closed then return end
    session.generation += 1
    local generation = session.generation
    table.clear(session.records)
    session.tapAt = nil
    session.recording = true
    session.started = os.clock()
    session.deadline = session.started + 8
    recordButton.Text = "MEREKAM..."
    status.Text = "Pukul roulette sekali sekarang. Rekam berhenti otomatis setelah 8 detik."
    setReport("Merekam petunjuk lokal. Setelah angka muncul, isi angkanya dan tekan ANALISA.")
    panel.Visible = false
    reopen.Visible = true
    task.delay(8, function()
        if session.closed or session.generation ~= generation then return end
        session.recording = false
        recordButton.Text = "REKAM LAGI"
        status.Text = "Selesai merekam. Isi angka yang muncul, lalu tekan ANALISA."
        panel.Visible = true
        reopen.Visible = false
    end)
end)

listen(analyseButton.MouseButton1Click, function()
    local expected = tonumber(numberBox.Text)
    if not expected or expected ~= math.floor(expected) or expected < 0 or expected > 255 then
        status.Text = "Isi angka roda dari 0 sampai 255 dulu."
        return
    end
    if not session.started then status.Text="Tekan REKAM lalu pukul roda dulu."; return end
    session.recording = false
    session.generation += 1
    recordButton.Text = "REKAM LAGI"
    local found, candidates = {}, {}
    for _, entry in ipairs(session.records) do
        local bits = {}
        for _, field in ipairs(entry.fields) do
            if field.value == expected then
                bits[#bits+1] = "field=" .. field.key
                local key = entry.path .. "|field|" .. field.key
                local d = math.abs(entry.time-(session.tapAt or 0))
                if not candidates[key] or d < candidates[key].distance then
                    candidates[key] = {distance=d, label="field=" .. field.key, path=entry.path}
                end
            end
        end
        for index, snap in ipairs(entry.buffers) do
            local marker = snap.kind .. index
            local offsets = {}
            for i,byte in ipairs(snap.bytes) do
                if byte == expected then
                    if #offsets < 8 then offsets[#offsets+1] = tostring(i-1) end
                    local key = entry.path .. "|" .. marker .. "|" .. (i-1)
                    local d = math.abs(entry.time-(session.tapAt or 0))
                    if not candidates[key] or d < candidates[key].distance then
                        candidates[key] = {distance=d, label=marker .. "@" .. (i-1), path=entry.path}
                    end
                end
            end
            if #offsets > 0 then
                bits[#bits+1] = marker .. "=" .. snap.length .. "B@" .. table.concat(offsets,",")
            end
            local digits, digitOffsets = tostring(expected), {}
            for i=1,#snap.bytes-#digits+1 do
                local match = true
                for j=1,#digits do
                    if snap.bytes[i+j-1] ~= string.byte(digits,j) then match=false; break end
                end
                if match then
                    if #digitOffsets < 8 then digitOffsets[#digitOffsets+1] = tostring(i-1) end
                    local key = entry.path .. "|" .. marker .. "|digits|" .. (i-1)
                    local d = math.abs(entry.time-(session.tapAt or 0))
                    if not candidates[key] or d < candidates[key].distance then
                        candidates[key] = {distance=d, label=marker .. ".digits@" .. (i-1), path=entry.path}
                    end
                end
            end
            if #digitOffsets > 0 then
                bits[#bits+1] = marker .. ".digits=" .. snap.length .. "B@" .. table.concat(digitOffsets,",")
            end
        end
        if #bits > 0 then
            local ref = session.tapAt or 0
            found[#found+1] = {distance=math.abs(entry.time-ref), time=entry.time-ref,
                value="R" .. entry.id .. " " .. table.concat(bits," | ")}
        end
    end
    table.sort(found, function(a,b) return a.distance < b.distance end)
    local lines = {"ZEKIO DIAG RODA v1", "Angka yang terlihat: " .. expected,
        "Jalur: " .. remoteCount .. " | paket: " .. #session.records,
        "Sentuhan: " .. (session.tapAt and string.format("%.3fs", session.tapAt) or "tidak terdeteksi"),
        "Net.EVENTS: " .. tostring(session.netInfo or "masih diperiksa")}
    if session.previousCandidates and session.previousExpected ~= expected then
        local common = {}
        for key, candidate in pairs(candidates) do
            if session.previousCandidates[key] then common[#common+1] = candidate end
        end
        table.sort(common, function(a,b) return a.distance < b.distance end)
        lines[#lines+1] = "Kecocokan dua angka berbeda: " .. #common .. " (masih perlu verifikasi)"
        for i=1,math.min(#common,12) do
            lines[#lines+1] = common[i].label .. " | " .. common[i].path
        end
    elseif session.previousCandidates then
        lines[#lines+1] = "Angka sama dengan percobaan sebelumnya; coba lagi sampai berbeda."
    else
        lines[#lines+1] = "Ulangi REKAM dan ANALISA sekali lagi dengan angka yang berbeda."
    end
    if not session.previousCandidates or session.previousExpected ~= expected then
        session.previousCandidates, session.previousExpected = candidates, expected
    end
    lines[#lines+1] = "Kemungkinan posisi byte (bukan bukti hasil):"
    for i=1,math.min(#found,14) do
        lines[#lines+1] = string.format("%+.3fs %s", found[i].time, found[i].value)
    end
    if #found == 0 then lines[#lines+1] = "Tidak ada kecocokan pada 256 byte awal / field hasil." end
    local used = {}
    for i=1,math.min(#found,14) do
        local id = found[i].value:match("^R(%d+)")
        if id then used[tonumber(id)] = true end
    end
    for _, entry in ipairs(session.records) do
        if used[entry.id] then
            lines[#lines+1] = "R" .. entry.id .. "=" .. entry.path
            used[entry.id] = nil
        end
    end
    table.clear(session.records)
    setReport(table.concat(lines,"\n"))
    status.Text = "Analisa selesai. Tekan SALIN HASIL dan kirim hasilnya."
end)
listen(copyButton.MouseButton1Click, function()
    if type(setclipboard) == "function" then
        local ok = pcall(setclipboard, report)
        status.Text = ok and "Hasil tersalin. Tempel di chat." or "Tidak bisa menyalin. Ambil screenshot hasil."
    else
        status.Text = "Salin tidak tersedia. Ambil screenshot hasil."
    end
end)
