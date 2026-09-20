--[[
    NORLI GUI STUDIO
    V1 - Mobile GUI Builder
    Client-side / Executor friendly

    Recursos da V1:
    • Editor em tela cheia, otimizado para celular
    • Criar: Frame, TextLabel, TextButton, TextBox, ImageLabel,
      ImageButton e ScrollingFrame
    • Selecionar objetos tocando neles
    • Mover com D-Pad: cima / baixo / esquerda / direita
    • Alterar posição, tamanho, nome e ZIndex
    • Frame: cor, transparência, cantos arredondados, borda
    • Texto: texto, fonte, tamanho, cor, stroke e transparência
    • Imagem: Image, transparência e cor
    • Duplicar e apagar
    • Exportar a interface inteira para Lua
    • Tenta copiar automaticamente com setclipboard / toclipboard /
      set_clipboard quando o executor disponibilizar essa função

    Observação:
    O exportador gera a parte visual da GUI. Ele não cria lógica
    automática de botões/eventos, pois esta V1 é focada no design.
]]

--// Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
if not Player then
    return
end

local PlayerGui = Player:WaitForChild("PlayerGui")

--// Cleanup de uma execução anterior
local old = PlayerGui:FindFirstChild("NORLI_GUI_STUDIO")
if old then
    old:Destroy()
end

--// Helpers
local function clamp(n, min, max)
    return math.max(min, math.min(max, n))
end

local function round(n)
    return math.floor(n + 0.5)
end

local function hexToColor3(text, fallback)
    if typeof(text) ~= "string" then
        return fallback
    end

    text = text:gsub("#", ""):gsub("%s", "")
    if #text ~= 6 then
        return fallback
    end

    local r = tonumber(text:sub(1, 2), 16)
    local g = tonumber(text:sub(3, 4), 16)
    local b = tonumber(text:sub(5, 6), 16)

    if not r or not g or not b then
        return fallback
    end

    return Color3.fromRGB(r, g, b)
end

local function colorToHex(c)
    c = c or Color3.new(1, 1, 1)
    return string.format("#%02X%02X%02X", round(c.R * 255), round(c.G * 255), round(c.B * 255))
end

local function safeSetClipboard(textValue)
    local funcs = {
        rawget(_G, "setclipboard"),
        rawget(_G, "toclipboard"),
        rawget(_G, "set_clipboard"),
    }

    for _, fn in ipairs(funcs) do
        if type(fn) == "function" then
            local ok = pcall(fn, textValue)
            if ok then
                return true
            end
        end
    end

    return false
end

local function make(className, props, parent)
    local obj = Instance.new(className)
    for k, v in pairs(props or {}) do
        pcall(function()
            obj[k] = v
        end)
    end
    obj.Parent = parent
    return obj
end

local function corner(parent, radius)
    local c = parent:FindFirstChild("NORLI_Corner")
    if not c then
        c = Instance.new("UICorner")
        c.Name = "NORLI_Corner"
        c.Parent = parent
    end
    c.CornerRadius = UDim.new(0, radius or 10)
    return c
end

local function stroke(parent, color, transparency, thickness)
    local s = parent:FindFirstChild("NORLI_Stroke")
    if not s then
        s = Instance.new("UIStroke")
        s.Name = "NORLI_Stroke"
        s.Parent = parent
    end
    s.Color = color or Color3.new(1, 1, 1)
    s.Transparency = transparency == nil and 0 or transparency
    s.Thickness = thickness or 1
    return s
end

local function tween(obj, props, duration)
    local ok, tw = pcall(function()
        return TweenService:Create(obj, TweenInfo.new(duration or 0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props)
    end)
    if ok and tw then
        tw:Play()
        return tw
    end
end

--// Root GUI
local Gui = make("ScreenGui", {
    Name = "NORLI_GUI_STUDIO",
    IgnoreGuiInset = true,
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 99999,
}, PlayerGui)

--// Palette
local BG = Color3.fromRGB(10, 12, 17)
local PANEL = Color3.fromRGB(20, 23, 31)
local PANEL2 = Color3.fromRGB(28, 32, 42)
local CARD = Color3.fromRGB(34, 39, 50)
local ACCENT = Color3.fromRGB(105, 145, 255)
local ACCENT2 = Color3.fromRGB(85, 118, 225)
local GOOD = Color3.fromRGB(67, 210, 125)
local BAD = Color3.fromRGB(235, 78, 92)
local TEXT = Color3.fromRGB(244, 246, 250)
local MUTED = Color3.fromRGB(160, 168, 184)
local LINE = Color3.fromRGB(55, 61, 76)

--// State
local selected = nil
local creating = false
local moveStep = 10

--// Main shell
local Shell = make("Frame", {
    Name = "Shell",
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = BG,
    BorderSizePixel = 0,
    Active = true,
}, Gui)

-- header
local Header = make("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 58),
    BackgroundColor3 = PANEL,
    BorderSizePixel = 0,
    ZIndex = 20,
}, Shell)
stroke(Header, LINE, 0.35, 1)

local Brand = make("TextLabel", {
    Size = UDim2.new(0, 170, 1, 0),
    Position = UDim2.new(0, 14, 0, 0),
    BackgroundTransparency = 1,
    Text = "NORLI GUI STUDIO",
    Font = Enum.Font.GothamBold,
    TextSize = 17,
    TextColor3 = TEXT,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 21,
}, Header)

local Status = make("TextLabel", {
    Size = UDim2.new(0, 140, 1, 0),
    Position = UDim2.new(0, 182, 0, 0),
    BackgroundTransparency = 1,
    Text = "V1 • MOBILE",
    Font = Enum.Font.GothamMedium,
    TextSize = 11,
    TextColor3 = MUTED,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 21,
}, Header)

