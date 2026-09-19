--// NORLI HUB
--// Interface + ESP System + Item Grabber 3D
--// CORRIGIDO: compatibilidade de GUI, botões mobile e ordem das funções

local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

--// PARENT SEGURO DA INTERFACE
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

--// LIMPA VERSÃO ANTIGA SE EXISTIR
pcall(function()
	local OldGui = GuiParent:FindFirstChild("NorliHub")
	if OldGui then
		OldGui:Destroy()
	end
end)

pcall(function()
	local OldCoreGui = CoreGui:FindFirstChild("NorliHub")
	if OldCoreGui then
		OldCoreGui:Destroy()
	end
end)

--// ESTADO DOS ESPs
local ESPStates = {
	KILLERS = false,
	SURVIVORS = false,
	SPECTATORS = false,
	GENERATORS = false
}

--// CORES DOS ESPs
local COLORS = {
	KILLERS = Color3.fromRGB(255, 0, 0),
	SURVIVORS = Color3.fromRGB(0, 255, 0),
	SPECTATORS = Color3.fromRGB(255, 255, 255),
	GENERATORS = Color3.fromRGB(255, 255, 0)
}

--// CACHE DE OBJETOS RASTREADOS
local TrackedObjects = {}

--// FUNÇÃO SEGURA PARA VERIFICAR SE O OBJETO AINDA ESTÁ NO WORKSPACE
local function IsInWorkspace(instance)
	if not instance then
		return false
	end

	local ok, result = pcall(function()
		return instance:IsDescendantOf(workspace)
	end)

	return ok and result
end

--// RETORNA A PRIMEIRA BASEPART DENTRO DE QUALQUER OBJETO
local function GetFirstBasePart(instance)
	if not instance then
		return nil
	end

	local okIsA, isBasePart = pcall(function()
		return instance:IsA("BasePart")
	end)

	if okIsA and isBasePart then
		return instance
	end

	local okDesc, descendants = pcall(function()
		return instance:GetDescendants()
	end)

	if not okDesc then
		return nil
	end

	for _, desc in ipairs(descendants) do
		local okDescIsA, descIsBasePart = pcall(function()
			return desc:IsA("BasePart")
		end)
		if okDescIsA and descIsBasePart then
			return desc
		end
	end

	return nil
end

--// PASTA DOS GERADORES
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

--// APLICA OU REMOVE AURA
local function ApplyAura(target, color, toggleKey)
	if not IsInWorkspace(target) then
		return
	end

	local tag = "NorliESP_Aura"
	local existing = target:FindFirstChild(tag)

	if existing and existing:IsA("Highlight") and existing.FillColor == color then
		TrackedObjects[target] = {
			Color = color,
			ToggleKey = toggleKey
		}
		return
	end

	if existing then
		pcall(function()
			existing:Destroy()
		end)
	end

	local highlight = Instance.new("Highlight")
	highlight.Name = tag
	highlight.FillColor = color
	highlight.OutlineColor = color
	highlight.FillTransparency = 0.7
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

	local okTargetType, targetType = pcall(function()
		if target:IsA("Model") then
			return "Model"
		elseif target:IsA("BasePart") then
			return "BasePart"
		end
		return "Other"
	end)

	if okTargetType and targetType == "Model" then
		highlight.Adornee = target
	elseif okTargetType and targetType == "BasePart" then
		highlight.Adornee = target
	else
		local part = GetFirstBasePart(target)
		if part then
			highlight.Adornee = part
		else
			highlight:Destroy()
			return
		end
	end

	local parentOk = pcall(function()
		highlight.Parent = target
	end)

	if not parentOk then
		pcall(function()
			highlight:Destroy()
		end)
		return
	end

	TrackedObjects[target] = {
		Color = color,
		ToggleKey = toggleKey
	}
end

