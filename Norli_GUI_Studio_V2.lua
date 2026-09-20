--[[
    NORLI GUI STUDIO
    V2 - Mobile GUI Builder

    Foco desta versão:
    • Interface mobile-first e modular, com painéis que não se sobrepõem
    • Biblioteca de elementos com símbolo + nome curto
    • Paleta visual de cores (sem digitar RGB/HEX)
    • Dropdown real com todas as opções disponíveis em Enum.Font
    • Hierarquia simples via seleção + criação de filhos
    • Movimento, redimensionamento, rotação e ZIndex
    • Modificadores GUI: UICorner, UIStroke, UIGradient, UIPadding,
      UIListLayout, UIGridLayout, UIPageLayout, UIAspectRatioConstraint,
      UISizeConstraint e UIScale
    • Assets: galeria/pesquisa opcional por palavra-chave usando requests do executor
    • Exportação da árvore visual completa para Lua
    • Limpeza de CoreGui no início + restauração ao fechar/reexecutar
    • Limpeza LOCAL de Tools da mochila/personagem para deixar a tela limpa

    Observação importante sobre Assets:
    Não existe uma forma segura de obter "todos os IDs possíveis do Roblox"
    de uma vez. A V2 usa pesquisa de catálogo quando o executor disponibiliza
    uma função HTTP; resultados podem depender da API/rede/permissões.
]]

--// Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
if not player then return end
local playerGui = player:WaitForChild("PlayerGui")

--// Rerun-safe cleanup
local oldGui = playerGui:FindFirstChild("NORLI_GUI_STUDIO")
if oldGui then
    pcall(function() oldGui:Destroy() end)
end

--// Safe helpers
local function pcallv(fn, ...)
    local ok, a, b, c = pcall(fn, ...)
    if ok then return a, b, c end
end

local function safeGet(obj, prop)
    local ok, value = pcall(function() return obj[prop] end)
    return ok and value or nil
end

local function safeSet(obj, prop, value)
    return pcall(function() obj[prop] = value end)
end

local function clamp(n, a, b)
    return math.max(a, math.min(b, n))
end

local function round(n)
    return math.floor(n + 0.5)
end

local function colorToHex(c)
    c = c or Color3.new(1, 1, 1)
    return string.format("#%02X%02X%02X", round(c.R * 255), round(c.G * 255), round(c.B * 255))
end

local function safeClipboard(text)
    local names = {"setclipboard", "toclipboard", "set_clipboard"}
    for _, name in ipairs(names) do
        local fn = rawget(_G, name)
        if type(fn) == "function" then
            local ok = pcall(fn, text)
            if ok then return true end
        end
    end
    return false
end

local function make(className, props, parent)
    local obj = Instance.new(className)
    for k, v in pairs(props or {}) do
        safeSet(obj, k, v)
    end
    obj.Parent = parent
    return obj
end

