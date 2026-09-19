--[[
    Skider Hub V4 - Rebuilt with Fluent UI
    Original: kaiv4.lua
    Integrated modules: 3tn.lua (Tween speed = 150, BringMob, FastAttack)
    Bug fixes & Missing definitions: ngu.md
]]

repeat task.wait() until game:IsLoaded() and game:GetService("Players").LocalPlayer

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer

-- Auto Join Team (Marines hoặc Pirates, mặc định Marines)
local function autoJoinTeam()
    local targetTeam = "Marines"
    pcall(function()
        local lp = Players.LocalPlayer
        local u = lp and lp.Name
        if type(getgenv().AccountConfigs) == "table" and u and type(getgenv().AccountConfigs[u]) == "table" and getgenv().AccountConfigs[u]["Select Team"] then
            targetTeam = getgenv().AccountConfigs[u]["Select Team"]
        elseif type(getgenv().Config) == "table" then
            if u and type(getgenv().Config[u]) == "table" and getgenv().Config[u]["Select Team"] then
                targetTeam = getgenv().Config[u]["Select Team"]
            elseif getgenv().Config["Select Team"] then
                targetTeam = getgenv().Config["Select Team"]
            elseif getgenv().Config["Team"] then
                targetTeam = getgenv().Config["Team"]
            end
        end
    end)
    if targetTeam == "Marine" then targetTeam = "Marines" end
    if targetTeam == "Pirate" then targetTeam = "Pirates" end

    local lp = Players.LocalPlayer or Players.PlayerAdded:Wait()
    if lp and lp.Team and lp.Team.Name == targetTeam then
        return true
    end

    local startTime = tick()
    repeat
        task.wait(0.25)
        pcall(function()
            ReplicatedStorage.Remotes.CommF_:InvokeServer("SetTeam", targetTeam)
        end)
        pcall(function()
            local pGui = lp:FindFirstChild("PlayerGui")
            if pGui then
                local chooseTeam = pGui:FindFirstChild("ChooseTeam", true)
                if chooseTeam and chooseTeam.Visible then
                    local teamPart = chooseTeam:FindFirstChild(targetTeam, true)
                    if teamPart then
                        local btn = teamPart:FindFirstChildWhichIsA("TextButton", true) or teamPart:FindFirstChildWhichIsA("ImageButton", true)
                        if btn then
                            for _, conn in pairs(getconnections(btn.MouseButton1Click or btn.Activated)) do
                                conn.Function()
                            end
                        end
                    end
                end
                local uiController = pGui:FindFirstChild("UIController", true)
                if uiController and getgc and getconstants then
                    for _, v in pairs(getgc(true)) do
                        if type(v) == "function" and getfenv(v).script == uiController then
                            local c = getconstants(v)
                            if (c[1] == "Pirates" or c[1] == "Marines") and #c == 1 and c[1] == targetTeam then
                                v(targetTeam)
                            end
                        end
                    end
                end
            end
        end)
    until (lp and lp.Team and lp.Team.Name == targetTeam) or (tick() - startTime > 12)
    return (lp and lp.Team and lp.Team.Name == targetTeam)
end

autoJoinTeam()

--------------------------------------------------------------------------------
-- 1. FLUENT UI INITIALIZATION
--------------------------------------------------------------------------------
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Skider Hub V4",
    SubTitle = "create by biee_dungbuon",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    StatusServer = Window:AddTab({ Title = "Status & Server", Icon = "activity" }),
    RaceNormal   = Window:AddTab({ Title = "Race Normal", Icon = "user" }),
    RaceV4       = Window:AddTab({ Title = "Race V4", Icon = "sparkles" }),
    KillTrial    = Window:AddTab({ Title = "Kill Trial", Icon = "swords" }),
    Settings     = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

-- Backward compatibility for notifications
local uiLibrary = {
    CreateNoti = function(params)
        Fluent:Notify({
            Title = params.Title or "Skider Hub V4",
            Content = params.Desc or "",
            Duration = params.ShowTime or 5
        })
    end
}

--------------------------------------------------------------------------------
-- FLOATING TOGGLE BUTTON (Nút hình vuông bo tròn góc trái dưới màn hình)
--------------------------------------------------------------------------------
local toggleScreenGui = Instance.new("ScreenGui")
toggleScreenGui.Name = "SkiderV4ToggleGUI"
toggleScreenGui.ResetOnSpawn = false
toggleScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
toggleScreenGui.Parent = (gethui and gethui()) or cloneref(game:GetService("CoreGui"))

local toggleBtn = Instance.new("ImageButton", toggleScreenGui)
toggleBtn.Name = "ToggleUIBtn"
toggleBtn.AnchorPoint = Vector2.new(0, 1)
toggleBtn.Position = UDim2.new(0, 18, 1, -18)
toggleBtn.Size = UDim2.new(0, 75, 0, 75)
toggleBtn.BackgroundTransparency = 1
toggleBtn.BorderSizePixel = 0
toggleBtn.Image = "rbxassetid://90412962524051"
toggleBtn.ScaleType = Enum.ScaleType.Fit
toggleBtn.AutoButtonColor = false
toggleBtn.ZIndex = 100

local toggleCorner = Instance.new("UICorner", toggleBtn)
toggleCorner.CornerRadius = UDim.new(0, 15)

-- Hỗ trợ kéo thả nút (Draggable) trên PC & Mobile
local dragging = false
local dragInput, dragStart, startPos

local function updateDrag(input)
    local delta = input.Position - dragStart
    toggleBtn.Position = UDim2.new(
        startPos.X.Scale,
        startPos.X.Offset + delta.X,
        startPos.Y.Scale,
        startPos.Y.Offset + delta.Y
    )
end

toggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = toggleBtn.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

toggleBtn.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        updateDrag(input)
    end
end)

-- Sự kiện Click bật/tắt UI (Tác dụng y hệt bấm phím LeftControl của Fluent UI)
local toggleDebounce = false
local function onToggleActivated()
    if dragging then return end
    if toggleDebounce then return end
    toggleDebounce = true

    -- Kích hoạt chuẩn cơ chế toggle của Fluent UI như khi bấm phím LeftControl
    pcall(function()
        if Window and type(Window.Minimize) == "function" then
            Window:Minimize()
        else
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
            task.wait(0.02)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
        end
    end)

    -- Hiệu ứng nhún (bounce animation) khi bấm
    local shrink = TweenService:Create(toggleBtn, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 64, 0, 64)
    })
    shrink:Play()
    shrink.Completed:Wait()
    TweenService:Create(toggleBtn, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 75, 0, 75)
    }):Play()
    toggleDebounce = false
end

toggleBtn.Activated:Connect(onToggleActivated)

--------------------------------------------------------------------------------
-- 2. GLOBAL SETTINGS & STATE INITIALIZATION (ngu.md Section 1)
--------------------------------------------------------------------------------
getgenv().Settings = getgenv().Settings or {}
local Settings = getgenv().Settings

local configFolder = "Mtrchill"
local lp = Players.LocalPlayer or Players.PlayerAdded:Wait()
while not lp or not lp.Name or lp.Name == "" do
    task.wait(0.05)
    lp = Players.LocalPlayer
end
local username = lp.Name
local configFilePath = configFolder .. "/" .. username .. "-kaiv4.json"

-- Tải cấu hình từ file JSON theo username người chơi
local function LoadConfigFile()
    if isfile and readfile and isfile(configFilePath) then
        local success, content = pcall(readfile, configFilePath)
        if success and content and #content > 0 then
            local ok, data = pcall(function()
                return HttpService:JSONDecode(content)
            end)
            if ok and type(data) == "table" then
                for k, v in pairs(data) do
                    Settings[k] = v
                end
            end
        end
    end
end

-- 1. Nạp file cấu hình đã lưu trước đó từ thư mục Mtrchill/<username>-kaiv4.json (nếu có)
LoadConfigFile()

-- 2. Nạp cấu hình từ config.lua (getgenv().Config hoặc getgenv().AccountConfigs)
-- Ưu tiên ghi đè nếu người dùng vừa thiết lập trong config.lua
if type(getgenv().AccountConfigs) == "table" and type(getgenv().AccountConfigs[username]) == "table" then
    for k, v in pairs(getgenv().AccountConfigs[username]) do
        Settings[k] = v
    end
elseif type(getgenv().Config) == "table" then
    if type(getgenv().Config[username]) == "table" then
        for k, v in pairs(getgenv().Config[username]) do
            Settings[k] = v
        end
    else
        for k, v in pairs(getgenv().Config) do
            Settings[k] = v
        end
    end
end

local function WriteConfigFile()
    if not writefile then return end
    pcall(function()
        if makefolder and isfolder and not isfolder(configFolder) then
            makefolder(configFolder)
        end
        local encoded = HttpService:JSONEncode(Settings)
        writefile(configFilePath, encoded)
    end)
end

-- 3. Tự động lưu lại cấu hình mới nhất vào file Mtrchill/<username>-kaiv4.json
WriteConfigFile()

local function SaveSettings(key, value, value2)
    Settings[key] = value
    if value2 ~= nil and type(value) == "table" then
        Settings[key] = value
    end
    if type(getgenv().Config) == "table" then
        if type(getgenv().Config[username]) == "table" then
            getgenv().Config[username][key] = value
        else
            getgenv().Config[key] = value
        end
    end
    WriteConfigFile()
end

local items3 = {}
local items6 = {
    "Swan Pirate",
    "Forest Pirate",
    "Mythological Pirate",
    "Dragon Crew Warrior",
    "Dragon Crew Archer",
    "Jungle Pirate",
    "Musketeer Pirate",
    "Reborn Skeleton",
    "Living Zombie",
    "Demonic Soul",
    "Posessed Mummy"
}

getgenv().Chests = getgenv().Chests or {}
getgenv().BlBossHuman = getgenv().BlBossHuman or {}
local BlBossHuman = getgenv().BlBossHuman

getgenv().TempleProgress = getgenv().TempleProgress or { value = 0, checked = 0 }
local TempleProgress = getgenv().TempleProgress

local TempleTeleporting = false
getgenv().TurnOffHOPSVPullAndTrial = nil
getgenv().VerifyTrial = false
getgenv().TrialDone = false
getgenv().KillAuraDone = false
getgenv().PlayerKillTrial = {}
getgenv().BlackListPlayerTrial = {}
getgenv().DelayHop = false
getgenv().AimPos = nil
getgenv().CheckPlaceId2 = getgenv().CheckPlaceId2 or 4442272183

local items16, items17 = {}, {}
local items18 = { "Last Resort", "Agility", "Water Body", "Heavenly Blood", "Energy Core", "Heightened Senses" }

--------------------------------------------------------------------------------
-- 3. CORE MODULES FROM 3tn.lua (Tween = 150, BringMob, FastAttack)
--------------------------------------------------------------------------------

-- [TWEEN MODULE] Speed locked at 150 according to requirements
local TweenManager = {}
local CurrentTween = nil
local TWEEN_SPEED = 150 -- TOÀN BỘ TWEEN ĐỀU Ở 150

function TweenManager.CancelCurrent()
    if CurrentTween then
        pcall(function() CurrentTween:Cancel() end)
        CurrentTween = nil
    end
end

function ToTarget(targetCFrame, skipTween)
    local char = localPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local head = char:FindFirstChild("Head") or hrp
    if not head:FindFirstChild("eltrul") then
        local bv = Instance.new("BodyVelocity")
        bv.Name = "eltrul"
        bv.MaxForce = Vector3.new(0, math.huge, 0)
        bv.Velocity = Vector3.zero
        bv.Parent = head
    end

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end

    local targetPos = typeof(targetCFrame) == "CFrame" and targetCFrame.Position or targetCFrame
    local targetCF = typeof(targetCFrame) == "CFrame" and targetCFrame or CFrame.new(targetPos)
    local dist = (hrp.Position - targetPos).Magnitude

    if skipTween or dist <= 15 then
        TweenManager.CancelCurrent()
        hrp.CFrame = targetCF
        return
    end

    TweenManager.CancelCurrent()
    local tweenDuration = dist / TWEEN_SPEED
    local tweenInfo = TweenInfo.new(tweenDuration, Enum.EasingStyle.Linear)
    CurrentTween = TweenService:Create(hrp, tweenInfo, { CFrame = targetCF })
    CurrentTween:Play()
    return CurrentTween
end

-- [BRING MOB MODULE] From 3tn.lua CombatController.Grab
function BringMob(Mob)
    pcall(sethiddenproperty, localPlayer, "SimulationRadius", math.huge)
    if not Mob or not Mob:FindFirstChild("HumanoidRootPart") then return end
    local targetName = Mob.Name
    local hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    for _, enemy in ipairs(Workspace.Enemies:GetChildren()) do
        if enemy.Name == targetName and enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 and enemy:FindFirstChild("HumanoidRootPart") then
            if isnetworkowner and isnetworkowner(enemy.PrimaryPart or enemy.HumanoidRootPart) then
                local rootPart = enemy.HumanoidRootPart
                local bv = rootPart:FindFirstChild("FarmingVelocity")
                if not bv then
                    bv = Instance.new("BodyVelocity")
                    bv.Name = "FarmingVelocity"
                    bv.MaxForce = Vector3.new(4000, 4000, 4000)
                    bv.Velocity = Vector3.zero
                    bv.Parent = rootPart
                end

                local bp = rootPart:FindFirstChild("FarmingPosition")
                if not bp then
                    bp = Instance.new("BodyPosition")
                    bp.Name = "FarmingPosition"
                    bp.MaxForce = Vector3.new(4000, 4000, 4000)
                    bp.P = 4.12
                    bp.D = 1000
                    bp.Parent = rootPart
                end

                enemy:SetAttribute("IsGrabbed", true)
                local midPos = hrp.CFrame * CFrame.new(0, 0, -5)
                rootPart.CFrame = midPos
                bp.Position = midPos.Position
            end
        end
    end
end

-- [FAST ATTACK MODULE] From 3tn.lua
local Net = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
local RegisterAttack = Net:WaitForChild("RE/RegisterAttack")
local RegisterHit = Net:WaitForChild("RE/RegisterHit")

local FastAttack = {}
FastAttack.__index = FastAttack
function FastAttack.new()
    local self = setmetatable({
        Debounce = 0,
        ComboDebounce = 0,
        EnemyRootPart = nil
    }, FastAttack)
    pcall(function()
        local Modules = ReplicatedStorage:WaitForChild("Modules")
        self.CombatFlags = require(Modules.Flags).COMBAT_REMOTE_THREAD
        local LocalScript = localPlayer:WaitForChild("PlayerScripts"):FindFirstChildOfClass("LocalScript")
        if LocalScript and getsenv then
            self.HitFunction = getsenv(LocalScript)._G.SendHitsToServer
        end
    end)
    return self
end

function FastAttack:IsEntityAlive(entity)
    local humanoid = entity and entity:FindFirstChild("Humanoid")
    return humanoid and humanoid.Health > 0
end

function FastAttack:GetBladeHits(Character, Distance)
    Distance = Distance or 60
    local Position = Character:GetPivot().Position
    local BladeHits = {}
    for _, Enemy in ipairs(Workspace.Enemies:GetChildren()) do
        if Enemy ~= Character and self:IsEntityAlive(Enemy) then
            local BasePart = Enemy:FindFirstChild("HumanoidRootPart")
            if BasePart and (Position - BasePart.Position).Magnitude <= Distance then
                if not self.EnemyRootPart then
                    self.EnemyRootPart = BasePart
                else
                    table.insert(BladeHits, {Enemy, BasePart})
                    table.insert(BladeHits, {})
                end
            end
        end
    end
    return BladeHits
end

function FastAttack:Attack()
    if (tick() - self.Debounce) < 0.05 then return end
    self.Debounce = tick()
    local char = localPlayer.Character
    if not char or not self:IsEntityAlive(char) then return end
    local equipped = char:FindFirstChildOfClass("Tool")
    if not equipped then return end

    self.EnemyRootPart = nil
    local BladeHits = self:GetBladeHits(char, 60)
    if self.EnemyRootPart then
        pcall(function()
            RegisterAttack:FireServer(0.05)
            if self.CombatFlags and self.HitFunction then
                self.HitFunction(self.EnemyRootPart, BladeHits)
            else
                RegisterHit:FireServer(self.EnemyRootPart, BladeHits)
            end
        end)
    end
end

local fastAttackInstance = FastAttack.new()

function ClickM1(target)
    fastAttackInstance:Attack()
end

getgenv().AttackFunctionnhungSuperTrial = function()
    fastAttackInstance:Attack()
end

--------------------------------------------------------------------------------
-- 4. MISSING HELPER FUNCTIONS (ngu.md Section 2)
--------------------------------------------------------------------------------

function GoToSea(placeId)
    if not placeId or game.PlaceId == placeId then
        return true
    end
    if placeId == 4442272183 and game.PlaceId ~= 4442272183 then
        ReplicatedStorage.Remotes.CommF_:InvokeServer("TravelDressrosa")
        return false
    elseif placeId == 7449423635 and game.PlaceId ~= 7449423635 then
        ReplicatedStorage.Remotes.CommF_:InvokeServer("TravelZou")
        return false
    elseif placeId == 2753915549 and game.PlaceId ~= 2753915549 then
        ReplicatedStorage.Remotes.CommF_:InvokeServer("TravelMain")
        return false
    end
    return true
end