local ExportButton = make("TextButton", {
    Size = UDim2.new(0, 122, 0, 38),
    Position = UDim2.new(1, -134, 0.5, -19),
    BackgroundColor3 = GOOD,
    AutoButtonColor = false,
    Text = "EXPORT LUA",
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    TextColor3 = Color3.new(0.05, 0.07, 0.08),
    BorderSizePixel = 0,
    ZIndex = 21,
}, Header)
corner(ExportButton, 11)

-- left toolbar
local Left = make("Frame", {
    Name = "Toolbox",
    Size = UDim2.new(0, 188, 1, -58),
    Position = UDim2.new(0, 0, 0, 58),
    BackgroundColor3 = PANEL,
    BorderSizePixel = 0,
    ZIndex = 15,
}, Shell)

local ToolboxTitle = make("TextLabel", {
    Size = UDim2.new(1, -20, 0, 30),
    Position = UDim2.new(0, 10, 0, 10),
    BackgroundTransparency = 1,
    Text = "ELEMENTOS",
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextColor3 = MUTED,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 16,
}, Left)

local ToolScroll = make("ScrollingFrame", {
    Size = UDim2.new(1, -12, 1, -52),
    Position = UDim2.new(0, 6, 0, 42),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    CanvasSize = UDim2.new(),
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = LINE,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    ZIndex = 16,
}, Left)

local ToolLayout = make("UIListLayout", {
    Padding = UDim.new(0, 7),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, ToolScroll)

make("UIPadding", {
    PaddingTop = UDim.new(0, 3),
    PaddingBottom = UDim.new(0, 8),
    PaddingLeft = UDim.new(0, 4),
    PaddingRight = UDim.new(0, 4),
}, ToolScroll)

-- center design area
local Work = make("Frame", {
    Name = "WorkArea",
    Size = UDim2.new(1, -388, 1, -58),
    Position = UDim2.new(0, 188, 0, 58),
    BackgroundColor3 = Color3.fromRGB(13, 15, 21),
    BorderSizePixel = 0,
    ZIndex = 1,
}, Shell)

local WorkTitle = make("TextLabel", {
    Size = UDim2.new(1, -20, 0, 26),
    Position = UDim2.new(0, 10, 0, 8),
    BackgroundTransparency = 1,
    Text = "CANVAS • toque em um elemento para selecionar",
    Font = Enum.Font.GothamMedium,
    TextSize = 11,
    TextColor3 = MUTED,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 3,
}, Work)

local CanvasHolder = make("Frame", {
    Size = UDim2.new(1, -20, 1, -44),
    Position = UDim2.new(0, 10, 0, 38),
    BackgroundColor3 = Color3.fromRGB(24, 27, 35),
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Active = true,
    ZIndex = 2,
}, Work)
corner(CanvasHolder, 12)
stroke(CanvasHolder, LINE, 0.15, 1)

-- Visual phone-like inner canvas. Interface objects are parented here.
local DesignRoot = make("Frame", {
    Name = "DesignRoot",
    Size = UDim2.new(1, -20, 1, -20),
    Position = UDim2.new(0, 10, 0, 10),
    BackgroundColor3 = Color3.fromRGB(17, 19, 25),
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Active = true,
    ZIndex = 2,
}, CanvasHolder)
corner(DesignRoot, 10)

-- right properties panel
local Right = make("Frame", {
    Name = "Properties",
    Size = UDim2.new(0, 200, 1, -58),
    Position = UDim2.new(1, -200, 0, 58),
    BackgroundColor3 = PANEL,
    BorderSizePixel = 0,
    ZIndex = 15,
}, Shell)

local PropsTitle = make("TextLabel", {
    Size = UDim2.new(1, -18, 0, 30),
    Position = UDim2.new(0, 9, 0, 10),
    BackgroundTransparency = 1,
    Text = "PROPRIEDADES",
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextColor3 = MUTED,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 16,
}, Right)

local SelectedName = make("TextLabel", {
    Size = UDim2.new(1, -18, 0, 32),
    Position = UDim2.new(0, 9, 0, 38),
    BackgroundColor3 = PANEL2,
    Text = "Nenhum objeto",
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextColor3 = TEXT,
    TextXAlignment = Enum.TextXAlignment.Center,
    TextTruncate = Enum.TextTruncate.AtEnd,
    BorderSizePixel = 0,
    ZIndex = 16,
}, Right)
corner(SelectedName, 8)

local PropScroll = make("ScrollingFrame", {
    Size = UDim2.new(1, -10, 1, -82),
    Position = UDim2.new(0, 5, 0, 76),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    CanvasSize = UDim2.new(),
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = LINE,
    ScrollingDirection = Enum.ScrollingDirection.Y,
    ZIndex = 16,
}, Right)

local PropLayout = make("UIListLayout", {
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, PropScroll)

make("UIPadding", {
    PaddingTop = UDim.new(0, 3),
    PaddingBottom = UDim.new(0, 10),
    PaddingLeft = UDim.new(0, 4),
    PaddingRight = UDim.new(0, 4),
}, PropScroll)

-- bottom movement controls
local MovePad = make("Frame", {
    Size = UDim2.new(0, 154, 0, 118),
    Position = UDim2.new(0.5, -77, 1, -130),
    BackgroundColor3 = PANEL,
    BackgroundTransparency = 0.05,
    BorderSizePixel = 0,
    ZIndex = 30,
}, Shell)
corner(MovePad, 15)
stroke(MovePad, LINE, 0.2, 1)

local StepLabel = make("TextLabel", {
    Size = UDim2.new(1, -8, 0, 18),
    Position = UDim2.new(0, 4, 0, 3),
    BackgroundTransparency = 1,
    Text = "MOVE 10 PX",
    Font = Enum.Font.GothamBold,
    TextSize = 9,
    TextColor3 = MUTED,
    ZIndex = 31,
}, MovePad)

local function moveButton(textValue, x, y)
    local b = make("TextButton", {
        Size = UDim2.new(0, 40, 0, 34),
        Position = UDim2.new(0, x, 0, y),
        BackgroundColor3 = PANEL2,
        AutoButtonColor = false,
        Text = textValue,
        Font = Enum.Font.GothamBold,
        TextSize = 17,
        TextColor3 = TEXT,
        BorderSizePixel = 0,
        ZIndex = 31,
    }, MovePad)
    corner(b, 9)
    return b
end

local Up = moveButton("▲", 57, 22)
local LeftMove = moveButton("◀", 14, 63)
local Down = moveButton("▼", 57, 63)
local RightMove = moveButton("▶", 100, 63)

local Hint = make("TextLabel", {
    Size = UDim2.new(0, 250, 0, 25),
    Position = UDim2.new(0.5, -125, 1, -32),
    BackgroundTransparency = 1,
    Text = "Selecione • mova • edite • exporte",
    Font = Enum.Font.GothamMedium,
    TextSize = 10,
    TextColor3 = MUTED,
    TextXAlignment = Enum.TextXAlignment.Center,
    ZIndex = 30,
}, Shell)

--// Property control helpers
local propRows = {}

local function clearProps()
    for _, child in ipairs(PropScroll:GetChildren()) do
        if child:IsA("GuiObject") or child:IsA("UIListLayout") or child:IsA("UIPadding") then
            if child ~= PropLayout and not child:IsA("UIPadding") then
                child:Destroy()
            end
        end
    end
end

local function addLabel(textValue)
    return make("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        Text = textValue,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = MUTED,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 17,
    }, PropScroll)
end

local function addBox(labelText, defaultText, callback, height)
    local wrap = make("Frame", {
        Size = UDim2.new(1, 0, 0, height or 50),
        BackgroundTransparency = 1,
        ZIndex = 17,
    }, PropScroll)

    make("TextLabel", {
        Size = UDim2.new(1, 0, 0, 17),
        BackgroundTransparency = 1,
        Text = labelText,
        Font = Enum.Font.GothamMedium,
        TextSize = 9,
        TextColor3 = MUTED,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 18,
    }, wrap)

    local box = make("TextBox", {
        Size = UDim2.new(1, 0, 0, 29),
        Position = UDim2.new(0, 0, 0, 19),
        BackgroundColor3 = PANEL2,
        Text = tostring(defaultText),
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextColor3 = TEXT,
        PlaceholderColor3 = MUTED,
        ClearTextOnFocus = false,
        BorderSizePixel = 0,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 18,
    }, wrap)
    corner(box, 7)

    box.FocusLost:Connect(function()
        if selected then
            callback(box.Text)
        end
    end)

    return box, wrap
end

local function addButton(textValue, callback)
    local b = make("TextButton", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = PANEL2,
        AutoButtonColor = false,
        Text = textValue,
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = TEXT,
        BorderSizePixel = 0,
        ZIndex = 18,
    }, PropScroll)
    corner(b, 8)
    b.Activated:Connect(callback)
    return b