local function tween(obj, props, duration)
    local ok, info = pcall(function()
        return TweenInfo.new(duration or 0.13, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    end)
    if not ok then return end
    local ok2, tw = pcall(function()
        return TweenService:Create(obj, info, props)
    end)
    if ok2 and tw then tw:Play() end
end

local function corner(obj, radius)
    local c = obj:FindFirstChild("NORLI_Corner")
    if not c then
        c = Instance.new("UICorner")
        c.Name = "NORLI_Corner"
        c.Parent = obj
    end
    c.CornerRadius = UDim.new(0, radius or 10)
    return c
end

local function getStroke(obj)
    return obj:FindFirstChild("NORLI_Stroke") or obj:FindFirstChildOfClass("UIStroke")
end

local function ensureStroke(obj)
    local s = getStroke(obj)
    if not s then
        s = Instance.new("UIStroke")
        s.Name = "NORLI_Stroke"
        s.Parent = obj
    end
    return s
end

local function clearStroke(obj)
    local s = getStroke(obj)
    if s and s.Name ~= "NORLI_Selection" then
        s:Destroy()
    end
end

--// Roblox UI cleanup - reversible
local coreGuiTypes = {
    Enum.CoreGuiType.Backpack,
    Enum.CoreGuiType.PlayerList,
    Enum.CoreGuiType.Health,
    Enum.CoreGuiType.Chat,
    Enum.CoreGuiType.EmotesMenu,
    Enum.CoreGuiType.Captures,
    Enum.CoreGuiType.SelfView,
}

local previousCoreGui = {}
for _, typeValue in ipairs(coreGuiTypes) do
    local ok, value = pcall(function()
        return StarterGui:GetCoreGuiEnabled(typeValue)
    end)
    if ok then previousCoreGui[typeValue] = value end
    pcall(function() StarterGui:SetCoreGuiEnabled(typeValue, false) end)
end

local function restoreCoreGui()
    for typeValue, wasEnabled in pairs(previousCoreGui) do
        pcall(function() StarterGui:SetCoreGuiEnabled(typeValue, wasEnabled) end)
    end
end

--// Local inventory cleanup requested by user.
--// This is intentionally local: it does not attempt to modify server data.
local function cleanLocalTools()
    local backpack = player:FindFirstChildOfClass("Backpack")
    if backpack then
        for _, obj in ipairs(backpack:GetChildren()) do
            if obj:IsA("Tool") then pcall(function() obj:Destroy() end) end
        end
    end
    local character = player.Character
    if character then
        for _, obj in ipairs(character:GetChildren()) do
            if obj:IsA("Tool") then pcall(function() obj:Destroy() end) end
        end
    end
end
cleanLocalTools()

--// Theme
local C = {
    bg = Color3.fromRGB(9, 11, 15),
    surface = Color3.fromRGB(17, 20, 27),
    surface2 = Color3.fromRGB(23, 27, 36),
    card = Color3.fromRGB(29, 34, 44),
    card2 = Color3.fromRGB(35, 41, 53),
    accent = Color3.fromRGB(97, 140, 255),
    accent2 = Color3.fromRGB(73, 110, 225),
    green = Color3.fromRGB(80, 211, 127),
    red = Color3.fromRGB(239, 84, 99),
    text = Color3.fromRGB(245, 247, 251),
    muted = Color3.fromRGB(157, 166, 183),
    line = Color3.fromRGB(55, 62, 77),
    canvas = Color3.fromRGB(13, 16, 22),
}

local Palette = {
    Color3.fromRGB(255,255,255), Color3.fromRGB(240,240,240), Color3.fromRGB(210,214,220), Color3.fromRGB(165,170,180),
    Color3.fromRGB(95,100,110), Color3.fromRGB(35,38,44), Color3.fromRGB(0,0,0), Color3.fromRGB(230,72,72),
    Color3.fromRGB(255,109,109), Color3.fromRGB(255,164,79), Color3.fromRGB(255,211,87), Color3.fromRGB(168,224,84),
    Color3.fromRGB(81,204,117), Color3.fromRGB(71,214,170), Color3.fromRGB(70,194,230), Color3.fromRGB(84,153,239),
    Color3.fromRGB(104,121,255), Color3.fromRGB(151,104,255), Color3.fromRGB(213,91,235), Color3.fromRGB(247,96,167),
    Color3.fromRGB(133,88,64), Color3.fromRGB(170,114,78), Color3.fromRGB(198,149,112), Color3.fromRGB(234,190,153),
    Color3.fromRGB(255,238,201), Color3.fromRGB(198,90,72), Color3.fromRGB(156,58,58), Color3.fromRGB(102,65,165),
    Color3.fromRGB(71,76,160), Color3.fromRGB(60,117,178), Color3.fromRGB(52,143,149), Color3.fromRGB(58,157,97),
    Color3.fromRGB(113,177,69), Color3.fromRGB(170,190,62), Color3.fromRGB(206,195,57), Color3.fromRGB(242,214,64),
    Color3.fromRGB(255,151,51), Color3.fromRGB(214,104,46), Color3.fromRGB(191,71,106), Color3.fromRGB(119,73,107),
    Color3.fromRGB(91,74,116), Color3.fromRGB(71,87,113), Color3.fromRGB(74,103,132), Color3.fromRGB(80,130,122),
    Color3.fromRGB(87,145,91), Color3.fromRGB(132,150,77), Color3.fromRGB(174,162,72), Color3.fromRGB(198,133,64),
}

--// Root
local Gui = make("ScreenGui", {
    Name = "NORLI_GUI_STUDIO",
    IgnoreGuiInset = true,
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 100000,
}, playerGui)

Gui.Destroying:Connect(restoreCoreGui)

local Root = make("Frame", {
    Size = UDim2.fromScale(1,1),
    BackgroundColor3 = C.bg,
    BorderSizePixel = 0,
}, Gui)

--// Header
local Header = make("Frame", {
    Size = UDim2.new(1,0,0,56),
    BackgroundColor3 = C.surface,
    BorderSizePixel = 0,
    ZIndex = 10,
}, Root)
local HeaderStroke = ensureStroke(Header)
HeaderStroke.Transparency = 0.65
HeaderStroke.Thickness = 1
HeaderStroke.Color = C.line

local Brand = make("TextLabel", {
    Size = UDim2.new(1,-210,0,25),
    Position = UDim2.new(0,14,0,7),
    BackgroundTransparency = 1,
    Text = "NORLI GUI STUDIO",
    Font = Enum.Font.GothamBold,
    TextSize = 15,
    TextColor3 = C.text,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 11,
}, Header)

local Status = make("TextLabel", {
    Size = UDim2.new(1,-210,0,17),
    Position = UDim2.new(0,14,0,32),
    BackgroundTransparency = 1,
    Text = "V2  •  MOBILE  •  READY",
    Font = Enum.Font.GothamMedium,
    TextSize = 9,
    TextColor3 = C.muted,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 11,
}, Header)

local RestoreButton = make("TextButton", {
    Size = UDim2.new(0,88,0,34),
    Position = UDim2.new(1,-186,0,11),
    BackgroundColor3 = C.card,
    BorderSizePixel = 0,
    AutoButtonColor = false,
    Text = "↺ UI ROBLOX",
    Font = Enum.Font.GothamBold,
    TextSize = 9,
    TextColor3 = C.muted,
    ZIndex = 11,
}, Header)
corner(RestoreButton, 9)
RestoreButton.Activated:Connect(function()
    restoreCoreGui()
    Status.Text = "ROBLOX UI RESTAURADA"
    Status.TextColor3 = C.green
    task.delay(1.3, function()
        if Status.Parent then
            Status.Text = "V2  •  MOBILE  •  READY"
            Status.TextColor3 = C.muted
        end
    end)
end)

local CloseButton = make("TextButton", {
    Size = UDim2.new(0,78,0,34),
    Position = UDim2.new(1,-90,0,11),
    BackgroundColor3 = C.red,
    BorderSizePixel = 0,
    AutoButtonColor = false,
    Text = "✕ FECHAR",
    Font = Enum.Font.GothamBold,
    TextSize = 9,
    TextColor3 = Color3.new(1,1,1),
    ZIndex = 11,
}, Header)
corner(CloseButton, 9)
CloseButton.Activated:Connect(function()
    Gui:Destroy()
end)

--// Canvas
local CanvasHolder = make("Frame", {
    Size = UDim2.new(1,0,1,-112),
    Position = UDim2.new(0,0,0,56),
    BackgroundColor3 = C.canvas,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Active = true,
}, Root)

local Canvas = make("Frame", {
    Size = UDim2.new(1,-24,1,-24),
    Position = UDim2.new(0,12,0,12),
    BackgroundColor3 = Color3.fromRGB(18,21,28),
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Active = true,
}, CanvasHolder)
corner(Canvas, 14)
local CanvasStroke = ensureStroke(Canvas)
CanvasStroke.Color = C.line
CanvasStroke.Transparency = 0.45

local Grid = make("Frame", {
    Size = UDim2.fromScale(1,1),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Active = false,
    ZIndex = 1,
}, Canvas)

--// Editor project root
local DesignRoot = make("Frame", {
    Name = "DesignRoot",
    Size = UDim2.new(1,-20,1,-20),
    Position = UDim2.new(0,10,0,10),
    BackgroundColor3 = Color3.fromRGB(16,18,24),
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Active = true,
    ZIndex = 3,
}, Canvas)
corner(DesignRoot, 11)

-- Subtle grid made from strokes, not image assets.
for i = 1, 7 do
    local v = make("Frame", {Size=UDim2.new(0,1,1,0), Position=UDim2.new(i/8,0,0,0), BackgroundColor3=C.line, BackgroundTransparency=0.88, BorderSizePixel=0, ZIndex=2}, Grid)
end
for i = 1, 5 do
    local h = make("Frame", {Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,i/6,0), BackgroundColor3=C.line, BackgroundTransparency=0.88, BorderSizePixel=0, ZIndex=2}, Grid)
end

local EmptyHint = make("TextLabel", {
    Size = UDim2.new(1,-40,0,64),
    Position = UDim2.new(0,20,0.5,-32),
    BackgroundTransparency = 1,
    Text = "CANVAS VAZIO\nEscolha um símbolo em ELEMENTOS para começar",
    Font = Enum.Font.GothamMedium,
    TextSize = 12,
    TextColor3 = C.muted,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Center,
    TextYAlignment = Enum.TextYAlignment.Center,
    ZIndex = 3,
}, DesignRoot)

--// State
local selected = nil
local selectionVisual = nil
local currentTab = nil
local colorTarget = "BackgroundColor3"
local panel = nil
local panelTitle = nil
local panelBody = nil
local panelBack = nil
local tabButtons = {}
local connections = {}
local openTab

local function disconnectAll(list)
    for _, c in ipairs(list) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(list)
end

