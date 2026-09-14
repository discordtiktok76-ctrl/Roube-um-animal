--// Egg Teleporter + 3D Preview
--// Executor Script

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

--==================================================
-- CONFIGURAÇÃO
--==================================================

local Map = workspace:FindFirstChild("Map")
local Stages = Map and Map:FindFirstChild("Stages")

if not Stages then
    warn("Map.Stages não encontrado.")
    return
end

local EGG_AREA_CFRAME = CFrame.new(
    -0.5,
    5608.68457,
    -1386.02295
)

--==================================================
-- LIMPAR GUI ANTIGA
--==================================================

pcall(function()
    local old = CoreGui:FindFirstChild("Egg3DTeleporter")
    if old then
        old:Destroy()
    end
end)

--==================================================
-- GUI PRINCIPAL
--==================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Egg3DTeleporter"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(430, 650)
Main.Position = UDim2.new(0.5, -215, 0.5, -325)
Main.BackgroundColor3 = Color3.fromRGB(15, 12, 20)
Main.BackgroundTransparency = 0.08
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(150, 60, 255)
MainStroke.Thickness = 2
MainStroke.Parent = Main

--==================================================
-- TÍTULO
--==================================================

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 0, 45)
Title.Position = UDim2.fromOffset(15, 5)
Title.BackgroundTransparency = 1
Title.Text = "🥚 Egg Teleporter"
Title.TextColor3 = Color3.fromRGB(235, 220, 255)
Title.TextSize = 21
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Main

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(32, 32)
Close.Position = UDim2.new(1, -40, 0, 10)
Close.BackgroundColor3 = Color3.fromRGB(35, 25, 45)
Close.Text = "×"
Close.TextColor3 = Color3.fromRGB(255, 255, 255)
Close.TextSize = 23
Close.Font = Enum.Font.GothamBold
Close.Parent = Main

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 8)
CloseCorner.Parent = Close

Close.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

--==================================================
-- DRAG
--==================================================

local dragging = false
local dragStart
local startPos

