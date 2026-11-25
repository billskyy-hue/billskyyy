-- BILL AUTO BREAKER
-- Own a World UI scaffold: automatic block discovery is not connected yet.
-- No game remotes are called and no blocks are modified by this build.

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

if not Players.LocalPlayer then return end

pcall(function()
    local old = CoreGui:FindFirstChild("BILL_AUTO_BREAKER")
    if old then old:Destroy() end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "BILL_AUTO_BREAKER"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local parented = false
pcall(function()
    if typeof(gethui) == "function" then gui.Parent = gethui(); parented = true end
end)
if not parented then gui.Parent = CoreGui end

local function make(className, props, parent)
    local obj = Instance.new(className)
    for k, v in pairs(props or {}) do obj[k] = v end
    obj.Parent = parent
    return obj
end
local function corner(obj, radius)
    make("UICorner", {CornerRadius = UDim.new(0, radius or 8)}, obj)
end
local function styleButton(btn, bg)
    btn.BackgroundColor3 = bg
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = Color3.fromRGB(245,245,250)
    btn.TextSize = 12
    corner(btn, 7)
end

local panel = make("Frame", {
    Name="Panel", Size=UDim2.fromOffset(320, 390),
    Position=UDim2.new(0.5,-160,0.5,-195),
    BackgroundColor3=Color3.fromRGB(18,18,23), BorderSizePixel=0,
}, gui)
corner(panel, 12)
make("UIStroke", {Color=Color3.fromRGB(65,65,82), Thickness=1}, panel)

local top = make("Frame", {Name="TopBar", Size=UDim2.new(1,0,0,42), BackgroundColor3=Color3.fromRGB(29,29,38), BorderSizePixel=0}, panel)
corner(top, 12)
make("Frame", {Size=UDim2.new(1,0,0,12), Position=UDim2.new(0,0,1,-12), BackgroundColor3=Color3.fromRGB(29,29,38), BorderSizePixel=0}, top)
make("TextLabel", {BackgroundTransparency=1, Position=UDim2.fromOffset(13,0), Size=UDim2.new(1,-55,1,0), Font=Enum.Font.GothamBold, Text="BILL AUTO BREAKER", TextColor3=Color3.fromRGB(240,240,248), TextSize=15, TextXAlignment=Enum.TextXAlignment.Left}, top)
local close = make("TextButton", {Name="Close", Size=UDim2.fromOffset(30,28), Position=UDim2.new(1,-36,0,7), Text="×", TextSize=20}, top)
styleButton(close, Color3.fromRGB(75,38,45))

local function label(text, y, h)
    return make("TextLabel", {BackgroundTransparency=1, Position=UDim2.fromOffset(14,y), Size=UDim2.new(1,-28,0,h or 18), Font=Enum.Font.Gotham, Text=text, TextColor3=Color3.fromRGB(190,190,205), TextSize=11, TextXAlignment=Enum.TextXAlignment.Left}, panel)
end

label("DAFTAR BLOK", 53, 18)
local scan = make("TextButton", {Name="ScanBlocks", Position=UDim2.new(1,-104,0,49), Size=UDim2.fromOffset(90,27), Text="SCAN BLOCK"}, panel)
styleButton(scan, Color3.fromRGB(48,82,130))

local list = make("ScrollingFrame", {
    Name="BlockList", Position=UDim2.fromOffset(14,76), Size=UDim2.new(1,-28,0,158),
    BackgroundColor3=Color3.fromRGB(29,29,38), BorderSizePixel=0,
    CanvasSize=UDim2.new(0,0,0,0), ScrollBarThickness=4,
}, panel)
corner(list, 8)
make("UIListLayout", {Padding=UDim.new(0,5), SortOrder=Enum.SortOrder.LayoutOrder}, list)
make("UIPadding", {PaddingTop=UDim.new(0,7), PaddingBottom=UDim.new(0,7), PaddingLeft=UDim.new(0,7), PaddingRight=UDim.new(0,7)}, list)
local empty = make("TextLabel", {Name="EmptyMessage", Size=UDim2.new(1,-14,0,34), BackgroundTransparency=1, Font=Enum.Font.Gotham, Text="Belum ada data blok. Tekan SCAN BLOCK.", TextColor3=Color3.fromRGB(135,135,150), TextSize=11, TextWrapped=true}, list)

label("BLOK DIPILIH", 242, 16)
local selected = make("TextLabel", {Name="SelectedBlock", Position=UDim2.fromOffset(14,260), Size=UDim2.new(1,-28,0,25), BackgroundColor3=Color3.fromRGB(32,32,42), BorderSizePixel=0, Font=Enum.Font.Gotham, Text="Belum ada blok dipilih", TextColor3=Color3.fromRGB(220,220,230), TextSize=11, TextXAlignment=Enum.TextXAlignment.Left}, panel)
corner(selected, 7)

label("JEDA PEMINDAIAN (detik)", 294, 17)
local delayBox = make("TextBox", {Name="ScanDelay", Position=UDim2.fromOffset(14,313), Size=UDim2.new(1,-28,0,29), BackgroundColor3=Color3.fromRGB(32,32,42), BorderSizePixel=0, ClearTextOnFocus=false, Font=Enum.Font.Gotham, Text="0.5", TextColor3=Color3.fromRGB(245,245,250), TextSize=12}, panel)
corner(delayBox, 7)

local start = make("TextButton", {Name="Start", Position=UDim2.fromOffset(14,350), Size=UDim2.new(0.5,-19,0,28), Text="START"}, panel)
styleButton(start, Color3.fromRGB(36,115,82))
local stop = make("TextButton", {Name="Stop", Position=UDim2.new(0.5,5,0,350), Size=UDim2.new(0.5,-19,0,28), Text="STOP"}, panel)
styleButton(stop, Color3.fromRGB(115,48,55))

local status = make("TextLabel", {Name="Status", BackgroundTransparency=1, Position=UDim2.fromOffset(14,378), Size=UDim2.new(1,-28,0,16), Font=Enum.Font.Gotham, Text="STATUS: Menunggu", TextColor3=Color3.fromRGB(220,190,105), TextSize=10, TextXAlignment=Enum.TextXAlignment.Left}, panel)

local function setStatus(msg, color)
    status.Text = "STATUS: " .. msg
    status.TextColor3 = color or Color3.fromRGB(220,190,105)
end

scan.MouseButton1Click:Connect(function()
    setStatus("Scanner game belum dihubungkan.", Color3.fromRGB(255,190,110))
    empty.Text = "Scanner belum terhubung ke data Own a World."
end)
start.MouseButton1Click:Connect(function()
    if selected.Text == "Belum ada blok dipilih" then
        setStatus("Scan dan pilih blok terlebih dahulu.", Color3.fromRGB(255,190,110))
        return
    end
    setStatus("Fungsi auto break belum dihubungkan.", Color3.fromRGB(255,190,110))
end)
stop.MouseButton1Click:Connect(function()
    setStatus("Berhenti.")
end)
close.MouseButton1Click:Connect(function() gui:Destroy() end)

-- Drag panel using the top bar.
local dragging, dragStart, startPos
 top.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging, dragStart, startPos = true, input.Position, panel.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+delta.X, startPos.Y.Scale, startPos.Y.Offset+delta.Y)
    end
end)

print("BILL AUTO BREAKER UI loaded. Scanner/breaker belum terhubung.")
