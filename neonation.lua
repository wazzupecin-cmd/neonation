-- ╔══════════════════════════════════════════════════════════════╗
-- ║       NEONATION WH  ·  ESP + Aimbot + Bank ESP + Unload       ║
-- ║       v2.3 — Bank ESP с таймером ограбления                   ║
-- ╚══════════════════════════════════════════════════════════════╝
-- K  — открыть/закрыть меню
-- ----------------------------------------------------------------

-- ═══════════════════════════════════════════════════════════════
--  SERVICES
-- ═══════════════════════════════════════════════════════════════
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local TeleportService  = game:GetService("TeleportService")
local Workspace        = game:GetService("Workspace")
local Camera           = Workspace.CurrentCamera

local LP = Players.LocalPlayer
local LG = LP:WaitForChild("PlayerGui")

-- Реестр всех "вечных" коннектов (для полного анлоада)
local LIVE = {}

-- ═══════════════════════════════════════════════════════════════
--  НАСТРОЙКИ
-- ═══════════════════════════════════════════════════════════════
local Settings = {
    aimbotPC        = false,
    aimbotPCFOV     = 150,
    aimbotPCSmooth  = 0.15,

    aimbotMobile       = false,
    aimbotMobileFOV    = 200,
    aimbotMobileSmooth = 0.10,

    espEnabled     = false,
    bankESP        = false,
    espRoles = {
        ["Civilian"]      = { enabled = true, color = Color3.fromRGB(80,  210,  80) },
        ["Border Patrol"] = { enabled = true, color = Color3.fromRGB(255, 210,  50) },
        ["Police"]        = { enabled = true, color = Color3.fromRGB(80,  160, 255) },
        ["FBI"]           = { enabled = true, color = Color3.fromRGB(30,  80,  200) },
        ["US Army"]       = { enabled = true, color = Color3.fromRGB(100, 150,  50) },
        ["SWAT"]          = { enabled = true, color = Color3.fromRGB(60,  60,  60) },
        ["BORTAC"]        = { enabled = true, color = Color3.fromRGB(90,  60,  30) },
    },
    espRoleSource  = "Team",

    aimPart       = "Head",
    aimPrediction = 0,

    aimbotTargetTeams = {
        ["Civilian"]      = true,
        ["Border Patrol"] = true,
        ["Police"]        = true,
        ["FBI"]           = true,
        ["US Army"]       = true,
        ["SWAT"]          = true,
        ["BORTAC"]        = true,
    },
}

-- ═══════════════════════════════════════════════════════════════
--  ЦВЕТА (неоновая палитра)
-- ═══════════════════════════════════════════════════════════════
local C = {
    panel     = Color3.fromRGB(13, 13, 26),
    sidebar   = Color3.fromRGB(10, 10, 20),
    accent    = Color3.fromRGB(0,  212, 255),
    accent2   = Color3.fromRGB(255, 0, 127),
    text      = Color3.fromRGB(255, 255, 255),
    subtext   = Color3.fromRGB(160, 160, 200),
    divider   = Color3.fromRGB(40, 40, 60),
    row_idle  = Color3.fromRGB(20, 20, 36),
    danger    = Color3.fromRGB(255, 65, 85),
    on_col    = Color3.fromRGB(0,  212, 255),
    off_col   = Color3.fromRGB(70,  70, 90),
    fov_col   = Color3.fromRGB(255, 60, 60),
    fov_mob   = Color3.fromRGB(255, 160, 40),
    bank_col  = Color3.fromRGB(255, 200, 60),
}

-- ═══════════════════════════════════════════════════════════════
--  REJOIN
-- ═══════════════════════════════════════════════════════════════
local function rejoin()
    TeleportService:Teleport(game.PlaceId, LP)
end

-- ═══════════════════════════════════════════════════════════════
--  ESP (с расстоянием)
-- ═══════════════════════════════════════════════════════════════
local ESPObjects = {}

local function getPlayerRole(player)
    if Settings.espRoleSource == "Team" then
        if player.Team then return player.Team.Name end
    elseif Settings.espRoleSource == "Value" then
        local v = player:FindFirstChild("Role") or
                  (player.Character and player.Character:FindFirstChild("Role"))
        if v then return v.Value end
    elseif Settings.espRoleSource == "Tag" then
        local CS = game:GetService("CollectionService")
        for rn in pairs(Settings.espRoles) do
            if CS:HasTag(player.Character or player, rn) then return rn end
        end
    end
    return nil
end

local function getRoleColor(rn)
    local cfg = Settings.espRoles[rn]
    if cfg and cfg.enabled then return cfg.color end
    return nil
end