function HopServer()
    task.spawn(function()
        local sb = ReplicatedStorage:FindFirstChild("__ServerBrowser") or ReplicatedStorage:WaitForChild("__ServerBrowser", 5)
        if not sb then return end
        for page = 1, 100 do
            local ok, servers = pcall(function()
                return sb:InvokeServer(page)
            end)
            if ok and type(servers) == "table" and next(servers) ~= nil then
                local valid = {}
                for jid, data in pairs(servers) do
                    local jStr = tostring(jid or "")
                    if jStr ~= "" and jStr ~= tostring(game.JobId) then
                        local count = type(data) == "table" and tonumber(data.Count or data.count or data.playing) or 0
                        if count and count < (Players.MaxPlayers or 12) then
                            table.insert(valid, jStr)
                        end
                    end
                end
                if #valid > 0 then
                    local target = valid[math.random(1, #valid)]
                    pcall(function()
                        sb:InvokeServer("teleport", target)
                    end)
                    return
                end
            end
            task.wait(0.05)
        end
    end)
end

function HopLessAll()
    HopServer()
end

function SpecialHop(targetName)
    HopServer()
end

function TeleportSeaEvents(mob)
    if mob and mob:FindFirstChild("HumanoidRootPart") then
        ToTarget(mob.HumanoidRootPart.CFrame * CFrame.new(0, 50, 0))
    end
end

function BorrowTempleOfTime()
    if not Workspace:FindFirstChild("Map") then return end
    if not Workspace.Map:FindFirstChild("Temple of Time") then
        if ReplicatedStorage:FindFirstChild("MapStash") and ReplicatedStorage.MapStash:FindFirstChild("Temple of Time") then
            ReplicatedStorage.MapStash["Temple of Time"].Parent = Workspace.Map
        end
    end
end

function GetTempleOfTime()
    BorrowTempleOfTime()
    return Workspace.Map:FindFirstChild("Temple of Time")
end

function IsInTempleOfTime()
    local hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    return (hrp.Position - Vector3.new(28286.35546875, 14896.5078125, 102.62469482422)).Magnitude < 3000
end

local topOfGreatTree = CFrame.new(3028, 2281, -7325)
local TEMPLE_ENTRY_POS = Vector3.new(28310.0234, 14895.1123, 109.456741)

function TeleportTempleOfTime()
    BorrowTempleOfTime()
    if IsInTempleOfTime() then
        return "arrived"
    end

    -- 1. Kiem tra Sea: Temple of Time chi ton tai o Sea 3 (Zou)
    local mapAttr = Workspace:GetAttribute("MAP")
    if mapAttr and mapAttr ~= "Sea3" and game.PlaceId ~= 7449423635 then
        uiLibrary.CreateNoti({ Title = "Skider Hub V4", Desc = "Can o Third Sea (Sea 3) de vao Temple of Time!", ShowTime = 5 })
        return "wrong_sea"
    end

    local hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return "no_character" end

    -- 2. Thu requestEntrance truc tiep truoc
    pcall(function()
        ReplicatedStorage.Remotes.CommF_:InvokeServer("requestEntrance", TEMPLE_ENTRY_POS)
    end)
    task.wait(0.5)
    if IsInTempleOfTime() then
        return "arrived"
    end

    -- 3. Xu ly tien trinh RaceV4Progress (NPC Ancient One)
    local v4Ok, v4Status = pcall(function()
        return ReplicatedStorage.Remotes.CommF_:InvokeServer("RaceV4Progress", "Check")
    end)

    if v4Ok and type(v4Status) == "number" then
        if v4Status == 1 then
            pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("RaceV4Progress", "Begin") end)
            task.wait(0.5)
        elseif v4Status == 2 then
            pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("RaceV4Progress", "Teleport") end)
            task.wait(0.5)
            if IsInTempleOfTime() then
                return "arrived"
            end
        elseif v4Status == 3 then
            pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("RaceV4Progress", "Continue") end)
            task.wait(0.5)
        end
    end

    -- 4. Neu chua vao duoc, server Blox Fruits yeu cau nhan vat phai dung o Dinh Cay Co Thu (Great Tree)
    local distToTree = (hrp.Position - topOfGreatTree.Position).Magnitude
    if distToTree > 30 then
        ToTarget(topOfGreatTree)
        return "moving_to_tree"
    end

    -- Da o dinh cay co thu -> kich hoat cong teleport vao den
    pcall(function()
        ReplicatedStorage.Remotes.CommF_:InvokeServer("RaceV4Progress", "Teleport")
    end)
    task.wait(0.5)
    pcall(function()
        ReplicatedStorage.Remotes.CommF_:InvokeServer("requestEntrance", TEMPLE_ENTRY_POS)
    end)
    task.wait(0.8)

    if IsInTempleOfTime() then
        return "arrived"
    end

    -- 5. Kiem tra race: neu nguoi choi chua dat V3 thi khong the mo V4
    local currentRaceState = CheckRace()
    if currentRaceState == " V1" or currentRaceState == " V2" then
        return "locked"
    end

    return "in_progress"
end

function DetectMob(nameOrTable)
    local hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
    local nearest, minDist = nil, math.huge
    for _, v in ipairs(Workspace.Enemies:GetChildren()) do
        local match = false
        if type(nameOrTable) == "table" then
            match = table.find(nameOrTable, v.Name) ~= nil
        else
            match = (v.Name == nameOrTable)
        end
        if match and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 and v:FindFirstChild("HumanoidRootPart") then
            local dist = hrp and (v.HumanoidRootPart.Position - hrp.Position).Magnitude or 0
            if dist < minDist then
                minDist = dist
                nearest = v
            end
        end
    end
    return nearest
end

function DetectNpc(name)
    if Workspace:FindFirstChild("NPCs") then
        for _, v in ipairs(Workspace.NPCs:GetChildren()) do
            if v.Name == name and v:FindFirstChild("HumanoidRootPart") then
                return v
            end
        end
    end
    if ReplicatedStorage:FindFirstChild("NPCs") then
        for _, v in ipairs(ReplicatedStorage.NPCs:GetChildren()) do
            if v.Name == name and v:FindFirstChild("HumanoidRootPart") then
                return v
            end
        end
    end
    return nil
end

function CheckNameBoss(name)
    for _, v in ipairs(Workspace.Enemies:GetChildren()) do
        if v.Name == name and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 and v:FindFirstChild("HumanoidRootPart") then
            return v
        end
    end
    for _, v in ipairs(ReplicatedStorage:GetChildren()) do
        if v.Name == name and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 and v:FindFirstChild("HumanoidRootPart") then
            return v
        end
    end
    return nil
end

function DetectPartSpawnMob(name, bool)
    if not Workspace:FindFirstChild("_WorldOrigin") or not Workspace._WorldOrigin:FindFirstChild("EnemySpawns") then
        return nil
    end
    for _, v in ipairs(Workspace._WorldOrigin.EnemySpawns:GetChildren()) do
        if string.find(v.Name, name) or v.Name == name then
            if bool and v:FindFirstChild("Ignored") then
                -- skip
            else
                return v
            end
        end
    end
    return nil
end

function DetectNameTablePart(tbl)
    if type(tbl) ~= "table" then return tbl end
    for _, name in ipairs(tbl) do
        if not table.find(items3, name) then
            return name
        end
    end
    return tbl[1]
end

function DeleteIgnoredMobSpawn()
    if Workspace:FindFirstChild("_WorldOrigin") and Workspace._WorldOrigin:FindFirstChild("EnemySpawns") then
        for _, v in ipairs(Workspace._WorldOrigin.EnemySpawns:GetChildren()) do
            local ign = v:FindFirstChild("Ignored")
            if ign then ign:Destroy() end
        end
    end
end

function IsMobAlive(mob)
    return mob and mob.Parent and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 and mob:FindFirstChild("HumanoidRootPart")
end

function SizePart(mob)
    if mob and mob:FindFirstChild("HumanoidRootPart") then
        mob.HumanoidRootPart.Size = Vector3.new(60, 60, 60)
        mob.HumanoidRootPart.CanCollide = false
        if mob:FindFirstChild("Humanoid") then
            mob.Humanoid.WalkSpeed = 0
            mob.Humanoid.JumpPower = 0
        end
    end
end

function EquipTool(name)
    if not name then return end
    local char = localPlayer.Character
    if not char or not char:FindFirstChild("Humanoid") then return end
    for _, tool in ipairs(localPlayer.Backpack:GetChildren()) do
        if tool:IsA("Tool") and (tool.Name == name or tool.ToolTip == name) then
            char.Humanoid:EquipTool(tool)
            return
        end
    end
end

function NameWeapon(weaponType)
    weaponType = weaponType or Settings["Select Weapon"] or "Melee"
    for _, tool in ipairs(localPlayer.Backpack:GetChildren()) do
        if tool:IsA("Tool") and (tool.ToolTip == weaponType or tool.Name == weaponType) then
            return tool.Name
        end
    end
    if localPlayer.Character then
        for _, tool in ipairs(localPlayer.Character:GetChildren()) do
            if tool:IsA("Tool") and (tool.ToolTip == weaponType or tool.Name == weaponType) then
                return tool.Name
            end
        end
    end
    return weaponType
end

function UsedualFlock()
    local char = localPlayer.Character
    if char and not char:FindFirstChild("HasBuso") then
        ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso")
    end
end

function AutoAllSkill(pvp)
    local skills = {"Z", "X", "C", "V", "F"}
    for _, k in ipairs(skills) do
        VirtualInputManager:SendKeyEvent(true, k, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, k, false, game)
    end
end

function GetNearestChest()
    local nearest, minDist = nil, 99999
    local hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    for _, v in ipairs(Workspace:GetDescendants()) do
        if (v.Name == "Chest1" or v.Name == "Chest2" or v.Name == "Chest3") and v:IsA("BasePart") and v.CanTouch and not v:FindFirstChild("Ignored") and not v:GetAttribute("IsDisabled") then
            local dist = (v.Position - hrp.Position).Magnitude
            if dist < minDist then
                minDist = dist
                nearest = v
            end
        end
    end
    return nearest
end

function PathFindChest()
    local chest = GetNearestChest()
    if chest then
        return { Part = chest }
    end
    return nil
end

function DetectItemPlr(name)
    local backpack = localPlayer.Backpack:FindFirstChild(name)
    local char = localPlayer.Character and localPlayer.Character:FindFirstChild(name)
    return (backpack ~= nil or char ~= nil)
end

function CheckCountItem(name, count)
    local item = localPlayer.Backpack:FindFirstChild(name) or (localPlayer.Character and localPlayer.Character:FindFirstChild(name))
    if item and item:FindFirstChild("Count") then
        return item.Count.Value >= count
    end
    local inv = ReplicatedStorage.Remotes.CommF_:InvokeServer("getInventory")
    if type(inv) == "table" then
        for _, itm in ipairs(inv) do
            if itm.Name == name then
                return (itm.Count or 1) >= count
            end
        end
    end
    return false
end

function CheckItemInventory(name)
    if DetectItemPlr(name) then return true end
    local ok, inv = pcall(function()
        return ReplicatedStorage.Remotes.CommF_:InvokeServer("getInventory")
    end)
    if ok and type(inv) == "table" then
        for _, itm in pairs(inv) do
            if itm.Name == name or (itm.Index and itm.Index.StorageKey == name) then
                return true
            end
        end
    end
    -- Fallback to ItemReplicationService (dành cho Materials / Accessories)
    pcall(function()
        local IRS = require(game:GetService("ReplicatedStorage").ItemReplicationService)
        local KEYS = require(game:GetService("ReplicatedStorage").ItemReplicationService.KEYS)
        local MATCH = require(game:GetService("ReplicatedStorage").ItemConfig.Storage).match
        local data = IRS:GetItems(KEYS.QUANTITY)
        for _, v in pairs(data) do
            local item = MATCH(v.ItemId)._ok
            if item and item.Index and item.Index.StorageKey == name then
                return true
            end
        end
    end)
    return false
end

function CheckFruitplr()
    for _, v in ipairs(localPlayer.Backpack:GetChildren()) do
        if v:IsA("Tool") and v.ToolTip == "Blox Fruit" then return true end
    end
    if localPlayer.Character then
        for _, v in ipairs(localPlayer.Character:GetChildren()) do
            if v:IsA("Tool") and v.ToolTip == "Blox Fruit" then return true end
        end
    end
    return false
end

function TakeFruitInventory(bool)
    local inv = ReplicatedStorage.Remotes.CommF_:InvokeServer("getInventory")
    if type(inv) == "table" then
        for _, itm in ipairs(inv) do
            if itm.Type == "Fruit" or string.find(itm.Name, "Fruit") then
                return itm.Name
            end
        end
    end
    return nil
end

function CheckAcientOneStatus()
    local code, progress = nil, nil
    pcall(function()
        code, progress = ReplicatedStorage.Remotes.CommF_:InvokeServer("UpgradeRace", "Check")
    end)
    if code == 0 then
        return "You Are Ready For Trial [Gear: " .. tostring(progress or 0) .. "]"
    elseif code == 5 then
        return "You Are Done Your Race"
    elseif code == 6 then
        local done = math.clamp((progress or 2) - 2, 0, 3)
        return "Upgrades completed: " .. tostring(done) .. "/3, Need Trains More"
    elseif code == 1 or code == 3 then
        return "Please Train More"
    elseif code == 2 or code == 4 or code == 7 then
        return "You Can Buy Gear"
    elseif code == 8 then
        local rem = math.max(0, 10 - (progress or 0))
        return rem > 0 and ("Mastery (" .. tostring(rem) .. " left)") or "Mastery Done"
    else
        local vp = nil
        pcall(function()
            vp = ReplicatedStorage.Remotes.CommF_:InvokeServer("RaceV4Progress", "Check")
        end)
        if vp and tonumber(vp) and tonumber(vp) >= 4 then
            return "You Are Ready For Trial"
        elseif vp and tonumber(vp) == 0 then
            return "Quest Not Started"
        elseif vp then
            return "Quest " .. tostring(vp) .. "/5"
        end
        return "You have yet to achieve greatness"
    end
end

function ResetRaceStatus()
    getgenv().RaceStatus = nil
end

function TurnOnV4()
    if not localPlayer.Character:FindFirstChild("RaceTransformed") then
        VirtualInputManager:SendKeyEvent(true, "Y", false, game)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, "Y", false, game)
    end
end

function CheckGoTrain()
    local code, progress = nil, nil
    pcall(function()
        code, progress = ReplicatedStorage.Remotes.CommF_:InvokeServer("UpgradeRace", "Check")
    end)
    if code == 1 or code == 3 or code == 6 or (code == 8 and (progress or 0) < 10) then
        return true
    end
    local st = CheckAcientOneStatus()
    return string.find(st, "Train") ~= nil
end

function ChooseGearV4()
    local dt = ReplicatedStorage.Remotes.CommF_:InvokeServer("TempleClock", "Check")
    if dt and dt.HadPoint then
        local gearChoice = Settings["Select Gear V4"] or "Omega"
        local lvl = (dt.RaceDetails and dt.RaceDetails.Completed) or dt.Completed or 1
        local choosegear = (lvl == 1 or lvl == 5) and "Blank" or gearChoice
        ReplicatedStorage.Remotes.CommF_:InvokeServer("TempleClock", "SpendPoint", "Gear" .. tostring(lvl), choosegear)
    end
end

function AutoQuestBarito()
    local res = ReplicatedStorage.Remotes.CommF_:InvokeServer("BartiloQuestProgress")
    if type(res) == "table" then
        if not res.KilledBandits then
            ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", "BartiloQuest", 1)
            local mob = DetectMob("Swan Pirate")
            if mob then
                BringMob(mob)
                SizePart(mob)
                ClickM1(mob)
                ToTarget(mob.HumanoidRootPart.CFrame * CFrame.new(0, 20, 7))
            else
                local sp = DetectPartSpawnMob("Swan Pirate")
                if sp then ToTarget(sp.CFrame * CFrame.new(0, 50, 0)) end
            end
        elseif not res.KilledSpring then
            local boss = CheckNameBoss("Jeremy")
            if boss then
                BringMob(boss)
                SizePart(boss)
                ClickM1(boss)
                ToTarget(boss.HumanoidRootPart.CFrame * CFrame.new(0, 20, 7))
            else
                ToTarget(CFrame.new(2316.0397949219, 448.95474243164, 767.72882080078))
            end
        elseif not res.DidPlates then
            local colosseumCode = {
                CFrame.new(-1836.0, 11, 1714),
                CFrame.new(-1850.49329, 13.1789551, 1750.89685),
                CFrame.new(-1858.87305, 19.3777466, 1712.01807),
                CFrame.new(-1803.94324, 16.5789185, 1750.89685),
                CFrame.new(-1858.55835, 16.8604317, 1724.79541),
                CFrame.new(-1869.54224, 15.987854, 1681.00659),
                CFrame.new(-1800.0979, 16.4978027, 1684.52368),
                CFrame.new(-1819.26343, 14.795166, 1717.90625),
                CFrame.new(-1813.51843, 14.8604736, 1724.79541)
            }
            for _, cf in ipairs(colosseumCode) do
                ToTarget(cf, true)
                task.wait(0.5)
            end
        end
    else
        ReplicatedStorage.Remotes.CommF_:InvokeServer("BartiloQuestProgress")
    end
end

function CheckMoon()
    local mapAttr = Workspace:GetAttribute("MAP")
    local isSea2 = mapAttr == "Sea2" or game.PlaceId == 4442272183
    local t = ""
    if isSea2 and Lighting:FindFirstChild("FantasySky") and Lighting.FantasySky.MoonTextureId then
        t = Lighting.FantasySky.MoonTextureId
    elseif Lighting:FindFirstChild("Sky") and Lighting.Sky.MoonTextureId then
        t = Lighting.Sky.MoonTextureId
    elseif Lighting:FindFirstChild("Space_Skybox") and Lighting.Space_Skybox.MoonTextureId then
        t = Lighting.Space_Skybox.MoonTextureId
    end
    t = t:gsub("rbxassetid://", "http://www.roblox.com/asset/?id=")
    local moonMap = {
        ["http://www.roblox.com/asset/?id=15493317929"] = "Blue Moon",
        ["http://www.roblox.com/asset/?id=9709149431"] = "Full Moon",
        ["http://www.roblox.com/asset/?id=9709149052"] = "7/8",
        ["http://www.roblox.com/asset/?id=9709143733"] = "6/8",
        ["http://www.roblox.com/asset/?id=9709150401"] = "5/8",
        ["http://www.roblox.com/asset/?id=9709135895"] = "4/8",
        ["http://www.roblox.com/asset/?id=9709150086"] = "2/8",
        ["http://www.roblox.com/asset/?id=9709139597"] = "1/8",
        ["http://www.roblox.com/asset/?id=9709149680"] = "0/8",
    }
    if moonMap[t] then return moonMap[t] end
    if Lighting:GetAttribute("MoonPhase") == 5 then return "Full Moon" end
    return "Next Night"
end

function CheckClockTime()
    local ct = Lighting.ClockTime
    if ct >= 17 or ct < 6 then
        return "Night"
    end
    return "Day"
end

function CheckBoat()
    if not Workspace:FindFirstChild("Boats") then return nil end
    for _, boat in ipairs(Workspace.Boats:GetChildren()) do
        if boat:IsA("Model") then
            local owner = boat:FindFirstChild("Owner")
            local hd = boat:FindFirstChild("Humanoid")
            if owner and hd and tostring(owner.Value) == localPlayer.Name and hd.Value > 0 then
                return boat
            end
        end
    end
    return nil
end

function PrepareMultiSelectList(lookup, saved)
    local list = {}
    local seen = {}
    local function add(name)
        if type(name) == "string" and name ~= "" and not seen[name] then
            seen[name] = true
            table.insert(list, name)
        end
    end
    if localPlayer and localPlayer.Name then
        add(localPlayer.Name)
    end
    if type(lookup) == "table" then
        for k, _ in pairs(lookup) do
            add(k)
        end
    end
    if type(saved) == "table" then
        for k, v in pairs(saved) do
            if type(k) == "string" and v == true then
                add(k)
            elseif type(v) == "string" then
                add(v)
            end
        end
    end
    return list