end

local function addSwitch(textValue, value, callback)
    local b = addButton(textValue .. ": " .. (value and "ON" or "OFF"), function()
        value = not value
        callback(value)
        b.Text = textValue .. ": " .. (value and "ON" or "OFF")
    end)
    return b
end

--// Selection visualization
local SelectionBox
local SelectionStroke

local function clearSelectionVisual()
    if SelectionStroke then
        SelectionStroke:Destroy()
        SelectionStroke = nil
    end
    if SelectionBox then
        SelectionBox:Destroy()
        SelectionBox = nil
    end
end

local function showSelectionVisual()
    clearSelectionVisual()
    if not selected or not selected.Parent then
        return
    end

    SelectionBox = make("Frame", {
        Name = "NORLI_Selection",
        Size = UDim2.new(1, 6, 1, 6),
        Position = UDim2.new(0, -3, 0, -3),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Active = false,
        Selectable = false,
        ZIndex = math.max(selected.ZIndex + 100, 100),
    }, selected)

    SelectionStroke = stroke(SelectionBox, ACCENT, 0, 2)
end

local function setSelected(obj)
    if obj == DesignRoot or (obj and not obj:IsDescendantOf(DesignRoot)) then
        return
    end

    if selected == obj then
        showSelectionVisual()
        return
    end

    clearSelectionVisual()
    selected = obj

    if selected then
        SelectedName.Text = selected.Name
        showSelectionVisual()
    else
        SelectedName.Text = "Nenhum objeto"
    end
end

--// Tool creation
local function connectSelectable(obj)
    if not obj:IsA("GuiObject") then
        return
    end

    obj.Active = true

    obj.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then
            task.defer(function()
                if obj.Parent and obj:IsDescendantOf(DesignRoot) then
                    setSelected(obj)
                end
            end)
        end
    end)
end

local function uniqueName(base)
    local i = 1
    local name = base
    while DesignRoot:FindFirstChild(name) do
        i += 1
        name = base .. i
    end
    return name
end