Title.InputBegan:Connect(function(input)
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

UserInputService.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then

        local delta = input.Position - dragStart

        Main.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

--==================================================
-- TELEPORTE
--==================================================

local function getCharacter()
    return LocalPlayer.Character
end

local function teleportCFrame(cf)
    local character = getCharacter()
    if not character then return end

    local root = character:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = cf + Vector3.new(0, 3, 0)
    end
end

local function teleportToObject(object)
    if not object or not object.Parent then return end

    local character = getCharacter()
    if not character then return end

    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local targetCFrame

    if object:IsA("Model") then
        targetCFrame = object:GetPivot()
    elseif object:IsA("BasePart") then
        targetCFrame = object.CFrame
    elseif object:IsA("Folder") then
        local part = object:FindFirstChildWhichIsA("BasePart", true)
        if part then
            targetCFrame = part.CFrame
        end
    end

    if targetCFrame then
        root.CFrame = targetCFrame + Vector3.new(0, 4, 0)
    end
end

--==================================================
-- LABELS / DROPDOWNS
--==================================================

local AreaLabel = Instance.new("TextLabel")
AreaLabel.Size = UDim2.new(1, -30, 0, 25)
AreaLabel.Position = UDim2.fromOffset(15, 55)
AreaLabel.BackgroundTransparency = 1
AreaLabel.Text = "Área"
AreaLabel.TextColor3 = Color3.fromRGB(190, 170, 210)
AreaLabel.TextSize = 14
AreaLabel.Font = Enum.Font.GothamSemibold
AreaLabel.TextXAlignment = Enum.TextXAlignment.Left
AreaLabel.Parent = Main

local AreaButton = Instance.new("TextButton")
AreaButton.Size = UDim2.new(1, -30, 0, 40)
AreaButton.Position = UDim2.fromOffset(15, 80)
AreaButton.BackgroundColor3 = Color3.fromRGB(27, 22, 34)
AreaButton.Text = "Selecionar área ▼"
AreaButton.TextColor3 = Color3.fromRGB(230, 220, 240)
AreaButton.TextSize = 14
AreaButton.Font = Enum.Font.Gotham
AreaButton.TextXAlignment = Enum.TextXAlignment.Left
AreaButton.Parent = Main

local AreaPadding = Instance.new("UIPadding")
AreaPadding.PaddingLeft = UDim.new(0, 12)
AreaPadding.Parent = AreaButton

local AreaCorner = Instance.new("UICorner")
AreaCorner.CornerRadius = UDim.new(0, 7)
AreaCorner.Parent = AreaButton

local AreaStroke = Instance.new("UIStroke")
AreaStroke.Color = Color3.fromRGB(90, 55, 120)
AreaStroke.Parent = AreaButton

local AreaList = Instance.new("ScrollingFrame")
AreaList.Size = UDim2.new(1, -30, 0, 130)
AreaList.Position = UDim2.fromOffset(15, 125)
AreaList.BackgroundColor3 = Color3.fromRGB(20, 16, 26)
AreaList.BorderSizePixel = 0
AreaList.ScrollBarThickness = 4
AreaList.Visible = false
AreaList.ZIndex = 20
AreaList.Parent = Main

local AreaListCorner = Instance.new("UICorner")
AreaListCorner.CornerRadius = UDim.new(0, 7)
AreaListCorner.Parent = AreaList

local AreaLayout = Instance.new("UIListLayout")
AreaLayout.Padding = UDim.new(0, 3)
AreaLayout.Parent = AreaList

local EggLabel = Instance.new("TextLabel")
EggLabel.Size = UDim2.new(1, -30, 0, 25)
EggLabel.Position = UDim2.fromOffset(15, 175)
EggLabel.BackgroundTransparency = 1
EggLabel.Text = "Ovo / Item"
EggLabel.TextColor3 = Color3.fromRGB(190, 170, 210)
EggLabel.TextSize = 14
EggLabel.Font = Enum.Font.GothamSemibold
EggLabel.TextXAlignment = Enum.TextXAlignment.Left
EggLabel.Parent = Main

local EggButton = Instance.new("TextButton")
EggButton.Size = UDim2.new(1, -30, 0, 40)
EggButton.Position = UDim2.fromOffset(15, 200)
EggButton.BackgroundColor3 = Color3.fromRGB(27, 22, 34)
EggButton.Text = "Selecione um ovo ▼"
EggButton.TextColor3 = Color3.fromRGB(230, 220, 240)
EggButton.TextSize = 14
EggButton.Font = Enum.Font.Gotham
EggButton.TextXAlignment = Enum.TextXAlignment.Left
EggButton.Parent = Main

local EggPadding = Instance.new("UIPadding")
EggPadding.PaddingLeft = UDim.new(0, 12)
EggPadding.Parent = EggButton

local EggCorner = Instance.new("UICorner")
EggCorner.CornerRadius = UDim.new(0, 7)
EggCorner.Parent = EggButton

local EggStroke = Instance.new("UIStroke")
EggStroke.Color = Color3.fromRGB(90, 55, 120)
EggStroke.Parent = EggButton

local EggList = Instance.new("ScrollingFrame")
EggList.Size = UDim2.new(1, -30, 0, 130)
EggList.Position = UDim2.fromOffset(15, 245)
EggList.BackgroundColor3 = Color3.fromRGB(20, 16, 26)
EggList.BorderSizePixel = 0
EggList.ScrollBarThickness = 4
EggList.Visible = false
EggList.ZIndex = 20
EggList.Parent = Main

local EggListCorner = Instance.new("UICorner")
EggListCorner.CornerRadius = UDim.new(0, 7)
EggListCorner.Parent = EggList

local EggLayout = Instance.new("UIListLayout")
EggLayout.Padding = UDim.new(0, 3)
EggLayout.Parent = EggList

local selectedStage = nil
local selectedEgg = nil

--==================================================
-- BOTÕES
--==================================================

local TPSelected = Instance.new("TextButton")
TPSelected.Size = UDim2.new(0.48, -10, 0, 38)
TPSelected.Position = UDim2.fromOffset(15, 295)
TPSelected.BackgroundColor3 = Color3.fromRGB(100, 45, 180)
TPSelected.Text = "TP Item Selecionado"
TPSelected.TextColor3 = Color3.fromRGB(255, 255, 255)
TPSelected.TextSize = 13
TPSelected.Font = Enum.Font.GothamBold
TPSelected.Parent = Main

local TPSelectedCorner = Instance.new("UICorner")
TPSelectedCorner.CornerRadius = UDim.new(0, 7)
TPSelectedCorner.Parent = TPSelected

local TPArea = Instance.new("TextButton")
TPArea.Size = UDim2.new(0.48, -10, 0, 38)
TPArea.Position = UDim2.new(0.52, 5, 0, 295)
TPArea.BackgroundColor3 = Color3.fromRGB(55, 35, 75)
TPArea.Text = "TP Área dos Ovos"
TPArea.TextColor3 = Color3.fromRGB(255, 255, 255)
TPArea.TextSize = 13
TPArea.Font = Enum.Font.GothamBold
TPArea.Parent = Main

local TPAreaCorner = Instance.new("UICorner")
TPAreaCorner.CornerRadius = UDim.new(0, 7)
TPAreaCorner.Parent = TPArea

--==================================================
-- PREVIEW 3D
--==================================================

local PreviewTitle = Instance.new("TextLabel")
PreviewTitle.Size = UDim2.new(1, -30, 0, 25)
PreviewTitle.Position = UDim2.fromOffset(15, 340)
PreviewTitle.BackgroundTransparency = 1
PreviewTitle.Text = "Preview 3D dos ovos"
PreviewTitle.TextColor3 = Color3.fromRGB(210, 190, 230)
PreviewTitle.TextSize = 15
PreviewTitle.Font = Enum.Font.GothamBold
PreviewTitle.TextXAlignment = Enum.TextXAlignment.Left
PreviewTitle.Parent = Main

local PreviewList = Instance.new("ScrollingFrame")
PreviewList.Size = UDim2.new(1, -30, 0, 285)
PreviewList.Position = UDim2.fromOffset(15, 365)
PreviewList.BackgroundColor3 = Color3.fromRGB(11, 9, 15)
PreviewList.BackgroundTransparency = 0.2
PreviewList.BorderSizePixel = 0
PreviewList.ScrollBarThickness = 5
PreviewList.CanvasSize = UDim2.new(0, 0, 0, 0)
PreviewList.Parent = Main

local PreviewCorner = Instance.new("UICorner")
PreviewCorner.CornerRadius = UDim.new(0, 8)
PreviewCorner.Parent = PreviewList

local PreviewStroke = Instance.new("UIStroke")
PreviewStroke.Color = Color3.fromRGB(80, 45, 110)
PreviewStroke.Parent = PreviewList

local PreviewLayout = Instance.new("UIListLayout")
PreviewLayout.Padding = UDim.new(0, 7)
PreviewLayout.Parent = PreviewList

PreviewLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    PreviewList.CanvasSize = UDim2.new(
        0, 0, 0,
        PreviewLayout.AbsoluteContentSize.Y + 10
    )
end)