end

--------------------------------------------------------------------------------
-- 5. ORIGINAL BUSINESS LOGIC (from kaiv4.lua - preserved intact)
--------------------------------------------------------------------------------

function AutoMinkV2()
	local part2 = GetNearestChest()
	if part2 then
		local npcNames
		repeat
			task.wait()
			if (localPlayer.Character.HumanoidRootPart.Position - part2.Position).Magnitude <= 5 then
				if not npcNames then
					npcNames = (tick())
				elseif tick() - npcNames >= 5 then
					Instance.new("IntValue", part2).Name = "Ignored"
					wait(0.5)
				end
				VirtualInputManager:SendKeyEvent(true, "Space", false, game)
				wait()
				VirtualInputManager:SendKeyEvent(false, "Space", false, game)
				TweenManager.CancelCurrent()
			end
			ToTarget(part2.CFrame, true)
		until not part2
			or not part2.Parent
			or not Settings["Auto Upgrade Race V2-V3"]
			or (part2:GetAttribute("IsDisabled"))
			or (part2:FindFirstChild("Ignored"))
			or not part2:FindFirstChild("TouchInterest")
	else
		local value7 = PathFindChest()
		if value7 then
			ToTarget(value7.Part.CFrame)
			if localPlayer:DistanceFromCharacter(value7.Part.Position) <= 100 or (GetNearestChest()) then
				Instance.new("IntValue", value7).Name = "Ignored"
			end
		else
			if Workspace:FindFirstChild("_WorldOrigin") and Workspace._WorldOrigin:FindFirstChild("PlayerSpawns") and Workspace._WorldOrigin.PlayerSpawns:FindFirstChild("Pirates") then
				for unusedIndex, player in pairs(Workspace._WorldOrigin.PlayerSpawns.Pirates:GetChildren()) do
					if player:FindFirstChild("Ignored") then
						player:FindFirstChild("Ignored"):Destroy()
					end
				end
			end
		end
	end
end

function DetectSeabeast()
	if not Workspace:FindFirstChild("SeaBeasts") then return false end
	local iterator2, state2, initialKey2 = next, Workspace.SeaBeasts:GetChildren()
	for unusedIndex, value7 in iterator2, state2, initialKey2 do
		if value7.Name == "SeaBeast1" and value7:FindFirstChild("HealthBBG") then
			local health, health2 =
				value7.HealthBBG.Frame.TextLabel.Text:gsub("/%d+,%d+", ""), value7.HealthBBG.Frame.TextLabel.Text
			local formattedHealth = string.find(health, ",") and (health2:gsub("%d+,%d+/", "")) or (health2:gsub("%d+/", ""))
			if tonumber((formattedHealth:gsub(",", ""))) >= 90000 then
				return value7
			end
		end
	end
	return false
end

function AutoFishV2()
	local humanoid4, value7 = DetectSeabeast(), CheckBoat()
	if not humanoid4 then
		if not value7 then
			local targetCFrame2 = CFrame.new(-11.94833755493164, 10.293913841247559, 2957.010498046875)
			if localPlayer:DistanceFromCharacter(targetCFrame2.Position) > 8 then
				ToTarget(targetCFrame2)
			else
				ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyBoat", "PirateBrigade")
			end
		else
			local targetCFrame2 = CFrame.new(753.0653686523438, value7.WorldPivot.Y, 6994.5146484375)
			if (value7.VehicleSeat.Position - targetCFrame2.Position).Magnitude > 50 then
				value7.VehicleSeat.CFrame = targetCFrame2
			elseif not localPlayer.Character.Humanoid.Sit then
				ToTarget(value7.VehicleSeat.CFrame)
			end
		end
	else
		repeat
			task.wait()
			TeleportSeaEvents(humanoid4)
			local rootPart7 = humanoid4:FindFirstChild("HumanoidRootPart")
			if rootPart7 then
				getgenv().AimPos = CFrame.new(rootPart7.Position.X, 40, rootPart7.Position.Z)
				if localPlayer:DistanceFromCharacter(rootPart7.Position) < 400 then
					AutoAllSkill()
				end
			end
		until not humanoid4
			or not humanoid4.Parent
			or (humanoid4:FindFirstChild("Health") and humanoid4.Health.Value <= 0)
			or not Settings["Auto Upgrade Race V2-V3"]
	end
end

function CheckRace()
	local remoteResult2, remoteResult3 =
		ReplicatedStorage.Remotes.CommF_:InvokeServer("Wenlocktoad", "1"),
		ReplicatedStorage.Remotes.CommF_:InvokeServer("Alchemist", "1")
	if localPlayer.Character and localPlayer.Character:FindFirstChild("RaceTransformed") then
		return " V4"
	end
	if remoteResult2 == -2 then
		return " V3"
	end
	if remoteResult3 == -2 then
		return " V2"
	end
	return " V1"
end

function DetectPlayerAngel()
	for unusedIndex, player in pairs(Players:GetChildren()) do
		if
			player.Name ~= localPlayer.Name
			and (Workspace.Characters:FindFirstChild(player.Name))
			and player:FindFirstChild("Data") and player.Data:FindFirstChild("Race") and player.Data.Race.Value == "Skypiea"
			and not table.find(items16, player.Name)
			and (player.Character and player.Character:FindFirstChild("Humanoid"))
			and player.Character.Humanoid.Health > 0
		then
			return player
		end
	end
end

function DetectPlayerGhoul()
	for unusedIndex, player in pairs(Players:GetChildren()) do
		if
			player.Name ~= localPlayer.Name
			and (Workspace.Characters:FindFirstChild(player.Name))
			and not table.find(items17, player.Name)
			and (player.Character and player.Character:FindFirstChild("Humanoid"))
			and player.Character.Humanoid.Health > 0
		then
			return player
		end
	end
end

function CheckSafezone(player)
	if not Workspace:FindFirstChild("_WorldOrigin") or not Workspace._WorldOrigin:FindFirstChild("SafeZones") then return false end
	for unusedIndex, child in pairs(Workspace._WorldOrigin.SafeZones:GetChildren()) do
		if child:IsA("Part") and player and player:FindFirstChild("HumanoidRootPart") and player:FindFirstChild("Humanoid") then
			if
				(child.Position - player.HumanoidRootPart.Position).magnitude <= 400
				and player.Humanoid.Health / player.Humanoid.MaxHealth >= 0.9
			then
				return true
			end
		end
	end
	return false
end

function CheckPlayercantAttack(player)
	if not localPlayer.PlayerGui:FindFirstChild("Notifications") then return false end
	for key, player2 in pairs(localPlayer.PlayerGui.Notifications:GetDescendants()) do
		if player2:IsA("TextLabel") then
			if string.find(player2.Text, "attack") and not player2:FindFirstChild(player.Name) then
				key = Instance.new("TextBox")
				key.Parent = player2.Parent
				key.Name = player.Name
				player2:Destroy()
				return true
			end
		end
	end
end

function UpgradeRaceV2AndV3()
	local value7 = CheckRace()
	if value7 == " V3" then
		uiLibrary.CreateNoti({ Title = "Skider Hub V4", Desc = "Done V3", ShowTime = 5 })
		wait(5)
		return
	end
	if not GoToSea(getgenv().CheckPlaceId2) then
		return
	end
	if value7 == " V1" then
		if localPlayer.Data.Beli.Value < 500000 then
			uiLibrary.CreateNoti({ Title = "Skider Hub V4", Desc = "Beli >= 500k", ShowTime = 5 })
			wait(5)
			return
		end
		local alchemistStep = ReplicatedStorage.Remotes.CommF_:InvokeServer("Alchemist", "1")
		if alchemistStep == 0 then
			ReplicatedStorage.Remotes.CommF_:InvokeServer("Alchemist", "2")
		elseif alchemistStep == 1 then
			if not DetectItemPlr("Flower 1") then
				if Workspace:FindFirstChild("Flower1") then ToTarget(Workspace.Flower1.CFrame) end
			elseif not DetectItemPlr("Flower 2") then
				if Workspace:FindFirstChild("Flower2") then ToTarget(Workspace.Flower2.CFrame) end
			elseif not DetectItemPlr("Flower 3") then
				local character3 = DetectMob("Swan Pirate")
				if not character3 then
					local text2 = "Swan Pirate"
					if typeof(text2) == "table" then
						if #items3 >= 11 then
							items3 = {}
							return
						end
						local part2 = DetectPartSpawnMob(DetectNameTablePart(text2))
						if part2 then
							table.insert(items3, DetectNameTablePart(text2))
							repeat
								wait()
								ToTarget(part2.CFrame * CFrame.new(0, 60, 0))
							until localPlayer:DistanceFromCharacter(part2.Position) <= 100
								or (DetectMob(text2))
								or not Settings["Auto Upgrade Race V2-V3"]
							wait(1)
						end
					else
						local part2 = DetectPartSpawnMob(text2, true)
						if part2 then
							Instance.new("IntValue", part2).Name = "Ignored"
							repeat
								wait()
								ToTarget(part2.CFrame * CFrame.new(0, 60, 0))
							until localPlayer:DistanceFromCharacter(part2.Position) <= 100
								or (DetectMob(text2))
								or not Settings["Auto Upgrade Race V2-V3"]
							wait(1)
						else
							DeleteIgnoredMobSpawn()
						end
					end
				else
					repeat
						task.wait()
						SizePart(character3)
						BringMob(character3)
						UsedualFlock()
						ClickM1(character3)
						if Settings["Select Weapon"] == "Blox Fruit" then
							ToTarget(character3.HumanoidRootPart.CFrame * CFrame.new(-7, 20, 0))
						else
							ToTarget(character3.HumanoidRootPart.CFrame * CFrame.new(7, 20, 0))
						end
					until not IsMobAlive(character3) or not Settings["Auto Upgrade Race V2-V3"]
				end
			end
		elseif alchemistStep == 2 then
			if localPlayer:DistanceFromCharacter(Vector3.new(-2777.6001, 72.9661407, -3571.42285)) > 8 then
				ToTarget(CFrame.new(-2777.6001, 72.9661407, -3571.42285))
			else
				ReplicatedStorage.Remotes.CommF_:InvokeServer("Alchemist", "3")
			end
		else
			AutoQuestBarito()
		end
	else
		local remoteResult2 = ReplicatedStorage.Remotes.CommF_:InvokeServer("Wenlocktoad", "1")
		if remoteResult2 == 0 then
			ReplicatedStorage.Remotes.CommF_:InvokeServer("Wenlocktoad", "2")
			return
		elseif remoteResult2 == 2 then
			ReplicatedStorage.Remotes.CommF_:InvokeServer("Wenlocktoad", "3")
			return
		elseif remoteResult2 == -1 then
			uiLibrary.CreateNoti({ Title = "Skider Hub V4", Desc = "Beli >= 2m", ShowTime = 5 })
			wait(5)
			return
		end
		remoteResult2 = localPlayer.Data.Race.Value .. value7
		if remoteResult2 == "Human V2" then
			local object = not table.find(BlBossHuman, "Jeremy") and (CheckNameBoss("Jeremy"))
				or not table.find(BlBossHuman, "Orbitus") and (CheckNameBoss("Orbitus"))
				or not table.find(BlBossHuman, "Diamond") and (CheckNameBoss("Diamond"))
			if object then
				local name4 = CheckNameBoss(object.Name)
				if name4 then
					repeat
						task.wait()
						SizePart(name4)
						UsedualFlock()
						ClickM1(name4)
						if Settings["Select Weapon"] == "Blox Fruit" then
							ToTarget(name4.HumanoidRootPart.CFrame * CFrame.new(-7, 20, 0))
						else
							ToTarget(name4.HumanoidRootPart.CFrame * CFrame.new(7, 20, 0))
						end
					until not IsMobAlive(name4)
					if not table.find(BlBossHuman, object.Name) then
						table.insert(BlBossHuman, object.Name)
					end
				end
			else
				uiLibrary.CreateNoti({ Title = "Skider Hub V4", Desc = "Waiting Boss Spawn", ShowTime = 5 })
				wait(5)
			end
		elseif remoteResult2 == "Mink V2" then
			AutoMinkV2()
		elseif remoteResult2 == "Cyborg V2" then
			if not CheckFruitplr() then
				if TakeFruitInventory(true) then
					ReplicatedStorage.Remotes.CommF_:InvokeServer("LoadFruit", TakeFruitInventory(true))
				end
			end
		elseif remoteResult2 == "Fishman V2" then
			AutoFishV2()
		elseif remoteResult2 == "Skypiea V2" then
			local player = DetectPlayerAngel()
			if player then
				table.insert(items16, player.Name)
				local timestamp = tick()
				repeat
					wait()
					spawn(function()
						if localPlayer.PlayerGui:FindFirstChild("Main") and localPlayer.PlayerGui.Main:FindFirstChild("BottomHUDList") and localPlayer.PlayerGui.Main.BottomHUDList:FindFirstChild("PvpDisabled") and localPlayer.PlayerGui.Main.BottomHUDList.PvpDisabled.Visible then
							ReplicatedStorage.Remotes.CommF_:InvokeServer("EnablePvp")
						end
					end)
					spawn(function()
						getgenv().AimPos = CFrame.new(
							player.Character.HumanoidRootPart.CFrame.p,
							player.Character.HumanoidRootPart.Position
								+ player.Character.HumanoidRootPart.Velocity / 1.2
						)
						if localPlayer:DistanceFromCharacter(player.Character.HumanoidRootPart.Position) < 50 then
							localPlayer.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame
								* CFrame.new(0, 0, 3)
						else
							ToTarget(player.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3))
						end
					end)
					spawn(function()
						if localPlayer:DistanceFromCharacter(player.Character.HumanoidRootPart.Position) < 50 then
							AutoAllSkill(true)
						end
					end)
				until tick() - timestamp >= 70
					or not player.Character
					or not player.Character.Parent
					or player.Character.Humanoid.Health == 0
					or (CheckSafezone(player.Character))
					or (CheckPlayercantAttack(player.Character))
					or not Settings["Auto Upgrade Race V2-V3"]
			else
				HopServer()
				wait(5)
			end
		elseif remoteResult2 == "Ghoul V2" then
			local player = DetectPlayerGhoul()
			if player then
				table.insert(items17, player.Name)
				local timestamp = tick()
				repeat
					wait()
					spawn(function()
						if localPlayer.PlayerGui:FindFirstChild("Main") and localPlayer.PlayerGui.Main:FindFirstChild("BottomHUDList") and localPlayer.PlayerGui.Main.BottomHUDList:FindFirstChild("PvpDisabled") and localPlayer.PlayerGui.Main.BottomHUDList.PvpDisabled.Visible then
							ReplicatedStorage.Remotes.CommF_:InvokeServer("EnablePvp")
						end
					end)
					spawn(function()
						getgenv().AimPos = CFrame.new(
							player.Character.HumanoidRootPart.CFrame.p,
							player.Character.HumanoidRootPart.Position
								+ player.Character.HumanoidRootPart.Velocity / 1.2
						)
						if localPlayer:DistanceFromCharacter(player.Character.HumanoidRootPart.Position) < 50 then
							localPlayer.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame
								* CFrame.new(0, 0, 3)
						else
							ToTarget(player.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3))
						end
					end)
					spawn(function()
						if localPlayer:DistanceFromCharacter(player.Character.HumanoidRootPart.Position) < 50 then
							AutoAllSkill(true)
						end
					end)
				until tick() - timestamp >= 70
					or not player.Character
					or not player.Character.Parent
					or player.Character.Humanoid.Health == 0
					or (CheckSafezone(player.Character))
					or (CheckPlayercantAttack(player.Character))
					or not Settings["Auto Upgrade Race V2-V3"]
			else
				HopServer()
				wait(5)
			end
		end
	end
end

function BuyChipLaw()
	local result = ReplicatedStorage.Remotes.CommF_:InvokeServer("BlackbeardReward", "Microchip", "2")
	return result == 1 or result == 2
end

local count11, enabled5, enabled6 = 0, false, false
function DetectkeyCyborg(keyName)
	if not localPlayer.PlayerGui:FindFirstChild("Notifications") then return false end
	local iterator2, state2, initialKey2 =
		next, localPlayer.PlayerGui.Notifications:GetChildren()
	for unusedIndex, value7 in iterator2, state2, initialKey2 do
		if value7.Name == "NotificationTemplate" and value7:FindFirstChild("TranslateMe") and value7.TranslateMe.Text == keyName then
			return true
		end
	end
	return false
end

-- Forward reference for Fluent Toggle
local ToggleAutoGetFullyCyborg

