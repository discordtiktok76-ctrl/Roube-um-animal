--[[
    NORLI GUI STUDIO — V3
    Editor de interfaces do Roblox feito para ser usado 100% pelo celular.

    Rode isto dentro de um jogo SEU sem outros jogadores (ex.: o "lugar"
    pessoal que a própria conta Roblox cria automaticamente). Não foi feito
    para rodar em jogos de terceiros com outros jogadores presentes.

    NOVIDADES DA V3 (o que mudou de verdade em relação à V2):
    • Arrastar com o dedo: toque e arraste qualquer elemento no canvas —
      não depende mais só do D-pad.
    • Alças de redimensionar e girar direto no elemento selecionado.
    • Zoom (pinça com dois dedos) e pan (arrastar com dois dedos) no canvas,
      com botões de zoom/ajuste na barra de ferramentas.
    • Desfazer / Refazer (histórico de até 60 ações: mover, redimensionar,
      girar, criar, duplicar, apagar).
    • Aba CAMADAS: lista de elementos com selecionar, ocultar, travar,
      subir/descer na pilha (ZIndex) e apagar.
    • Aba OBJETOS com busca e "usados recentemente".
    • Snap em grade (liga/desliga) para alinhar sem esforço no celular.
    • Aba PROJETO: exportar para o jogo (Lua), SALVAR projeto na área de
      transferência e CARREGAR um projeto colado (via loadstring, quando o
      executor permite).
    • Barra de abas agora rola na horizontal — cabe qualquer quantidade de
      abas confortavelmente numa tela pequena.
]]

--// Services ---------------------------------------------------------------
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local StarterGui        = game:GetService("StarterGui")
local UserInputService  = game:GetService("UserInputService")
local HttpService       = game:GetService("HttpService")

local player = Players.LocalPlayer
if not player then return end
local playerGui = player:WaitForChild("PlayerGui")

--// Rerun-safe cleanup -------------------------------------------------------
local oldGui = playerGui:FindFirstChild("NORLI_GUI_STUDIO")
if oldGui then
    pcall(function() oldGui:Destroy() end)
end

--// Safe helpers -------------------------------------------------------------
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

local function getLoadstring()
    return rawget(_G, "loadstring") or (type(loadstring) == "function" and loadstring) or nil
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

--// Roblox UI cleanup — reversible ------------------------------------------
local coreGuiTypes = {
    Enum.CoreGuiType.Backpack, Enum.CoreGuiType.PlayerList, Enum.CoreGuiType.Health,
    Enum.CoreGuiType.Chat, Enum.CoreGuiType.EmotesMenu, Enum.CoreGuiType.Captures,
    Enum.CoreGuiType.SelfView,
}
local previousCoreGui = {}
for _, typeValue in ipairs(coreGuiTypes) do
    local ok, value = pcall(function() return StarterGui:GetCoreGuiEnabled(typeValue) end)
    if ok then previousCoreGui[typeValue] = value end
    pcall(function() StarterGui:SetCoreGuiEnabled(typeValue, false) end)
end
local function restoreCoreGui()
    for typeValue, wasEnabled in pairs(previousCoreGui) do
        pcall(function() StarterGui:SetCoreGuiEnabled(typeValue, wasEnabled) end)
    end
end

--// Local-only inventory cleanup (does not touch server data) ---------------
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

--// Theme --------------------------------------------------------------------
local C = {
    bg = Color3.fromRGB(9, 11, 15), surface = Color3.fromRGB(17, 20, 27),
    surface2 = Color3.fromRGB(23, 27, 36), card = Color3.fromRGB(29, 34, 44),
    card2 = Color3.fromRGB(35, 41, 53), accent = Color3.fromRGB(97, 140, 255),
    accent2 = Color3.fromRGB(73, 110, 225), green = Color3.fromRGB(80, 211, 127),
    red = Color3.fromRGB(239, 84, 99), amber = Color3.fromRGB(240, 176, 74),
    text = Color3.fromRGB(245, 247, 251), muted = Color3.fromRGB(157, 166, 183),
    line = Color3.fromRGB(55, 62, 77), canvas = Color3.fromRGB(13, 16, 22),
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

--// Undo / Redo history ------------------------------------------------------
local MAX_HISTORY = 60
local undoStack, redoStack = {}, {}
local suppressHistory = false

local function pushHistory(undoFn, redoFn)
    if suppressHistory then return end
    table.insert(undoStack, {undo = undoFn, redo = redoFn})
    if #undoStack > MAX_HISTORY then table.remove(undoStack, 1) end
    table.clear(redoStack)
end

--// Root ----------------------------------------------------------------------
local Gui = make("ScreenGui", {
    Name = "NORLI_GUI_STUDIO", IgnoreGuiInset = true, ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 100000,
}, playerGui)
Gui.Destroying:Connect(restoreCoreGui)

local Root = make("Frame", {Size = UDim2.fromScale(1,1), BackgroundColor3 = C.bg, BorderSizePixel = 0}, Gui)

--// Header ---------------------------------------------------------------------
local Header = make("Frame", {Size = UDim2.new(1,0,0,56), BackgroundColor3 = C.surface, BorderSizePixel = 0, ZIndex = 10}, Root)
local HeaderStroke = ensureStroke(Header)
HeaderStroke.Transparency = 0.65
HeaderStroke.Thickness = 1
HeaderStroke.Color = C.line

local Brand = make("TextLabel", {
    Size = UDim2.new(1,-210,0,25), Position = UDim2.new(0,14,0,7), BackgroundTransparency = 1,
    Text = "NORLI GUI STUDIO", Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = C.text,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 11,
}, Header)

local Status = make("TextLabel", {
    Size = UDim2.new(1,-210,0,17), Position = UDim2.new(0,14,0,32), BackgroundTransparency = 1,
    Text = "V3  •  MOBILE  •  PRONTO", Font = Enum.Font.GothamMedium, TextSize = 9, TextColor3 = C.muted,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 11,
}, Header)

local statusToken = 0
local function flashStatus(text, color, duration)
    statusToken += 1
    local token = statusToken
    Status.Text = text
    Status.TextColor3 = color or C.muted
    task.delay(duration or 1.2, function()
        if Status.Parent and token == statusToken then
            Status.Text = "V3  •  MOBILE  •  PRONTO"
            Status.TextColor3 = C.muted
        end
    end)
end

local RestoreButton = make("TextButton", {
    Size = UDim2.new(0,88,0,34), Position = UDim2.new(1,-186,0,11), BackgroundColor3 = C.card,
    BorderSizePixel = 0, AutoButtonColor = false, Text = "↺ UI ROBLOX", Font = Enum.Font.GothamBold,
    TextSize = 9, TextColor3 = C.muted, ZIndex = 11,
}, Header)
corner(RestoreButton, 9)
RestoreButton.Activated:Connect(function()
    restoreCoreGui()
    flashStatus("ROBLOX UI RESTAURADA", C.green, 1.3)
end)

local CloseButton = make("TextButton", {
    Size = UDim2.new(0,78,0,34), Position = UDim2.new(1,-90,0,11), BackgroundColor3 = C.red,
    BorderSizePixel = 0, AutoButtonColor = false, Text = "✕ FECHAR", Font = Enum.Font.GothamBold,
    TextSize = 9, TextColor3 = Color3.new(1,1,1), ZIndex = 11,
}, Header)
corner(CloseButton, 9)
CloseButton.Activated:Connect(function() Gui:Destroy() end)

--// Undo / Redo actions (need flashStatus, defined above) --------------------
local function doUndo()
    local action = table.remove(undoStack)
    if not action then flashStatus("NADA PARA DESFAZER", C.muted); return end
    suppressHistory = true
    pcall(action.undo)
    suppressHistory = false
    table.insert(redoStack, action)
    flashStatus("DESFEITO", C.accent)
end

local function doRedo()
    local action = table.remove(redoStack)
    if not action then flashStatus("NADA PARA REFAZER", C.muted); return end
    suppressHistory = true
    pcall(action.redo)
    suppressHistory = false
    table.insert(undoStack, action)
    flashStatus("REFEITO", C.accent)
end

--// Editing state used by the toolbar and the canvas -------------------------
local snapEnabled = false
local gridSize = 8

--// Canvas ---------------------------------------------------------------------
local TOOLBAR_H = 34
local TABBAR_H = 58

local CanvasHolder = make("Frame", {
    Size = UDim2.new(1,0,1,-(56+TOOLBAR_H+TABBAR_H)), Position = UDim2.new(0,0,0,56+TOOLBAR_H),
    BackgroundColor3 = C.canvas, BorderSizePixel = 0, ClipsDescendants = true, Active = true,
}, Root)

local Canvas = make("Frame", {
    Size = UDim2.new(1,-24,1,-24), Position = UDim2.new(0,12,0,12), BackgroundColor3 = Color3.fromRGB(18,21,28),
    BorderSizePixel = 0, ClipsDescendants = true, Active = true,
}, CanvasHolder)
corner(Canvas, 14)
local CanvasStroke = ensureStroke(Canvas)
CanvasStroke.Color = C.line
CanvasStroke.Transparency = 0.45

local Grid = make("Frame", {Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, BorderSizePixel = 0, Active = false, ZIndex = 1}, Canvas)

local DesignRoot = make("Frame", {
    Name = "DesignRoot", Size = UDim2.new(1,-20,1,-20), Position = UDim2.new(0,10,0,10),
    BackgroundColor3 = Color3.fromRGB(16,18,24), BorderSizePixel = 0, ClipsDescendants = true, Active = true, ZIndex = 3,
}, Canvas)
corner(DesignRoot, 11)
local ZoomScale = make("UIScale", {Name = "NORLI_Zoom", Scale = 1}, DesignRoot)
local basePosition = DesignRoot.Position

for i = 1, 7 do
    make("Frame", {Size=UDim2.new(0,1,1,0), Position=UDim2.new(i/8,0,0,0), BackgroundColor3=C.line, BackgroundTransparency=0.88, BorderSizePixel=0, ZIndex=2}, Grid)
end
for i = 1, 5 do
    make("Frame", {Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,i/6,0), BackgroundColor3=C.line, BackgroundTransparency=0.88, BorderSizePixel=0, ZIndex=2}, Grid)