local function setHintVisible()
    EmptyHint.Visible = (#DesignRoot:GetChildren() == 1) -- selection-independent, ignores hint itself below.
end

local function isSelectable(obj)
    return obj and obj:IsA("GuiObject") and obj:IsDescendantOf(DesignRoot) and obj ~= DesignRoot and obj ~= EmptyHint and not (obj.Name == "NORLI_Selection")
end

local function removeSelectionVisual()
    if selectionVisual then
        pcall(function() selectionVisual:Destroy() end)
        selectionVisual = nil
    end
end

local function showSelectionVisual()
    removeSelectionVisual()
    if not isSelectable(selected) then return end
    selectionVisual = make("Frame", {
        Name = "NORLI_Selection",
        Size = UDim2.new(1,8,1,8),
        Position = UDim2.new(0,-4,0,-4),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Active = false,
        ZIndex = math.max(1000, selected.ZIndex + 100),
    }, selected)
    local s = ensureStroke(selectionVisual)
    s.Name = "NORLI_Selection"
    s.Color = C.accent
    s.Thickness = 2
    s.Transparency = 0
end

--// Content panels
local function createDrawer(title)
    if panel then pcall(function() panel:Destroy() end) end
    panel = make("Frame", {
        Size = UDim2.new(0.92,0,0.79,0),
        Position = UDim2.new(0.04,0,0.08,0),
        BackgroundColor3 = C.surface,
        BorderSizePixel = 0,
        ZIndex = 200,
    }, Root)
    corner(panel, 15)
    local s = ensureStroke(panel)
    s.Color = C.line
    s.Transparency = 0.2
    s.Thickness = 1

    panelTitle = make("TextLabel", {
        Size = UDim2.new(1,-110,0,40),
        Position = UDim2.new(0,14,0,6),
        BackgroundTransparency = 1,
        Text = title,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = C.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 201,
    }, panel)

    panelBack = make("TextButton", {
        Size = UDim2.new(0,76,0,32),
        Position = UDim2.new(1,-90,0,10),
        BackgroundColor3 = C.card,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "← FECHAR",
        Font = Enum.Font.GothamBold,
        TextSize = 9,
        TextColor3 = C.text,
        ZIndex = 201,
    }, panel)
    corner(panelBack, 9)
    panelBack.Activated:Connect(function()
        if panel then panel:Destroy(); panel=nil; currentTab=nil end
    end)

    panelBody = make("ScrollingFrame", {
        Size = UDim2.new(1,-20,1,-58),
        Position = UDim2.new(0,10,0,50),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = C.accent,
        CanvasSize = UDim2.new(),
        ZIndex = 201,
    }, panel)
    make("UIPadding", {PaddingLeft=UDim.new(0,2), PaddingRight=UDim.new(0,2), PaddingTop=UDim.new(0,2), PaddingBottom=UDim.new(0,12)}, panelBody)
    make("UIListLayout", {Padding=UDim.new(0,7), SortOrder=Enum.SortOrder.LayoutOrder}, panelBody)
    panelBody:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(function()
        panelBody.CanvasSize = UDim2.new(0,0,0, math.max(panelBody.AbsoluteCanvasSize.Y, panelBody.AbsoluteSize.Y) + 12)
    end)
    return panelBody
end

local function section(parent, textValue)
    return make("TextLabel", {
        Size=UDim2.new(1,0,0,20),
        BackgroundTransparency=1,
        Text=textValue,
        Font=Enum.Font.GothamBold,
        TextSize=9,
        TextColor3=C.muted,
        TextXAlignment=Enum.TextXAlignment.Left,
        ZIndex=202,
    }, parent)
end

local function button(parent, textValue, callback, height)
    local b = make("TextButton", {
        Size=UDim2.new(1,0,0,height or 36),
        BackgroundColor3=C.card,
        BorderSizePixel=0,
        AutoButtonColor=false,
        Text=textValue,
        Font=Enum.Font.GothamBold,
        TextSize=10,
        TextColor3=C.text,
        ZIndex=202,
    }, parent)
    corner(b, 9)
    b.Activated:Connect(callback)
    b.MouseEnter:Connect(function() tween(b,{BackgroundColor3=C.card2},0.08) end)
    b.MouseLeave:Connect(function() tween(b,{BackgroundColor3=C.card},0.08) end)
    return b
end

local function compactRow(parent, labelText, valueText, onMinus, onPlus)
    local wrap = make("Frame", {Size=UDim2.new(1,0,0,37), BackgroundTransparency=1, ZIndex=202}, parent)
    make("TextLabel", {Size=UDim2.new(0.42,0,1,0), BackgroundTransparency=1, Text=labelText, Font=Enum.Font.GothamMedium, TextSize=9, TextColor3=C.muted, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=203}, wrap)
    local minus = button(wrap, "−", onMinus, 31)
    minus.Size = UDim2.new(0,34,0,31); minus.Position = UDim2.new(0.52,0,0,3)
    local value = make("TextLabel", {Size=UDim2.new(0,58,0,31), Position=UDim2.new(0.52,38,0,3), BackgroundColor3=C.surface2, BorderSizePixel=0, Text=valueText, Font=Enum.Font.GothamBold, TextSize=9, TextColor3=C.text, ZIndex=203}, wrap)
    corner(value, 8)
    local plus = button(wrap, "+", onPlus, 31)
    plus.Size = UDim2.new(0,34,0,31); plus.Position = UDim2.new(0.52,100,0,3)
    return value
end

local function textBox(parent, labelText, initial, callback, placeholder)
    local wrap = make("Frame", {Size=UDim2.new(1,0,0,56), BackgroundTransparency=1, ZIndex=202}, parent)
    make("TextLabel", {Size=UDim2.new(1,0,0,18), BackgroundTransparency=1, Text=labelText, Font=Enum.Font.GothamMedium, TextSize=9, TextColor3=C.muted, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=203}, wrap)
    local box = make("TextBox", {Size=UDim2.new(1,0,0,33), Position=UDim2.new(0,0,0,21), BackgroundColor3=C.card, BorderSizePixel=0, Text=tostring(initial or ""), PlaceholderText=placeholder or "", ClearTextOnFocus=false, Font=Enum.Font.GothamMedium, TextSize=10, TextColor3=C.text, PlaceholderColor3=C.muted, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=203}, wrap)
    corner(box, 9)
    box.FocusLost:Connect(function() callback(box.Text) end)
    return box
end

--// Selection
local refreshProperties = function() end

local function setSelected(obj)
    if obj and obj == EmptyHint then obj = nil end
    if obj and not isSelectable(obj) then return end
    selected = obj
    removeSelectionVisual()
    if selected then
        showSelectionVisual()
        EmptyHint.Visible = false
    else
        EmptyHint.Visible = true
    end
    refreshProperties()
end

local function connectSelectable(obj)
    if not obj:IsA("GuiObject") then return end
    obj.Active = true
    obj.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            if not panel then setSelected(obj) end
        end
    end)
end

local function selectFromHierarchy()
    if not panelBody then return end
    for _, child in ipairs(panelBody:GetChildren()) do
        if child:GetAttribute("NORLI_HIERARCHY_ITEM") then child:Destroy() end
    end
    local items = {}
    local function scan(parent, depth)
        for _, child in ipairs(parent:GetChildren()) do
            if child:IsA("GuiObject") and child ~= EmptyHint and child ~= Grid and child.Name ~= "NORLI_Selection" then
                table.insert(items, {obj=child, depth=depth})
                scan(child, depth+1)
            end
        end
    end
    scan(DesignRoot, 0)
    table.sort(items, function(a,b)
        return a.depth < b.depth
    end)
    for _, item in ipairs(items) do
        local o = item.obj
        local prefix = string.rep("  ", math.min(item.depth, 5))
        local icon = ({
            Frame="▣", TextLabel="T", TextButton="▣", TextBox="⌨",
            ImageLabel="▧", ImageButton="◈", ScrollingFrame="▤",
            ViewportFrame="◉", CanvasGroup="◫", VideoFrame="▶"
        })[o.ClassName] or "•"
        local b = button(panelBody, prefix .. icon .. "  " .. o.Name, function() setSelected(o) end, 34)
        b:SetAttribute("NORLI_HIERARCHY_ITEM", true)
        if o == selected then b.BackgroundColor3 = C.accent2 end
    end
end

--// Element library
local elements = {
    {class="Frame", icon="▣", label="Frame", desc="Painel / container"},
    {class="TextLabel", icon="T", label="Texto", desc="Texto estático"},
    {class="TextButton", icon="▣", label="Botão", desc="Botão de texto"},
    {class="TextBox", icon="⌨", label="Caixa", desc="Campo de texto"},
    {class="ImageLabel", icon="▧", label="Imagem", desc="Imagem estática"},
    {class="ImageButton", icon="◈", label="Img. Botão", desc="Botão com imagem"},
    {class="ScrollingFrame", icon="▤", label="Scroll", desc="Área rolável"},
    {class="ViewportFrame", icon="◉", label="3D", desc="Modelo / viewport"},
    {class="CanvasGroup", icon="◫", label="Grupo", desc="Grupo com aparência"},
    {class="VideoFrame", icon="▶", label="Vídeo", desc="Vídeo GUI"},
}

