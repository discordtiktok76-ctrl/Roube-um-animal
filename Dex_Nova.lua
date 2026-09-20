--[[
    DEX NOVA 1.0 | Explorer de Instances para executor (cliente)
    Arquivo unico, offline. Execute novamente para substituir a janela anterior.
    As edicoes em Instances dependem das permissoes do cliente/executor e das regras do jogo.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer
if not localPlayer then
    warn("Dex Nova: LocalPlayer indisponivel.")
    return
end

local globalEnv = nil
pcall(function()
    if type(getgenv) == "function" then globalEnv = getgenv() end
end)
if globalEnv and type(globalEnv.__DEX_NOVA) == "table" then
    pcall(function() globalEnv.__DEX_NOVA.Destroy() end)
end

local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end
local C = {
    bg = rgb(14, 19, 29), surface = rgb(22, 29, 41), raised = rgb(32, 41, 56),
    hover = rgb(42, 55, 73), accent = rgb(107, 163, 255), pale = rgb(187, 214, 255),
    text = rgb(238, 244, 255), muted = rgb(150, 166, 188), line = rgb(56, 70, 91),
    danger = rgb(241, 110, 116), green = rgb(114, 215, 166), gold = rgb(236, 190, 105)
}
local function make(className, props, parent)
    local obj = Instance.new(className)
    for key, value in pairs(props or {}) do obj[key] = value end
    obj.Parent = parent
    return obj
end
local function corner(obj, radius)
    make("UICorner", {CornerRadius = UDim.new(0, radius or 9)}, obj)
    return obj
end
local function stroke(obj)
    make("UIStroke", {Color = C.line, Thickness = 1, Transparency = 0.25}, obj)
    return obj
end
local function label(parent, text, size, color)
    return make("TextLabel", {
        BackgroundTransparency = 1, Text = text or "", TextColor3 = color or C.text,
        Font = Enum.Font.Gotham, TextSize = size or 14, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, BorderSizePixel = 0
    }, parent)
end
local function button(parent, text, w, h, color)
    local b = make("TextButton", {
        AutoButtonColor = false, Text = text, TextSize = 13,
        Font = Enum.Font.GothamMedium, TextColor3 = C.text,
        BackgroundColor3 = color or C.raised, BorderSizePixel = 0,
        Size = UDim2.new(0, w, 0, h)
    }, parent)
    corner(b, 8)
    return b
end
local function input(parent, placeholder)
    local b = make("TextBox", {
        Text = "", PlaceholderText = placeholder or "", ClearTextOnFocus = false,
        Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = C.text,
        PlaceholderColor3 = C.muted, TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundColor3 = C.raised, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 38)
    }, parent)
    corner(b, 8)
    make("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 8)}, b)
    return b
end
local function safeIsA(obj, className)
    local ok, result = pcall(function() return obj:IsA(className) end)
    return ok and result
end
local function safeName(obj)
    local ok, value = pcall(function() return obj.Name end)
    return ok and tostring(value) or "[indisponivel]"
end
local function safeClass(obj)
    local ok, value = pcall(function() return obj.ClassName end)
    return ok and tostring(value) or "Instance"
end
local function getChildren(obj)
    local ok, children = pcall(function() return obj:GetChildren() end)
    return ok and children or {}
end
local function isPresent(obj)
    if obj == game then return true end
    local ok, parent = pcall(function() return obj.Parent end)
    return ok and parent ~= nil
end
local function lower(text) return string.lower(tostring(text or "")) end
local function pathOf(obj)
    if obj == game then return "game" end
    local segments = {}
    local current = obj
    for _ = 1, 256 do
        if current == game then
            local out = "game"
            for i = #segments, 1, -1 do out = out .. "[" .. string.format("%q", segments[i]) .. "]" end
            return out
        end
        local ok, parent = pcall(function() return current.Parent end)
        if not ok or not parent then break end
        segments[#segments + 1] = safeName(current)
        current = parent
    end
    return nil
end

local gui = make("ScreenGui", {
    Name = "DexNovaScreen", ResetOnSpawn = false, IgnoreGuiInset = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 100002
})
local guiParent
if type(gethui) == "function" then
    local ok, result = pcall(gethui)
    if ok and result then guiParent = result end
end
if not guiParent then
    local ok, result = pcall(function() return game:GetService("CoreGui") end)
    if ok and result then guiParent = result end
end
if not guiParent then guiParent = localPlayer:WaitForChild("PlayerGui") end
local existing = guiParent:FindFirstChild("DexNovaScreen")
if existing then pcall(function() existing:Destroy() end) end
local okParent = pcall(function() gui.Parent = guiParent end)
if not okParent then gui.Parent = localPlayer:WaitForChild("PlayerGui") end

local root = make("Frame", {
    Name = "Overlay", BackgroundTransparency = 1, BorderSizePixel = 0,
    Size = UDim2.fromScale(1, 1), Active = false
}, gui)
local panel = make("Frame", {
    Name = "Panel", BackgroundColor3 = C.bg, BorderSizePixel = 0,
    ClipsDescendants = true, Active = true
}, root)
corner(panel, 14)
stroke(panel)
local header = make("Frame", {
    Name = "Header", BackgroundColor3 = C.surface, BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 52), Active = true
}, panel)
local brand = label(header, "◆  DEX NOVA", 16, C.text)
brand.Font = Enum.Font.GothamBold
brand.Position = UDim2.fromOffset(16, 0)
brand.Size = UDim2.new(1, -112, 1, 0)
local minimizeButton = button(header, "—", 36, 32)
minimizeButton.AnchorPoint = Vector2.new(1, 0.5)
minimizeButton.Position = UDim2.new(1, -54, 0.5, 0)
local closeButton = button(header, "×", 36, 32)
closeButton.AnchorPoint = Vector2.new(1, 0.5)
closeButton.Position = UDim2.new(1, -10, 0.5, 0)
local tabBar = make("Frame", {
    BackgroundTransparency = 1, Size = UDim2.new(1, -20, 0, 38),
    Position = UDim2.fromOffset(10, 59)
}, panel)
local tabLayout = make("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 7),
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    SortOrder = Enum.SortOrder.LayoutOrder
}, tabBar)
local tabs = {}
for order, name in ipairs({"Explorer", "Propriedades", "Prévia"}) do
    local b = button(tabBar, name, 0, 34)
    b.Size = UDim2.new(1/3, -5, 0, 34)
    b.LayoutOrder = order
    tabs[name] = b
end
local contents = make("Frame", {
    BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 104),
    Size = UDim2.new(1, -20, 1, -133)
}, panel)
local explorer = make("Frame", {BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1)}, contents)
local properties = make("Frame", {BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false}, contents)
local preview = make("Frame", {BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false}, contents)
local footer = label(panel, "Pronto", 11, C.muted)
footer.Position = UDim2.new(0, 16, 1, -25)
footer.Size = UDim2.new(1, -32, 0, 20)
local floatButton = button(root, "◆ DEX", 84, 38, C.accent)
floatButton.TextColor3 = C.bg
floatButton.AnchorPoint = Vector2.new(1, 1)
floatButton.Position = UDim2.new(1, -12, 1, -12)
floatButton.Visible = false