function GetCyborg()
	if ReplicatedStorage.Remotes.CommF_:InvokeServer("CyborgTrainer", "Check") == 2 then
		uiLibrary.CreateNoti({ Title = "Skider Hub V4", Desc = "Plz Turn Off", ShowTime = 5 })
		wait(5)
		return
	end
	if not GoToSea(getgenv().CheckPlaceId2) then
		return
	end
	if ReplicatedStorage.Remotes.CommF_:InvokeServer("CyborgTrainer", "Check") then
		ReplicatedStorage.Remotes.CommF_:InvokeServer("CyborgTrainer", "Buy")
		return
	end
	if not enabled6 and not DetectItemPlr("Core Brain") then
		repeat
			wait(1)
			if Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("CircleIsland") and Workspace.Map.CircleIsland:FindFirstChild("RaidSummon") then
				fireclickdetector(Workspace.Map.CircleIsland.RaidSummon.Button.Main.ClickDetector)
			end
		until DetectkeyCyborg("{color1_Green}Please supply a {item1} to continue.{color1_/}")
			or (DetectkeyCyborg("{color1_Red}Microchip not found.{color1_/}"))
		local callback18 = DetectkeyCyborg
		if callback18("{color1_Red}Microchip not found.{color1_/}") then
			enabled5 = false
		else
			local callback19 = DetectkeyCyborg
			if callback19("{color1_Green}Please supply a {item1} to continue.{color1_/}") then
				enabled5 = true
			end
		end
		enabled6 = true
	end
	if Settings["Auto Get Fully Cyborg"] and not CheckNameBoss("Order") and not enabled5 then
		if not DetectItemPlr("Fist of Darkness") then
			if count11 >= 20 and Settings["Auto Get Cyborg Hop Collect Chest"] then
				if not getgenv().DelayHop then
					task.delay(5, function()
						getgenv().DelayHop = true
						spawn(function()
							HopLessAll()
						end)
						spawn(function()
							HopServer()
						end)
						getgenv().DelayHop = false
					end)
				end
				return
			end
			local part2 = GetNearestChest()
			if part2 then
				count11 = count11 + 1
				local chestTick = nil -- Fixed variable shadowing (ngu.md bug fix)
				repeat
					task.wait()
					if
						(localPlayer.Character.HumanoidRootPart.Position - part2.Position).Magnitude <= 5
					then
						if not chestTick then
							chestTick = (tick())
						elseif tick() - chestTick >= 5 then
							Instance.new("IntValue", part2).Name = "Ignored"
							wait(0.5)
						end
						VirtualInputManager:SendKeyEvent(true, "Space", false, game)
						wait()
						VirtualInputManager:SendKeyEvent(false, "Space", false, game)
						TweenManager.CancelCurrent()
					end
					ToTarget(part2.CFrame, true)
				until not part2
					or not part2.Parent
					or not Settings["Auto Get Cyborg"]
					or (part2:GetAttribute("IsDisabled"))
					or (part2:FindFirstChild("Ignored"))
					or not part2:FindFirstChild("TouchInterest")
			else
				local value7 = PathFindChest()
				if value7 then
					ToTarget(value7.Part.CFrame)
					if localPlayer:DistanceFromCharacter(value7.Part.Position) <= 100 or (GetNearestChest()) then
						Instance.new("IntValue", value7).Name = "Ignored"
					end
				else
					if Workspace:FindFirstChild("_WorldOrigin") and Workspace._WorldOrigin:FindFirstChild("PlayerSpawns") and Workspace._WorldOrigin.PlayerSpawns:FindFirstChild("Pirates") then
						for unusedIndex, player in
							pairs(Workspace._WorldOrigin.PlayerSpawns.Pirates:GetChildren())
						do
							if player:FindFirstChild("Ignored") then
								player:FindFirstChild("Ignored"):Destroy()
							end
						end
					end
				end
			end
		else
			wait(1)
			repeat
				wait()
				if Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("CircleIsland") and Workspace.Map.CircleIsland:FindFirstChild("RaidSummon") then
					fireclickdetector(Workspace.Map.CircleIsland.RaidSummon.Button.Main.ClickDetector)
				end
			until not DetectItemPlr("Fist of Darkness")
			wait(0.5)
			if ToggleAutoGetFullyCyborg then
				ToggleAutoGetFullyCyborg:SetValue(false)
			end
			enabled5 = true
		end
		return
	end
	if enabled5 then
		if DetectItemPlr("Core Brain") then
			if Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("CircleIsland") and Workspace.Map.CircleIsland:FindFirstChild("RaidSummon") then
				fireclickdetector(Workspace.Map.CircleIsland.RaidSummon.Button.Main.ClickDetector)
			end
			return
		end
		local character3 = CheckNameBoss("Order")
		if character3 then
			repeat
				task.wait()
				SizePart(character3)
				UsedualFlock()
				ClickM1(character3)
				if Settings["Select Weapon"] == "Blox Fruit" then
					ToTarget(character3.HumanoidRootPart.CFrame * CFrame.new(-7, 20, 0))
				else
					ToTarget(character3.HumanoidRootPart.CFrame * CFrame.new(7, 20, 0))
				end
			until not IsMobAlive(character3) or not Settings["Auto Get Cyborg"]
		elseif not DetectItemPlr("Microchip") and localPlayer.Data.Fragments.Value >= 1000 then
			BuyChipLaw()
			wait(2)
		elseif DetectItemPlr("Microchip") then
			if Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("CircleIsland") and Workspace.Map.CircleIsland:FindFirstChild("RaidSummon") then
				fireclickdetector(Workspace.Map.CircleIsland.RaidSummon.Button.Main.ClickDetector)
			end
		end
	end
end

function GetRaceGhoul()
	if not GoToSea(getgenv().CheckPlaceId2) then
		return
	end
	if
		localPlayer.Data.Race.Value == "Ghoul"
		or ReplicatedStorage.Remotes.CommF_:InvokeServer("Ectoplasm", "BuyCheck", 4, true) == 2
		or ReplicatedStorage.Remotes.CommF_:InvokeServer("Ectoplasm", "Change", 4, true) == 1
	then
		uiLibrary.CreateNoti({ Title = "Skider Hub V4", Desc = "Plz Turn Off", ShowTime = 5 })
		wait(5)
		return
	end
	if not CheckCountItem("Ectoplasm", 100) then
		local items18 = { "Ship Deckhand", "Ship Steward", "Ship Officer", "Ship Engineer" }
		local character3 = DetectMob(items18)
		if character3 then
			repeat
				task.wait()
				SizePart(character3)
				BringMob(character3)
				UsedualFlock()
				ClickM1(character3)
				if Settings["Select Weapon"] == "Blox Fruit" then
					ToTarget(character3.HumanoidRootPart.CFrame * CFrame.new(-7, 20, 0))
				else
					ToTarget(character3.HumanoidRootPart.CFrame * CFrame.new(7, 20, 0))
				end
			until not IsMobAlive(character3) or not Settings["Auto Get Ghoul"]
		elseif typeof(items18) == "table" then
			if #items3 >= #items18 then
				items3 = {}
				return
			end
			local part2 = DetectPartSpawnMob(DetectNameTablePart(items18))
			if part2 then
				table.insert(items3, DetectNameTablePart(items18))
				repeat
					wait()
					ToTarget(part2.CFrame * CFrame.new(0, 60, 0))
				until localPlayer:DistanceFromCharacter(part2.Position) <= 100
					or (DetectMob(items18))
					or not Settings["Auto Get Ghoul"]
				wait(1)
			end
		else
			local part2 = DetectPartSpawnMob(items18, true)
			if part2 then
				Instance.new("IntValue", part2).Name = "Ignored"
				repeat
					wait()
					ToTarget(part2.CFrame * CFrame.new(0, 60, 0))
				until localPlayer:DistanceFromCharacter(part2.Position) <= 100
					or (DetectMob(items18))
					or not Settings["Auto Get Ghoul"]
				wait(1)
			else
				DeleteIgnoredMobSpawn()
			end
		end
		return
	end
	if DetectItemPlr("Hellfire Torch") then
		local targetPos = CFrame.new(
			918.615234, 122.202454, 33454.3789,
			-0.999998808, 0, 0.00172644004,
			0, 1, 0,
			-0.00172644004, 0, -0.999998808
		)
		if (targetPos.Position - localPlayer.Character.HumanoidRootPart.Position).Magnitude <= 8 then
			ReplicatedStorage.Remotes.CommF_:InvokeServer("Ectoplasm", "BuyCheck", 4)
			ReplicatedStorage.Remotes.CommF_:InvokeServer("Ectoplasm", "Buy", 4)
		else
			ToTarget(targetPos)
		end
	else
		local character3 = CheckNameBoss("Cursed Captain")
		if character3 then
			repeat
				task.wait()
				SizePart(character3)
				UsedualFlock()
				ClickM1(character3)
				if Settings["Select Weapon"] == "Blox Fruit" then
					ToTarget(character3.HumanoidRootPart.CFrame * CFrame.new(-7, 20, 0))
				else
					ToTarget(character3.HumanoidRootPart.CFrame * CFrame.new(7, 20, 0))
				end
			until not IsMobAlive(character3) or not Settings["Auto Get Ghoul"]
			wait(5)
		else
			if Settings["Hop Server Get Ghoul"] then
				SpecialHop("Cursed Captain")
			end
			uiLibrary.CreateNoti({ Title = "Skider Hub V4", Desc = "Wating Boss Spawn", ShowTime = 5 })
			wait(5)
		end
	end
end

function BuyGearV4()
	local code, progress = nil, nil
	pcall(function()
		code, progress = ReplicatedStorage.Remotes.CommF_:InvokeServer("UpgradeRace", "Check")
	end)
	if code == 2 or code == 4 or code == 7 or string.find(CheckAcientOneStatus(), "Can Buy Gear") then
		ReplicatedStorage.Remotes.CommF_:InvokeServer("UpgradeRace", "Buy")
		ResetRaceStatus()
	end
end

-- Separate variable name for PullLever to prevent name collision (ngu.md bug fix)
local leverTargetCFrame, count12 =
	CFrame.new(
		28576.4688,
		14935.9512,
		75.469101,
		-1,
		-4.22219593E-8,
		1.13133396E-8,
		0,
		-0.258819044,
		-0.965925813,
		4.37113883E-8,
		-0.965925813,
		0.258819044
	),
	0.2

function GetBlueGear()
	if Workspace.Map:FindFirstChild("MysticIsland") then
		for unusedIndex, child in pairs(Workspace.Map.MysticIsland:GetChildren()) do
			if child:IsA("MeshPart") and child.MeshId == "rbxassetid://10153114969" then
				return child
			end
		end
	end
end

function GetHighestPoint()
	if not Workspace.Map:FindFirstChild("MysticIsland") then
		return nil
	end
	for unusedIndex, child in pairs(Workspace.Map.MysticIsland:GetDescendants()) do
		if child:IsA("MeshPart") then
			if child.MeshId == "rbxassetid://6745037796" then
				return child
			end
		end
	end
end

function CheckAbility()
	local iterator2, state2, initialKey2 = next, localPlayer.Backpack:GetChildren()
	for _, value7 in iterator2, state2, initialKey2 do
		if table.find(items18, value7.Name) then
			return true
		end
	end
	iterator2, state2, initialKey2 = next, localPlayer.Character:GetChildren()
	for _, value7 in iterator2, state2, initialKey2 do
		if table.find(items18, value7.Name) then
			return true
		end
	end
	return false
end

function CollectBlueGear()
	local value7 = GetBlueGear()
	if value7 and not value7.CanCollide and value7.Transparency ~= 1 then
		if localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") and localPlayer.Character.HumanoidRootPart:FindFirstChild("Agility") then
			localPlayer.Character.HumanoidRootPart.Agility:Destroy()
		end
		uiLibrary.CreateNoti({ Title = "Skider Hub V4", Desc = "Đã tìm thấy Blue Gear! Đang nhặt...", ShowTime = 3 })
		ToTarget(value7.CFrame)
		return
	end

	-- Gear chưa xuất hiện hoặc chưa kích hoạt -> Bay lên đỉnh cao nhất và niệm nhìn Mặt Trăng
	local highPoint = GetHighestPoint()
	if not highPoint then
		local dealer = DetectNpc("Advanced Fruit Dealer")
		if dealer and dealer:FindFirstChild("HumanoidRootPart") then
			ToTarget(dealer.HumanoidRootPart.CFrame)
		end
		return
	end

	local targetCF = highPoint.CFrame * CFrame.new(0, 211.88, 0)
	local hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	if (hrp.Position - targetCF.Position).Magnitude > 10 then
		uiLibrary.CreateNoti({ Title = "Skider Hub V4", Desc = "Đang bay lên đỉnh cao nhất Mirage...", ShowTime = 3 })
		ToTarget(targetCF)
	else
		hrp.CFrame = targetCF
		local moonDir = Lighting:GetMoonDirection()
		local targetCamPos = Workspace.CurrentCamera.CFrame.Position + moonDir * 100
		Workspace.CurrentCamera.CFrame = CFrame.lookAt(Workspace.CurrentCamera.CFrame.Position, targetCamPos)
		if localPlayer.Character:FindFirstChild("Humanoid") then
			localPlayer.Character.Humanoid.AutoRotate = false
			localPlayer.Character.Humanoid.RootPart.CFrame = CFrame.lookAt(hrp.Position, targetCamPos)
			localPlayer.Character.Humanoid.Sit = false
		end
		if CheckClockTime() == "Night" then
			uiLibrary.CreateNoti({ Title = "Skider Hub V4", Desc = "Đang niệm chiêu thức tộc nhìn Mặt Trăng...", ShowTime = 2 })
			pcall(function()
				ReplicatedStorage.Remotes.CommE:FireServer("ActivateAbility")
			end)
			VirtualInputManager:SendKeyEvent(true, "T", false, game)
			task.wait(0.2)
			VirtualInputManager:SendKeyEvent(false, "T", false, game)
			if not CheckAbility() and not hrp:FindFirstChild("Agility") then
				if ReplicatedStorage:FindFirstChild("FX") and ReplicatedStorage.FX:FindFirstChild("Agility") then
					local fx = ReplicatedStorage.FX.Agility:Clone()
					fx.Parent = hrp
					fx.Enabled = false
				end
			end
		else
			uiLibrary.CreateNoti({ Title = "Skider Hub V4", Desc = "Đang chờ trời tối (Night) trên Mirage Island...", ShowTime = 3 })
		end
		task.wait(1)
	end
end

local race_abilities = {
	["Human"] = "Last Resort",
	["Mink"] = "Agility",
	["Fishman"] = "Water Body",
	["Skypiea"] = "Heavenly Blood",
	["Ghoul"] = "Heightened Senses",
	["Cyborg"] = "Energy Core"
}

local function CheckRaceV3()
	local datarace = localPlayer.Data and localPlayer.Data:FindFirstChild("Race") and localPlayer.Data.Race.Value
	local ability_name = race_abilities[datarace]
	if not ability_name or type(ability_name) ~= "string" then
		return "Not Have V3"
	end
	local bp = localPlayer:FindFirstChild("Backpack")
	local ch = localPlayer.Character
	if (bp and bp:FindFirstChild(ability_name)) or (ch and ch:FindFirstChild(ability_name)) then
		if (bp and bp:FindFirstChild("Awakening")) or (ch and ch:FindFirstChild("Awakening")) then
			return "Have V4"
		else
			return "Have V3"
		end
	end
	return "Not Have V3"
end

function PullLeverV4()
	if not CheckItemInventory("Valkyrie Helm") or not CheckItemInventory("Mirror Fractal") then
		uiLibrary.CreateNoti({
			Title = "Skider Hub V4",
			Desc = "Cần có Valkyrie Helm và Mirror Fractal để làm V4!",
			ShowTime = 5,
		})
		task.wait(5)
		return
	end

	-- Kiểm tra Sea 3
	local place_check = game.PlaceId
	local sea3 = (place_check == 7449423635 or place_check == 100117331123089)
	if not sea3 and Workspace:GetAttribute("MAP") ~= "Sea3" then
		uiLibrary.CreateNoti({
			Title = "Skider Hub V4",
			Desc = "Cần ở Sea 3 để làm nhiệm vụ V4!",
			ShowTime = 5,
		})
		task.wait(5)
		return
	end

	-- Kiểm tra Race V3
	local racev3 = CheckRaceV3()
	if racev3 ~= "Have V3" and racev3 ~= "Have V4" then
		uiLibrary.CreateNoti({
			Title = "Skider Hub V4",
			Desc = "Cần nâng cấp tộc lên V3 trước!",
			ShowTime = 5,
		})
		task.wait(5)
		return
	end

	-- 1. Nếu chưa mở CheckTempleDoor
	local doorUnlocked = ReplicatedStorage.Remotes.CommF_:InvokeServer("CheckTempleDoor")
	if not doorUnlocked then
		-- Tiến trình NPC Ancient One
		local remoteResult2 = ReplicatedStorage.Remotes.CommF_:InvokeServer("RaceV4Progress", "Check")
		if remoteResult2 == 1 then
			ReplicatedStorage.Remotes.CommF_:InvokeServer("RaceV4Progress", "Begin")
			task.wait(1)
			return
		elseif remoteResult2 == 2 then
			TempleProgress.value, TempleProgress.checked = 2, tick()
			TeleportTempleOfTime()
			return
		elseif remoteResult2 == 3 then
			ReplicatedStorage.Remotes.CommF_:InvokeServer("RaceV4Progress", "Continue")
			task.wait(1)
			return
		end

		-- Kiểm tra Mirage Island
		local mirageLocation = Workspace:FindFirstChild("_WorldOrigin")
			and Workspace._WorldOrigin:FindFirstChild("Locations")
			and Workspace._WorldOrigin.Locations:FindFirstChild("Mirage Island")
		local mysticInMap = Workspace.Map:FindFirstChild("MysticIsland") ~= nil

		if not mirageLocation and not mysticInMap then
			if Settings["Hop Server [Trial Or Pull Lever]"] then
				uiLibrary.CreateNoti({ Title = "Skider Hub V4", Desc = "Đang tìm server có Mirage Island...", ShowTime = 3 })
				SpecialHop("Mirage")
			else
				uiLibrary.CreateNoti({ Title = "Skider Hub V4", Desc = "Đang chờ đảo Mirage Island xuất hiện...", ShowTime = 3 })
				task.wait(3)
			end
			return
		end

		-- Đảo có trong server nhưng chưa stream map -> bay tới tọa độ đảo
		if not mysticInMap then
			if mirageLocation then
				uiLibrary.CreateNoti({ Title = "Skider Hub V4", Desc = "Đang bay tới Mirage Island...", ShowTime = 3 })
				ToTarget(mirageLocation.CFrame)
			end
			return
		end

		-- Đảo đã load vào map -> thực hiện nhặt gear / niệm trăng
		CollectBlueGear()
	else
		-- 2. Đã mở CheckTempleDoor -> Vào Temple of Time kéo cần gạt
		if not IsInTempleOfTime() then
			TeleportTempleOfTime()
			return
		end
		BorrowTempleOfTime()
		local value7 = GetTempleOfTime()
		if not value7 or not value7:FindFirstChild("Lever") then
			return
		end

		local leverModel = value7.Lever
		local leverPart = leverModel:FindFirstChild("Lever") or leverModel:FindFirstChild("Part")
		local promptPart = leverModel:FindFirstChild("Part") or leverModel:FindFirstChild("Prompt") or leverPart
		local leverPrompt = leverModel:FindFirstChildWhichIsA("ProximityPrompt", true)

		local targetZ = leverTargetCFrame.Z
		local currentZ = leverPart and leverPart.CFrame.Z or 0
		if math.abs(currentZ - targetZ) > count12 then
			if localPlayer:DistanceFromCharacter(promptPart.Position) > 10 then
				ToTarget(promptPart.CFrame)
			else
				if leverPrompt then
					fireproximityprompt(leverPrompt, 5)
				end
			end
		else
			uiLibrary.CreateNoti({ Title = "Skider Hub V4", Desc = "Đã kéo cần gạt V4 thành công!", ShowTime = 5 })
			task.wait(5)
		end
	end
end

function DetectNameMulti(player)
	local lookup6 = {}
	local helperSource = Settings["Name Helper TurnV3"]
		or (type(getgenv().Config) == "table" and getgenv().Config["Name Helper TurnV3"])
		or Settings["Select Players Multi"]
	if helperSource and not player then
		if type(helperSource) == "table" then
			for key, val in pairs(helperSource) do
				if type(key) == "string" and val == true then
					lookup6[key] = true
				elseif type(val) == "string" then
					lookup6[val] = true
				elseif type(val) == "table" then
					for _, subName in ipairs(val) do
						if type(subName) == "string" then
							lookup6[subName] = true
						end
					end
				end
			end
		end
	end
	if localPlayer and localPlayer.Name and lookup6[localPlayer.Name] == nil then
		lookup6[localPlayer.Name] = false
	end
	for unusedIndex, player2 in pairs(Players:GetChildren()) do
		if player2:IsA("Player") and not lookup6[player2.Name] then
			lookup6[player2.Name] = false
		end
	end
	return lookup6
