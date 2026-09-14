--// Egg 3D Review + Teleporter
--// Versão compacta para celular / executor
--// Busca TODOS os objetos dentro de TODOS os SpawnedEggs em workspace.Map.Stages
--// Preview 3D virtualizado para não criar milhares de ViewportFrames ao mesmo tempo.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

--==================================================
-- CONFIG
--==================================================

local IMAGE_ID = "rbxassetid://6706685085"

local EGG_AREA_CFRAME = CFrame.new(
    -0.5,
    5608.68457,
    -1386.02295
)

local GUI_NAME = "Egg3DReviewCompact"

-- Tamanho aproximado 300x300, pensado para celular
local MAIN_SIZE = Vector2.new(300, 300)

-- Altura de cada item na lista
local ROW_HEIGHT = 94
local ROW_GAP = 6

-- Quantos previews 3D serão reutilizados.
-- Isso evita criar milhares de ViewportFrames ao mesmo tempo.
local VISIBLE_BUFFER = 5
local MAX_POOL = 18

-- Atualização periódica para capturar mudanças mesmo se o jogo trocar
-- os objetos sem disparar os eventos esperados.
local SCAN_INTERVAL = 1.5

--==================================================
-- HELPERS
--==================================================

local function findMapStages()
    local map = workspace:FindFirstChild("Map")
    if not map then
        return nil, nil
    end

    local stages = map:FindFirstChild("Stages")
    return map, stages
end

local _, Stages = findMapStages()

if not Stages then
    warn("[Egg3D] workspace.Map.Stages não encontrado.")
    return
end

local function safeDestroy(instance)
    if instance then
        pcall(function()
            instance:Destroy()
        end)
    end
end

local function getCharacterRoot()
    local character = LocalPlayer.Character
    if not character then
        return nil
    end

    return character:FindFirstChild("HumanoidRootPart")
end

local function teleportToCFrame(cf)
    local root = getCharacterRoot()
    if not root then
        return false
    end

    root.CFrame = cf + Vector3.new(0, 3, 0)
    return true
end

local function getObjectCFrame(object)
    if not object or not object.Parent then
        return nil
    end

    if object:IsA("Model") then
        local ok, pivot = pcall(function()
            return object:GetPivot()
        end)

        if ok then
            return pivot
        end
    elseif object:IsA("BasePart") then
        return object.CFrame
    elseif object:IsA("Folder") then
        local part = object:FindFirstChildWhichIsA("BasePart", true)
        if part then
            return part.CFrame
        end
    end

    local part = object:FindFirstChildWhichIsA("BasePart", true)
    if part then
        return part.CFrame
    end

    return nil
end

local function teleportToObject(object)
    local cf = getObjectCFrame(object)
    if not cf then
        return false
    end

    local root = getCharacterRoot()
    if not root then
        return false
    end

    root.CFrame = cf + Vector3.new(0, 4, 0)
    return true
end

--==================================================
-- LIMPAR VERSÃO ANTERIOR
--==================================================

pcall(function()
    local old = CoreGui:FindFirstChild(GUI_NAME)
    if old then
        old:Destroy()
    end
end)

--==================================================
-- GUI
--==================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = GUI_NAME
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.Parent = CoreGui

--==================================================
-- JANELA PRINCIPAL
--==================================================

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(MAIN_SIZE.X, MAIN_SIZE.Y)
Main.Position = UDim2.new(0.5, -MAIN_SIZE.X / 2, 0.5, -MAIN_SIZE.Y / 2)
Main.BackgroundColor3 = Color3.fromRGB(13, 10, 18)
Main.BackgroundTransparency = 0.08
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(157, 65, 255)
MainStroke.Thickness = 1.7
MainStroke.Parent = Main

--==================================================
-- HEADER
--==================================================

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 40)
Header.BackgroundTransparency = 1
Header.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -78, 1, 0)
Title.Position = UDim2.fromOffset(10, 0)
Title.BackgroundTransparency = 1
Title.Text = "🥚 Egg 3D Review"
Title.TextColor3 = Color3.fromRGB(240, 232, 248)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local HideButton = Instance.new("TextButton")
HideButton.Size = UDim2.fromOffset(28, 28)
HideButton.Position = UDim2.new(1, -34, 0, 6)
HideButton.BackgroundColor3 = Color3.fromRGB(31, 24, 40)
HideButton.Text = "−"
HideButton.TextColor3 = Color3.fromRGB(255, 255, 255)
HideButton.TextSize = 18
HideButton.Font = Enum.Font.GothamBold
HideButton.AutoButtonColor = true
HideButton.Parent = Header