--// LIMPA AURAS INVÁLIDAS
local function CleanInvalidAuras()
	for obj, data in pairs(TrackedObjects) do
		local stillValidObject = IsInWorkspace(obj)

		if not stillValidObject then
			TrackedObjects[obj] = nil
		else
			local isValid = false

			if data and ESPStates[data.ToggleKey] then
				if data.ToggleKey == "KILLERS" then
					isValid = obj.Parent and obj.Parent.Name == "Killers"
				elseif data.ToggleKey == "SURVIVORS" then
					isValid = obj.Parent and obj.Parent.Name == "Survivors"
				elseif data.ToggleKey == "SPECTATORS" then
					isValid = obj.Parent and obj.Parent.Name == "Spectating"
				elseif data.ToggleKey == "GENERATORS" then
					local mapFolder = GetMapFolder()
					isValid = obj.Name == "Generator" and mapFolder ~= nil and obj:IsDescendantOf(mapFolder)
				end
			end

			if not isValid then
				local aura = obj:FindFirstChild("NorliESP_Aura")
				if aura then
					pcall(function()
						aura:Destroy()
					end)
				end

				TrackedObjects[obj] = nil
			end
		end
	end
end

--// SINCRONIZA TODOS OS ESPs
local function SyncAllAuras()
	CleanInvalidAuras()

	local playersFolder = workspace:FindFirstChild("Players")
	if playersFolder then
		if ESPStates.KILLERS then
			local killersFolder = playersFolder:FindFirstChild("Killers")
			if killersFolder then
				for _, child in pairs(killersFolder:GetChildren()) do
					ApplyAura(child, COLORS.KILLERS, "KILLERS")
				end
			end
		end

		if ESPStates.SURVIVORS then
			local survivorsFolder = playersFolder:FindFirstChild("Survivors")
			if survivorsFolder then
				for _, child in pairs(survivorsFolder:GetChildren()) do
					ApplyAura(child, COLORS.SURVIVORS, "SURVIVORS")
				end
			end
		end

		if ESPStates.SPECTATORS then
			local spectatingFolder = playersFolder:FindFirstChild("Spectating")
			if spectatingFolder then
				for _, child in pairs(spectatingFolder:GetChildren()) do
					ApplyAura(child, COLORS.SPECTATORS, "SPECTATORS")
				end
			end
		end
	end

	if ESPStates.GENERATORS then
		local mapFolder = GetMapFolder()
		if mapFolder then
			for _, desc in pairs(mapFolder:GetDescendants()) do
				if desc.Name == "Generator" then
					ApplyAura(desc, COLORS.GENERATORS, "GENERATORS")
				end
			end
		end
	end
end

--// SCREEN GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NorliHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999999

local screenParented = pcall(function()
	ScreenGui.Parent = GuiParent
end)

if not screenParented then
	pcall(function()
		ScreenGui.Parent = CoreGui
	end)
end

if not ScreenGui.Parent then
	pcall(function()
		ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	end)
end

--// MAIN
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

--// TEXTURA
local Texture = Instance.new("ImageLabel")
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

--// CAMADA ESCURA
local DarkOverlay = Instance.new("Frame")
DarkOverlay.Size = UDim2.fromScale(1, 1)
DarkOverlay.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
DarkOverlay.BackgroundTransparency = 0.35
DarkOverlay.BorderSizePixel = 0
DarkOverlay.ZIndex = 2
DarkOverlay.Parent = Main

local OverlayCorner = Instance.new("UICorner")
OverlayCorner.CornerRadius = UDim.new(0, 8)
OverlayCorner.Parent = DarkOverlay

--// LOGO DO TÍTULO
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

--// TÍTULO
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

--// BOTÃO X
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

--// SCROLL
local OptionsScroll = Instance.new("ScrollingFrame")
OptionsScroll.Name = "OptionsScroll"
OptionsScroll.Size = UDim2.fromOffset(198, 283)
OptionsScroll.Position = UDim2.fromOffset(6, 37)
OptionsScroll.BackgroundTransparency = 1
OptionsScroll.BorderSizePixel = 0
OptionsScroll.CanvasSize = UDim2.new(1, 0, 0, 0)
OptionsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
OptionsScroll.ScrollingDirection = Enum.ScrollingDirection.Y
OptionsScroll.ScrollBarThickness = 4
OptionsScroll.ScrollBarImageColor3 = Color3.fromRGB(90, 90, 90)
OptionsScroll.ScrollBarImageTransparency = 0.35
OptionsScroll.ClipsDescendants = true
OptionsScroll.ZIndex = 4
OptionsScroll.Parent = Main

--// BOTÃO FLUTUANTE
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
local dragStart
local startPosition
local dragInput

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

