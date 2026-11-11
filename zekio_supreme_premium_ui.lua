-- Zekio Supreme Premium | UI ONLY P2
-- Self-contained interface. Every feature action is an unconnected UI stub.
-- No gameplay discovery, remotes, movement, item actions or key verification.
local G = (getgenv and getgenv()) or _G
if G.__ZekioPremiumUI and G.__ZekioPremiumUI.Cleanup then pcall(G.__ZekioPremiumUI.Cleanup) end
local Session = { Connections = {}, PageConnections = {}, Values = {}, Controls = {}, Closed = false }
G.__ZekioPremiumUI = Session
local Players = game:GetService("Players")
local Input = game:GetService("UserInputService")
local player = Players.LocalPlayer
assert(player, "Jalankan UI dari client Roblox setelah masuk game.")
local playerGui = player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui", 15)
assert(playerGui, "PlayerGui belum tersedia.")
local UI = { Page = "overview", Group = "farming", Theme = "Gelap", Scale = 1, Width = 720, Height = 460, Styles = setmetatable({}, { __mode = "k" }) }
local function alive() return not Session.Closed and G.__ZekioPremiumUI == Session end
local V = Session.Values
local COLORS = {
    Gelap = { bg="16141E", side="111018", card="211E2B", input="191622", raised="2A2537", line="373040", text="F2EEF9", muted="B4A9C4", accent="AD89FF", soft="342548", onAccent="211331" },
    Terang = { bg="F6F4FB", side="EEE9F6", card="FFFFFF", input="F8F6FC", raised="EDE7F5", line="DCD4E8", text="282035", muted="6E627F", accent="7846CB", soft="EBE0FD", onAccent="FFFFFF" },
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
    for k,v in pairs(properties or {}) do o[k]=v end
    return o
end
local function button(parent, text, size, callback, primary, pageScope)
    local b=make("TextButton",{Text=text,Size=size,Font=Enum.Font.GothamBold,TextSize=12,BorderSizePixel=0,AutoButtonColor=true},parent)
    UI.tint(b,"BackgroundColor3",primary and "accent" or "raised")
    UI.tint(b,"TextColor3",primary and "onAccent" or "text");round(b,9)
    if callback then connect(b.MouseButton1Click,function() if alive() then callback() end end,pageScope) end
    return b
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
    overview={title="Ringkasan",subtitle="Semua kontrol Zekio Supreme dalam satu panel.",special="overview"},
    farm={title="Farm",subtitle="Place, break, dan collect di area pilihan.",action="Jalankan Farm",groups={
        group("Target farming",{s("farm.block","Block pilihan",blocks),r("collect.radius","Radius collect",2,1,4,1," tile"),t("farm.three","Area aksi 3 tile","Pilih area kerja yang dapat dijangkau.",true),t("farm.background","Break background","Lanjutkan ke lapisan belakang.")}),
        group("Collect & seed",{t("collect.enabled","Auto Collect","Ambil drop di sekitar karakter.",true),t("collect.beforeBreak","Collect sebelum break","Tunggu tile bersih sebelum produksi berikutnya.",true),t("drop.enabled","Auto Drop Seed","Gunakan tujuan dari menu Titik Drop.")})}},
    farmer={title="Farmer",subtitle="Harvest pohon ready dan tanam pada tile terjangkau.",action="Jalankan Farmer",groups={
        group("Tanaman & mode",{s("farmer.seed","Seed pilihan",seeds,"Sugar Cane Seed"),s("farmer.mode","Mode Farmer",{"Harvest saja","Harvest + tanam","Tanam saja"}),r("farmer.range","Jangkauan aksi",2,1,2,1," tile"),info("Area harvest: vertikal dan horizontal. Waktu ready mengikuti masing-masing pohon.")}),
        group("Kontrol Farmer",{t("farmer.ready","Prioritaskan pohon ready","Panen didahulukan saat tanaman sudah siap.",true),t("farmer.refill","Ambil seed saat habis","Cari seed pilihan yang tersedia di world.",true),t("collect.enabled","Auto Collect","Ambil hasil panen dalam jangkauan.",true)})}},
    pabrik={title="Pabrik",subtitle="Harvest → ambil block → break → tanam.",special="steps",action="Jalankan Pabrik",groups={
        group("Bahan produksi",{s("pabrik.seed","Seed / tanaman",seeds,"Sugar Cane Seed"),n("pabrik.take","Jumlah block diambil",30,1,200)}),
        group("Kontrol siklus",{t("pabrik.loop","Ulangi siklus","Lanjutkan setelah penanaman selesai.",true),t("collect.beforeBreak","Bersihkan drop sebelum break","Ambil hasil di tile sebelum melanjutkan.",true),t("drop.enabled","Auto Drop Seed","Kirim seed sesuai pengaturan Titik Drop."),info("Pohon ready diprioritaskan sebelum fase berikutnya.")})}},
    dirt={title="Dirt Farm",subtitle="Penggalian per baris dengan prioritas lava.",action="Jalankan Dirt Farm",groups={
        group("Penggalian",{r("dirt.delay","Jeda pukul",200,200,600,20," ms"),t("dirt.lava","Prioritas lava","Dahulukan lava dalam jangkauan.",true),t("dirt.collect","Collect saat menggali","Ambil hasil di sepanjang jalur kerja.",true),info("Rute zigzag per baris. World Lock, lock lain, dan spawn dilindungi.")})}},
    clear={title="Clear World",subtitle="Bersihkan area sambil mempertahankan lock.",action="Jalankan Clear World",groups={
        group("Lapisan world",{t("clear.foreground","Foreground","Bersihkan block bagian depan.",true),t("clear.background","Background","Bersihkan block bagian belakang."),t("clear.collect","Collect hasil break","Ambil drop sebelum melanjutkan.",true),info("World Lock, lock lain, dan area spawn dilindungi.")}),
        group("Batas area",{pair(f("clear.x","Mulai X","Otomatis"),f("clear.y","Mulai Y","Otomatis")),pair(f("clear.width","Lebar area","Seluruh area"),f("clear.height","Tinggi area","Seluruh area"))})}},
    splice={title="Splice",subtitle="Atur pasangan seed untuk proses splice.",action="Jalankan Splice",groups={
        group("Pasangan seed",{s("splice.a","Seed pertama",seeds),s("splice.b","Seed kedua",seeds,"Grass Seed"),t("splice.refill","Isi ulang seed dari world","Ambil pasangan seed yang tersedia.",true),info("Hasil splice akan ditampilkan setelah data game dihubungkan.")})}},
    door={title="Teleport ID Door",subtitle="Tujuan perpindahan melalui world dan ID door.",action="Teleport ke door",groups={group("Tujuan",{f("door.world","Nama world","NAMAWORLD"),f("door.id","ID door","Opsional")})}},
    drop={title="Titik Drop",subtitle="Tujuan penyimpanan untuk Auto Drop Seed.",action="Simpan titik drop",groups={
        group("World penyimpanan",{f("drop.world","Nama world","WORLDSEED"),f("drop.door","ID door","Opsional"),pair(f("drop.x","Tile X","Belum diatur"),f("drop.y","Tile Y","Belum diatur"))}),
        group("Jumlah seed",{pair(n("drop.amount","Jumlah dikirim",200,1,200),n("drop.keep","Sisa dibawa",50,0,200)),t("drop.enabled","Auto Drop Seed","Aktifkan tampilan pengiriman seed."),info("Pengiriman menunggu saat tujuan penuh atau belum siap.")})}},
    growscan={title="Growscan",subtitle="Ringkasan item dan pohon dalam world.",action="Pindai world",groups={group("Pemindaian",{s("scan.kind","Jenis data",{"Semua","Pohon","Seed","Block"}),info("Hasil scan akan ditampilkan di sini setelah fitur dihubungkan.")})}},
    inventory={title="Tas",subtitle="Daftar item dan jumlah inventori.",action="Refresh inventori",groups={group("Inventori",{s("bag.kind","Kategori",{"Semua","Seed","Block"}),info("Daftar item belum dihubungkan. Pratinjau ini tidak membaca inventori game.")})}},
    vending={title="Vending",subtitle="Cari item dan lihat informasi vending.",action="Cari vending",groups={group("Cari item",{f("vending.item","Nama item","Contoh: Sugar Cane"),n("vending.amount","Jumlah item",1,1,200),info("Daftar vending akan muncul setelah fitur dihubungkan.")})}},
    chat={title="Auto Chat",subtitle="Susun pesan dan atur interval pengulangan.",action="Pratinjau pesan",groups={group("Pesan otomatis",{f("chat.message","Isi pesan","Tulis pesan…"),n("chat.interval","Interval pesan (detik)",60,1,3600),t("chat.enabled","Auto Chat","Tombol ini hanya mengubah tampilan UI.")})}},
    bonus={title="Bonus",subtitle="Tampilan pengambilan bonus dan kode redeem.",action="Coba kode bonus",groups={group("Kode bonus",{f("bonus.code","Kode redeem","MASUKKAN KODE"),t("bonus.auto","Auto Bonus","Atur preferensi bonus dalam pratinjau.")})}},
    security={title="Keamanan",subtitle="Preferensi perlindungan sesi.",groups={group("Perlindungan",{info("World Lock, lock lain, dan spawn dilindungi."),t("security.worldChange","Stop saat world berubah","Hentikan rutinitas dari world sebelumnya.",true),t("security.error","Jeda saat aksi gagal","Tampilkan alasan sebelum melanjutkan.",true),t("security.storage","Jeda saat kirim seed","Lanjutkan setelah kembali ke world kerja.",true)})}},
    settings={title="Setelan",subtitle="Sesuaikan tampilan Zekio Supreme Premium.",special="settings",groups={group("Tampilan",{s("ui.theme","Tema",{"Gelap","Terang"}),r("ui.scale","Ukuran UI",85,70,100,5,"%"),t("ui.notifications","Notifikasi UI","Tampilkan pesan dari tombol pratinjau.",true),info("Preferensi di pratinjau ini hanya tersimpan selama UI terbuka.")})}},
    stats={title="Statistik",subtitle="Ringkasan aktivitas setelah fitur dihubungkan.",special="stats"},
    key={title="Akun & Key",subtitle="Panel akses Zekio Supreme Premium.",special="key",action="Verifikasi key",groups={group("License key",{f("key.value","Key premium","Masukkan key premium"),info("Validasi key belum dihubungkan. Tidak ada key yang dikirim atau diverifikasi.")})}},
    updates={title="Update",subtitle="Zekio Supreme Premium • UI Build P2.",groups={group("12 November 2026",{info("19 menu dengan tema hitam–ungu dan pilihan tema terang."),info("Tombol, dropdown, slider, dan kolom input dapat dicoba."),info("Panel mendukung HP, dapat digeser dan dikecilkan."),info("Build ini hanya UI. Seluruh aksi game belum dihubungkan.")})}},
}
local GROUPS={
    {id="farming",title="Farming",mark="F",pages={"farm","farmer","pabrik","splice","dirt","clear"}},
    {id="world",title="World",mark="W",pages={"door","drop","growscan"}},
    {id="items",title="Item",mark="I",pages={"inventory","vending"}},
    {id="tools",title="Utilitas",mark="U",pages={"chat","bonus","security"}},
    {id="system",title="Sistem",mark="S",pages={"settings","stats","key","updates"}},
}
Session.Pages=PAGES
Session.Build="PREMIUM UI P2"
Session.MenuCount=0
for _ in pairs(PAGES) do Session.MenuCount=Session.MenuCount+1 end