end

function DetectNameAbility(player)
	local iterator2, state2, initialKey2 = next, player:GetChildren()
	for unusedIndex, value7 in iterator2, state2, initialKey2 do
		if table.find(items18, value7.Name) then
			return true
		end
	end
	return false
end

function GetOtherPlayerRaces()
	local lookup6 = {}
	for unusedIndex, player in pairs(Players:GetChildren()) do
		if player.Name ~= localPlayer.Name and player:FindFirstChild("Data") and player.Data:FindFirstChild("Race") then
			lookup6[player.Name] = player.Data.Race.Value
		end
	end
	return lookup6
end

function CheckMultiPlayerNearDoor()
	if not Workspace:FindFirstChild("Characters") then return false end
	local iterator2, state2, initialKey2 = next, Workspace.Characters:GetChildren()
	local count13 = 0
	for key, value7 in iterator2, state2, initialKey2 do
		key = GetOtherPlayerRaces()[value7.Name]
		if key
			and value7:FindFirstChild("HumanoidRootPart")
			and (DetectNameAbility(value7.HumanoidRootPart))
			and Workspace.Map:FindFirstChild("Temple of Time")
			and Workspace.Map["Temple of Time"]:FindFirstChild(key .. "Corridor")
			and (
					value7.HumanoidRootPart.Position
					- Workspace.Map["Temple of Time"][key .. "Corridor"].Door.Door.RightDoor.Union.Position
				).Magnitude
				< 100
		then
			count13 = count13 + 1
		end
	end
	if count13 >= 2 then
		return true
	end
	return false
end

function CheckMultiAccount()
	local lookup6 = {}
	for unusedIndex, player in pairs(Players:GetChildren()) do
		if Settings["Select Players Multi"] and Settings["Select Players Multi"][player.Name] and player:FindFirstChild("Data") and player.Data:FindFirstChild("Race") then
			lookup6[player.Name] = player.Data.Race.Value
		end
	end
	return lookup6
end

function CheckMultiTeleDoor()
	if not Workspace:FindFirstChild("Characters") then return false end
	local iterator2, state2, initialKey2 = next, Workspace.Characters:GetChildren()
	local count13 = 0
	for key, value7 in iterator2, state2, initialKey2 do
		key = CheckMultiAccount()[value7.Name]
		if key
			and value7:FindFirstChild("HumanoidRootPart")
			and Workspace.Map:FindFirstChild("Temple of Time")
			and Workspace.Map["Temple of Time"]:FindFirstChild(key .. "Corridor")
			and (
					value7.HumanoidRootPart.Position
					- Workspace.Map["Temple of Time"][key .. "Corridor"].Door.Door.RightDoor.Union.Position
				).Magnitude
				< 100
		then
			count13 = count13 + 1
		end
	end
	if count13 >= 2 then
		return true
	end
	return false
end


-- ══════════════════════════════════════════════════════════════════
-- TURNV3 (Đồng bộ V3 Countdown & Watchdog Ghost Temple)
-- Tích hợp nguyên bản từ Kaiv4-BNN/kaiv4mixbnncrack-nam.lua
-- ══════════════════════════════════════════════════════════════════
local V3_FILE_POLL      = 0.05
local V3_READY_FRESH    = 5.0
local V3_FIRE_COUNT     = 3
local V3_FIRE_INTERVAL  = 0.05
local V3_DOOR_DIST      = 65
local FILE_ROOT         = "TurnV3"

local USERNAME = localPlayer.Name

local CommF_ = nil
pcall(function()
    CommF_ = ReplicatedStorage:WaitForChild("Remotes", 5):WaitForChild("CommF_", 5)
end)

-- ════════════ ROLE DETECTION ════════════
-- Helper = có trong Name Helper TurnV3
-- Main   = KHÔNG có trong Name Helper TurnV3
local LOCAL_HELPERS   = {}
local HelpWhitelist   = {}
local isUper = true
local isAlly = false

local function refreshTurnV3Roles()
    table.clear(LOCAL_HELPERS)
    table.clear(HelpWhitelist)
    local raw = Settings["Name Helper TurnV3"]
        or (type(getgenv().Config) == "table" and getgenv().Config["Name Helper TurnV3"])
        or (type(getgenv().HelperList) == "table" and getgenv().HelperList)
        or Settings["Select Players Multi"]
        or {}

    local seen = {}
    local function parseItem(item)
        if type(item) == "table" then
            for k, v in pairs(item) do
                if type(k) == "number" and type(v) == "string" then
                    parseItem(v)
                elseif type(k) == "string" and v == true then
                    parseItem(k)
                elseif type(v) == "table" then
                    parseItem(v)
                end
            end
        elseif type(item) == "string" then
            local clean = item:match("^%s*(.-)%s*$")
            if clean ~= "" and not seen[clean] then
                seen[clean] = true
                table.insert(LOCAL_HELPERS, clean)
                HelpWhitelist[clean] = true
            end
        end
    end
    parseItem(raw)

    isUper = not HelpWhitelist[USERNAME]
    isAlly = HelpWhitelist[USERNAME] == true
end

refreshTurnV3Roles()

-- SERVER TIME
local function v3ServerNow()
    local ok, v = pcall(function() return Workspace:GetServerTimeNow() end)
    return (ok and tonumber(v)) and tonumber(v) or tick()
end

-- FILE SYNC API
local FILE_SYNC_AVAILABLE = type(writefile) == "function"
    and type(readfile)   == "function"
    and type(isfile)     == "function"
    and type(makefolder) == "function"
    and type(isfolder)   == "function"

local function safeMakeFolder(path)
    if not FILE_SYNC_AVAILABLE then return false end
    if isfolder(path) then return true end
    return pcall(makefolder, path)
end

local function safeReadJson(path)
    if not FILE_SYNC_AVAILABLE or not isfile(path) then return nil end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
    if ok and type(data) == "table" then return data end
    return nil
end

local function safeWriteJson(path, data)
    if not FILE_SYNC_AVAILABLE then return false end
    local ok = pcall(function() writefile(path, HttpService:JSONEncode(data)) end)
    return ok
end

local function sanitize(s)
    s = tostring(s or "x"):gsub("[^%w%-_%.]", "_")
    return s ~= "" and s or "x"
end

-- FILE PATHS
local function groupFolder()
    if not safeMakeFolder(FILE_ROOT) then return nil end
    local folder = FILE_ROOT .. "/group"
    if not safeMakeFolder(folder) then return nil end
    return folder
end

local function ownReadyPath()
    return sanitize(USERNAME) .. "-skiderhubv4turnv3.json"
end

local function commandPath()
    return "command-skiderhubv4turnv3.json"
end

-- STATE
local readySent        = false
local lastReadyWrite   = 0
local handledRoundId   = ""
local scheduledRoundId = ""
local abilityCooldown  = 0
local currentStatus    = "Dang khoi dong..."

local function setStatus(s) currentStatus = tostring(s or "") end

-- V4 STATUS CHECK
local v4Cache       = { at = 0, data = nil }
local V4_CACHE_TIME = 10.0

local function invalidateV4Cache()
    v4Cache.at   = 0
    v4Cache.data = nil
end

local function getV4StatusSimple()
    if v4Cache.data and tick() - v4Cache.at < V4_CACHE_TIME then
        return v4Cache.data
    end
    local s = { canTrial = true, needsTraining = false, needsPurchase = false, complete = false }
    if not CommF_ then
        v4Cache.at = tick(); v4Cache.data = s; return s
    end
    local ok, err = pcall(function()
        local char        = localPlayer.Character
        local transformed = char and char:FindFirstChild("RaceTransformed")
        if transformed then
            local ok2, code = pcall(function() return CommF_:InvokeServer("UpgradeRace", "Check") end)
            if ok2 and code ~= nil then
                code = tonumber(code)
                if code == 0 then
                    s.canTrial = true
                elseif code == 5 then
                    s.complete = true; s.canTrial = true
                elseif code == 1 or code == 3 or code == 6 or code == 8 then
                    s.canTrial = false; s.needsTraining = true
                elseif code == 2 or code == 4 or code == 7 then
                    s.canTrial = false; s.needsPurchase = true
                end
            end
        else
            local ok2, progress = pcall(function()
                return CommF_:InvokeServer("RaceV4Progress", "Check")
            end)
            if ok2 and tonumber(progress) then
                progress = tonumber(progress)
                if progress >= 4 then
                    s.canTrial = true
                else
                    s.canTrial      = false
                    s.needsTraining = true
                end
            end
        end
    end)
    if not ok then
        s = { canTrial = true, needsTraining = false, needsPurchase = false, complete = false }
    end
    v4Cache.at = tick(); v4Cache.data = s; return s
end

local function isnight()
    local c = Lighting.ClockTime
    return c >= 16 or c < 5
end

local function isfullmoon()
    return Lighting:GetAttribute("MoonPhase") == 5
end

-- DOOR CHECK
local function getDoor()
    local data = localPlayer:FindFirstChild("Data")
    local race = data and data:FindFirstChild("Race")
    if not race then return nil end

    local temple = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Temple of Time")
    if not temple then
        local ms = ReplicatedStorage:FindFirstChild("MapStash")
        temple = ms and ms:FindFirstChild("Temple of Time")
    end
    if not temple then return nil end

    local raceVal  = race.Value
    local corridor = temple:FindFirstChild(raceVal .. "Corridor")
    if not corridor then
        for _, c in ipairs(temple:GetChildren()) do
            if c.Name:lower():find(raceVal:lower(), 1, true) then corridor = c; break end
        end
    end
    if not corridor then return nil end

    local door = corridor:FindFirstChild("Door")
    if not door then return nil end
    pcall(function()
        local union = door.Door.RightDoor.Union
        if union and union:IsA("BasePart") then
            door = union
        end
    end)
    if door:IsA("BasePart") then return door end
    local entrance = door:FindFirstChild("Entrance") or door
    if entrance:IsA("BasePart") then return entrance end
    return entrance:FindFirstChildWhichIsA("BasePart", true)
end

local function localDoorState()
    local char     = localPlayer.Character
    local hrp      = char and char:FindFirstChild("HumanoidRootPart")
    local hum      = char and char:FindFirstChildOfClass("Humanoid")
    local door     = getDoor()
    local distance = math.huge
    if door and hrp then distance = (door.Position - hrp.Position).Magnitude end
    local timerVisible = false
    pcall(function()
        timerVisible = (localPlayer.PlayerGui:FindFirstChild("Main") and localPlayer.PlayerGui.Main:FindFirstChild("Timer") and localPlayer.PlayerGui.Main.Timer.Visible == true)
            or (localPlayer.PlayerGui:FindFirstChild("Main") and localPlayer.PlayerGui.Main:FindFirstChild("TopHUDList") and localPlayer.PlayerGui.Main.TopHUDList:FindFirstChild("RaidTimer") and localPlayer.PlayerGui.Main.TopHUDList.RaidTimer.Visible == true)
    end)
    local alive = hum ~= nil and hum.Health > 0
    return {
        nearDoor     = alive and door ~= nil and distance <= V3_DOOR_DIST,
        distance     = distance,
        timerVisible = timerVisible,
        alive        = alive,
    }
end

-- WRITE OWN READY FILE
local function writeOwnReadyFile(force)
    if not FILE_SYNC_AVAILABLE then return false end
    if not force and tick() - lastReadyWrite < V3_FILE_POLL then return readySent end
    lastReadyWrite = tick()

    local path = ownReadyPath()
    if not path then return false end

    if handledRoundId == "" then
        local prev = safeReadJson(path)
        if prev and tostring(prev.fired_round or "") ~= "" then
            handledRoundId = tostring(prev.fired_round)
        end
    end

    local st    = localDoorState()
    local ready = tick() >= abilityCooldown
        and st.alive
        and st.nearDoor
        and not st.timerVisible

    readySent = ready
    local payload = {
        job_id      = game.JobId,
        username    = USERNAME,
        role        = isAlly and "helper" or "main",
        ready       = ready,
        near_door   = st.nearDoor,
        updated_at  = v3ServerNow(),
        fired_round = handledRoundId,
    }
    safeWriteJson(path, payload)
    pcall(function()
        local f = groupFolder()
        if f then safeWriteJson(f .. "/ready_" .. sanitize(USERNAME) .. ".json", payload) end
    end)
    return ready
end

-- READ ALL READY FILES
local function readAllReadyFiles()
    local readyCount = 0
    local total      = 0
    local now        = v3ServerNow()
    local folder     = groupFolder()

    for _, name in ipairs(LOCAL_HELPERS) do
        if Players:FindFirstChild(name) then
            total = total + 1
            local path1 = sanitize(name) .. "-skiderhubv4turnv3.json"
            local data = safeReadJson(path1)
            if not data and folder then
                data = safeReadJson(folder .. "/ready_" .. sanitize(name) .. ".json")
            end
            local valid = data
                and tostring(data.job_id or "") == tostring(game.JobId)
                and data.ready == true
                and tonumber(data.updated_at)
                and math.abs(now - tonumber(data.updated_at)) <= V3_READY_FRESH
            if valid then readyCount = readyCount + 1 end
        end
    end

    return readyCount, total >= 1 and readyCount >= total
end

-- READ V3 COMMAND
local function readV3Command()
    local path = commandPath()
    local data = safeReadJson(path)
    if not data then
        local f = groupFolder()
        if f then data = safeReadJson(f .. "/command.json") end
    end
    if not data then return nil end
    if tostring(data.job_id or "") ~= tostring(game.JobId) then return nil end

    local now       = v3ServerNow()
    local expiresAt = tonumber(data.expires_at) or 0
    if expiresAt <= now then return nil end
    return data
end

-- MAIN CREATE ROUND
local function mainCreateRound()
    if not isUper then return nil end

    local v4 = getV4StatusSimple()
    if v4 and (v4.needsTraining or v4.needsPurchase) then
        setStatus("Main | Dang training - bo qua countdown")
        return nil
    end

    local ffaNow = false
    pcall(function()
        ffaNow = Workspace.Map:FindFirstChild("Temple of Time") and Workspace.Map["Temple of Time"].FFABorder.Forcefield.Transparency == 0
    end)
    if ffaNow then return nil end

    if scheduledRoundId ~= "" then
        return readV3Command()
    end

    local current = readV3Command()
    if current then return current end

    local readyCount, allReady = readAllReadyFiles()
    if not allReady then
        local helperTotal = 0
        for _, n in ipairs(LOCAL_HELPERS) do
            if Players:FindFirstChild(n) then helperTotal = helperTotal + 1 end
        end
        setStatus(string.format("Main | Cho helper ready %d/%d...", readyCount, helperTotal))
        return nil
    end

    local countdownVal = tonumber(Settings["V3 Countdown"]) or tonumber(getgenv().Config and getgenv().Config["V3 Countdown"]) or 3
    local now     = v3ServerNow()
    local fireAt  = now + countdownVal
    local roundId = sanitize(USERNAME) .. "_" .. tostring(math.floor(fireAt * 1000))

    local members = {}
    local seen    = {}
    local function addMember(name)
        name = tostring(name or "")
        if name ~= "" and not seen[name] then seen[name] = true; table.insert(members, name) end
    end
    addMember(USERNAME)
    for _, name in ipairs(LOCAL_HELPERS) do
        addMember(name)
    end

    local command = {
        job_id     = game.JobId,
        round_id   = roundId,
        main       = USERNAME,
        members    = members,
        created_at = now,
        fire_at    = fireAt,
        expires_at = fireAt + 10,
        countdown  = countdownVal,
    }

    if safeWriteJson(commandPath(), command) then
        pcall(function()
            local f = groupFolder()
            if f then safeWriteJson(f .. "/command.json", command) end
        end)
        setStatus(string.format("Main | V3 countdown %.0fs...", countdownVal))
        return command
    end
    return nil
end

-- WAIT FOR SHARED FIRE TIME
local function waitForSharedFireTime(fireAt)
    while true do
        local remaining = fireAt - v3ServerNow()
        if remaining <= 0 then return end
        setStatus(string.format("V3 countdown %.2fs", remaining))
        if remaining > 0.25 then
            task.wait(math.min(0.10, math.max(0.03, remaining - 0.15)))
        else
            RunService.Heartbeat:Wait()
        end
    end
end

-- SCHEDULE WORKSPACE ROUND
local function scheduleWorkspaceRound(command)
    local roundId = tostring(command and command.round_id or "")
    local fireAt  = tonumber(command and command.fire_at) or 0
    if roundId == "" or fireAt <= 0 then return false end
    if roundId == handledRoundId or roundId == scheduledRoundId then return false end

    local inMembers = false
    for _, m in ipairs(command.members or {}) do
        if tostring(m) == USERNAME then inMembers = true; break end
    end
    if not inMembers then return false end

    scheduledRoundId = roundId

    task.spawn(function()
        waitForSharedFireTime(fireAt)

        local st    = localDoorState()
        local jobOk = tostring(command.job_id or "") == tostring(game.JobId)

        if jobOk and st.nearDoor and not st.timerVisible then
            setStatus(isUper and "Main | Kich hoat V3!" or "Helper | Kich hoat V3!")

            pcall(function()
                local hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.AssemblyLinearVelocity  = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                end
            end)

            for i = 1, V3_FIRE_COUNT do
                pcall(function()
                    ReplicatedStorage.Remotes.CommE:FireServer("ActivateAbility")
                end)
                pcall(function()
                    VirtualInputManager:SendKeyEvent(true, "T", false, game)
                    task.wait()
                    VirtualInputManager:SendKeyEvent(false, "T", false, game)
                end)
                if i < V3_FIRE_COUNT then task.wait(V3_FIRE_INTERVAL) end
            end

            handledRoundId  = roundId
            abilityCooldown = tick() + 30
            readySent       = false
            pcall(writeOwnReadyFile, true)

            task.spawn(function()
                local myRound = roundId
                for _ = 1, 15 do
                    task.wait(1)
                    if handledRoundId ~= myRound then return end
                    local ffaOk = false
                    pcall(function()
                        ffaOk = Workspace.Map["Temple of Time"].FFABorder.Forcefield.Transparency == 0
                    end)
                    if ffaOk then return end
                    local timerOk = false
                    pcall(function()
                        timerOk = (localPlayer.PlayerGui:FindFirstChild("Main") and localPlayer.PlayerGui.Main:FindFirstChild("Timer") and localPlayer.PlayerGui.Main.Timer.Visible == true)
                            or (localPlayer.PlayerGui:FindFirstChild("Main") and localPlayer.PlayerGui.Main:FindFirstChild("TopHUDList") and localPlayer.PlayerGui.Main.TopHUDList:FindFirstChild("RaidTimer") and localPlayer.PlayerGui.Main.TopHUDList.RaidTimer.Visible == true)
                    end)
                    if timerOk then return end
                end
                if handledRoundId ~= roundId then return end
                local st2       = localDoorState()
                local ffaActive = false
                local insideTrial = false
                pcall(function()
                    ffaActive = Workspace.Map["Temple of Time"].FFABorder.Forcefield.Transparency == 0
                end)
                pcall(function()
                    insideTrial = (localPlayer.PlayerGui:FindFirstChild("Main") and localPlayer.PlayerGui.Main:FindFirstChild("Timer") and localPlayer.PlayerGui.Main.Timer.Visible == true)
                        or (localPlayer.PlayerGui:FindFirstChild("Main") and localPlayer.PlayerGui.Main:FindFirstChild("TopHUDList") and localPlayer.PlayerGui.Main.TopHUDList:FindFirstChild("RaidTimer") and localPlayer.PlayerGui.Main.TopHUDList.RaidTimer.Visible == true)
                end)
                if st2.nearDoor and not ffaActive and not insideTrial then
                    setStatus("Ghost Temple! Resetting...")
                    handledRoundId  = ""
                    abilityCooldown = tick() + 8
                    pcall(function() localPlayer.Character.Humanoid.Health = 0 end)
                end
            end)
        else
            handledRoundId  = roundId
            abilityCooldown = tick() + 5
            readySent       = false
            pcall(writeOwnReadyFile, true)
            setStatus(string.format("[MISS] Cach cua %.0f studs - cho 5s", st.distance))
        end

        scheduledRoundId = ""
    end)
    return true