--// FECHAR / REABRIR
CloseButton.Activated:Connect(function()
	Main.Visible = false
	FloatingButton.Visible = true
end)

FloatingButton.Activated:Connect(function()
	Main.Visible = true
	FloatingButton.Visible = false
end)

--// FUNÇÃO PARA CRIAR TOGGLE
local function CreateToggle(name, yPosition, stateKey)
	local Button = Instance.new("TextButton")
	Button.Name = name .. "Toggle"
	Button.Size = UDim2.fromOffset(42, 24)
	Button.Position = UDim2.fromOffset(12, yPosition)
	Button.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	Button.BorderSizePixel = 0
	Button.Text = ""
	Button.AutoButtonColor = false
	Button.ZIndex = 5
	Button.Parent = OptionsScroll

	local ButtonCorner = Instance.new("UICorner")
	ButtonCorner.CornerRadius = UDim.new(0, 6)
	ButtonCorner.Parent = Button

	local Indicator = Instance.new("Frame")
	Indicator.Name = "Indicator"
	Indicator.Size = UDim2.fromOffset(18, 18)
	Indicator.Position = UDim2.fromOffset(3, 3)
	Indicator.BackgroundColor3 = Color3.fromRGB(220, 55, 55)
	Indicator.BorderSizePixel = 0
	Indicator.ZIndex = 6
	Indicator.Parent = Button

	local IndicatorCorner = Instance.new("UICorner")
	IndicatorCorner.CornerRadius = UDim.new(0, 4)
	IndicatorCorner.Parent = Indicator

	local Glow = Instance.new("UIStroke")
	Glow.Name = "Glow"
	Glow.Thickness = 1
	Glow.Transparency = 0.35
	Glow.Color = Color3.fromRGB(220, 55, 55)
	Glow.Parent = Indicator

	local Label = Instance.new("TextLabel")
	Label.Name = name .. "Label"
	Label.Size = UDim2.fromOffset(125, 20)
	Label.Position = UDim2.fromOffset(62, yPosition + 2)
	Label.BackgroundTransparency = 1
	Label.Text = name
	Label.TextColor3 = Color3.fromRGB(225, 225, 225)
	Label.TextSize = 11
	Label.Font = Enum.Font.FredokaOne
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.TextYAlignment = Enum.TextYAlignment.Center
	Label.TextWrapped = false
	Label.ZIndex = 5
	Label.Parent = OptionsScroll

	local Enabled = false

	Button.Activated:Connect(function()
		Enabled = not Enabled
		ESPStates[stateKey] = Enabled

		local position
		local color

		if Enabled then
			position = UDim2.new(1, -21, 0, 3)
			color = Color3.fromRGB(60, 210, 100)
		else
			position = UDim2.fromOffset(3, 3)
			color = Color3.fromRGB(220, 55, 55)
		end

		TweenService:Create(
			Indicator,
			TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Position = position,
				BackgroundColor3 = color
			}
		):Play()

		TweenService:Create(
			Glow,
			TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Color = color
			}
		):Play()

		pcall(SyncAllAuras)
	end)
end

--// TOGGLES ESP
CreateToggle("ESP KILLERS", 8, "KILLERS")
CreateToggle("ESP SURVIVORS", 41, "SURVIVORS")
CreateToggle("ESP SPECTATORS", 74, "SPECTATORS")
CreateToggle("ESP GENERATORS", 107, "GENERATORS")

--// ITEM GRABBER CONFIG
local ItemConfig = {
	MEDKIT = {
		Label = "MEDKIT",
		Path = {"Map", "Ingame", "Medkit"},
		Color = Color3.fromRGB(255, 90, 90)
	},
	BLOXYCOLA = {
		Label = "BLOXY COLA",
		Path = {"Map", "Ingame", "Map", "BloxyCola"},
		Color = Color3.fromRGB(90, 170, 255)
	}
}

local function ResolvePath(path)
	local current = workspace

	for _, name in ipairs(path) do
		if not current then
			return nil
		end

		local ok, nextObject = pcall(function()
			return current:FindFirstChild(name)
		end)

		if not ok or not nextObject then
			return nil
		end

		current = nextObject
	end

	return current
end

local function GetItem(key)
	local config = ItemConfig[key]
	if not config then
		return nil
	end

	return ResolvePath(config.Path)
