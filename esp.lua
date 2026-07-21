local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Keep track of active drawings so we don't duplicate or leak memory on rescan
local activeDrawings = {}

local function cleanupDrawings()
    for _, item in ipairs(activeDrawings) do
        if item.box then item.box:Remove() end
        if item.text then item.text:Remove() end
        if item.connection then item.connection:Disconnect() end
    end
    activeDrawings = {}
end

-- Function to track and draw items on screen
local function trackItem(targetObject, labelText)
    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = Color3.fromRGB(0, 255, 255)
    box.Thickness = 1.5
    box.Filled = false

    local text = Drawing.new("Text")
    text.Visible = false
    text.Color = Color3.fromRGB(255, 255, 255)
    text.Size = 14
    text.Center = true
    text.Outline = true
    text.Text = labelText

    local connection
    connection = RunService.RenderStepped:Connect(function()
        if not targetObject or not targetObject.Parent then
            box:Remove()
            text:Remove()
            connection:Disconnect()
            return
        end

        local part = targetObject:IsA("Model") and targetObject.PrimaryPart or targetObject
        if part and part:IsA("BasePart") then
            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)

            if onScreen then
                local distance = (Camera.CFrame.Position - part.Position).Magnitude
                local scale = math.clamp(1000 / distance, 10, 100)

                box.Size = Vector2.new(scale, scale)
                box.Position = Vector2.new(screenPos.X - scale / 2, screenPos.Y - scale / 2)
                box.Visible = true

                text.Position = Vector2.new(screenPos.X, screenPos.Y - scale / 2 - 16)
                text.Visible = true
            else
                box.Visible = false
                text.Visible = false
            end
        else
            box.Visible = false
            text.Visible = false
        end
    end)

    table.insert(activeDrawings, {box = box, text = text, connection = connection})
end

-- Scan the workspace for existing items
local function scanWorkspace()
    cleanupDrawings()
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local name = obj.Name:lower()
        if name:find("scroll") or name:find("advantage") or name:find("shovel") or name:find("hammer") then
            if obj:IsA("BasePart") or (obj:IsA("Model") and obj.PrimaryPart) then
                trackItem(obj, obj.Name)
            end
        end
    end
    print("[Outlaster ESP] Workspace rescanned.")
end

-- Initial scan
scanWorkspace()

-- Listen for new items dropping/spawning in real-time
Workspace.DescendantAdded:Connect(function(obj)
    task.wait(0.2)
    local name = obj.Name:lower()
    if name:find("scroll") or name:find("advantage") or name:find("shovel") or name:find("hammer") then
        if obj:IsA("BasePart") or obj:IsA("Model") then
            trackItem(obj, obj.Name)
        end
    end
end)

-- Create a small clickable UI Button on screen for Rescanning
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "OutlasterESPControl"
screenGui.Parent = game.CoreGui
screenGui.IgnoreGuiInset = true

local rescanButton = Instance.new("TextButton")
rescanButton.Name = "RescanButton"
rescanButton.Parent = screenGui
rescanButton.BackgroundColor3 = Color3.fromRGB(40, 41, 52)
rescanButton.BorderSizePixel = 0
rescanButton.Position = UDim2.new(0, 15, 0, 15)
rescanButton.Size = UDim2.new(0, 110, 0, 35)
rescanButton.Font = Enum.Font.GothamBold
rescanButton.Text = "Rescan ESP [P]"
rescanButton.TextColor3 = Color3.fromRGB(255, 255, 255)
rescanButton.TextSize = 13

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 6)
uiCorner.Parent = rescanButton

-- Click button to rescan
rescanButton.MouseButton1Click:Connect(function()
    scanWorkspace()
end)

-- Press 'P' to rescan
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.P then
        scanWorkspace()
    end
end)

print("Outlaster 2D Drawing ESP + Rescan UI Loaded via Matcha.")