local function createESP(player)
    if player == LP then return end
    if ESPObjects[player] then return end

    local bb = Instance.new("BillboardGui")
    bb.Name        = "ESPBillboard"
    bb.AlwaysOnTop = true
    bb.Size        = UDim2.new(0, 130, 0, 60)
    bb.StudsOffset = Vector3.new(0, 3.4, 0)

    local nameLbl = Instance.new("TextLabel", bb)
    nameLbl.Size                 = UDim2.new(1,0,0.4,0)
    nameLbl.Position             = UDim2.new(0,0,0,0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text                 = player.Name
    nameLbl.Font                 = Enum.Font.GothamBold
    nameLbl.TextSize             = 13
    nameLbl.TextStrokeTransparency = 0.35
    nameLbl.TextColor3           = C.text

    local roleLbl = Instance.new("TextLabel", bb)
    roleLbl.Size                 = UDim2.new(1,0,0.3,0)
    roleLbl.Position             = UDim2.new(0,0,0.4,0)
    roleLbl.BackgroundTransparency = 1
    roleLbl.Text                 = ""
    roleLbl.Font                 = Enum.Font.Gotham
    roleLbl.TextSize             = 11
    roleLbl.TextStrokeTransparency = 0.5
    roleLbl.TextColor3           = C.subtext

    local distLbl = Instance.new("TextLabel", bb)
    distLbl.Size                 = UDim2.new(1,0,0.3,0)
    distLbl.Position             = UDim2.new(0,0,0.7,0)
    distLbl.BackgroundTransparency = 1
    distLbl.Text                 = ""
    distLbl.Font                 = Enum.Font.Gotham
    distLbl.TextSize             = 10
    distLbl.TextColor3           = C.text
    distLbl.TextStrokeTransparency = 0.5

    local box = Instance.new("SelectionBox")
    box.LineThickness        = 0.05
    box.SurfaceTransparency  = 0.82

    ESPObjects[player] = { bb = bb, nameLbl = nameLbl, roleLbl = roleLbl, distLbl = distLbl, box = box }

    local function attach(char)
        local root = char:WaitForChild("HumanoidRootPart", 6)
        if not root then return end
        local role  = getPlayerRole(player)
        local color = role and getRoleColor(role)
        if color then
            nameLbl.TextColor3 = color
            roleLbl.Text       = "[" .. role .. "]"
            roleLbl.TextColor3 = color
            box.Color3         = color
            box.SurfaceColor3  = color
            box.Adornee        = char
            box.Parent         = Workspace
            bb.Parent          = root
        else
            bb.Parent  = nil
            box.Parent = nil
        end
    end

    if player.Character then attach(player.Character) end
    player.CharacterAdded:Connect(attach)
end

local function removeESP(player)
    local e = ESPObjects[player]
    if not e then return end
    pcall(function() e.bb:Destroy() end)
    pcall(function() e.box:Destroy() end)
    ESPObjects[player] = nil
end

local function updateESPDistances()
    local camPos = Camera.CFrame.Position
    for player, data in pairs(ESPObjects) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local rootPos = player.Character.HumanoidRootPart.Position
            local dist = (rootPos - camPos).Magnitude
            if data.distLbl then
                data.distLbl.Text = string.format("%.1f м", dist)
            end
        else
            if data.distLbl then
                data.distLbl.Text = ""
            end
        end
    end
end

local espConn, espLeaveConn, espUpdateConn

local function enableESP()
    for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
    espConn = Players.PlayerAdded:Connect(createESP)
    espLeaveConn = Players.PlayerRemoving:Connect(removeESP)
    espUpdateConn = RunService.Heartbeat:Connect(updateESPDistances)
    LIVE[#LIVE+1] = espConn
    LIVE[#LIVE+1] = espLeaveConn
    LIVE[#LIVE+1] = espUpdateConn
end

local function disableESP()
    if espConn then espConn:Disconnect(); espConn = nil end
    if espLeaveConn then espLeaveConn:Disconnect(); espLeaveConn = nil end
    if espUpdateConn then espUpdateConn:Disconnect(); espUpdateConn = nil end
    for p in pairs(ESPObjects) do removeESP(p) end
end

local function refreshESP()
    if Settings.espEnabled then disableESP(); enableESP() end
end

-- ═══════════════════════════════════════════════════════════════
--  BANK ESP (подсветка + таймер ограбления)  [UPDATED v2.4]
--  Теперь ищет "bank", "bankrobbery", "puente", "banco" и атрибуты.
--  На банке отображается "Puente Bank", в HUD – только статус/таймер.
-- ═══════════════════════════════════════════════════════════════
local BANK_MANUAL_PATH = ""   -- <-- можно вписать точный путь, если авто-поиск не справляется

local bankPart, bankValue = nil, nil
local bankBBs = {}
local BankHud, hudLbl = nil, nil

local function getObjectByPath(path)
    local cur = game
    for seg in path:gmatch("[^%.]+") do
        cur = cur:FindFirstChild(seg)
        if not cur then return nil end
    end
    return cur
end

local function classifyBank(obj)
    if obj:IsA("BoolValue") or obj:IsA("IntValue") or obj:IsA("NumberValue") or obj:IsA("StringValue") then
        if not bankValue then bankValue = obj end
    elseif obj:IsA("BasePart") or obj:IsA("Model") then
        if not bankPart then bankPart = obj end
    end
end

local function scanBank()
    bankPart, bankValue = nil, nil

    -- Если задан ручной путь
    if BANK_MANUAL_PATH ~= "" then
        local obj = getObjectByPath(BANK_MANUAL_PATH)
        if obj then classifyBank(obj) end
        if bankPart or bankValue then return end
    end

    -- Собираем все объекты из Workspace и ReplicatedStorage
    local all = {}
    pcall(function()
        for _, d in ipairs(Workspace:GetDescendants()) do table.insert(all, d) end
    end)
    pcall(function()
        for _, d in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do table.insert(all, d) end
    end)

    -- Ищем по имени и атрибутам
    for _, d in ipairs(all) do
        local name = d.Name:lower()
        if name:find("bankrobbery") or name:find("bank") or name:find("puente") or name:find("banco") then
            classifyBank(d)
        end
        -- Если ещё не нашли bankPart, проверяем атрибуты
        if not bankPart then
            local attrs = d:GetAttributes()
            for key, _ in pairs(attrs) do
                local k = key:lower()
                if k:find("bank") or k:find("robbery") or k:find("puente") then
                    classifyBank(d)
                    break
                end
            end
        end
        if bankPart and bankValue then break end
    end

    -- Если нашли только bankPart, но нет bankValue – попробуем найти значение внутри bankPart
    if bankPart and not bankValue then
        pcall(function()
            for _, ch in ipairs(bankPart:GetChildren()) do
                if ch:IsA("ValueBase") then
                    bankValue = ch
                    break
                end
            end
        end)
        if not bankValue then
            pcall(function()
                for _, attr in ipairs({"BankRobbery", "RobberyCooldown", "Cooldown", "Timer", "CanRob", "NextRobbery"}) do
                    local a = bankPart:GetAttribute(attr)
                    if a ~= nil then
                        bankValue = bankPart -- сохраняем ссылку для чтения атрибута
                        break
                    end
                end
            end)
        end
    end
end

local function formatTime(sec)
    sec = math.max(0, math.floor(sec))
    local m = math.floor(sec / 60)
    local s = sec % 60
    return string.format("%02d:%02d", m, s)
end

local function interpretBankValue(v)
    if typeof(v) == "boolean" then
        if v then return "Открыт" else return "Закрыт" end
    elseif typeof(v) == "number" then
        if v > 1000000000 then
            local left = v - os.time()
            if left <= 0 then return "Открыт" end
            return "⏳ " .. formatTime(left)
        elseif v <= 0 then
            return "Открыт"
        else
            return "⏳ " .. formatTime(v)
        end
    elseif typeof(v) == "string" and v ~= "" then
        return v
    end
    return nil
end

local function readBankStatus()
    local sources = {}
    if bankValue then
        pcall(function() table.insert(sources, bankValue.Value) end)
    end
    if bankPart then
        for _, attrName in ipairs({"BankRobbery", "RobberyCooldown", "Cooldown", "Timer", "CanRob", "NextRobbery"}) do
            pcall(function()
                local a = bankPart:GetAttribute(attrName)
                if a ~= nil then table.insert(sources, a) end
            end)
        end
        pcall(function()
            for _, ch in ipairs(bankPart:GetChildren()) do
                if ch:IsA("ValueBase") then table.insert(sources, ch.Value) end
            end
        end)
        if bankPart:IsA("Model") then
            pcall(function()
                local pp = bankPart.PrimaryPart or bankPart:FindFirstChildWhichIsA("BasePart", true)
                if pp then
                    for _, ch in ipairs(pp:GetChildren()) do
                        if ch:IsA("ValueBase") then table.insert(sources, ch.Value) end
                    end
                end
            end)
        end
    end
    for _, v in ipairs(sources) do
        local t = interpretBankValue(v)
        if t then return t end
    end
    return nil
end

local function attachBankHighlight(target)
    local adornee, bbParent = target, target
    if target:IsA("Model") then
        local part = target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart", true)
        if not part then return end
        bbParent = part
    end

    local box = Instance.new("SelectionBox")
    box.LineThickness     = 0.08
    box.SurfaceTransparency = 0.85
    box.Color3            = C.bank_col
    box.SurfaceColor3     = C.bank_col
    box.Adornee           = adornee
    box.Parent            = Workspace

    local bb = Instance.new("BillboardGui")
    bb.AlwaysOnTop = true
    bb.Size        = UDim2.new(0, 230, 0, 44)
    bb.StudsOffset = Vector3.new(0, 6, 0)
    bb.Parent      = bbParent

    local lbl = Instance.new("TextLabel", bb)
    lbl.Size = UDim2.new(1,0,1,0)
    lbl.BackgroundColor3 = Color3.fromRGB(10,10,20)
    lbl.BackgroundTransparency = 0.35
    lbl.TextColor3 = C.bank_col
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 14
    lbl.Text = "Puente Bank"  -- изменено
    Instance.new("UICorner", lbl).CornerRadius = UDim.new(0,6)
    local st = Instance.new("UIStroke", lbl)
    st.Color = C.bank_col
    st.Transparency = 0.4

    bankBBs[target] = { box = box, bb = bb, lbl = lbl }
end

local function createBankHud()
    BankHud = Instance.new("ScreenGui")
    BankHud.Name = "BankHud"
    BankHud.ResetOnSpawn = false
    BankHud.DisplayOrder = 900
    BankHud.Parent = LG

    local pill = Instance.new("Frame", BankHud)
    pill.AnchorPoint = Vector2.new(0.5, 0)
    pill.Position = UDim2.new(0.5, 0, 0, 12)
    pill.Size = UDim2.new(0, 280, 0, 34)
    pill.BackgroundColor3 = Color3.fromRGB(10,10,20)
    pill.BackgroundTransparency = 0.25
    Instance.new("UICorner", pill).CornerRadius = UDim.new(0,8)
    local st = Instance.new("UIStroke", pill)
    st.Color = C.bank_col
    st.Transparency = 0.3

    hudLbl = Instance.new("TextLabel", pill)
    hudLbl.Size = UDim2.new(1,0,1,0)
    hudLbl.BackgroundTransparency = 1
    hudLbl.Font = Enum.Font.GothamBold
    hudLbl.TextSize = 13
    hudLbl.TextColor3 = C.bank_col
    hudLbl.Text = "Поиск банка..."  -- начальный текст
end

local function updateBankTexts()
    local status = readBankStatus() or "не найден"
    -- Теперь выводим только статус/таймер, без префикса
    if hudLbl and hudLbl.Parent then hudLbl.Text = status end
    for _, data in pairs(bankBBs) do
        if data.lbl and data.lbl.Parent then
            -- На банке оставляем "Puente Bank", менять не будем
        end
    end
end

local bankLoopThread = nil

local function enableBankESP()
    scanBank()
    if bankPart then attachBankHighlight(bankPart) end
    createBankHud()
    updateBankTexts()

    bankLoopThread = task.spawn(function()
        local tick = 0
        while Settings.bankESP do
            tick = tick + 1
            if (not bankPart and not bankValue) and tick % 10 == 0 then
                scanBank()
                if bankPart then attachBankHighlight(bankPart) end
            end
            updateBankTexts()
            task.wait(0.5)
        end
    end)
    LIVE[#LIVE+1] = bankLoopThread
end

local function disableBankESP()
    Settings.bankESP = false
    if bankLoopThread then
        task.cancel(bankLoopThread)
        bankLoopThread = nil
    end
    for _, data in pairs(bankBBs) do
        pcall(function() data.bb:Destroy() end)
        pcall(function() data.box:Destroy() end)
    end
    bankBBs = {}
    pcall(function() BankHud:Destroy() end)
    BankHud, hudLbl = nil, nil
    bankPart, bankValue = nil, nil
end

-- ═══════════════════════════════════════════════════════════════
--  FOV CIRCLES (UICorner + UIStroke, без ассетов)
-- ═══════════════════════════════════════════════════════════════
if LG:FindFirstChild("FOVGui") then LG:FindFirstChild("FOVGui"):Destroy() end
local FOVGui = Instance.new("ScreenGui")
FOVGui.Name          = "FOVGui"
FOVGui.ResetOnSpawn  = false
FOVGui.ZIndexBehavior= Enum.ZIndexBehavior.Sibling
FOVGui.DisplayOrder  = 1000
FOVGui.Parent        = LG

local FOV_PC_Frame = Instance.new("Frame", FOVGui)
FOV_PC_Frame.BackgroundTransparency = 1
FOV_PC_Frame.AnchorPoint = Vector2.new(0.5, 0.5)
FOV_PC_Frame.Position    = UDim2.new(0.5, 0, 0.5, 0)
FOV_PC_Frame.ZIndex      = 50
FOV_PC_Frame.Visible     = false
Instance.new("UICorner", FOV_PC_Frame).CornerRadius = UDim.new(0.5, 0)
local pcStroke = Instance.new("UIStroke", FOV_PC_Frame)
pcStroke.Color      = C.fov_col
pcStroke.Thickness  = 1.5
pcStroke.Transparency = 0.1

local FOV_MOB_Frame = Instance.new("Frame", FOVGui)
FOV_MOB_Frame.BackgroundTransparency = 1
FOV_MOB_Frame.AnchorPoint = Vector2.new(0.5, 0.5)
FOV_MOB_Frame.Position    = UDim2.new(0.5, 0, 0.5, 0)
FOV_MOB_Frame.ZIndex      = 50
FOV_MOB_Frame.Visible     = false
Instance.new("UICorner", FOV_MOB_Frame).CornerRadius = UDim.new(0.5, 0)
local mobStroke = Instance.new("UIStroke", FOV_MOB_Frame)
mobStroke.Color      = C.fov_mob
mobStroke.Thickness  = 1.5
mobStroke.Transparency = 0.1

local function updateFOVCircles()
    local pcR = Settings.aimbotPCFOV * 2
    FOV_PC_Frame.Size    = UDim2.new(0, pcR, 0, pcR)
    FOV_PC_Frame.Visible = Settings.aimbotPC

    local mobR = Settings.aimbotMobileFOV * 2
    FOV_MOB_Frame.Size    = UDim2.new(0, mobR, 0, mobR)
    FOV_MOB_Frame.Visible = Settings.aimbotMobile
end
updateFOVCircles()

-- ═══════════════════════════════════════════════════════════════
--  AIMBOT (проверка стен + фильтр ролей)
-- ═══════════════════════════════════════════════════════════════
Camera.CameraType = Enum.CameraType.Custom
UserInputService.MouseBehavior = Enum.MouseBehavior.Default

local function getAimPosition(char)
    if Settings.aimPart == "Head" then
        local h = char:FindFirstChild("Head")
        if h then return h.Position end
    else
        local ut = char:FindFirstChild("UpperTorso")
        if ut then return ut.Position + Vector3.new(0, ut.Size.Y * 0.15, 0) end
        local t = char:FindFirstChild("Torso")
        if t then return t.Position + Vector3.new(0, 0.5, 0) end
    end
    local h = char:FindFirstChild("Head")
    return h and h.Position or nil
end

local function getVelocity(char)
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then
        local v = root.AssemblyLinearVelocity or root.Velocity or Vector3.zero
        return Vector3.new(v.X, 0, v.Z)
    end
    return Vector3.zero
end

local function isAlive(p)
    if p == LP or not p.Character or p.Character == LP.Character then return false end
    local hum = p.Character:FindFirstChildOfClass("Humanoid")
    return hum ~= nil and hum.Health > 0 and getAimPosition(p.Character) ~= nil
end

local function isRoleAllowed(player)
    local role = getPlayerRole(player)
    if not role then return false end
    return Settings.aimbotTargetTeams[role] == true
end

local function isTargetVisible(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return false end
    local aimPos = getAimPosition(targetPlayer.Character)
    if not aimPos then return false end
    local origin = Camera.CFrame.Position
    local direction = (aimPos - origin).unit
    local distance = (aimPos - origin).Magnitude
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {targetPlayer.Character, LP.Character}
    local result = Workspace:Raycast(origin, direction * distance, params)
    return not result
end

local locked = nil
local lockedPos = nil
local lockedPosSmooth = 0.3

local function pickTarget(fov)
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local best, bestDist = nil, fov
    local myPos = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myPos then return nil end
    myPos = myPos.Position

    for _, p in ipairs(Players:GetPlayers()) do
        if isAlive(p) and isRoleAllowed(p) and isTargetVisible(p) then
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local dist = (root.Position - myPos).Magnitude
                if dist <= 500 then
                    local pos = getAimPosition(p.Character)
                    if pos then
                        local sp, on = Camera:WorldToScreenPoint(pos)
                        if on then
                            local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                            if d < bestDist then best, bestDist = p, d end
                        end
                    end
                end
            end
        end
    end
    return best
end

local AIM_BIND = "AimbotCamBind"
pcall(function() RunService:UnbindFromRenderStep(AIM_BIND) end)
local aimbotActive = false

local function updateAimbotBinding()
    local active = Settings.aimbotPC or Settings.aimbotMobile
    if active and not aimbotActive then
        RunService:BindToRenderStep(AIM_BIND, Enum.RenderPriority.Camera.Value + 10, function(dt)
            if not (Settings.aimbotPC or Settings.aimbotMobile) then
                locked = nil; lockedPos = nil; return
            end
            local fov = Settings.aimbotPC and Settings.aimbotPCFOV or Settings.aimbotMobileFOV

            local target = nil
            if locked and isAlive(locked) and isRoleAllowed(locked) and isTargetVisible(locked) then
                local pos = getAimPosition(locked.Character)
                if pos then
                    local sp, on = Camera:WorldToScreenPoint(pos)
                    if on then
                        local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                        local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                        if d < fov * 1.5 then target = locked end
                    end
                end
            end
            if not target then
                target = pickTarget(fov)
                locked = target; lockedPos = nil
            end
            if not target then return end

            local rawPos = getAimPosition(target.Character)
            if not rawPos then return end
            local vel = getVelocity(target.Character) * Settings.aimPrediction
            local aimPos = rawPos + vel

            if lockedPos then
                lockedPos = lockedPos:Lerp(aimPos, lockedPosSmooth)
            else
                lockedPos = aimPos
            end
            aimPos = lockedPos

            local cf = Camera.CFrame
            local goal = CFrame.new(cf.Position, aimPos)
            local currentDir = cf.LookVector
            local targetDir = (aimPos - cf.Position).unit
            local angle = math.acos(math.clamp(currentDir:Dot(targetDir), -1, 1))
            local maxAngle = math.rad(8)
            if angle > maxAngle then
                local t = maxAngle / angle
                local newDir = currentDir:Lerp(targetDir, t).unit
                goal = CFrame.lookAt(cf.Position, cf.Position + newDir)
            end
            Camera.CFrame = goal
        end)
        aimbotActive = true
    elseif not active and aimbotActive then
        RunService:UnbindFromRenderStep(AIM_BIND)
        locked = nil; lockedPos = nil; aimbotActive = false
    end
end

local function toggleAimbotPC()
    Settings.aimbotPC = not Settings.aimbotPC
    if Settings.aimbotPC then Settings.aimbotMobile = false end
    updateFOVCircles(); updateAimbotBinding()
end

local function toggleAimbotMobile()
    Settings.aimbotMobile = not Settings.aimbotMobile
    if Settings.aimbotMobile then Settings.aimbotPC = false end
    updateFOVCircles(); updateAimbotBinding()
end

updateAimbotBinding()

-- ═══════════════════════════════════════════════════════════════
--  GUI: Neonation WH
-- ═══════════════════════════════════════════════════════════════
if LG:FindFirstChild("RBXMenu") then LG:FindFirstChild("RBXMenu"):Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "RBXMenu"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder   = 10
ScreenGui.Parent         = LG

local Blur = Instance.new("BlurEffect")
Blur.Size   = 0
Blur.Parent = game:GetService("Lighting")

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Name              = "Main"
MainFrame.AnchorPoint       = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3  = C.panel
MainFrame.BorderSizePixel   = 0
MainFrame.Position          = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.Size              = UDim2.new(0, 860, 0, 580)
MainFrame.ClipsDescendants  = true
MainFrame.Visible           = false
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color       = C.accent
MainStroke.Transparency= 0.7
MainStroke.Thickness   = 1.5
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local Shadow = Instance.new("ImageLabel", MainFrame)
Shadow.AnchorPoint          = Vector2.new(0.5,0.5)
Shadow.BackgroundTransparency=1
Shadow.Position             = UDim2.new(0.5,0,0.5,10)
Shadow.Size                 = UDim2.new(1,40,1,40)
Shadow.ZIndex               = 0
Shadow.Image                = "rbxassetid://1316045217"
Shadow.ImageColor3          = Color3.new(0,0,0)
Shadow.ImageTransparency    = 0.5
Shadow.ScaleType            = Enum.ScaleType.Slice
Shadow.SliceCenter          = Rect.new(10,10,118,118)

local TopBar = Instance.new("Frame", MainFrame)
TopBar.BackgroundColor3 = C.sidebar
TopBar.BorderSizePixel  = 0
TopBar.Size             = UDim2.new(1,0,0,50)
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0,12)

local Title = Instance.new("TextLabel", TopBar)
Title.Text             = "霓  NEONATION WH"
Title.Font             = Enum.Font.GothamBold
Title.TextSize         = 18
Title.TextColor3       = C.text
Title.BackgroundTransparency=1
Title.Position         = UDim2.new(0,20,0,0)
Title.Size             = UDim2.new(0.6,0,1,0)
Title.TextXAlignment   = Enum.TextXAlignment.Left

local titleGrad = Instance.new("UIGradient", Title)
titleGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   C.accent),
    ColorSequenceKeypoint.new(0.5, C.accent2),
    ColorSequenceKeypoint.new(1,   C.text),
})
titleGrad.Rotation = 45

local SubLbl = Instance.new("TextLabel", TopBar)
SubLbl.Text            = "[ K ] Toggle"
SubLbl.Font            = Enum.Font.Gotham
SubLbl.TextSize        = 10
SubLbl.TextColor3      = C.subtext
SubLbl.BackgroundTransparency=1
SubLbl.Position        = UDim2.new(0,20,0,32)
SubLbl.Size            = UDim2.new(0.4,0,0,14)
SubLbl.TextXAlignment  = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", TopBar)
CloseBtn.Text            = "×"
CloseBtn.Font            = Enum.Font.GothamBold
CloseBtn.TextSize        = 16
CloseBtn.TextColor3      = C.subtext
CloseBtn.BackgroundColor3= Color3.fromRGB(30,30,50)
CloseBtn.AnchorPoint     = Vector2.new(1,0.5)
CloseBtn.Position        = UDim2.new(1,-14,0.5,0)
CloseBtn.Size            = UDim2.new(0,32,0,32)
CloseBtn.AutoButtonColor = false
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0,8)

local LeftPanel = Instance.new("Frame", MainFrame)
LeftPanel.BackgroundColor3 = C.sidebar
LeftPanel.BorderSizePixel  = 0
LeftPanel.Position         = UDim2.new(0,0,0,50)
LeftPanel.Size             = UDim2.new(0, 180, 1, -50)

local Divider = Instance.new("Frame", MainFrame)
Divider.BackgroundColor3 = C.divider
Divider.BorderSizePixel  = 0
Divider.Position         = UDim2.new(0,180,0,50)
Divider.Size             = UDim2.new(0,1,1,-50)

local RightPanel = Instance.new("ScrollingFrame", MainFrame)
RightPanel.BackgroundTransparency = 1
RightPanel.BorderSizePixel = 0
RightPanel.Position        = UDim2.new(0,190,0,55)
RightPanel.Size            = UDim2.new(1, -200, 1, -60)
RightPanel.CanvasSize      = UDim2.new(0,0,0,0)
RightPanel.AutomaticCanvasSize = Enum.AutomaticSize.Y
RightPanel.ScrollBarThickness = 3
RightPanel.ScrollBarImageColor3 = C.accent

local RightLayout = Instance.new("UIListLayout", RightPanel)
RightLayout.Padding = UDim.new(0,8)
RightLayout.FillDirection = Enum.FillDirection.Vertical
RightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
RightLayout.SortOrder = Enum.SortOrder.LayoutOrder

local TabFrames = {}
local CurrentTab = nil

-- ═══════════════════════════════════════════════════════════════
--  ПОЛНЫЙ АНЛОАД (кнопка 滅)
-- ═══════════════════════════════════════════════════════════════
local function unloadCheat()
    Settings.aimbotPC = false
    Settings.aimbotMobile = false
    Settings.espEnabled = false
    pcall(updateAimbotBinding)
    pcall(disableESP)
    pcall(disableBankESP)
    pcall(updateFOVCircles)

    for _, cn in ipairs(LIVE) do
        pcall(function() 
            if type(cn) == "thread" then 
                task.cancel(cn) 
            else 
                cn:Disconnect() 
            end 
        end)
    end

    pcall(function() Blur:Destroy() end)
    pcall(function() FOVGui:Destroy() end)
    pcall(function() ScreenGui:Destroy() end)
end

-- ═══════════════════════════════════════════════════════════════
--  HELPERS GUI
-- ═══════════════════════════════════════════════════════════════
local function takeOrder(parent)
    local m = 0
    for _, ch in ipairs(parent:GetChildren()) do
        if ch:IsA("GuiObject") then m = math.max(m, ch.LayoutOrder) end
    end
    return m + 1
end

local function createSection(parent, title)
    local section = Instance.new("Frame", parent)
    section.BackgroundTransparency = 1
    section.Size = UDim2.new(1, -20, 0, 0)
    section.AutomaticSize = Enum.AutomaticSize.Y
    section.LayoutOrder = takeOrder(parent)

    local layout = Instance.new("UIListLayout", section)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)

    local header = Instance.new("TextLabel", section)
    header.Text = title
    header.Font = Enum.Font.GothamBold
    header.TextSize = 12
    header.TextColor3 = C.accent
    header.BackgroundTransparency = 1
    header.Size = UDim2.new(1,0,0,20)
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.LayoutOrder = 0
    return section