end

--// SEPARADOR ITEM GRABBER
local ItemSeparator = Instance.new("TextLabel")
ItemSeparator.Name = "ItemSeparator"
ItemSeparator.Size = UDim2.fromOffset(186, 18)
ItemSeparator.Position = UDim2.fromOffset(12, 146)
ItemSeparator.BackgroundTransparency = 1
ItemSeparator.Text = "ITEM GRABBER"
ItemSeparator.TextColor3 = Color3.fromRGB(255, 255, 255)
ItemSeparator.TextSize = 11
ItemSeparator.Font = Enum.Font.FredokaOne
ItemSeparator.TextXAlignment = Enum.TextXAlignment.Left
ItemSeparator.TextStrokeTransparency = 0.6
ItemSeparator.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
ItemSeparator.ZIndex = 5
ItemSeparator.Parent = OptionsScroll

--// LABEL SEM ITEM
local NoItemLabel = Instance.new("TextLabel")
NoItemLabel.Name = "NoItemLabel"
NoItemLabel.Size = UDim2.fromOffset(186, 24)
NoItemLabel.Position = UDim2.fromOffset(12, 166)
NoItemLabel.BackgroundTransparency = 1
NoItemLabel.Text = "Procurando itens no mapa..."
NoItemLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
NoItemLabel.TextSize = 10
NoItemLabel.Font = Enum.Font.FredokaOne
NoItemLabel.TextXAlignment = Enum.TextXAlignment.Center
NoItemLabel.ZIndex = 5
NoItemLabel.Parent = OptionsScroll

--// BOTÕES DE ITEM
local SelectedItemKey = nil
local ItemButtons = {}
local SelectItem
local RefreshItemAvailability

local function MakeItemButton(key, xPosition)
	local config = ItemConfig[key]
	local Button = Instance.new("TextButton")
	Button.Name = key .. "ItemButton"
	Button.Size = UDim2.fromOffset(88, 24)
	Button.Position = UDim2.fromOffset(xPosition, 166)
	Button.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	Button.BorderSizePixel = 0
	Button.Text = config.Label
	Button.TextColor3 = Color3.fromRGB(225, 225, 225)
	Button.TextSize = 9
	Button.Font = Enum.Font.FredokaOne
	Button.AutoButtonColor = false
	Button.Visible = false
	Button.ZIndex = 5
	Button.Parent = OptionsScroll

	local ButtonCorner = Instance.new("UICorner")
	ButtonCorner.CornerRadius = UDim.new(0, 6)
	ButtonCorner.Parent = Button

	local ButtonStroke = Instance.new("UIStroke")
	ButtonStroke.Color = Color3.fromRGB(80, 80, 80)
	ButtonStroke.Thickness = 1
	ButtonStroke.Transparency = 0.45
	ButtonStroke.Parent = Button

	Button.Activated:Connect(function()
		if SelectItem then
			SelectItem(key)
		end
	end)

	return Button
end

ItemButtons.MEDKIT = MakeItemButton("MEDKIT", 12)
ItemButtons.BLOXYCOLA = MakeItemButton("BLOXYCOLA", 106)

--// PREVIEW 3D
local PreviewFrame = Instance.new("ViewportFrame")
PreviewFrame.Name = "PreviewFrame"
PreviewFrame.Size = UDim2.fromOffset(186, 110)
PreviewFrame.Position = UDim2.fromOffset(12, 196)
PreviewFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
PreviewFrame.BackgroundTransparency = 0.2
PreviewFrame.BorderSizePixel = 0
PreviewFrame.ClipDescendants = true
PreviewFrame.ZIndex = 5
PreviewFrame.Parent = OptionsScroll

local PreviewCorner = Instance.new("UICorner")
PreviewCorner.CornerRadius = UDim.new(0, 6)
PreviewCorner.Parent = PreviewFrame

local PreviewStroke = Instance.new("UIStroke")
PreviewStroke.Color = Color3.fromRGB(70, 70, 70)
PreviewStroke.Thickness = 1
PreviewStroke.Transparency = 0.35
PreviewStroke.Parent = PreviewFrame

local PreviewCamera = Instance.new("Camera")
PreviewCamera.Name = "PreviewCamera"
PreviewCamera.FieldOfView = 70
PreviewCamera.Parent = PreviewFrame
PreviewFrame.CurrentCamera = PreviewCamera