local HideCorner = Instance.new("UICorner")
HideCorner.CornerRadius = UDim.new(0, 7)
HideCorner.Parent = HideButton

--==================================================
-- STATUS / TP ÁREA
--==================================================

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -110, 0, 24)
Status.Position = UDim2.fromOffset(10, 41)
Status.BackgroundTransparency = 1
Status.Text = "Carregando ovos..."
Status.TextColor3 = Color3.fromRGB(185, 168, 201)
Status.TextSize = 11
Status.Font = Enum.Font.Gotham
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = Main

local TPAreaButton = Instance.new("TextButton")
TPAreaButton.Size = UDim2.fromOffset(92, 25)
TPAreaButton.Position = UDim2.new(1, -102, 0, 40)
TPAreaButton.BackgroundColor3 = Color3.fromRGB(91, 42, 160)
TPAreaButton.Text = "TP Área"
TPAreaButton.TextColor3 = Color3.fromRGB(255, 255, 255)
TPAreaButton.TextSize = 11
TPAreaButton.Font = Enum.Font.GothamBold
TPAreaButton.Parent = Main

local TPAreaCorner = Instance.new("UICorner")
TPAreaCorner.CornerRadius = UDim.new(0, 6)
TPAreaCorner.Parent = TPAreaButton

--==================================================
-- LISTA VIRTUALIZADA
--==================================================

local List = Instance.new("ScrollingFrame")
List.Name = "EggList"
List.Size = UDim2.new(1, -14, 1, -74)
List.Position = UDim2.fromOffset(7, 70)
List.BackgroundColor3 = Color3.fromRGB(9, 7, 12)
List.BackgroundTransparency = 0.18
List.BorderSizePixel = 0
List.ScrollBarThickness = 4
List.ScrollBarImageTransparency = 0.15
List.CanvasSize = UDim2.fromOffset(0, 0)
List.ClipsDescendants = true
List.Active = true
List.Parent = Main

local ListCorner = Instance.new("UICorner")
ListCorner.CornerRadius = UDim.new(0, 8)
ListCorner.Parent = List

local EmptyLabel = Instance.new("TextLabel")
EmptyLabel.Size = UDim2.new(1, -20, 0, 50)
EmptyLabel.Position = UDim2.fromOffset(10, 80)
EmptyLabel.BackgroundTransparency = 1
EmptyLabel.Text = "Nenhum ovo encontrado."
EmptyLabel.TextColor3 = Color3.fromRGB(175, 162, 186)
EmptyLabel.TextSize = 12
EmptyLabel.Font = Enum.Font.GothamSemibold
EmptyLabel.Visible = false
EmptyLabel.Parent = List

--==================================================
-- ITEM DATA
--==================================================

local Items = {}
local ItemCount = 0
local CurrentSignature = ""
local Refreshing = false

local function clearItems()
    table.clear(Items)
end

local function collectAllEggs()
    local collected = {}

    -- Todas as pastas de áreas:
    -- workspace.Map.Stages.<Área>.SpawnedEggs
    for _, stage in ipairs(Stages:GetChildren()) do
        local spawnedEggs = stage:FindFirstChild("SpawnedEggs")

        if spawnedEggs then
            for _, object in ipairs(spawnedEggs:GetChildren()) do
                table.insert(collected, {
                    object = object,
                    stageName = stage.Name,
                    name = object.Name,
                    key = tostring(object:GetDebugId()) .. "|" .. stage.Name,
                })
            end
        end
    end

    -- Ordem consistente
    table.sort(collected, function(a, b)
        local an = string.lower(a.name)
        local bn = string.lower(b.name)

        if an == bn then
            return string.lower(a.stageName) < string.lower(b.stageName)
        end

        return an < bn
    end)

    return collected
end