end

local function createToggleEx(parent, icon, label, desc, accentColor, getState, toggle)
    accentColor = accentColor or C.accent
    local Row = Instance.new("TextButton", parent)
    Row.BackgroundColor3 = Color3.fromRGB(18,18,32)
    Row.Size             = UDim2.new(1,0,0,44)
    Row.AutoButtonColor  = false
    Row.Text             = ""
    Row.LayoutOrder      = takeOrder(parent)
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0,6)

    local Icon = Instance.new("TextLabel", Row)
    Icon.Text              = icon
    Icon.Font              = Enum.Font.GothamBold
    Icon.TextSize          = 16
    Icon.TextColor3        = accentColor
    Icon.BackgroundTransparency=1
    Icon.Position          = UDim2.new(0,10,0,0)
    Icon.Size              = UDim2.new(0,30,1,0)

    local Lbl = Instance.new("TextLabel", Row)
    Lbl.Text               = label
    Lbl.Font               = Enum.Font.GothamBold
    Lbl.TextSize           = 12
    Lbl.TextColor3         = C.text
    Lbl.BackgroundTransparency=1
    Lbl.Position           = UDim2.new(0,45,0,4)
    Lbl.Size               = UDim2.new(0.5,0,0,18)

    local Desc = Instance.new("TextLabel", Row)
    Desc.Text              = desc
    Desc.Font              = Enum.Font.Gotham
    Desc.TextSize          = 9
    Desc.TextColor3        = C.subtext
    Desc.BackgroundTransparency=1
    Desc.Position          = UDim2.new(0,45,0,22)
    Desc.Size              = UDim2.new(0.5,0,0,14)

    local Pill = Instance.new("Frame", Row)
    Pill.AnchorPoint       = Vector2.new(1,0.5)
    Pill.Position          = UDim2.new(1,-12,0.5,0)
    Pill.Size              = UDim2.new(0,38,0,20)
    Pill.BackgroundColor3  = C.off_col
    Instance.new("UICorner", Pill).CornerRadius = UDim.new(1,0)

    local Knob = Instance.new("Frame", Pill)
    Knob.AnchorPoint       = Vector2.new(0,0.5)
    Knob.Position          = UDim2.new(0,2,0.5,0)
    Knob.Size              = UDim2.new(0,14,0,14)
    Knob.BackgroundColor3  = Color3.new(1,1,1)
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1,0)

    local function refreshPill()
        local on = getState()
        TweenService:Create(Pill, TweenInfo.new(0.15), {
            BackgroundColor3 = on and C.on_col or C.off_col
        }):Play()
        TweenService:Create(Knob, TweenInfo.new(0.15, Enum.EasingStyle.Back), {
            Position = on and UDim2.new(1,-16,0.5,0) or UDim2.new(0,2,0.5,0)
        }):Play()
    end
    refreshPill()

    Row.MouseEnter:Connect(function()
        TweenService:Create(Row, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(28,28,46) }):Play()
    end)
    Row.MouseLeave:Connect(function()
        TweenService:Create(Row, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(18,18,32) }):Play()
    end)
    Row.MouseButton1Click:Connect(function()
        toggle(); refreshPill()
    end)
    return Row