local PreviewStatusLabel = Instance.new("TextLabel")
PreviewStatusLabel.Name = "PreviewStatusLabel"
PreviewStatusLabel.Size = UDim2.fromScale(1, 1)
PreviewStatusLabel.Position = UDim2.fromOffset(0, 0)
PreviewStatusLabel.BackgroundTransparency = 1
PreviewStatusLabel.Text = "Nenhum item selecionado"
PreviewStatusLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
PreviewStatusLabel.TextSize = 10
PreviewStatusLabel.Font = Enum.Font.FredokaOne
PreviewStatusLabel.TextWrapped = true
PreviewStatusLabel.ZIndex = 6
PreviewStatusLabel.Parent = PreviewFrame

--// BOTÃO PEGAR ITEM
local GrabButton = Instance.new("TextButton")
GrabButton.Name = "GrabButton"
GrabButton.Size = UDim2.fromOffset(186, 28)
GrabButton.Position = UDim2.fromOffset(12, 312)
GrabButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
GrabButton.BorderSizePixel = 0
GrabButton.Text = "PEGAR ITEM"
GrabButton.TextColor3 = Color3.fromRGB(150, 150, 150)
GrabButton.TextSize = 11
GrabButton.Font = Enum.Font.FredokaOne
GrabButton.AutoButtonColor = false
GrabButton.ZIndex = 5
GrabButton.Parent = OptionsScroll

local GrabCorner = Instance.new("UICorner")
GrabCorner.CornerRadius = UDim.new(0, 6)
GrabCorner.Parent = GrabButton

local GrabStroke = Instance.new("UIStroke")
GrabStroke.Color = Color3.fromRGB(80, 80, 80)
GrabStroke.Thickness = 1
GrabStroke.Transparency = 0.45
GrabStroke.Parent = GrabButton

--// STATUS DO ITEM
local ItemStatus = Instance.new("TextLabel")
ItemStatus.Name = "ItemStatus"
ItemStatus.Size = UDim2.fromOffset(186, 20)
ItemStatus.Position = UDim2.fromOffset(12, 344)
ItemStatus.BackgroundTransparency = 1
ItemStatus.Text = ""
ItemStatus.TextColor3 = Color3.fromRGB(255, 255, 255)
ItemStatus.TextSize = 9
ItemStatus.Font = Enum.Font.FredokaOne
ItemStatus.TextXAlignment = Enum.TextXAlignment.Center
ItemStatus.TextWrapped = true
ItemStatus.ZIndex = 5
ItemStatus.Parent = OptionsScroll

--// VARIÁVEIS DO PREVIEW
local PreviewClone = nil
local PreviewHighlight = nil
local PreviewCenter = Vector3.new(0, 0, 0)
local PreviewDistance = 5
local PreviewRotation = 0

local function ClearPreview()
	if PreviewClone then
		pcall(function()
			PreviewClone:Destroy()
		end)
		PreviewClone = nil
	end

	if PreviewHighlight then
		pcall(function()
			PreviewHighlight:Destroy()
		end)
		PreviewHighlight = nil
	end

	PreviewStatusLabel.Visible = true
	PreviewStatusLabel.Text = "Nenhum item selecionado"
end

local function SanitizeClone(clone)
	if not clone then
		return
	end

	local ok, descendants = pcall(function()
		return clone:GetDescendants()
	end)

	if not ok then
		return
	end

	for _, desc in ipairs(descendants) do
		local shouldDestroy = false

		pcall(function()
			if desc:IsA("LuaSourceContainer")
				or desc:IsA("Sound")
				or desc:IsA("Animation") then
				shouldDestroy = true
			end
		end)

		if shouldDestroy then
			pcall(function()
				desc:Destroy()
			end)
		elseif desc:IsA("BasePart") then
			pcall(function()
				desc.Anchored = true
				desc.CanCollide = false
			end)
		end
	end
end