local defaultProps = {
    Frame = function()
        return {BackgroundColor3=Color3.fromRGB(54,60,76), Size=UDim2.fromOffset(180,100)}
    end,
    TextLabel = function()
        return {BackgroundTransparency=1, Size=UDim2.fromOffset(190,42), Text="Texto", Font=Enum.Font.GothamBold, TextSize=20, TextColor3=Color3.new(1,1,1), TextXAlignment=Enum.TextXAlignment.Center, TextYAlignment=Enum.TextYAlignment.Center}
    end,
    TextButton = function()
        return {BackgroundColor3=C.accent2, Size=UDim2.fromOffset(180,50), Text="Botão", Font=Enum.Font.GothamBold, TextSize=17, TextColor3=Color3.new(1,1,1), AutoButtonColor=false, TextXAlignment=Enum.TextXAlignment.Center, TextYAlignment=Enum.TextYAlignment.Center}
    end,
    TextBox = function()
        return {BackgroundColor3=Color3.fromRGB(42,47,60), Size=UDim2.fromOffset(190,50), Text="", PlaceholderText="Digite aqui...", ClearTextOnFocus=false, Font=Enum.Font.GothamMedium, TextSize=16, TextColor3=Color3.new(1,1,1)}
    end,
    ImageLabel = function()
        return {BackgroundColor3=Color3.fromRGB(34,39,50), Size=UDim2.fromOffset(170,120), Image=""}
    end,
    ImageButton = function()
        return {BackgroundColor3=Color3.fromRGB(34,39,50), Size=UDim2.fromOffset(170,120), Image="", AutoButtonColor=false}
    end,
    ScrollingFrame = function()
        return {BackgroundColor3=Color3.fromRGB(32,37,48), Size=UDim2.fromOffset(200,150), CanvasSize=UDim2.fromOffset(0,450), ScrollBarThickness=5, ScrollBarImageColor3=C.accent}
    end,
    ViewportFrame = function()
        return {BackgroundColor3=Color3.fromRGB(25,28,36), Size=UDim2.fromOffset(190,150)}
    end,
    CanvasGroup = function()
        return {BackgroundColor3=Color3.fromRGB(43,48,62), Size=UDim2.fromOffset(180,100), GroupTransparency=0}
    end,
    VideoFrame = function()
        return {BackgroundColor3=Color3.fromRGB(18,20,25), Size=UDim2.fromOffset(200,130), Video=""}
    end,
}

local function uniqueName(base, parent)
    local n = 1
    local name = base
    while parent:FindFirstChild(name) do
        n += 1
        name = base .. n
    end
    return name
end

local function createElement(className)
    local parent = DesignRoot
    if selected and selected:IsA("GuiObject") and selected ~= EmptyHint and selected ~= DesignRoot then
        parent = selected
    end

    local obj = Instance.new(className)
    obj.Name = uniqueName(className, parent)
    local props = defaultProps[className] and defaultProps[className]() or {}
    for k,v in pairs(props) do safeSet(obj,k,v) end
    obj.Position = UDim2.fromOffset(18,18)
    obj.ZIndex = clamp((selected and selected.ZIndex or 5) + 1, 1, 999)
    obj.Parent = parent

    if className == "Frame" or className == "TextButton" or className == "TextBox" or className == "ImageButton" or className == "ImageLabel" or className == "ScrollingFrame" or className == "ViewportFrame" or className == "CanvasGroup" then
        corner(obj, className == "TextLabel" and 6 or 10)
    end

    connectSelectable(obj)
    setSelected(obj)
    EmptyHint.Visible = false
    return obj
end

--// Properties
local function addTag(parent, value)
    return make("TextLabel", {Size=UDim2.new(1,0,0,28), BackgroundColor3=C.surface2, BorderSizePixel=0, Text=value, Font=Enum.Font.GothamBold, TextSize=9, TextColor3=C.muted, TextXAlignment=Enum.TextXAlignment.Center, ZIndex=203}, parent)
end

local function boolSwitch(parent, labelText, current, callback)
    local b = button(parent, labelText .. "  •  " .. (current and "ON" or "OFF"), function()
        current = not current
        callback(current)
        b.Text = labelText .. "  •  " .. (current and "ON" or "OFF")
    end, 36)
    return b
end

local function rebuildHierarchyShortcut()
    if not panelBody then return end
end

refreshProperties = function()
    if not currentTab or currentTab ~= "INSPECT" then return end
    if not panelBody then return end
    disconnectAll(connections)
    for _, child in ipairs(panelBody:GetChildren()) do
        if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
            child:Destroy()
        end
    end

    if not selected then
        addTag(panelBody, "SELECIONE UM ELEMENTO NO CANVAS")
        button(panelBody, "☷ ABRIR HIERARQUIA", function() selectFromHierarchy() end)
        return
    end

    addTag(panelBody, selected.ClassName .. "  •  " .. selected.Name)
    section(panelBody, "GERAL")
    textBox(panelBody, "NOME", selected.Name, function(v)
        local cleaned = tostring(v):gsub("[^%w_]", "_")
        if cleaned == "" then cleaned = "Element" end
        selected.Name = cleaned
        showSelectionVisual()
    end)
    compactRow(panelBody, "ROTAÇÃO", tostring(round(selected.Rotation)), function() selected.Rotation = selected.Rotation - 5; refreshProperties() end, function() selected.Rotation = selected.Rotation + 5; refreshProperties() end)
    compactRow(panelBody, "ZINDEX", tostring(selected.ZIndex), function() selected.ZIndex = clamp(selected.ZIndex-1,0,999) end, function() selected.ZIndex = clamp(selected.ZIndex+1,0,999) end)

    section(panelBody, "POSIÇÃO / TAMANHO")
    compactRow(panelBody, "X", tostring(round(selected.Position.X.Offset)), function() selected.Position = UDim2.new(selected.Position.X.Scale, selected.Position.X.Offset-5, selected.Position.Y.Scale, selected.Position.Y.Offset) end, function() selected.Position = UDim2.new(selected.Position.X.Scale, selected.Position.X.Offset+5, selected.Position.Y.Scale, selected.Position.Y.Offset) end)
    compactRow(panelBody, "Y", tostring(round(selected.Position.Y.Offset)), function() selected.Position = UDim2.new(selected.Position.X.Scale, selected.Position.X.Offset, selected.Position.Y.Scale, selected.Position.Y.Offset-5) end, function() selected.Position = UDim2.new(selected.Position.X.Scale, selected.Position.X.Offset, selected.Position.Y.Scale, selected.Position.Y.Offset+5) end)
    compactRow(panelBody, "LARGURA", tostring(round(selected.Size.X.Offset)), function() selected.Size = UDim2.new(selected.Size.X.Scale, clamp(selected.Size.X.Offset-5,5,2000), selected.Size.Y.Scale, selected.Size.Y.Offset); showSelectionVisual() end, function() selected.Size = UDim2.new(selected.Size.X.Scale, clamp(selected.Size.X.Offset+5,5,2000), selected.Size.Y.Scale, selected.Size.Y.Offset); showSelectionVisual() end)
    compactRow(panelBody, "ALTURA", tostring(round(selected.Size.Y.Offset)), function() selected.Size = UDim2.new(selected.Size.X.Scale, selected.Size.X.Offset, selected.Size.Y.Scale, clamp(selected.Size.Y.Offset-5,5,2000)); showSelectionVisual() end, function() selected.Size = UDim2.new(selected.Size.X.Scale, selected.Size.X.Offset, selected.Size.Y.Scale, clamp(selected.Size.Y.Offset+5,5,2000)); showSelectionVisual() end)

    section(panelBody, "AÇÕES")
    button(panelBody, "↗  CRIAR FILHO AQUI", function()
        openTab("ELEMENTS")
    end)
    button(panelBody, "▣  DUPLICAR", function()
        local clone = selected:Clone()
        clone.Name = uniqueName(selected.Name, selected.Parent)
        clone.Position = selected.Position + UDim2.fromOffset(18,18)
        clone.Parent = selected.Parent
        for _,d in ipairs(clone:GetDescendants()) do if d:IsA("GuiObject") then connectSelectable(d) end end
        connectSelectable(clone)
        setSelected(clone)
        refreshProperties()
    end)
    button(panelBody, "✕  APAGAR", function()
        local old = selected
        setSelected(nil)
        if old and old.Parent then old:Destroy() end
        refreshProperties()
    end)
    button(panelBody, "☷  HIERARQUIA", function() selectFromHierarchy() end)

    section(panelBody, "VISIBILIDADE")
    boolSwitch(panelBody, "VISÍVEL", selected.Visible, function(v) selected.Visible = v end)
    boolSwitch(panelBody, "CLIPS DESCENDENTES", selected.ClipsDescendants, function(v) selected.ClipsDescendants = v end)
    boolSwitch(panelBody, "ATIVO", selected.Active, function(v) selected.Active = v end)

    if selected:IsA("GuiButton") then
        section(panelBody, "BOTÃO")
        boolSwitch(panelBody, "INTERACTABLE", safeGet(selected,"Interactable") == true, function(v) safeSet(selected,"Interactable",v) end)
    end
