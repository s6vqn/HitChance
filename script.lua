-- Stickman (skeleton) ESP - Roblox executor (kailangan ng Drawing API)
-- K = ON/OFF. Gumagana sa R15 at R6.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local LP = Players.LocalPlayer

if not Drawing or not Drawing.new then
    warn("[ESP] Walang Drawing API ang executor mo. Hindi gagana ang ESP.")
    return
end

local S = {
    Enabled = true,
    ToggleKey = Enum.KeyCode.K,
    Color = Color3.fromRGB(255, 255, 255),
    Thickness = 1.5,
    MaxDistance = 5000,   -- studs
    TeamCheck = false,
    HeadCircle = true,
    ShowNPCs = true,      -- true = pati NPC (kahit anong Model na may Humanoid)
}

-- linisin kung na-run na dati
if getgenv and getgenv().__StickmanCleanup then pcall(getgenv().__StickmanCleanup) end

local R15 = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
}
local R6 = {
    {"Head", "Torso"},
    {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
    {"Torso", "Left Leg"}, {"Torso", "Right Leg"},
}
local MAXLINES = #R15

local objects = {} -- [player] = {lines = {...}, head = Circle}

local function newObjects()
    local o = {lines = {}}
    for i = 1, MAXLINES do
        local l = Drawing.new("Line")
        l.Visible = false
        l.Thickness = S.Thickness
        l.Color = S.Color
        o.lines[i] = l
    end
    local c = Drawing.new("Circle")
    c.Visible = false
    c.Filled = false
    c.NumSides = 20
    c.Thickness = S.Thickness
    c.Color = S.Color
    o.head = c
    return o
end

local function hide(o)
    for _, l in ipairs(o.lines) do l.Visible = false end
    o.head.Visible = false
end

local function destroy(plr)
    local o = objects[plr]
    if not o then return end
    for _, l in ipairs(o.lines) do pcall(function() l:Remove() end) end
    pcall(function() o.head:Remove() end)
    objects[plr] = nil
end

local function project(cam, part)
    local v, on = cam:WorldToViewportPoint(part.Position)
    if not on or v.Z <= 0 then return nil end
    return Vector2.new(v.X, v.Y), v.Z
end

local function update(char, cam)
    local o = objects[char]
    if not o then o = newObjects() objects[char] = o end

    local plr = Players:GetPlayerFromCharacter(char)
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
        or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Head")
    if not root or (hum and hum.Health <= 0)
        or (S.TeamCheck and plr and plr.Team ~= nil and plr.Team == LP.Team)
        or (not S.ShowNPCs and not plr)
        or (root.Position - cam.CFrame.Position).Magnitude > S.MaxDistance then
        hide(o)
        return
    end

    local bones = char:FindFirstChild("UpperTorso") and R15 or R6
    local used = 0
    for _, pair in ipairs(bones) do
        local a, b = char:FindFirstChild(pair[1]), char:FindFirstChild(pair[2])
        used += 1
        local line = o.lines[used]
        if a and b then
            local pa, pb = project(cam, a), project(cam, b)
            if pa and pb then
                line.From, line.To = pa, pb
                line.Color, line.Thickness = S.Color, S.Thickness
                line.Visible = true
            else
                line.Visible = false
            end
        else
            line.Visible = false
        end
    end
    for i = used + 1, MAXLINES do o.lines[i].Visible = false end

    local head = char:FindFirstChild("Head")
    if S.HeadCircle and head then
        local p, depth = project(cam, head)
        if p then
            local fovScale = cam.ViewportSize.Y / (2 * math.tan(math.rad(cam.FieldOfView) / 2))
            o.head.Position = p
            o.head.Radius = math.max(2, (head.Size.Y / 2) * fovScale / depth)
            o.head.Color, o.head.Thickness = S.Color, S.Thickness
            o.head.Visible = true
        else
            o.head.Visible = false
        end
    else
        o.head.Visible = false
    end
end

-- hanapin ang LAHAT ng Model na may Humanoid (player man o NPC)
local tracked = {}
local function tryAdd(inst)
    -- Humanoid, o HumanoidRootPart (para sa bots na walang Humanoid)
    if inst:IsA("Humanoid") or (inst.Name == "HumanoidRootPart" and inst:IsA("BasePart")) then
        local m = inst.Parent
        if m and m:IsA("Model") then tracked[m] = true end
    end
end
for _, d in ipairs(workspace:GetDescendants()) do tryAdd(d) end
local c0 = workspace.DescendantAdded:Connect(tryAdd)

local function step()
    local cam = workspace.CurrentCamera
    if not cam then return end
    if not S.Enabled then
        for _, o in pairs(objects) do hide(o) end
        return
    end
    for char in pairs(tracked) do
        if not char.Parent or not char:IsDescendantOf(workspace) then
            tracked[char] = nil
            destroy(char)
        elseif char ~= LP.Character then
            local ok = pcall(update, char, cam)
            if not ok and objects[char] then hide(objects[char]) end
        end
    end
end

RunService:BindToRenderStep("StickmanESP", Enum.RenderPriority.Camera.Value + 2, step)

local c1 = c0
local c2 = UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == S.ToggleKey then
        S.Enabled = not S.Enabled
        print("[ESP] Enabled:", S.Enabled)
    end
end)

if getgenv then
    getgenv().__StickmanCleanup = function()
        pcall(function() RunService:UnbindFromRenderStep("StickmanESP") end)
        c1:Disconnect()
        c2:Disconnect()
        for plr in pairs(objects) do destroy(plr) end
    end
end

print("[ESP] Loaded. K = ON/OFF")