end

local EmptyHint = make("TextLabel", {
    Size = UDim2.new(1,-40,0,64), Position = UDim2.new(0,20,0.5,-32), BackgroundTransparency = 1,
    Text = "CANVAS VAZIO\nEscolha um símbolo em OBJETOS para começar",
    Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = C.muted, TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center, ZIndex = 3,
}, DesignRoot)

--// Toolbar: undo/redo, zoom, snap --------------------------------------------
local Toolbar = make("Frame", {Size=UDim2.new(1,0,0,TOOLBAR_H), Position=UDim2.new(0,0,0,56), BackgroundColor3=C.surface2, BorderSizePixel=0, ZIndex=9}, Root)
local toolLayout = make("UIListLayout", {FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,6), VerticalAlignment=Enum.VerticalAlignment.Center, SortOrder=Enum.SortOrder.LayoutOrder}, Toolbar)
make("UIPadding", {PaddingLeft=UDim.new(0,8), PaddingRight=UDim.new(0,8)}, Toolbar)

local function toolButton(icon, width, callback)
    local b = make("TextButton", {Size=UDim2.new(0,width,0,26), BackgroundColor3=C.card, BorderSizePixel=0, AutoButtonColor=false, Text=icon, Font=Enum.Font.GothamBold, TextSize=11, TextColor3=C.text, ZIndex=10}, Toolbar)
    corner(b, 7)
    b.Activated:Connect(callback)
    return b
end

toolButton("↺", 34, function() doUndo() end)
toolButton("↻", 34, function() doRedo() end)

local snapButton = toolButton("▦ SNAP: OFF", 90, function() end)
snapButton.Activated:Connect(function()
    snapEnabled = not snapEnabled
    snapButton.Text = "▦ SNAP: " .. (snapEnabled and "ON" or "OFF")
    snapButton.BackgroundColor3 = snapEnabled and C.accent2 or C.card
end)

toolButton("－", 30, function()
    ZoomScale.Scale = clamp(ZoomScale.Scale - 0.1, 0.4, 2.5)
end)
local zoomLabel = make("TextLabel", {Size=UDim2.new(0,48,0,26), BackgroundColor3=C.card, BorderSizePixel=0, Text="100%", Font=Enum.Font.GothamBold, TextSize=9, TextColor3=C.text, ZIndex=10}, Toolbar)
corner(zoomLabel, 7)
toolButton("＋", 30, function()
    ZoomScale.Scale = clamp(ZoomScale.Scale + 0.1, 0.4, 2.5)
end)
toolButton("⤢ AJUSTAR", 76, function()
    ZoomScale.Scale = 1
    DesignRoot.Position = basePosition
end)

ZoomScale:GetPropertyChangedSignal("Scale"):Connect(function()
    zoomLabel.Text = tostring(round(ZoomScale.Scale * 100)) .. "%"
end)

local function getStageScale()
    return ZoomScale.Scale
end

--// Two-finger pan and pinch-to-zoom on the canvas ---------------------------
local panStartPosition = nil
CanvasHolder.TouchPan:Connect(function(_, totalTranslation, _, state)
    if state == Enum.UserInputState.Begin then
        panStartPosition = DesignRoot.Position
    elseif state == Enum.UserInputState.Change and panStartPosition then
        DesignRoot.Position = UDim2.new(
            panStartPosition.X.Scale, panStartPosition.X.Offset + totalTranslation.X,
            panStartPosition.Y.Scale, panStartPosition.Y.Offset + totalTranslation.Y
        )
    else
        panStartPosition = nil
    end
end)

local pinchStartScale = 1
CanvasHolder.TouchPinch:Connect(function(_, scale, _, state)
    if state == Enum.UserInputState.Begin then
        pinchStartScale = ZoomScale.Scale
    elseif state == Enum.UserInputState.Change then
        ZoomScale.Scale = clamp(pinchStartScale * scale, 0.4, 2.5)
    end
end)

--// Editor state ----------------------------------------------------------------
local selected = nil
local selectionVisual = nil
local currentTab = nil
local colorTarget = "BackgroundColor3"
local panel, panelTitle, panelBody, panelBack = nil, nil, nil, nil
local tabButtons = {}
local connections = {}
local recentClasses = {}
local openTab
local refreshProperties = function() end
local refreshLayers = function() end
local beginDrag, beginResize, beginRotate

local function disconnectAll(list)
    for _, c in ipairs(list) do pcall(function() c:Disconnect() end) end
    table.clear(list)
end

local function isSelectable(obj)
    return obj and obj:IsA("GuiObject") and obj:IsDescendantOf(DesignRoot) and obj ~= DesignRoot and obj ~= EmptyHint and obj.Name ~= "NORLI_Selection"
end

