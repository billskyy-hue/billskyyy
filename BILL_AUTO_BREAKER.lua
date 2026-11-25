-- BILL AUTO BREAKER | passive world scanner
-- Reads Workspace metadata only. It does not call remotes or modify blocks.

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
if not player then return end

pcall(function()
    local old = CoreGui:FindFirstChild("BILL_AUTO_BREAKER")
    if old then old:Destroy() end
end)

local function make(className, props, parent)
    local obj = Instance.new(className)
    for k, v in pairs(props or {}) do obj[k] = v end
    obj.Parent = parent
    return obj
end

local function corner(obj, radius)
    make("UICorner", {CornerRadius = UDim.new(0, radius or 8)}, obj)
end

local function styleButton(btn, color)
    btn.BackgroundColor3 = color
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = Color3.fromRGB(245,245,250)
    btn.TextSize = 11
    corner(btn, 7)
end

local gui = Instance.new("ScreenGui")
gui.Name = "BILL_AUTO_BREAKER"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local parented = false
pcall(function()
    if typeof(gethui) == "function" then
        gui.Parent = gethui()
        parented = true
    end
end)
if not parented then gui.Parent = CoreGui end

local panel = make("Frame", {
    Name="Panel", Size=UDim2.fromOffset(340,440),
    Position=UDim2.new(0.5,-170,0.5,-220),
    BackgroundColor3=Color3.fromRGB(18,18,23), BorderSizePixel=0
}, gui)
corner(panel,12)
make("UIStroke",{Color=Color3.fromRGB(65,65,82),Thickness=1},panel)

local top = make("Frame",{
    Name="TopBar",Size=UDim2.new(1,0,0,42),
    BackgroundColor3=Color3.fromRGB(29,29,38),BorderSizePixel=0
},panel)
corner(top,12)
make("Frame",{
    Size=UDim2.new(1,0,0,12),Position=UDim2.new(0,0,1,-12),
    BackgroundColor3=Color3.fromRGB(29,29,38),BorderSizePixel=0
},top)
make("TextLabel",{
    BackgroundTransparency=1,Position=UDim2.fromOffset(13,0),
    Size=UDim2.new(1,-55,1,0),Font=Enum.Font.GothamBold,
    Text="BILL AUTO BREAKER",TextColor3=Color3.fromRGB(240,240,248),
    TextSize=15,TextXAlignment=Enum.TextXAlignment.Left
},top)

local close = make("TextButton",{
    Name="Close",Size=UDim2.fromOffset(30,28),
    Position=UDim2.new(1,-36,0,7),Text="×",TextSize=20
},top)
styleButton(close,Color3.fromRGB(75,38,45))

local scan = make("TextButton",{
    Name="ScanBlocks",Position=UDim2.fromOffset(14,52),
    Size=UDim2.fromOffset(110,29),Text="SCAN BLOCK"
},panel)
styleButton(scan,Color3.fromRGB(48,82,130))

local info = make("TextLabel",{
    Name="ScanInfo",BackgroundTransparency=1,
    Position=UDim2.fromOffset(134,52),Size=UDim2.new(1,-148,0,29),
    Font=Enum.Font.Gotham,Text="Menunggu pemindaian",
    TextColor3=Color3.fromRGB(175,175,190),TextSize=10,
    TextXAlignment=Enum.TextXAlignment.Left
},panel)

local list = make("ScrollingFrame",{
    Name="BlockList",Position=UDim2.fromOffset(14,88),
    Size=UDim2.new(1,-28,0,230),
    BackgroundColor3=Color3.fromRGB(29,29,38),BorderSizePixel=0,
    CanvasSize=UDim2.new(0,0,0,0),ScrollBarThickness=4
},panel)
corner(list,8)
local layout = make("UIListLayout",{
    Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder
},list)
make("UIPadding",{
    PaddingTop=UDim.new(0,7),PaddingBottom=UDim.new(0,7),
    PaddingLeft=UDim.new(0,7),PaddingRight=UDim.new(0,7)
},list)

local selected = make("TextLabel",{
    Name="SelectedBlock",Position=UDim2.fromOffset(14,326),
    Size=UDim2.new(1,-28,0,38),
    BackgroundColor3=Color3.fromRGB(32,32,42),BorderSizePixel=0,
    Font=Enum.Font.Gotham,Text="Dipilih: belum ada",
    TextColor3=Color3.fromRGB(220,220,230),TextSize=10,
    TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left
},panel)
corner(selected,7)

local status = make("TextLabel",{
    Name="Status",BackgroundTransparency=1,
    Position=UDim2.fromOffset(14,371),Size=UDim2.new(1,-28,0,38),
    Font=Enum.Font.Gotham,Text="STATUS: Siap scan",
    TextColor3=Color3.fromRGB(220,190,105),TextSize=10,
    TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,
    TextYAlignment=Enum.TextYAlignment.Top
},panel)