end

-- TRY ACTIVATE ABILITY
local activating = false

local function tryActivateAbility()
    if not (Settings["Multi Trial"] == true and Settings["Auto Turn On V3 Near Door"] == true) then
        return false
    end
    if activating then return false end
    if not (isnight() and isfullmoon()) then
        return false
    end

    local ffaNow = false
    pcall(function()
        ffaNow = Workspace.Map:FindFirstChild("Temple of Time") and Workspace.Map["Temple of Time"].FFABorder.Forcefield.Transparency == 0
    end)
    if ffaNow or tick() < abilityCooldown then return false end

    refreshTurnV3Roles()

    activating = true
    pcall(writeOwnReadyFile, false)

    local command = nil
    if isUper then
        command = mainCreateRound()
    else
        command = readV3Command()
        if not command then
            local st = localDoorState()
            setStatus(st.nearDoor and "Helper | Cho Main countdown..." or "Helper | Di toi cua...")
        else
            setStatus(string.format("Helper | Nhan lenh %.1fs",
                math.max(0, (tonumber(command.fire_at) or 0) - v3ServerNow())))
        end
    end

    activating = false
    if command then return scheduleWorkspaceRound(command) end
    return false
end

-- POLL LOOP (runs when Multi Trial + Auto Turn On V3 Near Door are enabled)
task.spawn(function()
    while task.wait(V3_FILE_POLL) do
        if Settings["Multi Trial"] == true and Settings["Auto Turn On V3 Near Door"] == true then
            pcall(tryActivateAbility)
        end
    end
end)

-- UI (TurnV3 Label góc phải giữa màn hình)
local PlayerGui = localPlayer:FindFirstChildOfClass("PlayerGui")
    or localPlayer:WaitForChild("PlayerGui", 10)

local StatusLabel = nil
local turnV3ScreenGui = nil

local function createTurnV3UI()
    pcall(function()
        local old = PlayerGui:FindFirstChild("TurnV3UI")
        if old then old:Destroy() end
    end)

    turnV3ScreenGui = Instance.new("ScreenGui")
    turnV3ScreenGui.Name           = "TurnV3UI"
    turnV3ScreenGui.ResetOnSpawn   = false
    turnV3ScreenGui.IgnoreGuiInset = true
    turnV3ScreenGui.Enabled        = (Settings["Multi Trial"] == true and Settings["Auto Turn On V3 Near Door"] == true)
    turnV3ScreenGui.Parent         = PlayerGui

    StatusLabel = Instance.new("TextLabel", turnV3ScreenGui)
    StatusLabel.Size                   = UDim2.new(0, 280, 0, 26)
    StatusLabel.Position               = UDim2.new(1, -290, 0.5, -13)
    StatusLabel.AnchorPoint            = Vector2.new(0, 0)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text                   = "TurnV3 | Loading..."
    StatusLabel.TextColor3             = Color3.fromRGB(200, 200, 200)
    StatusLabel.Font                   = Enum.Font.FredokaOne
    StatusLabel.TextSize               = 18
    StatusLabel.TextStrokeTransparency = 0.5
    StatusLabel.TextXAlignment         = Enum.TextXAlignment.Right
    StatusLabel.TextTruncate           = Enum.TextTruncate.AtEnd

    task.spawn(function()
        while turnV3ScreenGui and turnV3ScreenGui.Parent do
            task.wait(0.05)
            pcall(function()
                local isRunning = (Settings["Multi Trial"] == true and Settings["Auto Turn On V3 Near Door"] == true)
                if turnV3ScreenGui.Enabled ~= isRunning then
                    turnV3ScreenGui.Enabled = isRunning
                end
                if not isRunning then return end

                local s = currentStatus:lower()
                local color
                if s:find("countdown") then
                    color = Color3.fromRGB(255, 165, 40)
                elseif s:find("kich hoat") or s:find("v3!") then
                    color = Color3.fromRGB(50, 255, 100)
                elseif s:find("trial") or s:find("doing") then
                    color = Color3.fromRGB(50, 255, 100)
                elseif s:find("ghost") or s:find("miss") or s:find("reset") then
                    color = Color3.fromRGB(255, 80, 80)
                elseif s:find("cho") or s:find("wait") or s:find("nhan") then
                    color = Color3.fromRGB(100, 180, 255)
                else
                    color = Color3.fromRGB(200, 200, 200)
                end
                StatusLabel.TextColor3 = color
                StatusLabel.Text       = currentStatus
            end)
        end
    end)
end

pcall(createTurnV3UI)

function TrialHuman()
	if Workspace._WorldOrigin.Locations:FindFirstChild("Trial of Strength") then
		local StrengthPart = Workspace._WorldOrigin.Locations["Trial of Strength"]
		if (localPlayer.Character.HumanoidRootPart.Position - StrengthPart.Position).Magnitude <= 1000 then
			for unusedIndex, enemy in pairs(Workspace.Enemies:GetChildren()) do
				if
					IsMobAlive(enemy)
					and (enemy.HumanoidRootPart.Position - StrengthPart.Position).Magnitude <= 1000
				then
					return enemy
				end
			end
		end
	end
end

function TrialGhoul()
	if Workspace._WorldOrigin.Locations:FindFirstChild("Trial of Carnage") then
		if
			(
				localPlayer.Character.HumanoidRootPart.Position
				- Workspace._WorldOrigin.Locations["Trial of Carnage"].Position
			).Magnitude <= 1000
		then
			for unusedIndex, enemy in pairs(Workspace.Enemies:GetChildren()) do
				if
					IsMobAlive(enemy)
					and (
							enemy.HumanoidRootPart.Position
							- Workspace._WorldOrigin.Locations["Trial of Carnage"].Position
						).Magnitude
						<= 1000
				then
					return enemy
				end
			end
		end
	end
end

function GetSeaBeastTrial()
	if not Workspace.Map:FindFirstChild("FishmanTrial") then
		return
	end
	local part2 = Workspace._WorldOrigin.Locations:FindFirstChild("Trial of Water")
	if part2 and Workspace:FindFirstChild("SeaBeasts") then
		local iterator2, state2, initialKey2 = next, Workspace.SeaBeasts:GetChildren()
		for unusedIndex, value7 in iterator2, state2, initialKey2 do
			if
				string.find(value7.Name, "SeaBeast")
				and (value7:FindFirstChild("HumanoidRootPart"))
				and (value7.HumanoidRootPart.Position - part2.Position).Magnitude <= 1500
			then
				if value7:FindFirstChild("Health") and value7.Health.Value > 0 then
					return value7
				end
			end
		end
	end
end

function TeleportSeabeast2(seaBeast)
	if not seaBeast:FindFirstChild("HumanoidRootPart") then return end
	if
		(Vector3.new(0, seaBeast.HumanoidRootPart.Position.Y, 0) - Vector3.new(0, -60, 0)).Magnitude
		<= 175
	then
		ToTarget(seaBeast.HumanoidRootPart.CFrame * CFrame.new(0, 200, 50))
	else
		ToTarget(CFrame.new(seaBeast.HumanoidRootPart.Position.X, 140, seaBeast.HumanoidRootPart.Position.Z))
	end
end

function CheckCDSkill(skillName)
	if not localPlayer.PlayerGui:FindFirstChild("Main") or not localPlayer.PlayerGui.Main:FindFirstChild("Skills") or not localPlayer.PlayerGui.Main.Skills:FindFirstChild(skillName) then
		EquipTool(skillName)
		return
	end
	local iterator2, state2, initialKey2 =
		next, localPlayer.PlayerGui.Main.Skills[skillName]:GetChildren()
	for unusedIndex, value7 in iterator2, state2, initialKey2 do
		if value7:IsA("Frame") then
			if
				value7.Name ~= "Template"
					and value7:FindFirstChild("Title")
					and value7.Title.TextColor3 == Color3.new(1, 1, 1)
					and value7:FindFirstChild("Cooldown")
					and (value7.Cooldown.Size == UDim2.new(0, 0, 1, -1)
					or value7.Cooldown.Size == UDim2.new(1, 0, 1, -1))
			then
				return value7
			end
		end
	end
end

function VerifyNearbyTrial()
	local items19 = {
		"Trial of the Machine",
		"Trial of Speed",
		"Trial of Strength",
		"Trial of Water",
		"Trial of the King",
		"Trial of Carnage",
		"Trial of Flames",
	}
	if not Workspace:FindFirstChild("_WorldOrigin") or not Workspace._WorldOrigin:FindFirstChild("Locations") then return false end
	for unusedIndex, value7 in next, Workspace._WorldOrigin.Locations:GetChildren() do
		if table.find(items19, value7.Name) and localPlayer:DistanceFromCharacter(value7.Position) < 1500 then
			return true
		end
	end
	return false
end

-- Forward references for Fluent Toggles
local ToggleAutoTrial
local ToggleHopServerTrial

function AutoTrialV4()
	if Settings["Auto Finish Train Quest"] and Settings["Stack Train With Trial Race"] and (CheckGoTrain()) then
		return
	end
	local lookup6 = Lighting.ClockTime
	if
		(CheckMoon() == "Full Moon" and not (lookup6 > 5 and lookup6 < 12) or CheckMoon() == "Next Night")
		and Settings["Hop Server [Trial Or Pull Lever]"]
	then
		if ToggleHopServerTrial then
			ToggleHopServerTrial:SetValue(false)
		end
		task.wait(3)
	elseif Settings["Hop Server [Trial Or Pull Lever]"] then
		HopServer()
		return
	end
	if not IsInTempleOfTime() and not VerifyNearbyTrial() then
		if TeleportTempleOfTime() == "locked" then
			uiLibrary.CreateNoti({ Title = "Skider Hub V4", Desc = "Temple of Time is locked", ShowTime = 5 })
			task.wait(5)
		end
		return
	end
	lookup6 = GetTempleOfTime()
	if
		lookup6
			and (lookup6:FindFirstChild("FFABorder"))
			and (lookup6.FFABorder:FindFirstChild("Forcefield"))
			and lookup6.FFABorder.Forcefield.Transparency == 1
		or (VerifyNearbyTrial())
	then
		if localPlayer.PlayerGui:FindFirstChild("Main") and localPlayer.PlayerGui.Main:FindFirstChild("TopHUDList") and localPlayer.PlayerGui.Main.TopHUDList:FindFirstChild("RaidTimer") and localPlayer.PlayerGui.Main.TopHUDList.RaidTimer.Visible then
			if VerifyNearbyTrial() and not getgenv().VerifyTrial then
				getgenv().VerifyTrial = true
			end
			repeat
				wait()
			until VerifyNearbyTrial()
				or not localPlayer.PlayerGui.Main.TopHUDList.RaidTimer.Visible
			local localPlayer4 = localPlayer.Data.Race.Value
			if localPlayer4 == "Human" or localPlayer4 == "Ghoul" then
				local trialLocName = (localPlayer4 == "Human") and "Trial of Strength" or "Trial of Carnage"
				local trialPlace = Workspace._WorldOrigin.Locations:FindFirstChild(trialLocName)
				repeat
					task.wait()
					local character3 = (localPlayer4 == "Human") and TrialHuman() or TrialGhoul()
					if character3 and character3:FindFirstChild("HumanoidRootPart") and character3:FindFirstChild("Humanoid") and character3.Humanoid.Health > 0 then
						repeat
							task.wait()
							EquipTool(NameWeapon(Settings["Select Weapon"]))
							pcall(function()
								ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso")
							end)
							SizePart(character3)
							ToTarget(character3.HumanoidRootPart.CFrame * CFrame.new(0, 30, 0))
							ClickM1(character3)
							UsedualFlock()
						until not IsMobAlive(character3)
							or not localPlayer.PlayerGui.Main.TopHUDList.RaidTimer.Visible
							or (trialPlace and (localPlayer.Character.HumanoidRootPart.Position - trialPlace.Position).Magnitude > 1000)
					end
				until not localPlayer.PlayerGui.Main.TopHUDList.RaidTimer.Visible
					or (trialPlace and (localPlayer.Character.HumanoidRootPart.Position - trialPlace.Position).Magnitude > 1000)
			elseif localPlayer4 == "Skypiea" then
				repeat
					task.wait()
					pcall(function()
						if Workspace.Map:FindFirstChild("SkyTrial") and Workspace.Map.SkyTrial:FindFirstChild("Model") and Workspace.Map.SkyTrial.Model:FindFirstChild("FinishPart") then
							ToTarget(Workspace.Map.SkyTrial.Model.FinishPart.CFrame)
						end
					end)
					task.wait(1)
				until not localPlayer.PlayerGui.Main.TopHUDList.RaidTimer.Visible
					or (Workspace.Map:FindFirstChild("Temple of Time") and Workspace.Map["Temple of Time"]:FindFirstChild("FFABorder") and Workspace.Map["Temple of Time"].FFABorder.Forcefield.Transparency == 0)
			elseif localPlayer4 == "Fishman" then
				local part2 = Workspace._WorldOrigin.Locations:FindFirstChild("Trial of Water")
				if part2 and localPlayer:DistanceFromCharacter(part2.Position) < 1500 then
					local humanoid4 = GetSeaBeastTrial()
					if not localPlayer.Backpack:FindFirstChild("Sharkman Karate") and not (localPlayer.Character and localPlayer.Character:FindFirstChild("Sharkman Karate")) then
						pcall(function()
							ReplicatedStorage.Remotes.CommF_:InvokeServer("BuySharkmanKarate")
						end)
					end
					pcall(function() EquipTool("Sharkman Karate") end)
					repeat
						task.wait()
						if humanoid4 and humanoid4:FindFirstChild("HumanoidRootPart") and humanoid4:FindFirstChild("Health") and humanoid4.Health.Value > 0 then
							local rootPart7 = humanoid4.HumanoidRootPart
							getgenv().AimPos = CFrame.new(rootPart7.Position.X, 40, rootPart7.Position.Z)
							ToTarget(rootPart7.CFrame * CFrame.new(0, 500, 0))
							AutoAllSkill()
						else
							humanoid4 = GetSeaBeastTrial()
						end
					until not humanoid4
						or not humanoid4.Parent
						or (humanoid4:FindFirstChild("Health") and humanoid4.Health.Value == 0)
						or not localPlayer.PlayerGui.Main.TopHUDList.RaidTimer.Visible
						or (Workspace.Map:FindFirstChild("Temple of Time") and Workspace.Map["Temple of Time"]:FindFirstChild("FFABorder") and Workspace.Map["Temple of Time"].FFABorder.Forcefield.Transparency == 0)
				end
			elseif localPlayer4 == "Mink" then
				repeat
					task.wait()
					pcall(function()
						if Workspace.Map:FindFirstChild("MinkTrial") and Workspace.Map.MinkTrial:FindFirstChild("Ceiling") then
							ToTarget(Workspace.Map.MinkTrial.Ceiling.CFrame * CFrame.new(0, -20, 0))
						elseif Workspace:FindFirstChild("StartPoint") then
							ToTarget(Workspace.StartPoint.CFrame * CFrame.new(0, 2, 0))
						end
					end)
					task.wait(1)
				until not localPlayer.PlayerGui.Main.TopHUDList.RaidTimer.Visible
					or (Workspace.Map:FindFirstChild("Temple of Time") and Workspace.Map["Temple of Time"]:FindFirstChild("FFABorder") and Workspace.Map["Temple of Time"].FFABorder.Forcefield.Transparency == 0)
			elseif localPlayer4 == "Cyborg" then
				repeat
					task.wait()
					pcall(function()
						if Workspace.Map:FindFirstChild("CyborgTrial") and Workspace.Map.CyborgTrial:FindFirstChild("Floor") then
							ToTarget(Workspace.Map.CyborgTrial.Floor.CFrame * CFrame.new(0, 500, 0))
						else
							ToTarget(CFrame.new(28282.5703125, 15396.8505859375, 105.1042709350586))
						end
					end)
					task.wait(1)
				until not localPlayer.PlayerGui.Main.TopHUDList.RaidTimer.Visible
					or (Workspace.Map:FindFirstChild("Temple of Time") and Workspace.Map["Temple of Time"]:FindFirstChild("FFABorder") and Workspace.Map["Temple of Time"].FFABorder.Forcefield.Transparency == 0)
			end
		else
			if not lookup6 then
				return
			end
			if lookup6:FindFirstChild(localPlayer.Data.Race.Value .. "Corridor") then
				local part2 = lookup6[localPlayer.Data.Race.Value .. "Corridor"].Door.Door.RightDoor.Union
				if localPlayer:DistanceFromCharacter(part2.Position) > 8 then
					ToTarget(part2.CFrame)
				end
				if not (Settings["Multi Trial"] and Settings["Auto Turn On V3 Near Door"]) then
					if
						Settings["Multi Trial"]
						and (CheckMultiTeleDoor())
						and localPlayer:DistanceFromCharacter(part2.Position) <= 8
					then
						VirtualInputManager:SendKeyEvent(true, "T", false, game)
						task.wait()
						VirtualInputManager:SendKeyEvent(false, "T", false, game)
						return
					end
					if Settings["Auto Turn On V3 Near Door"] and (CheckMultiPlayerNearDoor()) then
						VirtualInputManager:SendKeyEvent(true, "T", false, game)
						task.wait()
						VirtualInputManager:SendKeyEvent(false, "T", false, game)
					end
				end
			end
		end
	elseif getgenv().VerifyTrial then
		if not Settings["Multi Trial"] and not Settings["Auto Reset Character"] then
			Settings["Auto Trial"] = false
			if ToggleAutoTrial then
				ToggleAutoTrial:SetValue(false)
			end
		end
		getgenv().VerifyTrial = false
	end