local function isLocked(obj)
    return obj and obj:GetAttribute("NORLI_Locked") == true
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
        Name = "NORLI_Selection", Size = UDim2.new(1,8,1,8), Position = UDim2.new(0,-4,0,-4),
        BackgroundTransparency = 1, BorderSizePixel = 0, Active = false, ZIndex = math.max(1000, selected.ZIndex + 100),
    }, selected)
    local s = ensureStroke(selectionVisual)
    s.Name = "NORLI_Selection"
    s.Color = C.accent
    s.Thickness = 2
    s.Transparency = 0

    if isLocked(selected) then return end -- no handles on locked elements

    local resizeHandle = make("TextButton", {
        Name = "NORLI_ResizeHandle", Size = UDim2.fromOffset(26,26), Position = UDim2.new(1,-9,1,-9),
        AnchorPoint = Vector2.new(0.5,0.5), BackgroundColor3 = C.accent, BorderSizePixel = 0,
        AutoButtonColor = false, Text = "◢", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Color3.new(1,1,1),
        Active = true, ZIndex = math.max(1001, selected.ZIndex + 101),
    }, selectionVisual)
    corner(resizeHandle, 13)
    resizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            beginResize(selected, input)
        end
    end)

    local rotateHandle = make("TextButton", {
        Name = "NORLI_RotateHandle", Size = UDim2.fromOffset(26,26), Position = UDim2.new(0.5,0,0,-30),
        AnchorPoint = Vector2.new(0.5,0.5), BackgroundColor3 = C.green, BorderSizePixel = 0,
        AutoButtonColor = false, Text = "↻", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Color3.new(1,1,1),
        Active = true, ZIndex = math.max(1001, selected.ZIndex + 101),
    }, selectionVisual)
    corner(rotateHandle, 13)
    rotateHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            beginRotate(selected, input)
        end
    end)
end

--// Content panel scaffolding --------------------------------------------------
local function createDrawer(title)
    if panel then pcall(function() panel:Destroy() end) end
    panel = make("Frame", {Size = UDim2.new(0.92,0,0.79,0), Position = UDim2.new(0.04,0,0.08,0), BackgroundColor3 = C.surface, BorderSizePixel = 0, ZIndex = 200}, Root)
    corner(panel, 15)
    local s = ensureStroke(panel)
    s.Color = C.line
    s.Transparency = 0.2
    s.Thickness = 1

    panelTitle = make("TextLabel", {Size = UDim2.new(1,-110,0,40), Position = UDim2.new(0,14,0,6), BackgroundTransparency = 1, Text = title, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 201}, panel)

    panelBack = make("TextButton", {Size = UDim2.new(0,76,0,32), Position = UDim2.new(1,-90,0,10), BackgroundColor3 = C.card, BorderSizePixel = 0, AutoButtonColor = false, Text = "← FECHAR", Font = Enum.Font.GothamBold, TextSize = 9, TextColor3 = C.text, ZIndex = 201}, panel)
    corner(panelBack, 9)
    panelBack.Activated:Connect(function()
        if panel then panel:Destroy(); panel = nil; currentTab = nil end
    end)

    panelBody = make("ScrollingFrame", {Size = UDim2.new(1,-20,1,-58), Position = UDim2.new(0,10,0,50), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = C.accent, CanvasSize = UDim2.new(), ZIndex = 201}, panel)
    make("UIPadding", {PaddingLeft=UDim.new(0,2), PaddingRight=UDim.new(0,2), PaddingTop=UDim.new(0,2), PaddingBottom=UDim.new(0,12)}, panelBody)
    make("UIListLayout", {Padding=UDim.new(0,7), SortOrder=Enum.SortOrder.LayoutOrder}, panelBody)
    panelBody:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(function()
        panelBody.CanvasSize = UDim2.new(0,0,0, math.max(panelBody.AbsoluteCanvasSize.Y, panelBody.AbsoluteSize.Y) + 12)
    end)
    return panelBody
end

local function section(parent, textValue)
    return make("TextLabel", {Size=UDim2.new(1,0,0,20), BackgroundTransparency=1, Text=textValue, Font=Enum.Font.GothamBold, TextSize=9, TextColor3=C.muted, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=202}, parent)
end

local function button(parent, textValue, callback, height)
    local b = make("TextButton", {Size=UDim2.new(1,0,0,height or 36), BackgroundColor3=C.card, BorderSizePixel=0, AutoButtonColor=false, Text=textValue, Font=Enum.Font.GothamBold, TextSize=10, TextColor3=C.text, ZIndex=202}, parent)
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

local function textBox(parent, labelText, initial, callback, placeholder, multiline)
    local h = multiline and 140 or 56
    local wrap = make("Frame", {Size=UDim2.new(1,0,0,h), BackgroundTransparency=1, ZIndex=202}, parent)
    make("TextLabel", {Size=UDim2.new(1,0,0,18), BackgroundTransparency=1, Text=labelText, Font=Enum.Font.GothamMedium, TextSize=9, TextColor3=C.muted, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=203}, wrap)
    local box = make("TextBox", {
        Size=UDim2.new(1,0,0,h-21), Position=UDim2.new(0,0,0,21), BackgroundColor3=C.card, BorderSizePixel=0,
        Text=tostring(initial or ""), PlaceholderText=placeholder or "", ClearTextOnFocus=false, Font=Enum.Font.GothamMedium,
        TextSize=10, TextColor3=C.text, PlaceholderColor3=C.muted, TextXAlignment=Enum.TextXAlignment.Left,
        TextYAlignment = multiline and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
        MultiLine = multiline or false, TextWrapped = multiline or false, ZIndex=203,
    }, wrap)
    corner(box, 9)
    box.FocusLost:Connect(function() callback(box.Text) end)
    return box
end

local function addTag(parent, value)
    return make("TextLabel", {Size=UDim2.new(1,0,0,28), BackgroundColor3=C.surface2, BorderSizePixel=0, Text=value, Font=Enum.Font.GothamBold, TextSize=9, TextColor3=C.muted, TextXAlignment=Enum.TextXAlignment.Center, TextWrapped=true, ZIndex=203}, parent)
end

local function boolSwitch(parent, labelText, current, callback)
    local b = button(parent, labelText .. "  •  " .. (current and "ON" or "OFF"), function()
        current = not current
        callback(current)
        b.Text = labelText .. "  •  " .. (current and "ON" or "OFF")
    end, 36)
    return b
end