local function makeSignature(list)
    local pieces = table.create(#list)

    for i, entry in ipairs(list) do
        local object = entry.object
        pieces[i] = table.concat({
            entry.stageName,
            entry.name,
            object and object.ClassName or "?",
            object and object:GetFullName() or "?",
        }, "||")
    end

    return table.concat(pieces, "###")
end

--==================================================
-- PREVIEW 3D
--==================================================

local function removeUnsafeDescendants(clone)
    for _, descendant in ipairs(clone:GetDescendants()) do
        if descendant:IsA("Script")
            or descendant:IsA("LocalScript")
            or descendant:IsA("ModuleScript")
            or descendant:IsA("ProximityPrompt")
            or descendant:IsA("ClickDetector")
            or descendant:IsA("TouchTransmitter") then

            safeDestroy(descendant)
        end
    end
end

local function cloneForViewport(object)
    if not object or not object.Parent then
        return nil
    end

    local clone

    pcall(function()
        clone = object:Clone()
    end)

    if not clone then
        return nil
    end

    removeUnsafeDescendants(clone)

    -- Desligar efeitos/partículas muito pesados no preview
    for _, descendant in ipairs(clone:GetDescendants()) do
        if descendant:IsA("ParticleEmitter")
            or descendant:IsA("Trail")
            or descendant:IsA("Beam")
            or descendant:IsA("Smoke")
            or descendant:IsA("Fire")
            or descendant:IsA("Sparkles") then

            descendant.Enabled = false
        elseif descendant:IsA("BasePart") then
            descendant.Anchored = true
            descendant.CanCollide = false
            descendant.CanTouch = false
            descendant.CanQuery = false
        end
    end

    return clone
end

local function setupViewport(viewport, object)
    -- Limpar conteúdo anterior
    for _, child in ipairs(viewport:GetChildren()) do
        safeDestroy(child)
    end

    local worldModel = Instance.new("WorldModel")
    worldModel.Name = "WorldModel"
    worldModel.Parent = viewport

    local camera = Instance.new("Camera")
    camera.Name = "Camera"
    camera.Parent = viewport
    viewport.CurrentCamera = camera

    camera.FieldOfView = 45

    local clone = cloneForViewport(object)

    if not clone then
        return
    end

    clone.Parent = worldModel

    -- Coloca o modelo na origem do preview
    pcall(function()
        if clone:IsA("Model") then
            clone:PivotTo(CFrame.new())
        elseif clone:IsA("BasePart") then
            clone.CFrame = CFrame.new()
        end
    end)

    local objectSize = nil

    pcall(function()
        if clone:IsA("Model") then
            local _, size = clone:GetBoundingBox()
            objectSize = size
        elseif clone:IsA("BasePart") then
            objectSize = clone.Size
        else
            local firstPart = clone:FindFirstChildWhichIsA("BasePart", true)
            if firstPart then
                objectSize = firstPart.Size
            end
        end
    end)

    if objectSize then
        local largest = math.max(
            objectSize.X,
            objectSize.Y,
            objectSize.Z
        )

        if largest < 0.1 or largest ~= largest then
            largest = 4
        end

        local distance = math.clamp(largest * 2.15, 3, 22)

        camera.CFrame = CFrame.lookAt(
            Vector3.new(
                distance * 0.75,
                largest * 0.35,
                distance
            ),
            Vector3.new(
                0,
                largest * 0.15,
                0
            )
        )
    else
        camera.CFrame = CFrame.lookAt(
            Vector3.new(0, 2, 7),
            Vector3.new(0, 0, 0)
        )
    end

    -- Iluminação simples do preview
    viewport.Ambient = Color3.fromRGB(200, 190, 215)
    viewport.LightColor = Color3.fromRGB(255, 255, 255)
    viewport.LightDirection = Vector3.new(-1, -1, -1)
end

--==================================================
-- POOL DE CARDS
--==================================================

local Pool = {}
local PoolSize = 0
local FirstVisibleIndex = -1

local function createCard()
    local card = Instance.new("Frame")
    card.Name = "EggCard"
    card.Size = UDim2.new(1, -10, 0, ROW_HEIGHT)
    card.BackgroundColor3 = Color3.fromRGB(23, 18, 30)
    card.BorderSizePixel = 0
    card.Visible = false
    card.Parent = List

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 7)
    cardCorner.Parent = card

    local preview = Instance.new("ViewportFrame")
    preview.Name = "Preview3D"
    preview.Size = UDim2.fromOffset(76, 76)
    preview.Position = UDim2.fromOffset(6, 9)
    preview.BackgroundColor3 = Color3.fromRGB(10, 8, 13)
    preview.BorderSizePixel = 0
    preview.Parent = card

    local previewCorner = Instance.new("UICorner")
    previewCorner.CornerRadius = UDim.new(0, 7)
    previewCorner.Parent = preview

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.Size = UDim2.new(1, -168, 0, 25)
    nameLabel.Position = UDim2.fromOffset(91, 12)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = ""
    nameLabel.TextColor3 = Color3.fromRGB(238, 229, 246)
    nameLabel.TextSize = 12
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = card

    local stageLabel = Instance.new("TextLabel")
    stageLabel.Name = "Stage"
    stageLabel.Size = UDim2.new(1, -168, 0, 22)
    stageLabel.Position = UDim2.fromOffset(91, 37)
    stageLabel.BackgroundTransparency = 1
    stageLabel.Text = ""
    stageLabel.TextColor3 = Color3.fromRGB(163, 146, 176)
    stageLabel.TextSize = 10
    stageLabel.Font = Enum.Font.Gotham
    stageLabel.TextXAlignment = Enum.TextXAlignment.Left
    stageLabel.TextTruncate = Enum.TextTruncate.AtEnd
    stageLabel.Parent = card

    local tpButton = Instance.new("TextButton")
    tpButton.Name = "Teleport"
    tpButton.Size = UDim2.fromOffset(82, 28)
    tpButton.Position = UDim2.new(1, -90, 1, -34)
    tpButton.BackgroundColor3 = Color3.fromRGB(103, 46, 180)
    tpButton.Text = "TP"
    tpButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    tpButton.TextSize = 11
    tpButton.Font = Enum.Font.GothamBold
    tpButton.Parent = card

    local tpCorner = Instance.new("UICorner")
    tpCorner.CornerRadius = UDim.new(0, 6)
    tpCorner.Parent = tpButton

    local indexLabel = Instance.new("TextLabel")
    indexLabel.Name = "Index"
    indexLabel.Size = UDim2.new(1, -175, 0, 16)
    indexLabel.Position = UDim2.fromOffset(91, 61)
    indexLabel.BackgroundTransparency = 1
    indexLabel.Text = ""
    indexLabel.TextColor3 = Color3.fromRGB(116, 102, 127)
    indexLabel.TextSize = 9
    indexLabel.Font = Enum.Font.Gotham
    indexLabel.TextXAlignment = Enum.TextXAlignment.Left
    indexLabel.Parent = card

    return {
        frame = card,
        viewport = preview,
        name = nameLabel,
        stage = stageLabel,
        index = indexLabel,
        teleport = tpButton,
        boundItem = nil,
        boundIndex = nil,
    }
