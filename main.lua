-- WCUE HARDCODE EDITOR (FIXED - UI WILL APPEAR)

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local EditorRig = nil
local selectedPart = nil
local cachedParts = {}

local function getTargetRig()
    EditorRig = Workspace:FindFirstChild("EditorRig", true)
    if EditorRig and (EditorRig:FindFirstChild("Head") or EditorRig:FindFirstChild("Torso")) then
        return EditorRig
    end
    return player.Character
end

local function hexToColor(hex)
    hex = hex:gsub("#", ""):gsub("%s+", "")
    if #hex ~= 6 then return Color3.fromRGB(150,150,150) end
    return Color3.fromRGB(tonumber(hex:sub(1,2),16) or 150, tonumber(hex:sub(3,4),16) or 150, tonumber(hex:sub(5,6),16) or 150)
end

local function applyColor(itemName, col, target)
    local count = 0
    for _, obj in target:GetDescendants() do
        if obj.Name == itemName and (obj:IsA("BasePart") or obj:IsA("MeshPart")) then
            obj.Color = col
            obj.Transparency = 0
            count = count + 1
        end
        local surf = obj:FindFirstChildOfClass("SurfaceAppearance")
        if surf then surf.Color = col; count = count + 1 end
    end
    return count
end

local function applyScale(itemName, scale, target)
    local count = 0
    for _, obj in target:GetDescendants() do
        if obj.Name == itemName and (obj:IsA("BasePart") or obj:IsA("MeshPart")) then
            local orig = obj:GetAttribute("OrigSize") or obj.Size
            obj:SetAttribute("OrigSize", orig)
            obj.Size = orig * scale
            count = count + 1
        end
    end
    return count
end

local function spamAddServer(accName)
    local count = 0
    for _, remote in ReplicatedStorage:GetDescendants() do
        if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
            local rname = remote.Name:lower()
            if rname:find("equip") or rname:find("add") or rname:find("morph") or rname:find("custom") or rname:find("access") then
                pcall(function() remote:FireServer(accName) end)
                pcall(function() remote:FireServer("Equip", accName) end)
                pcall(function() remote:FireServer("Add", accName, true) end)
                count = count + 1
            end
        end
    end
    return "SPAMMED " .. count .. " remotes for: " .. accName
end

-- GUI (FIXED - ALL PARENTS ASSIGNED)
local gui = Instance.new("ScreenGui")
gui.Name = "WCUEHardEditor"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 320, 0, 380)
frame.Position = UDim2.new(0.5, -160, 0.05, 0)
frame.BackgroundColor3 = Color3.fromRGB(25,25,40)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1,0,0,25)
status.Position = UDim2.new(0,0,0,0)
status.BackgroundTransparency = 1
status.Text = "WCUE HARDCODE - LOADING..."
status.TextColor3 = Color3.new(1,1,1)
status.Font = Enum.Font.GothamBold
status.TextSize = 14
status.Parent = frame

local hexBox = Instance.new("TextBox")
hexBox.Size = UDim2.new(0.6,0,0,35)
hexBox.Position = UDim2.new(0.05,0,0.08,0)
hexBox.Text = "#FF69B4"
hexBox.BackgroundColor3 = Color3.fromRGB(45,45,60)
hexBox.TextColor3 = Color3.new(1,1,1)
hexBox.Font = Enum.Font.Code
hexBox.Parent = frame

local scaleBox = Instance.new("TextBox")
scaleBox.Size = UDim2.new(0.3,0,0,35)
scaleBox.Position = UDim2.new(0.67,0,0.08,0)
scaleBox.Text = "1.2"
scaleBox.BackgroundColor3 = Color3.fromRGB(45,45,60)
scaleBox.TextColor3 = Color3.new(1,1,1)
scaleBox.Parent = frame

local partDrop = Instance.new("TextButton")
partDrop.Size = UDim2.new(0.9,0,0,35)
partDrop.Position = UDim2.new(0.05,0,0.18,0)
partDrop.Text = "Select Part/Mesh ▼"
partDrop.BackgroundColor3 = Color3.fromRGB(55,55,75)
partDrop.TextColor3 = Color3.new(1,1,1)
partDrop.Font = Enum.Font.GothamBold
partDrop.Parent = frame

local listFrame = Instance.new("ScrollingFrame")
listFrame.Size = UDim2.new(0.9,0,0,120)
listFrame.Position = UDim2.new(0.05,0,0.28,0)
listFrame.BackgroundColor3 = Color3.fromRGB(35,35,50)
listFrame.BorderSizePixel = 0
listFrame.ScrollBarThickness = 4
listFrame.Visible = false
listFrame.CanvasSize = UDim2.new(0,0,0,0)
listFrame.Parent = frame

local colorBtn = Instance.new("TextButton")
colorBtn.Size = UDim2.new(0.44,0,0,35)
colorBtn.Position = UDim2.new(0.05,0,0.43,0)
colorBtn.Text = "HEX Color"
colorBtn.BackgroundColor3 = Color3.fromRGB(70,150,255)
colorBtn.TextColor3 = Color3.new(1,1,1)
colorBtn.Parent = frame

local scaleBtn = Instance.new("TextButton")
scaleBtn.Size = UDim2.new(0.44,0,0,35)
scaleBtn.Position = UDim2.new(0.51,0,0.43,0)
scaleBtn.Text = "Scale"
scaleBtn.BackgroundColor3 = Color3.fromRGB(180,100,255)
scaleBtn.TextColor3 = Color3.new(1,1,1)
scaleBtn.Parent = frame