--// Selection / drag / resize / rotate ----------------------------------------
local function setSelected(obj)
    if obj and obj == EmptyHint then obj = nil end
    if obj and not isSelectable(obj) then return end
    selected = obj
    removeSelectionVisual()
    if selected then
        showSelectionVisual()
        EmptyHint.Visible = false
    else
        EmptyHint.Visible = (#DesignRoot:GetChildren() <= 2) -- DesignRoot + EmptyHint + NORLI_Zoom
    end
    refreshProperties()
end

local function isSameInput(a, b)
    if a == b then return true end
    if a.UserInputType == Enum.UserInputType.MouseButton1 and b.UserInputType == Enum.UserInputType.MouseMovement then return true end
    return false
end

beginDrag = function(obj, input)
    local startInputPos = input.Position
    local startObjPos = obj.Position
    local moved = false
    local conn1, conn2

    conn1 = UserInputService.InputChanged:Connect(function(inp)
        if not isSameInput(inp, input) then return end
        local scale = getStageScale()
        local delta = (inp.Position - startInputPos) / scale
        if delta.Magnitude > 3 then moved = true end
        local newX, newY = startObjPos.X.Offset + delta.X, startObjPos.Y.Offset + delta.Y
        if snapEnabled then
            newX = round(newX / gridSize) * gridSize
            newY = round(newY / gridSize) * gridSize
        end
        obj.Position = UDim2.new(startObjPos.X.Scale, newX, startObjPos.Y.Scale, newY)
        if obj == selected then showSelectionVisual() end
    end)

    conn2 = UserInputService.InputEnded:Connect(function(inp)
        if not isSameInput(inp, input) then return end
        conn1:Disconnect()
        conn2:Disconnect()
        if moved then
            local endPos = obj.Position
            pushHistory(
                function() obj.Position = startObjPos; if obj == selected then showSelectionVisual() end end,
                function() obj.Position = endPos; if obj == selected then showSelectionVisual() end end
            )
        end
    end)
end

beginResize = function(obj, input)
    local startSize = obj.Size
    local startInputPos = input.Position
    local rad = math.rad(obj.Rotation)
    local cosA, sinA = math.cos(rad), math.sin(rad)
    local conn1, conn2

    conn1 = UserInputService.InputChanged:Connect(function(inp)
        if not isSameInput(inp, input) then return end
        local scale = getStageScale()
        local raw = (inp.Position - startInputPos) / scale
        local localDX = raw.X * cosA + raw.Y * sinA
        local localDY = -raw.X * sinA + raw.Y * cosA
        local newW = clamp(startSize.X.Offset + localDX, 16, 3000)
        local newH = clamp(startSize.Y.Offset + localDY, 16, 3000)
        if snapEnabled then
            newW = round(newW / gridSize) * gridSize
            newH = round(newH / gridSize) * gridSize
        end
        obj.Size = UDim2.new(startSize.X.Scale, newW, startSize.Y.Scale, newH)
        showSelectionVisual()
    end)

    conn2 = UserInputService.InputEnded:Connect(function(inp)
        if not isSameInput(inp, input) then return end
        conn1:Disconnect()
        conn2:Disconnect()
        local endSize = obj.Size
        pushHistory(
            function() obj.Size = startSize; showSelectionVisual() end,
            function() obj.Size = endSize; showSelectionVisual() end
        )
    end)
end

beginRotate = function(obj, input)
    local startRotation = obj.Rotation
    local center = obj.AbsolutePosition + obj.AbsoluteSize / 2
    local startAngle = math.deg(math.atan2(input.Position.Y - center.Y, input.Position.X - center.X))
    local conn1, conn2

    conn1 = UserInputService.InputChanged:Connect(function(inp)
        if not isSameInput(inp, input) then return end
        local angle = math.deg(math.atan2(inp.Position.Y - center.Y, inp.Position.X - center.X))
        local newRotation = startRotation + (angle - startAngle)
        if snapEnabled then newRotation = round(newRotation / 15) * 15 end
        obj.Rotation = newRotation
        showSelectionVisual()
    end)

    conn2 = UserInputService.InputEnded:Connect(function(inp)
        if not isSameInput(inp, input) then return end
        conn1:Disconnect()
        conn2:Disconnect()
        local endRotation = obj.Rotation
        pushHistory(
            function() obj.Rotation = startRotation; showSelectionVisual() end,
            function() obj.Rotation = endRotation; showSelectionVisual() end
        )
    end)
end

local function connectSelectable(obj)
    if not obj:IsA("GuiObject") then return end
    obj.Active = true
    obj.InputBegan:Connect(function(input)
        if panel then return end
        if isLocked(obj) then return end
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            setSelected(obj)
            beginDrag(obj, input)
        end
    end)
end

--// Element library -------------------------------------------------------------
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
    Frame = function() return {BackgroundColor3=Color3.fromRGB(54,60,76), Size=UDim2.fromOffset(180,100)} end,
    TextLabel = function() return {BackgroundTransparency=1, Size=UDim2.fromOffset(190,42), Text="Texto", Font=Enum.Font.GothamBold, TextSize=20, TextColor3=Color3.new(1,1,1), TextXAlignment=Enum.TextXAlignment.Center, TextYAlignment=Enum.TextYAlignment.Center} end,
    TextButton = function() return {BackgroundColor3=C.accent2, Size=UDim2.fromOffset(180,50), Text="Botão", Font=Enum.Font.GothamBold, TextSize=17, TextColor3=Color3.new(1,1,1), AutoButtonColor=false, TextXAlignment=Enum.TextXAlignment.Center, TextYAlignment=Enum.TextYAlignment.Center} end,
    TextBox = function() return {BackgroundColor3=Color3.fromRGB(42,47,60), Size=UDim2.fromOffset(190,50), Text="", PlaceholderText="Digite aqui...", ClearTextOnFocus=false, Font=Enum.Font.GothamMedium, TextSize=16, TextColor3=Color3.new(1,1,1)} end,
    ImageLabel = function() return {BackgroundColor3=Color3.fromRGB(34,39,50), Size=UDim2.fromOffset(170,120), Image=""} end,
    ImageButton = function() return {BackgroundColor3=Color3.fromRGB(34,39,50), Size=UDim2.fromOffset(170,120), Image="", AutoButtonColor=false} end,
    ScrollingFrame = function() return {BackgroundColor3=Color3.fromRGB(32,37,48), Size=UDim2.fromOffset(200,150), CanvasSize=UDim2.fromOffset(0,450), ScrollBarThickness=5, ScrollBarImageColor3=C.accent} end,
    ViewportFrame = function() return {BackgroundColor3=Color3.fromRGB(25,28,36), Size=UDim2.fromOffset(190,150)} end,
    CanvasGroup = function() return {BackgroundColor3=Color3.fromRGB(43,48,62), Size=UDim2.fromOffset(180,100), GroupTransparency=0} end,
    VideoFrame = function() return {BackgroundColor3=Color3.fromRGB(18,20,25), Size=UDim2.fromOffset(200,130), Video=""} end,
}

local function uniqueName(base, parent)
    local n, name = 1, base
    while parent:FindFirstChild(name) do
        n += 1
        name = base .. n
    end
    return name
end

local function rememberRecent(className)
    for i = #recentClasses, 1, -1 do
        if recentClasses[i] == className then table.remove(recentClasses, i) end
    end
    table.insert(recentClasses, 1, className)
    while #recentClasses > 5 do table.remove(recentClasses) end
end

local function createElement(className)
    local parentObj = DesignRoot
    if selected and selected:IsA("GuiObject") and selected ~= EmptyHint and selected ~= DesignRoot and not isLocked(selected) then
        parentObj = selected
    end

    local obj = Instance.new(className)
    obj.Name = uniqueName(className, parentObj)
    local props = defaultProps[className] and defaultProps[className]() or {}
    for k, v in pairs(props) do safeSet(obj, k, v) end
    obj.Position = UDim2.fromOffset(18,18)
    obj.ZIndex = clamp((selected and selected.ZIndex or 5) + 1, 1, 999)
    obj.Parent = parentObj

    if className ~= "TextLabel" then corner(obj, 10) else corner(obj, 6) end

    connectSelectable(obj)
    setSelected(obj)
    EmptyHint.Visible = false
    rememberRecent(className)

    pushHistory(
        function()
            if selected == obj then setSelected(nil) end
            obj.Parent = nil
        end,
        function()
            obj.Parent = parentObj
            connectSelectable(obj)
            setSelected(obj)
        end
    )
    return obj
end