end

local function ensurePoolSize()
    local target = math.clamp(
        math.ceil(List.AbsoluteSize.Y / (ROW_HEIGHT + ROW_GAP)) + VISIBLE_BUFFER,
        8,
        MAX_POOL
    )

    while PoolSize < target do
        PoolSize += 1
        Pool[PoolSize] = createCard()
    end
end

local function bindCard(card, item, index)
    card.boundItem = item
    card.boundIndex = index

    card.frame.Position = UDim2.fromOffset(
        5,
        (index - 1) * (ROW_HEIGHT + ROW_GAP)
    )

    card.name.Text = item.name
    card.stage.Text = "Área: " .. item.stageName
    card.index.Text = "#" .. tostring(index) .. "  •  Preview 3D"
    card.frame.Visible = true

    card.teleport.MouseButton1Click:Connect(function()
        local currentItem = card.boundItem

        if currentItem and currentItem.object and currentItem.object.Parent then
            teleportToObject(currentItem.object)
        end
    end)
end

-- O botão de cada card é conectado apenas uma vez.
-- Recria pool para não acumular conexões.
local function recreatePool()
    for _, card in ipairs(Pool) do
        safeDestroy(card.frame)
    end

    table.clear(Pool)
    PoolSize = 0

    ensurePoolSize()

    for _, card in ipairs(Pool) do
        local oldClick = card.teleport

        -- O callback vai ler card.boundItem atual.
        oldClick.MouseButton1Click:Connect(function()
            local currentItem = card.boundItem
            if currentItem and currentItem.object and currentItem.object.Parent then
                teleportToObject(currentItem.object)
            end
        end)
    end
end

--==================================================
-- RENDERIZAÇÃO VIRTUAL
--==================================================

local lastRenderTop = 0