local function createElement(className)
    local props = {
        BackgroundColor3 = Color3.fromRGB(70, 74, 87),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, -80, 0.5, -45),
        Size = UDim2.new(0, 160, 0, 90),
        ZIndex = 10,
        Active = true,
    }

    if className == "Frame" then
        props.BackgroundColor3 = Color3.fromRGB(54, 60, 76)

    elseif className == "TextLabel" then
        props.BackgroundColor3 = Color3.fromRGB(40, 45, 58)
        props.Text = "TextLabel"
        props.Font = Enum.Font.GothamBold
        props.TextSize = 20
        props.TextColor3 = Color3.new(1, 1, 1)
        props.TextStrokeTransparency = 1
        props.TextXAlignment = Enum.TextXAlignment.Center
        props.TextYAlignment = Enum.TextYAlignment.Center

    elseif className == "TextButton" then
        props.BackgroundColor3 = ACCENT2
        props.Text = "Button"
        props.Font = Enum.Font.GothamBold
        props.TextSize = 18
        props.TextColor3 = Color3.new(1, 1, 1)
        props.TextXAlignment = Enum.TextXAlignment.Center
        props.TextYAlignment = Enum.TextYAlignment.Center
        props.AutoButtonColor = false
        props.Size = UDim2.new(0, 180, 0, 55)

    elseif className == "TextBox" then
        props.BackgroundColor3 = Color3.fromRGB(39, 44, 56)
        props.Text = "TextBox"
        props.Font = Enum.Font.GothamMedium
        props.TextSize = 17
        props.TextColor3 = Color3.new(1, 1, 1)
        props.PlaceholderText = "Digite aqui..."
        props.ClearTextOnFocus = false
        props.Size = UDim2.new(0, 200, 0, 52)

    elseif className == "ImageLabel" then
        props.BackgroundColor3 = Color3.fromRGB(36, 40, 52)
        props.Image = ""
        props.Size = UDim2.new(0, 160, 0, 120)

    elseif className == "ImageButton" then
        props.BackgroundColor3 = Color3.fromRGB(36, 40, 52)
        props.Image = ""
        props.AutoButtonColor = false
        props.Size = UDim2.new(0, 160, 0, 120)

    elseif className == "ScrollingFrame" then
        props.BackgroundColor3 = Color3.fromRGB(35, 39, 50)
        props.Size = UDim2.new(0, 200, 0, 150)
        props.CanvasSize = UDim2.new(0, 0, 0, 500)
        props.ScrollBarThickness = 5
        props.ScrollBarImageColor3 = ACCENT
    end

    local obj = Instance.new(className)
    obj.Name = uniqueName(className)
    for k, v in pairs(props) do
        pcall(function()
            obj[k] = v
        end)
    end
    obj.Parent = DesignRoot

    if obj:IsA("GuiObject") then
        corner(obj, className == "TextButton" or className == "TextBox" and 10 or 8)
        if className == "Frame" then
            stroke(obj, Color3.fromRGB(110, 120, 150), 0.5, 1)
        end
        connectSelectable(obj)
    end

    setSelected(obj)
    return obj
end

local tools = {
    {"＋  FRAME", "Frame"},
    {"T  TEXT LABEL", "TextLabel"},
    {"▣  TEXT BUTTON", "TextButton"},
    {"⌨  TEXT BOX", "TextBox"},
    {"▧  IMAGE LABEL", "ImageLabel"},
    {"▣  IMAGE BUTTON", "ImageButton"},
    {"▤  SCROLLING FRAME", "ScrollingFrame"},
}

for index, item in ipairs(tools) do
    local b = make("TextButton", {
        LayoutOrder = index,
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = CARD,
        AutoButtonColor = false,
        Text = item[1],
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = TEXT,
        BorderSizePixel = 0,
        ZIndex = 17,
    }, ToolScroll)
    corner(b, 9)

    b.Activated:Connect(function()
        createElement(item[2])
        tween(b, {BackgroundColor3 = ACCENT2}, 0.08)
        task.delay(0.12, function()
            if b.Parent then
                tween(b, {BackgroundColor3 = CARD}, 0.1)
            end
        end)
    end)
end

ToolLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ToolScroll.CanvasSize = UDim2.new(0, 0, 0, ToolLayout.AbsoluteContentSize.Y + 12)
end)

