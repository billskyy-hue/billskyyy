-- Zekio Fast Break Test 1. Run AFTER the licensed Premium UI is ready.
-- Companion only: no remote discovery, no production file replacement.
-- Applies 190ms break / 0ms after-break for 30 seconds, then restores.
local G = (getgenv and getgenv()) or _G
if G.__ZekioFastBreakTest then G.__ZekioFastBreakTest.Close() end
local premium = G.__ZekioPremiumUI
assert(premium and premium.EngineReady and not premium.Closed,
    "Buka Zekio Premium dan tunggu menu siap sebelum menjalankan tes.")
local function find(title)
    for _, model in ipairs(premium.EngineControls or {}) do
        if model.Title == title and model.Kind == "Slider" and type(model.Callback) == "function" then
            return model
        end
    end
    error("Kontrol tidak cocok dengan versi tes: " .. title)
end
local speed = find("Speed Break (ms)")
local after = find("Jeda setelah hancur (ms)")
local players = game:GetService("Players")
local gui = Instance.new("ScreenGui")
gui.Name = "ZekioFastBreakTest"
gui.ResetOnSpawn = false
gui.DisplayOrder = 1000
gui.Parent = players.LocalPlayer:WaitForChild("PlayerGui")
local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(310, 180)
panel.Position = UDim2.new(0.5, -155, 0, 70)
panel.BackgroundColor3 = Color3.fromRGB(28, 23, 39)
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)
local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, -20, 0, 102)
label.Position = UDim2.fromOffset(10, 8)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.new(1, 1, 1)
label.Font = Enum.Font.Gotham
label.TextSize = 14
label.TextWrapped = true
label.Text = "FAST BREAK • TES TERPISAH\n190 ms / jeda setelah hancur 0 ms\nAtur target Farm, lalu mulai tes.\nTidak menjalankan Farm secara otomatis."
label.Parent = panel
local function button(text, x)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(135, 45)
    b.Position = UDim2.fromOffset(x, 120)
    b.BackgroundColor3 = Color3.fromRGB(139, 94, 218)
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.Text = text
    b.Parent = panel
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    return b
end
local start = button("TES 30 DETIK", 15)
local close = button("PULIHKAN / TUTUP", 160)
local test = { Active = false, Closed = false, Generation = 0 }
G.__ZekioFastBreakTest = test
local function restore()
    test.Generation += 1
    if not test.Active then return end
    test.Active = false
    -- Model values remain the user's normal settings. Respect edits made during test.
    local ok1, e1 = pcall(speed.Callback, speed.Value)
    local ok2, e2 = pcall(after.Callback, after.Value)
    if not ok1 or not ok2 then warn("Zekio restore: " .. tostring(e1 or e2)) end
    label.Text = "Tes selesai. Pengaturan normal dipulihkan.\nBandingkan jumlah blok yang hancur dalam 30 detik.\nKecepatan nyata belum diverifikasi oleh tes ini."
    start.Text = "ULANG TES"
end
function test.Close()
    if test.Closed then return end
    restore()
    test.Closed = true
    gui:Destroy()
    if G.__ZekioFastBreakTest == test then G.__ZekioFastBreakTest = nil end
end
close.MouseButton1Click:Connect(test.Close)
start.MouseButton1Click:Connect(function()
    if test.Active or test.Closed then return end
    if premium.Closed or G.__ZekioPremiumUI ~= premium then test.Close(); return end
    test.Active = true
    local ok, err = pcall(function() speed.Callback(190); after.Callback(0) end)
    if not ok then restore(); label.Text = "Tes gagal: " .. tostring(err); return end
    local generation = test.Generation
    start.Text = "TES AKTIF"
    task.spawn(function()
        local deadline = os.clock() + 30
        while test.Active and not test.Closed and generation == test.Generation do
            if premium.Closed or G.__ZekioPremiumUI ~= premium then test.Close(); return end
            local left = math.ceil(deadline - os.clock())
            if left <= 0 then restore(); return end
            label.Text = "FAST BREAK • " .. left .. " detik\n190 ms / jeda 0 ms\nJalankan Farm pada target uji.\nJangan simpan konfigurasi selama tes."
            task.wait(0.25)
        end
    end)
end)
return test
