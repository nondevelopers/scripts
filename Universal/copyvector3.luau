local COPY_KEY = Enum.KeyCode.P
local DECIMALS = 2

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer

if getgenv().LIPCopyPos_Conn then
    pcall(function() getgenv().LIPCopyPos_Conn:Disconnect() end)
end

local function Notify(text)
    print("[Copy Position] " .. text)
    pcall(function()
        StarterGui:SetCore("SendNotification", { Title = "Copy Position", Text = text, Duration = 4 })
    end)
end

local function Round(n)
    local m = 10 ^ DECIMALS
    return math.floor(n * m + 0.5) / m
end

local function CopyPosition()
    local char = LocalPlayer.Character
    local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart"))
    if not root then
        Notify("No character found")
        return
    end

    local p = root.Position
    local text = string.format("Vector3.new(%s, %s, %s)", Round(p.X), Round(p.Y), Round(p.Z))

    local copy = setclipboard or toclipboard or (syn and syn.write_clipboard)
    if copy then
        copy(text)
        Notify("Copied: " .. text)
    else
        Notify("Executor has no clipboard function. Printed instead: " .. text)
    end
end

-- Copy once on execute
CopyPosition()

-- Copy again on key press
getgenv().LIPCopyPos_Conn = UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == COPY_KEY then
        CopyPosition()
    end
end)