end

local function createSliderEx(parent, labelTxt, minV, maxV, getVal, setVal, accentColor)
    accentColor = accentColor or C.accent
    local Row = Instance.new("Frame", parent)
    Row.BackgroundColor3 = Color3.fromRGB(18,18,32)
    Row.Size             = UDim2.new(1,0,0,48)
    Row.LayoutOrder      = takeOrder(parent)
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0,6)

    local Lbl = Instance.new("TextLabel", Row)
    Lbl.Text             = labelTxt
    Lbl.Font             = Enum.Font.GothamBold
    Lbl.TextSize         = 11
    Lbl.TextColor3       = C.text
    Lbl.BackgroundTransparency=1
    Lbl.Position         = UDim2.new(0,12,0,4)
    Lbl.Size             = UDim2.new(0.6,0,0,16)

    local ValLbl = Instance.new("TextLabel", Row)
    ValLbl.Font          = Enum.Font.GothamBold
    ValLbl.TextSize      = 11
    ValLbl.TextColor3    = accentColor
    ValLbl.BackgroundTransparency=1
    ValLbl.AnchorPoint   = Vector2.new(1,0)
    ValLbl.Position      = UDim2.new(1,-12,0,4)
    ValLbl.Size          = UDim2.new(0,40,0,16)
    ValLbl.TextXAlignment= Enum.TextXAlignment.Right

    local Track = Instance.new("Frame", Row)
    Track.BackgroundColor3 = C.divider
    Track.BorderSizePixel  = 0
    Track.Position         = UDim2.new(0,12,0,32)
    Track.Size             = UDim2.new(1,-24,0,4)
    Instance.new("UICorner", Track).CornerRadius = UDim.new(1,0)

    local Fill = Instance.new("Frame", Track)
    Fill.BackgroundColor3 = accentColor
    Fill.BorderSizePixel  = 0
    Fill.Size             = UDim2.new(0,0,1,0)
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(1,0)

    local Handle = Instance.new("Frame", Track)
    Handle.AnchorPoint    = Vector2.new(0.5, 0.5)
    Handle.BackgroundColor3= accentColor
    Handle.Position       = UDim2.new(0,0,0.5,0)
    Handle.Size           = UDim2.new(0,12,0,12)
    Instance.new("UICorner", Handle).CornerRadius = UDim.new(1,0)

    local function updateVisual()
        local v   = getVal()
        local pct = math.clamp((v - minV) / (maxV - minV), 0, 1)
        ValLbl.Text     = tostring(v)
        Fill.Size       = UDim2.new(pct,0,1,0)
        Handle.Position = UDim2.new(pct,0,0.5,0)
        updateFOVCircles()
    end
    updateVisual()

    local dragSlider = false
    local conn1 = Track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragSlider = true
        end
    end)
    local conn2 = UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragSlider = false
        end
    end)
    local conn3 = UserInputService.InputChanged:Connect(function(inp)
        if dragSlider and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            local abs  = Track.AbsolutePosition
            local sz   = Track.AbsoluteSize
            local pct  = math.clamp((inp.Position.X - abs.X) / sz.X, 0, 1)
            local newV = math.floor(minV + pct*(maxV-minV) + 0.5)
            setVal(newV)
            updateVisual()
        end
    end)
    LIVE[#LIVE+1] = conn1
    LIVE[#LIVE+1] = conn2
    LIVE[#LIVE+1] = conn3
    return Row
end

local function createButtonEx(parent, icon, label, desc, accentColor, callback)
    accentColor = accentColor or C.danger
    local Row = Instance.new("TextButton", parent)
    Row.BackgroundColor3 = Color3.fromRGB(18,18,32)
    Row.Size             = UDim2.new(1,0,0,44)
    Row.AutoButtonColor  = false
    Row.Text             = ""
    Row.LayoutOrder      = takeOrder(parent)
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0,6)

    local Icon = Instance.new("TextLabel", Row)
    Icon.Text              = icon
    Icon.Font              = Enum.Font.GothamBold
    Icon.TextSize          = 18
    Icon.TextColor3        = accentColor
    Icon.BackgroundTransparency=1
    Icon.Position          = UDim2.new(0,10,0,0)
    Icon.Size              = UDim2.new(0,30,1,0)

    local Lbl = Instance.new("TextLabel", Row)
    Lbl.Text               = label
    Lbl.Font               = Enum.Font.GothamBold
    Lbl.TextSize           = 12
    Lbl.TextColor3         = C.text
    Lbl.BackgroundTransparency=1
    Lbl.Position           = UDim2.new(0,45,0,4)
    Lbl.Size               = UDim2.new(0.6,0,0,18)

    local Desc = Instance.new("TextLabel", Row)
    Desc.Text              = desc
    Desc.Font              = Enum.Font.Gotham
    Desc.TextSize          = 9
    Desc.TextColor3        = C.subtext
    Desc.BackgroundTransparency=1
    Desc.Position          = UDim2.new(0,45,0,22)
    Desc.Size              = UDim2.new(0.6,0,0,14)

    local Arrow = Instance.new("TextLabel", Row)
    Arrow.Text             = "》"
    Arrow.Font             = Enum.Font.GothamBold
    Arrow.TextSize         = 16
    Arrow.TextColor3       = C.subtext
    Arrow.BackgroundTransparency=1
    Arrow.AnchorPoint      = Vector2.new(1,0.5)
    Arrow.Position         = UDim2.new(1,-12,0.5,0)
    Arrow.Size             = UDim2.new(0,20,1,0)
    Arrow.TextXAlignment   = Enum.TextXAlignment.Center

    Row.MouseEnter:Connect(function()
        TweenService:Create(Row, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(28,28,46) }):Play()
        TweenService:Create(Arrow, TweenInfo.new(0.1), { TextColor3 = accentColor }):Play()
    end)
    Row.MouseLeave:Connect(function()
        TweenService:Create(Row, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(18,18,32) }):Play()
        TweenService:Create(Arrow, TweenInfo.new(0.1), { TextColor3 = C.subtext }):Play()
    end)
    Row.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)
    return Row