local function CloneForPreview(item)
	if not item then
		return nil
	end

	local clone

	local ok, result = pcall(function()
		if item:IsA("Tool") then
			local handle = item:FindFirstChild("Handle")
			if handle and handle:IsA("BasePart") then
				return handle:Clone()
			else
				return item:Clone()
			end
		elseif item:IsA("Folder") then
			local model = Instance.new("Model")
			model.Name = item.Name

			for _, child in ipairs(item:GetChildren()) do
				local childClone = child:Clone()
				if childClone then
					childClone.Parent = model
				end
			end

			return model
		else
			return item:Clone()
		end
	end)

	if not ok then
		return nil
	end

	clone = result
	SanitizeClone(clone)

	return clone
end

local function UpdatePreview()
	ClearPreview()

	if not SelectedItemKey then
		return
	end

	local item = GetItem(SelectedItemKey)

	if not item then
		PreviewStatusLabel.Text = "Item não encontrado"
		return
	end

	local clone = CloneForPreview(item)

	if not clone then
		PreviewStatusLabel.Text = "Falha ao clonar item"
		return
	end

	clone.Parent = PreviewFrame
	PreviewClone = clone

	local cf, size

	local boundsOk = pcall(function()
		if clone:IsA("Model") then
			cf, size = clone:GetBoundingBox()
		elseif clone:IsA("BasePart") then
			cf = clone.CFrame
			size = clone.Size
		else
			local firstPart = GetFirstBasePart(clone)
			if firstPart then
				cf = firstPart.CFrame
				size = firstPart.Size
			end
		end
	end)

	if not boundsOk or not cf or not size then
		PreviewStatusLabel.Visible = true
		PreviewStatusLabel.Text = "Não foi possível calcular o preview"
		return
	end

	if size.Magnitude <= 0 then
		size = Vector3.new(1, 1, 1)
	end

	PreviewCenter = cf.Position
	PreviewDistance = math.clamp(math.max(size.X, size.Y, size.Z) * 2.2 + 1.5, 2, 40)

	PreviewCamera.CFrame = CFrame.lookAt(
		PreviewCenter + Vector3.new(
			PreviewDistance * 0.45,
			PreviewDistance * 0.35,
			PreviewDistance * 0.8
		),
		PreviewCenter
	)

	local adornee = clone

	if not (clone:IsA("Model") or clone:IsA("BasePart")) then
		adornee = GetFirstBasePart(clone)
	end

	if adornee then
		local highlight = Instance.new("Highlight")
		highlight.Name = "NorliPreviewOutline"
		highlight.Adornee = adornee
		highlight.FillTransparency = 1
		highlight.OutlineTransparency = 0
		highlight.OutlineColor = ItemConfig[SelectedItemKey].Color
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.Parent = clone

		PreviewHighlight = highlight
	end

	PreviewStatusLabel.Visible = false
end

local function UpdateItemButtonsVisual()
	for key, button in pairs(ItemButtons) do
		if button.Visible then
			if SelectedItemKey == key then
				button.BackgroundColor3 = Color3.fromRGB(60, 210, 100)
				button.TextColor3 = Color3.fromRGB(0, 0, 0)
			else
				button.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
				button.TextColor3 = Color3.fromRGB(225, 225, 225)
			end
		end
	end
end

local function UpdateGrabButton()
	local item = SelectedItemKey and GetItem(SelectedItemKey)
	if item then
		GrabButton.BackgroundColor3 = Color3.fromRGB(60, 210, 100)
		GrabButton.TextColor3 = Color3.fromRGB(0, 0, 0)
	else
		GrabButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
		GrabButton.TextColor3 = Color3.fromRGB(150, 150, 150)
	end
end

--// CORREÇÃO PRINCIPAL: DECLARAÇÃO ANTECIPADA
SelectItem = function(key)
	local item = GetItem(key)

	if not item then
		if RefreshItemAvailability then
			RefreshItemAvailability()
		end
		return
	end

	SelectedItemKey = key
	UpdateItemButtonsVisual()
	UpdateGrabButton()
	UpdatePreview()
end

RefreshItemAvailability = function()
	local anyItem = false

	for key, _ in pairs(ItemConfig) do
		local item = GetItem(key)
		local exists = item ~= nil and item.Parent ~= nil and IsInWorkspace(item)

		local button = ItemButtons[key]
		if button then
			button.Visible = exists
		end

		if exists then
			anyItem = true
		end

		if SelectedItemKey == key and not exists then
			SelectedItemKey = nil
			UpdatePreview()
		end
	end

	NoItemLabel.Visible = not anyItem

	if SelectedItemKey and (not PreviewClone or not PreviewClone.Parent) then
		UpdatePreview()
	end

	UpdateItemButtonsVisual()
	UpdateGrabButton()