end

--// Style panel
local function openStyle()
    local body = createDrawer("ESTILO  •  CORES / FONTES / EFEITOS")
    section(body,"COR ATIVA")
    addTag(body,"Escolha o alvo e depois toque em uma cor")
    local targetRow = make("Frame", {Size=UDim2.new(1,0,0,39), BackgroundTransparency=1, ZIndex=202}, body)
    local targets = {
        {key="BackgroundColor3", label="FUNDO"},
        {key="TextColor3", label="TEXTO"},
        {key="Stroke", label="BORDA"},
        {key="ImageColor3", label="IMAGEM"},
    }
    for i,t in ipairs(targets) do
        local b = button(targetRow, t.label, function() colorTarget=t.key end, 34)
        b.Size = UDim2.new(0.25,-3,0,34)
        b.Position = UDim2.new((i-1)*0.25,0,0,0)
    end

    section(body,"PALETA")
    local gridFrame = make("Frame", {Size=UDim2.new(1,0,0,268), BackgroundTransparency=1, ZIndex=202}, body)
    local gridLayout = make("UIGridLayout", {CellSize=UDim2.new(0,29,0,29), CellPadding=UDim2.new(0,5,0,5), FillDirectionMaxCells=7, HorizontalAlignment=Enum.HorizontalAlignment.Center, SortOrder=Enum.SortOrder.LayoutOrder}, gridFrame)
    for _, col in ipairs(Palette) do
        local sw = make("TextButton", {Size=UDim2.fromOffset(29,29), BackgroundColor3=col, BorderSizePixel=0, Text="", AutoButtonColor=false, ZIndex=203}, gridFrame)
        corner(sw,8)
        sw.Activated:Connect(function()
            if not selected then return end
            if colorTarget == "Stroke" then
                local s = ensureStroke(selected)
                s.Color = col
                s.Transparency = 0
            elseif safeGet(selected,colorTarget) ~= nil then
                safeSet(selected,colorTarget,col)
            end
            showSelectionVisual()
        end)
    end

    if selected and (selected:IsA("GuiObject")) then
        section(body,"APARÊNCIA")
        compactRow(body,"TRANSP. FUNDO", tostring(round(selected.BackgroundTransparency*100)).."%", function() selected.BackgroundTransparency=clamp(selected.BackgroundTransparency+0.05,0,1) end, function() selected.BackgroundTransparency=clamp(selected.BackgroundTransparency-0.05,0,1) end)
        local c = selected:FindFirstChildOfClass("UICorner")
        compactRow(body,"CANTOS", tostring(c and c.CornerRadius.Offset or 0), function() corner(selected,clamp((c and c.CornerRadius.Offset or 0)-2,0,100)) end, function() corner(selected,clamp((c and c.CornerRadius.Offset or 0)+2,0,100)) end)
        local s = getStroke(selected)
        boolSwitch(body,"UISTROKE", s ~= nil, function(v)
            if v then ensureStroke(selected) else clearStroke(selected) end
        end)
        if s then
            compactRow(body,"ESPESSURA", tostring(round(s.Thickness)), function() s.Thickness=clamp(s.Thickness-1,1,10) end, function() s.Thickness=clamp(s.Thickness+1,1,10) end)
            compactRow(body,"TRANSP. BORDA", tostring(round(s.Transparency*100)).."%", function() s.Transparency=clamp(s.Transparency+0.05,0,1) end, function() s.Transparency=clamp(s.Transparency-0.05,0,1) end)
        end
    end

    if selected and (selected:IsA("TextLabel") or selected:IsA("TextButton") or selected:IsA("TextBox")) then
        section(body,"TEXTO")
        textBox(body,"TEXTO",selected.Text,function(v) selected.Text=v end)
        compactRow(body,"TAMANHO",tostring(selected.TextSize),function() selected.TextSize=clamp(selected.TextSize-1,6,120) end,function() selected.TextSize=clamp(selected.TextSize+1,6,120) end)
        boolSwitch(body,"TEXT SCALED",selected.TextScaled,function(v) selected.TextScaled=v end)
        boolSwitch(body,"TEXT WRAPPED",selected.TextWrapped,function(v) selected.TextWrapped=v end)

        section(body,"FONTE  •  DROPDOWN")
        local fontButton = button(body, "Fonte atual: " .. selected.Font.Name .. "  ▾", function() end, 38)
        fontButton.Activated:Connect(function()
            local drop = body:FindFirstChild("NORLI_FontDrop")
            if drop then drop:Destroy(); return end
            local list = make("ScrollingFrame", {Name="NORLI_FontDrop", Size=UDim2.new(1,0,0,220), BackgroundColor3=C.surface2, BorderSizePixel=0, ScrollBarThickness=3, ScrollBarImageColor3=C.accent, CanvasSize=UDim2.new(), ZIndex=250}, body)
            corner(list,10)
            local lay = make("UIListLayout", {Padding=UDim.new(0,4), SortOrder=Enum.SortOrder.Name}, list)
            make("UIPadding", {PaddingTop=UDim.new(0,6),PaddingBottom=UDim.new(0,6),PaddingLeft=UDim.new(0,6),PaddingRight=UDim.new(0,6)}, list)
            local fonts = Enum.Font:GetEnumItems()
            table.sort(fonts,function(a,b) return a.Name < b.Name end)
            for _,font in ipairs(fonts) do
                local fb = make("TextButton", {Size=UDim2.new(1,0,0,32), BackgroundColor3=C.card, BorderSizePixel=0, AutoButtonColor=false, Text=font.Name, Font=font, TextSize=14, TextColor3=C.text, ZIndex=251}, list)
                corner(fb,8)
                fb.Activated:Connect(function()
                    selected.Font = font
                    fontButton.Text = "Fonte atual: " .. font.Name .. "  ▾"
                    list:Destroy()
                end)
            end
            lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() list.CanvasSize=UDim2.new(0,0,0,lay.AbsoluteContentSize.Y+12) end)
        end)
    end

    section(body,"MODIFICADORES")
    local function addModifier(className)
        if not selected then return end
        if selected:FindFirstChildOfClass(className) then return end
        local m = Instance.new(className)
        m.Parent = selected
        refreshProperties()
    end
    button(body,"＋ UICORNER",function() addModifier("UICorner") end)
    button(body,"＋ UISTROKE",function() addModifier("UIStroke") end)
    button(body,"＋ UIGRADIENT",function() addModifier("UIGradient") end)
    button(body,"＋ UIPADDING",function() addModifier("UIPadding") end)
    button(body,"＋ UIASPECTRATIO",function() addModifier("UIAspectRatioConstraint") end)
    button(body,"＋ UISIZECONSTRAINT",function() addModifier("UISizeConstraint") end)
    button(body,"＋ UISCALE",function() addModifier("UIScale") end)
    button(body,"＋ UILISTLAYOUT",function() addModifier("UIListLayout") end)
    button(body,"＋ UIGRIDLAYOUT",function() addModifier("UIGridLayout") end)
    button(body,"＋ UIPAGELAYOUT",function() addModifier("UIPageLayout") end)
