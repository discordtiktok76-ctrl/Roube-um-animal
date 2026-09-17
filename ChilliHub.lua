--[[
    🌶️ Chilli Hub — Interface para Executor Roblox
    Execute em qualquer executor (Fluxus, Delta, Solara, etc.)
    Pressione RightShift para abrir/fechar a janela.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:GetWaitForChild("PlayerGui")

-- ══════════════════════════════════════════════════════════
--  CONFIGURAÇÕES / ESTADO
-- ══════════════════════════════════════════════════════════

local State = {
    AutoSteal = false,
    PrioritizeRift = false,
    TargetAreas = "All Areas",
    MinRarity = "Any",
    MinValue = 317,
    TargetEggs = "All",
}

-- ══════════════════════════════════════════════════════════
--  HELPERS
-- ══════════════════════════════════════════════════════════

local function Tween(obj, t, props)
    TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function Make(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do
        obj[k] = v
    end
    obj.Parent = parent
    return obj
end

local function Round(obj, r)
    Make("UICorner", { CornerRadius = UDim.new(0, r or 8) }, obj)
end

local function Stroke(obj, color, thickness, transparency)
    return Make("UIStroke", {
        Color = color,
        Thickness = thickness or 2,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, obj)
end

local function Padding(obj, l, r, t, b)
    Make("UIPadding", {
        PaddingLeft = UDim.new(0, l or 0),
        PaddingRight = UDim.new(0, r or 0),
        PaddingTop = UDim.new(0, t or 0),
        PaddingBottom = UDim.new(0, b or 0),
    }, obj)
end

local Fonts = {
    Title = Enum.Font.GothamBlack,
    Bold = Enum.Font.GothamBold,
    Medium = Enum.Font.GothamMedium,
    Regular = Enum.Font.Gotham,
}

-- ══════════════════════════════════════════════════════════
--  SCREEN GUI
-- ══════════════════════════════════════════════════════════

local ScreenGui = Make("ScreenGui", {
    Name = "ChilliHub",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 999,
}, PlayerGui)

-- ══════════════════════════════════════════════════════════
--  JANELA PRINCIPAL
-- ══════════════════════════════════════════════════════════

local Main = Make("Frame", {
    Name = "Main",
    Size = UDim2.fromOffset(600, 380),
    Position = UDim2.new(0.5, -300, 0.5, -190),
    BackgroundColor3 = Color3.fromRGB(28, 28, 30),
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, ScreenGui)
Round(Main, 10)
Stroke(Main, Color3.fromRGB(120, 15, 20), 2)

-- Sombra
local Shadow = Make("ImageLabel", {
    Name = "Shadow",
    Size = UDim2.new(1, 60, 1, 60),
    Position = UDim2.fromOffset(-30, -30),
    BackgroundTransparency = 1,
    Image = "rbxassetid://6014261993",
    ImageColor3 = Color3.fromRGB(0, 0, 0),
    ImageTransparency = 0.4,
    ScaleType = Enum.ScaleType.Slice,
    SliceCenter = Rect.new(49, 49, 450, 450),
    ZIndex = -1,
}, Main)

-- ══════════════════════════════════════════════════════════
--  HEADER (barra vermelha com título + X)
-- ══════════════════════════════════════════════════════════

local Header = Make("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 46),
    BackgroundColor3 = Color3.fromRGB(200, 25, 35),
    BorderSizePixel = 0,
}, Main)

Make("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(235, 45, 55)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(210, 25, 40)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(185, 15, 30)),
    }),
    Rotation = 90,
}, Header)

-- Título
local Title = Make("TextLabel", {
    Name = "Title",
    Size = UDim2.new(1, -60, 1, 0),
    Position = UDim2.fromOffset(14, 0),
    BackgroundTransparency = 1,
    Text = "🌶️ Chilli Hub",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 22,
    Font = Fonts.Title,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Header)
Stroke(Title, Color3.fromRGB(90, 5, 10), 2)

-- Botão Fechar (X)
local CloseBtn = Make("TextButton", {
    Name = "Close",
    Size = UDim2.fromOffset(34, 34),
    Position = UDim2.new(1, -41, 0.5, -17),
    BackgroundColor3 = Color3.fromRGB(190, 20, 30),
    Text = "✕",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 16,
    Font = Fonts.Bold,
    AutoButtonColor = false,
}, Header)
Round(CloseBtn, 7)
Stroke(CloseBtn, Color3.fromRGB(255, 255, 255), 1, 0.7)

CloseBtn.MouseEnter:Connect(function()
    Tween(CloseBtn, 0.15, { BackgroundColor3 = Color3.fromRGB(255, 60, 60) })
end)
CloseBtn.MouseLeave:Connect(function()
    Tween(CloseBtn, 0.15, { BackgroundColor3 = Color3.fromRGB(190, 20, 30) })
end)
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- ══════════════════════════════════════════════════════════
--  ARRASTAR A JANELA
-- ══════════════════════════════════════════════════════════

do
    local dragging = false
    local dragStart, startPos

    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    Header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                local delta = input.Position - dragStart
                Main.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end
    end)
end

-- ══════════════════════════════════════════════════════════
--  MENU LATERAL (botões vermelhos)
-- ══════════════════════════════════════════════════════════

local SideMenu = Make("Frame", {
    Name = "SideMenu",
    Size = UDim2.fromOffset(130, 380 - 46),
    Position = UDim2.fromOffset(0, 46),
    BackgroundColor3 = Color3.fromRGB(35, 35, 38),
    BorderSizePixel = 0,
}, Main)
Stroke(SideMenu, Color3.fromRGB(90, 90, 95), 1)

Make("UIListLayout", {
    Padding = UDim.new(0, 6),
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    SortOrder = Enum.SortOrder.LayoutOrder,
}, SideMenu)
Padding(SideMenu, 0, 0, 10, 0)

local menuButtons = {
    { name = "Auto Steal", icon = "🥷", order = 1 },
    { name = "Farm", icon = "🌾", order = 2 },
    { name = "Player", icon = "👤", order = 3 },
    { name = "Predictor", icon = "🔮", order = 4 },
    { name = "Progress", icon = "📊", order = 5 },
    { name = "Server", icon = "🖥️", order = 6 },
    { name = "Misc", icon = "⚙️", order = 7 },
    { name = "Egg Finder", icon = "🥚", order = 8 },
}

local MenuBtnRefs = {}

for _, item in ipairs(menuButtons) do
    local btn = Make("TextButton", {
        Name = item.name,
        Size = UDim2.fromOffset(112, 32),
        BackgroundColor3 = Color3.fromRGB(210, 30, 40),
        Text = ("  %s  %s"):format(item.icon, item.name),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 13,
        Font = Fonts.Bold,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false,
        LayoutOrder = item.order,
    }, SideMenu)
    Round(btn, 7)
    Stroke(btn, Color3.fromRGB(120, 10, 20), 2)
    MenuBtnRefs[item.name] = btn
end

-- ══════════════════════════════════════════════════════════
--  ÁREA DE CONTEÚDO (páginas)
-- ══════════════════════════════════════════════════════════

local Content = Make("Frame", {
    Name = "Content",
    Size = UDim2.new(1, -140, 1, -56),
    Position = UDim2.fromOffset(135, 51),
    BackgroundTransparency = 1,
}, Main)

local pages = {}

local function NewPage(name)
    local page = Make("ScrollingFrame", {
        Name = name,
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Color3.fromRGB(200, 30, 40),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
    }, Content)
    Make("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, page)
    Padding(page, 4, 6, 4, 4)
    pages[name] = page
    return page
end

-- Placeholder das outras páginas
for _, item in ipairs(menuButtons) do
    if item.name ~= "Auto Steal" then
        NewPage(item.name)
    end
end

-- ══════════════════════════════════════════════════════════
--  COMPONENTES
-- ══════════════════════════════════════════════════════════

-- ▬ Toggle
local function CreateToggle(parent, config)
    -- config: { Label, Sub, Default, Callback, Order }
    local row = Make("Frame", {
        Name = config.Label,
        Size = UDim2.new(1, 0, 0, config.Sub and 52 or 42),
        BackgroundColor3 = Color3.fromRGB(40, 40, 44),
        BorderSizePixel = 0,
        LayoutOrder = config.Order or 1,
    }, parent)
    Round(row, 8)
    Stroke(row, Color3.fromRGB(90, 90, 95), 1)

    Make("TextLabel", {
        Size = UDim2.new(1, -70, 0, config.Sub and 22 or 42),
        Position = UDim2.fromOffset(12, config.Sub and 5 or 0),
        BackgroundTransparency = 1,
        Text = config.Label,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 15,
        Font = Fonts.Bold,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)

    if config.Sub then
        Make("TextLabel", {
            Size = UDim2.new(1, -70, 0, 18),
            Position = UDim2.fromOffset(12, 27),
            BackgroundTransparency = 1,
            Text = config.Sub,
            TextColor3 = Color3.fromRGB(170, 170, 175),
            TextSize = 11,
            Font = Fonts.Regular,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
        }, row)
    end

    -- Fundo do switch
    local switchBg = Make("TextButton", {
        Size = UDim2.fromOffset(46, 24),
        Position = UDim2.new(1, -58, 0.5, -12),
        BackgroundColor3 = Color3.fromRGB(75, 75, 80),
        Text = "",
        AutoButtonColor = false,
    }, row)
    Round(switchBg, 12)
    Stroke(switchBg, Color3.fromRGB(20, 20, 22), 1, 0.4)

    -- Bolinha
    local knob = Make("Frame", {
        Size = UDim2.fromOffset(18, 18),
        Position = UDim2.fromOffset(3, 3),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
    }, switchBg)
    Round(knob, 9)

    local enabled = config.Default or false

    local function Apply()
        local targetColor = enabled and Color3.fromRGB(60, 200, 80) or Color3.fromRGB(75, 75, 80)
        Tween(switchBg, 0.2, { BackgroundColor3 = targetColor })
        Tween(knob, 0.2, { Position = enabled and UDim2.fromOffset(25, 3) or UDim2.fromOffset(3, 3) })
    end

    if enabled then Apply() end

    switchBg.MouseButton1Click:Connect(function()
        enabled = not enabled
        Apply()
        if config.Callback then config.Callback(enabled) end
    end)

    return {
        Set = function(v) enabled = v; Apply() end,
        Get = function() return enabled end,
    }
end

-- ▬ Dropdown
local function CreateDropdown(parent, config)
    -- config: { Label, Sub, Options, Default, Callback, Order }
    local row = Make("Frame", {
        Name = config.Label,
        Size = UDim2.new(1, 0, 0, config.Sub and 54 or 44),
        BackgroundColor3 = Color3.fromRGB(40, 40, 44),
        BorderSizePixel = 0,
        LayoutOrder = config.Order or 1,
    }, parent)
    Round(row, 8)
    Stroke(row, Color3.fromRGB(90, 90, 95), 1)

    Make("TextLabel", {
        Size = UDim2.new(0.5, 0, 0, config.Sub and 24 or 44),
        Position = UDim2.fromOffset(12, config.Sub and 5 or 0),
        BackgroundTransparency = 1,
        Text = config.Label,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 15,
        Font = Fonts.Bold,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)

    if config.Sub then
        Make("TextLabel", {
            Size = UDim2.new(0.5, 0, 0, 18),
            Position = UDim2.fromOffset(12, 28),
            BackgroundTransparency = 1,
            Text = config.Sub,
            TextColor3 = Color3.fromRGB(170, 170, 175),
            TextSize = 11,
            Font = Fonts.Regular,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
        }, row)
    end

    local value = config.Default or config.Options[1]

    -- Botão do dropdown
    local dropBtn = Make("TextButton", {
        Size = UDim2.fromOffset(130, 30),
        Position = UDim2.new(1, -142, 0.5, -15),
        BackgroundColor3 = Color3.fromRGB(25, 25, 28),
        Text = "  " .. tostring(value) .. "  ▼",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 13,
        Font = Fonts.Medium,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false,
    }, row)
    Round(dropBtn, 6)
    Stroke(dropBtn, Color3.fromRGB(70, 70, 75), 1)

    -- Lista suspensa
    local dropList = Make("Frame", {
        Size = UDim2.fromOffset(130, 0),
        Position = UDim2.new(1, -142, 1, 4),
        BackgroundColor3 = Color3.fromRGB(25, 25, 28),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 10,
    }, row)
    Round(dropList, 6)
    Stroke(dropList, Color3.fromRGB(70, 70, 75), 1)
    Make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, dropList)

    local open = false

    local function BuildList()
        for _, child in ipairs(dropList:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        for i, opt in ipairs(config.Options) do
            local optBtn = Make("TextButton", {
                Size = UDim2.new(1, 0, 0, 28),
                BackgroundColor3 = Color3.fromRGB(25, 25, 28),
                Text = "  " .. tostring(opt),
                TextColor3 = tostring(opt) == tostring(value) and Color3.fromRGB(80, 220, 100) or Color3.fromRGB(255, 255, 255),
                TextSize = 13,
                Font = Fonts.Medium,
                TextXAlignment = Enum.TextXAlignment.Left,
                AutoButtonColor = false,
                LayoutOrder = i,
                ZIndex = 11,
            }, dropList)
            optBtn.MouseEnter:Connect(function()
                Tween(optBtn, 0.1, { BackgroundColor3 = Color3.fromRGB(50, 50, 55) })
            end)
            optBtn.MouseLeave:Connect(function()
                Tween(optBtn, 0.1, { BackgroundColor3 = Color3.fromRGB(25, 25, 28) })
            end)
            optBtn.MouseButton1Click:Connect(function()
                value = opt
                dropBtn.Text = "  " .. tostring(value) .. "  ▼"
                open = false
                Tween(dropList, 0.2, { Size = UDim2.fromOffset(130, 0) })
                task.delay(0.2, function() dropList.Visible = false end)
                if config.Callback then config.Callback(value) end
            end)
        end
    end

    dropBtn.MouseButton1Click:Connect(function()
        open = not open
        if open then
            BuildList()
            dropList.Visible = true
            local h = math.min(#config.Options * 28, 140)
            Tween(dropList, 0.2, { Size = UDim2.fromOffset(130, h) })
        else
            Tween(dropList, 0.2, { Size = UDim2.fromOffset(130, 0) })
            task.delay(0.2, function() dropList.Visible = false end)
        end
    end)

    return {
        Set = function(v) value = v; dropBtn.Text = "  " .. tostring(v) .. "  ▼" end,
        Get = function() return value end,
    }
end

-- ▬ Slider
local function CreateSlider(parent, config)
    -- config: { Label, Sub, Min, Max, Default, Suffix, Callback, Order }
    local row = Make("Frame", {
        Name = config.Label,
        Size = UDim2.new(1, 0, 0, config.Sub and 56 or 46),
        BackgroundColor3 = Color3.fromRGB(40, 40, 44),
        BorderSizePixel = 0,
        LayoutOrder = config.Order or 1,
    }, parent)
    Round(row, 8)
    Stroke(row, Color3.fromRGB(90, 90, 95), 1)

    Make("TextLabel", {
        Size = UDim2.new(0.55, 0, 0, config.Sub and 24 or 46),
        Position = UDim2.fromOffset(12, config.Sub and 5 or 0),
        BackgroundTransparency = 1,
        Text = config.Label,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 15,
        Font = Fonts.Bold,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)

    if config.Sub then
        Make("TextLabel", {
            Size = UDim2.new(0.55, 0, 0, 18),
            Position = UDim2.fromOffset(12, 29),
            BackgroundTransparency = 1,
            Text = config.Sub,
            TextColor3 = Color3.fromRGB(170, 170, 175),
            TextSize = 11,
            Font = Fonts.Regular,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, row)
    end

    local value = config.Default or config.Min

    -- Label do valor
    local valueLbl = Make("TextLabel", {
        Size = UDim2.fromOffset(70, 22),
        Position = UDim2.new(1, -82, 0, 6),
        BackgroundColor3 = Color3.fromRGB(25, 25, 28),
        Text = (config.Suffix or "") .. value,
        TextColor3 = Color3.fromRGB(120, 230, 120),
        TextSize = 12,
        Font = Fonts.Bold,
    }, row)
    Round(valueLbl, 5)
    Stroke(valueLbl, Color3.fromRGB(70, 70, 75), 1)

    -- Trilho
    local track = Make("Frame", {
        Size = UDim2.new(0.4, 0, 0, 8),
        Position = UDim2.new(1, -10, 0.5, 8),
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = Color3.fromRGB(25, 25, 28),
        BorderSizePixel = 0,
    }, row)
    Round(track, 4)

    -- Preenchimento
    local fill = Make("Frame", {
        Size = UDim2.fromScale((value - config.Min) / (config.Max - config.Min), 1),
        BackgroundColor3 = Color3.fromRGB(60, 200, 80),
        BorderSizePixel = 0,
    }, track)
    Round(fill, 4)

    -- Knob
    local knob = Make("Frame", {
        Size = UDim2.fromOffset(14, 14),
        Position = UDim2.fromScale((value - config.Min) / (config.Max - config.Min), 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
    }, track)
    Round(knob, 7)
    Stroke(knob, Color3.fromRGB(20, 20, 22), 1, 0.3)

    local dragging = false

    local function SetFromX(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        value = math.round(config.Min + rel * (config.Max - config.Min))
        fill.Size = UDim2.fromScale(rel, 1)
        knob.Position = UDim2.fromScale(rel, 0.5)
        valueLbl.Text = (config.Suffix or "") .. value
        if config.Callback then config.Callback(value) end
    end

    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            SetFromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            SetFromX(input.Position.X)
        end
    end)

    return {
        Set = function(v)
            value = math.clamp(v, config.Min, config.Max)
            local rel = (value - config.Min) / (config.Max - config.Min)
            fill.Size = UDim2.fromScale(rel, 1)
            knob.Position = UDim2.fromScale(rel, 0.5)
            valueLbl.Text = (config.Suffix or "") .. value
        end,
        Get = function() return value end,
    }
end

-- ══════════════════════════════════════════════════════════
--  PÁGINA: AUTO STEAL (exatamente os toggles da imagem)
-- ══════════════════════════════════════════════════════════

local AutoStealPage = NewPage("AutoSteal")

CreateToggle(AutoStealPage, {
    Label = "Auto Steal",
    Default = false,
    Order = 1,
    Callback = function(v)
        State.AutoSteal = v
        print("[ChilliHub] Auto Steal:", v)
        -- 👉 insira sua lógica de Auto Steal aqui
    end,
})

CreateDropdown(AutoStealPage, {
    Label = "Target Areas",
    Sub = "12 selected",
    Options = { "All Areas", "Spawn", "Beach", "Forest", "Volcano", "Desert", "Snow", "Underworld", "Glitch", "Cyber", "Rainbow", "Void" },
    Default = "All Areas",
    Order = 2,
    Callback = function(v)
        State.TargetAreas = v
        print("[ChilliHub] Target Areas:", v)
    end,
})

CreateDropdown(AutoStealPage, {
    Label = "Min Rarity",
    Sub = "Steal eggs of the chosen rarity and every rarity above it",
    Options = { "Any", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Godly" },
    Default = "Any",
    Order = 3,
    Callback = function(v)
        State.MinRarity = v
        print("[ChilliHub] Min Rarity:", v)
    end,
})

CreateSlider(AutoStealPage, {
    Label = "Min Value To Steal",
    Sub = "Skip eggs worth less than this (0 = off)",
    Min = 0,
    Max = 1000,
    Default = 317,
    Suffix = "",
    Order = 4,
    Callback = function(v)
        State.MinValue = v
        print("[ChilliHub] Min Value:", v)
    end,
})

CreateDropdown(AutoStealPage, {
    Label = "Target Specific Eggs",
    Sub = "Only steal these eggs (empty = all)",
    Options = { "All", "Rift Egg", "Void Egg", "Cyber Egg", "Golden Egg", "Rainbow Egg" },
    Default = "All",
    Order = 5,
    Callback = function(v)
        State.TargetEggs = v
        print("[ChilliHub] Target Eggs:", v)
    end,
})

CreateToggle(AutoStealPage, {
    Label = "Prioritize Rift Recipe Eggs",
    Sub = "Steal eggs the Rift recipe needs first",
    Default = false,
    Order = 6,
    Callback = function(v)
        State.PrioritizeRift = v
        print("[ChilliHub] Prioritize Rift:", v)
    end,
})

-- ══════════════════════════════════════════════════════════
--  NAVEGAÇÃO ENTRE PÁGINAS
-- ══════════════════════════════════════════════════════════

local function SelectPage(name)
    for pageName, page in pairs(pages) do
        page.Visible = (pageName == name)
    end
    for _, item in ipairs(menuButtons) do
        local btn = MenuBtnRefs[item.name]
        local active = (item.name == name)
        Tween(btn, 0.15, {
            BackgroundColor3 = active and Color3.fromRGB(150, 20, 30) or Color3.fromRGB(210, 30, 40),
        })
    end
end

for _, item in ipairs(menuButtons) do
    MenuBtnRefs[item.name].MouseButton1Click:Connect(function()
        SelectPage(item.name)
    end)
end

SelectPage("AutoSteal")

-- ══════════════════════════════════════════════════════════
--  TECLA PARA ABRIR/FECHAR (RightShift)
-- ══════════════════════════════════════════════════════════

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        Main.Visible = not Main.Visible
    end
end)

print("🌶️ Chilli Hub carregado! Pressione RightShift para abrir/fechar.")
