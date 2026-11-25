-- BILL AUTO BREAKER | Workspace + ReplicatedStorage Explorer
-- Passive inspection only: lists instance names/classes and selected metadata.
-- Does NOT decompile/require modules, call remotes, or modify game objects.

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

if not Players.LocalPlayer then return end

pcall(function()
    local old = CoreGui:FindFirstChild("BILL_AUTO_BREAKER")
    if old then old:Destroy() end
end)

local function make(className, props, parent)
    local obj = Instance.new(className)
    for k,v in pairs(props or {}) do obj[k] = v end
    obj.Parent = parent
    return obj
end
local function corner(obj, radius)
    make("UICorner", {CornerRadius=UDim.new(0,radius or 8)}, obj)
end
local function style(btn, color)
    btn.BackgroundColor3=color
    btn.BorderSizePixel=0
    btn.Font=Enum.Font.GothamBold
    btn.TextColor3=Color3.fromRGB(245,245,250)
    btn.TextSize=11
    corner(btn,7)
end

local gui=Instance.new("ScreenGui")
gui.Name="BILL_AUTO_BREAKER"
gui.ResetOnSpawn=false
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
local attached=false
pcall(function()
    if typeof(gethui)=="function" then gui.Parent=gethui(); attached=true end
end)
if not attached then gui.Parent=CoreGui end

local panel=make("Frame",{
    Name="Panel",Size=UDim2.fromOffset(360,470),
    Position=UDim2.new(0.5,-180,0.5,-235),
    BackgroundColor3=Color3.fromRGB(18,18,23),BorderSizePixel=0
},gui)
corner(panel,12)
make("UIStroke",{Color=Color3.fromRGB(65,65,82),Thickness=1},panel)