local function renderVisibleCards(force)
    if ItemCount <= 0 then
        for _, card in ipairs(Pool) do
            card.frame.Visible = false
        end
        return
    end

    ensurePoolSize()

    local rowStep = ROW_HEIGHT + ROW_GAP
    local first = math.floor(List.CanvasPosition.Y / rowStep) + 1

    local startIndex = math.max(1, first - 2)
    local endIndex = math.min(ItemCount, startIndex + PoolSize - 1)

    if not force and startIndex == FirstVisibleIndex then
        return
    end

    FirstVisibleIndex = startIndex

    local cardSlot = 1

    for index = startIndex, endIndex do
        local card = Pool[cardSlot]
        local item = Items[index]

        if card and item then
            card.boundItem = item
            card.boundIndex = index

            card.frame.Position = UDim2.fromOffset(
                5,
                (index - 1) * rowStep
            )

            card.name.Text = item.name
            card.stage.Text = "Área: " .. item.stageName
            card.index.Text = "#" .. tostring(index) .. " • Preview 3D"
            card.frame.Visible = true

            setupViewport(card.viewport, item.object)
        end

        cardSlot += 1
    end

    while cardSlot <= PoolSize do
        Pool[cardSlot].frame.Visible = false
        Pool[cardSlot].boundItem = nil
        Pool[cardSlot].boundIndex = nil
        cardSlot += 1
    end
end

local function updateCanvas()
    local rowStep = ROW_HEIGHT + ROW_GAP
    local height = math.max(
        0,
        ItemCount * rowStep + ROW_GAP
    )

    List.CanvasSize = UDim2.fromOffset(0, height)
end

--==================================================
-- REFRESH PRINCIPAL
--==================================================

local function refreshAll(force)
    if Refreshing then
        return
    end

    Refreshing = true

    task.spawn(function()
        local collected = collectAllEggs()
        local signature = makeSignature(collected)

        local changed = signature ~= CurrentSignature

        if changed or force then
            clearItems()

            for i, entry in ipairs(collected) do
                Items[i] = entry
            end

            ItemCount = #Items
            CurrentSignature = signature

            updateCanvas()

            EmptyLabel.Visible = ItemCount == 0

            Status.Text = string.format(
                "%d ovos • todas as áreas",
                ItemCount
            )

            FirstVisibleIndex = -1
            renderVisibleCards(true)
        end

        Refreshing = false
    end)
end

--==================================================
-- SCROLL
--==================================================

List:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
    renderVisibleCards(false)
end)

List:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
    ensurePoolSize()
    renderVisibleCards(true)
end)

--==================================================
-- TP ÁREA
--==================================================

TPAreaButton.MouseButton1Click:Connect(function()
    teleportToCFrame(EGG_AREA_CFRAME)
end)

--==================================================
-- ESCONDER / MOSTRAR
--==================================================

--==================================================
-- BOTÃO FLUTUANTE COM IMAGEM
--==================================================

local ToggleButton = Instance.new("ImageButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Size = UDim2.fromOffset(43, 43)
ToggleButton.Position = UDim2.new(1, -52, 0, 115)
ToggleButton.BackgroundColor3 = Color3.fromRGB(18, 15, 23)
ToggleButton.BackgroundTransparency = 0.08
ToggleButton.BorderSizePixel = 0
ToggleButton.Image = IMAGE_ID
ToggleButton.ScaleType = Enum.ScaleType.Fit
ToggleButton.AutoButtonColor = true
ToggleButton.ZIndex = 100
ToggleButton.Parent = ScreenGui

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 10)
ToggleCorner.Parent = ToggleButton

local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Color = Color3.fromRGB(255, 255, 255)
ToggleStroke.Thickness = 1.6
ToggleStroke.Parent = ToggleButton

local function setMainVisible(visible)
    Main.Visible = visible
end

HideButton.MouseButton1Click:Connect(function()
    setMainVisible(false)
end)

--==================================================
-- DRAG DO BOTÃO FLUTUANTE
--==================================================

local dragging = false
local dragInput = nil
local dragStart = nil
local startPos = nil
local moved = false

