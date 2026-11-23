-- CAMLOCK + CHAMS ESP (combined) - Roblox executor
-- Camlock: hawakan ang HoldKey (default right click) para mag-lock. T = ON/OFF (nagsisimula OFF).
-- ESP: K = ON/OFF (sa PC). Sa mobile, naka-ON agad. Para i-off: getgenv().ChamsOff = true

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local LP = Players.LocalPlayer

----------------------------------------------------------------
-- SETTINGS
----------------------------------------------------------------
local C = {  -- Camlock
    Enabled = false,
    HoldKey = Enum.UserInputType.MouseButton2,
    ToggleKey = Enum.KeyCode.T,
    Smoothing = 2,        -- 1 = snap, mas mataas = mas smooth/mabagal (subukan 2-15)
    FOV = 40,             -- radius sa pixels mula sa crosshair (maliit = yung nasa crosshair lang)
    MaxDistance = 500,    -- studs
    WallCheck = true,
    Part = "Head",        -- "Head" o "Torso"
}

local E = {  -- ESP
    Enabled = true,
    ToggleKey = Enum.KeyCode.K,
    Fill = Color3.fromRGB(255, 0, 0),
    Outline = Color3.fromRGB(255, 255, 255),
    FillTransparency = 0.5,
    VisibleColor = Color3.fromRGB(0, 255, 0),   -- GREEN = walang pader, tanaw mo
    HiddenColor = Color3.fromRGB(255, 0, 0),    -- RED = nasa likod ng pader
    MaxDistance = 5000,
    ShowNPCs = true,
    TeamCheck = false,
    Labels = false,         -- false = walang text, kulay lang sa katawan
    HideGameNames = true,   -- itatago ang pangalan/health bar na galing mismo sa laro
}

----------------------------------------------------------------
-- CLEANUP NG NAKARAANG RUN
----------------------------------------------------------------
if getgenv then
    for _, k in ipairs({"__CamlockEspCleanup", "__CamlockCleanup", "__ChamsCleanup"}) do
        if getgenv()[k] then pcall(getgenv()[k]) end
    end
end

pcall(function() RunService:UnbindFromRenderStep("CamlockStep") end)
pcall(function() RunService:UnbindFromRenderStep("ChamsStep") end)

local parents = {game:GetService("CoreGui")}
if LP:FindFirstChild("PlayerGui") then table.insert(parents, LP.PlayerGui) end
if gethui then
    local okH, h = pcall(gethui)
    if okH and h then table.insert(parents, h) end
end
for _, parent in ipairs(parents) do
    for _, c in ipairs(parent:GetChildren()) do
        if c.Name == "ChamsHolder" or c.Name == "CamlockBtn" then pcall(function() c:Destroy() end) end
    end
end

----------------------------------------------------------------
-- CAMLOCK
----------------------------------------------------------------
local touchLock = false  -- para sa mobile (button sa screen)

local function isDown(key)
    if touchLock then return true end
    if key.EnumType == Enum.UserInputType then
        return UIS:IsMouseButtonPressed(key)
    end
    return UIS:IsKeyDown(key)
end

local function getPart(char)
    if C.Part == "Head" then
        return char:FindFirstChild("Head")
    end
    return char:FindFirstChild("UpperTorso")
        or char:FindFirstChild("Torso")
        or char:FindFirstChild("HumanoidRootPart")
end

local function isDead(char, hum)
    if hum.Health <= 0 or hum:GetState() == Enum.HumanoidStateType.Dead then
        return true
    end
    local ok, ko = pcall(function()
        local be = char:FindFirstChild("BodyEffects")
        local v = be and be:FindFirstChild("K.O")
        return v and v.Value
    end)
    return ok and ko == true
end

local function visible(cam, part, char, force)
    if not C.WallCheck and not force then return true end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local ignore = {char}
    if LP.Character then table.insert(ignore, LP.Character) end
    params.FilterDescendantsInstances = ignore
    local origin = cam.CFrame.Position
    local dir = part.Position - origin
    for _ = 1, 8 do
        local hit = workspace:Raycast(origin, dir, params)
        if not hit then return true end
        local inst = hit.Instance
        if inst.Transparency >= 0.9 or not inst.CanCollide then
            table.insert(ignore, inst)
            params.FilterDescendantsInstances = ignore
        else
            return false
        end
    end
    return false