end

local function createRoleToggleEx(parent, roleName, roleColor, isTarget)
    local Row = Instance.new("Frame", parent)
    Row.BackgroundColor3 = Color3.fromRGB(16,16,28)
    Row.Size             = UDim2.new(1,0,0,32)
    Row.LayoutOrder      = takeOrder(parent)
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0,5)

    local Dot = Instance.new("Frame", Row)
    Dot.AnchorPoint      = Vector2.new(0,0.5)
    Dot.Position         = UDim2.new(0,8,0.5,0)
    Dot.Size             = UDim2.new(0,8,0,8)
    Dot.BackgroundColor3 = roleColor
    Instance.new("UICorner", Dot).CornerRadius = UDim.new(1,0)

    local Lbl = Instance.new("TextLabel", Row)
    Lbl.Text             = roleName
    Lbl.Font             = Enum.Font.Gotham
    Lbl.TextSize         = 11
    Lbl.TextColor3       = C.text
    Lbl.BackgroundTransparency=1
    Lbl.Position         = UDim2.new(0,22,0,0)
    Lbl.Size             = UDim2.new(0.6,0,1,0)
    Lbl.TextXAlignment   = Enum.TextXAlignment.Left

    local Pill = Instance.new("Frame", Row)
    Pill.AnchorPoint     = Vector2.new(1,0.5)
    Pill.Position        = UDim2.new(1,-8,0.5,0)
    Pill.Size            = UDim2.new(0,32,0,16)
    local onState
    if isTarget then
        onState = Settings.aimbotTargetTeams[roleName]
    else
        onState = Settings.espRoles[roleName].enabled
    end
    Pill.BackgroundColor3 = onState and C.on_col or C.off_col
    Instance.new("UICorner", Pill).CornerRadius = UDim.new(1,0)

    local Knob = Instance.new("Frame", Pill)
    Knob.AnchorPoint     = Vector2.new(0,0.5)
    Knob.Position        = onState and UDim2.new(1,-14,0.5,0) or UDim2.new(0,2,0.5,0)
    Knob.Size            = UDim2.new(0,12,0,12)
    Knob.BackgroundColor3= Color3.new(1,1,1)
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1,0)

    local Btn = Instance.new("TextButton", Row)
    Btn.BackgroundTransparency=1
    Btn.Size             = UDim2.new(1,0,1,0)
    Btn.Text             = ""
    Btn.ZIndex           = 5

    Btn.MouseButton1Click:Connect(function()
        if isTarget then
            Settings.aimbotTargetTeams[roleName] = not Settings.aimbotTargetTeams[roleName]
            if locked and not isRoleAllowed(locked) then locked = nil; lockedPos = nil end
        else
            Settings.espRoles[roleName].enabled = not Settings.espRoles[roleName].enabled
            refreshESP()
        end
        local on = isTarget and Settings.aimbotTargetTeams[roleName] or Settings.espRoles[roleName].enabled
        TweenService:Create(Pill, TweenInfo.new(0.15), { BackgroundColor3 = on and C.on_col or C.off_col }):Play()
        TweenService:Create(Knob, TweenInfo.new(0.15, Enum.EasingStyle.Back), {
            Position = on and UDim2.new(1,-14,0.5,0) or UDim2.new(0,2,0.5,0)
        }):Play()
    end)
    return Row