local function setStatus(msg,color)
    status.Text="STATUS: "..msg
    status.TextColor3=color or Color3.fromRGB(220,190,105)
end

local function metadataOf(obj)
    local values={}
    local ok,attrs=pcall(function() return obj:GetAttributes() end)
    if ok then
        for key,value in pairs(attrs) do
            local k=string.lower(tostring(key))
            if string.find(k,"id") or string.find(k,"block")
                or string.find(k,"tile") or string.find(k,"item") then
                if type(value)=="string" or type(value)=="number" then
                    table.insert(values,tostring(key).."="..tostring(value))
                end
            end
        end
    end
    for _,child in ipairs(obj:GetChildren()) do
        if child:IsA("ValueBase") then
            local k=string.lower(child.Name)
            if string.find(k,"id") or string.find(k,"block")
                or string.find(k,"tile") or string.find(k,"item") then
                table.insert(values,child.Name.."="..tostring(child.Value))
            end
        end
    end
    return table.concat(values,", ")
end

local function clearRows()
    for _,child in ipairs(list:GetChildren()) do
        if child:IsA("TextButton") or child.Name=="EmptyMessage" then
            child:Destroy()
        end
    end
end

local function emptyMessage(msg)
    make("TextLabel",{
        Name="EmptyMessage",Size=UDim2.new(1,-14,0,50),
        BackgroundTransparency=1,Font=Enum.Font.Gotham,
        Text=msg,TextColor3=Color3.fromRGB(150,150,165),
        TextSize=11,TextWrapped=true
    },list)
end

local busy=false
local function scanWorld()
    if busy then return end
    busy=true
    scan.Text="SCANNING..."
    clearRows()

    local found,seen={},{}
    local checked=0
    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            checked=checked+1
            local meta=metadataOf(obj)
            if meta~="" then
                local key=obj:GetFullName().."|"..meta
                if not seen[key] then
                    seen[key]=true
                    local pos="pos: -"
                    if obj:IsA("BasePart") then
                        local p=obj.Position
                        pos=string.format("pos: %.0f, %.0f, %.0f",p.X,p.Y,p.Z)
                    else
                        local ok,pivot=pcall(function() return obj:GetPivot() end)
                        if ok then
                            local p=pivot.Position
                            pos=string.format("pos: %.0f, %.0f, %.0f",p.X,p.Y,p.Z)
                        end
                    end
                    table.insert(found,{
                        name=obj.Name,meta=meta,path=obj:GetFullName(),pos=pos
                    })
                end
            end
        end
    end

    table.sort(found,function(a,b)
        return string.lower(a.name)<string.lower(b.name)
    end)

    if #found==0 then
        emptyMessage("Tidak ditemukan metadata Attribute/Value bernama ID, Block, Tile, atau Item. Format data game belum terdeteksi.")
    else
        for i,record in ipairs(found) do
            local row=make("TextButton",{
                Name="BlockEntry",Size=UDim2.new(1,-2,0,42),
                BackgroundColor3=Color3.fromRGB(40,40,53),BorderSizePixel=0,
                Font=Enum.Font.Gotham,
                Text=record.name.." | "..record.meta,
                TextColor3=Color3.fromRGB(230,230,240),TextSize=10,
                TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,
                LayoutOrder=i
            },list)
            corner(row,6)
            row.MouseButton1Click:Connect(function()
                selected.Text="Dipilih: "..record.name.." | "..record.meta.."\n"..record.pos
                setStatus("Kandidat dipilih; ID berasal dari metadata lokal.")
            end)
        end
    end

    task.wait()
    list.CanvasSize=UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+14)
    info.Text=tostring(#found).." kandidat / "..tostring(checked).." objek diperiksa"
    scan.Text="SCAN BLOCK"
    busy=false
    if #found>0 then
        setStatus("Scan selesai. Periksa kandidat.")
    else
        setStatus("Scan selesai; metadata ID tidak ditemukan.",Color3.fromRGB(255,170,110))
    end
end

scan.MouseButton1Click:Connect(scanWorld)
close.MouseButton1Click:Connect(function() gui:Destroy() end)

local dragging,dragStart,startPos
top.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1
        or input.UserInputType==Enum.UserInputType.Touch then
        dragging,dragStart,startPos=true,input.Position,panel.Position
        input.Changed:Connect(function()
            if input.UserInputState==Enum.UserInputState.End then dragging=false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement
        or input.UserInputType==Enum.UserInputType.Touch) then
        local delta=input.Position-dragStart
        panel.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,
            startPos.Y.Scale,startPos.Y.Offset+delta.Y)
    end
end)

print("BILL AUTO BREAKER passive scanner loaded.")
