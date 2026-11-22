-- CHARACTER DEBUGGER - Roblox executor
-- F4 = buksan/isara ang panel. Pili ka ng character sa kaliwa (player, NPC, bot),
-- lalabas sa kanan ang LAHAT ng detalye: Humanoid, lahat ng parts/joints/accessories/values/attributes.
-- Copy = kopyahin sa clipboard | Save = i-save sa espdebug_char.txt | Refresh = i-update ang listahan

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local LP = Players.LocalPlayer

if getgenv and getgenv().__CharDebugCleanup then pcall(getgenv().__CharDebugCleanup) end

local OPEN_KEY = Enum.KeyCode.F4
local MAX_LINES = 900

-- ================= DUMP =================
local function f(n) return string.format("%.2f", n) end

local function describe(inst, depth, lines)
    if #lines >= MAX_LINES then return end
    local pad = string.rep("  ", depth)
    local s = pad .. "[" .. inst.ClassName .. "] " .. inst.Name
    if inst:IsA("BasePart") then
        s ..= string.format(" size=(%s,%s,%s) pos=(%.1f,%.1f,%.1f) transp=%s collide=%s anchored=%s mat=%s",
            f(inst.Size.X), f(inst.Size.Y), f(inst.Size.Z),
            inst.Position.X, inst.Position.Y, inst.Position.Z,
            f(inst.Transparency), tostring(inst.CanCollide), tostring(inst.Anchored), inst.Material.Name)
    elseif inst:IsA("ValueBase") then
        s ..= " value=" .. tostring(inst.Value)
    elseif inst:IsA("JointInstance") then
        s ..= " P0=" .. (inst.Part0 and inst.Part0.Name or "nil") .. " P1=" .. (inst.Part1 and inst.Part1.Name or "nil")
    elseif inst:IsA("Humanoid") then
        s ..= " health=" .. f(inst.Health) .. "/" .. f(inst.MaxHealth)
    end
    table.insert(lines, s)
    local okA, attrs = pcall(function() return inst:GetAttributes() end)
    if okA then
        for k, v in pairs(attrs) do
            table.insert(lines, pad .. "  @" .. tostring(k) .. " = " .. tostring(v))
        end
    end
    for _, c in ipairs(inst:GetChildren()) do
        describe(c, depth + 1, lines)
    end
end

local function dump(model)
    local lines = {}
    local plr = Players:GetPlayerFromCharacter(model)
    local cam = workspace.CurrentCamera
    local hum = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
    table.insert(lines, "=== " .. model.Name .. " ===")
    table.insert(lines, "Path: " .. model:GetFullName())
    table.insert(lines, "Type: " .. (plr and ("PLAYER (" .. plr.Name .. ", id " .. plr.UserId .. ")") or "NPC / BOT"))
    if plr then
        table.insert(lines, "Team: " .. tostring(plr.Team) .. " | DisplayName: " .. plr.DisplayName)
    end
    local rig = model:FindFirstChild("UpperTorso") and "R15" or (model:FindFirstChild("Torso") and "R6" or "CUSTOM/UNKNOWN")
    table.insert(lines, "Rig (nakita sa parts): " .. rig)
    table.insert(lines, "PrimaryPart: " .. tostring(model.PrimaryPart) .. " | Root: " .. tostring(root))
    if root and cam then
        table.insert(lines, "Distance: " .. f((root.Position - cam.CFrame.Position).Magnitude) .. " studs")
        local v, on = cam:WorldToViewportPoint(root.Position)
        table.insert(lines, string.format("Screen: (%.0f, %.0f) depth=%.1f onScreen=%s", v.X, v.Y, v.Z, tostring(on)))
        table.insert(lines, "Velocity: " .. tostring(root.AssemblyLinearVelocity))
    end
    if hum then
        table.insert(lines, "--- HUMANOID ---")
        for _, prop in ipairs({"Health", "MaxHealth", "RigType", "WalkSpeed", "JumpPower", "JumpHeight",
            "HipHeight", "DisplayName", "PlatformStand", "Sit", "FloorMaterial", "UseJumpPower"}) do
            local ok, val = pcall(function() return hum[prop] end)
            if ok then table.insert(lines, "  " .. prop .. " = " .. tostring(val)) end
        end
        local okS, st = pcall(function() return hum:GetState() end)
        if okS then table.insert(lines, "  State = " .. tostring(st)) end
    else
        table.insert(lines, "--- WALANG HUMANOID (custom bot) ---")
    end
    table.insert(lines, "--- BUONG PUNO ---")
    describe(model, 0, lines)
    if #lines >= MAX_LINES then table.insert(lines, "... (pinutol sa " .. MAX_LINES .. " linya)") end
    return table.concat(lines, "\n")
end

-- ================= HANAPIN ANG MGA CHARACTER =================
local function findModels()
    local set, list = {}, {}
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("Humanoid") or (d.Name == "HumanoidRootPart" and d:IsA("BasePart")) then
            local m = d.Parent
            if m and m:IsA("Model") and not set[m] then
                set[m] = true
                table.insert(list, m)
            end
        end
    end
    local cam = workspace.CurrentCamera
    local function dist(m)
        local r = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
        return r and cam and (r.Position - cam.CFrame.Position).Magnitude or math.huge
    end
    table.sort(list, function(a, b) return dist(a) < dist(b) end)
    return list, dist
end