end

-- ═══════════════════════════════════════════════════════════════
--  ВКЛАДКИ (иконки — иероглифы)
-- ═══════════════════════════════════════════════════════════════
local tabs = {
    { name = "Aimbot",   icon = "瞄" },
    { name = "ESP",      icon = "視" },
    { name = "Targets",  icon = "敵" },
    { name = "Visuals",  icon = "彩" },
    { name = "Misc",     icon = "具" },
    { name = "Settings", icon = "設" },
}

local tabButtons = {}
local tabSelects = {}

for i, tab in ipairs(tabs) do
    local btn = Instance.new("TextButton", LeftPanel)
    btn.Name = tab.name
    btn.BackgroundColor3 = Color3.fromRGB(10,10,20)
    btn.Size = UDim2.new(1,0,0,40)
    btn.Position = UDim2.new(0,0,0, (i-1)*42 + 10)
    btn.Text = "  " .. tab.icon .. "  " .. tab.name
    btn.TextColor3 = C.subtext
    btn.TextSize = 13
    btn.Font = Enum.Font.Gotham
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)

    local indicator = Instance.new("Frame", btn)
    indicator.Size = UDim2.new(0,3,0.6,0)
    indicator.Position = UDim2.new(0,0,0.2,0)
    indicator.BackgroundColor3 = C.accent
    indicator.BorderSizePixel = 0
    indicator.Visible = false

    local function select()
        for _, f in pairs(TabFrames) do if f then f.Visible = false end end
        for _, b in pairs(tabButtons) do b.indicator.Visible = false; b.TextColor3 = C.subtext end
        if TabFrames[tab.name] then
            TabFrames[tab.name].Visible = true
            CurrentTab = tab.name
        end
        btn.indicator.Visible = true
        btn.TextColor3 = C.text
    end
    tabSelects[tab.name] = select

    btn.MouseButton1Click:Connect(select)
    btn.MouseEnter:Connect(function()
        if not btn.indicator.Visible then
            TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(20,20,36) }):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if not btn.indicator.Visible then
            TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(10,10,20) }):Play()
        end
    end)

    tabButtons[btn] = { btn = btn, indicator = indicator }
