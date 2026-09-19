--// NORLI HUB
--// Interface + 3 Páginas + ESP Permanente + Item Dropdown
--// Atualizado: ESP com atualização contínua e item detectado por nome

local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

--//==============================================================
--// GUI PARENT
--//==============================================================
local function GetGuiParent()
    local ok, result = pcall(function()
        if gethui then
            return gethui()
        end
        return nil
    end)

    if ok and result then
        return result
    end

    if LocalPlayer then
        local okPlayerGui, playerGui = pcall(function()
            return LocalPlayer:WaitForChild("PlayerGui", 5)
        end)

        if okPlayerGui and playerGui then
            return playerGui
        end
    end

    return CoreGui
end

local GuiParent = GetGuiParent()

pcall(function()
    local oldGui = GuiParent:FindFirstChild("NorliHub")
    if oldGui then
        oldGui:Destroy()
    end
end)

pcall(function()
    local oldCoreGui = CoreGui:FindFirstChild("NorliHub")
    if oldCoreGui then
        oldCoreGui:Destroy()
    end
end)

--//==============================================================
--// ESTADOS DOS ESPs
--//==============================================================
local ESPStates = {
    KILLERS = false,
    SURVIVORS = false,
    SPECTATORS = false,
    GENERATORS = false
}

local ESPColors = {
    KILLERS = Color3.fromRGB(255, 0, 0),
    SURVIVORS = Color3.fromRGB(0, 255, 0),
    SPECTATORS = Color3.fromRGB(255, 255, 255),
    GENERATORS = Color3.fromRGB(255, 255, 0)
}

local ESPTag = "NorliESP_Aura"
local TrackedESP = {}

--//==============================================================
--// FUNÇÕES UTILITÁRIAS
--//==============================================================
local function IsAlive(instance)
    return instance ~= nil
end

local function IsInWorkspace(instance)
    if not instance then
        return false
    end

    local ok, result = pcall(function()
        return instance:IsDescendantOf(workspace)
    end)

    return ok and result
end

local function GetFirstBasePart(instance)
    if not instance then
        return nil
    end

    local okBase, isBase = pcall(function()
        return instance:IsA("BasePart")
    end)

    if okBase and isBase then
        return instance
    end

    local okDesc, descendants = pcall(function()
        return instance:GetDescendants()
    end)

    if not okDesc then
        return nil
    end

    for _, descendant in ipairs(descendants) do
        local ok, result = pcall(function()
            return descendant:IsA("BasePart")
        end)

        if ok and result then
            return descendant
        end
    end

    return nil
end

local function IsRenderableInstance(instance)
    if not instance then
        return false
    end

    local ok = pcall(function()
        return instance:IsA("Model")
            or instance:IsA("BasePart")
            or instance:IsA("Tool")
            or instance:IsA("Folder")
    end)

    if not ok then
        return false
    end

    if instance:IsA("BasePart") or instance:IsA("Model") or instance:IsA("Tool") then
        return true
    end

    return GetFirstBasePart(instance) ~= nil
end

local function GetPlayersFolder()
    return workspace:FindFirstChild("Players")
end

local function GetMapFolder()
    local map = workspace:FindFirstChild("Map")
    if not map then
        return nil
    end

    local ingame = map:FindFirstChild("Ingame")
    if not ingame then
        return nil
    end

    return ingame:FindFirstChild("Map")
end

local function GetESPFolder(toggleKey)
    local playersFolder = GetPlayersFolder()
    if not playersFolder then
        return nil
    end

    if toggleKey == "KILLERS" then
        return playersFolder:FindFirstChild("Killers")
    elseif toggleKey == "SURVIVORS" then
        return playersFolder:FindFirstChild("Survivors")
    elseif toggleKey == "SPECTATORS" then
        return playersFolder:FindFirstChild("Spectating")
    end

    return nil
end

local function IsObjectValidForESP(instance, toggleKey)
    if not instance or not IsInWorkspace(instance) then
        return false
    end

    if toggleKey == "GENERATORS" then
        local mapFolder = GetMapFolder()
        if not mapFolder then
            return false
        end

        return instance.Name == "Generator" and instance:IsDescendantOf(mapFolder)
    end

    local folder = GetESPFolder(toggleKey)
    if not folder then
        return false
    end

    return instance.Parent == folder
end

--//==============================================================
--// ESP
--//==============================================================
local function DestroyHighlightForObject(object)
    if not object then
        return
    end

    local highlight = nil

    pcall(function()
        highlight = object:FindFirstChild(ESPTag)
    end)

    if highlight then
        pcall(function()
            highlight:Destroy()
        end)
    end
end

local function RemoveESPForKey(toggleKey)
    for object, data in pairs(TrackedESP) do
        if not data or data.ToggleKey == toggleKey then
            DestroyHighlightForObject(object)
            TrackedESP[object] = nil
        end
    end
end