-- Native UI only. Nothing below imports or controls gameplay.
local gui=make("ScreenGui",{Name="ZekioSupremePremiumUI",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=1600,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
local parent=playerGui
if type(gethui)=="function" then local ok,result=pcall(gethui);if ok and result then parent=result end end
local parentOK=pcall(function() gui.Parent=parent end);if not parentOK then gui.Parent=playerGui end
Session.Gui=gui
local root=frame(gui,UDim2.fromScale(1,1),nil,{Name="Viewport"})
local host=frame(root,UDim2.fromOffset(720,460),nil,{Name="WindowHost",Position=UDim2.fromOffset(20,20)})
local window=frame(host,UDim2.fromOffset(720,460),"bg",{Name="PremiumWindow",Active=true,Position=UDim2.fromOffset(0,0)})
local windowScale=make("UIScale",{Name="ResponsiveScale",Scale=1},window)
round(window,16);outline(window)
local header=frame(window,UDim2.new(1,0,0,68),nil)
local headerLine=frame(header,UDim2.new(1,0,0,1),"line",{Position=UDim2.new(0,0,1,-1)})
local logo=frame(header,UDim2.fromOffset(38,38),"soft",{Position=UDim2.fromOffset(15,15)})
round(logo,11)
label(logo,"Z",25,"accent",{Font=Enum.Font.GothamBold,Position=UDim2.fromOffset(5,-1),Size=UDim2.fromOffset(28,36)})
label(logo,"S",25,"accent",{Font=Enum.Font.GothamBold,Position=UDim2.fromOffset(14,5),Size=UDim2.fromOffset(27,36)})
local title=label(header,"Zekio Supreme",17,"text",{Font=Enum.Font.GothamBold,Position=UDim2.fromOffset(65,13),Size=UDim2.new(1,-170,0,23)})
local edition=label(header,"PREMIUM  •  UI PREVIEW",11,"accent",{Position=UDim2.fromOffset(65,38),Size=UDim2.new(1,-170,0,16)})
local dragArea=make("TextButton",{Name="WindowDragHandle",Text="",BackgroundTransparency=1,AutoButtonColor=false,Position=UDim2.fromOffset(54,0),Size=UDim2.new(1,-144,1,0)},header)
local menuButton=button(header,"≡",UDim2.fromOffset(36,40),function() UI.drawer(not UI.Drawer) end,false)
menuButton.Position=UDim2.fromOffset(8,14);menuButton.Visible=false
local minimize=button(header,"−",UDim2.fromOffset(34,36),function() UI.closePopup();window.Visible=false;UI.Bubble.Visible=true end,false)
minimize.Position=UDim2.new(1,-84,0,16)
local close=button(header,"×",UDim2.fromOffset(34,36),function() Session.Cleanup() end,false)
close.Position=UDim2.new(1,-44,0,16)
local body=frame(window,UDim2.new(1,0,1,-98),nil,{Position=UDim2.fromOffset(0,68)})
local side=make("ScrollingFrame",{Name="Navigation",BackgroundTransparency=0,BorderSizePixel=0,Size=UDim2.new(0,170,1,0),ScrollBarThickness=4,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.None,ScrollingDirection=Enum.ScrollingDirection.Y,ClipsDescendants=true},body)
UI.tint(side,"BackgroundColor3","side");UI.tint(side,"ScrollBarImageColor3","accent")
local nav=frame(side,UDim2.fromOffset(146,0),nil,{Position=UDim2.fromOffset(10,10)})
local navLayout=stack(nav,4)
local sideLine=frame(body,UDim2.new(0,1,1,0),"line",{Position=UDim2.fromOffset(170,0)})
local content=make("ScrollingFrame",{Name="PageContent",BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(171,0),Size=UDim2.new(1,-171,1,0),ScrollBarThickness=4,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.None,ScrollingDirection=Enum.ScrollingDirection.Y,ClipsDescendants=true},body)
UI.tint(content,"ScrollBarImageColor3","accent")
local footer=frame(window,UDim2.new(1,0,0,30),"side",{Position=UDim2.new(0,0,1,-30)})
local footerText=label(footer,"Mode pratinjau • aksi game belum dihubungkan",11,"muted",{Position=UDim2.fromOffset(13,0),Size=UDim2.new(1,-55,1,0)})
label(footer,"P2",11,"accent",{Position=UDim2.new(1,-38,0,0),Size=UDim2.fromOffset(25,30),TextXAlignment=Enum.TextXAlignment.Right})
local shade=button(body,"",UDim2.fromScale(1,1),function() UI.drawer(false) end,false)
shade.BackgroundTransparency=.35;shade.ZIndex=29;shade.Visible=false
local bubble=button(root,"ZS",UDim2.fromOffset(54,54),function() window.Visible=true;UI.Bubble.Visible=false end,true)
UI.Bubble=bubble;bubble.Name="PremiumOpenButton";bubble.Position=UDim2.fromOffset(16,100);bubble.Visible=false;round(bubble,16)
local toast=frame(window,UDim2.new(1,-28,0,63),"raised",{Position=UDim2.new(0,14,1,-106),ZIndex=100,Visible=false})
round(toast,10);outline(toast)
label(toast,"Pratinjau UI",11,"accent",{Position=UDim2.fromOffset(12,8),Size=UDim2.new(1,-50,0,16),ZIndex=101,Font=Enum.Font.GothamBold})
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
function UI.preview(action) UI.notify(action..": tampilan saja, aksi game belum dihubungkan.") end
function UI.drawer(open)
    UI.Drawer=UI.Compact and open or false
    side.Visible=not UI.Compact or UI.Drawer
    side.ZIndex=UI.Compact and 40 or 1
    shade.Visible=UI.Drawer
end
local function disconnectPage()
    for _,c in ipairs(Session.PageConnections) do c:Disconnect() end
    Session.PageConnections={};Session.Controls={};Session.ActiveSlider=nil
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
    round(popup,10);outline(popup)
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
    local cardFrame=frame(parent,UDim2.new(1,0,0,50),"card",{Name="ContentCard"})
    round(cardFrame,12);outline(cardFrame)
    local inner=frame(cardFrame,UDim2.new(1,-28,0,22),nil,{Name="CardContent",Position=UDim2.fromOffset(14,14)})
    local layout=stack(inner,12)
    label(inner,titleText,13,"text",{Size=UDim2.new(1,0,0,22),Font=Enum.Font.GothamBold})
    UI.fitStack(inner,layout,12,function(height)
        if inner.Size.Y.Offset~=height then inner.Size=UDim2.new(1,-28,0,height) end
        if cardFrame.Size.Y.Offset~=height+28 then cardFrame.Size=UDim2.new(1,0,0,height+28) end
    end,true)
    return inner
end
local function displayRow(parent,left,right)
    local row=frame(parent,UDim2.new(1,0,0,40),nil)
    label(row,left,12,"muted",{Size=UDim2.new(.45,-6,1,0),TextWrapped=true})
    label(row,right,12,"text",{Position=UDim2.new(.45,6,0,0),Size=UDim2.new(.55,-6,1,0),TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Right})
end
local function field(parent,row,width)
    local wrapper=frame(parent,UDim2.new(width or 1,width and -6 or 0,0,68),nil)
    label(wrapper,row.title,11,"muted",{Size=UDim2.new(1,0,0,19)})
    local current=value(row.key,row.default)
    if row.kind=="select" then
        local b=button(wrapper,tostring(current).."  ▾",UDim2.new(1,0,0,42),nil,false,true)
        b.Position=UDim2.fromOffset(0,24);b.TextXAlignment=Enum.TextXAlignment.Left;padding(b,11)
        Session.Controls[row.key]=b
        connect(b.MouseButton1Click,function()
            UI.dropdown(b,row.choices,V[row.key],function(selected)
                V[row.key]=selected;b.Text=selected.."  ▾"
                if row.key=="ui.theme" then UI.theme(selected) end
            end)
        end,true)
    else
        local box=make("TextBox",{Text=tostring(current),PlaceholderText=row.placeholder or "",ClearTextOnFocus=false,Font=Enum.Font.Gotham,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,BorderSizePixel=0,Size=UDim2.new(1,0,0,42),Position=UDim2.fromOffset(0,24)},wrapper)
        UI.tint(box,"BackgroundColor3","input");UI.tint(box,"TextColor3","text");UI.tint(box,"PlaceholderColor3","muted");round(box,8);outline(box);padding(box,10)
        Session.Controls[row.key]=box
        if not row.number then connect(box:GetPropertyChangedSignal("Text"),function() V[row.key]=box.Text end,true) end
        connect(box.FocusLost,function()
            if row.number then
                local parsed=tonumber(box.Text)
                if parsed then V[row.key]=math.clamp(math.floor(parsed),row.min or -math.huge,row.max or math.huge) end
                box.Text=tostring(V[row.key])
            else V[row.key]=box.Text end
        end,true)
    end
    return wrapper
end
function UI.row(parent,row)
    if row.kind=="info" then
        local wrap=frame(parent,UDim2.new(1,0,0,40),"raised");round(wrap,8)
        local text=label(wrap,row.title,11,"muted",{Position=UDim2.fromOffset(10,10),Size=UDim2.new(1,-20,0,0),AutomaticSize=Enum.AutomaticSize.Y,TextWrapped=true})
        local function fitText()
            if not alive() or not wrap.Parent then return end
            local height=math.max(40,math.ceil(text.AbsoluteSize.Y/math.max(.01,UI.Scale))+20)
            if wrap.Size.Y.Offset~=height then wrap.Size=UDim2.new(1,0,0,height) end
        end
        connect(text:GetPropertyChangedSignal("AbsoluteSize"),fitText,true)
        connect(windowScale:GetPropertyChangedSignal("Scale"),fitText,true)
        fitText()
    elseif row.kind=="pair" then
        local wrap=frame(parent,UDim2.new(1,0,0,68),nil)
        field(wrap,row.items[1],.5)
        field(wrap,row.items[2],.5).Position=UDim2.new(.5,6,0,0)
    elseif row.kind=="input" or row.kind=="select" then field(parent,row)
    elseif row.kind=="toggle" then
        local current=value(row.key,row.default)
        local wrap=frame(parent,UDim2.new(1,0,0,78),nil)
        label(wrap,row.title,12,"text",{Font=Enum.Font.GothamBold,Size=UDim2.new(1,-60,0,30),TextWrapped=true})
        label(wrap,row.description or "",11,"muted",{Position=UDim2.fromOffset(0,34),Size=UDim2.new(1,-60,0,40),TextWrapped=true,TextYAlignment=Enum.TextYAlignment.Top})
        local hit=make("TextButton",{Text="",BackgroundTransparency=1,AutoButtonColor=false,Size=UDim2.fromScale(1,1)},wrap)
        local switch=frame(wrap,UDim2.fromOffset(38,22),current and "accent" or "line",{Position=UDim2.new(1,-42,0,20)});round(switch,20)
        local knob=frame(switch,UDim2.fromOffset(16,16),current and "onAccent" or "card",{Position=UDim2.fromOffset(current and 19 or 3,3)});round(knob,12)
        hit.ZIndex=4;switch.ZIndex=3;knob.ZIndex=3
        Session.Controls[row.key]=hit
        connect(hit.MouseButton1Click,function()
            V[row.key]=not V[row.key]
            UI.tint(switch,"BackgroundColor3",V[row.key] and "accent" or "line")
            UI.tint(knob,"BackgroundColor3",V[row.key] and "onAccent" or "card")
            knob.Position=UDim2.fromOffset(V[row.key] and 19 or 3,3)
        end,true)
    elseif row.kind=="slider" then
        local current=value(row.key,row.default)
        local wrap=frame(parent,UDim2.new(1,0,0,65),nil)
        label(wrap,row.title,12,"text",{Size=UDim2.new(1,-90,0,22)})
        local number=label(wrap,tostring(current)..row.unit,11,"accent",{Position=UDim2.new(1,-90,0,0),Size=UDim2.fromOffset(90,22),TextXAlignment=Enum.TextXAlignment.Right})
        local track=frame(wrap,UDim2.new(1,0,0,5),"line",{Position=UDim2.fromOffset(0,42)});round(track,4)
        local fill=frame(track,UDim2.new((current-row.min)/(row.max-row.min),0,1,0),"accent");round(fill,4)
        local knob=frame(track,UDim2.fromOffset(17,17),"accent",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new((current-row.min)/(row.max-row.min),0,.5,0)});round(knob,10)
        local hit=make("TextButton",{Text="",BackgroundTransparency=1,AutoButtonColor=false,Position=UDim2.fromOffset(0,23),Size=UDim2.new(1,0,0,42)},wrap)
        hit.ZIndex=4
        local function update(x)
            local ratio=math.clamp((x-track.AbsolutePosition.X)/math.max(1,track.AbsoluteSize.X),0,1)
            local raw=row.min+ratio*(row.max-row.min)
            local newValue=math.clamp(row.min+math.floor((raw-row.min)/row.step+.5)*row.step,row.min,row.max)
            V[row.key]=newValue;number.Text=tostring(newValue)..row.unit
            local p=(newValue-row.min)/(row.max-row.min)
            fill.Size=UDim2.new(p,0,1,0);knob.Position=UDim2.new(p,0,.5,0)
            if row.key=="ui.scale" then UI.layout() end
        end
        Session.Controls[row.key]=hit
        connect(hit.InputBegan,function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
                Session.Drag=nil;Session.ActiveSlider={input=input,update=update};update(input.Position.X)
            end
        end,true)
    end
end

local pageRoot
function UI.navigation()
    for _,child in ipairs(nav:GetChildren()) do if not child:IsA("UIListLayout") then child:Destroy() end end
    for _,c in ipairs(UI.NavConnections or {}) do c:Disconnect() end
    UI.NavConnections={}
    local function navButton(text,id,groupId)
        local b=button(nav,text,UDim2.new(1,0,0,37),nil,UI.Page==id,false)
        b.TextXAlignment=Enum.TextXAlignment.Left;padding(b,10)
        UI.NavConnections[#UI.NavConnections+1]=b.MouseButton1Click:Connect(function() if alive() then UI.show(id,groupId) end end)
    end
    navButton("Ringkasan","overview")
    for _,g in ipairs(GROUPS) do
        local section=g
        local expanded=UI.Group==g.id
        local b=button(nav,g.title.."   "..(expanded and "−" or "+"),UDim2.new(1,0,0,39),nil,false,false)
        b.TextXAlignment=Enum.TextXAlignment.Left;padding(b,10)
        UI.NavConnections[#UI.NavConnections+1]=b.MouseButton1Click:Connect(function()
            if not alive() then return end
            UI.Group=UI.Group==section.id and nil or section.id;UI.navigation()
        end)
        if expanded then for _,id in ipairs(g.pages) do navButton("  "..PAGES[id].title,id,g.id) end end
    end
    label(nav,"UI ONLY  •  P2",11,"muted",{Size=UDim2.new(1,0,0,34)})
end
local function special(parent,name)
    if name=="overview" then
        local c=card(parent,"Status sesi");displayRow(c,"Akses","Premium UI preview");displayRow(c,"Koneksi fitur","Belum dihubungkan");displayRow(c,"World","—")
        local shortcuts=card(parent,"Akses cepat")
        for _,id in ipairs({"farmer","pabrik","dirt","clear"}) do
            local target=id
            button(shortcuts,PAGES[id].title,UDim2.new(1,0,0,42),function() UI.show(target,"farming") end,false,true)
        end
    elseif name=="stats" then
        local c=card(parent,"Aktivitas sesi")
        for _,nameText in ipairs({"Panen","Tanam","Place","Break","Collect","Durasi sesi"}) do displayRow(c,nameText,"—") end
        caption(parent,"Statistik belum dihubungkan ke aktivitas game.",35)
    elseif name=="steps" then
        local c=card(parent,"Urutan kerja")
        for index,text in ipairs({"Harvest pohon ready","Ambil block","Break block","Tanam seed"}) do displayRow(c,tostring(index).."  "..text,"—") end
    elseif name=="key" then
        local c=card(parent,"Zekio Supreme Premium");displayRow(c,"Status key","Belum diverifikasi");displayRow(c,"Masa berlaku","—");displayRow(c,"Akun","—")
    elseif name=="settings" then
        local c=card(parent,"Konfigurasi")
        button(c,"Simpan konfigurasi",UDim2.new(1,0,0,42),function() UI.preview("Simpan konfigurasi") end,false,true)
        button(c,"Muat konfigurasi",UDim2.new(1,0,0,42),function() UI.preview("Muat konfigurasi") end,false,true)
    end
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
    label(heading,page.title,21,"text",{Size=UDim2.new(1,0,0,28),Font=Enum.Font.GothamBold})
    label(heading,page.subtitle,12,"muted",{Position=UDim2.fromOffset(0,35),Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,TextWrapped=true,TextYAlignment=Enum.TextYAlignment.Top})
    if page.special and page.special~="settings" then special(pageRoot,page.special) end
    for _,section in ipairs(page.groups or {}) do
        local c=card(pageRoot,section.title)
        for _,row in ipairs(section.rows) do UI.row(c,row) end
    end
    if page.special=="settings" then special(pageRoot,page.special) end
    if page.action then
        button(pageRoot,page.action,UDim2.new(1,0,0,44),function() UI.preview(page.title) end,true,true)
    end
    local bottom=caption(pageRoot,"Mode pratinjau • tombol fitur belum menjalankan aksi game.",34)
    bottom.LayoutOrder=10000
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
    local w=portrait and math.min(380,math.max(260,vw-32)) or (UI.Compact and 600 or 720)
    local h=portrait and 500 or (UI.Compact and 400 or 460)
    local fit=math.min(1,math.max(1,vw-32)/w,math.max(1,vh-32)/h)
    local zoom=math.clamp(tonumber(value("ui.scale",85)) or 85,70,100)/100
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
    edition.Text=UI.Compact and "PREMIUM • UI" or "PREMIUM  •  UI PREVIEW"
    dragArea.Position=UDim2.fromOffset(54,0);dragArea.Size=UDim2.new(1,-148,1,0)
    footerText.Text=UI.Compact and "UI preview • tanpa aksi game" or "Mode pratinjau • aksi game belum dihubungkan"
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
    Session.Closed=true;Session.ActiveSlider=nil;Session.Drag=nil
    for _,c in ipairs(Session.PageConnections) do pcall(function() c:Disconnect() end) end
    for _,c in ipairs(UI.NavConnections or {}) do pcall(function() c:Disconnect() end) end
    for _,c in ipairs(Session.Connections) do pcall(function() c:Disconnect() end) end
    gui:Destroy()
    if G.__ZekioPremiumUI==Session then G.__ZekioPremiumUI=nil end
end
UI.layout();UI.show("overview")

