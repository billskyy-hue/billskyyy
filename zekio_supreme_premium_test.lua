-- Separate test copy. Production file is unchanged.
-- Zekio Supreme Premium P15 | Proxy, startup and Farm repair
-- The readable build avoids an extra, synchronous payload-unpacking step.
local Boot = { Done = false, Stage = "Menyiapkan menu premium" }
do
    local environment = _G
    if type(getgenv) == "function" then
        local ok, value = pcall(getgenv)
        if ok and type(value) == "table" then environment = value end
    end
    Boot.G = environment

    -- A failed old startup may leave a non-table value in the global session.
    for _, key in ipairs({ "__ZekioPremiumUI", "__ZekioSupremePremiumEngine", "__KzoyzOpus" }) do
        local previous = environment[key]
        if type(previous) == "table" then
            local cleanup = rawget(previous, "Cleanup")
            if type(cleanup) == "function" then pcall(cleanup) end
        end
        environment[key] = nil
    end

    local gui, label
    function Boot.Show(message)
        Boot.Stage = tostring(message)
        pcall(function()
            if not label then
                local players = game:GetService("Players")
                local player = players.LocalPlayer
                local fallback = player and (player:FindFirstChildOfClass("PlayerGui") or player:FindFirstChild("PlayerGui"))
                local root = fallback
                if type(gethui) == "function" then
                    local ok, value = pcall(gethui)
                    if ok and value then root = value end
                end
                if not root then return end
                gui = Instance.new("ScreenGui")
                gui.Name, gui.ResetOnSpawn, gui.DisplayOrder = "ZekioPremiumStartup", false, 2000000
                local parentOK = pcall(function() gui.Parent = root end)
                if not parentOK and fallback then gui.Parent = fallback end
                label = Instance.new("TextLabel")
                label.Name = "Message"
                label.Size = UDim2.new(0.9, 0, 0, 160)
                label.Position = UDim2.new(0.05, 0, 0.7, 0)
                label.BackgroundColor3, label.TextColor3 = Color3.fromRGB(20, 22, 29), Color3.fromRGB(245, 245, 245)
                label.TextSize, label.TextWrapped = 14, true
                label.TextXAlignment, label.TextYAlignment = Enum.TextXAlignment.Left, Enum.TextYAlignment.Top
                label.Parent = gui
            end
            label.Text = "ZEKIO SUPREME PREMIUM P15\n" .. Boot.Stage:sub(1, 1300)
        end)
    end
    function Boot.Close()
        Boot.Done = true
        if gui then pcall(function() gui:Destroy() end) end
        gui, label = nil, nil
    end
    function Boot.Fail(message)
        Boot.Done = true
        Boot.Show("Menu gagal dibuka: " .. tostring(message) .. "\nKirim screenshot pesan ini.")
        warn("[Zekio Premium startup] " .. tostring(message))
    end
    Boot.Show(Boot.Stage)
end

-- Test copy: opens directly without license activation.

local Premium
local uiOk, uiError = xpcall(function()
Premium=(function()
-- Zekio Supreme Premium | P15 FULL
-- Native premium UI with the r29 Farm repair.
-- Standalone premium test build without key activation.
local G = Boot.G
local Session = { Connections = {}, PageConnections = {}, Values = {}, Controls = {}, Sections = {}, SectionButtons = {}, Closed = false }
G.__ZekioPremiumUI = Session
local Players = game:GetService("Players")
local Input = game:GetService("UserInputService")
local player = Players.LocalPlayer
assert(player, "Jalankan script dari client Roblox setelah masuk game.")
local playerGui = player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui", 15)
assert(playerGui, "PlayerGui belum tersedia.")
local UI = { Page = "overview", Group = "farming", Theme = "Gelap", Scale = 1, Width = 640, Height = 380, Transparency = .18, Surfaces = setmetatable({}, { __mode = "k" }), Styles = setmetatable({}, { __mode = "k" }) }
local function alive() return not Session.Closed and G.__ZekioPremiumUI == Session end
local V = Session.Values
local COLORS = {
    Gelap = { bg="16141E", side="111018", card="211E2B", input="191622", raised="2A2537", line="373040", text="F2EEF9", muted="B4A9C4", accent="AD89FF", soft="342548", onAccent="211331", mainIcon="63D995", mainIconSelected="14532D" },
    Terang = { bg="F6F4FB", side="EEE9F6", card="FFFFFF", input="F8F6FC", raised="EDE7F5", line="DCD4E8", text="282035", muted="6E627F", accent="7846CB", soft="EBE0FD", onAccent="FFFFFF", mainIcon="218048", mainIconSelected="CBFFD9" },
}
local function color(key) return Color3.fromHex(COLORS[UI.Theme][key]) end
function UI.tint(instance, property, key)
    local properties = UI.Styles[instance] or {}; UI.Styles[instance] = properties
    properties[property] = key; instance[property] = color(key)
end
function UI.theme(name)
    UI.Theme = COLORS[name] and name or "Gelap"
    for instance, properties in pairs(UI.Styles) do
        if instance.Parent then for property, key in pairs(properties) do instance[property] = color(key) end
        else UI.Styles[instance] = nil end
    end
end
-- Surface backgrounds fade independently; text, icons and strokes stay crisp.
function UI.surfaceAlpha(role)
    local amount=UI.Transparency
    if role=="window" then return amount end
    if role=="sidebar" then return amount/(amount+.03) end
    if role=="card" then return amount/(amount+.10) end
    return amount*(role=="floating" and .25 or .30)
end
function UI.surface(object,role)
    local opacity=UI.surfaceAlpha(role)
    UI.Surfaces[object]={role=role,last=opacity}
    object.BackgroundTransparency=opacity
end
function UI.setTransparency(percent)
    local value=math.clamp(tonumber(percent) or 18,0,40)
    V["ui.transparency"]=value;UI.Transparency=value/100
    for object,spec in pairs(UI.Surfaces) do
        -- Respect explicit overrides on transparent section headers or shades.
        if object.Parent and math.abs(object.BackgroundTransparency-spec.last)<.00001 then
            spec.last=UI.surfaceAlpha(spec.role)
            object.BackgroundTransparency=spec.last
        else UI.Surfaces[object]=nil end
    end
end
local function make(class, properties, parent)
    local o = Instance.new(class)
    for key, value in pairs(properties or {}) do o[key] = value end
    o.Parent = parent
    return o
end
local function connect(signal, callback, pageScope)
    local c = signal:Connect(callback)
    local list = pageScope and Session.PageConnections or Session.Connections
    list[#list + 1] = c; return c
end
local function round(parent, radius) make("UICorner", { CornerRadius = UDim.new(0, radius or 10) }, parent) end
local function outline(parent)
    local stroke = make("UIStroke", { Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, parent)
    UI.tint(stroke, "Color", "line")
end
local function padding(parent, amount)
    make("UIPadding", { PaddingTop=UDim.new(0,amount), PaddingBottom=UDim.new(0,amount), PaddingLeft=UDim.new(0,amount), PaddingRight=UDim.new(0,amount) }, parent)
end
local function stack(parent, gap)
    return make("UIListLayout", { Padding=UDim.new(0,gap or 10), SortOrder=Enum.SortOrder.LayoutOrder }, parent)
end
local function label(parent, text, size, token, properties)
    local o = make("TextLabel", { BackgroundTransparency=1, Text=text, Font=Enum.Font.Gotham, TextSize=size or 13,
        TextXAlignment=Enum.TextXAlignment.Left, TextYAlignment=Enum.TextYAlignment.Center, BorderSizePixel=0 }, parent)
    UI.tint(o,"TextColor3",token or "text")
    for k,v in pairs(properties or {}) do o[k]=v end
    return o
end
local function frame(parent, size, token, properties)
    local o=make("Frame",{Size=size,BorderSizePixel=0},parent)
    if token then UI.tint(o,"BackgroundColor3",token) else o.BackgroundTransparency=1 end
    if token=="card" and properties and properties.Name=="ContentCard" then UI.surface(o,"card") end
    for k,v in pairs(properties or {}) do o[k]=v end
    return o
end
local function button(parent, text, size, callback, primary, pageScope)
    local b=make("TextButton",{Text=text,Size=size,Font=Enum.Font.GothamBold,TextSize=12,BorderSizePixel=0,AutoButtonColor=true},parent)
    UI.tint(b,"BackgroundColor3",primary and "accent" or "raised")
    UI.surface(b,"control")
    UI.tint(b,"TextColor3",primary and "onAccent" or "text");round(b,9)
    if callback then connect(b.MouseButton1Click,function() if alive() then callback() end end,pageScope) end
    return b
end
-- Original native line icons. No image assets or external icon library.
local MENU_ICONS={
    overview={rects={{2,2,8,8,2},{14,2,8,5,2},{14,11,8,11,2},{2,14,8,8,2}}},
    farm={paths={{4,21,17,8},{4,6,9,3,14,3,19,6,22,12},{9,3,8,8},{15,4,14,10}}},
    farmer={paths={{12,22,12,11},{12,14,6,13,3,8,8,7,12,10,12,14},{12,11,14,5,21,3,21,8,17,12,12,12}}},
    pabrik={paths={{2,22,2,11,8,7,8,11,14,7,14,11,22,11,22,22,2,22},{16,11,16,2,20,2,20,11},{6,16,6,18},{12,16,12,18},{18,16,18,18}}},
    dirt={paths={{2,6,12,2,22,6,12,10,2,6},{2,12,12,16,22,12},{2,18,12,22,22,18}}},
    clear={paths={{3,15,13,5,16,5,22,11,22,14,14,22,9,22,3,16,3,15},{8,10,17,19},{10,22,23,22}}},
    splice={paths={{6,6,6,18},{6,13,12,13,18,7,18,6}},circles={{6,4,2},{6,20,2},{18,4,2}}},
    door={rects={{4,2,16,20,2}},circles={{16,12,0.7}},paths={{1,12,10,12},{7,9,10,12,7,15}}},
    drop={paths={{12,22,4.5,11.5,4,8,5,5,8,2.5,12,2,16,2.5,19,5,20,8,19.5,11.5,12,22}},circles={{12,8,2.5}}},
    growscan={paths={{2,8,2,2,8,2},{16,2,22,2,22,8},{22,16,22,22,16,22},{8,22,2,22,2,16},{6,12,18,12}},circles={{12,12,3}}},
    inventory={rects={{6,6,12,16,3},{8,13,8,6,2}},paths={{9,6,9,2,15,2,15,6},{3,11,3,17},{21,11,21,17}}},
    vending={rects={{4,11,16,11,1},{14,15,4,7,1}},paths={{2,11,5,3,19,3,22,11,2,11},{8,3,7,11},{16,3,17,11},{7,16,10,16}}},
    chat={paths={{4,3,20,3,22,5,22,15,20,17,9,17,3,22,3,5,4,3},{7,8,17,8},{7,12,14,12}}},
    bonus={rects={{3,10,18,12,1},{2,7,20,4,1}},paths={{12,7,12,22},{12,7,8,7,5,5,5,3,7,2,10,3,12,7},{12,7,16,7,19,5,19,3,17,2,14,3,12,7}}},
    security={paths={{12,2,21,6,20,14,17,19,12,22,7,19,4,14,3,6,12,2},{8,12,11,15,17,9}}},
    settings={circles={{12,12,7},{12,12,3}},paths={{20,12,22,12},{17.6569,17.6569,19.0711,19.0711},{12,20,12,22},{6.3431,17.6569,4.9289,19.0711},{4,12,2,12},{6.3431,6.3431,4.9289,4.9289},{12,4,12,2},{17.6569,6.3431,19.0711,4.9289}}},
    stats={paths={{2,2,2,22,22,22}},rects={{6,13,3,8,0.6},{11,8,3,13,0.6},{16,3,3,18,0.6}}},
    key={circles={{7,8,5}},paths={{10.5,11.5,21,22},{16,17,19,14},{19,20,22,17}}},
    updates={rects={{5,2,15,20,2}},paths={{3,6,7,6},{3,12,7,12},{3,18,7,18},{10,7,16,7},{10,12,16,12},{10,17,14,17}}},
    world={circles={{12,12,10}},paths={{2,12,22,12},{4,7,20,7},{4,17,20,17},{12,2,8.5,5,7,12,8.5,19,12,22},{12,2,15.5,5,17,12,15.5,19,12,22}}},
    tools={paths={{13,2,15.5,8.5,22,11,15.5,13.5,13,20,10.5,13.5,4,11,10.5,8.5,13,2},{4,2,4,6},{2,4,6,4}}},
}
MENU_ICONS.connection={paths={{7,2,7,7},{17,2,17,7},{5,7,19,7,19,12,16,16,8,16,5,12,5,7},{12,16,12,22}}}
MENU_ICONS.rejoin={paths={{20,7,17,4,12,3,7,4,3,8,3,14,7,19,12,21,18,19,21,15},{20,2,20,7,15,7}}}
MENU_ICONS.discord={paths={{4,17,6,14,6,9,8,5,12,3,16,5,18,9,18,14,20,17,4,17},{9,21,15,21}}}

local ICON_ALIASES={farming="farmer",items="inventory",system="settings"}
function UI.icon(parent,name,x,y,size,token)
    local key=ICON_ALIASES[name] or name
    local data=MENU_ICONS[key] or MENU_ICONS.overview
    local host=frame(parent,UDim2.fromOffset(size,size),nil,{Name="MenuIcon_"..name,Position=UDim2.fromOffset(x,y),Active=false})
    local canvas=frame(host,UDim2.fromOffset(24,24),nil,{Name="IconCanvas",Active=false})
    make("UIScale",{Scale=size/24},canvas)
    token=token or "accent"
    for _,path in ipairs(data.paths or {}) do
        for i=1,#path-2,2 do
            local x1,y1,x2,y2=path[i],path[i+1],path[i+2],path[i+3]
            local dx,dy=x2-x1,y2-y1
            local line=frame(canvas,UDim2.fromOffset(math.sqrt(dx*dx+dy*dy),2),token,{
                AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromOffset((x1+x2)/2,(y1+y2)/2),Rotation=math.deg(math.atan2(dy,dx)),Active=false})
            round(line,1)
        end
    end
    local function ring(px,py,w,h,radius)
        local shape=frame(canvas,UDim2.fromOffset(w,h),nil,{Position=UDim2.fromOffset(px,py),Active=false})
        round(shape,radius)
        local stroke=make("UIStroke",{Thickness=2,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},shape)
        UI.tint(stroke,"Color",token)
    end
    for _,c in ipairs(data.circles or {}) do ring(c[1]-c[3],c[2]-c[3],c[3]*2,c[3]*2,99) end
    for _,r in ipairs(data.rects or {}) do ring(r[1],r[2],r[3],r[4],r[5]) end
    return host
end
-- Visible labels are separate from decorative icons, keeping the whole row clickable.
function UI.menuLabel(b,text,name,height,selected,hasArrow,isMain)
    b.TextTransparency=1
    local token=selected and "onAccent" or "text"
    local iconToken=selected and "onAccent" or "accent"
    if isMain then iconToken=selected and "mainIconSelected" or "mainIcon" end
    if name=="rejoin" then iconToken="mainIcon" end
    UI.icon(b,name,10,(height-18)/2,18,iconToken)
    label(b,text,isMain and 14 or 12,token,{Name="MenuTitle",Position=UDim2.fromOffset(36,0),Size=UDim2.new(1,hasArrow and -62 or -44,1,0),Font=Enum.Font.GothamBold,TextWrapped=true,Active=false})
end

local function value(key, initial)
    if V[key]==nil then V[key]=initial end
    return V[key]
end
local function t(key,title,description,default) return {kind="toggle",key=key,title=title,description=description,default=default or false} end
local function f(key,title,placeholder,default) return {kind="input",key=key,title=title,placeholder=placeholder or "",default=default or ""} end
local function n(key,title,default,min,max) return {kind="input",key=key,title=title,default=default,number=true,min=min,max=max,placeholder=tostring(default)} end
local function s(key,title,choices,default) return {kind="select",key=key,title=title,choices=choices,default=default or choices[1]} end
local function r(key,title,default,min,max,step,unit) return {kind="slider",key=key,title=title,default=default,min=min,max=max,step=step,unit=unit} end
local function info(text) return {kind="info",title=text} end
local function pair(a,b) return {kind="pair",items={a,b}} end
local function group(title, rows) return {title=title,rows=rows} end
local seeds={"Dirt Seed","Grass Seed","Sugar Cane Seed","Lava Seed"}
local blocks={"Dirt","Grass","Sugar Cane","Lava"}
local PAGES = {
    overview={title="Ringkasan",subtitle="Status sesi dan akses cepat.",nodes={}},
    farm={title="Farm",subtitle="Place, break, collect dan pengaturan Grid Tile.",nodes={}},
    farmer={title="Farmer",subtitle="Harvest pohon ready dan tanam pada tile terjangkau.",nodes={}},
    pabrik={title="Pabrik",subtitle="Harvest → ambil block → break → tanam.",nodes={}},
    dirt={title="Dirt Farm",subtitle="Bangun lahan, gali per baris dan prioritaskan lava.",nodes={}},
    clear={title="Clear World",subtitle="Bersihkan world dengan perlindungan lock dan spawn.",nodes={}},
    splice={title="Splice",subtitle="Tanam pasangan seed untuk splice.",nodes={}},
    drop={title="Titik Drop",subtitle="Penyimpanan seed untuk Farm dan Pabrik.",nodes={}},
    growscan={title="Growscan",subtitle="Data item, block dan pohon dalam world.",nodes={}},
    inventory={title="Tas",subtitle="Inventori, trash item dan pembelian lock.",nodes={}},
    vending={title="Vending",subtitle="Isi stock dan kosongkan vending milikmu.",nodes={}},
    proxy={title="Proxy",subtitle="Fast Pull melalui wrench.",nodes={}},
    chat={title="Auto Chat",subtitle="Susun dan kirim pesan dengan interval pilihan.",nodes={}},
    bonus={title="Bonus",subtitle="Quest, redeem dan kode bonus.",nodes={}},
    security={title="Keamanan",subtitle="Penjaga dan pengaturan respons sesi.",nodes={}},
    settings={title="Setelan",subtitle="Tampilan, karakter dan opsi performa.",nodes={}},
    connection={title="Koneksi",subtitle="Hubungkan data game dan konfigurasi.",nodes={}},
    rejoin={title="Auto Rejoin",subtitle="Kembali ke world terakhir dan lanjutkan aktivitas sebelumnya.",nodes={}},
    discord={title="Discord",subtitle="Atur notifikasi webhook dan laporan statistik.",nodes={}},
    stats={title="Statistik",subtitle="Catatan hasil aktivitas sesi ini.",nodes={}},
    key={title="Akun Tes",subtitle="Informasi akun dan status konfigurasi lisensi.",nodes={}},
    updates={title="Update",subtitle="Zekio Supreme Premium • Build P15.",nodes={}},
}
local GROUPS={
    {id="farming",title="Farming",mark="F",pages={"farmer","pabrik","splice","dirt","clear"}},
    {id="world",title="World",mark="W",pages={"drop","growscan"}},
    {id="items",title="Item",mark="I",pages={"inventory","vending"}},
    {id="proxy",title="Proxy",mark="P",pages={"proxy"}},
    {id="tools",title="Utilitas",mark="U",pages={"chat","bonus","security"}},
    {id="rejoin",title="Auto Rejoin",direct="rejoin",pages={"rejoin"}},
    {id="system",title="Sistem",mark="S",pages={"settings","connection","discord","stats","key","updates"}},
}
Session.Pages=PAGES
Session.Build="PREMIUM P15"
Session.MenuCount=0
for _ in pairs(PAGES) do Session.MenuCount=Session.MenuCount+1 end

-- Native UI only. Nothing below imports or controls gameplay.
local gui=make("ScreenGui",{Name="ZekioSupremePremiumUI",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=1600,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
local parent=playerGui
if type(gethui)=="function" then local ok,result=pcall(gethui);if ok and result then parent=result end end
local parentOK=pcall(function() gui.Parent=parent end);if not parentOK then gui.Parent=playerGui end
Session.Gui=gui
local root=frame(gui,UDim2.fromScale(1,1),nil,{Name="Viewport"})
local host=frame(root,UDim2.fromOffset(640,380),nil,{Name="WindowHost",Position=UDim2.fromOffset(20,20)})
local window=frame(host,UDim2.fromOffset(640,380),"bg",{Name="PremiumWindow",Active=true,Position=UDim2.fromOffset(0,0)})
local windowScale=make("UIScale",{Name="ResponsiveScale",Scale=1},window)
round(window,16);outline(window);UI.surface(window,"window")
local header=frame(window,UDim2.new(1,0,0,68),nil)
local headerLine=frame(header,UDim2.new(1,0,0,1),"line",{Position=UDim2.new(0,0,1,-1)})
local logo=frame(header,UDim2.fromOffset(38,38),"soft",{Position=UDim2.fromOffset(15,15)})
round(logo,11)
label(logo,"Z",25,"accent",{Font=Enum.Font.GothamBold,Position=UDim2.fromOffset(5,-1),Size=UDim2.fromOffset(28,36)})
label(logo,"S",25,"accent",{Font=Enum.Font.GothamBold,Position=UDim2.fromOffset(14,5),Size=UDim2.fromOffset(27,36)})
local title=label(header,"Zekio Supreme",17,"text",{Font=Enum.Font.GothamBold,Position=UDim2.fromOffset(65,13),Size=UDim2.new(1,-170,0,23)})
local edition=label(header,"PREMIUM  •  GROWBLOX",11,"accent",{Position=UDim2.fromOffset(65,38),Size=UDim2.new(1,-170,0,16)})
local dragArea=make("TextButton",{Name="WindowDragHandle",Text="",BackgroundTransparency=1,AutoButtonColor=false,Position=UDim2.fromOffset(54,0),Size=UDim2.new(1,-144,1,0)},header)
local menuButton=button(header,"≡",UDim2.fromOffset(36,40),function() UI.drawer(not UI.Drawer) end,false)
menuButton.Position=UDim2.fromOffset(8,14);menuButton.Visible=false
local minimize=button(header,"−",UDim2.fromOffset(34,36),function() UI.closePopup();window.Visible=false;UI.Bubble.Visible=true end,false)
minimize.Position=UDim2.new(1,-84,0,16)
local close=button(header,"×",UDim2.fromOffset(34,36),function() Session.Cleanup() end,false)
close.Position=UDim2.new(1,-44,0,16)
local body=frame(window,UDim2.new(1,0,1,-98),nil,{Position=UDim2.fromOffset(0,68)})
local side=make("ScrollingFrame",{Name="Navigation",BackgroundTransparency=0,BorderSizePixel=0,Size=UDim2.new(0,170,1,0),ScrollBarThickness=4,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.None,ScrollingDirection=Enum.ScrollingDirection.Y,ClipsDescendants=true},body)
UI.tint(side,"BackgroundColor3","side");UI.tint(side,"ScrollBarImageColor3","accent");UI.surface(side,"sidebar")
local nav=frame(side,UDim2.fromOffset(146,0),nil,{Position=UDim2.fromOffset(10,10)})
local navLayout=stack(nav,4)
local sideLine=frame(body,UDim2.new(0,1,1,0),"line",{Position=UDim2.fromOffset(170,0)})
local content=make("ScrollingFrame",{Name="PageContent",BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(171,0),Size=UDim2.new(1,-171,1,0),ScrollBarThickness=4,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.None,ScrollingDirection=Enum.ScrollingDirection.Y,ClipsDescendants=true},body)
UI.tint(content,"ScrollBarImageColor3","accent")
local footer=frame(window,UDim2.new(1,0,0,30),"side",{Position=UDim2.new(0,0,1,-30)})
UI.surface(footer,"sidebar")
local footerText=label(footer,"Zekio Supreme Premium • Growblox",11,"muted",{Position=UDim2.fromOffset(13,0),Size=UDim2.new(1,-55,1,0)})
label(footer,"P15",11,"accent",{Position=UDim2.new(1,-38,0,0),Size=UDim2.fromOffset(25,30),TextXAlignment=Enum.TextXAlignment.Right})
local shade=button(body,"",UDim2.fromScale(1,1),function() UI.drawer(false) end,false)
shade.BackgroundTransparency=.35;shade.ZIndex=29;shade.Visible=false
local bubble=button(root,"ZS",UDim2.fromOffset(54,54),function() window.Visible=true;UI.Bubble.Visible=false end,true)
UI.Bubble=bubble;bubble.Name="PremiumOpenButton";bubble.Position=UDim2.fromOffset(16,100);bubble.Visible=false;round(bubble,16)
-- Embedded original ZS artwork; no external image host required.
task.spawn(function()
    local assetFn = getcustomasset or getsynasset
    if type(assetFn) ~= "function" or type(writefile) ~= "function" then return end
    local ok, asset = pcall(function()
        local encoded = [=[/9j/4AAQSkZJRgABAQAAAQABAAD/4gIoSUNDX1BST0ZJTEUAAQEAAAIYAAAAAAQwAABtbnRyUkdCIFhZWiAAAAAAAAAAAAAAAABhY3NwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQAA9tYAAQAAAADTLQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAlkZXNjAAAA8AAAAHRyWFlaAAABZAAAABRnWFlaAAABeAAAABRiWFlaAAABjAAAABRyVFJDAAABoAAAAChnVFJDAAABoAAAAChiVFJDAAABoAAAACh3dHB0AAAByAAAABRjcHJ0AAAB3AAAADxtbHVjAAAAAAAAAAEAAAAMZW5VUwAAAFgAAAAcAHMAUgBHAEIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFhZWiAAAAAAAABvogAAOPUAAAOQWFlaIAAAAAAAAGKZAAC3hQAAGNpYWVogAAAAAAAAJKAAAA+EAAC2z3BhcmEAAAAAAAQAAAACZmYAAPKnAAANWQAAE9AAAApbAAAAAAAAAABYWVogAAAAAAAA9tYAAQAAAADTLW1sdWMAAAAAAAAAAQAAAAxlblVTAAAAIAAAABwARwBvAG8AZwBsAGUAIABJAG4AYwAuACAAMgAwADEANv/bAEMAAwICAwICAwMDAwQDAwQFCAUFBAQFCgcHBggMCgwMCwoLCw0OEhANDhEOCwsQFhARExQVFRUMDxcYFhQYEhQVFP/bAEMBAwQEBQQFCQUFCRQNCw0UFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFP/AABEIBgAGAAMBIgACEQEDEQH/xAAeAAEAAQQDAQEAAAAAAAAAAAAABAECAwUGBwgJCv/EAGcQAAEDAgMFBQIJBQgKDA4CAwEAAgMEEQUGIQcSMUFRCBMiYXEygQkUI0JSkaHB0RVicpKxFiQzQ4KT0uE0RFNjc4OUorLTFyY2RUZUdISjs8LwGBklJzU3VVZkdZXD4vEoZYVHV//EAB0BAQACAwEBAQEAAAAAAAAAAAABAgMEBQYHCAn/xABOEQACAQMBBQMHCAcHAgUEAwEAAQIDBBEFEiExQVEGE3EiYYGRobHRBxQyQlKSwfAVI0NicoLhJDNEU6Ky0hY0F2OTwvElVIPiJjU2c//aAAwDAQACEQMRAD8A+VSIiAIiIAicUQBAiIARZERAEREAREQBERAEREAREQC6IiAIiIAiIgCIiAIiIAiIgCJa6IBdLoiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIERADxREQBERAEREAREQBERAEuiIAiIgCIiAIiIAiIgCIiAIiIAnIoiAIiqDogKIiIAiIgCIiAIiIAg1REAHFLoiAIiIAES6IAiIgCIl0AREQBERAEREAREQBERAEREAREQBERAEREAREvdAEREAREQBERAEREAREQBERAEREAREQBERABxREQBERAEREAREQBEHFEAREQBLoiAIiIAiIgCIiAIiIAUREAREQBERAEREAREQBEQoAiIgCIiAIiIBdERAERBqgCIRZEAREQBERAESyIAiIgCFEQBERAEREAREQC6IiAIiIAiDih4oAiIgCIiAIiIAiIgCIiAIiIAiIgANkREAvoiIgCIiAIiIAiIgCIiAJZEHAoAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiJZAEREAREQBERAEREAREQBERAEREAREQBERAEREAREQBERAEREAREQCyJ6IgCIiAIiIAiIgCIltEAREQBETTogCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCckRAEREAREQBERAES6IBdERAEQIgCIiAIiIByREQBEQoAiIgCIiAIiIAgREAREQBECIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgF7oeSIgCIiADmiWQoAiIgCIEPFADoiHiiABEvoiAIiAIAiIgCIiAcU4IiAIiIAiIgCIOKHigCIiAIiIAl7IiAIiIAlkRAEREAREQBERAEREAREQBERAOAREQBERACboiIAiIgCckRAEREAREQBEHBEAREQBERAETSyIAiIgCIiAIiIAiIgCIiAIiIAicEQBERAEREATTzRCgBREQBEQIAiILIAlkRAL2REQBERAEQIgCIiAcCl0CIAiGyX0QBERAFUGyoiAXuiIgCqBcKiA2QBEQoAiIgCIiAX0REQBERAERBxQBERAEREAREQBERAETkiAIgCIAiIgCIiAIiIAiIgCIUQBEQC6AXRCiAIiIAiIgCBEQBERAEREAREQBERAEvZEQA6lERAEQC5RAEREAREQBERAEREAREQBECFAEREAREQBECqSgKIiaIAiIgCIiAIiIAiJz0QBERAEREAREQBEQGyAJa6IgCIiABCiIAiIgCIiAIiIAiIgCIiAIiIAiaIgCIiAIiIAiIgCIiAIiIAiJdAEREASyIgCIiAIhRAEREAREQBERAEREAREQAC4REQBESyAIiIAiIgCIiAIUQoAiIgCIiAEWRLogCEWQKuiAoiIgCIiAIgRAERV0JQFOARV4IAhOCnBFdZW8SgwEVbW4KhQgIiIAnJEQBERAEREAREQDjZCiIAiIgCIiAIiIAiIgCIiAIiDigCJeyXKAIiIAiIgCIiAIiIBfRERAEREAREQAIiIAiIgCJayIAiIgCqLKiIAiIgCIiAJyREAREQBERAEREAREQBETkgCIiAIiIAiIgCIiAcUQFEAREvxQBDxREAREQBERAEREAREQBERAERCgCIiAIiIAiIgCIiAE3REQBERAEREAROCIAiIgCcURALIiIAiIgCIiAIiIAiIgCIiAIiIAiryVEARAiAIiIAiIgHFERAERORQBERAEREAREQAjzREQBERAEREAS10RAERVCAoiFEATgiICu8qIiAIiIAiIgCIiAIiIAnBLIUAS+iIgCIiAIicEAuiIgCJZEAAultVUDRLX4ITgpzVSLJZLaoMDQ6KtksijJI53REUZJCWsiJkYCIinIKEKiuQ8FJXBaqpZU56IAQiqGqiEAIURABoiIgCIiAJZEQBERAEREAREQBERAE4FEQDilrIiAIiIAiIgFkREAREQBERAEREAREQBERAORREQBEQoAiIgHFAbIiAIiIAiIgCIiAIiIAUSyIAiIgCIiAJZEQBERAEREAREQCyJdEAREQBERAEREAREQBL2REAREQBERAEKckQBERAEREAREQBERAEREATREQBERAEREAvdLIqtQFLWREQBERALIiIAiIgCIiAIiIAiIgGiIiAIiIBdERAEv8AUiIAiIgCIqiyAoiHiiAIiBAEREAREA0QBERAES2hRAETTkiAIURAERCOiAIiIAiIgCIiAIiIAiIgCIiAIiIAiJbRAEREASyIgCJe6IAiIgFkRVAugKcdFXdQCxVVBOAnBEUF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REAREQBEHFEAsiIgCIiAIiIABdEuiAIiIAlkRAL6IiIAnFEQCyJdEAROSIAUREBXeVVbwVQhKZVVBsrb6XVVXBdMuDtVcDZWJdQXUjICrgVi3lUHVRgyKRlBVwKxX0VQ5VwZFMyh6vD1huFUHVVaMymZi9Wl6xkpdEizqZLi9W7yoXK0m6tgxOZcTZWlyoSrSVZIwuRUm6oqXVCbqTE2PROKoikpkJdFbyUlWVvY6KiFFJUIiIAiIBdAEtdEBsgFrIhKWQBERAEREAREQBERAOKJwRAEREAvZERAEKIgCcURALXREQAJdEQBERAEREABsiJxQBLWRCblAAiIgF9EREAREQC+iIlkAREQBAbIiAIiIAiIgAF0PFEQBERAEREAROKIAiIgCIiAIiIAiWRAEBsiIAiIgCHiiIAiIgCXREAREQBERAEREAKIiAIiIAiIgCIiAIERAEREAREQBERAESyIAnIIlkAREQBEQC6AIiIAiIgCIiAJZEQBERAEREAREQBES90AREQBERAEREAREQBAURAOSIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiWQA6IhN0QBERAEuiIAicE4oAiIgF1de6tvoqg2QlFUVN5AbqCclURFBbJcHXVQdVYqqC6ZeHKocrAbqqYLqReSqEq26pvKMDaLr6ITcKwlLqcFdoqXWKpdURSUbCIhNlOCuQlwqG91RCMlSbqiIpKhERAEREAREQBESyAIiIAiIgCIiAIiIAiFEAREQBERAES6IAiIgCIiAIiIAiIgCIiAIiIAnBEQBERAEKIgCIiAIiIAiIgHBEKIAiIgCJdEAREQBERAEREAREQBERAEREAREQBERAEKIgCIEQBERAEREAREQBERALoiIAiIgCIgQBEIRAERDogCJ5ogCIiAIiIAiIgCIiAIiIAiIgCA2S2iIAiIgCJZEAREQBEtdEAREQBERAEREAREQBERAEtoiIAgNkRAERAbIAiE3RAEREARLIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIERAEREAHFERALeacERAV4hUGiJdAVubqqtVb3CE5KoqAqqjBZMKoNlRFGCclSqIigZCJdUJVsEZKoTZW35IpK5FyicEtpdCAEREAREQBERAEREAREQBERAEREAREQBERAEREAREQC2l0REAREQBERAEREAREQBERAEvoiIAiJZAEREAREQBE5IgCIiAIiEWQBERAEREAREQBERAEREA5IiIAiIgCIiAIiIAiIgCIiAIiIAiIOKAIh4ogCIiAIiIAiIgCIiAIiIAiIRZAEREAREQBERAEREARLIgCIiAWREQBERAEREAREQBEQ6oAiJayAJe6IgCIiAIiIAiJwQAiyJxRAEREARAbIdUAREQBERAEREAREQBNERANEREAREQBERAEQ8UQBERAETyRAEROCAIiIBZLoiAIiIAiAIgCIiAIiIAiIgCIiAIiIAiWRAEREAHFVIAVEQBOBREAKWRCboAiW0RALpdOCICocq3urUQnJddWk3REACXTiiEBERAEREAREOqAIiIAl7IiAFERAEQ6IgHqiIgCJZEAsiE3RAEREAuiIgCIiAIiIAiWRAEKIgCIiAIiIAiIgBREQBERAEREAvZOKIgFiiIgCWuiIAiIgCJyRAEREAREQBERAECIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIURAERAgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAicUQBERAEREAREQBERAEREAREQBERAEREAREQBERAEREAREQBERAEREAKIiAIiIAiIgK6WVERAEREAREQBES6AIiIAiIgCIiAIgF0QBOSWRAEREARL3RAEREAREQBERAEREARE5IAiIgCJfREAREQBERAES104IAiIgCIiAIlkCAIiBAEREAREQBERALIiIAiXRAEREAREQBERAEREAREQBEvdEAREQBERAAiIgCJxKFADxREQBERAEREAREQBCiIAiIgCJwRAEREAREQBERAEREAREsgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiJdAEREAREtdAEROSAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIgRAEREAREQBERAERAUAREtfVAEREAREQBERAEREAREQBERAEREARL6cEQBERAEREAREQBERAEREAREQBEQoAiIgCIiAIiE3QBERAEREAREQBERAEQGyIAiIgF0REAREQBERAEREAuiIgCIqi1uCAoiIgCIiAIiIAiIgCIiAIiIAiIgANkREAtdERAEREAREQBERAEREAREQBERAEREASyBCdUAQIiAIiIAiIgCXREAQoiAIiIAgFyiIAiIgCIiAA2REQBEQdUAREQBERAEREAREQBERAEREATiiIAiIgCIiAIiIAiIEAREQBERAEREAREQBERAEREAAuiIgCIiAIiE3QBERAEREAREQBERAEREAREQBERAEREAREQBEsiAIiIAiIgCIiAIiIAiIgCIiAIiIAl0RAEREAREQBLIgNkAREQBERAVPBUREAREQBERAEREAREQBERANEREAREQBERAEREAKIiAWulrIiAIiIAiIgCIiAIiIAiIgCIiAA2REQBERAEREAREQC1kQ6ogCIiAIiIAiIgFih0REAPJES9kAOhREQBERAEREAREQBERAEREAS9kRAL3REQBERAEREAREsgBREQBERAEREAREvogCIiAIiIAiIgCFEQBERAERAgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAcURLIAiIgCIiAIiIAiIgCWREAREQBERAAiIgCIeKIAiIgCIiAIiIAiIgCIiAIiIAiW0RAEREAREQBERAEsURAEROCAIiIAiIgFkREAREQBERAEREAREQBERAEREAREQBCiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIhRAEREAREQBERAEREARLIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiWRAEREAHNERAEREAREQBERAEREAREQBERAEREAREQBERAEREARCiAIiIAiIgCIiAIiIAhREAREQBERAEREAREQBERAEREAREQBERAEREAREQBERAEREAREQBERAEREAREQBLoiAIiIAiIgHJERAEREAREQBEuiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiIAiIgCIiAIiID/9k=]=]
        local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        local lookup = {}
        for i=1,64 do lookup[string.byte(alphabet,i)]=i-1 end
        local chunks = {}
        for i=1,#encoded,4 do
            local a,b,c,d=string.byte(encoded,i,i+3)
            local n=(lookup[a] or 0)*262144+(lookup[b] or 0)*4096+(lookup[c] or 0)*64+(lookup[d] or 0)
            local piece=string.char(math.floor(n/65536)%256)
            if c~=61 then piece=piece..string.char(math.floor(n/256)%256) end
            if d~=61 then piece=piece..string.char(n%256) end
            chunks[#chunks+1]=piece
        end
        local path="zekio_supreme_logo_v1.png"
        writefile(path,table.concat(chunks))
        return assetFn(path)
    end)
    if not ok or type(asset)~="string" or Session.Closed then return end
    bubble.Text=""
    bubble.BackgroundTransparency=1
    local artwork=make("ImageLabel",{Name="ZekioLogo",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Image=asset,ScaleType=Enum.ScaleType.Fit,Active=false,ZIndex=bubble.ZIndex+1},bubble)
    round(artwork,16)
end)

local toast=frame(window,UDim2.new(1,-28,0,63),"raised",{Position=UDim2.new(0,14,1,-106),ZIndex=100,Visible=false})
round(toast,10);outline(toast);UI.surface(toast,"floating")
label(toast,"Zekio Supreme",11,"accent",{Position=UDim2.fromOffset(12,8),Size=UDim2.new(1,-50,0,16),ZIndex=101,Font=Enum.Font.GothamBold})
local toastText=label(toast,"",11,"text",{Position=UDim2.fromOffset(12,26),Size=UDim2.new(1,-50,0,30),TextWrapped=true,ZIndex=101,TextYAlignment=Enum.TextYAlignment.Top})
local toastClose=button(toast,"×",UDim2.fromOffset(28,36),function() toast.Visible=false end,false)
toastClose.Position=UDim2.new(1,-35,0,10);toastClose.ZIndex=102
local popupShade=make("TextButton",{Name="PopupDismiss",Text="",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ZIndex=80,Visible=false},window)
local popup
function UI.closePopup()
    if popup then popup:Destroy();popup=nil end
    popupShade.Visible=false
end
connect(popupShade.MouseButton1Click,UI.closePopup)
function UI.notify(message)
    if not alive() then return end
    if V["ui.notifications"]==false then toast.Visible=false;return end
    toastText.Text=message;toast.Visible=true
end

function UI.drawer(open)
    UI.Drawer=UI.Compact and open or false
    side.Visible=not UI.Compact or UI.Drawer
    side.ZIndex=UI.Compact and 40 or 1
    shade.Visible=UI.Drawer
end
local function disconnectPage()
    if Session.UnmountControls then Session.UnmountControls() end
    for _,c in ipairs(Session.PageConnections) do c:Disconnect() end
    Session.PageConnections={};Session.Controls={};Session.SectionButtons={};Session.ActiveSlider=nil
    UI.closePopup()
end
function UI.dropdown(anchor, choices, selected, callback)
    UI.closePopup();popupShade.Visible=true
    local factor=math.max(.01,UI.Scale)
    local w=math.min(math.max(anchor.AbsoluteSize.X/factor,170),UI.Width-24)
    local h=math.min(#choices*38+12,240,UI.Height-110)
    local anchorX=(anchor.AbsolutePosition.X-window.AbsolutePosition.X)/factor
    local anchorY=(anchor.AbsolutePosition.Y-window.AbsolutePosition.Y)/factor
    local x=math.clamp(anchorX,12,math.max(12,UI.Width-w-12))
    local y=anchorY+anchor.AbsoluteSize.Y/factor+4
    if y+h>UI.Height-36 then y=math.max(72,anchorY-h-4) end
    y=math.clamp(y,8,math.max(8,UI.Height-h-36))
    popup=frame(window,UDim2.fromOffset(w,h),"card",{Position=UDim2.fromOffset(x,y),ZIndex=81,Name="DropdownPopup"})
    round(popup,10);outline(popup);UI.surface(popup,"floating")
    local scroll=make("ScrollingFrame",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=2,CanvasSize=UDim2.fromOffset(0,#choices*38+12),AutomaticCanvasSize=Enum.AutomaticSize.None,ScrollingDirection=Enum.ScrollingDirection.Y,ClipsDescendants=true,ZIndex=82},popup)
    padding(scroll,6);stack(scroll,3)
    for _,entry in ipairs(choices) do
        local choice=entry
        local b=button(scroll,choice,UDim2.fromOffset(w-16,35),function() UI.closePopup();callback(choice) end,choice==selected,true)
        b.ZIndex=83;b.TextXAlignment=Enum.TextXAlignment.Left;padding(b,10)
    end
end
-- Measure rendered child heights, then convert once to unscaled UI units.
-- Scroll canvases keep X=0; no descendant is allowed to grow the canvas width.
function UI.fitStack(container, layout, gap, callback, pageScope)
    local busy=false
    local watched=setmetatable({}, {__mode="k"})
    local resize
    local function watch(child)
        if child:IsA("GuiObject") and not watched[child] then
            watched[child]=true
            connect(child:GetPropertyChangedSignal("AbsoluteSize"),function() resize() end,pageScope)
            connect(child:GetPropertyChangedSignal("Visible"),function() resize() end,pageScope)
        end
    end
    resize=function()
        if busy or not alive() or not container.Parent then return end
        busy=true
        local total,count=0,0
        local _=layout.AbsoluteContentSize
        for _,child in ipairs(container:GetChildren()) do
            watch(child)
            if child:IsA("GuiObject") and child.Visible then
                total=total+child.AbsoluteSize.Y/math.max(.01,UI.Scale)
                count=count+1
            end
        end
        callback(math.ceil(total+gap*math.max(0,count-1)))
        busy=false
    end
    connect(container.ChildAdded,function(child) watch(child);resize() end,pageScope)
    connect(container.ChildRemoved,resize,pageScope)
    connect(layout:GetPropertyChangedSignal("AbsoluteContentSize"),resize,pageScope)
    connect(windowScale:GetPropertyChangedSignal("Scale"),resize,pageScope)
    resize()
    return resize
end
UI.fitStack(nav,navLayout,4,function(height)
    if nav.Size.Y.Offset~=height then nav.Size=UDim2.fromOffset(146,height) end
    side.CanvasSize=UDim2.fromOffset(0,height+20)
end,false)

local function caption(parent, text, height)
    return label(parent,text,12,"muted",{Size=UDim2.new(1,0,0,height or 30),TextWrapped=true,TextYAlignment=Enum.TextYAlignment.Top})
end
local function card(parent,titleText)
    local key=UI.Page..":"..titleText
    if Session.Sections[key]==nil then Session.Sections[key]=true end
    local cardFrame=frame(parent,UDim2.new(1,0,0,54),"card",{Name="ContentCard"})
    round(cardFrame,12);outline(cardFrame)
    local headerButton=button(cardFrame,"",UDim2.new(1,-28,0,36),nil,false,true)
    headerButton.Name="SectionToggle_"..key
    headerButton.Position=UDim2.fromOffset(14,8)
    headerButton.BackgroundTransparency=1
    UI.icon(headerButton,UI.Page,0,9,18,"accent")
    label(headerButton,titleText,13,"text",{Position=UDim2.fromOffset(26,0),Size=UDim2.new(1,-54,1,0),Font=Enum.Font.GothamBold,TextWrapped=true})
    local arrow=label(headerButton,"−",18,"accent",{Position=UDim2.new(1,-24,0,0),Size=UDim2.fromOffset(24,36),TextXAlignment=Enum.TextXAlignment.Right})
    local inner=frame(cardFrame,UDim2.new(1,-28,0,0),nil,{Name="CardContent",Position=UDim2.fromOffset(14,50)})
    local layout=stack(inner,12)
    local contentHeight=0
    local function applyState()
        local open=Session.Sections[key]==true
        inner.Visible=open
        arrow.Text=open and "−" or "+"
        local height=open and (contentHeight+64) or 54
        if cardFrame.Size.Y.Offset~=height then cardFrame.Size=UDim2.new(1,0,0,height) end
    end
    local measure=UI.fitStack(inner,layout,12,function(height)
        contentHeight=height
        if inner.Size.Y.Offset~=height then inner.Size=UDim2.new(1,-28,0,height) end
        applyState()
    end,true)
    connect(headerButton.MouseButton1Click,function()
        if not alive() or not cardFrame.Parent then return end
        UI.closePopup()
        Session.Sections[key]=not Session.Sections[key]
        applyState()
        if Session.Sections[key] then measure() end
    end,true)
    Session.SectionButtons[key]=headerButton
    applyState()
    return inner
end

local function displayRow(parent,left,right)
    local row=frame(parent,UDim2.new(1,0,0,40),nil)
    label(row,left,12,"muted",{Size=UDim2.new(.45,-6,1,0),TextWrapped=true})
    label(row,right,12,"text",{Position=UDim2.new(.45,6,0,0),Size=UDim2.new(.55,-6,1,0),TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Right})
end
-- Native premium controls keep their models alive while pages are unmounted.
-- The gameplay engine registers its real callbacks through this interface.
Session.EngineReady=false
Session.EngineControls={}
Session.Mounted={}
Session.RegistrationErrors={}
local route={Farm="farm",Farmer="farmer",Pabrik="pabrik",["Dirt Farm"]="dirt",["Clear World"]="clear",Splice="splice",
    ["Titik Drop"]="drop",Growscan="growscan",Tas="inventory",Vending="vending",["Auto Chat"]="chat",Bonus="bonus",
    Penjaga="security",Pengaturan="settings",Statistik="stats",Koneksi="connection",Discord="discord",["Auto Rejoin"]="rejoin"}
local function copyValue(v)
    return type(v)=="table" and table.clone(v) or v
end
local function sameValue(a,b)
    if type(a)~="table" or type(b)~="table" then return a==b end
    if #a~=#b then return false end
    for i,v in ipairs(a) do if v~=b[i] then return false end end
    return true
end
local function paint(model)
    local bind=model.Bind
    if bind and bind.root and bind.root.Parent and alive() then bind.update() end
end
local function invoke(model,...)
    if not alive() then return false end
    if not model.Builtin and not Session.EngineReady then UI.notify("Data game masih dimuat. Lihat Ringkasan.");return false end
    if type(model.Callback)~="function" then return true end
    local args=table.pack(...)
    local ok,err=xpcall(function() model.Callback(table.unpack(args,1,args.n)) end,function(e) return tostring(e) end)
    if not ok then UI.notify(model.Title..": "..tostring(err):sub(1,360));warn("[Zekio Premium] "..tostring(err)) end
    return ok
end
local Methods={}
function Methods:Set(v)
    if self.Kind=="Toggle" then v=v==true
    elseif self.Kind=="Input" then v=tostring(v or "")
    elseif self.Kind=="Slider" then
        v=tonumber(v);if not v then return end
        v=math.clamp(self.Min+math.floor((v-self.Min)/self.Step+.5)*self.Step,self.Min,self.Max)
    elseif self.Kind=="Dropdown" and self.Multi then
        v=type(v)=="table" and table.clone(v) or (v~=nil and {v} or {})
    end
    local previous=self.Value
    self.Value=copyValue(v);self.Draft=nil;paint(self)
    if not sameValue(previous,v) then
        if not invoke(self,copyValue(v)) and self.Kind=="Toggle" and self.Value==v then self.Value=previous;paint(self) end
    end
    return self
end
function Methods:Select(v) return self:Set(v) end
function Methods:Refresh(values)
    self.Choices=type(values)=="table" and table.clone(values) or {}
    paint(self)
    if Session.PopupModel==self and UI.PopupRefresh then UI.PopupRefresh() end
    return self
end
function Methods:SetDesc(text) self.Desc=tostring(text or "");paint(self);return self end
function Methods:SetTitle(text) self.Title=tostring(text or "");paint(self);return self end
function Methods:Fire()
    if self.Busy then return end
    self.Busy=true;paint(self)
    task.spawn(function() invoke(self);self.Busy=false;paint(self) end)
end
local Containers={}
local function register(container,kind,cfg)
    cfg=cfg or {}
    local model=setmetatable({Kind=kind,Title=tostring(cfg.Title or ""),Desc=tostring(cfg.Desc or ""),
        Callback=cfg.Callback,Value=copyValue(cfg.Value),Choices=table.clone(cfg.Values or {}),Multi=cfg.Multi==true,
        Placeholder=cfg.Placeholder or "",Builtin=container.Builtin,Page=container.Page}, {__index=Methods})
    if kind=="Toggle" then model.Value=cfg.Value==true end
    if kind=="Input" then model.Value=tostring(cfg.Value or "") end
    if kind=="Dropdown" and model.Multi then model.Value=type(cfg.Value)=="table" and table.clone(cfg.Value) or (cfg.Value~=nil and {cfg.Value} or {}) end
    if kind=="Slider" then
        local v=type(cfg.Value)=="table" and cfg.Value or {}
        model.Min,model.Max=tonumber(v.Min) or 0,tonumber(v.Max) or 100
        model.Step=math.max(.001,tonumber(cfg.Step) or 1)
        model.Value=math.clamp(tonumber(v.Default) or model.Min,model.Min,model.Max)
    end
    model.Id=container.Page..":"..tostring(#Session.EngineControls+1)
    container.Nodes[#container.Nodes+1]=model
    Session.EngineControls[#Session.EngineControls+1]=model
    return model
end
for _,kind in ipairs({"Paragraph","Button","Toggle","Input","Dropdown","Slider"}) do
    local controlKind=kind
    Containers[kind]=function(self,cfg) return register(self,controlKind,cfg) end
end
function Containers:Section(cfg)
    cfg=cfg or {}
    local node={Kind="Section",Title=tostring(cfg.Title or "Pengaturan"),Nodes={},Page=self.Page,Builtin=self.Builtin}
    self.Nodes[#self.Nodes+1]=node
    local key=self.Page..":"..node.Title
    if Session.Sections[key]==nil then Session.Sections[key]=cfg.Opened~=false end
    return setmetatable(node,{__index=Containers})
end
function Session.CreateTab(titleText)
    local id=assert(route[titleText],"Menu engine belum dipetakan: "..tostring(titleText))
    local page=assert(PAGES[id],"Halaman tidak tersedia: "..id)
    page.Loaded=true
    if not page.Container then page.Container=setmetatable({Page=id,Nodes=page.nodes},{__index=Containers}) end
    return page.Container
end
local function builtin(id)
    return setmetatable({Page=id,Nodes=PAGES[id].nodes,Builtin=true},{__index=Containers})
end
function Session.CommitInputs()
    for _,model in ipairs(Session.Mounted) do
        if model.Kind=="Input" and model.Draft~=nil then model:Set(model.Draft) end
    end
end
function Session.UnmountControls()
    Session.CommitInputs()
    for _,model in ipairs(Session.Mounted) do model.Bind=nil;model.PaintValue=nil end
    Session.Mounted={}
end

local originalClosePopup=UI.closePopup
function UI.closePopup()
    for _,c in ipairs(UI.PopupConnections or {}) do c:Disconnect() end
    for _,c in ipairs(UI.PopupRows or {}) do c:Disconnect() end
    UI.PopupConnections={};UI.PopupRows={};UI.PopupRefresh=nil;Session.PopupModel=nil
    originalClosePopup()
end
function UI.selectPopup(anchor,model)
    UI.closePopup();popupShade.Visible=true;Session.PopupModel=model
    local factor=math.max(.01,UI.Scale)
    local w=math.min(math.max(anchor.AbsoluteSize.X/factor,220),UI.Width-24)
    local h=math.min(290,UI.Height-112)
    local x=math.clamp((anchor.AbsolutePosition.X-window.AbsolutePosition.X)/factor,12,math.max(12,UI.Width-w-12))
    local ay=(anchor.AbsolutePosition.Y-window.AbsolutePosition.Y)/factor
    local y=ay+anchor.AbsoluteSize.Y/factor+4
    if y+h>UI.Height-36 then y=math.max(72,ay-h-4) end
    y=math.clamp(y,8,math.max(8,UI.Height-h-36))
    popup=frame(window,UDim2.fromOffset(w,h),"card",{Name="DropdownPopup",Position=UDim2.fromOffset(x,y),ZIndex=81})
    round(popup,10);outline(popup);UI.surface(popup,"floating")
    label(popup,model.Multi and "Pilih beberapa item" or "Pilih item",11,"accent",{Position=UDim2.fromOffset(10,7),Size=UDim2.new(1,-78,0,20),ZIndex=82})
    local done=button(popup,"Selesai",UDim2.fromOffset(64,26),nil,false)
    done.Position=UDim2.new(1,-72,0,5);done.ZIndex=83
    UI.PopupConnections[#UI.PopupConnections+1]=done.MouseButton1Click:Connect(UI.closePopup)
    local search=make("TextBox",{Name="DropdownSearch",Text="",PlaceholderText="Cari nama atau ID…",ClearTextOnFocus=false,TextSize=12,
        Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,Size=UDim2.new(1,-20,0,32),Position=UDim2.fromOffset(10,37),BorderSizePixel=0,ZIndex=82},popup)
    UI.surface(search,"control");UI.tint(search,"BackgroundColor3","input");UI.tint(search,"TextColor3","text");UI.tint(search,"PlaceholderColor3","muted");round(search,7);padding(search,8)
    local scroll=make("ScrollingFrame",{Name="DropdownChoices",BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(8,77),Size=UDim2.new(1,-16,1,-100),
        ScrollBarThickness=3,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.None,ScrollingDirection=Enum.ScrollingDirection.Y,ClipsDescendants=true,ZIndex=82},popup)
    UI.tint(scroll,"ScrollBarImageColor3","accent")
    local limitText=label(popup,"",10,"muted",{Position=UDim2.new(0,10,1,-20),Size=UDim2.new(1,-20,0,16),ZIndex=82})
    local function render()
        if not popup or not scroll.Parent then return end
        for _,c in ipairs(UI.PopupRows) do c:Disconnect() end
        UI.PopupRows={}
        for _,child in ipairs(scroll:GetChildren()) do child:Destroy() end
        local query=string.lower(search.Text or "")
        local matches,shown=0,0
        for _,raw in ipairs(model.Choices) do
            local entry=raw
            if query=="" or string.find(string.lower(tostring(entry)),query,1,true) then
                matches+=1
                if shown<160 then
                    local chosen=model.Multi and table.find(model.Value or {},entry)~=nil or (not model.Multi and model.Value==entry)
                    local b=button(scroll,(chosen and "✓  " or "")..tostring(entry),UDim2.fromOffset(w-34,34),nil,chosen)
                    b.Name="DropdownChoice";b.TextWrapped=true;b.Position=UDim2.fromOffset(2,shown*38);b.ZIndex=83
                    UI.PopupRows[#UI.PopupRows+1]=b.MouseButton1Click:Connect(function()
                        if not alive() then return end
                        if model.Multi then
                            local values=table.clone(model.Value or {})
                            local at=table.find(values,entry)
                            if at then table.remove(values,at) else values[#values+1]=entry end
                            model:Select(values);render()
                        else model:Select(entry);UI.closePopup() end
                    end)
                    shown+=1
                end
            end
        end
        scroll.CanvasSize=UDim2.fromOffset(0,shown*38)
        limitText.Text=matches>shown and ("Tampil "..shown.." dari "..matches.."; persempit pencarian") or (tostring(matches).." pilihan")
    end
    UI.PopupRefresh=render
    UI.PopupConnections[#UI.PopupConnections+1]=search:GetPropertyChangedSignal("Text"):Connect(function() scroll.CanvasPosition=Vector2.new();render() end)
    render()
end

function UI.renderModel(parent,model)
    if model.Kind=="Section" then
        local inner=card(parent,model.Title)
        for _,child in ipairs(model.Nodes) do UI.renderModel(inner,child) end
        return
    end
    local wrap,texts,titleLabel,descLabel,widget
    if model.Kind=="Paragraph" then
        wrap=card(parent,model.Title)
        descLabel=label(wrap,model.Desc,12,"muted",{Size=UDim2.new(1,0,0,18),AutomaticSize=Enum.AutomaticSize.Y,TextWrapped=true,TextYAlignment=Enum.TextYAlignment.Top})
    else
        wrap=frame(parent,UDim2.new(1,0,0,54),nil,{Name="Control_"..model.Id})
        texts=frame(wrap,UDim2.new(1,model.Kind=="Toggle" and -58 or 0,0,0),nil)
        local textLayout=stack(texts,5)
        titleLabel=label(texts,model.Title,12,"text",{Size=UDim2.new(1,0,0,18),AutomaticSize=Enum.AutomaticSize.Y,TextWrapped=true,Font=Enum.Font.GothamBold})
        descLabel=label(texts,model.Desc,11,"muted",{Size=UDim2.new(1,0,0,15),AutomaticSize=Enum.AutomaticSize.Y,TextWrapped=true,Visible=model.Desc~="",TextYAlignment=Enum.TextYAlignment.Top})
        UI.fitStack(texts,textLayout,5,function(h)
            texts.Size=UDim2.new(1,model.Kind=="Toggle" and -58 or 0,0,h)
            local extra=(model.Kind=="Toggle") and 12 or 54
            local minimum=model.Kind=="Toggle" and 52 or (model.Kind=="Button" and 54 or 72)
            wrap.Size=UDim2.new(1,0,0,math.max(minimum,h+extra))
            if widget and model.Kind~="Toggle" then widget.Position=UDim2.fromOffset(0,h+8) end
        end,true)
        if model.Kind=="Toggle" then
            widget=make("TextButton",{Text="",Name="ToggleHit",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),AutoButtonColor=false,ZIndex=4},wrap)
            local switch=frame(wrap,UDim2.fromOffset(38,22),"line",{Position=UDim2.new(1,-42,0,12),ZIndex=3});round(switch,20)
            local knob=frame(switch,UDim2.fromOffset(16,16),"card",{Position=UDim2.fromOffset(3,3),ZIndex=3});round(knob,12)
            model.PaintValue=function()
                UI.tint(switch,"BackgroundColor3",model.Value and "accent" or "line")
                UI.tint(knob,"BackgroundColor3",model.Value and "onAccent" or "card")
                knob.Position=UDim2.fromOffset(model.Value and 19 or 3,3)
            end
            connect(widget.MouseButton1Click,function() task.spawn(function() model:Set(not model.Value) end) end,true)
        elseif model.Kind=="Input" then
            widget=make("TextBox",{Text=tostring(model.Value or ""),PlaceholderText=model.Placeholder,ClearTextOnFocus=false,Font=Enum.Font.Gotham,TextSize=12,
                TextXAlignment=Enum.TextXAlignment.Left,BorderSizePixel=0,Size=UDim2.new(1,0,0,40)},wrap)
            UI.surface(widget,"control");UI.tint(widget,"BackgroundColor3","input");UI.tint(widget,"TextColor3","text");UI.tint(widget,"PlaceholderColor3","muted");round(widget,8);outline(widget);padding(widget,10)
            connect(widget:GetPropertyChangedSignal("Text"),function() model.Draft=widget.Text end,true)
            connect(widget.FocusLost,function() model:Set(widget.Text) end,true)
            model.PaintValue=function() if model.Draft==nil and widget.Text~=model.Value then widget.Text=tostring(model.Value or "") end end
        elseif model.Kind=="Slider" then
            widget=frame(wrap,UDim2.new(1,0,0,40),nil)
            local track=frame(widget,UDim2.new(1,-65,0,5),"line",{Position=UDim2.fromOffset(0,18)});round(track,4)
            local fill=frame(track,UDim2.new(0,0,1,0),"accent");round(fill,4)
            local knob=frame(track,UDim2.fromOffset(15,15),"accent",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(0,0,.5,0)});round(knob,10)
            local number=label(widget,"",11,"accent",{Position=UDim2.new(1,-58,0,8),Size=UDim2.fromOffset(58,24),TextXAlignment=Enum.TextXAlignment.Right})
            local hit=make("TextButton",{Text="",BackgroundTransparency=1,AutoButtonColor=false,Size=UDim2.new(1,-65,1,0),ZIndex=4},widget)
            model.PaintValue=function()
                local ratio=(model.Value-model.Min)/math.max(.001,model.Max-model.Min)
                fill.Size=UDim2.new(ratio,0,1,0);knob.Position=UDim2.new(ratio,0,.5,0)
                number.Text=tostring(math.floor(model.Value*1000+.5)/1000)
            end
            local function update(x)
                local ratio=math.clamp((x-track.AbsolutePosition.X)/math.max(1,track.AbsoluteSize.X),0,1)
                model:Set(model.Min+ratio*(model.Max-model.Min))
            end
            connect(hit.InputBegan,function(input)
                if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
                    Session.Drag=nil;Session.ActiveSlider={input=input,update=update};update(input.Position.X)
                end
            end,true)
        else
            widget=button(wrap,"",UDim2.new(1,0,0,40),nil,model.Kind=="Button",true)
            widget.TextWrapped=true
            if model.Kind=="Dropdown" then
                model.PaintValue=function()
                    local text=type(model.Value)=="table" and (#model.Value>0 and table.concat(model.Value,", ") or "Tanpa filter") or tostring(model.Value or "Pilih item")
                    widget.Text=(#text>85 and text:sub(1,82).."…" or text).."  ▾"
                end
                connect(widget.MouseButton1Click,function() UI.selectPopup(widget,model) end,true)
            else
                model.PaintValue=function() widget.Text=model.Busy and "Memproses…" or model.Title end
                titleLabel.Visible=false
                connect(widget.MouseButton1Click,function() model:Fire() end,true)
            end
        end
        if widget and model.Kind~="Toggle" then widget.Position=UDim2.fromOffset(0,texts.Size.Y.Offset+8) end
    end
    model.Bind={root=wrap,widget=widget,update=function()
        if titleLabel then titleLabel.Text=model.Title end
        if descLabel then descLabel.Text=model.Desc:sub(1,24000);descLabel.Visible=model.Kind=="Paragraph" or model.Desc~="" end
        if model.PaintValue then model.PaintValue() end
    end}
    Session.Mounted[#Session.Mounted+1]=model
    Session.Controls[model.Id]=widget or descLabel
    paint(model)
end

local overview=builtin("overview")
local bootModel=overview:Paragraph({Title="Status sesi",Desc="Menyiapkan data Growblox…"})
local activityModel=overview:Paragraph({Title="Aktivitas",Desc="Menunggu koneksi ke world…"})
function Session.UpdateSummary(text) activityModel:SetDesc(text) end
local quick=overview:Section({Title="Akses cepat",Opened=true})
for _,id in ipairs({"farmer","pabrik","dirt","clear"}) do
    local target=id
    quick:Button({Title=PAGES[id].title,Callback=function() UI.show(target,"farming") end})
end
function Session.SetBootStatus(text) bootModel:SetDesc(tostring(text)) end
function Session.SetEngineReady()
    Session.EngineReady=true
    local count=0
    for _,m in ipairs(Session.EngineControls) do if not m.Builtin then count+=1 end end
    local summary=#Session.RegistrationErrors==0 and "Menu siap" or ("Menu dimuat; "..#Session.RegistrationErrors.." bagian gagal dibuat")
    local connection = Session.ConnectionError and ("\nKoneksi gagal: "..Session.ConnectionError)
        or "\nPeriksa tab Koneksi bila data game belum terbaca."
    bootModel:SetDesc(summary.." • "..count.." kontrol tersedia"..connection.."\nSalinan tes tanpa key")
    UI.show(UI.Page)
end
function Session.RecordRegistrationError(message)
    Session.RegistrationErrors[#Session.RegistrationErrors+1]=tostring(message)
    warn("[Zekio Premium UI] "..tostring(message))
end
local appearance=builtin("settings"):Section({Title="Tampilan premium",Opened=true})
local themeControl=appearance:Dropdown({Title="Tema UI",Values={"Gelap","Terang"},Value="Gelap",Callback=function(v) V["ui.theme"]=v;UI.theme(v) end})
local scaleControl=appearance:Slider({Title="Ukuran UI (%)",Value={Min=70,Max=100,Default=value("ui.scale",100)},Step=5,Callback=function(v) V["ui.scale"]=v;UI.layout() end})
local transparencyControl=appearance:Slider({Title="Transparansi UI (%)",Desc="Latar panel saja; tulisan dan ikon tetap jelas",Value={Min=0,Max=40,Default=value("ui.transparency",18)},Step=1,Callback=UI.setTransparency})
local noticeControl=appearance:Toggle({Title="Notifikasi UI",Value=true,Callback=function(v) V["ui.notifications"]=v;if not v then toast.Visible=false end end})
function Session.ApplyAppearance()
    -- Apply the requested size once when upgrading a saved P6 configuration.
    if V["ui.layoutRevision"]~=7 then
        V["ui.layoutRevision"]=7;V["ui.scale"]=100
        if V["ui.transparency"]==nil then V["ui.transparency"]=18 end
    end
    local theme=COLORS[V["ui.theme"]] and V["ui.theme"] or "Gelap"
    local scale=math.clamp(tonumber(V["ui.scale"]) or 100,70,100)
    V["ui.theme"],V["ui.scale"]=theme,scale
    themeControl:Select(theme);scaleControl:Set(scale);noticeControl:Set(V["ui.notifications"]~=false)
    transparencyControl:Set(math.clamp(tonumber(V["ui.transparency"]) or 18,0,40))
    UI.setTransparency(V["ui.transparency"])
    UI.theme(theme);UI.layout()
end
-- Proxy listens only while this premium session is active.
do
    local tab = builtin("proxy")
    local pullInfo = tab:Paragraph({Title="Status Fast Pull", Desc="Mati. Nyalakan setelah data game siap."})
    function Session.SetProxyPullStatus(text)
        if alive() then pcall(function() pullInfo:SetDesc(tostring(text)) end) end
    end
    local fastToggle, pullGeneration = nil, 0
    fastToggle = tab:Toggle({Title="Fast Pull melalui wrench", Desc="Coba pull pemain yang di-wrench saat target dikenali.", Value=false,
        Callback=function(on)
            pullGeneration = pullGeneration + 1
            local generation = pullGeneration
            if not on then
                if Session.ProxyStop then Session.ProxyStop() end
                Session.SetProxyPullStatus("Fast Pull mati.")
                return
            end
            if not Session.ProxyStart then
                task.defer(function()
                    if alive() and generation == pullGeneration then
                        fastToggle:Set(false)
                        Session.SetProxyPullStatus("Data game belum siap. Tunggu koneksi, lalu coba lagi.")
                    end
                end)
                return
            end
            local ok, started, why = pcall(Session.ProxyStart)
            if not ok or not started then
                local message = ok and tostring(why or "Mekanisme wrench tidak tersedia.") or tostring(started)
                task.defer(function()
                    if alive() and generation == pullGeneration then fastToggle:Set(false); Session.SetProxyPullStatus(message) end
                end)
            end
        end})
end

local account=builtin("key")
account:Paragraph({Title="Akun",Desc=tostring(player.DisplayName or player.Name or "Pemain").."\nUsername: "..tostring(player.Name or "—").."\nUser ID: "..tostring(player.UserId or "—")})
account:Paragraph({Title="Versi tes",Desc="Salinan Premium tanpa key untuk pengujian."})
builtin("updates"):Paragraph({Title="Premium P15",Desc="Proxy: Fast Pull melalui wrench (percobaan).\nUkuran panel mengikuti UI lama dan latar sedikit transparan.\nFungsi versi utama r29 dihubungkan ke UI premium.\nFarm, Farmer, Pabrik, Dirt Farm, Clear World, collect dan drop seed.\nSplice, Vending, Tas, Growscan, Auto Chat, Bonus, Penjaga, konfigurasi, reconnect dan notifikasi Discord.\nMenu Teleport ID Door dihapus."})

Session.EngineUI={}
function Session.EngineUI:CreateWindow()
    return {Open=function() window.Visible=true;bubble.Visible=false end,EditOpenButton=function() end,
        Destroy=function() if not Session.Closed then Session.Cleanup() end end}
end
function Session.EngineUI:Notify(cfg) UI.notify(tostring(cfg.Title or "Zekio Supreme")..": "..tostring(cfg.Content or "")) end
function Session.AttachGrid(grid)
    local restore=false
    grid.DisplayOrder=gui.DisplayOrder+1
    connect(grid:GetPropertyChangedSignal("Enabled"),function()
        if not alive() then return end
        if grid.Enabled then
            restore=window.Visible;window.Visible=false;bubble.Visible=true
        elseif restore then
            restore=false;window.Visible=true;bubble.Visible=false
        end
    end)
end


local pageRoot
function UI.navigation()
    for _,child in ipairs(nav:GetChildren()) do if not child:IsA("UIListLayout") then child:Destroy() end end
    for _,c in ipairs(UI.NavConnections or {}) do c:Disconnect() end
    UI.NavConnections={}
    local function navButton(text,id,groupId)
        local b=button(nav,text,UDim2.new(1,0,0,37),nil,UI.Page==id,false)
        b.Name="Nav_"..id
        UI.menuLabel(b,PAGES[id].title,id,37,UI.Page==id,false,id=="overview")
        UI.NavConnections[#UI.NavConnections+1]=b.MouseButton1Click:Connect(function() if alive() then UI.show(id,groupId) end end)
    end
    navButton("Ringkasan","overview")
    for _,g in ipairs(GROUPS) do
        if g.direct then
            navButton(g.title,g.direct,g.id)
        else
        local section=g
        local expanded=UI.Group==g.id
        local b=button(nav,g.title.."   "..(expanded and "−" or "+"),UDim2.new(1,0,0,39),nil,false,false)
        b.Name="NavGroup_"..g.id
        UI.menuLabel(b,g.title,g.id,39,false,true,true)
        label(b,expanded and "−" or "+",16,"accent",{Name="GroupArrow",Position=UDim2.new(1,-22,0,0),Size=UDim2.fromOffset(12,39),TextXAlignment=Enum.TextXAlignment.Right,Active=false})
        UI.NavConnections[#UI.NavConnections+1]=b.MouseButton1Click:Connect(function()
            if not alive() then return end
            if UI.Group==section.id then
                UI.Group=nil
            else
                UI.Group=section.id
            end
            UI.navigation()
        end)
        if expanded then for _,id in ipairs(g.pages) do navButton("  "..PAGES[id].title,id,g.id) end end
        end
    end
    label(nav,"PREMIUM  •  P15",11,"muted",{Size=UDim2.new(1,0,0,34)})
end
function UI.show(id,groupId)
    if not alive() or not PAGES[id] then return end
    UI.Page=id
    if groupId then UI.Group=groupId else for _,g in ipairs(GROUPS) do if table.find(g.pages,id) then UI.Group=g.id end end end
    disconnectPage()
    if pageRoot then pageRoot:Destroy() end
    pageRoot=frame(content,UDim2.fromOffset(UI.PageWidth or 509,0),nil,{Position=UDim2.fromOffset(16,16),Name="Page_"..id})
    local pageLayout=stack(pageRoot,14)
    UI.fitStack(pageRoot,pageLayout,14,function(height)
        local width=UI.PageWidth or 509
        if pageRoot.Size.Y.Offset~=height or pageRoot.Size.X.Offset~=width then pageRoot.Size=UDim2.fromOffset(width,height) end
        content.CanvasSize=UDim2.fromOffset(0,height+32)
    end,true)
    local page=PAGES[id]
    local heading=frame(pageRoot,UDim2.new(1,0,0,66),nil,{AutomaticSize=Enum.AutomaticSize.Y})
    local badge=frame(heading,UDim2.fromOffset(40,40),"soft",{Name="PageIconBadge",Position=UDim2.fromOffset(0,2),Active=false})
    round(badge,11)
    UI.icon(badge,id,8,8,24,"accent")
    label(heading,page.title,21,"text",{Position=UDim2.fromOffset(52,0),Size=UDim2.new(1,-52,0,28),Font=Enum.Font.GothamBold})
    label(heading,page.subtitle,12,"muted",{Position=UDim2.fromOffset(52,35),Size=UDim2.new(1,-52,0,0),AutomaticSize=Enum.AutomaticSize.Y,TextWrapped=true,TextYAlignment=Enum.TextYAlignment.Top})
    if #page.nodes==0 then
        local pending=card(pageRoot,"Memuat fitur")
        label(pending,"Menunggu data game dan kontrol fitur…",12,"muted",{Size=UDim2.new(1,0,0,36),TextWrapped=true})
    else
        for _,node in ipairs(page.nodes) do UI.renderModel(pageRoot,node) end
    end
    content.CanvasPosition=Vector2.new(0,0)
    UI.navigation();UI.drawer(false);UI.theme(UI.Theme)
    Session.CurrentPage=id
end
Session.ShowPage=function(id) UI.show(id) end
function UI.layout()
    if not alive() then return end
    UI.closePopup()
    local viewport=root.AbsoluteSize
    local vw=viewport.X>0 and viewport.X or 800
    local vh=viewport.Y>0 and viewport.Y or 600
    local portrait=vh>vw
    UI.Compact=portrait or vw<620
    local w=portrait and math.min(380,math.max(260,vw-32)) or 640
    local h=portrait and 500 or 380
    local fit=math.min(1,math.max(1,vw-32)/w,math.max(1,vh-32)/h)
    local zoom=math.clamp(tonumber(value("ui.scale",100)) or 100,70,100)/100
    UI.Scale,UI.Width,UI.Height=math.max(.01,fit*zoom),w,h
    local renderedW,renderedH=w*UI.Scale,h*UI.Scale
    local first=not UI.Positioned
    local x=first and (vw-renderedW)/2 or host.Position.X.Offset
    local y=first and (vh-renderedH)/2 or host.Position.Y.Offset
    host.Size=UDim2.fromOffset(renderedW,renderedH)
    host.Position=UDim2.fromOffset(math.clamp(x,8,math.max(8,vw-renderedW-8)),math.clamp(y,8,math.max(8,vh-renderedH-8)))
    window.Size=UDim2.fromOffset(w,h)
    windowScale.Scale=UI.Scale
    UI.Positioned=true
    side.Size=UDim2.new(0,170,1,0);sideLine.Visible=not UI.Compact
    content.Position=UDim2.fromOffset(UI.Compact and 0 or 171,0)
    content.Size=UDim2.new(1,UI.Compact and 0 or -171,1,0)
    UI.PageWidth=math.max(100,w-(UI.Compact and 0 or 171)-40)
    if pageRoot then pageRoot.Size=UDim2.fromOffset(UI.PageWidth,pageRoot.Size.Y.Offset) end
    menuButton.Visible=UI.Compact;logo.Visible=not UI.Compact
    title.Position=UDim2.fromOffset(UI.Compact and 54 or 65,13)
    title.Size=UDim2.new(1,UI.Compact and -151 or -170,0,23)
    title.TextSize=UI.Compact and 14 or 17
    edition.Position=UDim2.fromOffset(UI.Compact and 54 or 65,38)
    edition.Text=UI.Compact and "PREMIUM" or "PREMIUM  •  GROWBLOX"
    dragArea.Position=UDim2.fromOffset(54,0);dragArea.Size=UDim2.new(1,-148,1,0)
    footerText.Text=UI.Compact and "Zekio Supreme Premium" or "Zekio Supreme Premium • Growblox"
    UI.drawer(false)
    Session.Layout={Width=w,Height=h,Scale=UI.Scale,RenderedWidth=renderedW,RenderedHeight=renderedH,ViewportWidth=vw,ViewportHeight=vh,PageWidth=UI.PageWidth}
end

connect(root:GetPropertyChangedSignal("AbsoluteSize"),UI.layout)
connect(content:GetPropertyChangedSignal("CanvasPosition"),UI.closePopup)
connect(dragArea.InputBegan,function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
        UI.closePopup();Session.ActiveSlider=nil
        Session.Drag={input=input,x=input.Position.X,y=input.Position.Y,startX=host.Position.X.Offset,startY=host.Position.Y.Offset}
    end
end)
connect(Input.InputChanged,function(input)
    if not alive() then return end
    local slider=Session.ActiveSlider
    if slider and (input==slider.input or input.UserInputType==Enum.UserInputType.MouseMovement) then slider.update(input.Position.X);return end
    local drag=Session.Drag
    if drag and (input==drag.input or input.UserInputType==Enum.UserInputType.MouseMovement) then
        local vp=root.AbsoluteSize
        host.Position=UDim2.fromOffset(math.clamp(drag.startX+input.Position.X-drag.x,8,math.max(8,vp.X-host.AbsoluteSize.X-8)),math.clamp(drag.startY+input.Position.Y-drag.y,8,math.max(8,vp.Y-host.AbsoluteSize.Y-8)))
    end
end)
connect(Input.InputEnded,function(input)
    if Session.ActiveSlider and (input==Session.ActiveSlider.input or input.UserInputType==Enum.UserInputType.MouseButton1) then Session.ActiveSlider=nil end
    if Session.Drag and (input==Session.Drag.input or input.UserInputType==Enum.UserInputType.MouseButton1) then Session.Drag=nil end
end)
connect(Input.WindowFocusReleased,function() Session.ActiveSlider=nil;Session.Drag=nil;UI.closePopup() end)
function Session.Cleanup()
    if Session.Closed then return end
    Session.CommitInputs()
    Session.Closed=true;Session.ActiveSlider=nil;Session.Drag=nil
    UI.closePopup()
    if Session.EngineCleanup then pcall(Session.EngineCleanup) end
    for _,model in ipairs(Session.EngineControls) do model.Bind=nil;model.PaintValue=nil end
    for _,c in ipairs(Session.PageConnections) do pcall(function() c:Disconnect() end) end
    for _,c in ipairs(UI.NavConnections or {}) do pcall(function() c:Disconnect() end) end
    for _,c in ipairs(Session.Connections) do pcall(function() c:Disconnect() end) end
    gui:Destroy()
    if G.__ZekioPremiumUI==Session then G.__ZekioPremiumUI=nil end
end
UI.layout();UI.show("overview")

Session.LoaderURL="https://raw.githubusercontent.com/billskyy-hue/billskyyy/main/zekio_supreme_premium_test.lua?v=premium-keys-1"
return Session

end)()
end, function(message)
    if debug and type(debug.traceback) == "function" then return debug.traceback(tostring(message), 2) end
    return tostring(message)
end)
if not uiOk then
    local partial = Boot.G.__ZekioPremiumUI
    if type(partial) == "table" then
        for _, c in ipairs(partial.PageConnections or {}) do pcall(function() c:Disconnect() end) end
        for _, c in ipairs(partial.Connections or {}) do pcall(function() c:Disconnect() end) end
        if partial.Gui then pcall(function() partial.Gui:Destroy() end) end
        partial.Closed = true
    end
    Boot.G.__ZekioPremiumUI = nil
    Boot.Fail(uiError)
    return
end
Boot.Close()

-- Test copy: no license heartbeat.

-- PREMIUM_ENGINE_BEGIN
task.spawn(function()
if Premium.Closed then return end

local G = Boot.G
for _, key in ipairs({ "__ZekioSupremePremiumEngine" }) do -- tutup hanya sesi tes sebelumnya
    local previous = G[key]
    if type(previous) == "table" and type(rawget(previous, "Cleanup")) == "function" then
        pcall(rawget(previous, "Cleanup"))
    end
    G[key] = nil
end
local Session = {}
G.__ZekioSupremePremiumEngine = Session
local function alive()
    return G.__ZekioSupremePremiumEngine == Session and not Session.Failed and not Session.Closed and not Premium.Closed
end

-- Startup stays inside the native premium dashboard, without a test console.
function Session.GuiParent(fallback) return Premium.Gui.Parent or fallback end
function Session.Report(message) pcall(Premium.SetBootStatus, tostring(message)) end
function Session.CloseBoot() end
function Session.ResetPartial()
    if Premium.ProxyStop then pcall(Premium.ProxyStop) end
    if Session.RestoreNames then pcall(Session.RestoreNames) end
    if Session.UnbindInput then pcall(Session.UnbindInput) end
    for _,c in ipairs(Session.StartupConnections or {}) do pcall(function() c:Disconnect() end) end
    for _,g in ipairs(Session.StartupGuis or {}) do pcall(function() g:Destroy() end) end
end
function Session.FailStartup(message)
    Session.Failed=true;Premium.EngineReady=false;Session.ResetPartial()
    Session.Report("Gagal memuat data game: "..tostring(message):sub(1,1200).."\nMasuk world, lalu jalankan ulang script.")
end
Session.Cleanup=function() Session.Closed=true;Session.ResetPartial() end
Premium.EngineCleanup=function()
    if Session.Cleanup then pcall(Session.Cleanup) end
    if G.__ZekioSupremePremiumEngine==Session then G.__ZekioSupremePremiumEngine=nil end
end
Session.Report("Memuat modul Growblox…")

local startupOk, startupError = xpcall(function()
if not alive() then return end
do
    local getId = getthreadidentity or get_thread_identity or getidentity or (syn and syn.get_thread_identity)
    if type(getId) == "function" then pcall(function() Session.Ident = getId() end) end
    Session.Exec = coroutine.create(function(job)
        while true do
            job.ok, job.err = pcall(job.fn)
            job.done = true
            Session.ExecBusy = false
            job = coroutine.yield()
        end
    end)
end

---------------------------------------------------------------------
-- SERVICES & MODULE GAME
---------------------------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
Session.Report("Menunggu PlayerGui")
assert(LocalPlayer, "Masuk ke game Roblox terlebih dahulu")
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 15)
assert(PlayerGui, "PlayerGui belum tersedia setelah 15 detik; masuk world lalu execute ulang")

-- Cari dependensi tanpa menunggu satu lokasi folder selamanya.
local Shared = (function()
    local boot = { Modules = {}, Errors = {}, Sources = {}, Missing = {}, Version = "startup r10" }
    local wanted = { itemdb = true, inventory = true, net = true, particles = true,
        worldmenu = true, roles = true, sfx = true, splice = true }
    local seen, containers, remotes, gameGui = {}, {}, nil, nil

    local function note(text)
        Session.Report("Data game: " .. tostring(text))
    end
    local function field(v, k)
        local ok, value = pcall(function() return v[k] end)
        if ok then return value end
    end
    local function path(node)
        local ok, value = pcall(function() return node:GetFullName() end)
        return ok and tostring(value) or tostring(field(node, "Name") or "modul")
    end
    local function inspect(node)
        if seen[node] then return end
        seen[node] = true
        local name = field(node, "Name")
        if type(name) ~= "string" then return end
        local key = string.lower(name)
        if key == "worldremotes" and not remotes then remotes = node end
        if key == "gamegui" and not gameGui then gameGui = node end
        if not wanted[key] then return end
        local ok, isModule = pcall(function() return node:IsA("ModuleScript") end)
        if not (ok and isModule) then return end
        local list = boot.Modules[key]
        if not list then list = {}; boot.Modules[key] = list end
        if #list < 8 then list[#list + 1] = node end
    end

    local old = ReplicatedStorage:FindFirstChild("Shared")
    if old then
        local ok, children = pcall(function() return old:GetChildren() end)
        if ok then for _, node in ipairs(children) do inspect(node) end end
    end
    containers[#containers + 1] = ReplicatedStorage
    containers[#containers + 1] = PlayerGui
    local scripts = LocalPlayer:FindFirstChild("PlayerScripts")
    if scripts then containers[#containers + 1] = scripts end
    local okFirst, first = pcall(game.GetService, game, "ReplicatedFirst")
    if okFirst and first then containers[#containers + 1] = first end
    note("mencari modul yang tersedia")
    for _, root in ipairs(containers) do
        inspect(root)
        local ok, descendants = pcall(function() return root:GetDescendants() end)
        if ok and type(descendants) == "table" then
            for i, node in ipairs(descendants) do
                inspect(node)
                if i % 400 == 0 then task.wait() end
            end
        end
    end
    for _, enumerate in ipairs({ getloadedmodules or false, getnilinstances or false }) do
        if type(enumerate) == "function" then
            local ok, nodes = pcall(enumerate)
            if ok and type(nodes) == "table" then
                for _, node in pairs(nodes) do inspect(node) end
            end
        end
    end

    function boot:FindFirstChild(name)
        local list = self.Modules[string.lower(tostring(name))]
        return list and list[1] or nil
    end
    function boot.catalog(value)
        if type(value) ~= "table" then return false end
        local count, checked = 0, 0
        for id, entry in next, value do
            checked = checked + 1
            if type(id) == "number" and type(entry) == "table"
                and type(rawget(entry, "name")) == "string"
                and (type(rawget(entry, "hits")) == "number" or type(rawget(entry, "solid")) == "boolean"
                    or type(rawget(entry, "grow")) == "number") then
                count = count + 1
                if count >= 3 then return true end
            end
            if checked >= 64 then break end
        end
        return false
    end
    function boot.network(value)
        if type(value) ~= "table" then return false end
        local tile, act = rawget(value, "tile"), rawget(value, "act")
        return type(tile) == "table" and type(field(tile, "send")) == "function"
            and type(act) == "table" and type(field(act, "send")) == "function"
    end
    local function requireBounded(node)
        if not (task and type(task.spawn) == "function" and type(task.wait) == "function") then
            return false, "task.spawn / task.wait tidak tersedia"
        end
        local job = { done = false }
        local thread = task.spawn(function()
            job.ok, job.value = pcall(require, node)
            job.done = true
        end)
        local start = os.clock()
        while not job.done and os.clock() - start < 3 do task.wait() end
        if not job.done then
            if type(task.cancel) == "function" then pcall(task.cancel, thread) end
            return false, "require melewati batas 3 detik"
        end
        return job.ok, job.value
    end
    local function import(name, validate)
        local candidates = boot.Modules[string.lower(name)] or {}
        for _, node in ipairs(candidates) do
            note("memuat " .. name .. " dari " .. path(node))
            local ok, value = requireBounded(node)
            if ok and type(value) == "table" and (not validate or validate(value)) then
                boot.Sources[name] = path(node)
                return true, value
            end
            boot.Errors[#boot.Errors + 1] = name .. " @ " .. path(node) .. ": "
                .. (ok and "format modul tidak cocok" or tostring(value))
        end
        return false, nil
    end
    function boot:Load(name)
        return import(name)
    end

    local itemOK
    itemOK, boot.ItemDB = import("ItemDB", boot.catalog)
    boot.InventoryOK, boot.Inventory = import("Inventory")
    boot.NetOK, boot.Net = import("Net", boot.network)
    boot.ParticlesOK, boot.Particles = import("Particles")
    boot.MenuOK, boot.Menu = import("WorldMenu")
    boot.RolesOK, boot.Roles = import("Roles")
    boot.SfxOK, boot.Sfx = import("Sfx")
    -- Modul dapat dilepas dari tree setelah dimuat. Cek bentuk data yang dipakai
    -- script, tanpa require() semua ModuleScript yang tidak dikenal.
    if (not itemOK or not boot.NetOK) and type(getgc) == "function" then
        note("mencari data item / jaringan yang sudah dimuat game")
        local ok, objects = pcall(getgc, true)
        if ok and type(objects) == "table" then
            local function consider(value, label)
                if type(value) ~= "table" or value == G or value == _G or value == boot then return end
                if not itemOK and boot.catalog(value) then
                    itemOK, boot.ItemDB = true, value
                    boot.Sources.ItemDB = label
                end
                if not boot.NetOK and boot.network(value) then
                    boot.NetOK, boot.Net = true, value
                    boot.Sources.Net = label
                end
            end
            local checked = 0
            for _, value in pairs(objects) do
                consider(value, "data game yang sudah dimuat (getgc)")
                checked = checked + 1
                if itemOK and boot.NetOK then break end
                if checked % 300 == 0 then task.wait() end
            end
            -- Beberapa executor hanya mengekspos fungsi, sementara data modulnya
            -- masih dapat dibaca melalui upvalue fungsi game yang sudah berjalan.
            if not itemOK or not boot.NetOK then
                note("menelusuri data modul yang ditangkap fungsi game")
                local bulk = getupvalues or (debug and debug.getupvalues)
                local single = getupvalue or (debug and debug.getupvalue)
                for _, fn in pairs(objects) do
                    if type(fn) == "function" then
                        local values
                        if type(bulk) == "function" then
                            local okValues, found = pcall(bulk, fn)
                            if okValues and type(found) == "table" then values = found end
                        end
                        if values then
                            for _, value in pairs(values) do consider(value, "upvalue fungsi game") end
                        elseif type(single) == "function" then
                            for i = 1, 40 do
                                local okValue, first, second = pcall(single, fn, i)
                                if not okValue or (first == nil and second == nil) then break end
                                consider(second ~= nil and second or first, "upvalue fungsi game")
                            end
                        end
                    end
                    checked = checked + 1
                    if itemOK and boot.NetOK then break end
                    if checked % 200 == 0 then task.wait() end
                end
            end
        end
    end
    boot.Inventory = boot.Inventory or {}
    boot.GameGui = gameGui or PlayerGui
    boot.Remotes = remotes
    if not remotes then
        boot.EmptyRemotes = Instance.new("Folder")
        boot.EmptyRemotes.Name = "ZekioTestNoLegacyRemotes"
        boot.Remotes = boot.EmptyRemotes
    end
    for _, entry in ipairs({ {"Inventory", boot.InventoryOK}, {"Net", boot.NetOK},
        {"Particles", boot.ParticlesOK}, {"WorldMenu", boot.MenuOK}, {"Roles", boot.RolesOK}, {"Sfx", boot.SfxOK} }) do
        if not entry[2] then boot.Missing[#boot.Missing + 1] = entry[1] end
    end
    boot.Status = "ItemDB: " .. tostring(boot.Sources.ItemDB or "belum ditemukan")
        .. (#boot.Missing > 0 and (" | modul opsional belum terbaca: " .. table.concat(boot.Missing, ", ")) or "")
    if not itemOK then
        local names = {}
        for name, candidates in pairs(boot.Modules) do
            if #candidates > 0 then names[#names + 1] = name .. " @ " .. path(candidates[1]) end
        end
        table.sort(names)
        local message = "ItemDB belum ditemukan. Script tidak akan menunggu Shared tanpa batas.\n"
            .. "Modul terbaca: " .. (#names > 0 and table.concat(names, "; ") or "tidak ada nama modul lama")
            .. (#boot.Errors > 0 and ("\n" .. table.concat(boot.Errors, "\n")) or "")
        note(message)
        if boot.EmptyRemotes then boot.EmptyRemotes:Destroy() end
        error(message, 0)
    end
    note(boot.Status)
    return boot
end)()
if not alive() then return end
local WorldRemotes = Shared.Remotes
local SetTileRemote = WorldRemotes:FindFirstChild("SetTile")
local ItemDB = Shared.ItemDB
local InventoryModule = Shared.Inventory
local NetOk, Net = Shared.NetOK, Shared.Net
local GameGui = Shared.GameGui
local ParticlesOk, ParticlesModule = Shared.ParticlesOK, Shared.Particles
local MenuModOk, MenuModule = Shared.MenuOK, Shared.Menu
local RolesOk, RolesModule = Shared.RolesOK, Shared.Roles
local SfxOk, SfxModule = Shared.SfxOK, Shared.Sfx

local WindUI = Premium.EngineUI

---------------------------------------------------------------------
-- PENGATURAN & DATA
---------------------------------------------------------------------
local State = {
    Running = false,
    Mode = "Place + Break",       -- "Place + Break" | "Break saja" | "Place saja"
    PlaceMs = 250,                -- jeda setelah tiap place
    BreakMs = 220,                -- jeda tiap pukulan (normal 220)
    AfterBreakMs = 300,           -- jeda setelah block hancur
    HitsOverride = 0,             -- jumlah pukulan manual (0 = otomatis)
    BreakBackground = true,       -- selalu ikut pecah background (tanpa tombol)
    MultiTarget = 1,              -- jumlah tile dipukul bergantian (1 = biasa)
    SelectedId = nil,
    Offsets = {},                 -- tile yang dipilih di Grid
    CalibX = 0,
    CalibY = 0,
    AntiAfk = true,
    MutePunch = true,
    Visual = true,                -- animasi tangan saat break / place / tanam / panen (tampilan saja)
    LiteMode = false,
    AutoCollect = true,           -- ambil drop di tile yang dipilih
    SkipCollectGems = false,      -- lewati gems pada collector dan pencarian drop script
    CollectAround = false,        -- ambil drop di sekitar karakter (radius) kapan saja
    CollectRadius = 3,            -- jari-jari collect (tile), dipakai mode Remote
    CollectMode = "Sentuhan",     -- "Sentuhan" (badan, seperti main manual) / "Remote" (ambil dari jauh, cara lama)
    Override = nil,               -- Pabrik memakai tile & block sendiri
    Quiet = false,                -- tanpa notifikasi (dipakai Pabrik)
    Cycles = 0,
    Placed = 0,
    Broken = 0,
    Collected = 0,                -- jumlah drop yang diambil
    CollectFail = 0,              -- jumlah drop yang ditolak server
    LastAction = "-",
    SeedDrop = true,              -- seed hasil break sudah banyak -> drop ke titik drop
    SeedDropAt = 190,             -- drop kalau seed sudah sebanyak ini
    SeedKeep = 0,                 -- seed yang disisakan
    Dropped = 0,
    DropPause = false,            -- Auto Farm dijeda sementara (sedang pergi drop)
}

local Misc = {
    Speed = 100,      -- walkspeed % (100 = normal)
    InfJump = false,
    Ghost = false,    -- fly + tembus block
    UpHeld = false,   -- tombol ▲ di layar ditahan
    DownHeld = false, -- tombol ▼ di layar ditahan
    CustomName = true,          -- watermark nama (selalu aktif, mati hanya saat script ditutup)
    NameText = "Zekio Supreme",  -- teks watermark
}

-- Auto Clear World
local Clear = {
    Running = false,
    IncludeBg = true,         -- ikut pecah background
    UseBlock = true,          -- taruh block kalau tidak ada pijakan
    ScaffoldId = nil,         -- block yang dipakai untuk pijakan
    Collect = true,           -- ambil drop tiap habis pecah
    Sweep = "Kiri → Kanan",   -- "Kiri → Kanan" atau "Zig-zag"
    Skip = {},                -- tile yang dilewati sementara
    TopRow = -1,              -- baris yang sedang dibersihkan
    DirRow = nil,             -- arah zig-zag untuk baris ini
    Dir = nil,
    Broken = 0,
    Remaining = -1,
    Status = "-",
}

-- Auto Splice: tanam Seed A lalu splice Seed B
local Splice = {
    Running = false,
    Roam = true,        -- keliling world pakai A* (false = hanya tile Grid)
    Roaming = false,
    A = nil,
    B = nil,
    Ms = 300,
    Made = 0,
    Planted = 0,
    Fail = {},
    Skip = {},
    Status = "-",
    Row = {},           -- baris yang sedang dikerjakan (rapi per baris)
}

-- Lahan (farm world): baris block dari atas ke bawah
local Land = {
    X0 = 0, X1 = 99,  -- kolom awal & akhir
    Y0 = 2,           -- baris block paling atas
    Gap = 2,          -- jarak antar baris (2 = ada 1 tile kosong untuk pohon)
    Rows = 10,        -- jumlah baris
    Stairs = true,    -- ujung baris dibuka bergantian kiri/kanan (jalan naik-turun seperti tangga)
}

-- Bangun Lahan
local Build = {
    Running = false,
    BlockId = nil,
    UseBlock = true,     -- boleh taruh block pijakan kalau baris pertama tidak terjangkau
    Produce = true,      -- block kurang -> produksi dulu (tanam & panen) sampai cukup
    ThenPabrik = false,  -- selesai -> langsung jalankan Pabrik
    Placed = 0,
    Phase = "-",
    Status = "-",
    Skip = {},
    FieldSkip = {},      -- tile panen / tanam yang dilewati sementara (produksi block)
    Row = {},            -- baris tanam produksi yang sedang dikerjakan
    Harvested = 0,
    Planted = 0,
    Dug = 0,             -- tile yang digali (block + background)
    Carved = {},         -- [idx] = true: block-nya digali Bangun Lahan (background ikut dipecah)
    Surface = nil,       -- y permukaan tanah asli (di bawahnya background ikut dipecah)
    Under = {},          -- [baris] = waktu: sementara pasang dari bawah (tidak bisa naik ke baris itu)
    BreakTimes = {},     -- tile yang terus balik lagi setelah digali
    LavaSkip = {},       -- jeda singkat hanya jika pukulan lava gagal
    LavaCleared = 0,
    PunchMs = 200,       -- jeda tangan Dirt Farm; tidak mengubah Auto Farm / Pabrik
    Reserve = 0,         -- block yang tidak boleh dipasang (disisakan untuk bikin seed)
    RESERVE = 10,        -- sisakan block segini saat produksi
    BreakX = -1, BreakY = -1, -- posisi break produksi (belum diatur = otomatis di ujung kanan baris)
    Tiles = {},          -- tile break produksi, relatif ke posisi break ("dx,dy") (Grid mode Lahan)
}

-- Vending: isi stock dari drop / kosongkan sampai habis
local Vend = {
    Running = false,
    Mode = "Isi stock dari drop",  -- atau "Kosongkan sampai habis"
    Point = "",                    -- titik drop vending: "WORLD" / "WORLD:ID" (kosong = world ini)
    Status = "-",
    Stocked = 0, Taken = 0, Dropped = 0,
    Picked = {},                   -- [id] = jumlah hasil pungut yang belum masuk vending
    Items = {},                    -- item yang boleh diambil / di-stock / dikosongkan (kosong = semua)
    Kind = "Semua",                -- "Semua" / "Block saja" / "Seed saja"
    Seen = {},                     -- item yang pernah terlihat (vending, tas, drop) untuk daftar pilihan
    DropX = -1, DropY = -1,        -- posisi berdiri di titik drop vending (-1 = titik kedatangan)
    Carry = {},                    -- [id] = jumlah yang diambil dari vending (mode kosongkan)
}

-- Pabrik: break block -> tanam seed -> panen -> break lagi, seed lebihan di-drop
local Pabrik = {
    Running = false,
    Fast = true,         -- target dekat, jalur lurus, jeda aksi 140 ms
    SeedId = nil,
    BlockId = nil,
    WholeWorld = false,  -- tanam & panen di seluruh world (bukan hanya lahan)
    Tiles = {},          -- tile break, relatif ke posisi break ("dx,dy")
    BreakX = -1, BreakY = -1,
    BreakSec = 60,       -- lama 1 sesi break sebelum cek pohon lagi
    Drop = true,
    Keep = 50,           -- seed yang disisakan untuk ditanam lagi
    DropAt = 200,        -- drop kalau seed sudah sebanyak ini
    DropWorld = "",      -- "" = world ini | "WORLD" | "WORLD:ID"
    DropX = -1, DropY = -1,
    Harvested = 0,
    Planted = 0,
    Dropped = 0,
    Skip = {},
    Status = "-",
    Traveling = false,
    Home = "",
    Zone = nil,          -- tempat drop (tidak ikut di-collect), dipakai semua fitur drop
    Row = {},            -- baris tanam yang sedang dikerjakan
}

local Guard = {
    On = false,
    Who = "Staff (Mod/Dev)",   -- "Staff (Mod/Dev)" | "Semua pemain"
    StopAll = true,            -- diam semua aktivitas
    Leave = false,             -- keluar world
    AutoBack = true,           -- lanjut lagi setelah aman
    BackSec = 60,              -- (keluar world) tunggu sebelum masuk lagi
    CalmSec = 5,               -- (diam) tunggu sepi dulu sebelum lanjut
    Mode = "idle",             -- idle | pause | away | out | back
    Allow = {},                -- pemain biasa yang sudah ada saat Penjaga dinyalakan (diabaikan)
    Alerted = {},              -- sudah diberi peringatan
    Saved = nil,               -- aktivitas sebelum dihentikan
    Token = 0,
    BackAt = 0,
    CalmAt = nil,
    LeftFg = nil,
    BackText = nil,
    Status = "Mati",
    Detected = 0,
}

-- Farmer: panen & tanam otomatis
local Farmer = {
    Running = false,
    Harvest = true,
    HarvestOnly = true, -- fokus panen sampai Auto Plant diaktifkan sendiri
    Plant = false,
    Collect = true,
    UseBlock = false,   -- taruh block kalau tidak ada jalan
    ScaffoldId = nil,
    HarvestMs = 250,    -- jeda setelah tiap panen
    PlantMs = 250,      -- jeda setelah tiap tanam
    SeedId = nil,
    Skip = {},
    Harvested = 0,
    Planted = 0,
    Status = "-",
    Drop = false,       -- Farmer menyimpan hasil; tidak memakai auto drop
    DropAt = 190,       -- drop kalau item hasil panen sudah sebanyak ini
    Keep = 50,          -- seed tanam yang disisakan
    Dropped = 0,
    Got = {},           -- seed pohon yang pernah dipanen (untuk cari item hasil panen)
    Row = {},           -- baris tanam yang sedang dikerjakan (tanam rapi per baris)
}

-- Tombol gerak buatan (dipakai Clear & Farmer)
local AutoInput = { active = false, left = false, right = false, jump = false, down = false }

-- Auto Chat
local Spam = {
    On = false,
    Texts = {},         -- daftar pesan, dikirim bergantian
    IntervalSec = 6,
    Index = 1,
    Sent = 0,
    Last = "-",
}

local Refs = {
    World = nil,      -- data world (fg, bg, ukuran)
    Inv = nil,        -- inventori
    SetTile = nil,    -- fungsi place game
    State = nil,      -- posisi karakter
    Punch = nil,      -- fungsi pukul game
    Particles = {},   -- particle (untuk mode Lite)
    Menu = nil,       -- menu game (keluar / masuk world)
    Gems = nil,       -- update angka gems
    Hud = nil,        -- jangkauan pukul & place
    Trees = nil,      -- data pohon (waktu tanam)
    Others = nil,     -- daftar pemain lain di world (untuk Penjaga)
}

-- Daftar drop di world (diambil dari game)
local Drops = { list = nil, update = nil, brokeAt = {} }
-- Animasi aksi: fungsi gambar tangan game + nomor upvalue "aksi terakhir" (diisi saat hubungkan)
local Anim = { fn = nil, idx = nil, set = nil }
local DropFailUntil = {}   -- drop yang ditolak, dicoba lagi nanti

local UI = {}

-- Jalankan fn dengan izin penuh. Hasil: ok, err (seperti pcall)
function UI.ident()
    local getId = getthreadidentity or get_thread_identity or getidentity or (syn and syn.get_thread_identity)
    if type(getId) ~= "function" then return nil end
    local ok, v = pcall(getId)
    return ok and v or nil
end
function UI.exec(fn)
    local setId = setthreadidentity or set_thread_identity or setidentity or (syn and syn.set_thread_identity)
    local function elevate()
        if Session.Ident and type(setId) == "function" then pcall(setId, Session.Ident) end
    end
    local co = Session.Exec
    if co and not Session.ExecBusy and coroutine.status(co) == "suspended" then
        local job = { fn = function() elevate(); fn() end }
        Session.ExecBusy = true
        local okR, errR = coroutine.resume(co, job)
        if okR then
            -- Refresh bisa yield. Tunggu hasil sebenarnya, bukan hasil resume pertama.
            local deadline = os.clock() + 10
            while not job.done do
                if not alive() then return false, "Sesi script sudah ditutup" end
                if os.clock() >= deadline then return false, "Pekerjaan UI belum selesai setelah 10 detik" end
                task.wait()
            end
            return job.ok, job.err
        end
        Session.ExecBusy = false
        return false, tostring(errR)
    end
    -- cadangan: jalankan di thread ini (setelah identitasnya dikembalikan)
    elevate()
    local ok2, err2 = pcall(fn)
    if ok2 then return true end
    return false, tostring(err2)
end
UI.Jobs = {}
function UI.later(key, fn, delay)
    UI.Jobs[key] = { fn = fn, at = os.clock() + (delay or 0) }
end
-- Jalankan pekerjaan UI yang sudah waktunya (dipanggil oleh thread INIT, lihat bagian INIT)
function UI.runJobs()
    local now = os.clock()
    local due = {}
    for key, job in pairs(UI.Jobs) do
        if now >= job.at then due[#due + 1] = key end
    end
    for _, key in ipairs(due) do
        local job = UI.Jobs[key]
        if job and now >= job.at then
            UI.Jobs[key] = nil
            local ok, err = pcall(job.fn)
            if not ok then warn("[Zekio Supreme Premium] UI job " .. tostring(key) .. ": " .. tostring(err)) end
        end
    end
end
local Connections = {}
Session.StartupConnections = Connections
local HitCount = {}   -- hitung pukulan (cadangan)
local PlacedAt = {}   -- kapan tile di-place

---------------------------------------------------------------------
-- BAHASA (Indonesia / English)
---------------------------------------------------------------------
-- Cara kerja:
--   - Semua teks script ditulis dalam Bahasa Indonesia.
--   - Kalau English dipilih, I18N.T(teks) menerjemahkan:
--       1. teks utuh (judul & deskripsi menu) dari daftar EN
--       2. teks yang berubah-ubah (status, notifikasi) per frasa dari daftar PH
--   - Menu WindUI dibungkus (I18N.wrap) supaya judul, deskripsi & isi status ikut diterjemahkan.
local I18N = { Lang = "id", Saved = "id", Ask = true }

do (function() -- fungsi sendiri: variabel di dalam tidak ikut batas 200 local

I18N.EN = {
    -- grup sidebar & tab
    ["Fitur"] = "Features", ["Keamanan"] = "Security", ["Setelan"] = "Setup",
    ["Pengaturan"] = "Settings", ["Penjaga"] = "Guard", ["Statistik"] = "Stats", ["Tas"] = "Bag",
    ["Dirt Farm"] = "Dirt Farm", ["Pabrik"] = "Factory", ["Koneksi"] = "Connection",
    -- kotak
    ["Kontrol"] = "Controls", ["Mode & Kecepatan"] = "Mode & Speed", ["Kecepatan"] = "Speed",
    ["Karakter"] = "Character", ["Opsi"] = "Options", ["Pesan"] = "Messages",
    ["Aksi saat terdeteksi"] = "Action when detected", ["Waktu"] = "Timing", ["Lainnya"] = "Other",
    ["Quest Harian"] = "Daily Quests", ["Pohon (siap panen)"] = "Trees (ready to harvest)",
    ["Auto Recycle (buang item)"] = "Auto Recycle (trash items)", ["Bentuk Dirt Farm"] = "Dirt Farm shape",
    ["Pilihan"] = "Options", ["Posisi & tile break"] = "Break position & tiles",
    ["Koreksi posisi"] = "Position correction", ["Yang dikirim"] = "What to send",
    -- Farm
    ["Bisa juga lewat tombol START di Grid"] = "Can also use the START button in the Grid",
    ["Ambil drop di tile yang dipilih"] = "Pick up drops on the selected tiles",
    ["Collect di sekitar karakter"] = "Collect around character",
    ["Ambil semua drop dalam radius, kapan saja"] = "Pick up all drops within the radius, anytime",
    ["Radius collect (tile)"] = "Collect radius (tiles)",
    ["Dipakai juga Clear, Farmer, Splice & Pabrik. Terlalu jauh bisa ditolak server"] =
        "Also used by Clear, Farmer, Splice & Factory. Too far may be rejected by the server",
    ["Buka Grid Tile"] = "Open Tile Grid",
    ["Kotak 5x5, tengah = karakter"] = "5x5 grid, center = character",
    -- Clear
    ["Status Clear"] = "Clear Status",
    ["Bersihkan dari baris atas ke bawah"] = "Clear from the top row down",
    ["Arah sapu"] = "Sweep direction",
    ["Zig-zag lebih cepat (tidak balik ke kiri)"] = "Zig-zag is faster (no going back left)",
    ["Pakai block pijakan"] = "Use scaffold blocks",
    ["Taruh block untuk lewat jurang / naik ke block melayang"] = "Place blocks to cross gaps / reach floating blocks",
    ["Block pijakan"] = "Scaffold block",
    ["Block yang dipakai untuk pijakan"] = "Block used as scaffold",
    ["Auto collect tiap habis pecah"] = "Auto collect after each break",
    ["Ambil drop di sekitar karakter"] = "Pick up drops around the character",
    ["Reset tile yang dilewati"] = "Reset skipped tiles",
    ["Coba lagi tile yang tadi gagal"] = "Retry tiles that failed",
    -- Farmer
    ["Status Farmer"] = "Farmer Status",
    ["Jalankan Farmer"] = "Run Farmer",
    ["Panen pohon siap & tanam seed otomatis"] = "Harvest ready trees & plant seeds automatically",
    ["Seed untuk ditanam"] = "Seed to plant",
    ["Hanya seed yang ada di inventori"] = "Only seeds in your inventory",
    ["Refresh daftar seed"] = "Refresh seed list",
    ["Hanya pohon yang sudah siap"] = "Only trees that are ready",
    ["Tanam di atas block yang kosong"] = "Plant on top of empty blocks",
    ["Ambil hasil panen di sekitar karakter"] = "Pick up harvest drops around the character",
    ["Jeda setelah tiap panen"] = "Delay after each harvest",
    ["Jeda setelah tiap tanam seed"] = "Delay after each seed planted",
    ["Taruh block kalau tidak ada jalan (block tetap tertinggal)"] = "Place blocks when there is no path (blocks stay behind)",
    -- Speed & opsi
    ["Place semua tile dulu, lalu break"] = "Place all tiles first, then break",
    ["Jeda setelah tiap place"] = "Delay after each place",
    ["Jeda tiap pukulan (normal 220). Dipakai juga Clear"] = "Delay per hit (normal 220). Also used by Clear",
    ["Auto Farm: tile dipukul bergantian (seperti 2 jari). Pakai Rayman's Fist = 2-3 tile segaris sekali pukul"] =
        "Auto Farm: tiles are hit in turns (like 2 fingers). With Rayman's Fist = 2-3 tiles in a line per punch",
    ["Jeda setelah hancur (ms)"] = "Delay after break (ms)",
    ["Tunggu sebelum lanjut ke tile berikutnya"] = "Wait before moving to the next tile",
    ["Mode Lite"] = "Lite Mode",
    ["Matikan particle & suara (HP low-end)"] = "Turn off particles & sounds (low-end phones)",
    ["Mute suara pukulan"] = "Mute punch sounds",
    ["Pukulan per block (cadangan)"] = "Hits per block (fallback)",
    ["Dipakai kalau 'Pukul: TIDAK'. 0 = otomatis"] = "Used when 'Punch: NO'. 0 = automatic",
    ["Pilih Block"] = "Select Block",
    ["Hanya item yang bisa di-place"] = "Only placeable items",
    ["Refresh daftar"] = "Refresh list",
    ["Lompat di udara (bisa kena rollback)"] = "Jump mid-air (may get rolled back)",
    ["Fly + Tembus Block"] = "Fly + Noclip",
    ["Tembus block, pakai tombol ▲/▼ (bisa kena rollback)"] = "Pass through blocks, use the ▲/▼ buttons (may get rolled back)",
    ["Bahasa / Language"] = "Language / Bahasa",
    ["Titik Drop"] = "Drop Point", ["Atur titik drop"] = "Set drop point", ["Drop otomatis"] = "Auto drop",
    ["Seed sudah banyak: jeda, drop ke titik drop (tab Titik Drop), balik ke posisi farm"] =
        "Too many seeds: pause, drop at the drop point (Drop Point tab), return to farm position",
    ["Seed dari block yang dipilih"] = "Seeds of the selected block",
    ["Drop kalau hampir penuh"] = "Drop when almost full",
    ["Hasil panen (block & seed) dibawa ke titik drop (tab Titik Drop)"] =
        "Harvest items (blocks & seeds) are taken to the drop point (Drop Point tab)",
    ["Drop kalau item sudah"] = "Drop when an item reaches",
    ["Maksimal 200 per item"] = "Max 200 per item",
    ["Sisakan seed tanam"] = "Seeds to keep for planting",
    ["Seed yang dipilih untuk ditanam tidak di-drop semua"] = "The planting seed is not dropped completely",
    ["Ke titik drop (tab Titik Drop)"] = "To the drop point (Drop Point tab)",
    ["Block kurang diproduksi dulu, lalu dipasang dari atas seperti ular (tanpa pijakan)"] =
        "Missing blocks are produced first, then placed from the top like a snake (no scaffolding)",
    ["Gali dulu dari permukaan sampai bawah, lalu pasang baris naik sampai atas (baris jadi jembatan). Block habis: produksi 1 baris"] =
        "Digs from the surface down to the bottom first, then places rows upward to the top (each row is its own bridge). Out of blocks: produces on 1 row",
    ["Baris block paling atas. Baris di bawahnya otomatis sampai di atas bedrock (tanah digali)"] =
        "Top block row. Rows below go automatically down to just above bedrock (dirt is dug out)",
    ["Berdiri di atas block pertama baris paling atas, lalu tekan (tangga kiri di sebelah kirinya)"] =
        "Stand on the first block of the top row, then press (left stairs go to its left)",
    ["Baris block paling atas. Baris di bawahnya dibuat otomatis sampai tanah"] =
        "Top block row. Rows below are made automatically down to the ground",
    ["Ganti bahasa, lalu execute ulang"] = "Change language, then re-execute",
    ["Mode collect"] = "Collect mode", ["Sentuhan"] = "Touch",
    ["Berlaku untuk semua fitur. Sentuhan = seperti main manual. Remote = ambil dari jauh (cara lama, cepat)"] =
        "Applies to all features. Touch = like manual play. Remote = picks up from a distance (old method, fast)",
    ["Ambil drop di semua tile grid (caranya ikut Mode collect)"] = "Pick up drops on all grid tiles (method follows Collect mode)",
    ["Radius collect (mode Remote)"] = "Collect radius (Remote mode)",
    ["Jarak ambil drop di sekitar karakter (tile)"] = "Pickup distance around the character (tiles)",
    ["Animasi aksi"] = "Action animation",
    ["Tangan bergerak saat break / place / tanam / panen + efek place. Matikan untuk hemat FPS"] =
        "Arm moves on break / place / plant / harvest + place effect. Turn off to save FPS",
    ["Jenis item"] = "Item type",
    ["Berlaku untuk isi stock (drop yang dipungut) dan kosongkan (vending yang diambil)"] =
        "Applies to stock (drops picked up) and empty (vendings taken from)",
    ["Block saja"] = "Blocks only", ["Seed saja"] = "Seeds only",
    ["Item yang diambil"] = "Items to take",
    ["Bisa pilih banyak. Kosong = semua item. Daftar: isi vending, tas & drop yang terlihat"] =
        "Multi-select. Empty = all items. List: vending contents, backpack & seen drops",
    ["Muat ulang daftar item"] = "Reload item list",
    ["Pilih item"] = "Pick items",
    ["Tambah item yang dipegang"] = "Add the held item",
    ["Pilih item di tas game (dipegang), lalu tekan. Masuk ke daftar item yang diambil"] =
        "Select an item in the game backpack (held), then press. Adds it to the items to take",
    ["Hapus pilihan item"] = "Clear item selection",
    ["Kembali ke semua item"] = "Back to all items",
    ["Simpan posisi drop vending (posisi karakter)"] = "Save vending drop position (character position)",
    ["Berdiri di tempat drop (boleh di world titik drop), lalu tekan. Dipakai mode isi stock & kosongkan"] =
        "Stand at the drop spot (can be in the drop-point world), then press. Used by stock & empty modes",
    ["Hapus posisi drop vending"] = "Clear vending drop position",
    ["Drop / tunggu di titik kedatangan (pintu) saja"] = "Drop / wait at the arrival point (door) only",
    ["Ambil item dari vending, tas & drop di world ini"] = "Read items from vendings, backpack & drops in this world",
    ["Posisi break produksi = posisi karakter"] = "Production break position = character position",
    ["Berdiri di tempat break lalu tekan. Tekan lagi di tempat yang sama = kembali otomatis"] =
        "Stand at the break spot and press. Press again at the same spot = back to automatic",
    ["Pilih tile break produksi (Grid)"] = "Pick production break tiles (Grid)",
    ["Grid terbuka dalam mode Dirt Farm (terpisah dari Auto Farm & Pabrik)"] =
        "Grid opens in Dirt Farm mode (separate from Auto Farm & Factory)",
    ["Status Vending"] = "Vending Status",
    ["Jalankan Vending"] = "Run Vending",
    ["Jalankan di world vending milikmu"] = "Run it in your vending world",
    ["Titik drop vending"] = "Vending drop point",
    ["WORLD atau WORLD:ID (kosong = world ini). Isi stock: ambil drop di sini. Kosongkan: drop di sini"] =
        "WORLD or WORLD:ID (empty = this world). Stock: picks up drops here. Empty: drops here",
    ["Isi stock dari drop"] = "Stock from drops",
    ["Kosongkan sampai habis"] = "Empty until done",
    ["Drop di semua tile grid diambil dengan sentuhan badan (melangkah / lompat), tanpa remote"] =
        "Drops on every grid tile are picked up by body touch (step / jump), no remote",
    ["Drop di sekitar disusuri sampai tersentuh badan (tanpa remote)"] =
        "Nearby drops are walked over until the body touches them (no remote)",
    -- Chat
    ["Status Chat"] = "Chat Status",
    ["Daftar pesan"] = "Message list",
    ["Pisahkan dengan |   contoh: halo|jual dirt"] = "Separate with |   example: hi|selling dirt",
    ["pesan 1|pesan 2|pesan 3"] = "message 1|message 2|message 3",
    ["Interval (detik)"] = "Interval (seconds)",
    ["Jeda antar pesan (min 3 detik)"] = "Delay between messages (min 3 seconds)",
    ["Kirim pesan bergantian sesuai urutan"] = "Send messages in order, one after another",
    ["Kirim 1 pesan sekarang"] = "Send 1 message now",
    ["Tes kirim pesan berikutnya"] = "Test sending the next message",
    ["Isi daftar pesan dulu (tekan Enter setelah mengetik)"] = "Fill in the message list first (press Enter after typing)",
    -- Penjaga
    ["Status Penjaga"] = "Guard Status",
    ["Mati"] = "Off",
    ["Aktifkan Penjaga"] = "Enable Guard",
    ["Pantau Mod / Dev / pemain yang masuk world"] = "Watch for Mods / Devs / players entering the world",
    ["Yang dideteksi"] = "Detect",
    ["Semua pemain: yang sudah ada saat dinyalakan diabaikan"] = "All players: those already here when enabled are ignored",
    ["Diam semua aktivitas"] = "Pause all activities",
    ["Keluar world"] = "Leave world",
    ["Langsung keluar world saat terdeteksi"] = "Leave the world immediately when detected",
    ["Lanjut otomatis setelah aman"] = "Auto resume when safe",
    ["Keluar world: masuk lagi, cek, lalu lanjut aktivitas sebelumnya"] = "Leave world: rejoin, check, then resume previous activity",
    ["Masuk world lagi setelah (detik)"] = "Rejoin world after (seconds)",
    ["Untuk mode keluar world"] = "For leave-world mode",
    ["Tunggu aman (detik)"] = "Safe wait (seconds)",
    ["Untuk mode diam: jeda setelah mereka pergi"] = "For pause mode: delay after they leave",
    ["Abaikan pemain yang ada sekarang"] = "Ignore players here now",
    ["Untuk teman / akun sendiri (staff tetap dideteksi)"] = "For friends / alt accounts (staff are still detected)",
    ["Batalkan tunggu / lanjut"] = "Cancel wait / resume",
    ["Hentikan proses keluar-masuk & lanjut otomatis"] = "Stop the leave-rejoin process & auto resume",
    ["Dibatalkan"] = "Cancelled",
    -- Bonus
    ["Klaim hadiah quest yang sudah selesai"] = "Claim rewards for finished quests",
    ["Cek quest sekarang"] = "Check quests now",
    ["Tukar semua code aktif yang belum dipakai"] = "Redeem all active codes not used yet",
    ["Cek code sekarang"] = "Check codes now",
    ["Redeem code manual"] = "Redeem code manually",
    ["Ketik code lalu tekan Enter"] = "Type a code then press Enter",
    ["KODE"] = "CODE",
    -- Growscan
    ["Info World"] = "World Info",
    ["Tekan Scan sekarang"] = "Press Scan now",
    ["Update otomatis tiap 2 detik"] = "Auto update every 2 seconds",
    ["Scan sekarang"] = "Scan now",
    ["Cari item"] = "Search item",
    ["Saring nama item (kosongkan = semua)"] = "Filter item name (empty = all)",
    ["contoh: seed"] = "example: seed",
    ["Daftar"] = "List",
    -- Statistik
    ["Sesi ini"] = "This session",
    ["Reset statistik"] = "Reset stats",
    ["Mulai hitung dari nol"] = "Start counting from zero",
    ["Kirim ke Discord sekarang"] = "Send to Discord now",
    ["Perlu webhook di tab Discord"] = "Needs a webhook in the Discord tab",
    ["Aktifkan webhook Discord dulu"] = "Enable the Discord webhook first",
    ["Direset"] = "Reset",
    ["Masuk antrian kirim"] = "Added to send queue",
    -- Tas
    ["Item yang dipilih di-recycle otomatis"] = "Selected items are recycled automatically",
    ["Item yang di-recycle"] = "Items to recycle",
    ["Bisa pilih banyak. Tool & lock tidak ditampilkan"] = "Multiple allowed. Tools & locks are not shown",
    ["Recycle kalau jumlah >="] = "Recycle when amount >=",
    ["200 = hanya saat penuh 1 slot"] = "200 = only when a slot is full",
    ["Sisakan"] = "Keep",
    ["Jumlah yang tidak ikut di-recycle"] = "Amount not recycled",
    ["Refresh daftar item"] = "Refresh item list",
    ["100 WL -> 1 DL, 100 DL -> 1 BGL (sama seperti game)"] = "100 WL -> 1 DL, 100 DL -> 1 BGL (same as the game)",
    -- Splice
    ["Status Splice"] = "Splice Status",
    ["Tanam Seed A lalu splice Seed B"] = "Plant Seed A then splice Seed B",
    ["Seed A (ditanam)"] = "Seed A (planted)",
    ["Seed B (di-splice)"] = "Seed B (spliced)",
    ["Keliling world (A*)"] = "Roam world (A*)",
    ["Nyala: jalan ke seluruh world. Mati: hanya tile Grid 5x5"] = "On: walk the whole world. Off: only the 5x5 Grid tiles",
    ["Jeda tanam / splice (ms)"] = "Plant / splice delay (ms)",
    -- Lahan
    ["Status Dirt Farm"] = "Dirt Farm Status",
    ["Bangun Dirt Farm"] = "Build Dirt Farm",
    ["Hitung block, produksi kalau kurang, lalu pasang dari baris bawah"] = "Count blocks, produce if short, then place from the bottom row",
    ["Block Dirt Farm"] = "Dirt Farm block",
    ["Block padat dari inventori"] = "Solid block from inventory",
    ["X awal"] = "Start X",
    ["Kolom paling kiri"] = "Leftmost column",
    ["X akhir"] = "End X",
    ["Kolom paling kanan (lebih dari lebar world = sampai ujung)"] = "Rightmost column (beyond world width = to the edge)",
    ["Y baris atas"] = "Top row Y",
    ["Baris block paling atas (minimal 1)"] = "Topmost block row (minimum 1)",
    ["Jarak antar baris"] = "Row spacing",
    ["2 = y1, y3, y5.. | 3 = y1, y4, y7.. (maks 3 supaya bisa lompat naik)"] = "2 = y1, y3, y5.. | 3 = y1, y4, y7.. (max 3 so you can jump up)",
    ["Jumlah baris"] = "Number of rows",
    ["Tangga di pojok kiri-kanan"] = "Stairs at left-right corners",
    ["Ujung baris dibuka bergantian, jadi bisa turun-naik zig-zag"] = "Row ends open alternately, so you can go up/down in a zig-zag",
    ["Pakai posisi karakter sebagai pojok kiri-atas"] = "Use character position as top-left corner",
    ["X awal = kolom karakter, Y baris atas = tile di bawah kaki"] = "Start X = character column, top row Y = tile under the feet",
    ["Produksi block kalau kurang"] = "Produce blocks if short",
    ["Tanam & panen seed block itu dulu sampai cukup"] = "Plant & harvest that block's seed first until enough",
    ["Boleh taruh block pijakan"] = "Allow scaffold blocks",
    ["Kalau baris paling bawah tidak terjangkau dari tanah"] = "If the bottom row can't be reached from the ground",
    ["Lanjut Pabrik setelah selesai"] = "Start Factory when finished",
    -- Pabrik
    ["Status Pabrik"] = "Factory Status",
    ["Jalankan Pabrik"] = "Run Factory",
    ["Break -> tanam -> panen -> break lagi, seed lebihan di-drop"] = "Break -> plant -> harvest -> break again, extra seeds are dropped",
    ["Seed pabrik"] = "Factory seed",
    ["Block-nya otomatis (contoh: Dirt Seed -> Dirt)"] = "Block is automatic (example: Dirt Seed -> Dirt)",
    ["Tanam di seluruh world"] = "Plant in the whole world",
    ["Mati = hanya di Dirt Farm (tab Dirt Farm)"] = "Off = only on the Dirt Farm (Dirt Farm tab)",
    ["Pakai posisi sekarang untuk break"] = "Use current position for breaking",
    ["Berdiri di tempat break, lalu tekan"] = "Stand at the break spot, then press",
    ["Pilih tile break (Grid)"] = "Select break tiles (Grid)",
    ["Grid terbuka dalam mode Pabrik (terpisah dari tile Auto Farm)"] = "Grid opens in Factory mode (separate from Auto Farm tiles)",
    ["Lama 1 sesi break (detik)"] = "Break session length (seconds)",
    ["Setelah ini cek pohon siap dulu"] = "After this, check for ready trees first",
    ["Sisakan seed"] = "Seeds to keep",
    ["Untuk ditanam lagi"] = "For replanting",
    ["Drop kalau seed sudah"] = "Drop when seeds reach",
    ["Contoh 200 & sisakan 50 = drop 150"] = "Example 200 & keep 50 = drop 150",
    ["World drop"] = "Drop world",
    ["Kosong = world ini | WORLD | WORLD:ID (masuk lewat pintu ID)"] = "Empty = this world | WORLD | WORLD:ID (enter via door ID)",
    ["Pakai posisi sekarang untuk drop"] = "Use current position for dropping",
    ["Berdiri di tempat drop (boleh di world lain), lalu tekan"] = "Stand at the drop spot (can be another world), then press",
    ["Hapus posisi drop"] = "Clear drop position",
    ["Drop di titik kedatangan (pintu) saja"] = "Drop at the arrival point (door) instead",
    ["Ada block tapi posisi / tile break belum diatur"] = "Has blocks but break position / tiles are not set",
    ["Gagal jalan ke posisi break, dicoba lagi nanti"] = "Failed to walk to break position, retrying later",
    -- Koneksi & config
    ["Referensi game"] = "Game references",
    ["Hubungkan ke game"] = "Connect to game",
    ["Pakai setelah pindah world"] = "Use after changing worlds",
    ["Simpan pengaturan otomatis, dimuat lagi saat execute"] = "Save settings automatically, loaded again on execute",
    ["Simpan config sekarang"] = "Save config now",
    ["Hapus file config, lalu execute ulang"] = "Delete the config file, then re-execute",
    ["Koreksi posisi X"] = "Position correction X",
    ["Isi 1 / -1 kalau tile meleset"] = "Enter 1 / -1 if tiles are off",
    ["Koreksi posisi Y"] = "Position correction Y",
    ["Masuk lagi & lanjut aktivitas kalau terlempar"] = "Rejoin & resume activity if kicked out",
    ["Terlempar dari world"] = "Kicked from world",
    ["World ditutup / di-kick: masuk lagi ke world yang sama"] = "World closed / kicked: rejoin the same world",
    ["Selalu kembali ke world"] = "Always return to world",
    ["Kalau berada di luar world (layar pilih world), masuk lagi otomatis"] = "If outside a world (world select screen), rejoin automatically",
    ["World tujuan"] = "Target world",
    ["Kosongkan = world terakhir yang kamu masuki"] = "Empty = the last world you entered",
    ["NAMAWORLD"] = "WORLDNAME",
    ["Rejoin world sekarang"] = "Rejoin world now",
    ["Keluar lalu masuk lagi, aktivitas dilanjutkan"] = "Leave and rejoin, activity resumes",
    ["Disconnect dari server"] = "Disconnected from server",
    ["Teleport ulang ke game lalu masuk world terakhir"] = "Teleport back to the game and enter the last world",
    ["Jeda sebelum masuk lagi (detik)"] = "Delay before rejoining (seconds)",
    ["URL script (untuk rejoin server)"] = "Script URL (for server rejoin)",
    ["Link raw script ini, supaya jalan lagi setelah teleport. Kosong = pakai autoexec"] =
        "Raw link of this script, so it runs again after teleport. Empty = use autoexec",
    ["Sedang proses masuk world, tunggu dulu"] = "Already entering a world, please wait",
    ["World tujuan belum ada. Isi 'World tujuan' atau masuk world dulu"] = "No target world yet. Fill in 'Target world' or enter a world first",
    -- Discord
    ["Notifikasi Discord"] = "Discord Notifications",
    ["Kirim kabar penting ke channel Discord kamu"] = "Send important updates to your Discord channel",
    ["URL Webhook"] = "Webhook URL",
    ["Channel Discord > Edit > Integrasi > Webhook > Salin URL"] = "Discord channel > Edit > Integrations > Webhook > Copy URL",
    ["Tes kirim"] = "Test send",
    ["Laporan statistik (menit)"] = "Stats report (minutes)",
    ["Kirim statistik sesi tiap X menit. 0 = mati"] = "Send session stats every X minutes. 0 = off",
    ["Mod / Dev / pemain masuk world"] = "Mod / Dev / player entered world",
    ["Aktivitas berhenti (block habis / error)"] = "Activity stopped (out of blocks / error)",
    ["Quest diklaim / redeem berhasil"] = "Quest claimed / redeem successful",
    ["Terlempar / disconnect / masuk lagi"] = "Kicked / disconnected / rejoined",
    ["Pabrik drop seed / Dirt Farm selesai / berhenti"] = "Factory dropped seeds / Dirt Farm done / stopped",
    ["Isi URL webhook dulu"] = "Fill in the webhook URL first",
    ["Pesan tes masuk antrian"] = "Test message queued",
    ["URL webhook tidak valid"] = "Invalid webhook URL",
    ["Tes notifikasi dari Zekio Supreme Premium"] = "Test notification from Zekio Supreme Premium",
    -- pilihan dropdown
    ["Kiri → Kanan"] = "Left → Right", ["Semua pemain"] = "All players", ["Semua"] = "All",
    ["Depan"] = "Front", ["Break saja"] = "Break only", ["Place saja"] = "Place only",
    ["(memuat...)"] = "(loading...)", ["(inventori kosong)"] = "(inventory empty)",
    ["(inventori belum terbaca)"] = "(inventory not read yet)",
    ["(inventori kosong / belum terbaca)"] = "(inventory empty / not read yet)",
    ["Channel chat world belum ada (masuk world dulu)"] = "World chat channel not found (enter a world first)",
    ["Daftar pesan kosong"] = "Message list is empty",
    ["Inventori penuh"] = "Inventory full",
    ["Tanya bahasa saat execute"] = "Ask language on execute",
    ["Execute ulang untuk ganti bahasa / Re-execute to apply"] = "Re-execute to apply the new language",
    ["Munculkan pilihan bahasa tiap execute"] = "Show the language choice on every execute",
    -- Grid
    ["Grid Tile"] = "Tile Grid", ["Bersihkan pilihan"] = "Clear selection",
    ["Tile Break Pabrik"] = "Factory Break Tiles", ["START PABRIK"] = "START FACTORY", ["STOP PABRIK"] = "STOP FACTORY",
}

-- Frasa untuk teks yang berubah-ubah (status, notifikasi, pesan Discord)
I18N.PH = {
    { "Data world belum ketemu", "World data not found" }, { "Data drop belum ketemu", "Drop data not found" },
    { "Data pohon belum ketemu", "Tree data not found" }, { "Data pohon tidak ketemu", "Tree data not found" },
    { "Tekan 'Hubungkan ke game'", "Press 'Connect to game'" }, { "Hubungkan ke game", "Connect to game" },
    { "Kamu belum masuk world", "You are not in a world yet" }, { "belum masuk world", "not in a world yet" },
    { "tidak di world", "not in a world" },
    { "Menunggu karakter / world...", "Waiting for character / world..." },
    { "Menunggu pohon siap", "Waiting for trees to be ready" }, { "Menunggu", "Waiting" },
    { "Dihentikan karena", "Stopped because" }, { "Dihentikan", "Stopped" }, { "dimulai", "started" },
    { "hubungkan ulang ke game", "reconnecting to game" },
    { "Dijeda Penjaga", "Paused by Guard" }, { "Dijeda", "Paused" }, { "Waspada", "Alert" }, { "Ada:", "Present:" },
    { "Aman", "Safe" }, { "Pemain di world", "Players in world" }, { "Staff online di server", "Staff online on server" },
    { "Terdeteksi", "Detected" }, { "kali", "times" }, { "tidak ada", "none" },
    { "pemain diabaikan", "players ignored" },
    { "Masuk world", "Entered world" }, { "Keluar world", "Leave world" },
    { "Masuk lagi dalam", "Rejoining in" }, { "Masuk lagi ke", "Rejoining" }, { "Masuk lagi berhasil", "Rejoined" },
    { "Masuk lagi", "Rejoin" }, { "Masuk ke", "Entering" }, { "Masih ada", "Still here:" }, { "Keluar lagi", "Leaving again" },
    { "Sudah keluar world", "Already left the world" }, { "lanjut otomatis mati", "auto resume off" },
    { "Di luar world", "Outside the world" }, { "Mereka sudah pergi", "They left" }, { "Lanjut dalam", "Resuming in" },
    { "Sudah aman", "Safe now" }, { "World aman", "World is safe" }, { "World sudah beda", "Different world" },
    { "aktivitas tidak dilanjutkan", "activity not resumed" }, { "aktivitas dilanjutkan", "activity resumed" },
    { "aktivitas hanya dijeda", "activity only paused" },
    { "lanjut aktivitas", "resuming activity" }, { "Lanjut aktivitas", "Resuming activity" },
    { "Gagal balik ke posisi farm", "Failed to return to farm position" },
    { "Auto Farm tidak dilanjutkan", "Auto Farm not resumed" },
    { "Jalan balik ke posisi farm", "Walking back to farm position" },
    { "Jalan ke posisi break", "Walking to break position" }, { "Jalan ke posisi drop", "Walking to drop position" },
    { "Cari jalan A* ke", "Finding A* path to" }, { "Jalan ke", "Walking to" }, { "Lompati lubang ke", "Jumping gap to" },
    { "Lompat ke", "Jumping to" }, { "Turun ke", "Dropping down to" }, { "Naik pakai block ke", "Climbing with block to" },
    { "Taruh block pijakan", "Placing scaffold block" },
    { "di bawahnya berbahaya", "dangerous below" }, { "di bawahnya jurang", "pit below" },
    { "Lewati pijakan", "Skip foothold" }, { "Lewati", "Skip" },
    { "Pukul", "Hit" }, { "Pecah", "Broke" }, { "Panen", "Harvest" }, { "Tanam", "Plant" },
    { "Pasang Dirt Farm: sisa", "Placing Dirt Farm: remaining" }, { "Pasang", "Place" },
    { "Gali: sisa", "Digging: remaining" }, { "Gali", "Dig" }, { "Pukul", "Punch" },
    { "Tile Break Dirt Farm", "Dirt Farm Break Tiles" }, { "START DIRT FARM", "START DIRT FARM" }, { "STOP DIRT FARM", "STOP DIRT FARM" },
    { "Semua vending item terpilih sudah kosong", "All vendings of the selected items are empty" },
    { "semua item yang bisa dijual", "all sellable items" },
    { " - coba lagi", " - retrying" }, { "Tambah stock gagal:", "Adding stock failed:" },
    { "Menjauh dari drop sendiri supaya bisa dipungut", "Stepping away from own drops so they can be picked up" },
    { "Item terpilih sudah habis. Tidak diambil (bukan item terpilih):", "Selected items are empty. Not taken (not selected):" },
    { "Hapus pilihan item untuk ambil semua", "Clear the item selection to take everything" }, { "Cek ulang isi vending...", "Re-checking vending contents..." },
    { "Daftar item gagal dimuat:", "Item list failed to load:" }, { "tidak terbaca", "not readable" },
    { "Vending milikmu di", "Your vendings in" },
    { "Jalan ke posisi drop vending", "Walking to the vending drop position" },
    { "Tidak bisa jalan ke posisi drop vending", "Can't reach the vending drop position" },
    { "Tas penuh: atur titik drop vending (WORLD / WORLD:ID / simpan posisi XY)", "Backpack full: set the vending drop point (WORLD / WORLD:ID / save XY position)" },
    { "Daftar item:", "Item list:" }, { "Item dipilih:", "Item selected:" },
    { "Pegang dulu block / seed di tas game (bukan tool)", "Hold a block / seed in the game backpack first (not a tool)" },
    { "Pilihan item dihapus: semua item", "Item selection cleared: all items" },
    { "Posisi drop vending", "Vending drop position" }, { "Posisi drop vending dihapus", "Vending drop position cleared" },
    { "(titik kedatangan)", "(arrival point)" }, { "dropdown belum dibuat", "dropdown not created yet" },
    { "refresh gagal", "refresh failed" }, { "tas", "bag" },
    { "Vending item terpilih penuh / belum ada yang menjual item terpilih", "Vendings of the selected items are full / none sells them yet" },
    { "Fungsi animasi game tidak ketemu (tekan 'Hubungkan ke game')", "Game animation function not found (press 'Connect to game')" },
    { "Animasi", "Animation" }, { "(belum ada item)", "(no items yet)" }, { "| jenis:", "| type:" },
    { ": semua |", ": all |" }, { "jenis: Semua", "type: All" },
    { "Block saja", "Blocks only" }, { "Seed saja", "Seeds only" },
    { "Posisi break produksi", "Production break position" }, { "otomatis", "automatic" },
    { "kanan karakter, dekat ujung baris", "right of the character, near the row end" },
    { "grid Dirt Farm", "Dirt Farm grid" }, { "posisi break Dirt Farm", "Dirt Farm break position" },
    { "Ke vending", "To vending" }, { "): tambah", "): add" }, { "): ambil", "): take" },
    { "Gagal tambah stock di", "Failed to add stock at" }, { "Tidak bisa ke vending", "Can't reach vending" },
    { "Semua vending penuh / belum ada vending yang menjual item", "All vendings full / none sells an item yet" },
    { "Menunggu drop baru di", "Waiting for new drops in" }, { "untuk isi stock", "to restock" },
    { "Pergi ke titik drop", "Going to drop point" }, { "Gagal ke titik drop", "Failed to reach drop point" },
    { "Semua vending sudah kosong", "All vendings are empty" }, { "Ambil", "Take" },
    { "Selesai, ada vending yang gagal diambil", "Done, some vendings could not be emptied" },
    { "Vending kosong, tapi drop gagal", "Vendings empty, but dropping failed" },
    { "Tas penuh oleh item lain, kosongkan tas dulu", "Backpack is full of other items, clear it first" },
    { "Drop gagal", "Drop failed" }, { "Tambah stock gagal terus", "Adding stock keeps failing" },
    { "Gagal pulang ke world vending", "Failed to return to the vending world" },
    { "ambil drop", "to pick drops" },
    { "Tas penuh: atur titik drop vending (WORLD atau WORLD:ID)", "Backpack full: set the vending drop point (WORLD or WORLD:ID)" },
    { "Tidak ada vending milikmu di world ini (jalankan di world vending)", "No vending of yours in this world (run it in the vending world)" },
    { "Fungsi vending game tidak ketemu", "Game vending function not found" },
    { "milikmu di world ini | isi", "yours in this world | stocked" }, { "kosong", "empty" },
    { "diambil", "taken" },
    { "tile gali belum terjangkau, dicoba lagi", "dig tiles not reachable yet, retrying" },
    { "tile gali dilewati", "dig tiles skipped" }, { "Bersihkan drop di Dirt Farm", "Cleaning up drops on the Dirt Farm" },
    { "Ambil drop block sisa galian", "Picking up leftover dug blocks" },
    { "Bersihkan drop sisa galian (per baris)", "Cleaning up leftover dug drops (row by row)" },
    { "Ambil drop sisa di Dirt Farm (per baris)", "Picking up leftover drops on the Dirt Farm (row by row)" },
    { "Bersihkan drop di Dirt Farm (per baris)", "Cleaning up drops on the Dirt Farm (row by row)" },
    { "Bersihkan drop baris y", "Cleaning drops on row y" },
    { "Block habis, produksi 1 baris dulu", "Out of blocks, producing on 1 row first" },
    { "lanjut pasang", "resuming placing" }, { "sisakan", "keep" }, { "baris y", "row y" },
    { "Jalan ke posisi pasang-pecah", "Walking to the place-break spot" },
    { "Naik tangga ke", "Climbing stairs to" }, { "belum terjangkau, dilewati sebentar", "not reachable yet, skipped for a while" },
    { "Tidak ada baris Dirt Farm (cek X awal / X akhir / Y baris atas)", "No Dirt Farm rows (check start X / end X / top row Y)" },
    { "Belum ada baris lengkap", "No complete row yet" }, { "seed-nya tidak ketemu", "its seed was not found" },
    { "celah, tangga, background", "gaps, stairs, background" }, { "selesai", "done" },
    { "Produksi block", "Producing blocks" }, { "total butuh", "total needed" },
    { "Dirt Farm selesai", "Dirt Farm finished" }, { "Block cukup", "Enough blocks" }, { "mulai pasang", "starting to place" },
    { "Block habis, masih kurang", "Out of blocks, still short" }, { "Seed & block habis", "Seeds & blocks used up" },
    { "tidak ada pohon tumbuh", "no trees growing" }, { "Butuh", "Need" }, { "Seed habis", "Out of seeds" },
    { "seed-nya tidak ketemu", "its seed was not found" }, { "Block kurang", "Blocks short" },
    { "Sisa tile belum terjangkau / terhalang, dicoba lagi", "Remaining tiles unreachable / blocked, retrying" },
    { "Dirt Farm penuh, menunggu", "Dirt Farm is full, waiting" }, { "Bukan di world pabrik", "Not in the factory world" },
    { "menunggu...", "waiting..." }, { "Pergi ke", "Going to" }, { "untuk drop", "to drop" }, { "Pulang ke", "Returning to" },
    { "Gagal pulang ke world pabrik", "Failed to return to factory world" }, { "Drop gagal", "Drop failed" },
    { "tidak bisa drop di posisi ini", "can't drop at this position" },
    { "tidak bisa jalan ke posisi drop", "can't walk to the drop position" },
    { "Posisi drop belum diatur", "Drop position not set" }, { "drop dilewati", "drop skipped" },
    { "Posisi drop dihapus", "Drop position cleared" }, { "Posisi drop", "Drop position" }, { "Posisi break", "Break position" },
    { "di posisi pabrik", "at the factory position" }, { "Pabrik berhenti", "Factory stopped" },
    { "Bangun Dirt Farm", "Build Dirt Farm" }, { "Pabrik", "Factory" }, { "Penjaga", "Guard" }, { "Dirt Farm", "Dirt Farm" },
    { "Gagal masuk lagi ke", "Failed to rejoin" }, { "Gagal masuk", "Failed to enter" }, { "Gagal keluar world", "Failed to leave world" },
    { "Dicoba lagi nanti", "Will retry later" }, { "dicoba lagi", "retrying" },
    { "Gagal splice", "Splice failed" }, { "ditolak server", "rejected by server" }, { "Splice jadi", "Spliced into" },
    { "Menunggu tile Grid kosong (panen dulu pohonnya)", "Waiting for empty Grid tiles (harvest the trees first)" },
    { "Seed A habis, tidak ada pohon A yang bisa di-splice", "Seed A used up, no A trees to splice" },
    { "tidak ada tempat tanam / pohon untuk di-splice", "no planting spot / tree to splice" },
    { "Karakter tidak ditemukan (keluar world?)", "Character not found (left the world?)" },
    { "di inventori habis", "in inventory is used up" }, { "Auto Farm berhenti", "Auto Farm stopped" },
    { "Auto Clear berhenti", "Auto Clear stopped" }, { "Farmer berhenti", "Farmer stopped" },
    { "Inventori penuh", "Inventory full" }, { "tidak bisa diambil lagi", "can't be picked up anymore" },
    { "Laporan statistik", "Stats report" }, { "Quest diklaim", "Quest claimed" }, { "Redeem berhasil", "Redeem successful" },
    { "Redeem gagal", "Redeem failed" }, { "Terlempar dari world", "Kicked from world" }, { "Terlempar dari", "Kicked from" },
    { "Kembali otomatis", "Auto return" }, { "berhasil", "succeeded" },
    { "Rejoin: menunggu masuk", "Rejoin: waiting to enter" }, { "Rejoin: gagal masuk", "Rejoin: failed to enter" },
    { "Disconnect dari server", "Disconnected from server" }, { "script tidak di-queue", "script not queued" },
    { "Berhasil masuk lagi", "Rejoined" }, { "World tujuan", "Target world" },
    { "Mode diganti, nyalakan lagi", "Mode changed, turn it on again" }, { "World sudah bersih!", "World is clean!" },
    { "Block pijakan belum dipilih / habis: jalan tanpa block pijakan", "Scaffold block not selected / empty: moving without scaffold" },
    { "Auto Harvest tidak bisa cek pohon siap", "Auto Harvest can't check ready trees" },
    { "Aktifkan Auto Harvest atau Auto Plant", "Enable Auto Harvest or Auto Plant" },
    { "Pilih seed dulu untuk Auto Plant", "Select a seed for Auto Plant first" },
    { "Pilih seed pabrik dulu", "Select a factory seed first" }, { "Block dari seed ini tidak ketemu", "Block for this seed not found" },
    { "Atur Dirt Farm dulu", "Set up the Dirt Farm first" }, { "Pilih block padat untuk Dirt Farm", "Select a solid block for the Dirt Farm" },
    { "Pilih Seed A dan Seed B dulu", "Select Seed A and Seed B first" }, { "Seed A dan Seed B harus beda", "Seed A and Seed B must differ" },
    { "Kombinasi ini tidak bisa di-splice", "This combination can't be spliced" },
    { "Pilih tile dulu di Grid Tile", "Select tiles in the Tile Grid first" }, { "Pilih block dari inventori", "Select a block from inventory" },
    { "Hentikan Auto Farm / Clear / Farmer dulu", "Stop Auto Farm / Clear / Farmer first" },
    { "atau nyalakan Keliling world", "or turn on Roam world" },
    { "Kontrol gerak game (WorldMenu.isDown) tidak ketemu", "Game movement control (WorldMenu.isDown) not found" },
    { "Fungsi pukul game belum ketemu", "Game punch function not found" },
    { "Seed habis: atur posisi & tile break di tab Pabrik supaya bisa dapat seed", "Out of seeds: set break position & tiles in the Factory tab to get seeds" },
    { "Config dihapus. Execute ulang untuk default", "Config deleted. Re-execute for defaults" },
    { "Config dimuat", "Config loaded" }, { "Belum ada config", "No config yet" }, { "Tersimpan", "Saved" },
    { "Executor tidak bisa simpan file", "Executor can't save files" }, { "Executor tidak bisa hapus file", "Executor can't delete files" },
    { "Executor tidak punya fungsi request", "Executor has no request function" },
    { "Gagal simpan file", "Failed to save file" }, { "Gagal hapus file", "Failed to delete file" },
    { "Gagal kirim", "Failed to send" }, { "Terkirim", "Sent" }, { "Antrian", "Queue" },
    { "Gagal buka", "Failed to open" }, { "Gagal", "Failed" },
    -- label status
    { "BERHENTI", "STOPPED" }, { "JALAN", "RUNNING" }, { "fase", "phase" }, { "PANEN", "HARVEST" }, { "TANAM", "PLANT" },
    { "TUNGGU", "WAIT" }, { "TIDAK terbaca (harvest mati)", "NOT readable (harvest off)" }, { "terbaca", "readable" },
    { "TIDAK", "NO" }, { "cadangan", "fallback" }, { "Inventori", "Inventory" }, { "Posisi", "Position" },
    { "Karakter", "Character" }, { "Aksi", "Action" }, { "Baris", "Row" }, { "Pohon", "Trees" }, { "Pijakan", "Scaffold" },
    { "Pemain", "Players" }, { "belum dipilih", "not selected" }, { "belum diatur", "not set" }, { "ditolak", "rejected" },
    { "Bentuk", "Shape" }, { "baris", "rows" }, { "jarak", "spacing" }, { "tangga", "stairs" }, { "punya", "have" },
    { "butuh", "need" }, { "kurang", "short" }, { "cukup", "enough" }, { "Terpasang", "Placed" },
    { "terhalang block lain", "blocked by other blocks" }, { "Celah tanam terisi block", "Planting gaps filled with blocks" },
    { "bersihkan dulu", "clear it first" }, { "Celah tanam: bersih", "Planting gaps: clear" }, { "Seed block", "Block seed" },
    { "Hasil", "Result" }, { "panen", "harvest" }, { "tanam", "plant" }, { "di-drop", "dropped" }, { "sisakan", "keep" },
    { "drop saat", "drop at" }, { "world ini", "this world" }, { "pintu", "door" }, { "Lama sesi", "Session time" },
    { "Block pecah", "Blocks broken" }, { "Block di-place", "Blocks placed" }, { "Drop diambil", "Drops collected" },
    { "Item terbanyak", "Top items" }, { "Selesai", "Done" }, { "diklaim script", "claimed by script" },
    { "Quest baru dalam", "New quests in" }, { "Quest belum bisa diambil", "Quests not available yet" },
    { "Gagal ambil quest", "Failed to get quests" }, { "Gagal ambil daftar code", "Failed to get code list" },
    { "Pesan terakhir", "Last message" }, { "Cek lagi dalam", "Checking again in" }, { "detik", "seconds" },
    { "Auto klaim mati", "Auto claim off" }, { "Code aktif", "Active codes" }, { "sudah ditukar", "redeemed" },
    { "ditukar script", "redeemed by script" }, { "Auto redeem mati", "Auto redeem off" },
    { "Redeem sedang ditutup", "Redeem is closed" }, { "Block depan", "Front blocks" }, { "tumpukan", "piles" },
    { "siap panen", "ready" }, { "tumbuh", "growing" }, { "Scan terakhir", "Last scan" }, { "siap", "ready" },
    { "berikut", "next" }, { "Tidak ada yang cocok", "No matches" }, { "Kosong", "Empty" }, { "Tidak ada pohon", "No trees" },
    { "item lain", "more items" }, { "jenis lain", "more types" }, { "pakai Cari item", "use Search item" },
    { "(pohon)", "(tree)" }, { "Di-recycle", "Recycled" }, { "Item dipilih", "Items selected" }, { "Ditanam", "Planted" },
    { "tidak bisa di-splice", "can't be spliced" }, { "Pilih Seed A dan Seed B", "Select Seed A and Seed B" },
    { "Menghitung...", "Calculating..." }, { "Mulai...", "Starting..." }, { "Lanjut aktivitas...", "Resuming activity..." },
    { "data pemain belum ketemu", "player data not found" }, { "belum ketemu", "not found" },
    { "tidak ketemu", "not found" }, { "ketemu", "found" }, { "tekan", "press" },
    { "tidak ada block padat di inventori", "no solid blocks in inventory" },
    { "tidak ada seed di inventori", "no seeds in inventory" }, { "tidak ada pohon", "no trees" },
    { "tidak ada tempat tanam", "no planting spot" },
    { "Y baris atas", "top row Y" }, { "baris atas", "top row" }, { "Y awal", "start Y" }, { "X awal", "start X" },
    { "jumlah baris", "row count" }, { "masuk lagi dalam", "rejoining in" }, { "masuk ke", "entering" },
    { "dalam", "in" }, { "Executor tidak punya", "Executor has no" },
    { "tidak bisa dijangkau / dipecah", "can't be reached / broken" }, { "Sisa", "Remaining" },
    { "dilewati, coba ulang", "skipped, retrying" }, { "Gagal membaca pengaturan", "Failed to read settings" },
    { "balasan kosong", "empty reply" }, { "fungsi drop game tidak ketemu", "game drop function not found" },
    { "fungsi masuk world tidak ketemu", "game enter-world function not found" },
    { "fungsi splice game tidak ketemu", "game splice function not found" },
    { "gagal masuk", "failed to enter" }, { "nama world tidak diketahui", "unknown world name" },
    { "tidak bisa ke server", "can't reach the server" }, { "tunggu", "wait" },
    { "world penuh / dikunci / gagal", "world full / locked / failed" }, { "aman", "safe" }, { "Fase", "Phase" },
    { "Titik drop belum diatur (tab Titik Drop), drop dilewati", "Drop point not set (Drop Point tab), drop skipped" },
    { "Ambil hasil panen...", "Picking up harvest..." }, { "Lanjut Auto Farm", "Resuming Auto Farm" },
    { "Auto Farm dihentikan", "Auto Farm stopped" }, { "Gagal pulang ke world farmer", "Failed to return to farmer world" },
    { "Gagal pulang ke world farm", "Failed to return to farm world" },
    { "Sesi break tanpa aksi: cek posisi & tile break (dicoba lagi 1 menit)",
        "Break session had no action: check break position & tiles (retry in 1 minute)" },
    { "pohon siap belum terjangkau, dicoba lagi", "ready trees not reachable yet, retrying" },
    { "Seed hampir penuh", "Seeds almost full" },
    { "atur titik drop & nyalakan Auto drop seed", "set a drop point & turn on Auto drop seed" },
    { "Pasang & pecah", "Place & break" }, { "untuk dapat seed", "to get seeds" },
    { "Seed habis & tidak ada tempat pasang-pecah di samping karakter",
        "Out of seeds & no spot beside the character to place and break" },
    { "Tidak ada tempat tanam, menunggu", "No planting spot, waiting" },
    { "drop di titik ini tidak di-collect lagi", "drops at this point are not collected again" },
    { "titik kedatangan", "arrival point" }, { "hasil panen", "harvest" }, { "sisakan seed", "keep seeds" },
    { "Dipakai", "Used by" }, { "Di-drop", "Dropped" }, { "Catatan", "Note" }, { "Titik", "Point" },
    { "Produksi", "Production" }, { "Drop seed", "Seed drop" },
    { "Tidak ada baris yang muat (Y atas terlalu bawah). Berdiri di pojok kiri-ATAS Dirt Farm lalu tekan 'Pakai posisi karakter'",
        "No rows fit (top Y too low). Stand at the TOP-LEFT corner of the Dirt Farm, then press 'Use character position'" },
    { "tidak ada baris yang muat (Y atas terlalu bawah)", "no rows fit (top Y too low)" },
    { "berdiri di pojok kiri-atas lalu tekan 'Pakai posisi karakter'", "stand at the top-left corner, then press 'Use character position'" },
    { "Tidak bisa ke awal Dirt Farm", "Can't reach the Dirt Farm start" }, { "Pecah anak tangga", "Breaking stair step" },
    { "Pasang anak tangga", "Placing stair step" }, { "Turun ke anak tangga", "Stepping down to stair step" },
    { "Bersihkan tile Dirt Farm", "Clearing Dirt Farm tile" }, { "Ambil drop", "Picking up drop" },
    { "1 kosong per baris, tangga kiri & kanan", "1 gap per row, stairs on left & right" },
    { "titik drop belum diatur", "drop point not set" }, { "otomatis saat", "automatic at" },
    { "Dipakai: Pabrik (seed) & Auto Farm (otomatis saat item ~190)",
        "Used by: Factory (seeds) & Auto Farm (automatic when an item reaches ~190)" },
    { "saat", "at" },
    { "Mati", "Off" }, { "mati", "off" }, { "pohon siap", "trees ready" }, { "pohon", "trees" },
    { "di-recycle", "recycled" }, { "di-splice", "spliced" }, { "di-place", "placed" }, { "di-queue", "queued" }, { "habis", "used up" }, { "dan", "and" }, { "atau", "or" }, { "dari", "from" }, { "untuk", "for" },
    { "sudah", "already" }, { "belum", "not yet" }, { "lagi", "again" }, { "di", "at" }, { "ke", "to" },
}

-- Pola tambahan (format waktu "1j 2m 3d" -> "1h 2m 3s", "/jam" -> "/hour")
I18N.RAW = {
    { "(%d+)j (%d+)m (%d+)d", "%1h %2m %3s" },
    { "(%d+)m (%d+)d", "%1m %2s" },
    { "(%d+)j (%d+)m", "%1h %2m" },
    { "/jam", "/hour" },
    { "(%d+) dtk", "%1 s" },
}

function I18N.prep()
    local list = {}
    for _, p in ipairs(I18N.PH) do
        if p[1] ~= p[2] then
            local pat = p[1]:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0")
            if p[1]:match("^%w") then pat = "%f[%w]" .. pat end
            if p[1]:match("%w$") then pat = pat .. "%f[%W]" end
            list[#list + 1] = { pat, (p[2]:gsub("%%", "%%%%")), #p[1] }
        end
    end
    table.sort(list, function(a, b) return a[3] > b[3] end)
    I18N.list = list
end

-- Terjemahkan teks (kalau bahasa = English)
function I18N.T(s)
    if I18N.Lang ~= "en" or type(s) ~= "string" or s == "" then return s end
    local e = I18N.EN[s]
    if e then return e end
    if not I18N.list then I18N.prep() end
    for _, r in ipairs(I18N.list) do s = s:gsub(r[1], r[2]) end
    for _, r in ipairs(I18N.RAW) do s = s:gsub(r[1], r[2]) end
    return s
end

-- Teks pilihan dropdown: hanya terjemahan utuh (nama item game tidak diubah)
function I18N.V(s)
    if I18N.Lang ~= "en" or type(s) ~= "string" then return s end
    return I18N.EN[s] or s
end

-- Bungkus objek WindUI: judul, deskripsi, pilihan dropdown & isi status ikut diterjemahkan
I18N.Backs = setmetatable({}, { __mode = "k" })

local function mapList(list, back)
    local out = {}
    for i, val in ipairs(list) do
        local tr = I18N.V(val)
        out[i] = tr
        if type(tr) == "string" then back[tr] = val end
    end
    return out
end

function I18N.wrap(obj)
    if I18N.Lang ~= "en" or type(obj) ~= "table" then return obj end
    return setmetatable({}, {
        __index = function(_, k)
            local v = obj[k]
            if type(v) ~= "function" then return v end
            return function(_, cfg, ...)
                local back
                if k == "Dropdown" and type(cfg) == "table" then
                    back = {}
                    if type(cfg.Values) == "table" then cfg.Values = mapList(cfg.Values, back) end
                    if type(cfg.Value) == "string" then
                        cfg.Value = I18N.V(cfg.Value)
                    elseif type(cfg.Value) == "table" then
                        cfg.Value = mapList(cfg.Value, back)
                    end
                    local cb = cfg.Callback
                    if cb then
                        -- tampil dalam English, callback tetap terima teks asli
                        cfg.Callback = function(opt, ...)
                            if type(opt) == "string" then
                                opt = back[opt] or opt
                            elseif type(opt) == "table" then
                                local o2 = {}
                                for i, x in ipairs(opt) do o2[i] = back[x] or x end
                                opt = o2
                            end
                            return cb(opt, ...)
                        end
                    end
                elseif (k == "Refresh" or k == "Select") and I18N.Backs[obj] then
                    local b = I18N.Backs[obj]
                    if type(cfg) == "table" then
                        cfg = mapList(cfg, b)
                    elseif type(cfg) == "string" then
                        cfg = I18N.V(cfg)
                    end
                end
                if type(cfg) == "table" and k ~= "Refresh" and k ~= "Select" and cfg[1] == nil then
                    for _, f in ipairs({ "Title", "Desc", "Placeholder", "Content" }) do
                        if type(cfg[f]) == "string" then cfg[f] = I18N.T(cfg[f]) end
                    end
                elseif type(cfg) == "string" and (k == "SetDesc" or k == "SetTitle") then
                    cfg = I18N.T(cfg)
                end
                local r = v(obj, cfg, ...)
                if back and type(r) == "table" then I18N.Backs[r] = back end
                if type(r) == "table" and r ~= obj then return I18N.wrap(r) end
                return r
            end
        end,
    })
end
end)() end

local function notify(title, content, dur)
    task.defer(function()
        pcall(function()
            WindUI:Notify({ Title = I18N.T(title), Content = I18N.T(content), Duration = dur or 3, Icon = "info" })
        end)
    end)
end

---------------------------------------------------------------------
-- CONFIG: simpan & muat pengaturan otomatis
---------------------------------------------------------------------
-- Cara kerja:
--   1. Saat execute, file config dibaca lalu nilainya dipasang ke pengaturan
--      SEBELUM UI dibuat, jadi tombol & slider langsung tampil sesuai config.
--   2. Tiap 3 detik pengaturan sekarang dibandingkan dengan yang terakhir disimpan.
--      Ada yang berubah -> langsung disimpan (auto save).
--   3. File per akun: workspace/ZekioSupremePremiumTest/config_<UserId>.json
--   Yang tidak disimpan: tombol jalan (Auto Farm / Clear / Farmer / Chat), fly & inf jump.
local Config = {
    AutoSave = true,
    Paused = false,      -- true setelah reset (supaya file tidak dibuat lagi)
    Folder = "ZekioSupremePremiumTest",
    Data = {},           -- isi file saat execute
    List = {},           -- tabel pengaturan yang disimpan
    LastJson = nil,
    Status = "-",
}

do (function() -- fungsi sendiri: variabel di dalam tidak ikut batas 200 local
    local HttpService = game:GetService("HttpService")
    local canFile = type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
    Config.CanFile = canFile
    Config.Path = Config.Folder .. "/config_" .. tostring(LocalPlayer.UserId) .. ".json"

    local function read()
        if not canFile then return nil end
        local okE, exists = pcall(isfile, Config.Path)
        if not okE or not exists then return nil end
        local okR, raw = pcall(readfile, Config.Path)
        if not okR or type(raw) ~= "string" then return nil end
        local okD, data = pcall(HttpService.JSONDecode, HttpService, raw)
        if okD and type(data) == "table" then return data end
        return nil
    end

    local loaded = read()
    Config.Found = loaded ~= nil
    Config.Data = loaded or {}
    if Config.Data.AutoSave == false then Config.AutoSave = false end
    Config.Status = Config.Found and "Config dimuat" or (canFile and "Belum ada config" or "Executor tidak bisa simpan file")

    -- Daftarkan tabel pengaturan. Nilai dari file langsung dipasang
    -- (kecuali key di 'later', dipasang sendiri setelah terhubung ke game).
    function Config.add(name, tbl, keys, later)
        table.insert(Config.List, { name = name, tbl = tbl, keys = keys })
        local saved = Config.Data[name]
        if type(saved) ~= "table" then return end
        for _, k in ipairs(keys) do
            local v, cur = saved[k], tbl[k]
            if v ~= nil and not (later and later[k]) and (cur == nil or type(v) == type(cur)) then
                tbl[k] = v
            end
        end
    end

    function Config.saved(name, key)
        local t = Config.Data[name]
        return type(t) == "table" and t[key] or nil
    end

    local function collect()
        local out = { AutoSave = Config.AutoSave, Version = 1 }
        for _, e in ipairs(Config.List) do
            local t = {}
            for _, k in ipairs(e.keys) do t[k] = e.tbl[k] end
            out[e.name] = t
        end
        return out
    end

    function Config.save(force)
        if not canFile then
            Config.Status = "Executor tidak bisa simpan file"
            return false
        end
        if Config.Paused and not force then return false end
        local okJ, json = pcall(HttpService.JSONEncode, HttpService, collect())
        if not okJ then
            Config.Status = "Gagal membaca pengaturan"
            return false
        end
        if not force and json == Config.LastJson then return true end
        if type(isfolder) == "function" and type(makefolder) == "function" then
            local okF, has = pcall(isfolder, Config.Folder)
            if okF and not has then pcall(makefolder, Config.Folder) end
        end
        local ok = pcall(writefile, Config.Path, json)
        if ok then
            Config.LastJson = json
            Config.Paused = false
            Config.Status = "Tersimpan " .. os.date("%H:%M:%S")
        else
            Config.Status = "Gagal simpan file"
        end
        return ok
    end

    -- Hapus file config (execute ulang = kembali ke default)
    function Config.reset()
        Config.Paused = true
        Config.LastJson = nil
        if canFile and type(delfile) == "function" then
            local ok = pcall(delfile, Config.Path)
            Config.Status = ok and "Config dihapus. Execute ulang untuk default" or "Gagal hapus file"
            return ok
        end
        Config.Status = "Executor tidak bisa hapus file"
        return false
    end

    function Config.start()
        -- tandai kondisi sekarang sebagai "sudah tersimpan" kalau sama dengan file
        if Config.Found then
            local okJ, json = pcall(HttpService.JSONEncode, HttpService, collect())
            if okJ then Config.LastJson = json end
        end
        task.spawn(function()
            while alive() do
                task.wait(3)
                if Config.AutoSave and alive() then Config.save(false) end
            end
        end)
    end
end)() end

Config.add("Farm", State, {
    "Mode", "PlaceMs", "BreakMs", "AfterBreakMs", "HitsOverride", "SelectedId", "Offsets",
    "CalibX", "CalibY", "AntiAfk", "MutePunch", "Visual", "LiteMode", "AutoCollect", "MultiTarget",
    "CollectAround", "CollectRadius", "CollectMode", "SkipCollectGems", "SeedDrop", "SeedDropAt", "SeedKeep",
})
Config.add("Clear", Clear, { "UseBlock", "ScaffoldId", "Collect", "Sweep" })
Config.add("Farmer", Farmer, {
    "Harvest", "HarvestOnly", "Plant", "Collect", "UseBlock", "ScaffoldId", "HarvestMs", "PlantMs", "SeedId",
})
-- Config lama belum memiliki pilihan fokus panen. Saat pertama memakai
-- versi ini, pilihan awal tetap harvest saja, tanpa tanam / auto drop.
Farmer.Drop = false
if Farmer.HarvestOnly then Farmer.Harvest, Farmer.Plant = true, false end
-- update 1084: game memberi jeda minimal antar aksi (place ~0.135 dtk, pukul ~0.19 dtk)
State.PlaceMs = math.max(State.PlaceMs, 140)
State.BreakMs = math.max(State.BreakMs, 200)
Farmer.HarvestMs = math.max(Farmer.HarvestMs, 140)
Farmer.PlantMs = math.max(Farmer.PlantMs, 140)
Config.add("Misc", Misc, { "Speed" })
Config.add("Chat", Spam, { "Texts", "IntervalSec" })
Config.add("Lahan", Land, { "X0", "X1", "Y0" })
Config.add("Bangun", Build, { "BlockId", "ThenPabrik", "BreakX", "BreakY", "Tiles" })
Config.add("Vending", Vend, { "Mode", "Point", "Items", "DropX", "DropY" })
Config.add("Pabrik", Pabrik, {
    "Fast", "SeedId", "WholeWorld", "Tiles", "BreakX", "BreakY",
    "Drop", "Keep", "DropAt", "DropWorld", "DropX", "DropY",
})
Config.add("PremiumUI", Premium.Values, { "ui.theme", "ui.scale", "ui.notifications", "ui.transparency", "ui.layoutRevision" })
Premium.ApplyAppearance()
Config.add("Bahasa", I18N, { "Saved", "Ask" })
I18N.Lang = (I18N.Saved == "en") and "en" or "id"

---------------------------------------------------------------------
-- STATISTIK SESI & NOTIFIKASI DISCORD (data; tampilan ada di tab Statistik / Discord)
---------------------------------------------------------------------
local Stats = { T0 = os.clock(), Gems0 = nil, Items = {}, Base = {} }

-- Cara kerja webhook:
--   Hook.send(jenis, teks) memasukkan pesan ke antrian.
--   Antrian dikirim satu per satu tiap 2.5 detik (supaya tidak kena batas Discord).
local Hook = {
    On = false,
    Url = "",
    Penjaga = true,   -- mod / dev / pemain masuk world
    Stop = true,      -- aktivitas berhenti (block habis, error)
    Full = true,      -- inventori penuh
    Bonus = true,     -- quest diklaim / redeem berhasil
    Rejoin = true,    -- terlempar / masuk lagi
    Pabrik = true,    -- pabrik drop / lahan selesai / berhenti
    ReportMin = 0,    -- laporan statistik tiap X menit (0 = mati)
    Queue = {},
    LastFull = {},
    Status = "-",
}

do (function()
    local HttpService = game:GetService("HttpService")

    local function requester()
        return (syn and syn.request) or (http and http.request) or http_request or request
            or (fluxus and fluxus.request)
    end

    function Hook.valid(url)
        url = tostring(url or "")
        for _, host in ipairs({ "discord.com", "discordapp.com", "ptb.discord.com", "canary.discord.com" }) do
            if string.sub(url, 1, #host + 22) == "https://" .. host .. "/api/webhooks/" then return true end
        end
        return false
    end

    -- jenis: "penjaga" | "stop" | "full" | "bonus" | "rejoin" | "report" | "test"
    function Hook.send(kind, text)
        if not Hook.On or not Hook.valid(Hook.Url) then return end
        local allow = kind == "test" or kind == "report"
            or (kind == "penjaga" and Hook.Penjaga) or (kind == "stop" and Hook.Stop)
            or (kind == "full" and Hook.Full) or (kind == "bonus" and Hook.Bonus)
            or (kind == "rejoin" and Hook.Rejoin) or (kind == "pabrik" and Hook.Pabrik)
        if not allow or #Hook.Queue >= 20 then return end
        table.insert(Hook.Queue, I18N.T(tostring(text)))
    end

    task.spawn(function()
        while alive() do
            local text = table.remove(Hook.Queue, 1)
            if not text then
                task.wait(0.5)
            else
                local req = requester()
                if not req then
                    Hook.Status = "Executor tidak punya fungsi request"
                else
                    local body = HttpService:JSONEncode({
                        username = "Zekio Supreme Premium",
                        content = ("**[%s]** %s"):format(LocalPlayer.Name, text),
                    })
                    local ok, res = pcall(req, {
                        Url = Hook.Url, Method = "POST",
                        Headers = { ["Content-Type"] = "application/json" }, Body = body,
                    })
                    local code = ok and type(res) == "table" and tonumber(res.StatusCode or res.Status) or nil
                    if ok and (code == nil or code < 300) then
                        Hook.Status = "Terkirim " .. os.date("%H:%M:%S")
                    else
                        Hook.Status = "Gagal kirim (" .. tostring(code or res) .. ")"
                    end
                end
                task.wait(2.5)
            end
        end
    end)
end)() end

---------------------------------------------------------------------
-- CARI DATA & FUNGSI GAME (getgc)
---------------------------------------------------------------------
local function getconsts(fn)
    -- Sebagian executor menyediakan API debug yang mengembalikan tabel kosong.
    -- Coba kedua API sebelum menyimpulkan fungsi game tidak ditemukan.
    local previous
    for index, api in ipairs({ (debug and debug.getconstants) or false, getconstants or false }) do
        if type(api) == "function" and api ~= previous then
            previous = api
            local ok, constants = pcall(api, fn)
            if ok and type(constants) == "table" and next(constants) ~= nil then
                Refs.ConstantsAPI = index == 1 and "debug.getconstants" or "getconstants"
                return constants
            end
        end
    end
    return {}
end
local getUpvalues -- dipakai juga oleh pencarian inventori sebelum bagian Auto Collect

-- Fungsi place game: satu-satunya yang memakai "placedAt" + "flips" sekaligus.
-- Kirimnya "tile" (game baru, ByteNet) atau "SetTile" (game lama).
local function isSetTileFn(fn)
    if not getconsts then return false end
    local ok, consts = pcall(getconsts, fn)
    if not ok or type(consts) ~= "table" then return false end
    local hasSend, hasPlaced, hasFlips = false, false, false
    for _, c in pairs(consts) do
        if c == "tile" or c == "SetTile" then hasSend = true
        elseif c == "placedAt" then hasPlaced = true
        elseif c == "flips" then hasFlips = true end
    end
    return hasSend and hasPlaced and hasFlips
end

-- Fungsi pukul game: teks "Empty the Vending Machine first!" + "newCrack"
-- (game lama: "HarvestProvider")
local function isPunchFn(fn)
    if not getconsts then return false end
    local ok, consts = pcall(getconsts, fn)
    if not ok or type(consts) ~= "table" then return false end
    local hasVend, hasMark = false, false
    for _, c in pairs(consts) do
        if type(c) == "string" then
            local text = c:lower()
            if text:find("vending", 1, true)
                and (text:find("empty", 1, true) or text:find("break", 1, true)) then
                hasVend = true
            end
            if c == "newCrack" or c == "HarvestProvider" then hasMark = true end
        end
    end
    return hasVend and hasMark
end

-- Fungsi game yang menggambar tangan karakter saat memukul / memasang
function Anim.isArmFn(fn)
    if not getconsts then return false end
    local ok, consts = pcall(getconsts, fn)
    if not ok or type(consts) ~= "table" then return false end
    local a, b, c = false, false, false
    for _, k in pairs(consts) do
        if k == "forearm" then a = true
        elseif k == "heldReach" then b = true
        elseif k == "punchReach" then c = true end
    end
    return a and b and c
end

-- Cari nomor upvalue "aksi terakhir" (tabel {t, x, y, facing} atau nil) di fungsi tangan.
-- Upvalue ini dipakai bersama oleh kode input & gambar karakter game, jadi cukup diganti sekali.
function Anim.bind(fn)
    local gu = (debug and debug.getupvalue) or getupvalue
    local su = (debug and debug.setupvalue) or setupvalue
    if not (gu and su) then return false end
    local vals, last = {}, 0
    for i = 1, 16 do
        local ok, v = pcall(gu, fn, i)
        if not ok then break end
        vals[i] = v
        if v ~= nil then last = i end
    end
    for i = 1, last - 1 do
        local v = vals[i]
        if v == nil or (type(v) == "table" and rawget(v, "t") ~= nil and rawget(v, "facing") ~= nil) then
            Anim.fn, Anim.idx, Anim.set = fn, i, su
            return true
        end
    end
    return false
end

local function isStateHolder(v)
    local fn = rawget(v, "state")
    if type(fn) ~= "function" then return false end
    local ok, s = pcall(fn)
    return ok and type(s) == "table" and type(s.x) == "number" and type(s.y) == "number"
        and s.facing ~= nil and s.vx ~= nil
end

-- Pastikan fungsi milik game, bukan milik script ini
local function isGameFn(fn)
    if fn == isSetTileFn or fn == isPunchFn then return false end
    if isexecutorclosure then
        local ok, res = pcall(isexecutorclosure, fn)
        if ok and res then return false end
    end
    -- Fungsi game juga bisa berada di Shared / PlayerScripts. Nama source bukan
    -- bukti bahwa fungsi itu bukan milik game; cocokkan sidik fungsi di bawah.
    return true
end

function Refs.member(v, key)
    local ok, value = pcall(function() return v[key] end)
    if ok then return value end
end

function Refs.inventorySlots(v)
    if type(v) ~= "table" then return nil end
    -- slots boleh diwariskan lewat __index, bukan hanya field mentah pada tabel.
    local slots = Refs.member(v, "slots")
    return type(slots) == "table" and slots or nil
end

-- require() dari executor tidak selalu memberi objek modul yang identik dengan
-- require() milik game. Terima kontrak inventori yang sama tanpa menyamakan closure.
function Refs.inventoryOK(v)
    if v == InventoryModule or not Refs.inventorySlots(v) then return false end
    local count = Refs.member(v, "count")
    if type(count) ~= "function" then return false end
    local ok, mt = pcall(getmetatable, v)
    if ok and type(mt) == "table" and (mt == InventoryModule or rawget(mt, "__index") == InventoryModule) then
        return true
    end
    if count == Refs.member(InventoryModule, "count") then return true end
    -- Jangan menerima tabel {slots = ...} saja (misalnya config atau daftar UI).
    return type(Refs.member(v, "add")) == "function"
        and type(Refs.member(v, "remove")) == "function"
        and type(Refs.member(v, "room")) == "function"
end

-- Telusuri referensi dengan batas ukuran/kedalaman, tanpa memanggil metode yang
-- mengubah isi tas. Ini juga bekerja ketika getgc() tidak mengekspos tabel game.
function Refs.findInventory(roots, limit)
    limit = limit or 1200
    local queue, seen, cursor = {}, {}, 1
    local found = Refs.inventoryOK(Refs.Inv) and Refs.Inv or nil
    local source = found and Refs.InvSource or nil
    local keys = { "inventory", "Inventory", "inv", "Inv", "backpack", "Backpack",
        "bag", "Bag", "data", "Data", "state", "State", "openBackpack", "ui" }
    local function push(value, depth, label)
        local kind = type(value)
        if (kind ~= "table" and kind ~= "function") or seen[value] or #queue >= limit then return end
        if value == G or value == _G or value == Refs or value == UI or value == Session
            or value == State or value == ItemDB or value == InventoryModule then return end
        if kind == "function" and not isGameFn(value) then return end
        seen[value] = true
        queue[#queue + 1] = { value = value, depth = depth, label = label }
    end
    for _, root in ipairs(roots) do push(root.value, 0, root.label) end
    while cursor <= #queue do
        local entry = queue[cursor]
        cursor = cursor + 1
        local value, depth = entry.value, entry.depth
        if type(value) == "table" then
            if not found and Refs.inventoryOK(value) then found, source = value, entry.label end
            if not Refs.World and type(rawget(value, "fg")) == "table"
                and type(rawget(value, "bg")) == "table" and type(rawget(value, "w")) == "number"
                and type(rawget(value, "h")) == "number" and rawget(value, "spawn") ~= nil then
                Refs.World = value
            end
            if found and Refs.World then return found, source, "objek " .. tostring(cursor - 1) end
            if depth < 5 then
                -- Field bernama didahulukan supaya objek UI besar tidak memenuhi antrian.
                for _, key in ipairs(keys) do
                    push(rawget(value, key), depth + 1, entry.label .. "." .. key)
                end
                local count = 0
                for key, child in next, value do
                    count = count + 1
                    if count > 64 then break end
                    -- Grid tile / isi slot bukan pemilik inventori dan bisa sangat besar.
                    if key ~= "_G" and key ~= "_ENV" and key ~= "fg" and key ~= "bg"
                        and key ~= "slots" and key ~= "live" and key ~= "free" then
                        push(child, depth + 1, entry.label)
                    end
                end
                local ok, mt = pcall(getmetatable, value)
                if ok and type(mt) == "table" then push(rawget(mt, "__index"), depth + 1, entry.label) end
            end
        elseif depth < 5 and getUpvalues then
            for _, upvalue in pairs(getUpvalues(value)) do
                push(upvalue, depth + 1, entry.label .. ".upvalue")
            end
        end
        if cursor % 100 == 0 then task.wait() end
    end
    local canRead = (debug and (type(debug.getupvalues) == "function" or type(debug.getupvalue) == "function"))
        or type(getupvalues) == "function" or type(getupvalue) == "function"
    return found, source, "objek " .. tostring(cursor - 1) .. "; upvalue " .. (canRead and "tersedia" or "tidak tersedia")
end

function Refs.inventoryFn(fn)
    if type(getconstants) ~= "function" and not (debug and type(debug.getconstants) == "function") then return true end
    local ok, constants = pcall(getconsts, fn)
    if not ok or type(constants) ~= "table" then return false end
    for _, key in pairs(constants) do
        if key == "slots" or key == "inventory" or key == "Inventory"
            or key == "backpack" or key == "Backpack" or key == "openBackpack" then return true end
    end
    return false
end

function Refs.inventoryEntries()
    local inv = Refs.Inv
    local slots = Refs.inventorySlots(inv)
    if not Refs.inventoryOK(inv) or type(slots) ~= "table" then
        Refs.InvError = "Data inventori belum ditemukan (deteksi r2); rincian pencarian ada di tab Koneksi"
        return {}
    end
    Refs.InvError = nil
    local out = {}
    -- pairs tetap membaca slot setelah lubang / indeks 0; ipairs berhenti di lubang pertama.
    for _, slot in pairs(slots) do
        if type(slot) == "table" then
            local id, n = tonumber(slot.id), tonumber(slot.n)
            if id and id >= 0 and id < math.huge and id % 1 == 0 and n and n > 0 and n < math.huge then
                out[#out + 1] = { id = id, n = n }
            end
        end
    end
    return out
end

local function findRefs()
    -- Periksa kemampuan scan sebelum menghapus hasil quickRefs yang sudah berhasil.
    if type(getgc) ~= "function" then
        Refs.ScanErr = "Executor tidak punya getgc()"
        return false, Refs.ScanErr
    end
    local okGC, objects = pcall(getgc, true)
    if not okGC or type(objects) ~= "table" then
        Refs.ScanErr = "Scan game gagal: " .. tostring(objects)
        return false, Refs.ScanErr
    end
    Refs.ScanErr = nil
    local previousInv = Refs.inventoryOK(Refs.Inv) and Refs.Inv or nil
    local previousSource = Refs.InvSource
    local inventoryRoots = {}
    Refs.World, Refs.Inv, Refs.SetTile, Refs.State, Refs.Punch, Refs.Menu = nil, nil, nil, nil, nil, nil
    Refs.StateOwner = nil
    Refs.Input, Refs.InputSource = nil, nil
    Refs.InvSource = nil
    Refs.Gems = nil
    Refs.Hud = nil
    Refs.Others = nil
    Refs.Arm = nil
    Refs.Particles = {}
    Anim.Particles = nil
    for _, v in pairs(objects) do
        local tv = type(v)
        if tv == "table" then
            if not Refs.World then
                local ok, isWorld = pcall(function()
                    return type(rawget(v, "fg")) == "table" and type(rawget(v, "bg")) == "table"
                        and type(rawget(v, "w")) == "number" and type(rawget(v, "h")) == "number"
                        and rawget(v, "spawn") ~= nil
                end)
                if ok and isWorld then Refs.World = v end
            end
            if not Refs.Inv then
                if Refs.inventoryOK(v) then
                    Refs.Inv, Refs.InvSource = v, "getgc"
                elseif #inventoryRoots < 160 and (rawget(v, "inventory") or rawget(v, "Inventory")
                    or rawget(v, "inv") or rawget(v, "backpack")) then
                    inventoryRoots[#inventoryRoots + 1] = { value = v, label = "data game" }
                end
            end
            if not Refs.State then
                local ok, isHolder = pcall(isStateHolder, v)
                if ok and isHolder then Refs.State, Refs.StateOwner = rawget(v, "state"), v end
            end
            if not Refs.Menu then
                local ok, isMenu = pcall(function()
                    return type(Refs.member(v, "openBackpack")) == "function" and type(Refs.member(v, "ui")) == "table"
                end)
                if ok and isMenu then Refs.Menu = v end
            end
            if not Refs.Gems then
                local ok, isG = pcall(function() return type(rawget(v, "addGems")) == "function" end)
                if ok and isG then Refs.Gems = v end
            end
            if not Refs.Hud then
                local ok, isH = pcall(function()
                    return type(rawget(v, "punchRange")) == "function" and type(rawget(v, "handPower")) == "function"
                end)
                if ok and isH then Refs.Hud = v end
            end
            if not Refs.Others then
                -- data pemain lain: punya list(), where(), playerAt()
                local ok, isO = pcall(function()
                    return type(rawget(v, "list")) == "function" and type(rawget(v, "where")) == "function"
                        and type(rawget(v, "playerAt")) == "function"
                end)
                if ok and isO then Refs.Others = v end
            end
            if ParticlesOk then
                local ok, isP = pcall(function()
                    return getmetatable(v) == ParticlesModule and type(rawget(v, "live")) == "table"
                        and type(rawget(v, "free")) == "table"
                end)
                if ok and isP then table.insert(Refs.Particles, v) end
            end
        elseif tv == "function" and isGameFn(v) then
            if not Refs.SetTile and isSetTileFn(v) then
                Refs.SetTile = v
            elseif not Refs.Punch and isPunchFn(v) then
                Refs.Punch = v
            end
            if not Refs.Inv and #inventoryRoots < 160 and Refs.inventoryFn(v) then
                inventoryRoots[#inventoryRoots + 1] = { value = v, label = "fungsi game" }
            end
        end
        if Refs.World and Refs.Inv and Refs.SetTile and Refs.State and Refs.Punch
            and Refs.Menu and Refs.Gems and Refs.Hud and Refs.Others then break end
    end
    if not Refs.Inv then
        table.insert(inventoryRoots, 1, { value = Refs.World, label = "world" })
        table.insert(inventoryRoots, 1, { value = Refs.Menu, label = "menu" })
        table.insert(inventoryRoots, 1, { value = MenuModOk and MenuModule or nil, label = "WorldMenu" })
        Refs.Inv, Refs.InvSource, Refs.InvScanInfo = Refs.findInventory(inventoryRoots)
    end
    if not Refs.Inv and previousInv then Refs.Inv, Refs.InvSource = previousInv, previousSource end
    return Refs.World ~= nil
end





-- Fast Pull is adapted from the Fast Wrench implementation in anchhub_delta.lua.
-- It never guesses a target or reports that the server accepted the command.
do (function()
    local fast = { active=false, generation=0, patches={}, slots={}, lastAt=0, lastUid=nil }
    local getUp = (debug and debug.getupvalue) or getupvalue
    local setUp = (debug and debug.setupvalue) or setupvalue
    local constants = (debug and debug.getconstants) or getconstants

    local function status(message)
        if Premium.SetProxyPullStatus then Premium.SetProxyPullStatus(message) end
    end
    local function readUp(fn, index)
        if type(getUp) ~= "function" then return false end
        local ok, a, b = pcall(getUp, fn, index)
        if not ok then return false end
        if type(a) == "string" and b ~= nil then return true, b end
        return true, a
    end
    local function restore()
        fast.active = false
        fast.generation = fast.generation + 1
        for _, patch in ipairs(fast.patches) do
            local ok, current = readUp(patch.fn, patch.index)
            if ok and current == fast.wrapper then pcall(setUp, patch.fn, patch.index, patch.old) end
        end
        for _, slot in ipairs(fast.slots) do
            if rawget(slot.owner, slot.key) == fast.wrapper then pcall(rawset, slot.owner, slot.key, slot.old) end
        end
        table.clear(fast.patches); table.clear(fast.slots)
        fast.wrapper = nil
        fast.lastAt, fast.lastUid = 0, nil
    end
    Premium.ProxyStop = restore

    local function resolveTarget(argument)
        local requested = tonumber(argument)
        if type(argument) == "table" then
            requested = tonumber(rawget(argument, "id") or rawget(argument, "pid") or rawget(argument, "userId"))
        end
        if not requested then return nil, nil, false end
        local found, display, conflict = nil, nil, false
        local function offer(uid, name)
            uid = tonumber(uid)
            if not uid or uid <= 0 or uid % 1 ~= 0 or uid == LocalPlayer.UserId then return end
            if found and found ~= uid then conflict = true; return end
            found, display = uid, tostring(name or uid):gsub("`.", "")
        end
        if type(argument) == "table" then offer(rawget(argument,"userId"), rawget(argument,"name")) end
        local okPlayer, directPlayer = pcall(Players.GetPlayerByUserId, Players, requested)
        if okPlayer and directPlayer then offer(directPlayer.UserId, directPlayer.Name) end
        local others = Refs.Others
        if others and type(rawget(others, "list")) == "function" then
            local ok, list = pcall(rawget(others, "list"))
            if ok and type(list) == "table" then
                for key, item in pairs(list) do
                    if type(item) == "table" then
                        local uid = tonumber(rawget(item,"userId") or rawget(item,1))
                        if tonumber(rawget(item,"id")) == requested
                            or tonumber(rawget(item,"pid")) == requested or uid == requested then
                            offer(uid, rawget(item,"name") or rawget(item,2))
                        end
                    end
                end
            end
        end
        -- The reference implementation finds selected player data in call-stack upvalues.
        -- Only accept an entry that matches the requested id; do not choose a nearby or first player.
        local playerDialog = false
        local pending = {}
        local menu = PlayerGui:FindFirstChild("MenuGui")
        menu = menu and menu:FindFirstChild("Player")
        if debug and type(debug.info) == "function" and type(getUp) == "function" then
            for level = 2, 18 do
                local ok, fn = pcall(debug.info, level, "f")
                if not ok or type(fn) ~= "function" then break end
                for index = 1, 30 do
                    local got, value = readUp(fn, index)
                    if not got then break end
                    if type(value) == "table" then
                        local uid = tonumber(rawget(value,"userId"))
                        if uid and (tonumber(rawget(value,"id")) == requested
                            or tonumber(rawget(value,"pid")) == requested or uid == requested) then
                            pending[#pending+1] = {uid=uid, name=rawget(value,"name")}
                        end
                        local box = rawget(value,"box")
                        if menu and typeof(box) == "Instance" and type(rawget(value,"close")) == "function" then
                            local boxOK, belongs = pcall(function() return box == menu or box:IsDescendantOf(menu) end)
                            if boxOK and belongs then playerDialog = true end
                        end
                    end
                end
            end
        end
        for _, candidate in ipairs(pending) do offer(candidate.uid, candidate.name) end
        if conflict then return nil, nil, playerDialog end
        return found, display, playerDialog
    end

    function Premium.ProxyStart()
        restore()
        if not alive() then return false, "Sesi game sudah ditutup." end
        if not NetOk or type(Net) ~= "table" or type(rawget(Net,"call")) ~= "function" then
            return false, "Net.call tidak tersedia. Hubungkan data game lalu coba lagi."
        end
        local original = rawget(Net,"call")
        fast.active = true
        local generation = fast.generation
        local function wrapper(command, ...)
            local target = select(1, ...)
            if not fast.active or not alive() or fast.generation ~= generation then
                return original(command, ...)
            end
            if command == "WrenchPlayer" or command == "GetPlayerLevel" or command == "PlayerInfo" then
                local resolveOK, uid, name, inPlayerDialog = pcall(resolveTarget, target)
                local wrenchEvent = command == "WrenchPlayer" or inPlayerDialog
                if resolveOK and wrenchEvent and uid then
                    local now = os.clock()
                    if fast.lastUid == uid and now - fast.lastAt < 0.3 then return nil end
                    fast.lastAt, fast.lastUid = now, uid
                    task.spawn(function()
                        if not fast.active or not alive() or fast.generation ~= generation then return end
                        local ok, response = pcall(original, "WorldCommand", "pull", "#" .. tostring(uid))
                        if not fast.active or fast.generation ~= generation then return end
                        if not ok or response == false then
                            status("Perintah pull gagal atau ditolak untuk " .. tostring(name) .. ".")
                        else
                            status("Perintah pull dikirim untuk " .. tostring(name) .. ". Hasil bergantung pada game.")
                        end
                    end)
                    return nil
                elseif command == "WrenchPlayer" then
                    status("Target wrench belum dapat dipastikan; dialog game tetap dilanjutkan.")
                end
            end
            return original(command, ...)
        end
        fast.wrapper = wrapper
        local function patchSlot(owner, key)
            if type(owner) ~= "table" or rawget(owner,key) ~= original then return end
            local ok = pcall(rawset, owner, key, wrapper)
            if ok and rawget(owner,key) == wrapper then
                fast.slots[#fast.slots+1] = {owner=owner, key=key, old=original}
            end
        end
        patchSlot(Net, "call")
        patchSlot(Refs.World, "call")

        -- Only patch a closure that explicitly contains the wrench command and
        -- holds this exact Net.call as an upvalue. Avoid a global replacement.
        if type(getgc) == "function" and type(constants) == "function"
            and type(getUp) == "function" and type(setUp) == "function" then
            local ok, objects = pcall(getgc, false)
            if ok and type(objects) == "table" then
                for n, fn in ipairs(objects) do
                    if not fast.active or not alive() or fast.generation ~= generation then return false, "Fast Pull dibatalkan." end
                    if type(fn) == "function" and fn ~= wrapper then
                        local gameFn = true
                        if type(isexecutorclosure) == "function" then
                            local checkOK, isExec = pcall(isexecutorclosure, fn)
                            if checkOK and isExec then gameFn = false end
                        end
                        if gameFn then
                            local constOK, values = pcall(constants, fn)
                            local isWrench = false
                            if constOK and type(values) == "table" then
                                for _, value in pairs(values) do if value == "WrenchPlayer" then isWrench = true; break end end
                            end
                            if isWrench then
                                for index = 1, 30 do
                                    local got, value = readUp(fn, index)
                                    if not got then break end
                                    if value == original then
                                        local changed = pcall(setUp, fn, index, wrapper)
                                        local verified, current = readUp(fn, index)
                                        if changed and verified and current == wrapper then
                                            fast.patches[#fast.patches+1] = {fn=fn,index=index,old=original}
                                        end
                                    end
                                end
                            end
                        end
                    end
                    if n % 300 == 0 then task.wait() end
                end
            end
        end
        if #fast.slots == 0 and #fast.patches == 0 then
            restore()
            return false, "Pemantau wrench tidak dapat dipasang oleh executor."
        end
        status("Aktif. Gunakan wrench pada pemain; jika target tidak jelas, dialog normal tetap terbuka.")
        return true
    end
end)() end

local function refsText()
    return "World: " .. (Refs.World and "OK" or "TIDAK")
        .. " | Inventori: " .. (Refs.inventoryOK(Refs.Inv) and "OK" or "TIDAK")
        .. " | setTile: " .. (Refs.SetTile and "OK" or "cadangan")
        .. " | Posisi: " .. (Refs.State and "OK" or "cadangan")
        .. " | Pukul: " .. (Refs.Punch and "OK" or "TIDAK")
        .. " | Drop: " .. (Drops.list and "OK" or "TIDAK")
        .. " | Pohon: " .. (Refs.Trees and "OK" or "TIDAK")
        .. " | Pemain: " .. (Refs.Others and "OK" or "TIDAK")
        .. " | Animasi: " .. (Anim.fn and "OK" or "TIDAK")
        .. " | Dropdown: " .. (UI.DropErr and ("ERROR " .. tostring(UI.DropErr))
            or (not Refs.inventoryOK(Refs.Inv) and "menunggu inventori") or (UI.DropOk and "OK" or "-"))
        .. "\nKontrol gerak: " .. tostring(AutoInput and AutoInput.status and AutoInput.status() or "belum diperiksa")
        .. "\nStartup: " .. tostring(Shared and Shared.Status or "-")
        .. "\nDeteksi inventori r2: " .. tostring(Refs.InvSource or Refs.InvScanInfo or "-")
        .. (Refs.TreeScanError and ("\nPohon: " .. Refs.TreeScanError) or "")
        .. (Refs.InvError and ("\nInventori: " .. Refs.InvError) or "")
        .. (Refs.InvWatchErr and ("\nEvent inventori: " .. Refs.InvWatchErr) or "")
        .. (Refs.ScanErr and ("\nScan: " .. Refs.ScanErr) or "")
end

---------------------------------------------------------------------
-- ITEM & INVENTORI
---------------------------------------------------------------------
local function itemName(id)
    local it = ItemDB[id]
    return (it and it.name) or ("Item #" .. tostring(id))
end

local function invCount(id)
    if not Refs.Inv then return 0 end
    local ok, n = pcall(function() return Refs.Inv:count(id) end)
    n = ok and tonumber(n) or nil
    if n and n >= 0 and n < math.huge then return n end
    local total = 0
    for _, slot in ipairs(Refs.inventoryEntries()) do
        if slot.id == tonumber(id) then total = total + slot.n end
    end
    return total
end

local function isPlaceable(id)
    local it = ItemDB[id]
    if not it then return false end
    if it.kind == "tool" or it.kind == "cloth" or it.kind == "clothes" or it.kind == "consumable" then
        return false
    end
    if it.lock or it.area then return false end
    return true
end

local function placeableIds()
    local ids, seen = {}, {}
    for _, slot in ipairs(Refs.inventoryEntries()) do
        if not seen[slot.id] and isPlaceable(slot.id) then
            seen[slot.id] = true
            ids[#ids + 1] = slot.id
        end
    end
    table.sort(ids)
    return ids
end

local function inventoryLabels(ids)
    local out = {}
    for _, id in ipairs(ids or placeableIds()) do
        out[#out + 1] = string.format("%s [%d]", itemName(id), id)
    end
    if #out == 0 then out = { "(inventori kosong / belum terbaca)" } end
    return out
end

-- Dropdown cuma di-refresh kalau jenis item berubah (biar tidak lag)
local lastInvSig = nil
local invRefreshPending = false

local lastSeedSig = nil
local lastBlockSig = nil

-- Seed di inventori (untuk Farmer)
local function seedIds()
    local ids, seen = {}, {}
    for _, slot in ipairs(Refs.inventoryEntries()) do
        local it = ItemDB[slot.id]
        if it and it.kind == "seed" and not seen[slot.id] then
            seen[slot.id] = true
            ids[#ids + 1] = slot.id
        end
    end
    table.sort(ids)
    return ids
end

-- Setelah daftar di-refresh, pilih lagi item yang sedang dipakai (dari config / pilihan lama)
local function selectSaved(dd, labels, id)
    if not dd or not id then return true end
    local want = "[" .. tostring(id) .. "]"
    for _, label in ipairs(labels) do
        if string.sub(label, -#want) == want then
            local ok, err = UI.exec(function() dd:Select(label) end)
            if not ok then UI.DropErr = "Pilih item: " .. tostring(err) end
            return ok
        end
    end
    return true
end

-- Refresh 1 dropdown; error dicatat (tampil di tab Koneksi)
function UI.ddRefresh(dd, labels)
    if not dd then return true end
    local ok, err = UI.exec(function() dd:Refresh(labels) end)
    if ok then
        UI.DropOk = os.clock()
    else
        UI.DropErr = ("%s (id %s/%s)"):format(tostring(err), tostring(UI.ident()), tostring(Session.Ident))
        UI.DropErrAt = os.clock()
    end
    return ok, err
end

local function doInvRefresh(force)
    UI.DropErr = nil
    if not Refs.inventoryOK(Refs.Inv) then
        if Anim.quickRefs then pcall(Anim.quickRefs) end
        if not Refs.inventoryOK(Refs.Inv) then findRefs() end
        if UI.watchInventory then UI.watchInventory() end
    end
    if Vend.refreshItems and not Vend.Running then pcall(Vend.refreshItems, false) end
    local ids = placeableIds()
    local sig = table.concat(ids, ",")
    if force or sig ~= lastInvSig then
        local labels = inventoryLabels(ids)
        local ok = UI.ddRefresh(UI.InvDropdown, labels)
        if ok then ok = selectSaved(UI.InvDropdown, labels, State.SelectedId) end
        lastInvSig = ok and sig or nil
    end
    local sids = seedIds()
    local ssig = table.concat(sids, ",")
    if force or ssig ~= lastSeedSig then
        local labels = {}
        for _, id in ipairs(sids) do
            labels[#labels + 1] = string.format("%s [%d]", itemName(id), id)
        end
        if #labels == 0 then labels = { "(tidak ada seed di inventori)" } end
        local ok = UI.ddRefresh(UI.SeedDropdown, labels)
        if ok then ok = selectSaved(UI.SeedDropdown, labels, Farmer.SeedId) end
        if UI.PabrikSeedDropdown then
            local pok = UI.ddRefresh(UI.PabrikSeedDropdown, labels)
            if pok then pok = selectSaved(UI.PabrikSeedDropdown, labels, Pabrik.SeedId) end
            ok = ok and pok
        end
        lastSeedSig = ok and ssig or nil
    end
    -- block padat untuk pijakan
    local bids = {}
    for _, id in ipairs(ids) do
        local it = ItemDB[id]
        if it and it.solid and it.kind ~= "seed" then bids[#bids + 1] = id end
    end
    local bsig = table.concat(bids, ",")
    if force or bsig ~= lastBlockSig then
        local labels = {}
        for _, id in ipairs(bids) do
            labels[#labels + 1] = string.format("%s [%d]", itemName(id), id)
        end
        if #labels == 0 then labels = { "(tidak ada block padat di inventori)" } end
        local ok = true
        for _, entry in ipairs({
            { dd = UI.ClearBlockDropdown, id = Clear.ScaffoldId },
            { dd = UI.FarmerBlockDropdown, id = Farmer.ScaffoldId },
            { dd = UI.BuildBlockDropdown, id = Build.BlockId },
        }) do
            local refreshed = UI.ddRefresh(entry.dd, labels)
            if refreshed then refreshed = selectSaved(entry.dd, labels, entry.id) end
            ok = ok and refreshed
        end
        lastBlockSig = ok and bsig or nil
    end
    -- daftar Splice & Tas (dibuat di bagian bawah script)
    if UI.SpliceRefresh then
        local ok, err = pcall(UI.SpliceRefresh, force)
        if not ok then UI.DropErr = "Splice: " .. tostring(err) end
    end
    if UI.TrashRefresh then
        local ok, err = pcall(UI.TrashRefresh, force)
        if not ok then UI.DropErr = "Tas: " .. tostring(err) end
    end
end

function UI.checkInventory(force, silent)
    local ok, err = pcall(doInvRefresh, force)
    if not ok then UI.DropErr = tostring(err) end
    if UI.RefInfo then pcall(function() UI.RefInfo:SetDesc(refsText()) end) end
    local why = Refs.InvError or UI.DropErr
    if why then
        warn("[Zekio Supreme Premium] inventori: " .. tostring(why))
        if force and not silent then notify("Inventori", tostring(why), 6) end
    end
    return ok and why == nil, why
end

local function refreshInvDropdown(force)
    if force then UI.InvForce = true end
    if not force and invRefreshPending then return end
    invRefreshPending = true
    UI.later("inv", function()
        invRefreshPending = false
        local f = UI.InvForce == true
        UI.InvForce = false
        if alive() then UI.checkInventory(f) end
    end, force and 0 or 0.3)
end

local invConn
local function watchInventory()
    if invConn then pcall(function() invConn:Disconnect() end) end
    invConn = nil
    Refs.InvWatchErr = nil
    if not Refs.Inv then return end
    local ok, err = pcall(function()
        local signal = Refs.Inv.changed
        if typeof(signal) == "Instance" then signal = signal.Event end
        if not signal or type(signal.Connect) ~= "function" then
            error("Event changed tidak tersedia; gunakan Refresh daftar")
        end
        invConn = signal:Connect(function()
            if alive() then refreshInvDropdown(false) end
        end)
    end)
    if ok and invConn then
        table.insert(Connections, invConn)
    elseif not ok then
        Refs.InvWatchErr = tostring(err)
    end
end
UI.watchInventory = watchInventory

---------------------------------------------------------------------
-- WORLD: tile & posisi karakter
---------------------------------------------------------------------
local function tileAt(layer, x, y)
    local w = Refs.World
    if not w or x < 0 or y < 0 or x >= w.w or y >= w.h then return nil end
    local grid = w[layer]
    local row = grid and grid[y]
    return row and (row[x] or 0) or nil
end

local function getView()
    local gg = PlayerGui:FindFirstChild("GameGui")
    local cam = gg and gg:FindFirstChild("World") and gg.World:FindFirstChild("Camera")
    local tiles = cam and cam:FindFirstChild("Tiles")
    local pv = cam and cam:FindFirstChild("PlayerView")
    if not (tiles and pv) then return nil end
    local sample = tiles:FindFirstChildWhichIsA("ImageLabel")
    if not sample or sample.AbsoluteSize.X <= 0 then return nil end
    return { tiles = tiles, pv = pv, ts = sample.AbsoluteSize.X }
end

local function getPlayerTile()
    if Refs.State then
        local ok, s = pcall(Refs.State)
        if ok and type(s) == "table" and type(s.x) == "number" then
            if s.active == false then return nil end
            return math.floor(s.x) + State.CalibX, math.floor(s.y - 0.475) + State.CalibY
        end
    end
    local v = getView()
    if not v then return nil end
    local center = v.pv.AbsolutePosition + v.pv.AbsoluteSize / 2
    local rel = center - v.tiles.AbsolutePosition
    return math.floor(rel.X / v.ts) + State.CalibX, math.floor(rel.Y / v.ts) + State.CalibY
end

-- Tile, block & mode Auto Farm yang dipakai sekarang (Pabrik memakai miliknya sendiri)
local function farmOffsets()
    local o = State.Override
    return (o and o.offsets) or State.Offsets
end
local function farmBlock()
    local o = State.Override
    if o then return o.block end
    return State.SelectedId
end
local function farmMode()
    local o = State.Override
    return (o and o.mode) or State.Mode
end

local function sortedOffsets()
    local list = {}
    for key in pairs(farmOffsets()) do
        local dx, dy = string.match(key, "^(-?%d+),(-?%d+)$")
        table.insert(list, { dx = tonumber(dx), dy = tonumber(dy) })
    end
    table.sort(list, function(a, b)
        if a.dy ~= b.dy then return a.dy < b.dy end
        return a.dx < b.dx
    end)
    return list
end

---------------------------------------------------------------------
-- AKSI DASAR: place & pukul
---------------------------------------------------------------------
local function sendSetTile(layer, x, y, id)
    if id ~= 0 and State.Visual and Anim.place then Anim.place(x, y, id) end
    if Refs.SetTile then
        local ok, result, reason = pcall(Refs.SetTile, layer, x, y, id, false, false)
        if ok and result == false then return false, reason or "fungsi place game menolak aksi" end
        if ok then return true end
        warn("[Zekio Supreme Premium] setTile game gagal, pakai remote langsung: " .. tostring(result))
    end
    if NetOk and type(Net) == "table" and type(Net.tile) == "table" then
        -- sama seperti game: layer 1 = fg, 2 = bg
        local ok = pcall(Net.tile.send, {
            layer = (layer == "bg") and 2 or 1, x = x, y = y, id = id, flip = false,
        })
        if not ok then return false end
    elseif SetTileRemote then
        SetTileRemote:FireServer(layer, x, y, id, false)
    else
        return false
    end
    local grid = Refs.World and Refs.World[layer]
    if grid and grid[y] then grid[y][x] = id end
    return true
end

local function sendHitFx(x, y)
    if NetOk and type(Net) == "table" and Net.act then
        pcall(Net.act.send, { x = x + 0.5, y = y + 0.5 })
    end
end

local function hitsNeeded(id)
    if State.HitsOverride > 0 then return State.HitsOverride end
    local it = ItemDB[id]
    if not it then return 4 end
    local h = (it.kind == "seed") and 20 or it.hits
    return tonumber(h) or 4
end

function Refs.protectedItem(id)
    local it = ItemDB[id]
    if not it then return false end
    if it.lock or it.area or it.guildLock or it.vend or it.display then return true end
    local kind = string.lower(tostring(it.kind or "")):gsub("[_%-%s]+", "")
    if kind == "lock" or kind == "worldlock" or kind == "arealock" or kind == "guildlock" then return true end
    local name = string.lower(tostring(it.name or "")):gsub("<.->", ""):gsub("`.", ""):gsub("[_%-%s]+", " ")
    if name:find("%f[%a]lock%f[%A]") then return true end
    local compact = name:gsub("%s", "")
    return compact == "worldlock" or compact == "diamondlock" or compact == "bluegemlock"
        or compact == "guildlock" or compact == "smalllock" or compact == "biglock"
        or compact == "hugelock" or compact == "builderslock"
end

local function canBreak(id)
    if not id or id == 0 or Refs.protectedItem(id) then return false end
    local it = ItemDB[id]
    if not it then return false end
    local h = (it.kind == "seed") and 20 or it.hits
    return h == nil or h > 0
end

-- Game abaikan pukulan ke tile yang baru di-place (< 0.3 detik)
local PLACE_GUARD = 0.32

-- Place 1 tile kalau kosong. Hasil: "place" / "habis" / nil
local function tryPlace(x, y)
    local sel = farmBlock()
    if not sel then return nil end
    local fg = tileAt("fg", x, y)
    if fg == nil then return nil end
    local bg = tileAt("bg", x, y)
    local it = ItemDB[sel]
    local layer = (it and it.background) and "bg" or "fg"
    local cur = (layer == "bg") and bg or fg
    if not (cur == 0 and (layer == "bg" or fg == 0)) then return nil end
    if invCount(sel) <= 0 then return "habis" end

    local sent, reason = sendSetTile(layer, x, y, sel)
    if not sent then
        State.LastAction = "Place gagal: " .. tostring(reason or "fungsi place / pengiriman tidak tersedia")
        return nil, "place-error"
    end
    if Refs.Inv then pcall(function() Refs.Inv:remove(sel, 1) end) end
    local key = x .. "," .. y
    HitCount[key] = nil
    PlacedAt[key] = os.clock()
    State.Placed += 1
    State.LastAction = "Place " .. itemName(sel) .. " (" .. x .. "," .. y .. ")"
    return "place"
end

-- Masih ada yang bisa dipecah di tile ini? (block depan / background)
local function breakableAt(x, y)
    local fg = tileAt("fg", x, y)
    if fg == nil then return false end
    if fg ~= 0 then return canBreak(fg) end
    local bg = tileAt("bg", x, y)
    return State.BreakBackground and bg ~= nil and bg ~= 0 and canBreak(bg)
end

-- Pukul 1 kali. Hasil: "hit" / "broke" / nil
-- includeBg = ikut pecah background
local function tryBreak(x, y, includeBg, nativeOnly, settle, live)
    if live and not live() then return nil, "cancelled" end
    if includeBg == nil then includeBg = State.BreakBackground end
    local world, grid = Refs.World, Refs.World and Refs.World.fg
    local key = x .. "," .. y
    local fg = tileAt("fg", x, y)
    if fg == nil then return nil end
    local bg = tileAt("bg", x, y)
    local layer, id
    if fg ~= 0 then
        layer, id = "fg", fg
    elseif includeBg and bg ~= 0 then
        layer, id = "bg", bg
    end
    if not layer or not canBreak(id) then return nil end
    local spawn = world and world.spawn
    if spawn and x == spawn.X and y == spawn.Y then return nil, "protected" end

    -- tunggu sebentar kalau tile baru di-place
    local t = PlacedAt[key]
    if t then
        local age = os.clock() - t
        if age < PLACE_GUARD then task.wait(PLACE_GUARD - age) end
        PlacedAt[key] = nil
    end

    if Refs.World ~= world or not world or world.fg ~= grid then return nil, "world-changed" end
    if live and not live() then return nil, "cancelled" end
    -- Clear harus memilih ulang kalau isi tile berubah saat menunggu pijakan.
    if nativeOnly and (tileAt("fg", x, y) ~= fg or tileAt(layer, x, y) ~= id) then
        return nil, "tile-changed"
    end

    if type(Refs.Punch) == "function" then
        local ok, result, reason = pcall(Refs.Punch, x, y, State.MutePunch or nil, nil)
        if not ok then
            State.LastAction = ("Error pukul (%d,%d): %s"):format(x, y, tostring(result))
            return nil, "punch-error"
        end
        if settle and tileAt(layer, x, y) == id then
            local untilAt = os.clock() + settle
            while alive() and Refs.World == world and world.fg == grid
                and (not live or live())
                and tileAt(layer, x, y) == id and os.clock() < untilAt do task.wait(0.02) end
        end
        if Refs.World ~= world or world.fg ~= grid then return nil, "world-changed" end
        if live and not live() then return nil, "cancelled" end
        if tileAt(layer, x, y) ~= id then
            if State.Visual then Anim.swing(x, y, "punch") end
            Drops.brokeAt[key] = os.clock()
            State.Broken += 1
            State.LastAction = "Break " .. itemName(id) .. " (" .. x .. "," .. y .. ")"
            return "broke"
        end
        if result == false then
            State.LastAction = ("Pukul ditolak (%d,%d): %s"):format(x, y,
                tostring(reason or "fungsi game mengembalikan false"))
            return nil, "punch-rejected"
        end
        if State.Visual then Anim.swing(x, y, "punch") end
        State.LastAction = "Pukul " .. itemName(id) .. " (" .. x .. "," .. y .. ")"
        return "hit"
    end

    if nativeOnly then
        State.LastAction = "Fungsi pukul game terputus"
        return nil, "native-missing"
    end

    -- Cadangan: hitung pukulan sendiri
    local hc = HitCount[key]
    if not hc or hc.id ~= id or hc.layer ~= layer then
        hc = { id = id, layer = layer, n = 0 }
        HitCount[key] = hc
    end
    hc.n += 1
    sendHitFx(x, y)
    if State.Visual then Anim.swing(x, y, "punch") end
    local need = hitsNeeded(id)
    if hc.n >= need then
        sendSetTile(layer, x, y, 0)
        HitCount[key] = nil
        Drops.brokeAt[key] = os.clock()
        State.Broken += 1
        State.LastAction = "Break " .. itemName(id) .. " (" .. x .. "," .. y .. ")"
        return "broke"
    end
    State.LastAction = "Pukul " .. itemName(id) .. " " .. hc.n .. "/" .. need
    return "hit"
end

---------------------------------------------------------------------
-- AUTO COLLECT
---------------------------------------------------------------------
-- Cara game: World.takeDrop(uid, jumlah) -> server balas jumlahnya -> masuk inventori.
-- Game cuma ambil drop yang disentuh badan; di sini drop diambil langsung.
local TakeDropRemote = WorldRemotes:FindFirstChild("TakeDrop") -- game lama saja

-- Fungsi tangan game dipanggil dari fungsi gambar yang terhubung ke RenderStepped:
-- cukup periksa upvalue fungsi-fungsi itu (jauh lebih ringan dari scan getgc).
function Anim.findFast()
    if not getconnections or Anim.fn then return Anim.fn ~= nil end
    for _, name in ipairs({ "RenderStepped", "Heartbeat", "PreRender", "Stepped" }) do
        local okS, sig = pcall(function() return RunService[name] end)
        if okS and sig then
            local ok, conns = pcall(getconnections, sig)
            if ok and type(conns) == "table" then
                for _, c in ipairs(conns) do
                    local okf, fn = pcall(function() return c.Function end)
                    if okf and type(fn) == "function" then
                        for _, u in pairs(getUpvalues(fn)) do
                            if type(u) == "function" and Anim.isArmFn(u) then
                                Refs.Arm = u
                                return Anim.bind(u)
                            end
                        end
                    end
                end
            end
        end
    end
    return false
end

-- Cari data world & isi tas dari WorldMenu dan callback gambar/input game.
-- Telusuri juga tabel di dalam upvalue; maks 800 objek, tanpa getgc.
function Anim.quickRefs()
    if Refs.inventoryOK(Refs.Inv) and Refs.World then return true end
    local roots = {
        { value = MenuModOk and MenuModule or nil, label = "WorldMenu" },
        { value = Refs.Menu, label = "menu" },
        { value = Refs.World, label = "world" },
    }
    if type(getconnections) == "function" then
        for _, service in ipairs({
            { object = RunService, names = { "RenderStepped", "Heartbeat", "PreRender", "Stepped" } },
            { object = UserInputService, names = { "InputBegan", "InputEnded" } },
        }) do
            for _, name in ipairs(service.names) do
                local okS, sig = pcall(function() return service.object[name] end)
                if okS and sig then
                    local ok, conns = pcall(getconnections, sig)
                    if ok and type(conns) == "table" then
                        for _, c in ipairs(conns) do
                            local okf, fn = pcall(function() return c.Function end)
                            if okf and type(fn) == "function" then
                                roots[#roots + 1] = { value = fn, label = name }
                            end
                            if #roots >= 100 then break end
                        end
                    end
                end
            end
        end
    end
    local inv, source, info = Refs.findInventory(roots, 800)
    Refs.Inv, Refs.InvSource, Refs.InvScanInfo = inv, source, info
    return Refs.inventoryOK(Refs.Inv)
end

function getUpvalues(fn)
    local all = (debug and debug.getupvalues) or getupvalues
    if type(all) == "function" then
        local ok, ups = pcall(all, fn)
        if ok and type(ups) == "table" then return ups end
    end
    local out = {}
    local gu = (debug and debug.getupvalue) or getupvalue
    if type(gu) == "function" then
        for i = 1, 60 do
            local result = table.pack(pcall(gu, fn, i))
            if not result[1] or result.n < 2 then break end
            -- Executor: value. Lua-compatible API: name, value (termasuk value nil).
            if result.n >= 3 and type(result[2]) == "string" then out[i] = result[3]
            else out[i] = result[2] end
        end
    end
    return out
end

function Drops.record(d)
    if type(d) ~= "table" then return false end
    local uidType = type(d.uid)
    if uidType ~= "number" and uidType ~= "string" then return false end
    if (uidType == "number" and (d.uid ~= d.uid or math.abs(d.uid) == math.huge))
        or (uidType == "string" and d.uid == "") then return false end
    for _, key in ipairs({ "id", "x", "y", "n" }) do
        local value = d[key]
        if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then return false end
    end
    return d.n >= 0 and d.id >= 0 and d.id % 1 == 0
end

-- World-scoped drop state. A new world/grid must not reuse old UIDs or requests.
function Drops.bindWorld()
    local w = Refs.World
    local grid = w and w.fg
    if Drops.World and (Drops.World ~= w or Drops.Grid ~= grid) then
        Drops.list, Drops.update, Drops.seen, Drops.TouchBalances, Drops.Pool = nil, nil, nil, nil, nil
        Drops.Source, Drops.nextTick = nil, nil
        Drops.brokeAt = {}
        table.clear(DropFailUntil)
    end
    Drops.World, Drops.Grid = w, grid
    return w
end

function Drops.pool()
    local w = Drops.bindWorld()
    if not Drops.Pool then Drops.Pool = { world = w, busy = 0, room = {} } end
    return Drops.Pool
end

function Drops.room(id)
    if id == 112 then return math.huge end
    local inv = Refs.Inv
    if inv and type(inv.room) == "function" then
        local ok, n = pcall(inv.room, inv, id)
        if ok and type(n) == "number" and n == n then return math.max(0, n) end
    end
    return nil
end

function Drops.balance(id)
    if id == 112 then
        if type(Stats.gemsNow) == "function" then
            local ok, n = pcall(Stats.gemsNow)
            if ok and type(n) == "number" then return n end
        end
        return nil
    end
    if not Refs.Inv then return nil end
    local ok, n = pcall(invCount, id)
    if ok and type(n) == "number" then return n end
    return nil
end

-- A disappearing drop is not sufficient evidence of a native pickup. Count
-- only the portion also confirmed by a positive inventory/gem balance change.
function Drops.observeTouches(seen)
    local previous, balances = Drops.seen or {}, Drops.TouchBalances or {}
    local ids, lost, current = {}, {}, {}
    for _, d in ipairs(Drops.snapshot()) do current[d.uid] = d end
    for d, n in pairs(previous) do
        ids[d.id] = true
        local now = current[d.uid]
        local left = now and now.id == d.id and now.n or 0
        lost[d.id] = (lost[d.id] or 0) + math.max(0, n - left)
    end
    for d in pairs(seen) do ids[d.id] = true end
    for id in pairs(ids) do
        local n = Drops.balance(id)
        local before = balances[id]
        if n and before then
            local got = math.min(lost[id] or 0, math.max(0, n - before))
            if got > 0 then
                State.Collected = State.Collected + got
                Stats.Items[id] = (Stats.Items[id] or 0) + got
            end
        end
        balances[id] = n
    end
    Drops.TouchBalances, Drops.seen = balances, seen
end

function Drops.snapshot(list)
    local out = {}
    list = list or Drops.list
    if type(list) == "table" then
        for _, d in pairs(list) do
            if Drops.record(d) then out[#out + 1] = d end
        end
    end
    return out
end

function Drops.key(list, drop)
    for key, value in pairs(list or {}) do
        if rawequal(value, drop) then return key end
    end
end

function Drops.fail(message)
    Drops.Status, Drops.LastError = message, message
end

-- Tabel kosong hanya sah dari getter drop milik world. Upvalue kosong bisa saja
-- cache lain: dahulu tabel itu diterima lebih dulu dan collect tidak melihat drop.
local function isDropList(t, allowEmpty)
    if type(t) ~= "table" or t == Refs.World or t == Refs.Inv then return false end
    if next(t) == nil then return allowEmpty == true end
    for _, d in pairs(t) do
        if Drops.record(d) then return true end
    end
    return false
end

-- deep = true: boleh pakai getgc (berat, bisa bikin lag / crash di HP) -> hanya dari tombol "Hubungkan ke game"
local function findDropRefs(deep)
    Drops.bindWorld()
    -- 0) fungsi game World.dropList(): daftar drop yang sama untuk semua world (paling ringan)
    local w0 = Refs.World
    local dl = w0 and rawget(w0, "dropList")
    if type(dl) == "function" then
        local okl, l = pcall(dl)
        if okl and isDropList(l, true) then
            if Drops.list ~= l then Drops.update = nil end
            Drops.list = l
            Drops.Source = "World.dropList"
            -- v5.9.0: fungsi update (kurangi / hapus drop) juga wajib dicari. Dulu langsung
            -- return di sini, jadi Drops.update kosong -> drop hasil mode Remote tidak dihapus.
            if not Drops.update then Drops.findUpdate() end
            return true
        end
    end
    if Drops.list and not deep then return true end -- yang lama masih dipakai
    Drops.list, Drops.update, Drops.Source = nil, nil, nil
    -- 1) dari fungsi World.dropTaken (isinya: daftar drop + fungsi update)
    local wd = Refs.World and rawget(Refs.World, "dropTaken")
    if type(wd) == "function" then
        for _, u in pairs(getUpvalues(wd)) do
            if not Drops.list and isDropList(u) then
                Drops.list = u
                Drops.Source = "World.dropTaken"
            end
        end
    end
    -- 2) dari handler DropTaken game
    local ev = WorldRemotes:FindFirstChild("DropTaken")
    if not Drops.list and ev and getconnections then
        local ok, conns = pcall(getconnections, ev.OnClientEvent)
        if ok and type(conns) == "table" then
            for _, c in ipairs(conns) do
                local okf, fn = pcall(function() return c.Function end)
                if okf and type(fn) == "function" then
                    for _, u in pairs(getUpvalues(fn)) do
                        if not Drops.list and isDropList(u) then
                            Drops.list = u
                            Drops.Source = "DropTaken event"
                        end
                    end
                end
                if Drops.list then break end
            end
        end
    end
    -- 3) cadangan: cari lewat getgc (hanya kalau diminta: berat)
    if not Drops.list and deep and type(getgc) == "function" then
        local ok, objects = pcall(getgc, true)
        if ok and type(objects) == "table" then
            for _, v in pairs(objects) do
                if isDropList(v) then Drops.list, Drops.Source = v, "getgc"; break end
            end
        end
    end
    if Drops.list then Drops.findUpdate() end
    return Drops.list ~= nil
end

-- Cari fungsi game yang mengurangi / menghapus drop (dipakai World.dropTaken).
-- Ciri: upvalue World.dropTaken, dan fungsi itu sendiri memegang daftar drop yang sama.
function Drops.findUpdate()
    local w, list = Refs.World, Drops.list
    local wd = w and rawget(w, "dropTaken")
    if type(wd) ~= "function" or not list then return false end
    for _, u in pairs(getUpvalues(wd)) do
        if type(u) == "function" then
            for _, uu in pairs(getUpvalues(u)) do
                if rawequal(uu, list) then
                    Drops.update = u
                    return true
                end
            end
        end
    end
    return false
end

-- Terapkan hasil ambil drop ke tampilan, sama seperti game:
--   sisa > 0 -> angka drop dikurangi; sisa 0 -> keluar dari daftar + frame dihapus.
-- Tanpa ini, loop gambar game menampilkan drop lagi (flown di-reset saat badan tidak menyentuh).
function Drops.applyTaken(d, left)
    local list = Drops.list
    if not list or Drops.key(list, d) == nil then return end
    if not Drops.update then Drops.findUpdate() end
    if Drops.update then
        local ok = pcall(Drops.update, d, left)
        if ok then
            if left > 0 then
                d.flown = nil
                if typeof(d.frame) == "Instance" then pcall(function() d.frame.Visible = not d.culled end) end
            end
            return
        end
    end
    -- cadangan manual (fungsi game tidak ketemu)
    d.n = left
    if left > 0 then
        pcall(function()
            if d.setGem then d.setGem(left) elseif d.count then d.count:set(left > 1 and tostring(left) or "") end
        end)
        d.flown = nil
        if typeof(d.frame) == "Instance" then pcall(function() d.frame.Visible = not d.culled end) end
    else
        local i = Drops.key(list, d)
        if type(i) == "number" and i >= 1 and i % 1 == 0 and i <= #list then table.remove(list, i)
        elseif i ~= nil then list[i] = nil end
        if typeof(d.frame) == "Instance" then pcall(function() d.frame:Destroy() end) end
    end
end

local function takeDrop(d)
    if not Drops.record(d) then return false end
    if State.SkipCollectGems and d.id == 112 then return false end
    local pool = Drops.pool()
    local world, inventory, grid = Refs.World, Refs.Inv, Refs.World and Refs.World.fg
    if pool.busy >= 4 then return false end
    local worldTake = Refs.World and rawget(Refs.World, "takeDrop")
    if type(worldTake) ~= "function" and not TakeDropRemote then
        Drops.fail("Fungsi ambil drop game belum ditemukan; tekan Hubungkan ke game")
        return false
    end
    if not Drops.list or Drops.key(Drops.list, d) == nil then return false end
    if d.taking or d.pending or d.display or (d.n or 0) <= 0 then return false end
    -- drop yang kamu buang sendiri belum boleh dipungut lagi (aturan game), kecuali gems
    if d.armed == false and d.id ~= 112 then return false end
    local now = os.clock()
    if DropFailUntil[d.uid] and now < DropFailUntil[d.uid] then return false end

    local amount = d.n
    if d.id ~= 112 and Refs.Inv then -- 112 = gems, tidak makan slot
        local okr, room = pcall(function() return Refs.Inv:room(d.id) end)
        if okr and type(room) == "number" then amount = math.min(amount, math.max(0, room - (pool.room[d.id] or 0))) end
    end
    if amount <= 0 then -- inventori penuh: coba lagi 1 detik lagi
        Drops.fail("Inventori penuh untuk " .. itemName(d.id))
        DropFailUntil[d.uid] = now + 1
        local last = Hook.LastFull[d.id]
        if not last or now - last > 120 then
            Hook.LastFull[d.id] = now
            Hook.send("full", "Inventori penuh: " .. itemName(d.id) .. " tidak bisa diambil lagi")
        end
        return false
    end

    pool.busy = pool.busy + 1
    if d.id ~= 112 then pool.room[d.id] = (pool.room[d.id] or 0) + amount end
    d.taking = true -- cegah diambil dobel
    -- langsung hilang dari layar selama menunggu jawaban server.
    -- Tidak pakai d.flown: loop gambar game me-reset flown + memunculkan drop lagi
    -- tiap frame kalau badan tidak menyentuhnya (mode Remote = ambil dari jauh).
    if typeof(d.frame) == "Instance" then pcall(function() d.frame.Visible = false end) end
    local ok, taken
    if type(worldTake) == "function" then
        ok, taken = pcall(worldTake, d.uid, amount) -- cara game baru
    else
        ok, taken = pcall(TakeDropRemote.InvokeServer, TakeDropRemote, d.uid, amount)
    end
    d.taking = false
    pool.busy = math.max(0, pool.busy - 1)
    if d.id ~= 112 then pool.room[d.id] = math.max(0, (pool.room[d.id] or 0) - amount) end
    if Refs.World ~= world or Refs.Inv ~= inventory or not world or world.fg ~= grid then return false end

    if not (ok and type(taken) == "number" and taken > 0 and taken <= amount) then
        State.CollectFail = State.CollectFail + 1
        Drops.fail(ok and "Pengambilan drop ditolak / belum dikonfirmasi server"
            or ("Gagal ambil drop: " .. string.sub(tostring(taken), 1, 180)))
        d.refused = os.clock() -- tanda ditolak, sama seperti game
        d.failN = (d.failN or 0) + 1
        DropFailUntil[d.uid] = os.clock() + math.min(8, d.failN) -- 1, 2, 3.. detik (yang terus ditolak makin jarang)
        d.flown = nil
        if typeof(d.frame) == "Instance" then pcall(function() d.frame.Visible = not d.culled end) end
        return false
    end
    DropFailUntil[d.uid] = nil

    if d.id == 112 then
        if Refs.Gems then pcall(Refs.Gems.addGems, taken) end
    elseif Refs.Inv then
        pcall(function() Refs.Inv:add(d.id, taken) end)
    end
    Drops.applyTaken(d, math.max(0, (d.n or 0) - taken)) -- kurangi / hapus drop seperti game
    State.Collected = State.Collected + taken
    Stats.Items[d.id] = (Stats.Items[d.id] or 0) + taken
    State.LastAction = "Collect " .. itemName(d.id) .. " x" .. taken
    Drops.Status = "Terambil " .. itemName(d.id) .. " x" .. taken
    Drops.LastError = nil
    return true
end

local function inTile(t, x, y)
    return x >= t.x - 0.15 and x < t.x + 1.15 and y >= t.y - 0.15 and y < t.y + 1.15
end

-- ---------- Collector cepat ----------
-- Cek daftar drop TIAP FRAME. Drop di area langsung diambil, semuanya sekaligus
-- (paralel), jadi tidak antri menunggu balasan server satu per satu.
--   Auto Farm  : drop di tile yang dipilih di Grid
--   Clear / Farmer : drop di sekitar karakter
local OffsetParse = {}
local nextDropScan = 0

local function canTry(d, now)
    if not Drops.record(d) or d.taking or d.pending or d.display or d.n <= 0 then return false end
    if State.SkipCollectGems and d.id == 112 then return false end
    if d.armed == false and d.id ~= 112 then return false end
    local fail = DropFailUntil[d.uid]
    return not (fail and now < fail)
end

-- Drop TIDAK diambil lewat remote oleh script: drop terambil oleh game sendiri saat badan
-- menyentuhnya (fisika game, seperti main manual). Di sini cuma cari daftar drop & hitung
-- drop yang terambil di dekat badan (untuk status).
-- Mode Remote (cara lama): drop di tile grid / di sekitar karakter diambil lewat fungsi ambil-drop game
function Drops.remoteTick(list, s)
    local world = Refs.World
    local offs = farmOffsets()
    local farmArea = (State.AutoCollect or State.Override ~= nil) and next(offs) ~= nil
    local nearArea = State.CollectAround or (Clear.Running and Clear.Collect) or (Farmer.Running and Farmer.Collect)
        or Pabrik.Running or Build.Running or Splice.Roaming
    if not farmArea and not nearArea then
        Drops.Status = "Pilih tile Grid atau aktifkan Collect di sekitar karakter"
        return 0
    end
    local cx, cy = s.x, s.y - 0.475
    local ptx, pty = getPlayerTile()
    local now = os.clock()
    local R = (State.CollectRadius or 3) + 0.2
    local z = Pabrik.Zone -- tempat drop pabrik tidak ikut diambil lagi
    if z and z.world ~= (Refs.World and rawget(Refs.World, "name")) then z = nil end
    local queued = 0
    -- Snapshot mencegah drop terlewati saat request cepat menghapus elemen list.
    for _, d in ipairs(Drops.snapshot(list)) do
        if Refs.World ~= world or not alive() or Drops.pool().busy >= 4 then break end
        if canTry(d, now) and not (z and math.abs(d.x - z.x) <= 2.5 and math.abs(d.y - z.y) <= 2.5) then
            local hit = nearArea and math.abs(d.x - cx) <= R and math.abs(d.y - cy) <= R
            if not hit and farmArea and ptx then
                for key in pairs(offs) do
                    local o = OffsetParse[key]
                    if not o then
                        local dx, dy = string.match(key, "^(-?%d+),(-?%d+)$")
                        o = { tonumber(dx), tonumber(dy) }
                        OffsetParse[key] = o
                    end
                    if o[1] and math.abs(math.floor(d.x) - (ptx + o[1])) <= 1
                        and math.abs(math.floor(d.y) - (pty + o[2])) <= 1 then
                        hit = true
                        break
                    end
                end
            end
            if hit and math.abs(d.x - cx) <= R and math.abs(d.y - cy) <= R then queued = queued + 1; task.spawn(takeDrop, d) end
        end
    end
    if queued == 0 then Drops.Status = "Menunggu drop dalam area collect" end
    return queued
end

local function collectTick()
    Drops.bindWorld()
    if State.DropPause or Pabrik.Traveling then
        Drops.seen, Drops.TouchBalances = nil, nil
        Drops.Status = "Collect dijeda saat mengantar drop"
        return
    end
    local busy = State.AutoCollect or State.CollectAround or State.Override ~= nil or (Clear.Running and Clear.Collect)
        or (Farmer.Running and Farmer.Collect) or Pabrik.Running or Build.Running or Splice.Roaming or Vend.Running
    if not busy then Drops.Status = "Mati"; return end
    local tnow = os.clock()
    if tnow < (Drops.nextTick or 0) then return end -- 5-10x per detik cukup (hemat FPS)
    Drops.nextTick = tnow + ((State.CollectMode == "Remote") and 0.1 or 0.2)
    local list = Drops.list
    if not list then
        Drops.Status = "Daftar drop belum ditemukan; coba Hubungkan ke game saat ada drop"
        local now = os.clock()
        if now >= nextDropScan then -- cari daftar drop paling sering tiap 5 detik
            nextDropScan = now + 5
            findDropRefs()
        end
        return
    end
    local ok, s = false, nil
    if Refs.State then ok, s = pcall(Refs.State) end
    if not (ok and type(s) == "table" and type(s.x) == "number" and type(s.y) == "number") then
        Drops.Status = "Posisi karakter belum terbaca"
        return
    end
    if State.CollectMode == "Remote" then
        Drops.seen, Drops.TouchBalances = nil, nil
        Drops.remoteTick(list, s) -- jumlah terambil dihitung oleh takeDrop
        return
    end
    Drops.Status = AutoInput.Menu and "Sentuhan: drop diambil saat badan menyentuhnya"
        or "Kontrol gerak game belum terhubung; tekan Hubungkan ke game"
    if State.CollectAround then Drops.Status = Drops.Status .. "; untuk radius gunakan mode Remote" end
    local cx, cy = s.x, s.y - 0.475
    local seen = {}
    for _, d in ipairs(Drops.snapshot(list)) do
        if type(d) == "table" and type(d.x) == "number" and math.abs(d.x - cx) <= 1.5 and math.abs(d.y - cy) <= 1.5 then
            seen[d] = d.n or 0
        end
    end
    Drops.observeTouches(seen)
end

table.insert(Connections, RunService.Heartbeat:Connect(function()
    if alive() then
        local ok, err = pcall(collectTick)
        if not ok then Drops.fail("Error collect: " .. string.sub(tostring(err), 1, 180)) end
    end
end))

-- Tunggu sebentar sampai drop di tile ini terambil (supaya tidak tertimpa block baru)
local function waitTileDrops(t, maxSec)
    local world = Refs.World
    if not Drops.list then return false end
    local deadline = os.clock() + maxSec
    repeat
        if not alive() or Refs.World ~= world then return false end
        local busy = false
        for _, d in ipairs(Drops.snapshot()) do
            if d.n > 0 and not d.display and not (State.SkipCollectGems and d.id == 112)
                and inTile(t, d.x, d.y) then busy = true; break end
        end
        if not busy then return true end
        task.wait()
    until os.clock() >= deadline
    return false
end

-- Tunggu sampai drop yang menempel badan selesai dipungut game (sentuhan, bukan remote)
local function waitNearDrops(maxSec)
    local list = Drops.list
    if not list then return end
    task.wait(0.15) -- drop baru muncul sedikit terlambat
    local t0 = os.clock()
    while os.clock() - t0 < maxSec and alive() do
        local ok, s = false, nil
        if Refs.State then ok, s = pcall(Refs.State) end
        if not (ok and type(s) == "table" and type(s.x) == "number") then return end
        local cx, cy = s.x, s.y - 0.475
        local busy = false
        for _, d in ipairs(Drops.snapshot(list)) do
            -- sama dengan aturan game: < 0.6 tile mendatar & setinggi badan (kaki s.y, kepala s.y - 0.95)
            if type(d) == "table" and type(d.x) == "number" and (d.n or 0) > 0 and d.armed ~= false
                and not (State.SkipCollectGems and d.id == 112)
                and math.abs(d.x - s.x) < 0.6 and d.y + 0.3 > s.y - 0.95 and d.y - 0.3 < s.y then
                local room = true
                if d.id ~= 112 and Refs.Inv then -- inventori penuh: tidak akan terpungut
                    local okr, r = pcall(function() return Refs.Inv:room(d.id) end)
                    if okr and type(r) == "number" and r <= 0 then room = false end
                end
                if room then
                    busy = true
                    break
                end
            end
        end
        if not busy then return end
        task.wait()
    end
end

---------------------------------------------------------------------
-- STATUS
---------------------------------------------------------------------
local function offsetsText()
    local list = {}
    for _, o in ipairs(sortedOffsets()) do
        table.insert(list, "(" .. o.dx .. "," .. o.dy .. ")")
    end
    return #list > 0 and table.concat(list, " ") or "-"
end

local lastStatusText = nil

local function updateStatus()
    if not UI.Status then return end
    local px, py = getPlayerTile()
    local sel = State.SelectedId
    local txt = "Status   : " .. (State.Running and "JALAN" or "BERHENTI")
        .. "\nBlock    : " .. (sel and (itemName(sel) .. " x" .. invCount(sel)) or "-")
        .. "\nKarakter : " .. (px and ("(" .. px .. "," .. py .. ")") or "tidak di world")
        .. "\nTile     : " .. offsetsText()
        .. "\nPlace/Break/Collect : " .. State.Placed .. " / " .. State.Broken .. " / " .. State.Collected
        .. (State.CollectFail > 0 and (" (ditolak " .. State.CollectFail .. ")") or "")
        .. "\nCollect r3 [" .. tostring(State.CollectMode) .. "]: " .. tostring(Drops.Status or "menunggu koneksi")
        .. "\nDaftar drop: " .. tostring(#Drops.snapshot()) .. " | sumber: " .. tostring(Drops.Source or "belum ditemukan")
        .. (Drops.LastError and ("\nAlasan collect: " .. Drops.LastError) or "")
        .. (State.Dropped > 0 and ("\nDrop seed: di-drop " .. State.Dropped) or "")
        .. "\nAksi     : " .. State.LastAction
        .. (State.FarmError and State.FarmError ~= State.LastAction
            and ("\nAlasan berhenti: " .. State.FarmError) or "")
        .. (State.WorkReason and ("\nCollect sebelum break: " .. State.WorkReason) or "")
        .. (State.DropError and ("\nDrop seed: " .. State.DropError) or "")
    if txt == lastStatusText then return end
    lastStatusText = txt
    task.defer(function()
        pcall(function() UI.Status:SetDesc(txt) end)
    end)
end

---------------------------------------------------------------------
-- MODE LITE (matikan particle + suara)
---------------------------------------------------------------------
local DummyLabel = setmetatable({}, { __index = function() return 0 end, __newindex = function() end })
local DummyParticle = setmetatable({ l = DummyLabel, k = {} }, { __index = function() return 0 end, __newindex = function() end })
local NullSound
NullSound = setmetatable({}, {
    __index = function() return NullSound end,
    __newindex = function() end,
    __call = function() return NullSound end,
})
local LiteSaved = {}

local function liteOverride(tbl, key, repl)
    if type(tbl) == "table" and type(rawget(tbl, key)) == "function" then
        table.insert(LiteSaved, { tbl, key, rawget(tbl, key) })
        tbl[key] = repl
    end
end

local function setLite(on)
    State.LiteMode = on
    if on then
        if #LiteSaved == 0 then
            if ParticlesOk then liteOverride(ParticlesModule, "spawn", function() return DummyParticle end) end
            if SfxOk then
                liteOverride(SfxModule, "play", function() return NullSound end)
                liteOverride(SfxModule, "playAt", function() return NullSound end)
            end
        end
        for _, p in ipairs(Refs.Particles) do
            pcall(function()
                for _, e in ipairs(p.live) do
                    if typeof(e.l) == "Instance" then e.l.Visible = false end
                end
            end)
        end
    else
        for _, s in ipairs(LiteSaved) do
            pcall(function() s[1][s[2]] = s[3] end)
        end
        table.clear(LiteSaved)
    end
end

---------------------------------------------------------------------
-- MISC: walkspeed, infinite jump, fly + tembus block
---------------------------------------------------------------------
-- Infinite jump: game dibuat mengira ada Antigravity Generator, jadi bisa lompat di udara
local OrigJammerOn = nil
local function infJumpWrapper(id, ...)
    -- dimatikan saat Clear / Farmer jalan (lompat harus normal)
    if Misc.InfJump and id == 4992 and not AutoInput.active then
        return true
    end
    if OrigJammerOn then return OrigJammerOn(id, ...) end
    return false
end

local function hookJammer()
    local w = Refs.World
    if not w then return end
    local cur = rawget(w, "jammerOn")
    if cur == infJumpWrapper or type(cur) ~= "function" then return end
    OrigJammerOn = cur
    w.jammerOn = infJumpWrapper
end

local function unhookJammer()
    local w = Refs.World
    if w and rawget(w, "jammerOn") == infJumpWrapper and OrigJammerOn then
        w.jammerOn = OrigJammerOn
    end
end

local function setInfJump(on)
    Misc.InfJump = on
    if on then hookJammer() else unhookJammer() end
end

local function setGhost(on)
    Misc.Ghost = on
    if not on then
        Misc.UpHeld, Misc.DownHeld = false, false
        if Refs.World then Refs.World.ghost = false end
    end
    if UI.FlyPad then UI.FlyPad.Enabled = on end
end

local function setSpeed(pct)
    Misc.Speed = math.clamp(math.floor(tonumber(pct) or 100), 50, 500)
    if Misc.Speed == 100 and Refs.World then Refs.World.speedScale = 1 end
end

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
        if Misc.Ghost then
            if key == "down" and Misc.DownHeld then return true end
            if key == "jump" and Misc.UpHeld then return true end
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
        if value == G or value == _G or value == State or value == UI or value == AutoInput
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
                if n % 300 == 0 then task.wait() end
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
        if cursor % 120 == 0 then task.wait() end
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
            AutoInput.active, Misc.UpHeld, Misc.DownHeld = false, false, false
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
AutoInput.bindMenu(true)

-- Pasang walkspeed & fly tiap frame (game bisa menimpanya)
table.insert(Connections, RunService.Heartbeat:Connect(function()
    local w = Refs.World
    if not w or not alive() then return end
    if Misc.Speed ~= 100 then w.speedScale = Misc.Speed / 100 end
    if Misc.Ghost and w.ghost ~= true then w.ghost = true end
end))

---------------------------------------------------------------------
-- FARM LOOP: place semua dulu, baru break satu per satu
---------------------------------------------------------------------
local stopFarm

local function waitMs(ms, runId)
    task.wait(math.max(ms or 0, 10) / 1000)
    return State.Running and alive() and (not runId or State.RunId == runId)
end

local function validate()
    if Session.DoorTravel and Session.DoorTravel.Busy then return "Tunggu Teleport ID Door selesai dulu" end
    local doPlace = farmMode() ~= "Break saja"
    if not Refs.World then return "Data world belum ketemu. Tekan 'Hubungkan ke game'" end
    if next(farmOffsets()) == nil then return "Pilih tile dulu di Grid Tile" end
    if not getPlayerTile() then return "Kamu belum masuk world" end
    if doPlace and not farmBlock() then return "Pilih block dari inventori" end
    if farmMode() ~= "Place saja" and type(Refs.Punch) ~= "function" then
        return "Fungsi pukul game belum ditemukan; tekan Hubungkan ke game. Pembaca fungsi: "
            .. tostring(Refs.ConstantsAPI or "konstanta belum terbaca")
    end
    return nil
end

-- Rayman's Fist sedang dipakai? (fungsi asli game)
local function raymanOn()
    local w = Refs.World
    local f = w and rawget(w, "raymanOn")
    if type(f) ~= "function" then return false end
    local ok, on = pcall(f)
    return ok and on == true
end

-- Cari 2-3 tile target yang segaris dari karakter (8 arah, jarak 1-3),
-- sama seperti pukulan Rayman di game.
local RAY_DIRS = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 }, { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }
local function raymanLine(px, py, active)
    local byKey = {}
    for _, a in ipairs(active) do byKey[a.x .. "," .. a.y] = a end
    local best, bestDir = nil, nil
    for _, d in ipairs(RAY_DIRS) do
        local line = {}
        for i = 1, 3 do
            local a = byKey[(px + d[1] * i) .. "," .. (py + d[2] * i)]
            if a then line[#line + 1] = a end
        end
        if #line >= 2 and #line > (best and #best or 0) then best, bestDir = line, d end
    end
    return best, bestDir
end

-- Kabarkan gerakan Rayman ke server (paket yang sama dengan game saat pukulan Rayman)
local function raymanAct(dir)
    local ok, s = pcall(Refs.State)
    if not ok or type(s) ~= "table" or not s.x then return end
    if NetOk and type(Net) == "table" and Net.act then
        pcall(Net.act.send, { kind = 4, x = s.x + dir[1], y = s.y - 0.475 + dir[2] })
    end
end

local function farmLoop(runId)
    local lastStatus, pendingBg = 0, {}
    local world = Refs.World
    local worldName, grid = world and rawget(world, "name"), world and world.fg
    local pausedForDrop = false
    local function live()
        return State.Running and alive() and State.RunId == runId and Refs.World == world
            and world.fg == grid and rawget(world, "name") == worldName and not State.DropPause
    end
    while State.Running and alive() and State.RunId == runId do
        if State.DropPause then pausedForDrop = true; task.wait(0.2); continue end
        if Refs.World ~= world or not world or world.fg ~= grid or rawget(world, "name") ~= worldName then
            local current = Refs.World
            if pausedForDrop and type(worldName) == "string" and worldName ~= ""
                and current and rawget(current, "name") == worldName then
                world, grid, pendingBg = current, current.fg, {}
                Drops.bindWorld()
            else stopFarm("World berubah; mulai Auto Farm lagi di world tujuan"); return end
        end
        pausedForDrop = false
        local doPlace, doBreak = farmMode() ~= "Break saja", farmMode() ~= "Place saja"
        local px, py = getPlayerTile()
        if not px then stopFarm("Karakter tidak ditemukan (keluar world?)"); return end
        local tiles = {}
        for _, o in ipairs(sortedOffsets()) do tiles[#tiles + 1] = { x = px + o.dx, y = py + o.dy } end

        if doBreak then
            local safe, reason = Drops.prepareWork(tiles, px, py, live, { skipFullDrops = true })
            State.WorkReason, State.WaitingDrops = reason, #safe == 0
            tiles = safe
            if not live() then continue end
            if #tiles == 0 then
                State.LastAction = reason or "Menunggu tile bersih sebelum break"
                updateStatus()
                task.wait(0.25)
                continue
            end
        else
            State.WorkReason, State.WaitingDrops = nil, false
        end

        local acted, outOfBlock = false, false
        if doPlace then
            for _, t in ipairs(tiles) do
                if not live() then break end
                local key = t.x .. "," .. t.y
                if pendingBg[key] and (tileAt("fg", t.x, t.y) ~= 0 or not canBreak(tileAt("bg", t.x, t.y))) then
                    pendingBg[key] = nil
                end
                -- Finish a background layer after collecting the foreground
                -- rewards, before placing the next foreground block on it.
                if not pendingBg[key] and (not doBreak or Drops.tileReady(t, true)) then
                    local r, why = tryPlace(t.x, t.y)
                    if not live() then break end
                    if why == "place-error" then stopFarm(State.LastAction); return end
                    if r == "habis" then outOfBlock = true; break end
                    if r == "place" then acted = true; if not waitMs(State.PlaceMs, runId) then break end end
                end
            end
        end

        if doBreak and live() then
            local K, nextI, active = math.clamp(math.floor(State.MultiTarget or 1), 1, 5), 1, {}
            while live() do
                while #active < K and nextI <= #tiles do
                    local t = tiles[nextI]
                    nextI = nextI + 1
                    if Drops.tileReady(t, true) then active[#active + 1] = { x = t.x, y = t.y, n = 0 } end
                end
                if #active == 0 then break end
                local hits, rayDir
                if K > 1 and raymanOn() then hits, rayDir = raymanLine(px, py, active) end
                if not rayDir then hits = { active[1] } end
                local ready = true
                for _, a in ipairs(hits) do if not Drops.tileReady(a, true) then ready = false; a.done = true end end
                if not ready then rayDir = nil end
                local t0, hit, broke = os.clock(), false, false
                if rayDir then raymanAct(rayDir) end
                for i, a in ipairs(hits) do
                    if not live() then break end
                    if i > 1 then task.wait(0.05) end
                    if not live() then break end
                    local clear, blocker = Drops.tileReady(a, true)
                    if not clear then
                        a.done = true
                        State.WorkReason, State.LastAction = Drops.blockReason(blocker), Drops.blockReason(blocker)
                    else
                        local r, why = tryBreak(a.x, a.y, nil, true, 0.18, live)
                        if not live() then break end
                        if why == "native-missing" or why == "punch-error" then
                            stopFarm(State.LastAction); return
                        end
                        if r or why == "punch-rejected" then
                            a.n = a.n + 1
                            hit = true
                            acted = acted or r ~= nil
                        end
                        if r == "broke" then
                            broke, a.done = true, true -- collect before another layer or place cycle
                            local key = a.x .. "," .. a.y
                            pendingBg[key] = State.BreakBackground and tileAt("fg", a.x, a.y) == 0
                                and canBreak(tileAt("bg", a.x, a.y)) or nil
                        elseif a.n >= 80 then
                            stopFarm(("Tile (%d,%d) belum berubah setelah %d percobaan. %s")
                                :format(a.x, a.y, a.n, State.LastAction))
                            return
                        elseif r == nil and why ~= "punch-rejected" then a.done = true end
                    end
                    a.used = true
                end
                local nextActive = {}
                for _, a in ipairs(active) do if not a.done and not a.used then nextActive[#nextActive + 1] = a end end
                for _, a in ipairs(hits) do
                    a.used = nil
                    if not a.done then nextActive[#nextActive + 1] = a end
                end
                active = nextActive
                if hit then
                    local gap = (State.FastBreakTest and 190 or (State.Override and State.Override.breakMs) or State.BreakMs) / 1000
                    if rayDir then gap = math.max(gap, 0.35) end
                    local rest = gap - (os.clock() - t0)
                    if rest > 0.005 then task.wait(rest) end
                end
                if broke and not State.FastBreakTest and State.AfterBreakMs > 0 then task.wait(State.AfterBreakMs / 1000) end
                if live() and os.clock() - lastStatus >= 1 then
                    lastStatus = os.clock()
                    updateStatus()
                end
            end
        end
        if not State.Running or not alive() or State.RunId ~= runId then break end
        if State.DropPause then continue end
        if not acted then
            local sel = farmBlock()
            if outOfBlock or (doPlace and sel and invCount(sel) <= 0) then
                stopFarm("Block " .. itemName(sel) .. " di inventori habis"); return
            end
            if not waitMs(State.FastBreakTest and 190 or (State.Override and State.Override.breakMs) or State.BreakMs, runId) then break end
        end
        State.Cycles = State.Cycles + 1
        if os.clock() - lastStatus > 1 then lastStatus = os.clock(); updateStatus() end
    end
    updateStatus()
end


local function setRunningVisual()
    if State.Override then return end -- dijalankan Pabrik: tombol Auto Farm tidak diubah
    if UI.FarmToggle then pcall(function() UI.FarmToggle:Set(State.Running) end) end
    if UI.GridStart and UI.GridMode == "farm" then
        UI.GridStart.Text = State.Running and "STOP" or "START"
        UI.GridStart.BackgroundColor3 = State.Running and Color3.fromRGB(200, 60, 60) or Color3.fromRGB(46, 160, 90)
    end
end

stopFarm = function(reason)
    State.Running = false
    State.RunId = (State.RunId or 0) + 1
    State.FarmError = reason
    setRunningVisual()
    if reason and not State.Quiet then
        notify("Auto Farm berhenti", reason, 4)
        Hook.send("stop", "Auto Farm berhenti: " .. reason)
    end
    updateStatus()
end

-- Auto Farm, Clear & Farmer tidak boleh jalan bersamaan
local stopClear, stopFarmer

local function startFarm()
    if State.Running then return end
    local err = validate()
    if err then
        stopFarm(err)
        return
    end
    if Splice.Running and Splice.stop then Splice.stop("Dihentikan karena Auto Farm dimulai") end
    if Pabrik.Running and Pabrik.stop then Pabrik.stop("Dihentikan karena Auto Farm dimulai") end
    if Build.Running and Build.stop then Build.stop("Dihentikan karena Auto Farm dimulai") end
    if Clear.Running and stopClear then stopClear("Dihentikan karena Auto Farm dimulai") end
    if Farmer.Running and stopFarmer then stopFarmer("Dihentikan karena Auto Farm dimulai") end
    table.clear(HitCount)
    table.clear(PlacedAt)
    State.DropPause, State.WaitingDrops, State.WorkReason = false, false, nil
    State.DropError, State.DropOffUntil = nil, 0
    State.FarmError = nil
    State.Running = true
    State.RunId = (State.RunId or 0) + 1
    setRunningVisual()
    updateStatus()
    local runId = State.RunId
    task.spawn(function()
        local ok, err = xpcall(function() farmLoop(runId) end, function(message)
            if debug and type(debug.traceback) == "function" then
                return debug.traceback(tostring(message), 2)
            end
            return tostring(message)
        end)
        if not ok and alive() and State.RunId == runId then
            warn("[Zekio Premium Farm] " .. tostring(err))
            stopFarm("Farm error: " .. tostring(err))
        end
    end)
end


-- Fungsi untuk UI dikumpulkan di sini (Luau batasi 200 variabel per file)
local Auto = {}
do (function() -- fungsi sendiri: variabel di dalam tidak ikut batas 200 local
---------------------------------------------------------------------
-- GERAK OTOMATIS (dipakai Clear World & Farmer)
---------------------------------------------------------------------
-- Cara kerja:
--   - Jalan dicari pakai A* sesuai fisika game (jalan, jatuh, lompat naik 1-3 tile).
--   - Karakter digerakkan dengan "menekan" tombol, sama seperti main biasa.
--   - Tidak pakai fly / noclip karena server me-rollback.
--   - Kalau tidak ada pijakan, taruh block dari inventori (jembatan / tangga).
local floor, abs = math.floor, math.abs

local Move = { Placed = 0 }  -- jumlah block pijakan yang dipasang
local BadEdge = {}           -- jalur yang barusan gagal (dihindari dulu)
local ClearFail, FarmerFail = {}, {}
local BreakTimes = {}        -- tile yang terus balik lagi setelah pecah
local Reach = nil            -- daftar tile yang bisa dijangkau (cache)

local function autoOn()
    return (Clear.Running or Farmer.Running or Splice.Roaming or Pabrik.Running or Build.Running or Move.Homing
        or Vend.Running or Move.WorkCollect) and alive()
end

local function setMoveStatus(text)
    if Clear.Running then
        Clear.Status = text
    elseif Farmer.Running then
        Farmer.Status = text
    elseif Splice.Roaming then
        Splice.Status = text
    elseif Build.Running then
        Build.Status = text
    elseif Pabrik.Running then
        Pabrik.Status = text
    elseif Vend.Running then
        Vend.Status = text
    end
end

local function skipTile(tbl, idx, sec)
    tbl[idx] = os.clock() + (sec or 30)
end

local function skipped(tbl, idx, now)
    local t = tbl[idx]
    if not t then return false end
    if (now or os.clock()) >= t then
        tbl[idx] = nil
        return false
    end
    return true
end

local function skippedCount(tbl)
    local n, now = 0, os.clock()
    for _, t in pairs(tbl) do
        if t > now then n += 1 end
    end
    return n
end

local function hudRange(name, def)
    local f = Refs.Hud and Refs.Hud[name]
    if type(f) == "function" then
        local ok, r = pcall(f)
        if ok and type(r) == "number" and r > 0 then return r end
    end
    return def
end

local function punchReach() return hudRange("punchRange", 2.5) end
local function buildReach() return hudRange("buildRange", 2.5) end

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

-- Target kelihatan dari badan? (tidak terhalang lantai / atap padat di antaranya)
-- Panen lewat block bisa, tapi drop-nya jatuh di balik block dan tidak terambil.
function Move.los(nx, ny, tx, ty)
    if ty - ny >= 2 then
        for y = ny + 1, ty - 1 do
            if solidAt(tx, y) then return false end
        end
    elseif ny - ty >= 2 then
        for y = ty + 1, ny - 1 do
            if solidAt(tx, y) then return false end
        end
    end
    return true
end

-- Tile masuk jangkauan? (bentuk kotak di sekitar badan)
local function stateReaches(s, tx, ty, R)
    return abs(tx + 0.5 - s.x) <= R and abs(ty + 0.5 - (s.y - 0.475)) <= R
end

-- Boleh pecah di sini? (cek lock)
local function canWorkAt(x, y, nativeOnly)
    if nativeOnly then return type(Refs.Punch) == "function" end
    local w = Refs.World
    local ok, res = pcall(function()
        if w.areas and type(w.areas.mayBuild) == "function" and not w.areas.mayBuild(w.lock, x, y) then
            return false
        end
        if type(w.builderOk) == "function" and not w.builderOk(x, y, false) then
            return false
        end
        return true
    end)
    return (not ok) or res
end

-- ---------- Block pijakan ----------
local function scaffoldId()
    local id, use
    if Clear.Running then
        id, use = Clear.ScaffoldId, Clear.UseBlock
    elseif Farmer.Running then
        id, use = Farmer.ScaffoldId, Farmer.UseBlock
    end -- Bangun Lahan tidak pakai pijakan (jalan di atas baris yang sedang dibangun)
    if use and id and invCount(id) > 0 then return id end
    return nil
end

-- Boleh taruh block di sini? (kosong + izin bangun)
local function placeOk(x, y)
    local w = Refs.World
    if not w or x < 0 or y < 0 or x >= w.w or y >= w.h then return false end
    if fgIdAt(x, y) ~= 0 then return false end
    local ok, res = pcall(function()
        if w.areas and type(w.areas.canEdit) == "function" and not w.areas.canEdit(x, y) then return false end
        if type(w.builderOk) == "function" and not w.builderOk(x, y, true) then return false end
        return true
    end)
    return (not ok) or res
end

local function placeScaffold(x, y)
    local id = scaffoldId()
    if not id or not placeOk(x, y) then return false end
    local s = playerState()
    if not s or not stateReaches(s, x, y, buildReach() - 0.05) then return false end
    sendSetTile("fg", x, y, id) -- place lewat fungsi game
    if Refs.Inv then pcall(function() Refs.Inv:remove(id, 1) end) end
    Move.Placed += 1
    return true
end

local function worldVersion()
    -- berubah tiap ada block / pohon yang berubah, supaya cache jangkauan tidak basi
    return Clear.Broken + Farmer.Harvested + Farmer.Planted + Move.Placed + Splice.Planted
        + Pabrik.Harvested + Pabrik.Planted + Build.Placed + Build.Harvested + Build.Planted + Build.Dug
        + State.Placed + State.Broken
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

-- ---------- Antrian prioritas untuk A* ----------
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

-- ---------- A* ----------
-- Cari jalan termurah ke tempat yang bisa memukul salah satu target.
-- Langkah yang bisa dipakai:
--   walk   : geser 1 tile (+ taruh block kalau perlu)
--   fall   : jalan ke pinggir lalu jatuh
--   jump   : lompat naik 1-3 tile
--   gap    : lompati lubang 1-2 tile
--   stair  : tangga lahan: lompat naik 2 lewat lubang ke lorong setinggi 1 tile
--   pillar : lompat lalu taruh block di bawah kaki (naik 1)
local MAX_EXPAND = 8000
local BLOCK_COST = 2

local function reachOffsets(R)
    return floor(R), math.ceil(-R + 0.025), floor(R + 0.025)
end

local function astar(sx, sy, goals, gx, gy, R, useBlock)
    local w = Refs.World
    if not w then return nil, false, {} end
    local W, H = w.w, w.h
    local WH = W * H
    local dxm, dyLo, dyHi = reachOffsets(R)
    local oC, sC, bC = {}, {}, {}

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

    local function buildable(x, y)
        if not useBlock or x < 0 or x >= W or y < 0 or y >= H then return false end
        local i = y * W + x
        local v = bC[i]
        if v == nil then
            v = placeOk(x, y)
            bC[i] = v
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
        -- goals.maxY: tempat berdiri tidak boleh lebih bawah dari ini (Bangun Lahan)
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
                    if buildable(ax, y + 1) then
                        add(ax, y, "walk", 1 + BLOCK_COST, true)
                    end
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
            -- tangga lahan: naik 1-2 tile ke lorong setinggi 1 tile (atapnya pas di atas kepala,
            -- jadi lompat biasa tidak muat). Rapat ke dinding, lompat, geser masuk di puncak.
            for dy = 1, 2 do
                if open(x, y - 1) and (dy == 1 or open(x, y - 2)) and open(ax, y - dy) and sup(ax, y - dy)
                    and not (open(x, y - dy - 1) and open(ax, y - dy - 1)) then
                    add(ax, y - dy, "stair", 3 + 1.5 * dy, false)
                end
            end
        end
        -- naik 1 pakai block
        if useBlock and open(x, y - 1) and open(x, y - 2) and open(x, y - 3) and buildable(x, y) then
            add(x, y - 1, "pillar", 2 + BLOCK_COST, true)
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

-- Semua tile yang bisa dijangkau dari area ini
local function reachableTileSet(closed, W, R)
    local set = {}
    local dxm, dyLo, dyHi = reachOffsets(R)
    local n = 0
    for i in pairs(closed) do
        local x, y = i % W, i // W
        for dy = dyLo, dyHi do
            local ty = y + dy
            if ty >= 0 then
                local base = ty * W
                for dx = -dxm, dxm do
                    local tx = x + dx
                    if tx >= 0 and tx < W then set[base + tx] = true end
                end
            end
        end
        n += 1
        if n % 500 == 0 then task.wait() end
    end
    return set
end

-- Simpan daftar tile terjangkau, supaya tile di seberang jurang langsung dilewati
-- (tidak cari jalan berulang yang bikin karakter diam).
local function reachFilter(startI, R, useBlock)
    local c = Reach
    if c and c.world == Refs.World and c.start == startI and c.R == R and c.block == useBlock
        and c.ver == worldVersion() and os.clock() - c.at < 30 then
        return c.set
    end
    return nil
end

local function storeReach(startI, R, useBlock, closed)
    Reach = {
        world = Refs.World, start = startI, R = R, block = useBlock, ver = worldVersion(), at = os.clock(),
        set = reachableTileSet(closed, Refs.World.w, R),
    }
end

-- ---------- Gerakkan karakter ----------
local function releaseInput()
    AutoInput.left, AutoInput.right, AutoInput.jump, AutoInput.down = false, false, false, false
end

local function frame()
    task.wait()
    return autoOn()
end

local function waitAuto(ms)
    task.wait(math.max(ms or 0, 30) / 1000)
    return autoOn()
end

-- ===== ANIMASI AKSI (hanya tampilan di layar sendiri, tidak mengirim apa pun ke server) =====
-- Tangan karakter mengarah ke tile (sama seperti saat pemain memukul / memasang sendiri).
function Anim.swing(x, y, kind)
    if not (Anim.fn and Anim.idx and Anim.set) then return end
    local s = playerState()
    local facing = (s and x + 0.5 < s.x) and -1 or 1
    pcall(Anim.set, Anim.fn, Anim.idx, { t = os.clock(), x = x + 0.5, y = y + 0.5, facing = facing, kind = kind })
end

-- Efek asap kecil saat block dipasang (pakai efek "place" game)
function Anim.puff(x, y)
    local list = Refs.Particles
    if not list or #list == 0 then return end
    local pick = Anim.Particles
    if not pick then
        local worldGui = PlayerGui:FindFirstChild("GameGui")
        worldGui = worldGui and worldGui:FindFirstChild("World")
        for _, p in ipairs(list) do
            local ok, inWorld = pcall(function()
                return worldGui ~= nil and typeof(p.parent) == "Instance" and p.parent:IsDescendantOf(worldGui)
            end)
            if ok and inWorld then
                pick = p
                break
            end
        end
        pick = pick or list[1]
        Anim.Particles = pick
    end
    pcall(function() pick:place(x + 0.5, y + 0.5) end)
end

function Anim.place(x, y, id)
    local it = ItemDB[id]
    local seed = it and it.kind == "seed"
    Anim.swing(x, y, "build")
    if not seed then Anim.puff(x, y) end
end

-- Jalan ke targetX, lepas tombol saat sudah cukup dekat untuk berhenti
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
local function execWalk(tx, ty, cancel)
    local cx = tx + 0.5
    local s0 = playerState()
    if not s0 then return false end
    local limit = 1.5 + abs(cx - s0.x) * 0.35
    local t0 = os.clock()
    while frame() do
        if cancel and cancel() then releaseInput(); return false, "cancelled" end
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

-- Naik 1 tile: lompat, taruh block di bawah kaki, lalu mendarat di atasnya.
-- Block ditaruh agak telat supaya posisi di server sudah ikut naik.
local function execPillar(e)
    if not execWalk(e.fx, e.fy) then return false end
    if fgIdAt(e.fx, e.fy) ~= 0 then return false end
    releaseInput()
    if not frame() then return false end
    AutoInput.jump = true
    local t0 = os.clock()
    local placed, airborne = false, false
    while frame() do
        local s = playerState()
        if not s or s.dead then return false end
        if not s.grounded then airborne = true end
        steerX(s, e.fx + 0.5, 0.12)
        if AutoInput.jump and (s.y < e.fy - 0.9 or (airborne and (s.vy or 0) >= 0)) then
            AutoInput.jump = false
        end
        if not placed and airborne and s.y < e.fy - 0.25 and ((s.vy or 0) > -6 or s.y < e.fy - 0.8) then
            placed = placeScaffold(e.fx, e.fy)
            if not placed then return false end
        end
        if s.grounded and airborne then
            local nx, ny = floor(s.x), floor(s.y - 0.475)
            return placed and nx == e.x and ny == e.y
        end
        if not airborne and os.clock() - t0 > 0.35 then return false end
        if os.clock() - t0 > 1.8 then return false end
    end
    return false
end

local function followPath(path, cancel, smooth)
    local i = 1
    while i <= #path do
        if not autoOn() then return false end
        if cancel and cancel() then releaseInput(); return false, "cancelled" end
        local e = path[i]
        local last, ok = i, false
        if e.kind == "walk" then
            -- langkah searah digabung jadi satu gerakan
            local dir = e.x - e.fx
            while (not cancel or smooth) and path[last + 1] and path[last + 1].kind == "walk"
                and (path[last + 1].x - path[last + 1].fx) == dir
                and path[last + 1].y == e.y and path[last + 1].fy == e.y
                and path[last + 1].fx == path[last].x
                and (not smooth or (not path[last].build and not path[last + 1].build)) do
                last += 1
            end
            local anyBuild = false
            for j = i, last do
                if path[j].build then
                    anyBuild = true
                    break
                end
            end
            if anyBuild then
                -- perlu block: taruh block di depan, lalu melangkah
                ok = true
                for j = i, last do
                    local st = path[j]
                    if st.build and not realSupport(st.x, st.y) then
                        setMoveStatus(("Taruh block pijakan (%d,%d)"):format(st.x, st.y + 1))
                        if not placeScaffold(st.x, st.y + 1) or not waitAuto(120) then
                            ok = false
                            break
                        end
                    end
                    if not execWalk(st.x, st.y) then
                        ok = false
                        break
                    end
                end
            else
                setMoveStatus(("Jalan ke (%d,%d)"):format(path[last].x, path[last].y))
                ok = execWalk(path[last].x, path[last].y, smooth and cancel or nil)
            end
        elseif e.kind == "pillar" then
            setMoveStatus(("Naik pakai block ke (%d,%d)"):format(e.x, e.y))
            ok = execPillar(e)
        elseif e.kind == "fall" then
            setMoveStatus(("Turun ke (%d,%d)"):format(e.x, e.y))
            ok = execFall(e)
        elseif e.kind == "jump" then
            setMoveStatus(("Lompat ke (%d,%d)"):format(e.x, e.y))
            ok = execJump(e)
        elseif e.kind == "gap" then
            setMoveStatus(("Lompati lubang ke (%d,%d)"):format(e.x, e.y))
            ok = execGap(e)
        elseif e.kind == "stair" then
            setMoveStatus(("Naik tangga ke (%d,%d)"):format(e.x, e.y))
            ok = Move.execStair(e)
        end
        releaseInput()
        if cancel and cancel() then return false, "cancelled" end
        if not ok then
            -- hindari jalur ini sementara (tangga cuma sebentar, supaya tidak memutar jauh ke tangga lain)
            BadEdge[e.key] = os.clock() + ((e.kind == "stair") and 5 or 20)
            return false
        end
        i = last + 1
    end
    return true
end

-- Cari jalan ke grup target, lalu jalan ke sana
local function travelGroup(sx, sy, group, R, useBlock, skipTbl, failTbl)
    local w = Refs.World
    local goals = {}
    goals.maxY = group.maxY
    goals.los = group.los
    for _, t in ipairs(group) do goals[t.idx] = true end
    local first = group[1]
    setMoveStatus(("Cari jalan A* ke (%d,%d)"):format(first.x, first.y))
    local path, exhausted, closed = astar(sx, sy, goals, first.x, first.y, R, useBlock)
    if group.cancel and group.cancel() then releaseInput(); return false, "cancelled" end
    if path then
        if #path == 0 then
            local cur = playerState()
            if group.smooth and cur and abs(cur.x - (sx + 0.5)) > 0.08 then
                local ok, why = execWalk(sx, sy, group.cancel)
                releaseInput()
                if why == "cancelled" then return false, why end
                if ok then return true end
            end
            for _, t in ipairs(group) do skipTile(skipTbl, t.idx, group.smooth and 2 or 20) end
        else
            local ok, why = followPath(path, group.cancel, group.smooth)
            if why == "cancelled" then return false, why end
            if not ok then
                failTbl[first.idx] = (failTbl[first.idx] or 0) + 1
                if failTbl[first.idx] >= 3 then
                    for _, t in ipairs(group) do skipTile(skipTbl, t.idx, 40) end
                end
            end
        end
        releaseInput()
        return true
    end
    -- tidak ada jalan ke grup ini
    for _, t in ipairs(group) do skipTile(skipTbl, t.idx, exhausted and 60 or 30) end
    if exhausted and w then storeReach(sy * w.w + sx, R, useBlock, closed) end
    releaseInput()
    return false
end

-- ---------- Datangi drop yang belum terambil ----------
-- Hasil panen kadang jatuh di luar jangkauan collect. Drop dicari dari daftar drop game
-- (sama seperti Growscan), lalu karakter jalan mendekat (A*, tanpa pijakan) sampai drop
-- itu benar-benar terambil. Drop yang tidak ada jalannya dilewati sebentar.
-- Ambil drop di tile kerja dengan sentuhan badan (Auto Farm, Pabrik, bibit Bangun Lahan), tanpa remote.
-- Aturan game: drop terpungut kalau jaraknya < 0.6 tile dari tengah badan (mendatar) dan setinggi badan.
--   - tile sebaris (kiri / kanan, sampai 3 tile): disusuri sampai tile terjauh tiap sisi
--   - tile baris atas (kiri, tengah, kanan): berdiri di bawahnya lalu lompat kecil (tap); selama di udara
--     geser ke tile atas berikutnya yang masih ada drop-nya (bisa kena 2 sekaligus)
-- lalu balik lagi ke posisi kerja (hx, hy). Hasil: true = sudah balik ke posisi kerja.
function Drops.touchAll(tiles, hx, hy, live)
    local world = Refs.World
    live = live or function() return alive() end
    local function valid() return alive() and live() and Refs.World == world end
    local list = Drops.list
    if not list or not OrigIsDown then return false end
    local function dropsAt(t)
        for _, d in ipairs(Drops.snapshot(list)) do
            if canTry(d, os.clock()) and Drops.room(d.id) ~= 0
                and not d.taking and inTile(t, d.x, d.y) then
                return true
            end
        end
        return false
    end
    local has = {}
    for _, t in ipairs(tiles) do
        if not solidAt(t.x, t.y) and dropsAt(t) then has[#has + 1] = t end
    end
    if #has == 0 then return false end
    local s0 = playerState()
    if not s0 or s0.dead or not s0.grounded then return false end
    local function ground(c) return openAt(c, hy) and realSupport(c, hy) end
    local function walkable(a, b)
        local st = (b >= a) and 1 or -1
        for c = a, b, st do
            if not ground(c) then return false end
        end
        return true
    end
    local was = AutoInput.active
    AutoInput.active = true
    local function moveTo(cx, maxT)
        local t0 = os.clock()
        while valid() and os.clock() - t0 < (maxT or 1.2) do
            task.wait()
            local c = playerState()
            if not c or c.dead then break end
            steerX(c, cx, 0.1)
            if c.grounded and abs(c.x - cx) <= 0.15 and abs(c.vx or 0) < 1.5 then
                AutoInput.left, AutoInput.right = false, false
                return true
            end
        end
        AutoInput.left, AutoInput.right = false, false
        return false
    end
    -- lompat kecil (tap = naik +-1.4 tile, tidak sampai naik ke atas baris block), di udara geser ke toX
    local function hop(toX)
        AutoInput.left, AutoInput.right = false, false
        local c0 = playerState()
        if not c0 then return end
        local y0 = c0.y
        AutoInput.jump = true
        local t0, air = os.clock(), false
        while valid() and os.clock() - t0 < 1.4 do
            task.wait()
            local c = playerState()
            if not c or c.dead then break end
            if not c.grounded then
                air = true
                AutoInput.jump = false -- tap: lepas begitu lepas dari tanah
            end
            if toX and air and c.y <= y0 - 0.25 then steerX(c, toX, 0.1) else AutoInput.left, AutoInput.right = false, false end
            if air and c.grounded then break end
            if not air and os.clock() - t0 > 0.35 then break end
        end
        AutoInput.jump, AutoInput.left, AutoInput.right = false, false, false
    end
    -- baris badan: susuri sampai tile terjauh tiap sisi
    local lo, hi = hx, hx
    for _, t in ipairs(has) do
        if t.y == hy and abs(t.x - hx) <= 4 then
            if t.x < lo then lo = t.x end
            if t.x > hi then hi = t.x end
        end
    end
    if lo < hx and walkable(hx - 1, lo) then moveTo(lo + 0.5) end
    if hi > hx and walkable(hx + 1, hi) then moveTo(hi + 0.5) end
    -- baris atas: lompat di bawah tile yang masih ada drop-nya (maks 4 lompatan)
    for _ = 1, 4 do
        local cs = playerState()
        if not cs or not valid() then break end
        local cur = floor(cs.x)
        local cols = {}
        for _, t in ipairs(has) do
            if t.y == hy - 1 and abs(t.x - hx) <= 3 and ground(t.x) and walkable(cur, t.x)
                and not solidAt(t.x, t.y) and dropsAt(t) then
                cols[#cols + 1] = t.x
            end
        end
        if #cols == 0 then break end
        table.sort(cols, function(p, q) return abs(p - cur) < abs(q - cur) end)
        local a = cols[1]
        if a ~= cur then moveTo(a + 0.5) end
        hop(cols[2] and (cols[2] + 0.5) or nil) -- sambil geser ke tile berikutnya
    end
    -- balik ke posisi kerja
    local ok = valid() and moveTo(hx + 0.5, 2)
    AutoInput.left, AutoInput.right, AutoInput.jump = false, false, false
    AutoInput.active = was
    waitNearDrops(0.2)
    return ok, true -- nilai kedua menandakan collect benar-benar mencoba bergerak
end

-- Most uncollected drops remain blockers until collected. In normal Auto Farm,
-- drops that cannot fit in inventory are non-blocking, so break keeps running.
-- The Factory and other modes retain the original blocking behavior.
function Drops.tileReady(t, skipFullDrops)
    if not Drops.list then return false, "Daftar drop belum terbaca; jeda break" end
    for _, d in ipairs(Drops.snapshot()) do
        if d.n > 0 and not d.display and not (State.SkipCollectGems and d.id == 112)
            and inTile(t, d.x, d.y) and (not skipFullDrops or Drops.room(d.id) ~= 0) then
            return false, d
        end
    end
    return true
end

function Drops.blockReason(d)
    if type(d) ~= "table" then return tostring(d or "Menunggu tile bersih") end
    if Drops.room(d.id) == 0 then return "Tas penuh: " .. itemName(d.id) .. "; jeda break" end
    if d.armed == false and d.id ~= 112 then return "Item di tile belum boleh diambil; jeda break" end
    if d.pending or d.taking then return "Menunggu konfirmasi collect sebelum break" end
    return "Masih ada " .. itemName(d.id) .. " di tile; collect dahulu"
end

function Drops.workTiles(tiles)
    local out, seen, w = {}, {}, Refs.World
    if not w then return out end
    for _, t in ipairs(tiles) do
        for y = math.max(0, t.y - 1), math.min(w.h - 1, t.y + 1) do
            for x = math.max(0, t.x - 1), math.min(w.w - 1, t.x + 1) do
                local key = x .. "," .. y
                if not seen[key] then out[#out + 1], seen[key] = { x = x, y = y }, true end
            end
        end
    end
    return out
end

function Drops.visitForWork(d, hx, hy, live)
    local world, was, untilAt = Refs.World, AutoInput.active, os.clock() + 5
    Move.WorkCollect, AutoInput.active = true, true
    local ok, err = pcall(function()
        Move.visitDrop(d, function() return not live() or os.clock() >= untilAt end)
        if live() and Refs.World == world then
            if not Auto.walkTo(hx, hy, 8, function() return not live() end) then
                error("Gagal kembali ke posisi farm setelah collect", 0)
            end
        end
    end)
    Move.WorkCollect = false
    releaseInput()
    AutoInput.active = was and live() and Refs.World == world
    return ok, err
end

function Drops.prepareWork(tiles, hx, hy, live, options)
    options = options or {}
    local world, was = Drops.bindWorld(), AutoInput.active
    Drops.WorkBusy = true
    local ok, safe, reason = pcall(function()
        if not world or not live() then return {}, "Collect dibatalkan" end
        if not Drops.list then findDropRefs() end
        if not Drops.list then return {}, "Daftar drop belum terbaca; tekan Hubungkan ke game" end
        local collect = options.collect or State.AutoCollect or State.Override ~= nil
        local skipFullDrops = options.skipFullDrops == true
        local nearby = Drops.workTiles(tiles)
        Drops.waitSpawn(nearby)
        if not live() then return {}, "Collect dibatalkan" end
        if collect then
            if State.CollectMode == "Remote" then
                local untilAt = os.clock() + 1.5
                repeat
                    local queued = 0
                    local s = playerState()
                    if not s or s.dead or not live() then break end
                    for _, d in ipairs(Drops.snapshot()) do
                        if queued >= 4 or Drops.pool().busy >= 4 then break end
                        if canTry(d, os.clock()) and (not skipFullDrops or Drops.room(d.id) ~= 0) then
                            local hit = false
                            for _, t in ipairs(nearby) do if inTile(t, d.x, d.y) then hit = true; break end end
                            local R = (State.CollectRadius or 3) + 0.2
                            if hit and math.abs(d.x - s.x) <= R and math.abs(d.y - (s.y - 0.475)) <= R then
                                queued = queued + 1
                                task.spawn(takeDrop, d)
                            end
                        end
                    end
                    local clear = true
                    for _, t in ipairs(tiles) do if not Drops.tileReady(t, skipFullDrops) then clear = false; break end end
                    if clear and Drops.pool().busy == 0 then break end
                    task.wait(0.05)
                until not live() or os.clock() >= untilAt
            else
                local returned, attempted = Drops.touchAll(nearby, hx, hy, live)
                if not live() then return {}, "Collect dibatalkan" end
                local s = playerState()
                if attempted and (not returned or not s
                    or math.abs(s.x - (hx + 0.5)) > 0.3 or floor(s.y - 0.475) ~= hy) then
                    return {}, "Gagal kembali ke posisi farm setelah collect"
                end
                -- Native A* handles a remaining open drop below/above the sweep.
                -- Make only one bounded visit, then return to the same farm anchor.
                for _, t in ipairs(tiles) do
                    local clear, d = Drops.tileReady(t, skipFullDrops)
                    if not clear and type(d) == "table" and canTry(d, os.clock())
                        and Drops.room(d.id) ~= 0 and not solidAt(floor(d.x), floor(d.y)) then
                        local visited, why = Drops.visitForWork(d, hx, hy, live)
                        if not visited then return {}, tostring(why) end
                        break
                    end
                end
            end
        end
        if not live() or Refs.World ~= world then return {}, "Collect dibatalkan" end
        local seed = options.seed or (farmBlock() and Auto.seedOfBlock(farmBlock()))
        if seed and not skipFullDrops and Drops.room(seed) == 0 then
            return {}, "Tas seed penuh; menunggu auto drop / ruang inventori"
        end
        local out, why = {}, nil
        for _, t in ipairs(tiles) do
            local clear, blocker = Drops.tileReady(t, skipFullDrops)
            if clear then out[#out + 1] = t else why = why or Drops.blockReason(blocker) end
        end
        return out, why
    end)
    Drops.WorkBusy, Move.WorkCollect = false, false
    releaseInput()
    AutoInput.active = was and live() and Refs.World == world
    if not ok then return {}, "Collect gagal: " .. tostring(safe) end
    return safe, reason
end

function Drops.touch(t, hx, hy)
    return Drops.touchAll({ t }, hx, hy)
end

-- Tile yang barusan pecah: drop-nya datang dari server (sesuai ping). Tunggu sampai drop baru
-- muncul di tile itu (atau batas waktu), supaya tidak keburu ketimpa block baru / tidak tersentuh.
function Drops.waitSpawn(tiles)
    local ping = 0.1
    pcall(function() ping = LocalPlayer:GetNetworkPing() end)
    local limit = math.clamp(0.7 + 4 * ping, 0.9, 2)
    local newest = nil
    for _, t in ipairs(tiles) do
        local b = Drops.brokeAt[t.x .. "," .. t.y]
        if b and os.clock() - b < limit and (not newest or b > newest) then newest = b end
    end
    if not newest then return end
    local list = Drops.list
    while os.clock() - newest < limit and alive() do
        if list then
            for _, d in ipairs(Drops.snapshot(list)) do
                if type(d) == "table" and type(d.x) == "number" and (d.born or 0) >= newest then
                    for _, t in ipairs(tiles) do
                        if inTile(t, d.x, d.y) then
                            task.wait(0.05) -- drop lain dari pecahan yang sama
                            return
                        end
                    end
                end
            end
        end
        task.wait()
    end
end

-- Datangi 1 drop sampai terambil (berdiri di tile drop-nya; kalau tile itu tidak bisa dipijak,
-- misal lubang tangga: berdiri tepat di bawahnya lalu lompat sekali). Hasil: true = terambil.
function Move.visitDrop(d, cancel)
    if cancel and cancel() then return false, "cancelled" end
    local w = Refs.World
    local s = playerState()
    if not w or not s then return false, "nopath" end
    local W = w.w
    local tx, ty = floor(d.x), floor(d.y)
    if solidAt(tx, ty) then return false, "nopath" end -- terkubur di dalam block: tidak bisa disentuh
    local sx, sy = startNode(s)
    local goal = { [ty * W + tx] = true }
    local path = astar(sx, sy, goal, tx, ty, 0.5, false)
    if not path and ty + 1 < w.h then
        path = astar(sx, sy, { [(ty + 1) * W + tx] = true }, tx, ty + 1, 0.5, false)
    end
    if not path then path = astar(sx, sy, goal, tx, ty, 1.2, false) end
    if not path then return false, "nopath" end
    if cancel and cancel() then return false, "cancelled" end
    if #path > 0 then
        local ok, why = followPath(path, cancel)
        releaseInput()
        if not ok then return false, why == "cancelled" and "cancelled" or "nopath" end
    end
    local ping = 0.1
    pcall(function() ping = LocalPlayer:GetNetworkPing() end)
    waitNearDrops(math.clamp(0.6 + 3 * ping, 1, 2.5))
    if cancel and cancel() then return false, "cancelled" end
    local function left() return (d.n or 0) > 0 and Drops.key(Drops.list, d) ~= nil end
    local cur = playerState()
    if left() and cur and cur.grounded and abs(d.x - cur.x) <= 0.9 and d.y < cur.y - 0.9 and d.y > cur.y - 2.6 then
        -- drop di atas kepala: lompat sekali supaya kena badan
        AutoInput.active = true
        AutoInput.jump = true
        task.wait(0.25)
        AutoInput.jump = false
        local t0 = os.clock()
        repeat
            task.wait(0.05)
            local c = playerState()
        until not c or c.grounded or os.clock() - t0 > 1.5
        waitNearDrops(0.5)
    end
    if left() then return false, "left" end
    return true
end

-- Susuri 1 baris (tile badan ry) dari kolom xa ke xb tanpa berhenti di tiap drop:
-- drop di jalan terambil sambil lewat, sama seperti main manual.
function Move.walkRow(ry, xa, xb)
    local w = Refs.World
    if not w then return false end
    for _, tx in ipairs({ xa, xb }) do
        local s = playerState()
        if not s or s.dead then return false end
        local sx, sy = startNode(s)
        if not (sx == tx and sy == ry) then
            local goal = { [ry * w.w + tx] = true }
            local path = astar(sx, sy, goal, tx, ry, 0.5, false) or astar(sx, sy, goal, tx, ry, 1.2, false)
            if not path then
                releaseInput()
                return false
            end
            if #path > 0 and not followPath(path) then
                releaseInput()
                return false
            end
        end
    end
    releaseInput()
    return true
end

-- Ambil drop yang belum terambil, PER BARIS (seperti main manual):
--   pilih drop terdekat (baris sendiri didahulukan), lalu susuri baris itu dari ujung terdekat
--   ke ujung lainnya tanpa berhenti. Yang masih tertinggal (mis. di lubang tangga) baru didatangi
--   satu-satu, dan yang tetap tidak terambil tidak dicoba lagi sebentar.
-- filter(d) = true: drop ini boleh diambil (nil = semua). maxSec = batas waktu (20 dtk).
Move.FetchFail = {}
function Move.fetchDrops(live, maxDist, filter, maxSec)
    local list = Drops.list
    local w = Refs.World
    if not list or not w then return 0 end
    maxDist = maxDist or 8
    local got, t0 = 0, os.clock()
    local function want(d, now)
        if not (canTry(d, now) and d.id) then return false end
        if Move.FetchFail[d.uid] and now < Move.FetchFail[d.uid] then return false end
        if solidAt(floor(d.x), floor(d.y)) then -- terkubur di dalam block: tidak bisa disentuh
            Move.FetchFail[d.uid] = now + 300
            return false
        end
        local z = Pabrik.Zone
        if z and not Move.NoZone and z.world == rawget(w, "name") and abs(d.x - z.x) <= 2.5 and abs(d.y - z.y) <= 2.5 then
            return false
        end
        if filter and not filter(d) then return false end
        if d.id ~= 112 and Refs.Inv then -- inventori penuh: tidak usah diambil
            local okr, r = pcall(function() return Refs.Inv:room(d.id) end)
            if okr and type(r) == "number" and r <= 0 then return false end
        end
        return true
    end
    while live() and alive() and os.clock() - t0 < (maxSec or 20) do
        local s = playerState()
        if not s or s.dead then break end
        if not s.grounded then
            task.wait(0.05)
            continue
        end
        local cx, cy = s.x, s.y - 0.475
        local now = os.clock()
        local best, bd = nil, nil
        for _, d in ipairs(Drops.snapshot(list)) do
            if want(d, now) then
                local dx, dy = d.x - cx, d.y - cy
                if abs(dx) <= maxDist and abs(dy) <= maxDist and (abs(dx) >= 0.6 or abs(dy) >= 0.75) then
                    local dd = dx * dx + 9 * dy * dy -- baris sendiri didahulukan
                    if not bd or dd < bd then best, bd = d, dd end
                end
            end
        end
        if not best then break end
        local ry = floor(best.y)
        if best.x < 0 or ry < 0 or best.x >= w.w or ry >= w.h then
            Move.FetchFail[best.uid] = now + 30
        else
            -- semua drop di baris itu: susuri dari ujung terdekat ke ujung lainnya
            local inRow, lo, hi = {}, best.x, best.x
            for _, d in ipairs(Drops.snapshot(list)) do
                if floor(d.y) == ry and abs(d.x - cx) <= maxDist and want(d, now) then
                    inRow[#inRow + 1] = d
                    if d.x < lo then lo = d.x end
                    if d.x > hi then hi = d.x end
                end
            end
            local xa, xb = floor(lo), floor(hi)
            if abs(hi - cx) < abs(lo - cx) then xa, xb = xb, xa end
            setMoveStatus(("Ambil drop baris y %d (x %d-%d)"):format(ry, math.min(xa, xb), math.max(xa, xb)))
            local ok = Move.walkRow(ry, xa, xb)
            -- pungutan dikirim ke server: tunggu balasannya (ping) sebelum menilai drop tertinggal
            local ping = 0.1
            pcall(function() ping = LocalPlayer:GetNetworkPing() end)
            local tw = os.clock()
            repeat
                task.wait(0.05)
                local busy = false
                for _, d in ipairs(inRow) do
                    if d.taking then
                        busy = true
                        break
                    end
                end
            until not busy or os.clock() - tw > math.clamp(0.3 + 3 * ping, 0.5, 2.5)
            got += 1
            Move.FetchTry = Move.FetchTry or {}
            for _, d in ipairs(inRow) do
                if (d.n or 0) > 0 and Drops.key(list, d) ~= nil then
                    local okv, why = false, "nopath"
                    if ok then okv, why = Move.visitDrop(d) end
                    if not okv then
                        local tries = (Move.FetchTry[d.uid] or 0) + 1
                        Move.FetchTry[d.uid] = tries
                        if why == "left" and tries < 4 then
                            Move.FetchFail[d.uid] = os.clock() + 1.5 -- sudah didatangi (balasan server telat / sisa sebagian): coba lagi sebentar lagi
                        else
                            Move.FetchFail[d.uid] = os.clock() + 30 -- tidak ada jalan / tetap tidak terambil
                        end
                    else
                        Move.FetchTry[d.uid] = nil
                    end
                end
            end
        end
    end
    releaseInput()
    return got
end

local function autoBegin()
    AutoInput.active = true
    releaseInput()
    Reach = nil
    if Misc.Ghost then
        setGhost(false) -- fly dimatikan (kena rollback)
        if UI.GhostToggle then pcall(function() UI.GhostToggle:Set(false) end) end
    end
end

local function autoEnd()
    if Clear.Running or Farmer.Running or Splice.Roaming or Pabrik.Running or Build.Running or Move.Homing
        or Vend.Running or Move.WorkCollect then
        return
    end
    AutoInput.active = false
    releaseInput()
end

local function blockText(useBlock, id)
    if not useBlock then return "mati" end
    if not id then return "belum dipilih" end
    local n = invCount(id)
    return itemName(id) .. " x" .. n .. (n <= 0 and " (habis)" or "")
end

---------------------------------------------------------------------
-- CLEAR WORLD: bersihkan dari baris atas ke bawah, 2 baris sekali sapu
---------------------------------------------------------------------
-- Boleh dipecah? (lock, vending, display tidak disentuh)
local function clearCanBreak(id)
    if not id or id == 0 then return false end
    local it = ItemDB[id]
    if not it or Refs.protectedItem(id) then return false end
    local h = (it.kind == "seed") and 20 or it.hits
    if type(h) == "number" and h > 0 then return true end
    local w = Refs.World
    return (it.staffHits and w and w.areas and w.areas.staff) and true or false
end

-- Layer yang dipecah: fg dulu, lalu bg
local function clearLayerAt(x, y)
    local w = Refs.World
    local sp = w and w.spawn
    if sp ~= nil and (typeof(sp) == "Vector2" or type(sp) == "table") and x == sp.X and y == sp.Y then
        return nil
    end
    local fg = tileAt("fg", x, y)
    if fg == nil then return nil end
    if fg ~= 0 then
        if clearCanBreak(fg) then return "fg", fg end
        return nil -- fg tidak bisa dipecah, bg juga tidak
    end
    if Clear.IncludeBg then
        local bg = tileAt("bg", x, y)
        if bg and bg ~= 0 and clearCanBreak(bg) then return "bg", bg end
    end
    return nil
end

-- Cari baris paling atas yang masih ada block
local function scanTopRow()
    local w = Refs.World
    local W, H = w.w, w.h
    local now = os.clock()
    for y = 0, H - 1 do
        local frow, brow = w.fg[y], w.bg[y]
        for x = 0, W - 1 do
            local fid = frow and frow[x] or 0
            local bid = brow and brow[x] or 0
            if (fid ~= 0 or (Clear.IncludeBg and bid ~= 0)) and clearLayerAt(x, y)
                and not skipped(Clear.Skip, y * W + x, now) then
                return y
            end
        end
    end
    return nil
end

local function countRemaining()
    local w = Refs.World
    if not w then return -1 end
    local W, H = w.w, w.h
    local n, scanned = 0, 0
    for y = 0, H - 1 do
        local frow, brow = w.fg[y], w.bg[y]
        for x = 0, W - 1 do
            local fid = frow and frow[x] or 0
            local bid = brow and brow[x] or 0
            if (fid ~= 0 or (Clear.IncludeBg and bid ~= 0)) and clearLayerAt(x, y) then n += 1 end
        end
        scanned += W
        if scanned >= 8000 then
            scanned = 0
            task.wait()
        end
    end
    return n
end

-- Arah sapu. Zig-zag: arah dipilih sekali per baris (dari ujung terdekat),
-- lalu dipegang sampai baris selesai supaya tidak bolak-balik.
local function bandDir(topRow, s)
    if Clear.Sweep ~= "Zig-zag" then return 1 end
    if Clear.DirRow == topRow and Clear.Dir then return Clear.Dir end
    local w = Refs.World
    local now = os.clock()
    local minX, maxX
    for y = topRow, math.min(topRow + 1, w.h - 1) do
        for x = 0, w.w - 1 do
            if clearLayerAt(x, y) and not skipped(Clear.Skip, y * w.w + x, now) then
                if not minX or x < minX then minX = x end
                if not maxX or x > maxX then maxX = x end
            end
        end
    end
    local dir = 1
    if minX and maxX and abs(s.x - maxX) < abs(s.x - minX) then dir = -1 end
    Clear.DirRow, Clear.Dir = topRow, dir
    return dir
end

-- Semua target di baris ini, urut sesuai arah sapu.
-- Tile yang tidak terjangkau langsung dilewati.
local function bandTargets(top, bottom, dir, filter)
    local w = Refs.World
    local W = w.w
    local list = {}
    local now = os.clock()
    for y = top, math.min(bottom, w.h - 1) do
        for x = 0, W - 1 do
            local idx = y * W + x
            if clearLayerAt(x, y) and not skipped(Clear.Skip, idx, now) then
                if filter and not filter[idx] then
                    skipTile(Clear.Skip, idx, 60) -- di seberang jurang / tidak ada jalan
                else
                    -- Jangan saring lagi memakai asumsi API mayBuild/builderOk.
                    -- Target ini tetap lewat fungsi pukul asli, bukan setTile.
                    list[#list + 1] = { x = x, y = y, idx = idx }
                end
            end
        end
    end
    table.sort(list, function(a, b)
        if a.x ~= b.x then return a.x * dir < b.x * dir end
        return a.y < b.y
    end)
    return list
end

-- Tile yang bisa dipukul dari sini. Pijakan kaki dipecah paling akhir.
local function clearInReach(s, bottom, dir)
    local w = Refs.World
    local W = w.w
    local R = punchReach() - 0.08
    local cx, cy = s.x, s.y - 0.475
    local footRow = floor(s.y + 0.01)
    local colA, colB = floor(s.x - 0.3), floor(s.x + 0.3 - 0.0001)
    local now = os.clock()
    local list = {}
    for ty = math.max(0, floor(cy - R - 0.5)), math.min(floor(cy + R + 0.5), bottom, w.h - 1) do
        for tx = math.max(0, floor(cx - R - 0.5)), math.min(floor(cx + R + 0.5), W - 1) do
            if stateReaches(s, tx, ty, R) then
                local idx = ty * W + tx
                if not skipped(Clear.Skip, idx, now) and clearLayerAt(tx, ty) then
                    list[#list + 1] = {
                        x = tx, y = ty, idx = idx,
                        support = (ty == footRow and tx >= colA and tx <= colB),
                    }
                end
            end
        end
    end
    table.sort(list, function(a, b)
        if a.support ~= b.support then return not a.support end
        if a.x ~= b.x then return a.x * dir < b.x * dir end
        return a.y < b.y
    end)
    return list
end

-- Kalau pijakan dipecah, jatuh berapa tile? (nil = jatuh ke lava/duri)
local function fallAfterBreak(s, x, footRow)
    local colA, colB = floor(s.x - 0.3), floor(s.x + 0.3 - 0.0001)
    for c = colA, colB do
        if c ~= x and (solidAt(c, footRow) or platformAt(c, footRow)) then return 0 end -- masih menapak kolom lain
    end
    local w = Refs.World
    for y = footRow + 1, math.min(w.h - 1, footRow + 60) do
        if hazardAt(x, y) then return nil end
        if solidAt(x, y) or platformAt(x, y) then return y - footRow end
    end
    return 60
end

-- Pukul satu tile sampai bersih (fg lalu bg)
local function clearBreakTile(t)
    local x, y, idx = t.x, t.y, t.idx
    local layer, id = clearLayerAt(x, y)
    if not layer then return end
    local hits, maxHits = 0, hitsNeeded(id) * 3 + 6
    while Clear.Running and alive() do
        layer, id = clearLayerAt(x, y)
        if not layer then return end
        local r, reason = tryBreak(x, y, Clear.IncludeBg, true)
        if reason == "native-missing" then
            stopClear("Fungsi pukul game terputus. Tekan 'Hubungkan ke game', lalu mulai lagi")
            return
        end
        if r == nil then
            if reason == "tile-changed" then
                Clear.Status = ("Tile (%d,%d) berubah, periksa ulang"):format(x, y)
                return
            end
            Clear.Status = ("Lewati (%d,%d): %s"):format(x, y,
                reason == "punch-error" and State.LastAction or "tile belum bisa dipukul")
            skipTile(Clear.Skip, idx, 60)
            return
        end
        if r == "broke" then
            Clear.Broken += 1
            Clear.Status = "Pecah " .. itemName(id) .. " (" .. x .. "," .. y .. ")"
            BreakTimes[idx] = (BreakTimes[idx] or 0) + 1
            if BreakTimes[idx] > 6 then -- server terus mengembalikan tile ini
                skipTile(Clear.Skip, idx, 120)
                return
            end
            hits = 0
            local _, nid = clearLayerAt(x, y)
            if nid then maxHits = hitsNeeded(nid) * 3 + 6 end
        else
            hits += 1
            Clear.Status = "Pukul " .. itemName(id) .. " (" .. x .. "," .. y .. ")"
            if hits > maxHits then
                Clear.Status = ("Lewati (%d,%d): tile belum berubah setelah %d pukulan"):format(x, y, hits)
                skipTile(Clear.Skip, idx, 45)
                return
            end
        end
        if not waitAuto(State.FastBreakTest and 190 or State.BreakMs) then return end
        if r == "broke" then
            local s = playerState()
            if not s or not s.grounded then return end -- jatuh, cek ulang posisi
        end
    end
end

local function clearBreakList(list, s0)
    local footY = floor(s0.y - 0.475)
    local R = punchReach() - 0.08
    local done = 0
    for _, t in ipairs(list) do
        if not Clear.Running or not alive() then break end
        local s = playerState()
        if not s or s.dead or not stateReaches(s, t.x, t.y, R) then break end
        if not s.grounded or floor(s.y - 0.475) ~= footY then break end
        local skipIt = false
        if t.support then
            local d = fallAfterBreak(s, t.x, floor(s.y + 0.01))
            if d == nil then
                skipIt = true
                Clear.Status = ("Lewati (%d,%d): di bawahnya berbahaya"):format(t.x, t.y)
            elseif d > 3 then
                -- di bawahnya jurang: pecah nanti dari samping
                skipIt = true
                Clear.Status = ("Lewati pijakan (%d,%d): di bawahnya jurang"):format(t.x, t.y)
            end
        end
        if skipIt then
            skipTile(Clear.Skip, t.idx, 20)
        else
            clearBreakTile(t)
            done += 1
        end
    end
    return done
end

local lastClearText = nil
local function updateClearStatus()
    if not UI.ClearStatus then return end
    local txt = "Status   : " .. (Clear.Running and "JALAN" or "BERHENTI")
        .. "\nBaris    : " .. (Clear.TopRow >= 0 and (Clear.TopRow .. "-" .. (Clear.TopRow + 1)) or "-")
        .. "  | arah: " .. ((Clear.Dir == -1 and Clear.Sweep == "Zig-zag") and "kanan→kiri" or "kiri→kanan")
        .. "\nDipecah  : " .. Clear.Broken .. "  | collect: " .. State.Collected
        .. "\nSisa     : " .. (Clear.Remaining >= 0 and tostring(Clear.Remaining) or "-")
        .. "  | dilewati: " .. skippedCount(Clear.Skip)
        .. "\nPijakan  : " .. blockText(Clear.UseBlock, Clear.ScaffoldId) .. "  | dipasang: " .. Move.Placed
        .. "\nAksi     : " .. Clear.Status
    if txt == lastClearText then return end
    lastClearText = txt
    task.defer(function()
        pcall(function() UI.ClearStatus:SetDesc(txt) end)
    end)
end

local function clearLoop()
    local idle, lastUi, lastCount = 0, 0, -10
    while Clear.Running and alive() do
        task.wait()
        local now = os.clock()
        if now - lastCount > 3 then
            lastCount = now
            Clear.Remaining = countRemaining()
            if not Clear.Running or not alive() then break end
        end
        if now - lastUi > 0.5 then
            lastUi = now
            updateClearStatus()
        end
        local w = Refs.World
        local s = playerState()
        if not w or not s or s.dead then
            releaseInput()
            Clear.Status = "Menunggu karakter / world..."
            task.wait(0.5)
            continue
        end
        if not s.grounded then
            releaseInput() -- masih di udara, tunggu mendarat
            continue
        end
        releaseInput()

        local topRow = scanTopRow()
        if not topRow then
            local remaining = countRemaining()
            Clear.Remaining = remaining
            if remaining == 0 then
                stopClear("World sudah bersih!")
                return
            end
            idle += 1
            if idle >= 3 then
                stopClear(("Selesai. Sisa %d tile tidak bisa dijangkau / dipecah"):format(remaining))
                return
            end
            Clear.Status = ("Sisa %d tile dilewati, coba ulang (%d/3)..."):format(remaining, idle)
            updateClearStatus()
            table.clear(Clear.Skip)
            table.clear(ClearFail)
            table.clear(BadEdge)
            Reach = nil
            if not waitAuto(2000) then break end
            continue
        end

        Clear.TopRow = topRow
        local bottom = topRow + 1 -- 2 baris dibersihkan dulu sebelum turun
        local dir = bandDir(topRow, s)

        -- 1) Pecahkan yang terjangkau
        local list = clearInReach(s, bottom, dir)
        if #list > 0 then
            if clearBreakList(list, s) > 0 then idle = 0 end
            continue
        end

        -- 2) Ambil drop di sekitar dengan menyusurinya (sentuhan badan), lalu jalan ke bagian berikutnya
        if Clear.Collect then
            local band0 = topRow - 1
            if Move.fetchDrops(function() return Clear.Running end, 5, function(d)
                return d.y >= band0 and d.y < bottom + 2
            end, 8) > 0 then
                continue
            end
        end
        local R = punchReach() - 0.35
        local useBlock = scaffoldId() ~= nil
        local sx, sy = startNode(s)
        local band = bandTargets(topRow, bottom, dir, reachFilter(sy * w.w + sx, R, useBlock))
        if #band > 0 then
            -- tujuan: 5 kolom berikutnya sesuai arah sapu
            local group = {}
            for _, t in ipairs(band) do
                if (t.x - band[1].x) * dir <= 4 then group[#group + 1] = t end
            end
            travelGroup(sx, sy, group, R, useBlock, Clear.Skip, ClearFail)
        end
    end
    releaseInput()
end

local function setClearVisual()
    if UI.ClearToggle then pcall(function() UI.ClearToggle:Set(Clear.Running) end) end
end

stopClear = function(reason)
    Clear.Running = false
    autoEnd()
    setClearVisual()
    Clear.Status = reason or "Dihentikan"
    if reason then
        notify("Auto Clear", reason, 5)
        if not string.find(reason, "^Dihentikan") then Hook.send("stop", "Auto Clear berhenti: " .. reason) end
    end
    updateClearStatus()
end

local function checkAutoStart()
    if not Refs.World then return "Data world belum ketemu. Tekan 'Hubungkan ke game'" end
    if not Refs.Punch then return "Fungsi pukul game belum ketemu. Tekan 'Hubungkan ke game'" end
    if not OrigIsDown then AutoInput.bindMenu() end
    if not OrigIsDown then return AutoInput.Error or "Kontrol gerak game belum terhubung" end
    if not playerState() then return "Kamu belum masuk world" end
    return nil
end

local function startClear()
    if Clear.Running then return end
    local err = checkAutoStart()
    if err then
        notify("Auto Clear", err, 4)
        setClearVisual()
        return
    end
    if Clear.UseBlock and (not Clear.ScaffoldId or invCount(Clear.ScaffoldId) <= 0) then
        notify("Auto Clear", "Block pijakan belum dipilih / habis: jalan tanpa block pijakan", 5)
    end
    if Splice.Running and Splice.stop then Splice.stop("Dihentikan karena Auto Clear dimulai") end
    if Pabrik.Running and Pabrik.stop then Pabrik.stop("Dihentikan karena Auto Clear dimulai") end
    if Build.Running and Build.stop then Build.stop("Dihentikan karena Auto Clear dimulai") end
    if State.Running then stopFarm("Dihentikan karena Auto Clear dimulai") end
    if Farmer.Running then stopFarmer("Dihentikan karena Auto Clear dimulai") end
    table.clear(Clear.Skip)
    table.clear(ClearFail)
    table.clear(BadEdge)
    table.clear(BreakTimes)
    Clear.Broken = 0
    Clear.Remaining = -1
    Clear.TopRow = -1
    Clear.DirRow, Clear.Dir = nil, nil
    Clear.Status = "Mulai..."
    Clear.Running = true
    autoBegin()
    setClearVisual()
    updateClearStatus()
    task.spawn(function()
        local ok, e = pcall(clearLoop)
        if not ok then
            warn("[Zekio Supreme Premium] Auto Clear error: " .. tostring(e))
            if Clear.Running then stopClear("Error: " .. tostring(e)) end
        end
    end)
end

---------------------------------------------------------------------
-- FARMER: panen pohon yang siap + tanam seed
---------------------------------------------------------------------
-- Pohon siap kalau: waktu server >= waktu tanam + lama tumbuh (sama dengan game).
-- Seed ditanam di tile kosong yang di bawahnya ada block.
local function findTreeRefs()
    if Auto.TreeScanBusy then return Refs.Trees ~= nil end
    Refs.Trees, Refs.TreeMode, Refs.TreeP = nil, nil, nil
    -- 1) cara utama (game v1159+): ikuti fungsi World.tileChanged -> fungsi simpan pohon.
    --    Tetap jalan walau world belum punya pohon (tabel kosong).
    local okS, foundS = pcall(function() return Auto.findTreesStruct and Auto.findTreesStruct() end)
    if okS and foundS == true then return true end
    Refs.Trees, Refs.TreeMode, Refs.TreeP = nil, nil, nil
    -- 2) game lama: handler remote WorldRemotes.TreeChanged
    local ev = WorldRemotes:FindFirstChild("TreeChanged")
    if ev and ev:IsA("RemoteEvent") and getconnections then
        local ok, conns = pcall(getconnections, ev.OnClientEvent)
        if ok and type(conns) == "table" then
            for _, c in ipairs(conns) do
                local okf, fn = pcall(function() return c.Function end)
                if okf and type(fn) == "function" then
                    for _, u in pairs(getUpvalues(fn)) do
                        if type(u) == "table" and u ~= Refs.World and rawget(u, "fg") == nil then
                            local _, v = next(u)
                            if type(v) == "table" and type(rawget(v, "p")) == "number" then
                                Refs.Trees, Refs.TreeMode, Refs.TreeP = u, "idx", "p"
                                break
                            end
                        end
                    end
                end
                if Refs.Trees then return true end
            end
        end
    end
    -- 3) telusuri fungsi world dan handler yang tersedia.
    if Auto.findTreesDeep then pcall(Auto.findTreesDeep) end
    if Refs.Trees then return true end
    -- 4) cadangan: cocokkan tabel game dengan posisi pohon di world.
    if Auto.findTreesGC and not Auto.TreeScanBusy then
        local w, now = Refs.World, os.clock()
        if Auto.TreeScanWorld ~= w or now >= (Auto.NextTreeGCScan or 0) then
            Auto.TreeScanWorld, Auto.NextTreeGCScan = w, now + 60
            Auto.TreeScanBusy = true
            local ok, err = pcall(Auto.findTreesGC)
            Auto.TreeScanBusy = false
            if not ok then Refs.TreeScanError = tostring(err) end
        end
    end
    return Refs.Trees ~= nil
end

-- Tabel ini cocok jadi data pohon? Kosong = boleh (world tanpa pohon).
-- Isi = [y*W+x] -> { p = waktu tanam (waktu server), f = buah, s = sudah di-splice }
function Auto.treeTableOk(t)
    local w = Refs.World
    if type(t) ~= "table" or t == w or getmetatable(t) ~= nil or rawget(t, "fg") ~= nil then return false end
    local n = 0
    for k, v in pairs(t) do
        n += 1
        if n > 6 then break end
        if type(k) ~= "number" or type(v) ~= "table" or type(rawget(v, "p")) ~= "number" then return false end
        if w and type(w.w) == "number" and type(w.h) == "number" and (k < 0 or k >= w.w * w.h) then return false end
    end
    return true
end

-- Cari data pohon dari struktur kode game (tanpa getgc, tanpa remote):
--   World.tileChanged memegang (upvalue) tabel pohon + fungsi simpan pohon.
--   Fungsi simpan pohon memegang World + tabel pohon + tabel gambar pohon.
--   Tabel yang dipegang KEDUANYA = tabel pohon.
function Auto.findTreesStruct()
    local w = Refs.World
    if not w or not getUpvalues then return false end
    local roots = {}
    for _, name in ipairs({ "tileChanged", "treeChanged", "setTree" }) do
        local f = rawget(w, name)
        if type(f) == "function" then roots[#roots + 1] = f end
    end
    for _, root in ipairs(roots) do
        local ups = getUpvalues(root)
        local tset = {}
        for _, u in pairs(ups) do
            if type(u) == "table" and u ~= w then tset[u] = true end
        end
        for _, g in pairs(ups) do
            if type(g) == "function" then
                local gu = getUpvalues(g)
                local hasW, nT, shared = false, 0, {}
                for _, v in pairs(gu) do
                    if rawequal(v, w) then
                        hasW = true
                    elseif type(v) == "table" then
                        nT += 1
                        if tset[v] then shared[#shared + 1] = v end
                    end
                end
                -- fungsi simpan pohon: upvalue sedikit (World + 2 tabel), satu tabel sama dengan tileChanged
                if hasW and nT <= 3 and #shared == 1 and Auto.treeTableOk(shared[1]) then
                    Refs.Trees, Refs.TreeMode, Refs.TreeP = shared[1], "idx", "p"
                    return true
                end
            end
        end
        -- cadangan: tabel milik tileChanged yang isinya jelas data pohon
        for t in pairs(tset) do
            if next(t) ~= nil and Auto.treeTableOk(t) and Auto.treeShape(t) == "idx" then
                Refs.Trees, Refs.TreeMode, Refs.TreeP = t, "idx", "p"
                return true
            end
        end
    end
    return false
end

-- Data pohon di tile (x,y): { p = waktu tanam (waktu server), s = sudah di-splice }.
-- Bentuk tabel bisa beda tergantung versi game (lihat Auto.findTreesDeep).
function Auto.treeEntry(x, y)
    local t, w = Refs.Trees, Refs.World
    if not t or not w then return nil end
    local mode = Refs.TreeMode or "idx"
    local e
    if mode == "xy" then
        e = t[x .. "," .. y]
    elseif mode == "rows" then
        local r = t[y]
        e = type(r) == "table" and r[x] or nil
    else
        e = t[y * w.w + x]
    end
    if type(e) == "number" then return { p = e } end
    if type(e) ~= "table" then return nil end
    local pk = Refs.TreeP or "p"
    if pk ~= "p" then return { p = rawget(e, pk), s = rawget(e, "s") } end
    return e
end

-- Tabel ini data pohon? Hasil: mode ("idx" / "xy" / "rows"), nama field waktu tanam
function Auto.treeShape(t)
    local w = Refs.World
    if type(t) ~= "table" or not w or t == w or rawget(t, "fg") ~= nil then return nil end
    local W, H = w.w, w.h
    local okT, st = pcall(function() return workspace:GetServerTimeNow() end)
    if not okT then st = os.time() end
    local function timeKey(e)
        if type(e) == "number" then
            return (math.abs(e - st) < 86400 * 90) and "#" or nil
        end
        if type(e) ~= "table" then return nil end
        local pv = rawget(e, "p")
        if type(pv) == "number" and math.abs(pv - st) < 86400 * 90 then return "p" end
        for fk, fv in pairs(e) do
            if type(fv) == "number" and math.abs(fv - st) < 86400 * 90 then return fk end
        end
        return nil
    end
    local function seedAt(x, y)
        local row = w.fg[y]
        local id = row and row[x]
        local it = id and ItemDB[id]
        return it ~= nil and it.kind == "seed"
    end
    local checked, good, bad, mode, pk = 0, 0, 0, nil, nil
    for k, v in pairs(t) do
        checked += 1
        if checked > 10 then break end
        local x, y, e, m = nil, nil, nil, nil
        if type(k) == "number" and k % 1 == 0 and k >= 0 then
            if type(v) == "table" and k < H and timeKey(v) == nil then
                -- baris: t[y][x]
                local kx, ve = next(v)
                if type(kx) == "number" and kx >= 0 and kx < W then x, y, e, m = kx, k, ve, "rows" end
            elseif k < W * H then
                x, y, e, m = k % W, k // W, v, "idx"
            end
        elseif type(k) == "string" then
            local a, b = string.match(k, "^(%d+),(%d+)$")
            if a then x, y, e, m = tonumber(a), tonumber(b), v, "xy" end
        end
        if not x then return nil end
        if mode and mode ~= m then return nil end
        mode = m
        local tk = timeKey(e)
        if tk and seedAt(x, y) then
            good += 1
            pk = (tk == "#") and "p" or tk
        else
            bad += 1 -- data lama (pohon sudah dipanen) masih tersimpan: boleh sedikit
        end
    end
    if good == 0 or bad > good then return nil end
    return mode, pk
end

-- Cari tabel pohon pada objek game. Kandidat harus cocok dengan koordinat
-- pohon hidup dan waktu tanam yang masuk akal, bukan sekadar nama tabel.
function Auto.findTreesGC()
    local w = Refs.World
    if not w or type(getgc) ~= "function" then return false end
    local ok, objects = pcall(getgc, true)
    if not ok or type(objects) ~= "table" then
        Refs.TreeScanError = "Daftar objek game tidak dapat dibaca"
        return false
    end
    local now = workspace:GetServerTimeNow()
    local trees = {}
    for y = 0, w.h - 1 do
        local row = w.fg[y]
        if type(row) == "table" then
            for x = 0, w.w - 1 do
                local id = row[x]
                if id and ItemDB[id] and ItemDB[id].kind == "seed" then
                    trees[#trees + 1] = { x = x, y = y }
                    if #trees >= 16 then break end
                end
            end
        end
        if #trees >= 16 then break end
    end
    if #trees == 0 then
        Refs.TreeScanError = "Tidak ada pohon untuk memeriksa data"
        return false
    end
    local minMatch = math.min(2, #trees)
    local validKey = { p = true, plantedAt = true, plantTime = true, planted = true, startTime = true }
    local seen, examined, functionsChecked = {}, 0, 0
    local function consider(t)
        if type(t) ~= "table" or seen[t] or t == w or rawget(t, "fg") ~= nil then return false end
        seen[t] = true
        local shapeOk, mode, key = pcall(Auto.treeShape, t)
        if not shapeOk or not mode or not validKey[key or "p"] then return false end
        local matches = 0
        for _, tree in ipairs(trees) do
            local e
            if mode == "idx" then
                e = rawget(t, tree.y * w.w + tree.x)
            elseif mode == "xy" then
                e = rawget(t, tree.x .. "," .. tree.y)
            elseif mode == "rows" then
                local row = rawget(t, tree.y)
                e = type(row) == "table" and rawget(row, tree.x) or nil
            end
            local planted = type(e) == "table" and rawget(e, key or "p") or e
            if type(planted) == "number" and planted == planted
                and planted <= now + 60 and planted >= now - 90 * 86400 then
                matches += 1
                if matches >= minMatch then
                    if Refs.World ~= w or Refs.Trees then return false end
                    Refs.Trees, Refs.TreeMode, Refs.TreeP = t, mode, key or "p"
                    Refs.TreeScanError = nil
                    return true
                end
            end
        end
        return false
    end
    for _, obj in pairs(objects) do
        if Refs.World ~= w or Refs.Trees then return Refs.Trees ~= nil end
        if type(obj) == "table" and consider(obj) then return true end
        if type(obj) == "function" and functionsChecked < 1500 and isGameFn(obj) then
            functionsChecked += 1
            for _, upvalue in pairs(getUpvalues(obj)) do
                if type(upvalue) == "table" and consider(upvalue) then return true end
            end
        end
        examined += 1
        if examined % 400 == 0 then task.wait() end
        if examined >= 100000 then break end
    end
    Refs.TreeScanError = "Data waktu pohon belum ditemukan"
    return false
end

-- Cari data pohon lewat upvalue fungsi game (remote world, fungsi World, RunService, Net). Tanpa getgc.
function Auto.findTreesDeep()
    local w = Refs.World
    if not w or not getUpvalues then return false end
    local queue, seenF, seenT, nF = {}, {}, {}, 0
    local function addFn(fn)
        if type(fn) == "function" and not seenF[fn] then queue[#queue + 1] = fn end
    end
    local function tryTable(t)
        if seenT[t] then return false end
        seenT[t] = true
        local mode, pk = Auto.treeShape(t)
        if mode then
            Refs.Trees, Refs.TreeMode, Refs.TreeP = t, mode, pk
            return true
        end
        return false
    end
    -- 1) isi World langsung (tabel & fungsi)
    for _, v in pairs(w) do
        if type(v) == "table" then
            if tryTable(v) then return true end
        elseif type(v) == "function" then
            addFn(v)
        end
    end
    -- 2) handler remote world
    if getconnections then
        for _, ev in ipairs(WorldRemotes:GetChildren()) do
            if ev:IsA("RemoteEvent") then
                local ok, conns = pcall(getconnections, ev.OnClientEvent)
                if ok and type(conns) == "table" then
                    for _, c in ipairs(conns) do
                        local okf, fn = pcall(function() return c.Function end)
                        if okf then addFn(fn) end
                    end
                end
            end
        end
        for _, name in ipairs({ "RenderStepped", "Heartbeat", "Stepped" }) do
            local okS, sig = pcall(function() return RunService[name] end)
            local ok, conns = pcall(getconnections, sig)
            if okS and ok and type(conns) == "table" then
                for _, c in ipairs(conns) do
                    local okf, fn = pcall(function() return c.Function end)
                    if okf then addFn(fn) end
                end
            end
        end
    end
    -- 3) telusuri upvalue (maks 1500 fungsi)
    local i = 1
    while i <= #queue and nF < 1500 do
        local fn = queue[i]
        i += 1
        if not seenF[fn] then
            seenF[fn] = true
            nF += 1
            for _, u in pairs(getUpvalues(fn)) do
                if type(u) == "table" then
                    if tryTable(u) then return true end
                elseif type(u) == "function" then
                    addFn(u)
                end
            end
        end
    end
    return false
end

local function farmReach()
    return math.min(punchReach(), buildReach())
end

local function seedCount()
    return Farmer.SeedId and invCount(Farmer.SeedId) or 0
end

-- Kapan pohon ini siap panen (nil = bukan pohon)
local function treeReadyAt(x, y, id)
    if not Refs.Trees or not Refs.World then return nil end
    local it = ItemDB[id]
    if not (it and it.kind == "seed") then return nil end
    local t = Auto.treeEntry(x, y)
    if type(t) ~= "table" or type(t.p) ~= "number" then return nil end
    return t.p + (it.grow or 0)
end

-- Bisa tanam seed di sini? (seedId kosong = seed Farmer)
local function plantSpotOk(x, y, seedId)
    local w = Refs.World
    if not w or x < 0 or y < 0 or x >= w.w or y + 1 >= w.h then return false end
    if fgIdAt(x, y) ~= 0 then return false end
    local below = fgIdAt(x, y + 1)
    if below == 0 then return false end
    local it = ItemDB[below]
    if not it or it.kind == "seed" then return false end
    if not (solidAt(x, y + 1) or it.platform) then return false end
    local ok, res = pcall(function()
        if w.areas and type(w.areas.canEdit) == "function" and not w.areas.canEdit(x, y) then return false end
        if type(w.builderOk) == "function" and not w.builderOk(x, y, true) then return false end
        local sid = seedId or Farmer.SeedId
        local seed = sid and ItemDB[sid]
        if seed and type(w.needsWay) == "function" and w.needsWay(seed)
            and type(w.wayBlocked) == "function" and w.wayBlocked(x, y) then
            return false
        end
        return true
    end)
    return (not ok) or res
end

-- Mesin panen & tanam dipakai bersama oleh Farmer dan Pabrik.
-- FC = pengaturan yang sedang dipakai (seed, area, kecepatan, dll).
local FC = nil
local function farmerCfg()
    return {
        run = function() return Farmer.Running end,
        harvest = Farmer.Harvest,
        plant = Farmer.Plant and not Farmer.HarvestOnly,
        focusHarvest = Farmer.HarvestOnly == true,
        seed = Farmer.SeedId,
        skip = Farmer.Skip,
        hms = Farmer.HarvestMs,
        pms = Farmer.PlantMs,
        area = nil,      -- function(x, y): boleh panen di sini?
        plantSet = nil,  -- [idx] = true: hanya tanam di tile ini
        exclude = nil,   -- [idx] = true: jangan tanam di tile ini
        row = nil,               -- Farmer: semua baris yang masuk jangkauan
        batch = true,            -- jeda sekali per putaran, bukan per tile
        sweepPlant = true,       -- Farmer: tanam sambil menyusuri jalur; Pabrik tidak berubah
        collect = Farmer.Collect, -- ambil drop panen dulu sebelum lanjut
        status = function(t) Farmer.Status = t end,
        onHarvest = function(id)
            Farmer.Harvested += 1
            if id then Farmer.Got[id] = true end
        end,
        onPlant = function() Farmer.Planted += 1 end,
    }
end

local function fcSeeds()
    return FC.seed and invCount(FC.seed) or 0
end

local function fcHarvestOk(x, y)
    return FC.harvest and (not FC.area or FC.area(x, y))
end

local function fcPlantOk(idx)
    return (not FC.plantSet or FC.plantSet[idx]) and not (FC.exclude and FC.exclude[idx])
end

local function plantSeed(x, y)
    local id = FC.seed
    if not id or invCount(id) <= 0 then return false end
    sendSetTile("fg", x, y, id)
    if Refs.Inv then pcall(function() Refs.Inv:remove(id, 1) end) end
    FC.onPlant()
    FC.status("Tanam " .. itemName(id) .. " (" .. x .. "," .. y .. ")")
    return true
end

-- Pukulan dapat dibalas setelah frame ini. Jangan beri cooldown 30 detik
-- hanya karena pohon belum hilang tepat saat fungsi pukul kembali.
function Move.harvestTree(x, y, id, R)
    for attempt = 1, 3 do
        if not FC.run() or not alive() then return false, "cancelled" end
        local s = playerState()
        if not s or not stateReaches(s, x, y, R) then return false, "range" end
        if fgIdAt(x, y) ~= id then return false, "changed" end
        local ra = treeReadyAt(x, y, id)
        if not ra or workspace:GetServerTimeNow() < ra then return false, "changed" end
        local result = tryBreak(x, y, false)
        if result == "broke" then return true end
        if result ~= "hit" then return false, "punch" end
        local untilAt = os.clock() + 0.45
        repeat
            task.wait(0.05)
            if not FC.run() or not alive() then return false, "cancelled" end
            if fgIdAt(x, y) ~= id then
                Drops.brokeAt[x .. "," .. y] = os.clock()
                State.Broken += 1
                return true
            end
        until os.clock() >= untilAt
    end
    return false, "unchanged"
end

-- Antrean Farmer memakai jangkauan pukul dan tanam masing-masing. Pabrik /
-- produksi lahan tetap memakai pengaturan baris dan fase yang sudah ada.
function Move.farmerAreaTargets(s, kind, cfg)
    local w = Refs.World
    if not w or not s then return {}, 0 end
    local harvesting = kind == "harvest"
    local R = (harvesting and punchReach() or buildReach()) - 0.08
    local cx, cy, list = s.x, s.y - 0.475, {}
    local now, st = os.clock(), workspace:GetServerTimeNow()
    for y = math.max(0, floor(cy - R - 0.5)), math.min(w.h - 1, floor(cy + R + 0.5)) do
        for x = math.max(0, floor(cx - R - 0.5)), math.min(w.w - 1, floor(cx + R + 0.5)) do
            local idx = y * w.w + x
            if stateReaches(s, x, y, R) and not skipped(cfg.skip, idx, now) then
                local id = fgIdAt(x, y)
                if harvesting and cfg.harvest and id ~= 0 and (not cfg.only or id == cfg.only)
                    and (not cfg.area or cfg.area(x, y)) then
                    local ra = treeReadyAt(x, y, id)
                    -- Fokus panen mencakup atas/bawah dan kiri/kanan. Jangan
                    -- buang pohon terjangkau hanya karena drop berada di balik lantai.
                    if ra and st >= ra and (cfg.focusHarvest or Move.los(floor(cx), floor(cy), x, y)) then
                        if canWorkAt(x, y) then
                            list[#list + 1] = { x = x, y = y, idx = idx, id = id, readyAt = ra }
                        else
                            skipTile(cfg.skip, idx, 120)
                        end
                    end
                elseif not harvesting and cfg.plant and id == 0
                    and (not cfg.plantSet or cfg.plantSet[idx])
                    and (not cfg.exclude or not cfg.exclude[idx])
                    and not (cfg.sweepPlant and Farmer.PlantRoute
                        and Farmer.PlantRoute.world == w and Farmer.PlantRoute.seed == cfg.seed
                        and (Farmer.PlantRoute.pending[idx] or 0) > now)
                    and plantSpotOk(x, y, cfg.seed) then
                    list[#list + 1] = { x = x, y = y, idx = idx }
                end
            end
        end
    end
    table.sort(list, function(a, b)
        if harvesting and a.readyAt ~= b.readyAt then return a.readyAt < b.readyAt end
        if a.y ~= b.y then return a.y < b.y end
        return a.x < b.x
    end)
    return list, R
end

-- Kerjakan seluruh antrean dari posisi yang sama; konfirmasi balasannya bersama.
-- Fokus harvest memberi jeda tangan normal sebelum mengirim target berikutnya.
function Move.farmerArea(s)
    local cfg, w = FC, Refs.World
    local function live()
        return FC == cfg and cfg.run() and alive() and Refs.World == w
    end
    if not live() then return 0 end
    local harvest, HR = Move.farmerAreaTargets(s, "harvest", cfg)
    local harvestAt, nextPunchAt = os.clock(), os.clock()
    local done, got, planted, failed = 0, 0, 0, 0
    Farmer.BatchHarvest, Farmer.BatchPlanted = 0, 0
    local function confirmed(t)
        if t.finished then return end
        t.finished = true
        got += 1
        Farmer.BatchHarvest = got
        State.Broken += 1
        Drops.brokeAt[t.x .. "," .. t.y] = os.clock()
        cfg.onHarvest(t.id)
    end
    for round = 1, 3 do
        for _, t in ipairs(harvest) do
            if not live() then return done end
            if not t.finished then
                local cur = playerState()
                local ra = treeReadyAt(t.x, t.y, t.id)
                if t.sent and fgIdAt(t.x, t.y) ~= t.id then
                    confirmed(t)
                elseif not cur or cur.dead or not stateReaches(cur, t.x, t.y, HR)
                    or fgIdAt(t.x, t.y) ~= t.id or ra ~= t.readyAt
                    or workspace:GetServerTimeNow() < ra then
                    t.finished = true
                else
                    -- Tangan biasa tetap punya jeda. Selesaikan semua target
                    -- dari posisi ini; jangan kirim tile kedua saat pukulan pertama masih cooldown.
                    if cfg.focusHarvest and os.clock() < nextPunchAt then
                        if not waitAuto((nextPunchAt - os.clock()) * 1000) then return done end
                        if not live() then return done end
                    end
                    local punch = Refs.Punch
                    cur = playerState()
                    ra = treeReadyAt(t.x, t.y, t.id)
                    if not cur or cur.dead or not stateReaches(cur, t.x, t.y, HR)
                        or fgIdAt(t.x, t.y) ~= t.id or ra ~= t.readyAt
                        or workspace:GetServerTimeNow() < ra then
                        t.finished = true
                    else
                        local ok = type(punch) == "function"
                        if ok then
                            ok = pcall(punch, t.x, t.y, State.MutePunch or nil, nil)
                            done += 1
                            if cfg.focusHarvest then nextPunchAt = os.clock() + 0.22 end
                        end
                        if ok then
                            t.sent = true
                            if State.Visual and Anim.swing then Anim.swing(t.x, t.y, "punch") end
                            if fgIdAt(t.x, t.y) ~= t.id then confirmed(t) end
                        else
                            t.finished = true
                            failed += 1
                            skipTile(cfg.skip, t.idx, 3)
                        end
                    end
                end
            end
        end
        local untilAt = os.clock() + 0.45
        while live() do
            local pending = false
            for _, t in ipairs(harvest) do
                if t.sent and not t.finished then
                    if fgIdAt(t.x, t.y) ~= t.id then confirmed(t) else pending = true end
                end
            end
            if not pending or os.clock() >= untilAt then break end
            task.wait(0.05)
        end
        local pending = false
        for _, t in ipairs(harvest) do if not t.finished then pending = true; break end end
        if not pending then break end
    end
    if not live() then return done end
    for _, t in ipairs(harvest) do
        if not t.finished then
            failed += 1
            skipTile(cfg.skip, t.idx, 3)
        end
    end
    if #harvest > 0 then
        local rest = cfg.hms
        if cfg.focusHarvest then rest = rest - (os.clock() - harvestAt) * 1000 end
        if rest > 0 and not waitAuto(rest) then return done end
    end
    if not live() then return done end

    -- Scan ulang sesudah panen: tile yang baru kosong bisa langsung ditanam
    -- dalam putaran ini, termasuk tile di baris lain yang masih terjangkau.
    local plant, PR = Move.farmerAreaTargets(playerState(), "plant", cfg)
    for _, t in ipairs(plant) do
        if not live() then return done end
        if not cfg.seed or invCount(cfg.seed) <= 0 then break end
        local cur = playerState()
        if cur and not cur.dead and stateReaches(cur, t.x, t.y, PR)
            and plantSpotOk(t.x, t.y, cfg.seed) then
            done += 1
            if sendSetTile("fg", t.x, t.y, cfg.seed) then
                if Refs.Inv then pcall(function() Refs.Inv:remove(cfg.seed, 1) end) end
                cfg.onPlant()
                planted += 1
                Farmer.BatchPlanted = planted
                if cfg.sweepPlant then
                    local route = Move.farmerPlantState(cfg)
                    route.pending[t.idx] = os.clock() + 1
                    route.nextPulseAt = os.clock() + math.max(0.14, (cfg.pms or 250) / 1000)
                end
            else
                failed += 1
                skipTile(cfg.skip, t.idx, 3)
            end
        end
    end
    if planted > 0 and not waitAuto(cfg.pms) then return done end
    if not live() then return done end
    if done > 0 or failed > 0 then
        cfg.status(("Area: panen %d/%d | tanam %d%s"):format(got, #harvest, planted,
            failed > 0 and (" | %d belum berhasil, dicoba lagi"):format(failed) or ""))
    end
    if got > 0 and cfg.collect then
        if cfg.focusHarvest then
            -- Collector yang sudah aktif mengambil drop dekat badan / saat
            -- melewati baris. Jangan menyisipkan perjalanan memutar mencari drop.
            task.wait(0.1)
        else
            task.wait(0.25)
            if not live() then return done end
            local cy = s.y - 0.475
            Move.fetchDrops(live, 8, function(d) return abs(d.y - cy) <= 1.6 end, 10)
        end
    end
    return done
end

-- Panen & tanam semua yang terjangkau dari sini
local function farmerWorkInReach(s)
    if FC.batch then return Move.farmerArea(s) end
    local w = Refs.World
    local W = w.w
    local R = (FC.pabrikFast and (FC.harvest and punchReach() or buildReach())
        or (FC.pabrikHarvest and punchReach() or farmReach())) - 0.08
    local cx, cy = s.x, s.y - 0.475
    local now = os.clock()
    local st = workspace:GetServerTimeNow()
    local doPlant = FC.plant and fcSeeds() > 0
    local harvest, plant = {}, {}
    local bx, by = floor(s.x), floor(cy)
    for ty = math.max(0, floor(cy - R - 0.5)), math.min(floor(cy + R + 0.5), w.h - 1) do
        for tx = math.max(0, floor(cx - R - 0.5)), math.min(floor(cx + R + 0.5), W - 1) do
            if stateReaches(s, tx, ty, R) then
                local idx = ty * W + tx
                if not skipped(FC.skip, idx, now) then
                    local id = fgIdAt(tx, ty)
                    if id ~= 0 and fcHarvestOk(tx, ty) and (not FC.only or id == FC.only) then
                        local ra = treeReadyAt(tx, ty, id)
                        if ra and st >= ra and (FC.pabrikHarvest or Move.los(bx, by, tx, ty)) then
                            if canWorkAt(tx, ty) then
                                harvest[#harvest + 1] = { x = tx, y = ty, idx = idx, id = id, readyAt = ra }
                            else
                                skipTile(FC.skip, idx, 120)
                            end
                        end
                    elseif doPlant and id == 0 and fcPlantOk(idx) and (not FC.row or FC.row.y == ty)
                        and plantSpotOk(tx, ty, FC.seed) then
                        plant[#plant + 1] = { x = tx, y = ty, idx = idx }
                    end
                end
            end
        end
    end
    local function byX(a, b)
        if a.x ~= b.x then return a.x < b.x end
        return a.y < b.y
    end
    table.sort(harvest, function(a, b)
        if FC.pabrikFast then
            local da = (a.x - cx)^2 + 1.69 * (a.y - cy)^2
            local db = (b.x - cx)^2 + 1.69 * (b.y - cy)^2
            if da ~= db then return da < db end
        end
        if a.readyAt ~= b.readyAt then return a.readyAt < b.readyAt end
        return byX(a, b)
    end)
    table.sort(plant, function(a, b)
        if FC.pabrikFast and FC.row and FC.row.dir == -1 and a.x ~= b.x then return a.x > b.x end
        return byX(a, b)
    end)

    local done, got = 0, 0
    for _, t in ipairs(harvest) do
        if not FC.run() or not alive() then return done end
        local cur = playerState()
        if not cur or not stateReaches(cur, t.x, t.y, R) then break end
        local id = t.id
        local began = os.clock()
        if FC.harvestRoom and not FC.harvestRoom() then return done end
        local harvested, why = Move.harvestTree(t.x, t.y, id, R)
        if harvested then
            FC.onHarvest(id)
            got += 1
            FC.status("Panen " .. itemName(id) .. " (" .. t.x .. "," .. t.y .. ")")
        else
            if why == "cancelled" or why == "range" then return done end
            if why ~= "changed" then
                skipTile(FC.skip, t.idx, 3)
                FC.status(why == "punch" and "Pukul gagal; tekan Hubungkan ke game"
                    or "Panen belum dikonfirmasi game, dicoba lagi")
            end
        end
        done += 1
        -- Confirmation time already counts toward the action interval.
        local rest = FC.pabrikFast and math.max(0, FC.hms - (os.clock() - began) * 1000) or FC.hms
        if rest > 0 and not waitAuto(rest) then return done end
    end
    -- ambil hasil panen dulu sebelum pindah / tanam
    if got > 0 and FC.collect then
        FC.status("Ambil hasil panen...")
        task.wait(0.25) -- drop panen muncul sedikit terlambat
        if not FC.run() or not alive() then return done end
        -- susuri baris ini sampai drop terjauh (terambil sambil lewat, tanpa berhenti)
        if Move.fetchDrops(FC.run, 8, function(d) return abs(d.y - cy) <= 1.6 end, 10) > 0 then return done end
    end
    for _, t in ipairs(plant) do
        if not FC.run() or not alive() then return done end
        if FC.yieldHarvest and FC.yieldHarvest() then return done end
        if fcSeeds() <= 0 then break end
        local cur = playerState()
        if not cur or not stateReaches(cur, t.x, t.y, R) then return done end
        if fgIdAt(t.x, t.y) == 0 then
            if not plantSeed(t.x, t.y) then break end
            done += 1
            if not waitAuto(FC.pms) then return done end
        end
    end
    return done
end

-- Status lintasan terpisah dari FC: FC diperbarui setiap putaran Farmer,
-- tetapi arah baris harus tetap sama sampai sisi itu selesai.
function Move.farmerPlantState(cfg)
    local r = Farmer.PlantRoute
    if not r or r.world ~= Refs.World or r.seed ~= cfg.seed then
        r = { world = Refs.World, seed = cfg.seed, pending = {}, nextPulseAt = 0 }
        Farmer.PlantRoute = r
    end
    return r
end

-- Pilih ujung lintasan, bukan satu tile terdekat setiap kali. Pada baris
-- lain dekati ujung terdekat dulu, lalu susuri baris dari ujung tersebut.
function Move.farmerPlantTarget(cfg, list, px, py)
    local r, valid = Move.farmerPlantState(cfg), {}
    local now = os.clock()
    for _, t in ipairs(list) do
        if (r.pending[t.idx] or 0) <= now and plantSpotOk(t.x, t.y, cfg.seed) then
            valid[#valid + 1] = t
        end
    end
    if #valid == 0 then return nil end
    local y, first, last = valid[1].y, valid[1], valid[#valid]
    if y ~= py then
        local entry = abs(first.x - px) <= abs(last.x - px) and first or last
        r.y, r.dir = y, entry == first and 1 or -1
        return entry
    end
    if r.y ~= y or not r.dir then
        local s = playerState()
        r.y, r.dir = y, (s and (s.facing or 1) < 0) and -1 or 1
    end
    local lo, hi = px, px
    while lo > 0 and openAt(lo - 1, y) and realSupport(lo - 1, y) do lo -= 1 end
    while hi + 1 < r.world.w and openAt(hi + 1, y) and realSupport(hi + 1, y) do hi += 1 end
    for turn = 1, 2 do
        local best
        for _, t in ipairs(valid) do
            if t.x >= lo and t.x <= hi and (t.x - px) * r.dir >= 0
                and (not best or (t.x - best.x) * r.dir > 0) then best = t end
        end
        if best then return best end
        if turn == 1 then r.dir = -r.dir end
    end
    -- Ada celah / tangga: A* tetap menentukan jalur yang aman ke bagian lain.
    local nearest
    for _, t in ipairs(valid) do
        if not nearest or abs(t.x - px) < abs(nearest.x - px) then nearest = t end
    end
    r.dir = nearest.x >= px and 1 or -1
    return nearest
end

-- Satu pulsa tanpa task.wait: jeda tanam tidak menghentikan tombol gerak.
-- Tile kosong, izin, jangkauan dan stok diperiksa lagi tepat sebelum kirim.
function Move.farmerPlantPulse(cfg, r)
    local function live()
        return FC == cfg and cfg.run() and alive() and Refs.World == r.world
            and Farmer.Plant and not Farmer.HarvestOnly and Farmer.SeedId == cfg.seed
    end
    if not live() or not cfg.plant or not cfg.seed or os.clock() < r.nextPulseAt then return 0 end
    local s = playerState()
    if not s or s.dead or not s.grounded then return 0 end
    r.nextPulseAt = os.clock() + math.max(0.14, (cfg.pms or 250) / 1000)
    local targets, R = Move.farmerAreaTargets(s, "plant", cfg)
    local py = floor(s.y - 0.475)
    table.sort(targets, function(a, b)
        local ay, by = abs(a.y - py), abs(b.y - py)
        if ay ~= by then return ay < by end
        if a.x ~= b.x then return (a.x - b.x) * (r.dir or 1) < 0 end
        return a.y < b.y
    end)
    local planted = 0
    for _, t in ipairs(targets) do
        if not live() or invCount(cfg.seed) <= 0 then break end
        local cur = playerState()
        if cur and cur.grounded and not cur.dead and stateReaches(cur, t.x, t.y, R)
            and (r.pending[t.idx] or 0) <= os.clock() and plantSpotOk(t.x, t.y, cfg.seed) then
            if sendSetTile("fg", t.x, t.y, cfg.seed) then
                r.pending[t.idx] = os.clock() + 1
                if Refs.Inv then pcall(function() Refs.Inv:remove(cfg.seed, 1) end) end
                cfg.onPlant()
                planted += 1
            else
                skipTile(cfg.skip, t.idx, 3)
            end
        end
    end
    if planted > 0 then
        Farmer.BatchPlanted = planted
        cfg.status(("Tanam sambil jalan: %d tile | seed %d"):format(planted, invCount(cfg.seed)))
    end
    return planted
end

-- Pohon yang baru ready tetap dapat memotong perjalanan tanam. Tile yang
-- sudah dinyatakan tidak terjangkau sementara tidak memicu putaran sia-sia.
function Move.farmerPlantReady(cfg)
    if not cfg.harvest then return false end
    local w, now, st = Refs.World, os.clock(), workspace:GetServerTimeNow()
    if not w then return false end
    local s = playerState()
    if not s or s.dead then return false end
    local sx, sy = startNode(s)
    local filter = reachFilter(sy * w.w + sx, punchReach() - 0.35, scaffoldId() ~= nil)
    for y, row in pairs(w.fg) do
        if type(y) == "number" and type(row) == "table" then
            for x, id in pairs(row) do
                if type(x) == "number" and id ~= 0 and not skipped(cfg.skip, y * w.w + x, now)
                    and (not filter or filter[y * w.w + x])
                    and (not cfg.only or id == cfg.only) and (not cfg.area or cfg.area(x, y)) then
                    local readyAt = treeReadyAt(x, y, id)
                    if readyAt and st >= readyAt and canWorkAt(x, y) then return true end
                end
            end
        end
    end
    return false
end

-- Gerakan mendatar digabung sampai ujung lintasan. Tanam berjalan pada
-- frame yang sama, tanpa coroutine lain yang bisa tertinggal saat Stop.
function Move.farmerPlantWalk(tx, ty, cfg, r, cancel)
    local start = playerState()
    if not start then return false end
    local cx, at = tx + 0.5, os.clock()
    local limit = 1.5 + abs(cx - start.x) * 0.5
    while frame() do
        if cancel() then releaseInput(); return false, "cancelled" end
        local s = playerState()
        if not s or s.dead or not s.grounded or floor(s.y - 0.475) ~= ty then
            releaseInput(); return false, "moved"
        end
        Move.farmerPlantPulse(cfg, r)
        if cancel() then releaseInput(); return false, "cancelled" end
        if abs(s.x - cx) <= 0.2 and abs(s.vx or 0) < 2 then
            releaseInput(); return true
        end
        local dir = cx > s.x and 1 or -1
        local nx = math.clamp(floor(s.x + dir * 0.55), math.min(floor(s.x), tx), math.max(floor(s.x), tx))
        if not openAt(nx, ty) or not realSupport(nx, ty) then
            releaseInput(); return false, "blocked"
        end
        steerX(s, cx, 0.1)
        if os.clock() - at > limit then releaseInput(); return false, "timeout" end
    end
    releaseInput()
    return false, "cancelled"
end

-- Cari target + kapan pohon berikutnya siap.
--   Panen : pohon yang paling awal matang; jarak jadi pembanding kalau waktunya sama.
--   Tanam : rapi per baris. Selesaikan 1 baris dulu (baris yang sedang dikerjakan,
--           atau baris terdekat dengan karakter), dari tile paling kiri ke kanan.
local function farmerScan(px, py, maxN, filter)
    local w = Refs.World
    local W, H = w.w, w.h
    local best = {}
    local now = os.clock()
    local st = workspace:GetServerTimeNow()
    local nextReady = nil
    local function earlier(a, b)
        if (FC.focusHarvest or FC.pabrikFast) and a.d ~= b.d then return a.d < b.d end
        if a.readyAt ~= b.readyAt then return a.readyAt < b.readyAt end
        if a.d ~= b.d then return a.d < b.d end
        return a.idx < b.idx
    end
    local doPlant = FC.plant and fcSeeds() > 0
    local rows = {} -- [y] = daftar tempat tanam di baris itu
    local scanned = 0
    for y = 0, H - 1 do
        local frow, below = w.fg[y], w.fg[y + 1]
        for x = 0, W - 1 do
            local id = frow and frow[x] or 0
            if id ~= 0 then
                if fcHarvestOk(x, y) and (not FC.only or id == FC.only) then
                    local ra = treeReadyAt(x, y, id)
                    if ra and st >= ra then
                        local idx = y * W + x
                        if not skipped(FC.skip, idx, now) then
                            if not filter or filter[idx] then
                                local dx, dy = x - px, (y - py) * 1.3
                                local d = dx * dx + dy * dy
                                local target = { x = x, y = y, idx = idx, d = d, kind = "harvest", readyAt = ra }
                                if #best < maxN or earlier(target, best[#best]) then
                                    if canWorkAt(x, y) then
                                        local pos = #best + 1
                                        while pos > 1 and earlier(target, best[pos - 1]) do pos -= 1 end
                                        table.insert(best, pos, target)
                                        if #best > maxN then best[#best] = nil end
                                    else
                                        skipTile(FC.skip, idx, 120)
                                    end
                                end
                            end
                        end
                    elseif ra and (not nextReady or ra - st < nextReady) then
                        nextReady = ra - st
                    end
                end
            elseif doPlant then
                local b = below and below[x] or 0
                local idx = y * W + x
                if b ~= 0 and fcPlantOk(idx) and not skipped(FC.skip, idx, now) then
                    if not filter or filter[idx] then
                        local r = rows[y]
                        if not r then
                            r = {}
                            rows[y] = r
                        end
                        r[#r + 1] = { x = x, y = y, idx = idx, kind = "plant" }
                    end
                end
            end
        end
        scanned += W
        if scanned >= 6000 then
            scanned = 0
            task.wait()
            if not FC.run() or not alive() then break end
        end
    end
    if #best > 0 or not doPlant then return best, nextReady end

    -- tanam rapi: baris yang sedang dikerjakan dulu, lalu baris terdekat
    local lock = FC.sweepPlant and Move.farmerPlantState(FC).y or (FC.row and FC.row.y)
    local order = {}
    for y in pairs(rows) do order[#order + 1] = y end
    local function rowKey(y) return (y == lock) and -1 or math.abs(y - py) end
    table.sort(order, function(a, b)
        local ka, kb = rowKey(a), rowKey(b)
        if ka ~= kb then return ka < kb end
        return a < b
    end)
    for _, y in ipairs(order) do
        local list = rows[y]
        table.sort(list, function(a, b) return a.x < b.x end)
        if FC.pabrikFast and FC.row then
            if FC.row.y ~= y or not FC.row.dir then
                FC.row.dir = abs(list[1].x - px) <= abs(list[#list].x - px) and 1 or -1
            end
            if FC.row.dir < 0 then table.sort(list, function(a, b) return a.x > b.x end) end
        end
        if FC.sweepPlant then
            local target = Move.farmerPlantTarget(FC, list, px, py)
            if target then return { target }, nextReady end
        else
        for _, t in ipairs(list) do
            if plantSpotOk(t.x, t.y, FC.seed) then
                if FC.row then FC.row.y = y end
                return { t }, nextReady
            end
            skipTile(FC.skip, t.idx, 120)
        end
        end
    end
    if FC.row then FC.row.y = nil end
    return best, nextReady
end

function Move.farmerPlantTravel(s, cfg, target, useBlock)
    local w, r = Refs.World, Move.farmerPlantState(cfg)
    local why, checkAt = nil, 0
    local function cancel()
        if FC ~= cfg or not cfg.run() or not alive() or Refs.World ~= w
            or not Farmer.Plant or Farmer.HarvestOnly or Farmer.SeedId ~= cfg.seed then
            why = "wait"; return true
        end
        if invCount(cfg.seed) <= 0 then why = "work"; return true end
        if os.clock() >= checkAt then
            checkAt = os.clock() + 0.25
            if Move.farmerPlantReady(cfg) then why = "harvest"; return true end
        end
        return false
    end
    if cancel() then releaseInput(); return why end
    local sx, sy = startNode(s)
    local goals = { [target.idx] = true }
    local path = astar(sx, sy, goals, target.x, target.y, 0.5, useBlock)
    if cancel() then releaseInput(); return why end
    if not path then
        -- Tile dapat ditanam dari samping meski tidak bisa dipijak langsung.
        local group = { target, cancel = cancel }
        travelGroup(sx, sy, group, buildReach() - 0.35, useBlock, cfg.skip, FarmerFail)
        releaseInput()
        return why or "move"
    end
    cfg.status(("Tanam sambil jalan ke (%d,%d)"):format(target.x, target.y))
    Move.farmerPlantPulse(cfg, r)
    local i = 1
    while i <= #path do
        if cancel() then releaseInput(); return why end
        local e, last, ok, reason = path[i], i, false, nil
        if e.kind == "walk" and not e.build then
            local dir = e.x - e.fx
            while path[last + 1] and path[last + 1].kind == "walk" and not path[last + 1].build
                and path[last + 1].y == e.y and (path[last + 1].x - path[last + 1].fx) == dir do
                last += 1
            end
            r.dir = dir
            ok, reason = Move.farmerPlantWalk(path[last].x, e.y, cfg, r, cancel)
        else
            ok, reason = followPath({ e }, cancel)
            if not cancel() then Move.farmerPlantPulse(cfg, r) end
        end
        releaseInput()
        if cancel() or reason == "cancelled" then return why or "wait" end
        if not ok then
            if e.key then BadEdge[e.key] = os.clock() + 3 end
            skipTile(cfg.skip, target.idx, 3)
            return "move"
        end
        i = last + 1
    end
    releaseInput()
    return "move"
end

-- Pilih titik berdiri yang benar-benar menjangkau sedikitnya dua pohon
-- ready. Tujuan A* berupa posisi berdiri, bukan tepi jangkauan satu pohon.
function Move.farmerGroupRoute(s, cfg, targets, nearby, useBlock)
    local w = Refs.World
    if not w or not cfg.focusHarvest or #targets < 2 then return false end
    local sx, sy = startNode(s)
    local R = punchReach() - 0.08
    local dxm, dyLo, dyHi = reachOffsets(R)
    local cells, anchor = {}, nearby[1] and nearby[1].idx
    for _, t in ipairs(targets) do
        local id = fgIdAt(t.x, t.y)
        local ra = treeReadyAt(t.x, t.y, id)
        if ra and workspace:GetServerTimeNow() >= ra and not skipped(cfg.skip, t.idx) then
            for ny = math.max(0, t.y - dyHi), math.min(w.h - 2, t.y - dyLo) do
                for nx = math.max(0, t.x - dxm), math.min(w.w - 1, t.x + dxm) do
                    local idx = ny * w.w + nx
                    local c = cells[idx]
                    if not c then
                        c = { x = nx, y = ny, n = 0,
                            open = openAt(nx, ny) and (realSupport(nx, ny)
                                or (useBlock and placeOk(nx, ny + 1))) }
                        cells[idx] = c
                    end
                    if c.open and (cfg.focusHarvest or Move.los(nx, ny, t.x, t.y))
                        and stateReaches({ x = nx + 0.5, y = ny + 0.95 }, t.x, t.y, R) then
                        c.n = c.n + 1
                        if anchor == t.idx then c.anchor = true end
                    end
                end
            end
        end
    end
    local goals, best, bestD = { maxExpand = 600 }, nil, nil
    for idx, c in pairs(cells) do
        if c.n >= 2 and (not anchor or c.anchor) then
            goals[idx] = true
            local d = abs(c.x - sx) + 1.5 * abs(c.y - sy)
            local forward = not Farmer.SweepDir or (c.x - sx) * Farmer.SweepDir >= 0
            if not bestD or d < bestD or (d == bestD and (c.n > best.n
                or (c.n == best.n and forward and not best.forward))) then
                best, bestD = c, d
                c.forward = forward
            end
        end
    end
    if not best then return false end -- jangan menahan pohon tunggal tanpa pasangan yang terjangkau
    local function live() return FC == cfg and cfg.run() and alive() and Refs.World == w end
    if not live() then return false end
    cfg.status(("Cari posisi panen %d pohon dekat (%d,%d)"):format(best.n, best.x, best.y))
    local path = astar(sx, sy, goals, best.x, best.y, 0.5, useBlock)
    if not path or not live() then return false end -- upaya kelompok tidak memberi cooldown ke pohon
    local ok
    if #path == 0 then
        if abs(s.x - (sx + 0.5)) <= 0.08 then return false end
        ok = execWalk(sx, sy) -- rapatkan posisi, bukan skip seluruh kelompok selama 20 detik
    else
        ok = followPath(path, function() return not live() end)
    end
    releaseInput()
    if ok and live() then
        local cur = playerState()
        if cur and abs(cur.x - s.x) > 0.2 then Farmer.SweepDir = cur.x > s.x and 1 or -1 end
        return true
    end
    return false
end

local lastFarmerText = nil
local function updateFarmerStatus()
    if Refs.World and not Refs.Trees and os.clock() >= (Auto.nextTreeScan or 0) then
        Auto.nextTreeScan = os.clock() + 15
        pcall(findTreeRefs)
    end
    if not UI.FarmerStatus then return end
    local seed = Farmer.SeedId
    local txt = "Status  : " .. (Farmer.Running and "JALAN" or "BERHENTI")
        .. "\nPanen   : " .. Farmer.Harvested .. "  | tanam: " .. Farmer.Planted .. "  | collect: " .. State.Collected
        .. "\nSeed    : " .. (seed and (itemName(seed) .. " x" .. invCount(seed)) or "-")
        .. "\nMode    : " .. (Farmer.HarvestOnly and "harvest area vertikal + horizontal"
            or "tanam sambil jalan per baris + harvest sesuai pilihan")
        .. "\nIsi seed: " .. ((Farmer.Plant and not Farmer.HarvestOnly)
            and (Farmer.RefillStatus or "otomatis saat seed pilihan habis") or "tidak aktif saat harvest saja")
        .. "\nPohon   : " .. (Refs.Trees and "terbaca" or "TIDAK terbaca (harvest mati)")
        .. "\nKontrol : " .. AutoInput.status()
        .. "\nPijakan : " .. blockText(Farmer.UseBlock, Farmer.ScaffoldId)
        .. "\nDrop    : mati; hasil panen disimpan"
        .. "\nAksi    : " .. Farmer.Status
    if txt == lastFarmerText then return end
    lastFarmerText = txt
    task.defer(function()
        pcall(function() UI.FarmerStatus:SetDesc(txt) end)
    end)
end

-- 1 langkah mesin panen/tanam (pakai FC):
--   kerjakan yang terjangkau, atau jalan ke target terdekat.
-- Hasil: "work" | "move" | "wait" | "idle" (+ detik ke pohon siap berikutnya)
-- Tersangkut lama di udara / pinggir block (bikin karakter diam): dorong sedikit ke samping
function Move.airCheck(s)
    if s.grounded then
        Move.AirAt = nil
        return
    end
    if not Move.AirAt then
        Move.AirAt = os.clock()
    elseif os.clock() - Move.AirAt > 3 then
        Move.AirAt = nil
        local right = (s.facing or 1) < 0 -- ke arah sebaliknya
        AutoInput.active = true
        AutoInput.right, AutoInput.left = right, not right
        task.wait(0.2)
        AutoInput.right, AutoInput.left = false, false
    end
end

-- Seed pilihan habis: cari drop seed yang sama di seluruh world. Berhasil
-- hanya kalau jumlah di tas bertambah, bukan sekadar berhasil berjalan.
function Farmer.refillSeed(seed)
    local w, cfg = Refs.World, FC
    if not Farmer.Running or not Farmer.Plant or Farmer.HarvestOnly or not seed or Farmer.SeedId ~= seed
        or not w or not alive() then return "cancelled" end
    if invCount(seed) > 0 then return "ready" end
    if Refs.Inv then
        local okr, room = pcall(function() return Refs.Inv:room(seed) end)
        if okr and type(room) == "number" and room <= 0 then
            Farmer.RefillStatus = "Tas penuh untuk seed pilihan; kosongkan slot dulu"
            return "none"
        end
    end
    local now = os.clock()
    if Farmer.RefillWorld ~= w or Farmer.RefillFor ~= seed then
        Farmer.RefillWorld, Farmer.RefillFor = w, seed
        Farmer.RefillNext, Farmer.RefillSkip = 0, {}
    end
    if now < (Farmer.RefillNext or 0) then return "none" end
    Farmer.RefillNext = now + 1
    if not Drops.list then pcall(findDropRefs) end -- pencarian ringan, tanpa getgc
    if not Drops.list then
        Farmer.RefillStatus = "Daftar drop belum terbaca; tekan Hubungkan ke game"
        return "none"
    end
    local s = playerState()
    if not s or s.dead then return "cancelled" end
    local best, distance
    for _, d in ipairs(Drops.snapshot()) do
        local retryAt = Farmer.RefillSkip[d.uid]
        if d.id == seed and canTry(d, now) and (not retryAt or now >= retryAt)
            and d.x >= 0 and d.y >= 0 and d.x < w.w and d.y < w.h
            and not solidAt(floor(d.x), floor(d.y)) then
            local dx, dy = d.x - s.x, d.y - (s.y - 0.475)
            local dd = dx * dx + 4 * dy * dy
            if not distance or dd < distance then best, distance = d, dd end
        end
    end
    if not best then
        Farmer.RefillStatus = "Menunggu drop " .. itemName(seed) .. " yang bisa diambil"
        return "none"
    end
    local function live()
        return Farmer.Running and Farmer.Plant and not Farmer.HarvestOnly and Farmer.SeedId == seed
            and Refs.World == w and FC == cfg and alive()
    end
    local function cancel() return not live() or invCount(seed) > 0 end
    local function takeNearby()
        if not live() or State.CollectMode ~= "Remote" or not canTry(best, os.clock()) then return end
        local cur = playerState()
        local R = (State.CollectRadius or 3) + 0.2
        if cur and abs(best.x - cur.x) <= R and abs(best.y - (cur.y - 0.475)) <= R then
            pcall(takeDrop, best) -- seed ini saja, termasuk jika Auto Collect mati
        end
    end
    local before = invCount(seed)
    Farmer.RefillStatus = ("Ambil %s di (%d,%d)"):format(itemName(seed), floor(best.x), floor(best.y))
    Farmer.Status = Farmer.RefillStatus
    takeNearby()
    local ok = true
    if live() and invCount(seed) <= before then
        ok = pcall(Move.visitDrop, best, cancel)
    end
    releaseInput()
    if not live() then return "cancelled" end
    takeNearby()
    local untilAt = os.clock() + 0.6
    while live() and invCount(seed) <= before and best.taking and os.clock() < untilAt do
        task.wait(0.05)
    end
    if not live() then return "cancelled" end
    local got = invCount(seed) - before
    if got > 0 then
        Farmer.Refilled = (Farmer.Refilled or 0) + got
        Farmer.RefillNext = 0
        Farmer.RefillStatus = ("Terambil %d %s; lanjut tanam"):format(got, itemName(seed))
        Farmer.Status = Farmer.RefillStatus
        return "picked"
    end
    Farmer.RefillSkip[best.uid] = os.clock() + 3
    Farmer.RefillStatus = ok and "Seed belum masuk tas; coba drop lain sebentar lagi"
        or "Gagal mendatangi seed; coba drop lain sebentar lagi"
    Farmer.Status = Farmer.RefillStatus
    return "waiting"
end

local function fieldStep()
    local w = Refs.World
    local stepCfg = FC
    local s = playerState()
    if not w or not s or s.dead then
        releaseInput()
        task.wait(0.5)
        return "wait"
    end
    if not s.grounded then
        releaseInput()
        Move.airCheck(s)
        task.wait()
        return "wait"
    end
    Move.AirAt = nil
    releaseInput()
    if FC.batch and not FC.harvest and not FC.plant then return "idle" end
    if FC.yieldHarvest and FC.yieldHarvest() then return "harvest" end
    local targets, nextReady
    if FC.focusHarvest and FC.harvest and not FC.plant then
        local cfg = FC
        local nearby = Move.farmerAreaTargets(s, "harvest", cfg)
        if #nearby < 2 then
            local sx, sy = startNode(s)
            local R, useBlock = punchReach() - 0.35, scaffoldId() ~= nil
            targets, nextReady = farmerScan(floor(s.x), floor(s.y - 0.475), 32,
                reachFilter(sy * w.w + sx, R, useBlock))
            if FC ~= cfg or not cfg.run() or not alive() or Refs.World ~= w then return "wait" end
            if Move.farmerGroupRoute(s, cfg, targets, nearby, useBlock) then return "move" end
            if FC ~= cfg or not cfg.run() or not alive() or Refs.World ~= w then return "wait" end
            s = playerState() or s
        end
    end
    if farmerWorkInReach(s) > 0 then return "work" end
    if FC.yieldHarvest and FC.yieldHarvest() then return "harvest" end
    if FC.batch and FC.plant and FC.seed and fcSeeds() <= 0 then
        local refill = Farmer.refillSeed(FC.seed)
        if refill == "picked" or refill == "ready" then return "work" end
        if refill == "waiting" then return "refill" end
        if refill == "cancelled" then return "wait" end
    end
    local R = FC.batch and math.max(FC.harvest and punchReach() or 0, FC.plant and buildReach() or 0) - 0.35
        or (FC.pabrikFast and (FC.harvest and punchReach() or buildReach())
            or (FC.pabrikHarvest and punchReach() or farmReach())) - 0.35
    local useBlock = scaffoldId() ~= nil
    local sx, sy = startNode(s)
    local px, py = floor(s.x), floor(s.y - 0.475)
    if not targets then
        targets, nextReady = farmerScan(px, py, 8, reachFilter(sy * w.w + sx, R, useBlock))
    end
    if FC ~= stepCfg or Refs.World ~= w or not FC.run() or not alive() then return "wait" end
    if #targets == 0 then return "idle", nextReady end
    if FC.sweepPlant and targets[1].kind == "plant" then
        return Move.farmerPlantTravel(s, FC, targets[1], useBlock)
    end
    if FC.batch then
        R = (targets[1].kind == "harvest" and punchReach() or buildReach()) - 0.35
    end
    -- Fokus panen memakai jangkauan asli ke segala arah, termasuk beda baris.
    -- Mode tanam tetap mendekati baris pohon untuk mengambil hasil panennya.
    targets.los = targets[1].kind == "harvest" and not (FC.focusHarvest or FC.pabrikHarvest)
    if targets[1].kind == "plant" then targets.cancel = FC.yieldHarvest end
    if FC.pabrikFast then
        local cfg, pending = FC, targets.cancel
        targets.smooth = true
        targets.cancel = function()
            return FC ~= cfg or Refs.World ~= w or not cfg.run() or not alive()
                or (pending and pending())
        end
    end
    travelGroup(sx, sy, targets, R, useBlock, FC.skip, FarmerFail)
    return "move"
end

function Farmer.setHarvest(on)
    Farmer.PlantRoute = nil
    Farmer.Harvest, Farmer.HarvestOnly, Farmer.Drop = on == true, on == true, false
    if on then
        Farmer.Plant = false
        Farmer.RefillStatus = "Tidak aktif saat harvest saja"
        if UI.FarmerPlantToggle then pcall(function() UI.FarmerPlantToggle:Set(false) end) end
    end
    table.clear(Farmer.Skip)
    if Farmer.Running then FC = farmerCfg() end
    if Auto.updateFarmerStatus then Auto.updateFarmerStatus() end
end

function Farmer.setPlant(on)
    Farmer.PlantRoute = nil
    Farmer.Plant, Farmer.Drop = on == true, false
    if on then
        Farmer.HarvestOnly = false -- Auto Plant adalah pilihan tambahan yang disengaja
        Farmer.RefillStatus = "Otomatis ambil seed pilihan saat habis"
    elseif Farmer.Harvest then
        Farmer.HarvestOnly = true
        Farmer.RefillStatus = "Tidak aktif saat harvest saja"
    end
    table.clear(Farmer.Skip)
    if Farmer.Running then FC = farmerCfg() end
    if Auto.updateFarmerStatus then Auto.updateFarmerStatus() end
end

-- Item hasil panen yang sudah hampir penuh (kompatibilitas versi lama).
-- Farmer tidak menawarkan hasil untuk auto drop, termasuk jika Titik Drop sudah diatur.
function Farmer.dropList()
    return {}
end

local function farmerLoop()
    local lastUi = 0
    while Farmer.Running and alive() do
        task.wait()
        if os.clock() - lastUi > 0.5 then
            lastUi = os.clock()
            updateFarmerStatus()
        end
        FC = farmerCfg()
        if not Refs.World then
            Farmer.Status = "Menunggu karakter / world..."
            task.wait(0.5)
        else
            local r, nextReady = fieldStep()
            if r == "wait" and not playerState() then
                Farmer.Status = "Menunggu karakter / world..."
            end
            if r == "idle" then
                local parts = {}
                if Farmer.Harvest then
                    parts[#parts + 1] = nextReady and ("pohon siap ±" .. math.ceil(nextReady) .. " dtk") or "tidak ada pohon"
                end
                if FC.plant then
                    parts[#parts + 1] = (seedCount() <= 0)
                        and (Farmer.RefillStatus or "seed habis / belum dipilih") or "tidak ada tempat tanam"
                end
                Farmer.Status = "Menunggu: " .. table.concat(parts, ", ")
                if not waitAuto(250) then break end
            end
        end
    end
    releaseInput()
end

local function setFarmerVisual()
    if UI.FarmerToggle then pcall(function() UI.FarmerToggle:Set(Farmer.Running) end) end
end

stopFarmer = function(reason)
    Farmer.Running = false
    autoEnd()
    setFarmerVisual()
    Farmer.Status = reason or "Dihentikan"
    if reason then
        notify("Farmer", reason, 5)
        if not string.find(reason, "^Dihentikan") then Hook.send("stop", "Farmer berhenti: " .. reason) end
    end
    updateFarmerStatus()
end

local function startFarmer()
    if Farmer.Running then return end
    local err = checkAutoStart()
    if not err and not Farmer.Harvest and not Farmer.Plant then
        err = "Aktifkan Auto Harvest atau Auto Plant"
    end
    if not err and not Farmer.Harvest and not Farmer.SeedId then
        err = "Pilih seed dulu untuk Auto Plant"
    end
    if err then
        notify("Farmer", err, 4)
        setFarmerVisual()
        return
    end
    if Farmer.Harvest and not Refs.Trees and not findTreeRefs() then
        notify("Farmer", "Data pohon tidak ketemu: Auto Harvest tidak bisa cek pohon siap", 5)
    end
    if Splice.Running and Splice.stop then Splice.stop("Dihentikan karena Farmer dimulai") end
    if Pabrik.Running and Pabrik.stop then Pabrik.stop("Dihentikan karena Farmer dimulai") end
    if Build.Running and Build.stop then Build.stop("Dihentikan karena Farmer dimulai") end
    if State.Running then stopFarm("Dihentikan karena Farmer dimulai") end
    if Clear.Running then stopClear("Dihentikan karena Farmer dimulai") end
    table.clear(Farmer.Skip)
    table.clear(FarmerFail)
    table.clear(BadEdge)
    table.clear(Farmer.Row)
    Farmer.DropOffUntil = 0
    Farmer.SweepDir = nil
    Farmer.PlantRoute = nil
    Farmer.BatchHarvest, Farmer.BatchPlanted = 0, 0
    Farmer.RefillNext, Farmer.RefillSkip, Farmer.RefillWorld, Farmer.RefillFor = 0, {}, nil, nil
    Farmer.RefillStatus = "Otomatis ambil seed pilihan saat habis"
    Farmer.Status = "Mulai..."
    Farmer.Running = true
    autoBegin()
    setFarmerVisual()
    updateFarmerStatus()
    task.spawn(function()
        local ok, e = pcall(farmerLoop)
        if not ok then
            warn("[Zekio Supreme Premium] Farmer error: " .. tostring(e))
            if Farmer.Running then stopFarmer("Error: " .. tostring(e)) end
        end
    end)
end

---------------------------------------------------------------------
-- SPLICE KELILING: tanam Seed A + splice Seed B di seluruh world
---------------------------------------------------------------------
-- Cara kerja (sama seperti Farmer, tapi aksinya splice):
--   1. Kerjakan semua tile yang terjangkau dari posisi sekarang:
--        tile kosong (di bawahnya block) -> tanam A, lalu splice B ke pohon A itu
--        pohon A yang belum di-splice     -> splice B
--   2. Kalau tidak ada lagi yang terjangkau: cari tile terdekat, jalan ke sana pakai A*.
--   Pohon yang sudah siap panen tidak bisa di-splice (aturan game), jadi dilewati.
local SpliceFail = {}

local function spliceInv()
    return invCount(Splice.A or 0), invCount(Splice.B or 0)
end

-- Jenis kerja di tile ini: "plant" | "splice" | nil
local function spliceKind(x, y, st)
    local A = Splice.A
    local id = fgIdAt(x, y)
    if id == 0 then
        local a, b = spliceInv()
        if a > 0 and b > 0 and plantSpotOk(x, y, A) then return "plant" end
        return nil
    end
    if id ~= A then return nil end
    local t = Auto.treeEntry(x, y)
    if type(t) == "table" and t.s == true then return nil end -- sudah di-splice
    local ra = treeReadyAt(x, y, id)
    if ra and st >= ra then return nil end -- sudah siap panen
    local _, b = spliceInv()
    if b > 0 and canWorkAt(x, y) then return "splice" end
    return nil
end

local function spliceOnce(x, y)
    local w = Refs.World
    local f = w and rawget(w, "spliceSeed")
    if type(f) ~= "function" then return false, "fungsi splice game tidak ketemu" end
    local ok, made = pcall(f, x, y, Splice.B)
    if ok and made and ItemDB[made] then
        pcall(function() Refs.Inv:remove(Splice.B, 1) end)
        if Refs.SetTile then pcall(Refs.SetTile, "fg", x, y, made, true) end -- ganti di layar saja
        Splice.Made += 1
        Splice.Status = ("Splice jadi %s (%d,%d)"):format(itemName(made), x, y)
        return true
    end
    return false, "ditolak server"
end

-- Kerjakan 1 tile: tanam A (kalau kosong) lalu splice B
local function spliceTile(t)
    local A = Splice.A
    if fgIdAt(t.x, t.y) == 0 then
        if invCount(A) <= 0 then return false end
        sendSetTile("fg", t.x, t.y, A)
        pcall(function() Refs.Inv:remove(A, 1) end)
        Splice.Planted += 1
        Splice.Status = ("Tanam %s (%d,%d)"):format(itemName(A), t.x, t.y)
        if not waitAuto(Splice.Ms) then return false end
    end
    if fgIdAt(t.x, t.y) ~= A then
        skipTile(Splice.Skip, t.idx, 30)
        return true
    end
    local ok, why = spliceOnce(t.x, t.y)
    if not ok then
        SpliceFail[t.idx] = (SpliceFail[t.idx] or 0) + 1
        skipTile(Splice.Skip, t.idx, 60)
        Splice.Status = ("Gagal splice (%d,%d): %s"):format(t.x, t.y, tostring(why))
    end
    waitAuto(Splice.Ms)
    return true
end

local function spliceWorkInReach(s)
    local w = Refs.World
    local W = w.w
    local R = farmReach() - 0.08
    local cx, cy = s.x, s.y - 0.475
    local now = os.clock()
    local st = workspace:GetServerTimeNow()
    local list = {}
    for ty = math.max(0, floor(cy - R - 0.5)), math.min(floor(cy + R + 0.5), w.h - 1) do
        for tx = math.max(0, floor(cx - R - 0.5)), math.min(floor(cx + R + 0.5), W - 1) do
            if stateReaches(s, tx, ty, R) then
                local idx = ty * W + tx
                if Splice.Row.y == ty and not skipped(Splice.Skip, idx, now) and spliceKind(tx, ty, st) then
                    list[#list + 1] = { x = tx, y = ty, idx = idx }
                end
            end
        end
    end
    table.sort(list, function(a, b)
        if a.x ~= b.x then return a.x < b.x end
        return a.y < b.y
    end)
    local done = 0
    for _, t in ipairs(list) do
        if not Splice.Roaming or not alive() then return done end
        local cur = playerState()
        if not cur or not stateReaches(cur, t.x, t.y, R) then return done end
        if not spliceTile(t) then return done end
        done += 1
    end
    return done
end

-- Tile kerja berikutnya: rapi per baris (baris yang sedang dikerjakan / terdekat),
-- dari kiri ke kanan
local function spliceScan(px, py, maxN, filter)
    local w = Refs.World
    local W, H = w.w, w.h
    local now = os.clock()
    local st = workspace:GetServerTimeNow()
    local rows = {} -- [y] = tile kerja paling kiri di baris itu
    local scanned = 0
    for y = 0, H - 1 do
        for x = 0, W - 1 do
            local idx = y * W + x
            if not rows[y] and not skipped(Splice.Skip, idx, now) and spliceKind(x, y, st) then
                if filter and not filter[idx] then
                    skipTile(Splice.Skip, idx, 60)
                else
                    rows[y] = { x = x, y = y, idx = idx }
                end
            end
        end
        scanned += W
        if scanned > 6000 then
            scanned = 0
            task.wait()
            if not Splice.Roaming then return {} end
        end
    end
    local lock, pick, pk = Splice.Row.y, nil, nil
    for y, t in pairs(rows) do
        local k = (y == lock) and -1 or math.abs(y - py)
        if not pick or k < pk or (k == pk and y < pick.y) then pick, pk = t, k end
    end
    Splice.Row.y = pick and pick.y or nil
    return pick and { pick } or {}
end

local function spliceRoamLoop(runId)
    while Splice.Roaming and Splice.Running and alive() and Splice.RunId == runId do
        task.wait()
        local w = Refs.World
        local s = playerState()
        if not w or not s or s.dead then
            releaseInput()
            Splice.Status = "Menunggu karakter / world..."
            task.wait(0.5)
            continue
        end
        if not s.grounded then
            releaseInput()
            continue
        end
        releaseInput()
        local a, b = spliceInv()
        if b <= 0 then
            if Splice.stop then Splice.stop("Seed habis") end
            break
        end
        -- 1) kerjakan yang terjangkau
        if spliceWorkInReach(s) > 0 then continue end
        -- 2) jalan ke tile terdekat
        local R = farmReach() - 0.35
        local sx, sy = startNode(s)
        local px, py = floor(s.x), floor(s.y - 0.475)
        local targets = spliceScan(px, py, 8, reachFilter(sy * w.w + sx, R, false))
        if not Splice.Roaming or not alive() then break end
        if #targets == 0 then
            Splice.Status = (a <= 0) and "Seed A habis, tidak ada pohon A yang bisa di-splice"
                or "Menunggu: tidak ada tempat tanam / pohon untuk di-splice"
            if not waitAuto(1000) then break end
            continue
        end
        travelGroup(sx, sy, targets, R, false, Splice.Skip, SpliceFail)
    end
    releaseInput()
end

local function startSpliceRoam()
    if not OrigIsDown then AutoInput.bindMenu() end
    if not OrigIsDown then return AutoInput.Error or "Kontrol gerak game belum terhubung" end
    table.clear(Splice.Row)
    if not playerState() then return "Kamu belum masuk world" end
    if not Refs.Trees then findTreeRefs() end
    table.clear(Splice.Skip)
    table.clear(SpliceFail)
    table.clear(BadEdge)
    Splice.Roaming = true
    autoBegin()
    local id = Splice.RunId
    task.spawn(function()
        local ok, e = pcall(spliceRoamLoop, id)
        if not ok then
            warn("[Zekio Supreme Premium] Splice error: " .. tostring(e))
            if Splice.Running and Splice.stop then Splice.stop("Error: " .. tostring(e)) end
        end
    end)
    return nil
end

local function stopSpliceRoam()
    Splice.Roaming = false
    autoEnd()
    releaseInput()
end

-- Jalan ke 1 tile tertentu (dipakai Penjaga: balik ke posisi Auto Farm).
-- Pakai A* yang sama, tanpa taruh block.
local function walkTo(tx, ty, maxSec, cancel)
    local w = Refs.World
    if not w or not OrigIsDown then return false end
    if tx < 0 or ty < 0 or tx >= w.w or ty >= w.h then return false end
    Move.Homing = true
    autoBegin()
    local goal = { [ty * w.w + tx] = true }
    local t0, ok = os.clock(), false
    while alive() and Move.Homing and os.clock() - t0 < (maxSec or 30) do
        if cancel and cancel() then break end
        local s = playerState()
        if not s or s.dead then
            task.wait(0.3) -- tunggu respawn / world selesai dimuat
        else
            local sx, sy = startNode(s)
            if sx == tx and sy == ty and s.grounded then
                ok = true
                break
            end
            local path = astar(sx, sy, goal, tx, ty, 0.5, false)
            if not path then break end -- tidak ada jalan
            if #path > 0 then
                local _, why = followPath(path, cancel)
                if why == "cancelled" then break end
            end
            releaseInput()
            task.wait(0.15)
        end
    end
    Move.Homing = false
    autoEnd()
    return ok
end

---------------------------------------------------------------------
-- LAHAN: bentuk farm world
---------------------------------------------------------------------
-- Baris block dari Y atas ke bawah, selalu 1 tile kosong di antaranya (tempat pohon & jalan).
-- Jumlah baris otomatis: turun terus menembus tanah sampai bedrock. Kalau bedrock jatuh di baris
-- lahan, bedrock itu jadi lantai baris terakhir (tanah tepat di atas bedrock ikut digali).
-- (tanah di celah baris digali Bangun Lahan, tanah di baris lahan dipakai sebagai lahan).
-- Kedua ujung baris dibuat tangga (lihat landCols).
-- Hasil disimpan sebentar (dipanggil sangat sering oleh Pabrik / status).
local function landRows()
    local w = Refs.World
    if not w then return {} end
    local x0 = math.clamp(math.floor(math.min(Land.X0, Land.X1)), 0, w.w - 1)
    local x1 = math.clamp(math.floor(math.max(Land.X0, Land.X1)), 0, w.w - 1)
    local y0 = math.max(1, math.floor(Land.Y0))
    local c = Land.Cache
    local now = os.clock()
    if c and c.w == w and c.x0 == x0 and c.x1 == x1 and c.y0 == y0 and now - c.at < 2 then
        return c.rows
    end
    local rows = {}
    local span = x1 - x0 + 1
    -- block yang tidak bisa dipecah (bedrock dll)
    local function hard(x, y)
        local id = fgIdAt(x, y)
        if id == 0 then return false end
        local it = ItemDB[id]
        return it ~= nil and it.solid == true and not canBreak(id)
    end
    local y = y0
    while y <= w.h - 2 and #rows < 40 do
        local hg, hr = 0, 0
        for x = x0, x1 do
            if hard(x, y - 1) then hg += 1 end
            if hard(x, y) then hr += 1 end
        end
        if hg * 2 > span then break end -- celahnya bedrock: berhenti
        rows[#rows + 1] = y
        if hr * 2 > span then break end -- baris ini bedrock: jadi lantai paling bawah
        y += 2
    end
    Land.Cache = { w = w, x0 = x0, x1 = x1, y0 = y0, at = now, rows = rows }
    return rows
end

-- Tile lahan sudah jadi? (block padat apa saja, bukan pohon / lava / duri)
function Build.done(x, y)
    local id = fgIdAt(x, y)
    if id == 0 then return false end
    local it = ItemDB[id]
    if not it or it.kind == "seed" or not it.solid then return false end
    return not (it.deadly or it.hurts or it.laser)
end

-- Kolom block baris ke-k (0 = paling atas). Tangga 2 kolom di KIRI dan KANAN:
--   baris ke-1, 3, 5.. : x0+1 .. x1-1              (kolom x0 & x1 kosong)
--   baris ke-2, 4, 6.. : x0, x0+2 .. x1-2, x1      (kolom x0+1 & x1-1 kosong)
-- Jadi dari ujung mana saja bisa turun (jatuh 2 tile ke anak tangga di bawahnya)
-- dan naik (lompat 2 tile), selang-seling seperti tangga.
local function landCols(k)
    local w = Refs.World
    local x0 = math.clamp(math.floor(math.min(Land.X0, Land.X1)), 0, w.w - 1)
    local x1 = math.clamp(math.floor(math.max(Land.X0, Land.X1)), 0, w.w - 1)
    local cols = {}
    if x1 - x0 < 4 then -- terlalu sempit untuk tangga
        for x = x0, x1 do cols[#cols + 1] = x end
    elseif k % 2 == 0 then
        for x = x0 + 1, x1 - 1 do cols[#cols + 1] = x end
    else
        cols[#cols + 1] = x0
        for x = x0 + 2, x1 - 2 do cols[#cols + 1] = x end
        cols[#cols + 1] = x1
    end
    return cols
end

local function inLandRect(x, y)
    local rows = landRows()
    if #rows == 0 then return false end
    local x0 = math.min(Land.X0, Land.X1)
    local x1 = math.max(Land.X0, Land.X1)
    return x >= x0 and x <= x1 and y >= rows[1] - 1 and y <= rows[#rows]
end

-- Tile block lahan: [idx] = true
local function landBlockSet()
    local set = {}
    local w = Refs.World
    if not w then return set end
    for k, y in ipairs(landRows()) do
        for _, x in ipairs(landCols(k - 1)) do set[y * w.w + x] = true end
    end
    return set
end

-- Tile tanam lahan (di atas block yang sudah terpasang): [idx] = true
local function landPlantSet()
    local set = {}
    local w = Refs.World
    if not w then return set end
    for k, y in ipairs(landRows()) do
        for _, x in ipairs(landCols(k - 1)) do
            if fgIdAt(x, y) ~= 0 and y - 1 >= 0 then set[(y - 1) * w.w + x] = true end
        end
    end
    return set
end

-- Hitung kebutuhan block lahan (+ sisa tile yang harus digali)
local function landInfo(blockId, P0, carve0)
    local info = { rows = 0, total = 0, need = 0, done = 0, blocked = 0, carve = 0 }
    local w = Refs.World
    if not w then return info end
    local rows = landRows()
    info.rows = #rows
    for k, y in ipairs(rows) do
        for _, x in ipairs(landCols(k - 1)) do
            info.total += 1
            if Build.done(x, y) then
                info.done += 1
            else
                info.need += 1
                if fgIdAt(x, y) ~= 0 then info.blocked += 1 end -- pohon / lava dll: dipecah dulu lalu dipasang
            end
        end
    end
    if carve0 then
        info.carve = #carve0
    else
        local P = P0 or (Build.plan and Build.plan())
        if P then info.carve = #Build.carveList(P) end
    end
    return info
end

-- Seed <-> block (seed biasanya id block + 1, kecuali item khusus yang punya seedId)
local function seedOfBlock(block)
    local it = block and ItemDB[block]
    if not it then return nil end
    local sid = it.seedId or (block + 1)
    local sd = ItemDB[sid]
    if sd and sd.kind == "seed" then return sid end
    return nil
end

local function blockOfSeed(seed)
    if not seed then return nil end
    local b = seed - 1
    local it = ItemDB[b]
    if it and it.kind ~= "seed" and (it.seedId == nil or it.seedId == seed) then return b end
    return nil
end

-- Hitungan menunggu dan tile acuan memakai waktu matang paling awal yang
-- masih ada. Menanam tile baru tidak mereset waktu tile sebelumnya.
local function readyTreeCount(whole, only, skip)
    local w = Refs.World
    if not w then return 0 end
    local st = workspace:GetServerTimeNow()
    local x0, x1, y0, y1 = 0, w.w - 1, 0, w.h - 1
    if not whole then
        local rows = landRows()
        if #rows == 0 then return 0 end
        x0 = math.max(0, math.min(Land.X0, Land.X1))
        x1 = math.min(w.w - 1, math.max(Land.X0, Land.X1))
        y0, y1 = math.max(0, rows[1] - 1), rows[#rows]
    end
    local n, nxt, first, missing = 0, nil, nil, 0
    for y = y0, y1 do
        for x = x0, x1 do
            local id = fgIdAt(x, y)
            if id ~= 0 and (not only or id == only) then
                local ra = treeReadyAt(x, y, id)
                if ra then
                    local idx = y * w.w + x
                    if not first or ra < first.at or (ra == first.at and idx < first.idx) then
                        first = { x = x, y = y, id = id, idx = idx, at = ra }
                    end
                    if st >= ra then
                        if not skip or not skipped(skip, y * w.w + x) then n += 1 end
                    elseif not nxt or ra - st < nxt then
                        nxt = ra - st
                    end
                elseif ItemDB[id] and ItemDB[id].kind == "seed" then
                    missing += 1
                end
            end
        end
    end
    return n, nxt, first, missing
end

---------------------------------------------------------------------
-- PABRIK
---------------------------------------------------------------------
-- Fase (berputar terus):
--   PANEN : panen semua pohon siap di lahan (berhenti kalau block / seed hampir 200)
--   AMBIL : pungut block yang sesuai seed pilihan dari hasil panen di world ini
--   BREAK : jalan ke posisi break, Auto Farm di tile pabrik; jeda saat pohon siap.
--   TANAM : setelah break, tanam seed di semua tile lahan yang kosong
--   Pohon siap didahulukan selama inventori masih punya ruang hasil panen.
--   TUNGGU: tunggu pohon siap, lalu kembali ke PANEN
--   Kapan saja seed >= batas drop -> pergi drop (seed - sisakan), lalu pulang.
-- Inventori maksimal 200 per item, jadi semua fase dijaga supaya tidak penuh.
-- Drop yang jatuh di tempat drop tidak di-collect lagi.
local BOOT_SEEDS = 10 -- (mode produksi) cukup seed segini untuk mulai tanam
local CAP = 190       -- batas aman jumlah item (maksimal 200 per item)

local function pabrikCfg(o, harvest, plant)
    local plantSet, area = nil, nil
    if not o.whole then
        plantSet = landPlantSet()
        area = inLandRect
    end
    return {
        run = o.live,
        harvest = harvest,
        pabrikFast = Pabrik.Fast,
        pabrikHarvest = harvest, -- jangkauan dan jalur panen Pabrik
        plant = plant and invCount(o.seed) > 0,
        seed = o.seed,
        skip = Pabrik.Skip,
        hms = Pabrik.Fast and 140 or Farmer.HarvestMs,
        pms = Pabrik.Fast and 140 or Farmer.PlantMs,
        area = area,
        plantSet = plantSet,
        exclude = o.exclude,
        row = Pabrik.Row,
        collect = not harvest, -- panen dahulu; perjalanan ambil block punya fase sendiri
        status = function(t) Pabrik.Status = t end,
        harvestRoom = function() return invCount(o.seed) < CAP - 20 and invCount(o.block) < CAP - 20 end,
        onHarvest = function() Pabrik.Harvested += 1 end,
        onPlant = function() Pabrik.Planted += 1 end,
        yieldHarvest = (not harvest and plant) and function() return Pabrik.wantHarvest(o) end or nil,
    }
end

-- Baca pohon aktual setiap 250 ms. Countdown hanya untuk status, bukan
-- alasan menahan panen sampai satu sesi break / tanam habis.
function Pabrik.wantHarvest(o)
    if not o.live() or not alive() or Pabrik.Traveling then return false end
    if invCount(o.seed) >= CAP - 20 or invCount(o.block) >= CAP - 20 then return false end
    local now, w = os.clock(), Refs.World
    if not w then return false end
    if now < (o.harvestRetryAt or 0) then return false end
    if o.readyWorld ~= w or o.readyWhole ~= o.whole or now >= (o.readyCheckAt or 0) then
        o.readyCount = readyTreeCount(o.whole, nil, Pabrik.Skip)
        o.readyWorld, o.readyWhole, o.readyCheckAt = w, o.whole, now + 0.25
    end
    return (o.readyCount or 0) > 0
end

-- Satu pengambilan block per langkah. Jumlah yang benar-benar masuk tas
-- menjadi acuan, bukan hilangnya drop atau keberhasilan berjalan saja.
function Pabrik.takeBlocks(o)
    local w = Refs.World
    local function live() return o.live() and alive() and Refs.World == w and not Pabrik.Traveling end
    if not w or not live() then return "cancelled" end
    if Pabrik.wantHarvest(o) then return "harvest" end
    if o.takeWorld ~= w or o.takeBlock ~= o.block then
        o.takeWorld, o.takeBlock, o.takeSkip = w, o.block, {}
        o.takePending, o.takeUnreadable = false, false
    end
    o.takePending, o.takeUnreadable = false, false
    if invCount(o.block) >= CAP then return "full" end
    if Refs.Inv then
        local okr, room = pcall(function() return Refs.Inv:room(o.block) end)
        if okr and type(room) == "number" and room <= 0 then return "full" end
    end
    if not Drops.list then pcall(findDropRefs) end -- tanpa pemindaian getgc
    if not Drops.list then
        o.takeUnreadable = true
        o.takeStatus = "Daftar drop block belum terbaca; tekan Hubungkan ke game"
        Pabrik.Status = o.takeStatus
        return "none"
    end
    local s, now = playerState(), os.clock()
    if not s or s.dead then return "cancelled" end
    local best, distance
    local zone = Pabrik.Zone
    if zone and zone.world ~= rawget(w, "name") then zone = nil end
    for _, d in ipairs(Drops.snapshot()) do
        if d.id == o.block and d.n > 0 and not d.display
            and d.x >= 0 and d.y >= 0 and d.x < w.w and d.y < w.h
            and not solidAt(floor(d.x), floor(d.y))
            and (o.whole or inLandRect(floor(d.x), floor(d.y)))
            and not (zone and abs(d.x - zone.x) <= 2.5 and abs(d.y - zone.y) <= 2.5) then
            o.takePending = true
            if canTry(d, now) and (not o.takeSkip[d.uid] or now >= o.takeSkip[d.uid]) then
                local dx, dy = d.x - s.x, d.y - (s.y - 0.475)
                local dd = dx * dx + 4 * dy * dy
                if not distance or dd < distance then best, distance = d, dd end
            end
        end
    end
    if not best then
        o.takeStatus = o.takePending and "Block belum masuk tas; coba pengambilan lagi sebentar" or nil
        return "none"
    end
    local before = invCount(o.block)
    local function cancel()
        return not live() or invCount(o.block) > before or Pabrik.wantHarvest(o)
    end
    local function takeNearby()
        if cancel() or State.CollectMode ~= "Remote" or Drops.key(Drops.list, best) == nil
            or not canTry(best, os.clock()) then return end
        local cur, R = playerState(), (State.CollectRadius or 3) + 0.2
        if cur and abs(best.x - cur.x) <= R and abs(best.y - (cur.y - 0.475)) <= R then
            pcall(takeDrop, best)
        end
    end
    o.takeStatus = ("Ambil block %s di (%d,%d)"):format(itemName(o.block), floor(best.x), floor(best.y))
    Pabrik.Status = o.takeStatus
    takeNearby()
    if live() and invCount(o.block) <= before and not Pabrik.wantHarvest(o) then
        pcall(Move.visitDrop, best, cancel)
    end
    releaseInput()
    if not live() then return "cancelled" end
    if Pabrik.wantHarvest(o) then return "harvest" end
    takeNearby()
    local untilAt = os.clock() + 0.6
    while live() and not Pabrik.wantHarvest(o) and invCount(o.block) <= before
        and best.taking and os.clock() < untilAt do
        task.wait(0.05)
    end
    if not live() then return "cancelled" end
    if Pabrik.wantHarvest(o) then return "harvest" end
    local got = invCount(o.block) - before
    if got > 0 then
        Pabrik.BlocksTaken = (Pabrik.BlocksTaken or 0) + got
        o.takeStatus = ("Block masuk tas +%d; siapkan sesi break"):format(got)
        Pabrik.Status = o.takeStatus
        return "picked", got
    end
    o.takeSkip[best.uid] = os.clock() + 3
    o.takeStatus = "Block belum masuk tas; coba drop lain sebelum lanjut break"
    Pabrik.Status = o.takeStatus
    return "waiting"
end

-- Break block di posisi pabrik (pakai Auto Farm dengan tile & block pabrik)
local function pabrikBreak(o)
    if Pabrik.wantHarvest(o) then return true, "harvest" end
    if os.clock() < (Pabrik.BreakFailUntil or 0) then return false end
    local s = playerState()
    if not s then return false end
    local hx, hy = startNode(s)
    if hx ~= Pabrik.BreakX or hy ~= Pabrik.BreakY then
        Pabrik.Status = ("Jalan ke posisi break (%d,%d)"):format(Pabrik.BreakX, Pabrik.BreakY)
        if not walkTo(Pabrik.BreakX, Pabrik.BreakY, 45, function()
            return not o.live() or Pabrik.wantHarvest(o)
        end) then
            if Pabrik.wantHarvest(o) then return true, "harvest" end
            if not o.live() then return false end
            Pabrik.Status = "Gagal jalan ke posisi break, dicoba lagi nanti"
            Pabrik.BreakFailUntil = os.clock() + 30
            return false
        end
    end
    if not o.live() then return false end
    if Pabrik.wantHarvest(o) then return true, "harvest" end
    State.Override = { offsets = Pabrik.Tiles, block = o.block, mode = "Place + Break" }
    State.Quiet = true
    State.WaitingDrops, State.WorkReason = nil, nil
    table.clear(HitCount)
    table.clear(PlacedAt)
    State.Running = true
    State.RunId = (State.RunId or 0) + 1
    local id = State.RunId
    local acts0 = State.Placed + State.Broken
    local lastActs, lastActAt = acts0, os.clock()
    local harvestInterrupt = false
    task.spawn(function() -- pengawas sesi break
        while State.Running and State.RunId == id do
            task.wait(0.25)
            if not State.Running or State.RunId ~= id then break end
            local sd = invCount(o.seed)
            local acts = State.Placed + State.Broken
            if acts ~= lastActs then lastActs, lastActAt = acts, os.clock() end
            if Pabrik.wantHarvest(o) then
                harvestInterrupt = true
                Pabrik.Status = "Pohon siap, jeda break lalu panen"
                State.Running = false
                break
            end
            if not o.live() or sd >= CAP
                or (o.drop and Pabrik.Drop and sd >= Pabrik.DropAt)
                or (o.breakMode ~= "always" and sd >= BOOT_SEEDS)
                or (not Drops.WorkBusy and os.clock() - lastActAt > 8) then -- 8 detik tidak ada place / pukul: jangan diam di sini
                State.Running = false
            end
        end
    end)
    Pabrik.CollectReason = nil
    Pabrik.Status = "Break " .. itemName(o.block) .. " di posisi pabrik"
    local ok, e = pcall(farmLoop, id)
    if not ok then warn("[Zekio Supreme Premium] Pabrik break error: " .. tostring(e)) end
    State.Running = false
    State.Override = nil
    State.Quiet = false
    if not harvestInterrupt and State.Placed + State.Broken == acts0 and invCount(o.block) > 0 then
        Pabrik.CollectReason = State.WaitingDrops and State.WorkReason or nil
        Pabrik.BreakFailUntil = os.clock() + (Pabrik.CollectReason and 2 or 60)
        Pabrik.Status = Pabrik.CollectReason or "Sesi break tanpa aksi: cek posisi & tile break (dicoba lagi 1 menit)"
    end
    return true, harvestInterrupt and "harvest" or nil
end

-- "WORLD" / "WORLD:ID" / ":ID" -> nama world, id pintu
local function parseDropTarget()
    local raw = tostring(Pabrik.DropWorld or ""):gsub("%s", "")
    local name, door = string.match(raw, "^([^:]*):(.+)$")
    if not name then name = raw end
    name = string.upper(name):gsub("[^A-Z0-9]", "")
    if door == "" then door = nil end
    return name, door
end

-- Pindah world (lewat menu game), bisa langsung ke pintu tertentu
local function goWorld(name, door)
    if Guard.worldName() ~= "" then
        Guard.leaveWorld()
        task.wait(2)
    end
    if door and Refs.World then rawset(Refs.World, "arriveDoor", door) end
    local ok, err = Guard.enterWorld(name)
    if ok then
        task.wait(1.5)
        Guard.afterEnter()
    end
    return ok, err
end

-- Drop pakai fungsi drop game (item jatuh di depan karakter)
local function dropItems(id, n, live)
    local world, inventory = Refs.World, Refs.Inv
    local hud = Refs.Hud
    local f = hud and rawget(hud, "onDrop")
    if type(f) ~= "function" then return 0, "fungsi drop game tidak ketemu" end
    local wanted, gotTotal, flipped = math.max(0, math.floor(n)), 0, false
    local function valid() return live() and alive() and Refs.World == world and Refs.Inv == inventory end
    while gotTotal < wanted and valid() do
        local before = invCount(id)
        if before <= 0 then return gotTotal, "Item tersisa di tas tidak mencukupi untuk drop" end
        local amount = math.min(wanted - gotTotal, before, 200)
        local ok, accepted, detail = pcall(f, id, amount)
        if not ok then return gotTotal, "Drop gagal: " .. tostring(accepted):sub(1, 160) end
        if not valid() then return gotTotal, "Drop dibatalkan karena world / sesi berubah" end
        local message = type(detail) == "string" and detail or (type(accepted) == "string" and accepted or "")
        local lower = string.lower(message)
        if accepted == false and (lower:find("full", 1, true) or lower:find("penuh", 1, true)
            or lower:find("too many", 1, true)) then
            return gotTotal, "Drop ditolak game: " .. message
        end
        local ping = 0.1
        pcall(function() ping = LocalPlayer:GetNetworkPing() end)
        local deadline, stableAt, candidate = os.clock() + math.clamp(1 + 3 * ping, 1.5, 3), nil, 0
        repeat
            task.wait(0.05)
            if not valid() then return gotTotal, "Drop dibatalkan karena world / sesi berubah" end
            local delta = math.max(0, before - invCount(id))
            if delta > 0 and delta <= amount then
                if delta ~= candidate then candidate, stableAt = delta, os.clock() end
                if stableAt and os.clock() - stableAt >= 0.4 then break end
            else candidate, stableAt = 0, nil end
        until os.clock() >= deadline and (not stableAt or os.clock() - stableAt >= 0.4)
        if candidate > 0 and stableAt and os.clock() - stableAt >= 0.4 then
            gotTotal = gotTotal + candidate
            if gotTotal < wanted then task.wait(0.35) end
        elseif accepted == false and not flipped then
            -- Retry a facing change only after an explicit rejection. A void
            -- response might still be in flight, so it must never be duplicated.
            flipped = true
            local st, was = playerState(), AutoInput.active
            local right = st and (st.facing or 1) < 0
            AutoInput.active, AutoInput.right, AutoInput.left = true, right, not right
            task.wait(0.06)
            releaseInput()
            AutoInput.active = was and valid()
            task.wait(0.3)
        else
            return gotTotal, "Drop belum dikonfirmasi; world/tile mungkin penuh atau tidak ada izin. Item tersisa tetap di tas"
        end
    end
    if not valid() then return gotTotal, "Drop dibatalkan" end
    return gotTotal, nil
end


-- Titik drop bersama (dipakai Pabrik dan Auto Farm):
-- pergi ke titik drop (bisa world lain / WORLD:ID), drop item, lalu pulang ke world asal.
-- items = { { id =, n = }, ... }  -> it.got diisi jumlah yang berhasil di-drop
-- Hasil: ok, alasan ("nopoint" | "home" | teks error)
local function dropTrip(items, live, say)
    say = say or function() end
    local name, door = parseDropTarget()
    local home = Guard.worldName()
    if name == "" then name = home end
    if Pabrik.DropX < 0 and not door and name == home then
        say("Titik drop belum diatur (tab Titik Drop), drop dilewati")
        return false, "nopoint"
    end
    Pabrik.Traveling = true
    local pendingUntil = os.clock() + 2
    while live() and Drops.Pool and Drops.Pool.busy > 0 and os.clock() < pendingUntil do task.wait(0.05) end
    if not live() or (Drops.Pool and Drops.Pool.busy > 0) then
        Pabrik.Traveling = false
        autoEnd()
        return false, "Collect belum selesai / sesi dihentikan; drop ditunda"
    end
    local away = name ~= home
    local ok, why = true, nil
    if away or door then
        say("Pergi ke " .. name .. (door and (":" .. door) or "") .. " untuk drop")
        local okw, err = goWorld(name, door)
        if not okw then ok, why = false, "gagal masuk " .. name .. " (" .. tostring(err) .. ")" end
    end
    if ok and live() and Pabrik.DropX >= 0 then
        say(("Jalan ke posisi drop (%d,%d)"):format(Pabrik.DropX, Pabrik.DropY))
        if not walkTo(Pabrik.DropX, Pabrik.DropY, 60) then ok, why = false, "tidak bisa jalan ke posisi drop" end
    end
    if ok and live() then
        local s = playerState()
        if s then Pabrik.Zone = { world = Guard.worldName(), x = s.x, y = s.y - 0.475 } end
        for _, it in ipairs(items) do
            if not live() then break end
            local got, err = dropItems(it.id, it.n, live)
            it.got = got
            if got > 0 then
                local msg = ("Drop %s x%d di %s"):format(itemName(it.id), got, Guard.worldName())
                say(msg)
                notify("Drop", msg, 4)
                Hook.send("pabrik", msg)
            end
            if err then
                ok, why = false, err
                break
            end
        end
    end
    if not live() then ok, why = false, "Drop dibatalkan" end
    if not ok then
        say("Drop gagal: " .. tostring(why))
        notify("Drop", "Drop gagal: " .. tostring(why), 5)
        Hook.send("pabrik", "Drop gagal: " .. tostring(why))
    end
    -- pulang ke world asal
    if away and home ~= "" and live() then
        say("Pulang ke " .. home)
        local okh = goWorld(home, nil)
        if not okh and live() then
            task.wait(5)
            okh = goWorld(home, nil)
        end
        if not okh then
            Pabrik.Traveling = false
            autoEnd()
            return false, "home"
        end
    end
    Pabrik.Traveling = false
    autoEnd()
    return ok, why
end
Auto.dropTrip = dropTrip

-- Titik drop sudah diatur? (posisi, WORLD:ID, atau world lain)
function Pabrik.pointSet()
    if Pabrik.DropX >= 0 then return true end
    local name, door = parseDropTarget()
    if door then return true end
    return name ~= "" and name ~= Guard.worldName()
end

local function pabrikDrop(seed, n, live)
    local items = { { id = seed, n = n } }
    local ok, why = dropTrip(items, live, function(t) Pabrik.Status = t end)
    Pabrik.Dropped += items[1].got or 0
    if why == "home" then
        if Pabrik.stop then Pabrik.stop("Gagal pulang ke world pabrik " .. tostring(Pabrik.Home)) end
    elseif not ok then
        Pabrik.DropError = tostring(why)
        Pabrik.DropOffUntil = os.clock() + ((why == "nopoint") and 60 or 120)
    else
        Pabrik.DropError, Pabrik.DropOffUntil = nil, 0
    end
end

-- Auto Farm: seed hasil break sudah banyak -> jeda, drop seed ke titik drop,
-- balik ke posisi farm, lalu lanjut lagi (dicek tiap 2 detik)
task.spawn(function()
    while alive() do
        task.wait(2)
        local seed = State.SelectedId and seedOfBlock(State.SelectedId)
        if State.Running and State.SeedDrop~=false and not State.Override and Pabrik.pointSet() and not State.DropPause and not Drops.WorkBusy
            and (not Drops.Pool or Drops.Pool.busy == 0) and seed
            and os.clock() >= (State.DropOffUntil or 0) then
            local n = invCount(seed)
            local s = playerState()
            if s and n >= State.SeedDropAt and n > State.SeedKeep then
                local hx, hy = startNode(s)
                local runId = State.RunId
                local function live() return State.Running and alive() and State.RunId == runId end
                State.DropPause = true
                task.wait(0.8) -- tunggu pukulan terakhir selesai
                local items = { { id = seed, n = n - State.SeedKeep } }
                local ok, why = dropTrip(items, live, function(t) State.LastAction = t end)
                State.Dropped += items[1].got or 0
                if not ok then
                    State.DropError = tostring(why)
                    State.DropOffUntil = os.clock() + ((why == "nopoint") and 60 or 120)
                else State.DropError, State.DropOffUntil = nil, 0 end
                if why == "home" then
                    stopFarm("Gagal pulang ke world farm")
                elseif live() then
                    State.LastAction = ("Jalan balik ke posisi farm (%d,%d)"):format(hx, hy)
                    if not walkTo(hx, hy, 60) then
                        stopFarm("Gagal balik ke posisi farm, Auto Farm dihentikan")
                    else
                        State.LastAction = State.DropError and ("Drop tertunda: " .. State.DropError) or "Lanjut Auto Farm"
                    end
                end
                State.DropPause = false
            end
        end
    end
end)

local PHASE_NAME = { panen = "PANEN", ambil = "AMBIL BLOCK", tanam = "TANAM", ["break"] = "BREAK", tunggu = "TUNGGU" }

local function breakReady()
    return Pabrik.BreakX >= 0 and next(Pabrik.Tiles) ~= nil and os.clock() >= (Pabrik.BreakFailUntil or 0)
end

-- 1 langkah pabrik. o = { seed, block, drop, breakMode, whole, exclude, live, phase }
-- Hasil: "drop" | "work" | "take" | "move" | "wait" | "break" | "next" | "idle" (+ detik ke pohon siap)
local function pabrikStep(o)
    if not o.live() or not alive() then return "wait" end
    local seeds, blocks = invCount(o.seed), invCount(o.block)
    o.phase = o.phase or "panen"
    Pabrik.Phase = PHASE_NAME[o.phase]
    -- drop seed lebihan (kapan saja)
    if o.drop and Pabrik.Drop and seeds >= Pabrik.DropAt and seeds > Pabrik.Keep
        and os.clock() >= (Pabrik.DropOffUntil or 0) then
        pabrikDrop(o.seed, seeds - Pabrik.Keep, o.live)
        return "drop"
    end

    if o.phase ~= "panen" and Pabrik.wantHarvest(o) then
        o.phase = "panen"
        Pabrik.Phase = "PANEN"
        Pabrik.Status = "Pohon siap, lanjut panen"
    end

    if o.phase == "panen" then
        -- 1x panen bisa kena beberapa pohon, jadi sisakan ruang ~20 item
        if blocks >= CAP - 20 or seeds >= CAP - 20 then
            o.phase = "ambil"
            return "next"
        end
        FC = pabrikCfg(o, true, false)
        local r = fieldStep()
        if r == "idle" then
            o.readyCheckAt = 0 -- target yang baru dilewati harus dibaca ulang
            if (o.readyCount or 0) > 0 then
                -- Jalur belum tersedia: beri fase lain kesempatan, lalu cek lagi.
                o.harvestRetryAt = os.clock() + 1
                Reach = nil
            end
            o.idleAt = os.clock()
            o.phase = "ambil"
            return "next"
        end
        return r
    end

    if o.phase == "ambil" then
        local r = Pabrik.takeBlocks(o)
        if r == "harvest" then o.phase = "panen"; return "next" end
        if r == "cancelled" then return "wait" end
        if r == "picked" then return "take" end
        if r == "waiting" then
            waitAuto(200)
            return "wait"
        end
        o.phase = "break"
        return "next"
    end

    if o.phase == "break" then
        local want
        if o.breakMode == "always" then
            want = blocks > 0 and seeds < CAP
        else -- mode produksi: break hanya untuk dapat seed awal
            local _, nxt = readyTreeCount(o.whole)
            want = blocks > 0 and seeds < BOOT_SEEDS and nxt == nil
        end
        if want and breakReady() then
            local ok, why = pabrikBreak(o)
            if ok then
                if why == "harvest" then
                    o.phase = "panen"
                    return "next"
                end
                o.phase = "tanam"
                return "break"
            end
        end
        o.phase = "tanam"
        return "next"
    end

    if o.phase == "tanam" then
        if seeds > 0 then
            FC = pabrikCfg(o, false, true)
            local r = fieldStep()
            if r == "harvest" then o.phase = "panen"; return "next" end
            if r ~= "idle" then return r end
        end
        o.plantAt = os.clock()
        o.takeCheckAt = os.clock() + 1
        o.phase = "tunggu"
        return "next"
    end

    -- tunggu
    local n, nxt = readyTreeCount(o.whole)
    if o.breakMode == "always" and blocks > 0 and seeds < CAP and breakReady() then
        o.phase = "ambil"
        return "next"
    end
    if (seeds > 0 and os.clock() - (o.plantAt or 0) > 10)
        or (blocks < CAP and os.clock() >= (o.takeCheckAt or 0)) then
        -- Drop block yang masih di world diperiksa sebelum break / tanam lagi.
        o.takeCheckAt = os.clock() + 1
        o.phase = "ambil"
        return "next"
    end
    return "idle", nxt, n
end

local function waitText(sec)
    sec = math.max(0, math.ceil(sec or 0))
    if sec >= 60 then return ("%dm %dd"):format(sec // 60, sec % 60) end
    return sec .. " dtk"
end

function Pabrik.harvestStatus()
    if not Refs.World then return "Belum masuk world" end
    if not Refs.Trees then return "Waktu pohon belum terbaca" end
    local n, _, first, missing = readyTreeCount(Pabrik.WholeWorld)
    local suffix = (missing or 0) > 0 and (" | waktu %d pohon belum terbaca"):format(missing) or ""
    if not first then return "Belum ada waktu pohon terbaca" .. suffix end
    local remaining = math.max(0, first.at - workspace:GetServerTimeNow())
    local status = n > 0 and (n .. " pohon READY") or ("siap " .. waitText(remaining))
    return ("%s | acuan (%d,%d) %s%s"):format(status, first.x, first.y, itemName(first.id), suffix)
end

local function pabrikLoop(runId)
    local function live() return Pabrik.Running and alive() and Pabrik.RunId == runId end
    local o = { seed = Pabrik.SeedId, block = Pabrik.BlockId, drop = true, breakMode = "always", live = live }
    while live() do
        task.wait()
        o.whole = Pabrik.WholeWorld
        if not Refs.Trees then
            Pabrik.Status = "Mencari data waktu pohon; panen belum dapat diperiksa"
            if os.clock() >= (o.nextTreeScan or 0) then
                o.nextTreeScan = os.clock() + 10
                pcall(findTreeRefs)
            end
            if not Refs.Trees then
                if not waitAuto(500) then break end
                continue
            end
        end
        local here = Guard.worldName()
        if not Pabrik.Traveling and Pabrik.Home ~= "" and here ~= Pabrik.Home then
            Pabrik.Status = "Bukan di world pabrik (" .. Pabrik.Home .. "), menunggu..."
            task.wait(2)
            continue
        end
        local r, nextReady, nReady = pabrikStep(o)
        if r ~= "idle" then o.stuckAt = nil end
        if r == "idle" then
            local seeds, blocks = invCount(o.seed), invCount(o.block)
            if not nextReady and (nReady or 0) == 0 and seeds <= 0 and blocks <= 0
                and not o.takePending and not o.takeUnreadable then
                if Pabrik.stop then Pabrik.stop("Seed & block habis, tidak ada pohon tumbuh") end
                break
            end
            if (nReady or 0) > 0 then
                -- ada pohon siap tapi tidak terjangkau: lama-lama reset daftar lewati & jalur
                o.stuckAt = o.stuckAt or os.clock()
                if os.clock() - o.stuckAt > 30 then
                    o.stuckAt = nil
                    table.clear(Pabrik.Skip)
                    table.clear(BadEdge)
                    Reach = nil
                end
            end
            if seeds >= CAP - 20 and not (Pabrik.Drop and Pabrik.pointSet()) then
                Pabrik.Status = ("Seed hampir penuh (%d): atur titik drop & nyalakan Auto drop seed"):format(seeds)
            elseif (nReady or 0) > 0 then
                Pabrik.Status = nReady .. " pohon siap belum terjangkau, dicoba lagi"
            elseif seeds <= 0 and blocks <= 0 and (o.takePending or o.takeUnreadable) then
                Pabrik.Status = o.takeStatus or "Menunggu block hasil panen yang bisa diambil"
            elseif nextReady then
                Pabrik.Status = "Menunggu pohon siap ±" .. waitText(nextReady)
            elseif blocks > 0 and (Pabrik.BreakX < 0 or next(Pabrik.Tiles) == nil) then
                Pabrik.Status = "Ada block tapi posisi / tile break belum diatur"
            elseif seeds > 0 then
                Pabrik.Status = "Dirt Farm penuh, menunggu"
            else
                Pabrik.Status = "Menunggu..."
            end
            if not waitAuto(250) then break end
        end
    end
    releaseInput()
end

function Pabrik.stop(reason)
    Pabrik.Running = false
    Pabrik.Traveling = false
    if State.Override then State.Running = false end
    autoEnd()
    releaseInput()
    Pabrik.Status = reason or "Dihentikan"
    if UI.PabrikToggle then pcall(function() UI.PabrikToggle:Set(false) end) end
    if reason then
        notify("Pabrik", reason, 5)
        if not string.find(reason, "^Dihentikan") then Hook.send("pabrik", "Pabrik berhenti: " .. reason) end
    end
end

function Pabrik.start()
    if Pabrik.Running then return end
    local err
    local block = blockOfSeed(Pabrik.SeedId)
    if not Refs.World then
        err = "Data world belum ketemu. Tekan 'Hubungkan ke game'"
    elseif not OrigIsDown and not AutoInput.bindMenu() then
        err = AutoInput.Error or "Kontrol gerak game belum terhubung"
    elseif not playerState() then
        err = "Kamu belum masuk world"
    elseif not Pabrik.SeedId then
        err = "Pilih seed pabrik dulu"
    elseif not block then
        err = "Block dari seed ini tidak ketemu"
    elseif not Pabrik.WholeWorld and #landRows() == 0 then
        err = "Atur Dirt Farm dulu (tab Dirt Farm)"
    end
    if err then
        notify("Pabrik", err, 4)
        if UI.PabrikToggle then pcall(function() UI.PabrikToggle:Set(false) end) end
        return
    end
    if State.Running and not State.Override then stopFarm("Dihentikan karena Pabrik dimulai") end
    if Clear.Running then stopClear("Dihentikan karena Pabrik dimulai") end
    if Farmer.Running then stopFarmer("Dihentikan karena Pabrik dimulai") end
    if Splice.Running and Splice.stop then Splice.stop("Dihentikan karena Pabrik dimulai") end
    if not Refs.Trees then findTreeRefs() end
    Pabrik.BlockId = block
    Pabrik.Home = Guard.worldName()
    table.clear(Pabrik.Skip)
    table.clear(Pabrik.Row)
    table.clear(BadEdge)
    Pabrik.DropOffUntil, Pabrik.BreakFailUntil = 0, 0
    Pabrik.Running = true
    Pabrik.RunId = (Pabrik.RunId or 0) + 1
    Pabrik.Status = "Mulai: panen ready -> ambil block -> break -> tanam"
    autoBegin()
    if UI.PabrikToggle then pcall(function() UI.PabrikToggle:Set(true) end) end
    local id = Pabrik.RunId
    task.spawn(function()
        local ok, e = pcall(pabrikLoop, id)
        if not ok then
            warn("[Zekio Supreme Premium] Pabrik error: " .. tostring(e))
            if Pabrik.Running then Pabrik.stop("Error: " .. tostring(e)) end
        end
    end)
end

---------------------------------------------------------------------
-- VENDING
---------------------------------------------------------------------
-- Mode "Isi stock dari drop":
--   1. Pergi ke titik drop vending (WORLD / WORLD:ID, kosong = world ini), tunggu di sana sampai ada drop
--      item yang dijual vending-mu (atau item apa saja kalau ada vending kosong), pungut (sentuhan badan).
--   2. Pulang ke world vending, tambah stock ke vending yang menjual item itu / masukkan ke vending kosong.
--   3. Ulangi. Pindah world hanya kalau ada yang dibawa (hemat, tidak bolak-balik terus).
-- Mode "Kosongkan sampai habis":
--   Ambil isi semua vending milikmu. Tas penuh / semua sudah diambil -> pergi ke titik drop vending,
--   drop semua, pulang, lanjut sampai semua vending kosong.
-- Aksi vending lewat fungsi game (World.vendCall), karakter harus berdiri di depan mesin.
local VEND_STOCK, VEND_EMPTY = "Isi stock dari drop", "Kosongkan sampai habis"
Vend.Fail = {} -- vending yang gagal diambil isinya: [x,y] = jumlah gagal

function Vend.point()
    local raw = tostring(Vend.Point or ""):gsub("%s", "")
    local name, door = string.match(raw, "^([^:|]*)[:|](.+)$")
    if not name then name = raw end
    name = string.upper(name):gsub("[^A-Z0-9]", "")
    if door == "" then door = nil end
    return name, door
end

-- Vending milikmu di world ini: { x, y, fg, id, stock, cap }
function Vend.machines()
    local w = Refs.World
    local out = {}
    if not w then return out end
    local vends = rawget(w, "vends")
    local owner = rawget(w, "vendOwner")
    for y = 0, w.h - 1 do
        local row = w.fg[y]
        if row then
            for x = 0, w.w - 1 do
                local id = row[x] or 0
                local it = id ~= 0 and ItemDB[id]
                if it and it.vend then
                    local okO, mine = true, true
                    if type(owner) == "function" then okO, mine = pcall(owner, x, y) end
                    if okO and mine then
                        local d = nil
                        if type(vends) == "table" and type(vends.get) == "function" then
                            local okD, v = pcall(vends.get, x, y)
                            if okD and type(v) == "table" then d = v end
                        end
                        d = d or {}
                        if not d.shop then
                            out[#out + 1] = {
                                x = x, y = y, fg = id, id = d.id, stock = tonumber(d.stock) or 0,
                                cap = (id == 9268) and 10398 or 5199,
                            }
                        end
                    end
                end
            end
        end
    end
    return out
end

-- Item ini boleh diproses? (pilihan jenis + daftar item; tool & lock tidak pernah)
-- Bisa masuk vending? (gems, tool, lock, item tidak bisa ditrade, mesin vending: tidak)
function Vend.sellable(id)
    if type(id) ~= "number" or id == 112 then return false end
    local it = ItemDB[id]
    if not it or it.kind == "tool" then return false end
    if it.lock or it.area or it.guildLock or it.untradeable or it.vend or it.hub then return false end
    local nm = tostring(it.name or ""):lower()
    if nm == "gems" or nm == "gem" then return false end
    return true
end

function Vend.allow(id)
    if not Vend.sellable(id) then return false end
    if #Vend.Items > 0 and not table.find(Vend.Items, id) then return false end
    return true
end

function Vend.filtered()
    return #Vend.Items > 0
end

-- Pilihan item untuk dropdown: item di vending, di tas, drop yang pernah terlihat, dan yang sudah dipilih
function Vend.labels(machines)
    local seen = Vend.Seen
    local st = { inv = 0, drop = 0, vend = 0 }
    for _, m in ipairs(machines or {}) do
        if m.id then
            seen[m.id] = true
            st.vend += 1
        end
    end
    -- isi tas: baca slot inventori (sama seperti dropdown block / seed)
    if Refs.Inv then
        local okS, slots = pcall(function() return Refs.Inv.slots end)
        if okS and type(slots) == "table" then
            for _, slot in pairs(slots) do
                local id = type(slot) == "table" and tonumber(slot.id) or nil
                if id and (tonumber(slot.n) or 1) > 0 then
                    seen[id] = true
                    st.inv += 1
                end
            end
        end
    end
    -- drop di world ini
    local list = Drops.list
    if type(list) == "table" then
        local n, ids = 0, {}
        for _, d in pairs(list) do
            n += 1
            if n > 600 then break end
            local id = type(d) == "table" and tonumber(d.id) or nil
            if id and not ids[id] then
                ids[id] = true
                seen[id] = true
                st.drop += 1
            end
        end
    end
    for _, id in ipairs(Vend.Items) do seen[id] = true end
    local ids = {}
    for id in pairs(seen) do
        if Vend.sellable(id) then ids[#ids + 1] = id end
    end
    table.sort(ids)
    local labels, picked = {}, {}
    for _, id in ipairs(ids) do
        local label = ("%s [%d]"):format(tostring(itemName(id)), id)
        labels[#labels + 1] = label
        if table.find(Vend.Items, id) then picked[#picked + 1] = label end
    end
    return labels, picked, st
end

function Vend.call(...)
    local w = Refs.World
    local f = w and rawget(w, "vendCall")
    if type(f) ~= "function" then return false end
    local ok, res = pcall(f, ...)
    return ok and res == true
end

-- Berdiri di depan vending (aturan game: <= 0.85 tile mendatar, sebaris)
function Vend.goTo(m)
    local function near(c)
        return c ~= nil and math.abs(c.x - (m.x + 0.5)) <= 0.84 and math.abs((c.y - 0.5) - (m.y + 0.5)) <= 0.58
    end
    if near(playerState()) then return true end
    if walkTo(m.x, m.y, 40) and near(playerState()) then return true end
    for _, dx in ipairs({ -1, 1 }) do
        if walkTo(m.x + dx, m.y, 30) then
            local t0 = os.clock()
            AutoInput.active = true
            while alive() and os.clock() - t0 < 1 do
                task.wait()
                local c = playerState()
                if not c then break end
                steerX(c, m.x + 0.5 + dx * 0.55, 0.06)
                if near(c) and c.grounded then break end
            end
            releaseInput()
            if near(playerState()) then return true end
        end
    end
    return false
end

function Vend.sortNear(list)
    local s = playerState()
    if not s then return list end
    table.sort(list, function(a, b)
        local da = math.abs(a.x + 0.5 - s.x) + 2 * math.abs(a.y + 1 - s.y)
        local db = math.abs(b.x + 0.5 - s.x) + 2 * math.abs(b.y + 1 - s.y)
        return da < db
    end)
    return list
end

-- Tambah stock HANYA dari item hasil pungut (Vend.Picked = jumlahnya), bukan barang lain di tas.
-- Item hasil pungut yang belum punya vending -> vending kosong.
function Vend.stockAll(live)
    local list = Vend.sortNear(Vend.machines())
    local selling = {}
    for _, m in ipairs(list) do
        if m.id and m.stock > 0 then selling[m.id] = true end
    end
    local done, tried = 0, 0
    for _, m in ipairs(list) do
        if not live() then break end
        local id = (m.id and m.stock > 0) and m.id or nil
        if id and not Vend.allow(id) then id = nil end
        local n = 0
        if id then
            -- vending yang sudah menjual item ini: semua isi tas ikut di-stock
            n = math.min(invCount(id), m.cap - m.stock)
        elseif not (m.id and m.stock > 0) then
            -- vending kosong: item pilihan yang ada di tas, atau (tanpa pilihan) item hasil pungut
            local cands = {}
            if #Vend.Items > 0 then
                for _, pid in ipairs(Vend.Items) do cands[#cands + 1] = pid end
            else
                for pid, cnt in pairs(Vend.Picked) do
                    if cnt > 0 then cands[#cands + 1] = pid end
                end
                table.sort(cands)
            end
            for _, pid in ipairs(cands) do
                if not selling[pid] and Vend.allow(pid) and invCount(pid) > 0 then
                    id = pid
                    break
                end
            end
            if id then
                n = math.min(invCount(id), m.cap)
                if #Vend.Items == 0 then n = math.min(n, Vend.Picked[id] or 0) end
            end
        end
        if id and n > 0 then
            tried += 1
            Vend.Status = ("Ke vending (%d,%d): tambah %s x%d"):format(m.x, m.y, itemName(id), n)
            if Vend.goTo(m) then
                if Vend.call("stock", m.x, m.y, id, n) then
                    selling[id] = true
                    if Vend.Picked[id] then
                        Vend.Picked[id] -= n
                        if Vend.Picked[id] <= 0 then Vend.Picked[id] = nil end
                    end
                    Vend.Stocked += n
                    done += n
                    Vend.Status = ("Stock %s +%d di (%d,%d)"):format(itemName(id), n, m.x, m.y)
                    task.wait(0.3)
                else
                    Vend.Status = ("Gagal tambah stock di (%d,%d)"):format(m.x, m.y)
                    task.wait(0.5)
                end
            else
                Vend.Status = ("Tidak bisa ke vending (%d,%d)"):format(m.x, m.y)
            end
        end
    end
    return done, tried
end

-- Item yang dicari untuk diisi: yang dijual vending & belum penuh.
-- Vending kosong: boleh diisi item baru (maksimal sejumlah vending kosong, item yang vendingnya penuh tidak diambil).
function Vend.wanted()
    local want, sold, empty = {}, {}, 0
    for _, m in ipairs(Vend.machines()) do
        if m.id and m.stock > 0 then
            sold[m.id] = true
            if m.stock < m.cap and Vend.allow(m.id) then want[m.id] = true end
        else
            empty += 1
        end
    end
    return want, empty, sold
end

-- Pindah world (lewat menu game); world sama & tanpa pintu = tidak pindah
function Vend.travel(name, door)
    if name == Guard.worldName() and not door then return true end
    Vend.Traveling = true
    local called, ok, err = pcall(goWorld, name, door)
    Vend.Traveling = false
    if not called then return false, tostring(ok) end
    if ok then
        -- tunggu karakter muncul di world tujuan (bukan jeda tetap)
        local t0 = os.clock()
        while os.clock() - t0 < 4 and not (playerState() and Guard.worldName() == name) do task.wait(0.1) end
        task.wait(0.2)
    end
    return ok, err
end

-- Pungut drop item yang dicari di world ini (sentuhan badan, per baris). Hasil: jumlah item terambil.
function Vend.pickHere(live, want, empty, sold)
    local before = {} -- jumlah di tas sebelum item itu dipungut (dicatat saat drop-nya pertama dilihat)
    local newIds = 0
    for id, cnt in pairs(Vend.Picked) do
        if not sold[id] and cnt > 0 and invCount(id) > 0 then newIds += 1 end
    end
    local function wantId(d)
        if not Vend.allow(d.id) then return false end
        if not want[d.id] then
            if sold[d.id] or empty <= 0 then return false end -- vending item ini penuh / tidak ada vending kosong
            if before[d.id] == nil and not (Vend.Picked[d.id] and invCount(d.id) > 0) then
                if newIds >= empty then return false end -- vending kosong sudah "dipesan" item lain
                newIds += 1
            end
        end
        if before[d.id] == nil then before[d.id] = invCount(d.id) end
        return true
    end
    Move.NoZone = true -- drop yang di-drop Pabrik di titik drop boleh diambil
    Move.fetchDrops(live, 999, wantId, 240)
    Move.NoZone = false
    local got = 0
    for id, n in pairs(before) do
        local diff = invCount(id) - n
        if diff > 0 then
            got += diff
            Vend.Picked[id] = (Vend.Picked[id] or 0) + diff
        end
    end
    return got
end

-- Drop semua hasil kosongkan vending di titik drop vending, lalu pulang
function Vend.dropTrip(live, home)
    local name, door = Vend.point()
    if name == "" then name = home end
    local items = {}
    for id, cnt in pairs(Vend.Carry) do -- hanya jumlah yang diambil dari vending (barang lain di tas tidak ikut)
        local n = math.min(cnt, invCount(id))
        if n > 0 then items[#items + 1] = { id = id, n = n } end
    end
    if #items == 0 then return true end
    Vend.Status = "Pergi ke titik drop " .. name .. (door and (":" .. door) or "")
    local ok, err = Vend.travel(name, door)
    if not ok then
        Vend.Status = "Gagal ke titik drop: " .. tostring(err)
        return false
    end
    if not Vend.goSpot(live) then return false end
    for _, it in ipairs(items) do
        if not live() then break end
        local got, derr = dropItems(it.id, it.n, live)
        Vend.Dropped += got
        if got > 0 then
            local msg = ("Drop %s x%d di %s"):format(itemName(it.id), got, Guard.worldName())
            Vend.Status = msg
            Hook.send("pabrik", "Vending: " .. msg)
        end
        if derr then Vend.Status = "Drop: " .. tostring(derr) end
    end
    if Guard.worldName() ~= home and live() then
        Vend.Status = "Pulang ke " .. home
        local okh = Vend.travel(home, nil)
        if not okh and live() then
            task.wait(5)
            okh = Vend.travel(home, nil)
        end
        if not okh then return false, "home" end
    end
    return true
end

-- Jalan ke posisi drop vending yang disimpan (kalau diatur)
function Vend.goSpot(live)
    if Vend.DropX < 0 or not live() then return true end
    local s = playerState()
    if s then
        local hx, hy = startNode(s)
        if hx == Vend.DropX and hy == Vend.DropY then return true end
    end
    Vend.Status = ("Jalan ke posisi drop vending (%d,%d)"):format(Vend.DropX, Vend.DropY)
    if walkTo(Vend.DropX, Vend.DropY, 60) then return true end
    Vend.Status = ("Tidak bisa jalan ke posisi drop vending (%d,%d)"):format(Vend.DropX, Vend.DropY)
    return false
end

-- Drop yang kamu buang sendiri baru bisa dipungut setelah karakter menjauh (aturan game: armed).
-- Kalau berdiri di atas / dekat drop sendiri item yang dicari: geser 2-4 tile, tunggu sebentar.
function Vend.stepAway(live)
    local s = playerState()
    local list = Drops.list
    if not s or type(list) ~= "table" or not live() then return false end
    local near = false
    for _, d in pairs(list) do
        if type(d) == "table" and d.armed == false and type(d.x) == "number" and type(d.y) == "number"
            and Vend.allow(d.id) and math.abs(d.x - s.x) < 1.8 and math.abs(d.y - (s.y - 0.5)) < 1.8 then
            near = true
            break
        end
    end
    if not near then return false end
    local hx, hy = startNode(s)
    for _, dx in ipairs({ 3, -3, 2, -2, 4, -4 }) do
        if not live() then return false end
        Vend.Status = "Menjauh dari drop sendiri supaya bisa dipungut"
        if walkTo(hx + dx, hy, 8) then
            Vend.sleep(0.6, live)
            return true
        end
    end
    return false
end

-- Setelah pindah world: tunggu data world & vending termuat (maks 12 dtk). Hasil: daftar vending
function Vend.waitWorld(home, live)
    local t0 = os.clock()
    local list = {}
    while live() and os.clock() - t0 < 25 do
        if Guard.worldName() == home and playerState() then
            list = Vend.machines()
            if #list > 0 then return list end
        end
        task.wait(0.5)
    end
    return list
end

-- Titik drop diatur? (world lain / pintu / posisi XY)
function Vend.hasPoint()
    local name, door = Vend.point()
    return name ~= "" or door ~= nil or Vend.DropX >= 0
end

-- Gangguan sementara (ping tinggi, server telat, gagal pindah world): coba lagi dengan jeda
-- yang makin panjang. Baru berhenti setelah 8x gagal berturut-turut. Hasil: true = lanjut.
function Vend.soft(reason, live)
    Vend.Soft = (Vend.Soft or 0) + 1
    if Vend.Soft > 8 then
        Vend.stop(reason)
        return false
    end
    Vend.Status = reason .. (" - coba lagi %d/8"):format(Vend.Soft)
    Vend.sleep(math.min(2 + Vend.Soft * 2, 15), live)
    return live()
end

-- tunggu (bisa dihentikan)
function Vend.sleep(sec, live)
    local t0 = os.clock()
    while live() and os.clock() - t0 < sec do task.wait(0.25) end
end

local function vendLoop(runId)
    local function live() return Vend.Running and alive() and Vend.RunId == runId end
    local home = Guard.worldName()
    Vend.Home = home
    Vend.Soft = 0
    if #Vend.waitWorld(home, live) == 0 then
        if live() then Vend.stop("Tidak ada vending milikmu di world ini (jalankan di world vending)") end
        return
    end
    while live() do
        task.wait()
        if Vend.Mode == VEND_EMPTY then
            -- ===== kosongkan =====
            if Guard.worldName() ~= home then
                if not Vend.travel(home, nil) then
                    if not Vend.soft("Gagal pulang ke world vending " .. home, live) then break end
                    continue
                end
            end
            local hasPoint = Vend.hasPoint()
            local list = {}
            local all = Vend.waitWorld(home, live)
            if #all == 0 and live() then
                if not Vend.soft("Vending milikmu di " .. home .. " tidak terbaca", live) then break end
                pcall(goWorld, home, nil) -- masuk ulang supaya data world termuat
                continue
            end
            local skipped = {}
            for _, m in ipairs(all) do
                if m.id and m.stock > 0 then
                    if not Vend.allow(m.id) then
                        skipped[#skipped + 1] = itemName(m.id) .. " x" .. m.stock
                    elseif (Vend.Fail[m.x .. "," .. m.y] or 0) < 4 then
                        list[#list + 1] = m
                    end
                end
            end
            if #list == 0 and not Vend.Confirm then
                -- cek sekali lagi sebentar lagi (data stock dari server bisa telat)
                Vend.Confirm = true
                Vend.Status = "Cek ulang isi vending..."
                Vend.sleep(1.5, live)
                continue
            end
            Vend.Confirm = false
            if #list == 0 then
                -- selesai: bawa sisa ke titik drop (kalau diatur)
                if hasPoint and next(Vend.Carry) then
                    local ok, why = Vend.dropTrip(live, home)
                    if why == "home" or not ok then
                        if not Vend.soft(why == "home" and ("Gagal pulang ke world vending " .. home)
                            or ("Vending kosong, tapi drop gagal: " .. Vend.Status), live) then break end
                        continue
                    end
                    Vend.Soft = 0
                end
                table.clear(Vend.Carry)
                if next(Vend.Fail) then
                    Vend.stop("Selesai, ada vending yang gagal diambil")
                elseif #skipped > 0 then
                    Vend.stop("Item terpilih sudah habis. Tidak diambil (bukan item terpilih): "
                        .. table.concat(skipped, ", ", 1, math.min(#skipped, 4))
                        .. ((#skipped > 4) and (" +" .. (#skipped - 4)) or "")
                        .. ". Hapus pilihan item untuk ambil semua")
                else
                    Vend.stop("Semua vending sudah kosong")
                end
                break
            end
            local full = false
            for _, m in ipairs(Vend.sortNear(list)) do
                if not live() then break end
                local room = 200
                if Refs.Inv then
                    local okr, r = pcall(function() return Refs.Inv:room(m.id) end)
                    if okr and type(r) == "number" then room = r end
                end
                if room <= 0 then
                    full = true
                    break
                end
                Vend.Status = ("Ke vending (%d,%d): ambil %s"):format(m.x, m.y, itemName(m.id))
                local key = m.x .. "," .. m.y
                if Vend.goTo(m) then
                    local before = invCount(m.id)
                    local okc = Vend.call("empty", m.x, m.y)
                    task.wait(0.4)
                    local got = invCount(m.id) - before
                    if got > 0 then
                        Vend.Soft = 0
                        Vend.Taken += got
                        Vend.Carry[m.id] = (Vend.Carry[m.id] or 0) + got
                        Vend.Fail[key] = nil
                        Vend.Status = ("Ambil %s x%d dari (%d,%d)"):format(itemName(m.id), got, m.x, m.y)
                        if got < m.stock then
                            -- tas tidak muat semua: buang dulu ke titik drop, lalu ambil sisanya
                            full = true
                            break
                        end
                    else
                        Vend.Fail[key] = (Vend.Fail[key] or 0) + 1
                        if not okc and next(Vend.Carry) then
                            full = true -- kemungkinan tas penuh: buang dulu ke titik drop
                            break
                        end
                        Vend.sleep(1, live) -- server telat (ping): jeda sebelum coba lagi
                    end
                else
                    Vend.Fail[key] = (Vend.Fail[key] or 0) + 1
                    Vend.Status = ("Tidak bisa ke vending (%d,%d)"):format(m.x, m.y)
                end
            end
            if not live() then break end
            if full then
                if not hasPoint then
                    Vend.stop("Tas penuh: atur titik drop vending (WORLD / WORLD:ID / simpan posisi XY)")
                    break
                end
                if not next(Vend.Carry) then
                    Vend.stop("Tas penuh oleh item lain, kosongkan tas dulu")
                    break
                end
                local ok, why = Vend.dropTrip(live, home)
                if why == "home" or not ok then
                    -- barang tetap dicatat, dicoba drop lagi di putaran berikutnya
                    if not Vend.soft(why == "home" and ("Gagal pulang ke world vending " .. home)
                        or ("Drop gagal: " .. Vend.Status), live) then break end
                    continue
                end
                Vend.Soft = 0
                table.clear(Vend.Carry)
                table.clear(Vend.Fail)
            end
        else
            -- ===== isi stock dari drop =====
            if Guard.worldName() == home then
                Vend.waitWorld(home, live)
                local done, tried = Vend.stockAll(live)
                if not live() then break end
                if tried > 0 and done == 0 then
                    if not Vend.soft("Tambah stock gagal: " .. Vend.Status, live) then break end
                    continue
                else
                    if done > 0 then Vend.Soft = 0 end
                end
            end
            local want, empty, sold = Vend.wanted()
            if not next(want) and empty == 0 then
                Vend.Status = Vend.filtered() and "Vending item terpilih penuh / belum ada yang menjual item terpilih"
                    or "Semua vending penuh / belum ada vending yang menjual item"
                Vend.sleep(4, live)
                continue
            end
            local name, door = Vend.point()
            if name == "" then name = home end
            if Guard.worldName() ~= name or door then
                if not (Guard.worldName() == name and Vend.AtPoint) then
                    Vend.Status = "Pergi ke " .. name .. (door and (":" .. door) or "") .. " ambil drop"
                    local ok, err = Vend.travel(name, door)
                    if not ok then
                        Vend.Status = "Gagal ke titik drop: " .. tostring(err)
                        Vend.sleep(10, live)
                        continue
                    end
                    Vend.AtPoint = true
                end
            end
            Vend.goSpot(live)
            -- tunggu di titik drop sampai ada yang bisa diambil (tidak bolak-balik world)
            local got = 0
            while live() do
                Vend.stepAway(live)
                got += Vend.pickHere(live, want, empty, sold)
                local carry = false
                for id in pairs(want) do
                    if invCount(id) > 0 then
                        carry = true
                        break
                    end
                end
                if not carry then
                    for id, cnt in pairs(Vend.Picked) do
                        if cnt > 0 and invCount(id) > 0 then
                            carry = true
                            break
                        end
                    end
                end
                if carry then break end
                Vend.Status = "Menunggu drop baru di " .. Guard.worldName() .. "..."
                Vend.sleep(0.5, live)
            end
            if not live() then break end
            Vend.AtPoint = false
            if Guard.worldName() ~= home then
                Vend.Status = "Pulang ke " .. home .. " untuk isi stock"
                local okh = Vend.travel(home, nil)
                if not okh then
                    if not Vend.soft("Gagal pulang ke world vending " .. home, live) then break end
                    continue
                end
            end
        end
    end
    releaseInput()
end

function Vend.stop(reason)
    Vend.Running = false
    Vend.AtPoint = false
    Move.NoZone = false
    autoEnd()
    releaseInput()
    Vend.Status = reason or "Dihentikan"
    Vend.Confirm = false
    if UI.VendToggle then UI.later("vendToggle", function() UI.VendToggle:Set(false) end) end
    if reason then
        notify("Vending", reason, 5)
        if not string.find(reason, "^Dihentikan") then Hook.send("pabrik", "Vending: " .. reason) end
    end
end

function Vend.start()
    if Vend.Running then return end
    local err
    if not Refs.World then
        err = "Data world belum ketemu. Tekan 'Hubungkan ke game'"
    elseif not OrigIsDown and not AutoInput.bindMenu() then
        err = AutoInput.Error or "Kontrol gerak game belum terhubung"
    elseif not playerState() then
        err = "Kamu belum masuk world"
    elseif type(rawget(Refs.World, "vendCall")) ~= "function" then
        err = "Fungsi vending game tidak ketemu"
    end
    if err then
        notify("Vending", err, 4)
        if UI.VendToggle then pcall(function() UI.VendToggle:Set(false) end) end
        return
    end
    if State.Running and not State.Override then stopFarm("Dihentikan karena Vending dimulai") end
    if Clear.Running then stopClear("Dihentikan karena Vending dimulai") end
    if Farmer.Running then stopFarmer("Dihentikan karena Vending dimulai") end
    if Splice.Running and Splice.stop then Splice.stop("Dihentikan karena Vending dimulai") end
    if Pabrik.Running then Pabrik.stop("Dihentikan karena Vending dimulai") end
    if Build.Running and Build.stop then Build.stop("Dihentikan karena Vending dimulai") end
    table.clear(Vend.Carry)
    table.clear(Vend.Picked)
    table.clear(Vend.Fail)
    table.clear(BadEdge)
    Vend.FailRuns = 0
    Vend.AtPoint = false
    Vend.Running = true
    Vend.RunId = (Vend.RunId or 0) + 1
    Vend.Status = "Mulai..."
    autoBegin()
    if UI.VendToggle then pcall(function() UI.VendToggle:Set(true) end) end
    local id = Vend.RunId
    task.spawn(function()
        local ok, e = pcall(vendLoop, id)
        if not ok then
            warn("[Zekio Supreme Premium] Vending error: " .. tostring(e))
            if Vend.Running then Vend.stop("Error: " .. tostring(e)) end
        end
    end)
end
Auto.VEND_MODES = { VEND_STOCK, VEND_EMPTY }

---------------------------------------------------------------------
-- BANGUN LAHAN
---------------------------------------------------------------------
-- Cara kerja (sama seperti bikin farm manual di world baru yang penuh tanah):
--   1. GALI    : dari permukaan sampai bawah (tepat di atas bedrock), seperti ular.
--                Celah 1 tile di atas tiap baris digali (tempat pohon & jalan), ujung kiri
--                & kanan dibuka bergantian jadi tangga, background tanah ikut dipecah.
--                Tanah di baris lahan dibiarkan = sudah jadi lahan.
--   2. PASANG  : baris yang masih kosong (di atas permukaan) dipasang dari BAWAH ke atas.
--                Block pertama dipasang dari ujung tangga, lalu baris itu jadi jembatan:
--                berdiri di ujungnya, pasang block ke depan satu-satu, maju, sampai ujung.
--   3. PRODUKSI: block habis -> ambil dulu drop block sisa galian di lahan, lalu tanam 1 baris,
--                pasang-pecah block di KANAN karakter untuk dapat seed (seperti Pabrik),
--                collect, panen. Sampai 190 block -> lanjut pasang, sisakan 10 block.
--   4. BERSIH  : semua drop yang tertinggal di lahan dicari (scan) lalu didatangi pakai A*.
local BuildFail = {}

function Build.protectedTile(x, y)
    local spawn = Refs.World and Refs.World.spawn
    return (spawn and x == spawn.X and y == spawn.Y) or Refs.protectedItem(fgIdAt(x, y))
end

local function overlapsPlayer(x, y, s)
    return x + 1 > s.x - 0.3 and x < s.x + 0.3 and y + 1 > s.y - 0.95 and y < s.y
end

local function placeBuild(t, s)
    local id = Build.BlockId
    if invCount(id) <= (Build.Reserve or 0) or overlapsPlayer(t.x, t.y, s) then return false end
    if not placeOk(t.x, t.y) then
        skipTile(Build.Skip, t.idx, 120)
        return false
    end
    sendSetTile("fg", t.x, t.y, id)
    pcall(function() Refs.Inv:remove(id, 1) end)
    Build.Placed += 1
    Build.Status = ("Pasang %s (%d,%d)"):format(itemName(id), t.x, t.y)
    return true
end

-- Rencana lahan: baris, kolom block & lubang tangga tiap baris
function Build.plan()
    local w = Refs.World
    if not w then return nil end
    local rows = landRows()
    if #rows == 0 then return nil end
    local W = w.w
    local P = {
        rows = rows, K = #rows, W = W,
        x0 = math.clamp(math.floor(math.min(Land.X0, Land.X1)), 0, W - 1),
        x1 = math.clamp(math.floor(math.max(Land.X0, Land.X1)), 0, W - 1),
        cols = {}, isLand = {}, holes = {},
    }
    for k = 1, #rows do
        local cols = landCols(k - 1)
        local set = {}
        for _, x in ipairs(cols) do set[x] = true end
        local holes = {}
        for x = P.x0, P.x1 do
            if not set[x] then holes[#holes + 1] = x end
        end
        P.cols[k], P.isLand[k], P.holes[k] = cols, set, holes
    end
    return P
end

-- Permukaan tanah asli: baris pertama yang dia & baris bawahnya sebagian besar padat
function Build.findSurface(P)
    local w = Refs.World
    local span = P.x1 - P.x0 + 1
    local function full(y)
        local n = 0
        for x = P.x0, P.x1 do
            local it = ItemDB[fgIdAt(x, y)]
            if it and it.solid and it.kind ~= "seed" then n += 1 end
        end
        return n * 2 > span
    end
    for y = math.max(0, P.rows[1] - 1), w.h - 2 do
        if full(y) and full(y + 1) then return y end
    end
    return math.huge
end

-- Yang masih harus digali di tile ini: "fg" (tanah / batu / lava), "bg" (background tanah), nil = beres.
-- Pohon & benda tidak padat dibiarkan.
function Build.carveLayer(x, y, W)
    if Build.protectedTile(x, y) then return nil end
    local fg = fgIdAt(x, y)
    if fg ~= 0 then
        local it = ItemDB[fg]
        if it and it.kind ~= "seed" and (it.solid or it.deadly or it.hurts or it.laser or Build.isLava(fg))
            and canBreak(fg) then return "fg" end
        return nil
    end
    if y >= (Build.Surface or math.huge) or Build.Carved[y * W + x] then
        local bg = tileAt("bg", x, y)
        if bg and bg ~= 0 and canBreak(bg) then return "bg" end
    end
    return nil
end

-- Titik awal sesuai posisi pintu: satu tile di bawah batu tepat di bawah spawn.
function Build.spawnStart()
    local w = Refs.World
    local spawn = w and w.spawn
    local x = spawn and tonumber(spawn.X)
    local doorY = spawn and tonumber(spawn.Y)
    if not x or not doorY or x % 1 ~= 0 or doorY % 1 ~= 0 then
        return nil, "Posisi pintu world belum terbaca"
    end
    local y = doorY + 2
    if x < 0 or x >= w.w or y < 0 or y + 1 >= w.h then
        return nil, "Posisi tanah di bawah pintu berada di luar world"
    end
    local base = fgIdAt(x, doorY + 1)
    local rock = ItemDB[base]
    local rockName = rock and string.lower(tostring(rock.name or "")) or ""
    if not rock or not rock.solid or (canBreak(base) and not rockName:find("bedrock", 1, true)) then
        return nil, "Batu di bawah pintu belum dikenali; titik awal tidak digunakan"
    end
    local id = fgIdAt(x, y)
    if id ~= 0 then
        local item = ItemDB[id]
        local name = item and string.lower(tostring(item.name or "")):gsub("<.->", ""):gsub("`.", "") or ""
        if not item or not name:find("%f[%a]dirt%f[%A]") or not canBreak(id) then
            return nil, "Tile di bawah batu bukan Dirt yang dapat digali"
        end
    end
    local x0, x1 = math.min(Land.X0, Land.X1), math.max(Land.X0, Land.X1)
    if x < x0 or x > x1 then return nil, "Posisi pintu di luar X awal dan X akhir Dirt Farm" end
    return { x = x, y = y, idx = y * w.w + x }
end

-- Urutan gali seperti ular, dari atas ke bawah (hanya tile yang masih perlu digali):
--   celah baris ke-1 kiri -> kanan, turun lewat lubang ujung kanan,
--   celah baris ke-2 kanan -> kiri, turun lewat lubang ujung kiri, dst.
--   Lubang di ujung awal dibuka dari celah di bawahnya (supaya tidak terperosok).
--   Lantai lahan di dalam tanah yang bolong (gua) / lava ditambal block sambil lewat.
function Build.carveList(P)
    local W, list = P.W, {}
    local pass, direction
    local function add(x, y, kind)
        if y >= 0 and Build.carveLayer(x, y, W) then
            list[#list + 1] = { x = x, y = y, idx = y * W + x, kind = kind, pass = pass, dir = direction }
        end
    end
    local surf = Build.Surface or math.huge
    local canFill = Build.BlockId ~= nil and invCount(Build.BlockId) > 0
    local function fill(x, y)
        if y < surf then return end
        local id = fgIdAt(x, y)
        local need = false
        if id == 0 then
            need = canFill
        elseif not Build.done(x, y) then
            local it = ItemDB[id]
            need = it ~= nil and it.kind ~= "seed" and (it.deadly or it.hurts or it.laser or Build.isLava(id))
                and canBreak(id) and true or false
        end
        if need then list[#list + 1] = { x = x, y = y, idx = y * W + x, kind = "fill", pass = pass, dir = direction } end
    end
    for k = 1, P.K do
        local y = P.rows[k]
        local d = ((k - 1) % 2 == 0) and 1 or -1
        pass, direction = k, d
        local up = nil -- lubang ujung awal baris di atasnya, dibuka dari celah ini
        if k > 1 and #P.holes[k - 1] > 0 then
            local ph = P.holes[k - 1]
            up = (d == -1) and ph[1] or ph[#ph]
        end
        local a, b = P.x0, P.x1
        if d == -1 then a, b = P.x1, P.x0 end
        local L = P.isLand[k]
        for x = a, b, d do
            if L[x] then fill(x, y) end -- lantai dulu, baru celah di atasnya
            add(x, y - 1, "gap")
            if x == up then add(x, P.rows[k - 1], "hole") end
        end
        -- lubang ujung akhir baris ini = jalan turun ke celah baris bawahnya
        if k < P.K and #P.holes[k] > 0 then
            local h = P.holes[k]
            add((d == 1) and h[#h] or h[1], y, "hole")
        end
    end
    return list
end

-- Lava/bahaya di area Dirt Farm didahulukan, termasuk lava di lantai.
-- Seed dan item yang dilindungi tidak masuk daftar ini.
function Build.isLava(id)
    local it = ItemDB[id]
    if not it or it.kind == "seed" or not canBreak(id) then return false end
    local name = string.lower(tostring(it.name or ""))
    return (it.lava or it.deadly or it.hurts or it.laser
        or string.find(name, "lava", 1, true) or string.find(name, "magma", 1, true)) and true or false
end

function Build.lavaTarget(P, s)
    local w = Refs.World
    P, s = P or Build.ActivePlan, s or playerState()
    if not w or not P or not s or s.dead or not s.grounded then return nil end
    local R, cy = punchReach() - 0.08, s.y - 0.475
    local best, distance
    for y = math.max(0, P.rows[1] - 1, floor(cy - R - 0.5)),
        math.min(w.h - 1, P.rows[P.K], floor(cy + R + 0.5)) do
        for x = math.max(P.x0, floor(s.x - R - 0.5)), math.min(P.x1, floor(s.x + R + 0.5)) do
            if not Build.protectedTile(x, y) and stateReaches(s, x, y, R) and Build.isLava(fgIdAt(x, y)) and canWorkAt(x, y, true) then
                local foot = floor(s.y + 0.01)
                local under = y == foot and x >= floor(s.x - 0.3) and x <= floor(s.x + 0.3 - 0.0001)
                local drop = 0
                if under then drop = fallAfterBreak(s, x, foot) end
                if not under or (drop ~= nil and drop <= 3) then
                    local dx, dy = x + 0.5 - s.x, y + 0.5 - cy
                    local d = dx * dx + dy * dy
                    if not distance or d < distance then
                        best, distance = { x = x, y = y, idx = y * w.w + x, kind = "lava" }, d
                    end
                end
            end
        end
    end
    return best
end

-- Jeda dipakai sebelum pukulan berikutnya, tanpa menambah jeda sesudah tile
-- selesai. Tunggu balasan singkat agar tile yang hilang terlambat tetap dihitung.
function Build.punch(x, y, includeBg, live)
    live = live or function() return Build.Running end
    local w = Refs.World
    local function valid() return live() and alive() and Refs.World == w end
    if not w or not valid() then return nil, "stop" end
    local layer = fgIdAt(x, y) ~= 0 and "fg" or "bg"
    local id = tileAt(layer, x, y)
    if not id or id == 0 or (layer == "bg" and not includeBg) then return "changed" end
    while valid() and os.clock() < (Build.NextPunchAt or 0) do
        local lava = Build.lavaTarget()
        if lava and (lava.x ~= x or lava.y ~= y) and not Build.isLava(id) then return nil, "lava" end
        task.wait(math.min(0.025, Build.NextPunchAt - os.clock()))
    end
    if not valid() then return nil, "stop" end
    if tileAt(layer, x, y) ~= id then return "changed" end
    local s = playerState()
    if not s or s.dead or not s.grounded or not stateReaches(s, x, y, punchReach() - 0.08) then
        return nil, "range"
    end
    local lava = Build.lavaTarget()
    if lava and (lava.x ~= x or lava.y ~= y) and not Build.isLava(id) then return nil, "lava" end
    if type(Refs.Punch) ~= "function" then
        Build.Status = "Fungsi pukul game belum terbaca; tekan Hubungkan ke game"
        return nil, "punch"
    end
    local before = State.Broken
    local result = tryBreak(x, y, includeBg, true)
    if not result then Build.Status = State.LastAction or "Pukulan game gagal; tekan Hubungkan ke game" end
    Build.NextPunchAt = os.clock() + math.max(200, Build.PunchMs or 200) / 1000
    if result == "hit" then
        while valid() and tileAt(layer, x, y) == id and os.clock() < Build.NextPunchAt do
            task.wait(math.min(0.025, Build.NextPunchAt - os.clock()))
        end
        if not valid() then return nil, "stop" end
        if tileAt(layer, x, y) ~= id then
            if State.Broken == before then
                State.Broken += 1
                Drops.brokeAt[x .. "," .. y] = os.clock()
            end
            result = "broke"
        end
    end
    return result
end

function Build.lavaStep(P, live)
    local t = Build.lavaTarget(P)
    if not t then return false end
    if skipped(Build.LavaSkip, t.idx) then
        Build.Status = "Lava masih ada; menunggu pukulan game bisa dicoba lagi"
        waitAuto(100)
        return true
    end
    Build.Status = ("Prioritas lava: %s (%d,%d)"):format(itemName(fgIdAt(t.x, t.y)), t.x, t.y)
    local world, dug = Refs.World, Build.Dug
    local result = Build.carveTile(t, live, true)
    if (result == "done" or result == "fall") and Refs.World == world and Build.Dug > dug
        and not Build.isLava(fgIdAt(t.x, t.y)) then
        Build.LavaCleared = (Build.LavaCleared or 0) + 1
    elseif result == "skip" then
        skipTile(Build.LavaSkip, t.idx, 1)
    end
    return true
end

-- Jalan (A*) ke tempat yang menjangkau salah satu target.
-- maxY = tempat berdiri tidak boleh lebih bawah dari ini, noSelf = jangan berdiri di tile target.
-- Hasil: "move" | "nopath" | "wait"
function Build.goNear(targets, R, maxY, noSelf)
    local w = Refs.World
    local s = playerState()
    if not w or not s then return "wait" end
    if Build.lavaTarget() then return "wait" end
    local sx, sy = startNode(s)
    local goals = { maxY = maxY, noSelf = noSelf }
    for _, t in ipairs(targets) do goals[t.idx] = true end
    local f = targets[1]
    setMoveStatus(("Cari jalan A* ke (%d,%d)"):format(f.x, f.y))
    local path = astar(sx, sy, goals, f.x, f.y, R, false)
    if not path then
        releaseInput()
        return "nopath"
    end
    local fails = BuildFail[f.idx] or 0
    if #path == 0 then
        execWalk(sx, sy) -- sudah di tempat tapi belum terjangkau: rapikan ke tengah tile
        fails += 1
    else
        local ok, why = followPath(path, function()
            return not Build.Running or not alive() or Refs.World ~= w or Build.lavaTarget() ~= nil
        end)
        if why == "cancelled" then releaseInput(); return "wait" end
        if not ok then fails += 1 else fails = 0 end
    end
    releaseInput()
    if fails >= 4 then
        fails = 0
        for _, t in ipairs(targets) do skipTile(Build.Skip, t.idx, 30) end
    end
    BuildFail[f.idx] = (fails > 0) and fails or nil
    return "move"
end

-- Pukul 1 tile sampai bersih (block dulu, lalu background).
-- Hasil: "done" | "fall" (karakter jatuh) | "skip" | "stop"
function Build.carveTile(t, live, onlyFg)
    local w = Refs.World
    if not w then return "stop" end
    local hits, maxHits = 0, nil
    while live() and alive() and Refs.World == w do
        if onlyFg and not Build.isLava(fgIdAt(t.x, t.y)) then return "done" end
        local lava = Build.lavaTarget()
        if not onlyFg and lava and (lava.x ~= t.x or lava.y ~= t.y) then return "lava" end
        local layer = onlyFg and "fg" or Build.carveLayer(t.x, t.y, Refs.World.w)
        if not layer then return "done" end
        local id = (layer == "fg") and fgIdAt(t.x, t.y) or (tileAt("bg", t.x, t.y) or 0)
        maxHits = maxHits or (hitsNeeded(id) * 3 + 6)
        local r, why = Build.punch(t.x, t.y, layer == "bg", live)
        if why == "lava" then return "lava" end
        if why == "stop" then return "stop" end
        if why == "range" then return "fall" end
        if r == nil then
            skipTile(Build.Skip, t.idx, 60)
            return "skip"
        end
        if r == "changed" then
            hits, maxHits = 0, nil
        elseif r == "broke" then
            if layer == "fg" then Build.Carved[t.idx] = true end
            Build.Dug += 1
            Build.Status = ("Gali %s (%d,%d)"):format(itemName(id), t.x, t.y)
            local bt = (Build.BreakTimes[t.idx] or 0) + 1
            Build.BreakTimes[t.idx] = bt
            if bt > 8 then -- server terus mengembalikan tile ini
                skipTile(Build.Skip, t.idx, 120)
                return "skip"
            end
            hits, maxHits = 0, nil
            local s = playerState()
            if not s or not s.grounded then
                return "fall"
            end
        else
            hits += 1
            Build.Status = ("Pukul %s (%d,%d)"):format(itemName(id), t.x, t.y)
            if hits > maxHits then
                skipTile(Build.Skip, t.idx, 45)
                return "skip"
            end
        end
        -- Build.punch menjaga cooldown bersama; tidak ada jeda tambahan di sini.
    end
    return "stop"
end

-- Lantai lahan bolong / lava: pecah dulu kalau perlu, lalu pasang block.
-- Hasil: "done" | "fall" | "skip" | "stop"
function Build.fillTile(t)
    local id = fgIdAt(t.x, t.y)
    if id ~= 0 and not Build.done(t.x, t.y) then
        Build.Status = ("Pecah %s di lantai (%d,%d)"):format(itemName(id), t.x, t.y)
        for _ = 1, 40 do
            local r, why = Build.punch(t.x, t.y, false)
            if why == "lava" then return "lava" end
            if why == "stop" then return "stop" end
            if why == "range" then return "fall" end
            if r == nil then
                skipTile(Build.Skip, t.idx, 60)
                return "skip"
            end
            if r == "broke" then break end
            if fgIdAt(t.x, t.y) == 0 then break end
        end
        local cur = playerState()
        if not cur or not cur.grounded then return "fall" end
    end
    if fgIdAt(t.x, t.y) == 0 then
        local cur = playerState()
        if not cur or invCount(Build.BlockId) <= 0 or not placeBuild(t, cur) then
            skipTile(Build.Skip, t.idx, 30)
            return "skip"
        end
        Build.Status = ("Tambal lantai Dirt Farm (%d,%d)"):format(t.x, t.y)
        if not waitAuto(State.PlaceMs) then return "stop" end
    end
    return "done"
end

-- 1 langkah gali. Hasil: "work" | "move" | "wait" | "none"
function Build.carveStep(P, list, live)
    Build.ActivePlan = P
    local w = Refs.World
    local s = playerState()
    if not w or not s or s.dead then
        releaseInput()
        task.wait(0.5)
        return "wait"
    end
    if not s.grounded then
        releaseInput()
        Move.airCheck(s)
        task.wait()
        return "wait"
    end
    Move.AirAt = nil
    releaseInput()
    if Build.lavaStep(P, live) then return "work" end
    local R = punchReach() - 0.08
    local start = Build.StartTarget
    if start then
        if not Build.carveLayer(start.x, start.y, P.W) then
            Build.StartTarget = nil
        elseif skipped(Build.Skip, start.idx) then
            Build.Status = "Menunggu untuk mencoba lagi tanah di bawah batu"
            task.wait(0.5)
            return "wait"
        elseif not stateReaches(s, start.x, start.y, R) then
            Build.Status = ("Menuju tanah di bawah batu (%d,%d)"):format(start.x, start.y)
            local result = Build.goNear({ start }, math.min(punchReach(), buildReach()) - 0.35, nil, false)
            if result == "nopath" then
                Build.Status = "Belum ada jalan ke tanah di bawah batu"
                task.wait(0.5)
            end
            return result == "nopath" and "wait" or result
        else
            local foot = floor(s.y + 0.01)
            if start.y == foot and start.x >= floor(s.x - 0.3) and start.x <= floor(s.x + 0.3 - 0.0001) then
                local fall = fallAfterBreak(s, start.x, foot)
                if fall == nil or fall > 3 then
                    Build.Status = "Posisi awal terlalu tinggi untuk digali dari sini"
                    task.wait(0.5)
                    return "wait"
                end
            end
            Build.Status = ("Gali tanah pertama (%d,%d)"):format(start.x, start.y)
            local result = Build.carveTile(start, live)
            if result == "done" then Build.StartTarget = nil end
            return "work"
        end
    end
    local now = os.clock()
    local route = Build.Route
    if not route or route.world ~= w or route.x0 ~= P.x0 or route.x1 ~= P.x1 or route.lastY ~= P.rows[P.K] then
        route = { world = w, x0 = P.x0, x1 = P.x1, lastY = P.rows[P.K], pass = 1 }
        Build.Route = route
    end
    local pass, firstPass
    for _, t in ipairs(list) do
        if not skipped(Build.Skip, t.idx, now) and (t.kind == "fill" or Build.carveLayer(t.x, t.y, P.W)) then
            local p = t.pass or 1
            if not firstPass or p < firstPass then firstPass = p end
            if p >= route.pass and (not pass or p < pass) then pass = p end
        end
    end
    pass = pass or firstPass
    if not pass then return "none" end
    route.pass = pass
    local pending, near = {}, {}
    for _, t in ipairs(list) do
        if (t.pass or 1) == pass and not skipped(Build.Skip, t.idx, now) then
            pending[#pending + 1] = t
            if stateReaches(s, t.x, t.y, R) then near[#near + 1] = t end
        end
    end
    -- Selesaikan semua tile terjangkau di lintasan ini. Target jauh di awal
    -- daftar tidak lagi memaksa balik ke ujung baris sebelum bekerja di sini.
    local did = 0
    for _, t in ipairs(near) do
        if did >= 12 or not live() or not alive() or Refs.World ~= w then break end
        if Build.lavaStep(P, live) then return "work" end
        if not skipped(Build.Skip, t.idx, now) then
            local cur = playerState()
            if not cur or cur.dead or not cur.grounded or not stateReaches(cur, t.x, t.y, R) then break end
            if t.kind == "fill" and overlapsPlayer(t.x, t.y, cur) then
                skipTile(Build.Skip, t.idx, 0.5) -- rapikan posisi sesudah target lain selesai
            elseif not canWorkAt(t.x, t.y, true) then
                skipTile(Build.Skip, t.idx, 300) -- dikunci orang lain
            elseif t.kind == "fill" then
                did += 1
                if Build.fillTile(t) ~= "done" then break end
            else
                -- block pijakan sendiri: pecah hanya kalau jatuhnya pendek & aman
                local foot = floor(cur.y + 0.01)
                if t.y == foot and t.x >= floor(cur.x - 0.3) and t.x <= floor(cur.x + 0.3 - 0.0001) then
                    local d = fallAfterBreak(cur, t.x, foot)
                    if d == nil or d > 3 then
                        skipTile(Build.Skip, t.idx, 20)
                        -- tile lain dalam jangkauan tetap boleh dikerjakan
                    else
                        did += 1
                        if Build.carveTile(t, live) ~= "done" then break end
                    end
                else
                    did += 1
                    if Build.carveTile(t, live) ~= "done" then break end
                end
            end
        end
    end
    if did > 0 then return "work" end
    if not live() or not alive() or Refs.World ~= w then return "wait" end
    local cur = playerState() or s
    local dir = pending[1] and pending[1].dir or 1
    table.sort(pending, function(a, b)
        local da = abs(a.x + 0.5 - cur.x) + 2 * abs(a.y + 0.5 - (cur.y - 0.475))
        local db = abs(b.x + 0.5 - cur.x) + 2 * abs(b.y + 0.5 - (cur.y - 0.475))
        if da ~= db then return da < db end
        if a.x ~= b.x then return a.x * dir < b.x * dir end
        return a.kind == "fill" and b.kind ~= "fill"
    end)
    local goals = {}
    for _, t in ipairs(pending) do
        if not skipped(Build.Skip, t.idx) and #goals < 8 then goals[#goals + 1] = t end
    end
    if #goals == 0 then return "none" end
    local r = Build.goNear(goals, math.min(punchReach(), buildReach()) - 0.35, nil, goals[1].kind == "fill")
    if r == "nopath" then
        -- Kelompok ini saja ditunda; jangan tandai seluruh baris gagal.
        for _, t in ipairs(goals) do skipTile(Build.Skip, t.idx, 5) end
        return "move"
    end
    return r
end

-- Tile masuk baris: block di samping lubang tangga (block pertama baris dipasang dari sini)
function Build.entries(P, k)
    local e = {}
    local holes, L = P.holes[k], P.isLand[k]
    if #holes == 0 then
        e[P.x0], e[P.x1] = true, true
    else
        for _, h in ipairs(holes) do
            if L[h - 1] and L[h - 2] then e[h - 1] = true end
            if L[h + 1] and L[h + 2] then e[h + 1] = true end
        end
    end
    return e
end

-- 1 langkah pasang: baris paling BAWAH yang belum lengkap dulu, naik ke atas.
-- Baris yang sedang dipasang jadi jembatan: berdiri di atasnya lalu pasang ke depan.
-- Hasil: "work" | "move" | "wait" | "none"
function Build.placeStep(P)
    Build.ActivePlan = P
    local w = Refs.World
    local s = playerState()
    if not w or not s or s.dead then
        releaseInput()
        task.wait(0.5)
        return "wait"
    end
    if not s.grounded then
        releaseInput()
        Move.airCheck(s)
        task.wait()
        return "wait"
    end
    Move.AirAt = nil
    releaseInput()
    if Build.lavaStep(P, function() return Build.Running end) then return "work" end
    local W = P.W
    local R = buildReach() - 0.08
    local now = os.clock()
    local k, T = nil, nil
    for kk = P.K, 1, -1 do
        local y = P.rows[kk]
        local list = {}
        for _, x in ipairs(P.cols[kk]) do
            local idx = y * W + x
            if not Build.done(x, y) and not skipped(Build.Skip, idx, now) then
                list[#list + 1] = { x = x, y = y, idx = idx }
            end
        end
        if #list > 0 then
            k, T = kk, list
            break
        end
    end
    if not k then return "none" end
    local y = P.rows[k]
    local px = s.x
    table.sort(T, function(a, b) return abs(a.x + 0.5 - px) < abs(b.x + 0.5 - px) end)
    local _, sy = startNode(s)
    local onRow = sy <= y - 1 -- berdiri di atas baris ini (jembatan)
    local under = Build.Under[k] ~= nil and now < Build.Under[k]
    local entry = Build.entries(P, k)
    local hasAny = false
    for _, x in ipairs(P.cols[k]) do
        if Build.done(x, y) then
            hasAny = true
            break
        end
    end

    -- pasang yang terjangkau, yang paling dekat dulu (maks 2 per langkah)
    local done = 0
    for _, t in ipairs(T) do
        if done >= 2 then break end
        local cur = playerState()
        if not cur or not cur.grounded then break end
        if stateReaches(cur, t.x, t.y, R) and (onRow or under or entry[t.x]) then
            if fgIdAt(t.x, t.y) ~= 0 then
                -- tile lahan berisi pohon / lava / hiasan: pecah dulu
                if not canWorkAt(t.x, t.y, true) then
                    skipTile(Build.Skip, t.idx, 300)
                else
                    Build.Status = ("Bersihkan tile Dirt Farm (%d,%d)"):format(t.x, t.y)
                    local broke = false
                    for _ = 1, 40 do
                        local r, why = Build.punch(t.x, t.y, false)
                        if why == "lava" then return "work" end
                        if why == "stop" or why == "range" then return "wait" end
                        if r == nil then break end -- tidak bisa dipecah (lock, pintu, dll)
                        if r == "broke" then
                            broke = true
                            break
                        end
                    end
                    -- tidak bisa dibersihkan: jangan didatangi ulang terus (bikin bolak-balik jauh)
                    if not broke then skipTile(Build.Skip, t.idx, 1800) end
                    waitNearDrops(0.15)
                end
                return "work"
            end
            if placeBuild(t, cur) then
                done += 1
                if entry[t.x] then Build.Under[k] = nil end
                if not waitAuto(State.PlaceMs) then return "wait" end
            elseif invCount(Build.BlockId) <= (Build.Reserve or 0) then
                break
            end
        end
    end
    if done > 0 then return "work" end
    if invCount(Build.BlockId) <= (Build.Reserve or 0) then return "none" end

    local RR = buildReach() - 0.35
    -- naik ke baris ini lalu pasang ke depan (baris jadi jembatan)
    if hasAny and not under then
        local r = Build.goNear(T, RR, y - 1, true)
        if r ~= "nopath" then return r end
        Build.Under[k] = now + 60 -- tidak bisa naik ke baris ini: sementara pasang dari bawah
        under = true
    end
    -- belum ada pijakan: ke ujung tangga, pasang block pertama baris dari sana
    if not under then
        local E = {}
        for _, t in ipairs(T) do
            if entry[t.x] then E[#E + 1] = t end
        end
        if #E > 0 then
            local r = Build.goNear(E, RR, nil, true)
            if r ~= "nopath" then return r end
        end
        Build.Under[k] = now + 60
    end
    local r = Build.goNear(T, RR, nil, true)
    if r == "nopath" then
        for _, t in ipairs(T) do skipTile(Build.Skip, t.idx, 30) end
        Build.Status = ("Baris y %d belum terjangkau, dilewati sebentar"):format(y)
        return "none"
    end
    return r
end

-- ---------- Produksi block (1 baris, seperti Pabrik) ----------
function Build.cfg(o, harvest, plant)
    return {
        run = o.live,
        harvest = harvest,
        plant = plant and invCount(o.seed) > 0,
        seed = o.seed,
        only = o.seed,           -- hanya panen pohon seed block ini
        skip = Build.FieldSkip,
        hms = Farmer.HarvestMs,
        pms = Farmer.PlantMs,
        area = inLandRect,       -- hanya pohon di lahan (baris per baris)
        plantSet = o.plantSet,   -- tanam hanya di baris produksi
        exclude = o.exclude,
        row = Build.Row,
        collect = true,
        status = function(t) Build.Status = t end,
        onHarvest = function() Build.Harvested += 1 end,
        onPlant = function() Build.Planted += 1 end,
    }
end

-- Baris produksi: baris lengkap tepat di bawah baris yang sedang dipasang
-- (kalau tidak ada: baris lengkap terdekat dengan karakter)
function Build.prodRow(P)
    local function complete(k)
        local y = P.rows[k]
        for _, x in ipairs(P.cols[k]) do
            if not Build.done(x, y) then return false end
        end
        return true
    end
    for k = P.K, 1, -1 do
        if not complete(k) then
            if k < P.K then return k + 1 end
            break
        end
    end
    local s = playerState()
    local best, bd = nil, nil
    for k = 1, P.K do
        if complete(k) then
            local d = s and abs(P.rows[k] - s.y) or k
            if not bd or d < bd then best, bd = k, d end
        end
    end
    return best
end

-- Tempat tanam baris produksi + posisi pasang-pecah.
-- Posisi break & grid lahan diatur (tab Lahan / Grid mode Lahan): pakai itu.
-- Belum diatur: otomatis berdiri dekat ujung kanan baris, block di KANAN karakter.
function Build.prodSpots(P, k)
    local W, y = P.W, P.rows[k]
    local gy = y - 1
    local o = { set = {} }
    local L = P.isLand[k]
    local skip = {}
    if Build.BreakX >= 0 and next(Build.Tiles) ~= nil then
        skip[Build.BreakY * W + Build.BreakX] = true -- jangan tanam di tempat berdiri & tile break
        for key in pairs(Build.Tiles) do
            local dx, dy = string.match(key, "^(-?%d+),(-?%d+)$")
            if dx then skip[(Build.BreakY + tonumber(dy)) * W + Build.BreakX + tonumber(dx)] = true end
        end
    else
        local bx = P.x1 - 3
        if gy >= 0 and bx > P.x0 and L[bx] and L[bx + 1] and Build.done(bx, y) and Build.done(bx + 1, y) then
            o.stand = { x = bx, y = gy }
            o.tile = { x = bx + 1, y = gy }
            skip[gy * W + bx], skip[gy * W + bx + 1] = true, true
        end
    end
    if gy >= 0 then
        for _, x in ipairs(P.cols[k]) do
            local idx = gy * W + x
            if not skip[idx] then o.set[idx] = true end
        end
    end
    return o
end

-- Sesi break produksi di posisi & grid lahan (mesin Auto Farm: multi tile, sentuh drop tiap putaran).
-- Berhenti kalau seed sudah cukup untuk mengisi baris, block habis, atau 8 dtk tidak ada aksi.
function Build.breakSession(o)
    if Build.lavaTarget() then return false end
    local s = playerState()
    if not s then return false end
    local hx, hy = startNode(s)
    if hx ~= Build.BreakX or hy ~= Build.BreakY then
        Build.Status = ("Jalan ke posisi break Dirt Farm (%d,%d)"):format(Build.BreakX, Build.BreakY)
        if not walkTo(Build.BreakX, Build.BreakY, 45, function() return not o.live() or Build.lavaTarget() ~= nil end) then
            if Build.lavaTarget() or not o.live() then return false end
            Build.Status = "Gagal jalan ke posisi break Dirt Farm, pakai posisi otomatis"
            return nil
        end
    end
    if not o.live() then return false end
    local before = invCount(o.seed)
    local want = math.max(1, Build.freeSpots(o))
    State.Override = { offsets = Build.Tiles, block = o.block, mode = "Place + Break", breakMs = Build.PunchMs or 200 }
    State.Quiet = true
    State.WaitingDrops, State.WorkReason = nil, nil
    table.clear(HitCount)
    table.clear(PlacedAt)
    State.Running = true
    State.RunId = (State.RunId or 0) + 1
    local id = State.RunId
    local lastActs, lastActAt = State.Placed + State.Broken, os.clock()
    task.spawn(function() -- pengawas sesi break
        while State.Running and State.RunId == id do
            task.wait(0.1)
            if not State.Running or State.RunId ~= id then break end
            local acts = State.Placed + State.Broken
            if acts ~= lastActs then lastActs, lastActAt = acts, os.clock() end
            if not o.live() or Build.lavaTarget() or invCount(o.seed) >= before + want or invCount(o.block) <= 0
                or (not Drops.WorkBusy and os.clock() - lastActAt > 8) then
                State.Running = false
            end
        end
    end)
    Build.Status = ("Break %s di posisi break Dirt Farm (%d,%d)"):format(itemName(o.block), Build.BreakX, Build.BreakY)
    local ok, e = pcall(farmLoop, id)
    if not ok then warn("[Zekio Supreme Premium] Break Dirt Farm error: " .. tostring(e)) end
    State.Running = false
    State.Override = nil
    State.Quiet = false
    return invCount(o.seed) > before
end

-- Tempat tanam yang masih kosong di baris produksi
function Build.freeSpots(o)
    local w = Refs.World
    if not w then return 0 end
    if not o.plantSet then
        local n, nxt = readyTreeCount(true, o.seed)
        return (n == 0 and nxt == nil) and 1 or 0
    end
    local n = 0
    for idx in pairs(o.plantSet) do
        local x, y = idx % w.w, idx // w.w
        if fgIdAt(x, y) == 0 and plantSpotOk(x, y, o.seed) then n += 1 end
    end
    return n
end

-- Pasang lalu pecah block di KANAN karakter untuk dapat seed (seperti Pabrik)
function Build.bootstrap(o)
    local w = Refs.World
    if not w or invCount(o.block) <= 0 or Build.lavaTarget() then return false end
    if Build.BreakX >= 0 and next(Build.Tiles) ~= nil then
        local r = Build.breakSession(o)
        if r ~= nil then return r end -- nil = tidak bisa ke posisi break: pakai cara otomatis
    end
    local spot = nil
    if o.stand then
        local s0 = playerState()
        local hx, hy = nil, nil
        if s0 then hx, hy = startNode(s0) end
        if hx ~= o.stand.x or hy ~= o.stand.y then
            Build.Status = ("Jalan ke posisi pasang-pecah (%d,%d)"):format(o.stand.x, o.stand.y)
            if not walkTo(o.stand.x, o.stand.y, 45, function() return not o.live() or Build.lavaTarget() ~= nil end) then o.stand = nil end
        end
        if o.stand and o.tile then
            local id = fgIdAt(o.tile.x, o.tile.y)
            if id == o.block or (id == 0 and placeOk(o.tile.x, o.tile.y)) then spot = o.tile end
        end
    end
    if Build.lavaTarget() or not o.live() then return false end
    local s = playerState()
    if not s or not s.grounded then return false end
    if not spot then
        local R = farmReach() - 0.08
        local ty = floor(s.y - 0.475)
        for _, dx in ipairs({ 1, 2, -1, -2 }) do -- kanan dulu
            local tx = floor(s.x) + dx
            local idx = ty * w.w + tx
            if tx >= 0 and tx < w.w and ty >= 0 and fgIdAt(tx, ty) == 0
                and not (o.plantSet and o.plantSet[idx]) and not (o.exclude and o.exclude[idx])
                and stateReaches(s, tx, ty, R) and not overlapsPlayer(tx, ty, s) and placeOk(tx, ty) then
                spot = { x = tx, y = ty }
                break
            end
        end
    end
    if not spot then return false end
    -- 1 sesi panjang (seperti Pabrik): pasang-pecah terus sampai seed cukup untuk mengisi
    -- semua tempat kosong di baris produksi, atau block habis. Tidak diselingi panen / tanam.
    local before = invCount(o.seed)
    local want = math.max(1, Build.freeSpots(o))
    for _ = 1, 300 do
        if not o.live() or Build.lavaTarget() or Refs.World ~= w then break end
        local current = playerState()
        if not current then break end
        local hx, hy = startNode(current)
        local safe, reason = Drops.prepareWork({ spot }, hx, hy, function()
            return o.live() and Refs.World == w and not Build.lavaTarget()
        end, { collect = true, seed = o.seed })
        if #safe == 0 then Build.Status = reason or "Menunggu collect sebelum produksi seed"; break end
        if not o.live() or Refs.World ~= w or Build.lavaTarget() then break end
        if invCount(o.seed) >= before + want or (invCount(o.block) <= 0 and fgIdAt(spot.x, spot.y) == 0) then break end
        if fgIdAt(spot.x, spot.y) == 0 then
            sendSetTile("fg", spot.x, spot.y, o.block)
            pcall(function() Refs.Inv:remove(o.block, 1) end)
            PlacedAt[spot.x .. "," .. spot.y] = os.clock()
            Build.Status = ("Pasang & pecah %s untuk dapat seed (%d,%d)"):format(itemName(o.block), spot.x, spot.y)
            if not waitAuto(State.PlaceMs) then break end
        end
        for _ = 1, 40 do
            if not o.live() then break end
            local r, why = Build.punch(spot.x, spot.y, false, o.live)
            if why == "lava" or why == "stop" or why == "range" then return false end
            if r == nil or r == "broke" then break end
        end
    end
    return invCount(o.seed) > before
end

-- 1 langkah produksi. Hasil: "work" | "move" | "wait" | "next" | "idle" (+ detik pohon siap, jumlah pohon siap)
-- Siklus berurutan (seperti Pabrik), tiap fase diselesaikan dulu, tidak saling potong:
--   PANEN : panen SEMUA pohon siap di lahan (baris per baris), hasilnya diambil   -> TANAM
--   TANAM : isi semua tempat kosong di baris produksi                              -> BREAK / TUNGGU
--   BREAK : seed habis & baris belum penuh: pasang-pecah di kanan karakter sampai
--           seed cukup untuk mengisi baris (atau block habis)                      -> TANAM
--   TUNGGU: tunggu pohon siap SEKALIGUS (tidak ada lagi yang siap dalam 20 dtk)   -> PANEN
function Build.produceStep(o)
    o.phase = o.phase or "panen"
    if o.phase == "panen" then
        FC = Build.cfg(o, true, false)
        local r = fieldStep()
        if r == "idle" then
            o.phase = "tanam"
            return "next"
        end
        return r
    end
    if o.phase == "tanam" then
        if invCount(o.seed) > 0 and Build.freeSpots(o) > 0 then
            FC = Build.cfg(o, false, true)
            local r = fieldStep()
            if r ~= "idle" then return r end
        end
        if not o.broke and Build.freeSpots(o) > 0 and invCount(o.seed) <= 0 and invCount(o.block) > 0 then
            o.phase = "break"
        else
            o.phase, o.broke = "tunggu", nil
        end
        return "next"
    end
    if o.phase == "break" then
        o.broke = true -- 1 sesi break tiap putaran
        o.bootAt = os.clock()
        Build.bootstrap(o)
        o.phase = "tanam"
        return "work"
    end
    -- TUNGGU
    local n, nxt = readyTreeCount(false, o.seed)
    if n > 0 and (nxt == nil or nxt > 20) then
        o.phase = "panen" -- pohon siap sekaligus
        return "next"
    end
    if n == 0 and nxt == nil and Build.freeSpots(o) > 0 and os.clock() - (o.retryAt or 0) > 10 then
        -- tidak ada pohon tumbuh sama sekali (break tadi tidak dapat seed): tanam / break lagi
        if invCount(o.seed) > 0 or (invCount(o.block) > 0 and os.clock() - (o.bootAt or 0) > 5) then
            o.retryAt = os.clock()
            o.phase = "tanam"
            return "next"
        end
    end
    return "idle", nxt, n
end

-- Bersihkan drop di dalam lahan PER BARIS (scan daftar drop game), seperti main manual:
--   baris terdekat dulu, disusuri dari ujung ke ujung tanpa berhenti (terambil sambil lewat),
--   lalu pindah ke baris sebelahnya. ids = nil (semua) atau { [id] = true }
function Build.sweep(P, live, ids, maxSec)
    if not Drops.list then return 0 end
    local x0, x1 = P.x0, P.x1 + 1
    local y0, y1 = math.max(0, P.rows[1] - 1), P.rows[P.K] + 1
    return Move.fetchDrops(function() return live() and not Build.lavaTarget(P) end, 999, function(d)
        return d.x >= x0 and d.x < x1 and d.y >= y0 and d.y < y1 and (not ids or ids[d.id] == true)
    end, maxSec or 60)
end

function Build.stop(reason)
    Build.Running = false
    if Pabrik.Running == false and State.Override then State.Running = false end
    autoEnd()
    releaseInput()
    Build.Phase = reason or "Dihentikan"
    if UI.BuildToggle then pcall(function() UI.BuildToggle:Set(false) end) end
    if reason then
        notify("Bangun Dirt Farm", reason, 5)
        if not string.find(reason, "^Dihentikan") then Hook.send("pabrik", "Bangun Dirt Farm: " .. reason) end
    end
end

local function buildLoop(runId)
    local function live() return Build.Running and alive() and Build.RunId == runId end
    local seed = seedOfBlock(Build.BlockId)
    local o = { seed = seed, block = Build.BlockId, live = live }
    local phase = nil
    local noneAt = nil
    while live() do
        task.wait()
        local P = Build.plan()
        if not P then
            Build.stop("Tidak ada baris Dirt Farm (cek X awal / X akhir / Y baris atas)")
            break
        end
        Build.ActivePlan = P
        if Build.lavaStep(P, live) then continue end
        if Build.Surface == nil then Build.Surface = Build.findSurface(P) end
        local carve = Build.carveList(P)
        local info = landInfo(Build.BlockId, P, carve)
        Build.Info = info
        Build.InfoAt = os.clock()

        -- 1) GALI dulu sampai bawah
        local r = "none"
        if #carve > 0 then
            Build.Reserve = 0
            Build.Phase = ("Gali: sisa %d tile"):format(#carve)
            r = Build.carveStep(P, carve, live)
            if r ~= "none" then noneAt = nil end
        end
        if r == "none" and #carve == 0 and not o.dugSwept then
            -- Ambil bahan hanya jika kurang. Jangan menyusuri seluruh world
            -- lalu kembali ke awal sebelum pemasangan yang sebenarnya sudah bisa jalan.
            o.dugSwept, o.sweptAt = true, os.clock()
            if invCount(Build.BlockId) < info.need then
                Build.Phase = "Ambil block sisa galian yang masih dibutuhkan"
                Build.sweep(P, live, { [Build.BlockId] = true }, 30)
            end
            continue
        end
        if r == "none" then
            local have = invCount(Build.BlockId)
            if info.need == 0 then
                -- tinggal tile gali yang dilewati: coba lagi sebentar
                if #carve > 0 then
                    noneAt = noneAt or os.clock()
                    local waited = os.clock() - noneAt
                    if waited < 45 then
                        Build.Status = #carve .. " tile gali belum terjangkau, dicoba lagi"
                        if waited > 20 and not o.carveReset then
                            o.carveReset = true
                            table.clear(Build.Skip)
                            table.clear(BuildFail)
                            table.clear(BadEdge)
                            Reach = nil
                        end
                        if not waitAuto(1000) then break end
                        continue
                    end
                end
                -- 4) BERSIH: ambil semua drop yang tertinggal di lahan
                Build.Phase = "Bersihkan drop di Dirt Farm (per baris)"
                Build.sweep(P, live, nil, 90)
                if not live() then break end
                if Build.lavaTarget(P) then continue end
                local note = (#carve > 0) and (", " .. #carve .. " tile gali dilewati") or ""
                Build.stop("Dirt Farm selesai (" .. info.done .. " block" .. note .. ")")
                if Build.ThenPabrik then
                    if not Pabrik.SeedId then Pabrik.SeedId = seed end
                    Pabrik.start()
                end
                break
            end
            local reserve = (have >= info.need or not seed) and 0 or Build.RESERVE
            if phase ~= "produksi" and have > reserve then
                -- 2) PASANG (sisakan block untuk produksi kalau masih kurang)
                phase = "pasang"
                Build.Reserve = reserve
                Build.Phase = ("Pasang Dirt Farm: sisa %d tile"):format(info.need)
                    .. ((reserve > 0) and (" (sisakan " .. reserve .. " block)") or "")
                local pr = Build.placeStep(P)
                if pr == "none" and invCount(Build.BlockId) > reserve then
                    Build.Status = "Sisa tile belum terjangkau / terhalang, dicoba lagi"
                    noneAt = noneAt or os.clock()
                    if os.clock() - noneAt > 20 then -- lama tidak ada yang bisa dipasang: reset & coba lagi
                        noneAt = nil
                        table.clear(Build.Skip)
                        table.clear(BuildFail)
                        table.clear(BadEdge)
                        table.clear(Build.Under)
                        Reach = nil
                    end
                    if not waitAuto(1500) then break end
                elseif pr ~= "none" then
                    noneAt = nil
                end
            elseif not seed then
                Build.stop(("Block habis, masih kurang %d (seed-nya tidak ketemu)"):format(info.need))
                break
            else
                -- 3) PRODUKSI
                if phase ~= "produksi" then
                    if os.clock() - (o.sweptAt or -1e9) > 120 then
                        -- ambil dulu drop yang tertinggal di lahan (block, seed & lainnya), per baris
                        o.sweptAt = os.clock()
                        Build.Phase = "Ambil drop sisa di Dirt Farm (per baris)"
                        Build.sweep(P, live, { [Build.BlockId] = true }, 30)
                        continue
                    end
                    phase = "produksi"
                    o.phase, o.rowK = nil, nil
                    notify("Bangun Dirt Farm", "Block habis, produksi 1 baris dulu", 4)
                end
                local target = math.min(CAP, info.need + Build.RESERVE)
                if have >= target then
                    phase = "pasang"
                    notify("Bangun Dirt Farm", "Block cukup (" .. have .. "), lanjut pasang", 4)
                else
                    if o.rowK and not P.rows[o.rowK] then o.rowK = nil end
                    if o.rowK == nil then
                        o.rowK = Build.prodRow(P) or false
                        table.clear(Build.Row)
                        if o.rowK then
                            local sp = Build.prodSpots(P, o.rowK)
                            o.plantSet, o.stand, o.tile, o.exclude = sp.set, sp.stand, sp.tile, nil
                        else -- belum ada baris lengkap: tanam di mana saja di luar tile lahan
                            o.plantSet, o.stand, o.tile, o.exclude = nil, nil, nil, landBlockSet()
                        end
                    end
                    Build.Phase = ("Produksi %s: block %d / %d"):format(PHASE_NAME[o.phase or "panen"] or "-", have, target)
                        .. (o.rowK and (" | baris y " .. P.rows[o.rowK]) or "")
                    local pr, nextReady, nReady = Build.produceStep(o)
                    if pr ~= "idle" then o.stuckAt = nil end
                    if pr == "idle" then
                        if not nextReady and (nReady or 0) == 0 and invCount(seed) <= 0 and have <= 0 then
                            Build.stop("Seed & block habis. Butuh " .. info.need .. " block")
                            break
                        end
                        if (nReady or 0) > 0 then
                            Build.Status = nReady .. " pohon siap belum terjangkau, dicoba lagi"
                            o.stuckAt = o.stuckAt or os.clock()
                            if os.clock() - o.stuckAt > 30 then -- reset daftar lewati & jalur
                                o.stuckAt = nil
                                table.clear(Build.FieldSkip)
                                table.clear(BadEdge)
                                Reach = nil
                            end
                        elseif nextReady then
                            Build.Status = "Menunggu pohon siap ±" .. waitText(nextReady)
                        elseif invCount(seed) <= 0 then
                            Build.Status = "Seed habis & tidak ada tempat pasang-pecah di samping karakter"
                        else
                            Build.Status = "Tidak ada tempat tanam, menunggu"
                        end
                        if not waitAuto(1000) then break end
                    end
                end
            end
        end
    end
    releaseInput()
end

function Build.start()
    if Build.Running then return end
    local err
    local it = Build.BlockId and ItemDB[Build.BlockId]
    if not Refs.World then
        err = "Data world belum ketemu. Tekan 'Hubungkan ke game'"
    elseif not OrigIsDown and not AutoInput.bindMenu() then
        err = AutoInput.Error or "Kontrol gerak game belum terhubung"
    elseif not playerState() then
        err = "Kamu belum masuk world"
    elseif not (it and it.solid) then
        err = "Pilih block padat untuk Dirt Farm"
    end
    local start
    if not err then
        start, err = Build.spawnStart()
        if start then
            -- Celah pertama adalah tile yang ditandai, lantainya satu tile di bawahnya.
            Land.Y0 = start.y + 1
            Land.Cache = nil
            if #landRows() == 0 then err = "Tidak ada baris Dirt Farm yang muat di bawah batu" end
        end
    end
    if err then
        notify("Bangun Dirt Farm", err, 4)
        if UI.BuildToggle then pcall(function() UI.BuildToggle:Set(false) end) end
        return
    end
    if State.Running and not State.Override then stopFarm("Dihentikan karena Bangun Dirt Farm dimulai") end
    if Clear.Running then stopClear("Dihentikan karena Bangun Dirt Farm dimulai") end
    if Farmer.Running then stopFarmer("Dihentikan karena Bangun Dirt Farm dimulai") end
    if Splice.Running and Splice.stop then Splice.stop("Dihentikan karena Bangun Dirt Farm dimulai") end
    if Pabrik.Running then Pabrik.stop("Dihentikan karena Bangun Dirt Farm dimulai") end
    if not Refs.Trees then findTreeRefs() end
    table.clear(Build.Skip)
    table.clear(BuildFail)
    table.clear(Build.FieldSkip)
    table.clear(Build.Row)
    table.clear(Build.Under)
    table.clear(Build.BreakTimes)
    table.clear(Build.LavaSkip)
    table.clear(BadEdge)
    Build.Surface = nil -- dihitung ulang (permukaan tanah asli)
    Build.StartTarget = start
    Build.Reserve = 0
    Build.Route, Build.ActivePlan, Build.NextPunchAt = nil, nil, nil
    Build.LavaCleared = 0
    Land.Cache = nil
    Pabrik.BreakFailUntil = 0
    Build.Running = true
    Build.RunId = (Build.RunId or 0) + 1
    Build.Phase = "Menghitung..."
    autoBegin()
    if UI.BuildToggle then pcall(function() UI.BuildToggle:Set(true) end) end
    local id = Build.RunId
    task.spawn(function()
        local ok, e = pcall(buildLoop, id)
        if not ok then
            warn("[Zekio Supreme Premium] Bangun Dirt Farm error: " .. tostring(e))
            if Build.Running then Build.stop("Error: " .. tostring(e)) end
        end
    end)
end

Auto.landInfo = landInfo
Auto.landRows = landRows
Auto.seedOfBlock = seedOfBlock
Auto.blockOfSeed = blockOfSeed
Auto.parseDropTarget = parseDropTarget

Auto.walkTo = walkTo
Auto.startSpliceRoam = startSpliceRoam
Auto.stopSpliceRoam = stopSpliceRoam
Auto.treeReadyAt = treeReadyAt
Auto.plantSpotOk = plantSpotOk
Auto.stopWalk = function() Move.Homing = false end
Auto.here = function()
    local s = playerState()
    if s then return startNode(s) end
    return nil
end
Auto.startClear = startClear
Auto.startFarmer = startFarmer
Auto.updateClearStatus = updateClearStatus
Auto.updateFarmerStatus = updateFarmerStatus
Auto.findTreeRefs = findTreeRefs
Auto.tileOpen = openAt
Auto.releaseInput = releaseInput
Auto.BadEdge = BadEdge
Auto.ClearFail = ClearFail
Auto.resetReach = function() Reach = nil end
end)() end -- do (gerak otomatis)

---------------------------------------------------------------------
-- AUTO CHAT
---------------------------------------------------------------------
-- Pesan dikirim ke chat world, bergantian sesuai urutan
local TextChatService = game:GetService("TextChatService")

local function worldChannel()
    local folder = TextChatService:FindFirstChild("WorldChannels")
    if not folder then return nil end
    local name = Refs.World and Refs.World.name
    if type(name) == "string" and name ~= "" then
        local ch = folder:FindFirstChild(name)
        if ch then return ch end
    end
    -- cadangan: cari channel yang ada kita
    for _, ch in ipairs(folder:GetChildren()) do
        if ch:IsA("TextChannel") then
            for _, src in ipairs(ch:GetChildren()) do
                if src:IsA("TextSource") and src.UserId == LocalPlayer.UserId then return ch end
            end
        end
    end
    return nil
end

local function parseSpamTexts(raw)
    local out = {}
    for part in string.gmatch(raw or "", "[^|\n]+") do
        part = part:gsub("^%s+", ""):gsub("%s+$", "")
        if part ~= "" then out[#out + 1] = part end
    end
    return out
end

local lastSpamText = nil
local function updateSpamStatus()
    if not UI.SpamStatus then return end
    local txt = "Status   : " .. (Spam.On and "JALAN" or "BERHENTI")
        .. "\nPesan    : " .. #Spam.Texts .. " (bergantian)"
        .. "\nTerkirim : " .. Spam.Sent
        .. "\nTerakhir : " .. Spam.Last
    if txt == lastSpamText then return end
    lastSpamText = txt
    task.defer(function()
        pcall(function() UI.SpamStatus:SetDesc(txt) end)
    end)
end

-- Kirim pesan berikutnya
local function sendNextChat()
    if #Spam.Texts == 0 then
        Spam.Last = "Daftar pesan kosong"
        return false
    end
    local ch = worldChannel()
    if not ch then
        Spam.Last = "Channel chat world belum ada (masuk world dulu)"
        return false
    end
    if Spam.Index > #Spam.Texts then Spam.Index = 1 end
    local msg = Spam.Texts[Spam.Index]
    Spam.Index = Spam.Index % #Spam.Texts + 1
    local ok, err = pcall(ch.SendAsync, ch, msg)
    if ok then
        Spam.Sent += 1
        Spam.Last = msg
    else
        Spam.Last = "Gagal: " .. tostring(err)
    end
    return ok
end

Spam.NextAt = 0
task.spawn(function()
    while alive() do
        if Spam.On and os.clock() >= Spam.NextAt then
            sendNextChat()
            Spam.NextAt = os.clock() + math.max(3, Spam.IntervalSec)
            updateSpamStatus()
        end
        task.wait(0.25)
    end
end)

---------------------------------------------------------------------
-- WATERMARK NAMA LOKAL
---------------------------------------------------------------------
local TextService = game:GetService("TextService")
local NameFx = { t0 = os.clock() }
local NAME_COLORS = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(170,90,255)),
    ColorSequenceKeypoint.new(0.25, Color3.fromRGB(60,205,255)),
    ColorSequenceKeypoint.new(0.50, Color3.fromRGB(255,110,210)),
    ColorSequenceKeypoint.new(0.75, Color3.fromRGB(60,205,255)),
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(170,90,255)),
})
local NAME_FONT = Enum.Font.FredokaOne

local function nameHolders()
    local gg=PlayerGui:FindFirstChild("GameGui")
    local world=gg and gg:FindFirstChild("World")
    local cam=world and world:FindFirstChild("Camera")
    local chat=PlayerGui:FindFirstChild("ChatGui")
    local hud=chat and chat:FindFirstChild("HUD")
    local panel=hud and hud:FindFirstChild("PlayerPanel")
    return cam and cam:FindFirstChild("NameTag"),panel and panel:FindFirstChild("Name")
end
local function textWidth(text,size)
    local ok,v=pcall(TextService.GetTextSize,TextService,text,size,NAME_FONT,Vector2.new(2000,200))
    return (ok and v.X or #text*size*.55)+6
end
local function makeLabel(holder,size,isTag)
    local lb=Instance.new("TextLabel")
    lb.Name="ZekioPremiumName";lb.BackgroundTransparency=1;lb.RichText=false
    lb.Font=NAME_FONT;lb.TextSize=size;lb.TextColor3=Color3.new(1,1,1);lb.Text=Misc.NameText
    lb.ZIndex=isTag and 1017 or 10
    if isTag then
        lb.AnchorPoint=Vector2.new(.5,.5);lb.Position=UDim2.fromScale(.5,.5)
        lb.TextXAlignment=Enum.TextXAlignment.Center
    else
        lb.AnchorPoint=Vector2.new(0,.5);lb.Position=UDim2.new(0,3,.5,0);lb.TextXAlignment=Enum.TextXAlignment.Left
    end
    local stroke=Instance.new("UIStroke")
    stroke.Thickness=2;stroke.Color=Color3.fromRGB(25,12,40);stroke.Transparency=.1;stroke.Parent=lb
    local gradient=Instance.new("UIGradient");gradient.Color=NAME_COLORS;gradient.Rotation=12;gradient.Parent=lb
    local scale=Instance.new("UIScale");scale.Parent=lb;lb.Parent=holder
    return {holder=holder,bitmap=holder:FindFirstChild("BitmapText"),label=lb,gr=gradient,sc=scale,
        isTag=isTag,text=nil,w=0}
end
local function dropEntry(entry)
    if not entry then return end
    pcall(function() entry.label:Destroy() end)
    if entry.bitmap then pcall(function() entry.bitmap.Visible=true end) end
    if entry.isTag and entry.bitmap then
        pcall(function()
            local width=entry.bitmap.Size.X.Offset
            entry.holder.Size=UDim2.fromOffset(width,entry.holder.Size.Y.Offset)
            local wrench=entry.holder:FindFirstChild("Wrench")
            if wrench then wrench.Position=UDim2.fromOffset(width+4,wrench.Position.Y.Offset) end
        end)
    end
end
local function nameRestore()
    dropEntry(NameFx.tag);dropEntry(NameFx.panel)
    NameFx.tag,NameFx.panel=nil,nil
end
local function nameKeep(entry,holder,size,isTag)
    if not holder then dropEntry(entry);return nil end
    if not entry or entry.holder~=holder or not entry.label.Parent then
        dropEntry(entry);entry=makeLabel(holder,size,isTag)
    end
    local text=Misc.NameText
    if entry.text~=text then
        entry.text=text
        entry.label.Text=text
        entry.w=textWidth(text,size)
    end
    if entry.bitmap and entry.bitmap.Visible then entry.bitmap.Visible=false end
    if isTag then
        local height=math.max(holder.Size.Y.Offset,size+6)
        if entry.label.Size.X.Offset~=entry.w or entry.label.Size.Y.Offset~=height then entry.label.Size=UDim2.fromOffset(entry.w,height) end
        if holder.Size.X.Offset~=entry.w then holder.Size=UDim2.fromOffset(entry.w,holder.Size.Y.Offset) end
        local wrench=holder:FindFirstChild("Wrench")
        if wrench and wrench.Position.X.Offset~=entry.w+4 then wrench.Position=UDim2.fromOffset(entry.w+4,wrench.Position.Y.Offset) end
    else entry.label.Size=UDim2.new(1,-6,1,0) end
    return entry
end
function NameFx.refresh()
    if not alive() or not Misc.CustomName then return end
    local tag,panelName=nameHolders()
    NameFx.tag=nameKeep(NameFx.tag,tag,22,true)
    NameFx.panel=nameKeep(NameFx.panel,panelName,21,false)
end
Session.RestoreNames=nameRestore
table.insert(Connections,RunService.RenderStepped:Connect(function()
    if not alive() then return end
    pcall(NameFx.refresh)
    local elapsed=os.clock()-NameFx.t0
    local offset=Vector2.new(((elapsed*.45)%2)-1,0)
    local pulse=1+.045*math.sin(elapsed*3.2)
    if NameFx.tag then NameFx.tag.gr.Offset=offset;NameFx.tag.sc.Scale=pulse end
    if NameFx.panel then NameFx.panel.gr.Offset=offset;NameFx.panel.sc.Scale=pulse end
end))


---------------------------------------------------------------------
-- ANTI AFK
---------------------------------------------------------------------
table.insert(Connections, LocalPlayer.Idled:Connect(function()
    if State.AntiAfk and alive() then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end))

---------------------------------------------------------------------
-- GUI TAMBAHAN: Grid Tile 5x5 + tombol Fly ▲/▼
---------------------------------------------------------------------
Session.Report("Menyiapkan panel dan kontrol")
local guiParent = Session.GuiParent(PlayerGui)

local function newScreenGui(name)
    local sg = Instance.new("ScreenGui")
    Session.StartupGuis = Session.StartupGuis or {}
    table.insert(Session.StartupGuis, sg)
    sg.Name = name
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder = 999
    sg.Enabled = false
    if syn and syn.protect_gui then pcall(syn.protect_gui, sg) end
    sg.Parent = guiParent
    return sg
end

local GRID_RADIUS = 2
local CELL = 38
local GAP = 4

local GridGui = newScreenGui("ZekioPremiumGrid")
UI.GridGui = GridGui

local side = GRID_RADIUS * 2 + 1
local gridSize = side * CELL + (side - 1) * GAP

local Panel = Instance.new("Frame")
Panel.Size = UDim2.fromOffset(gridSize + 20, gridSize + 96)
Panel.Position = UDim2.fromOffset(20, 80)
Panel.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
Panel.BorderSizePixel = 0
Panel.Parent = GridGui
Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 10)
local pStroke = Instance.new("UIStroke", Panel)
pStroke.Color = Color3.fromRGB(70, 70, 90)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 0, 28)
Title.Position = UDim2.fromOffset(10, 4)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextColor3 = Color3.fromRGB(235, 235, 245)
Title.Text = I18N.T("Grid Tile")
Title.Parent = Panel

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.fromOffset(24, 24)
CloseBtn.Position = UDim2.new(1, -30, 0, 6)
CloseBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.Parent = Panel
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
CloseBtn.MouseButton1Click:Connect(function()
    GridGui.Enabled = false
end)

local GridHolder = Instance.new("Frame")
GridHolder.Size = UDim2.fromOffset(gridSize, gridSize)
GridHolder.Position = UDim2.fromOffset(10, 36)
GridHolder.BackgroundTransparency = 1
GridHolder.Parent = Panel

local COLOR_OFF = Color3.fromRGB(48, 48, 60)
local COLOR_ON = Color3.fromRGB(46, 160, 90)
local COLOR_ME = Color3.fromRGB(60, 110, 220)
local CellButtons = {}

-- Grid dipakai untuk 2 hal: tile Auto Farm, atau tile break Pabrik
UI.GridMode = "farm"
UI.gridTarget = function()
    if UI.GridMode == "pabrik" then return Pabrik.Tiles end
    if UI.GridMode == "lahan" then return Build.Tiles end
    return State.Offsets
end

local function paintCell(key)
    local b = CellButtons[key]
    if b then b.BackgroundColor3 = UI.gridTarget()[key] and COLOR_ON or COLOR_OFF end
end

for row = 0, side - 1 do
    for col = 0, side - 1 do
        local dx, dy = col - GRID_RADIUS, row - GRID_RADIUS
        local key = dx .. "," .. dy
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.fromOffset(CELL, CELL)
        btn.Position = UDim2.fromOffset(col * (CELL + GAP), row * (CELL + GAP))
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Parent = GridHolder
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

        if dx == 0 and dy == 0 then
            btn.Text = "ME"
            btn.BackgroundColor3 = COLOR_ME
            btn.AutoButtonColor = false
        else
            btn.Text = ""
            btn.BackgroundColor3 = UI.gridTarget()[key] and COLOR_ON or COLOR_OFF
            CellButtons[key] = btn
            btn.MouseButton1Click:Connect(function()
                local tgt = UI.gridTarget()
                tgt[key] = (not tgt[key]) or nil
                paintCell(key)
                updateStatus()
            end)
        end
    end
end

local GridStart = Instance.new("TextButton")
GridStart.Size = UDim2.new(1, -20, 0, 30)
GridStart.Position = UDim2.new(0, 10, 1, -54)
GridStart.BackgroundColor3 = COLOR_ON
GridStart.Font = Enum.Font.GothamBold
GridStart.TextSize = 14
GridStart.TextColor3 = Color3.new(1, 1, 1)
GridStart.Text = "START"
GridStart.Parent = Panel
Instance.new("UICorner", GridStart).CornerRadius = UDim.new(0, 8)
UI.GridStart = GridStart
GridStart.MouseButton1Click:Connect(function()
    if UI.GridMode == "lahan" then
        if Build.Running then Build.stop() elseif Build.start then Build.start() end
    elseif UI.GridMode == "pabrik" then
        if Pabrik.Running then Pabrik.stop() else Pabrik.start() end
    elseif State.Running and not State.Override then
        stopFarm()
    else
        startFarm()
    end
end)

local ClearBtn = Instance.new("TextButton")
ClearBtn.Size = UDim2.new(1, -20, 0, 18)
ClearBtn.Position = UDim2.new(0, 10, 1, -22)
ClearBtn.BackgroundTransparency = 1
ClearBtn.Font = Enum.Font.Gotham
ClearBtn.TextSize = 12
ClearBtn.TextColor3 = Color3.fromRGB(180, 180, 195)
ClearBtn.Text = I18N.T("Bersihkan pilihan")
ClearBtn.Parent = Panel
ClearBtn.MouseButton1Click:Connect(function()
    local tgt = UI.gridTarget()
    for key in pairs(tgt) do
        tgt[key] = nil
        paintCell(key)
    end
    updateStatus()
end)

-- Tombol ganti mode Grid: Farm (tile Auto Farm) / Pabrik (tile break pabrik)
do (function()
    local ModeBtn = Instance.new("TextButton")
    ModeBtn.Size = UDim2.fromOffset(62, 22)
    ModeBtn.Position = UDim2.new(1, -98, 0, 7)
    ModeBtn.Font = Enum.Font.GothamBold
    ModeBtn.TextSize = 11
    ModeBtn.TextColor3 = Color3.new(1, 1, 1)
    ModeBtn.Parent = Panel
    Instance.new("UICorner", ModeBtn).CornerRadius = UDim.new(0, 6)
    Title.Size = UDim2.new(1, -106, 0, 28)

    local function apply()
        local pab = UI.GridMode == "pabrik"
        local lah = UI.GridMode == "lahan"
        ModeBtn.Text = lah and I18N.T("Dirt Farm") or (pab and I18N.T("Pabrik") or "Farm")
        ModeBtn.BackgroundColor3 = lah and Color3.fromRGB(60, 140, 200)
            or (pab and Color3.fromRGB(200, 120, 40) or Color3.fromRGB(60, 60, 75))
        Title.Text = I18N.T(lah and "Tile Break Dirt Farm" or (pab and "Tile Break Pabrik" or "Grid Tile"))
        for key in pairs(CellButtons) do paintCell(key) end
        if lah then
            GridStart.Text = I18N.T(Build.Running and "STOP DIRT FARM" or "START DIRT FARM")
            GridStart.BackgroundColor3 = Build.Running and Color3.fromRGB(200, 60, 60) or COLOR_ON
        elseif pab then
            GridStart.Text = I18N.T(Pabrik.Running and "STOP PABRIK" or "START PABRIK")
            GridStart.BackgroundColor3 = Pabrik.Running and Color3.fromRGB(200, 60, 60) or COLOR_ON
        else
            local run = State.Running and not State.Override
            GridStart.Text = run and "STOP" or "START"
            GridStart.BackgroundColor3 = run and Color3.fromRGB(200, 60, 60) or COLOR_ON
        end
    end

    UI.setGridMode = function(m)
        UI.GridMode = m
        apply()
    end
    ModeBtn.MouseButton1Click:Connect(function() -- Farm -> Pabrik -> Lahan -> Farm
        local nxt = { farm = "pabrik", pabrik = "lahan", lahan = "farm" }
        UI.setGridMode(nxt[UI.GridMode] or "farm")
    end)
    apply()
end)() end

-- Panel bisa digeser lewat judul
do (function() -- fungsi sendiri: variabel di dalam tidak ikut batas 200 local
    local dragging, dragStart, startPos
    Title.Active = true
    Title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Panel.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            Panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end))
end)() end

task.spawn(function()
    while alive() do
        if GridGui.Enabled then
            local px, py = getPlayerTile()
            local t = px and ("ME (" .. px .. "," .. py .. ")") or I18N.T("Grid Tile | tidak di world")
            if Title.Text ~= t then Title.Text = t end
        end
        task.wait(0.5)
    end
end)

-- Tombol ▲/▼ untuk Fly (muncul saat Fly aktif)
local FlyPad = newScreenGui("ZekioTestFlyPad")
UI.FlyPad = FlyPad

local function flyButton(text, yOffset, onHold)
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(64, 64)
    b.AnchorPoint = Vector2.new(1, 0.5)
    b.Position = UDim2.new(1, -24, 0.5, yOffset)
    b.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    b.BackgroundTransparency = 0.2
    b.Text = text
    b.Font = Enum.Font.GothamBold
    b.TextSize = 28
    b.TextColor3 = Color3.new(1, 1, 1)
    b.AutoButtonColor = true
    b.Parent = FlyPad
    Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
    local st = Instance.new("UIStroke", b)
    st.Color = Color3.fromRGB(90, 90, 120)
    st.Thickness = 2
    -- dilepas saat jari diangkat (walau sudah geser keluar), supaya tidak nyangkut
    local heldInput = nil
    b.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then
            heldInput = input
            onHold(true)
        end
    end)
    table.insert(Connections, UserInputService.InputEnded:Connect(function(input)
        if heldInput and (input == heldInput
            or (input.UserInputType == Enum.UserInputType.MouseButton1
                and heldInput.UserInputType == Enum.UserInputType.MouseButton1)) then
            heldInput = nil
            onHold(false)
        end
    end))
    return b
end

flyButton("▲", -40, function(v) Misc.UpHeld = v end)
flyButton("▼", 40, function(v) Misc.DownHeld = v end)

---------------------------------------------------------------------
-- UI WINDUI
---------------------------------------------------------------------
-- Bahasa tersimpan dipakai langsung. Pilihan bahasa tidak menahan pembuatan menu.
Session.Report("Menghubungkan kontrol premium")
local Window = I18N.wrap(WindUI:CreateWindow({
    Title = "Zekio Supreme",
    Icon = "sprout",
    Author = "Premium P15 | engine r29",
    Folder = "ZekioSupremePremiumTest",
    Size = UDim2.fromOffset(640, 380),
    Theme = "Dark",
    Transparent = true,
    SideBarWidth = 150,
    ToggleKey = Enum.KeyCode.Insert,  -- PC: tekan Insert untuk buka/tutup menu
}))
assert(Window, "WindUI tidak mengembalikan jendela menu")
Session.MenuCreated = true
Session.StartupWindow = Window
pcall(function() if type(Window.Open) == "function" then Window:Open() end end)
Session.Report("Menu dibuat; menyiapkan tab")
-- Tombol minimize muncul di mobile DAN PC (OnlyMobile=false), bisa digeser.
-- Cadangan PC: kalau tombol susah dicari, tekan Insert.
pcall(function()
    Window:EditOpenButton({
        Title = "Zekio Supreme Premium",
        Icon = "sprout",
        Draggable = true,
        OnlyMobile = false,
    })
end)

-- Kalau 1 elemen error, tab lain tetap dibuat
local function safe(fn)
    local ok, err = pcall(fn)
    if not ok then Premium.RecordRegistrationError(err) end
end

-- Native premium sidebar keeps its own category order and styling.
local function makeTab(title,icon,group)
    return I18N.wrap(Premium.CreateTab(title))
end

-- Kotak di dalam tab yang bisa dibuka / ditutup (supaya tab tidak terlihat penuh).
-- WindUI lama tanpa fitur ini: cuma judul, elemen tetap di tab.
local function box(tab, title, opened)
    local ok, sec = pcall(function()
        return tab:Section({ Title = title, Box = true, BoxBorder = true, Opened = opened == true })
    end)
    if ok and type(sec) == "table" and type(sec.Toggle) == "function" then return sec end
    pcall(function() tab:Section({ Title = title }) end)
    return tab
end
local Box = {}

-- Angka pakai Slider; kalau gagal, pakai kotak input
local function addNumber(tab, o)
    local ok = pcall(function()
        tab:Slider({
            Title = o.Title,
            Desc = o.Desc,
            Step = o.Step or 1,
            Value = { Min = o.Min, Max = o.Max, Default = o.Default },
            Callback = function(v)
                v = tonumber(v)
                if v then o.Callback(v) end
            end,
        })
    end)
    if ok then return end
    safe(function()
        tab:Input({
            Title = o.Title,
            Desc = (o.Desc and (o.Desc .. " ") or "") .. "(" .. o.Min .. "-" .. o.Max .. ")",
            Value = tostring(o.Default),
            Placeholder = tostring(o.Default),
            Callback = function(text)
                local v = tonumber(text)
                if v then o.Callback(math.clamp(v, o.Min, o.Max)) end
            end,
        })
    end)
end

-- ===== TAB: FARM =====
local FarmTab = makeTab("Farm", "pickaxe", "farm")

safe(function()
    UI.Status = FarmTab:Paragraph({ Title = "Status", Desc = "-" })
end)

Box.FarmCtl = box(FarmTab, "Kontrol", true)
Box.FarmBlock = box(FarmTab, "Block", true)
Box.FarmSpeed = box(FarmTab, "Mode & Kecepatan", false)
Box.FarmDrop = box(FarmTab, "Drop seed", false)
safe(function()
    Box.FarmDrop:Toggle({Title="Auto Drop Seed",Desc="Antar seed hasil break ke Titik Drop, lalu kembali melanjutkan farm",
        Value=State.SeedDrop,Callback=function(on) State.SeedDrop=on end})
end)
addNumber(Box.FarmDrop,{Title="Drop saat seed mencapai",Min=2,Max=200,Step=1,Default=State.SeedDropAt,
    Callback=function(v) State.SeedDropAt=math.floor(v) end})
addNumber(Box.FarmDrop,{Title="Seed yang disisakan",Min=0,Max=199,Step=1,Default=State.SeedKeep,
    Callback=function(v) State.SeedKeep=math.floor(v) end})

safe(function()
    UI.FarmToggle = Box.FarmCtl:Toggle({
        Title = "Auto Farm",
        Desc = "Bisa juga lewat tombol START di Grid",
        Value = false,
        Callback = function(on)
            if on then startFarm() elseif State.Running then stopFarm() end
        end,
    })
end)

safe(function()
    Box.FarmCtl:Toggle({
        Title = "Auto Collect",
        Desc = "Ambil drop di semua tile grid (caranya ikut Mode collect)",
        Value = State.AutoCollect,
        Callback = function(on) State.AutoCollect = on end,
    })
end)



safe(function()
    Box.FarmCtl:Dropdown({
        Title = "Mode collect",
        Desc = "Berlaku untuk semua fitur. Sentuhan = seperti main manual. Remote = ambil dari jauh (cara lama, cepat)",
        Values = { "Sentuhan", "Remote" },
        Value = State.CollectMode,
        Callback = function(v)
            if type(v) == "table" then v = v[1] end
            if v == "Sentuhan" or v == "Remote" then State.CollectMode = v end
        end,
    })
end)

safe(function()
    Box.FarmCtl:Toggle({
        Title = "Collect di sekitar karakter",
        Desc = "Mode Remote: ambil dalam radius meski Auto Farm mati atau Grid kosong",
        Value = State.CollectAround,
        Callback = function(on) State.CollectAround = on end,
    })
end)

addNumber(Box.FarmCtl, {
    Title = "Radius collect (mode Remote)",
    Desc = "Jarak ambil drop di sekitar karakter (tile)",
    Min = 1, Max = 5, Step = 1, Default = State.CollectRadius,
    Callback = function(v) State.CollectRadius = math.floor(v) end,
})


safe(function()
    Box.FarmCtl:Button({
        Title = "Buka Grid Tile",
        Desc = "Kotak 5x5, tengah = karakter",
        Callback = function() GridGui.Enabled = true end,
    })
end)

-- ===== TAB: CLEAR WORLD =====
local ClearTab = makeTab("Clear World", "eraser", "farm")

safe(function()
    UI.ClearStatus = ClearTab:Paragraph({ Title = "Status Clear", Desc = "-" })
end)

Box.ClearCtl = box(ClearTab, "Kontrol", true)
Box.ClearSet = box(ClearTab, "Pengaturan", false)

safe(function()
    UI.ClearToggle = Box.ClearCtl:Toggle({
        Title = "Auto Clear World",
        Desc = "Bersihkan dari baris atas ke bawah",
        Value = false,
        Callback = function(on)
            if on then Auto.startClear() elseif Clear.Running then stopClear() end
        end,
    })
end)

safe(function()
    Box.ClearSet:Dropdown({
        Title = "Arah sapu",
        Desc = "Zig-zag lebih cepat (tidak balik ke kiri)",
        Values = { "Kiri → Kanan", "Zig-zag" },
        Value = Clear.Sweep,
        Callback = function(opt) Clear.Sweep = opt end,
    })
end)

safe(function()
    Box.ClearSet:Toggle({
        Title = "Pakai block pijakan",
        Desc = "Taruh block untuk lewat jurang / naik ke block melayang",
        Value = Clear.UseBlock,
        Callback = function(on)
            Clear.UseBlock = on
            Auto.resetReach()
        end,
    })
end)

safe(function()
    UI.ClearBlockDropdown = Box.ClearSet:Dropdown({
        Title = "Block pijakan",
        Desc = "Block yang dipakai untuk pijakan",
        Values = { "(memuat...)" },
        Callback = function(opt)
            local id = tonumber(string.match(opt or "", "%[(%d+)%]$"))
            if id then
                Clear.ScaffoldId = id
                Auto.resetReach()
            end
        end,
    })
end)

safe(function()
    Box.ClearSet:Toggle({
        Title = "Auto collect tiap habis pecah",
        Desc = "Drop di sekitar disusuri sampai tersentuh badan (tanpa remote)",
        Value = Clear.Collect,
        Callback = function(on) Clear.Collect = on end,
    })
end)

safe(function()
    Box.ClearCtl:Button({
        Title = "Reset tile yang dilewati",
        Desc = "Coba lagi tile yang tadi gagal",
        Callback = function()
            table.clear(Clear.Skip)
            table.clear(Auto.BadEdge)
            table.clear(Auto.ClearFail)
            Auto.updateClearStatus()
        end,
    })
end)

-- ===== TAB: FARMER =====
local FarmerTab = makeTab("Farmer", "leaf", "farm")

safe(function()
    UI.FarmerStatus = FarmerTab:Paragraph({ Title = "Status Farmer", Desc = "-" })
end)

Box.FarmerCtl = box(FarmerTab, "Kontrol", true)
Box.FarmerSeed = box(FarmerTab, "Seed", true)
Box.FarmerSpeed = box(FarmerTab, "Kecepatan", false)
Box.FarmerBlock = box(FarmerTab, "Block pijakan", false)

safe(function()
    Box.FarmerCtl:Toggle({
        Title = "Jangan Auto Collect Gems",
        Desc = "Lewati gems saat collect dan mencari drop. Block/seed tetap diambil sesuai pengaturan. Gems yang tersentuh badan masih bisa terambil oleh game.",
        Value = State.SkipCollectGems,
        Callback = function(on) State.SkipCollectGems = on == true end,
    })
end)

safe(function()
    UI.FarmerToggle = Box.FarmerCtl:Toggle({
        Title = "Jalankan Farmer",
        Desc = "Fokus panen pohon ready, tanpa auto drop. Auto Plant bisa diaktifkan terpisah",
        Value = false,
        Callback = function(on)
            if on then Auto.startFarmer() elseif Farmer.Running then stopFarmer() end
        end,
    })
end)

safe(function()
    UI.SeedDropdown = Box.FarmerSeed:Dropdown({
        Title = "Seed untuk ditanam",
        Desc = "Hanya seed yang ada di inventori",
        Values = { "(memuat...)" },
        Callback = function(opt)
            local id = tonumber(string.match(opt or "", "%[(%d+)%]$"))
            if id then
                Farmer.SeedId = id
                table.clear(Farmer.Skip)
                Auto.updateFarmerStatus()
            end
        end,
    })
end)

safe(function()
    Box.FarmerSeed:Button({
        Title = "Refresh daftar seed",
        Callback = function() UI.later("invForce", function() UI.checkInventory(true) end) end,
    })
end)

safe(function()
    UI.FarmerHarvestToggle = Box.FarmerCtl:Toggle({
        Title = "Auto Harvest",
        Desc = "Panen pohon ready atas, bawah, kiri dan kanan dalam jangkauan pukul; Auto Plant mati",
        Value = Farmer.Harvest,
        Callback = Farmer.setHarvest,
    })
end)

safe(function()
    UI.FarmerPlantToggle = Box.FarmerCtl:Toggle({
        Title = "Auto Plant",
        Desc = "Tanam sambil menyusuri baris, lewati pohon yang sudah ada; ambil seed pilihan saat habis",
        Value = Farmer.Plant,
        Callback = Farmer.setPlant,
    })
end)

safe(function()
    Box.FarmerCtl:Toggle({
        Title = "Auto Collect",
        Desc = "Ambil hasil panen di sekitar karakter",
        Value = Farmer.Collect,
        Callback = function(on) Farmer.Collect = on end,
    })
end)

addNumber(Box.FarmerSpeed, {
    Title = "Speed Harvest (ms)",
    Desc = "Farmer: jeda setelah satu putaran panen area",
    Min = 140, Max = 2000, Step = 10, Default = Farmer.HarvestMs,
    Callback = function(v) Farmer.HarvestMs = math.floor(v) end,
})

addNumber(Box.FarmerSpeed, {
    Title = "Speed Plant (ms)",
    Desc = "Farmer: jeda setelah satu putaran tanam area",
    Min = 140, Max = 2000, Step = 10, Default = Farmer.PlantMs,
    Callback = function(v) Farmer.PlantMs = math.floor(v) end,
})

safe(function()
    Box.FarmerBlock:Toggle({
        Title = "Pakai block pijakan",
        Desc = "Taruh block kalau tidak ada jalan (block tetap tertinggal)",
        Value = Farmer.UseBlock,
        Callback = function(on)
            Farmer.UseBlock = on
            Auto.resetReach()
        end,
    })
end)

safe(function()
    UI.FarmerBlockDropdown = Box.FarmerBlock:Dropdown({
        Title = "Block pijakan",
        Desc = "Block yang dipakai untuk pijakan",
        Values = { "(memuat...)" },
        Callback = function(opt)
            local id = tonumber(string.match(opt or "", "%[(%d+)%]$"))
            if id then
                Farmer.ScaffoldId = id
                Auto.resetReach()
            end
        end,
    })
end)

-- ===== FARM: MODE & KECEPATAN =====
local SpeedTab = Box.FarmSpeed -- digabung ke tab Farm

-- Session-only test switch: normal slider settings and saved config stay intact.
State.FastBreakTest = false
safe(function()
    SpeedTab:Toggle({
        Title = "Fast Break (Tes)",
        Desc = "Farm / Clear: jeda pukul 190 ms, jeda setelah hancur 0 ms. Matikan untuk kembali ke slider normal. Kecepatan nyata bergantung respons game.",
        Value = false,
        Callback = function(on) State.FastBreakTest = on == true end,
    })
end)


safe(function()
    SpeedTab:Dropdown({
        Title = "Mode",
        Desc = "Place semua tile dulu, lalu break",
        Values = { "Place + Break", "Break saja", "Place saja" },
        Value = State.Mode,
        Callback = function(opt) State.Mode = opt end,
    })
end)

addNumber(SpeedTab, {
    Title = "Speed Place (ms)",
    Desc = "Jeda setelah tiap place",
    Min = 140, Max = 1000, Step = 10, Default = State.PlaceMs,
    Callback = function(v) State.PlaceMs = math.floor(v) end,
})

addNumber(SpeedTab, {
    Title = "Speed Break (ms)",
    Desc = "Jeda tiap pukulan (normal 220). Dipakai juga Clear",
    Min = 200, Max = 1000, Step = 10, Default = State.BreakMs,
    Callback = function(v) State.BreakMs = math.floor(v) end,
})

addNumber(SpeedTab, {
    Title = "Multi target break",
    Desc = "Auto Farm: tile dipukul bergantian (seperti 2 jari). Pakai Rayman's Fist = 2-3 tile segaris sekali pukul",
    Min = 1, Max = 5, Step = 1, Default = State.MultiTarget,
    Callback = function(v) State.MultiTarget = math.clamp(math.floor(v), 1, 5) end,
})

addNumber(SpeedTab, {
    Title = "Jeda setelah hancur (ms)",
    Desc = "Tunggu sebelum lanjut ke tile berikutnya",
    Min = 0, Max = 1500, Step = 50, Default = State.AfterBreakMs,
    Callback = function(v) State.AfterBreakMs = math.floor(v) end,
})

-- ===== TAB: PENGATURAN (Opsi + Misc digabung) =====
local SetTab = makeTab("Pengaturan", "sliders-horizontal", "setel")
Box.SetChar = box(SetTab, "Karakter", true)
Box.SetOpt = box(SetTab, "Opsi", true)
local OptTab = Box.SetOpt

safe(function()
    OptTab:Toggle({
        Title = "Mode Lite",
        Desc = "Matikan particle & suara (HP low-end)",
        Value = State.LiteMode,
        Callback = function(on) setLite(on) end,
    })
end)

safe(function()
    OptTab:Toggle({
        Title = "Mute suara pukulan",
        Value = State.MutePunch,
        Callback = function(on) State.MutePunch = on end,
    })
end)

safe(function()
    OptTab:Toggle({
        Title = "Animasi aksi",
        Desc = "Tangan bergerak saat break / place / tanam / panen + efek place. Matikan untuk hemat FPS",
        Value = State.Visual,
        Callback = function(on)
            State.Visual = on
            if on and not Anim.fn and Refs.World then
                notify("Animasi", "Fungsi animasi game tidak ketemu (tekan 'Hubungkan ke game')", 4)
            end
        end,
    })
end)

safe(function()
    OptTab:Toggle({
        Title = "Anti AFK",
        Value = State.AntiAfk,
        Callback = function(on) State.AntiAfk = on end,
    })
end)

addNumber(OptTab, {
    Title = "Pukulan per block (cadangan)",
    Desc = "Dipakai kalau 'Pukul: TIDAK'. 0 = otomatis",
    Min = 0, Max = 20, Step = 1, Default = State.HitsOverride,
    Callback = function(v) State.HitsOverride = math.floor(v) end,
})

-- ===== FARM: PILIH BLOCK =====
local InvTab = Box.FarmBlock -- digabung ke tab Farm

safe(function()
    UI.InvDropdown = InvTab:Dropdown({
        Title = "Pilih Block",
        Desc = "Hanya item yang bisa di-place",
        Values = { "(memuat...)" },
        Callback = function(opt)
            local id = tonumber(string.match(opt or "", "%[(%d+)%]$"))
            if id then
                State.SelectedId = id
                updateStatus()
            end
        end,
    })
end)

safe(function()
    InvTab:Button({
        Title = "Refresh daftar",
        Callback = function() UI.later("invForce", function() UI.checkInventory(true) end) end,
    })
end)

-- ===== PENGATURAN: KARAKTER =====
local MiscTab = Box.SetChar

addNumber(MiscTab, {
    Title = "Walkspeed (%)",
    Desc = "100 = normal",
    Min = 50, Max = 500, Step = 10, Default = Misc.Speed,
    Callback = function(v) setSpeed(v) end,
})

safe(function()
    MiscTab:Toggle({
        Title = "Infinite Jump",
        Desc = "Lompat di udara (bisa kena rollback)",
        Value = false,
        Callback = function(on) setInfJump(on) end,
    })
end)

safe(function()
    UI.GhostToggle = MiscTab:Toggle({
        Title = "Fly + Tembus Block (beta)",
        Desc = "Eksperimental: tombol ▲/▼; posisi dapat dikembalikan oleh server",
        Value = false,
        Callback = function(on) setGhost(on) end,
    })
end)

-- ===== TAB: AUTO CHAT =====
local ChatTab = makeTab("Auto Chat", "message-circle", "fitur")

safe(function()
    UI.SpamStatus = ChatTab:Paragraph({ Title = "Status Chat", Desc = "-" })
end)

Box.ChatCtl = box(ChatTab, "Kontrol", true)
Box.ChatMsg = box(ChatTab, "Pesan", true)

safe(function()
    Box.ChatMsg:Input({
        Title = "Daftar pesan",
        Desc = "Pisahkan dengan |   contoh: halo|jual dirt",
        Value = table.concat(Spam.Texts, "|"),
        Placeholder = "pesan 1|pesan 2|pesan 3",
        Callback = function(text)
            Spam.Texts = parseSpamTexts(text)
            Spam.Index = 1
            updateSpamStatus()
        end,
    })
end)

addNumber(Box.ChatMsg, {
    Title = "Interval (detik)",
    Desc = "Jeda antar pesan (min 3 detik)",
    Min = 3, Max = 120, Step = 1, Default = Spam.IntervalSec,
    Callback = function(v) Spam.IntervalSec = math.max(3, math.floor(v)) end,
})

safe(function()
    UI.SpamToggle = Box.ChatCtl:Toggle({
        Title = "Auto Chat",
        Desc = "Kirim pesan bergantian sesuai urutan",
        Value = false,
        Callback = function(on)
            Spam.On = on
            if on then
                if #Spam.Texts == 0 then notify("Auto Chat", "Isi daftar pesan dulu (tekan Enter setelah mengetik)", 4) end
                Spam.NextAt = 0 -- langsung kirim pesan pertama
            end
            updateSpamStatus()
        end,
    })
end)

safe(function()
    Box.ChatCtl:Button({
        Title = "Kirim 1 pesan sekarang",
        Desc = "Tes kirim pesan berikutnya",
        Callback = function()
            task.spawn(function()
                sendNextChat()
                updateSpamStatus()
            end)
        end,
    })
end)

---------------------------------------------------------------------
-- PENJAGA: deteksi Mod / Dev / pemain yang masuk world
---------------------------------------------------------------------
-- Cara kerja:
--   1. Tiap 0.5 detik baca daftar pemain di world (data game "Others").
--   2. Role dicek pakai modul Roles game (Developer / Moderator, undercover juga ketahuan).
--   3. Ada yang dicari -> semua aktivitas dihentikan, bisa juga langsung keluar world.
--   4. Setelah aman -> aktivitas sebelumnya dilanjutkan.
--      Mode keluar: tunggu X detik, masuk world lagi, cek lagi.
--      Masih ada orangnya -> keluar lagi. Sudah aman -> lanjut (Auto Farm jalan balik ke posisi awal).

do (function() -- fungsi sendiri: variabel di dalam tidak ikut batas 200 local
    local function strip(s) return (tostring(s or ""):gsub("`.", "")) end

    local function roleOf(uid)
        if not (RolesOk and type(RolesModule) == "table") then return nil end
        local okD, dev = pcall(RolesModule.isDeveloper, uid)
        if okD and dev then return "Developer" end
        local okM, mod = pcall(RolesModule.isModerator, uid)
        if okM and mod then return "Moderator" end
        return nil
    end

    local function worldName()
        local n = Refs.World and rawget(Refs.World, "name")
        return type(n) == "string" and n or ""
    end

    -- Pemain lain di world ini: { id, name, role }
    local function playersHere()
        local out = {}
        local o = Refs.Others
        if not o or type(rawget(o, "list")) ~= "function" then return out end
        local ok, list = pcall(o.list)
        if not ok or type(list) ~= "table" then return out end
        for _, e in ipairs(list) do
            local uid = type(e) == "table" and tonumber(e[1] or e.userId)
            if uid and uid ~= LocalPlayer.UserId then
                out[#out + 1] = { id = uid, name = strip(e[2] or e.name or uid), role = roleOf(uid) }
            end
        end
        return out
    end
    Guard.playersHere = playersHere

    local function threatsOf(list)
        local out = {}
        for _, p in ipairs(list) do
            if p.role or (Guard.Who == "Semua pemain" and not Guard.Allow[p.id]) then
                out[#out + 1] = p
            end
        end
        return out
    end

    local function label(p)
        local under = false
        if p.role and type(RolesModule.isUndercover) == "function" then
            local ok, u = pcall(RolesModule.isUndercover, p.id)
            under = ok and u == true
        end
        return p.name .. " (" .. (p.role or "Pemain") .. (under and ", undercover" or "") .. ")"
    end

    local function names(list, max)
        local t = {}
        for i, p in ipairs(list) do
            if i > (max or 4) then
                t[#t + 1] = "+" .. (#list - i + 1) .. " lagi"
                break
            end
            t[#t + 1] = label(p)
        end
        return table.concat(t, ", ")
    end

    local function anyRunning()
        return State.Running or Clear.Running or Farmer.Running or Splice.Running or Spam.On
            or Pabrik.Running or Build.Running or Vend.Running
    end

    -- Catat aktivitas yang sedang jalan (untuk dilanjutkan nanti)
    local function snapshot()
        local tx, ty = Auto.here()
        return {
            farm = State.Running and not State.Override, clear = Clear.Running, farmer = Farmer.Running,
            spam = Spam.On, splice = Splice.Running, pabrik = Pabrik.Running, build = Build.Running, vend = Vend.Running,
            world = worldName(), tx = tx, ty = ty,
        }
    end

    local function stopAll()
        Auto.stopWalk()
        if Pabrik.Running then Pabrik.stop() end
        if Build.Running then Build.stop() end
        if State.Running then stopFarm() end
        if Clear.Running then
            stopClear()
            Clear.Status = "Dijeda Penjaga"
        end
        if Farmer.Running then
            stopFarmer()
            Farmer.Status = "Dijeda Penjaga"
        end
        if Splice.Running and Splice.stop then Splice.stop() end
        if Vend.Running and Vend.stop then Vend.stop() end
        if Spam.On then
            Spam.On = false
            if UI.SpamToggle then pcall(function() UI.SpamToggle:Set(false) end) end
        end
        Auto.releaseInput()
    end

    -- Keluar world = sama seperti tombol "Exit World" game
    local function leaveWorld()
        local m = Refs.Menu
        if m and type(rawget(m, "openPicker")) == "function" and pcall(m.openPicker) then
            return true
        end
        local w = Refs.World
        if w and type(rawget(w, "call")) == "function" then
            return (pcall(w.call, "LeaveWorld"))
        end
        return false
    end

    -- Masuk world lewat menu game (sama seperti ketik nama world lalu Enter)
    local function enterWorld(name, live)
        if live and not live() then return false, "Perjalanan dibatalkan" end
        local w = Refs.World
        if not w or name == "" then return false, "nama world tidak diketahui" end
        local oldFg = rawget(w, "fg")
        local m = Refs.Menu
        if m and type(rawget(m, "enter")) == "function" then
            local ok, err = pcall(m.enter, name)
            if live and not ok then return false, tostring(err) end
        elseif type(rawget(w, "enter")) == "function" then
            local ok, res, msg = pcall(w.enter, name)
            if ok and not res then return false, strip(msg) end
        else
            return false, "fungsi masuk world tidak ketemu"
        end
        -- berhasil kalau data world sudah diganti yang baru
        local t0 = os.clock()
        while alive() and os.clock() - t0 < 8 do
            if live and not live() then return false, "Perjalanan dibatalkan" end
            local current = Refs.World
            if live and current and current ~= w and rawget(current, "name") == name
                and type(rawget(current, "fg")) == "table" then return true end
            if rawget(w, "fg") ~= oldFg then return true end
            task.wait(0.25)
        end
        return false, "world penuh / dikunci / gagal"
    end

    local function stillBack(token)
        return alive() and Guard.Token == token and Guard.Mode == "back"
    end

    -- Lanjutkan aktivitas yang tadi dihentikan
    local function resumeAll(saved, token)
        if not saved then return end
        if saved.world ~= "" and worldName() ~= saved.world then
            notify("Penjaga", "World sudah beda, aktivitas tidak dilanjutkan", 5)
            return
        end
        if saved.spam and not Spam.On and stillBack(token) then
            if UI.SpamToggle then pcall(function() UI.SpamToggle:Set(true) end) end
            Spam.On = true
        end
        if saved.build then
            if stillBack(token) then Build.start() end
        elseif saved.pabrik then
            if stillBack(token) then Pabrik.start() end
        elseif saved.farm then
            -- Auto Farm memakai tile di sekitar karakter, jadi harus balik ke posisi awal
            local hx, hy = Auto.here()
            if saved.tx and (hx ~= saved.tx or hy ~= saved.ty) then
                Guard.BackText = ("Jalan balik ke posisi farm (%d,%d)"):format(saved.tx, saved.ty)
                local ok = Auto.walkTo(saved.tx, saved.ty, 45)
                if not ok and stillBack(token) then ok = Auto.walkTo(saved.tx, saved.ty, 30) end
                if not ok then
                    if stillBack(token) then
                        notify("Penjaga", "Gagal balik ke posisi farm. Auto Farm tidak dilanjutkan", 6)
                    end
                    return
                end
            end
            if stillBack(token) then startFarm() end
        elseif saved.clear then
            if stillBack(token) then Auto.startClear() end
        elseif saved.farmer then
            if stillBack(token) then Auto.startFarmer() end
        elseif saved.vend then
            if stillBack(token) and Vend.start then Vend.start() end
        elseif saved.splice then
            if stillBack(token) and Splice.start then Splice.start() end
        end
    end

    local function beginResume()
        local saved = Guard.Saved
        Guard.Token += 1
        local token = Guard.Token
        Guard.Mode = "back"
        Guard.BackText = nil
        task.spawn(function()
            local ok, err = pcall(resumeAll, saved, token)
            if not ok then warn("[Zekio Supreme Premium] Penjaga lanjut error: " .. tostring(err)) end
            if Guard.Token == token and Guard.Mode == "back" then
                Guard.Mode, Guard.Saved, Guard.BackText = "idle", nil, nil
            end
        end)
    end

    local function goAway()
        if not leaveWorld() then
            notify("Penjaga", "Gagal keluar world, aktivitas hanya dijeda", 5)
            Guard.Mode = "pause"
            return
        end
        task.wait(0.3)
        Guard.LeftFg = Refs.World and rawget(Refs.World, "fg")
        Guard.BackAt = os.clock() + Guard.BackSec
        Guard.Mode = Guard.AutoBack and "away" or "out"
        Guard.Status = "Keluar world"
    end

    -- Ada orang baru yang dicari masuk world
    local function trigger(fresh)
        Guard.Detected += #fresh
        notify("Penjaga", "Masuk world: " .. names(fresh), 6)
        Hook.send("penjaga", "Masuk world " .. worldName() .. ": " .. names(fresh))
        if not Guard.StopAll and not Guard.Leave then return end -- hanya peringatan
        -- simpan aktivitas (kalau sedang jalan balik, pakai catatan lama)
        if Guard.Mode ~= "back" and (anyRunning() or not Guard.Saved) then
            Guard.Saved = snapshot()
        end
        Guard.Token += 1
        stopAll()
        Guard.CalmAt = nil
        if Guard.Leave then
            goAway()
            if Guard.Mode == "away" then
                notify("Penjaga", "Keluar world. Masuk lagi dalam " .. Guard.BackSec .. " detik", 5)
                Hook.send("penjaga", "Keluar world, masuk lagi dalam " .. Guard.BackSec .. " detik")
            elseif Guard.Mode == "out" then
                notify("Penjaga", "Keluar world", 4)
            end
        else
            Guard.Mode = "pause"
        end
    end

    -- Setelah masuk world lagi: cek dulu, masih ada orangnya atau tidak
    local function checkAfterEnter()
        Auto.resetReach()
        pcall(findDropRefs)
        pcall(Auto.findTreeRefs)
        table.clear(DropFailUntil)
        task.wait(1.5) -- tunggu daftar pemain terisi
        local th = threatsOf(playersHere())
        if #th > 0 then
            for _, p in ipairs(th) do Guard.Alerted[p.id] = true end
            notify("Penjaga", "Masih ada " .. names(th) .. ". Keluar lagi", 5)
            goAway()
            return
        end
        notify("Penjaga", "World aman, lanjut aktivitas", 4)
        Hook.send("penjaga", "World " .. worldName() .. " aman, lanjut aktivitas")
        beginResume()
    end

    -- Staff yang online di server (bukan hanya di world ini)
    local lastScan, staffText = -10, "-"
    local function serverStaff()
        if os.clock() - lastScan < 3 then return staffText end
        lastScan = os.clock()
        local t = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local r = roleOf(plr.UserId)
                if r then t[#t + 1] = (plr.DisplayName or plr.Name) .. " (" .. r .. ")" end
            end
        end
        staffText = (#t > 0) and table.concat(t, ", ") or "tidak ada"
        return staffText
    end

    function Guard.tick(here)
        if not Guard.On then
            Guard.Status = "Mati"
            return
        end
        local now = os.clock()
        local mode = Guard.Mode

        -- ===== sedang di luar world =====
        if mode == "away" or mode == "out" then
            local fgNow = Refs.World and rawget(Refs.World, "fg")
            if Guard.LeftFg and fgNow ~= Guard.LeftFg then
                -- sudah masuk world lagi secara manual
                if mode == "away" and Guard.Saved and worldName() == Guard.Saved.world then
                    checkAfterEnter()
                else
                    Guard.Mode, Guard.Saved = "idle", nil
                end
                return
            end
            local name = Guard.Saved and Guard.Saved.world or ""
            if mode == "out" or name == "" then
                Guard.Status = "Sudah keluar world (lanjut otomatis mati)"
                return
            end
            local left = Guard.BackAt - now
            if left > 0 then
                Guard.Status = ("Di luar world. Masuk lagi ke %s dalam %d detik"):format(name, math.ceil(left))
                return
            end
            Guard.Status = "Masuk lagi ke " .. name .. "..."
            Guard.updateStatus({})
            local ok, err = enterWorld(name)
            if not ok then
                Guard.BackAt = os.clock() + math.max(15, Guard.BackSec)
                notify("Penjaga", "Gagal masuk " .. name .. ": " .. tostring(err) .. ". Dicoba lagi nanti", 5)
                return
            end
            checkAfterEnter()
            return
        end

        -- ===== di dalam world =====
        local present = {}
        for _, p in ipairs(here) do present[p.id] = true end
        for id in pairs(Guard.Alerted) do
            if not present[id] then Guard.Alerted[id] = nil end -- sudah pergi
        end
        local threats = threatsOf(here)
        local fresh = {}
        for _, p in ipairs(threats) do
            if not Guard.Alerted[p.id] then
                Guard.Alerted[p.id] = true
                fresh[#fresh + 1] = p
            end
        end
        if #fresh > 0 then
            trigger(fresh)
            if Guard.Mode == "away" or Guard.Mode == "out" then return end
        end

        if #threats > 0 then
            Guard.CalmAt = nil
            Guard.Status = (Guard.Mode == "pause" and "Dijeda. Ada: " or "Waspada. Ada: ") .. names(threats)
            return
        end

        if Guard.Mode == "pause" then
            Guard.CalmAt = Guard.CalmAt or now
            local wait = Guard.CalmSec - (now - Guard.CalmAt)
            if wait > 0 then
                Guard.Status = ("Mereka sudah pergi. Lanjut dalam %d detik"):format(math.ceil(wait))
                return
            end
            Guard.CalmAt = nil
            if Guard.AutoBack and Guard.Saved then
                notify("Penjaga", "Sudah aman, lanjut aktivitas", 4)
                beginResume()
            else
                Guard.Mode, Guard.Saved = "idle", nil
            end
            return
        end

        if Guard.Mode == "back" then
            Guard.Status = Guard.BackText or "Lanjut aktivitas..."
            return
        end
        Guard.Status = "Aman"
    end

    function Guard.updateStatus(here)
        local txt = table.concat({
            "Status: " .. Guard.Status .. (Refs.Others and "" or " (data pemain belum ketemu: tekan 'Hubungkan ke game')"),
            "Pemain di world: " .. ((#here == 0) and "tidak ada" or names(here, 6)),
            "Staff online di server: " .. serverStaff(),
            "Terdeteksi: " .. Guard.Detected .. " kali",
        }, "\n")
        if txt ~= Guard.LastTxt then
            Guard.LastTxt = txt
            if UI.GuardStatus then pcall(function() UI.GuardStatus:SetDesc(txt) end) end
        end
    end

    -- Nyalakan / matikan Penjaga
    function Guard.set(on)
        Guard.On = on
        Guard.Token += 1
        Auto.stopWalk()
        Guard.Mode, Guard.Saved, Guard.CalmAt, Guard.BackText = "idle", nil, nil, nil
        table.clear(Guard.Alerted)
        table.clear(Guard.Allow)
        if on then
            -- pemain biasa yang sudah ada sekarang diabaikan (teman / akun sendiri)
            for _, p in ipairs(playersHere()) do
                if not p.role then Guard.Allow[p.id] = true end
            end
        end
    end

    -- dipakai fitur lain (Auto Reconnect)
    Guard.snapshot = snapshot
    Guard.stopAll = stopAll
    Guard.enterWorld = enterWorld
    Guard.leaveWorld = leaveWorld
    Guard.worldName = worldName
    Guard.anyRunning = anyRunning
    function Guard.afterEnter()
        Auto.resetReach()
        pcall(findDropRefs)
        pcall(Auto.findTreeRefs)
        table.clear(DropFailUntil)
    end
    function Guard.resumeSaved(saved)
        Guard.Saved = saved
        beginResume()
    end

    function Guard.allowNow()
        local n = 0
        for _, p in ipairs(playersHere()) do
            if not p.role then
                Guard.Allow[p.id] = true
                n += 1
            end
        end
        return n
    end

    task.spawn(function()
        while alive() do
            local here = (Guard.Mode ~= "away" and Guard.Mode ~= "out") and playersHere() or {}
            local ok, err = pcall(Guard.tick, here)
            if not ok then warn("[Zekio Supreme Premium] Penjaga error: " .. tostring(err)) end
            Guard.updateStatus(here)
            task.wait(0.5)
        end
    end)
end)() end

Config.add("Penjaga", Guard, { "On", "Who", "StopAll", "Leave", "AutoBack", "BackSec", "CalmSec" }, { On = true })

-- ===== TAB: PENJAGA =====
do (function() -- fungsi sendiri: variabel di dalam tidak ikut batas 200 local
    local GuardTab = makeTab("Penjaga", "eye", "aman")

    safe(function()
        UI.GuardStatus = GuardTab:Paragraph({ Title = "Status Penjaga", Desc = "Mati" })
    end)

    local gCtl = box(GuardTab, "Kontrol", true)
    local gAct = box(GuardTab, "Aksi saat terdeteksi", true)
    local gTime = box(GuardTab, "Waktu", false)
    local gMore = box(GuardTab, "Lainnya", false)

    safe(function()
        UI.GuardToggle = gCtl:Toggle({
            Title = "Aktifkan Penjaga",
            Desc = "Pantau Mod / Dev / pemain yang masuk world",
            Value = false,
            Callback = function(on) Guard.set(on) end,
        })
    end)

    safe(function()
        gCtl:Dropdown({
            Title = "Yang dideteksi",
            Desc = "Semua pemain: yang sudah ada saat dinyalakan diabaikan",
            Values = { "Staff (Mod/Dev)", "Semua pemain" },
            Value = Guard.Who,
            Callback = function(opt) Guard.Who = opt end,
        })
    end)

    safe(function()
        gAct:Toggle({
            Title = "Diam semua aktivitas",
            Desc = "Stop Auto Farm, Clear, Farmer & Auto Chat",
            Value = Guard.StopAll,
            Callback = function(on) Guard.StopAll = on end,
        })
    end)

    safe(function()
        gAct:Toggle({
            Title = "Keluar world",
            Desc = "Langsung keluar world saat terdeteksi",
            Value = Guard.Leave,
            Callback = function(on) Guard.Leave = on end,
        })
    end)

    safe(function()
        gAct:Toggle({
            Title = "Lanjut otomatis setelah aman",
            Desc = "Keluar world: masuk lagi, cek, lalu lanjut aktivitas sebelumnya",
            Value = Guard.AutoBack,
            Callback = function(on) Guard.AutoBack = on end,
        })
    end)

    addNumber(gTime, {
        Title = "Masuk world lagi setelah (detik)",
        Desc = "Untuk mode keluar world",
        Min = 20, Max = 600, Step = 5, Default = Guard.BackSec,
        Callback = function(v) Guard.BackSec = math.floor(v) end,
    })

    addNumber(gTime, {
        Title = "Tunggu aman (detik)",
        Desc = "Untuk mode diam: jeda setelah mereka pergi",
        Min = 2, Max = 60, Step = 1, Default = Guard.CalmSec,
        Callback = function(v) Guard.CalmSec = math.floor(v) end,
    })

    safe(function()
        gMore:Button({
            Title = "Abaikan pemain yang ada sekarang",
            Desc = "Untuk teman / akun sendiri (staff tetap dideteksi)",
            Callback = function()
                notify("Penjaga", Guard.allowNow() .. " pemain diabaikan", 3)
            end,
        })
    end)

    safe(function()
        gMore:Button({
            Title = "Batalkan tunggu / lanjut",
            Desc = "Hentikan proses keluar-masuk & lanjut otomatis",
            Callback = function()
                Guard.set(Guard.On)
                notify("Penjaga", "Dibatalkan", 3)
            end,
        })
    end)
end)() end

---------------------------------------------------------------------
-- BONUS: auto klaim quest & auto redeem code
---------------------------------------------------------------------
-- Pakai panggilan yang sama dengan menu Quest & Redeem game:
--   Net.call("Quests", "list")            -> daftar quest hari ini
--   Net.call("Quests", "claim", id)       -> klaim hadiah (server yang cek syaratnya)
--   Net.call("ActiveCodes")               -> daftar code aktif
--   Net.call("ModCommand", "redeemcode", code) -> tukar code (dipakai menu Redeem game)
local Bonus = {
    Quest = false,
    Redeem = false,
    QuestEvery = 30,   -- cek quest tiap 30 detik
    CodeEvery = 300,   -- cek code tiap 5 menit
    NextQuest = 0,
    NextCode = 0,
    Claimed = 0,
    Redeemed = 0,
    Tried = {},        -- code yang sudah dicoba
    QuestFail = {},    -- quest yang ditolak server (dicoba lagi nanti)
    QuestText = "-",
    CodeText = "-",
    ResetAt = nil,
}

do (function() -- fungsi sendiri: variabel di dalam tidak ikut batas 200 local
    local function strip(s) return (tostring(s or ""):gsub("`.", "")) end

    local function netCall(...)
        if NetOk and type(Net) == "table" and type(Net.call) == "function" then
            return pcall(Net.call, ...)
        end
        return false, "Net.call tidak ada"
    end

    local function timeText(sec)
        sec = math.max(0, math.floor(sec or 0))
        if sec >= 3600 then return ("%dj %dm"):format(sec // 3600, sec % 3600 // 60) end
        return ("%dm %dd"):format(sec // 60, sec % 60)
    end

    local function setGems(n)
        local g = Refs.Gems
        if type(n) == "number" and g and type(rawget(g, "setGems")) == "function" then
            pcall(g.setGems, n)
        end
    end

    function Bonus.checkQuests()
        if Bonus.BusyQ then return end
        Bonus.BusyQ = true
        local ok, good, data = netCall("Quests", "list")
        if not ok then
            Bonus.QuestText = "Gagal ambil quest: " .. strip(good)
        elseif not good or type(data) ~= "table" or type(data.quests) ~= "table" then
            Bonus.QuestText = "Quest belum bisa diambil" .. (type(data) == "string" and (": " .. strip(data)) or "")
        else
            local total, done, wait = 0, 0, 0
            local now = os.clock()
            for _, q in ipairs(data.quests) do
                total += 1
                local have, need = tonumber(q.have) or 0, tonumber(q.need) or math.huge
                if q.claimed then
                    done += 1
                elseif have >= need and not ((Bonus.QuestFail[q.id] or 0) > now) then
                    -- syarat sama seperti tombol Claim game
                    local okc, success, msg, _, gems = netCall("Quests", "claim", q.id)
                    if okc and success then
                        done += 1
                        Bonus.Claimed += 1
                        local reward = q.xp and (tostring(q.reward) .. " XP") or (tostring(q.reward) .. " gems")
                        notify("Quest diklaim", strip(q.text or q.id) .. "  +" .. reward, 4)
                        Hook.send("bonus", "Quest diklaim: " .. strip(q.text or q.id) .. " +" .. reward)
                        setGems(gems)
                    else
                        wait += 1
                        Bonus.QuestFail[q.id] = now + 120
                        if okc and msg then Bonus.LastQuestMsg = strip(msg) end
                    end
                    task.wait(0.6)
                elseif have >= need then
                    wait += 1
                end
            end
            Bonus.ResetAt = os.clock() + (tonumber(data.resetIn) or 0)
            Bonus.QuestText = ("Selesai %d/%d | diklaim script: %d"):format(done, total, Bonus.Claimed)
                .. ((wait > 0) and (" | ditolak: " .. wait) or "")
        end
        Bonus.BusyQ = false
    end

    -- Tukar 1 code. Berhasil kalau balasan server diawali warna hijau (`2)
    function Bonus.redeem(code)
        local ok, res = netCall("ModCommand", "redeemcode", code)
        if not ok then return nil, "tidak bisa ke server" end
        local lines = type(res) == "table" and type(res.lines) == "table" and res.lines or nil
        if not lines then return false, "balasan kosong" end
        local first = tostring(lines[1] or "")
        local parts = {}
        for _, l in ipairs(lines) do parts[#parts + 1] = strip(l) end
        return string.sub(first, 1, 2) == "`2", table.concat(parts, " ")
    end

    function Bonus.checkCodes()
        if Bonus.BusyR then return end
        Bonus.BusyR = true
        local ok, list = netCall("ActiveCodes")
        if not ok or type(list) ~= "table" then
            Bonus.CodeText = "Gagal ambil daftar code"
        elseif list.note ~= nil then
            Bonus.CodeText = "Redeem sedang ditutup: " .. strip(list.note)
        else
            local total, have, newOk = 0, 0, 0
            for _, c in ipairs(list) do
                total += 1
                local code = c.code and tostring(c.code)
                if c.done then
                    have += 1
                elseif code and not Bonus.Tried[code] and not (type(c.uses) == "number" and c.uses == 0) then
                    local success, msg = Bonus.redeem(code)
                    if success ~= nil then Bonus.Tried[code] = true end -- server sudah jawab
                    if success then
                        have += 1
                        newOk += 1
                        Bonus.Redeemed += 1
                        notify("Redeem berhasil", code .. ": " .. tostring(msg), 5)
                        Hook.send("bonus", "Redeem berhasil " .. code .. ": " .. tostring(msg))
                    elseif success == false then
                        Bonus.LastCodeMsg = code .. ": " .. tostring(msg)
                    end
                    task.wait(1)
                end
            end
            Bonus.CodeText = ("Code aktif: %d | sudah ditukar: %d | ditukar script: %d"):format(total, have, Bonus.Redeemed)
        end
        Bonus.BusyR = false
    end

    function Bonus.updateStatus()
        local now = os.clock()
        local q = Bonus.QuestText
        if Bonus.ResetAt then q = q .. "\nQuest baru dalam " .. timeText(Bonus.ResetAt - now) end
        if Bonus.LastQuestMsg then q = q .. "\nPesan terakhir: " .. Bonus.LastQuestMsg end
        q = q .. "\n" .. (Bonus.Quest and ("Cek lagi dalam " .. math.max(0, math.ceil(Bonus.NextQuest - now)) .. " detik") or "Auto klaim mati")
        local c = Bonus.CodeText
        if Bonus.LastCodeMsg then c = c .. "\nPesan terakhir: " .. Bonus.LastCodeMsg end
        c = c .. "\n" .. (Bonus.Redeem and ("Cek lagi dalam " .. timeText(Bonus.NextCode - now)) or "Auto redeem mati")
        if UI.QuestStatus then pcall(function() UI.QuestStatus:SetDesc(q) end) end
        if UI.CodeStatus then pcall(function() UI.CodeStatus:SetDesc(c) end) end
    end

    task.spawn(function()
        while alive() do
            local now = os.clock()
            if Bonus.Quest and now >= Bonus.NextQuest then
                Bonus.NextQuest = now + Bonus.QuestEvery
                pcall(Bonus.checkQuests)
            end
            if Bonus.Redeem and now >= Bonus.NextCode then
                Bonus.NextCode = now + Bonus.CodeEvery
                pcall(Bonus.checkCodes)
            end
            Bonus.updateStatus()
            task.wait(1)
        end
    end)
end)() end

Config.add("Bonus", Bonus, { "Quest", "Redeem" })

-- ===== TAB: BONUS =====
do (function() -- fungsi sendiri: variabel di dalam tidak ikut batas 200 local
    local BonusTab = makeTab("Bonus", "gift", "fitur")
    local bQuest = box(BonusTab, "Quest Harian", true)
    local bCode = box(BonusTab, "Redeem Code", true)

    safe(function()
        UI.QuestStatus = bQuest:Paragraph({ Title = "Status", Desc = "-" })
    end)

    safe(function()
        bQuest:Toggle({
            Title = "Auto Claim Quest",
            Desc = "Klaim hadiah quest yang sudah selesai",
            Value = Bonus.Quest,
            Callback = function(on)
                Bonus.Quest = on
                if on then Bonus.NextQuest = 0 end
            end,
        })
    end)

    safe(function()
        bQuest:Button({
            Title = "Cek quest sekarang",
            Callback = function() task.spawn(Bonus.checkQuests) end,
        })
    end)

    safe(function()
        UI.CodeStatus = bCode:Paragraph({ Title = "Status", Desc = "-" })
    end)

    safe(function()
        bCode:Toggle({
            Title = "Auto Redeem Code",
            Desc = "Tukar semua code aktif yang belum dipakai",
            Value = Bonus.Redeem,
            Callback = function(on)
                Bonus.Redeem = on
                if on then Bonus.NextCode = 0 end
            end,
        })
    end)

    safe(function()
        bCode:Button({
            Title = "Cek code sekarang",
            Callback = function()
                table.clear(Bonus.Tried)
                task.spawn(Bonus.checkCodes)
            end,
        })
    end)

    safe(function()
        bCode:Input({
            Title = "Redeem code manual",
            Desc = "Ketik code lalu tekan Enter",
            Value = "",
            Placeholder = "KODE",
            Callback = function(text)
                local code = tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
                if code == "" then return end
                task.spawn(function()
                    local success, msg = Bonus.redeem(code)
                    if success then Bonus.Redeemed += 1 end
                    notify(success and "Redeem berhasil" or "Redeem gagal", code .. ": " .. tostring(msg), 5)
                end)
            end,
        })
    end)
end)() end

---------------------------------------------------------------------
-- GROWSCAN: Floating Items & World Blocks (seperti Growscan 9000 di Growtopia)
---------------------------------------------------------------------
-- Cara kerja:
--   - Floating Items: daftar drop di world (data drop game), dijumlah per item.
--   - World Blocks: semua tile world dihitung per item (block depan + background).
--     Seed yang tertanam di block depan = pohon.
--   - Auto Scan: diulang tiap 2 detik. Hasil diurutkan dari jumlah terbanyak.
local Scan = {
    Auto = false,
    Layer = "Semua",      -- "Semua" | "Depan" | "Background"
    Filter = "",          -- cari nama item
    Every = 2,
    Limit = 60,           -- maksimal baris per daftar
    Last = nil,
}

do (function() -- fungsi sendiri: variabel di dalam tidak ikut batas 200 local
    local function fmtNum(n)
        local str = tostring(math.floor(n))
        local out = str:reverse():gsub("(%d%d%d)", "%1."):reverse()
        return (out:gsub("^%.", ""))
    end

    local function blockName(id)
        local it = ItemDB[id]
        local nm = itemName(id)
        if it and it.kind == "seed" then nm = nm .. " (pohon)" end
        return nm
    end

    -- Ubah hitungan {id = jumlah} jadi teks, urut dari terbanyak
    local function listText(counts, nameFn)
        local list = {}
        for id, n in pairs(counts) do list[#list + 1] = { id = id, n = n } end
        table.sort(list, function(a, b)
            if a.n ~= b.n then return a.n > b.n end
            return a.id < b.id
        end)
        local filter = string.lower(Scan.Filter or "")
        local lines, total = {}, 0
        for _, e in ipairs(list) do
            local name = nameFn(e.id)
            if filter == "" or string.find(string.lower(name), filter, 1, true) then
                total += 1
                if total <= Scan.Limit then
                    lines[#lines + 1] = name .. "  x" .. fmtNum(e.n)
                end
            end
        end
        if total > Scan.Limit then lines[#lines + 1] = ("... +%d item lain (pakai Cari item)"):format(total - Scan.Limit) end
        if #lines == 0 then lines[1] = (filter ~= "") and "Tidak ada yang cocok" or "Kosong" end
        return table.concat(lines, "\n"), total
    end

    local function scanFloating()
        local counts, total, piles = {}, 0, 0
        local list = Drops.list
        if type(list) ~= "table" then return nil end
        for _, d in pairs(list) do
            if type(d) == "table" and type(d.id) == "number" then
                local n = tonumber(d.n) or 1
                if n > 0 then
                    counts[d.id] = (counts[d.id] or 0) + n
                    total += n
                    piles += 1
                end
            end
        end
        return counts, total, piles
    end

    local function scanBlocks()
        local w = Refs.World
        if not w or type(w.fg) ~= "table" or type(w.w) ~= "number" then return nil end
        local fgC, bgC, nf, nb = {}, {}, 0, 0
        local trees = {} -- [seed] = { r = siap, g = tumbuh, nxt = detik ke panen berikutnya }
        local st = workspace:GetServerTimeNow()
        local readyAt = Auto.treeReadyAt
        for y = 0, w.h - 1 do
            local rf = w.fg[y]
            local rb = w.bg and w.bg[y]
            for x = 0, w.w - 1 do
                local a = rf and rf[x] or 0
                if a ~= 0 then
                    fgC[a] = (fgC[a] or 0) + 1
                    nf += 1
                    local it = ItemDB[a]
                    if readyAt and it and it.kind == "seed" then
                        local ra = readyAt(x, y, a)
                        if ra then
                            local e = trees[a]
                            if not e then
                                e = { r = 0, g = 0 }
                                trees[a] = e
                            end
                            if st >= ra then
                                e.r += 1
                            else
                                e.g += 1
                                if not e.nxt or ra - st < e.nxt then e.nxt = ra - st end
                            end
                        end
                    end
                end
                local b = rb and rb[x] or 0
                if b ~= 0 then
                    bgC[b] = (bgC[b] or 0) + 1
                    nb += 1
                end
            end
            if y % 64 == 63 then task.wait() end -- world besar: jangan bikin lag
        end
        return fgC, bgC, nf, nb, trees
    end

    local function waitText(sec)
        sec = math.max(0, math.floor(sec or 0))
        if sec >= 3600 then return ("%dj %dm"):format(sec // 3600, sec % 3600 // 60) end
        return ("%dm %dd"):format(sec // 60, sec % 60)
    end

    -- Daftar pohon: siap panen dulu, lalu yang paling cepat siap
    local function treeText(trees)
        local list, totalR, totalG = {}, 0, 0
        local filter = string.lower(Scan.Filter or "")
        for id, e in pairs(trees) do
            totalR += e.r
            totalG += e.g
            local name = itemName(id)
            if filter == "" or string.find(string.lower(name), filter, 1, true) then
                list[#list + 1] = { name = name, e = e }
            end
        end
        table.sort(list, function(a, b)
            if a.e.r ~= b.e.r then return a.e.r > b.e.r end
            return (a.e.nxt or math.huge) < (b.e.nxt or math.huge)
        end)
        local lines = {}
        for i, v in ipairs(list) do
            if i > Scan.Limit then
                lines[#lines + 1] = ("... +%d jenis lain"):format(#list - Scan.Limit)
                break
            end
            local line = ("%s: %d siap | %d tumbuh"):format(v.name, v.e.r, v.e.g)
            if v.e.nxt then line = line .. " (berikut " .. waitText(v.e.nxt) .. ")" end
            lines[#lines + 1] = line
        end
        if #lines == 0 then lines[1] = (filter ~= "") and "Tidak ada yang cocok" or "Tidak ada pohon" end
        return table.concat(lines, "\n"), totalR, totalG
    end

    local function setDesc(el, txt, key)
        if Scan[key] == txt then return end
        Scan[key] = txt
        if el then pcall(function() el:SetDesc(txt) end) end
    end

    function Scan.run()
        if Scan.Busy then return end
        Scan.Busy = true
        local w = Refs.World
        local fl, flTotal, piles = scanFloating()
        local fgC, bgC, nf, nb, trees = scanBlocks()
        local treeTxt, treeR, treeG = "Data pohon belum ketemu", nil, nil
        if trees then treeTxt, treeR, treeG = treeText(trees) end

        local floatText = fl and select(1, listText(fl, itemName)) or "Data drop belum ketemu. Tekan 'Hubungkan ke game'"
        local blockText = "Data world belum ketemu. Tekan 'Hubungkan ke game'"
        if fgC then
            local pick
            if Scan.Layer == "Depan" then
                pick = fgC
            elseif Scan.Layer == "Background" then
                pick = bgC
            else
                pick = {}
                for id, n in pairs(fgC) do pick[id] = (pick[id] or 0) + n end
                for id, n in pairs(bgC) do pick[id] = (pick[id] or 0) + n end
            end
            blockText = select(1, listText(pick, blockName))
        end

        local name = w and rawget(w, "name")
        local info = table.concat({
            "World: " .. ((type(name) == "string" and name ~= "") and name or "-")
                .. (w and type(w.w) == "number" and (" (" .. w.w .. "x" .. w.h .. ")") or ""),
            "Block depan: " .. (nf and fmtNum(nf) or "-") .. " | Background: " .. (nb and fmtNum(nb) or "-"),
            "Floating: " .. (flTotal and (fmtNum(flTotal) .. " item (" .. piles .. " tumpukan)") or "-"),
            "Pohon: " .. (treeR and (fmtNum(treeR) .. " siap panen | " .. fmtNum(treeG) .. " tumbuh") or "-"),
            "Scan terakhir: " .. os.date("%H:%M:%S"),
        }, "\n")

        setDesc(UI.ScanInfo, info, "_info")
        setDesc(UI.ScanFloat, floatText, "_float")
        setDesc(UI.ScanBlocks, blockText, "_blocks")
        setDesc(UI.ScanTrees, treeTxt, "_trees")
        Scan.Busy = false
    end

    task.spawn(function()
        local last = 0
        while alive() do
            if Scan.Auto and os.clock() - last >= Scan.Every then
                last = os.clock()
                pcall(Scan.run)
            end
            task.wait(0.5)
        end
    end)
end)() end

Config.add("Growscan", Scan, { "Auto", "Layer" })

-- ===== TAB: GROWSCAN =====
do (function() -- fungsi sendiri: variabel di dalam tidak ikut batas 200 local
    local ScanTab = makeTab("Growscan", "scan-search", "fitur")

    safe(function()
        UI.ScanInfo = ScanTab:Paragraph({ Title = "Info World", Desc = "Tekan Scan sekarang" })
    end)

    local sCtl = box(ScanTab, "Kontrol", true)
    local sFloat = box(ScanTab, "Floating Items", true)
    local sBlock = box(ScanTab, "World Blocks", false)
    local sTree = box(ScanTab, "Pohon (siap panen)", true)

    safe(function()
        sCtl:Toggle({
            Title = "Auto Scan",
            Desc = "Update otomatis tiap 2 detik",
            Value = Scan.Auto,
            Callback = function(on)
                Scan.Auto = on
                if on then task.spawn(Scan.run) end
            end,
        })
    end)

    safe(function()
        sCtl:Button({
            Title = "Scan sekarang",
            Callback = function() task.spawn(Scan.run) end,
        })
    end)

    safe(function()
        sCtl:Input({
            Title = "Cari item",
            Desc = "Saring nama item (kosongkan = semua)",
            Value = "",
            Placeholder = "contoh: seed",
            Callback = function(text)
                Scan.Filter = tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
                task.spawn(Scan.run)
            end,
        })
    end)

    safe(function()
        UI.ScanFloat = sFloat:Paragraph({ Title = "Daftar", Desc = "-" })
    end)

    safe(function()
        sBlock:Dropdown({
            Title = "Layer",
            Values = { "Semua", "Depan", "Background" },
            Value = Scan.Layer,
            Callback = function(opt)
                Scan.Layer = opt
                task.spawn(Scan.run)
            end,
        })
    end)

    safe(function()
        UI.ScanBlocks = sBlock:Paragraph({ Title = "Daftar", Desc = "-" })
    end)

    safe(function()
        UI.ScanTrees = sTree:Paragraph({ Title = "Daftar", Desc = "-" })
    end)
end)() end

---------------------------------------------------------------------
-- STATISTIK SESI
---------------------------------------------------------------------
-- Cara kerja:
--   - Saat execute (atau tombol Reset), angka awal dicatat.
--   - Tiap detik: angka sekarang - angka awal = hasil sesi. Dibagi lama sesi = per jam.
--   - Gems dibaca dari angka gems di HUD game (nilai di dalam fungsi addGems).
do (function()
    local function gemsNow()
        local g = Refs.Gems
        local f = g and rawget(g, "addGems")
        if type(f) ~= "function" then return nil end
        for _, v in pairs(getUpvalues(f)) do
            if type(v) == "number" then return v end
        end
        return nil
    end
    Stats.gemsNow = gemsNow

    local function fmt(n)
        local str = tostring(math.floor(n or 0))
        local neg = string.sub(str, 1, 1) == "-"
        if neg then str = string.sub(str, 2) end
        local out = str:reverse():gsub("(%d%d%d)", "%1."):reverse()
        out = out:gsub("^%.", "")
        return (neg and "-" or "") .. out
    end

    local function dur(sec)
        sec = math.max(0, math.floor(sec))
        return ("%dj %dm %dd"):format(sec // 3600, sec % 3600 // 60, sec % 60)
    end

    -- angka yang dihitung (semuanya naik terus selama script jalan)
    local function counters()
        return {
            broken = State.Broken, placed = State.Placed, collected = State.Collected,
            harvested = Farmer.Harvested, planted = Farmer.Planted,
        }
    end

    function Stats.reset()
        Stats.T0 = os.clock()
        Stats.Gems0 = gemsNow()
        Stats.Items = {}
        Stats.Base = counters()
    end
    Stats.Base = counters()

    function Stats.text()
        local hours = math.max((os.clock() - Stats.T0) / 3600, 1 / 3600)
        local now, base = counters(), Stats.Base
        local function line(label, key)
            local v = now[key] - (base[key] or 0)
            return ("%s: %s  (%s/jam)"):format(label, fmt(v), fmt(v / hours))
        end
        local g = gemsNow()
        if g and not Stats.Gems0 then Stats.Gems0 = g end
        local gemLine = "Gems: -"
        if g and Stats.Gems0 then
            local d = g - Stats.Gems0
            gemLine = ("Gems: %s  (%s%s, %s/jam)"):format(fmt(g), d >= 0 and "+" or "", fmt(d), fmt(d / hours))
        end
        -- 5 item terbanyak yang terkumpul
        local top = {}
        for id, n in pairs(Stats.Items) do top[#top + 1] = { id = id, n = n } end
        table.sort(top, function(a, b) return a.n > b.n end)
        local tops = {}
        for i = 1, math.min(5, #top) do tops[i] = itemName(top[i].id) .. " x" .. fmt(top[i].n) end
        return table.concat({
            "Lama sesi: " .. dur(os.clock() - Stats.T0),
            gemLine,
            line("Block pecah", "broken"),
            line("Block di-place", "placed"),
            line("Drop diambil", "collected"),
            line("Panen", "harvested"),
            line("Tanam", "planted"),
            "Item terbanyak: " .. ((#tops > 0) and table.concat(tops, ", ") or "-"),
        }, "\n")
    end

    task.spawn(function()
        local lastReport = os.clock()
        while alive() do
            local ok, txt = pcall(Stats.text)
            if ok and UI.StatsText and txt ~= Stats.Shown then
                Stats.Shown = txt
                pcall(function() UI.StatsText:SetDesc(txt) end)
            end
            -- laporan berkala ke Discord
            if Hook.ReportMin > 0 and os.clock() - lastReport >= Hook.ReportMin * 60 then
                lastReport = os.clock()
                if ok then Hook.send("report", "Laporan statistik\n```\n" .. txt .. "\n```") end
            elseif Hook.ReportMin <= 0 then
                lastReport = os.clock()
            end
            task.wait(1)
        end
    end)
end)() end

-- ===== TAB: STATISTIK =====
do (function()
    local StatTab = makeTab("Statistik", "bar-chart-3", "fitur")

    safe(function()
        UI.StatsText = StatTab:Paragraph({ Title = "Sesi ini", Desc = "-" })
    end)

    safe(function()
        StatTab:Button({
            Title = "Reset statistik",
            Desc = "Mulai hitung dari nol",
            Callback = function()
                Stats.reset()
                notify("Statistik", "Direset", 2)
            end,
        })
    end)

    safe(function()
        StatTab:Button({
            Title = "Kirim ke Discord sekarang",
            Desc = "Perlu webhook di tab Discord",
            Callback = function()
                local ok, txt = pcall(Stats.text)
                if not (Hook.On and Hook.valid(Hook.Url)) then
                    notify("Statistik", "Aktifkan webhook Discord dulu", 3)
                elseif ok then
                    Hook.send("report", "Laporan statistik\n```\n" .. txt .. "\n```")
                    notify("Statistik", "Masuk antrian kirim", 2)
                end
            end,
        })
    end)
end)() end

---------------------------------------------------------------------
-- TAS: auto recycle item sampah & auto convert lock
---------------------------------------------------------------------
-- Cara kerja (sama seperti tombol di inventori game):
--   Recycle : hapus dari inventori lalu World.call("Recycle", id, jumlah)
--   Convert : 100 World Lock -> 1 Diamond Lock, 100 Diamond Lock -> 1 Blue Gem Lock
--             lewat World.call("ConvertLock", dari, ke)
-- Tool & lock tidak bisa dipilih untuk recycle (supaya tidak terbuang tidak sengaja).
local Bag = {
    TrashOn = false,
    TrashList = {},    -- daftar id item yang di-recycle
    TrashAt = 150,     -- recycle kalau jumlahnya sudah segini
    Keep = 0,          -- sisakan sebanyak ini
    LockOn = false,
    Recycled = 0,
    Converted = 0,
    Status = "-",
}

do (function()
    local LOCK_IDS = { [242] = true, [1796] = true, [7188] = true }
    local LOCK_STEPS = {
        { from = 242, to = 1796, name = "Diamond Lock" },
        { from = 1796, to = 7188, name = "Blue Gem Lock" },
    }

    local function worldCall(...)
        local w = Refs.World
        local f = w and rawget(w, "call")
        if type(f) ~= "function" then return false end
        return pcall(f, ...)
    end

    local function trashable(id)
        local it = ItemDB[id]
        return it ~= nil and it.kind ~= "tool" and not LOCK_IDS[id]
    end

    function Bag.recycle(id, n)
        if not Refs.Inv or n <= 0 or not trashable(id) then return false end
        n = math.min(n, invCount(id))
        if n <= 0 then return false end
        pcall(function() Refs.Inv:remove(id, n) end)
        local ok = worldCall("Recycle", id, n)
        if ok then
            Bag.Recycled += n
            Bag.Status = ("Recycle %s x%d"):format(itemName(id), n)
        end
        return ok
    end

    -- sama seperti cek tombol convert di game (muat atau tidak)
    local function convertLock(step)
        local inv = Refs.Inv
        if not inv or invCount(step.from) < 100 then return false end
        local okU, used = pcall(function() return inv:used() end)
        local okC, cap = pcall(function() return inv.capacity end)
        if invCount(step.to) + 1 > 200 then return false end
        if invCount(step.to) == 0 and invCount(step.from) ~= 100 and okU and okC
            and type(used) == "number" and type(cap) == "number" and used >= cap then
            return false
        end
        pcall(function()
            inv:remove(step.from, 100)
            inv:add(step.to, 1)
        end)
        local ok = worldCall("ConvertLock", step.from, step.to)
        if ok then
            Bag.Converted += 1
            Bag.Status = "Convert ke " .. step.name
        end
        return ok
    end

    function Bag.tick()
        if Bag.TrashOn then
            for _, id in ipairs(Bag.TrashList) do
                local n = invCount(id)
                if n >= Bag.TrashAt and n > Bag.Keep then
                    Bag.recycle(id, n - Bag.Keep)
                    task.wait(0.5)
                end
            end
        end
        if Bag.LockOn then
            for _, step in ipairs(LOCK_STEPS) do
                if convertLock(step) then task.wait(0.5) end
            end
        end
    end

    -- label dropdown: item di inventori yang boleh di-recycle
    function Bag.labels()
        local out, seen = {}, {}
        for _, slot in ipairs(Refs.inventoryEntries()) do
            local id = slot.id
            if not seen[id] and trashable(id) then
                seen[id] = true
                out[#out + 1] = { id = id, label = ("%s [%d]"):format(itemName(id), id) }
            end
        end
        -- item yang sudah dipilih tetap tampil walau sedang habis
        for _, id in ipairs(Bag.TrashList) do
            if not seen[id] then
                seen[id] = true
                out[#out + 1] = { id = id, label = ("%s [%d]"):format(itemName(id), id) }
            end
        end
        table.sort(out, function(a, b) return a.id < b.id end)
        local labels, picked = {}, {}
        for _, e in ipairs(out) do
            labels[#labels + 1] = e.label
            if table.find(Bag.TrashList, e.id) then picked[#picked + 1] = e.label end
        end
        return labels, picked
    end

    task.spawn(function()
        while alive() do
            pcall(Bag.tick)
            if UI.BagStatus then
                local txt = ("Status: %s\nDi-recycle: %d item | Convert lock: %d kali\nItem dipilih: %d"):format(
                    Bag.Status, Bag.Recycled, Bag.Converted, #Bag.TrashList)
                if txt ~= Bag.Shown then
                    Bag.Shown = txt
                    pcall(function() UI.BagStatus:SetDesc(txt) end)
                end
            end
            task.wait(3)
        end
    end)
end)() end

Config.add("Tas", Bag, { "TrashOn", "TrashList", "TrashAt", "Keep", "LockOn" })

-- ===== TAB: TAS =====
do (function()
    local BagTab = makeTab("Tas", "backpack", "fitur")

    safe(function()
        UI.BagStatus = BagTab:Paragraph({ Title = "Status", Desc = "-" })
    end)

    local bTrash = box(BagTab, "Auto Recycle (buang item)", true)
    local bLock = box(BagTab, "Auto Convert Lock", false)

    safe(function()
        bTrash:Toggle({
            Title = "Auto Recycle",
            Desc = "Item yang dipilih di-recycle otomatis",
            Value = Bag.TrashOn,
            Callback = function(on) Bag.TrashOn = on end,
        })
    end)

    safe(function()
        local labels, picked = Bag.labels()
        UI.TrashDropdown = bTrash:Dropdown({
            Title = "Item yang di-recycle",
            Desc = "Bisa pilih banyak. Tool & lock tidak ditampilkan",
            Values = (#labels > 0) and labels or { "(inventori belum terbaca)" },
            Value = picked,
            Multi = true,
            AllowNone = true,
            Callback = function(opts)
                local list = {}
                for _, label in ipairs(type(opts) == "table" and opts or { opts }) do
                    local id = tonumber(string.match(tostring(label), "%[(%d+)%]$"))
                    if id then list[#list + 1] = id end
                end
                Bag.TrashList = list
            end,
        })
    end)

    -- dipanggil saat inventori berubah
    local lastSig = nil
    UI.TrashRefresh = function(force)
        local labels, picked = Bag.labels()
        local sig = table.concat(labels, "|")
        if not force and sig == lastSig then return end
        if not UI.TrashDropdown then return end
        local ok = UI.ddRefresh(UI.TrashDropdown, (#labels > 0) and labels or { "(inventori kosong)" })
        if ok and #picked > 0 then
            local err
            ok, err = UI.exec(function() UI.TrashDropdown:Select(picked) end)
            if not ok then UI.DropErr = "Tas: " .. tostring(err) end
        end
        lastSig = ok and sig or nil
    end

    addNumber(bTrash, {
        Title = "Recycle kalau jumlah >=",
        Desc = "200 = hanya saat penuh 1 slot",
        Min = 1, Max = 200, Step = 1, Default = Bag.TrashAt,
        Callback = function(v) Bag.TrashAt = math.floor(v) end,
    })

    addNumber(bTrash, {
        Title = "Sisakan",
        Desc = "Jumlah yang tidak ikut di-recycle",
        Min = 0, Max = 199, Step = 1, Default = Bag.Keep,
        Callback = function(v) Bag.Keep = math.floor(v) end,
    })

    safe(function()
        bTrash:Button({
            Title = "Refresh daftar item",
            Callback = function() UI.later("trash", function() UI.TrashRefresh(true) end) end,
        })
    end)

    safe(function()
        bLock:Toggle({
            Title = "Auto Convert Lock",
            Desc = "100 WL -> 1 DL, 100 DL -> 1 BGL (sama seperti game)",
            Value = Bag.LockOn,
            Callback = function(on) Bag.LockOn = on end,
        })
    end)
end)() end

---------------------------------------------------------------------
-- AUTO SPLICE
---------------------------------------------------------------------
-- Cara kerja (sama seperti splice manual di game):
--   1. Tanam Seed A di tile Grid yang kosong (di bawahnya harus ada block).
--   2. Taruh Seed B di atas pohon A -> World.spliceSeed(x, y, B).
--   3. Server membalas id pohon hasil splice, tile langsung diganti di layar.
--   Hasil splice diperkirakan dulu pakai modul Splice game; kalau tidak bisa, tidak dijalankan.
do (function()
    local okMod, SpliceMod = Shared:Load("Splice")

    function Splice.result(a, b)
        if not (okMod and type(SpliceMod) == "table" and type(SpliceMod.result) == "function") then return nil end
        if not (a and b) then return nil end
        local ok, r = pcall(SpliceMod.result, a, b)
        return ok and r or nil
    end

    local function setVisual()
        if UI.SpliceToggle then pcall(function() UI.SpliceToggle:Set(Splice.Running) end) end
    end

    function Splice.stop(reason)
        Splice.Running = false
        if Splice.Roaming then Auto.stopSpliceRoam() end
        Splice.Status = reason or "Dihentikan"
        setVisual()
        if reason then notify("Auto Splice", reason, 4) end
    end

    local function treeSpliced(x, y)
        local t = Auto.treeEntry(x, y)
        return type(t) == "table" and t.s == true
    end

    local function spliceAt(x, y)
        local w = Refs.World
        local f = w and rawget(w, "spliceSeed")
        if type(f) ~= "function" then return false, "fungsi splice game tidak ketemu" end
        local ok, made = pcall(f, x, y, Splice.B)
        if ok and made and ItemDB[made] then
            pcall(function() Refs.Inv:remove(Splice.B, 1) end)
            if Refs.SetTile then pcall(Refs.SetTile, "fg", x, y, made, true) end -- ganti di layar saja
            Splice.Made += 1
            Splice.Status = ("Splice jadi %s (%d,%d)"):format(itemName(made), x, y)
            return true
        end
        return false, "ditolak server"
    end

    local function loop(runId)
        while Splice.Running and alive() and Splice.RunId == runId do
            local px, py = getPlayerTile()
            if not px then
                Splice.stop("Karakter tidak ditemukan (keluar world?)")
                return
            end
            local A, B = Splice.A, Splice.B
            local acted = false
            local now = os.clock()
            for _, o in ipairs(sortedOffsets()) do
                if not Splice.Running then break end
                local x, y = px + o.dx, py + o.dy
                local key = x .. "," .. y
                if not (Splice.Fail[key] and Splice.Fail[key] > now) then
                    local fg = tileAt("fg", x, y)
                    -- 1) tanam Seed A
                    if fg == 0 and invCount(A) > 0 and invCount(B) > 0 and Auto.plantSpotOk(x, y, A) then
                        sendSetTile("fg", x, y, A)
                        pcall(function() Refs.Inv:remove(A, 1) end)
                        Splice.Planted += 1
                        Splice.Status = ("Tanam %s (%d,%d)"):format(itemName(A), x, y)
                        acted = true
                        task.wait(Splice.Ms / 1000)
                        fg = tileAt("fg", x, y)
                    end
                    -- 2) splice Seed B ke pohon A
                    if fg == A and invCount(B) > 0 and not treeSpliced(x, y) then
                        local ok, why = spliceAt(x, y)
                        if not ok then
                            Splice.Fail[key] = os.clock() + 30
                            Splice.Status = ("Gagal splice (%d,%d): %s"):format(x, y, why)
                        end
                        acted = true
                        task.wait(Splice.Ms / 1000)
                    end
                end
            end
            if not acted then
                if invCount(A) <= 0 or invCount(B) <= 0 then
                    Splice.stop("Seed habis")
                    return
                end
                Splice.Status = "Menunggu tile Grid kosong (panen dulu pohonnya)"
                task.wait(1)
            end
        end
    end

    function Splice.start()
        if Splice.Running then return end
        local err
        if not Refs.World then
            err = "Data world belum ketemu. Tekan 'Hubungkan ke game'"
        elseif not (Splice.A and Splice.B) then
            err = "Pilih Seed A dan Seed B dulu"
        elseif Splice.A == Splice.B then
            err = "Seed A dan Seed B harus beda"
        elseif not Splice.result(Splice.A, Splice.B) then
            err = "Kombinasi ini tidak bisa di-splice"
        elseif not Splice.Roam and next(State.Offsets) == nil then
            err = "Pilih tile dulu di Grid Tile (tab Farm), atau nyalakan Keliling world"
        elseif State.Running or Clear.Running or Farmer.Running then
            err = "Hentikan Auto Farm / Clear / Farmer dulu"
        end
        if err then
            notify("Auto Splice", err, 4)
            setVisual()
            return
        end
        table.clear(Splice.Fail)
        Splice.Running = true
        Splice.RunId = (Splice.RunId or 0) + 1
        setVisual()
        if Splice.Roam then
            local e = Auto.startSpliceRoam()
            if e then Splice.stop(e) end
        else
            task.spawn(loop, Splice.RunId)
        end
    end

    function Splice.resultText()
        if not (Splice.A and Splice.B) then return "Pilih Seed A dan Seed B" end
        local r = Splice.result(Splice.A, Splice.B)
        if not r then return "Hasil: tidak bisa di-splice" end
        return "Hasil: " .. itemName(r)
    end

    task.spawn(function()
        while alive() do
            if UI.SpliceStatus then
                local txt = ("Status: %s\n%s\nSeed A: %s (x%d) | Seed B: %s (x%d)\nDitanam: %d | Splice jadi: %d"):format(
                    Splice.Running and Splice.Status or ("BERHENTI - " .. Splice.Status), Splice.resultText(),
                    Splice.A and itemName(Splice.A) or "-", Splice.A and invCount(Splice.A) or 0,
                    Splice.B and itemName(Splice.B) or "-", Splice.B and invCount(Splice.B) or 0,
                    Splice.Planted, Splice.Made)
                if txt ~= Splice.Shown then
                    Splice.Shown = txt
                    pcall(function() UI.SpliceStatus:SetDesc(txt) end)
                end
            end
            task.wait(1)
        end
    end)
end)() end

Config.add("Splice", Splice, { "A", "B", "Ms", "Roam" })
Splice.Ms = math.max(Splice.Ms, 140)

-- ===== TAB: SPLICE =====
do (function()
    local SpTab = makeTab("Splice", "git-merge", "farm")

    safe(function()
        UI.SpliceStatus = SpTab:Paragraph({ Title = "Status Splice", Desc = "-" })
    end)

    local sCtl = box(SpTab, "Kontrol", true)
    local sSeed = box(SpTab, "Seed", true)
    local sSpeed = box(SpTab, "Kecepatan", false)

    safe(function()
        UI.SpliceToggle = sCtl:Toggle({
            Title = "Auto Splice",
            Desc = "Tanam Seed A lalu splice Seed B",
            Value = false,
            Callback = function(on)
                if on then Splice.start() elseif Splice.Running then Splice.stop() end
            end,
        })
    end)

    local function seedLabels()
        local labels = {}
        for _, id in ipairs(seedIds()) do labels[#labels + 1] = ("%s [%d]"):format(itemName(id), id) end
        if #labels == 0 then labels = { "(tidak ada seed di inventori)" } end
        return labels
    end
    local function idOf(opt) return tonumber(string.match(tostring(opt or ""), "%[(%d+)%]$")) end

    safe(function()
        UI.SpliceA = sSeed:Dropdown({
            Title = "Seed A (ditanam)",
            Values = { "(memuat...)" },
            Callback = function(opt)
                local id = idOf(opt)
                if id then Splice.A = id end
            end,
        })
    end)

    safe(function()
        UI.SpliceB = sSeed:Dropdown({
            Title = "Seed B (di-splice)",
            Values = { "(memuat...)" },
            Callback = function(opt)
                local id = idOf(opt)
                if id then Splice.B = id end
            end,
        })
    end)

    -- dipanggil saat inventori berubah
    local lastSig = nil
    UI.SpliceRefresh = function(force)
        local labels = seedLabels()
        local sig = table.concat(labels, "|")
        if not force and sig == lastSig then return end
        local ok = true
        for _, pair in ipairs({ { UI.SpliceA, Splice.A }, { UI.SpliceB, Splice.B } }) do
            local dd, id = pair[1], pair[2]
            if dd then
                local refreshed = UI.ddRefresh(dd, labels)
                if refreshed then refreshed = selectSaved(dd, labels, id) end
                ok = ok and refreshed
            end
        end
        lastSig = ok and sig or nil
    end

    safe(function()
        sSeed:Button({
            Title = "Refresh daftar seed",
            Callback = function() UI.later("splice", function() UI.SpliceRefresh(true) end) end,
        })
    end)

    safe(function()
        sCtl:Toggle({
            Title = "Keliling world (A*)",
            Desc = "Nyala: jalan ke seluruh world. Mati: hanya tile Grid 5x5",
            Value = Splice.Roam,
            Callback = function(on)
                if Splice.Running then Splice.stop("Mode diganti, nyalakan lagi") end
                Splice.Roam = on
            end,
        })
    end)

    addNumber(sSpeed, {
        Title = "Jeda tanam / splice (ms)",
        Min = 140, Max = 2000, Step = 10, Default = Splice.Ms,
        Callback = function(v) Splice.Ms = math.floor(v) end,
    })
end)() end

-- ===== TAB: LAHAN (bangun farm world) =====
do (function()
    local LTab = makeTab("Dirt Farm", "layout-grid", "farm")

    safe(function()
        UI.LahanStatus = LTab:Paragraph({ Title = "Status Dirt Farm", Desc = "-" })
    end)

    local lCtl = box(LTab, "Bangun Dirt Farm", true)
    local lShape = box(LTab, "Bentuk Dirt Farm", true)

    safe(function()
        UI.BuildToggle = lCtl:Toggle({
            Title = "Bangun Dirt Farm",
            Desc = "Gali per baris tanpa kembali ke awal, pukulan lebih rapat, lava terjangkau didahulukan. Block kurang: produksi 1 baris",
            Value = false,
            Callback = function(on)
                if on then Build.start() elseif Build.Running then Build.stop() end
            end,
        })
    end)

    safe(function()
        UI.BuildBlockDropdown = lCtl:Dropdown({
            Title = "Block Dirt Farm",
            Desc = "Block padat dari inventori",
            Values = { "(memuat...)" },
            Callback = function(opt)
                local id = tonumber(string.match(opt or "", "%[(%d+)%]$"))
                if id then Build.BlockId = id end
            end,
        })
    end)

    local function num(text, def)
        local v = tonumber(tostring(text or ""):match("%-?%d+"))
        return v or def
    end

    safe(function()
        lShape:Input({
            Title = "X awal",
            Desc = "Kolom paling kiri",
            Value = tostring(Land.X0),
            Placeholder = "0",
            Callback = function(t) Land.X0 = math.max(0, num(t, Land.X0)) end,
        })
    end)

    safe(function()
        lShape:Input({
            Title = "X akhir",
            Desc = "Kolom paling kanan (lebih dari lebar world = sampai ujung)",
            Value = tostring(Land.X1),
            Placeholder = "99",
            Callback = function(t) Land.X1 = math.max(0, num(t, Land.X1)) end,
        })
    end)

    safe(function()
        lShape:Input({
            Title = "Y baris atas",
            Desc = "Baris block paling atas. Baris di bawahnya otomatis sampai di atas bedrock (tanah digali)",
            Value = tostring(Land.Y0),
            Placeholder = "2",
            Callback = function(t) Land.Y0 = math.max(1, num(t, Land.Y0)) end,
        })
    end)

    safe(function()
        lShape:Button({
            Title = "Pakai posisi karakter sebagai pojok kiri-atas",
            Desc = "Berdiri di atas block pertama baris paling atas, lalu tekan (tangga kiri di sebelah kirinya)",
            Callback = function()
                local x, y = Auto.here()
                if not x then
                    notify("Dirt Farm", "Kamu belum masuk world", 3)
                    return
                end
                -- block yang dipijak = block pertama baris atas, kolom tangga kiri di sebelah kirinya
                Land.X0, Land.Y0 = math.max(0, x - 1), y + 1
                notify("Dirt Farm", ("X awal %d, Y baris atas %d"):format(Land.X0, Land.Y0), 4)
            end,
        })
    end)

    safe(function()
        lCtl:Toggle({
            Title = "Lanjut Pabrik setelah selesai",
            Value = Build.ThenPabrik,
            Callback = function(on) Build.ThenPabrik = on end,
        })
    end)

    safe(function()
        lCtl:Button({
            Title = "Posisi break produksi = posisi karakter",
            Desc = "Berdiri di tempat break lalu tekan. Tekan lagi di tempat yang sama = kembali otomatis",
            Callback = function()
                local x, y = Auto.here()
                if not x then
                    notify("Dirt Farm", "Kamu belum masuk world", 3)
                    return
                end
                if Build.BreakX == x and Build.BreakY == y then
                    Build.BreakX, Build.BreakY = -1, -1
                    notify("Dirt Farm", "Posisi break produksi: otomatis", 3)
                else
                    Build.BreakX, Build.BreakY = x, y
                    if next(Build.Tiles) == nil then Build.Tiles["1,0"] = true end
                    notify("Dirt Farm", ("Posisi break produksi (%d,%d)"):format(x, y), 3)
                end
            end,
        })
    end)

    safe(function()
        lCtl:Button({
            Title = "Pilih tile break produksi (Grid)",
            Desc = "Grid terbuka dalam mode Dirt Farm (terpisah dari Auto Farm & Pabrik)",
            Callback = function()
                if UI.setGridMode then UI.setGridMode("lahan") end
                if UI.GridGui then UI.GridGui.Enabled = true end
            end,
        })
    end)

    task.spawn(function()
        while alive() do
            local txt
            if Refs.World then
                local info = Build.Info
                if not (Build.Running and info) then
                    local key = tostring(Build.BlockId) .. "|" .. Land.X0 .. "|" .. Land.X1 .. "|" .. Land.Y0
                    if not info or not Build.InfoAt or os.clock() - Build.InfoAt > 5 or Build.InfoKey ~= key then
                        info = Auto.landInfo(Build.BlockId)
                        Build.Info, Build.InfoAt, Build.InfoKey = info, os.clock(), key
                    end
                end
                local rows = Auto.landRows()
                local have = Build.BlockId and invCount(Build.BlockId) or 0
                local seed = Auto.seedOfBlock(Build.BlockId)
                txt = table.concat({
                    "Status   : " .. (Build.Running and "JALAN" or "BERHENTI") .. " - " .. Build.Phase,
                    (#rows > 0) and ("Bentuk   : %d baris (y %d-%d), x %d-%d, 1 kosong per baris, tangga kiri & kanan"):format(
                        #rows, rows[1], rows[#rows], math.min(Land.X0, Land.X1), math.max(Land.X0, Land.X1))
                        or "Bentuk   : tidak ada baris yang muat (Y atas terlalu bawah)",
                    ("Block    : %s | punya %d | butuh %d%s"):format(Build.BlockId and itemName(Build.BlockId) or "-",
                        have, info.need, (info.need > have) and (" (kurang " .. (info.need - have) .. ")") or " (cukup)"),
                    ("Terpasang: %d / %d%s"):format(info.done, info.total,
                        info.blocked > 0 and (" | terhalang block lain: " .. info.blocked) or ""),
                    (info.carve > 0) and ("Gali     : sisa " .. info.carve .. " tile (celah, tangga, background)")
                        or "Gali     : selesai",
                    "Seed block: " .. (seed and (itemName(seed) .. " x" .. invCount(seed)) or "-"),
                    ("Produksi : panen %d | tanam %d"):format(Build.Harvested, Build.Planted),
                    "Break    : " .. ((Build.BreakX >= 0 and next(Build.Tiles) ~= nil)
                        and ("(" .. Build.BreakX .. "," .. Build.BreakY .. ") | grid Dirt Farm")
                        or "otomatis (kanan karakter, dekat ujung baris)"),
                    "Aksi     : " .. Build.Status,
                    ("Lava     : prioritas otomatis | dibersihkan %d | jeda pukul %d ms"):format(
                        Build.LavaCleared or 0, Build.PunchMs or 200),
                }, "\n")
            else
                txt = "Data world belum ketemu"
            end
            if UI.LahanStatus and txt ~= Build.Shown then
                Build.Shown = txt
                pcall(function() UI.LahanStatus:SetDesc(txt) end)
            end
            -- tombol START di Grid (mode lahan)
            if UI.GridMode == "lahan" and UI.GridStart then
                UI.GridStart.Text = I18N.T(Build.Running and "STOP DIRT FARM" or "START DIRT FARM")
                UI.GridStart.BackgroundColor3 = Build.Running and Color3.fromRGB(200, 60, 60) or Color3.fromRGB(46, 160, 90)
            end
            task.wait(1)
        end
    end)
end)() end

-- ===== TAB: VENDING =====
do (function()
    local VTab = makeTab("Vending", "store", "farm")

    safe(function()
        UI.VendStatus = VTab:Paragraph({ Title = "Status Vending", Desc = "-" })
    end)

    local vCtl = box(VTab, "Kontrol", true)
    local vItem = box(VTab, "Pilih item", true)
    local vDrop = box(VTab, "Titik drop vending", true)

    safe(function()
        UI.VendToggle = vCtl:Toggle({
            Title = "Jalankan Vending",
            Desc = "Jalankan di world vending milikmu",
            Value = false,
            Callback = function(on)
                if on then Vend.start() elseif Vend.Running then Vend.stop() end
            end,
        })
    end)

    safe(function()
        vCtl:Dropdown({
            Title = "Mode",
            Values = Auto.VEND_MODES,
            Value = Vend.Mode,
            Callback = function(v)
                if type(v) == "table" then v = v[1] end
                if type(v) == "string" then Vend.Mode = v end
            end,
        })
    end)

    safe(function()
        local labels, picked = Vend.labels(Refs.World and Vend.machines() or nil)
        UI.VendItems = vItem:Dropdown({
            Title = "Item yang diambil",
            Desc = "Bisa pilih banyak. Kosong = semua item. Daftar: isi vending, tas & drop yang terlihat",
            Values = (#labels > 0) and labels or { "(belum ada item)" },
            Value = picked,
            Multi = true,
            AllowNone = true,
            Callback = function(opts)
                local list = {}
                for _, label in ipairs(type(opts) == "table" and opts or { opts }) do
                    local id = tonumber(string.match(tostring(label), "%[(%d+)%]$"))
                    if id then list[#list + 1] = id end
                end
                Vend.Items = list
            end,
        })
    end)

    -- isi ulang daftar item kalau ada item baru (vending / tas / drop di world ini)
    -- Hasil: jumlah item di daftar, teks rincian (tas / drop / vending) atau pesan error
    function Vend.refreshItems(force, machines)
        if not UI.VendItems then return 0, "dropdown belum dibuat" end
        local ok, labels, picked, st = pcall(function()
            local m = machines
            if not m and Refs.World then
                local okM, res = pcall(Vend.machines)
                m = okM and res or nil
            end
            return Vend.labels(m)
        end)
        if not ok then
            warn("[Zekio Supreme Premium] daftar item vending error: " .. tostring(labels))
            return 0, "error: " .. tostring(labels)
        end
        local info = ("tas %d | drop %d | vending %d"):format(st.inv, st.drop, st.vend)
        local sig = table.concat(labels, "|")
        if not force and sig == Vend.ItemSig then return #labels, info end
        Vend.ItemSig = sig
        UI.later("vendItems", function()
            local okR, errR = UI.exec(function()
                UI.VendItems:Refresh((#labels > 0) and labels or { "(belum ada item)" })
            end)
            if not okR then
                Vend.ItemSig = nil
                warn("[Zekio Supreme Premium] refresh dropdown item vending gagal: " .. tostring(errR))
                notify("Vending", "Daftar item gagal dimuat: " .. tostring(errR), 6)
                return
            end
            if #picked > 0 then UI.exec(function() UI.VendItems:Select(picked) end) end
        end)
        return #labels, info
    end

    safe(function()
        vItem:Button({
            Title = "Muat ulang daftar item",
            Desc = "Ambil item dari vending, tas & drop di world ini",
            Callback = function()
                local n, info = Vend.refreshItems(true)
                notify("Vending", ("Daftar item: %d item (%s)"):format(n, tostring(info)), 5)
            end,
        })
    end)

    safe(function()
        vItem:Button({
            Title = "Tambah item yang dipegang",
            Desc = "Pilih item di tas game (dipegang), lalu tekan. Masuk ke daftar item yang diambil",
            Callback = function()
                local id = nil
                if Refs.Inv then pcall(function() id = tonumber(Refs.Inv.selected) end) end
                local it = id and ItemDB[id]
                if not it or it.kind == "tool" or it.lock then
                    notify("Vending", "Pegang dulu block / seed di tas game (bukan tool)", 4)
                    return
                end
                if not table.find(Vend.Items, id) then table.insert(Vend.Items, id) end
                Vend.Seen[id] = true
                Vend.refreshItems(true)
                notify("Vending", "Item dipilih: " .. itemName(id), 3)
            end,
        })
    end)

    safe(function()
        vItem:Button({
            Title = "Hapus pilihan item",
            Desc = "Kembali ke semua item",
            Callback = function()
                table.clear(Vend.Items)
                Vend.ItemSig = nil
                UI.later("vendClear", function() UI.exec(function() UI.VendItems:Select(nil) end) end)
                Vend.refreshItems(true)
                notify("Vending", "Pilihan item dihapus: semua item", 3)
            end,
        })
    end)

    safe(function()
        UI.VendPointInput = vDrop:Input({
            Title = "Titik drop vending",
            Desc = "WORLD atau WORLD:ID (kosong = world ini). Isi stock: ambil drop di sini. Kosongkan: drop di sini",
            Value = Vend.Point,
            Placeholder = "STORAGE:ID",
            Callback = function(t) Vend.Point = tostring(t or "") end,
        })
    end)

    safe(function()
        vDrop:Button({
            Title = "Simpan posisi drop vending (posisi karakter)",
            Desc = "Berdiri di tempat drop (boleh di world titik drop), lalu tekan. Dipakai mode isi stock & kosongkan",
            Callback = function()
                local x, y = Auto.here()
                if not x then
                    notify("Vending", "Kamu belum masuk world", 3)
                    return
                end
                Vend.DropX, Vend.DropY = x, y
                -- world titik drop ikut diisi, kecuali sudah pakai pintu (WORLD:ID / WORLD|ID)
                local _, door = Vend.point()
                if not door then
                    Vend.Point = Guard.worldName()
                    if UI.VendPointInput then pcall(function() UI.VendPointInput:Set(Vend.Point) end) end
                end
                notify("Vending", ("Posisi drop vending (%d,%d) di %s"):format(x, y, Vend.Point), 4)
            end,
        })
    end)

    safe(function()
        vDrop:Button({
            Title = "Hapus posisi drop vending",
            Desc = "Drop / tunggu di titik kedatangan (pintu) saja",
            Callback = function()
                Vend.DropX, Vend.DropY = -1, -1
                notify("Vending", "Posisi drop vending dihapus", 3)
            end,
        })
    end)

    task.spawn(function()
        while alive() do
            local txt
            if Refs.World then
                local list = Vend.machines()
                local total, empty = 0, 0
                for _, m in ipairs(list) do
                    if m.id and m.stock > 0 then total += m.stock else empty += 1 end
                end
                local name, door = Vend.point()
                local names = {}
                for i, id in ipairs(Vend.Items) do
                    if i > 4 then
                        names[#names + 1] = "+" .. (#Vend.Items - 4)
                        break
                    end
                    names[#names + 1] = itemName(id)
                end
                if not Vend.Running then Vend.refreshItems(false, list) end
                txt = table.concat({
                    "Status  : " .. (Vend.Running and "JALAN" or "BERHENTI") .. " - " .. Vend.Mode,
                    "Item    : " .. ((#names > 0) and table.concat(names, ", ") or "semua item yang bisa dijual"),
                    ("Vending : %d milikmu di world ini | isi %d | kosong %d"):format(#list, total, empty),
                    "Titik   : " .. ((name ~= "" or door) and (name .. (door and (":" .. door) or "")) or "world ini")
                        .. (Vend.DropX >= 0 and (" (" .. Vend.DropX .. "," .. Vend.DropY .. ")") or " (titik kedatangan)"),
                    ("Hasil   : stock +%d | diambil %d | di-drop %d"):format(Vend.Stocked, Vend.Taken, Vend.Dropped),
                    "Aksi    : " .. Vend.Status,
                }, "\n")
            else
                txt = "Data world belum ketemu"
            end
            if UI.VendStatus and txt ~= Vend.Shown then
                Vend.Shown = txt
                pcall(function() UI.VendStatus:SetDesc(txt) end)
            end
            task.wait(1)
        end
    end)
end)() end

-- ===== TAB: PABRIK =====
do (function()
    local PTab = makeTab("Pabrik", "factory", "farm")

    safe(function()
        UI.PabrikStatus = PTab:Paragraph({ Title = "Status Pabrik", Desc = "-" })
    end)

    local pCtl = box(PTab, "Kontrol", true)
    local pBreak = box(PTab, "Posisi & tile break", true)
    local pDrop = box(PTab, "Drop seed", true)

    safe(function()
        UI.PabrikToggle = pCtl:Toggle({
            Title = "Jalankan Pabrik",
            Desc = "Panen pohon ready -> ambil block -> break -> tanam; ulang otomatis",
            Value = false,
            Callback = function(on)
                if on then Pabrik.start() elseif Pabrik.Running then Pabrik.stop() end
            end,
        })
    end)

    safe(function()
        pCtl:Toggle({
            Title = "Pabrik lebih cepat",
            Desc = "Dahulukan target dekat, jalan lurus lebih lancar, dan kurangi jeda tambahan",
            Value = Pabrik.Fast,
            Callback = function(on) Pabrik.Fast = on; table.clear(Pabrik.Row) end,
        })
    end)

    safe(function()
        UI.PabrikSeedDropdown = pCtl:Dropdown({
            Title = "Seed pabrik",
            Desc = "Block-nya otomatis (contoh: Dirt Seed -> Dirt)",
            Values = { "(memuat...)" },
            Callback = function(opt)
                local id = tonumber(string.match(opt or "", "%[(%d+)%]$"))
                if id then Pabrik.SeedId = id end
            end,
        })
    end)

    safe(function()
        pCtl:Toggle({
            Title = "Tanam di seluruh world",
            Desc = "Mati = hanya di Dirt Farm (tab Dirt Farm)",
            Value = Pabrik.WholeWorld,
            Callback = function(on) Pabrik.WholeWorld = on end,
        })
    end)

    safe(function()
        pBreak:Button({
            Title = "Pakai posisi sekarang untuk break",
            Desc = "Berdiri di tempat break, lalu tekan",
            Callback = function()
                local x, y = Auto.here()
                if not x then
                    notify("Pabrik", "Kamu belum masuk world", 3)
                    return
                end
                Pabrik.BreakX, Pabrik.BreakY = x, y
                notify("Pabrik", ("Posisi break (%d,%d)"):format(x, y), 3)
            end,
        })
    end)

    safe(function()
        pBreak:Button({
            Title = "Pilih tile break (Grid)",
            Desc = "Grid terbuka dalam mode Pabrik (terpisah dari tile Auto Farm)",
            Callback = function()
                if UI.setGridMode then UI.setGridMode("pabrik") end
                if UI.GridGui then UI.GridGui.Enabled = true end
            end,
        })
    end)

    safe(function()
        pDrop:Toggle({
            Title = "Auto drop seed",
            Desc = "Ke titik drop (tab Titik Drop)",
            Value = Pabrik.Drop,
            Callback = function(on) Pabrik.Drop = on end,
        })
    end)

    addNumber(pDrop, {
        Title = "Sisakan seed",
        Desc = "Untuk ditanam lagi",
        Min = 0, Max = 199, Step = 1, Default = Pabrik.Keep,
        Callback = function(v) Pabrik.Keep = math.floor(v) end,
    })

    addNumber(pDrop, {
        Title = "Drop kalau seed sudah",
        Desc = "Contoh 200 & sisakan 50 = drop 150",
        Min = 2, Max = 200, Step = 1, Default = Pabrik.DropAt,
        Callback = function(v) Pabrik.DropAt = math.floor(v) end,
    })

    local function countKeys(t)
        local n = 0
        for _ in pairs(t) do n += 1 end
        return n
    end

    task.spawn(function()
        while alive() do
            local seed, block = Pabrik.SeedId, Auto.blockOfSeed(Pabrik.SeedId)
            local name, door = Auto.parseDropTarget()
            local dropAt = (name ~= "" and name or "world ini") .. (door and (" pintu " .. door) or "")
                .. (Pabrik.DropX >= 0 and (" (" .. Pabrik.DropX .. "," .. Pabrik.DropY .. ")") or "")
            local txt = table.concat({
                "Status : " .. (Pabrik.Running and ("JALAN - fase " .. tostring(Pabrik.Phase or "-")) or "BERHENTI"),
                ("Seed   : %s x%d | block %s x%d"):format(seed and itemName(seed) or "-", seed and invCount(seed) or 0,
                    block and itemName(block) or "-", block and invCount(block) or 0),
                ("Break  : %s | tile %d"):format(Pabrik.BreakX >= 0 and ("(" .. Pabrik.BreakX .. "," .. Pabrik.BreakY .. ")")
                    or "belum diatur", countKeys(Pabrik.Tiles)),
                ("Drop   : %s | sisakan %d, drop saat >= %d"):format(Pabrik.Drop and dropAt or "mati", Pabrik.Keep, Pabrik.DropAt),
                "Pola   : panen ready -> ambil block -> break -> tanam",
                ("Hasil  : panen %d | ambil block %d | tanam %d | di-drop %d"):format(Pabrik.Harvested,
                    Pabrik.BlocksTaken or 0, Pabrik.Planted, Pabrik.Dropped),
                "Panen  : " .. Pabrik.harvestStatus(),
                "Aksi   : " .. Pabrik.Status
                    .. (Pabrik.CollectReason and ("\nCollect: " .. Pabrik.CollectReason) or "")
                    .. (Pabrik.DropError and ("\nDrop tertunda: " .. Pabrik.DropError) or ""),
            }, "\n")
            if UI.PabrikStatus and txt ~= Pabrik.Shown then
                Pabrik.Shown = txt
                pcall(function() UI.PabrikStatus:SetDesc(txt) end)
            end
            -- tombol START di Grid (mode pabrik)
            if UI.GridMode == "pabrik" and UI.GridStart then
                UI.GridStart.Text = I18N.T(Pabrik.Running and "STOP PABRIK" or "START PABRIK")
                UI.GridStart.BackgroundColor3 = Pabrik.Running and Color3.fromRGB(200, 60, 60) or Color3.fromRGB(46, 160, 90)
            end
            task.wait(1)
        end
    end)
end)() end

---------------------------------------------------------------------
-- AUTO RECONNECT
---------------------------------------------------------------------
-- Cara kerja:
--   Terlempar dari world (event WorldClosed dari server):
--     catat aktivitas -> tunggu -> masuk world yang sama lagi -> lanjut aktivitas.
--   Disconnect dari server Roblox (layar error muncul):
--     catat aktivitas ke file -> teleport ulang ke game dengan data world
--     (game otomatis masuk world itu) -> script jalan lagi -> lanjut aktivitas.
--     Supaya script jalan lagi setelah teleport: isi URL script (queue_on_teleport)
--     atau taruh script di folder autoexec executor.
local Rejoin = {
    On = false,
    World = true,       -- masuk lagi kalau terlempar dari world
    Server = true,      -- rejoin kalau disconnect dari server
    DelaySec = 5,
    ScriptUrl = Premium.LoaderURL,
    Keep = true,        -- selalu kembali ke world tujuan kalau berada di luar world
    Target = "",        -- world tujuan (kosong = world terakhir)
    LastWorld = "",     -- world terakhir yang dimasuki
    Last = nil,         -- catatan aktivitas terakhir
    LastAt = 0,
    Busy = false,
    Count = 0,
    Status = "Mati — nyalakan Auto Rejoin",
    Token = 0,
    RetryAt = 0,
}

do (function()
    local HttpService = game:GetService("HttpService")
    local TeleportService = game:GetService("TeleportService")
    local GuiService = game:GetService("GuiService")
    local canFile = type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
    local PENDING = "ZekioSupremePremiumTest/rejoin_" .. tostring(LocalPlayer.UserId) .. ".json"

    -- One worker owns a recovery. Keep the last valid snapshot frozen outside
    -- the world; never replace it with empty-world coordinates or paused flags.
    local function normalWorld()
        return not Pabrik.Traveling and not Vend.Traveling and Guard.Mode == "idle"
    end

    local function ready(world)
        local w = Refs.World
        return world ~= "" and Guard.worldName() == world and w
            and type(rawget(w, "fg")) == "table" and Auto.here() ~= nil
    end

    function Rejoin.targetWorld()
        local t = tostring(Rejoin.Target or ""):upper():gsub("[^A-Z0-9]", "")
        return t ~= "" and t or (Rejoin.LastWorld or "")
    end

    function Rejoin.capture()
        if Rejoin.Busy or Rejoin.Leaving or not normalWorld() then return end
        local world = Guard.worldName()
        if not ready(world) then return end
        if Rejoin.LastWorld ~= world then Rejoin.Last = nil end
        Rejoin.LastWorld = world
        if Guard.anyRunning() then
            Rejoin.Last = Guard.snapshot()
            if Rejoin.Last.vend and type(Vend.Home) == "string" and Vend.Home ~= "" then
                Rejoin.Last.world = Vend.Home
                Rejoin.LastWorld = Vend.Home
            end
            Rejoin.LastAt = os.clock()
        elseif os.clock() - Rejoin.LastAt > 3 then
            Rejoin.Last = nil -- activity was stopped while still inside the world
        end
    end

    local function resume(saved, reason, live)
        Guard.afterEnter()
        if not alive() or (live and not live()) or not ready(saved.world) then return false end
        Rejoin.Count += 1
        Rejoin.Status = "Masuk lagi berhasil; memulihkan aktivitas"
        notify("Auto Rejoin", reason .. ": memulihkan aktivitas", 4)
        Hook.send("rejoin", reason .. " ke " .. tostring(saved.world))
        Guard.resumeSaved(saved)
        Rejoin.ResumeToken = Guard.Token
        return true
    end

    function Rejoin.cancel()
        Rejoin.Token += 1
        Rejoin.Busy = false
        Rejoin.Leaving = false
        Rejoin.OutSince = nil
        Rejoin.RetryAt = 0
        if Rejoin.ResumeToken and Guard.Token == Rejoin.ResumeToken and Guard.Mode == "back" then
            Guard.Token += 1
            Guard.Mode, Guard.Saved = "idle", nil
            Guard.stopAll()
        end
        Rejoin.ResumeToken = nil
        Rejoin.Status = "Auto Rejoin dibatalkan"
    end

    function Rejoin.set(on)
        if not on then Rejoin.cancel() end
        Rejoin.On = on == true
        if Rejoin.On then
            Rejoin.Keep = true
            if UI.RejoinKeepToggle then pcall(function() UI.RejoinKeepToggle:Set(true) end) end
            Rejoin.capture()
            Rejoin.Status = "Siaga — kembali ke world terakhir dan lanjut aktivitas"
        else
            Rejoin.Last = nil
            Rejoin.Status = "Auto Rejoin mati"
        end
    end

    function Rejoin.request(world, saved, reason, manual)
        if Rejoin.Busy or Rejoin.Leaving or not alive() or not normalWorld() or world == "" then return false end
        if not manual and not Rejoin.On then return false end
        Rejoin.Token += 1
        local token = Rejoin.Token
        local function live()
            return alive() and Rejoin.Token == token and (manual or Rejoin.On)
                and not Rejoin.Leaving and normalWorld()
        end
        local function waitFor(sec)
            local untilAt = os.clock() + sec
            repeat
                if not live() then return false end
                task.wait(0.1)
            until os.clock() >= untilAt
            return live()
        end
        Rejoin.Busy = true
        Rejoin.Status = "Menunggu untuk masuk lagi ke " .. world
        -- Stop synchronously so no old farm worker keeps moving during loading.
        Guard.stopAll()
        task.spawn(function()
            local success = false
            local ok, err = pcall(function()
                if manual and Guard.worldName() ~= "" then
                    if not Guard.leaveWorld() then error("Gagal keluar world") end
                end
                if not waitFor(math.max(2, tonumber(Rejoin.DelaySec) or 5)) then return end
                for attempt = 1, 3 do
                    if not live() then return end
                    local here = Guard.worldName()
                    if here ~= "" and here ~= world then
                        Rejoin.Last = nil
                        Rejoin.Status = "World diganti; rejoin sebelumnya dibatalkan"
                        return
                    end
                    if not ready(world) then
                        Rejoin.Status = ("Masuk ke %s (%d/3)"):format(world, attempt)
                        local entered, why = Guard.enterWorld(world, live)
                        if not entered then Rejoin.Status = "Menunggu world: " .. tostring(why) end
                    end
                    local timeout = os.clock() + 15
                    while live() and not ready(world) and os.clock() < timeout do task.wait(0.25) end
                    if not live() then return end
                    if ready(world) then
                        Guard.afterEnter()
                        if not live() or not ready(world) then return end
                        -- Revalidate after ref discovery, which can yield.
                        Rejoin.Count += 1
                        Rejoin.Status = "Kembali ke " .. world .. " berhasil"
                        if saved and saved.world == world then
                            Rejoin.Status ..= "; memulihkan aktivitas"
                            Guard.resumeSaved(saved)
                            Rejoin.ResumeToken = Guard.Token
                        end
                        success = true
                        Hook.send("rejoin", reason .. ": " .. world)
                        return
                    end
                    if attempt < 3 and not waitFor(8) then return end
                end
                Rejoin.Status = "World belum tersedia; dicoba lagi dalam 20 detik"
            end)
            if Rejoin.Token == token then
                Rejoin.Busy = false
                Rejoin.OutSince = nil
                Rejoin.RetryAt = success and 0 or (os.clock() + 20)
                if not ok then
                    Rejoin.Status = "Rejoin gagal: " .. tostring(err):sub(1, 160) .. "; coba lagi nanti"
                end
            end
        end)
        return true
    end

    local function onWorldClosed(_msg)
        if not (Rejoin.On and Rejoin.World) or not normalWorld() or Rejoin.Busy then return end
        -- If the event precedes clearing the game state, capture it now.
        Rejoin.capture()
        local world = Rejoin.targetWorld()
        Rejoin.request(world, Rejoin.Last, "World ditutup", false)
    end

    local closedHooked = false
    if NetOk and type(Net) == "table" and type(Net.on) == "function"
        and type(Net.EVENTS) == "table" and Net.EVENTS.WorldClosed then
        closedHooked = pcall(Net.on, "WorldClosed", function(msg)
            if alive() then onWorldClosed(msg) end
        end, function() return Guard.worldName() end)
    end
    if not closedHooked then
        local closed = WorldRemotes:FindFirstChild("WorldClosed")
        if closed and closed:IsA("RemoteEvent") then
            table.insert(Connections, closed.OnClientEvent:Connect(function(msg)
                if alive() then onWorldClosed(msg) end
            end))
        end
    end

    function Rejoin.now()
        Rejoin.capture()
        local world = Rejoin.targetWorld()
        if world == "" then
            notify("Auto Rejoin", "Masuk world dulu atau isi World tujuan", 4)
            return
        end
        if not Rejoin.request(world, Rejoin.Last, "Rejoin manual", true) then
            notify("Auto Rejoin", "Tunggu proses masuk world atau perjalanan yang sedang berjalan", 4)
        end
    end

    function Rejoin.tick()
        Rejoin.capture()
        if not (Rejoin.On and Rejoin.Keep) or Rejoin.Busy or Rejoin.Leaving or not normalWorld() then
            Rejoin.OutSince = nil
            return
        end
        if Guard.worldName() ~= "" then
            Rejoin.OutSince = nil
            return
        end
        Rejoin.OutSince = Rejoin.OutSince or os.clock()
        if os.clock() - Rejoin.OutSince < 0.5 or os.clock() < Rejoin.RetryAt then return end
        Rejoin.request(Rejoin.targetWorld(), Rejoin.Last, "Kembali otomatis", false)
    end

    task.spawn(function()
        while alive() do
            local ok, err = pcall(Rejoin.tick)
            if not ok then Rejoin.Status = "Menunggu data world: " .. tostring(err):sub(1, 120) end
            task.wait(0.25)
        end
    end)

    -- ===== disconnect dari server =====
    local function queueScript()
        local q = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
        local url = tostring(Rejoin.ScriptUrl or "")
        if type(q) == "function" and string.sub(url, 1, 8) == "https://" then
            return pcall(q, ("loadstring(game:HttpGet(%q))()"):format(url))
        end
        return false
    end

    local function onDisconnect(msg)
        if not (Rejoin.On and Rejoin.Server) or Rejoin.Leaving then return end
        Rejoin.capture()
        Rejoin.Leaving = true
        Rejoin.Token += 1
        local disconnectToken = Rejoin.Token
        local saved = Rejoin.Last or (Guard.anyRunning() and Guard.snapshot()) or nil
        local world = saved and saved.world or Rejoin.targetWorld()
        Config.save(true) -- creates the config folder before writing the resume record
        if canFile and saved then
            local data = {
                world = saved.world, farm = saved.farm, clear = saved.clear, farmer = saved.farmer,
                spam = saved.spam, splice = saved.splice, pabrik = saved.pabrik, build = saved.build, vend = saved.vend,
                tx = saved.tx, ty = saved.ty, at = os.time(),
            }
            pcall(function() writefile(PENDING, HttpService:JSONEncode(data)) end)
        end
        local queued = queueScript()
        Rejoin.Status = "Disconnect: rejoin..." .. (queued and "" or " (script tidak di-queue)")
        Hook.send("rejoin", "Disconnect dari server (" .. tostring(msg) .. "). Rejoin ke " .. (world ~= "" and world or "game"))
        task.spawn(function()
            task.wait(Rejoin.DelaySec)
            while alive() and Rejoin.On and Rejoin.Server and Rejoin.Leaving and Rejoin.Token == disconnectToken do
                pcall(function()
                    TeleportService:Teleport(game.PlaceId, LocalPlayer, (world ~= "") and { world = world } or nil)
                end)
                task.wait(15) -- belum pindah: coba lagi
            end
        end)
    end

    pcall(function()
        table.insert(Connections, GuiService.ErrorMessageChanged:Connect(function(msg)
            if alive() and type(msg) == "string" and msg ~= "" then onDisconnect(msg) end
        end))
    end)

    -- ===== setelah execute: lanjutkan dari catatan rejoin =====
    function Rejoin.startup(reconnectFn)
        if not canFile then return end
        local okE, has = pcall(isfile, PENDING)
        if not okE or not has then return end
        local okR, raw = pcall(readfile, PENDING)
        if type(delfile) == "function" then pcall(delfile, PENDING) end
        if not okR or type(raw) ~= "string" then return end
        local okD, saved = pcall(HttpService.JSONDecode, HttpService, raw)
        if not okD or type(saved) ~= "table" or type(saved.world) ~= "string" or saved.world == "" then return end
        if os.time() - (tonumber(saved.at) or 0) > 15 * 60 then return end -- terlalu lama
        Rejoin.Token += 1
        local token = Rejoin.Token
        local function live() return alive() and Rejoin.On and Rejoin.Token == token end
        if not live() then return end
        Rejoin.Busy = true
        Rejoin.Status = "Rejoin: menunggu masuk " .. saved.world
        -- tunggu game masuk world (lewat data teleport); kalau tidak, masuk sendiri
        local t0 = os.clock()
        local tried = false
        while live() and os.clock() - t0 < 60 do
            if Refs.World and Guard.worldName() == saved.world and Auto.here() then break end
            if not Refs.World then pcall(reconnectFn) end
            if Refs.World and not tried and os.clock() - t0 > 12 then
                tried = true
                Guard.enterWorld(saved.world, live)
            end
            task.wait(2)
        end
        if live() and ready(saved.world) then
            pcall(reconnectFn)
            task.wait(1)
            resume(saved, "Rejoin server", live)
        elseif live() then
            Rejoin.Status = "Rejoin: gagal masuk " .. saved.world
            Hook.send("rejoin", Rejoin.Status)
        end
        if Rejoin.Token == token then Rejoin.Busy = false end
    end
end)() end

Config.add("Reconnect", Rejoin, { "On", "World", "Server", "DelaySec", "ScriptUrl", "Keep", "Target" })
Config.add("Discord", Hook, { "On", "Url", "Penjaga", "Stop", "Full", "Bonus", "Rejoin", "Pabrik", "ReportMin" })

-- ===== TAB: TITIK DROP (dipakai Pabrik dan Auto Farm) =====
do (function()
    local DTab = makeTab("Titik Drop", "map-pin", "farm")

    safe(function()
        UI.DropPointStatus = DTab:Paragraph({ Title = "Titik Drop", Desc = "-" })
    end)

    local dBox = box(DTab, "Atur titik drop", true)

    safe(function()
        UI.DropWorldInput = dBox:Input({
            Title = "World drop",
            Desc = "Kosong = world ini | WORLD | WORLD:ID (masuk lewat pintu ID)",
            Value = Pabrik.DropWorld,
            Placeholder = "STORAGE:1",
            Callback = function(t) Pabrik.DropWorld = tostring(t or "") end,
        })
    end)

    safe(function()
        dBox:Button({
            Title = "Pakai posisi sekarang untuk drop",
            Desc = "Berdiri di tempat drop (boleh di world lain), lalu tekan",
            Callback = function()
                local x, y = Auto.here()
                if not x then
                    notify("Titik Drop", "Kamu belum masuk world", 3)
                    return
                end
                Pabrik.DropX, Pabrik.DropY = x, y
                -- world ikut diisi, kecuali sudah pakai format WORLD:ID
                if not string.find(Pabrik.DropWorld or "", ":", 1, true) then
                    Pabrik.DropWorld = Guard.worldName()
                    if UI.DropWorldInput then pcall(function() UI.DropWorldInput:Set(Pabrik.DropWorld) end) end
                end
                notify("Titik Drop", ("Posisi drop (%d,%d) di %s"):format(x, y, Pabrik.DropWorld), 4)
            end,
        })
    end)

    safe(function()
        dBox:Button({
            Title = "Hapus posisi drop",
            Desc = "Drop di titik kedatangan (pintu) saja",
            Callback = function()
                Pabrik.DropX, Pabrik.DropY = -1, -1
                notify("Titik Drop", "Posisi drop dihapus", 3)
            end,
        })
    end)

    task.spawn(function()
        while alive() do
            local name, door = Auto.parseDropTarget()
            local here = Guard.worldName()
            local point
            if Pabrik.DropX < 0 and not door and (name == "" or name == here) then
                point = "belum diatur"
            else
                point = (name ~= "" and name or "world ini") .. (door and (" pintu " .. door) or "")
                    .. (Pabrik.DropX >= 0 and (" (" .. Pabrik.DropX .. "," .. Pabrik.DropY .. ")") or " (titik kedatangan)")
            end
            local txt = table.concat({
                "Titik  : " .. point,
                "Dipakai: Pabrik (seed) & Auto Farm (otomatis saat item ~190)",
                ("Di-drop: Pabrik %d | Auto Farm %d"):format(Pabrik.Dropped, State.Dropped),
                "Catatan: drop di titik ini tidak di-collect lagi",
            }, "\n")
            if UI.DropPointStatus and txt ~= UI.DropPointShown then
                UI.DropPointShown = txt
                pcall(function() UI.DropPointStatus:SetDesc(txt) end)
            end
            task.wait(1)
        end
    end)
end)() end

-- ===== TAB: KONEKSI =====
local ConnTab = makeTab("Koneksi", "plug", "setel")

safe(function()
    UI.RefInfo = ConnTab:Paragraph({ Title = "Referensi game", Desc = "-" })
end)

Box.ConnMain = box(ConnTab, "Koneksi", true)
Box.ConnCfg = box(ConnTab, "Config", true)
Box.ConnCalib = box(ConnTab, "Koreksi posisi", false)
Box.ConnLang = box(ConnTab, "Bahasa / Language", false)

local function reconnect(show)
    -- hentikan Clear / Farmer dulu
    if Clear.Running then stopClear("Dihentikan: hubungkan ulang ke game") end
    if Farmer.Running then stopFarmer("Dihentikan: hubungkan ulang ke game") end
    Auto.resetReach()
    -- 1) cari isi tas cepat lalu langsung isi dropdown (tidak menunggu scan getgc yang lama)
    if pcall(Anim.quickRefs) and Refs.Inv then
        UI.checkInventory(true, true)
        task.wait() -- biar dropdown tampil dulu sebelum scan lengkap (scan menahan layar sebentar)
    end
    -- 2) scan lengkap
    findRefs()
    AutoInput.bindMenu()
    watchInventory()
    UI.checkInventory(true, true) -- langsung di thread ini (thread INIT / antrian UI), bukan thread tombol
    findDropRefs(true)
    Drops.LastError = nil
    Auto.NextTreeGCScan = 0 -- tombol Hubungkan boleh memulai pencarian ulang
    Auto.findTreeRefs()
    table.clear(DropFailUntil)
    Anim.fn, Anim.idx = nil, nil
    pcall(Anim.findFast)
    if State.LiteMode then setLite(true) end
    if Misc.InfJump then hookJammer() end
    pcall(function() UI.RefInfo:SetDesc(refsText()) end)
    updateStatus()
    if show then notify(show, refsText(), 5) end
end

safe(function()
    Box.ConnMain:Button({
        Title = "Hubungkan ke game",
        Desc = "Pakai setelah pindah world",
        Callback = function()
            UI.later("reconnect", function() reconnect("Koneksi") end)
        end,
    })
end)

safe(function()
    UI.ConfigStatus = Box.ConnCfg:Paragraph({ Title = "Status", Desc = Config.Status })
end)

safe(function()
    Box.ConnCfg:Toggle({
        Title = "Auto Save Config",
        Desc = "Simpan pengaturan otomatis, dimuat lagi saat execute",
        Value = Config.AutoSave,
        Callback = function(on)
            Config.AutoSave = on
            Config.save(true) -- simpan pilihan ini juga
        end,
    })
end)

safe(function()
    Box.ConnCfg:Button({
        Title = "Simpan config sekarang",
        Callback = function()
            local ok = Config.save(true)
            notify("Config", ok and "Tersimpan" or Config.Status, 3)
        end,
    })
end)

safe(function()
    Box.ConnCfg:Button({
        Title = "Reset config (default)",
        Desc = "Hapus file config, lalu execute ulang",
        Callback = function()
            Config.reset()
            notify("Config", Config.Status, 4)
        end,
    })
end)

safe(function()
    Box.ConnLang:Dropdown({
        Title = "Bahasa / Language",
        Desc = "Ganti bahasa, lalu execute ulang",
        Values = { "Indonesia", "English" },
        Value = I18N.Saved == "en" and "English" or "Indonesia",
        Callback = function(v)
            local lang = (v == "English") and "en" or "id"
            if lang == I18N.Saved then return end
            I18N.Saved = lang
            Config.save(true)
            notify("Bahasa / Language", "Execute ulang untuk ganti bahasa / Re-execute to apply", 5)
        end,
    })
end)

safe(function()
    Box.ConnLang:Toggle({
        Title = "Tanya bahasa saat execute",
        Desc = "Pilihan muncul setelah menu terbuka; pergantian bahasa berlaku saat execute ulang",
        Value = I18N.Ask,
        Callback = function(on) I18N.Ask = on end,
    })
end)

safe(function()
    Box.ConnCalib:Input({
        Title = "Koreksi posisi X",
        Desc = "Isi 1 / -1 kalau tile meleset",
        Value = tostring(State.CalibX),
        Callback = function(text) State.CalibX = tonumber(text) or 0 end,
    })
end)

safe(function()
    Box.ConnCalib:Input({
        Title = "Koreksi posisi Y",
        Value = tostring(State.CalibY),
        Callback = function(text) State.CalibY = tonumber(text) or 0 end,
    })
end)

-- ===== KONEKSI: AUTO RECONNECT =====
do (function()
    local RejoinTab = makeTab("Auto Rejoin", "rotate-cw", "setel")
    local rBox = box(RejoinTab, "Auto Rejoin", true)

    safe(function()
        UI.RejoinStatus = rBox:Paragraph({ Title = "Status", Desc = Rejoin.Status })
    end)

    safe(function()
        rBox:Toggle({
            Title = "Auto Rejoin",
            Desc = "Keluar world: masuk world terakhir, lalu lanjut aktivitas sebelumnya",
            Value = Rejoin.On,
            Callback = function(on) Rejoin.set(on) end,
        })
    end)

    safe(function()
        rBox:Toggle({
            Title = "Terlempar dari world",
            Desc = "World ditutup / di-kick: masuk lagi ke world yang sama",
            Value = Rejoin.World,
            Callback = function(on)
                Rejoin.World = on
                if not on then Rejoin.cancel() end
            end,
        })
    end)

    safe(function()
        UI.RejoinKeepToggle = rBox:Toggle({
            Title = "Selalu kembali ke world",
            Desc = "Kalau berada di luar world (layar pilih world), masuk lagi otomatis",
            Value = Rejoin.Keep,
            Callback = function(on)
                Rejoin.Keep = on
                if not on then Rejoin.cancel() end
            end,
        })
    end)

    safe(function()
        rBox:Input({
            Title = "World tujuan",
            Desc = "Kosongkan = world terakhir yang kamu masuki",
            Value = Rejoin.Target,
            Placeholder = "NAMAWORLD",
            Callback = function(text)
                Rejoin.cancel()
                Rejoin.Target = tostring(text or "")
            end,
        })
    end)

    safe(function()
        rBox:Button({
            Title = "Rejoin world sekarang",
            Desc = "Keluar lalu masuk lagi, aktivitas dilanjutkan",
            Callback = function() Rejoin.now() end,
        })
    end)

    safe(function()
        rBox:Toggle({
            Title = "Disconnect dari server",
            Desc = "Teleport ulang ke game lalu masuk world terakhir",
            Value = Rejoin.Server,
            Callback = function(on) Rejoin.Server = on end,
        })
    end)

    addNumber(rBox, {
        Title = "Jeda sebelum masuk lagi (detik)",
        Min = 2, Max = 60, Step = 1, Default = Rejoin.DelaySec,
        Callback = function(v) Rejoin.DelaySec = math.floor(v) end,
    })

    safe(function()
        rBox:Input({
            Title = "URL script (untuk rejoin server)",
            Desc = "Link raw script ini, supaya jalan lagi setelah teleport. Kosong = pakai autoexec",
            Value = Rejoin.ScriptUrl,
            Placeholder = "https://...",
            Callback = function(text)
                Rejoin.ScriptUrl = tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
            end,
        })
    end)
end)() end

-- ===== TAB: DISCORD =====
do (function()
    local DcTab = makeTab("Discord", "bell", "setel")

    safe(function()
        UI.HookStatus = DcTab:Paragraph({ Title = "Status", Desc = Hook.Status })
    end)

    local dMain = box(DcTab, "Webhook", true)
    local dWhat = box(DcTab, "Yang dikirim", false)

    safe(function()
        dMain:Toggle({
            Title = "Notifikasi Discord",
            Desc = "Kirim kabar penting ke channel Discord kamu",
            Value = Hook.On,
            Callback = function(on) Hook.On = on end,
        })
    end)

    safe(function()
        dMain:Input({
            Title = "URL Webhook",
            Desc = "Channel Discord > Edit > Integrasi > Webhook > Salin URL",
            Value = Hook.Url,
            Placeholder = "https://discord.com/api/webhooks/...",
            Callback = function(text)
                text = tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
                Hook.Url = text
                if text ~= "" and not Hook.valid(text) then
                    notify("Discord", "URL webhook tidak valid", 4)
                end
            end,
        })
    end)

    safe(function()
        dMain:Button({
            Title = "Tes kirim",
            Callback = function()
                if not Hook.valid(Hook.Url) then
                    notify("Discord", "Isi URL webhook dulu", 3)
                    return
                end
                local was = Hook.On
                Hook.On = true
                Hook.send("test", "Tes notifikasi dari Zekio Supreme Premium")
                Hook.On = was
                notify("Discord", "Pesan tes masuk antrian", 3)
            end,
        })
    end)

    addNumber(dMain, {
        Title = "Laporan statistik (menit)",
        Desc = "Kirim statistik sesi tiap X menit. 0 = mati",
        Min = 0, Max = 180, Step = 5, Default = Hook.ReportMin,
        Callback = function(v) Hook.ReportMin = math.floor(v) end,
    })

    for _, item in ipairs({
        { "Penjaga", "Mod / Dev / pemain masuk world" },
        { "Stop", "Aktivitas berhenti (block habis / error)" },
        { "Full", "Inventori penuh" },
        { "Bonus", "Quest diklaim / redeem berhasil" },
        { "Rejoin", "Terlempar / disconnect / masuk lagi" },
        { "Pabrik", "Pabrik drop seed / Dirt Farm selesai / berhenti" },
    }) do
        safe(function()
            dWhat:Toggle({
                Title = item[2],
                Value = Hook[item[1]],
                Callback = function(on) Hook[item[1]] = on end,
            })
        end)
    end
end)() end


---------------------------------------------------------------------
-- INIT
---------------------------------------------------------------------
-- All controls are registered before restoring saved toggles or dropdowns.
Premium.EngineReady=true
-- Thread pekerjaan UI: dibuat di sini (sama seperti thread status yang terbukti bisa mengubah UI).
-- Callback tombol / event game di sebagian executor tidak punya izin mengubah dropdown.
do
    task.spawn(function()
        while alive() do
            local ok, err = pcall(UI.runJobs)
            if not ok then warn("[Zekio Supreme Premium] UI runner: " .. tostring(err)) end
            task.wait(0.1)
        end
    end)
end

task.spawn(function()
    local ok, err = xpcall(function()
        reconnect("Zekio Supreme Premium P15")
        if not alive() then return end
        Premium.ConnectionError = nil
        if Config.saved("Penjaga", "On") == true then
            if UI.GuardToggle then pcall(function() UI.GuardToggle:Set(true) end) end
            if not Guard.On then Guard.set(true) end
        end
        Config.start()
        Rejoin.startup(reconnect)
    end, function(message)
        if debug and type(debug.traceback) == "function" then return debug.traceback(tostring(message), 2) end
        return tostring(message)
    end)
    if not ok and alive() then
        Premium.ConnectionError = tostring(err):sub(1, 1000)
        Session.Report("Gagal menghubungkan data game: " .. Premium.ConnectionError
            .. "\nCoba tombol Hubungkan ke game pada tab Koneksi.")
        warn("[Zekio Premium koneksi] " .. tostring(err))
    end
end)

task.spawn(function()
    while alive() do
        if not State.Running then updateStatus() end
        Auto.updateClearStatus()
        Auto.updateFarmerStatus()
        Premium.UpdateSummary(("World: %s\nFarm: %s | Farmer: %s\nPabrik: %s | Dirt Farm: %s\nClear: %s | Vending: %s"):format(
            Guard.worldName()~="" and Guard.worldName() or "belum masuk world",State.Running and "Jalan" or "Berhenti",
            Farmer.Running and "Jalan" or "Berhenti",Pabrik.Running and tostring(Pabrik.Phase or "Jalan") or "Berhenti",
            Build.Running and "Jalan" or "Berhenti",Clear.Running and "Jalan" or "Berhenti",Vend.Running and "Jalan" or "Berhenti"))
        updateSpamStatus()
        if UI.ConfigStatus and Config.Status ~= Config.Shown then
            Config.Shown = Config.Status
            pcall(function() UI.ConfigStatus:SetDesc(Config.Status) end)
        end
        local rj = ("%s\nWorld tujuan: %s\nBerhasil masuk lagi: %d kali"):format(
            Rejoin.Status, (Rejoin.targetWorld and Rejoin.targetWorld() ~= "") and Rejoin.targetWorld() or "-", Rejoin.Count)
        if UI.RejoinStatus and rj ~= Rejoin.Shown then
            Rejoin.Shown = rj
            pcall(function() UI.RejoinStatus:SetDesc(rj) end)
        end
        local hk = ("%s\nAntrian: %d pesan"):format(Hook.Status, #Hook.Queue)
        if UI.HookStatus and hk ~= Hook.Shown then
            Hook.Shown = hk
            pcall(function() UI.HookStatus:SetDesc(hk) end)
        end
        task.wait(1)
    end
end)

---------------------------------------------------------------------
-- CLEANUP (otomatis saat script dijalankan ulang)
---------------------------------------------------------------------
Session.Cleanup = function()
    if Session.Closed then return end
    Session.Closed=true
    if Premium.ProxyStop then pcall(Premium.ProxyStop) end
    Session.CloseBoot()
    State.Running = false
    Clear.Running = false
    Farmer.Running = false
    Spam.On = false
    if Config.AutoSave then pcall(Config.save, false) end -- simpan sebelum ditutup
    Guard.On = false
    Bonus.Quest, Bonus.Redeem = false, false
    Scan.Auto = false
    Splice.Running = false
    Rejoin.cancel()
    Rejoin.On = false
    Pabrik.Running = false
    Build.Running = false
    State.Override = nil
    pcall(Auto.stopWalk)
    AutoInput.active = false
    pcall(Auto.releaseInput)
    for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
    -- kembalikan nama asli (watermark dilepas)
    Misc.CustomName = false
    pcall(nameRestore)
    -- kembalikan fungsi game ke asal
    pcall(setLite, false)
    pcall(unhookJammer)
    AutoInput.unbindMenu()
    if Shared.EmptyRemotes then pcall(function() Shared.EmptyRemotes:Destroy() end) end
    if Refs.World then
        if Misc.Ghost then pcall(function() Refs.World.ghost = false end) end
        if Misc.Speed ~= 100 then pcall(function() Refs.World.speedScale = 1 end) end
    end
    pcall(function() GridGui:Destroy() end)
    pcall(function() FlyPad:Destroy() end)
    pcall(function() Window:Destroy() end)
end

Session.Ready=true
Session.CloseBoot()
Premium.AttachGrid(GridGui)
FlyPad.DisplayOrder=Premium.Gui.DisplayOrder+2
Premium.SetEngineReady()

end, function(message)
    if debug and type(debug.traceback) == "function" then return debug.traceback(tostring(message), 2) end
    return tostring(message)
end)
if not startupOk and alive() then Session.FailStartup(startupError) end

end)
return Premium