end

for _, tab in ipairs(tabs) do
    local frame = Instance.new("Frame", RightPanel)
    frame.Name = tab.name .. "Tab"
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1,0,0,0)
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.Visible = false
    frame.LayoutOrder = takeOrder(RightPanel)

    local fl = Instance.new("UIListLayout", frame)
    fl.SortOrder = Enum.SortOrder.LayoutOrder
    fl.Padding = UDim.new(0, 12)

    TabFrames[tab.name] = frame
end

-- ═══════════════════════════════════════════════════════════════
--  ЗАПОЛНЕНИЕ ВКЛАДОК
-- ═══════════════════════════════════════════════════════════════

-- 1. Aimbot
local aimbotFrame = TabFrames["Aimbot"]
local sec1 = createSection(aimbotFrame, "PC")
createToggleEx(sec1, "準", "Aimbot PC", "Авто-прицел мышью", C.fov_col,
    function() return Settings.aimbotPC end, toggleAimbotPC)
createSliderEx(sec1, "PC FOV (px)", 30, 600,
    function() return Settings.aimbotPCFOV end,
    function(v) Settings.aimbotPCFOV = v end, C.fov_col)
createSliderEx(sec1, "PC Smooth", 1, 30,
    function() return math.floor(Settings.aimbotPCSmooth * 100 + 0.5) end,
    function(v) Settings.aimbotPCSmooth = v / 100 end, C.fov_col)

local sec2 = createSection(aimbotFrame, "Mobile")
createToggleEx(sec2, "触", "Aimbot Mobile", "Авто-прицел для сенсора", C.fov_mob,
    function() return Settings.aimbotMobile end, toggleAimbotMobile)
createSliderEx(sec2, "Mobile FOV (px)", 30, 700,
    function() return Settings.aimbotMobileFOV end,
    function(v) Settings.aimbotMobileFOV = v end, C.fov_mob)
createSliderEx(sec2, "Mobile Smooth", 1, 30,
    function() return math.floor(Settings.aimbotMobileSmooth * 100 + 0.5) end,
    function(v) Settings.aimbotMobileSmooth = v / 100 end, C.fov_mob)

local sec3 = createSection(aimbotFrame, "Targeting")
local partRow = Instance.new("Frame", sec3)
partRow.BackgroundColor3 = Color3.fromRGB(18,18,32)
partRow.Size = UDim2.new(1,0,0,36)
partRow.LayoutOrder = takeOrder(sec3)
Instance.new("UICorner", partRow).CornerRadius = UDim.new(0,6)

local partLabel = Instance.new("TextLabel", partRow)
partLabel.Text = "Часть тела:"
partLabel.Font = Enum.Font.Gotham
partLabel.TextSize = 11
partLabel.TextColor3 = C.text
partLabel.BackgroundTransparency=1
partLabel.Position = UDim2.new(0,12,0,0)
partLabel.Size = UDim2.new(0.4,0,1,0)
partLabel.TextXAlignment = Enum.TextXAlignment.Left

local partVal = Instance.new("TextLabel", partRow)
partVal.Font = Enum.Font.GothamBold
partVal.TextSize = 11
partVal.TextColor3 = C.accent
partVal.BackgroundTransparency=1
partVal.Position = UDim2.new(0.4,0,0,0)
partVal.Size = UDim2.new(0.3,0,1,0)
partVal.TextXAlignment = Enum.TextXAlignment.Left
partVal.Text = Settings.aimPart

local partBtn = Instance.new("TextButton", partRow)
partBtn.Text = "Сменить"
partBtn.Font = Enum.Font.Gotham
partBtn.TextSize = 10
partBtn.TextColor3 = C.accent
partBtn.BackgroundColor3 = Color3.fromRGB(30,30,50)
partBtn.AnchorPoint = Vector2.new(1,0.5)
partBtn.Position = UDim2.new(1,-10,0.5,0)
partBtn.Size = UDim2.new(0,70,0,22)
partBtn.AutoButtonColor = false
Instance.new("UICorner", partBtn).CornerRadius = UDim.new(0,4)
partBtn.MouseButton1Click:Connect(function()
    if Settings.aimPart == "Head" then Settings.aimPart = "Chest" else Settings.aimPart = "Head" end
    partVal.Text = Settings.aimPart
end)

createSliderEx(sec3, "Prediction", 0, 30,
    function() return math.floor(Settings.aimPrediction * 100 + 0.5) end,
    function(v) Settings.aimPrediction = v / 100 end, C.accent)

-- 2. ESP
local espFrame = TabFrames["ESP"]
local secESP = createSection(espFrame, "General")
createToggleEx(secESP, "眼", "Enable ESP", "Показывать информацию о игроках", Color3.fromRGB(80,170,255),
    function() return Settings.espEnabled end,
    function()
        Settings.espEnabled = not Settings.espEnabled
        if Settings.espEnabled then enableESP() else disableESP() end
    end)

createToggleEx(secESP, "銀", "Bank ESP", "Подсветка банка + таймер ограбления", C.bank_col,
    function() return Settings.bankESP end,
    function()
        Settings.bankESP = not Settings.bankESP
        if Settings.bankESP then enableBankESP() else disableBankESP() end
    end)