local function ApplyESP(object, color, toggleKey)
    if not IsAlive(object) or not IsInWorkspace(object) then
        return
    end

    if not IsObjectValidForESP(object, toggleKey) then
        return
    end

    local adornee = object
    local canUseObject = false

    local ok = pcall(function()
        canUseObject = object:IsA("Model") or object:IsA("BasePart")
    end)

    if not ok then
        return
    end

    if not canUseObject then
        adornee = GetFirstBasePart(object)
    end

    if not adornee then
        return
    end

    local highlight
    local foundExisting = pcall(function()
        highlight = object:FindFirstChild(ESPTag)
    end)

    if foundExisting and highlight and highlight:IsA("Highlight") then
        highlight.Adornee = adornee
        highlight.FillColor = color
        highlight.OutlineColor = color
        highlight.FillTransparency = 0.72
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight:SetAttribute("NorliOwner", true)
        highlight:SetAttribute("NorliKey", toggleKey)

        TrackedESP[object] = {
            Highlight = highlight,
            ToggleKey = toggleKey,
            Color = color
        }
        return
    end

    if foundExisting and highlight then
        pcall(function()
            highlight:Destroy()
        end)
    end

    highlight = Instance.new("Highlight")
    highlight.Name = ESPTag
    highlight.Adornee = adornee
    highlight.FillColor = color
    highlight.OutlineColor = color
    highlight.FillTransparency = 0.72
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight:SetAttribute("NorliOwner", true)
    highlight:SetAttribute("NorliKey", toggleKey)

    local parentOk = pcall(function()
        highlight.Parent = object
    end)

    if not parentOk or not highlight.Parent then
        pcall(function()
            highlight:Destroy()
        end)
        return
    end

    TrackedESP[object] = {
        Highlight = highlight,
        ToggleKey = toggleKey,
        Color = color
    }
end

local function CleanTrackedESP()
    for object, data in pairs(TrackedESP) do
        local valid = false

        if data and ESPStates[data.ToggleKey] then
            valid = IsObjectValidForESP(object, data.ToggleKey)
        end

        if not valid then
            DestroyHighlightForObject(object)
            TrackedESP[object] = nil
        else
            local highlight = data.Highlight
            local highlightValid = false

            if highlight then
                highlightValid = pcall(function()
                    return highlight.Parent ~= nil and highlight:IsA("Highlight")
                end)
            end

            if not highlightValid then
                TrackedESP[object] = nil
            end
        end
    end
end

local function SyncESPKey(toggleKey)
    if not ESPStates[toggleKey] then
        RemoveESPForKey(toggleKey)
        return
    end

    if toggleKey == "GENERATORS" then
        local mapFolder = GetMapFolder()
        if not mapFolder then
            return
        end

        local ok, descendants = pcall(function()
            return mapFolder:GetDescendants()
        end)

        if not ok then
            return
        end

        for _, descendant in ipairs(descendants) do
            if descendant.Name == "Generator" then
                ApplyESP(descendant, ESPColors.GENERATORS, "GENERATORS")
            end
        end

        return
    end

    local folder = GetESPFolder(toggleKey)
    if not folder then
        return
    end

    local ok, children = pcall(function()
        return folder:GetChildren()
    end)

    if not ok then
        return
    end

    for _, child in ipairs(children) do
        ApplyESP(child, ESPColors[toggleKey], toggleKey)
    end
end

local function SyncAllESP()
    CleanTrackedESP()

    SyncESPKey("KILLERS")
    SyncESPKey("SURVIVORS")
    SyncESPKey("SPECTATORS")
    SyncESPKey("GENERATORS")
end

--//==============================================================
--// SCREEN GUI
--//==============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NorliHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999999

local screenParented = pcall(function()
    ScreenGui.Parent = GuiParent
end)

if not screenParented or not ScreenGui.Parent then
    pcall(function()
        ScreenGui.Parent = CoreGui
    end)
end

if not ScreenGui.Parent and LocalPlayer then
    pcall(function()
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui", 5)
    end)
end

--//==============================================================
--// MAIN
--//==============================================================
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(210, 330)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.Position = UDim2.new(0.5, 0, 0.5, -25)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Main.BackgroundTransparency = 0.12
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = Main

local Texture = Instance.new("ImageLabel")
Texture.Name = "Texture"
Texture.Size = UDim2.fromScale(1, 1)
Texture.BackgroundTransparency = 1
Texture.Image = "rbxassetid://102991861215975"
Texture.ImageTransparency = 0.55
Texture.ScaleType = Enum.ScaleType.Stretch
Texture.ZIndex = 1
Texture.Parent = Main

local TextureCorner = Instance.new("UICorner")
TextureCorner.CornerRadius = UDim.new(0, 8)
TextureCorner.Parent = Texture

local DarkOverlay = Instance.new("Frame")
DarkOverlay.Name = "DarkOverlay"
DarkOverlay.Size = UDim2.fromScale(1, 1)
DarkOverlay.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
DarkOverlay.BackgroundTransparency = 0.35
DarkOverlay.BorderSizePixel = 0
DarkOverlay.ZIndex = 2
DarkOverlay.Parent = Main

local OverlayCorner = Instance.new("UICorner")
OverlayCorner.CornerRadius = UDim.new(0, 8)
OverlayCorner.Parent = DarkOverlay

local TitleLogo = Instance.new("ImageLabel")
TitleLogo.Name = "TitleLogo"
TitleLogo.Size = UDim2.fromOffset(18, 18)
TitleLogo.Position = UDim2.fromOffset(4, 4)
TitleLogo.BackgroundTransparency = 1
TitleLogo.Image = "rbxassetid://10039620127"
TitleLogo.ScaleType = Enum.ScaleType.Fit
TitleLogo.ZIndex = 4
TitleLogo.Parent = Main