local top=make("Frame",{
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
local close=make("TextButton",{
    Name="Close",Size=UDim2.fromOffset(30,28),
    Position=UDim2.new(1,-36,0,7),Text="×",TextSize=20
},top)
style(close,Color3.fromRGB(75,38,45))

local wsBtn=make("TextButton",{
    Name="WorkspaceScan",Position=UDim2.fromOffset(14,52),
    Size=UDim2.fromOffset(155,30),Text="SCAN WORKSPACE"
},panel)
style(wsBtn,Color3.fromRGB(48,82,130))
local rsBtn=make("TextButton",{
    Name="ReplicatedScan",Position=UDim2.fromOffset(178,52),
    Size=UDim2.fromOffset(168,30),Text="SCAN REPLICATED"
},panel)
style(rsBtn,Color3.fromRGB(74,66,130))

local info=make("TextLabel",{
    Name="ScanInfo",BackgroundTransparency=1,
    Position=UDim2.fromOffset(14,86),Size=UDim2.new(1,-28,0,27),
    Font=Enum.Font.Gotham,Text="Pilih lokasi untuk dipindai",
    TextColor3=Color3.fromRGB(180,180,195),TextSize=10,
    TextXAlignment=Enum.TextXAlignment.Left
},panel)

local filter=make("TextBox",{
    Name="Filter",Position=UDim2.fromOffset(14,116),
    Size=UDim2.new(1,-28,0,29),
    BackgroundColor3=Color3.fromRGB(32,32,42),BorderSizePixel=0,
    ClearTextOnFocus=false,Font=Enum.Font.Gotham,
    PlaceholderText="Filter nama / class (contoh: ModuleScript, ItemDB)",
    Text="",TextColor3=Color3.fromRGB(245,245,250),
    PlaceholderColor3=Color3.fromRGB(130,130,145),TextSize=10
},panel)
corner(filter,7)

local list=make("ScrollingFrame",{
    Name="ExplorerList",Position=UDim2.fromOffset(14,153),
    Size=UDim2.new(1,-28,0,250),
    BackgroundColor3=Color3.fromRGB(29,29,38),BorderSizePixel=0,
    CanvasSize=UDim2.new(0,0,0,0),ScrollBarThickness=5
},panel)
corner(list,8)
local layout=make("UIListLayout",{
    Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder
},list)
make("UIPadding",{
    PaddingTop=UDim.new(0,7),PaddingBottom=UDim.new(0,7),
    PaddingLeft=UDim.new(0,7),PaddingRight=UDim.new(0,7)
},list)

local detail=make("TextLabel",{
    Name="SelectedObject",Position=UDim2.fromOffset(14,410),
    Size=UDim2.new(1,-28,0,25),
    BackgroundColor3=Color3.fromRGB(32,32,42),BorderSizePixel=0,
    Font=Enum.Font.Gotham,Text="Objek dipilih: belum ada",
    TextColor3=Color3.fromRGB(220,220,230),TextSize=9,
    TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left
},panel)
corner(detail,7)
local status=make("TextLabel",{
    Name="Status",BackgroundTransparency=1,
    Position=UDim2.fromOffset(14,439),Size=UDim2.new(1,-28,0,22),
    Font=Enum.Font.Gotham,Text="STATUS: Siap",
    TextColor3=Color3.fromRGB(220,190,105),TextSize=10,
    TextXAlignment=Enum.TextXAlignment.Left
},panel)

local records={}
local function setStatus(msg,color)
    status.Text="STATUS: "..msg
    status.TextColor3=color or Color3.fromRGB(220,190,105)
end
local function metadata(obj)
    local out={}
    local ok,attrs=pcall(function() return obj:GetAttributes() end)
    if ok then
        for k,v in pairs(attrs) do
            local key=string.lower(tostring(k))
            if string.find(key,"id") or string.find(key,"block")
                or string.find(key,"tile") or string.find(key,"item") then
                if type(v)=="string" or type(v)=="number" then
                    table.insert(out,tostring(k).."="..tostring(v))
                end
            end
        end
    end
    for _,child in ipairs(obj:GetChildren()) do
        if child:IsA("ValueBase") then
            local key=string.lower(child.Name)
            if string.find(key,"id") or string.find(key,"block")
                or string.find(key,"tile") or string.find(key,"item") then
                table.insert(out,child.Name.."="..tostring(child.Value))
            end
        end
    end
    return table.concat(out,", ")
end

local function clearList()
    for _,child in ipairs(list:GetChildren()) do
        if child:IsA("TextButton") or child.Name=="EmptyMessage" then
            child:Destroy()
        end
    end
end

local function render()
    clearList()
    local q=string.lower(filter.Text or "")
    local shown=0
    for _,r in ipairs(records) do
        local hay=string.lower(r.name.." "..r.class.." "..r.path.." "..r.meta)
        if q=="" or string.find(hay,q,1,true) then
            shown=shown+1
            local labelText="["..r.class.."] "..r.name
            if r.meta~="" then labelText=labelText.." | "..r.meta end
            local row=make("TextButton",{
                Name="ExplorerEntry",Size=UDim2.new(1,-2,0,38),
                BackgroundColor3=Color3.fromRGB(40,40,53),BorderSizePixel=0,
                Font=Enum.Font.Gotham,Text=labelText,
                TextColor3=Color3.fromRGB(230,230,240),TextSize=9,
                TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,
                LayoutOrder=shown
            },list)
            corner(row,6)
            row.MouseButton1Click:Connect(function()
                detail.Text="["..r.class.."] "..r.path
                setStatus("Objek dipilih. ModuleScript tidak dieksekusi atau didecompile.")
            end)
        end
    end
    if shown==0 then
        make("TextLabel",{
            Name="EmptyMessage",Size=UDim2.new(1,-14,0,42),
            BackgroundTransparency=1,Font=Enum.Font.Gotham,
            Text="Tidak ada hasil untuk filter ini.",
            TextColor3=Color3.fromRGB(150,150,165),TextSize=11,
            TextWrapped=true
        },list)
    end
    task.wait()
    list.CanvasSize=UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+14)
    info.Text=tostring(shown).." ditampilkan dari "..tostring(#records).." objek"
end

local busy=false
local function scanRoot(root)
    if busy then return end
    busy=true
    wsBtn.Text="SCAN WORKSPACE"
    rsBtn.Text="SCAN REPLICATED"
    clearList()
    records={}
    setStatus("Memindai "..root.Name.."...")
    local ok,desc=pcall(function() return root:GetDescendants() end)
    if not ok then
        busy=false
        setStatus("Gagal membaca "..root.Name,Color3.fromRGB(255,150,110))
        return
    end
    local cap=2500
    for i,obj in ipairs(desc) do
        if i>cap then break end
        local meta=metadata(obj)
        table.insert(records,{
            name=obj.Name,class=obj.ClassName,path=obj:GetFullName(),meta=meta
        })
    end
    render()
    setStatus("Selesai: "..tostring(math.min(#desc,cap)).." objek diperiksa")
    if #desc>cap then
        setStatus("Dibatasi "..cap.." objek; gunakan filter untuk menelusuri hasil.")
    end
    busy=false
end

wsBtn.MouseButton1Click:Connect(function() scanRoot(Workspace) end)
rsBtn.MouseButton1Click:Connect(function() scanRoot(ReplicatedStorage) end)
filter:GetPropertyChangedSignal("Text"):Connect(function()
    if #records>0 then render() end
end)
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

print("BILL AUTO BREAKER Explorer loaded.")