--// Properties (INSPECT) --------------------------------------------------------
refreshProperties = function()
    if currentTab ~= "INSPECT" or not panelBody then return end
    disconnectAll(connections)
    for _, child in ipairs(panelBody:GetChildren()) do
        if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then child:Destroy() end
    end

    if not selected then
        addTag(panelBody, "SELECIONE UM ELEMENTO NO CANVAS")
        button(panelBody, "☷  ABRIR CAMADAS", function() openTab("LAYERS") end)
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
    compactRow(panelBody, "ROTAÇÃO", tostring(round(selected.Rotation)), function() selected.Rotation -= 5; refreshProperties() end, function() selected.Rotation += 5; refreshProperties() end)
    compactRow(panelBody, "ZINDEX", tostring(selected.ZIndex), function() selected.ZIndex = clamp(selected.ZIndex-1,0,999) end, function() selected.ZIndex = clamp(selected.ZIndex+1,0,999) end)

    section(panelBody, "POSIÇÃO / TAMANHO")
    compactRow(panelBody, "X", tostring(round(selected.Position.X.Offset)), function() selected.Position = UDim2.new(selected.Position.X.Scale, selected.Position.X.Offset-5, selected.Position.Y.Scale, selected.Position.Y.Offset); showSelectionVisual() end, function() selected.Position = UDim2.new(selected.Position.X.Scale, selected.Position.X.Offset+5, selected.Position.Y.Scale, selected.Position.Y.Offset); showSelectionVisual() end)
    compactRow(panelBody, "Y", tostring(round(selected.Position.Y.Offset)), function() selected.Position = UDim2.new(selected.Position.X.Scale, selected.Position.X.Offset, selected.Position.Y.Scale, selected.Position.Y.Offset-5); showSelectionVisual() end, function() selected.Position = UDim2.new(selected.Position.X.Scale, selected.Position.X.Offset, selected.Position.Y.Scale, selected.Position.Y.Offset+5); showSelectionVisual() end)
    compactRow(panelBody, "LARGURA", tostring(round(selected.Size.X.Offset)), function() selected.Size = UDim2.new(selected.Size.X.Scale, clamp(selected.Size.X.Offset-5,5,2000), selected.Size.Y.Scale, selected.Size.Y.Offset); showSelectionVisual() end, function() selected.Size = UDim2.new(selected.Size.X.Scale, clamp(selected.Size.X.Offset+5,5,2000), selected.Size.Y.Scale, selected.Size.Y.Offset); showSelectionVisual() end)
    compactRow(panelBody, "ALTURA", tostring(round(selected.Size.Y.Offset)), function() selected.Size = UDim2.new(selected.Size.X.Scale, selected.Size.X.Offset, selected.Size.Y.Scale, clamp(selected.Size.Y.Offset-5,5,2000)); showSelectionVisual() end, function() selected.Size = UDim2.new(selected.Size.X.Scale, selected.Size.X.Offset, selected.Size.Y.Scale, clamp(selected.Size.Y.Offset+5,5,2000)); showSelectionVisual() end)

    section(panelBody, "AÇÕES")
    button(panelBody, "▣  DUPLICAR", function()
        local original = selected
        local clone = original:Clone()
        clone.Name = uniqueName(original.Name, original.Parent)
        clone.Position = original.Position + UDim2.fromOffset(18,18)
        clone.Parent = original.Parent
        for _, d in ipairs(clone:GetDescendants()) do if d:IsA("GuiObject") then connectSelectable(d) end end
        connectSelectable(clone)
        setSelected(clone)
        refreshProperties()
        pushHistory(
            function() if selected == clone then setSelected(nil) end; clone.Parent = nil end,
            function() clone.Parent = original.Parent; connectSelectable(clone); setSelected(clone) end
        )
    end)
    local lockBtn
    lockBtn = button(panelBody, isLocked(selected) and "🔓  DESTRAVAR" or "🔒  TRAVAR", function()
        selected:SetAttribute("NORLI_Locked", not isLocked(selected))
        refreshProperties()
    end)
    button(panelBody, "✕  APAGAR", function()
        local old = selected
        local oldParent = old.Parent
        setSelected(nil)
        old.Parent = nil
        pushHistory(
            function() old.Parent = oldParent end,
            function() if selected == old then setSelected(nil) end; old.Parent = nil end
        )
        refreshProperties()
    end)
    button(panelBody, "☷  CAMADAS", function() openTab("LAYERS") end)

    section(panelBody, "VISIBILIDADE")
    boolSwitch(panelBody, "VISÍVEL", selected.Visible, function(v) selected.Visible = v end)
    boolSwitch(panelBody, "CLIPS DESCENDENTES", selected.ClipsDescendants, function(v) selected.ClipsDescendants = v end)
    boolSwitch(panelBody, "ATIVO", selected.Active, function(v) selected.Active = v end)

    if selected:IsA("GuiButton") then
        section(panelBody, "BOTÃO")
        boolSwitch(panelBody, "INTERACTABLE", safeGet(selected,"Interactable") == true, function(v) safeSet(selected,"Interactable",v) end)
    end
end

--// Layers (CAMADAS) --------------------------------------------------------------
local function layerRow(parent, obj, depth)
    local card = make("Frame", {Size = UDim2.new(1,0,0,72), BackgroundColor3 = (obj == selected) and C.accent2 or C.card, BorderSizePixel = 0, ZIndex = 203}, parent)
    corner(card, 10)

    local icon = ({
        Frame="▣", TextLabel="T", TextButton="▣", TextBox="⌨", ImageLabel="▧",
        ImageButton="◈", ScrollingFrame="▤", ViewportFrame="◉", CanvasGroup="◫", VideoFrame="▶",
    })[obj.ClassName] or "•"

    local nameBtn = make("TextButton", {
        Size = UDim2.new(1,-14,0,26), Position = UDim2.new(0,7+depth*12,0,6), BackgroundTransparency = 1,
        AutoButtonColor = false, Text = icon .. "  " .. obj.Name, Font = Enum.Font.GothamBold, TextSize = 10,
        TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 204,
    }, card)
    nameBtn.Activated:Connect(function() setSelected(obj); refreshLayers() end)

    local strip = make("Frame", {Size = UDim2.new(1,-14,0,30), Position = UDim2.new(0,7,0,36), BackgroundTransparency = 1, ZIndex = 204}, card)
    make("UIListLayout", {FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,4), SortOrder=Enum.SortOrder.LayoutOrder}, strip)

    local function miniBtn(text, bg)
        local b = make("TextButton", {Size=UDim2.new(0,0,1,0), BackgroundColor3 = bg or C.surface2, BorderSizePixel=0, AutoButtonColor=false, Text=text, Font=Enum.Font.GothamBold, TextSize=11, TextColor3=C.text, ZIndex=205}, strip)
        corner(b, 7)
        return b
    end

    local locked = isLocked(obj)
    local lockBtn = miniBtn(locked and "🔒" or "🔓")
    lockBtn.Size = UDim2.new(0,36,1,0)
    lockBtn.Activated:Connect(function() obj:SetAttribute("NORLI_Locked", not locked); refreshLayers() end)

    local visBtn = miniBtn(obj.Visible and "👁" or "🚫")
    visBtn.Size = UDim2.new(0,36,1,0)
    visBtn.Activated:Connect(function() obj.Visible = not obj.Visible; refreshLayers() end)

    local upBtn = miniBtn("▲")
    upBtn.Size = UDim2.new(0,36,1,0)
    upBtn.Activated:Connect(function() obj.ZIndex = clamp(obj.ZIndex+1,0,999); flashStatus("CAMADA PARA FRENTE", C.accent) end)

    local downBtn = miniBtn("▼")
    downBtn.Size = UDim2.new(0,36,1,0)
    downBtn.Activated:Connect(function() obj.ZIndex = clamp(obj.ZIndex-1,0,999); flashStatus("CAMADA PARA TRÁS", C.accent) end)

    local delBtn = miniBtn("✕", C.red)
    delBtn.Size = UDim2.new(0,36,1,0)
    delBtn.Activated:Connect(function()
        local oldParent = obj.Parent
        if selected == obj then setSelected(nil) end
        obj.Parent = nil
        pushHistory(function() obj.Parent = oldParent end, function() obj.Parent = nil end)
        refreshLayers()
    end)