-- ================= GUI =================
local gui = Instance.new("ScreenGui")
gui.Name = "CharDebugger"
gui.ResetOnSpawn = false
gui.Enabled = true
local okParent = pcall(function() gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not okParent then gui.Parent = LP:WaitForChild("PlayerGui") end

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 780, 0, 450)
frame.Position = UDim2.new(0.5, -390, 0.5, -225)
frame.BackgroundColor3 = Color3.new(0, 0, 0)
frame.BorderColor3 = Color3.fromRGB(70, 70, 70)
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local function mk(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    o.Parent = parent
    return o
end

mk("TextLabel", {
    Size = UDim2.new(1, -40, 0, 28), Position = UDim2.new(0, 10, 0, 0),
    BackgroundTransparency = 1, Text = "Character Debugger  (F4 = show/hide)",
    TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.SourceSansBold, TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Left,
}, frame)

local closeBtn = mk("TextButton", {
    Size = UDim2.new(0, 28, 0, 24), Position = UDim2.new(1, -34, 0, 2),
    BackgroundColor3 = Color3.fromRGB(34, 34, 34), Text = "X",
    TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.SourceSansBold, TextSize = 16,
}, frame)

local list = mk("ScrollingFrame", {
    Size = UDim2.new(0, 240, 1, -78), Position = UDim2.new(0, 8, 0, 32),
    BackgroundColor3 = Color3.fromRGB(16, 16, 16), BorderSizePixel = 0,
    ScrollBarThickness = 6, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
}, frame)
mk("UIListLayout", {Padding = UDim.new(0, 2)}, list)

local detail = mk("ScrollingFrame", {
    Size = UDim2.new(1, -264, 1, -78), Position = UDim2.new(0, 256, 0, 32),
    BackgroundColor3 = Color3.fromRGB(16, 16, 16), BorderSizePixel = 0,
    ScrollBarThickness = 8, AutomaticCanvasSize = Enum.AutomaticSize.XY, CanvasSize = UDim2.new(),
}, frame)
local detailText = mk("TextLabel", {
    Size = UDim2.new(0, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.XY,
    BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(220, 220, 220),
    Font = Enum.Font.Code, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top, Text = "Pumili ng character sa kaliwa.",
}, detail)

local function button(text, x)
    return mk("TextButton", {
        Size = UDim2.new(0, 110, 0, 30), Position = UDim2.new(0, x, 1, -38),
        BackgroundColor3 = Color3.fromRGB(34, 34, 34), BorderColor3 = Color3.fromRGB(70, 70, 70),
        Text = text, TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.SourceSansBold, TextSize = 15,
    }, frame)
end
local refreshBtn = button("Refresh", 8)
local copyBtn = button("Copy", 126)
local saveBtn = button("Save file", 244)
local status = mk("TextLabel", {
    Size = UDim2.new(1, -370, 0, 30), Position = UDim2.new(0, 362, 1, -38),
    BackgroundTransparency = 1, Text = "", TextColor3 = Color3.fromRGB(0, 200, 120),
    Font = Enum.Font.SourceSans, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
}, frame)

-- ================= LOGIC =================
local selected = nil
local lastText = ""

local function showSelected()
    if selected and selected.Parent then
        lastText = dump(selected)
        detailText.Text = lastText
    elseif selected then
        detailText.Text = "Wala na ang character na ito (namatay/nawala). Pindutin ang Refresh."
    end
end

local function refreshList()
    for _, c in ipairs(list:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    local models, dist = findModels()
    for _, m in ipairs(models) do
        local plr = Players:GetPlayerFromCharacter(m)
        local tag = (m == LP.Character) and "ME" or (plr and "P" or "NPC")
        local d = dist(m)
        local b = mk("TextButton", {
            Size = UDim2.new(1, -8, 0, 24), BackgroundColor3 = Color3.fromRGB(30, 30, 30),
            BorderSizePixel = 0, TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.SourceSans,
            TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
            Text = string.format(" [%s] %s  (%s)", tag, m.Name, d == math.huge and "?" or (math.floor(d) .. "s")),
        }, list)
        b.MouseButton1Click:Connect(function()
            selected = m
            showSelected()
        end)
    end
    status.Text = #models .. " character(s) ang nahanap"
end

refreshBtn.MouseButton1Click:Connect(refreshList)
closeBtn.MouseButton1Click:Connect(function() gui.Enabled = false end)
copyBtn.MouseButton1Click:Connect(function()
    if setclipboard and lastText ~= "" then
        setclipboard(lastText)
        status.Text = "Nakopya sa clipboard!"
    else
        status.Text = "Walang setclipboard o walang napili"
    end
end)
saveBtn.MouseButton1Click:Connect(function()
    if writefile and lastText ~= "" then
        writefile("espdebug_char.txt", lastText)
        status.Text = "Na-save: espdebug_char.txt"
    else
        status.Text = "Walang writefile o walang napili"
    end
end)

local conn = UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == OPEN_KEY then
        gui.Enabled = not gui.Enabled
        if gui.Enabled then refreshList() end
    end
end)

-- live update ng napiling character (health, posisyon, atbp.)
local running = true
task.spawn(function()
    while running do
        task.wait(1)
        if gui.Enabled and selected then pcall(showSelected) end
    end
end)

if getgenv then
    getgenv().__CharDebugCleanup = function()
        running = false
        conn:Disconnect()
        gui:Destroy()
    end
end

refreshList()
print("[CharDebug] Loaded. F4 = show/hide")
