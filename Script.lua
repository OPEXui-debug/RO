-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Configuration
local ASSIST_SETTINGS = {
    Enabled = true,
    FovRadius = 150,        -- Radius of the visual FOV circle in pixels
    Smoothness = 0.15,      -- Camera interpolation speed (lower = smoother)
    TargetTagName = "Target" -- The name or tag of parts eligible for alignment
}

-- Players & Camera references
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Create the Visual FOV Circle using ScreenGui and a Frame
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AssistVisualization"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local FovCircle = Instance.new("Frame")
FovCircle.Size = UDim2.new(0, ASSIST_SETTINGS.FovRadius * 2, 0, ASSIST_SETTINGS.FovRadius * 2)
FovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
FovCircle.BackgroundTransparency = 1
FovCircle.BorderSizePixel = 0
FovCircle.Parent = ScreenGui

-- Apply a UICorner to make the frame a perfect circle
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(1, 0)
UICorner.Parent = FovCircle

-- Apply a UIStroke to give the circle an outline
local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(255, 255, 255)
UIStroke.Thickness = 1
UIStroke.Transparency = 0.5
UIStroke.Parent = FovCircle

-- Helper Function: Find the closest target within the FOV radius
local function getClosestTargetInFOV()
    local mousePosition = UserInputService:GetMouseLocation()
    local closestTarget = nil
    local shortestDistance = ASSIST_SETTINGS.FovRadius

    -- Find parts in workspace marked as targets
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name == ASSIST_SETTINGS.TargetTagName then
            local screenPos, onScreen = Camera:WorldToViewportPoint(obj.Position)
            
            if onScreen then
                local targetScreenPos = Vector2.new(screenPos.X, screenPos.Y)
                local distance = (targetScreenPos - mousePosition).Magnitude
                
                -- Verify the target falls within the configured FOV limit
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestTarget = obj
                end
            end
        end
    end
    return closestTarget
end

-- Core Logic Loop (Runs every frame prior to physics rendering)
RunService.RenderStepped:Connect(function()
    -- Dynamically update the FOV circle position and size to match settings
    FovCircle.Size = UDim2.new(0, ASSIST_SETTINGS.FovRadius * 2, 0, ASSIST_SETTINGS.FovRadius * 2)
    
    -- Check if the player is actively holding down the tracking button (Right Mouse Button)
    local isHoldingAim = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    
    if ASSIST_SETTINGS.Enabled and isHoldingAim then
        local targetPart = getClosestTargetInFOV()
        
        if targetPart then
            -- Calculate target rotation matrix looking from the camera to the target part
            local targetCFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
            
            -- Smoothly transition (interpolate) the camera orientation toward the target
            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, ASSIST_SETTINGS.Smoothness)
        end
    end
end)
