-- WCUE GAMEPASS BYPASS + PREVIEW UNLOCK (2026 EDITION - UPDATE main.lua)

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local EditorRig = nil
local selectedPart = nil
local cachedParts = {}

-- FULL WCUE ACCESSORY/MARKING LIST (FREE + ALL GAMEPASSES - FROM WIKI)
local wcueItems = {
    -- Free/Default
    "BackEarSpot", "EarTufts", "EarSpeckles", "TailRing", "TailStripe", "FurPatch", "WhiskerDot", "EyeScar",
    -- Gamepass Locked (these work via preview clone)
    "MarbledMarking", "MiniPack", "LargeWarrior", "ButterflyHarness", "ReindeerAntler", "FallHarvestLeaf", "HollyBerry", "PlagueDoctorMask",
    "WizardHat", "PirateHat", "FurBundle", "MonarchWing", "SummerFlower", "AutumnFur", "EyeShine", "BigKitty", "SmallCat",
    "FrontLegFluff", "BackLegStripe", "NoseScar", "CheekTuft", "ShoulderSpot", "FlankSwirl", "PawFreckle", "TailTipWhite",
    -- Events/Limited
    "NewleafPetal", "HalloweenPumpkin", "WinterSnowflake", "AnniversaryCrown", "VIPNecklace"
}

local function getTargetRig()
    EditorRig = Workspace:FindFirstChild("EditorRig", true)
    if EditorRig and (EditorRig:FindFirstChild("Head") or EditorRig:FindFirstChild("Torso")) then return EditorRig end
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
            obj.Color = col; obj.Transparency = 0; count += 1
        end
        local surf = obj:FindFirstChildOfClass("SurfaceAppearance")
        if surf then surf.Color = col; count += 1 end
    end
    return count
end

local function applyScale(itemName, scale, target)
    local count = 0
    for _, obj in target:GetDescendants() do
        if obj.Name == itemName and (obj:IsA("BasePart") or obj:IsA("MeshPart")) then
            local orig = obj:GetAttribute("OrigSize") or obj.Size
            obj:SetAttribute("OrigSize", orig)
            obj.Size = orig * scale; count += 1
        end
    end
    return count
end

-- GAMEPASS BYPASS: FORCE CLONE FROM PREVIEW TEMPLATES
local function loadPreviewItem(itemName)
    local target = getTargetRig()
    if not target then return "No rig" end
    
    -- Scan ALL services for hidden preview templates
    local sources = {ReplicatedStorage, game:GetService("ServerStorage"), game:GetService("Lighting"), game:GetService("StarterGui"), Workspace}
    local found = 0
    
    for _, source in pairs(sources) do
        for _, obj in source:GetDescendants() do
            if (obj.Name:lower():find(itemName:lower()) or obj.Name == itemName) and 
               (obj:IsA("MeshPart") or obj:IsA("Accessory") or obj:IsA("Part") or obj:IsA("Model")) then
                
                local clone = obj:Clone()
                clone.Parent = target
                if clone:IsA("BasePart") then clone.Transparency = 0; clone.Color = Color3.new(1,1,1) end
                found += 1
                print("Unlocked preview: " .. obj:GetFullName())
            end
        end
    end
    
    return found > 0 and ("Loaded " .. found .. "x " .. itemName .. " (gamepass bypassed!)") or ("No preview found: " .. itemName)
end

-- GUI (same layout, new LOAD PREVIEW button)
local gui = Instance.new("ScreenGui", playerGui); gui.Name = "WCUEBypass"; gui.ResetOnSpawn = false
local frame = Instance.new("Frame", gui); frame.Size = UDim2.new(0,340,0,420); frame.Position = UDim2.new(0.5,-170,0.05,0)
frame.BackgroundColor3 = Color3.fromRGB(25,25,40); frame.Active = true; frame.Draggable = true

-- [All GUI elements same as before, but add this button below ADD SERVER]
local previewBtn = Instance.new("TextButton", frame)
previewBtn.Size = UDim2.new(0.9,0,0,35); previewBtn.Position = UDim2.new(0.05,0,0.68,0)
previewBtn.Text = "LOAD PREVIEW (Gamepass Bypass)"
previewBtn.BackgroundColor3 = Color3.fromRGB(255,200,80)
previewBtn.TextColor3 = Color3.new(1,1,1); previewBtn.Parent = frame

-- Item selector dropdown with WCUE list
local itemDrop = Instance.new("TextButton", frame)
itemDrop.Size = UDim2.new(0.9,0,0,35); itemDrop.Position = UDim2.new(0.05,0,0.78,0)
itemDrop.Text = "Select WCUE Item ▼"; itemDrop.BackgroundColor3 = Color3.fromRGB(80,100,200)

local itemList = Instance.new("ScrollingFrame", frame)
itemList.Size = UDim2.new(0.9,0,0,100); itemList.Position = UDim2.new(0.05,0,0.88,0)
itemList.BackgroundColor3 = Color3.fromRGB(35,35,50); itemList.Visible = false; itemList.Parent = frame

-- [Rest of GUI/events same: status, hexBox, scaleBox, partDrop, listFrame, colorBtn, scaleBtn, accInput, addLocalBtn, addServerBtn (keep for free items), randBtn]

-- Populate WCUE item list
local function populateItemList()
    itemList:ClearAllChildren()
    local y = 5
    for _, item in ipairs(wcueItems) do
        local btn = Instance.new("TextButton", itemList)
        btn.Size = UDim2.new(1,-10,0,25); btn.Position = UDim2.new(0,5,0,y)
        btn.Text = item; btn.BackgroundColor3 = Color3.fromRGB(60,80,120)
        btn.TextColor3 = Color3.new(1,1,1); btn.TextScaled = true
        btn.MouseButton1Click:Connect(function()
            accInput.Text = item
            itemDrop.Text = "Loaded: " .. item
            itemList.Visible = false
        end)
        y += 28
    end
    itemList.CanvasSize = UDim2.new(0,0,0,y)
end
itemDrop.MouseButton1Click:Connect(function() populateItemList(); itemList.Visible = not itemList.Visible end)

-- Preview button event
previewBtn.MouseButton1Click:Connect(function()
    local item = accInput.Text:match("^%s*(.-)%s*$")
    if item ~= "" then status.Text = loadPreviewItem(item) end
end)

-- [Keep all other events/functions from previous script: partDrop, colorBtn, scaleBtn, etc.]
-- Status loop, prints, etc. same

print("WCUE BYPASS LOADED - Use 'Select WCUE Item' → LOAD PREVIEW for gamepass unlock!")