--// Properties
local function refreshProperties()
    clearProps()

    if not selected or not selected.Parent then
        SelectedName.Text = "Nenhum objeto"
        return
    end

    SelectedName.Text = selected.Name
    addLabel("GERAL")

    local nameBox = addBox("NAME", selected.Name, function(value)
        value = value:gsub("[^%w_]", "_")
        if value == "" then
            value = "Element"
        end
        selected.Name = value
        SelectedName.Text = value
    end)

    local pos = selected.Position
    addBox("POSITION  X", round(pos.X.Offset), function(value)
        local n = tonumber(value)
        if n then
            selected.Position = UDim2.new(pos.X.Scale, n, pos.Y.Scale, selected.Position.Y.Offset)
            showSelectionVisual()
            refreshProperties()
        end
    end)

    pos = selected.Position
    addBox("POSITION  Y", round(pos.Y.Offset), function(value)
        local n = tonumber(value)
        if n then
            selected.Position = UDim2.new(pos.X.Scale, selected.Position.X.Offset, pos.Y.Scale, n)
            showSelectionVisual()
            refreshProperties()
        end
    end)

    local size = selected.Size
    addBox("SIZE  WIDTH", round(size.X.Offset), function(value)
        local n = tonumber(value)
        if n then
            selected.Size = UDim2.new(size.X.Scale, clamp(n, 5, 2000), size.Y.Scale, selected.Size.Y.Offset)
            showSelectionVisual()
            refreshProperties()
        end
    end)

    size = selected.Size
    addBox("SIZE  HEIGHT", round(size.Y.Offset), function(value)
        local n = tonumber(value)
        if n then
            selected.Size = UDim2.new(size.X.Scale, selected.Size.X.Offset, size.Y.Scale, clamp(n, 5, 2000))
            showSelectionVisual()
            refreshProperties()
        end
    end)

    addBox("ZINDEX", selected.ZIndex, function(value)
        local n = tonumber(value)
        if n then
            selected.ZIndex = clamp(round(n), 0, 1000)
            showSelectionVisual()
        end
    end)

    addLabel("APARÊNCIA")

    addBox("BACKGROUND HEX", colorToHex(selected.BackgroundColor3), function(value)
        selected.BackgroundColor3 = hexToColor3(value, selected.BackgroundColor3)
        refreshProperties()
    end)

    addBox("BACKGROUND TRANSPARENCY 0-1", string.format("%.2f", selected.BackgroundTransparency), function(value)
        local n = tonumber(value)
        if n then
            selected.BackgroundTransparency = clamp(n, 0, 1)
            refreshProperties()
        end
    end)

    local uiCorner = selected:FindFirstChildOfClass("UICorner")
    local radius = uiCorner and uiCorner.CornerRadius.Offset or 0
    addBox("CORNER RADIUS", radius, function(value)
        local n = tonumber(value)
        if n then
            corner(selected, clamp(round(n), 0, 100))
            refreshProperties()
        end
    end)

    local uiStroke = selected:FindFirstChildOfClass("UIStroke")
    local strokeEnabled = uiStroke ~= nil
    addSwitch("OUTLINE", strokeEnabled, function(on)
        if on then
            stroke(selected, Color3.fromRGB(255, 255, 255), 0, 1)
        else
            local s = selected:FindFirstChildOfClass("UIStroke")
            if s then
                s:Destroy()
            end
        end
        refreshProperties()
    end)

    if uiStroke then
        addBox("OUTLINE HEX", colorToHex(uiStroke.Color), function(value)
            local s = selected:FindFirstChildOfClass("UIStroke")
            if s then
                s.Color = hexToColor3(value, s.Color)
            end
            refreshProperties()
        end)

        addBox("OUTLINE THICKNESS", uiStroke.Thickness, function(value)
            local n = tonumber(value)
            local s = selected:FindFirstChildOfClass("UIStroke")
            if s and n then
                s.Thickness = clamp(n, 1, 10)
            end
        end)

        addBox("OUTLINE TRANSPARENCY", string.format("%.2f", uiStroke.Transparency), function(value)
            local n = tonumber(value)
            local s = selected:FindFirstChildOfClass("UIStroke")
            if s and n then
                s.Transparency = clamp(n, 0, 1)
            end
        end)
    end

    if selected:IsA("TextLabel") or selected:IsA("TextButton") or selected:IsA("TextBox") then
        addLabel("TEXTO")

        addBox("TEXT", selected.Text, function(value)
            selected.Text = value
            refreshProperties()
        end, 57)

        addBox("TEXT SIZE", selected.TextSize, function(value)
            local n = tonumber(value)
            if n then
                selected.TextSize = clamp(round(n), 6, 120)
            end
        end)

        addBox("TEXT HEX", colorToHex(selected.TextColor3), function(value)
            selected.TextColor3 = hexToColor3(value, selected.TextColor3)
            refreshProperties()
        end)

        addBox("FONT", selected.Font.Name, function(value)
            local search = value:lower()
            local found = nil
            for _, font in ipairs(Enum.Font:GetEnumItems()) do
                if font.Name:lower() == search then
                    found = font
                    break
                end
            end
            if not found then
                for _, font in ipairs(Enum.Font:GetEnumItems()) do
                    if font.Name:lower():find(search, 1, true) then
                        found = font
                        break
                    end
                end
            end
            if found then
                selected.Font = found
                refreshProperties()
            end
        end)

        addBox("TEXT STROKE HEX", colorToHex(selected.TextStrokeColor3), function(value)
            selected.TextStrokeColor3 = hexToColor3(value, selected.TextStrokeColor3)
            refreshProperties()
        end)

        addBox("TEXT STROKE TRANSPARENCY", string.format("%.2f", selected.TextStrokeTransparency), function(value)
            local n = tonumber(value)
            if n then
                selected.TextStrokeTransparency = clamp(n, 0, 1)
            end
        end)

        addSwitch("TEXT SCALED", selected.TextScaled, function(on)
            selected.TextScaled = on
            refreshProperties()
        end)
    end

    if selected:IsA("ImageLabel") or selected:IsA("ImageButton") then
        addLabel("IMAGEM")

        addBox("IMAGE ID / URI", selected.Image, function(value)
            selected.Image = value
        end, 57)

        addBox("IMAGE TRANSPARENCY", string.format("%.2f", selected.ImageTransparency), function(value)
            local n = tonumber(value)
            if n then
                selected.ImageTransparency = clamp(n, 0, 1)
            end
        end)

        addBox("IMAGE COLOR HEX", colorToHex(selected.ImageColor3), function(value)
            selected.ImageColor3 = hexToColor3(value, selected.ImageColor3)
            refreshProperties()
        end)
    end

    if selected:IsA("ScrollingFrame") then
        addLabel("SCROLL")

        addBox("CANVAS WIDTH", selected.CanvasSize.X.Offset, function(value)
            local n = tonumber(value)
            if n then
                selected.CanvasSize = UDim2.new(selected.CanvasSize.X.Scale, clamp(round(n), 0, 5000), selected.CanvasSize.Y.Scale, selected.CanvasSize.Y.Offset)
                refreshProperties()
            end
        end)

        addBox("CANVAS HEIGHT", selected.CanvasSize.Y.Offset, function(value)
            local n = tonumber(value)
            if n then
                selected.CanvasSize = UDim2.new(selected.CanvasSize.X.Scale, selected.CanvasSize.X.Offset, selected.CanvasSize.Y.Scale, clamp(round(n), 0, 5000))
                refreshProperties()
            end
        end)

        addBox("SCROLLBAR THICKNESS", selected.ScrollBarThickness, function(value)
            local n = tonumber(value)
            if n then
                selected.ScrollBarThickness = clamp(round(n), 0, 30)
            end
        end)
    end

    addLabel("AÇÕES")

    addButton("DUPLICAR", function()
        if not selected then
            return
        end
        local clone = selected:Clone()
        clone.Name = uniqueName(selected.Name .. "_Copy")
        clone.Position = selected.Position + UDim2.new(0, 18, 0, 18)
        clone.Parent = DesignRoot

        for _, d in ipairs(clone:GetDescendants()) do
            if d:IsA("GuiObject") then
                connectSelectable(d)
            end
        end
        connectSelectable(clone)
        setSelected(clone)
        refreshProperties()
    end)

    addButton("APAGAR", function()
        if not selected then
            return
        end
        local oldSelected = selected
        selected = nil
        clearSelectionVisual()
        oldSelected:Destroy()
        refreshProperties()
    end)

    nameBox.Text = selected.Name