-- Camadas de dialogos e menus sao filhas do painel, acima das abas.
local shade = make("TextButton", {
    Name = "Shade", Text = "", AutoButtonColor = false,
    BackgroundColor3 = rgb(0, 0, 0), BackgroundTransparency = 0.35,
    BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), Visible = false,
    ZIndex = 20
}, panel)
local sheet = make("Frame", {
    Name = "Actions", BackgroundColor3 = C.surface, BorderSizePixel = 0,
    Position = UDim2.new(0, 8, 1, -8), AnchorPoint = Vector2.new(0, 1),
    Size = UDim2.new(1, -16, 0, 320), Visible = false, ZIndex = 21
}, panel)
corner(sheet, 11)
stroke(sheet)
local sheetTitle = label(sheet, "Ações", 15, C.text)
sheetTitle.Font = Enum.Font.GothamBold
sheetTitle.Position = UDim2.fromOffset(14, 10)
sheetTitle.Size = UDim2.new(1, -28, 0, 24)
sheetTitle.ZIndex = 22
local sheetScroll = make("ScrollingFrame", {
    Position = UDim2.fromOffset(10, 43), Size = UDim2.new(1, -20, 1, -52),
    BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
    ScrollBarImageColor3 = C.muted, CanvasSize = UDim2.fromOffset(0, 0), ZIndex = 22
}, sheet)
local modal = make("Frame", {
    Name = "Dialog", BackgroundColor3 = C.surface, BorderSizePixel = 0,
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.new(1, -34, 0, 220), Visible = false, ZIndex = 23
}, panel)
corner(modal, 11)
stroke(modal)
local modalTitle = label(modal, "", 16, C.text)
modalTitle.Font = Enum.Font.GothamBold
modalTitle.Position = UDim2.fromOffset(14, 14)
modalTitle.Size = UDim2.new(1, -28, 0, 24)
modalTitle.ZIndex = 24
local modalDescription = label(modal, "", 12, C.muted)
modalDescription.Position = UDim2.fromOffset(14, 42)
modalDescription.Size = UDim2.new(1, -28, 0, 36)
modalDescription.TextWrapped = true
modalDescription.TextYAlignment = Enum.TextYAlignment.Top
modalDescription.ZIndex = 24
local modalInputs = make("Frame", {
    BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 80),
    Size = UDim2.new(1, -28, 1, -130), ZIndex = 24
}, modal)
local modalCancel = button(modal, "Cancelar", 100, 34)
modalCancel.AnchorPoint = Vector2.new(1, 1)
modalCancel.Position = UDim2.new(1, -126, 1, -12)
modalCancel.ZIndex = 24
local modalSave = button(modal, "Salvar", 100, 34, C.accent)
modalSave.TextColor3 = C.bg
modalSave.AnchorPoint = Vector2.new(1, 1)
modalSave.Position = UDim2.new(1, -14, 1, -12)
modalSave.ZIndex = 24

local state = {
    alive = true, selected = nil, tab = "Explorer", filter = "Tudo",
    expanded = {[game] = true}, cache = setmetatable({}, {__mode = "k"}),
    visible = {}, searchResults = {}, searchToken = 0, searchBusy = false,
    query = "", suggestion = nil, copied = nil, previewMode = nil,
    previewTrack = nil, previewWorld = nil, previewCamera = nil,
    orbitYaw = 0.4, orbitPitch = -0.18, orbitDistance = 10,
    orbitCenter = Vector3.new(0, 0, 0), orbitAuto = false,
    connections = {}, rowLimit = 4000, drag = nil, deleting = false
}
local function connect(signal, callback)
    local c = signal:Connect(callback)
    state.connections[#state.connections + 1] = c
    return c
end
local function status(message, kind)
    if not state.alive then return end
    footer.Text = tostring(message)
    footer.TextColor3 = kind == "error" and C.danger or kind == "ok" and C.green or C.muted
end
local function errorText(err)
    local s = tostring(err)
    return #s > 125 and s:sub(1, 122) .. "..." or s
end
local function cleanupPreview()
    if state.previewTrack then pcall(function() state.previewTrack:Stop(0) end) end
    state.previewTrack = nil
    state.previewWorld = nil
    state.previewCamera = nil
    state.previewMode = nil
end
local function destroy()
    if not state.alive then return end
    state.alive = false
    state.searchToken = state.searchToken + 1
    cleanupPreview()
    if state.selectedChanged then state.selectedChanged:Disconnect() state.selectedChanged = nil end
    if state.attributeChanged then state.attributeChanged:Disconnect() state.attributeChanged = nil end
    if state.dialogConnection then state.dialogConnection:Disconnect() state.dialogConnection = nil end
    for _, c in ipairs(state.connections) do pcall(function() c:Disconnect() end) end
    if state.copied then pcall(function() state.copied:Destroy() end) end
    pcall(function() gui:Destroy() end)
    if globalEnv and globalEnv.__DEX_NOVA and globalEnv.__DEX_NOVA.Destroy == destroy then
        globalEnv.__DEX_NOVA = nil
    end
end
if globalEnv then globalEnv.__DEX_NOVA = {Destroy = destroy, Version = "1.0"} end

local function fitPanel(center)
    local vw, vh = root.AbsoluteSize.X, root.AbsoluteSize.Y
    if vw < 40 or vh < 70 then return end
    local width = math.max(270, math.min(570, vw - 16))
    local height = math.max(320, math.min(690, vh - 20))
    width = math.min(width, vw)
    height = math.min(height, vh)
    local px, py
    if center or panel.Size.X.Offset == 0 then
        px, py = (vw - width) / 2, (vh - height) / 2
    else
        px = math.max(0, math.min(panel.Position.X.Offset, vw - width))
        py = math.max(0, math.min(panel.Position.Y.Offset, vh - height))
    end
    panel.Size = UDim2.fromOffset(width, height)
    panel.Position = UDim2.fromOffset(px, py)
    sheet.Size = UDim2.new(1, -16, 0, math.min(390, height - 70))
    modal.Size = UDim2.new(1, -34, 0, math.min(270, height - 60))
end
local function hideLayers()
    shade.Visible = false
    sheet.Visible = false
    modal.Visible = false
end
connect(shade.Activated, hideLayers)
connect(modalCancel.Activated, hideLayers)
connect(root:GetPropertyChangedSignal("AbsoluteSize"), function() fitPanel(false) end)
connect(minimizeButton.Activated, function()
    hideLayers()
    panel.Visible = false
    floatButton.Visible = true
end)
connect(floatButton.Activated, function()
    panel.Visible = true
    floatButton.Visible = false
    fitPanel(false)
end)
connect(closeButton.Activated, destroy)
local dragStart, panelStart, dragInput
connect(header.InputBegan, function(inputObject)
    if inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch then
        dragStart, panelStart, dragInput = inputObject.Position, panel.Position, inputObject
    end
end)
connect(UserInputService.InputChanged, function(inputObject)
    if not dragInput then return end
    if inputObject == dragInput or (dragInput.UserInputType == Enum.UserInputType.MouseButton1 and inputObject.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = inputObject.Position - dragStart
        local x = math.max(0, math.min(panelStart.X.Offset + delta.X, root.AbsoluteSize.X - panel.AbsoluteSize.X))
        local y = math.max(0, math.min(panelStart.Y.Offset + delta.Y, root.AbsoluteSize.Y - panel.AbsoluteSize.Y))
        panel.Position = UDim2.fromOffset(x, y)
    end
end)
connect(UserInputService.InputEnded, function(inputObject)
    if inputObject == dragInput or (dragInput and dragInput.UserInputType == Enum.UserInputType.MouseButton1 and inputObject.UserInputType == Enum.UserInputType.MouseButton1) then
        dragInput = nil
    end
end)

local showTab, selectObject, redrawTree, startSearch, rebuildProperties, startPreview, openActions
local function showDialog(title, description, fields, onSave, saveText)
    hideLayers()
    shade.Visible, modal.Visible = true, true
    modalTitle.Text, modalDescription.Text = title, description or ""
    modalSave.Text = saveText or "Salvar"
    for _, child in ipairs(modalInputs:GetChildren()) do child:Destroy() end
    local values = {}
    for i, field in ipairs(fields or {}) do
        local box = input(modalInputs, field.placeholder or field.name)
        box.Text = field.value or ""
        box.Position = UDim2.fromOffset(0, (i - 1) * 43)
        box.Size = UDim2.new(1, 0, 0, 36)
        box.ZIndex = 24
        values[i] = box
    end
    -- A dialog's previous callback is disconnected when a new one is installed.
    if state.dialogConnection then state.dialogConnection:Disconnect() end
    state.dialogConnection = modalSave.Activated:Connect(function()
        if not state.alive or not modal.Visible then return end
        local strings = {}
        for i, box in ipairs(values) do strings[i] = box.Text end
        local ok, message = pcall(onSave, strings)
        if not ok then status(errorText(message), "error")
        elseif message == false then return
        else hideLayers() end
    end)
    if values[1] then values[1]:CaptureFocus() end
end
local function showSheet(title, actions)
    hideLayers()
    shade.Visible, sheet.Visible = true, true
    sheetTitle.Text = title
    for _, child in ipairs(sheetScroll:GetChildren()) do child:Destroy() end
    local offset = 0
    for _, entry in ipairs(actions) do
        local b = button(sheetScroll, entry[1], 0, 40, entry[3] and C.danger or C.raised)
        b.Size = UDim2.new(1, -6, 0, 40)
        b.Position = UDim2.fromOffset(0, offset)
        b.ZIndex = 23
        b.TextXAlignment = Enum.TextXAlignment.Left
        make("UIPadding", {PaddingLeft = UDim.new(0, 12)}, b)
        b.Activated:Connect(function()
            if not state.alive then return end
            hideLayers()
            local ok, err = pcall(entry[2])
            if not ok then status(errorText(err), "error") end
        end)
        offset = offset + 45
    end
    sheetScroll.CanvasSize = UDim2.fromOffset(0, offset + 5)
    sheetScroll.CanvasPosition = Vector2.new(0, 0)
end
local function copyText(text)
    local copier = nil
    if type(setclipboard) == "function" then copier = setclipboard
    elseif type(toclipboard) == "function" then copier = toclipboard end
    if copier then
        local ok = pcall(copier, text)
        if ok then status("Copiado para a área de transferência.", "ok") return end
    end
    showDialog("Copiar texto", "Selecione e copie o texto abaixo.", {{name = "Texto", value = text}}, function() end, "Fechar")
end

-- Explorer: arvore carregada por ramo, busca cooperativa e linhas recicladas.
local searchBox = input(explorer, "Pesquisar nome ou class:Classe")
searchBox.Size = UDim2.new(1, -45, 0, 38)
local ghost = label(explorer, "", 14, C.muted)
ghost.Position = UDim2.fromOffset(13, 0)
ghost.Size = UDim2.new(1, -70, 0, 38)
ghost.TextTransparency = 0.53
ghost.ZIndex = searchBox.ZIndex + 1
ghost.Active = false
local clearSearch = button(explorer, "×", 38, 38)
clearSearch.AnchorPoint = Vector2.new(1, 0)
clearSearch.Position = UDim2.new(1, 0, 0, 0)
local chipScroll = make("ScrollingFrame", {
    BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 46),
    Size = UDim2.new(1, 0, 0, 37), ScrollingDirection = Enum.ScrollingDirection.X,
    ScrollBarThickness = 0, CanvasSize = UDim2.fromOffset(0, 0)
}, explorer)
local filters = {"Tudo", "Partes", "Scripts", "Animações", "Interfaces"}
local filterButtons = {}
local totalWidth = 0
for _, filterName in ipairs(filters) do
    local chipWidth = (filterName == "Interfaces" or filterName == "Animações") and 104 or 82
    local chip = button(chipScroll, filterName, chipWidth, 30)
    chip.Position = UDim2.fromOffset(totalWidth, 1)
    chip.BackgroundColor3 = filterName == "Tudo" and C.accent or C.raised
    chip.TextColor3 = filterName == "Tudo" and C.bg or C.text
    filterButtons[filterName] = chip
    totalWidth = totalWidth + chipWidth + 6
    chip.Activated:Connect(function()
        state.filter = filterName
        for name, b in pairs(filterButtons) do
            b.BackgroundColor3 = name == filterName and C.accent or C.raised
            b.TextColor3 = name == filterName and C.bg or C.text
        end
        startSearch()
    end)
end
chipScroll.CanvasSize = UDim2.fromOffset(totalWidth, 0)
local list = make("ScrollingFrame", {
    Name = "Tree", BackgroundColor3 = C.surface, BorderSizePixel = 0,
    Position = UDim2.fromOffset(0, 91), Size = UDim2.new(1, 0, 1, -164),
    CanvasSize = UDim2.fromOffset(0, 0), ScrollBarThickness = 4,
    ScrollBarImageColor3 = C.muted, ScrollingDirection = Enum.ScrollingDirection.Y,
    Active = true, ClipsDescendants = true
}, explorer)
corner(list, 9)
local selectionBar = make("Frame", {
    BackgroundColor3 = C.surface, BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, -65),
    Size = UDim2.new(1, 0, 0, 65)
}, explorer)
corner(selectionBar, 9)
local selectedLabel = label(selectionBar, "Selecione uma Instance", 13, C.text)
selectedLabel.Font = Enum.Font.GothamMedium
selectedLabel.Position = UDim2.fromOffset(10, 5)
selectedLabel.Size = UDim2.new(1, -20, 0, 22)
local selectedClass = label(selectionBar, "Toque na seta para abrir uma pasta", 11, C.muted)
selectedClass.Position = UDim2.fromOffset(10, 27)
selectedClass.Size = UDim2.new(1, -20, 0, 18)
local actionButton = button(selectionBar, "Ações", 75, 30, C.accent)
actionButton.TextColor3 = C.bg
actionButton.AnchorPoint = Vector2.new(1, 1)
actionButton.Position = UDim2.new(1, -8, 1, -7)
local propsButton = button(selectionBar, "Detalhes", 78, 30)
propsButton.AnchorPoint = Vector2.new(1, 1)
propsButton.Position = UDim2.new(1, -90, 1, -7)
selectedLabel.Size = UDim2.new(1, -175, 0, 22)
selectedClass.Size = UDim2.new(1, -175, 0, 18)