end

--// Elements panel
local function openElements()
    local body = createDrawer("ELEMENTOS  •  escolha pelo símbolo")
    addTag(body,"Símbolo = tipo de objeto. Se houver um selecionado, o novo vira filho dele.")
    local grid = make("Frame", {Size=UDim2.new(1,0,0,360), BackgroundTransparency=1, ZIndex=202}, body)
    make("UIGridLayout", {CellSize=UDim2.new(0.48,0,0,60), CellPadding=UDim2.new(0,7,0,7), HorizontalAlignment=Enum.HorizontalAlignment.Center, SortOrder=Enum.SortOrder.LayoutOrder}, grid)
    for _, info in ipairs(elements) do
        local card = make("TextButton", {BackgroundColor3=C.card, BorderSizePixel=0, Text="", AutoButtonColor=false, ZIndex=203}, grid)
        corner(card,10)
        make("TextLabel", {Size=UDim2.new(0,40,1,0), Position=UDim2.new(0,8,0,0), BackgroundTransparency=1, Text=info.icon, Font=Enum.Font.GothamBold, TextSize=20, TextColor3=C.accent, ZIndex=204}, card)
        make("TextLabel", {Size=UDim2.new(1,-58,0,22), Position=UDim2.new(0,54,0,8), BackgroundTransparency=1, Text=info.label, Font=Enum.Font.GothamBold, TextSize=10, TextColor3=C.text, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=204}, card)
        make("TextLabel", {Size=UDim2.new(1,-58,0,19), Position=UDim2.new(0,54,0,29), BackgroundTransparency=1, Text=info.desc, Font=Enum.Font.GothamMedium, TextSize=8, TextColor3=C.muted, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=204}, card)
        card.Activated:Connect(function() createElement(info.class) end)
    end
    section(body,"CONTROLES GUI AVANÇADOS")
    button(body,"◫ CANVAS GROUP",function() createElement("CanvasGroup") end)
    button(body,"◉ VIEWPORT 3D",function() createElement("ViewportFrame") end)
    button(body,"▶ VIDEO FRAME",function() createElement("VideoFrame") end)
end

--// Movement panel
local function openMove()
    local body = createDrawer("MOVER  •  POSIÇÃO / TAMANHO")
    if not selected then
        addTag(body,"Selecione um elemento primeiro.")
        button(body,"← FECHAR",function() if panel then panel:Destroy(); panel=nil end end)
        return
    end
    addTag(body,selected.Name)
    local pad = make("Frame", {Size=UDim2.new(1,0,0,175), BackgroundTransparency=1, ZIndex=202}, body)
    section(body,"PASSO")
    local stepValue=5
    compactRow(body,"PIXELS",tostring(stepValue),function() stepValue=clamp(stepValue-1,1,50) end,function() stepValue=clamp(stepValue+1,1,50) end)
    local function dynamic(txt,x,y,dx,dy)
        local b=button(pad,txt,function()
            local p=selected.Position
            selected.Position=UDim2.new(p.X.Scale,p.X.Offset+dx*stepValue,p.Y.Scale,p.Y.Offset+dy*stepValue)
            showSelectionVisual()
        end,48)
        b.Size=UDim2.fromOffset(62,44); b.Position=UDim2.new(0,x,0,y)
    end
    dynamic("▲",104,3,0,-1); dynamic("◀",38,54,-1,0); dynamic("▶",170,54,1,0); dynamic("▼",104,105,0,1)

    section(body,"TAMANHO")
    compactRow(body,"LARGURA",tostring(round(selected.Size.X.Offset)),function() selected.Size=UDim2.new(selected.Size.X.Scale,clamp(selected.Size.X.Offset-5,5,2000)) end,function() selected.Size=UDim2.new(selected.Size.X.Scale,clamp(selected.Size.X.Offset+5,5,2000)) end)
    compactRow(body,"ALTURA",tostring(round(selected.Size.Y.Offset)),function() selected.Size=UDim2.new(selected.Size.X.Scale,selected.Size.X.Offset,selected.Size.Y.Scale,clamp(selected.Size.Y.Offset-5,5,2000)) end,function() selected.Size=UDim2.new(selected.Size.X.Scale,selected.Size.X.Offset,selected.Size.Y.Scale,clamp(selected.Size.Y.Offset+5,5,2000)) end)
end

--// Assets
local function getRequestFunction()
    local names={"request","http_request","syn_request"}
    for _,name in ipairs(names) do
        local fn=rawget(_G,name)
        if type(fn)=="function" then return fn end
    end
    return nil
end

local function urlEncode(s)
    s=tostring(s or "")
    return s:gsub("([^%w%-_%.~])",function(c) return string.format("%%%02X",string.byte(c)) end)
end

