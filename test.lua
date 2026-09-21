--[[
    Skider Hub V4 - Rebuilt with Fluent UI
    Original: kaiv4.lua
    Integrated modules: 3tn.lua (Tween speed = 150, BringMob, FastAttack)
    Bug fixes & Missing definitions: ngu.md
]]

repeat task.wait() until game:IsLoaded() and game:GetService("Players").LocalPlayer
task.wait(0.5)

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
-- SaveManager replaced with built-in Configuration & Copy Setting system
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
    RaceDraco    = Window:AddTab({ Title = "Race Draco", Icon = "flame" }),
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

local configFolder = "SkiderV4"
local lp = Players.LocalPlayer or Players.PlayerAdded:Wait()
while not lp or not lp.Name or lp.Name == "" do
    task.wait(0.05)
    lp = Players.LocalPlayer
end
local username = lp.Name
local configFilePath = configFolder .. "/" .. username .. "-kaiv4.json"

-- Tải cấu hình từ file JSON theo username người chơi (gộp toàn bộ vào thư mục SkiderV4)
local function LoadConfigFile()
    local function tryLoad(path)
        if isfile and readfile and isfile(path) then
            local success, content = pcall(readfile, path)
            if success and content and #content > 0 then
                local ok, data = pcall(function()
                    return HttpService:JSONDecode(content)
                end)
                if ok and type(data) == "table" then
                    for k, v in pairs(data) do
                        Settings[k] = v
                    end
                    return true
                end
            end
        end
        return false
    end

    -- 1. Đọc file cấu hình chuẩn trong thư mục SkiderV4/<username>-kaiv4.json
    if not tryLoad(configFilePath) then
        -- 2. Thử đọc SkiderV4/kaiv4.json
        if not tryLoad(configFolder .. "/kaiv4.json") then
            -- 3. Hỗ trợ đọc chuyển tiếp từ thư mục cũ Mtrchill nếu có
            if not tryLoad("Mtrchill/" .. username .. "-kaiv4.json") then
                tryLoad("Mtrchill/kaiv4.json")
            end
        end
    end
end

-- 1. Nạp file cấu hình đã lưu trước đó từ thư mục SkiderV4/<username>-kaiv4.json (nếu có)
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

if Settings["Auto Click"] == nil then
    Settings["Auto Click"] = true
end

local function WriteConfigFile()
    if not writefile then return end
    pcall(function()
        if makefolder and isfolder and not isfolder(configFolder) then
            makefolder(configFolder)
        end
        local encoded = HttpService:JSONEncode(Settings)
        writefile(configFilePath, encoded)
        writefile(configFolder .. "/kaiv4.json", encoded)
    end)
end

-- 3. Tự động lưu lại cấu hình mới nhất vào thư mục SkiderV4/<username>-kaiv4.json và SkiderV4/kaiv4.json
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

-- Race V4 Training Island Data & Engine (From piggyv4)
-- Chỉ train tại Haunted Castle (khoá cứng theo yêu cầu)
local TrainingIslandData = {
    ["Haunted Castle"] = {
        Position = CFrame.new(-9530.61035, 200.860657, 5763.13477),
        Mobs = { ["Reborn Skeleton"] = true, ["Living Zombie"] = true, ["Demonic Soul"] = true, ["Possessed Mummy"] = true }
    },
}
local TrainingIslandOrder = {
    "Haunted Castle"
}
local MAX_ACCS_PER_ISLAND = 2
local myAssignedIsland = nil
local isCurrentlyTraining = false
local currentTrainingStatus = "Idle"
local blockHopAfterTrial = false
local postTrialHopDone = false
local postTrialResetScheduled = false
local lastFFAState = 1

local function countAccountsAtIsland(islandName)
    local data = TrainingIslandData[islandName]
    if not data then return 0 end
    local islandPos
    if data.Positions then
        islandPos = data.Positions[1].Position
    else
        islandPos = data.Position.Position
    end
    local count = 0
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= localPlayer and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if hrp and (hrp.Position - islandPos).Magnitude < 1000 then
                count = count + 1
            end
        end
    end
    return count
end

local function assignTrainingIsland()
    local bestIsland = nil
    local bestCount = math.huge
    for _, islandName in ipairs(TrainingIslandOrder) do
        if TrainingIslandData[islandName] then
            local count = countAccountsAtIsland(islandName)
            if count < MAX_ACCS_PER_ISLAND and count < bestCount then
                bestCount = count
                bestIsland = islandName
            end
        end
    end
    if not bestIsland then
        for _, islandName in ipairs(TrainingIslandOrder) do
            if TrainingIslandData[islandName] then
                local count = countAccountsAtIsland(islandName)
                if count < bestCount then
                    bestCount = count
                    bestIsland = islandName
                end
            end
        end
    end
    myAssignedIsland = bestIsland or TrainingIslandOrder[1]
    return myAssignedIsland
end

local function forceReassignIsland()
    myAssignedIsland = nil
end

local function CheckMonster(...)
    local args = { ... }
    local containers = { Workspace:FindFirstChild("Enemies"), ReplicatedStorage }
    for i = 1, #args do
        for _, container in ipairs(containers) do
            if container then
                local m = container:FindFirstChild(args[i])
                if m and m:IsA("Model") and m.Name ~= "Blank Buddy" then
                    local h = m:FindFirstChildWhichIsA("Humanoid")
                    local r = m:FindFirstChild("HumanoidRootPart")
                    if h and r and h.Health > 0 then return m end
                end
            end
        end
    end
    for _, container in ipairs(containers) do
        if container then
            for _, m in ipairs(container:GetChildren()) do
                local h = m:FindFirstChild("Humanoid")
                local r = m:FindFirstChild("HumanoidRootPart")
                if m:IsA("Model") and h and r and h.Health > 0 and m.Name ~= "Blank Buddy" then
                    for i = 1, #args do
                        if m.Name == args[i] or m.Name:lower():find(args[i]:lower()) then
                            return m
                        end
                    end
                end
            end
        end
    end
    return nil
end

local function checkmob_(v)
    return v and v.Parent and v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0
end

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

-- [COMBAT & FAST ATTACK MODULE] Stable Engine from skider hub god max/loader.lua
local r, id
for _, v in {
    ReplicatedStorage:FindFirstChild("Util"),
    ReplicatedStorage:FindFirstChild("Common"),
    ReplicatedStorage:FindFirstChild("Remotes"),
    ReplicatedStorage:FindFirstChild("Assets"),
    ReplicatedStorage:FindFirstChild("FX"),
} do
    if v then
        for _, n in ipairs(v:GetChildren()) do
            if n:IsA("RemoteEvent") and n:GetAttribute("Id") then
                r, id = n, n:GetAttribute("Id")
            end
        end
        v.ChildAdded:Connect(function(n)
            if n:IsA("RemoteEvent") and n:GetAttribute("Id") then
                r, id = n, n:GetAttribute("Id")
            end
        end)
    end
end

-- equipWeapon tu loader.lua
function equipWeapon(weapon_type)
    if not weapon_type then
        weapon_type = Settings["Select Weapon"] or "Melee"
    end
    local char = localPlayer.Character
    if not char or not char:FindFirstChildOfClass("Humanoid") then return end
    if not char:FindFirstChild("HasBuso") then
        pcall(function()
            ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso")
        end)
    end
    local curTool = char:FindFirstChildOfClass("Tool")
    if curTool and (curTool.ToolTip == weapon_type or curTool.Name == weapon_type) then
        return
    end
    for _, v in ipairs(localPlayer.Backpack:GetChildren()) do
        if v:IsA("Tool") and (v.ToolTip == weapon_type or v.Name == weapon_type) then
            char.Humanoid:EquipTool(v)
            return
        end
    end
end

function EquipTool(name)
    equipWeapon(name)
end