local LogoCorner = Instance.new("UICorner")
LogoCorner.CornerRadius = UDim.new(1, 0)
LogoCorner.Parent = TitleLogo

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.fromOffset(105, 20)
Title.Position = UDim2.fromOffset(26, 3)
Title.BackgroundTransparency = 1
Title.Text = "NORLI HUB"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 12
Title.Font = Enum.Font.FredokaOne
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextYAlignment = Enum.TextYAlignment.Top
Title.TextStrokeTransparency = 0.45
Title.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
Title.ZIndex = 4
Title.Parent = Main

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.fromOffset(22, 22)
CloseButton.Position = UDim2.new(1, -27, 0, 2)
CloseButton.BackgroundTransparency = 1
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextSize = 14
CloseButton.Font = Enum.Font.FredokaOne
CloseButton.TextStrokeTransparency = 0.5
CloseButton.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
CloseButton.AutoButtonColor = false
CloseButton.ZIndex = 6
CloseButton.Parent = Main

--//==============================================================
--// BOTÃO FLUTUANTE
--//==============================================================
local FloatingButton = Instance.new("ImageButton")
FloatingButton.Name = "FloatingButton"
FloatingButton.Size = UDim2.fromOffset(52, 52)
FloatingButton.Position = UDim2.new(0.5, -26, 0.75, 0)
FloatingButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
FloatingButton.BackgroundTransparency = 0.08
FloatingButton.BorderSizePixel = 0
FloatingButton.Image = "rbxassetid://10039620127"
FloatingButton.ScaleType = Enum.ScaleType.Fit
FloatingButton.Visible = false
FloatingButton.AutoButtonColor = false
FloatingButton.ZIndex = 20
FloatingButton.Parent = ScreenGui

local FloatingCorner = Instance.new("UICorner")
FloatingCorner.CornerRadius = UDim.new(1, 0)
FloatingCorner.Parent = FloatingButton

local FloatingStroke = Instance.new("UIStroke")
FloatingStroke.Color = Color3.fromRGB(80, 80, 80)
FloatingStroke.Thickness = 1
FloatingStroke.Transparency = 0.25
FloatingStroke.Parent = FloatingButton

--// ARRASTAR BOTÃO FLUTUANTE
local dragging = false
local dragStart = nil
local startPosition = nil
local dragInput = nil

local function UpdateDrag(input)
    if not dragStart or not startPosition then
        return
    end

    local delta = input.Position - dragStart

    FloatingButton.Position = UDim2.new(
        startPosition.X.Scale,
        startPosition.X.Offset + delta.X,
        startPosition.Y.Scale,
        startPosition.Y.Offset + delta.Y
    )
end

FloatingButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPosition = FloatingButton.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                dragInput = nil
            end
        end)
    end
end)

FloatingButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then

        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        UpdateDrag(input)
    end
end)

CloseButton.Activated:Connect(function()
    Main.Visible = false
    FloatingButton.Visible = true
end)

FloatingButton.Activated:Connect(function()
    Main.Visible = true
    FloatingButton.Visible = false
end)

--//==============================================================
--// ABAS
--//==============================================================
local CurrentPage = "ESP"
local PageFrames = {}
local TabButtons = {}

local TabHolder = Instance.new("Frame")
TabHolder.Name = "TabHolder"
TabHolder.Size = UDim2.fromOffset(186, 25)
TabHolder.Position = UDim2.fromOffset(12, 25)
TabHolder.BackgroundTransparency = 1
TabHolder.ZIndex = 5
TabHolder.Parent = Main

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
TabLayout.Padding = UDim.new(0, 4)
TabLayout.Parent = TabHolder

local function CreateTab(name, displayName)
    local button = Instance.new("TextButton")
    button.Name = name .. "Tab"
    button.Size = UDim2.fromOffset(59, 24)
    button.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    button.BorderSizePixel = 0
    button.Text = displayName
    button.TextColor3 = Color3.fromRGB(190, 190, 190)
    button.TextSize = 10
    button.Font = Enum.Font.FredokaOne
    button.AutoButtonColor = false
    button.ZIndex = 5
    button.Parent = TabHolder

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button

    local stroke = Instance.new("UIStroke")
    stroke.Name = "Stroke"
    stroke.Color = Color3.fromRGB(75, 75, 75)
    stroke.Thickness = 1
    stroke.Transparency = 0.45
    stroke.Parent = button

    TabButtons[name] = button

    button.Activated:Connect(function()
        CurrentPage = name

        for pageName, pageFrame in pairs(PageFrames) do
            pageFrame.Visible = pageName == name
        end

        for tabName, tabButton in pairs(TabButtons) do
            local selected = tabName == name
            tabButton.BackgroundColor3 = selected
                and Color3.fromRGB(60, 210, 100)
                or Color3.fromRGB(35, 35, 35)
            tabButton.TextColor3 = selected
                and Color3.fromRGB(0, 0, 0)
                or Color3.fromRGB(190, 190, 190)
        end
    end)

    return button
end

CreateTab("ESP", "ESP")
CreateTab("AUTO", "AUTO")
CreateTab("ITEM", "ITEM")