local secESP2 = createSection(espFrame, "Roles to display")
for roleName, data in pairs(Settings.espRoles) do
    createRoleToggleEx(secESP2, roleName, data.color, false)
end

local secESP3 = createSection(espFrame, "Role source")
local srcRow = Instance.new("Frame", secESP3)
srcRow.BackgroundColor3 = Color3.fromRGB(18,18,32)
srcRow.Size = UDim2.new(1,0,0,36)
srcRow.LayoutOrder = takeOrder(secESP3)
Instance.new("UICorner", srcRow).CornerRadius = UDim.new(0,6)

local srcLabel = Instance.new("TextLabel", srcRow)
srcLabel.Text = "Источник:"
srcLabel.Font = Enum.Font.Gotham
srcLabel.TextSize = 11
srcLabel.TextColor3 = C.text
srcLabel.BackgroundTransparency=1
srcLabel.Position = UDim2.new(0,12,0,0)
srcLabel.Size = UDim2.new(0.3,0,1,0)
srcLabel.TextXAlignment = Enum.TextXAlignment.Left

local srcVal = Instance.new("TextLabel", srcRow)
srcVal.Font = Enum.Font.GothamBold
srcVal.TextSize = 11
srcVal.TextColor3 = C.accent
srcVal.BackgroundTransparency=1
srcVal.Position = UDim2.new(0.3,0,0,0)
srcVal.Size = UDim2.new(0.4,0,1,0)
srcVal.TextXAlignment = Enum.TextXAlignment.Left
srcVal.Text = Settings.espRoleSource

local srcBtn = Instance.new("TextButton", srcRow)
srcBtn.Text = "Сменить"
srcBtn.Font = Enum.Font.Gotham
srcBtn.TextSize = 10
srcBtn.TextColor3 = C.accent
srcBtn.BackgroundColor3 = Color3.fromRGB(30,30,50)
srcBtn.AnchorPoint = Vector2.new(1,0.5)
srcBtn.Position = UDim2.new(1,-10,0.5,0)
srcBtn.Size = UDim2.new(0,70,0,22)
srcBtn.AutoButtonColor = false
Instance.new("UICorner", srcBtn).CornerRadius = UDim.new(0,4)

local sources = {"Team", "Value", "Tag"}
local srcIdx = 1
for i, s in ipairs(sources) do if s == Settings.espRoleSource then srcIdx = i end end
srcBtn.MouseButton1Click:Connect(function()
    srcIdx = srcIdx % #sources + 1
    Settings.espRoleSource = sources[srcIdx]
    srcVal.Text = sources[srcIdx]
    refreshESP()
end)

-- 3. Targets
local targetsFrame = TabFrames["Targets"]
local secT = createSection(targetsFrame, "Allowed Teams for Aimbot")
for roleName, data in pairs(Settings.espRoles) do
    createRoleToggleEx(secT, roleName, data.color, true)
end

-- 4. Visuals
local visualsFrame = TabFrames["Visuals"]
local secV = createSection(visualsFrame, "FOV Circle Colors")
local info = Instance.new("TextLabel", secV)
info.Text = "Круги FOV: PC — красный, Mobile — оранжевый. Банк — золотой. Всё рисуется без внешних ассетов."
info.Font = Enum.Font.Gotham
info.TextSize = 11
info.TextColor3 = C.subtext
info.BackgroundTransparency = 1
info.Size = UDim2.new(1,0,0,20)
info.TextWrapped = true
info.LayoutOrder = takeOrder(secV)

-- 5. Misc
local miscFrame = TabFrames["Misc"]
local secM = createSection(miscFrame, "Utilities")
createButtonEx(secM, "回", "Rejoin", "Переподключиться к серверу", C.danger, function()
    task.delay(0.3, rejoin)
end)

createButtonEx(secM, "滅", "Unload Cheat", "Вырубает все функции и полностью убивает чит. K не работает. Повторная активация — только заново через эксплойт.", C.danger, function()
    task.delay(0.25, unloadCheat)
end)

-- 6. Settings
local settingsFrame = TabFrames["Settings"]
local secS = createSection(settingsFrame, "Information")
local info2 = Instance.new("TextLabel", secS)
info2.Text = "霓 Neonation WH Menu v2.4\nBank ESP: авто-поиск банка (bank, puente, banco), отображение статуса/таймера"
info2.Font = Enum.Font.Gotham
info2.TextSize = 11
info2.TextColor3 = C.text
info2.BackgroundTransparency = 1
info2.Size = UDim2.new(1,0,0,40)
info2.TextWrapped = true
info2.LayoutOrder = takeOrder(secS)

local function selectDefaultTab()
    if tabSelects["Aimbot"] then tabSelects["Aimbot"]() end
end

-- ══════════════════════════════════════════════════════════════
--  OPEN / CLOSE
-- ══════════════════════════════════════════════════════════════
local isOpen = false

local function openMenu()
    isOpen = true
    MainFrame.Visible = true
    TweenService:Create(Blur, TweenInfo.new(0.25), { Size = 6 }):Play()
    TweenService:Create(MainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 860, 0, 580), BackgroundTransparency = 0,
    }):Play()
    TweenService:Create(MainStroke, TweenInfo.new(0.3), { Transparency = 0.15 }):Play()
    if not CurrentTab then selectDefaultTab() end
end

local function closeMenu()
    isOpen = false
    TweenService:Create(Blur, TweenInfo.new(0.2), { Size = 0 }):Play()
    TweenService:Create(MainStroke, TweenInfo.new(0.15), { Transparency = 0.9 }):Play()
    local t = TweenService:Create(MainFrame,
        TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In),
        { Size = UDim2.new(0, 860, 0, 0), BackgroundTransparency = 1 })
    t:Play()
    t.Completed:Once(function() MainFrame.Visible = false end)
end

CloseBtn.MouseButton1Click:Connect(closeMenu)
CloseBtn.MouseEnter:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.1), { BackgroundColor3 = C.danger, TextColor3 = Color3.new(1,1,1) }):Play()
end)
CloseBtn.MouseLeave:Connect(function()
    TweenService:Create(CloseBtn, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(30,30,50), TextColor3 = C.subtext }):Play()
end)

-- Сохраняем все соединения для анлоада
local function addConnection(cn)
    LIVE[#LIVE+1] = cn
end

addConnection(UserInputService.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.K then
        if isOpen then closeMenu() else openMenu() end
    end
end))

local pv, pd = 0.15, 1
addConnection(RunService.Heartbeat:Connect(function(dt)
    if not isOpen then return end
    pv = pv + pd * dt * 0.4
    if pv >= 0.6 then pd = -1 end
    if pv <= 0.05 then pd = 1 end
    MainStroke.Transparency = pv
end))

local ang = 0
addConnection(RunService.Heartbeat:Connect(function(dt)
    ang = (ang + dt * 20) % 360
    titleGrad.Rotation = ang
end))

local dragging, dStart, dPos
addConnection(TopBar.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dStart = inp.Position; dPos = MainFrame.Position
    end
end))
addConnection(TopBar.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end))
addConnection(UserInputService.InputChanged:Connect(function(inp)
    if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
        local d = inp.Position - dStart
        MainFrame.Position = UDim2.new(dPos.X.Scale, dPos.X.Offset+d.X, dPos.Y.Scale, dPos.Y.Offset+d.Y)
    end
end))

-- Автооткрытие для теста (можно убрать)
task.delay(0.5, openMenu)
print("霓 Neonation WH Menu v2.4 loaded — Press K to toggle")
