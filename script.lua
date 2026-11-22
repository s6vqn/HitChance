-- CHAMS ESP (walang Drawing API na kailangan) - para sa mobile executors
-- Highlight (kulay sa katawan, nakikita sa pader) + pangalan/health/distansya sa ulo.
-- K = ON/OFF (sa PC). Sa mobile, naka-ON agad. Para i-off: i-set ang getgenv().ChamsOff = true

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local LP = Players.LocalPlayer

local S = {
    Enabled = true,
    ToggleKey = Enum.KeyCode.K,
    Fill = Color3.fromRGB(255, 0, 0),
    Outline = Color3.fromRGB(255, 255, 255),
    FillTransparency = 0.5,
    MaxDistance = 5000,
    ShowNPCs = true,
    TeamCheck = false,
    Labels = true,
    HideGameNames = true,   -- itatago ang pangalan/health bar na galing mismo sa laro
}

if getgenv and getgenv().__ChamsCleanup then pcall(getgenv().__ChamsCleanup) end

local holder = Instance.new("Folder")
holder.Name = "ChamsHolder"
local okP = pcall(function() holder.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not okP then holder.Parent = LP:WaitForChild("PlayerGui") end

local tracked = {}   -- [model] = {hl, bb, label}
local models = {}

local function tryAdd(inst)
    if inst:IsA("Humanoid") or (inst.Name == "HumanoidRootPart" and inst:IsA("BasePart")) then
        local m = inst.Parent
        if m and m:IsA("Model") then models[m] = true end
    end
end
for _, d in ipairs(workspace:GetDescendants()) do tryAdd(d) end
local c0 = workspace.DescendantAdded:Connect(tryAdd)

local function create(model)
    local hl = Instance.new("Highlight")
    hl.Adornee = model
    hl.FillColor = S.Fill
    hl.OutlineColor = S.Outline
    hl.FillTransparency = S.FillTransparency
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = holder

    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 160, 0, 30)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Parent = holder
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 14
    label.Parent = bb

    local o = {hl = hl, bb = bb, label = label}
    tracked[model] = o
    return o
end

local function remove(model)
    local o = tracked[model]
    if o then
        pcall(function() o.hl:Destroy() end)
        pcall(function() o.bb:Destroy() end)
        tracked[model] = nil
    end
end

local function hideObj(o)
    o.hl.Enabled = false
    o.bb.Enabled = false
end

local function step()
    local cam = workspace.CurrentCamera
    if not cam then return end
    local on = S.Enabled and not (getgenv and getgenv().ChamsOff)

    for model in pairs(models) do
        if not model.Parent or not model:IsDescendantOf(workspace) then
            models[model] = nil
            remove(model)
        elseif model ~= LP.Character then
            local o = tracked[model] or create(model)
            local plr = Players:GetPlayerFromCharacter(model)
            local hum = model:FindFirstChildOfClass("Humanoid")
            local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
                or model:FindFirstChild("Torso") or model:FindFirstChild("Head")

            -- itago ang sariling pangalan/health bar ng laro sa ibabaw ng ulo
            if S.HideGameNames and hum and hum.DisplayDistanceType ~= Enum.HumanoidDisplayDistanceType.None then
                pcall(function() hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end)
            end

            local hide = (not on) or (not root)
                or (hum and hum.Health <= 0)
                or (not S.ShowNPCs and not plr)
                or (S.TeamCheck and plr and plr.Team ~= nil and plr.Team == LP.Team)
            local dist = root and (root.Position - cam.CFrame.Position).Magnitude or math.huge
            if dist > S.MaxDistance then hide = true end

            if hide then
                hideObj(o)
            else
                o.hl.Enabled = true
                o.bb.Adornee = model:FindFirstChild("Head") or root
                o.bb.Enabled = S.Labels
                local hp = hum and (math.floor(hum.Health) .. "hp | ") or ""
                o.label.Text = hp .. math.floor(dist) .. "s"
            end
        end
    end
end

local conn = RunService.RenderStepped:Connect(function() pcall(step) end)
local c2 = UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == S.ToggleKey then
        S.Enabled = not S.Enabled
        print("[Chams] Enabled:", S.Enabled)
    end
end)

if getgenv then
    getgenv().__ChamsCleanup = function()
        conn:Disconnect()
        c0:Disconnect()
        c2:Disconnect()
        holder:Destroy()
    end
end

print("[Chams] Loaded.")
pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Chams ESP", Text = "Loaded", Duration = 4})
end)