--==================================================
-- PREVIEW 3D
--==================================================

local function prepareClone(object)
    local clone

    pcall(function()
        clone = object:Clone()
    end)

    if not clone then
        return nil
    end

    for _, descendant in ipairs(clone:GetDescendants()) do
        if descendant:IsA("Script")
            or descendant:IsA("LocalScript")
            or descendant:IsA("ModuleScript")
            or descendant:IsA("ProximityPrompt")
            or descendant:IsA("ClickDetector") then
            descendant:Destroy()
        end
    end

    return clone
end

local function createPreview(object, index)
    local holder = Instance.new("Frame")
    holder.Name = "Egg_" .. index
    holder.Size = UDim2.new(1, -10, 0, 105)
    holder.BackgroundColor3 = Color3.fromRGB(23, 18, 30)
    holder.BorderSizePixel = 0
    holder.Parent = PreviewList

    local holderCorner = Instance.new("UICorner")
    holderCorner.CornerRadius = UDim.new(0, 7)
    holderCorner.Parent = holder

    local viewport = Instance.new("ViewportFrame")
    viewport.Size = UDim2.fromOffset(90, 90)
    viewport.Position = UDim2.fromOffset(7, 7)
    viewport.BackgroundColor3 = Color3.fromRGB(13, 11, 18)
    viewport.BorderSizePixel = 0
    viewport.Parent = holder

    local viewportCorner = Instance.new("UICorner")
    viewportCorner.CornerRadius = UDim.new(0, 7)
    viewportCorner.Parent = viewport

    local worldModel = Instance.new("WorldModel")
    worldModel.Parent = viewport

    local clone = prepareClone(object)

    if clone then
        clone.Parent = worldModel

        pcall(function()
            if clone:IsA("Model") then
                clone:PivotTo(CFrame.new())
            elseif clone:IsA("BasePart") then
                clone.CFrame = CFrame.new()
            end
        end)

        local camera = Instance.new("Camera")
        camera.Parent = viewport
        viewport.CurrentCamera = camera

        pcall(function()
            local _, objectSize = clone:GetBoundingBox()

            local largest = math.max(
                objectSize.X,
                objectSize.Y,
                objectSize.Z
            )

            if largest < 0.1 then
                largest = 4
            end

            camera.CFrame = CFrame.lookAt(
                Vector3.new(0, largest * 0.25, largest * 2.4),
                Vector3.new(0, 0, 0)
            )
        end)
    end

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -115, 0, 30)
    nameLabel.Position = UDim2.fromOffset(105, 12)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = object.Name
    nameLabel.TextColor3 = Color3.fromRGB(235, 225, 245)
    nameLabel.TextSize = 14
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = holder

    local tpButton = Instance.new("TextButton")
    tpButton.Size = UDim2.fromOffset(100, 32)
    tpButton.Position = UDim2.new(1, -110, 1, -42)
    tpButton.BackgroundColor3 = Color3.fromRGB(105, 45, 185)
    tpButton.Text = "TELEPORTAR"
    tpButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    tpButton.TextSize = 11
    tpButton.Font = Enum.Font.GothamBold
    tpButton.Parent = holder

    local tpCorner = Instance.new("UICorner")
    tpCorner.CornerRadius = UDim.new(0, 6)
    tpCorner.Parent = tpButton

    tpButton.MouseButton1Click:Connect(function()
        if object and object.Parent then
            teleportToObject(object)
        end
    end)

    return holder