-- bringMob on dinh tu loader.lua
function BringMob(v)
    local char = localPlayer.Character
    if not char or not char.PrimaryPart then return end
    local targets = {}
    local mobName = typeof(v) == "Instance" and v.Name or v
    if Workspace:FindFirstChild("Enemies") then
        for _, x in ipairs(Workspace.Enemies:GetChildren()) do
            local h = x:FindFirstChildOfClass("Humanoid")
            local hrp = x.PrimaryPart or x:FindFirstChild("HumanoidRootPart")
            if hrp and h and h.Health > 0 and (not mobName or x.Name == mobName or x.Name:find(mobName)) and (char.PrimaryPart.Position - hrp.Position).Magnitude <= 180 then
                targets[#targets + 1] = x
                if #targets == 4 then break end
            end
        end
    end
    if #targets == 0 then return end
    local targetPos = (typeof(v) == "Instance" and (v.PrimaryPart or v:FindFirstChild("HumanoidRootPart"))) and (v.PrimaryPart or v.HumanoidRootPart).CFrame or targets[1].PrimaryPart.CFrame
    for _, x in ipairs(targets) do
        local part = x.PrimaryPart or x:FindFirstChild("HumanoidRootPart")
        if part and isnetworkowner and isnetworkowner(part) then
            part.CFrame = targetPos
        end
    end
end

-- Fast Attack tu https://pastefy.app/X6xLHpIv/raw?part=attack.lua
pcall(function()
    loadstring(game:HttpGet("https://pastefy.app/X6xLHpIv/raw?part=attack.lua"))()
end)

local function GetBladeHitsFast()
    local targets = {}
    local char = localPlayer.Character
    local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
    if not hrp then return targets end

    for _, folder in ipairs({ Workspace:FindFirstChild("Enemies"), Workspace:FindFirstChild("Characters") }) do
        if folder then
            for _, v in ipairs(folder:GetChildren()) do
                if v ~= char and v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Head") and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                    if (v.HumanoidRootPart.Position - hrp.Position).Magnitude < 65 then
                        table.insert(targets, v)
                    end
                end
            end
        end
    end
    return targets
end

function FastAttack(target)
    local char = localPlayer.Character
    if not char then return end

    pcall(function()
        local netModule = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("Net")
        if not netModule then return end
        local regAttack = netModule:FindFirstChild("RE/RegisterAttack")
        local regHit = netModule:FindFirstChild("RE/RegisterHit")
        if not regAttack or not regHit then return end

        regAttack:FireServer(-math.huge)

        local enemies = {}
        if target and target:FindFirstChild("HumanoidRootPart") and target:FindFirstChild("Head") then
            table.insert(enemies, target)
        else
            enemies = GetBladeHitsFast()
        end

        if #enemies > 0 then
            local args = { nil, {} }
            for i, v in ipairs(enemies) do
                if not args[1] then
                    args[1] = v:FindFirstChild("Head") or v.HumanoidRootPart
                end
                args[2][i] = { v, v.HumanoidRootPart }
            end
            regHit:FireServer(unpack(args))
        end
    end)
end

-- Adapter cho cac phan code goi fastAttackInstance:Attack()
local fastAttackInstance = {
    Attack = FastAttack
}

function ClickM1(target)
    FastAttack(target)
end

getgenv().AttackFunctionnhungSuperTrial = function()
    FastAttack()
end

-- KillMonster tu loader.lua: ham tieu diet quai/boss chuan muc, on dinh
function KillMonster(_v, fallbackCFrame)
    local char = localPlayer.Character
    if not char or not char:FindFirstChildOfClass("Humanoid") or char.Humanoid.Health <= 0 then
        return false
    end
    local targetFound = false
    for _, v2 in ipairs({ Workspace:FindFirstChild("Enemies"), ReplicatedStorage }) do
        if v2 then
            for _, v in ipairs(v2:GetChildren()) do
                local hum = v:FindFirstChildOfClass("Humanoid")
                local hrp = v.PrimaryPart or v:FindFirstChild("HumanoidRootPart")
                if v.Name:find(_v) and hrp and hum and hum.Health > 0 then
                    targetFound = true
                    repeat
                        task.wait()
                        char = localPlayer.Character
                        if not char or not char:FindFirstChildOfClass("Humanoid") or char.Humanoid.Health <= 0 then break end
                        if not v or not v.Parent or not v:FindFirstChildOfClass("Humanoid") or v:FindFirstChildOfClass("Humanoid").Health <= 0 then break end
                        hrp = v.PrimaryPart or v:FindFirstChild("HumanoidRootPart")
                        if not hrp then break end

                        local targetPos = hrp.Position + Vector3.new(0, 25, 7)
                        local dist = (char.HumanoidRootPart.Position - hrp.Position).Magnitude
                        ToTarget(CFrame.new(targetPos))

                        if dist <= 50 then
                            BringMob(v.Name)
                            equipWeapon(Settings["Select Weapon"])
                            FastAttack()
                        end
                    until not v
                        or not v.Parent
                        or not v.PrimaryPart
                        or not v:FindFirstChildOfClass("Humanoid")
                        or v:FindFirstChildOfClass("Humanoid").Health <= 0
                        or char.Humanoid.Health <= 0
                        or not char:FindFirstChild("Humanoid")
                    return true
                end
            end
        end
    end
    if not targetFound and fallbackCFrame then
        ToTarget(fallbackCFrame)
    end
    return targetFound
end

-- Auto Dodge tu loader.lua
task.spawn(function()
    while true do
        pcall(function()
            local char = localPlayer.Character
            if char and char.PrimaryPart and char:FindFirstChildOfClass("Humanoid") and char.Humanoid.Health > 0 then
                ReplicatedStorage.Remotes.CommE:FireServer("Dodge", nil, 30, true, workspace:GetServerTimeNow())
            end
        end)
        task.wait(1.5)
    end
end)
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

local _hopTried = {}
_hopTried[tostring(game.JobId)] = true

local function getServerBrowser()
    local sb = ReplicatedStorage:FindFirstChild("__ServerBrowser")
    if not sb then
        pcall(function()
            sb = ReplicatedStorage:WaitForChild("__ServerBrowser", 4)
        end)
    end
    return sb
end

local function teleportViaServerBrowser(jobId)
    local sb = getServerBrowser()
    if sb then
        local ok = pcall(function()
            sb:InvokeServer("teleport", jobId)
        end)
        return ok
    end
    return false
end

local function getOpenServers(maxPlayers)
    maxPlayers = maxPlayers or 11
    local serverList = {}
    local sb = getServerBrowser()

    -- 1. Thử lấy danh sách từ __ServerBrowser của game
    if sb then
        for page = 1, 3 do
            local ok, res = pcall(function() return sb:InvokeServer(page) end)
            if ok and type(res) == "table" and next(res) ~= nil then
                for jid, data in pairs(res) do
                    local idStr = tostring(jid or (type(data) == "table" and data.JobId) or "")
                    local count = type(data) == "table" and tonumber(data.Count or data.count or data.Players or data.playing) or 0
                    if idStr ~= "" and idStr ~= tostring(game.JobId) and not _hopTried[idStr] and count <= maxPlayers then
                        table.insert(serverList, { id = idStr, count = count })
                    end
                end
                if #serverList >= 5 then break end
            end
        end
    end

    -- 2. Nếu __ServerBrowser chưa trả về đủ, lập tức lấy qua Roblox Public API (luôn có sẵn 100 server)
    if #serverList == 0 then
        pcall(function()
            local url = string.format(
                "https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100&excludeFullGames=true",
                tostring(game.PlaceId)
            )
            local req = game:HttpGet(url)
            if req and req ~= "" then
                local body = HttpService:JSONDecode(req)
                if body and type(body.data) == "table" then
                    for _, s in ipairs(body.data) do
                        local sId = tostring(s.id or "")
                        local sPlaying = tonumber(s.playing) or 0
                        local sMax = tonumber(s.maxPlayers) or 12
                        if sId ~= "" and sId ~= tostring(game.JobId) and not _hopTried[sId] and sPlaying < sMax and sPlaying <= maxPlayers then
                            table.insert(serverList, { id = sId, count = sPlaying })
                        end
                    end
                end
            end
        end)
    end

    return serverList
end

function HopServer()
    task.spawn(function()
        pcall(function()
            if uiLibrary and uiLibrary.CreateNoti then
                uiLibrary.CreateNoti({ Title = "Skider Hub V4", Desc = "⚡ Đang tìm server qua __ServerBrowser...", ShowTime = 2 })
            end
        end)

        local pool = getOpenServers(11)

        if #pool > 0 then
            local chosen = pool[math.random(1, #pool)]
            _hopTried[chosen.id] = true
            pcall(function()
                if uiLibrary and uiLibrary.CreateNoti then
                    uiLibrary.CreateNoti({
                        Title = "Skider Hub V4",
                        Desc = string.format("🚀 Đang vào server: %s (%d/12)...", chosen.id:sub(1, 8), chosen.count),
                        ShowTime = 3
                    })
                end
            end)
            teleportViaServerBrowser(chosen.id)
            return true
        else
            -- Nếu đã thử hết server trong danh sách thì xóa tried để tìm lại
            table.clear(_hopTried)
            _hopTried[tostring(game.JobId)] = true
            local pool2 = getOpenServers(11)
            if #pool2 > 0 then
                local chosen = pool2[math.random(1, #pool2)]
                _hopTried[chosen.id] = true
                pcall(function()
                    if uiLibrary and uiLibrary.CreateNoti then
                        uiLibrary.CreateNoti({
                            Title = "Skider Hub V4",
                            Desc = string.format("🚀 Đang vào server: %s (%d/12)...", chosen.id:sub(1, 8), chosen.count),
                            ShowTime = 3
                        })
                    end
                end)
                teleportViaServerBrowser(chosen.id)
                return true
            end
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

    local mapAttr = Workspace:GetAttribute("MAP")
    if mapAttr and mapAttr ~= "Sea3" and game.PlaceId ~= 7449423635 and game.PlaceId ~= 100117331123089 then
        uiLibrary.CreateNoti({ Title = "Skider Hub V4", Desc = "Cần ở Third Sea (Sea 3) để vào Temple of Time!", ShowTime = 5 })
        return "wrong_sea"
    end

    local hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
    local hum = localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then
        return "waiting_character"
    end

    pcall(function()
        ReplicatedStorage.Remotes.CommF_:InvokeServer("requestEntrance", TEMPLE_ENTRY_POS)
    end)

    if IsInTempleOfTime() then
        return "arrived"
    end

    pcall(function()
        local v4Status = ReplicatedStorage.Remotes.CommF_:InvokeServer("RaceV4Progress", "Check")
        if v4Status == 1 then
            ReplicatedStorage.Remotes.CommF_:InvokeServer("RaceV4Progress", "Begin")
        elseif v4Status == 2 then
            ReplicatedStorage.Remotes.CommF_:InvokeServer("RaceV4Progress", "Teleport")
        elseif v4Status == 3 then
            ReplicatedStorage.Remotes.CommF_:InvokeServer("RaceV4Progress", "Continue")
        end
    end)

    local distToTree = (hrp.Position - topOfGreatTree.Position).Magnitude
    if distToTree > 30 then
        ToTarget(topOfGreatTree)
        return "moving_to_tree"
    else
        pcall(function()
            ReplicatedStorage.Remotes.CommF_:InvokeServer("RaceV4Progress", "Teleport")
        end)
        pcall(function()
            ReplicatedStorage.Remotes.CommF_:InvokeServer("requestEntrance", TEMPLE_ENTRY_POS)
        end)
    end

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
    local backpack = localPlayer.Backpack and localPlayer.Backpack:FindFirstChild(name)
    local char = localPlayer.Character and localPlayer.Character:FindFirstChild(name)
    return (backpack ~= nil or char ~= nil)
end

-- [[ MODERN INVENTORY CHECKING SYSTEM ]]
local InventoryController
local ItemConfig
local ItemReplication

pcall(function()
    InventoryController = require(game:GetService("ReplicatedStorage").Controllers.UI.Inventory)
    ItemConfig = require(game:GetService("ReplicatedStorage").ItemConfig)
    ItemReplication = require(game:GetService("ReplicatedStorage").Util.ItemReplication)
end)

local function getItemCount(itemId, networkedUID)
    if not ItemReplication then return 1 end
    for _, field in ipairs({"Count", "Quantity", "Amount", "Stack"}) do
        if ItemReplication[field] and typeof(ItemReplication[field].readClient) == "function" then
            local success, val = pcall(function()
                return ItemReplication[field].readClient(itemId, networkedUID)
            end)
            if success and typeof(val) == "number" then
                return val
            end
        end
    end
    return 1
end

local function getItemMastery(itemId, networkedUID)
    if ItemReplication and ItemReplication.Mastery and typeof(ItemReplication.Mastery.readClient) == "function" then
        local success, val = pcall(function()
            return ItemReplication.Mastery.readClient(itemId, networkedUID)
        end)
        if success and typeof(val) == "number" then
            return val
        end
    end
    return nil
end

function checkItem(itemName)
    if not InventoryController or not ItemConfig or not ItemReplication then
        pcall(function()
            InventoryController = InventoryController or require(game:GetService("ReplicatedStorage").Controllers.UI.Inventory)
            ItemConfig = ItemConfig or require(game:GetService("ReplicatedStorage").ItemConfig)
            ItemReplication = ItemReplication or require(game:GetService("ReplicatedStorage").Util.ItemReplication)
        end)
    end

    if not InventoryController or not InventoryController:GetIfInitialized() then
        return false, 0, nil
    end

    local ok, tiles = pcall(function()
        return InventoryController:GetTiles()
    end)
    if not ok or type(tiles) ~= "table" then
        return false, 0, nil
    end

    for _, tile in ipairs(tiles) do
        local cfg = nil
        pcall(function()
            cfg = ItemConfig.match(tile.ItemId):asNullable()
        end)
        if cfg then
            local storageKey = cfg.Index and cfg.Index.StorageKey
            local displayName = cfg.DisplayName or cfg.Name

            if storageKey == itemName or displayName == itemName then
                local count = tile.Count or tile.Amount or getItemCount(tile.ItemId, tile.NetworkedUID)
                local mastery = getItemMastery(tile.ItemId, tile.NetworkedUID)

                return true, count, mastery
            end
        end
    end

    return false, 0, nil
end
getgenv().checkItem = checkItem

function CheckCountItem(name, count)
    count = count or 1
    local item = (localPlayer.Backpack and localPlayer.Backpack:FindFirstChild(name)) or (localPlayer.Character and localPlayer.Character:FindFirstChild(name))
    if item and item:FindFirstChild("Count") then
        if item.Count.Value >= count then return true end
    end
    local hasItem, itemCount = checkItem(name)
    if hasItem and (itemCount or 0) >= count then
        return true
    end
    local ok, inv = pcall(function()
        return ReplicatedStorage.Remotes.CommF_:InvokeServer("getInventory")
    end)
    if ok and type(inv) == "table" then
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
    local hasItem = checkItem(name)
    if hasItem then return true end
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
    if not dt or not dt.HadPoint then return end
    local gear = DetectGearUp and DetectGearUp(dt)
    if not gear then return end
    local choice = Settings["Select Gear V4"] == "Alpha" and "Alpha" or "Omega"
    ReplicatedStorage.Remotes.CommF_:InvokeServer("TempleClock", "SpendPoint", gear, choice)
    local after = ReplicatedStorage.Remotes.CommF_:InvokeServer("TempleClock", "Check")
    if after and after.HadPoint and DetectGearUp and DetectGearUp(after) == gear then
        ReplicatedStorage.Remotes.CommF_:InvokeServer("TempleClock", "SpendPoint", gear, choice == "Alpha" and "Omega" or "Alpha")
    end
end

function AutoQuestBarito()
    local res = ReplicatedStorage.Remotes.CommF_:InvokeServer("BartiloQuestProgress")
    if type(res) == "table" then
        if not res.KilledBandits then
            ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", "BartiloQuest", 1)
            KillMonster("Swan Pirate", CFrame.new(932.624451, 156.106079, 1180.27466))
        elseif not res.KilledSpring then
            KillMonster("Jeremy", CFrame.new(2316.0397949219, 448.95474243164, 767.72882080078))
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
-- RACE DRACO (ported from bnn.lua and adapted to Fluent/current helpers)
--------------------------------------------------------------------------------

local DracoState = {
    quest = nil,
    hunterQuest = nil,
    killedTerrorshark = false,
    trialEntered = false,
    waitingForTrial = false,
    volcanoRockPass = false,
    lastNotice = {},
}

local function DracoNotify(message, duration)
    local now = tick()
    if now - (DracoState.lastNotice[message] or 0) < (duration or 5) then return end
    DracoState.lastNotice[message] = now
    uiLibrary.CreateNoti({ Title = "Skider Hub V4", Desc = message, ShowTime = duration or 5 })
end

local function DracoRoot()
    local char = localPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function DracoDistance(position)
    local root = DracoRoot()
    return root and (root.Position - position).Magnitude or math.huge
end

local function DracoNpc(name)
    for _, folder in ipairs({ Workspace:FindFirstChild("NPCs"), ReplicatedStorage:FindFirstChild("NPCs") }) do
        local npc = folder and folder:FindFirstChild(name)
        if npc then return npc end
    end
    local ok, npc = pcall(function()
        local manager = require(ReplicatedStorage:WaitForChild("NPCManager"))
        local result = manager.getNPCsByName(name)
        return result and result[1] and result[1]._modelState and result[1]._modelState._instance
    end)
    return ok and npc or nil
end

local function DracoRaidVisible(name)
    local gui = localPlayer:FindFirstChild("PlayerGui")
    local top = gui and gui:FindFirstChild("Main") and gui.Main:FindFirstChild("TopHUDList")
    local timer = top and top:FindFirstChild(name)
    return timer and timer.Visible == true or false
end

function CheckAcientOneDracoStatus()
    local char = localPlayer.Character
    if not char or not char:FindFirstChild("RaceTransformed") then
        local island = Workspace:FindFirstChild("HydraIslandClient")
        local remote = island and island:FindFirstChild("RemoteFunction")
        if remote then
            local ok, value = pcall(function() return remote:InvokeServer("Interacted") end)
            if ok and table.find({ 1, 2, 3, 4 }, value) then return "Ready For Trial" end
        end
        return "You have yet to achieve greatness"
    end

    local code, progress, fragments
    pcall(function()
        code, progress, fragments = ReplicatedStorage.Remotes.CommF_:InvokeServer("UpgradeRace", "Check", 2)
    end)
    if code == 0 then return "Ready For Trial" end
    if code == 1 or code == 3 then return "Required Train More" end
    if code == 2 or code == 4 or code == 7 then
        return "Can Buy Gear With " .. tostring(fragments or 0) .. " Fragments"
    end
    if code == 5 then return "You Are Done Your Race" end
    if code == 6 then return "Upgrades completed: " .. tostring(math.max(0, (progress or 2) - 2)) .. "/3, Need Trains More" end
    if code == 8 then return "Remaining " .. tostring(math.max(0, 10 - (progress or 0))) .. " training sessions" end
    return "You have yet to achieve greatness"
end

function DetectGearUp(data)
    if type(data) ~= "table" or type(data.RaceDetails) ~= "table" then return nil end
    local details = data.RaceDetails
    local gears = details.Gears or {}
    local spent = (details.A or 0) + (details.B or 0)
    local raceReady = (data.RaceLevel or 0) >= 2
    if not raceReady then return "Gear1" end
    if not data.HadPoint then return nil end
    if spent <= 0 then return "Gear2" end
    if spent == 1 then return "Gear3" end
    if spent == 2 then return "Gear4" end

    local types = {
        gears[1] == "A" and "Alpha" or gears[1] == "B" and "Omega" or "Blank",
        gears[2] == "A" and "Alpha" or gears[2] == "B" and "Omega" or "Blank",
        gears[3] == "A" and "Alpha" or gears[3] == "B" and "Omega" or "Blank",
    }
    if types[1] == types[2] and types[3] ~= types[1] then return "Gear4" end
    if types[1] == types[3] and types[2] ~= types[1] then return "Gear3" end
    if types[2] == types[3] and types[1] ~= types[2] then return "Gear2" end
    return "Gear4"
end

function DetectFireFlower()
    local folder = Workspace:FindFirstChild("FireFlowers")
    if not folder then return nil end
    for _, flower in ipairs(folder:GetChildren()) do
        if flower:IsA("Model") and flower.PrimaryPart then return flower end
    end
end

local DracoQuestStates = { V2InProgress = true, V3InProgress = true, V2TurnInReady = true, V3TurnInReady = true }

function AutoUpgradeRaceDraco()
    local data = localPlayer:FindFirstChild("Data")
    local race = data and data:FindFirstChild("Race")
    if not race or race.Value ~= "Draco" then
        DracoNotify("Change Race Draco first", 5)
        return
    end
    if DetectItemPlr("Primordial Reign") then
        DracoNotify("Race Draco V3 is complete", 5)
        return
    end

    local wizard = DracoNpc("Dragon Wizard")
    local root = wizard and wizard:FindFirstChild("HumanoidRootPart")
    local remote = ReplicatedStorage:FindFirstChild("Modules")
        and ReplicatedStorage.Modules:FindFirstChild("Net")
        and ReplicatedStorage.Modules.Net:FindFirstChild("RF/InteractDragonQuest")
    if not root or not remote then return end

    local state = type(DracoState.quest) == "table" and DracoState.quest.AvailableVQuest or nil
    if not state or not DracoQuestStates[state] then
        if DracoDistance(root.Position) > 8 then
            ToTarget(root.CFrame * CFrame.new(0, 4, 4))
            return
        end
        DracoState.quest = remote:InvokeServer({ NPC = "Dragon Wizard", Command = "Speak" })
        state = type(DracoState.quest) == "table" and DracoState.quest.AvailableVQuest or nil
        if state == "V2" or state == "V3" then
            remote:InvokeServer({ NPC = "Dragon Wizard", Command = "Ascension", Action = "Begin" })
            DracoState.quest = remote:InvokeServer({ NPC = "Dragon Wizard", Command = "Speak" })
        end
        return
    end

    if state == "V2TurnInReady" or state == "V3TurnInReady" then
        remote:InvokeServer({ NPC = "Dragon Wizard", Command = "Ascension", Action = "Complete" })
        DracoState.quest = nil
        return
    end

    if state == "V2InProgress" then
        if not CheckCountItem("Fire Flower", 5) then
            local flower = DetectFireFlower()
            if flower then
                ToTarget(flower.PrimaryPart.CFrame)
                local prompt = flower:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt and DracoDistance(flower.PrimaryPart.Position) < 8 then fireproximityprompt(prompt, 1) end
            else
                KillMonster("Forest Pirate")
            end
        elseif DracoDistance(root.Position) > 8 then
            ToTarget(root.CFrame * CFrame.new(0, 4, 4))
        else
            remote:InvokeServer({ NPC = "Dragon Wizard", Command = "Ascension", Action = "Complete" })
            DracoState.quest = nil
        end
        return
    end

    if state == "V3InProgress" then
        local shark = CheckNameBoss("Terrorshark") or DetectMob("Terrorshark")
        if shark and not DracoState.killedTerrorshark then
            KillMonster(shark.Name)
            if not IsMobAlive(shark) then DracoState.killedTerrorshark = true end
        elseif DracoState.killedTerrorshark then
            if DracoDistance(root.Position) > 8 then
                ToTarget(root.CFrame * CFrame.new(0, 4, 4))
            else
                remote:InvokeServer({ NPC = "Dragon Wizard", Command = "Ascension", Action = "Complete" })
                DracoState.quest = nil
                DracoState.killedTerrorshark = false
            end
        else
            local boat = CheckBoat()
            local seat = boat and boat:FindFirstChild("VehicleSeat", true)
            if not seat then
                local dock = CFrame.new(-16204.0811, 9.08636, 479.22595)
                if DracoDistance(dock.Position) > 8 then ToTarget(dock) else ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyBoat", "PirateBrigade") end
            elseif localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid") and not localPlayer.Character.Humanoid.Sit then
                ToTarget(seat.CFrame)
            end
        end
    end
end

function CheckRelicChuaDat(models)
    if not models then return false end
    for _, item in ipairs(models:GetDescendants()) do
        if item:IsA("ParticleEmitter") and item.Enabled then return true end
    end
    return false
end

function GetRelicChuaDat(parts)
    for name, model in pairs(parts or {}) do
        if string.find(name, "RelicModel", 1, true) and CheckRelicChuaDat(model) then return model, name end
    end
end

function GetRelicChuanbiDat(parts)
    for name, model in pairs(parts or {}) do
        local primary = model and model.PrimaryPart
        if string.find(name, "RelicModel", 1, true) and primary and primary:FindFirstChild("AlignPosition") and CheckRelicChuaDat(model) then
            return model, name
        end
    end
end

function CheckModelTrialDraco()
    local result = {}
    local map = Workspace:FindFirstChild("Map")
    local trial = map and map:FindFirstChild("DracoTrial")
    if not trial then return result end
    for _, name in ipairs({ "Relic1", "Relic2", "Relic3", "EndRelic1", "EndRelic2", "EndRelic3", "Door1", "Door2", "Door3", "Brazier1", "Brazier2", "Brazier3", "Center", "EndPlatform", "TeleportOut" }) do
        result[name] = trial:FindFirstChild(name, true)
    end
    local origin = Workspace:FindFirstChild("_WorldOrigin")
    for _, model in ipairs(origin and origin:GetChildren() or {}) do
        if model:IsA("Model") and model.Name == "Relic" then
            local mesh = model:FindFirstChildWhichIsA("MeshPart", true)
            if mesh then
                if mesh.Color == Color3.fromRGB(132, 203, 0) then result.RelicModel1 = model end
                if mesh.Color == Color3.fromRGB(232, 106, 110) then result.RelicModel2 = model end
                if mesh.Color == Color3.fromRGB(191, 153, 0) then result.RelicModel3 = model end
            end
        end
    end
    return result
end

local function RunDracoRelicTrial()
    local location = Workspace:FindFirstChild("_WorldOrigin") and Workspace._WorldOrigin:FindFirstChild("Locations")
    local flame = location and location:FindFirstChild("Trial of Flames")
    local map = Workspace:FindFirstChild("Map")
    local trial = map and map:FindFirstChild("DracoTrial")
    if not flame or not trial or DracoDistance(flame.Position) > 3000 then return false end

    local door = trial:FindFirstChild("DoorTouch", true)
    if door and door:FindFirstChild("TouchInterest") then
        DracoState.trialEntered = true
        ToTarget(door.CFrame)
        return true
    end
    if not DracoRaidVisible("RaidTimer") then
        local remote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("DracoTrial")
        if remote then remote:InvokeServer() end
        return true
    end

    local parts = CheckModelTrialDraco()
    local carried, carriedName = GetRelicChuanbiDat(parts)
    local loose, looseName = GetRelicChuaDat(parts)
    local target, prompt
    if carried and carriedName then
        target = parts["EndRelic" .. carriedName:match("%d+")]
    elseif loose and looseName then
        target = parts["Relic" .. looseName:match("%d+")]
    end
    prompt = target and target:FindFirstChildWhichIsA("ProximityPrompt", true)
    if target then
        local pivot = target:IsA("Model") and target:GetPivot() or target.CFrame
        if DracoDistance(pivot.Position) > 8 then ToTarget(pivot) elseif prompt then fireproximityprompt(prompt, 1) end
    end
    return true
end

function AutoTrialDraco()
    if RunDracoRelicTrial() then return end
    if DracoState.trialEntered then
        DracoState.trialEntered = false
        DracoNotify("Draco Trial completed", 5)
    end
    local island = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("PrehistoricIsland")
    if island then
        local teleport = island:FindFirstChild("TrialTeleport", true)
        if teleport then ToTarget(teleport.CFrame) return end
        local fossil = DracoNpc("Fossil Expert")
        if fossil and fossil:FindFirstChild("HumanoidRootPart") then ToTarget(fossil.HumanoidRootPart.CFrame) end
    else
        DracoNotify("Prehistoric Island not found", 5)
    end
end

function DetectRockVolcano()
    local map = Workspace:FindFirstChild("Map")
    local island = map and map:FindFirstChild("PrehistoricIsland")
    local rocks = island and island:FindFirstChild("Core") and island.Core:FindFirstChild("VolcanoRocks")
    local nearest, nearestDistance
    for _, rock in ipairs(rocks and rocks:GetChildren() or {}) do
        local specs = rock:FindFirstChild("Specs", true)
        if rock.Name == "Rock" and specs and specs:IsA("ParticleEmitter") and specs.Enabled then
            local distance = DracoDistance(rock:GetPivot().Position)
            if not nearestDistance or distance < nearestDistance then nearest, nearestDistance = rock, distance end
        end
    end
    return nearest
end

function DetectLava()
    local map = Workspace:FindFirstChild("Map")
    local island = map and map:FindFirstChild("PrehistoricIsland")
    for _, item in ipairs(island and island:GetDescendants() or {}) do
        if item.Name == "TouchInterest" and item.Parent and item.Parent.Name ~= "TrialTeleport" then return true end
    end
    return false
end

function DetectGolem()
    local enemies = Workspace:FindFirstChild("Enemies")
    for _, mob in ipairs(enemies and enemies:GetChildren() or {}) do
        local root = mob:FindFirstChild("HumanoidRootPart")
        if mob.Name == "Lava Golem" and root and IsMobAlive(mob) and DracoDistance(root.Position) <= 1500 then return mob end
    end
end

function DeleteLava()
    local map = Workspace:FindFirstChild("Map")
    local island = map and map:FindFirstChild("PrehistoricIsland")
    local lava = island and island:FindFirstChild("Core") and island.Core:FindFirstChild("InteriorLava")
    for _, item in ipairs(lava and lava:GetChildren() or {}) do item:Destroy() end
end

function DetectPositionVolcano()
    local result = {}
    local map = Workspace:FindFirstChild("Map")
    local island = map and map:FindFirstChild("PrehistoricIsland")
    local core = island and island:FindFirstChild("Core")
    local skull = core and core:FindFirstChild("Skull", true)
    if skull then result[1] = skull.Position end
    local ids = {
        ["87519803677536:293"] = 2, ["9664674474:234"] = 3, ["14130842310:266"] = 4,
        ["15672470777:86"] = 5, ["5159878936:261"] = 6, ["138849514693209:242"] = 7,
        ["87519803677536:279"] = 8,
    }
    for _, part in ipairs(island and island:GetDescendants() or {}) do
        if part:IsA("MeshPart") then
            local id = tostring(part.MeshId):match("(%d+)$")
            local slot = ids[tostring(id) .. ":" .. tostring(math.floor(part.Position.Y))]
            if slot then result[slot] = part.Position end
        end
    end
    return result
end

function CheckPosnearRock(positions, object)
    local position = object and object.Position
    if not position then return nil, 0 end
    local nearest, index, distance = nil, 0, math.huge
    for i, candidate in pairs(positions or {}) do
        local current = (Vector3.new(position.X, 0, position.Z) - Vector3.new(candidate.X, 0, candidate.Z)).Magnitude
        if current < distance then nearest, index, distance = candidate, i, current end
    end
    return nearest, index
end

function AutoUseSkillFixLava()
    local rock = DetectRockVolcano()
    if not rock then return end
    getgenv().AimPos = rock:GetPivot()
    pcall(AutoAllSkill)
    pcall(function() FastAttack(rock) end)
end

local function DetectEmberTemplate()
    for _, model in ipairs(Workspace:GetChildren()) do
        local part = model:FindFirstChild("Part")
        if model.Name == "EmberTemplate" and not model:FindFirstChild("Ignored") and part and part.Position.Y > -100 then return model end
    end
end

local function DetectDracoTree()
    local map = Workspace:FindFirstChild("Map")
    local waterfall = map and map:FindFirstChild("Waterfall")
    local island = waterfall and waterfall:FindFirstChild("IslandModel")
    for _, model in ipairs(island and island:GetDescendants() or {}) do
        if model:IsA("Model") and model.Name == "Tree" and not model:FindFirstChild("Ignored") and not model:GetAttribute("AlreadyDestroyedClient") then
            return model
        end
    end
end

local function DracoFarmMob(name, enabledKey)
    local mob = DetectMob(name)
    if mob then
        repeat
            task.wait()
            SizePart(mob)
            BringMob(mob)
            UsedualFlock()
            ClickM1(mob)
            local root = mob:FindFirstChild("HumanoidRootPart")
            if root then ToTarget(root.CFrame * CFrame.new(Settings["Select Weapon"] == "Blox Fruit" and -7 or 7, 20, 0)) end
        until not IsMobAlive(mob) or not Settings[enabledKey]
        return true
    end
    local spawnPart = DetectPartSpawnMob(type(name) == "table" and DetectNameTablePart(name) or name, true)
    if spawnPart then ToTarget(spawnPart.CFrame * CFrame.new(0, 60, 0)) end
    return false
end

local function RunDragonHunter(enabledKey)
    local ember = DetectEmberTemplate()
    if ember and ember:FindFirstChild("Part") then ToTarget(ember.Part.CFrame) return true end
    local hunter = DracoNpc("Dragon Hunter")
    local remote = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("Net")
    remote = remote and remote:FindFirstChild("RF/DragonHunter")
    if not hunter or not hunter:FindFirstChild("HumanoidRootPart") or not remote then return false end
    if not DracoState.hunterQuest then
        if DracoDistance(hunter.HumanoidRootPart.Position) > 8 then
            ToTarget(hunter.HumanoidRootPart.CFrame * CFrame.new(0, 4, 4))
        else
            local response = remote:InvokeServer({ Context = "Check" })
            if not response or not response.Text then response = remote:InvokeServer({ Context = "RequestQuest" }) end
            DracoState.hunterQuest = response and response.Text
        end
        return true
    end
    local text = tostring(DracoState.hunterQuest)
    if text:find("Hydra Enforcers") then return DracoFarmMob("Hydra Enforcer", enabledKey) end
    if text:find("Venomous Assailants") then return DracoFarmMob("Venomous Assailant", enabledKey) end
    if text:find("trees") then
        local tree = DetectDracoTree()
        if tree then
            local pivot = tree:GetPivot()
            ToTarget(pivot)
            getgenv().AimPos = pivot
            pcall(AutoAllSkill)
            return true
        end
    end
    DracoState.hunterQuest = nil
    return false
end

local function CraftVolcanicMagnet(enabledKey)
    if CheckItemInventory("Volcanic Magnet") or Settings["Ignore Craft Volcanic Magnet Draco"] then return true end
    if not CheckCountItem("Scrap Metal", 10) then
        DracoFarmMob({ "Jungle Pirate", "Musketeer Pirate" }, enabledKey)
        return false
    end
    if not CheckCountItem("Blaze Ember", 15) then
        RunDragonHunter(enabledKey)
        return false
    end
    local net = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("Net")
    local craft = net and net:FindFirstChild("RF/Craft")
    if craft then craft:InvokeServer("Craft", "Volcanic Magnet", 1, {}) end
    return CheckItemInventory("Volcanic Magnet") == true
end

local function FindPrehistoricIsland()
    local boat = CheckBoat()
    local seat = boat and boat:FindFirstChild("VehicleSeat", true)
    if not seat then
        local dock = CFrame.new(-16204.0811, 9.08636, 479.22595)
        if DracoDistance(dock.Position) > 8 then ToTarget(dock) else ReplicatedStorage.Remotes.CommF_:InvokeServer("BuyBoat", "PirateBrigade") end
        return
    end
    local humanoid = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.SeatPart ~= seat then ToTarget(seat.CFrame) return end
    for _, part in ipairs(boat:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end
    local direction = Vector3.new(-118834.5, seat.Position.Y, -78.95)
    local delta = direction - seat.Position
    if delta.Magnitude > 5 then seat.CFrame = CFrame.lookAt(seat.Position + delta.Unit * math.min(350 * 0.2, delta.Magnitude), direction) end
end

local VolcanoOffsets = {
    [273] = CFrame.new(40, 0, 0), [286] = CFrame.new(40, 0, 0), [246] = CFrame.new(0, -40, 0),
    [486] = CFrame.new(40, 0, 0), [364] = CFrame.new(40, 0, 0), [682] = CFrame.new(0, 0, -40),
    [490] = CFrame.new(0, 40, 0), [691] = CFrame.new(40, 0, 0), [502] = CFrame.new(-40, 0, 0),
    [256] = CFrame.new(-40, 0, 0), [290] = CFrame.new(0, 40, 0), [427] = CFrame.new(0, 40, 0),
    [692] = CFrame.new(0, 0, 40), [316] = CFrame.new(0, 40, 0), [481] = CFrame.new(0, 40, 0),
    [594] = CFrame.new(0, 40, 0), [649] = CFrame.new(40, 0, 0), [285] = CFrame.new(0, -40, 0),
    [250] = CFrame.new(0, 40, 0), [454] = CFrame.new(-40, 0, 0),
}

local function RunVolcano(enabledKey)
    local map = Workspace:FindFirstChild("Map")
    local island = map and map:FindFirstChild("PrehistoricIsland")
    if not island then FindPrehistoricIsland() return end
    local fossil = DracoNpc("Fossil Expert")
    if localPlayer:GetAttribute("CurrentLocation") ~= "Prehistoric Island" and fossil and fossil:FindFirstChild("HumanoidRootPart") then
        ToTarget(fossil.HumanoidRootPart.CFrame)
        return
    end
    local trialRock = island:FindFirstChild("TrialRock", true)
    local trialTeleport = island:FindFirstChild("TrialTeleport", true)
    if trialRock and trialRock:IsA("BasePart") and trialRock.Transparency == 1 and trialTeleport then
        DracoState.waitingForTrial = true
        ToTarget(trialTeleport.CFrame)
        return
    end
    if DetectLava() then
        for _, item in ipairs(island:GetDescendants()) do
            if item.Name == "TouchInterest" and item.Parent and item.Parent.Name ~= "TrialTeleport" then item:Destroy() end
        end
    end
    DeleteLava()
    if not DracoRaidVisible("PrehistoricRaidTimer") and not DracoRaidVisible("RaidTimer") then
        local promptPart = island:FindFirstChild("ActivationPrompt", true)
        local prompt = promptPart and promptPart:FindFirstChildWhichIsA("ProximityPrompt", true)
        if promptPart then
            ToTarget(promptPart.CFrame)
            if prompt and DracoDistance(promptPart.Position) < 8 then fireproximityprompt(prompt, 1) end
        end
        return
    end
    local golem = DetectGolem()
    if golem then
        local root = golem:FindFirstChild("HumanoidRootPart")
        if root then ToTarget(root.CFrame * CFrame.new(0, 20, 7)) end
        EquipTool(NameWeapon(Settings["Select Weapon Kill Golem"] or Settings["Select Weapon"] or "Melee"))
        ClickM1(golem)
        return
    end
    local rock = DetectRockVolcano()
    if rock then
        local pivot = rock:GetPivot()
        local offset = VolcanoOffsets[math.floor(pivot.Position.Y)] or CFrame.new(0, 40, 0)
        if Settings["Fix Volcano Safe"] then
            local safePositions = DetectPositionVolcano()
            local safe = CheckPosnearRock(safePositions, rock.PrimaryPart or rock:FindFirstChildWhichIsA("BasePart"))
            if safe and DracoDistance(safe) >= 400 then ToTarget(CFrame.new(safe)) return end
        end
        ToTarget(pivot * offset)
        if DracoDistance(pivot.Position) < 100 then AutoUseSkillFixLava() end
    end
end

function BuyGearDracoV4()
    if string.find(CheckAcientOneDracoStatus(), "Can Buy Gear", 1, true) then
        ReplicatedStorage.Remotes.CommF_:InvokeServer("UpgradeRace", "Buy", 2)
    end
end

local function TrainDraco(enabledKey)
    local enemies = Workspace:FindFirstChild("Enemies")
    local closest, closestDistance
    for _, mob in ipairs(enemies and enemies:GetChildren() or {}) do
        local root = mob:FindFirstChild("HumanoidRootPart")
        if root and IsMobAlive(mob) then
            local distance = DracoDistance(root.Position)
            if not closestDistance or distance < closestDistance then closest, closestDistance = mob, distance end
        end
    end
    if closest then DracoFarmMob(closest.Name, enabledKey) end
end

function FullyDraco()
    if not Settings["Fully Trial Draco"] then return end
    pcall(TurnOnV4)
    pcall(ChooseGearV4)
    local status = CheckAcientOneDracoStatus()
    if status == "Ready For Trial" then
        if RunDracoRelicTrial() then return end
        if not CraftVolcanicMagnet("Fully Trial Draco") then return end
        RunVolcano("Fully Trial Draco")
    elseif string.find(status, "Can Buy Gear", 1, true) then
        BuyGearDracoV4()
    elseif string.find(status, "Train", 1, true) or string.find(status, "training", 1, true) then
        TrainDraco("Fully Trial Draco")
    elseif string.find(status, "yet to achieve", 1, true) then
        AutoUpgradeRaceDraco()
    end
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
	for _, player in pairs(Players:GetPlayers()) do
		if
			player ~= localPlayer
			and player:FindFirstChild("Data") and player.Data:FindFirstChild("Race") and player.Data.Race.Value == "Skypiea"
			and not table.find(items16, player.Name)
			and player.Character and player.Character:FindFirstChild("Humanoid")
			and player.Character.Humanoid.Health > 0
			and player.Character:FindFirstChild("HumanoidRootPart")
		then
			return player
		end
	end
end

function DetectPlayerGhoul()
	for _, player in pairs(Players:GetPlayers()) do
		if
			player ~= localPlayer
			and not table.find(items17, player.Name)
			and player.Character and player.Character:FindFirstChild("Humanoid")
			and player.Character.Humanoid.Health > 0
			and player.Character:FindFirstChild("HumanoidRootPart")
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
			if not DetectItemPlr("Flower 1") and Workspace:FindFirstChild("Flower1") then
				ToTarget(Workspace.Flower1.CFrame)
			elseif not DetectItemPlr("Flower 2") and Workspace:FindFirstChild("Flower2") then
				ToTarget(Workspace.Flower2.CFrame)
			elseif not DetectItemPlr("Flower 3") then
				KillMonster("Swan Pirate", CFrame.new(932.624451, 156.106079, 1180.27466))
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
			if not table.find(BlBossHuman, "Jeremy") then
				if KillMonster("Jeremy", CFrame.new(2333.209228515625, 449.2427062988281, 699.5128784179688)) then
					table.insert(BlBossHuman, "Jeremy")
				end
			elseif not table.find(BlBossHuman, "Diamond") then
				if KillMonster("Diamond", CFrame.new(-1713.5589599609375, 198.99554443359375, -104.31584167480469)) then
					table.insert(BlBossHuman, "Diamond")
				end
			elseif not table.find(BlBossHuman, "Orbitus") then
				if KillMonster("Orbitus", CFrame.new(-2148.7568359375, 73.27831268310547, -4304.4130859375)) or KillMonster("Fajita", CFrame.new(-2148.7568359375, 73.27831268310547, -4304.4130859375)) then
					table.insert(BlBossHuman, "Orbitus")
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
			else
				local aroweCFrame = CFrame.new(288.7, 287.3, -2430.4)
				if localPlayer:DistanceFromCharacter(aroweCFrame.Position) > 10 then
					ToTarget(aroweCFrame)
				else
					ReplicatedStorage.Remotes.CommF_:InvokeServer("Wenlocktoad", "2")
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
-- ══════════════════════════════════════════════════════════════════
-- [2/3] TURNV3 (Đồng bộ V3 Countdown & Watchdog Ghost Temple)
-- Tích hợp nguyên bản từ Kaiv4-BNN/kaiv4mixbnncrack-nam.lua
-- ══════════════════════════════════════════════════════════════════
local isUper = true
local isAlly = false
local HelpWhitelist = {}
local LOCAL_HELPERS = {}

local function refreshTurnV3Roles()
    table.clear(LOCAL_HELPERS)
    table.clear(HelpWhitelist)
    local seen = {}
    local function addH(raw)
        if type(raw) == "table" then
            for k, v in pairs(raw) do
                if type(k) == "number" and type(v) == "string" then
                    addH(v)
                elseif type(k) == "string" and (v == true or type(v) == "table") then
                    addH(k)
                elseif type(v) == "table" or type(v) == "string" then
                    addH(v)
                end
            end
        elseif type(raw) == "string" then
            local name = raw:match("^%s*(.-)%s*$")
            if name ~= "" and not seen[name] then
                seen[name] = true
                table.insert(LOCAL_HELPERS, name)
                HelpWhitelist[name] = true
            end
        end
    end

    addH(getgenv().HelperList)
    if getgenv().JoinV4Config and getgenv().JoinV4Config["Helper"] then addH(getgenv().JoinV4Config["Helper"]) end
    if getgenv().Config and getgenv().Config["Name Helper TurnV3"] then addH(getgenv().Config["Name Helper TurnV3"]) end
    if Settings and Settings["Name Helper TurnV3"] then addH(Settings["Name Helper TurnV3"]) end
    if Settings and Settings["Select Players Multi"] then addH(Settings["Select Players Multi"]) end

    local myName = localPlayer.Name
    local myDisplay = localPlayer.DisplayName
    isUper = not (HelpWhitelist[myName] or HelpWhitelist[myDisplay])
    isAlly = (HelpWhitelist[myName] == true or HelpWhitelist[myDisplay] == true)
end

local function isHelperAccount()
    -- Chỉ dùng HelpWhitelist để xác định helper, KHÔNG dùng Auto Reset Character
    -- vì Auto Reset Character là tính năng reset char trong FFA, không phải role
    refreshTurnV3Roles()
    local myName = localPlayer.Name
    local myDisplay = localPlayer.DisplayName
    return isAlly == true or HelpWhitelist[myName] == true or HelpWhitelist[myDisplay] == true
end

do
    local V3_COUNTDOWN      = 4
    local V3_FILE_POLL      = 0.05
    local V3_READY_FRESH    = 5.0
    local V3_FIRE_COUNT     = 3
    local V3_FIRE_INTERVAL  = 0.05
    local V3_DOOR_DIST      = 65
    local FILE_ROOT         = "SkiderV4/TurnV3"

    -- SERVICES
    local Players           = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local RunService        = game:GetService("RunService")
    local HttpService       = game:GetService("HttpService")
    local Lighting          = game:GetService("Lighting")
    local LocalPlayer       = Players.LocalPlayer
    local USERNAME          = LocalPlayer.Name

    local CommF_ = nil
    pcall(function()
        CommF_ = ReplicatedStorage:WaitForChild("Remotes", 5):WaitForChild("CommF_", 5)
    end)

    -- ════════════ ROLE DETECTION ════════════
    -- Helper = có trong HelperList
    -- Main   = KHÔNG có trong HelperList
    local LOCAL_HELPERS   = {}

    local HelpWhitelist   = {}

    do

        local seen = {}

        local function addH(raw)

            if type(raw) == "table" then

                for k, v in pairs(raw) do

                    if type(k) == "number" and type(v) == "string" then addH(v)

                    elseif type(k) == "string" and (v == true or type(v) == "table") then addH(k)

                    elseif type(v) == "string" then addH(v) end

                end

            elseif type(raw) == "string" then

                local name = raw:match("^%s*(.-)%s*$")

                if name ~= "" and not seen[name] then

                    seen[name] = true

                    table.insert(LOCAL_HELPERS, name)

                    HelpWhitelist[name] = true

                end

            end

        end

        -- Multi-source: HelperList, JoinV4Config, Config, Settings

        addH(getgenv().HelperList)

        if getgenv().JoinV4Config and getgenv().JoinV4Config["Helper"] then addH(getgenv().JoinV4Config["Helper"]) end

        if getgenv().Config and getgenv().Config["Name Helper TurnV3"] then addH(getgenv().Config["Name Helper TurnV3"]) end

        if getgenv().Settings and getgenv().Settings["Name Helper TurnV3"] then addH(getgenv().Settings["Name Helper TurnV3"]) end

        if getgenv().Settings and getgenv().Settings["Select Players Multi"] then addH(getgenv().Settings["Select Players Multi"]) end

    end

    local isUper = not HelpWhitelist[USERNAME]   -- MAIN: không trong whitelist
    local isAlly =     HelpWhitelist[USERNAME]   -- HELPER: có trong whitelist

    print(string.format("[TurnV3] Role check: USERNAME='%s' | isMain=%s | isHelper=%s | HelperList=%s",
        USERNAME, tostring(isUper), tostring(isAlly),
        table.concat(LOCAL_HELPERS, ", ")))

    -- SERVER TIME
    local function v3ServerNow()
        local ok, v = pcall(function() return game:GetService("Workspace"):GetServerTimeNow() end)
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
        local f = groupFolder(); if not f then return nil end
        return f .. "/ready_" .. sanitize(USERNAME) .. ".json"
    end

    local function commandPath()
        local f = groupFolder(); if not f then return nil end
        return f .. "/command.json"
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
            local char        = LocalPlayer.Character
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
        local data = LocalPlayer:FindFirstChild("Data")
        local race = data and data:FindFirstChild("Race")
        if not race then return nil end

        local temple = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Temple of Time")
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
        local entrance = door:FindFirstChild("Entrance") or door
        if entrance:IsA("BasePart") then return entrance end
        return entrance:FindFirstChildWhichIsA("BasePart")
    end

    local function localDoorState()
        local char     = LocalPlayer.Character
        local hrp      = char and char:FindFirstChild("HumanoidRootPart")
        local hum      = char and char:FindFirstChildOfClass("Humanoid")
        local door     = getDoor()
        local distance = math.huge
        if door and hrp then distance = (door.Position - hrp.Position).Magnitude end
        local timerVisible = false
        pcall(function() timerVisible = LocalPlayer.PlayerGui.Main.Timer.Visible == true end)
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
        safeWriteJson(path, {
            job_id      = game.JobId,
            username    = USERNAME,
            ready       = ready,
            near_door   = st.nearDoor,
            updated_at  = v3ServerNow(),
            fired_round = handledRoundId,
        })
        return ready
    end

    -- READ ALL READY FILES
    local function readAllReadyFiles()
        local folder = groupFolder()
        if not folder then return 0, false end

        local readyCount = 0
        local total      = 0
        local now        = v3ServerNow()

        for _, name in ipairs(LOCAL_HELPERS) do
            if Players:FindFirstChild(name) then
                total = total + 1
                local path = folder .. "/ready_" .. sanitize(name) .. ".json"
                local data = safeReadJson(path)
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
        if not path then return nil end
        local data = safeReadJson(path)
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
            ffaNow = workspace.Map["Temple of Time"].FFABorder.Forcefield.Transparency == 0
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

        local now     = v3ServerNow()
        local fireAt  = now + V3_COUNTDOWN
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
            countdown  = V3_COUNTDOWN,
        }

        if safeWriteJson(commandPath(), command) then
            setStatus(string.format("Main | V3 countdown %.0fs...", V3_COUNTDOWN))
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
                    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.AssemblyLinearVelocity  = Vector3.zero
                        hrp.AssemblyAngularVelocity = Vector3.zero
                    end
                end)

                for i = 1, V3_FIRE_COUNT do
                    pcall(function()
                        ReplicatedStorage.Remotes.CommE:FireServer("ActivateAbility")
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
                            ffaOk = workspace.Map["Temple of Time"].FFABorder.Forcefield.Transparency == 0
                        end)
                        if ffaOk then return end
                        local timerOk = false
                        pcall(function() timerOk = LocalPlayer.PlayerGui.Main.Timer.Visible end)
                        if timerOk then return end
                    end
                    if handledRoundId ~= roundId then return end
                    local st2       = localDoorState()
                    local ffaActive = false
                    local insideTrial = false
                    pcall(function()
                        ffaActive = workspace.Map["Temple of Time"].FFABorder.Forcefield.Transparency == 0
                    end)
                    pcall(function()
                        insideTrial = LocalPlayer.PlayerGui.Main.Timer.Visible == true
                    end)
                    if st2.nearDoor and not ffaActive and not insideTrial then
                        setStatus("Ghost Temple! Resetting...")
                        handledRoundId  = ""
                        abilityCooldown = tick() + 8
                        pcall(function() LocalPlayer.Character.Humanoid.Health = 0 end)
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
        if activating then return false end
        if not (isnight() and isfullmoon()) then return false end

        local ffaNow = false
        pcall(function()
            ffaNow = workspace.Map["Temple of Time"].FFABorder.Forcefield.Transparency == 0
        end)
        if ffaNow or tick() < abilityCooldown then return false end

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

    -- POLL LOOP
    task.spawn(function()
        while task.wait(V3_FILE_POLL) do
            pcall(tryActivateAbility)
        end
    end)

    -- =========================================================
    -- HOP RANDOM SERVER VIA __ServerBrowser (sau khi xong trial / training)
    -- =========================================================
    local function hopRandomServer()
        local sb = ReplicatedStorage:FindFirstChild("__ServerBrowser")
            or ReplicatedStorage:WaitForChild("__ServerBrowser", 5)
        if not sb then return false end

        local servers = nil
        for page = 1, 10 do
            local ok, res = pcall(function()
                return sb:InvokeServer("getServers", page) or sb:InvokeServer(page)
            end)
            if ok and type(res) == "table" and next(res) ~= nil then
                servers = res
                break
            end
        end

        if not servers then return false end

        local validList = {}
        for jobId, data in pairs(servers) do
            local jid = tostring(jobId or (type(data) == "table" and data.JobId) or "")
            local count = tonumber(type(data) == "table" and (data.Count or data.Players or data.PlayerCount) or 0) or 0
            if jid ~= "" and jid ~= tostring(game.JobId) and count > 0 and count <= 11 then
                table.insert(validList, jid)
            end
        end

        if #validList > 0 then
            local target = validList[math.random(1, #validList)]
            setStatus(string.format("Hop random -> %s...", target:sub(1, 8)))
            pcall(function()
                sb:InvokeServer("teleport", target)
            end)
            return true
        end
        return false
    end

    -- FFA BORDER WATCHER: trial kết thúc -> invalidate V4 cache
    local lastFFAState_hop = 1
    task.spawn(function()
        while task.wait(0.3) do
            pcall(function()
                local ok, trans = pcall(function()
                    return workspace.Map["Temple of Time"].FFABorder.Forcefield.Transparency
                end)
                if not ok then return end
                if trans == 0 then
                    lastFFAState_hop = 0
                elseif lastFFAState_hop == 0 then
                    lastFFAState_hop = 1
                    -- Trial xong: xóa cache V4 để cập nhật trạng thái training mới ngay lập tức
                    invalidateV4Cache()
                    task.spawn(function()
                        task.wait(8)  -- server cần vài giây để cập nhật trạng thái
                        invalidateV4Cache()
                    end)
                end
            end)
        end
    end)

    -- HOP RANDOM AFTER TRIAL / TRAINING LOOP (chạy mỗi 5s)
    local lastRandomHopAt = 0
    task.spawn(function()
        task.wait(25)  -- đợi game load xong hoàn toàn
        while task.wait(5) do
            pcall(function()
                -- Helper KHONG BAO GIO random hop (tranh xung dot voi HopFM loop)
                if isAlly then return end
                -- Neu dang Full Moon: KHONG hop random, o lai lam trial
                local fmNow = isnight() and isfullmoon()
                if fmNow then return end
                -- Sap FM: o lai cho
                if isPreFMReady() then return end
                -- Kiem tra trang thai V4
                local v4 = getV4StatusSimple()
                if not v4 or v4.key == nil then setStatus("Status loading..."); return end
                if v4.key == "check_failed" then setStatus("Checking V4..."); return end
                if v4.needsTraining or v4.needsPurchase then
                    setStatus("Main | Dang training..."); return
                end
                if v4.canTrial then setStatus("Main | Trial ready - stay"); return end
                if v4.complete then setStatus("Main | V4 complete - wait FM"); return end
                -- Khi khong co Full Moon va da xong training -> Hop random tim server moi
                if tick() - lastRandomHopAt >= 10 then
                    lastRandomHopAt = tick()
                    hopRandomServer()
                end
            end)
        end
    end)

    -- UI (TurnV3 Label góc phải giữa màn hình)
    local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        or LocalPlayer:WaitForChild("PlayerGui", 10)

    local StatusLabel = nil

    local function createUI()
        pcall(function()
            local old = PlayerGui:FindFirstChild("TurnV3UI")
            if old then old:Destroy() end
        end)

        local sg = Instance.new("ScreenGui")
        sg.Name           = "TurnV3UI"
        sg.ResetOnSpawn   = false
        sg.IgnoreGuiInset = true
        sg.Parent         = PlayerGui

        StatusLabel = Instance.new("TextLabel", sg)
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
            while sg.Parent do
                task.wait(0.05)
                pcall(function()
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

    pcall(createUI)

    print(string.format("[TurnV3] Loaded | User=%s | Role=%s | FileSync=%s",
        USERNAME,
        isUper and "MAIN" or (isAlly and "HELPER" or "OBSERVER"),
        tostring(FILE_SYNC_AVAILABLE)
    ))
end

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

local myTrialCompleted = false
local trialInProgress = false

local races_trial_place = {
	["Human"] = Workspace._WorldOrigin.Locations:WaitForChild("Trial of Strength", 5),
	["Mink"] = Workspace._WorldOrigin.Locations:WaitForChild("Trial of Speed", 5),
	["Fishman"] = Workspace._WorldOrigin.Locations:WaitForChild("Trial of Water", 5),
	["Skypiea"] = Workspace._WorldOrigin.Locations:WaitForChild("Trial of the King", 5),
	["Ghoul"] = Workspace._WorldOrigin.Locations:WaitForChild("Trial of Carnage", 5),
	["Cyborg"] = Workspace._WorldOrigin.Locations:WaitForChild("Trial of the Machine", 5),
}

local race_abilities = {
	["Human"] = "Last Resort",
	["Mink"] = "Agility",
	["Fishman"] = "Water Body",
	["Skypiea"] = "Heavenly Blood",
	["Ghoul"] = "Heightened Senses",
	["Cyborg"] = "Energy Core"
}

-- getdoor defined above

local function isshouldturnonability()
	local count = 0
	pcall(function()
		local temple = Workspace.Map:FindFirstChild("Temple of Time")
		if not temple then return end
		for _, v in pairs(Workspace.Characters:GetChildren()) do
			if v.Name ~= localPlayer.Name and v:FindFirstChild("HumanoidRootPart") then
				local plr = Players:FindFirstChild(v.Name)
				if plr and plr:FindFirstChild("Data") and plr.Data:FindFirstChild("Race") then
					local theirrace = plr.Data.Race.Value
					local corridor = temple:FindFirstChild(theirrace .. "Corridor")
					local race_door = corridor and corridor:FindFirstChild("Door")
					race_door = race_door and (race_door:FindFirstChild("Entrance") or race_door:FindFirstChildWhichIsA("BasePart"))
					local abilityName = race_abilities[theirrace]
					if race_door and abilityName and (v.HumanoidRootPart.Position - race_door.Position).Magnitude < 15 then
						if v.HumanoidRootPart:FindFirstChild(abilityName) then
							count = count + 1
						end
					end
				end
			end
		end
	end)
	return count >= 2
end

function AutoTrialV4()
	if not isHelperAccount() and Settings["Auto Finish Train Quest"] and Settings["Stack Train With Trial Race"] and (CheckGoTrain()) then
		return
	end
	local lookup6 = game.Lighting.ClockTime
	if
		(CheckMoon() == "Full Moon" and not (lookup6 > 5 and lookup6 < 12) or CheckMoon() == "Next Night")
		and Settings["Hop Server [Trial Or Pull Lever]"]
	then
		if getgenv().TurnOffHOPSVPullAndTrial then
			if getgenv().TurnOffHOPSVPullAndTrial.SetValue then
				getgenv().TurnOffHOPSVPullAndTrial:SetValue(false)
			elseif getgenv().TurnOffHOPSVPullAndTrial.SetStage then
				getgenv().TurnOffHOPSVPullAndTrial:SetStage(false)
			end
		end
		task.wait(3)
	elseif Settings["Hop Server [Trial Or Pull Lever]"] then
		if (myTrialCompleted or postTrialHopDone) and Settings["Hop After Trial"] == false then
			-- Chặn hop sau khi hoàn thành trial nếu Hop After Trial = false
		else
			HopServer()
			return
		end
	end

	if not IsInTempleOfTime() and not VerifyNearbyTrial() then
		myTrialCompleted = false
		trialInProgress = false
		if TeleportTempleOfTime() == "locked" then
			uiLibrary.CreateNoti({ Title = "Skider Hub V4", Desc = "Temple of Time is locked", ShowTime = 5 })
			task.wait(5)
		end
		return
	end

	lookup6 = GetTempleOfTime()
	local forcefield = lookup6 and lookup6:FindFirstChild("FFABorder") and lookup6.FFABorder:FindFirstChild("Forcefield")
	-- Chỉ coi FFA active khi forcefield hiện lên (Transparency == 0) VÀ người chơi không còn trong phòng trial riêng
	local isFFAActive = forcefield and forcefield.Transparency == 0 and not isInsideOwnTrial()

	-- Nếu FFA đang diễn ra: Dừng tween ngay, nhường quyền cho FFA
	if isFFAActive then
		TweenManager.CancelCurrent()
		if isHelperAccount() then
			pcall(function()
				local char = localPlayer.Character
				local hum = char and char:FindFirstChild("Humanoid")
				if hum and hum.Health > 0 then
					hum.Health = 0
					pcall(function() char:BreakJoints() end)
				end
			end)
		end
		return
	end

	-- Nếu ĐÃ LÀM XONG PHẦN TRIAL CỦA MÌNH: ĐỨNG CHỜ TẠI CHỖ, TUYỆT ĐỐI KHÔNG ĐƯỢC TWEEN ĐI ĐÂU!
	if myTrialCompleted then
		TweenManager.CancelCurrent()
		return
	end

	-- Nếu trước đó đang làm trial mà hiện tại đã bị dịch chuyển về Temple of Time (hết trial zone):
	-- Tức là trial cá nhân đã hoàn tất, chuyển sang trạng thái đứng chờ FFA!
	if trialInProgress and not VerifyNearbyTrial() and IsInTempleOfTime() then

		-- Nếu là Helper bị chết/fail giữa trial -> KHÔNG set myTrialCompleted

		-- để họ quay về door và thử lại (không đứng chờ FFA)

		if isAlly then

			-- Helper bị fail trial: reset trạng thái để về door retry

			trialInProgress = false

			myTrialCompleted = false

			TweenManager.CancelCurrent()

			return

		else

			-- Main: đã thoát khỏi trial zone => đứng chờ FFA

			myTrialCompleted = true

			trialInProgress = false

			TweenManager.CancelCurrent()

			return

		end

	end

	if
		lookup6
			and (lookup6.FFABorder:FindFirstChild("Forcefield"))
			and lookup6.FFABorder.Forcefield.Transparency == 1
		or (VerifyNearbyTrial())
	then
		if game:GetService("Players").LocalPlayer.PlayerGui.Main.TopHUDList.RaidTimer.Visible then
			if VerifyNearbyTrial() and not getgenv().VerifyTrial then
				getgenv().VerifyTrial = true
			end
			repeat
				wait()
			until VerifyNearbyTrial()
				or not game:GetService("Players").LocalPlayer.PlayerGui.Main.TopHUDList.RaidTimer.Visible
			local localPlayer4 = game.Players.LocalPlayer.Data.Race.Value
			if localPlayer4 == "Human" then
				trialInProgress = true
				repeat
					task.wait()
					local character3 = TrialHuman()
					if character3 then
						repeat
							task.wait()
							EquipTool(NameWeapon(Settings["Select Weapon"] or "Melee"))
							SizePart(character3)
							if Settings["Select Weapon"] == "Blox Fruit" then
								ToTarget(character3.HumanoidRootPart.CFrame * CFrame.new(-7, 20, 0))
							else
								ToTarget(character3.HumanoidRootPart.CFrame * CFrame.new(7, 20, 0))
							end
							ClickM1(character3)
							UsedualFlock()
						until not IsMobAlive(character3)
							or not game:GetService("Players").LocalPlayer.PlayerGui.Main.TopHUDList.RaidTimer.Visible
							or (game.Players.LocalPlayer.Character.HumanoidRootPart.Position - game:GetService(
									"Workspace"
								)._WorldOrigin.Locations["Trial of Strength"].Position).Magnitude
								> 1000
					end
				until not game:GetService("Players").LocalPlayer.PlayerGui.Main.TopHUDList.RaidTimer.Visible
					or (
							game.Players.LocalPlayer.Character.HumanoidRootPart.Position
							- game:GetService("Workspace")._WorldOrigin.Locations["Trial of Strength"].Position
						).Magnitude
						> 1000
				myTrialCompleted = true
				trialInProgress = false
				TweenManager.CancelCurrent()
			elseif localPlayer4 == "Skypiea" then
				trialInProgress = true
				repeat
					task.wait()
					if
						game:GetService("Workspace")._WorldOrigin.Locations:FindFirstChild("Trial of the King")
						and (game.Players.LocalPlayer.Character.HumanoidRootPart.Position - game:GetService(
								"Workspace"
							)._WorldOrigin.Locations["Trial of the King"].CFrame.Position).Magnitude
							<= 1000
					then
						if game:GetService("Workspace").Map:FindFirstChild("SkyTrial") and game:GetService("Workspace").Map.SkyTrial:FindFirstChild("Model") and game:GetService("Workspace").Map.SkyTrial.Model:FindFirstChild("FinishPart") then
							ToTarget(game:GetService("Workspace").Map.SkyTrial.Model.FinishPart.CFrame)
						end
						task.wait(3)
					end
				until not game:GetService("Players").LocalPlayer.PlayerGui.Main.TopHUDList.RaidTimer.Visible
					or workspace.Map:FindFirstChild("Temple of Time") and workspace.Map["Temple of Time"].FFABorder.Forcefield.Transparency == 0
					or (game:GetService("Workspace").Map:FindFirstChild("SkyTrial") and game:GetService("Workspace").Map.SkyTrial:FindFirstChild("Model") and game:GetService("Workspace").Map.SkyTrial.Model:FindFirstChild("FinishPart") and localPlayer:DistanceFromCharacter(
							game:GetService("Workspace").Map.SkyTrial.Model.FinishPart.Position
						)
						> 1000)
				myTrialCompleted = true
				trialInProgress = false
				TweenManager.CancelCurrent()
			elseif localPlayer4 == "Fishman" then
				local part2 = game:GetService("Workspace")._WorldOrigin.Locations:FindFirstChild("Trial of Water")
				if part2 and localPlayer:DistanceFromCharacter(part2.Position) < 1500 then
					trialInProgress = true
					local humanoid4 = GetSeaBeastTrial()
					repeat
						task.wait()
						if humanoid4 then
							local rootPart7 = humanoid4:FindFirstChild("HumanoidRootPart")
							if rootPart7 then
								getgenv().AimPos = CFrame.new(rootPart7.Position.X, 40, rootPart7.Position.Z)
								TeleportSeabeast2(humanoid4)
								if localPlayer:DistanceFromCharacter(rootPart7.Position) < 400 then
									AutoAllSkill()
								end
							end
						end
					until not humanoid4
						or not humanoid4.Parent
						or humanoid4.Health.Value == 0
						or not game:GetService("Players").LocalPlayer.PlayerGui.Main.TopHUDList.RaidTimer.Visible
						or workspace.Map:FindFirstChild("Temple of Time") and workspace.Map["Temple of Time"].FFABorder.Forcefield.Transparency == 0
						or localPlayer:DistanceFromCharacter(
								game:GetService("Workspace")._WorldOrigin.Locations
									:FindFirstChild("Trial of Water").Position
							)
							> 1000
					myTrialCompleted = true
					trialInProgress = false
					TweenManager.CancelCurrent()
				end
			elseif localPlayer4 == "Mink" then
				trialInProgress = true
				repeat
					task.wait()
					if
						(
							game.Players.LocalPlayer.Character.HumanoidRootPart.Position
							- game:GetService("Workspace")._WorldOrigin.Locations["Trial of Speed"].Position
						).Magnitude <= 1000
					then
						if game:GetService("Workspace"):FindFirstChild("StartPoint") then
							ToTarget(game:GetService("Workspace").StartPoint.CFrame * CFrame.new(0, 2, 0))
						end
					end
				until not game:GetService("Players").LocalPlayer.PlayerGui.Main.TopHUDList.RaidTimer.Visible
					or localPlayer:DistanceFromCharacter(
							game:GetService("Workspace")._WorldOrigin.Locations
								:FindFirstChild("Trial of Speed").Position
						)
						> 1000
				myTrialCompleted = true
				trialInProgress = false
				TweenManager.CancelCurrent()
			elseif localPlayer4 == "Ghoul" then
				trialInProgress = true
				repeat
					task.wait()
					local character3 = TrialGhoul()
					if character3 then
						repeat
							task.wait()
							EquipTool(NameWeapon(Settings["Select Weapon"] or "Melee"))
							SizePart(character3)
							if Settings["Select Weapon"] == "Blox Fruit" then
								ToTarget(character3.HumanoidRootPart.CFrame * CFrame.new(-7, 20, 0))
							else
								ToTarget(character3.HumanoidRootPart.CFrame * CFrame.new(7, 20, 0))
							end
							UsedualFlock()
							ClickM1(character3)
						until not IsMobAlive(character3)
							or not game:GetService("Players").LocalPlayer.PlayerGui.Main.TopHUDList.RaidTimer.Visible
							or localPlayer:DistanceFromCharacter(
									game:GetService("Workspace")._WorldOrigin.Locations
										:FindFirstChild("Trial of Carnage").Position
								)
								> 1000
					end
				until not game:GetService("Players").LocalPlayer.PlayerGui.Main.TopHUDList.RaidTimer.Visible
					or localPlayer:DistanceFromCharacter(
							game:GetService("Workspace")._WorldOrigin.Locations
								:FindFirstChild("Trial of Carnage").Position
						)
						> 1000
				myTrialCompleted = true
				trialInProgress = false
				TweenManager.CancelCurrent()
			elseif localPlayer4 == "Cyborg" then
				repeat
					task.wait()
					ToTarget(CFrame.new(28282.5703125, 14896.8505859375, 105.1042709350586))
				until not game:GetService("Players").LocalPlayer.PlayerGui.Main.TopHUDList.RaidTimer.Visible
			end
		else
			-- CHƯA LÀM TRIAL VÀ ĐANG Ở TEMPLE OF TIME CHUẨN BỊ KÍCH HOẠT V3 TẠI CỬA
			if not myTrialCompleted and not trialInProgress then
				if not lookup6 then
					return
				end
				local part2 = lookup6[localPlayer.Data.Race.Value .. "Corridor"].Door.Door.RightDoor.Union
				if localPlayer:DistanceFromCharacter(part2.Position) > 8 then
					ToTarget(part2.CFrame)
				end
				if
					Settings["Multi Trial"]
					and (CheckMultiTeleDoor())
					and localPlayer:DistanceFromCharacter(part2.Position) <= 8
				then
					game:service("VirtualInputManager"):SendKeyEvent(true, "T", false, game)
					task.wait()
					game:service("VirtualInputManager"):SendKeyEvent(false, "T", false, game)
					return
				end
				if Settings["Auto Turn On V3 Near Door"] and (CheckMultiPlayerNearDoor()) then
					game:service("VirtualInputManager"):SendKeyEvent(true, "T", false, game)
					task.wait()
					game:service("VirtualInputManager"):SendKeyEvent(false, "T", false, game)
				end
			else
				TweenManager.CancelCurrent()
			end
		end
	elseif getgenv().VerifyTrial then
		if not Settings["Multi Trial"] and not isHelperAccount() then
			Settings["Auto Trial"] = false
			if ToggleAutoTrial then
				ToggleAutoTrial:SetValue(false)
			end
		end
		getgenv().VerifyTrial = false
	end
end

function PlayerTrial()
	local temple = workspace.Map:FindFirstChild("Temple of Time")
	if not temple or not temple:FindFirstChild("FFABorder") or not temple.FFABorder:FindFirstChild("Forcefield") then
		return nil
	end
	local player = temple.FFABorder.Forcefield
	local position9, value7 = player.Position, player.Size
	for key, value8 in
		pairs((workspace:FindPartsInRegion3(Region3.new(position9 - value7 / 2, position9 + value7 / 2), nil, 1 / 0)))
	do
		key = value8.Parent
		if key and (key:FindFirstChild("Humanoid")) then
			player = game.Players:GetPlayerFromCharacter(key)
			if player and player.Name ~= localPlayer.Name and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
				return player.Character
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
    pcall(function()
        if uiLibrary and uiLibrary.CreateNoti then
            uiLibrary.CreateNoti({ Title = "Skider Hub V4", Desc = "🚀 Đang vào JobID: " .. clean:sub(1, 8) .. "...", ShowTime = 3 })
        end
    end)
    return teleportViaServerBrowser(clean)
end

local function HopServerLessPlayer()
    pcall(function()
        if uiLibrary and uiLibrary.CreateNoti then
            uiLibrary.CreateNoti({ Title = "Skider Hub V4", Desc = "🔍 Đang tìm server ít người qua __ServerBrowser...", ShowTime = 2 })
        end
    end)
    task.spawn(function()
        local pool = getOpenServers(7)

        if #pool > 0 then
            table.sort(pool, function(a, b) return a.count < b.count end)
            local chosen = pool[1]
            _hopTried[chosen.id] = true
            pcall(function()
                if uiLibrary and uiLibrary.CreateNoti then
                    uiLibrary.CreateNoti({
                        Title = "Skider Hub V4",
                        Desc = string.format("🚀 Hop Low: Vào server %s (%d player)...", chosen.id:sub(1, 8), chosen.count),
                        ShowTime = 3
                    })
                end
            end)
            teleportViaServerBrowser(chosen.id)
            return true
        else
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

local SeaTeleportSection = Tabs.StatusServer:AddSection("Sea Teleport")

local function TeleportToSea(seaNum)
    local mapAttr = workspace:GetAttribute("MAP")
    local placeId = game.PlaceId
    if seaNum == 1 then
        if mapAttr == "Sea1" or placeId == 2753915549 then
            uiLibrary.CreateNoti({ Title = "Skider Hub V4", Desc = "You are already in Sea 1!", ShowTime = 3 })
            return
        end
        uiLibrary.CreateNoti({ Title = "Skider Hub V4", Desc = "Teleporting to Sea 1...", ShowTime = 4 })
        ReplicatedStorage.Remotes.CommF_:InvokeServer("TravelMain")
    elseif seaNum == 2 then
        if mapAttr == "Sea2" or placeId == 4442272183 then
            uiLibrary.CreateNoti({ Title = "Skider Hub V4", Desc = "You are already in Sea 2!", ShowTime = 3 })
            return
        end
        uiLibrary.CreateNoti({ Title = "Skider Hub V4", Desc = "Teleporting to Sea 2...", ShowTime = 4 })
        ReplicatedStorage.Remotes.CommF_:InvokeServer("TravelDressrosa")
    elseif seaNum == 3 then
        if mapAttr == "Sea3" or placeId == 7449423635 or placeId == 100117331123089 then
            uiLibrary.CreateNoti({ Title = "Skider Hub V4", Desc = "You are already in Sea 3!", ShowTime = 3 })
            return
        end
        uiLibrary.CreateNoti({ Title = "Skider Hub V4", Desc = "Teleporting to Sea 3...", ShowTime = 4 })
        ReplicatedStorage.Remotes.CommF_:InvokeServer("TravelZou")
    end
end

Tabs.StatusServer:AddButton({
    Title = "Sea 1",
    Description = "Teleport to First Sea (Main)",
    Callback = function()
        TeleportToSea(1)
    end
})

Tabs.StatusServer:AddButton({
    Title = "Sea 2",
    Description = "Teleport to Second Sea (Dressrosa)",
    Callback = function()
        TeleportToSea(2)
    end
})

Tabs.StatusServer:AddButton({
    Title = "Sea 3",
    Description = "Teleport to Third Sea (Zou)",
    Callback = function()
        TeleportToSea(3)
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
                "• Ancient One: " .. ancientStr .. "\n" ..
                "• Training: " .. tostring(currentTrainingStatus or "Idle")
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

-- [[ TAB: RACE DRACO ]]
local RaceDracoSection = Tabs.RaceDraco:AddSection("Race Draco")

local DracoStatusParagraph = Tabs.RaceDraco:AddParagraph({
    Title = "Ancient One Draco Status",
    Content = "Checking..."
})

Tabs.RaceDraco:AddToggle("AutoUpgradeRaceDraco", {
    Title = "Auto Upgrade Race V2-V3 Draco",
    Default = Settings["Auto Upgrade Race V2-V3 Draco"] or false,
    Callback = function(enabled)
        SaveSettings("Auto Upgrade Race V2-V3 Draco", enabled)
    end
})

Tabs.RaceDraco:AddToggle("AutoTrialDraco", {
    Title = "Auto Trial Draco",
    Default = Settings["Auto Trial Draco"] or false,
    Callback = function(enabled)
        SaveSettings("Auto Trial Draco", enabled)
    end
})

Tabs.RaceDraco:AddToggle("FullyTrialDraco", {
    Title = "Fully Trial Draco",
    Description = "Auto craft/find Prehistoric Island, clear volcano, trial, train, buy and choose gear",
    Default = Settings["Fully Trial Draco"] or false,
    Callback = function(enabled)
        SaveSettings("Fully Trial Draco", enabled)
    end
})

Tabs.RaceDraco:AddToggle("IgnoreCraftVolcanicMagnetDraco", {
    Title = "Ignore Craft Volcanic Magnet [Fully Draco]",
    Default = Settings["Ignore Craft Volcanic Magnet Draco"] or false,
    Callback = function(enabled)
        SaveSettings("Ignore Craft Volcanic Magnet Draco", enabled)
    end
})

Tabs.RaceDraco:AddToggle("AutoBuyGearDraco", {
    Title = "Auto Buy Gear Draco",
    Default = Settings["Auto Buy Gear Draco"] or false,
    Callback = function(enabled)
        SaveSettings("Auto Buy Gear Draco", enabled)
    end
})

Tabs.RaceDraco:AddToggle("AutoFinishTrainDracoQuest", {
    Title = "Auto Finish Train Draco Quest",
    Default = Settings["Auto Finish Train Draco Quest"] or false,
    Callback = function(enabled)
        SaveSettings("Auto Finish Train Draco Quest", enabled)
    end
})

local DracoVolcanoSection = Tabs.RaceDraco:AddSection("Draco Volcano Settings")

Tabs.RaceDraco:AddToggle("FixVolcanoSafe", {
    Title = "Fix Volcano Safe",
    Default = Settings["Fix Volcano Safe"] or false,
    Callback = function(enabled)
        SaveSettings("Fix Volcano Safe", enabled)
    end
})

Tabs.RaceDraco:AddDropdown("SelectWeaponKillGolem", {
    Title = "Select Weapon Kill Golem",
    Values = { "Melee", "Sword", "Blox Fruit", "Gun" },
    Default = Settings["Select Weapon Kill Golem"] or Settings["Select Weapon"] or "Melee",
    Callback = function(value)
        SaveSettings("Select Weapon Kill Golem", value)
    end
})

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            DracoStatusParagraph:SetDesc(CheckAcientOneDracoStatus())
        end)
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

Tabs.RaceV4:AddToggle("AutoTurnOnV4", {
    Title = "Auto Turn On V4",
    Default = Settings["Auto Turn On V4"] or false,
    Callback = function(enabled)
        SaveSettings("Auto Turn On V4", enabled)
    end
})

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
        if enabled then
            local mapAttr = workspace:GetAttribute("MAP")
            local placeId = game.PlaceId
            local isSea3 = (mapAttr == "Sea3") or (placeId == 7449423635) or (placeId == 100117331123089)
            if not isSea3 then
                uiLibrary.CreateNoti({ Title = "Skider Hub V4", Desc = "Multi Trial requires Sea 3! Traveling to Sea 3...", ShowTime = 5 })
                ReplicatedStorage.Remotes.CommF_:InvokeServer("TravelZou")
            end
        end
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
        if enabled then
            local mapAttr = workspace:GetAttribute("MAP")
            local placeId = game.PlaceId
            local isSea3 = (mapAttr == "Sea3") or (placeId == 7449423635) or (placeId == 100117331123089)
            if not isSea3 then
                uiLibrary.CreateNoti({ Title = "Skider Hub V4", Desc = "Auto Trial requires Sea 3! Traveling to Sea 3...", ShowTime = 5 })
                ReplicatedStorage.Remotes.CommF_:InvokeServer("TravelZou")
            end
        end
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

Tabs.RaceV4:AddToggle("HopAfterTrial", {
    Title = "Hop After Trial",
    Description = "Tự động hop server sau khi hoàn thành trial",
    Default = (Settings["Hop After Trial"] ~= nil) and Settings["Hop After Trial"] or true,
    Callback = function(enabled)
        SaveSettings("Hop After Trial", enabled)
    end
})

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
local function ExportConfigTableString()
    local configKeysOrder = {
        { key = "Select Team", default = (localPlayer.Team and localPlayer.Team.Name) or "Marines" },
        { key = "No Frog", default = false },
        { key = "Select Weapon", default = "Melee" },
        { key = "Auto Upgrade Race V2-V3 Draco", default = false },
        { key = "Auto Trial Draco", default = false },
        { key = "Fully Trial Draco", default = false },
        { key = "Ignore Craft Volcanic Magnet Draco", default = false },
        { key = "Auto Buy Gear Draco", default = false },
        { key = "Auto Finish Train Draco Quest", default = false },
        { key = "Fix Volcano Safe", default = false },
        { key = "Select Weapon Kill Golem", default = "Melee" },
        { key = "Auto Upgrade Race V2-V3", default = false },
        { key = "Auto Get Cyborg", default = false },
        { key = "Auto Get Fully Cyborg", default = false },
        { key = "Auto Get Cyborg Hop Collect Chest", default = false },
        { key = "Auto Get Ghoul", default = false },
        { key = "Hop Server Get Ghoul", default = false },
        { key = "Teleport Acient Clock", default = false },
        { key = "Auto Pull Lever V4", default = true },
        { key = "Auto Buy Gear", default = true },
        { key = "Select Gear V4", default = "Omega" },
        { key = "Auto Choose Gears", default = true },
        { key = "Auto Finish Train Quest", default = true },
        { key = "Stack Train With Trial Race", default = true },
        { key = "Multi Trial", default = false },
        { key = "Auto Reset Character", default = false },
        { key = "Auto Turn On V4", default = false },
        { key = "Select Players Multi", default = {} },
        { key = "Auto Trial", default = true },
        { key = "Auto Turn On V3 Near Door", default = true },
        { key = "V3 Countdown", default = 3 },
        { key = "Name Helper TurnV3", default = {} },
        { key = "Hop Server [Trial Or Pull Lever]", default = true },
        { key = "Hop After Trial", default = true },
        { key = "Select Weapon Attack Trial", default = "Melee" },
        { key = "Kill players When complete Trial", default = true },
        { key = "Use Skill when Kill Player", default = true },
        { key = "Just Use Skill when Player Active Ken", default = false },
        { key = "Auto Click", default = true },
    }

    local lines = { "getgenv().Config = {" }
    for _, item in ipairs(configKeysOrder) do
        local k = item.key
        local val = Settings[k]
        if val == nil then
            val = item.default
        end

        local prefix = string.format("    [%q]", k)
        local pad = 46 - #prefix
        if pad < 1 then pad = 1 end
        local spacing = string.rep(" ", pad)

        if type(val) == "boolean" then
            table.insert(lines, prefix .. spacing .. "= " .. (val and "true" or "false") .. ",")
        elseif type(val) == "number" then
            table.insert(lines, prefix .. spacing .. "= " .. tostring(val) .. ",")
        elseif type(val) == "string" then
            table.insert(lines, prefix .. spacing .. '= "' .. tostring(val) .. '",')
        elseif type(val) == "table" then
            local list = {}
            for _, subVal in pairs(val) do
                table.insert(list, tostring(subVal))
            end
            if #list == 0 then
                table.insert(lines, prefix .. spacing .. "= {},")
            else
                table.insert(lines, prefix .. spacing .. "= {")
                for i, subVal in ipairs(list) do
                    local comma = (i < #list) and "," or ""
                    table.insert(lines, string.format('        %q%s', subVal, comma))
                end
                table.insert(lines, "    },")
            end
        else
            table.insert(lines, prefix .. spacing .. "= " .. tostring(val) .. ",")
        end
    end
    table.insert(lines, "}")
    return table.concat(lines, "\n")
end

local ConfigSection = Tabs.Settings:AddSection("Configuration")

Tabs.Settings:AddButton({
    Title = "Copy Setting",
    Description = "Copy entire active config to clipboard (getgenv().Config format)",
    Callback = function()
        local configStr = ExportConfigTableString()
        local copyFn = setclipboard or toclipboard or (Clipboard and Clipboard.set) or (syn and syn.write_clipboard)
        if copyFn then
            copyFn(configStr)
            if uiLibrary and uiLibrary.CreateNoti then
                uiLibrary.CreateNoti({
                    Title = "Configuration",
                    Content = "Copied Config to Clipboard successfully!",
                    Duration = 4
                })
            else
                Fluent:Notify({
                    Title = "Configuration",
                    Content = "Copied Config to Clipboard successfully!",
                    Duration = 4
                })
            end
        else
            if uiLibrary and uiLibrary.CreateNoti then
                uiLibrary.CreateNoti({
                    Title = "Clipboard Error",
                    Content = "Your executor does not support setclipboard!",
                    Duration = 4
                })
            end
        end
    end
})

Tabs.Settings:AddButton({
    Title = "Copy Full Script",
    Description = "Copy Config + Loader script to clipboard",
    Callback = function()
        local fullScript = ExportConfigTableString() .. '\n\nloadstring(game:HttpGet("https://raw.githubusercontent.com/Bieoidungbuonnua/v4/refs/heads/main/skiderhubv4.lua"))()'
        local copyFn = setclipboard or toclipboard or (Clipboard and Clipboard.set) or (syn and syn.write_clipboard)
        if copyFn then
            copyFn(fullScript)
            if uiLibrary and uiLibrary.CreateNoti then
                uiLibrary.CreateNoti({
                    Title = "Configuration",
                    Content = "Copied Full Script to Clipboard successfully!",
                    Duration = 4
                })
            else
                Fluent:Notify({
                    Title = "Configuration",
                    Content = "Copied Full Script to Clipboard successfully!",
                    Duration = 4
                })
            end
        end
    end
})

local CombatSection = Tabs.Settings:AddSection("Combat Settings")

Tabs.Settings:AddToggle("AutoClickToggle", {
    Title = "Auto Click",
    Description = "Fast Attack continuously when holding Melee or Sword",
    Default = Settings["Auto Click"] ~= nil and Settings["Auto Click"] or true,
    Callback = function(enabled)
        SaveSettings("Auto Click", enabled)
    end
})

InterfaceManager:SetLibrary(Fluent)
InterfaceManager:SetFolder("SkiderV4")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)

Window:SelectTab(1)

--------------------------------------------------------------------------------
-- 7. WORKER LOOPS (Preserved and complete)
--------------------------------------------------------------------------------

-- Worker: Auto Click (Continuous Fast Attack for Melee / Sword)
task.spawn(function()
    while task.wait(0.03) do
        if Settings["Auto Click"] then
            local char = localPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if char and hum and hum.Health > 0 then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool and (tool.ToolTip == "Melee" or tool.ToolTip == "Sword" or tool:FindFirstChild("Melee") or tool:FindFirstChild("Sword")) then
                    pcall(function()
                        tool:Activate()
                    end)
                    fastAttackInstance:Attack()
                end
            end
        end
    end
end)

-- Draco workers (full Race Draco block from bnn.lua)
task.spawn(function()
    while task.wait(0.2) do
        if Settings["Auto Upgrade Race V2-V3 Draco"] and not Settings["Fully Trial Draco"] then
            pcall(AutoUpgradeRaceDraco)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if Settings["Auto Trial Draco"] and not Settings["Fully Trial Draco"] then
            pcall(AutoTrialDraco)
        end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if Settings["Fully Trial Draco"] then pcall(FullyDraco) end
    end
end)

task.spawn(function()
    while task.wait(0.3) do
        if Settings["Auto Buy Gear Draco"] then pcall(BuyGearDracoV4) end
    end
end)

task.spawn(function()
    while task.wait(0.2) do
        if Settings["Auto Finish Train Draco Quest"] and not Settings["Fully Trial Draco"] then
            pcall(function()
                local status = CheckAcientOneDracoStatus()
                if string.find(status, "Can Buy Gear", 1, true) then
                    BuyGearDracoV4()
                else
                    TrainDraco("Auto Finish Train Draco Quest")
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.25) do
        if Settings["Auto Turn On V4"] then pcall(TurnOnV4) end
    end
end)

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

-- Race V4 Training Execution Engine (From piggyv4)
local function runRaceTrainingWork()
    local char = localPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then
        currentTrainingStatus = "Waiting for character"
        task.wait(1)
        return false
    end

    -- 1. Nếu đang ở trong Temple of Time mà cần training -> Reset để Out Temple ra Sea 3
    if IsInTempleOfTime() then
        currentTrainingStatus = "Out Temple: Resetting character..."
        pcall(function()
            char.Humanoid.Health = 0
        end)
        task.wait(3)
        return false
    end

    -- 2. Kiểm tra tiến trình training
    if not CheckGoTrain() then
        local code = nil
        pcall(function()
            code = ReplicatedStorage.Remotes.CommF_:InvokeServer("UpgradeRace", "Check")
        end)
        if code == 2 or code == 4 or code == 7 then
            currentTrainingStatus = "Buying V4 upgrade..."
            BuyGearV4()
            task.wait(1)
        else
            currentTrainingStatus = "Training complete - Ready for trial"
        end
        isCurrentlyTraining = false
        blockHopAfterTrial = false
        return true
    end

    -- 3. Kiểm tra RaceTransformed khi vừa respawn sau trial reset
    if not char:FindFirstChild("RaceTransformed") then
        if postTrialResetScheduled then
            currentTrainingStatus = "Waiting character load after trial reset..."
            local waitStart = tick()
            repeat
                task.wait(0.3)
                char = localPlayer.Character
            until (char and char:FindFirstChild("RaceTransformed")) or tick() - waitStart > 6
            char = localPlayer.Character
            if not char or not char:FindFirstChild("RaceTransformed") then
                return false
            end
        else
            local ok, vp = pcall(function()
                return ReplicatedStorage.Remotes.CommF_:InvokeServer("RaceV4Progress", "Check")
            end)
            if ok and vp == 1 then
                pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("RaceV4Progress", "Begin") end)
            end
        end
    end

    isCurrentlyTraining = true
    blockHopAfterTrial = true

    -- 4. Kích hoạt Race V4 nếu thanh năng lượng đã đầy
    pcall(function()
        local energy = char:FindFirstChild("RaceEnergy")
        local transformed = char:FindFirstChild("RaceTransformed")
        if energy and energy.Value >= 1 and transformed and not transformed.Value then
            VirtualInputManager:SendKeyEvent(true, "Y", false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, "Y", false, game)
        end
    end)

    -- 5. Chọn đảo training phù hợp (vắng người nhất)
    local islandName = assignTrainingIsland()
    if not islandName then
        currentTrainingStatus = "No island available - Retrying"
        return false
    end
    local islandData = TrainingIslandData[islandName]
    if not islandData then
        forceReassignIsland()
        return false
    end

    local trainingPositions = nil
    if islandData.Positions then
        trainingPositions = islandData.Positions
    elseif islandData.Position then
        trainingPositions = { islandData.Position }
    else
        return false
    end

    local currentPosIndex = 1
    local function getCurrentPos()
        return trainingPositions[currentPosIndex]
    end
    local function advancePosition()
        currentPosIndex = currentPosIndex + 1
        if currentPosIndex > #trainingPositions then currentPosIndex = 1 end
    end

    local trainingPos = getCurrentPos()
    local hrp = char.HumanoidRootPart
    local distToIsland = (hrp.Position - trainingPos.Position).Magnitude
    if distToIsland >= 1500 then
        currentTrainingStatus = "Moving to [" .. tostring(islandName) .. "] for training"
        ToTarget(trainingPos)
        return false
    end

    local mobNames = {}
    for name in pairs(islandData.Mobs) do
        table.insert(mobNames, name)
    end

    local ATTACK_RANGE = 15
    local lastTweenAt = 0

    local function shouldStopTraining()
        if not Settings["Auto Finish Train Quest"] then return true end
        if not CheckGoTrain() then return true end
        return false
    end

    -- 6. Vòng lặp tìm quái và đánh sạc V4
    local cycleStart = tick()
    while not shouldStopTraining() and (tick() - cycleStart < 25) do
        local mob = CheckMonster(table.unpack(mobNames))
        if not mob then
            currentTrainingStatus = "[" .. tostring(islandName) .. "] Waiting for mobs..."
            ToTarget(getCurrentPos())
            task.wait(0.8)
            advancePosition()
        else
            repeat
                task.wait()
                char = localPlayer.Character
                if not char or not char:FindFirstChildOfClass("Humanoid") or char.Humanoid.Health <= 0 then break end
                if not mob or not mob.Parent or not mob:FindFirstChildOfClass("Humanoid") or mob:FindFirstChildOfClass("Humanoid").Health <= 0 then break end

                local mobHrp = mob.PrimaryPart or mob:FindFirstChild("HumanoidRootPart")
                if not mobHrp or not char:FindFirstChild("HumanoidRootPart") then break end

                local targetPos = mobHrp.Position + Vector3.new(0, 25, 7)
                local dist = (char.HumanoidRootPart.Position - mobHrp.Position).Magnitude
                ToTarget(CFrame.new(targetPos))

                if dist <= 50 then
                    BringMob(mob.Name)
                    equipWeapon(Settings["Select Weapon"])
                    FastAttack()
                end

                -- Nhấn Y kích hoạt Race V4 khi energy đầy
                local energy = char:FindFirstChild("RaceEnergy")
                if energy and energy.Value >= 1 then
                    VirtualInputManager:SendKeyEvent(true, "Y", false, game)
                    task.wait(0.05)
                    VirtualInputManager:SendKeyEvent(false, "Y", false, game)
                end

                currentTrainingStatus = "[" .. tostring(islandName) .. "] Farming mobs & charging V4"
            until not checkmob_(mob) or shouldStopTraining()
        end
    end

    -- 7. Kiểm tra sau vòng training xem đã hoàn tất chưa
    if not CheckGoTrain() then
        local code = nil
        pcall(function()
            code = ReplicatedStorage.Remotes.CommF_:InvokeServer("UpgradeRace", "Check")
        end)
        if code == 2 or code == 4 or code == 7 then
            currentTrainingStatus = "Training done! Buying V4 upgrade..."
            BuyGearV4()
            task.wait(1)
        end
        isCurrentlyTraining = false
        blockHopAfterTrial = false
        forceReassignIsland()
        return true
    end

    return false
end

-- Worker 8: Auto Finish Train Quest
task.spawn(function()
    while task.wait(0.2) do
        if Settings["Auto Finish Train Quest"] then
            pcall(function()
                if Settings["Stack Train With Trial Race"] and not CheckGoTrain() then
                    isCurrentlyTraining = false
                    return
                end
                runRaceTrainingWork()
            end)
        else
            isCurrentlyTraining = false
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

-- Worker 9: Kill players when complete trial (from kaiv4.lua)
task.spawn(function()
	while task.wait(0.1) do
		pcall(function()
			if Settings["Kill players When complete Trial"] then
				local temple = GetTempleOfTime()
				if temple and temple:FindFirstChild("FFABorder") and temple.FFABorder:FindFirstChild("Forcefield") and temple.FFABorder.Forcefield.Transparency ~= 1 then
					if game:GetService("Players").LocalPlayer.PlayerGui.Main.TopHUDList.RaidTimer.Visible then
						local character3, enabled7 = PlayerTrial(), false
						if character3 then
							repeat
								task.wait()
								task.spawn(function()
									if Lighting:FindFirstChild("Blur") and not Lighting.Blur.Enabled then
										game:GetService("VirtualInputManager"):SendKeyEvent(true, "E", false, game)
										task.wait()
										game:GetService("VirtualInputManager"):SendKeyEvent(false, "E", false, game)
										task.wait(3)
									end
									getgenv().AimPos = character3.HumanoidRootPart.CFrame
								end)
								if HasCooldownChanged(character3) then
									local timestamp = tick()
									repeat
										task.wait()
										task.spawn(getgenv().AttackFunctionnhungSuperTrial)
										localPlayer.Character.HumanoidRootPart.CFrame = character3.HumanoidRootPart.CFrame
											* CFrame.new(0, 50, 0)
									until tick() - timestamp >= 0.75
									enabled7 = false
								else
									if enabled7 then
										return
									end
									localPlayer.Character.HumanoidRootPart.CFrame = character3.HumanoidRootPart.CFrame
										* CFrame.new(0, 0, 4)
								end
								task.spawn(getgenv().AttackFunctionnhungSuperTrial)
								EquipTool(NameWeapon(Settings["Select Weapon Attack Trial"]))
								if
									Settings["Use Skill when Kill Player"]
									or Settings["Just Use Skill when Player Active Ken"]
								then
									if
										Settings["Just Use Skill when Player Active Ken"]
											and (game.Players[character3.Name]:GetAttribute("KenActive"))
										or not Settings["Just Use Skill when Player Active Ken"]
									then
										task.spawn(function()
											local object =
												CheckCDSkill(NameWeapon(Settings["Select Weapon Attack Trial"]))
											if object then
												game:GetService("VirtualInputManager")
													:SendKeyEvent(true, object.Name, false, game)
												task.wait(0.05)
												game:GetService("VirtualInputManager")
													:SendKeyEvent(false, object.Name, false, game)
											end
										end)
									end
								end
							until not character3
								or not character3.Parent
								or not character3:FindFirstChild("Humanoid")
								or character3.Humanoid.Health <= 0
								or not Settings["Kill players When complete Trial"]
								or not game:GetService("Players").LocalPlayer.PlayerGui.Main.TopHUDList.RaidTimer.Visible
								or not localPlayer.Character
								or not localPlayer.Character:FindFirstChild("Humanoid")
								or localPlayer.Character.Humanoid.Health <= 0
						end
					end
				end
			end
		end)
	end
end)


-- Worker 10: Auto Trial & Auto Reset Character
-- Helper bắt buộc reset khi FFA active (nguyên si logic kaiv4.lua gốc)
-- Out Temple (ChooseGear/BuyGear) chỉ dành cho Main
task.spawn(function()
	-- Cache role mỗi 2s để tránh rebuild HelpWhitelist quá thường xuyên
	local cachedIsHelper = isAlly
	local lastRoleRefresh = 0
	while task.wait(0.1) do
		-- Refresh role cache mỗi 2 giây
		if tick() - lastRoleRefresh > 2 then
			refreshTurnV3Roles()
			cachedIsHelper = isAlly
			lastRoleRefresh = tick()
		end

		-- Nếu Helper đang training -> nhường Worker 8 train xong rồi mới làm trial/reset
		if cachedIsHelper and isCurrentlyTraining and Settings["Auto Finish Train Quest"] and CheckGoTrain() then
			continue
		end

		if Settings["Auto Trial"] or Settings["Multi Trial"] then
			local success, result = pcall(function()
				AutoTrialV4()
			end)
			if result then
				print(success, result)
			end
		end

		-- Auto Reset (nguyên si logic kaiv4.lua gốc):
		-- Helper BẮT BUỘC reset khi FFA active (không cần bật toggle)
		pcall(function()
			local temple = GetTempleOfTime()
			if temple and temple.FFABorder.Forcefield.Transparency ~= 1 then
				if cachedIsHelper or Settings["Auto Reset Character"] then
					-- Helper: bắt buộc reset; main reset khi người dùng bật toggle
					localPlayer.Character.Humanoid.Health = 0
				end
			end
		end)
	end
end)

-- FFA Watcher & Post-Trial Out Temple (From piggyv4)
-- Out Temple (ChooseGear/BuyGear/Reset) chỉ dành cho Main (isUper)
task.spawn(function()
    while task.wait(0.3) do
        pcall(function()
            local temple = GetTempleOfTime()
            if not temple or not temple:FindFirstChild("FFABorder") or not temple.FFABorder:FindFirstChild("Forcefield") then
                return
            end
            local trans = temple.FFABorder.Forcefield.Transparency
            if trans == 0 then
                -- FFA đang diễn ra
                lastFFAState = 0
                postTrialResetScheduled = false
            elseif lastFFAState == 0 then
                -- Chuyển từ 0 sang 1: FFA vừa kết thúc!
                lastFFAState = 1
                -- Chỉ Main mới làm Out Temple (nhận gear + reset ra Sea 3)
                if isUper and not postTrialResetScheduled then
                    postTrialResetScheduled = true
                    blockHopAfterTrial = true
                    postTrialHopDone = true
                    task.spawn(function()
                        if uiLibrary and uiLibrary.CreateNoti then
                            uiLibrary.CreateNoti({ Title = "Skider Hub V4", Desc = "Trial completed! Claiming gear...", ShowTime = 5 })
                        end
                        -- 1. Nhận gear và mua gear tại đền
                        task.wait(1)
                        pcall(ChooseGearV4)
                        task.wait(1)
                        pcall(BuyGearV4)
                        -- 2. Chờ 5s rồi reset để Out Temple ra Sea 3
                        if uiLibrary and uiLibrary.CreateNoti then
                            uiLibrary.CreateNoti({ Title = "Skider Hub V4", Desc = "Out Temple: Resetting character in 5s...", ShowTime = 5 })
                        end
                        task.wait(5)
                        pcall(function()
                            local char = localPlayer.Character
                            if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                                char.Humanoid.Health = 0
                            end
                        end)
                        if uiLibrary and uiLibrary.CreateNoti then
                            uiLibrary.CreateNoti({ Title = "Skider Hub V4", Desc = "Out Temple complete! Respawning in Sea 3...", ShowTime = 5 })
                        end
                        task.wait(10)
                        postTrialResetScheduled = false
                        blockHopAfterTrial = false
                        if Settings["Hop After Trial"] ~= false and Settings["Hop Server [Trial Or Pull Lever]"] then
                            task.wait(2)
                            HopServer()
                        end
                    end)
                end
            end
        end)
    end
end)



uiLibrary.CreateNoti({ Title = "Skider Hub V4", Desc = "Script loaded successfully", ShowTime = 5 })
 