end

local function openLayers()
    local body = createDrawer("CAMADAS  •  hierarquia da interface")
    refreshLayers = function()
        if currentTab ~= "LAYERS" or not panelBody then return end
        for _, c in ipairs(panelBody:GetChildren()) do
            if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end
        end
        local items = {}
        local function scan(p, depth)
            for _, child in ipairs(p:GetChildren()) do
                if child:IsA("GuiObject") and child ~= EmptyHint and child.Name ~= "NORLI_Selection" then
                    table.insert(items, {obj = child, depth = depth})
                    scan(child, depth + 1)
                end
            end
        end
        scan(DesignRoot, 0)
        if #items == 0 then
            addTag(panelBody, "NENHUM ELEMENTO AINDA — vá em OBJETOS")
            return
        end
        addTag(panelBody, tostring(#items) .. " elemento(s)")
        for _, item in ipairs(items) do
            layerRow(panelBody, item.obj, item.depth)
        end
    end
    refreshLayers()
end

--// Elements (OBJETOS) with search + recent --------------------------------------
local function openElements()
    local body = createDrawer("OBJETOS  •  escolha pelo símbolo")
    addTag(body, "Se houver um elemento selecionado (e destravado), o novo vira filho dele.")

    local search = textBox(body, "BUSCAR", "", function() end, "ex.: botão, imagem, scroll")

    local recentSection = section(body, "USADOS RECENTEMENTE")
    local recentGrid = make("Frame", {Size=UDim2.new(1,0,0,60), BackgroundTransparency=1, ZIndex=202}, body)
    make("UIGridLayout", {CellSize=UDim2.new(0.48,0,0,60), CellPadding=UDim2.new(0,7,0,7), HorizontalAlignment=Enum.HorizontalAlignment.Center, SortOrder=Enum.SortOrder.LayoutOrder}, recentGrid)

    section(body, "TODOS OS ELEMENTOS")
    local grid = make("Frame", {Size=UDim2.new(1,0,0,360), BackgroundTransparency=1, ZIndex=202}, body)
    local gridLayout = make("UIGridLayout", {CellSize=UDim2.new(0.48,0,0,60), CellPadding=UDim2.new(0,7,0,7), HorizontalAlignment=Enum.HorizontalAlignment.Center, SortOrder=Enum.SortOrder.LayoutOrder}, grid)

    local function elementCard(parent, info)
        local card = make("TextButton", {BackgroundColor3=C.card, BorderSizePixel=0, Text="", AutoButtonColor=false, ZIndex=203}, parent)
        corner(card, 10)
        make("TextLabel", {Size=UDim2.new(0,40,1,0), Position=UDim2.new(0,8,0,0), BackgroundTransparency=1, Text=info.icon, Font=Enum.Font.GothamBold, TextSize=20, TextColor3=C.accent, ZIndex=204}, card)
        make("TextLabel", {Size=UDim2.new(1,-58,0,22), Position=UDim2.new(0,54,0,8), BackgroundTransparency=1, Text=info.label, Font=Enum.Font.GothamBold, TextSize=10, TextColor3=C.text, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=204}, card)
        make("TextLabel", {Size=UDim2.new(1,-58,0,19), Position=UDim2.new(0,54,0,29), BackgroundTransparency=1, Text=info.desc, Font=Enum.Font.GothamMedium, TextSize=8, TextColor3=C.muted, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=204}, card)
        card.Activated:Connect(function() createElement(info.class) end)
    end

    local elementByClass = {}
    for _, info in ipairs(elements) do elementByClass[info.class] = info end

    local function rebuildRecent()
        for _, c in ipairs(recentGrid:GetChildren()) do if c:IsA("GuiButton") then c:Destroy() end end
        if #recentClasses == 0 then
            recentSection.Visible = false
            recentGrid.Visible = false
            return
        end
        recentSection.Visible = true
        recentGrid.Visible = true
        for _, className in ipairs(recentClasses) do
            local info = elementByClass[className]
            if info then elementCard(recentGrid, info) end
        end
    end

    local function rebuildGrid(filterText)
        for _, c in ipairs(grid:GetChildren()) do if c:IsA("GuiButton") then c:Destroy() end end
        filterText = tostring(filterText or ""):lower()
        local shown = 0
        for _, info in ipairs(elements) do
            if filterText == "" or info.label:lower():find(filterText, 1, true) or info.class:lower():find(filterText, 1, true) then
                elementCard(grid, info)
                shown += 1
            end
        end
        grid.Size = UDim2.new(1,0,0, math.ceil(shown/2) * 67)
    end

    search:GetPropertyChangedSignal("Text"):Connect(function() rebuildGrid(search.Text) end)
    rebuildRecent()
    rebuildGrid("")

    section(body, "CONTROLES GUI AVANÇADOS")
    button(body, "◫ CANVAS GROUP", function() createElement("CanvasGroup") end)
    button(body, "◉ VIEWPORT 3D", function() createElement("ViewportFrame") end)
    button(body, "▶ VIDEO FRAME", function() createElement("VideoFrame") end)
end

--// Style panel (ESTILO) ----------------------------------------------------------
local function openStyle()
    local body = createDrawer("ESTILO  •  CORES / FONTES / EFEITOS")
    section(body,"COR ATIVA")
    addTag(body,"Escolha o alvo e depois toque em uma cor")
    local targetRow = make("Frame", {Size=UDim2.new(1,0,0,39), BackgroundTransparency=1, ZIndex=202}, body)
    local targets = {
        {key="BackgroundColor3", label="FUNDO"}, {key="TextColor3", label="TEXTO"},
        {key="Stroke", label="BORDA"}, {key="ImageColor3", label="IMAGEM"},
    }
    for i,t in ipairs(targets) do
        local b = button(targetRow, t.label, function() colorTarget=t.key end, 34)
        b.Size = UDim2.new(0.25,-3,0,34)
        b.Position = UDim2.new((i-1)*0.25,0,0,0)
    end

    section(body,"PALETA")
    local gridFrame = make("Frame", {Size=UDim2.new(1,0,0,268), BackgroundTransparency=1, ZIndex=202}, body)
    make("UIGridLayout", {CellSize=UDim2.new(0,29,0,29), CellPadding=UDim2.new(0,5,0,5), FillDirectionMaxCells=7, HorizontalAlignment=Enum.HorizontalAlignment.Center, SortOrder=Enum.SortOrder.LayoutOrder}, gridFrame)
    for _, col in ipairs(Palette) do
        local sw = make("TextButton", {Size=UDim2.fromOffset(29,29), BackgroundColor3=col, BorderSizePixel=0, Text="", AutoButtonColor=false, ZIndex=203}, gridFrame)
        corner(sw,8)
        sw.Activated:Connect(function()
            if not selected then return end
            local before
            if colorTarget == "Stroke" then
                local s = ensureStroke(selected)
                before = s.Color
                s.Color = col
                s.Transparency = 0
            elseif safeGet(selected,colorTarget) ~= nil then
                before = safeGet(selected,colorTarget)
                safeSet(selected,colorTarget,col)
            end
            showSelectionVisual()
            if before then
                local target, key = selected, colorTarget
                pushHistory(function()
                    if key == "Stroke" then ensureStroke(target).Color = before else safeSet(target,key,before) end
                end, function()
                    if key == "Stroke" then ensureStroke(target).Color = col else safeSet(target,key,col) end
                end)
            end
        end)
    end

    if selected and selected:IsA("GuiObject") then
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

--// Move panel (precision nudge, complements dragging) ---------------------------
local function openMove()
    local body = createDrawer("MOVER  •  AJUSTE FINO")
    if not selected then
        addTag(body,"Selecione um elemento primeiro (ou arraste-o direto no canvas).")
        return
    end
    addTag(body,selected.Name .. "  —  dica: também dá pra arrastar com o dedo no canvas")
    local pad = make("Frame", {Size=UDim2.new(1,0,0,175), BackgroundTransparency=1, ZIndex=202}, body)
    section(body,"PASSO")
    local stepValue=5
    compactRow(body,"PIXELS",tostring(stepValue),function() stepValue=clamp(stepValue-1,1,50) end,function() stepValue=clamp(stepValue+1,1,50) end)
    local function dynamic(txt,x,y,dx,dy)
        local b=button(pad,txt,function()
            local p=selected.Position
            local before = p
            selected.Position=UDim2.new(p.X.Scale,p.X.Offset+dx*stepValue,p.Y.Scale,p.Y.Offset+dy*stepValue)
            local after = selected.Position
            showSelectionVisual()
            local target = selected
            pushHistory(function() target.Position=before; if target==selected then showSelectionVisual() end end,
                        function() target.Position=after; if target==selected then showSelectionVisual() end end)
        end,48)
        b.Size=UDim2.fromOffset(62,44); b.Position=UDim2.new(0,x,0,y)
    end
    dynamic("▲",104,3,0,-1); dynamic("◀",38,54,-1,0); dynamic("▶",170,54,1,0); dynamic("▼",104,105,0,1)

    section(body,"TAMANHO")
    compactRow(body,"LARGURA",tostring(round(selected.Size.X.Offset)),function() selected.Size=UDim2.new(selected.Size.X.Scale,clamp(selected.Size.X.Offset-5,5,2000),selected.Size.Y.Scale,selected.Size.Y.Offset) end,function() selected.Size=UDim2.new(selected.Size.X.Scale,clamp(selected.Size.X.Offset+5,5,2000),selected.Size.Y.Scale,selected.Size.Y.Offset) end)
    compactRow(body,"ALTURA",tostring(round(selected.Size.Y.Offset)),function() selected.Size=UDim2.new(selected.Size.X.Scale,selected.Size.X.Offset,selected.Size.Y.Scale,clamp(selected.Size.Y.Offset-5,5,2000)) end,function() selected.Size=UDim2.new(selected.Size.X.Scale,selected.Size.X.Offset,selected.Size.Y.Scale,clamp(selected.Size.Y.Offset+5,5,2000)) end)
end

--// Assets panel ------------------------------------------------------------------
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

--// Serialization (export to game + save/load project) ---------------------------
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

-- skipNames: which named children to skip when walking the tree (editor-only helpers)
local function shouldSkip(obj)
    if obj.Name == "NORLI_Selection" or obj.Name == "NORLI_Corner" then return true end
    if obj == EmptyHint then return true end
    if not (obj:IsA("GuiObject") or obj:IsA("UICorner") or obj:IsA("UIStroke") or obj:IsA("UIGradient") or obj:IsA("UIPadding")
        or obj:IsA("UIAspectRatioConstraint") or obj:IsA("UISizeConstraint") or obj:IsA("UIScale") or obj:IsA("UIListLayout")
        or obj:IsA("UIGridLayout") or obj:IsA("UIPageLayout")) then return true end
    return false
end

local function serializeTree(lines, obj, parentExpr, vars, indexRef)
    if shouldSkip(obj) then return end
    indexRef.n += 1
    local var = "obj" .. indexRef.n
    vars[obj] = var
    table.insert(lines, "local "..var.." = Instance.new("..luaString(obj.ClassName)..")")
    if obj:IsA("GuiObject") then
        appendProps(lines,var,obj,exportGuiProps)
        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then appendProps(lines,var,obj,exportTextProps) end
        if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then appendProps(lines,var,obj,exportImageProps) end
        if obj:IsA("ScrollingFrame") then appendProps(lines,var,obj,exportScrollProps) end
        if obj:IsA("TextButton") or obj:IsA("ImageButton") then
            local interact=safeGet(obj,"Interactable")
            if interact~=nil then table.insert(lines, var..".Interactable = "..ser(interact)) end
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
    table.insert(lines, var..".Parent = "..parentExpr)
    table.insert(lines, "")
    for _,child in ipairs(obj:GetChildren()) do
        serializeTree(lines, child, var, vars, indexRef)
    end
end

local function exportLua()
    local lines={}
    table.insert(lines,"-- NORLI GUI STUDIO V3 EXPORT")
    table.insert(lines,"local Players = game:GetService(\"Players\")")
    table.insert(lines,"local player = Players.LocalPlayer")
    table.insert(lines,"local playerGui = player:WaitForChild(\"PlayerGui\")")
    table.insert(lines,"local old = playerGui:FindFirstChild(\"NORLI_EXPORTED_GUI\")")
    table.insert(lines,"if old then old:Destroy() end")
    table.insert(lines,"local gui = Instance.new(\"ScreenGui\")")
    table.insert(lines,"gui.Name = \"NORLI_EXPORTED_GUI\"")
    table.insert(lines,"gui.IgnoreGuiInset = true")
    table.insert(lines,"gui.ResetOnSpawn = false")
    table.insert(lines,"gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling")
    table.insert(lines,"gui.Parent = playerGui")
    table.insert(lines,"")
    local vars, indexRef = {}, {n=0}
    for _,obj in ipairs(DesignRoot:GetChildren()) do
        if obj:IsA("GuiObject") and obj ~= EmptyHint then
            serializeTree(lines, obj, "gui", vars, indexRef)
        end
    end
    table.insert(lines,"print(\"NORLI GUI export concluído\")")
    return table.concat(lines,"\n")
end

local function exportProjectBuilder()
    local lines={}
    table.insert(lines,"-- NORLI GUI STUDIO V3 — PROJETO SALVO")
    table.insert(lines,"-- Cole este código na aba PROJETO > CARREGAR PROJETO para restaurar.")
    table.insert(lines,"return function(root)")
    local vars, indexRef = {}, {n=0}
    local bodyLines = {}
    for _,obj in ipairs(DesignRoot:GetChildren()) do
        if obj:IsA("GuiObject") and obj ~= EmptyHint then
            serializeTree(bodyLines, obj, "root", vars, indexRef)
        end
    end
    for _,line in ipairs(bodyLines) do
        table.insert(lines, line == "" and "" or ("    " .. line))
    end
    table.insert(lines,"end")
    return table.concat(lines,"\n")
end

--// PROJETO panel: export / save / load / new -------------------------------------
local function clearCanvas()
    for _, child in ipairs(DesignRoot:GetChildren()) do
        if child ~= EmptyHint and child ~= ZoomScale then
            pcall(function() child:Destroy() end)
        end
    end
    setSelected(nil)
    EmptyHint.Visible = true
end

local function importProject(code)
    local ls = getLoadstring()
    if not ls then
        flashStatus("SEU EXECUTOR NÃO TEM loadstring", C.red, 2)
        return
    end
    local fn, err = ls(code)
    if not fn then
        flashStatus("ERRO DE SINTAXE NO CÓDIGO", C.red, 2)
        return
    end
    local ok, builder = pcall(fn)
    if not ok or type(builder) ~= "function" then
        flashStatus("PROJETO INVÁLIDO", C.red, 2)
        return
    end
    clearCanvas()
    local ok2, err2 = pcall(builder, DesignRoot)
    if not ok2 then
        flashStatus("ERRO AO CONSTRUIR PROJETO", C.red, 2)
        return
    end
    for _, d in ipairs(DesignRoot:GetDescendants()) do
        if d:IsA("GuiObject") and d.Name ~= "NORLI_Selection" then connectSelectable(d) end
    end
    EmptyHint.Visible = (#DesignRoot:GetChildren() <= 2)
    table.clear(undoStack)
    table.clear(redoStack)
    flashStatus("PROJETO CARREGADO", C.green, 1.6)
end

local function openProject()
    local body = createDrawer("PROJETO  •  exportar / salvar / carregar")

    section(body, "EXPORTAR PARA O JOGO")
    addTag(body,"Gera um script Lua pronto para colocar no seu jogo (cria a interface de verdade, fora do editor).")
    local exportBox = make("TextBox",{Size=UDim2.new(1,0,0,220),BackgroundColor3=Color3.fromRGB(10,12,16),BorderSizePixel=0,Text=exportLua(),Font=Enum.Font.Code,TextSize=9,TextColor3=Color3.fromRGB(225,231,240),TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,MultiLine=true,ClearTextOnFocus=false,TextWrapped=false,ZIndex=203},body)
    corner(exportBox,10)
    button(body,"⧉  COPIAR SCRIPT DO JOGO",function()
        if safeClipboard(exportBox.Text) then
            flashStatus("SCRIPT COPIADO", C.green)
        else
            exportBox:CaptureFocus()
            exportBox.CursorPosition = #exportBox.Text + 1
            flashStatus("SELECIONE E COPIE MANUALMENTE", C.muted, 2)
        end
    end)
    button(body,"↻  ATUALIZAR",function() openProject() end)

    section(body, "SALVAR PROJETO (ÁREA DE TRANSFERÊNCIA)")
    addTag(body,"Copia um código compacto do seu projeto para colar depois e continuar de onde parou.")
    button(body,"💾  SALVAR PROJETO",function()
        local code = exportProjectBuilder()
        if safeClipboard(code) then
            flashStatus("PROJETO COPIADO — cole em um bloco de notas", C.green, 2)
        else
            flashStatus("EXECUTOR SEM setclipboard — use CARREGAR abaixo", C.amber, 2)
        end
    end)

    section(body, "CARREGAR PROJETO")
    addTag(body,"Cole abaixo o código salvo anteriormente e toque em importar. Isso substitui o canvas atual.")
    local importBox = textBox(body, "COLE O CÓDIGO DO PROJETO AQUI", "", function() end, "cole aqui...", true)
    local importBtn
    local armed = false
    importBtn = button(body,"⤓  IMPORTAR PROJETO",function()
        if importBox.Text == "" then flashStatus("COLE UM CÓDIGO PRIMEIRO", C.muted); return end
        if not armed then
            armed = true
            importBtn.Text = "⚠  TOQUE DE NOVO PARA CONFIRMAR (APAGA O CANVAS)"
            importBtn.BackgroundColor3 = C.amber
            task.delay(4, function()
                if importBtn.Parent then
                    armed = false
                    importBtn.Text = "⤓  IMPORTAR PROJETO"
                    importBtn.BackgroundColor3 = C.card
                end
            end)
            return
        end
        armed = false
        importBtn.Text = "⤓  IMPORTAR PROJETO"
        importBtn.BackgroundColor3 = C.card
        importProject(importBox.Text)
    end)

    section(body, "NOVO PROJETO")
    local newBtn
    local newArmed = false
    newBtn = button(body,"🗑  LIMPAR CANVAS (NOVO PROJETO)",function()
        if not newArmed then
            newArmed = true
            newBtn.Text = "⚠  TOQUE DE NOVO PARA CONFIRMAR"
            newBtn.BackgroundColor3 = C.amber
            task.delay(4, function()
                if newBtn.Parent then
                    newArmed = false
                    newBtn.Text = "🗑  LIMPAR CANVAS (NOVO PROJETO)"
                    newBtn.BackgroundColor3 = C.card
                end
            end)
            return
        end
        newArmed = false
        clearCanvas()
        table.clear(undoStack)
        table.clear(redoStack)
        flashStatus("CANVAS LIMPO", C.amber, 1.4)
    end)
end

--// Tab bar (horizontal scroll — fits any number of tabs on mobile) --------------
local Tabs = make("ScrollingFrame", {
    Size=UDim2.new(1,0,0,TABBAR_H), Position=UDim2.new(0,0,1,-TABBAR_H), BackgroundColor3=C.surface,
    BorderSizePixel=0, ZIndex=10, ScrollingDirection=Enum.ScrollingDirection.X, ScrollBarThickness=3,
    ScrollBarImageColor3=C.accent, CanvasSize=UDim2.new(), AutomaticCanvasSize=Enum.AutomaticSize.X,
}, Root)
local tabLayout = make("UIListLayout", {FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,4), VerticalAlignment=Enum.VerticalAlignment.Center, SortOrder=Enum.SortOrder.LayoutOrder}, Tabs)
make("UIPadding", {PaddingLeft=UDim.new(0,4), PaddingRight=UDim.new(0,4)}, Tabs)

local tabInfo={
    {id="ELEMENTS",icon="＋",label="OBJETOS",fn=openElements},
    {id="LAYERS",icon="☰",label="CAMADAS",fn=openLayers},
    {id="INSPECT",icon="☷",label="INSPECT",fn=function() createDrawer("INSPECTOR"); refreshProperties() end},
    {id="STYLE",icon="◈",label="ESTILO",fn=openStyle},
    {id="MOVE",icon="✥",label="MOVER",fn=openMove},
    {id="ASSETS",icon="▧",label="ASSETS",fn=openAssets},
    {id="PROJECT",icon="↗",label="PROJETO",fn=openProject},
}

openTab = function(id)
    if panel then pcall(function() panel:Destroy() end); panel=nil end
    currentTab=id
    for _,info in ipairs(tabInfo) do
        if info.id==id then info.fn(); break end
    end
    for tid, btn in pairs(tabButtons) do
        btn.BackgroundColor3 = (tid == id) and C.accent2 or C.surface2
    end
end

for _,info in ipairs(tabInfo) do
    local b=make("TextButton", {
        Size=UDim2.fromOffset(88,48), LayoutOrder=table.find(tabInfo,info), BackgroundColor3=C.surface2,
        BorderSizePixel=0, AutoButtonColor=false, Text=info.icon.."\n"..info.label, Font=Enum.Font.GothamBold,
        TextSize=8, TextColor3=C.text, TextWrapped=true, ZIndex=11,
    }, Tabs)
    corner(b,10)
    tabButtons[info.id]=b
    b.Activated:Connect(function() openTab(info.id) end)
end

--// Canvas base interactions ------------------------------------------------------
Canvas.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then
        if input.Target==DesignRoot and not panel then setSelected(nil) end
    end
end)

DesignRoot.ChildAdded:Connect(function(child)
    if child:IsA("GuiObject") then connectSelectable(child) end
end)

--// Initial state ------------------------------------------------------------------
EmptyHint.Visible=true
Status.Text="V3  •  MOBILE  •  PRONTO"

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

openTab("ELEMENTS")
