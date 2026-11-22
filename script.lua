-- ESP DEBUG: ipinapakita kung ano ang nakikita ng script sa laro mo
-- I-run ito sa laro, tapos ipadala sa akin ang lumabas sa console (F9) o ang laman ng clipboard.

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local out = {}

local function log(...)
    local t = {}
    for i = 1, select("#", ...) do t[i] = tostring((select(i, ...))) end
    local line = table.concat(t, " ")
    table.insert(out, line)
    print("[DEBUG] " .. line)
end

log("=== ESP DEBUG ===")
log("Game:", game.PlaceId, "| Executor:", (identifyexecutor and select(1, identifyexecutor())) or "unknown")
log("Drawing API:", tostring(Drawing ~= nil and Drawing.new ~= nil))
log("getgenv:", tostring(getgenv ~= nil), "| setclipboard:", tostring(setclipboard ~= nil), "| writefile:", tostring(writefile ~= nil))
log("StreamingEnabled:", tostring(workspace.StreamingEnabled))
log("Camera:", tostring(workspace.CurrentCamera), "| FOV:", workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView)
log("My character:", tostring(LP.Character))
log("Players in server:", #Players:GetPlayers())

-- test: gumagana ba ang Drawing Line?
if Drawing and Drawing.new then
    local ok, err = pcall(function()
        local l = Drawing.new("Line")
        l.From = Vector2.new(100, 100)
        l.To = Vector2.new(300, 300)
        l.Color = Color3.new(1, 0, 0)
        l.Thickness = 3
        l.Visible = true
        task.delay(5, function() pcall(function() l:Remove() end) end)
    end)
    log("Drawing Line test:", ok and "OK (dapat may pulang guhit sa screen, 5 segundo)" or ("ERROR: " .. tostring(err)))
end

-- hanapin lahat ng posibleng character / NPC / bot
local found = {}
for _, d in ipairs(workspace:GetDescendants()) do
    if d:IsA("Humanoid") or (d.Name == "HumanoidRootPart" and d:IsA("BasePart")) then
        local m = d.Parent
        if m and m:IsA("Model") and not found[m] then
            found[m] = true
        end
    end
end

local n = 0
for m in pairs(found) do n += 1 end
log("Nahanap na Models (Humanoid/HumanoidRootPart):", n)

local shown = 0
for m in pairs(found) do
    if shown >= 25 then log("... (25 lang ang ipinapakita)") break end
    shown += 1
    local hum = m:FindFirstChildOfClass("Humanoid")
    local plr = Players:GetPlayerFromCharacter(m)
    local parts = {}
    for _, c in ipairs(m:GetChildren()) do
        if c:IsA("BasePart") then table.insert(parts, c.Name) end
    end
    local rig = m:FindFirstChild("UpperTorso") and "R15" or (m:FindFirstChild("Torso") and "R6" or "CUSTOM/UNKNOWN")
    log(string.format("#%d %s | path=%s | player=%s | rig=%s | hum=%s | health=%s",
        shown, m.Name, m:GetFullName(), plr and plr.Name or "NPC",
        rig, tostring(hum ~= nil), hum and math.floor(hum.Health) or "-"))
    log("    parts:", table.concat(parts, ", "))
end

-- mga players na walang character na nakikita
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LP then
        log("Player", p.Name, "| Character:", tostring(p.Character ~= nil), "| nasa workspace:", tostring(p.Character ~= nil and p.Character:IsDescendantOf(workspace)))
    end
end

log("=== TAPOS ===")
local text = table.concat(out, "\n")
if setclipboard then pcall(setclipboard, text) print("[DEBUG] Nakopya na sa clipboard. I-paste mo sa chat.") end
if writefile then pcall(writefile, "espdebug.txt", text) print("[DEBUG] Naka-save sa workspace folder ng executor: espdebug.txt") end