end

function PlayerTrial()
	if not Workspace.Map:FindFirstChild("Temple of Time") or not Workspace.Map["Temple of Time"]:FindFirstChild("FFABorder") then return nil end
	local player = Workspace.Map["Temple of Time"].FFABorder.Forcefield
	local position9, value7 = player.Position, player.Size
	for key, value8 in pairs(Workspace:FindPartsInRegion3(Region3.new(position9 - value7 / 2, position9 + value7 / 2), nil, math.huge)) do
		key = value8.Parent
		if key and (key:FindFirstChild("Humanoid")) then
			local plr = Players:GetPlayerFromCharacter(key)
			if plr and plr.Name ~= localPlayer.Name and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
				return plr.Character
			end
		end
	end
end

-- Fixed variable shadowing for cooldown cache (ngu.md bug fix)
local cachedCooldownAttributes = nil
function HasCooldownChanged(skillButton)
	local value7, value8 = skillButton:GetAttributes(), cachedCooldownAttributes
	if not value8 then
		cachedCooldownAttributes = skillButton:GetAttributes()
	end
	for key, value9 in next, value7, nil do
		if
			(
				string.find(key, "GunCooldown")
				or (string.find(key, "MeleeCooldown"))
				or (string.find(key, "SwordCooldown"))
				or (string.find(key, "BloxFruitCooldown"))
			) and value9 > 0
		then
			if cachedCooldownAttributes[key] ~= value9 then
				cachedCooldownAttributes = value7
				return true
			end
		end
	end
	return false
end

--------------------------------------------------------------------------------
-- 6. FLUENT UI BUILDING (Tabs, Sections, Toggles, Dropdowns, Buttons)
--------------------------------------------------------------------------------

-- ==============================================================================
-- STATUS & SERVER LOGIC & HELPERS
-- ==============================================================================
local scriptStartTime = tick()

local function getScriptTimer()
    local elapsed = math.floor(tick() - scriptStartTime)
    local h = math.floor(elapsed / 3600)
    local m = math.floor((elapsed % 3600) / 60)
    local s = elapsed % 60
    return string.format("%02dh %02dm %02ds", h, m, s)
end

local function getRealServerNow()
    local ok, now = pcall(function()
        return workspace:GetServerTimeNow()
    end)
    if ok and type(now) == "number" then
        return now
    end
    return os.time()
end