end

PropLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    PropScroll.CanvasSize = UDim2.new(0, 0, 0, PropLayout.AbsoluteContentSize.Y + 12)
end)

--// Selection refresh helper
local originalSetSelected = setSelected
setSelected = function(obj)
    originalSetSelected(obj)
    refreshProperties()
end

--// Initial connection for DesignRoot
DesignRoot.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
        if input.Target == DesignRoot then
            setSelected(nil)
        end
    end
end)

--// Movement
local function move(dx, dy)
    if not selected or not selected.Parent then
        return
    end

    local p = selected.Position
    selected.Position = UDim2.new(
        p.X.Scale,
        p.X.Offset + dx,
        p.Y.Scale,
        p.Y.Offset + dy
    )

    showSelectionVisual()
    refreshProperties()
end

Up.Activated:Connect(function() move(0, -moveStep) end)
Down.Activated:Connect(function() move(0, moveStep) end)
LeftMove.Activated:Connect(function() move(-moveStep, 0) end)
RightMove.Activated:Connect(function() move(moveStep, 0) end)

--// Remove selection box from export / cloning side effects
local function sanitizeForExport(instance)
    local clone = instance:Clone()
    for _, d in ipairs(clone:GetDescendants()) do
        if d.Name == "NORLI_Selection" then
            d:Destroy()
        end
    end
    return clone
end

--// Lua serializer
local function luaString(value)
    value = tostring(value)
    value = value:gsub("\\", "\\\\"):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub('"', '\\"')
    return '"' .. value .. '"'
end

local function numberString(n)
    if math.abs(n) < 0.000001 then
        n = 0
    end
    return string.format("%.5f", n):gsub("(%..-)0+$", "%1"):gsub("%.$", "")
end

local function serializeValue(v)
    local t = typeof(v)

    if t == "string" then
        return luaString(v)

    elseif t == "number" then
        return numberString(v)

    elseif t == "boolean" then
        return v and "true" or "false"

    elseif t == "Color3" then
        return string.format(
            "Color3.fromRGB(%d, %d, %d)",
            round(v.R * 255),
            round(v.G * 255),
            round(v.B * 255)
        )

    elseif t == "UDim2" then
        return string.format(
            "UDim2.new(%s, %s, %s, %s)",
            numberString(v.X.Scale),
            numberString(v.X.Offset),
            numberString(v.Y.Scale),
            numberString(v.Y.Offset)
        )

    elseif t == "UDim" then
        return string.format("UDim.new(%s, %s)", numberString(v.Scale), numberString(v.Offset))

    elseif t == "Vector2" then
        return string.format("Vector2.new(%s, %s)", numberString(v.X), numberString(v.Y))

    elseif t == "Vector3" then
        return string.format("Vector3.new(%s, %s, %s)", numberString(v.X), numberString(v.Y), numberString(v.Z))

    elseif t == "BrickColor" then
        return "BrickColor.new(" .. luaString(v.Name) .. ")"

    elseif t == "EnumItem" then
        return tostring(v)

    elseif t == "Font" then
        return "Font.new(" .. luaString(v.Family) .. ")"

    end

    return nil
end

local function isExportable(instance)
    return instance:IsA("GuiObject") or instance:IsA("UICorner") or instance:IsA("UIStroke")
        or instance:IsA("UIPadding") or instance:IsA("UIListLayout") or instance:IsA("UIGridLayout")
        or instance:IsA("UIPageLayout") or instance:IsA("UISizeConstraint")
end

local guiProperties = {
    "Name",
    "Position",
    "Size",
    "AnchorPoint",
    "ZIndex",
    "BackgroundColor3",
    "BackgroundTransparency",
    "BorderColor3",
    "BorderSizePixel",
    "Visible",
    "ClipsDescendants",
    "Rotation",
    "Selectable",
    "Active",
    "AutomaticSize",
}

local textProperties = {
    "Text",
    "Font",
    "TextSize",
    "TextColor3",
    "TextTransparency",
    "TextStrokeColor3",
    "TextStrokeTransparency",
    "TextScaled",
    "TextWrapped",
    "TextXAlignment",
    "TextYAlignment",
    "TextTruncate",
    "RichText",
    "PlaceholderText",
    "PlaceholderColor3",
    "ClearTextOnFocus",
    "MultiLine",
}

local imageProperties = {
    "Image",
    "ImageColor3",
    "ImageTransparency",
    "ResampleMode",
    "ScaleType",
    "SliceCenter",
    "SliceScale",
    "TileSize",
}

local scrollingProperties = {
    "CanvasSize",
    "CanvasPosition",
    "ScrollBarThickness",
    "ScrollBarImageColor3",
    "ScrollBarImageTransparency",
    "ScrollingDirection",
    "ElasticBehavior",
    "HorizontalScrollBarInset",
    "VerticalScrollBarInset",
}

local cornerProperties = {"CornerRadius"}
local strokeProperties = {"Color", "Transparency", "Thickness", "Enabled", "LineJoinMode"}

local function safeGet(instance, prop)
    local ok, value = pcall(function()
        return instance[prop]
    end)
    if ok then
        return value
    end
end

local function appendProperty(lines, indent, instance, prop)
    local value = safeGet(instance, prop)
    local serialized = value and serializeValue(value)

    if serialized then
        table.insert(lines, indent .. "obj." .. prop .. " = " .. serialized)
    end
end

local function sanitizeIdentifier(name)
    name = tostring(name or "Element")
    name = name:gsub("[^%w_]", "_")
    if name == "" then
        name = "Element"
    end
    if name:match("^%d") then
        name = "_" .. name
    end
    return name
end