local PageContainer = Instance.new("Frame")
PageContainer.Name = "PageContainer"
PageContainer.Size = UDim2.fromOffset(198, 266)
PageContainer.Position = UDim2.fromOffset(6, 57)
PageContainer.BackgroundTransparency = 1
PageContainer.ClipsDescendants = true
PageContainer.ZIndex = 4
PageContainer.Parent = Main

local ESPPage = Instance.new("Frame")
ESPPage.Name = "ESPPage"
ESPPage.Size = UDim2.fromScale(1, 1)
ESPPage.BackgroundTransparency = 1
ESPPage.ZIndex = 4
ESPPage.Parent = PageContainer
PageFrames.ESP = ESPPage

local AutoPage = Instance.new("Frame")
AutoPage.Name = "AutoPage"
AutoPage.Size = UDim2.fromScale(1, 1)
AutoPage.BackgroundTransparency = 1
AutoPage.ZIndex = 4
AutoPage.Parent = PageContainer
PageFrames.AUTO = AutoPage

local ItemPage = Instance.new("Frame")
ItemPage.Name = "ItemPage"
ItemPage.Size = UDim2.fromScale(1, 1)
ItemPage.BackgroundTransparency = 1
ItemPage.ZIndex = 4
ItemPage.Parent = PageContainer
PageFrames.ITEM = ItemPage

ESPPage.Visible = true
AutoPage.Visible = false
ItemPage.Visible = false

TabButtons.ESP.BackgroundColor3 = Color3.fromRGB(60, 210, 100)
TabButtons.ESP.TextColor3 = Color3.fromRGB(0, 0, 0)

--//==============================================================
--// PÁGINA ESP
--//==============================================================
local function CreateESPToggle(name, stateKey, yPosition)
    local holder = Instance.new("Frame")
    holder.Name = stateKey .. "Holder"
    holder.Size = UDim2.fromOffset(186, 28)
    holder.Position = UDim2.fromOffset(6, yPosition)
    holder.BackgroundTransparency = 1
    holder.ZIndex = 5
    holder.Parent = ESPPage

    local button = Instance.new("TextButton")
    button.Name = stateKey .. "Toggle"
    button.Size = UDim2.fromOffset(42, 24)
    button.Position = UDim2.fromOffset(0, 2)
    button.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    button.BorderSizePixel = 0
    button.Text = ""
    button.AutoButtonColor = false
    button.ZIndex = 5
    button.Parent = holder

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 6)
    buttonCorner.Parent = button

    local indicator = Instance.new("Frame")
    indicator.Name = "Indicator"
    indicator.Size = UDim2.fromOffset(18, 18)
    indicator.Position = UDim2.fromOffset(3, 3)
    indicator.BackgroundColor3 = Color3.fromRGB(220, 55, 55)
    indicator.BorderSizePixel = 0
    indicator.ZIndex = 6
    indicator.Parent = button

    local indicatorCorner = Instance.new("UICorner")
    indicatorCorner.CornerRadius = UDim.new(0, 4)
    indicatorCorner.Parent = indicator

    local glow = Instance.new("UIStroke")
    glow.Name = "Glow"
    glow.Thickness = 1
    glow.Transparency = 0.35
    glow.Color = Color3.fromRGB(220, 55, 55)
    glow.Parent = indicator

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.fromOffset(135, 22)
    label.Position = UDim2.fromOffset(58, 3)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(225, 225, 225)
    label.TextSize = 11
    label.Font = Enum.Font.FredokaOne
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.ZIndex = 5
    label.Parent = holder

    local enabled = false

    local function RenderState()
        local position
        local color

        if enabled then
            position = UDim2.new(1, -21, 0, 3)
            color = Color3.fromRGB(60, 210, 100)
        else
            position = UDim2.fromOffset(3, 3)
            color = Color3.fromRGB(220, 55, 55)
        end

        TweenService:Create(
            indicator,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                Position = position,
                BackgroundColor3 = color
            }
        ):Play()

        TweenService:Create(
            glow,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                Color = color
            }
        ):Play()
    end

    button.Activated:Connect(function()
        enabled = not enabled
        ESPStates[stateKey] = enabled

        if not enabled then
            RemoveESPForKey(stateKey)
        end

        RenderState()
        pcall(SyncAllESP)
    end)

    return button
end

CreateESPToggle("ESP KILLERS", "KILLERS", 8)
CreateESPToggle("ESP SURVIVORS", "SURVIVORS", 41)
CreateESPToggle("ESP SPECTATORS", "SPECTATORS", 74)
CreateESPToggle("ESP GENERATORS", "GENERATORS", 107)

local ESPInfo = Instance.new("TextLabel")
ESPInfo.Name = "ESPInfo"
ESPInfo.Size = UDim2.fromOffset(186, 50)
ESPInfo.Position = UDim2.fromOffset(6, 154)
ESPInfo.BackgroundTransparency = 1
ESPInfo.Text = "Os ESPs continuam atualizando enquanto estiverem ligados."
ESPInfo.TextColor3 = Color3.fromRGB(165, 165, 165)
ESPInfo.TextSize = 9
ESPInfo.Font = Enum.Font.FredokaOne
ESPInfo.TextWrapped = true
ESPInfo.TextXAlignment = Enum.TextXAlignment.Left
ESPInfo.TextYAlignment = Enum.TextYAlignment.Top
ESPInfo.ZIndex = 5
ESPInfo.Parent = ESPPage