local ROW_HEIGHT = 38
local rowPool = {}
local function isSearchActive() return state.query ~= "" or state.filter ~= "Tudo" end
local function cachedChildren(obj)
    local cached = state.cache[obj]
    if cached then return cached end
    cached = getChildren(obj)
    table.sort(cached, function(a, b)
        local na, nb = lower(safeName(a)), lower(safeName(b))
        if na == nb then return safeClass(a) < safeClass(b) end
        return na < nb
    end)
    state.cache[obj] = cached
    return cached
end
local function rebuildVisible()
    local output = {}
    if isSearchActive() then
        for _, result in ipairs(state.searchResults) do
            output[#output + 1] = {obj = result, depth = 0, searched = true}
        end
    else
        local stack = {{obj = game, depth = 0}}
        while #stack > 0 and #output < state.rowLimit do
            local node = table.remove(stack)
            output[#output + 1] = node
            if state.expanded[node.obj] then
                local children = cachedChildren(node.obj)
                for i = #children, 1, -1 do
                    if children[i] ~= gui and children[i] ~= root then
                        stack[#stack + 1] = {obj = children[i], depth = node.depth + 1}
                    end
                end
            end
        end
        if #stack > 0 then output[#output + 1] = {more = true} end
    end
    state.visible = output
    list.CanvasSize = UDim2.fromOffset(0, #output * ROW_HEIGHT)
end
local renderRows
local function toggleExpanded(obj)
    state.expanded[obj] = not state.expanded[obj]
    redrawTree()
end
local function rowStyle(obj)
    if safeIsA(obj, "Animation") then return "", C.pale, true end
    if safeIsA(obj, "LuaSourceContainer") then return "{ }", C.gold, false end
    if safeIsA(obj, "BasePart") then return "■", C.accent, false end
    if safeIsA(obj, "Model") then return "◈", C.green, false end
    if safeIsA(obj, "GuiObject") then return "▣", C.pale, false end
    if safeIsA(obj, "ValueBase") then return "≡", C.gold, false end
    return "◇", C.muted, false
end
local function createRow()
    local frame = make("Frame", {
        BackgroundColor3 = C.surface, BorderSizePixel = 0,
        Size = UDim2.new(1, -6, 0, ROW_HEIGHT - 2)
    }, list)
    local main = make("TextButton", {
        AutoButtonColor = false, Text = "", BackgroundTransparency = 1,
        BorderSizePixel = 0, Size = UDim2.fromScale(1, 1)
    }, frame)
    local arrow = make("TextButton", {
        Text = "", Font = Enum.Font.GothamBold, TextSize = 17,
        TextColor3 = C.muted, BackgroundTransparency = 1,
        BorderSizePixel = 0, Size = UDim2.fromOffset(25, ROW_HEIGHT - 2)
    }, frame)
    local icon = label(frame, "", 16, C.muted)
    icon.TextXAlignment = Enum.TextXAlignment.Center
    icon.Size = UDim2.fromOffset(23, ROW_HEIGHT - 2)
    local imageIcon = make("ImageLabel", {
        Image = "rbxassetid://79777748023029", ImageColor3 = rgb(255, 255, 255),
        BackgroundTransparency = 1, Size = UDim2.fromOffset(20, 20), Visible = false
    }, frame)
    local title = label(frame, "", 13, C.text)
    title.Font = Enum.Font.GothamMedium
    title.Size = UDim2.new(1, -120, 0, ROW_HEIGHT - 2)
    local kind = label(frame, "", 10, C.muted)
    kind.TextXAlignment = Enum.TextXAlignment.Right
    kind.AnchorPoint = Vector2.new(1, 0)
    kind.Position = UDim2.new(1, -7, 0, 0)
    kind.Size = UDim2.fromOffset(96, ROW_HEIGHT - 2)
    local row = {frame = frame, arrow = arrow, icon = icon, imageIcon = imageIcon,
        title = title, kind = kind, entry = nil}
    main.Activated:Connect(function()
        if not row.entry then return end
        if row.entry.more then
            state.rowLimit = state.rowLimit + 4000
            redrawTree()
        else
            selectObject(row.entry.obj)
        end
    end)
    arrow.Activated:Connect(function()
        if row.entry and row.entry.obj then toggleExpanded(row.entry.obj) end
    end)
    rowPool[#rowPool + 1] = row
end
renderRows = function()
    if not state.alive then return end
    local top = math.max(1, math.floor(list.CanvasPosition.Y / ROW_HEIGHT) + 1)
    local count = math.min(32, math.ceil(math.max(250, list.AbsoluteSize.Y) / ROW_HEIGHT) + 3)
    while #rowPool < count do createRow() end
    for i, row in ipairs(rowPool) do
        local index = top + i - 1
        local entry = i <= count and state.visible[index] or nil
        row.entry = entry
        row.frame.Visible = entry ~= nil
        if entry then
            row.frame.Position = UDim2.fromOffset(3, (index - 1) * ROW_HEIGHT)
            if entry.more then
                row.frame.BackgroundColor3 = C.raised
                row.arrow.Text, row.title.Text, row.kind.Text = "", "Mostrar mais 4.000 linhas", ""
                row.title.Position = UDim2.fromOffset(14, 0)
                row.title.Size = UDim2.new(1, -18, 1, 0)
                row.icon.Visible, row.imageIcon.Visible = false, false
            else
                local obj = entry.obj
                local indent = math.min(76, entry.depth * 13)
                local iconText, iconColor, useImage = rowStyle(obj)
                row.frame.BackgroundColor3 = state.selected == obj and C.hover or (index % 2 == 0 and C.surface or C.bg)
                row.arrow.Position = UDim2.fromOffset(indent + 1, 0)
                row.arrow.Text = entry.searched and "" or (#getChildren(obj) > 0 and (state.expanded[obj] and "⌄" or "›") or "")
                row.icon.Visible, row.imageIcon.Visible = not useImage, useImage
                row.icon.Text, row.icon.TextColor3 = iconText, iconColor
                row.icon.Position = UDim2.fromOffset(indent + 26, 0)
                row.imageIcon.Position = UDim2.fromOffset(indent + 27, 8)
                row.title.Text = safeName(obj)
                row.title.Position = UDim2.fromOffset(indent + 53, 0)
                row.title.Size = UDim2.new(1, -(indent + 152), 1, 0)
                row.kind.Text = safeClass(obj)
            end
        end
    end
end
redrawTree = function()
    if not state.alive then return end
    rebuildVisible()
    renderRows()
end
connect(list:GetPropertyChangedSignal("CanvasPosition"), renderRows)
connect(list:GetPropertyChangedSignal("AbsoluteSize"), renderRows)

local function matchesFilter(obj)
    if state.filter == "Partes" then return safeIsA(obj, "BasePart") or safeIsA(obj, "Model") end
    if state.filter == "Scripts" then return safeIsA(obj, "LuaSourceContainer") end
    if state.filter == "Animações" then return safeIsA(obj, "Animation") end
    if state.filter == "Interfaces" then return safeIsA(obj, "GuiObject") or safeIsA(obj, "ScreenGui") end
    return true
end
local function updateGhost()
    ghost.Text = ""
    local suggestion = state.suggestion
    if not suggestion or state.query == "" then return end
    local name = safeName(suggestion)
    if lower(name:sub(1, #state.query)) ~= lower(state.query) then return end
    local prefix = name:sub(1, #state.query)
    local width = TextService:GetTextSize(prefix, searchBox.TextSize, searchBox.Font, Vector2.new(10000, 40)).X
    ghost.Position = UDim2.fromOffset(13 + width, 0)
    ghost.Text = name:sub(#state.query + 1)
end
startSearch = function()
    if not state.alive then return end
    state.query = searchBox.Text:match("^%s*(.-)%s*$") or ""
    state.searchToken = state.searchToken + 1
    local token = state.searchToken
    state.searchResults, state.suggestion = {}, nil
    state.searchBusy = false
    updateGhost()
    if not isSearchActive() then
        redrawTree()
        status("Árvore de Instances · toque em › para expandir")
        return
    end
    local query = lower(state.query)
    local mode = "any"
    if query:sub(1, 6) == "class:" then mode, query = "class", query:sub(7)
    elseif query:sub(1, 5) == "name:" then mode, query = "name", query:sub(6) end
    query = query:match("^%s*(.-)%s*$") or ""
    state.searchBusy = true
    list.CanvasPosition = Vector2.new(0, 0)
    redrawTree()
    status("Pesquisando...")
    task.spawn(function()
        local prefixes, others = {}, {}
        local bestLength = math.huge
        local total, visited = 0, 0
        -- Pilha DFS: GetChildren apenas do ramo atual, sem montar GetDescendants inteiro.
        local stack = {{children = getChildren(game), index = 1}}
        while #stack > 0 and state.alive and token == state.searchToken do
            local frame = stack[#stack]
            local obj = frame.children[frame.index]
            if obj == nil then
                stack[#stack] = nil
            else
                frame.index = frame.index + 1
                if obj ~= gui and obj ~= root then
                    visited = visited + 1
                    if matchesFilter(obj) then
                        local name, class = lower(safeName(obj)), lower(safeClass(obj))
                        local namePos = string.find(name, query, 1, true)
                        local classPos = string.find(class, query, 1, true)
                        local matches = query == "" or (mode == "class" and classPos)
                            or (mode == "name" and namePos) or (mode == "any" and (namePos or classPos))
                        if matches then
                            total = total + 1
                            if namePos == 1 and #prefixes < 180 then
                                prefixes[#prefixes + 1] = obj
                            elseif #others < 180 then
                                others[#others + 1] = obj
                            end
                            if query ~= "" and mode ~= "class" and namePos == 1 and #name < bestLength then
                                state.suggestion, bestLength = obj, #name
                            end
                        end
                    end
                    stack[#stack + 1] = {children = getChildren(obj), index = 1}
                    if visited % 260 == 0 then
                        local combined = {}
                        for _, v in ipairs(prefixes) do combined[#combined + 1] = v end
                        for _, v in ipairs(others) do
                            if #combined >= 180 then break end
                            combined[#combined + 1] = v
                        end
                        state.searchResults = combined
                        redrawTree()
                        updateGhost()
                        status(string.format("Pesquisando... %d itens vistos · %d encontrados", visited, total))
                        task.wait()
                    end
                end
            end
        end
        if not state.alive or token ~= state.searchToken then return end
        local combined = {}
        for _, v in ipairs(prefixes) do combined[#combined + 1] = v end
        for _, v in ipairs(others) do
            if #combined >= 180 then break end
            combined[#combined + 1] = v
        end
        state.searchResults, state.searchBusy = combined, false
        redrawTree()
        updateGhost()
        status(string.format("%d resultado(s)%s", total, total > 180 and " · mostrando 180" or ""))
    end)
end
local debounceSerial = 0
local focusTree
connect(searchBox:GetPropertyChangedSignal("Text"), function()
    debounceSerial = debounceSerial + 1
    local serial = debounceSerial
    task.delay(0.16, function()
        if state.alive and serial == debounceSerial then startSearch() end
    end)
end)
connect(clearSearch.Activated, function()
    searchBox.Text = ""
    if state.filter ~= "Tudo" then
        state.filter = "Tudo"
        for name, b in pairs(filterButtons) do
            b.BackgroundColor3 = name == "Tudo" and C.accent or C.raised
            b.TextColor3 = name == "Tudo" and C.bg or C.text
        end
    end
    list.CanvasPosition = Vector2.new(0, 0)
    startSearch()
end)
connect(searchBox.FocusLost, function(enterPressed)
    if enterPressed and state.suggestion and state.query ~= "" then
        local suggestion = state.suggestion
        selectObject(suggestion)
        focusTree(suggestion)
        showTab("Explorer")
    end
end)
focusTree = function(obj)
    if not obj then return end
    searchBox.Text = ""
    state.filter = "Tudo"
    for name, b in pairs(filterButtons) do
        b.BackgroundColor3 = name == "Tudo" and C.accent or C.raised
        b.TextColor3 = name == "Tudo" and C.bg or C.text
    end
    state.searchToken = state.searchToken + 1
    state.query, state.searchResults, state.suggestion = "", {}, nil
    updateGhost()
    local current = obj
    for _ = 1, 256 do
        if current == game or not current then break end
        local ok, parent = pcall(function() return current.Parent end)
        if not ok or not parent then break end
        state.expanded[parent] = true
        current = parent
    end
    redrawTree()
    for i, entry in ipairs(state.visible) do
        if entry.obj == obj then
            list.CanvasPosition = Vector2.new(0, math.max(0, (i - 3) * ROW_HEIGHT))
            break
        end
    end
end
selectObject = function(obj)
    if not obj then return end
    state.selected = obj
    selectedLabel.Text = safeName(obj)
    selectedClass.Text = safeClass(obj)
    renderRows()
    rebuildProperties()
    status("Selecionado: " .. safeName(obj))
end
connect(actionButton.Activated, function() if state.selected then openActions() else status("Selecione uma Instance.") end end)
connect(propsButton.Activated, function() if state.selected then showTab("Propriedades") else status("Selecione uma Instance.") end end)

local treeUpdatePending = false
local function scheduleTreeUpdate()
    if treeUpdatePending or not state.alive then return end
    treeUpdatePending = true
    task.delay(0.18, function()
        treeUpdatePending = false
        if state.alive then
            if isSearchActive() then startSearch() else redrawTree() end
        end
    end)
end
connect(game.DescendantAdded, function(obj)
    local ok, parent = pcall(function() return obj.Parent end)
    if ok and parent then state.cache[parent] = nil end
    scheduleTreeUpdate()
end)
connect(game.DescendantRemoving, function(obj)
    local ok, parent = pcall(function() return obj.Parent end)
    if ok and parent then state.cache[parent] = nil end
    scheduleTreeUpdate()
end)

-- Propriedades: campos legiveis, edicao por tipo e atributos personalizados.
local propHeading = label(properties, "Nenhuma Instance selecionada", 14, C.text)
propHeading.Font = Enum.Font.GothamBold
propHeading.Position = UDim2.fromOffset(3, 0)
propHeading.Size = UDim2.new(1, -130, 0, 27)
local attrButton = button(properties, "+ Atributo", 105, 30)
attrButton.AnchorPoint = Vector2.new(1, 0)
attrButton.Position = UDim2.new(1, 0, 0, 0)
local propertySearch = input(properties, "Filtrar propriedades")
propertySearch.Position = UDim2.fromOffset(0, 39)
propertySearch.Size = UDim2.new(1, 0, 0, 36)
local propList = make("ScrollingFrame", {
    BackgroundColor3 = C.surface, BorderSizePixel = 0,
    Position = UDim2.fromOffset(0, 83), Size = UDim2.new(1, 0, 1, -83),
    CanvasSize = UDim2.fromOffset(0, 0), ScrollBarThickness = 4,
    ScrollBarImageColor3 = C.muted, Active = true
}, properties)
corner(propList, 9)
local propGroups = {
    {"Instance", {"Name", "ClassName", "Parent", "Archivable"}},
    {"Transformação", {"Position", "Orientation", "Rotation", "Size", "CFrame", "PivotOffset", "PrimaryPart"}},
    {"Aparência", {"Transparency", "Color", "BrickColor", "Material", "Reflectance", "CastShadow", "Shape"}},
    {"Física", {"Anchored", "CanCollide", "CanTouch", "CanQuery", "Massless", "AssemblyLinearVelocity"}},
    {"Interface", {"Enabled", "Visible", "Text", "TextColor3", "TextTransparency", "TextSize", "Image", "ImageColor3", "ImageTransparency", "BackgroundColor3", "BackgroundTransparency", "Size", "Position", "AnchorPoint", "ZIndex"}},
    {"Áudio / Animação", {"SoundId", "Volume", "PlaybackSpeed", "Looped", "Playing", "AnimationId"}},
    {"Humanoide", {"Health", "MaxHealth", "WalkSpeed", "JumpPower", "AutoRotate", "HipHeight"}},
    {"Luz e efeitos", {"Brightness", "Range", "Shadows", "LightEmission", "Rate", "Lifetime", "Speed"}},
    {"Dados", {"Value", "Disabled", "RunContext"}}
}
local function prettyValue(value)
    local typ = typeof(value)
    if typ == "Color3" then
        return string.format("#%02X%02X%02X", math.floor(value.R * 255 + 0.5),
            math.floor(value.G * 255 + 0.5), math.floor(value.B * 255 + 0.5))
    end
    if typ == "Instance" then return safeName(value) .. " (" .. safeClass(value) .. ")" end
    if typ == "EnumItem" then return value.Name end
    return tostring(value)
end
local function parseValue(old, raw)
    local typ = typeof(old)
    local trimmed = tostring(raw):match("^%s*(.-)%s*$") or ""
    if typ == "string" then return true, raw end
    if typ == "number" then
        local n = tonumber(trimmed)
        if n and n == n and math.abs(n) ~= math.huge then return true, n end
        return false, "Número inválido"
    end
    if typ == "boolean" then
        if trimmed == "true" or trimmed == "1" or lower(trimmed) == "sim" then return true, true end
        if trimmed == "false" or trimmed == "0" or lower(trimmed) == "não" or lower(trimmed) == "nao" then return true, false end
        return false, "Use true ou false"
    end
    local numbers = {}
    for n in trimmed:gmatch("[-+]?%d*%.?%d+[eE]?[-+]?%d*") do
        local value = tonumber(n)
        if value then numbers[#numbers + 1] = value end
    end
    if typ == "Vector3" and #numbers == 3 then return true, Vector3.new(numbers[1], numbers[2], numbers[3]) end
    if typ == "Vector2" and #numbers == 2 then return true, Vector2.new(numbers[1], numbers[2]) end
    if typ == "UDim" and #numbers == 2 then return true, UDim.new(numbers[1], numbers[2]) end
    if typ == "UDim2" and #numbers == 4 then
        return true, UDim2.new(numbers[1], numbers[2], numbers[3], numbers[4])
    end
    if typ == "Color3" then
        local hex = trimmed:match("^#?(%x%x%x%x%x%x)$")
        if hex then
            return true, Color3.fromRGB(tonumber(hex:sub(1, 2), 16),
                tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16))
        end
        if #numbers == 3 then
            for _, n in ipairs(numbers) do
                if n < 0 or n > 255 then return false, "RGB: valores de 0 a 255" end
            end
            return true, Color3.fromRGB(numbers[1], numbers[2], numbers[3])
        end
        return false, "Use #RRGGBB ou R, G, B (0–255)"
    end
    if typ == "BrickColor" then
        local ok, value = pcall(BrickColor.new, trimmed)
        if ok then return true, value end
        return false, "BrickColor inválida"
    end
    if typ == "EnumItem" then
        local ok, choices = pcall(function() return old.EnumType:GetEnumItems() end)
        if ok then
            for _, item in ipairs(choices) do
                if lower(item.Name) == lower(trimmed) then return true, item end
            end
        end
        return false, "Item de enumeração inválido"
    end
    return false, "Tipo não editável neste painel"
end
local function canEdit(value, propName)
    if propName == "ClassName" or propName == "Parent" or propName == "CFrame"
        or propName == "PrimaryPart" or propName == "AssemblyLinearVelocity" then return false end
    local t = typeof(value)
    return t == "string" or t == "number" or t == "boolean" or t == "Vector3"
        or t == "Vector2" or t == "Color3" or t == "UDim" or t == "UDim2"
        or t == "EnumItem" or t == "BrickColor"
end
local function collectProperties(obj)
    local groups, seen = {}, {}
    for _, definition in ipairs(propGroups) do
        local groupName = definition[1]
        local applies = groupName == "Instance"
            or (groupName == "Transformação" and (safeIsA(obj, "BasePart") or safeIsA(obj, "Model")))
            or (groupName == "Aparência" and safeIsA(obj, "BasePart"))
            or (groupName == "Física" and safeIsA(obj, "BasePart"))
            or (groupName == "Interface" and (safeIsA(obj, "GuiObject") or safeIsA(obj, "LayerCollector")))
            or (groupName == "Áudio / Animação" and (safeIsA(obj, "Sound") or safeIsA(obj, "Animation")))
            or (groupName == "Humanoide" and safeIsA(obj, "Humanoid"))
            or (groupName == "Luz e efeitos" and (safeIsA(obj, "Light") or safeIsA(obj, "ParticleEmitter")))
            or (groupName == "Dados" and (safeIsA(obj, "ValueBase") or safeIsA(obj, "LuaSourceContainer")))
        if applies then
            local current = {name = groupName, fields = {}}
            for _, propName in ipairs(definition[2]) do
                if not seen[propName] then
                    local ok, value = pcall(function() return obj[propName] end)
                    if ok then
                        seen[propName] = true
                        current.fields[#current.fields + 1] = {name = propName, value = value}
                    end
                end
            end
            if #current.fields > 0 then groups[#groups + 1] = current end
        end
    end
    local ok, attrs = pcall(function() return obj:GetAttributes() end)
    if ok and next(attrs) then
        local names = {}
        for name in pairs(attrs) do names[#names + 1] = name end
        table.sort(names)
        local current = {name = "Atributos", fields = {}}
        for _, name in ipairs(names) do
            current.fields[#current.fields + 1] = {name = name, value = attrs[name], attribute = true}
        end
        groups[#groups + 1] = current
    end
    return groups
end
local propUpdateSerial = 0
local function schedulePropRefresh()
    propUpdateSerial = propUpdateSerial + 1
    local serial = propUpdateSerial
    task.delay(0.24, function()
        if not state.alive or serial ~= propUpdateSerial or state.tab ~= "Propriedades" then return end
        local focused = UserInputService:GetFocusedTextBox()
        if focused and focused:IsDescendantOf(properties) then return end
        rebuildProperties()
    end)
end
local function editAttributeDelete(obj, name)
    showDialog("Remover atributo", "Remover " .. name .. " desta Instance?", {}, function()
        local ok, err = pcall(function() obj:SetAttribute(name, nil) end)
        if not ok then status(errorText(err), "error") return false end
        status("Atributo removido.", "ok")
        task.defer(rebuildProperties)
    end, "Remover")
end
rebuildProperties = function()
    if not state.alive then return end
    local obj = state.selected
    propHeading.Text = obj and (safeName(obj) .. "  ·  " .. safeClass(obj)) or "Nenhuma Instance selecionada"
    attrButton.Visible = obj ~= nil and obj ~= game
    for _, child in ipairs(propList:GetChildren()) do child:Destroy() end
    if not obj then
        propList.CanvasSize = UDim2.fromOffset(0, 0)
        return
    end
    local term = lower(propertySearch.Text)
    local y = 5
    for _, group in ipairs(collectProperties(obj)) do
        local shown = {}
        for _, field in ipairs(group.fields) do
            if term == "" or lower(field.name):find(term, 1, true) then shown[#shown + 1] = field end
        end
        if #shown > 0 then
            local groupTitle = label(propList, group.name, 11, C.accent)
            groupTitle.Font = Enum.Font.GothamBold
            groupTitle.Position = UDim2.fromOffset(10, y)
            groupTitle.Size = UDim2.new(1, -20, 0, 24)
            y = y + 25
            for _, field in ipairs(shown) do
                local currentField = field
                local row = make("Frame", {
                    BackgroundColor3 = y % 2 == 0 and C.bg or C.raised,
                    BorderSizePixel = 0, Position = UDim2.fromOffset(6, y),
                    Size = UDim2.new(1, -15, 0, 45)
                }, propList)
                corner(row, 6)
                local nameLabel = label(row, currentField.name, 12, C.muted)
                nameLabel.Position = UDim2.fromOffset(8, 2)
                nameLabel.Size = UDim2.new(1, currentField.attribute and -55 or -16, 0, 17)
                if currentField.attribute then
                    local del = button(row, "×", 29, 27)
                    del.AnchorPoint = Vector2.new(1, 0)
                    del.Position = UDim2.new(1, -5, 0, 9)
                    del.Activated:Connect(function() editAttributeDelete(obj, currentField.name) end)
                end
                local value = currentField.value
                if typeof(value) == "boolean" and canEdit(value, currentField.name) then
                    local toggle = button(row, value and "ATIVADO" or "DESATIVADO", 0, 24, value and C.green or C.hover)
                    toggle.TextColor3 = C.bg
                    toggle.Position = UDim2.fromOffset(8, 19)
                    toggle.Size = UDim2.new(1, currentField.attribute and -50 or -16, 0, 24)
                    toggle.Activated:Connect(function()
                        local ok, err = pcall(function()
                            if currentField.attribute then obj:SetAttribute(currentField.name, not value)
                            else obj[currentField.name] = not value end
                        end)
                        if ok then status(currentField.name .. " atualizado.", "ok") rebuildProperties()
                        else status(errorText(err), "error") end
                    end)
                elseif canEdit(value, currentField.name) then
                    local editor = input(row, "Valor")
                    editor.Text = prettyValue(value)
                    editor.TextSize = 12
                    editor.Position = UDim2.fromOffset(7, 19)
                    editor.Size = UDim2.new(1, currentField.attribute and -50 or -14, 0, 24)
                    editor.FocusLost:Connect(function()
                        local parsed, newValue = parseValue(value, editor.Text)
                        if not parsed then
                            editor.Text = prettyValue(value)
                            status(newValue, "error")
                            return
                        end
                        local ok, err = pcall(function()
                            if currentField.attribute then obj:SetAttribute(currentField.name, newValue)
                            else obj[currentField.name] = newValue end
                        end)
                        if ok then status(currentField.name .. " atualizado.", "ok")
                        else editor.Text = prettyValue(value) status(errorText(err), "error") end
                        task.defer(rebuildProperties)
                    end)
                else
                    local valueLabel = label(row, prettyValue(value), 12, C.text)
                    valueLabel.Position = UDim2.fromOffset(9, 19)
                    valueLabel.Size = UDim2.new(1, currentField.attribute and -52 or -18, 0, 24)
                end
                y = y + 48
            end
            y = y + 5
        end
    end
    if y == 5 then
        local empty = label(propList, "Nenhuma propriedade corresponde ao filtro.", 13, C.muted)
        empty.Position = UDim2.fromOffset(12, 14)
        empty.Size = UDim2.new(1, -22, 0, 28)
    end
    propList.CanvasSize = UDim2.fromOffset(0, y + 8)
end
connect(propertySearch:GetPropertyChangedSignal("Text"), rebuildProperties)
connect(attrButton.Activated, function()
    local obj = state.selected
    if not obj or obj == game then return end
    showDialog("Novo atributo", "Tipos: string, number ou boolean. Ex.: true / 42 / texto.",
        {{name = "Nome"}, {name = "Tipo", value = "string"}, {name = "Valor"}},
        function(values)
            local name, typ = values[1]:match("^%s*(.-)%s*$"), lower(values[2])
            if name == "" then status("Informe o nome do atributo.", "error") return false end
            local old = typ == "number" and 0 or typ == "boolean" and false or ""
            if typ ~= "string" and typ ~= "number" and typ ~= "boolean" then
                status("Tipo: string, number ou boolean.", "error") return false
            end
            local valid, parsed = parseValue(old, values[3])
            if not valid then status(parsed, "error") return false end
            local ok, err = pcall(function() obj:SetAttribute(name, parsed) end)
            if not ok then status(errorText(err), "error") return false end
            status("Atributo criado.", "ok")
            task.defer(rebuildProperties)
        end)
end)

-- Preview fisico/animado: copia isolada em WorldModel; nunca anima o personagem real.
local previewTitle = label(preview, "Selecione um Model, Part ou Animation", 14, C.text)
previewTitle.Font = Enum.Font.GothamBold
previewTitle.Position = UDim2.fromOffset(3, 1)
previewTitle.Size = UDim2.new(1, -6, 0, 26)
local previewPath = label(preview, "A prévia usa uma cópia local.", 11, C.muted)
previewPath.Position = UDim2.fromOffset(3, 25)
previewPath.Size = UDim2.new(1, -6, 0, 18)
local viewport = make("ViewportFrame", {
    BackgroundColor3 = C.surface, BorderSizePixel = 0,
    Ambient = rgb(180, 185, 200), LightColor = rgb(255, 250, 240),
    LightDirection = Vector3.new(-1, -1, -1), Active = true,
    Position = UDim2.fromOffset(0, 49), Size = UDim2.new(1, 0, 1, -108)
}, preview)
corner(viewport, 9)
local previewControls = make("Frame", {
    BackgroundTransparency = 1, Position = UDim2.new(0, 0, 1, -50),
    Size = UDim2.new(1, 0, 0, 45)
}, preview)
local zoomOut = button(previewControls, "−", 43, 40)
zoomOut.Position = UDim2.fromOffset(0, 0)
local zoomIn = button(previewControls, "+", 43, 40)
zoomIn.Position = UDim2.fromOffset(49, 0)
local rotateButton = button(previewControls, "Girar", 73, 40)
rotateButton.Position = UDim2.fromOffset(98, 0)
local playButton = button(previewControls, "Pausar", 85, 40, C.accent)
playButton.AnchorPoint = Vector2.new(1, 0)
playButton.Position = UDim2.new(1, 0, 0, 0)
playButton.TextColor3 = C.bg
playButton.Visible = false
local function setPreviewHint(text)
    previewTitle.Text = text
    previewPath.Text = "A prévia usa uma cópia local."
end
local function cloneTemporary(obj)
    local oldArchivable = obj.Archivable
    if not oldArchivable then obj.Archivable = true end
    local ok, copied = pcall(function() return obj:Clone() end)
    if not oldArchivable then pcall(function() obj.Archivable = oldArchivable end) end
    if not ok or not copied then error(copied or "Não foi possível clonar") end
    return copied
end
local function hasPart(obj)
    if safeIsA(obj, "BasePart") then return true end
    if not safeIsA(obj, "Model") then return false end
    local ok, part = pcall(function() return obj:FindFirstChildWhichIsA("BasePart", true) end)
    return ok and part ~= nil
end
local function updateOrbit()
    if not state.previewCamera then return end
    local cp = math.cos(state.orbitPitch)
    local offset = Vector3.new(math.sin(state.orbitYaw) * cp,
        math.sin(state.orbitPitch), math.cos(state.orbitYaw) * cp) * state.orbitDistance
    state.previewCamera.CFrame = CFrame.new(state.orbitCenter + offset, state.orbitCenter)
end
startPreview = function(obj)
    if not obj then setPreviewHint("Selecione um Model, Part ou Animation") return end
    if state.tab ~= "Prévia" then showTab("Prévia") return end
    cleanupPreview()
    viewport:ClearAllChildren()
    playButton.Visible = false
    if not safeIsA(obj, "Animation") and not hasPart(obj) then
        setPreviewHint("Esta Instance não tem prévia 3D")
        return
    end
    local world = make("WorldModel", {}, viewport)
    local camera = make("Camera", {FieldOfView = 55}, viewport)
    viewport.CurrentCamera = camera
    local ok, err = pcall(function()
        local model
        if safeIsA(obj, "Animation") then
            if obj.AnimationId == "" then error("AnimationId vazio") end
            local character = localPlayer.Character
            if not character then error("Seu personagem ainda não apareceu") end
            model = cloneTemporary(character)
        elseif safeIsA(obj, "BasePart") then
            model = Instance.new("Model")
            local part = cloneTemporary(obj)
            part.Parent = model
        else
            model = cloneTemporary(obj)
        end
        -- Scripts copiados sao desnecessarios para a exibicao e podem interferir nela.
        for _, descendant in ipairs(model:GetDescendants()) do
            if safeIsA(descendant, "LuaSourceContainer") then descendant:Destroy() end
        end
        model.Parent = world
        pcall(function() model:PivotTo(CFrame.new()) end)
        if safeIsA(obj, "Animation") then
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            local controller = model:FindFirstChildOfClass("AnimationController")
            local holder = humanoid or controller
            if not holder then error("O personagem não possui Humanoid ou AnimationController") end
            local rootPart = model:FindFirstChild("HumanoidRootPart")
            if rootPart and safeIsA(rootPart, "BasePart") then rootPart.Anchored = true end
            local animator = holder:FindFirstChildOfClass("Animator") or make("Animator", {}, holder)
            local track = animator:LoadAnimation(obj)
            pcall(function() track.Looped = true end)
            track:Play(0.1)
            state.previewTrack = track
            state.previewMode = "animation"
            playButton.Text, playButton.Visible = "Pausar", true
        else
            state.previewMode = "model"
        end
        local box, size = model:GetBoundingBox()
        state.orbitCenter = box.Position
        state.orbitDistance = math.max(6, size.Magnitude * 1.15)
        state.orbitYaw, state.orbitPitch = 0.4, -0.16
        state.previewWorld, state.previewCamera = world, camera
        updateOrbit()
        previewTitle.Text = safeName(obj) .. (state.previewMode == "animation" and " · Animation" or " · 3D")
        previewPath.Text = pathOf(obj) or "Instance sem pai"
    end)
    if not ok then
        cleanupPreview()
        viewport:ClearAllChildren()
        playButton.Visible = false
        setPreviewHint("Prévia indisponível")
        status("Prévia: " .. errorText(err), "error")
    else
        status("Prévia aberta: " .. safeName(obj), "ok")
    end
end
connect(zoomOut.Activated, function()
    if state.previewCamera then state.orbitDistance = math.min(10000, state.orbitDistance * 1.25) updateOrbit() end
end)
connect(zoomIn.Activated, function()
    if state.previewCamera then state.orbitDistance = math.max(1.5, state.orbitDistance / 1.25) updateOrbit() end
end)
connect(viewport.InputChanged, function(inputObject)
    if state.previewCamera and inputObject.UserInputType == Enum.UserInputType.MouseWheel then
        state.orbitDistance = math.max(1.5, math.min(10000,
            state.orbitDistance * (inputObject.Position.Z > 0 and 0.86 or 1.16)))
        updateOrbit()
    end
end)
connect(rotateButton.Activated, function()
    state.orbitAuto = not state.orbitAuto
    rotateButton.BackgroundColor3 = state.orbitAuto and C.accent or C.raised
    rotateButton.TextColor3 = state.orbitAuto and C.bg or C.text
end)
connect(playButton.Activated, function()
    local track = state.previewTrack
    if not track then return end
    local ok, err = pcall(function()
        if track.IsPlaying then track:Stop(0.1) playButton.Text = "Reproduzir"
        else track:Play(0.1) playButton.Text = "Pausar" end
    end)
    if not ok then status(errorText(err), "error") end
end)
local previewDrag, previewLast
connect(viewport.InputBegan, function(inputObject)
    if inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch then
        previewDrag, previewLast = inputObject, inputObject.Position
    end
end)
connect(UserInputService.InputChanged, function(inputObject)
    if not previewDrag or not state.previewCamera then return end
    if inputObject == previewDrag or
        (previewDrag.UserInputType == Enum.UserInputType.MouseButton1 and inputObject.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = inputObject.Position - previewLast
        previewLast = inputObject.Position
        state.orbitYaw = state.orbitYaw - delta.X * 0.012
        state.orbitPitch = math.max(-1.3, math.min(1.3, state.orbitPitch - delta.Y * 0.012))
        updateOrbit()
    end
end)
connect(UserInputService.InputEnded, function(inputObject)
    if inputObject == previewDrag or (previewDrag and previewDrag.UserInputType == Enum.UserInputType.MouseButton1
        and inputObject.UserInputType == Enum.UserInputType.MouseButton1) then previewDrag = nil end
end)
connect(RunService.RenderStepped, function(dt)
    if state.previewCamera and state.orbitAuto and state.tab == "Prévia" and panel.Visible then
        state.orbitYaw = state.orbitYaw + dt * 0.45
        updateOrbit()
    end
end)

-- Visualizacao opcional de scripts se o executor oferecer decompile.
local sourceFrame = make("Frame", {
    BackgroundColor3 = C.surface, BorderSizePixel = 0,
    Position = UDim2.fromOffset(9, 60), Size = UDim2.new(1, -18, 1, -70),
    Visible = false, ZIndex = 25
}, panel)
corner(sourceFrame, 9)
stroke(sourceFrame)
local sourceHeading = label(sourceFrame, "Código", 14, C.text)
sourceHeading.Position = UDim2.fromOffset(11, 9)
sourceHeading.Size = UDim2.new(1, -115, 0, 27)
sourceHeading.ZIndex = 26
local sourceClose = button(sourceFrame, "Fechar", 74, 29)
sourceClose.Position = UDim2.new(1, -84, 0, 8)
sourceClose.ZIndex = 26
local sourceScroll = make("ScrollingFrame", {
    BackgroundColor3 = C.bg, BorderSizePixel = 0, Position = UDim2.fromOffset(8, 44),
    Size = UDim2.new(1, -16, 1, -51), CanvasSize = UDim2.fromOffset(0, 0),
    ScrollBarThickness = 4, ScrollBarImageColor3 = C.muted, ZIndex = 26
}, sourceFrame)
local sourceText = make("TextBox", {
    Text = "", TextEditable = false, ClearTextOnFocus = false, MultiLine = true,
    Font = Enum.Font.Code, TextSize = 13, TextColor3 = C.text,
    BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top, BorderSizePixel = 0,
    Position = UDim2.fromOffset(8, 5), Size = UDim2.new(1, -16, 0, 100), ZIndex = 27
}, sourceScroll)
connect(sourceClose.Activated, function() sourceFrame.Visible = false shade.Visible = false end)
local function viewCode(obj)
    local decoder = type(decompile) == "function" and decompile or nil
    if not decoder then status("Este executor não oferece decompile.", "error") return end
    status("Lendo script...")
    task.spawn(function()
        local ok, code = pcall(decoder, obj)
        if not state.alive then return end
        if not ok or type(code) ~= "string" then
            status("Código indisponível: " .. errorText(code), "error") return
        end
        local limit = 100000
        local text = code:sub(1, limit)
        if #code > limit then text = text .. "\n-- Exibição limitada a 100.000 caracteres." end
        local _, lineCount = text:gsub("\n", "")
        sourceText.Text = text
        local height = math.max(120, math.min(300000, (lineCount + 2) * 16))
        sourceText.Size = UDim2.new(1, -16, 0, height)
        sourceScroll.CanvasSize = UDim2.fromOffset(0, height + 15)
        sourceScroll.CanvasPosition = Vector2.new(0, 0)
        sourceHeading.Text = "Código · " .. safeName(obj)
        hideLayers()
        shade.Visible = true
        sourceFrame.Visible = true
        status("Código exibido.", "ok")
    end)
end
connect(shade.Activated, function() sourceFrame.Visible = false end)

-- Acoes disponiveis por tipo; operacoes falhas retornam mensagem na barra inferior.
local function createChild(parent, className)
    local child = Instance.new(className)
    if className == "Part" then
        child.Anchored = true
        child.Size = Vector3.new(2, 2, 2)
    end
    local ok, err = pcall(function() child.Parent = parent end)
    if not ok then child:Destroy() error(err) end
    state.expanded[parent] = true
    state.cache[parent] = nil
    selectObject(child)
    focusTree(child)
    status(className .. " criado.", "ok")
end
local function duplicate(obj)
    local parent = obj.Parent
    if not parent then error("Instance sem pai") end
    local copy = cloneTemporary(obj)
    copy.Name = safeName(obj) .. " (cópia)"
    local ok, err = pcall(function() copy.Parent = parent end)
    if not ok then copy:Destroy() error(err) end
    state.cache[parent] = nil
    selectObject(copy)
    focusTree(copy)
    status("Cópia criada.", "ok")
end
local function deleteObject(obj)
    if obj == game or not isPresent(obj) then return end
    showDialog("Confirmar exclusão", "Excluir " .. safeName(obj) .. " e todos os seus descendentes?", {}, function()
        local oldParent = obj.Parent
        local ok, err = pcall(function() obj:Destroy() end)
        if not ok then status(errorText(err), "error") return false end
        if oldParent then state.cache[oldParent] = nil end
        if state.selected == obj then state.selected = nil end
        cleanupPreview()
        viewport:ClearAllChildren()
        setPreviewHint("Selecione um Model, Part ou Animation")
        selectedLabel.Text, selectedClass.Text = "Selecione uma Instance", ""
        rebuildProperties()
        redrawTree()
        status("Instance excluída.", "ok")
    end, "Excluir")
end
local function copyInstance(obj)
    local cloned = cloneTemporary(obj)
    if state.copied then pcall(function() state.copied:Destroy() end) end
    state.copied = cloned
    status("Instance copiada. Selecione o destino e use Colar.", "ok")
end
local function pasteInto(target)
    if not state.copied then return end
    local clone = state.copied:Clone()
    local ok, err = pcall(function() clone.Parent = target end)
    if not ok then clone:Destroy() error(err) end
    state.expanded[target] = true
    state.cache[target] = nil
    selectObject(clone)
    focusTree(clone)
    status("Instance colada.", "ok")
end
openActions = function()
    local obj = state.selected
    if not obj then return end
    local actions = {
        {"Encontrar na árvore", function() focusTree(obj) showTab("Explorer") end},
        {"Copiar caminho", function()
            local path = pathOf(obj)
            if path then copyText(path) else status("Instance sem caminho em game.", "error") end
        end},
        {"Copiar nome", function() copyText(safeName(obj)) end}
    }
    if obj ~= game then
        actions[#actions + 1] = {"Ir para o pai", function()
            if obj.Parent then selectObject(obj.Parent) focusTree(obj.Parent) end
        end}
        actions[#actions + 1] = {"Renomear", function()
            showDialog("Renomear Instance", safeClass(obj), {{name = "Novo nome", value = safeName(obj)}}, function(values)
                if values[1]:match("^%s*$") then status("Digite um nome.", "error") return false end
                local ok, err = pcall(function() obj.Name = values[1] end)
                if not ok then status(errorText(err), "error") return false end
                if obj.Parent then state.cache[obj.Parent] = nil end
                selectObject(obj)
                redrawTree()
                status("Nome atualizado.", "ok")
            end)
        end}
        actions[#actions + 1] = {"Duplicar", function() duplicate(obj) end}
        actions[#actions + 1] = {"Copiar Instance", function() copyInstance(obj) end}
    end
    if state.copied then
        actions[#actions + 1] = {"Colar como filho", function() pasteInto(obj) end}
    end
    actions[#actions + 1] = {"Criar filho...", function()
        local choices = {}
        for _, className in ipairs({"Folder", "Model", "Part", "StringValue", "NumberValue", "BoolValue", "Animation"}) do
            local targetClass = className
            choices[#choices + 1] = {"+ " .. className, function() createChild(obj, targetClass) end}
        end
        showSheet("Criar em " .. safeName(obj), choices)
    end}
    if hasPart(obj) then
        actions[#actions + 1] = {"Visualizar em 3D", function() startPreview(obj) end}
    end
    -- IsA verifica a classe real da Instance, nunca nome, texto ou asset id.
    if safeIsA(obj, "Animation") then
        actions[#actions + 1] = {"Prévia da animação", function() startPreview(obj) end}
    end
    if safeIsA(obj, "LuaSourceContainer") and type(decompile) == "function" then
        actions[#actions + 1] = {"Ver código do script", function() viewCode(obj) end}
    end
    if obj ~= game then
        actions[#actions + 1] = {"Excluir Instance", function() deleteObject(obj) end, true}
    end
    showSheet(safeName(obj) .. " · " .. safeClass(obj), actions)
end
showTab = function(name)
    if not state.alive then return end
    sourceFrame.Visible = false
    hideLayers()
    if state.tab == "Prévia" and name ~= "Prévia" then
        cleanupPreview()
        viewport:ClearAllChildren()
        playButton.Visible = false
    end
    state.tab = name
    explorer.Visible = name == "Explorer"
    properties.Visible = name == "Propriedades"
    preview.Visible = name == "Prévia"
    for title, b in pairs(tabs) do
        b.BackgroundColor3 = title == name and C.accent or C.raised
        b.TextColor3 = title == name and C.bg or C.text
    end
    if name == "Propriedades" then rebuildProperties() end
    if name == "Prévia" and not state.previewMode then
        if state.selected then startPreview(state.selected)
        else setPreviewHint("Selecione um Model, Part ou Animation") end
    end
end
for name, b in pairs(tabs) do
    local tabName = name
    connect(b.Activated, function() showTab(tabName) end)
end

-- Uma unica assinatura para o objeto selecionado; invalidacoes nao interrompem a digitacao.
local previousSelect = selectObject
selectObject = function(obj)
    if state.selectedChanged then state.selectedChanged:Disconnect() state.selectedChanged = nil end
    if state.attributeChanged then state.attributeChanged:Disconnect() state.attributeChanged = nil end
    previousSelect(obj)
    local ok, changed = pcall(function() return obj.Changed end)
    if ok and changed then
        state.selectedChanged = changed:Connect(function(property)
            if not state.alive then return end
            if property == "Name" then
                selectedLabel.Text = safeName(obj)
                if obj.Parent then state.cache[obj.Parent] = nil end
                if not isSearchActive() then scheduleTreeUpdate() end
            end
            schedulePropRefresh()
        end)
    end
    local okAttr, attributeSignal = pcall(function() return obj.AttributeChanged end)
    if okAttr and attributeSignal then
        state.attributeChanged = attributeSignal:Connect(function()
            if state.alive then schedulePropRefresh() end
        end)
    end
end
if globalEnv then
    globalEnv.__DEX_NOVA.Select = function(obj)
        if not state.alive or typeof(obj) ~= "Instance" then return false end
        selectObject(obj)
        focusTree(obj)
        panel.Visible, floatButton.Visible = true, false
        showTab("Explorer")
        return true
    end
    globalEnv.__DEX_NOVA.Show = function()
        if not state.alive then return false end
        panel.Visible, floatButton.Visible = true, false
        fitPanel(false)
        return true
    end
end
fitPanel(true)
showTab("Explorer")
redrawTree()
status("Pronto · toque em › para navegar; pesquisa e filtros ficam no topo.", "ok")