local function updateTogglePosition(input)
    if not dragging or not dragStart or not startPos then
        return
    end

    local delta = input.Position - dragStart

    if math.abs(delta.X) > 4 or math.abs(delta.Y) > 4 then
        moved = true
    end

    local viewport = workspace.CurrentCamera
        and workspace.CurrentCamera.ViewportSize
        or Vector2.new(800, 600)

    local newX = startPos.X.Offset + delta.X
    local newY = startPos.Y.Offset + delta.Y

    local halfW = ToggleButton.AbsoluteSize.X / 2
    local halfH = ToggleButton.AbsoluteSize.Y / 2

    newX = math.clamp(
        newX,
        -viewport.X + halfW + 2,
        -2
    )

    newY = math.clamp(
        newY,
        2,
        viewport.Y - halfH * 2 - 2
    )

    ToggleButton.Position = UDim2.new(
        1,
        newX,
        0,
        newY
    )
end

ToggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        moved = false
        dragInput = input
        dragStart = input.Position
        startPos = ToggleButton.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then

        dragInput = input
        updateTogglePosition(input)
    end
end)

-- Clique curto alterna a interface; arrastar apenas move o botão.
local toggleClickConnection = ToggleButton.MouseButton1Click:Connect(function()
    if moved then
        moved = false
        return
    end

    setMainVisible(not Main.Visible)
end)

--==================================================
-- DRAG DA JANELA
--==================================================

do
    local windowDragging = false
    local windowDragStart
    local windowStartPos

    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            windowDragging = true
            windowDragStart = input.Position
            windowStartPos = Main.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    windowDragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not windowDragging then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then

            local delta = input.Position - windowDragStart

            Main.Position = UDim2.new(
                windowStartPos.X.Scale,
                windowStartPos.X.Offset + delta.X,
                windowStartPos.Y.Scale,
                windowStartPos.Y.Offset + delta.Y
            )
        end
    end)
end

--==================================================
-- WATCHERS DAS ÁREAS / SPAWNED EGGS
--==================================================

local connections = {}

local function disconnectAllWatchers()
    for _, connection in ipairs(connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    table.clear(connections)
end

local function attachSpawnedEggsWatcher(spawnedEggs)
    if not spawnedEggs then
        return
    end

    table.insert(
        connections,
        spawnedEggs.ChildAdded:Connect(function()
            task.delay(0.05, function()
                refreshAll(false)
            end)
        end)
    )

    table.insert(
        connections,
        spawnedEggs.ChildRemoved:Connect(function()
            task.delay(0.05, function()
                refreshAll(false)
            end)
        end)
    )
end

local function attachStageWatcher(stage)
    if not stage then
        return
    end

    local spawnedEggs = stage:FindFirstChild("SpawnedEggs")

    if spawnedEggs then
        attachSpawnedEggsWatcher(spawnedEggs)
    end

    table.insert(
        connections,
        stage.ChildAdded:Connect(function(child)
            if child.Name == "SpawnedEggs" then
                attachSpawnedEggsWatcher(child)
                refreshAll(true)
            end
        end)
    )

    table.insert(
        connections,
        stage.ChildRemoved:Connect(function(child)
            if child.Name == "SpawnedEggs" then
                refreshAll(true)
            end
        end)
    )
end

local function rebuildWatchers()
    disconnectAllWatchers()

    if not Stages or not Stages.Parent then
        local _, newStages = findMapStages()
        Stages = newStages

        if not Stages then
            return
        end
    end

    for _, stage in ipairs(Stages:GetChildren()) do
        attachStageWatcher(stage)
    end

    table.insert(
        connections,
        Stages.ChildAdded:Connect(function(stage)
            attachStageWatcher(stage)
            refreshAll(true)
        end)
    )

    table.insert(
        connections,
        Stages.ChildRemoved:Connect(function()
            refreshAll(true)
        end)
    )
end

rebuildWatchers()

--==================================================
-- LOOP DE SEGURANÇA
--==================================================

task.spawn(function()
    while ScreenGui.Parent do
        task.wait(SCAN_INTERVAL)

        local _, currentStages = findMapStages()

        if currentStages ~= Stages then
            Stages = currentStages

            if Stages then
                rebuildWatchers()
                refreshAll(true)
            end
        elseif Stages then
            refreshAll(false)
        end
    end
end)

--==================================================
-- INICIALIZAÇÃO
--==================================================

recreatePool()
refreshAll(true)

print(string.format(
    "[Egg3D] Carregado. Procurando ovos em TODAS as áreas. Botão: %s",
    IMAGE_ID
))