--//==============================================================
--// PÁGINA AUTO
--//==============================================================
local AutoEmpty = Instance.new("TextLabel")
AutoEmpty.Name = "AutoEmpty"
AutoEmpty.Size = UDim2.fromOffset(186, 40)
AutoEmpty.Position = UDim2.fromOffset(6, 105)
AutoEmpty.BackgroundTransparency = 1
AutoEmpty.Text = "VAZIO"
AutoEmpty.TextColor3 = Color3.fromRGB(165, 165, 165)
AutoEmpty.TextSize = 10
AutoEmpty.Font = Enum.Font.FredokaOne
AutoEmpty.TextWrapped = true
AutoEmpty.TextXAlignment = Enum.TextXAlignment.Center
AutoEmpty.TextYAlignment = Enum.TextYAlignment.Center
AutoEmpty.ZIndex = 5
AutoEmpty.Parent = AutoPage

--//==============================================================
--// ITEM: DETECÇÃO POR NOME
--//==============================================================
local ItemConfig = {
    MEDKIT = {
        Label = "MEDKIT",
        Aliases = {
            "Medkit",
            "Med Kit",
            "Med-Kit",
            "Medical Kit",
            "MedicalKit",
            "MedkitItem"
        }
    },
    BLOXYCOLA = {
        Label = "BLOXY COLA",
        Aliases = {
            "BloxyCola",
            "Bloxy Cola",
            "Bloxy-Cola",
            "Bloxycola",
            "BloxyColaItem"
        }
    }
}

local function NormalizeName(value)
    value = tostring(value or "")
    value = string.lower(value)
    value = value:gsub("[^%w]", "")
    return value
end

local function GetNameScore(instanceName, aliases)
    local normalizedName = NormalizeName(instanceName)
    if normalizedName == "" then
        return 0
    end

    local bestScore = 0

    for _, alias in ipairs(aliases) do
        local normalizedAlias = NormalizeName(alias)

        if normalizedAlias ~= "" then
            if normalizedName == normalizedAlias then
                bestScore = math.max(bestScore, 100)
            elseif normalizedName:find(normalizedAlias, 1, true) then
                bestScore = math.max(bestScore, 90)
            elseif normalizedAlias:find(normalizedName, 1, true) then
                bestScore = math.max(bestScore, 80)
            end
        end
    end

    return bestScore
end

local function FindItemByName(key)
    local config = ItemConfig[key]
    if not config then
        return nil
    end

    local bestInstance = nil
    local bestScore = 0

    local function ScanContainer(container)
        if not container then
            return
        end

        local ok, descendants = pcall(function()
            return container:GetDescendants()
        end)

        if not ok then
            return
        end

        for _, instance in ipairs(descendants) do
            local score = GetNameScore(instance.Name, config.Aliases)

            --// Só verifica se o objeto é renderizável quando o nome realmente bate.
            if score > bestScore and IsRenderableInstance(instance) then
                bestScore = score
                bestInstance = instance

                --// 100 = nome exato. Não precisa continuar procurando.
                if bestScore >= 100 then
                    return
                end
            end
        end
    end

    --// Primeiro procura nas áreas mais prováveis do mapa.
    local map = workspace:FindFirstChild("Map")
    if map then
        local ingame = map:FindFirstChild("Ingame")
        if ingame then
            ScanContainer(ingame)
        end
    end

    --// Depois procura em todo o Workspace como fallback.
    if not bestInstance or bestScore < 100 then
        ScanContainer(workspace)
    end

    return bestInstance
end

local DetectedItems = {
    MEDKIT = nil,
    BLOXYCOLA = nil
}

local SelectedItemKey = nil
local DropdownOpen = false

--//==============================================================
--// ITEM UI
--//==============================================================
local ItemTitle = Instance.new("TextLabel")
ItemTitle.Name = "ItemTitle"
ItemTitle.Size = UDim2.fromOffset(186, 22)
ItemTitle.Position = UDim2.fromOffset(6, 9)
ItemTitle.BackgroundTransparency = 1
ItemTitle.Text = "ESCOLHA O ITEM"
ItemTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
ItemTitle.TextSize = 11
ItemTitle.Font = Enum.Font.FredokaOne
ItemTitle.TextXAlignment = Enum.TextXAlignment.Left
ItemTitle.ZIndex = 5
ItemTitle.Parent = ItemPage

local DropdownButton = Instance.new("TextButton")
DropdownButton.Name = "ItemDropdown"
DropdownButton.Size = UDim2.fromOffset(186, 30)
DropdownButton.Position = UDim2.fromOffset(6, 36)
DropdownButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
DropdownButton.BorderSizePixel = 0
DropdownButton.Text = "Escolha um item"
DropdownButton.TextColor3 = Color3.fromRGB(190, 190, 190)
DropdownButton.TextSize = 10
DropdownButton.Font = Enum.Font.FredokaOne
DropdownButton.TextXAlignment = Enum.TextXAlignment.Left
DropdownButton.AutoButtonColor = false
DropdownButton.ZIndex = 7
DropdownButton.Parent = ItemPage