local function openAssets()
    local body=createDrawer("ASSETS  •  TEXTURAS / IMAGENS")
    addTag(body,"A pesquisa usa a rede do executor quando disponível. O Roblox não oferece um endpoint seguro para listar todos os IDs de uma vez.")
    local search=textBox(body,"PESQUISAR NO CATÁLOGO","",function() end,"ex.: dog, button, icon")
    local status=addTag(body,"Aguardando pesquisa…")
    local results=make("Frame",{Size=UDim2.new(1,0,0,300),BackgroundTransparency=1,ZIndex=202},body)
    local resultGrid=make("UIGridLayout",{CellSize=UDim2.new(0.48,0,0,86),CellPadding=UDim2.new(0,7,0,7),HorizontalAlignment=Enum.HorizontalAlignment.Center},results)
    resultGrid.SortOrder=Enum.SortOrder.LayoutOrder

    local function doSearch(keyword)
        keyword=tostring(keyword or ""):gsub("^%s+",""):gsub("%s+$","")
        if keyword=="" then status.Text="Digite uma palavra-chave."; return end
        local req=getRequestFunction()
        if not req then
            status.Text="Este executor não fornece request/http_request. Use a galeria manual do seu executor."
            return
        end
        status.Text="Pesquisando…"
        for _,c in ipairs(results:GetChildren()) do if c:IsA("GuiButton") then c:Destroy() end end
        local url="https://catalog.roblox.com/v1/search/items/details?Keyword="..urlEncode(keyword).."&Limit=30&SortType=0&Category=1&Subcategory=8"
        task.spawn(function()
            local ok,response=pcall(function() return req({Url=url,Method="GET"}) end)
            if not ok or not response then status.Text="Falha ao consultar o catálogo."; return end
            local bodyText=response.Body or response.body
            if type(bodyText)~="string" then status.Text="Resposta do catálogo inválida."; return end
            local HttpService=game:GetService("HttpService")
            local okJson,data=pcall(function() return HttpService:JSONDecode(bodyText) end)
            if not okJson or type(data)~="table" or type(data.data)~="table" then status.Text="Nenhum resultado compatível."; return end
            local count=0
            for _,item in ipairs(data.data) do
                local id=item.id or item.assetId
                local name=item.name or "Asset"
                if id then
                    count+=1
                    local card=make("TextButton",{BackgroundColor3=C.card,BorderSizePixel=0,AutoButtonColor=false,Text="",ZIndex=204},results)
                    corner(card,9)
                    make("TextLabel",{Size=UDim2.new(1,-10,0,34),Position=UDim2.new(0,5,0,5),BackgroundTransparency=1,Text=tostring(name),Font=Enum.Font.GothamBold,TextSize=9,TextColor3=C.text,TextWrapped=true,ZIndex=205},card)
                    make("TextLabel",{Size=UDim2.new(1,-10,0,25),Position=UDim2.new(0,5,0,43),BackgroundTransparency=1,Text="ID  "..tostring(id),Font=Enum.Font.Code,TextSize=8,TextColor3=C.muted,ZIndex=205},card)
                    card.Activated:Connect(function()
                        if not selected then return end
                        if selected:IsA("ImageLabel") or selected:IsA("ImageButton") then
                            selected.Image="rbxassetid://"..tostring(id)
                            status.Text="Aplicado em "..selected.Name
                        else
                            status.Text="Selecione ImageLabel ou ImageButton para aplicar."
                        end
                    end)
                end
            end
            status.Text=count>0 and (tostring(count).." resultado(s). Toque para aplicar.") or "Nenhum resultado compatível."
        end)
    end
    search.FocusLost:Connect(function(enterPressed) if enterPressed then doSearch(search.Text) end end)
    button(body,"🔎 PESQUISAR AGORA",function() doSearch(search.Text) end)
    resultGrid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() results.Size=UDim2.new(1,0,0,math.max(300,resultGrid.AbsoluteContentSize.Y+10)) end)
end

--// DPad always available in Move tab/panel only
--// Export
local function luaString(v)
    v=tostring(v or "")
    v=v:gsub("\\","\\\\"):gsub("\n","\\n"):gsub("\r","\\r"):gsub('"','\\"')
    return '"'..v..'"'
end

local function nstr(n)
    n=tonumber(n) or 0
    if math.abs(n)<0.000001 then n=0 end
    local s=string.format("%.4f",n)
    s=s:gsub("(%..-)0+$","%1"):gsub("%.$","")
    return s
end

local function ser(v)
    local t=typeof(v)
    if t=="string" then return luaString(v) end
    if t=="number" then return nstr(v) end
    if t=="boolean" then return v and "true" or "false" end
    if t=="Color3" then return string.format("Color3.fromRGB(%d,%d,%d)",round(v.R*255),round(v.G*255),round(v.B*255)) end
    if t=="UDim" then return string.format("UDim.new(%s,%s)",nstr(v.Scale),nstr(v.Offset)) end
    if t=="UDim2" then return string.format("UDim2.new(%s,%s,%s,%s)",nstr(v.X.Scale),nstr(v.X.Offset),nstr(v.Y.Scale),nstr(v.Y.Offset)) end
    if t=="Vector2" then return string.format("Vector2.new(%s,%s)",nstr(v.X),nstr(v.Y)) end
    if t=="Vector3" then return string.format("Vector3.new(%s,%s,%s)",nstr(v.X),nstr(v.Y),nstr(v.Z)) end
    if t=="EnumItem" then return tostring(v) end
    if t=="BrickColor" then return "BrickColor.new("..luaString(v.Name)..")" end
    if t=="Rect" then return string.format("Rect.new(%s,%s,%s,%s)",nstr(v.Min.X),nstr(v.Min.Y),nstr(v.Max.X),nstr(v.Max.Y)) end
    if t=="NumberSequence" then
        local parts={}
        for _,k in ipairs(v.Keypoints) do table.insert(parts,string.format("NumberSequenceKeypoint.new(%s,%s,%s)",nstr(k.Time),nstr(k.Value),nstr(k.Envelope))) end
        return "NumberSequence.new({"..table.concat(parts,",").."})"
    end
    if t=="ColorSequence" then
        local parts={}
        for _,k in ipairs(v.Keypoints) do table.insert(parts,string.format("ColorSequenceKeypoint.new(%s,%s)",nstr(k.Time),ser(k.Value))) end
        return "ColorSequence.new({"..table.concat(parts,",").."})"
    end
    return nil
end

local function sanitizeName(s)
    s=tostring(s or "Element"):gsub("[^%w_]","_")
    if s=="" then s="Element" end
    if s:match("^%d") then s="_"..s end
    return s
end

local exportGuiProps={"Name","Position","Size","AnchorPoint","ZIndex","Visible","Rotation","LayoutOrder","BackgroundColor3","BackgroundTransparency","BorderColor3","BorderSizePixel","ClipsDescendants","Active","Selectable","AutomaticSize"}
local exportTextProps={"Text","Font","TextSize","TextColor3","TextTransparency","TextStrokeColor3","TextStrokeTransparency","TextScaled","TextWrapped","TextXAlignment","TextYAlignment","TextTruncate","RichText","PlaceholderText","PlaceholderColor3","ClearTextOnFocus","MultiLine"}
local exportImageProps={"Image","ImageColor3","ImageTransparency","ResampleMode","ScaleType","SliceCenter","SliceScale","TileSize"}
local exportScrollProps={"CanvasSize","CanvasPosition","ScrollBarThickness","ScrollBarImageColor3","ScrollBarImageTransparency","ScrollingDirection","ElasticBehavior","HorizontalScrollBarInset","VerticalScrollBarInset"}
local exportStrokeProps={"Color","Transparency","Thickness","Enabled","LineJoinMode"}
local exportCornerProps={"CornerRadius"}
local exportPaddingProps={"PaddingTop","PaddingBottom","PaddingLeft","PaddingRight"}
local exportGradientProps={"Color","Transparency","Rotation","Offset","Scale","Enabled"}
local exportAspectProps={"AspectRatio","AspectType","DominantAxis"}
local exportSizeProps={"MinSize","MaxSize"}
local exportScaleProps={"Scale"}
local exportListProps={"FillDirection","HorizontalAlignment","VerticalAlignment","Padding","SortOrder","Wraps","HorizontalFlex","VerticalFlex","ItemLineAlignment","FillDirectionMaxCells"}
local exportGridProps={"CellPadding","CellSize","FillDirection","FillDirectionMaxCells","HorizontalAlignment","VerticalAlignment","SortOrder","StartCorner"}
local exportPageProps={"Animated","Circular","EasingDirection","EasingStyle","Padding","TweenTime","TouchInputEnabled","GamepadInputEnabled","ScrollWheelInputEnabled"}

local function appendProps(lines,var,obj,props)
    for _,prop in ipairs(props) do
        local value=safeGet(obj,prop)
        local encoded=value~=nil and ser(value)
        if encoded then table.insert(lines,var.."."..prop.." = "..encoded) end
    end
end