end

--==================================================
-- FUNÇÕES DE LISTA
--==================================================

local function clearChildren(frame, keepLayout)
    for _, child in ipairs(frame:GetChildren()) do
        if child ~= keepLayout
            and not child:IsA("UICorner")
            and not child:IsA("UIStroke") then
            child:Destroy()
        end
    end
end

local function getStages()
    local result = {}

    for _, stage in ipairs(Stages:GetChildren()) do
        if stage:FindFirstChild("SpawnedEggs") then
            table.insert(result, stage)
        end
    end

    table.sort(result, function(a, b)
        return a.Name:lower() < b.Name:lower()
    end)

    return result
end

local function updateEggList()
    clearChildren(EggList, EggLayout)

    selectedEgg = nil
    EggButton.Text = "Selecione um ovo ▼"

    if not selectedStage then return end

    local spawnedEggs = selectedStage:FindFirstChild("SpawnedEggs")
    if not spawnedEggs then return end

    local eggs = spawnedEggs:GetChildren()

    table.sort(eggs, function(a, b)
        return a.Name:lower() < b.Name:lower()
    end)

    for _, egg in ipairs(eggs) do
        local button = Instance.new("TextButton")

        button.Size = UDim2.new(1, -8, 0, 32)
        button.BackgroundColor3 = Color3.fromRGB(29, 23, 37)
        button.Text = egg.Name
        button.TextColor3 = Color3.fromRGB(225, 215, 235)
        button.TextSize = 13
        button.Font = Enum.Font.Gotham
        button.TextXAlignment = Enum.TextXAlignment.Left
        button.ZIndex = 21
        button.Parent = EggList

        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 10)
        padding.Parent = button

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 5)
        corner.Parent = button

        button.MouseButton1Click:Connect(function()
            selectedEgg = egg
            EggButton.Text = egg.Name .. " ▼"
            EggList.Visible = false
        end)
    end

    task.defer(function()
        EggList.CanvasSize = UDim2.new(
            0, 0, 0,
            EggLayout.AbsoluteContentSize.Y + 5
        )
    end)
end

local function updateStageList()
    clearChildren(AreaList, AreaLayout)

    for _, stage in ipairs(getStages()) do
        local button = Instance.new("TextButton")

        button.Size = UDim2.new(1, -8, 0, 32)
        button.BackgroundColor3 = Color3.fromRGB(29, 23, 37)
        button.Text = stage.Name
        button.TextColor3 = Color3.fromRGB(225, 215, 235)
        button.TextSize = 13
        button.Font = Enum.Font.Gotham
        button.TextXAlignment = Enum.TextXAlignment.Left
        button.ZIndex = 21
        button.Parent = AreaList

        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 10)
        padding.Parent = button

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 5)
        corner.Parent = button

        button.MouseButton1Click:Connect(function()
            selectedStage = stage
            AreaButton.Text = stage.Name .. " ▼"
            AreaList.Visible = false

            updateEggList()
            updatePreview()
        end)
    end

    task.defer(function()
        AreaList.CanvasSize = UDim2.new(
            0, 0, 0,
            AreaLayout.AbsoluteContentSize.Y + 5
        )
    end)