local DropdownPadding = Instance.new("UIPadding")
DropdownPadding.PaddingLeft = UDim.new(0, 10)
DropdownPadding.PaddingRight = UDim.new(0, 26)
DropdownPadding.Parent = DropdownButton

local DropdownCorner = Instance.new("UICorner")
DropdownCorner.CornerRadius = UDim.new(0, 6)
DropdownCorner.Parent = DropdownButton

local DropdownStroke = Instance.new("UIStroke")
DropdownStroke.Color = Color3.fromRGB(80, 80, 80)
DropdownStroke.Thickness = 1
DropdownStroke.Transparency = 0.35
DropdownStroke.Parent = DropdownButton

local Arrow = Instance.new("TextLabel")
Arrow.Name = "Arrow"
Arrow.Size = UDim2.fromOffset(18, 30)
Arrow.Position = UDim2.new(1, -22, 0, 0)
Arrow.BackgroundTransparency = 1
Arrow.Text = "▼"
Arrow.TextColor3 = Color3.fromRGB(200, 200, 200)
Arrow.TextSize = 9
Arrow.Font = Enum.Font.FredokaOne
Arrow.TextXAlignment = Enum.TextXAlignment.Center
Arrow.TextYAlignment = Enum.TextYAlignment.Center
Arrow.ZIndex = 8
Arrow.Parent = DropdownButton

local DropdownList = Instance.new("Frame")
DropdownList.Name = "DropdownList"
DropdownList.Size = UDim2.fromOffset(186, 0)
DropdownList.Position = UDim2.fromOffset(6, 68)
DropdownList.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
DropdownList.BorderSizePixel = 0
DropdownList.Visible = false
DropdownList.ClipsDescendants = true
DropdownList.ZIndex = 20
DropdownList.Parent = ItemPage

local DropdownListCorner = Instance.new("UICorner")
DropdownListCorner.CornerRadius = UDim.new(0, 6)
DropdownListCorner.Parent = DropdownList

local DropdownListStroke = Instance.new("UIStroke")
DropdownListStroke.Color = Color3.fromRGB(80, 80, 80)
DropdownListStroke.Thickness = 1
DropdownListStroke.Transparency = 0.25
DropdownListStroke.Parent = DropdownList

local ItemStatus = Instance.new("TextLabel")
ItemStatus.Name = "ItemStatus"
ItemStatus.Size = UDim2.fromOffset(186, 24)
ItemStatus.Position = UDim2.fromOffset(6, 188)
ItemStatus.BackgroundTransparency = 1
ItemStatus.Text = ""
ItemStatus.TextColor3 = Color3.fromRGB(170, 170, 170)
ItemStatus.TextSize = 9
ItemStatus.Font = Enum.Font.FredokaOne
ItemStatus.TextWrapped = true
ItemStatus.TextXAlignment = Enum.TextXAlignment.Center
ItemStatus.ZIndex = 5
ItemStatus.Parent = ItemPage

local TeleportButton = Instance.new("TextButton")
TeleportButton.Name = "TeleportItem"
TeleportButton.Size = UDim2.fromOffset(186, 30)
TeleportButton.Position = UDim2.fromOffset(6, 150)
TeleportButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
TeleportButton.BorderSizePixel = 0
TeleportButton.Text = "TELEPORTAR ITEM"
TeleportButton.TextColor3 = Color3.fromRGB(150, 150, 150)
TeleportButton.TextSize = 10
TeleportButton.Font = Enum.Font.FredokaOne
TeleportButton.AutoButtonColor = false
TeleportButton.ZIndex = 6
TeleportButton.Parent = ItemPage

local TeleportCorner = Instance.new("UICorner")
TeleportCorner.CornerRadius = UDim.new(0, 6)
TeleportCorner.Parent = TeleportButton

local TeleportStroke = Instance.new("UIStroke")
TeleportStroke.Color = Color3.fromRGB(80, 80, 80)
TeleportStroke.Thickness = 1
TeleportStroke.Transparency = 0.35
TeleportStroke.Parent = TeleportButton

local ItemHint = Instance.new("TextLabel")
ItemHint.Name = "ItemHint"
ItemHint.Size = UDim2.fromOffset(186, 42)
ItemHint.Position = UDim2.fromOffset(6, 80)
ItemHint.BackgroundTransparency = 1
ItemHint.Text = "Os itens são procurados pelo nome no mapa."
ItemHint.TextColor3 = Color3.fromRGB(155, 155, 155)
ItemHint.TextSize = 9
ItemHint.Font = Enum.Font.FredokaOne
ItemHint.TextWrapped = true
ItemHint.TextXAlignment = Enum.TextXAlignment.Left
ItemHint.TextYAlignment = Enum.TextYAlignment.Top
ItemHint.ZIndex = 5
ItemHint.Parent = ItemPage

local DropdownOptionButtons = {}

local function SetItemStatus(message, color)
    ItemStatus.Text = message or ""
    ItemStatus.TextColor3 = color or Color3.fromRGB(170, 170, 170)
end

local function CloseDropdown()
    DropdownOpen = false
    DropdownList.Visible = false
    DropdownList.Size = UDim2.fromOffset(186, 0)
    Arrow.Text = "▼"
end