end

--// NOTIFICAÇÃO
local NotifyToken = 0

local function Notify(message, color)
	if not ItemStatus then
		return
	end

	NotifyToken = NotifyToken + 1
	local token = NotifyToken

	ItemStatus.Text = message
	ItemStatus.TextColor3 = color or Color3.fromRGB(255, 255, 255)

	task.delay(2.5, function()
		if token == NotifyToken and ItemStatus then
			ItemStatus.Text = ""
		end
	end)
end

--// TELEPORTAR ITEM
local function TeleportItem(key)
	local item = GetItem(key)

	if not item then
		Notify("Item não encontrado.", Color3.fromRGB(255, 90, 90))
		RefreshItemAvailability()
		return
	end

	local character = LocalPlayer and LocalPlayer.Character
	local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")

	if not humanoidRootPart then
		Notify("Personagem não encontrado.", Color3.fromRGB(255, 90, 90))
		return
	end

	local targetCFrame = humanoidRootPart.CFrame * CFrame.new(0, 2, -3)

	local success, errorMessage = pcall(function()
		if item:IsA("Model") then
			if not item.PrimaryPart then
				item.PrimaryPart = GetFirstBasePart(item)
			end

			if not item.PrimaryPart then
				error("Model sem parte válida.")
			end

			item:PivotTo(targetCFrame)

			for _, desc in pairs(item:GetDescendants()) do
				if desc:IsA("BasePart") then
					desc.Anchored = true
				end
			end
		elseif item:IsA("BasePart") then
			item.CFrame = targetCFrame
			item.Anchored = true
		elseif item:IsA("Tool") then
			local handle = item:FindFirstChild("Handle")

			if handle and handle:IsA("BasePart") then
				handle.CFrame = targetCFrame
				handle.Anchored = true
			else
				item.Parent = character
			end
		else
			local part = GetFirstBasePart(item)
			if not part then
				error("Objeto sem BasePart válida.")
			end

			local parentModel = part:FindFirstAncestorOfClass("Model")

			if parentModel then
				if not parentModel.PrimaryPart then
					parentModel.PrimaryPart = part
				end

				parentModel:PivotTo(targetCFrame)

				for _, desc in pairs(parentModel:GetDescendants()) do
					if desc:IsA("BasePart") then
						desc.Anchored = true
					end
				end
			else
				part.CFrame = targetCFrame
				part.Anchored = true
			end
		end
	end)

	if success then
		Notify("Item teleportado!", Color3.fromRGB(60, 210, 100))

		if SelectedItemKey == key then
			UpdatePreview()
		end
	else
		Notify("Falha: " .. tostring(errorMessage), Color3.fromRGB(255, 90, 90))
	end
end

GrabButton.Activated:Connect(function()
	if SelectedItemKey then
		TeleportItem(SelectedItemKey)
	else
		Notify("Selecione um item primeiro.", Color3.fromRGB(255, 220, 80))
	end
end)

--// ROTAÇÃO DO PREVIEW 3D
RunService.RenderStepped:Connect(function(deltaTime)
	if PreviewClone and PreviewClone.Parent and SelectedItemKey then
		PreviewRotation = (PreviewRotation + deltaTime * 35) % 360

		local rotationCF = CFrame.Angles(
			math.rad(-14),
			math.rad(PreviewRotation),
			0
		)

		local offset = rotationCF * Vector3.new(0, 0, PreviewDistance)

		PreviewCamera.CFrame = CFrame.lookAt(
			PreviewCenter + offset,
			PreviewCenter
		)
	end
end)

--// INICIALIZAÇÃO SEGURA

task.spawn(function()
	task.wait(0.35)

	pcall(function()
		RefreshItemAvailability()
	end)

	pcall(function()
		SyncAllAuras()
	end)

	while ScreenGui and ScreenGui.Parent do
		task.wait(1)

		pcall(function()
			SyncAllAuras()
		end)

		pcall(function()
			RefreshItemAvailability()
		end)
	end
end)

warn("[NORLI HUB] carregado com sucesso")