local function buildExport()
    local cleanRoot = sanitizeForExport(DesignRoot)

    local lines = {}
    local add = function(s)
        table.insert(lines, s)
    end

    add("-- NORLI GUI STUDIO - EXPORT V1")
    add("-- GUI visual export generated automatically.")
    add("")
    add("local Players = game:GetService(\"Players\")")
    add("local player = Players.LocalPlayer")
    add("local playerGui = player:WaitForChild(\"PlayerGui\")")
    add("")
    add("local existing = playerGui:FindFirstChild(\"NORLI_EXPORTED_GUI\")")
    add("if existing then existing:Destroy() end")
    add("")
    add("local gui = Instance.new(\"ScreenGui\")")
    add("gui.Name = \"NORLI_EXPORTED_GUI\"")
    add("gui.IgnoreGuiInset = true")
    add("gui.ResetOnSpawn = false")
    add("gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling")
    add("gui.Parent = playerGui")
    add("")

    local ids = {}
    local counter = 0

    local function register(instance, parentExpr)
        if not isExportable(instance) then
            return
        end

        if instance.Name == "NORLI_Selection" then
            return
        end

        counter += 1
        local id = "obj" .. counter
        ids[instance] = id

        local className = instance.ClassName
        local identifier = sanitizeIdentifier(instance.Name)

        add(string.format("local %s = Instance.new(%s)", id, luaString(className)))

        if instance:IsA("GuiObject") then
            for _, prop in ipairs(guiProperties) do
                appendProperty(lines, "", instance, prop)
                -- Replace obj.* with current variable name
                local last = lines[#lines]
                if last then
                    lines[#lines] = last:gsub("^obj%.", id .. ".")
                end
            end

            if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
                for _, prop in ipairs(textProperties) do
                    if prop ~= "PlaceholderText" or instance:IsA("TextBox") then
                        appendProperty(lines, "", instance, prop)
                        local last = lines[#lines]
                        if last then
                            lines[#lines] = last:gsub("^obj%.", id .. ".")
                        end
                    end
                end
            end

            if instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
                for _, prop in ipairs(imageProperties) do
                    appendProperty(lines, "", instance, prop)
                    local last = lines[#lines]
                    if last then
                        lines[#lines] = last:gsub("^obj%.", id .. ".")
                    end
                end
            end

            if instance:IsA("ScrollingFrame") then
                for _, prop in ipairs(scrollingProperties) do
                    appendProperty(lines, "", instance, prop)
                    local last = lines[#lines]
                    if last then
                        lines[#lines] = last:gsub("^obj%.", id .. ".")
                    end
                end
            end
        elseif instance:IsA("UICorner") then
            appendProperty(lines, "", instance, "CornerRadius")
            local last = lines[#lines]
            if last then
                lines[#lines] = last:gsub("^obj%.", id .. ".")
            end
        elseif instance:IsA("UIStroke") then
            for _, prop in ipairs(strokeProperties) do
                appendProperty(lines, "", instance, prop)
                local last = lines[#lines]
                if last then
                    lines[#lines] = last:gsub("^obj%.", id .. ".")
                end
            end
        end

        add(id .. ".Name = " .. luaString(instance.Name))
        add(id .. ".Parent = " .. parentExpr)
        add("")

        for _, child in ipairs(instance:GetChildren()) do
            register(child, id)
        end
    end

    -- Export DesignRoot as the main container.
    register(cleanRoot, "gui")

    add("-- End of generated interface")
    add("")

    -- Add a tiny report for executors / debugging.
    add("print(\"NORLI GUI exported successfully\")")

    return table.concat(lines, "\n")
end

--// Export window
local ExportOverlay
local ExportBox
local CopyStatus

local function closeExport()
    if ExportOverlay then
        ExportOverlay:Destroy()
        ExportOverlay = nil
    end
end

local function openExport()
    closeExport()

    local source = buildExport()

    ExportOverlay = make("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
        ZIndex = 100,
    }, Gui)

    local Card = make("Frame", {
        Size = UDim2.new(0.94, 0, 0.88, 0),
        Position = UDim2.new(0.03, 0, 0.07, 0),
        BackgroundColor3 = PANEL,
        BorderSizePixel = 0,
        ZIndex = 101,
    }, ExportOverlay)
    corner(Card, 15)
    stroke(Card, LINE, 0.1, 1)

    make("TextLabel", {
        Size = UDim2.new(1, -130, 0, 42),
        Position = UDim2.new(0, 14, 0, 6),
        BackgroundTransparency = 1,
        Text = "EXPORTAR INTERFACE PARA LUA",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = TEXT,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 102,
    }, Card)

    local Close = make("TextButton", {
        Size = UDim2.new(0, 72, 0, 34),
        Position = UDim2.new(1, -84, 0, 10),
        BackgroundColor3 = BAD,
        AutoButtonColor = false,
        Text = "FECHAR",
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 102,
    }, Card)
    corner(Close, 9)
    Close.Activated:Connect(closeExport)

    ExportBox = make("TextBox", {
        Size = UDim2.new(1, -28, 1, -105),
        Position = UDim2.new(0, 14, 0, 55),
        BackgroundColor3 = Color3.fromRGB(12, 14, 19),
        Text = source,
        Font = Enum.Font.Code,
        TextSize = 11,
        TextColor3 = Color3.fromRGB(230, 235, 245),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        MultiLine = true,
        ClearTextOnFocus = false,
        TextWrapped = false,
        BorderSizePixel = 0,
        ZIndex = 102,
    }, Card)
    corner(ExportBox, 10)
    stroke(ExportBox, LINE, 0.3, 1)

    local Copy = make("TextButton", {
        Size = UDim2.new(0.48, -18, 0, 40),
        Position = UDim2.new(0, 14, 1, -48),
        BackgroundColor3 = GOOD,
        AutoButtonColor = false,
        Text = "COPIAR LUA",
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = Color3.fromRGB(8, 11, 12),
        BorderSizePixel = 0,
        ZIndex = 103,
    }, Card)
    corner(Copy, 9)

    local SelectAll = make("TextButton", {
        Size = UDim2.new(0.48, -18, 0, 40),
        Position = UDim2.new(0.52, 4, 1, -48),
        BackgroundColor3 = PANEL2,
        AutoButtonColor = false,
        Text = "SELECIONAR TUDO",
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = TEXT,
        BorderSizePixel = 0,
        ZIndex = 103,
    }, Card)
    corner(SelectAll, 9)

    CopyStatus = make("TextLabel", {
        Size = UDim2.new(1, -28, 0, 16),
        Position = UDim2.new(0, 14, 1, -66),
        BackgroundTransparency = 1,
        Text = "O texto também pode ser selecionado manualmente.",
        Font = Enum.Font.GothamMedium,
        TextSize = 8,
        TextColor3 = MUTED,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 104,
    }, Card)

    Copy.Activated:Connect(function()
        local copied = safeSetClipboard(source)
        if copied then
            CopyStatus.Text = "✓ Copiado para a área de transferência."
            CopyStatus.TextColor3 = GOOD
        else
            CopyStatus.Text = "Selecione tudo e copie manualmente no executor."
            CopyStatus.TextColor3 = MUTED
            ExportBox:CaptureFocus()
            ExportBox.SelectionStart = 1
            ExportBox.CursorPosition = #ExportBox.Text + 1
        end
    end)

    SelectAll.Activated:Connect(function()
        ExportBox:CaptureFocus()
        ExportBox.SelectionStart = 1
        ExportBox.CursorPosition = #ExportBox.Text + 1
        CopyStatus.Text = "✓ Código selecionado."
        CopyStatus.TextColor3 = ACCENT
    end)
end

ExportButton.Activated:Connect(openExport)

--// Small interaction animations
for _, button in ipairs({
    ExportButton, Up, Down, LeftMove, RightMove, LeftMove,
}) do
    button.MouseEnter:Connect(function()
        if button == ExportButton then
            tween(button, {Size = UDim2.new(0, 126, 0, 40)}, 0.1)
        else
            tween(button, {BackgroundColor3 = CARD}, 0.08)
        end
    end)

    button.MouseLeave:Connect(function()
        if button == ExportButton then
            tween(button, {Size = UDim2.new(0, 122, 0, 38)}, 0.1)
        else
            tween(button, {BackgroundColor3 = PANEL2}, 0.08)
        end
    end)
end

--// Responsive layout
local function applyResponsive()
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(800, 600)

    if viewport.X < 800 then
        Left.Size = UDim2.new(0, 145, 1, -58)
        Right.Size = UDim2.new(0, 155, 1, -58)
        Right.Position = UDim2.new(1, -155, 0, 58)
        Work.Position = UDim2.new(0, 145, 0, 58)
        Work.Size = UDim2.new(1, -300, 1, -58)
        Brand.Size = UDim2.new(0, 145, 1, 0)
        Brand.TextSize = 14
        Status.Visible = false
        ExportButton.Size = UDim2.new(0, 104, 0, 36)
        ExportButton.Position = UDim2.new(1, -114, 0.5, -18)
        ExportButton.TextSize = 11
        MovePad.Position = UDim2.new(1, -168, 1, -125)
    else
        Left.Size = UDim2.new(0, 188, 1, -58)
        Right.Size = UDim2.new(0, 200, 1, -58)
        Right.Position = UDim2.new(1, -200, 0, 58)
        Work.Position = UDim2.new(0, 188, 0, 58)
        Work.Size = UDim2.new(1, -388, 1, -58)
        Brand.Size = UDim2.new(0, 170, 1, 0)
        Brand.TextSize = 17
        Status.Visible = true
        ExportButton.Size = UDim2.new(0, 122, 0, 38)
        ExportButton.Position = UDim2.new(1, -134, 0.5, -19)
    end
end

if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(applyResponsive)
end
applyResponsive()

--// Welcome sample to make first launch feel usable
local starter = Instance.new("Frame")
starter.Name = "SamplePanel"
starter.Size = UDim2.new(0, 220, 0, 130)
starter.Position = UDim2.new(0.5, -110, 0.5, -65)
starter.BackgroundColor3 = Color3.fromRGB(31, 36, 48)
starter.BorderSizePixel = 0
starter.ZIndex = 10
starter.Parent = DesignRoot
corner(starter, 14)
stroke(starter, ACCENT, 0.25, 1)
connectSelectable(starter)

local starterTitle = Instance.new("TextLabel")
starterTitle.Name = "Title"
starterTitle.Size = UDim2.new(1, -20, 0, 35)
starterTitle.Position = UDim2.new(0, 10, 0, 12)
starterTitle.BackgroundTransparency = 1
starterTitle.Text = "Seu primeiro design"
starterTitle.Font = Enum.Font.GothamBold
starterTitle.TextSize = 18
starterTitle.TextColor3 = TEXT
starterTitle.ZIndex = 11
starterTitle.Parent = starter
connectSelectable(starterTitle)

local starterText = Instance.new("TextLabel")
starterText.Name = "Description"
starterText.Size = UDim2.new(1, -20, 0, 48)
starterText.Position = UDim2.new(0, 10, 0, 55)
starterText.BackgroundTransparency = 1
starterText.Text = "Toque neste painel ou use os elementos do lado para começar."
starterText.TextWrapped = true
starterText.Font = Enum.Font.GothamMedium
starterText.TextSize = 12
starterText.TextColor3 = MUTED
starterText.ZIndex = 11
starterText.Parent = starter
connectSelectable(starterText)

-- Select sample by default
setSelected(starter)

-- Prevent editor from disappearing on accidental respawn-like GUI refresh
Gui.AncestryChanged:Connect(function(_, parent)
    if not parent then
        return
    end
end)

--// Final status
Status.Text = "V1 • MOBILE • READY"