end

function updatePreview()
    for _, child in ipairs(PreviewList:GetChildren()) do
        if child ~= PreviewLayout
            and not child:IsA("UICorner")
            and not child:IsA("UIStroke") then
            child:Destroy()
        end
    end

    if not selectedStage then
        PreviewTitle.Text = "Preview 3D dos ovos"
        return
    end

    local spawnedEggs = selectedStage:FindFirstChild("SpawnedEggs")

    if not spawnedEggs then
        PreviewTitle.Text = "Nenhum SpawnedEggs encontrado"
        return
    end

    local eggs = spawnedEggs:GetChildren()

    PreviewTitle.Text = "Preview 3D • " .. #eggs .. " item(s)"

    table.sort(eggs, function(a, b)
        return a.Name:lower() < b.Name:lower()
    end)

    for index, egg in ipairs(eggs) do
        createPreview(egg, index)
    end
end

--==================================================
-- EVENTOS
--==================================================

AreaButton.MouseButton1Click:Connect(function()
    AreaList.Visible = not AreaList.Visible
    EggList.Visible = false
end)

EggButton.MouseButton1Click:Connect(function()
    EggList.Visible = not EggList.Visible
    AreaList.Visible = false
end)

TPSelected.MouseButton1Click:Connect(function()
    if selectedEgg and selectedEgg.Parent then
        teleportToObject(selectedEgg)
    end
end)

TPArea.MouseButton1Click:Connect(function()
    teleportCFrame(EGG_AREA_CFRAME)
end)

--==================================================
-- ATUALIZAÇÃO AUTOMÁTICA
--==================================================

local refreshDebounce = false

local function refresh()
    if refreshDebounce then return end

    refreshDebounce = true

    task.delay(0.25, function()
        refreshDebounce = false

        if not ScreenGui.Parent then return end

        updateStageList()

        if selectedStage and selectedStage.Parent then
            updateEggList()
            updatePreview()
        end
    end)
end

Stages.ChildAdded:Connect(function(stage)
    local spawnedEggs = stage:FindFirstChild("SpawnedEggs")

    if spawnedEggs then
        spawnedEggs.ChildAdded:Connect(refresh)
        spawnedEggs.ChildRemoved:Connect(refresh)
    end

    stage.ChildAdded:Connect(function(child)
        if child.Name == "SpawnedEggs" then
            child.ChildAdded:Connect(refresh)
            child.ChildRemoved:Connect(refresh)
            refresh()
        end
    end)

    refresh()
end)

Stages.ChildRemoved:Connect(refresh)

for _, stage in ipairs(Stages:GetChildren()) do
    local spawnedEggs = stage:FindFirstChild("SpawnedEggs")

    if spawnedEggs then
        spawnedEggs.ChildAdded:Connect(refresh)
        spawnedEggs.ChildRemoved:Connect(refresh)
    end

    stage.ChildAdded:Connect(function(child)
        if child.Name == "SpawnedEggs" then
            child.ChildAdded:Connect(refresh)
            child.ChildRemoved:Connect(refresh)
            refresh()
        end
    end)
end

--==================================================
-- LOOP DE SEGURANÇA / ATUALIZAÇÃO
--==================================================

task.spawn(function()
    local lastSignature = ""

    while ScreenGui.Parent do
        task.wait(2)

        if selectedStage and selectedStage.Parent then
            local spawnedEggs = selectedStage:FindFirstChild("SpawnedEggs")

            if spawnedEggs then
                local names = {}

                for _, object in ipairs(spawnedEggs:GetChildren()) do
                    table.insert(names, object.Name)
                end

                table.sort(names)

                local signature = table.concat(names, "|")

                if signature ~= lastSignature then
                    lastSignature = signature
                    updateEggList()
                    updatePreview()
                end
            end
        end
    end
end)

--==================================================
-- INICIALIZAÇÃO
--==================================================

updateStageList()

local stages = getStages()

if #stages > 0 then
    selectedStage = stages[1]
    AreaButton.Text = selectedStage.Name .. " ▼"

    updateEggList()
    updatePreview()
end

print("Egg Teleporter carregado!")