end

-- pinakamalapit sa gitna ng screen (sa loob ng FOV)
local function findTarget(cam)
    local center = cam.ViewportSize / 2
    local best, bestD = nil, C.FOV
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local char = plr.Character
            local hum = char:FindFirstChildOfClass("Humanoid")
            local part = getPart(char)
            if hum and part and not isDead(char, hum) then
                local pos, onScreen = cam:WorldToViewportPoint(part.Position)
                local dist3 = (part.Position - cam.CFrame.Position).Magnitude
                if onScreen and dist3 <= C.MaxDistance then
                    local d = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if d < bestD and visible(cam, part, char) then
                        best, bestD = plr, d
                    end
                end
            end
        end
    end
    return best
end

local locked = nil
local tried = false  -- isang subok lang bawat hold

local function camStep(dt)
    local cam = workspace.CurrentCamera
    if not cam or not C.Enabled or not isDown(C.HoldKey) then
        locked = nil
        tried = false
        return
    end

    -- one-target: kapag nakalock na, ito lang hanggang bitawan ang key o mamatay/mawala
    if locked then
        local char = locked.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local part = char and getPart(char)
        if not (hum and part) or isDead(char, hum) then
            locked = nil
        end
    end
    -- yung pinakamalapit sa crosshair (loob ng FOV). Lilipat lang kapag may ibang mas malapit sa crosshair
    -- kaysa sa kasalukuyang naka-lock, ibig sabihin hinila mo ang mouse papunta sa iba.
    local cand = findTarget(cam)
    if cand and cand ~= locked then
        locked = cand
    end
    if not locked then return end

    local part = getPart(locked.Character)
    if not part then locked = nil return end

    -- smoothing: frame-rate independent
    local s = math.max(1, C.Smoothing)
    local alpha = 1 - (1 - 1 / s) ^ (math.clamp(dt, 0, 0.1) * 60)
    local goal = CFrame.new(cam.CFrame.Position, part.Position)
    cam.CFrame = cam.CFrame:Lerp(goal, alpha)
end

-- MOBILE: button sa screen (i-tap para ON/OFF ng lock)
local btnGui
if UIS.TouchEnabled then
    btnGui = Instance.new("ScreenGui")
    btnGui.Name = "CamlockBtn"
    btnGui.ResetOnSpawn = false
    local okP = pcall(function() btnGui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
    if not okP then btnGui.Parent = LP:WaitForChild("PlayerGui") end
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 80, 0, 80)
    b.Position = UDim2.new(1, -110, 0.5, -40)
    b.BackgroundColor3 = Color3.new(0, 0, 0)
    b.BackgroundTransparency = 0.3
    b.BorderColor3 = Color3.fromRGB(0, 200, 120)
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.SourceSansBold
    b.TextSize = 18
    b.Text = "LOCK\nOFF"
    b.Active = true
    b.Draggable = true
    b.Parent = btnGui
    b.MouseButton1Click:Connect(function()
        C.Enabled = true
        touchLock = not touchLock
        locked = nil
        b.Text = touchLock and "LOCK\nON" or "LOCK\nOFF"
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Camlock", Text = touchLock and "ON" or "OFF", Duration = 2})
        end)
    end)
end

RunService:BindToRenderStep("CamlockStep", Enum.RenderPriority.Camera.Value + 1, camStep)