local function formatServerAge(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    local d = math.floor(seconds / 86400)
    local h = math.floor((seconds % 86400) / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    if d > 0 then
        return string.format("%dd %02dh %02dm %02ds", d, h, m, s)
    elseif h > 0 then
        return string.format("%dh %02dm %02ds", h, m, s)
    end
    return string.format("%dm %02ds", m, s)
end

local function getServerAge()
    local locations = workspace:FindFirstChild("_WorldOrigin") and workspace._WorldOrigin:FindFirstChild("Locations")
    if not locations then return "Unavailable" end
    local now = getRealServerNow()
    local gz = locations:FindFirstChild("Green Zone")
    if gz then
        local v = gz:GetAttribute("TimeIn")
        if v and type(v) == "number" and v > 1400000000 and v <= now + 60 then
            return formatServerAge(now - v)
        end
    end
    local earliest = nil
    for _, obj in ipairs(locations:GetDescendants()) do
        local v = obj:GetAttribute("TimeIn")
        if v and type(v) == "number" and v > 1400000000 and v <= now + 60 then
            if not earliest or v < earliest then
                earliest = v
            end
        end
    end
    if earliest then
        return formatServerAge(now - earliest)
    end
    return "Unavailable"
end

local function CheckMoon()
    local mapAttr = workspace:GetAttribute("MAP")
    local sea = tonumber(tostring(mapAttr or ""):match("%d+")) or 3
    local t = (sea == 1 or sea == 3)
        and ((Lighting:FindFirstChild("Sky") and Lighting.Sky.MoonTextureId)
        or (Lighting:FindFirstChild("Space_Skybox") and Lighting.Space_Skybox.MoonTextureId))
        or (sea == 2 and Lighting:FindFirstChild("FantasySky") and Lighting.FantasySky.MoonTextureId)
        or ""
    t = tostring(t):gsub("rbxassetid://", "http://www.roblox.com/asset/?id=")
    local textures = {
        ["http://www.roblox.com/asset/?id=15493317929"] = "Blue Moon",
        ["http://www.roblox.com/asset/?id=9709149431"]  = "8/8",
        ["http://www.roblox.com/asset/?id=9709149052"]  = "7/8",
        ["http://www.roblox.com/asset/?id=9709143733"]  = "6/8",
        ["http://www.roblox.com/asset/?id=9709150401"]  = "5/8",
        ["http://www.roblox.com/asset/?id=9709135895"]  = "4/8",
        ["http://www.roblox.com/asset/?id=9709150086"]  = "2/8",
        ["http://www.roblox.com/asset/?id=9709139597"]  = "1/8",
        ["http://www.roblox.com/asset/?id=9709149680"]  = "0/8",
    }
    return textures[t] or "Unknown"
end

local function CheckMoonPhase()
    local m = Lighting:GetAttribute("MoonPhase")
    if not m then return "Unknown" end
    if m > 5 then return "Fake Moon (" .. m .. ")"
    elseif m < 5 then return "Bad Moon (" .. m .. ")"
    elseif m == 5 and not getgenv().isfmended then return "Full Moon Up (5)"
    elseif m == 5 and getgenv().isfmended then return "Full Moon Ended"
    end
    return tostring(m)
end

local function GetTimeToNight()
    local n = Lighting.ClockTime
    if n >= 18 or n < 6 then return "Night Now" end
    local d = 18 - n
    local s = math.floor((d / 24) * 1200)
    return string.format("%dm %02ds", math.floor(s / 60), s % 60)
end

local function GetTimeEndFullmoon()
    local n = Lighting.ClockTime
    if not (n >= 18 or n < 6) then return "Daytime" end
    local d = (n >= 18) and ((24 - n) + 6) or (6 - n)
    local s = math.floor((d / 24) * 1200)
    return string.format("%dm %02ds", math.floor(s / 60), s % 60)
end

local function CheckMirageIsland()
    local loc = workspace:FindFirstChild("_WorldOrigin") and workspace._WorldOrigin:FindFirstChild("Locations")
    local mirage = (loc and (loc:FindFirstChild("Mirage Island") or loc:FindFirstChild("Mystic Island")))
        or (workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("MysticIsland"))
    return mirage ~= nil
end

local function GetAncientOneStatus()
    local code, progress = nil, nil
    pcall(function()
        code, progress = ReplicatedStorage.Remotes.CommF_:InvokeServer("UpgradeRace", "Check")
    end)
    if code == nil then
        local vp = nil
        pcall(function()
            vp = ReplicatedStorage.Remotes.CommF_:InvokeServer("RaceV4Progress", "Check")
        end)
        if vp == nil then
            return "—"
        elseif tonumber(vp) and tonumber(vp) >= 4 then
            return "Ready For Trial"
        elseif tonumber(vp) == 0 then
            return "Quest Not Started"
        else
            return "Quest " .. tostring(vp) .. "/5"
        end
    elseif code == 0 then
        return "Ready For Trial"
    elseif code == 5 then
        return "V4 Completed"
    elseif code == 8 then
        local rem = math.max(0, 10 - (progress or 0))
        if rem > 0 then
            return "Mastery (" .. rem .. " left)"
        else
            return "Mastery Done"
        end
    elseif code == 1 or code == 3 then
        return "Training Required"
    elseif code == 2 or code == 4 or code == 7 then
        return "Buy Upgrade"
    elseif code == 6 then
        local done = math.clamp((progress or 2) - 2, 0, 3)
        return "Training (" .. done .. "/3)"
    else
        return "State: " .. tostring(code)
    end
end

local function cleanAndValidateJobId(jobId)
    if not jobId or jobId == "" then return nil end
    local clean = tostring(jobId):gsub("%s", ""):gsub("[^%w%-]", "")
    if clean and #clean >= 10 then
        return clean
    end
    return nil
end

local function joinServerByJobId(jobId)
    local clean = cleanAndValidateJobId(jobId)
    if not clean then return false end
    local success = pcall(function()
        local sb = ReplicatedStorage:FindFirstChild("__ServerBrowser") or ReplicatedStorage:WaitForChild("__ServerBrowser", 5)
        if sb then
            sb:InvokeServer("teleport", clean)
        end
    end)
    return success
end

local _hopTried = {}
_hopTried[tostring(game.JobId)] = true

local function HopServerLessPlayer()
    uiLibrary.CreateNoti({ Title = "Skider Hub V4", Desc = "Scanning 100 pages for low-player servers...", ShowTime = 4 })
    task.spawn(function()
        local browser = ReplicatedStorage:FindFirstChild("__ServerBrowser") or ReplicatedStorage:WaitForChild("__ServerBrowser", 5)
        if not browser then
            HopServer()
            return
        end
        local byJob = {}
        local completed = 0
        local MAX_PAGES = 100
        local MAX_PLAYERS = 7

        for page = 1, MAX_PAGES do
            task.delay((page - 1) * 0.02, function()
                local servers = nil
                for attempt = 1, 3 do
                    local ok, res = pcall(function()
                        return browser:InvokeServer(page)
                    end)
                    if ok and type(res) == "table" then
                        servers = res
                        break
                    end
                    if attempt < 3 then task.wait(0.15) end
                end

                if type(servers) == "table" then
                    for jid, data in pairs(servers) do
                        if type(data) == "table" then
                            local idStr = tostring(jid or "")
                            local count = tonumber(data.Count or data.count or data.playing)
                            if idStr ~= ""
                                and count
                                and count >= 1
                                and count <= MAX_PLAYERS
                                and idStr ~= tostring(game.JobId)
                                and not _hopTried[idStr]
                            then
                                local old = byJob[idStr]
                                if not old or count < old.players then
                                    byJob[idStr] = { id = idStr, players = count }
                                end
                            end
                        end
                    end
                end
                completed = completed + 1
            end)
        end

        local deadline = tick() + 7
        repeat task.wait(0.03) until completed >= MAX_PAGES or tick() >= deadline

        local buckets, counts = {}, {}
        for _, sv in pairs(byJob) do
            local c = math.floor(sv.players)
            if not buckets[c] then
                buckets[c] = {}
                table.insert(counts, c)
            end
            table.insert(buckets[c], sv)
        end
        table.sort(counts)

        local pool = {}
        local rng = Random.new()
        for _, c in ipairs(counts) do
            local bucket = buckets[c]
            for i = #bucket, 2, -1 do
                local j = rng:NextInteger(1, i)
                bucket[i], bucket[j] = bucket[j], bucket[i]
            end
            for _, sv in ipairs(bucket) do
                table.insert(pool, sv)
            end
        end

        if #pool > 0 then
            for idx, sv in ipairs(pool) do
                _hopTried[sv.id] = true
                uiLibrary.CreateNoti({ Title = "Skider Hub V4", Desc = string.format("Hop Low: Joining [%d/%d] (%d players)...", idx, #pool, sv.players), ShowTime = 3 })
                local ok = pcall(function()
                    browser:InvokeServer("teleport", sv.id)
                end)
                if ok then
                    task.wait(2)
                    return
                end
                task.wait(0.2)
            end
        else
            uiLibrary.CreateNoti({ Title = "Skider Hub V4", Desc = "No server <= 7 players in 100 pages, standard hopping...", ShowTime = 3 })
            table.clear(_hopTried)
            _hopTried[tostring(game.JobId)] = true
            HopServer()
        end
    end)
end

-- [[ TAB: STATUS & SERVER ]]
local StatusSection = Tabs.StatusServer:AddSection("Game & V4 Status")

local StatusParagraph = Tabs.StatusServer:AddParagraph({
    Title = "Live Environment & Quest Status",
    Content = "Loading status..."
})

local ServerSection = Tabs.StatusServer:AddSection("Server Controller")

local ServerInfoParagraph = Tabs.StatusServer:AddParagraph({
    Title = "Server Details",
    Content = "Place ID: " .. tostring(game.PlaceId) .. " (" .. tostring(workspace:GetAttribute("MAP") or "Sea") .. ")" ..
              "\nJob ID: " .. tostring(game.JobId) ..
              "\nPlayers: " .. tostring(#Players:GetPlayers()) .. "/" .. tostring(Players.MaxPlayers)
})

local inputTargetJobID = ""
local spamJoinEnabled = false

Tabs.StatusServer:AddInput("InputJobID", {
    Title = "Input JobID",
    Default = "",
    Placeholder = "Enter or paste JobID...",
    Numeric = false,
    Finished = false,
    Callback = function(val)
        inputTargetJobID = val
    end
})

local ToggleSpamJoin = Tabs.StatusServer:AddToggle("SpamJoin", {
    Title = "Spam Join (1s / time)",
    Description = "Spam connect to entered JobID every 1 second",
    Default = false,
    Callback = function(enabled)
        spamJoinEnabled = enabled
    end
})

Tabs.StatusServer:AddButton({
    Title = "Join JobID",
    Description = "Directly connect to entered JobID",
    Callback = function()
        local clean = cleanAndValidateJobId(inputTargetJobID)
        if clean then
            uiLibrary.CreateNoti({ Title = "Skider Hub V4", Desc = "Connecting to " .. clean:sub(1, 8) .. "...", ShowTime = 3 })
            joinServerByJobId(clean)
        else
            uiLibrary.CreateNoti({ Title = "Skider Hub V4", Desc = "Please input a valid JobID!", ShowTime = 3 })
        end
    end
})

Tabs.StatusServer:AddButton({
    Title = "Copy JobID",
    Description = "Copy current JobID to clipboard",
    Callback = function()
        pcall(function()
            if setclipboard then
                setclipboard(tostring(game.JobId))
                uiLibrary.CreateNoti({ Title = "Skider Hub V4", Desc = "Copied JobID to clipboard!", ShowTime = 3 })
            end
        end)
    end
})

Tabs.StatusServer:AddButton({
    Title = "Hop Server",
    Description = "Hop to a random server",
    Callback = function()
        HopServer()
    end
})

Tabs.StatusServer:AddButton({
    Title = "Hop Server Less Player",
    Description = "Scan 100 pages for lowest player server & join",
    Callback = function()
        HopServerLessPlayer()
    end
})

-- Heartbeat / Loop Live Update for Status Tab
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local timerStr = getScriptTimer()
            local serverAgeStr = getServerAge()
            local moonStr = CheckMoon()
            local moonPhaseStr = CheckMoonPhase()
            local toNightStr = GetTimeToNight()
            local toEndFMStr = GetTimeEndFullmoon()
            local mirageStr = CheckMirageIsland() and "Spawned ✅" or "Not Spawned ❌"
            local valkStr = (CheckItemInventory("Valkyrie Helm") or CheckItemInventory("Valkyrie Helmet")) and "Owned ✅" or "Not Owned ❌"
            local fractalStr = CheckItemInventory("Mirror Fractal") and "Owned ✅" or "Not Owned ❌"
            local ancientStr = GetAncientOneStatus()

            StatusParagraph:SetDesc(
                "• Timer: " .. timerStr .. "\n" ..
                "• Server Timer: " .. serverAgeStr .. "\n" ..
                "• Moon Phase: " .. moonStr .. " (" .. moonPhaseStr .. ")\n" ..
                "• Time ToNight: " .. toNightStr .. "\n" ..
                "• Time EndFullmoon: " .. toEndFMStr .. "\n" ..
                "• Mirage Island: " .. mirageStr .. "\n" ..
                "• Valkyrie Helm: " .. valkStr .. "\n" ..
                "• Mirror Fractal: " .. fractalStr .. "\n" ..
                "• Ancient One: " .. ancientStr
            )

            ServerInfoParagraph:SetDesc(
                "• Place ID: " .. tostring(game.PlaceId) .. " (" .. tostring(workspace:GetAttribute("MAP") or "Sea") .. ")\n" ..
                "• Current JobID: " .. tostring(game.JobId) .. "\n" ..
                "• Players: " .. tostring(#Players:GetPlayers()) .. "/" .. tostring(Players.MaxPlayers)
            )
        end)
    end
end)

-- Background Spam Join Loop (1s per attempt)
task.spawn(function()
    while true do
        if spamJoinEnabled and inputTargetJobID and inputTargetJobID ~= "" then
            local clean = cleanAndValidateJobId(inputTargetJobID)
            if clean then
                joinServerByJobId(clean)
            end
        end
        task.wait(1)
    end
end)

-- [[ TAB: RACE NORMAL ]]
local RaceNormalSection = Tabs.RaceNormal:AddSection("Race Normal")

Tabs.RaceNormal:AddDropdown("SelectWeapon", {
    Title = "Select Weapon",
    Values = { "Melee", "Sword", "Blox Fruit" },
    Default = Settings["Select Weapon"] or "Melee",
    Callback = function(val)
        SaveSettings("Select Weapon", val)
    end
})

local ToggleAutoUpgradeV2V3 = Tabs.RaceNormal:AddToggle("AutoUpgradeV2V3", {
    Title = "Auto Upgrade Race V2-V3",
    Default = Settings["Auto Upgrade Race V2-V3"] or false,
    Callback = function(enabled)
        SaveSettings("Auto Upgrade Race V2-V3", enabled)
    end
})

local CyborgSection = Tabs.RaceNormal:AddSection("Cyborg & Ghoul")

local ToggleAutoGetCyborg = Tabs.RaceNormal:AddToggle("AutoGetCyborg", {
    Title = "Auto Get Cyborg",
    Default = Settings["Auto Get Cyborg"] or false,
    Callback = function(enabled)
        SaveSettings("Auto Get Cyborg", enabled)
    end
})

ToggleAutoGetFullyCyborg = Tabs.RaceNormal:AddToggle("AutoGetFullyCyborg", {
    Title = "Auto Get Fully Cyborg",
    Default = Settings["Auto Get Fully Cyborg"] or false,
    Callback = function(enabled)
        SaveSettings("Auto Get Fully Cyborg", enabled)
    end
})

Tabs.RaceNormal:AddToggle("AutoGetCyborgHopCollectChest", {
    Title = "Auto Get Cyborg Hop Collect Chest",
    Default = Settings["Auto Get Cyborg Hop Collect Chest"] or false,
    Callback = function(enabled)
        SaveSettings("Auto Get Cyborg Hop Collect Chest", enabled)
    end
})

local ToggleAutoGetGhoul = Tabs.RaceNormal:AddToggle("AutoGetGhoul", {
    Title = "Auto Get Ghoul",
    Default = Settings["Auto Get Ghoul"] or false,
    Callback = function(enabled)
        SaveSettings("Auto Get Ghoul", enabled)
    end
})

Tabs.RaceNormal:AddToggle("HopServerGetGhoul", {
    Title = "Hop Server Get Ghoul",
    Default = Settings["Hop Server Get Ghoul"] or false,
    Callback = function(enabled)
        SaveSettings("Hop Server Get Ghoul", enabled)
    end
})

-- [[ TAB: RACE V4 ]]
local RaceV4Section = Tabs.RaceV4:AddSection("Race V4")

Tabs.RaceV4:AddToggle("NoFrog", {
    Title = "No Fog",
    Default = Settings["No Frog"] or false,
    Callback = function(enabled)
        SaveSettings("No Frog", enabled)
        if enabled then
            Lighting.FogEnd = 100000
            for unusedIndex, child in pairs(Lighting:GetDescendants()) do
                if child:IsA("Atmosphere") then
                    child:Destroy()
                end
            end
        end
    end
})

Tabs.RaceV4:AddToggle("TeleportAcientClock", {
    Title = "Teleport Acient Clock",
    Default = Settings["Teleport Acient Clock"] or false,
    Callback = function(enabled)
        SaveSettings("Teleport Acient Clock", enabled)
    end
})

Tabs.RaceV4:AddButton({
    Title = "Teleport Temple of Time",
    Description = "Teleport instantly to Temple of Time",
    Callback = function()
        if TempleTeleporting then
            TempleTeleporting = false
            return
        end
        TempleTeleporting = true
        task.spawn(function()
            local started = tick()
            while TempleTeleporting and tick() - started < 120 do
                local success, state = pcall(TeleportTempleOfTime)
                if success and state == "locked" then
                    uiLibrary.CreateNoti({ Title = "Skider Hub V4", Desc = "Temple of Time bị khóa! Cần Race V3 và tiến trình V4.", ShowTime = 5 })
                    break
                elseif success and state == "arrived" then
                    uiLibrary.CreateNoti({ Title = "Skider Hub V4", Desc = "Đã vào Temple of Time thành công!", ShowTime = 5 })
                    break
                elseif success and state == "wrong_sea" then
                    break
                end
                task.wait(0.5)
            end
            TempleTeleporting = false
            TweenManager.CancelCurrent()
        end)
    end
})

local TogglePullLever = Tabs.RaceV4:AddToggle("AutoPullLeverV4", {
    Title = "Auto Pull Lever V4",
    Default = Settings["Auto Pull Lever V4"] or false,
    Callback = function(enabled)
        SaveSettings("Auto Pull Lever V4", enabled)
    end
})

Tabs.RaceV4:AddToggle("AutoBuyGear", {
    Title = "Auto Buy Gear",
    Default = Settings["Auto Buy Gear"] or false,
    Callback = function(enabled)
        SaveSettings("Auto Buy Gear", enabled)
    end
})

Tabs.RaceV4:AddDropdown("SelectGearV4", {
    Title = "Select Gear V4",
    Values = { "Alpha", "Omega" },
    Default = Settings["Select Gear V4"] or "Omega",
    Callback = function(val)
        SaveSettings("Select Gear V4", val)
    end
})

local ToggleAutoChooseGears = Tabs.RaceV4:AddToggle("AutoChooseGears", {
    Title = "Auto Choose Gears",
    Default = Settings["Auto Choose Gears"] or false,
    Callback = function(enabled)
        SaveSettings("Auto Choose Gears", enabled)
    end
})
getgenv().ToggleAutoChooseGears = ToggleAutoChooseGears

Tabs.RaceV4:AddToggle("AutoFinishTrainQuest", {
    Title = "Auto Finish Train Quest",
    Default = Settings["Auto Finish Train Quest"] or false,
    Callback = function(enabled)
        SaveSettings("Auto Finish Train Quest", enabled)
    end
})

Tabs.RaceV4:AddToggle("StackTrainWithTrialRace", {
    Title = "Stack Train With Trial Race",
    Default = Settings["Stack Train With Trial Race"] or false,
    Callback = function(enabled)
        SaveSettings("Stack Train With Trial Race", enabled)
    end
})

local function formatMultiDefault(raw)
    local def = {}
    if type(raw) == "table" then
        for k, v in pairs(raw) do
            if type(k) == "string" and v == true then
                def[k] = true
            elseif type(v) == "string" then
                def[v] = true
            end
        end
    end
    return def
end

local DropdownSelectNameHelper = Tabs.RaceV4:AddDropdown("SelectNameHelper", {
    Title = "Select Name Helper",
    Values = PrepareMultiSelectList(DetectNameMulti(), Settings["Name Helper TurnV3"] or Settings["Select Players Multi"]),
    Multi = true,
    Default = formatMultiDefault(Settings["Name Helper TurnV3"] or Settings["Select Players Multi"]),
    Callback = function(val)
        SaveSettings("Name Helper TurnV3", val)
        SaveSettings("Select Players Multi", val)
        if refreshTurnV3Roles then
            refreshTurnV3Roles()
        end
    end
})

Tabs.RaceV4:AddButton({
    Title = "Refresh Helper Player",
    Description = "Update helper player list in dropdown",
    Callback = function()
        local list = PrepareMultiSelectList(DetectNameMulti(true), Settings["Name Helper TurnV3"] or Settings["Select Players Multi"])
        DropdownSelectNameHelper:SetValues(list)
    end
})

Tabs.RaceV4:AddDropdown("V3Countdown", {
    Title = "V3 Countdown (Seconds)",
    Description = "Countdown time before turning V3 in Temple of Time",
    Values = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "10" },
    Default = tostring(Settings["V3 Countdown"] or 3),
    Callback = function(val)
        SaveSettings("V3 Countdown", tonumber(val) or 3)
    end
})

Tabs.RaceV4:AddToggle("MultiTrial", {
    Title = "Multi Trial",
    Default = Settings["Multi Trial"] or false,
    Callback = function(enabled)
        SaveSettings("Multi Trial", enabled)
    end
})

Tabs.RaceV4:AddToggle("AutoResetCharacter", {
    Title = "Auto Reset Character",
    Default = Settings["Auto Reset Character"] or false,
    Callback = function(enabled)
        SaveSettings("Auto Reset Character", enabled)
    end
})

ToggleAutoTrial = Tabs.RaceV4:AddToggle("AutoTrial", {
    Title = "Auto Trial",
    Default = Settings["Auto Trial"] or false,
    Callback = function(enabled)
        SaveSettings("Auto Trial", enabled)
    end
})

Tabs.RaceV4:AddToggle("AutoTurnOnV3NearDoor", {
    Title = "Auto Turn On V3 Near Door",
    Description = "will auto turn on race if have players near door",
    Default = Settings["Auto Turn On V3 Near Door"] or false,
    Callback = function(enabled)
        SaveSettings("Auto Turn On V3 Near Door", enabled)
    end
})

ToggleHopServerTrial = Tabs.RaceV4:AddToggle("HopServerTrialOrPullLever", {
    Title = "Hop Server [Trial Or Pull Lever]",
    Default = Settings["Hop Server [Trial Or Pull Lever]"] or false,
    Callback = function(enabled)
        SaveSettings("Hop Server [Trial Or Pull Lever]", enabled)
    end
})
getgenv().TurnOffHOPSVPullAndTrial = ToggleHopServerTrial

-- [[ TAB: KILL TRIAL ]]
local KillTrialSection = Tabs.KillTrial:AddSection("Kill Trial")

Tabs.KillTrial:AddDropdown("SelectWeaponAttackTrial", {
    Title = "Select Weapon Attack Trial",
    Values = { "Melee", "Sword", "Blox Fruit" },
    Default = Settings["Select Weapon Attack Trial"] or "Melee",
    Callback = function(val)
        SaveSettings("Select Weapon Attack Trial", val)
    end
})

Tabs.KillTrial:AddToggle("KillPlayersWhenCompleteTrial", {
    Title = "Kill players When complete Trial",
    Description = "Turn on before Start Attack and Turn on Auto Trial",
    Default = Settings["Kill players When complete Trial"] or false,
    Callback = function(enabled)
        SaveSettings("Kill players When complete Trial", enabled)
    end
})

Tabs.KillTrial:AddToggle("UseSkillWhenKillPlayer", {
    Title = "Use Skill when Kill Player",
    Default = Settings["Use Skill when Kill Player"] or false,
    Callback = function(enabled)
        SaveSettings("Use Skill when Kill Player", enabled)
    end
})

Tabs.KillTrial:AddToggle("JustUseSkillWhenPlayerActiveKen", {
    Title = "Just Use Skill when Player Active Ken",
    Default = Settings["Just Use Skill when Player Active Ken"] or false,
    Callback = function(enabled)
        SaveSettings("Just Use Skill when Player Active Ken", enabled)
    end
})

-- [[ TAB: SETTINGS & CONFIG ]]
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("SkiderV4")
SaveManager:SetFolder("SkiderV4/BloxFruits")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

--------------------------------------------------------------------------------
-- 7. WORKER LOOPS (Preserved and complete)
--------------------------------------------------------------------------------

-- Worker 1: Auto Upgrade Race V2-V3
task.spawn(function()
    while task.wait(0.1) do
        if Settings["Auto Upgrade Race V2-V3"] then
            pcall(UpgradeRaceV2AndV3)
        end
    end
end)

-- Worker 2: Auto Get Cyborg
task.spawn(function()
    while task.wait(0.2) do
        if Settings["Auto Get Cyborg"] or Settings["Auto Get Fully Cyborg"] then
            pcall(GetCyborg)
        end
    end
end)

-- Worker 3: Auto Get Ghoul
task.spawn(function()
    while task.wait(0.2) do
        if Settings["Auto Get Ghoul"] then
            pcall(GetRaceGhoul)
        end
    end
end)

-- Worker 4: Teleport Ancient Clock
task.spawn(function()
    while task.wait(0.2) do
        if Settings["Teleport Acient Clock"] then
            pcall(function()
                local state = TeleportTempleOfTime()
                if state == "locked" then
                    uiLibrary.CreateNoti({
                        Title = "Skider Hub V4",
                        Desc = "Temple of Time is locked",
                        ShowTime = 5,
                    })
                    task.wait(5)
                elseif state == "arrived" then
                    local temple = Workspace.Map:FindFirstChild("Temple of Time")
                    local prompt = temple and temple:FindFirstChild("Prompt")
                    if prompt then
                        ToTarget(prompt.CFrame)
                    end
                end
            end)
        end
    end
end)

-- Worker 5: Auto Pull Lever V4
task.spawn(function()
    while task.wait(0.3) do
        if Settings["Auto Pull Lever V4"] then
            pcall(PullLeverV4)
        end
    end
end)

-- Worker 6: Auto Buy Gear
task.spawn(function()
    while task.wait(0.2) do
        if Settings["Auto Buy Gear"] then
            pcall(BuyGearV4)
        end
    end
end)

-- Worker 7: Auto Choose Gears
task.spawn(function()
    while task.wait(0.3) do
        if Settings["Auto Choose Gears"] then
            pcall(ChooseGearV4)
        end
    end
end)

-- Worker 8: Auto Finish Train Quest
task.spawn(function()
    while task.wait(0.1) do
        if Settings["Auto Finish Train Quest"] then
            pcall(function()
                if Settings["Stack Train With Trial Race"] and not CheckGoTrain() then
                    return
                end
                TurnOnV4()
                BuyGearV4()
                local character3 = DetectMob(items6)
                if character3 then
                    repeat
                        task.wait()
                        SizePart(character3)
                        BringMob(character3)
                        UsedualFlock()
                        ClickM1(character3)
                        if Settings["Select Weapon"] == "Blox Fruit" then
                            ToTarget(character3.HumanoidRootPart.CFrame * CFrame.new(-7, 20, 0))
                        else
                            ToTarget(character3.HumanoidRootPart.CFrame * CFrame.new(7, 20, 0))
                        end
                    until not IsMobAlive(character3)
                        or not Settings["Auto Finish Train Quest"]
                        or not CheckGoTrain()
                elseif typeof(items6) == "table" then
                    if #items3 >= #items6 then
                        items3 = {}
                        return
                    end
                    local part2 = DetectPartSpawnMob(DetectNameTablePart(items6))
                    if part2 then
                        table.insert(items3, DetectNameTablePart(items6))
                        repeat
                            wait()
                            ToTarget(part2.CFrame * CFrame.new(0, 60, 0))
                        until localPlayer:DistanceFromCharacter(part2.Position) <= 100
                            or (DetectMob(items6))
                            or not Settings["Auto Finish Train Quest"]
                            or not CheckGoTrain()
                        wait(1)
                    end
                else
                    local part2 = DetectPartSpawnMob(items6, true)
                    if part2 then
                        Instance.new("IntValue", part2).Name = "Ignored"
                        repeat
                            wait()
                            ToTarget(part2.CFrame * CFrame.new(0, 60, 0))
                        until localPlayer:DistanceFromCharacter(part2.Position) <= 100
                            or (DetectMob(items6))
                            or not Settings["Auto Finish Train Quest"]
                            or not CheckGoTrain()
                        wait(1)
                    else
                        DeleteIgnoredMobSpawn()
                    end
                end
            end)
        end
    end
end)

local pos_plr_trial = {
    CFrame.new(28692.3477, 14887.5605, -53.7669983),
    CFrame.new(28782.7246, 14898.9902, -59.6069946),
    CFrame.new(28700.875, 14888.2598, -154.110992),
    CFrame.new(28795.7715, 14888.2598, -112.917999),
    CFrame.new(28658.4551, 14888.2598, -121.372009),
    CFrame.new(28742.4688, 14887.5596, -18.2120056)
}

-- Worker 9: Kill Players When Complete Trial
task.spawn(function()
    while task.wait(0.1) do
        pcall(function()
            if Settings["Kill players When complete Trial"] then
                local temple = GetTempleOfTime()
                if temple and temple:FindFirstChild("FFABorder") and temple.FFABorder:FindFirstChild("Forcefield") and temple.FFABorder.Forcefield.Transparency ~= 1 then
                    if localPlayer.PlayerGui:FindFirstChild("Main") and localPlayer.PlayerGui.Main:FindFirstChild("TopHUDList") and localPlayer.PlayerGui.Main.TopHUDList:FindFirstChild("RaidTimer") and localPlayer.PlayerGui.Main.TopHUDList.RaidTimer.Visible then
                        local character3 = PlayerTrial()
                        if not character3 then
                            for _, v in pairs(Players:GetPlayers()) do
                                if v ~= localPlayer and v.Character and v.Character:FindFirstChild("Humanoid") and v.Character:FindFirstChild("HumanoidRootPart") and v.Character.Humanoid.Health > 0 then
                                    for _, pos in pairs(pos_plr_trial) do
                                        if (v.Character.HumanoidRootPart.Position - pos.Position).Magnitude < 15 then
                                            character3 = v.Character
                                            break
                                        end
                                    end
                                    if character3 then break end
                                end
                            end
                        end
                        if character3 and character3:FindFirstChild("HumanoidRootPart") and character3:FindFirstChild("Humanoid") and character3.Humanoid.Health > 0 then
                            repeat
                                task.wait()
                                task.spawn(function()
                                    if Lighting:FindFirstChild("Blur") and not Lighting.Blur.Enabled then
                                        VirtualInputManager:SendKeyEvent(true, "E", false, game)
                                        task.wait()
                                        VirtualInputManager:SendKeyEvent(false, "E", false, game)
                                        task.wait(3)
                                    end
                                    getgenv().AimPos = character3.HumanoidRootPart.CFrame
                                end)
                                local offset = CFrame.new(
                                    (math.random(1, 2) == 1 and 1 or -1) * math.random(1, 4),
                                    3,
                                    (math.random(1, 2) == 1 and 1 or -1) * math.random(1, 4)
                                )
                                localPlayer.Character.HumanoidRootPart.CFrame = character3.HumanoidRootPart.CFrame * offset
                                EquipTool(NameWeapon(Settings["Select Weapon Attack Trial"]))
                                ClickM1(character3)
                                if Settings["Use Skill when Kill Player"] or Settings["Just Use Skill when Player Active Ken"] then
                                    local targetPlr = Players:FindFirstChild(character3.Name)
                                    if (Settings["Just Use Skill when Player Active Ken"] and targetPlr and targetPlr:GetAttribute("KenActive"))
                                        or not Settings["Just Use Skill when Player Active Ken"]
                                    then
                                        task.spawn(function()
                                            local object = CheckCDSkill(NameWeapon(Settings["Select Weapon Attack Trial"]))
                                            if object then
                                                VirtualInputManager:SendKeyEvent(true, object.Name, false, game)
                                                task.wait(0.05)
                                                VirtualInputManager:SendKeyEvent(false, object.Name, false, game)
                                            end
                                        end)
                                    end
                                end
                            until not character3
                                or not character3.Parent
                                or not character3:FindFirstChild("Humanoid")
                                or character3.Humanoid.Health <= 0
                                or not Settings["Kill players When complete Trial"]
                                or not localPlayer.PlayerGui.Main.TopHUDList.RaidTimer.Visible
                                or not localPlayer.Character
                                or not localPlayer.Character:FindFirstChild("Humanoid")
                                or localPlayer.Character.Humanoid.Health <= 0
                                or (temple and temple:FindFirstChild("FFABorder") and temple.FFABorder:FindFirstChild("Forcefield") and temple.FFABorder.Forcefield.Transparency == 1)
                        end
                    end
                end
            end
        end)
    end
end)

-- Worker 10: Auto Trial & Auto Reset Character
task.spawn(function()
    while task.wait(0.1) do
        if Settings["Auto Trial"] then
            pcall(AutoTrialV4)
        end
        if Settings["Auto Reset Character"] then
            pcall(function()
                local temple = GetTempleOfTime()
                if temple and temple.FFABorder.Forcefield.Transparency ~= 1 then
                    localPlayer.Character.Humanoid.Health = 0
                end
            end)
        end
    end
end)

uiLibrary.CreateNoti({ Title = "Skider Hub V4", Desc = "Script loaded successfully", ShowTime = 5 })
 