local function OpenDropdown()
    DropdownOpen = true
    DropdownList.Visible = true
    Arrow.Text = "▲"

    local detectedCount = 0
    for _, key in ipairs({"MEDKIT", "BLOXYCOLA"}) do
        if DetectedItems[key] then
            detectedCount = detectedCount + 1
        end
    end

    local height = math.max(30, detectedCount * 30)
    if detectedCount == 0 then
        height = 30
    end

    DropdownList.Size = UDim2.fromOffset(186, height)
end

local function SelectItem(key)
    if key and DetectedItems[key] then
        SelectedItemKey = key
        DropdownButton.Text = ItemConfig[key].Label
        DropdownButton.TextColor3 = Color3.fromRGB(225, 225, 225)
        TeleportButton.BackgroundColor3 = Color3.fromRGB(60, 210, 100)
        TeleportButton.TextColor3 = Color3.fromRGB(0, 0, 0)
        SetItemStatus("Item selecionado: " .. ItemConfig[key].Label, Color3.fromRGB(190, 190, 190))
    else
        SelectedItemKey = nil
        DropdownButton.Text = "Nenhum item encontrado"
        DropdownButton.TextColor3 = Color3.fromRGB(175, 175, 175)
        TeleportButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        TeleportButton.TextColor3 = Color3.fromRGB(150, 150, 150)
    end

    CloseDropdown()
end

local function RebuildDropdownOptions()
    for _, button in pairs(DropdownOptionButtons) do
        pcall(function()
            button:Destroy()
        end)
    end

    table.clear(DropdownOptionButtons)

    local y = 0
    local foundAny = false

    for _, key in ipairs({"MEDKIT", "BLOXYCOLA"}) do
        local item = DetectedItems[key]

        if item then
            foundAny = true

            local option = Instance.new("TextButton")
            option.Name = key .. "Option"
            option.Size = UDim2.fromOffset(184, 28)
            option.Position = UDim2.fromOffset(1, y + 1)
            option.BackgroundColor3 = SelectedItemKey == key
                and Color3.fromRGB(60, 210, 100)
                or Color3.fromRGB(30, 30, 30)
            option.BorderSizePixel = 0
            option.Text = ItemConfig[key].Label
            option.TextColor3 = SelectedItemKey == key
                and Color3.fromRGB(0, 0, 0)
                or Color3.fromRGB(225, 225, 225)
            option.TextSize = 10
            option.Font = Enum.Font.FredokaOne
            option.TextXAlignment = Enum.TextXAlignment.Left
            option.AutoButtonColor = false
            option.ZIndex = 21
            option.Parent = DropdownList

            local padding = Instance.new("UIPadding")
            padding.PaddingLeft = UDim.new(0, 10)
            padding.Parent = option

            option.Activated:Connect(function()
                SelectItem(key)
            end)

            table.insert(DropdownOptionButtons, option)
            y = y + 30
        end
    end

    if not foundAny then
        local option = Instance.new("TextLabel")
        option.Name = "NoItems"
        option.Size = UDim2.fromOffset(184, 28)
        option.Position = UDim2.fromOffset(1, 1)
        option.BackgroundTransparency = 1
        option.Text = "Nenhum item encontrado"
        option.TextColor3 = Color3.fromRGB(145, 145, 145)
        option.TextSize = 9
        option.Font = Enum.Font.FredokaOne
        option.TextXAlignment = Enum.TextXAlignment.Center
        option.TextYAlignment = Enum.TextYAlignment.Center
        option.ZIndex = 21
        option.Parent = DropdownList
        table.insert(DropdownOptionButtons, option)
    end

    local count = foundAny and #DropdownOptionButtons or 1
    DropdownList.Size = UDim2.fromOffset(186, DropdownOpen and math.max(30, count * 30) or 0)
end

local function RefreshDetectedItems()
    local oldSelected = SelectedItemKey

    DetectedItems.MEDKIT = FindItemByName("MEDKIT")
    DetectedItems.BLOXYCOLA = FindItemByName("BLOXYCOLA")

    if oldSelected and DetectedItems[oldSelected] then
        DropdownButton.Text = ItemConfig[oldSelected].Label
        DropdownButton.TextColor3 = Color3.fromRGB(225, 225, 225)
    elseif oldSelected then
        SelectedItemKey = nil
        DropdownButton.Text = "Nenhum item encontrado"
        DropdownButton.TextColor3 = Color3.fromRGB(175, 175, 175)
    end

    if not SelectedItemKey then
        if DetectedItems.MEDKIT or DetectedItems.BLOXYCOLA then
            DropdownButton.Text = "Escolha um item"
            DropdownButton.TextColor3 = Color3.fromRGB(190, 190, 190)
        else
            DropdownButton.Text = "Nenhum item encontrado"
            DropdownButton.TextColor3 = Color3.fromRGB(175, 175, 175)
        end
    end

    local selectedExists = SelectedItemKey and DetectedItems[SelectedItemKey]

    if not selectedExists then
        TeleportButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        TeleportButton.TextColor3 = Color3.fromRGB(150, 150, 150)
    else
        TeleportButton.BackgroundColor3 = Color3.fromRGB(60, 210, 100)
        TeleportButton.TextColor3 = Color3.fromRGB(0, 0, 0)
    end

    RebuildDropdownOptions()