----------------------------------------------------------------
-- CHAMS ESP
----------------------------------------------------------------
local holder = Instance.new("Folder")
holder.Name = "ChamsHolder"
local okH2 = pcall(function() holder.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not okH2 then holder.Parent = LP:WaitForChild("PlayerGui") end

local tracked = {}   -- [model] = {hl, bb, label}
local models = {}

local function tryAdd(inst)
    if inst:IsA("Humanoid") or (inst.Name == "HumanoidRootPart" and inst:IsA("BasePart")) then
        local m = inst.Parent
        if m and m:IsA("Model") then models[m] = true end
    end
end
for _, d in ipairs(workspace:GetDescendants()) do tryAdd(d) end
local cAdded = workspace.DescendantAdded:Connect(tryAdd)

local function create(model)
    local hl = Instance.new("Highlight")
    hl.Adornee = model
    hl.FillColor = E.Fill
    hl.OutlineColor = E.Outline
    hl.FillTransparency = E.FillTransparency
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

-- WALLCHECK para sa ESP: may pader = RED, open area = GREEN
-- Ang ibang players/NPC ay hindi binibilang na pader. Ang mga transparent lang ang nilalampasan.
local function espVisible(cam, target)
    local ignore = {}
    if LP.Character then table.insert(ignore, LP.Character) end
    for m in pairs(models) do
        if m.Parent then table.insert(ignore, m) end
    end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local origin = cam.CFrame.Position
    local dir = target.Position - origin
    for _ = 1, 25 do
        params.FilterDescendantsInstances = ignore
        local hit = workspace:Raycast(origin, dir, params)
        if not hit then return true end          -- walang humarang = open area
        local p = hit.Instance
        -- pader kung nakikita (hindi halos transparent) at solid o malaki
        local isWall = p.Transparency < 0.95 and (p.CanCollide or p.Size.Magnitude > 6)
        if isWall then return false end          -- may pader
        table.insert(ignore, p)                  -- dekorasyon/salamin lang, lampasan
    end
    return false
end

local function espStep()
    local cam = workspace.CurrentCamera
    if not cam then return end
    local on = E.Enabled and not (getgenv and getgenv().ChamsOff)

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
            if E.HideGameNames and hum and hum.DisplayDistanceType ~= Enum.HumanoidDisplayDistanceType.None then
                pcall(function() hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end)
            end

            local hide = (not on) or (not root)
                or (hum and hum.Health <= 0)
                or (not E.ShowNPCs and not plr)
                or (E.TeamCheck and plr and plr.Team ~= nil and plr.Team == LP.Team)
            local dist = root and (root.Position - cam.CFrame.Position).Magnitude or math.huge
            if dist > E.MaxDistance then hide = true end

            if hide then
                hideObj(o)
            else
                o.hl.Enabled = true
                -- GREEN kung walang pader sa pagitan ng camera at ulo, RED kung may pader
                local now = tick()
                if not o.t or now - o.t > 0.08 then
                    o.t = now
                    local target = model:FindFirstChild("Head") or root
                    o.vis = espVisible(cam, target)
                end
                local col = o.vis and E.VisibleColor or E.HiddenColor
                o.hl.FillColor = col
                o.hl.OutlineColor = col
                o.bb.Adornee = model:FindFirstChild("Head") or root
                o.bb.Enabled = E.Labels
                local hp = hum and (math.floor(hum.Health) .. "hp | ") or ""
                o.label.Text = hp .. math.floor(dist) .. "s"
            end
        end
    end
end

RunService:BindToRenderStep("ChamsStep", Enum.RenderPriority.Camera.Value + 2, function() pcall(espStep) end)

----------------------------------------------------------------
-- INPUT (T = camlock, K = ESP)
----------------------------------------------------------------
local function notify(title, text)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {Title = title, Text = text, Duration = 2})
    end)
end

local inputConn = UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == C.ToggleKey then
        C.Enabled = not C.Enabled
        locked = nil
        print("[Camlock] Enabled:", C.Enabled)
        notify("Camlock", C.Enabled and "ON" or "OFF")
    elseif input.KeyCode == E.ToggleKey then
        E.Enabled = not E.Enabled
        print("[Chams] Enabled:", E.Enabled)
        notify("ESP", E.Enabled and "ON" or "OFF")
    end
end)

if getgenv then
    getgenv().__CamlockEspCleanup = function()
        pcall(function() RunService:UnbindFromRenderStep("CamlockStep") end)
        pcall(function() RunService:UnbindFromRenderStep("ChamsStep") end)
        inputConn:Disconnect()
        cAdded:Disconnect()
        if btnGui then btnGui:Destroy() end
        holder:Destroy()
    end
end

print("[Camlock+ESP] Loaded. T = camlock ON/OFF (hold right click), K = ESP ON/OFF.")
pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Camlock + ESP", Text = "Loaded", Duration = 4})
end)