local function exportLua()
    local lines={}
    local function add(s) lines[#lines+1]=s end
    add("-- NORLI GUI STUDIO V2 EXPORT")
    add("local Players = game:GetService(\"Players\")")
    add("local player = Players.LocalPlayer")
    add("local playerGui = player:WaitForChild(\"PlayerGui\")")
    add("local old = playerGui:FindFirstChild(\"NORLI_EXPORTED_GUI\")")
    add("if old then old:Destroy() end")
    add("local gui = Instance.new(\"ScreenGui\")")
    add("gui.Name = \"NORLI_EXPORTED_GUI\"")
    add("gui.IgnoreGuiInset = true")
    add("gui.ResetOnSpawn = false")
    add("gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling")
    add("gui.Parent = playerGui")
    add("")

    local index=0
    local vars={}
    local function visit(obj,parentExpr)
        if obj==EmptyHint or obj==Grid or obj==selectionVisual or obj.Name=="NORLI_Selection" then return end
        if not obj:IsA("GuiObject") and not obj:IsA("UICorner") and not obj:IsA("UIStroke") and not obj:IsA("UIGradient") and not obj:IsA("UIPadding") and not obj:IsA("UIAspectRatioConstraint") and not obj:IsA("UISizeConstraint") and not obj:IsA("UIScale") and not obj:IsA("UIListLayout") and not obj:IsA("UIGridLayout") and not obj:IsA("UIPageLayout") then return end
        index+=1
        local var="obj"..index
        vars[obj]=var
        add("local "..var.." = Instance.new("..luaString(obj.ClassName)..")")
        if obj:IsA("GuiObject") then
            appendProps(lines,var,obj,exportGuiProps)
            if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then appendProps(lines,var,obj,exportTextProps) end
            if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then appendProps(lines,var,obj,exportImageProps) end
            if obj:IsA("ScrollingFrame") then appendProps(lines,var,obj,exportScrollProps) end
            if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                local interact=safeGet(obj,"Interactable")
                if interact~=nil then add(var..".Interactable = "..ser(interact)) end
            end
        elseif obj:IsA("UIStroke") then appendProps(lines,var,obj,exportStrokeProps)
        elseif obj:IsA("UICorner") then appendProps(lines,var,obj,exportCornerProps)
        elseif obj:IsA("UIPadding") then appendProps(lines,var,obj,exportPaddingProps)
        elseif obj:IsA("UIGradient") then appendProps(lines,var,obj,exportGradientProps)
        elseif obj:IsA("UIAspectRatioConstraint") then appendProps(lines,var,obj,exportAspectProps)
        elseif obj:IsA("UISizeConstraint") then appendProps(lines,var,obj,exportSizeProps)
        elseif obj:IsA("UIScale") then appendProps(lines,var,obj,exportScaleProps)
        elseif obj:IsA("UIListLayout") then appendProps(lines,var,obj,exportListProps)
        elseif obj:IsA("UIGridLayout") then appendProps(lines,var,obj,exportGridProps)
        elseif obj:IsA("UIPageLayout") then appendProps(lines,var,obj,exportPageProps)
        end
        add(var..".Parent = "..parentExpr)
        add("")
        for _,child in ipairs(obj:GetChildren()) do
            visit(child,var)
        end
    end

    for _,obj in ipairs(DesignRoot:GetChildren()) do
        if obj:IsA("GuiObject") and obj~=EmptyHint then
            visit(obj,"gui")
        end
    end
    add("print(\"NORLI GUI export concluído\")")
    return table.concat(lines,"\n")
end

local function openExport()
    local body=createDrawer("EXPORT  •  LUA")
    local source=exportLua()
    addTag(body,"A árvore visual da sua interface foi convertida para código Lua.")
    local codeBox=make("TextBox",{Size=UDim2.new(1,0,0,340),BackgroundColor3=Color3.fromRGB(10,12,16),BorderSizePixel=0,Text=source,Font=Enum.Font.Code,TextSize=9,TextColor3=Color3.fromRGB(225,231,240),TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,MultiLine=true,ClearTextOnFocus=false,TextWrapped=false,ZIndex=203},body)
    corner(codeBox,10)
    button(body,"⧉  COPIAR LUA",function()
        if safeClipboard(source) then
            Status.Text="LUA COPIADO"
            Status.TextColor3=C.green
        else
            codeBox:CaptureFocus()
            codeBox.SelectionStart=1
            codeBox.CursorPosition=#codeBox.Text+1
            Status.Text="SELECIONE E COPIE MANUALMENTE"
            Status.TextColor3=C.muted
        end
    end)
    button(body,"↻  ATUALIZAR EXPORTAÇÃO",function() openExport() end)
end

--// Tab bar
local Tabs = make("Frame", {
    Size=UDim2.new(1,0,0,56),
    Position=UDim2.new(0,0,1,-56),
    BackgroundColor3=C.surface,
    BorderSizePixel=0,
    ZIndex=10,
}, Root)
local tabLayout=make("UIGridLayout",{CellSize=UDim2.new(1/6,-4,0,44),CellPadding=UDim2.new(0,4,0,0),HorizontalAlignment=Enum.HorizontalAlignment.Center,VerticalAlignment=Enum.VerticalAlignment.Center,SortOrder=Enum.SortOrder.LayoutOrder},Tabs)

local tabInfo={
    {id="ELEMENTS",icon="＋",label="OBJETOS",fn=openElements},
    {id="INSPECT",icon="☷",label="INSPECT",fn=function() createDrawer("INSPECTOR"); refreshProperties() end},
    {id="STYLE",icon="◈",label="ESTILO",fn=openStyle},
    {id="MOVE",icon="✥",label="MOVER",fn=openMove},
    {id="ASSETS",icon="▧",label="ASSETS",fn=openAssets},
    {id="EXPORT",icon="↗",label="EXPORT",fn=openExport},
}

openTab = function(id)
    if panel then pcall(function() panel:Destroy() end); panel=nil end
    currentTab=id
    for _,info in ipairs(tabInfo) do
        if info.id==id then
            info.fn()
            break
        end
    end
end

for _,info in ipairs(tabInfo) do
    local b=make("TextButton",{LayoutOrder=table.find(tabInfo,info),BackgroundColor3=C.surface2,BorderSizePixel=0,AutoButtonColor=false,Text=info.icon.."\n"..info.label,Font=Enum.Font.GothamBold,TextSize=8,TextColor3=C.text,TextWrapped=true,ZIndex=11},Tabs)
    corner(b,10)
    tabButtons[info.id]=b
    b.Activated:Connect(function() openTab(info.id) end)
end

--// Canvas base interactions
Canvas.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
        if input.Target==DesignRoot and not panel then setSelected(nil) end
    end
end)

--// Keep newly created hierarchy selectable.
DesignRoot.ChildAdded:Connect(function(child)
    if child:IsA("GuiObject") then connectSelectable(child) end
end)

--// Initial state: empty canvas + a practical sample only if desired by tap.
EmptyHint.Visible=true
Status.Text="V2  •  MOBILE  •  READY"

--// Small-screen adjustments
local function responsive()
    local camera=workspace.CurrentCamera
    local v=camera and camera.ViewportSize or Vector2.new(800,600)
    if v.X<420 then
        Brand.TextSize=13
        Status.TextSize=8
        RestoreButton.Size=UDim2.fromOffset(78,32)
        RestoreButton.Position=UDim2.new(1,-168,0,12)
        RestoreButton.Text="↺ UI"
        CloseButton.Size=UDim2.fromOffset(66,32)
        CloseButton.Position=UDim2.new(1,-78,0,12)
        CloseButton.Text="✕"
    else
        RestoreButton.Size=UDim2.fromOffset(88,34)
        RestoreButton.Position=UDim2.new(1,-186,0,11)
        RestoreButton.Text="↺ UI ROBLOX"
        CloseButton.Size=UDim2.fromOffset(78,34)
        CloseButton.Position=UDim2.new(1,-90,0,11)
        CloseButton.Text="✕ FECHAR"
    end
end
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(responsive) end
responsive()

--// Open object library at startup.
openTab("ELEMENTS")