end

DropdownButton.Activated:Connect(function()
    if DropdownOpen then
        CloseDropdown()
    else
        RefreshDetectedItems()
        OpenDropdown()
        RebuildDropdownOptions()
    end
end)

--//==============================================================
--// TELEPORTAR ITEM
--//==============================================================
local function GetCharacterRoot()
    local character = LocalPlayer and LocalPlayer.Character
    if not character then
        return nil
    end

    return character:FindFirstChild("HumanoidRootPart")
end

local function MoveObjectTo(object, targetCFrame)
    if not object then
        return false, "Objeto inválido."
    end

    --// Model / Tool / BasePart: usa PivotTo quando disponível.
    local canPivot = false
    pcall(function()
        canPivot = object:IsA("Model") or object:IsA("BasePart")
    end)

    if canPivot then
        local ok, errorMessage = pcall(function()
            object:PivotTo(targetCFrame)
        end)

        if ok then
            return true
        end

        if object:IsA("BasePart") then
            local partOk = pcall(function()
                object.CFrame = targetCFrame
            end)

            if partOk then
                return true
            end
        end

        return false, errorMessage
    end

    --// Objetos como Folder: move as BaseParts preservando a posição relativa.
    local rootPart = GetFirstBasePart(object)
    if not rootPart then
        return false, "O item não possui BasePart."
    end

    local parts = {}
    local okDesc, descendants = pcall(function()
        return object:GetDescendants()
    end)

    if okDesc then
        for _, descendant in ipairs(descendants) do
            if descendant:IsA("BasePart") then
                table.insert(parts, descendant)
            end
        end
    end

    if #parts == 0 and rootPart:IsA("BasePart") then
        table.insert(parts, rootPart)
    end

    for _, part in ipairs(parts) do
        local relative = rootPart.CFrame:ToObjectSpace(part.CFrame)
        part.CFrame = targetCFrame * relative
        part.AssemblyLinearVelocity = Vector3.zero
        part.AssemblyAngularVelocity = Vector3.zero
    end

    return true
end

local function TeleportSelectedItem()
    if not SelectedItemKey then
        SetItemStatus("Escolha um item primeiro.", Color3.fromRGB(255, 220, 80))
        return
    end

    local root = GetCharacterRoot()
    if not root then
        SetItemStatus("Personagem não encontrado.", Color3.fromRGB(255, 90, 90))
        return
    end

    local currentItem = FindItemByName(SelectedItemKey)
    if not currentItem then
        DetectedItems[SelectedItemKey] = nil
        RefreshDetectedItems()
        SetItemStatus("Item não encontrado no mapa.", Color3.fromRGB(255, 90, 90))
        return
    end

    DetectedItems[SelectedItemKey] = currentItem

    local targetCFrame = root.CFrame * CFrame.new(0, 2, -3)
    local success, errorMessage = MoveObjectTo(currentItem, targetCFrame)

    if success then
        SetItemStatus(
            "Teletransportado: " .. ItemConfig[SelectedItemKey].Label,
            Color3.fromRGB(60, 210, 100)
        )
    else
        SetItemStatus(
            "Falha: " .. tostring(errorMessage),
            Color3.fromRGB(255, 90, 90)
        )
    end
end

TeleportButton.Activated:Connect(TeleportSelectedItem)

--//==============================================================
--// ATUALIZAÇÃO CONTÍNUA
--//==============================================================
local LastESPUpdate = 0
local LastItemUpdate = 0
local Alive = true

ScreenGui.AncestryChanged:Connect(function(_, parent)
    if not parent then
        Alive = false
    end
end)

--// Atualiza quando algo novo entra/sai do Workspace.
workspace.DescendantAdded:Connect(function(instance)
    if not Alive then
        return
    end

    task.defer(function()
        if not Alive then
            return
        end

        for key, enabled in pairs(ESPStates) do
            if enabled then
                if key == "GENERATORS" then
                    if instance.Name == "Generator" then
                        pcall(function()
                            ApplyESP(instance, ESPColors.GENERATORS, "GENERATORS")
                        end)
                    end
                else
                    pcall(function()
                        if instance.Parent == GetESPFolder(key) then
                            ApplyESP(instance, ESPColors[key], key)
                        end
                    end)
                end
            end
        end

    end)
end)

workspace.DescendantRemoving:Connect(function(instance)
    if TrackedESP[instance] then
        TrackedESP[instance] = nil
    end

    task.defer(function()
        if not Alive then
            return
        end

        if CurrentPage == "ITEM" then
            pcall(RefreshDetectedItems)
        end
    end)
end)

task.spawn(function()
    task.wait(0.2)

    while Alive and ScreenGui and ScreenGui.Parent do
        local now = os.clock()

        if now - LastESPUpdate >= 0.4 then
            LastESPUpdate = now
            pcall(SyncAllESP)
        end

        if now - LastItemUpdate >= 0.8 then
            LastItemUpdate = now
            pcall(RefreshDetectedItems)
        end

        task.wait(0.1)
    end
end)

--// Primeira atualização.
pcall(SyncAllESP)
pcall(RefreshDetectedItems)

warn("[NORLI HUB] carregado com 3 páginas, ESP permanente e Item Dropdown")