local accInput = Instance.new("TextBox")
accInput.Size = UDim2.new(0.9,0,0,35)
accInput.Position = UDim2.new(0.05,0,0.53,0)
accInput.Text = "BackEarSpot"
accInput.BackgroundColor3 = Color3.fromRGB(45,45,60)
accInput.TextColor3 = Color3.new(1,1,1)
accInput.Parent = frame

local addLocalBtn = Instance.new("TextButton")
addLocalBtn.Size = UDim2.new(0.44,0,0,40)
addLocalBtn.Position = UDim2.new(0.05,0,0.61,0)
addLocalBtn.Text = "ADD LOCAL"
addLocalBtn.BackgroundColor3 = Color3.fromRGB(100,100,200)
addLocalBtn.TextColor3 = Color3.new(1,1,1)
addLocalBtn.Parent = frame

local addServerBtn = Instance.new("TextButton")
addServerBtn.Size = UDim2.new(0.44,0,0,40)
addServerBtn.Position = UDim2.new(0.51,0,0.61,0)
addServerBtn.Text = "ADD SERVER"
addServerBtn.BackgroundColor3 = Color3.fromRGB(255,100,100)
addServerBtn.TextColor3 = Color3.new(1,1,1)
addServerBtn.Parent = frame

local randBtn = Instance.new("TextButton")
randBtn.Size = UDim2.new(0.9,0,0,35)
randBtn.Position = UDim2.new(0.05,0,0.73,0)
randBtn.Text = "Random Colors"
randBtn.BackgroundColor3 = Color3.fromRGB(200,150,100)
randBtn.TextColor3 = Color3.new(1,1,1)
randBtn.Parent = frame

-- FUNCTIONS
local function updateList()
    local target = getTargetRig()
    if not target then return end
    cachedParts = {}
    local seen = {}
    for _, obj in target:GetDescendants() do
        local n = obj.Name
        if (obj:IsA("BasePart") or obj:IsA("MeshPart")) and not seen[n] and n ~= "HumanoidRootPart" then
            table.insert(cachedParts, n)
            seen[n] = true
        end
    end
    table.sort(cachedParts)
end

local function populateList()
    updateList()
    listFrame:ClearAllChildren()
    local y = 5
    for _, name in ipairs(cachedParts) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1,-10,0,28)
        btn.Position = UDim2.new(0,5,0,y)
        btn.Text = name
        btn.BackgroundColor3 = Color3.fromRGB(65,65,85)
        btn.TextColor3 = Color3.new(1,1,1)
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = listFrame
        btn.MouseButton1Click:Connect(function()
            selectedPart = name
            partDrop.Text = "Selected: " .. name
            listFrame.Visible = false
        end)
        y = y + 32
    end
    listFrame.CanvasSize = UDim2.new(0,0,0,y)
end

-- EVENTS
partDrop.MouseButton1Click:Connect(function()
    local target = getTargetRig()
    if target then
        populateList()
        listFrame.Visible = not listFrame.Visible
        status.Text = "EditorRig/Char Found - " .. #cachedParts .. " parts"
    else
        status.Text = "NO EditorRig/Character!"
    end
end)

colorBtn.MouseButton1Click:Connect(function()
    if selectedPart then
        local target = getTargetRig()
        local col = hexToColor(hexBox.Text)
        local cnt = applyColor(selectedPart, col, target)
        status.Text = "Colored " .. cnt .. " parts"
    end
end)

scaleBtn.MouseButton1Click:Connect(function()
    if selectedPart then
        local target = getTargetRig()
        local s = math.clamp(tonumber(scaleBox.Text) or 1, 0.5, 3)
        local cnt = applyScale(selectedPart, s, target)
        status.Text = "Scaled " .. cnt .. " parts to " .. s
    end
end)

addLocalBtn.MouseButton1Click:Connect(function()
    local acc = accInput.Text:match("^%s*(.-)%s*$")
    local target = getTargetRig()
    if target and acc ~= "" then
        status.Text = "Local add attempted: " .. acc
    end
end)

addServerBtn.MouseButton1Click:Connect(function()
    local acc = accInput.Text:match("^%s*(.-)%s*$")
    if acc ~= "" then
        status.Text = spamAddServer(acc)
    end
end)

randBtn.MouseButton1Click:Connect(function()
    local target = getTargetRig()
    if target then
        for _, obj in target:GetDescendants() do
            if obj:IsA("BasePart") or obj:IsA("MeshPart") then
                obj.Color = Color3.fromRGB(math.random(80,180), math.random(80,180), math.random(80,180))
            end
        end
        status.Text = "Random colors applied!"
    end
end)

-- STATUS LOOP
spawn(function()
    while wait(2) do
        local target = getTargetRig()
        if target and EditorRig then
            status.Text = "EDITORRIG DETECTED - READY"
            status.TextColor3 = Color3.fromRGB(0,255,0)
        elseif target then
            status.Text = "In-Game Character - READY"
            status.TextColor3 = Color3.fromRGB(0,200,255)
        else
            status.Text = "OPEN EDITOR OR SPAWN!"
            status.TextColor3 = Color3.fromRGB(255,100,100)
        end
    end
end)

print("WCUE HARDCODE EDITOR LOADED - UI SHOULD APPEAR NOW")
print("Go to character editor → click Select Part → use buttons")
