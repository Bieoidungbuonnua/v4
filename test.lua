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

-- A supplied JoinV4/Skiderhubv4 group config is itself an explicit OneClickV4 request.
-- This also supports loaders that forgot to assign getgenv().Mode separately.
local _HAS_EXTERNAL_JOINV4_CONFIG = type(getgenv().JoinV4Config) == "table"
    or type(getgenv().Skiderhubv4Config) == "table"
if getgenv().Mode == nil then
    local legacyMode = type(getgenv().Skiderhubv4Config) == "table" and getgenv().Skiderhubv4Config.Mode
    getgenv().Mode = legacyMode or (_HAS_EXTERNAL_JOINV4_CONFIG and "OneClickV4" or "Main")
end
do
    local normalizedMode = tostring(getgenv().Mode):gsub("^%s+", ""):gsub("%s+$", ""):gsub(",+$", "")
    if normalizedMode:lower() == "oneclickv4" then
        getgenv().Mode = "OneClickV4"
    elseif normalizedMode:lower() == "main" then
        getgenv().Mode = "Main"
    end
end

-- OneClickV4 starts only after player data is ready, matching its loader contract.
if getgenv().Mode == "OneClickV4" and not localPlayer:FindFirstChild("DataLoaded") then
    localPlayer:WaitForChild("DataLoaded")
end

-- Shared JoinV4 configuration (kept compatible with the original BNN bundle)
local _DEFAULT_JOINV4_CFG = {
    ["Key-Banana"] = "31d4bebb966b95e8bd94d7a6",
    ["Helper"] = {
        {"Cart3rRid3rDrag0n", "penel0peScott1"},
    },
    ["Note"] = {"trietautov4"},
    ["LimitMainPerGroup"] = 10,
}

-- Backward-compatible alias for early OneClickV4 config drafts.
if type(getgenv().JoinV4Config) ~= "table" and type(getgenv().Skiderhubv4Config) == "table" then
    getgenv().JoinV4Config = getgenv().Skiderhubv4Config
end

if type(getgenv().JoinV4Config) ~= "table" then
    getgenv().JoinV4Config = _DEFAULT_JOINV4_CFG
else
    for key, value in pairs(_DEFAULT_JOINV4_CFG) do
        if getgenv().JoinV4Config[key] == nil then
            getgenv().JoinV4Config[key] = value
        end
    end
end

do
    local seen, helperList = {}, {}
    for _, group in ipairs(getgenv().JoinV4Config["Helper"] or {}) do
        if type(group) == "table" then
            for _, name in ipairs(group) do
                local clean = tostring(name):gsub("^%s+", ""):gsub("%s+$", "")
                if clean ~= "" and not seen[clean] then
                    seen[clean] = true
                    table.insert(helperList, clean)
                end
            end
        elseif type(group) == "string" then
            local clean = group:gsub("^%s+", ""):gsub("%s+$", "")
            if clean ~= "" and not seen[clean] then
                seen[clean] = true
                table.insert(helperList, clean)
            end
        end
    end
    getgenv().HelperList = helperList
end

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
    if getgenv().Mode == "OneClickV4" then
        targetTeam = "Marines"
    end
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
-- HideUI: khi OneClickV4 + JoinV4Config["HideUI"] = true
-- → bỏ qua load Fluent nặng, dùng stub nhẹ, vẫn chạy automation đầy đủ
local _HIDE_UI = getgenv().Mode == "OneClickV4"
    and type(getgenv().JoinV4Config) == "table"
    and getgenv().JoinV4Config["HideUI"] == true

local Fluent, InterfaceManager, Window, Tabs, uiLibrary

if _HIDE_UI then
    -- Stub nhẹ: không load gì nặng, chỉ tạo dummy objects
    local _noTab = setmetatable({}, {
        __index = function(_, _k)
            return function(...) return {} end
        end
    })
    Fluent = {
        Notify = function(p)
            print(string.format("[SkiderV4] %s: %s", tostring(p and p.Title or ""), tostring(p and p.Content or "")))
        end
    }
    InterfaceManager = {
        SetLibrary = function() end,
        SetFolder  = function() end,
        BuildInterfaceSection = function() end,
    }
    Window = {
        AddTab      = function() return _noTab end,
        SelectTab   = function() end,
        Minimize    = function() end,
    }
    Tabs = {
        StatusServer = _noTab,
        RaceNormal   = _noTab,
        RaceV4       = _noTab,
        KillTrial    = _noTab,
        Settings     = _noTab,
    }
    uiLibrary = {
        CreateNoti = function(p)
            print(string.format("[SkiderV4] %s | %s", tostring(p and p.Title or ""), tostring(p and p.Desc or "")))
        end
    }
else
    -- Load đầy đủ Fluent UI bình thường
    Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
    InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

    Window = Fluent:CreateWindow({
        Title = "Skider Hub V4",
        SubTitle = "create by biee_dungbuon",
        TabWidth = 160,
        Size = UDim2.fromOffset(580, 460),
        Acrylic = true,
        Theme = "Dark",
        MinimizeKey = Enum.KeyCode.LeftControl
    })

    Tabs = {
        StatusServer = Window:AddTab({ Title = "Status & Server", Icon = "activity" }),
        RaceNormal   = Window:AddTab({ Title = "Race Normal", Icon = "user" }),
        RaceV4       = Window:AddTab({ Title = "Race V4", Icon = "sparkles" }),
        KillTrial    = Window:AddTab({ Title = "Kill Trial", Icon = "swords" }),
        Settings     = Window:AddTab({ Title = "Settings", Icon = "settings" }),
    }

    uiLibrary = {
        CreateNoti = function(params)
            Fluent:Notify({
                Title   = params.Title or "Skider Hub V4",
                Content = params.Desc or "",
                Duration = params.ShowTime or 5,
            })
        end
    }
end

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

-- OneClickV4 owns these values: saved settings and getgenv().Config cannot disable them.
-- JoinV4Config.Helper stays nested: one row is one group and slot [1] is Helper (FM).
local ONECLICK_V4_SETTINGS = {
    ["Auto Trial"] = true,
    ["Auto Turn On V3 Near Door"] = true,
    ["V3 Countdown"] = 3,
    ["Auto Buy Gear"] = true,
    ["Select Gear V4"] = "Omega",
    ["Auto Choose Gears"] = true,
    ["Auto Finish Train Quest"] = true,
    ["Stack Train With Trial Race"] = true,
    ["Multi Trial"] = true,
    ["Select Team"] = "Marines",
    ["No Frog"] = true,
}

local function ApplyOneClickV4Settings()
    for key, value in pairs(ONECLICK_V4_SETTINGS) do
        Settings[key] = value
    end
    local joinConfig = getgenv().JoinV4Config
    if type(joinConfig) == "table" and joinConfig["Hop After Trial"] ~= nil then
        Settings["Hop After Trial"] = joinConfig["Hop After Trial"] == true
    end
end

if getgenv().Mode == "OneClickV4" then
    ApplyOneClickV4Settings()

    local helperNames, helperSelection, seenHelpers = {}, {}, {}
    for _, group in ipairs(getgenv().JoinV4Config["Helper"] or {}) do
        if type(group) == "table" then
            for _, rawName in ipairs(group) do
                local name = tostring(rawName):gsub("^%s+", ""):gsub("%s+$", "")
                if name ~= "" and not seenHelpers[name] then
                    seenHelpers[name] = true
                    table.insert(helperNames, name)
                    helperSelection[name] = true
                end
            end
        end
    end
    Settings["Name Helper TurnV3"] = helperNames
    Settings["Select Players Multi"] = helperSelection
    getgenv().HelperList = helperNames
end

if Settings["Auto Click"] == nil then
    Settings["Auto Click"] = true
end
if Settings["Auto Turn On Buso"] == nil then
    Settings["Auto Turn On Buso"] = true
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

-- [COMBAT, FAST ATTACK & BRING MOB] Ported from bnn.lua
if Settings["Bring Mob"] == nil then Settings["Bring Mob"] = true end
if Settings["Bring Mob Count"] == nil then Settings["Bring Mob Count"] = 2 end
if Settings["Attack No Animation "] == nil then Settings["Attack No Animation "] = true end

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

getgenv().TableMobSpawn = getgenv().TableMobSpawn or {}
local TableMobSpawn = getgenv().TableMobSpawn

local function BnnAddMobSpawn(part)
    if part and not table.find(TableMobSpawn, part) then
        table.insert(TableMobSpawn, part)
    end
end

local function BnnRefreshMobSpawns()
    local origin = Workspace:FindFirstChild("_WorldOrigin")
    local enemySpawns = origin and origin:FindFirstChild("EnemySpawns")
    for _, part in ipairs(enemySpawns and enemySpawns:GetChildren() or {}) do
        local displayName = part:GetAttribute("DisplayName")
        if displayName and string.find(displayName, "Lv.") then BnnAddMobSpawn(part) end
    end
    if getnilinstances then
        pcall(function()
            for _, part in ipairs(getnilinstances()) do
                local displayName = part:GetAttribute("DisplayName")
                if displayName and string.find(displayName, "Lv.") then BnnAddMobSpawn(part) end
            end
        end)
    end
end
BnnRefreshMobSpawns()

local function BnnCleanMobName(name)
    return string.find(name, "Lv.") and name:gsub(" %pLv. %d+%p", "") or name
end

function DetectPartMobBring(name, mob, nearest, centerPart)
    BnnRefreshMobSpawns()
    local matches = {}
    local cleanName = BnnCleanMobName(name)
    for _, part in ipairs(TableMobSpawn) do
        if part and part:IsA("Part") then
            local cleanPartName = BnnCleanMobName(part.Name)
            if cleanPartName == name or part.Name == name or part.Name == cleanName then
                table.insert(matches, part)
            end
        end
    end
    if nearest then
        local bestDistance, bestPart = math.huge, nil
        local root = mob and mob:FindFirstChild("HumanoidRootPart")
        if not root then return nil end
        for _, part in ipairs(matches) do
            local distance = (root.Position - part.Position).Magnitude
            if distance < bestDistance then bestDistance, bestPart = distance, part end
        end
        return bestPart
    end
    local nearby = 0
    for _, part in ipairs(matches) do
        if centerPart and (centerPart.Position - part.Position).Magnitude <= 200 then nearby += 1 end
    end
    return nearby < #matches
end

function getcenter(name)
    BnnRefreshMobSpawns()
    local cleanName = BnnCleanMobName(name)
    local sum, count = Vector3.zero, 0
    for _, part in ipairs(TableMobSpawn) do
        if part and part:IsA("Part") then
            local cleanPartName = BnnCleanMobName(part.Name)
            if cleanPartName == name or part.Name == name or part.Name == cleanName then
                sum += part.Position
                count += 1
            end
        end
    end
    return count > 0 and CFrame.new(sum / count) or nil
end

function isnetworkowner2(part)
    if not part then return false end
    local characters = Workspace:FindFirstChild("Characters")
    for _, character in ipairs(characters and characters:GetChildren() or {}) do
        local root = character:FindFirstChild("HumanoidRootPart")
        if character.Name ~= localPlayer.Name and root and (root.Position - part.Position).Magnitude <= 300 then
            return false
        end
    end
    return true
end

function DeleteIgnoredMob()
    local enemies = Workspace:FindFirstChild("Enemies")
    for _, mob in ipairs(enemies and enemies:GetChildren() or {}) do
        local ignored = mob:IsA("Model") and mob:FindFirstChild("Ignored")
        if ignored then ignored:Destroy() end
    end
end

local bnnBringTarget, bnnBringAnchor
function BringMob(target)
    if not Settings["Bring Mob"] or not IsMobAlive(target) then return end
    local character = localPlayer.Character
    local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
    local targetRoot = target:FindFirstChild("HumanoidRootPart")
    if not playerRoot or not targetRoot then return end

    if bnnBringTarget ~= target then
        bnnBringTarget = target
        local spawnPart = DetectPartMobBring(target.Name, target, true)
        if not spawnPart then bnnBringTarget = nil return end
        bnnBringAnchor = spawnPart.CFrame
        local race = localPlayer:FindFirstChild("Data") and localPlayer.Data:FindFirstChild("Race")
        local transformed = character:FindFirstChild("RaceTransformed")
        if race and race.Value == "Cyborg" and transformed and transformed.Value then
            bnnBringAnchor = getcenter(target.Name) or bnnBringAnchor
        end
        DeleteIgnoredMob()
    end

    if getgenv().DaBringMob then
        task.delay(0.1, function() getgenv().DaBringMob = false end)
        return
    end

    local selected = {}
    if not target:FindFirstChild("Ignored") then table.insert(selected, target) end
    local requestedCount = tonumber(Settings["Bring Mob Count"]) or 2
    local radius, maximum = requestedCount > 2 and 350 or 200, requestedCount
    local race = localPlayer:FindFirstChild("Data") and localPlayer.Data:FindFirstChild("Race")
    local transformed = character:FindFirstChild("RaceTransformed")
    if race and race.Value == "Cyborg" and transformed and transformed.Value then radius, maximum = 300, 6 end

    local enemies = Workspace:FindFirstChild("Enemies")
    for _, mob in ipairs(enemies and enemies:GetChildren() or {}) do
        local root = mob:FindFirstChild("HumanoidRootPart")
        if mob ~= target and mob.Name == target.Name and not mob:FindFirstChild("Ignored")
            and IsMobAlive(mob) and isnetworkowner2(root)
            and (root.Position - bnnBringAnchor.Position).Magnitude <= radius and #selected < maximum
        then
            table.insert(selected, mob)
        end
    end

    if not bnnBringAnchor or (playerRoot.Position - targetRoot.Position).Magnitude > 50
        or not isnetworkowner2(playerRoot) or #selected < 2 then return end

    for _, mob in ipairs(selected) do
        local broughtMob = mob
        local root = broughtMob:FindFirstChild("HumanoidRootPart")
        local humanoid = broughtMob:FindFirstChildOfClass("Humanoid")
        if root and humanoid then
            SizePart(broughtMob)
            if not isnetworkowner2(root) then
                root.CFrame = broughtMob.WorldPivot
                if not broughtMob:FindFirstChild("Ignored") then Instance.new("IntValue", broughtMob).Name = "Ignored" end
                task.wait(0.3)
            else
                root.CFrame = bnnBringAnchor * CFrame.new(0, math.random(0, 2), math.random(0, 2))
                task.spawn(function()
                    local oldHealth = humanoid.Health
                    task.wait(2.2)
                    if broughtMob.Parent and humanoid.Health == oldHealth and not broughtMob:FindFirstChild("Ignored") then
                        root.CFrame = broughtMob.WorldPivot
                        Instance.new("IntValue", broughtMob).Name = "Ignored"
                        task.wait(0.3)
                    end
                end)
            end
            getgenv().DaBringMob = true
        end
    end
end

-- [[ ATTACK ENGINE - Replaced with FastAttack class (pastefy X6xLHpIv) ]]
-- loadstring FastMax helper
pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/AnhDzaiScript/Setting/refs/heads/main/FastMax.lua"))()
end)

local _AtkModules = ReplicatedStorage:WaitForChild("Modules")
local _AtkNet = _AtkModules:WaitForChild("Net")
local _RegisterAttack = _AtkNet:WaitForChild("RE/RegisterAttack")
local _RegisterHit    = _AtkNet:WaitForChild("RE/RegisterHit")
local _ShootGunEvent  = _AtkNet:WaitForChild("RE/ShootGunEvent")
local _GunValidator   = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Validator2")

local _AtkConfig = {
    AttackDistance  = 65,
    AttackMobs      = true,
    AttackPlayers   = true,
    AttackCooldown  = 0.2,
    ComboResetTime  = 0.3,
    MaxCombo        = 4,
    HitboxLimbs     = {"RightLowerArm", "RightUpperArm", "LeftLowerArm", "LeftUpperArm", "RightHand", "LeftHand"},
    AutoClickEnabled = true,
}

local FastAttackClass = {}
FastAttackClass.__index = FastAttackClass

function FastAttackClass.new()
    local self = setmetatable({
        Debounce        = 0,
        ComboDebounce   = 0,
        ShootDebounce   = 0,
        M1Combo         = 0,
        EnemyRootPart   = nil,
        Connections     = {},
        Overheat        = { Dragonstorm = { MaxOverheat = 3, Cooldown = 0, TotalOverheat = 0, Distance = 350, Shooting = false } },
        ShootsPerTarget = { ["Dual Flintlock"] = 2 },
        SpecialShoots   = { ["Skull Guitar"] = "TAP", ["Bazooka"] = "Position", ["Cannon"] = "Position", ["Dragonstorm"] = "Overheat" },
    }, FastAttackClass)

    pcall(function()
        self.CombatFlags  = require(_AtkModules.Flags).COMBAT_REMOTE_THREAD
        self.ShootFunction = getupvalue(require(ReplicatedStorage.Controllers.CombatController).Attack, 9)
        local LocalScript = localPlayer:WaitForChild("PlayerScripts"):FindFirstChildOfClass("LocalScript")
        if LocalScript and getsenv then
            self.HitFunction = getsenv(LocalScript)._G.SendHitsToServer
        end
    end)

    return self
end

function FastAttackClass:IsEntityAlive(entity)
    local humanoid = entity and entity:FindFirstChild("Humanoid")
    return humanoid and humanoid.Health > 0
end

function FastAttackClass:CheckStun(Character, Humanoid, ToolTip)
    local Stun = Character:FindFirstChild("Stun")
    local Busy = Character:FindFirstChild("Busy")
    if Humanoid.Sit and (ToolTip == "Sword" or ToolTip == "Melee" or ToolTip == "Blox Fruit") then
        return false
    elseif Stun and Stun.Value > 0 or Busy and Busy.Value then
        return false
    end
    return true
end

function FastAttackClass:GetBladeHits(Character, Distance)
    local Position = Character:GetPivot().Position
    local BladeHits = {}
    Distance = Distance or _AtkConfig.AttackDistance

    local function ProcessTargets(Folder)
        for _, Enemy in ipairs(Folder:GetChildren()) do
            if Enemy ~= Character and self:IsEntityAlive(Enemy) then
                local BasePart = Enemy:FindFirstChild(_AtkConfig.HitboxLimbs[math.random(#_AtkConfig.HitboxLimbs)])
                    or Enemy:FindFirstChild("HumanoidRootPart")
                if BasePart and (Position - BasePart.Position).Magnitude <= Distance then
                    if not self.EnemyRootPart then
                        self.EnemyRootPart = BasePart
                    else
                        table.insert(BladeHits, { Enemy, BasePart })
                    end
                end
            end
        end
    end

    if _AtkConfig.AttackMobs   then ProcessTargets(Workspace.Enemies) end
    if _AtkConfig.AttackPlayers then ProcessTargets(Workspace.Characters) end

    return BladeHits
end

function FastAttackClass:GetClosestEnemy(Character, Distance)
    local BladeHits = self:GetBladeHits(Character, Distance)
    local Closest, MinDistance = nil, math.huge
    for _, Hit in ipairs(BladeHits) do
        local Magnitude = (Character:GetPivot().Position - Hit[2].Position).Magnitude
        if Magnitude < MinDistance then
            MinDistance = Magnitude
            Closest = Hit[2]
        end
    end
    return Closest
end

function FastAttackClass:GetCombo()
    local Combo = (tick() - self.ComboDebounce) <= _AtkConfig.ComboResetTime and self.M1Combo or 0
    Combo = Combo >= _AtkConfig.MaxCombo and 1 or Combo + 1
    self.ComboDebounce = tick()
    self.M1Combo = Combo
    return Combo
end

function FastAttackClass:GetValidator2()
    local v1  = getupvalue(self.ShootFunction, 15)
    local v2  = getupvalue(self.ShootFunction, 13)
    local v3  = getupvalue(self.ShootFunction, 16)
    local v4  = getupvalue(self.ShootFunction, 17)
    local v5  = getupvalue(self.ShootFunction, 14)
    local v6  = getupvalue(self.ShootFunction, 12)
    local v7  = getupvalue(self.ShootFunction, 18)
    local v8  = v6 * v2
    local v9  = (v5 * v2 + v6 * v1) % v3
    v9 = (v9 * v3 + v8) % v4
    v5 = math.floor(v9 / v3)
    v6 = v9 - v5 * v3
    v7 = v7 + 1
    setupvalue(self.ShootFunction, 15, v1)
    setupvalue(self.ShootFunction, 13, v2)
    setupvalue(self.ShootFunction, 16, v3)
    setupvalue(self.ShootFunction, 17, v4)
    setupvalue(self.ShootFunction, 14, v5)
    setupvalue(self.ShootFunction, 12, v6)
    setupvalue(self.ShootFunction, 18, v7)
    return math.floor(v9 / v4 * 16777215), v7
end

function FastAttackClass:ShootInTarget(TargetPosition)
    local Character = localPlayer.Character
    if not self:IsEntityAlive(Character) then return end
    local Equipped = Character:FindFirstChildOfClass("Tool")
    if not Equipped or Equipped.ToolTip ~= "Gun" then return end
    local Cooldown = Equipped:FindFirstChild("Cooldown") and Equipped.Cooldown.Value or 0.3
    if (tick() - self.ShootDebounce) < Cooldown then return end
    local ShootType = self.SpecialShoots[Equipped.Name] or "Normal"
    if ShootType == "Position" or (ShootType == "TAP" and Equipped:FindFirstChild("RemoteEvent")) then
        Equipped:SetAttribute("LocalTotalShots", (Equipped:GetAttribute("LocalTotalShots") or 0) + 1)
        _GunValidator:FireServer(self:GetValidator2())
        if ShootType == "TAP" then
            Equipped.RemoteEvent:FireServer("TAP", TargetPosition)
        else
            _ShootGunEvent:FireServer(TargetPosition)
        end
        self.ShootDebounce = tick()
    else
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
        self.ShootDebounce = tick()
    end
end

function FastAttackClass:UseNormalClick(Character, Humanoid, Cooldown)
    self.EnemyRootPart = nil
    local BladeHits = self:GetBladeHits(Character)
    if self.EnemyRootPart then
        _RegisterAttack:FireServer(Cooldown)
        if self.CombatFlags and self.HitFunction then
            self.HitFunction(self.EnemyRootPart, BladeHits)
        else
            _RegisterHit:FireServer(self.EnemyRootPart, BladeHits)
        end
    end
end

function FastAttackClass:UseFruitM1(Character, Equipped, Combo)
    local Targets = self:GetBladeHits(Character)
    if not Targets[1] then return end
    local Direction = (Targets[1][2].Position - Character:GetPivot().Position).Unit
    Equipped.LeftClickRemote:FireServer(Direction, Combo)
end

function FastAttackClass:Attack()
    if not _AtkConfig.AutoClickEnabled or (tick() - self.Debounce) < _AtkConfig.AttackCooldown then return end
    local Character = localPlayer.Character
    if not Character or not self:IsEntityAlive(Character) then return end
    local Humanoid = Character.Humanoid
    local Equipped  = Character:FindFirstChildOfClass("Tool")
    if not Equipped then return end
    local ToolTip = Equipped.ToolTip
    if not table.find({"Melee", "Blox Fruit", "Sword", "Gun"}, ToolTip) then return end
    local Cooldown = Equipped:FindFirstChild("Cooldown") and Equipped.Cooldown.Value or _AtkConfig.AttackCooldown
    if not self:CheckStun(Character, Humanoid, ToolTip) then return end
    local Combo = self:GetCombo()
    Cooldown = Cooldown + (Combo >= _AtkConfig.MaxCombo and 0.05 or 0)
    self.Debounce = Combo >= _AtkConfig.MaxCombo and ToolTip ~= "Gun" and (tick() + 0.05) or tick()
    if ToolTip == "Blox Fruit" and Equipped:FindFirstChild("LeftClickRemote") then
        self:UseFruitM1(Character, Equipped, Combo)
    elseif ToolTip == "Gun" then
        local Target = self:GetClosestEnemy(Character, 120)
        if Target then self:ShootInTarget(Target.Position) end
    else
        self:UseNormalClick(Character, Humanoid, Cooldown)
    end
end

-- Tạo instance và kết nối Heartbeat
local _FastAttackInst = FastAttackClass.new()
table.insert(_FastAttackInst.Connections, RunService.Heartbeat:Connect(function()
    if Settings["Auto Click"] then
        _FastAttackInst:Attack()
    end
end))

-- === Wrapper functions giữ nguyên API cho phần còn lại của script ===

function AttackFunction(radius)
    -- Gọi attack class trực tiếp qua Heartbeat; fallback manual invoke nếu cần
    _FastAttackInst:Attack()
end

function AttackAOE(radius, includePlayers)
    local Character = localPlayer.Character
    if not Character then return nil end
    _FastAttackInst.EnemyRootPart = nil
    local hits = _FastAttackInst:GetBladeHits(Character, radius or 80)
    return #hits > 0 and hits or nil
end

function FastAttack(target)
    -- target hint: thu hẹp khoảng cách nếu cần, rồi gọi Attack
    _FastAttackInst:Attack()
end

local fastAttackInstance = { Attack = function() _FastAttackInst:Attack() end }

function ClickM1(target, wideRange)
    local character = localPlayer.Character
    local root      = character and character:FindFirstChild("HumanoidRootPart")
    local targetRoot = target and target:FindFirstChild("HumanoidRootPart")
    local humanoid  = target and target:FindFirstChildOfClass("Humanoid")
    if not root or not targetRoot or not humanoid or humanoid.Health <= 0
        or (root.Position - targetRoot.Position).Magnitude >= 70 then return end
    _FastAttackInst:Attack()
end
getgenv().ClickM1 = ClickM1

getgenv().ClickM1Dungeon = function(target, wideRange)
    local character = localPlayer.Character
    local root      = character and character:FindFirstChild("HumanoidRootPart")
    local targetRoot = target and target:FindFirstChild("HumanoidRootPart")
    local humanoid  = target and target:FindFirstChildOfClass("Humanoid")
    if not root or not targetRoot or not humanoid or humanoid.Health <= 0
        or (root.Position - targetRoot.Position).Magnitude >= 70 then return end
    _FastAttackInst:Attack()
end

getgenv().ClickM1Volcano = function(target, wideRange)
    local character = localPlayer.Character
    local root      = character and character:FindFirstChild("HumanoidRootPart")
    local targetRoot = target and target:FindFirstChild("HumanoidRootPart")
    local humanoid  = target and target:FindFirstChildOfClass("Humanoid")
    if not root or not targetRoot or not humanoid or humanoid.Health <= 0
        or (root.Position - targetRoot.Position).Magnitude >= 70 then return end
    _FastAttackInst:Attack()
end

getgenv().UseFruitM1 = function(target, secondaryDirection)
    local Character = localPlayer.Character
    if not Character then return false end
    local Equipped = Character:FindFirstChildOfClass("Tool")
    if not Equipped or Equipped.ToolTip ~= "Blox Fruit" then return false end
    if not Equipped:FindFirstChild("LeftClickRemote") then return false end
    _FastAttackInst:UseFruitM1(Character, Equipped, _FastAttackInst:GetCombo())
    return true
end
getgenv().UseFruitM1Boat = getgenv().UseFruitM1

getgenv().PathClickM1 = {}

getgenv().AttackFunctionnhungSuperTrial = function()
    _AtkConfig.AttackPlayers = true
    _FastAttackInst:Attack()
end
getgenv().AttackFunctionnhungSuper = getgenv().AttackFunctionnhungSuperTrial

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
                            BringMob(v)
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
local templeTeleportRetryRunning = false
local templeTeleportRetryState = "idle"
local templeTeleportRetryAttempts = 0

local function TryTeleportTempleOfTimeOnce()
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

    -- Kiểm tra trạng thái tiến trình RaceV4 giống như teleport temple gốc
    local v4Status
    pcall(function()
        v4Status = ReplicatedStorage.Remotes.CommF_:InvokeServer("RaceV4Progress", "Check")
    end)

    if v4Status == 1 then
        -- Bước 1: talk NPC Ancient One để Begin
        pcall(function()
            ReplicatedStorage.Remotes.CommF_:InvokeServer("RaceV4Progress", "Begin")
        end)
        return "in_progress"
    elseif v4Status == 2 then
        -- Bước 2: Cần di chuyển tới đỉnh cây rồi gọi Teleport + requestEntrance
        local distToTree = (hrp.Position - topOfGreatTree.Position).Magnitude
        if distToTree > 30 then
            ToTarget(topOfGreatTree)
            return "moving_to_tree"
        end
        -- Đã ở đỉnh cây: gọi Teleport rồi requestEntrance (đúng sequence game gốc)
        pcall(function()
            ReplicatedStorage.Remotes.CommF_:InvokeServer("RaceV4Progress", "Teleport")
        end)
        task.wait(0.3)
        pcall(function()
            ReplicatedStorage.Remotes.CommF_:InvokeServer("requestEntrance", TEMPLE_ENTRY_POS)
        end)
        if IsInTempleOfTime() then return "arrived" end
        return "in_progress"
    elseif v4Status == 3 then
        -- Bước 3: talk NPC Continue sau khi hoàn thành nhiệm vụ trong temple
        pcall(function()
            ReplicatedStorage.Remotes.CommF_:InvokeServer("RaceV4Progress", "Continue")
        end)
        task.wait(0.3)
        pcall(function()
            ReplicatedStorage.Remotes.CommF_:InvokeServer("requestEntrance", TEMPLE_ENTRY_POS)
        end)
        if IsInTempleOfTime() then return "arrived" end
        return "in_progress"
    else
        -- Không có v4Status rõ ràng: thử requestEntrance trực tiếp
        pcall(function()
            ReplicatedStorage.Remotes.CommF_:InvokeServer("requestEntrance", TEMPLE_ENTRY_POS)
        end)
        if IsInTempleOfTime() then return "arrived" end

        -- Fallback: di chuyển về đỉnh cây rồi thử Teleport
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
    end

    local currentRaceState = CheckRace()
    if currentRaceState == " V1" or currentRaceState == " V2" then
        return "locked"
    end

    return "in_progress"
end

local function SafeTryTeleportTempleOfTimeOnce()
    templeTeleportRetryAttempts = templeTeleportRetryAttempts + 1
    local ok, state = pcall(TryTeleportTempleOfTimeOnce)

    if not ok then
        local attemptError = state
        state = "retry_error"
        warn("[Temple Retry] Attempt failed: " .. tostring(attemptError))
    elseif type(state) ~= "string" then
        state = "in_progress"
    end

    getgenv().TempleTeleportStatus = {
        Running = templeTeleportRetryRunning,
        State = state,
        Attempts = templeTeleportRetryAttempts,
        UpdatedAt = tick(),
    }
    return state
end

function TeleportTempleOfTime()
    if IsInTempleOfTime() then
        templeTeleportRetryState = "arrived"
        return "arrived"
    end

    -- Tất cả nơi gọi dùng chung một worker để không tạo nhiều luồng InvokeServer
    -- chồng lên nhau. Lượt đầu chạy ngay, các lượt sau cách nhau đúng 1 giây.
    if templeTeleportRetryRunning then
        return templeTeleportRetryState
    end

    templeTeleportRetryRunning = true
    templeTeleportRetryState = SafeTryTeleportTempleOfTimeOnce()

    if templeTeleportRetryState == "wrong_sea" then
        templeTeleportRetryRunning = false
        return templeTeleportRetryState
    end

    task.spawn(function()
        local workerOk, workerError = pcall(function()
            while not IsInTempleOfTime() do
                task.wait(1)
                if IsInTempleOfTime() then break end

                templeTeleportRetryState = SafeTryTeleportTempleOfTimeOnce()
                if templeTeleportRetryState == "wrong_sea" then
                    break
                end
            end
        end)

        if not workerOk then
            templeTeleportRetryState = "retry_error"
            warn("[Temple Retry] Worker recovered: " .. tostring(workerError))
        end

        if IsInTempleOfTime() then
            templeTeleportRetryState = "arrived"
        end
        templeTeleportRetryRunning = false
        if type(getgenv().TempleTeleportStatus) == "table" then
            getgenv().TempleTeleportStatus.Running = false
            getgenv().TempleTeleportStatus.State = templeTeleportRetryState
            getgenv().TempleTeleportStatus.UpdatedAt = tick()
        end
    end)

    return templeTeleportRetryState
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

function DetectPartSpawnMob(name, skipIgnored)
    local function clean(value)
        return value:gsub(" %p?Lv%.? %d+%p?", "")
    end
    local cleanName = string.find(name, "Lv.") and clean(name) or name
    BnnRefreshMobSpawns()
    for _, part in ipairs(TableMobSpawn) do
        if part:IsA("Part") then
            local partName = string.find(part.Name, "Lv.") and clean(part.Name) or part.Name
            if (partName == name or partName == cleanName) and (not skipIgnored or not part:FindFirstChild("Ignored")) then
                return part
            end
        end
    end
    local origin = Workspace:FindFirstChild("_WorldOrigin")
    local enemySpawns = origin and origin:FindFirstChild("EnemySpawns")
    for _, part in ipairs(enemySpawns and enemySpawns:GetChildren() or {}) do
        if part:IsA("Part") then
            local partName = string.find(part.Name, "Lv.") and clean(part.Name) or part.Name
            if (partName == name or partName == cleanName) and (not skipIgnored or not part:FindFirstChild("Ignored")) then
                BnnAddMobSpawn(part)
                return part
            end
        end
    end
    if getnilinstances then
        for _, part in ipairs(getnilinstances()) do
            if part:IsA("Part") then
                local partName = string.find(part.Name, "Lv.") and clean(part.Name) or part.Name
                if (partName == name or partName == cleanName) and (not skipIgnored or not part:FindFirstChild("Ignored")) then
                    BnnAddMobSpawn(part)
                    return part
                end
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
    for _, part in ipairs(TableMobSpawn) do
        local ignored = part:FindFirstChild("Ignored")
        if ignored then ignored:Destroy() end
    end
end

function IsMobAlive(mob)
    return mob and mob.Parent and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 and mob:FindFirstChild("HumanoidRootPart")
end

function SizePart(mob)
    getgenv().AttackingMob = mob
    local root = mob and mob.Parent and mob:FindFirstChild("HumanoidRootPart")
    if not root or localPlayer:DistanceFromCharacter(root.Position) > 50 then return end
    for _, part in ipairs(mob:GetDescendants()) do
        if (part:IsA("Part") or part:IsA("MeshPart")) and part.CanCollide then
            part.CanCollide = false
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
    local weaponName = NameWeapon(Settings["Select Weapon"] or "Melee")
    local character = localPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local tool = weaponName and localPlayer.Backpack:FindFirstChild(weaponName)
    if tool and humanoid and not humanoid.Sit then
        humanoid:EquipTool(tool)
    end
end

-- Exact BNN-style Buso detection; kept separate from UsedualFlock.
function FFCMatch(model, pattern)
    if not model then return nil end
    for _, child in pairs(model:GetChildren()) do
        if string.match(child.Name, pattern) then
            return child
        end
    end
    return nil
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

local bnnRaceStatusCache, bnnRaceStatusCheckedAt = nil, 0

local function BnnReadAncientOneStatus()
    local character = localPlayer.Character
    if not character or not character:FindFirstChild("RaceTransformed") then
        return "You have yet to achieve greatness"
    end
    local code, progress, fragments = ReplicatedStorage.Remotes.CommF_:InvokeServer("UpgradeRace", "Check")
    if code == 1 or code == 3 then
        return "Required Train More"
    elseif code == 2 or code == 4 or code == 7 then
        return "Can Buy Gear With " .. tostring(fragments) .. " Fragments"
    elseif code == 5 then
        return "You Are Done Your Race."
    elseif code == 6 then
        return "Upgrades completed: " .. tostring((progress or 2) - 2) .. "/3, Need Trains More"
    elseif code == 0 then
        return "Ready For Trial"
    elseif code == 8 then
        return "Remaining " .. tostring(10 - (progress or 0)) .. " training sessions."
    end
    return "You have yet to achieve greatness"
end

function CheckAcientOneStatus()
    if bnnRaceStatusCache and tick() - bnnRaceStatusCheckedAt < 1 then return bnnRaceStatusCache end
    bnnRaceStatusCache = BnnReadAncientOneStatus()
    bnnRaceStatusCheckedAt = tick()
    return bnnRaceStatusCache
end

function ResetRaceStatus()
    bnnRaceStatusCache = nil
end

function TurnOnV4()
    local character = localPlayer.Character
    local energy = character and character:FindFirstChild("RaceEnergy")
    local transformed = character and character:FindFirstChild("RaceTransformed")
    if not energy or energy.Value < 1 or not transformed or transformed.Value then return end
    local awakening = localPlayer.Backpack:FindFirstChild("Awakening") or character:FindFirstChild("Awakening")
    if awakening and awakening:FindFirstChild("RemoteFunction") then
        awakening.RemoteFunction:InvokeServer(true)
    end
end

function CheckGoTrain()
    local status = CheckAcientOneStatus()
    if string.find(status, "Upgrades completed")
        or status == "Required Train More"
        or string.find(status, "training sessions.")
        or string.find(status, "Can Buy Gear")
    then
        return true
    end
end

function DetectGearUp(data)
    local ok, buttons = pcall(function()
        return require(localPlayer.PlayerGui.TempleGui.LocalScriptTemple.Buttons)
    end)
    if not ok or type(buttons) ~= "table" then return nil end

    data = data or ReplicatedStorage.Remotes.CommF_:InvokeServer("TempleClock", "Check")
    if type(data) ~= "table" or type(data.RaceDetails) ~= "table" then return nil end

    local details = data.RaceDetails
    local gears = details.Gears or {}
    local totalAB = (details.A or 0) + (details.B or 0)
    local hasPoint = data.HadPoint == true
    local raceLevelReady = (data.RaceLevel or 0) >= 2

    buttons.Gear1.GearType = "Default"
    buttons.Gear4.GearType = "Default"
    buttons.Gear5.GearType = "Default"
    buttons.Gear2.GearType = gears[1] == "A" and "Alpha" or gears[1] == "B" and "Omega" or "Blank"
    buttons.Gear3.GearType = gears[2] == "A" and "Alpha" or gears[2] == "B" and "Omega" or "Blank"
    buttons.Gear4.GearType = gears[3] == "A" and "Alpha" or gears[3] == "B" and "Omega" or "Blank"
    buttons.Gear2.CanSelect = false
    buttons.Gear3.CanSelect = false
    buttons.Gear2.Unlocked = totalAB >= 0 and raceLevelReady or false
    buttons.Gear3.Unlocked = totalAB >= 1 and raceLevelReady or false
    buttons.Gear4.Unlocked = totalAB >= 2 and raceLevelReady or false
    buttons.Gear5.CanSelect = false
    buttons.Gear5.Unlocked = (details.C or 0) >= 1
    buttons.Gear1.Unlocked = true

    if not raceLevelReady then
        buttons.Gear1.CanSelect = true
        buttons.Gear1.GearType = "Blank"
        hasPoint = true
    else
        buttons.Gear1.CanSelect = false
        buttons.Gear1.GearType = "Default"
    end

    if not hasPoint then
        buttons.Gear2.CanSelect = false
        buttons.Gear3.CanSelect = false
        buttons.Gear4.CanSelect = false
    else
        buttons.Gear2.CanSelect = totalAB == 0 and raceLevelReady or false
        buttons.Gear3.CanSelect = totalAB == 1 and raceLevelReady or false
        buttons.Gear4.CanSelect = totalAB >= 2 and raceLevelReady or false
        if totalAB >= 3 then
            buttons.Gear2.CanSelect = true
            buttons.Gear3.CanSelect = true
            buttons.Gear4.CanSelect = true
            local g2, g3, g4 = buttons.Gear2.GearType, buttons.Gear3.GearType, buttons.Gear4.GearType
            if (g2 == "Alpha" and g3 == "Alpha" and g4 == "Omega")
                or (g2 == "Omega" and g3 == "Omega" and g4 == "Alpha") then
                buttons.Gear4.CanSelect = false
            elseif (g2 == "Alpha" and g3 == "Omega" and g4 == "Omega")
                or (g2 == "Omega" and g3 == "Alpha" and g4 == "Alpha") then
                buttons.Gear4.CanSelect = false
                buttons.Gear2.CanSelect = false
            elseif (g2 == "Omega" and g3 == "Alpha" and g4 == "Omega")
                or (g2 == "Alpha" and g3 == "Omega" and g4 == "Alpha") then
                buttons.Gear4.CanSelect = false
                buttons.Gear3.CanSelect = false
            end
        end
    end

    for index = 1, 5 do
        local gear = buttons["Gear" .. index]
        if gear and gear.CanSelect then return "Gear" .. index end
    end
    return nil
end

function ChooseGearV4()
    local data = ReplicatedStorage.Remotes.CommF_:InvokeServer("TempleClock", "Check")
    if type(data) ~= "table" or not data.HadPoint then return end
    local gear = DetectGearUp(data)
    if not gear then return end
    local gearType = Settings["Select Gear V4"] == "Alpha" and "Alpha" or "Omega"
    ReplicatedStorage.Remotes.CommF_:InvokeServer("TempleClock", "SpendPoint", gear, gearType)
    local refreshed = ReplicatedStorage.Remotes.CommF_:InvokeServer("TempleClock", "Check")
    if refreshed and refreshed.HadPoint and DetectGearUp(refreshed) == gear then
        ReplicatedStorage.Remotes.CommF_:InvokeServer(
            "TempleClock",
            "SpendPoint",
            gear,
            gearType == "Alpha" and "Omega" or "Alpha"
        )
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
        ["http://www.roblox.com/asset/?id=9709149052"] = "Next Night",
        ["http://www.roblox.com/asset/?id=9709143733"] = "6/8",
        ["http://www.roblox.com/asset/?id=9709150401"] = "5/8",
        ["http://www.roblox.com/asset/?id=9709135895"] = "4/8",
        ["http://www.roblox.com/asset/?id=9709150086"] = "2/8",
        ["http://www.roblox.com/asset/?id=9709139597"] = "1/8",
        ["http://www.roblox.com/asset/?id=9709149680"] = "0/8",
    }
    if moonMap[t] then return moonMap[t] end
    if Lighting:GetAttribute("MoonPhase") == 5 then return "Full Moon" end
    return "Bad Moon"
end

function CheckClockTime()
    local ct = Lighting.ClockTime
    if ct >= 18 or ct < 5 then
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
	if string.find(CheckAcientOneStatus(), "Can Buy Gear") then
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
	if not GetHighestPoint() then
		local dealer = DetectNpc("Advanced Fruit Dealer")
		if dealer then
			ToTarget(dealer.HumanoidRootPart.CFrame)
			return
		end
	end
	local gear = GetBlueGear()
	if gear and not gear.CanCollide and gear.Transparency ~= 1 then
		local root = localPlayer.Character.HumanoidRootPart
		if root:FindFirstChild("Agility") then root.Agility:Destroy() end
		ToTarget(GetBlueGear().CFrame)
	elseif gear and gear.Transparency == 1 then
		local highest = GetHighestPoint()
		local target = highest and highest.CFrame * CFrame.new(0, 211.88, 0)
		if target and (target.Position - localPlayer.Character.HumanoidRootPart.Position).Magnitude > 10 then
			ToTarget(target)
		else
			localPlayer.CameraMode = "LockFirstPerson"
			localPlayer.CameraMode = "Classic"
			local started = tick()
			repeat
				task.wait()
				Workspace.CurrentCamera.CFrame = CFrame.new(
					Workspace.CurrentCamera.CFrame.Position,
					Lighting:GetMoonDirection() + Workspace.CurrentCamera.CFrame.Position
				)
			until tick() - started >= 3
			VirtualInputManager:SendKeyEvent(true, "T", false, game)
			task.wait(0.5)
			VirtualInputManager:SendKeyEvent(false, "T", false, game)
			local root = localPlayer.Character.HumanoidRootPart
			if not CheckAbility() and not root:FindFirstChild("Agility") then
				local fx = ReplicatedStorage.FX.Agility:Clone()
				fx.Parent = root
				fx.Enabled = false
			end
			task.wait(1.5)
		end
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

local function PullLeverV4Legacy()
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

function PullLeverV4()
	if not CheckItemInventory("Valkyrie Helm") or not CheckItemInventory("Mirror Fractal") then
		uiLibrary.CreateNoti({ Title = "Skider Hub V4", Desc = "Not Valkyrie Helm or not Mirror Fractal", ShowTime = 5 })
		task.wait(5)
		return
	end

	local doorUnlocked = ReplicatedStorage.Remotes.CommF_:InvokeServer("CheckTempleDoor")
	if not doorUnlocked then
		local progress = ReplicatedStorage.Remotes.CommF_:InvokeServer("RaceV4Progress", "Check")
		if progress == 1 then
			ReplicatedStorage.Remotes.CommF_:InvokeServer("RaceV4Progress", "Begin")
			return
		elseif progress == 2 then
			-- Exception requested by the user: retain the original Fluent Temple teleport engine.
			TeleportTempleOfTime()
			return
		elseif progress == 3 then
			ReplicatedStorage.Remotes.CommF_:InvokeServer("RaceV4Progress", "Continue")
			return
		end

		local mysticIsland = Workspace.Map:FindFirstChild("MysticIsland")
		if mysticIsland and CheckClockTime() == "Night" then
			CollectBlueGear()
		elseif mysticIsland and CheckClockTime() ~= "Night" then
			if not GetHighestPoint() then
				local dealer = DetectNpc("Advanced Fruit Dealer")
				if dealer then
					ToTarget(dealer.HumanoidRootPart.CFrame)
					return
				end
			end
			local highest = GetHighestPoint()
			local target = highest and highest.CFrame * CFrame.new(0, 211.88, 0)
			if target and (target.Position - localPlayer.Character.HumanoidRootPart.Position).Magnitude > 10 then
				ToTarget(target)
			end
		elseif not mysticIsland and Settings["Hop Server [Trial Or Pull Lever]"] then
			SpecialHop("Mirage")
		end
	else
		local temple = GetTempleOfTime()
		if not IsInTempleOfTime() then
			TeleportTempleOfTime()
			return
		end
		if not temple or not temple:FindFirstChild("Lever") then return end
		local lever = temple.Lever
		if lever.Lever.CFrame.Z > leverTargetCFrame.Z + count12 or lever.Lever.CFrame.Z < leverTargetCFrame.Z - count12 then
			if (localPlayer.Character.HumanoidRootPart.Position - lever.Part.Position).Magnitude > 10 then
				ToTarget(lever.Part.CFrame)
			else
				fireproximityprompt(lever.Prompt.ProximityPrompt, 1)
			end
		else
			uiLibrary.CreateNoti({ Title = "Skider Hub V4", Desc = "Done Pull Lever", ShowTime = 5 })
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
    -- Helper được xác định duy nhất từ danh sách TurnV3/Multi Trial.
    refreshTurnV3Roles()
    local myName = localPlayer.Name
    local myDisplay = localPlayer.DisplayName
    return isAlly == true or HelpWhitelist[myName] == true or HelpWhitelist[myDisplay] == true
end

do
    -- Giữ nguyên bộ điều phối từ backup, chỉ lấy số giây từ config OneClick/Main.
    local V3_COUNTDOWN      = math.max(1, tonumber(Settings["V3 Countdown"]) or 4)
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
                        if isAlly then
                            pcall(function() LocalPlayer.Character.Humanoid.Health = 0 end)
                        end
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
	-- Bỏ check FishmanTrial map node (quá strict, không cần thiết)
	-- Chỉ cần SeaBeast ở gần Trial of Water location
	local part2 = Workspace._WorldOrigin
		and Workspace._WorldOrigin.Locations
		and Workspace._WorldOrigin.Locations:FindFirstChild("Trial of Water")
	local seaBeasts = Workspace:FindFirstChild("SeaBeasts")
	if not part2 or not seaBeasts then return nil end
	for _, value7 in ipairs(seaBeasts:GetChildren()) do
		if string.find(value7.Name, "SeaBeast")
			and value7:FindFirstChild("HumanoidRootPart")
			and (value7.HumanoidRootPart.Position - part2.Position).Magnitude <= 1500
		then
			if value7:FindFirstChild("Health") and value7.Health.Value > 0 then
				return value7
			end
		end
	end
	return nil
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

function DetectPlayerKillName()
	local names = {}
	local characters = Workspace:FindFirstChild("Characters")
	for _, character in ipairs(characters and characters:GetChildren() or {}) do
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local root = character:FindFirstChild("HumanoidRootPart")
		if character:IsA("Model")
			and character.Name ~= localPlayer.Name
			and humanoid and humanoid.Health > 0
			and root
			and (root.Position - Vector3.new(28718.068359375, 14887.5625, -60.5482177734375)).Magnitude <= 400
		then
			table.insert(names, character.Name)
		end
	end
	return names
end

function NameAttackTrial()
	for index, name in pairs(getgenv().PlayerKillTrial or {}) do
		if not table.find(getgenv().BlackListPlayerTrial or {}, name) then return name, index end
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


-- Trial V4 engine upgraded from bnn.lua.
-- IMPORTANT: the original Fluent Temple teleport function and its flow are retained.
local function TrialTimerVisible()
	local gui = localPlayer:FindFirstChild("PlayerGui")
	local main = gui and gui:FindFirstChild("Main")
	local top = main and main:FindFirstChild("TopHUDList")
	local timer = top and top:FindFirstChild("RaidTimer")
	return timer and timer.Visible == true or false
end

local function TrialCharacterReady()
	local character = localPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return character, humanoid, root
end

local function TrialDistance(position)
	local _, _, root = TrialCharacterReady()
	return root and (root.Position - position).Magnitude or math.huge
end

local function TrialForcefield(temple)
	local border = temple and temple:FindFirstChild("FFABorder")
	return border and border:FindFirstChild("Forcefield")
end

local function StopTrialTween()
	if TweenManager and TweenManager.CancelCurrent then TweenManager.CancelCurrent() end
end

local function TrialMobAlive(mob)
	return mob and mob.Parent and mob:FindFirstChild("HumanoidRootPart") and IsMobAlive(mob)
end

local function AttackTrialMob(mob, trialLocation)
	while TrialMobAlive(mob) and TrialTimerVisible() and TrialDistance(trialLocation.Position) <= 1000 do
		task.wait()
		EquipTool(NameWeapon(Settings["Select Weapon"] or "Melee"))
		SizePart(mob)
		local offset = Settings["Select Weapon"] == "Blox Fruit" and CFrame.new(-7, 20, 0) or CFrame.new(7, 20, 0)
		ToTarget(mob.HumanoidRootPart.CFrame * offset)
		ClickM1(mob)
		UsedualFlock()
	end
end

local function RunHumanTrial()
	local locations = Workspace:FindFirstChild("_WorldOrigin") and Workspace._WorldOrigin:FindFirstChild("Locations")
	local trial = locations and locations:FindFirstChild("Trial of Strength")
	if not trial then return end
	while TrialTimerVisible() and TrialDistance(trial.Position) <= 1000 do
		local mob = TrialHuman()
		if mob then AttackTrialMob(mob, trial) else task.wait(0.1) end
	end
end

local function RunGhoulTrial()
	local locations = Workspace:FindFirstChild("_WorldOrigin") and Workspace._WorldOrigin:FindFirstChild("Locations")
	local trial = locations and locations:FindFirstChild("Trial of Carnage")
	if not trial then return end
	while TrialTimerVisible() and TrialDistance(trial.Position) <= 1000 do
		local mob = TrialGhoul()
		if mob then AttackTrialMob(mob, trial) else task.wait(0.1) end
	end
end

local function RunSkypieaTrial()
	local locations = Workspace:FindFirstChild("_WorldOrigin") and Workspace._WorldOrigin:FindFirstChild("Locations")
	local trial = locations and locations:FindFirstChild("Trial of the King")
	while TrialTimerVisible() and trial and TrialDistance(trial.Position) <= 1000 do
		task.wait()
		local skyTrial = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("SkyTrial")
		local model = skyTrial and skyTrial:FindFirstChild("Model")
		local finish = model and model:FindFirstChild("FinishPart")
		if finish then ToTarget(finish.CFrame) else task.wait(0.2) end
	end
end

-- SKILL SPAM WORKER (port t\u1eeb piggyv4) - b\u1eadt/t\u1eaft qua _G.SHOULDSPAMSKILLS
local _piggyValidTooltip = { Melee=true, ["Blox Fruit"]=true, Sword=true, Gun=true }
local _piggyValidKey     = { Z=true, X=true, C=true, V=true, F=true }
local _piggyFruits = {
	["Buddha-Buddha"]=true,["T-Rex-T-Rex"]=true,["Dragon-Dragon"]=true,
	["Yeti-Yeti"]=true,["Leopard-Leopard"]=true,["Venom-Venom"]=true,
	["Phoenix-Phoenix"]=true,["Kitsune-Kitsune"]=true,["Mammoth-Mammoth"]=true,
	["Gas-Gas"]=true,["Portal-Portal"]=true,
}
local function _piggyGetWeapons()
	local t = {}
	for _, v in ipairs(localPlayer.Backpack:GetChildren()) do
		if v:IsA("Tool") and _piggyValidTooltip[v.ToolTip] then table.insert(t, v) end
	end
	if localPlayer.Character then
		for _, v in ipairs(localPlayer.Character:GetChildren()) do
			if v:IsA("Tool") and _piggyValidTooltip[v.ToolTip] then table.insert(t, v) end
		end
	end
	return t
end
_G.SHOULDSPAMSKILLS = false
task.spawn(function()
	while task.wait(0.05) do
		if not _G.SHOULDSPAMSKILLS then continue end
		local skillsUI = localPlayer.PlayerGui
			and localPlayer.PlayerGui:FindFirstChild("Main")
			and localPlayer.PlayerGui.Main:FindFirstChild("Skills")
		if not skillsUI then continue end
		local weapons = _piggyGetWeapons()
		for _, v in ipairs(weapons) do
			if not skillsUI:FindFirstChild(v.Name) then pcall(EquipTool, v.Name) end
		end
		for _, v in ipairs(weapons) do
			if not _G.SHOULDSPAMSKILLS then break end
			if localPlayer.Character and not localPlayer.Character:FindFirstChild(v.Name) then
				pcall(EquipTool, v.Name)
			end
			local ui = skillsUI:FindFirstChild(v.Name)
			if not ui then continue end
			for _, slot in ipairs(ui:GetChildren()) do
				if not _piggyValidKey[slot.Name] then continue end
				local cd    = slot:FindFirstChild("Cooldown")
				local title = slot:FindFirstChild("Title")
				if not cd or not title then continue end
				if title.TextColor3 ~= Color3.new(1,1,1) then continue end
				if cd.Size ~= UDim2.new(0,0,1,-1) then continue end
				if slot.Name == "V" and _piggyFruits[ui.Name] then continue end
				VirtualInputManager:SendKeyEvent(true,  slot.Name, false, game)
				task.wait(0.05)
				VirtualInputManager:SendKeyEvent(false, slot.Name, false, game)
				task.wait(0.5)
			end
		end
	end
end)

local function RunFishmanTrial()
	local locations = Workspace:FindFirstChild("_WorldOrigin") and Workspace._WorldOrigin:FindFirstChild("Locations")
	local trial = locations and locations:FindFirstChild("Trial of Water")
	if not trial then return end

	-- HideUI-safe: fallback check b\u1eb1ng distance n\u1ebfu kh\u00f4ng t\u00ecm \u0111\u01b0\u1ee3c UI timer
	local function isTimerActive()
		local gui  = localPlayer:FindFirstChild("PlayerGui")
		local main = gui and gui:FindFirstChild("Main")
		local top  = main and (main:FindFirstChild("TopHUDList") or main:FindFirstChild("Timer"))
		if top then
			local raidTimer = top:FindFirstChild("RaidTimer") or top:FindFirstChild("Timer")
			if raidTimer then return raidTimer.Visible == true end
		end
		-- Fallback: c\u00f2n trong v\u00f9ng trial
		local hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
		return hrp and (hrp.Position - trial.Position).Magnitude <= 1500 or false
	end

	local seaBeast = GetSeaBeastTrial()
	repeat
		task.wait()
		if seaBeast and IsMobAlive(seaBeast) then
			TeleportSeabeast2(seaBeast)
			ClickM1(seaBeast)
			_G.SHOULDSPAMSKILLS = true
		else
			_G.SHOULDSPAMSKILLS = false
			seaBeast = GetSeaBeastTrial()
		end
	until not isTimerActive()

	_G.SHOULDSPAMSKILLS = false
end

local function ResolveMinkTrialGoal()
	local map = Workspace:FindFirstChild("Map")
	local minkTrial = map and map:FindFirstChild("MinkTrial")

	-- Newer maps expose the winning marker directly. Prefer it over StartPoint,
	-- because StartPoint is the blue spawn pad shown in the reported failure.
	local goalNames = { "RedPoint", "Red Point", "FinishPart", "Finish", "EndPoint", "Goal" }
	for _, goalName in ipairs(goalNames) do
		local goal = minkTrial and minkTrial:FindFirstChild(goalName, true)
		if not goal and (goalName == "RedPoint" or goalName == "Red Point") then
			goal = Workspace:FindFirstChild(goalName, true)
		end
		if goal then
			if goal:IsA("BasePart") then
				return goal.CFrame * CFrame.new(0, 2, 0), goal
			elseif goal:IsA("Attachment") then
				return goal.WorldCFrame * CFrame.new(0, 2, 0), goal.Parent
			elseif goal:IsA("Model") then
				return goal:GetPivot() * CFrame.new(0, 2, 0), goal.PrimaryPart
			end
		end
	end

	-- Proven fallback used by the piggyv4 Mink trial implementation: moving below
	-- MinkTrial.Ceiling reaches the red winning side without returning to spawn.
	local ceiling = minkTrial and minkTrial:FindFirstChild("Ceiling", true)
	if ceiling then
		if ceiling:IsA("BasePart") then
			return ceiling.CFrame * CFrame.new(0, -20, 0), nil
		elseif ceiling:IsA("Model") then
			return ceiling:GetPivot() * CFrame.new(0, -20, 0), nil
		end
	end

	return nil, nil
end

local function RunMinkTrial()
	local locations = Workspace:FindFirstChild("_WorldOrigin") and Workspace._WorldOrigin:FindFirstChild("Locations")
	local trial = locations and locations:FindFirstChild("Trial of Speed")
	if not trial then return end

	while TrialTimerVisible() and TrialDistance(trial.Position) <= 1000 do
		local goalCFrame, touchPart = ResolveMinkTrialGoal()
		if not goalCFrame then
			task.wait(0.2)
			continue
		end

		local distance = TrialDistance(goalCFrame.Position)
		if distance > 8 then
			-- Start one complete tween and let it advance. The old loop restarted
			-- ToTarget every frame, continuously cancelling its own tween.
			ToTarget(goalCFrame)
			local travelStarted = tick()
			local travelTimeout = math.max(2, distance / TWEEN_SPEED + 2)
			repeat
				task.wait(0.1)
			until not TrialTimerVisible()
				or TrialDistance(trial.Position) > 1000
				or TrialDistance(goalCFrame.Position) <= 8
				or tick() - travelStarted >= travelTimeout
		else
			local _, humanoid, root = TrialCharacterReady()
			if root and humanoid and humanoid.Health > 0 then
				root.CFrame = goalCFrame
				if touchPart and touchPart:IsA("BasePart") and firetouchinterest then
					pcall(function()
						firetouchinterest(root, touchPart, 0)
						task.wait()
						firetouchinterest(root, touchPart, 1)
					end)
				end
			end
			task.wait(0.15)
		end
	end
end

local function RunCyborgTrial()
	-- Keep the original Fluent Cyborg trial destination; do not import bnn's Temple jump.
	while TrialTimerVisible() do
		task.wait()
		ToTarget(CFrame.new(28282.5703125, 14896.8505859375, 105.1042709350586))
	end
end

function AutoTrialV4()
	if Settings["Auto Finish Train Quest"] and Settings["Stack Train With Trial Race"] and CheckGoTrain() then
		return
	end

	local clockTime = Lighting.ClockTime
	local moon = CheckMoon()
	if (moon == "Full Moon" and not (clockTime > 5 and clockTime < 12) or moon == "Next Night")
		and Settings["Hop Server [Trial Or Pull Lever]"]
	then
		if getgenv().TurnOffHOPSVPullAndTrial then
			local toggle = getgenv().TurnOffHOPSVPullAndTrial
			if toggle.SetValue then toggle:SetValue(false) elseif toggle.SetStage then toggle:SetStage(false) end
		end
		task.wait(3)
	elseif Settings["Hop Server [Trial Or Pull Lever]"] then
		if not ((myTrialCompleted or postTrialHopDone) and Settings["Hop After Trial"] == false) then
			HopServer()
			return
		end
	end

	-- Preserve the original kaiv4_fluent Temple entry process exactly.
	if not IsInTempleOfTime() and not VerifyNearbyTrial() then
		myTrialCompleted = false
		trialInProgress = false
		if TeleportTempleOfTime() == "locked" then
			uiLibrary.CreateNoti({ Title = "Skider Hub V4", Desc = "Temple of Time is locked", ShowTime = 5 })
			task.wait(5)
		end
		return
	end

	local temple = GetTempleOfTime()
	local forcefield = TrialForcefield(temple)
	local ffaActive = forcefield and forcefield.Transparency == 0 and not isInsideOwnTrial()
	if ffaActive then
		StopTrialTween()
		return
	end

	if (forcefield and forcefield.Transparency == 1) or VerifyNearbyTrial() then
		if TrialTimerVisible() then
			if VerifyNearbyTrial() and not getgenv().VerifyTrial then getgenv().VerifyTrial = true end
			repeat task.wait() until VerifyNearbyTrial() or not TrialTimerVisible()
			if not TrialTimerVisible() then return end

			local data = localPlayer:FindFirstChild("Data")
			local race = data and data:FindFirstChild("Race") and data.Race.Value
			if race == "Human" then
				RunHumanTrial()
			elseif race == "Skypiea" then
				RunSkypieaTrial()
			elseif race == "Fishman" then
				RunFishmanTrial()
			elseif race == "Mink" then
				RunMinkTrial()
			elseif race == "Ghoul" then
				RunGhoulTrial()
			elseif race == "Cyborg" then
				RunCyborgTrial()
			end
			StopTrialTween()
		else
			if not temple then return end
			local data = localPlayer:FindFirstChild("Data")
			local race = data and data:FindFirstChild("Race") and data.Race.Value
			local corridor = race and temple:FindFirstChild(race .. "Corridor")
			local door = corridor and corridor:FindFirstChild("Door")
			local innerDoor = door and door:FindFirstChild("Door")
			local rightDoor = innerDoor and innerDoor:FindFirstChild("RightDoor")
			local union = rightDoor and rightDoor:FindFirstChild("Union")
			if not union then return end

			if TrialDistance(union.Position) > 8 then ToTarget(union.CFrame) end
			-- AutoTrial only positions the account. The kaiv4mix TurnV3 coordinator
			-- exclusively decides readiness, countdown and the shared activation time.
		end
	elseif getgenv().VerifyTrial then
		if not Settings["Multi Trial"] and not isHelperAccount() then
			Settings["Auto Trial"] = false
			if ToggleAutoTrial then
				if ToggleAutoTrial.SetValue then ToggleAutoTrial:SetValue(false) elseif ToggleAutoTrial.SetStage then ToggleAutoTrial:SetStage(false) end
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
-- HideUI mode: toàn bộ block này bị bỏ qua, chỉ chạy automation worker
--------------------------------------------------------------------------------
if not _HIDE_UI then

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
    Title = "Auto Pull Lever",
    Default = Settings["Auto Pull Lever"] or Settings["Auto Pull Lever V4"] or false,
    Callback = function(enabled)
        SaveSettings("Auto Pull Lever", enabled)
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
        { key = "Auto Upgrade Race V2-V3", default = false },
        { key = "Auto Get Cyborg", default = false },
        { key = "Auto Get Fully Cyborg", default = false },
        { key = "Auto Get Cyborg Hop Collect Chest", default = false },
        { key = "Auto Get Ghoul", default = false },
        { key = "Hop Server Get Ghoul", default = false },
        { key = "Teleport Acient Clock", default = false },
        { key = "Auto Pull Lever", default = true },
        { key = "Auto Buy Gear", default = true },
        { key = "Select Gear V4", default = "Omega" },
        { key = "Auto Choose Gears", default = true },
        { key = "Auto Finish Train Quest", default = true },
        { key = "Stack Train With Trial Race", default = true },
        { key = "Multi Trial", default = false },
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

    local lines = {
        'repeat task.wait() until game:IsLoaded() and game:GetService("Players").LocalPlayer',
        "",
        'getgenv().Mode = "Main"',
        "",
        "getgenv().Config = {",
    }
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

local function ExportOneClickV4ConfigString()
    local cfg = getgenv().JoinV4Config or {}
    local lines = {
        'repeat task.wait() until game:IsLoaded() and game:GetService("Players").LocalPlayer and game:GetService("Players").LocalPlayer:FindFirstChild("DataLoaded")',
        "",
        'getgenv().Mode = "OneClickV4"',
        "",
        "getgenv().JoinV4Config = {",
    }

    local hopAfterTrial = cfg["Hop After Trial"]
    if hopAfterTrial == nil then
        hopAfterTrial = Settings["Hop After Trial"]
    end
    if hopAfterTrial == nil then hopAfterTrial = true end
    table.insert(lines, '    ["Hop After Trial"] = ' .. (hopAfterTrial == true and "true" or "false") .. ",")
    table.insert(lines, '    ["Helper"] = {')

    for _, group in ipairs(cfg["Helper"] or {}) do
        if type(group) == "table" then
            local names = {}
            for _, name in ipairs(group) do
                table.insert(names, string.format("%q", tostring(name)))
            end
            table.insert(lines, "        {" .. table.concat(names, ", ") .. "},")
        end
    end
    table.insert(lines, "    },")

    local notes = {}
    for _, note in ipairs(cfg["Note"] or {}) do
        table.insert(notes, string.format("%q", tostring(note)))
    end
    table.insert(lines, '    ["Note"] = {' .. table.concat(notes, ", ") .. "},")
    table.insert(lines, '    ["LimitMainPerGroup"] = ' .. tostring(tonumber(cfg["LimitMainPerGroup"]) or 10) .. ",")
    table.insert(lines, "}")
    return table.concat(lines, "\n")
end

local function ExportActiveConfigString()
    if getgenv().Mode == "OneClickV4" then
        return ExportOneClickV4ConfigString()
    end
    return ExportConfigTableString()
end

local ConfigSection = Tabs.Settings:AddSection("Configuration")

Tabs.Settings:AddButton({
    Title = "Copy Setting",
    Description = "Copy the active Main or OneClickV4 config",
    Callback = function()
        local configStr = ExportActiveConfigString()
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
        local fullScript = ExportActiveConfigString() .. '\n\nloadstring(game:HttpGet("https://raw.githubusercontent.com/Bieoidungbuonnua/v4/refs/heads/main/test.lua"))()'
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

Tabs.Settings:AddToggle("AutoTurnOnBuso", {
    Title = "Auto Turn On Buso",
    Description = "Automatically enables Buso Haki after joining or respawning",
    Default = Settings["Auto Turn On Buso"] ~= false,
    Callback = function(enabled)
        SaveSettings("Auto Turn On Buso", enabled)
    end
})

Tabs.Settings:AddToggle("AutoClickToggle", {
    Title = "Auto Click",
    Description = "Fast Attack continuously when holding Melee or Sword",
    Default = Settings["Auto Click"] or false,
    Callback = function(enabled)
        SaveSettings("Auto Click", enabled)
    end
})

Tabs.Settings:AddToggle("AttackNoAnimation", {
    Title = "Attack No Animation ",
    Default = Settings["Attack No Animation "] ~= false,
    Callback = function(enabled)
        SaveSettings("Attack No Animation ", enabled)
    end
})

Tabs.Settings:AddToggle("BringMob", {
    Title = "Bring Mob",
    Default = Settings["Bring Mob"] ~= false,
    Callback = function(enabled)
        SaveSettings("Bring Mob", enabled)
    end
})

Tabs.Settings:AddSlider("BringMobCount", {
    Title = "Bring Mob Count",
    Default = Settings["Bring Mob Count"] or 2,
    Min = 2,
    Max = 6,
    Rounding = 0,
    Callback = function(value)
        SaveSettings("Bring Mob Count", value)
    end
})

InterfaceManager:SetLibrary(Fluent)
InterfaceManager:SetFolder("SkiderV4")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)

Window:SelectTab(1)

end -- end if not _HIDE_UI (section 6 UI building)

--------------------------------------------------------------------------------
-- 7. WORKER LOOPS (Preserved and complete)
--------------------------------------------------------------------------------

-- OneClickV4 is a locked automation preset. Re-apply it in case a late UI callback
-- or an old saved config attempts to turn one of its required features off.
task.spawn(function()
    while task.wait(0.5) do
        if getgenv().Mode == "OneClickV4" then
            ApplyOneClickV4Settings()
        end
    end
end)

-- Worker: Auto Click (Continuous Fast Attack for Melee / Sword)
task.spawn(function()
    while task.wait() do
        if Settings["Auto Click"] then
            pcall(function()
                local fruitName = NameWeapon("Blox Fruit")
                if fruitName and localPlayer.Character and localPlayer.Character:FindFirstChild(fruitName) then
                    local hits = AttackAOE(80, true)
                    if hits then
                        getgenv().UseFruitM1(hits[1][1])
                    end
                else
                    getgenv().AttackFunctionnhungSuperTrial()
                end
            end)
        end
    end
end)

-- Worker: Auto Turn On Buso (same condition and timing as bnn.lua)
task.spawn(function()
    while task.wait(1) do
        if Settings["Auto Turn On Buso"] then
            pcall(function()
                local character = localPlayer.Character
                if character and not FFCMatch(character, "_BusoLayer1") and not character:FindFirstChild("HasBuso") then
                    ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso")
                    task.wait(2)
                end
            end)
        end
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

-- Worker 5: Auto Pull Lever
task.spawn(function()
    while task.wait(0.1) do
        if Settings["Auto Pull Lever"] or Settings["Auto Pull Lever V4"] then
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
local function runRaceTrainingWorkLegacy()
    local char = localPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then
        currentTrainingStatus = "Waiting for character"
        task.wait(1)
        return false
    end

    -- 1. Nếu đang ở trong Temple of Time mà cần training -> Reset để Out Temple ra Sea 3
    if IsInTempleOfTime() then
        currentTrainingStatus = "Legacy training engine disabled in Temple"
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
                    BringMob(mob)
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

-- Auto Finish Train Quest: luong cua bnn.lua, giu nguyen engine teleport Fluent.
local BnnRaceTrainingMobs = {
    "Reborn Skeleton",
    "Demonic Soul",
    "Living Zombie",
    "Posessed Mummy",
}
local bnnVisitedRaceSpawns = {}

local function BnnNextRaceSpawnName()
    if #bnnVisitedRaceSpawns >= #BnnRaceTrainingMobs then
        table.clear(bnnVisitedRaceSpawns)
        return nil
    end
    for _, name in ipairs(BnnRaceTrainingMobs) do
        if not table.find(bnnVisitedRaceSpawns, name) then return name end
    end
    return nil
end

local function runRaceTrainingWork()
    isCurrentlyTraining = true
    blockHopAfterTrial = true
    currentTrainingStatus = "Auto Finish Train Quest (bnn.lua)"
    TurnOnV4()
    BuyGearV4()

    local mob = DetectMob(BnnRaceTrainingMobs)
    if mob then
        repeat
            task.wait()
            SizePart(mob)
            BringMob(mob)
            UsedualFlock()
            ClickM1(mob)

            local root = mob:FindFirstChild("HumanoidRootPart")
            if root then
                if Settings["Select Weapon"] == "Blox Fruit" then
                    ToTarget(root.CFrame * CFrame.new(-7, 20, 0))
                else
                    ToTarget(root.CFrame * CFrame.new(7, 20, 0))
                end
            end
            currentTrainingStatus = "Haunted Castle: farming " .. tostring(mob.Name)
        until not IsMobAlive(mob)
            or not Settings["Auto Finish Train Quest"]
            or not CheckGoTrain()
    else
        local spawnName = BnnNextRaceSpawnName()
        if not spawnName then return end
        local spawnPart = DetectPartSpawnMob(spawnName)
        if spawnPart then
            if not table.find(bnnVisitedRaceSpawns, spawnName) then
                table.insert(bnnVisitedRaceSpawns, spawnName)
            end
            currentTrainingStatus = "Haunted Castle: waiting for " .. tostring(spawnName)
            repeat
                task.wait()
                local character = localPlayer.Character
                local root = character and character:FindFirstChild("HumanoidRootPart")
                if not root then break end
                ToTarget(spawnPart.CFrame * CFrame.new(0, 60, 0))
            until (spawnPart.Position - root.Position).Magnitude <= 100
                or DetectMob(BnnRaceTrainingMobs)
                or not Settings["Auto Finish Train Quest"]
                or not CheckGoTrain()
            task.wait(1)
        end
    end

end

-- Worker 8: Auto Finish Train Quest
task.spawn(function()
    while task.wait() do
        if Settings["Auto Finish Train Quest"] then
            pcall(function()
                if Settings["Stack Train With Trial Race"] and not CheckGoTrain() then
                    isCurrentlyTraining = false
                    blockHopAfterTrial = false
                    currentTrainingStatus = "Training complete - Ready for trial"
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


-- Worker 10: Auto Trial + helper reset noi bo (khong co toggle Auto Reset Character)
-- Helper bat buoc reset khi FFA active de van hanh Multi Trial/Turn V3 Near Door.
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
				if cachedIsHelper then
					-- Helper: bắt buộc reset khi FFA (dù không bật toggle)
					localPlayer.Character.Humanoid.Health = 0
				end
			end
		end)
	end
end)


--------------------------------------------------------------------------------
-- INTEGRATED MOONCHECK UI (kept unchanged from mooncheck.lua)
--------------------------------------------------------------------------------
-- Run MoonCheck independently so an executor-specific UI/closure error can never
-- prevent the JoinV4 API and Dynamic Island from starting.
task.spawn(function()
repeat task.wait(0.5) until game:IsLoaded()
local P = game:GetService("Players")
local L = P.LocalPlayer
repeat task.wait(0.25) until L
local RS = game:GetService("RunService")
function CheckSea(v)
    return v == tonumber(workspace:GetAttribute("MAP"):match("%d+"))
end
local MoonNewCClosure = newcclosure or function(callback) return callback end
CheckMoon = MoonNewCClosure(function()
    local t = (CheckSea(1) or CheckSea(3))
        and ((game.Lighting:FindFirstChild("Sky") and game.Lighting.Sky.MoonTextureId)
        or (game.Lighting:FindFirstChild("Space_Skybox") and game.Lighting.Space_Skybox.MoonTextureId))
        or (CheckSea(2) and game.Lighting:FindFirstChild("FantasySky") and game.Lighting.FantasySky.MoonTextureId)
        or ""
    t = t:gsub("rbxassetid://","http://www.roblox.com/asset/?id=")
    return ({
        ["http://www.roblox.com/asset/?id=15493317929"]="Blue Moon";
        ["http://www.roblox.com/asset/?id=9709149431"]="8/8";
        ["http://www.roblox.com/asset/?id=9709149052"]="7/8";
        ["http://www.roblox.com/asset/?id=9709143733"]="6/8";
        ["http://www.roblox.com/asset/?id=9709150401"]="5/8";
        ["http://www.roblox.com/asset/?id=9709135895"]="4/8";
        ["http://www.roblox.com/asset/?id=9709150086"]="2/8";
        ["http://www.roblox.com/asset/?id=9709139597"]="1/8";
        ["http://www.roblox.com/asset/?id=9709149680"]="0/8";
    })[t] or "nil"
end)
CheckMoonPhase = MoonNewCClosure(function()
    local m = game.Lighting:GetAttribute("MoonPhase")
    if not m then return "Unknown","Unknown Phase",nil end
    if m > 5 then return "Fake Moon","Fake Moon",m
    elseif m < 5 then return "Bad Moon","Bad Moon",m
    elseif m == 5 and not getgenv().isfmended then return "Full Moon","Full Moon Up",m
    elseif m == 5 and getgenv().isfmended then return "Ended","Full Moon End",m end
end)
local function S2T(s)
    if s < 0 then s = 0 end
    return string.format("%dm %ds",math.floor(s/60),s%60)
end
local C, D, NS, NE = 24, 1200, 18, 6
local function IsNight(c) return (c >= NS) or (c < NE) end
local function ToStart()
    local n = game.Lighting.ClockTime
    if IsNight(n) then return 0 end
    local d = n < NS and (NS-n) or 0
    return math.floor((d/C)*D)
end
local function ToEnd()
    local n = game.Lighting.ClockTime
    if not IsNight(n) then return 0 end
    local d = n >= NS and ((C-n)+NE) or (NE-n)
    return math.floor((d/C)*D)
end
local function HMS(c)
    local h = math.floor(c)
    local m = math.floor((c-h)*60)
    local s = math.floor(((c-h)*60-m)*60)
    return string.format("%02d:%02d:%02d",h,m,s)
end
local function CreateGUI()
    local g = L.PlayerGui:FindFirstChild("MoonStatusGUI")
    if g then g:Destroy() end
    g = Instance.new("ScreenGui")
    g.Name = "MoonStatusGUI"
    g.ResetOnSpawn = false
    g.IgnoreGuiInset = true
    g.DisplayOrder = 999999999
    g.ZIndexBehavior = Enum.ZIndexBehavior.Global
    g.Enabled = false                   -- hide
    g.Parent = L.PlayerGui
    local l = Instance.new("TextLabel")
    l.Name = "MainLabel"
    l.Size = UDim2.new(0,600,0,130)
    l.Position = UDim2.new(0.5,-300,0.5,-65)
    l.BackgroundTransparency = 1
    l.Font = Enum.Font.GothamBold
    l.TextSize = 20
    l.TextColor3 = Color3.fromRGB(255,255,255)
    l.TextWrapped = true
    l.TextStrokeTransparency = 0.3
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Top
    l.ZIndex = 2147483647
    l.RichText = true
    l.Parent = g
    return g,l
end
local G,Lb = CreateGUI()
local function Upd()
    local ms = CheckMoon()
    local ps,_,pv = CheckMoonPhase()
    local ct = game.Lighting.ClockTime
    local ts = ToStart()
    local te = ToEnd()
    local tsStr, teStr = S2T(ts), S2T(te)
    local pc = #P:GetPlayers()
    local isFull = (ms == "8/8" and ps == "Full Moon")
    local show = isFull and (ts > 0 or te > 0)
    G.Enabled = show
    if not show then return end
    local function T(t,r)
        return string.format('<font color="rgb(%d,%d,%d)">%s</font>',r.R*255,r.G*255,r.B*255,t)
    end
    local tc = isFull and Color3.fromRGB(255,215,0) or Color3.fromRGB(255,100,100)
    local kc = Color3.fromRGB(100,200,255)
    local vc = Color3.fromRGB(255,255,255)
    local sc = Color3.fromRGB(0,255,150)
    local pc2 = ps=="Full Moon" and Color3.fromRGB(0,255,150) or Color3.fromRGB(255,100,100)
    Lb.Text = string.format(
        "%s\n%s %s\n%s %s\n%s %s\n%s %s [Time: %s]\n%s %s",
        T("Full Moon Status",tc),
        T("Time To Start (Night/Full Moon):",kc),T(tsStr,vc),
        T("Players In Server:",kc),T(tostring(pc),vc),
        T("Time To End (Night/Full Moon):",kc),T(teStr,vc),
        T("Moon Status:",kc),T(ms,sc),HMS(ct),
        T("Phase:",kc),T(tostring(ps).." ("..tostring(pv or "N/A")..")",pc2)
    )
end
RS.Heartbeat:Connect(function()
    pcall(Upd)
end)
end)

--------------------------------------------------------------------------------
-- INTEGRATED JOINV4 ENGINE + DYNAMIC ISLAND STATUS UI
--------------------------------------------------------------------------------
-- [3/3] JOINV4 (Kaiv4-BNN/joinv4.lua) - API Moon Hop & Group Management
-- ══════════════════════════════════════════════════════════════════
;(function()
    local CFG = getgenv().JoinV4Config
    if type(CFG) ~= "table" then
        warn("[JoinV4] JoinV4Config is missing; runtime was not started")
        return
    end
    getgenv().JoinV4Active = true
    getgenv().JoinV4RuntimeStatus = "Starting"

    -- API / TIMING CONSTANTS
    local FM_API_URL      = "http://163.61.183.126:3000/fullmoon"
    local NEAR_MOON_API_URL = "http://162.4.177.49:8080/jobid/nearmoon/gay"
    local NEAR_MOON_ENABLED = CFG["Hop Near Moon"] == true
    local NEAR_MOON_MAX_TTN = 300   -- neu timetonight > 300s thi hop di (fake moon)
    local API_BASE        = "http://mbasic7.pikamc.vn:25082"
    local FM_API_INTERVAL  = 3      -- giây giữa các lần poll FM API
    local SYNC_INTERVAL    = 1.5   -- giây giữa các lần sync trạng thái lên API
    local HOP_STARTUP_DELAY = 3    -- giây trước khi bắt đầu hop

    -- SERVICES
    local HttpService       = game:GetService("HttpService")
    local Players           = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local CoreGui           = game:GetService("CoreGui")
    local Lighting          = game:GetService("Lighting")

    local Player   = Players.LocalPlayer
    local USERNAME = Player.Name

    -- PARSE CONFIG -> MULTI-GROUP ROLE DETECTION
    local function trim(s)
        return tostring(s):gsub("^%s+", ""):gsub("%s+$", "")
    end

    local helperGroups = CFG["Helper"] or {}  -- array of arrays
    local noteList     = CFG["Note"]   or {}  -- array of strings

    -- Sets toàn cục
    local AllHelperSet = {}  -- username -> true  (tất cả helpers mọi group)
    local AllHopFMSet  = {}  -- username -> groupIdx  (slot[1] của mỗi group)

    -- Thông tin của USERNAME
    local MY_GROUP_IDX     = nil   -- chỉ số group (1-based) USERNAME thuộc
    local MY_GROUP_NOTE    = nil   -- groupId string gửi API
    local MY_GROUP_HELPERS = {}    -- danh sách helpers của group mình (raw)
    local MY_HOPFM_NAME    = nil   -- tên HopFM helper của group mình

    for i, helperList in ipairs(helperGroups) do
        if type(helperList) == "table" then
            local note = trim(noteList[i] or ("group" .. i))

            -- slot[1] = HopFM của group này
            local hopFMName = nil
            if helperList[1] then
                hopFMName = trim(helperList[1])
                if hopFMName ~= "" then
                    AllHopFMSet[hopFMName] = i
                end
            end

            for _, h in ipairs(helperList) do
                h = trim(h)
                if h ~= "" then
                    AllHelperSet[h] = true
                    if h == USERNAME then
                        MY_GROUP_IDX     = i
                        MY_GROUP_NOTE    = note
                        MY_GROUP_HELPERS = helperList
                        MY_HOPFM_NAME    = hopFMName
                    end
                end
            end
        end
    end

    local isHelper = AllHelperSet[USERNAME] == true
    local isHopFM  = AllHopFMSet[USERNAME]  ~= nil   -- là slot[1] của group nào đó
    local isMain   = not isHelper

    -- GROUP_ID
    local GROUP_ID = isHelper and (MY_GROUP_NOTE or trim(noteList[1] or "joinv4")) or ""
    local myAssignedGroupId = ""  -- main: được cập nhật từ resp.group.id sau sync đầu tiên
    local myDefaultGroup = trim(noteList[1] or "group1")  -- fallback khi chua duoc gan group

    -- Build HelperSet riêng cho group của mình
    local MY_HelperSet  = {}
    local MY_HopFMSet   = {}
    for _, h in ipairs(MY_GROUP_HELPERS) do
        h = trim(h)
        if h ~= "" then
            MY_HelperSet[h] = true
            if AllHopFMSet[h] ~= nil then
                MY_HopFMSet[h] = true
            end
        end
    end

    -- STATE
    local currentStatus   = "Starting..."
    local lastFmApiAt     = 0
    local lastFmApiResult = nil
    local fmJoinedCache   = {}
    local FM_CACHE_EXPIRE = 180
    local HOP_STARTUP     = tick()
    local fmHopPending    = false
    local fmPendingCheckAt = 0
    local _failedHopJobId = ""

    -- HTTP
    local function httpReq()
        return http_request or (http and http.request) or request or (syn and syn.request)
    end

    local function httpGet(url)
        local r = httpReq()
        if not r then return nil end
        local ok, res = pcall(r, { Url = url, Method = "GET" })
        if ok and res then
            local body = res.Body or res.body
            local code = tonumber(res.StatusCode or res.status or 200) or 200
            if body and code == 200 then return body end
        end
        return nil
    end

    local function httpPost(url, body)
        local r = httpReq()
        if not r then return nil end
        local ok, res = pcall(r, {
            Url     = url,
            Method  = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body    = HttpService:JSONEncode(body)
        })
        if ok and res then
            local b = res.Body or res.body
            local code = tonumber(res.StatusCode or res.status or 200) or 200
            if b and code == 200 then
                local ok2, data = pcall(function() return HttpService:JSONDecode(b) end)
                if ok2 then return data end
            end
        end
        return nil
    end

    -- MOON CHECK
    local function isNight()
        local c = Lighting.ClockTime
        return c >= 16 or c < 5
    end

    local function isFullMoon()
        return Lighting:GetAttribute("MoonPhase") == 5
    end

    local function isPreFMReady()
        local ok, result = pcall(function()
            local function checkSea(v)
                local attr = workspace:GetAttribute("MAP")
                if not attr then return false end
                return v == tonumber(tostring(attr):match("%d+"))
            end
            local t = (checkSea(1) or checkSea(3))
                and ((Lighting:FindFirstChild("Sky") and Lighting.Sky.MoonTextureId)
                or   (Lighting:FindFirstChild("Space_Skybox") and Lighting.Space_Skybox.MoonTextureId))
                or   (checkSea(2) and Lighting:FindFirstChild("FantasySky") and Lighting.FantasySky.MoonTextureId)
                or ""
            t = t:gsub("rbxassetid://", "http://www.roblox.com/asset/?id=")
            local moonTex = ({
                ["http://www.roblox.com/asset/?id=9709149431"]  = "8/8",
                ["http://www.roblox.com/asset/?id=15493317929"] = "Blue Moon",
            })[t] or "nil"
            if moonTex ~= "8/8" and moonTex ~= "Blue Moon" then return false end
            local m = Lighting:GetAttribute("MoonPhase")
            if not m or m ~= 5 then return false end
            if getgenv().isfmended then return false end
            local NS, NE = 18, 6
            local ct = Lighting.ClockTime
            local isNightNow = ct >= NS or ct < NE
            if not isNightNow then
                local d = ct < NS and (NS - ct) or 0
                local toStart = math.floor((d / 24) * 1200)
                if toStart > 360 then return false end
            end
            return true
        end)
        return ok and result == true
    end

    -- FIND FM SERVER (Multi-fallback HTTP)
    local function findFMServer()
        if not FM_API_URL or FM_API_URL == "" then return nil end

        local function getField(tbl, ...)
            if type(tbl) ~= "table" then return nil end
            local low = {}
            for k, v in pairs(tbl) do if type(k) == "string" then low[k:lower()] = v end end
            for i = 1, select("#", ...) do
                local n = select(i, ...)
                if n then local val = low[n:lower()]; if val ~= nil then return val end end
            end
            return nil
        end

        local function parsePlayers(f)
            if not f then return nil end
            if type(f) == "number" then return f end
            if type(f) == "string" then
                local cur = f:match("(%d+)%s*/%s*%d+")
                if cur then return tonumber(cur) end
                return tonumber(f)
            end
            return nil
        end

        local function parseTimeToNight(entry)
            for _, n in ipairs({"timetonight","timeToNight","time_to_night","timeToNightSeconds","time"}) do
                local v = getField(entry, n); if v ~= nil then return tonumber(v) end
            end
            return nil
        end

        local resp = nil
        local httpMethods = {
            function(u) if type(syn) == "table" and type(syn.request) == "function" then return syn.request({Url=u,Method="GET"}) end end,
            function(u) if type(http_request) == "function" then return http_request({Url=u,Method="GET"}) end end,
            function(u) if type(request) == "function" then return request({Url=u,Method="GET"}) end end,
            function(u) if type(http) == "table" and type(http.request) == "function" then return http.request({Url=u,Method="GET"}) end end,
        }
        for _, fn in ipairs(httpMethods) do
            local ok, res = pcall(fn, FM_API_URL)
            if ok and res and type(res) == "table" and (res.Body or res.body) then
                local body = res.Body or res.body
                local code = tonumber(res.StatusCode or res.status or res.Status or 200) or 200
                resp = {Body = body, StatusCode = code}
                break
            end
        end
        if not resp or resp.StatusCode ~= 200 then return nil end

        local ok2, parsed = pcall(function() return HttpService:JSONDecode(resp.Body) end)
        if not ok2 or type(parsed) ~= "table" then return nil end

        local entries
        if type(parsed.data) == "table" and #parsed.data > 0 then
            entries = parsed.data
        elseif type(parsed) == "table" and #parsed > 0 then
            entries = parsed
        else return nil end

        local candidates = {}
        for _, v in ipairs(entries) do
            if type(v) ~= "table" then continue end
            local jobId   = getField(v, "jobid","JobId","JobID","jobId","job_id")
            local placeId = getField(v, "placeid","PlaceId","placeId","place_id")
            local players = parsePlayers(getField(v, "players","Players","playerCount","PlayerCount"))
            if not jobId or jobId == "" then continue end
            if tostring(jobId) == tostring(game.JobId) then continue end
            local cached = fmJoinedCache[tostring(jobId)]
            if cached and (os.time() - cached) < FM_CACHE_EXPIRE then continue end
            if not placeId or tonumber(placeId) ~= tonumber(game.PlaceId) then continue end
            if players and tonumber(players) >= 2 and tonumber(players) <= 7 then
                table.insert(candidates, {jobId = tostring(jobId), players = tonumber(players)})
            end
        end
        if #candidates == 0 then return nil end
        -- Chon server it player nhat de tranh race condition
        table.sort(candidates, function(a, b) return a.players < b.players end)
        return candidates[1].jobId
    end

    -- FIND NEAR MOON SERVER (API khong co timetonight, chi loc player + placeId)
    local function findNearMoonServer()
        if not NEAR_MOON_ENABLED or not NEAR_MOON_API_URL or NEAR_MOON_API_URL == "" then return nil end

        local function getField(tbl, ...)
            if type(tbl) ~= "table" then return nil end
            local low = {}
            for k, v in pairs(tbl) do if type(k) == "string" then low[k:lower()] = v end end
            for i = 1, select("#", ...) do
                local n = select(i, ...)
                if n then local val = low[n:lower()]; if val ~= nil then return val end end
            end
            return nil
        end

        local function parsePlayers(f)
            if not f then return nil end
            if type(f) == "number" then return f end
            if type(f) == "string" then
                local cur = f:match("(%d+)%s*/%s*%d+")
                if cur then return tonumber(cur) end
                return tonumber(f)
            end
            return nil
        end

        local resp = nil
        local httpMethods = {
            function(u) if type(syn) == "table" and type(syn.request) == "function" then return syn.request({Url=u,Method="GET"}) end end,
            function(u) if type(http_request) == "function" then return http_request({Url=u,Method="GET"}) end end,
            function(u) if type(request) == "function" then return request({Url=u,Method="GET"}) end end,
            function(u) if type(http) == "table" and type(http.request) == "function" then return http.request({Url=u,Method="GET"}) end end,
        }
        for _, fn in ipairs(httpMethods) do
            local ok, res = pcall(fn, NEAR_MOON_API_URL)
            if ok and res and type(res) == "table" and (res.Body or res.body) then
                local body = res.Body or res.body
                local code = tonumber(res.StatusCode or res.status or res.Status or 200) or 200
                resp = {Body = body, StatusCode = code}
                break
            end
        end
        if not resp or resp.StatusCode ~= 200 then return nil end

        local ok2, parsed = pcall(function() return HttpService:JSONDecode(resp.Body) end)
        if not ok2 or type(parsed) ~= "table" then return nil end

        local entries
        if type(parsed.data) == "table" and #parsed.data > 0 then
            entries = parsed.data
        elseif type(parsed) == "table" and #parsed > 0 then
            entries = parsed
        else return nil end

        local candidates = {}
        for _, v in ipairs(entries) do
            if type(v) ~= "table" then continue end
            local jobId   = getField(v, "jobid","JobId","JobID","jobId","job_id")
            local placeId = getField(v, "placeid","PlaceId","placeId","place_id")
            local players = parsePlayers(getField(v, "players","Players","playerCount","PlayerCount"))
            if not jobId or jobId == "" then continue end
            if tostring(jobId) == tostring(game.JobId) then continue end
            local cached = fmJoinedCache[tostring(jobId)]
            if cached and (os.time() - cached) < FM_CACHE_EXPIRE then continue end
            if not placeId or tonumber(placeId) ~= tonumber(game.PlaceId) then continue end
            -- Loc: players 2..6
            if players and tonumber(players) >= 2 and tonumber(players) <= 7 then
                table.insert(candidates, {jobId = tostring(jobId), players = tonumber(players)})
            end
        end
        if #candidates == 0 then return nil end
        -- Chon server it player nhat de tranh race condition
        table.sort(candidates, function(a, b) return a.players < b.players end)
        return candidates[1].jobId
    end

    -- Tinh timetonight (seconds) tu ClockTime hien tai trong server
    local function getServerTimeToNight()
        local ok, val = pcall(function()
            local NS = 18
            local ct = Lighting.ClockTime
            if ct >= NS or ct < 6 then return 0 end
            local d = ct < NS and (NS - ct) or 0
            return math.floor((d / 24) * 1200)
        end)
        return ok and (val or 9999) or 9999
    end

    -- TELEPORT
    local TeleportService = game:GetService("TeleportService")
    TeleportService.TeleportInitFailed:Connect(function(_player, result, _msg)
        local dead = result == Enum.TeleportResult.Failure
            or result == Enum.TeleportResult.GameEnded
            or result == Enum.TeleportResult.Unauthorized
        if dead and lastFmApiResult and lastFmApiResult ~= "" then
            warn("[JoinV4] TeleportInitFailed (" .. tostring(result) .. ") -> blacklist " .. lastFmApiResult:sub(1,8))
            _failedHopJobId = lastFmApiResult
            fmJoinedCache[lastFmApiResult] = os.time()
            lastFmApiResult = nil
            lastFmApiAt     = 0
        end
    end)

    local function hopTo(jobId)
        pcall(function()
            local sb = ReplicatedStorage:WaitForChild("__ServerBrowser", 5)
            if sb then
                sb:InvokeServer("teleport", jobId)
            end
        end)
    end

    -- NATIVE V4 STATUS CHECK
    local _CommF_ = nil
    pcall(function()
        _CommF_ = ReplicatedStorage:WaitForChild("Remotes", 5):WaitForChild("CommF_", 5)
    end)

    local function getLocalV4Status()
        local v4s = nil
        pcall(function()
            if type(getV4Status) == "function" then
                v4s = getV4Status(false)
            end
        end)
        if v4s then return v4s end

        if not _CommF_ then
            pcall(function()
                _CommF_ = ReplicatedStorage:FindFirstChild("Remotes")
                    and ReplicatedStorage.Remotes:FindFirstChild("CommF_")
            end)
        end
        if not _CommF_ then return nil end

        local char = Player.Character
        if not char then return nil end

        local raceTransformed = char:FindFirstChild("RaceTransformed")

        if not raceTransformed then
            local ok, progress = pcall(function()
                return _CommF_:InvokeServer("RaceV4Progress", "Check")
            end)
            if not ok then return nil end
            progress = tonumber(progress)
            if progress == nil then
                return { key = "check_failed", needsTraining = false, needsPurchase = false, canTrial = false, complete = false }
            end
            if progress < 4 then
                return { key = "pre_v4_progress_" .. tostring(progress), needsTraining = true, needsPurchase = false, canTrial = false, complete = false }
            else
                return { key = "first_trial_ready", needsTraining = false, needsPurchase = false, canTrial = true, complete = false }
            end
        else
            local ok, code, prog = pcall(function()
                return _CommF_:InvokeServer("UpgradeRace", "Check")
            end)
            if not ok then return nil end
            code = tonumber(code)
            if code == nil then return nil end

            if     code == 0 then return { key = "trial_ready",          needsTraining = false, needsPurchase = false, canTrial = true,  complete = false }
            elseif code == 1 then return { key = "training_stage_1",     needsTraining = true,  needsPurchase = false, canTrial = false, complete = false }
            elseif code == 2 then return { key = "buy_gear_1",           needsTraining = false, needsPurchase = true,  canTrial = false, complete = false }
            elseif code == 3 then return { key = "training_stage_2",     needsTraining = true,  needsPurchase = false, canTrial = false, complete = false }
            elseif code == 4 then return { key = "buy_duration",         needsTraining = false, needsPurchase = true,  canTrial = false, complete = false }
            elseif code == 5 then return { key = "completed",            needsTraining = false, needsPurchase = false, canTrial = false, complete = true  }
            elseif code == 6 then
                local completed = math.clamp((tonumber(prog) or 2) - 2, 0, 3)
                local remaining = math.max(0, 3 - completed)
                return { key = "three_session_training", needsTraining = remaining > 0, needsPurchase = false, canTrial = false, complete = false }
            elseif code == 7 then return { key = "buy_next_upgrade",     needsTraining = false, needsPurchase = true,  canTrial = false, complete = false }
            elseif code == 8 then
                local remaining = math.max(0, 10 - (tonumber(prog) or 0))
                return { key = "mastery_training", needsTraining = remaining > 0, needsPurchase = false, canTrial = false, complete = remaining <= 0 }
            else
                return { key = "not_ready_" .. tostring(code), needsTraining = false, needsPurchase = false, canTrial = false, complete = false }
            end
        end
    end

    local _v4Cache   = { needsTraining=nil, needsPurchase=nil, canTrial=false, complete=false, key=nil }
    local _v4CacheAt = 0
    local V4_CACHE_TTL = 4

    local function updateV4Cache()
        if not isMain then return end
        if tick() - _v4CacheAt < V4_CACHE_TTL then return end
        local v4s = getLocalV4Status()
        if v4s then
            _v4Cache   = v4s
            _v4CacheAt = tick()
        end
    end

    -- BUILD PAYLOAD
    local function buildPayload(hasFM)
        local gid = isHelper and GROUP_ID or myAssignedGroupId

        local groupsArr = {}
        for i, helperList in ipairs(helperGroups) do
            if type(helperList) == "table" then
                local note = trim(noteList[i] or ("group" .. i))
                local cleanHelpers = {}
                for _, h in ipairs(helperList) do
                    h = trim(h)
                    if h ~= "" then table.insert(cleanHelpers, h) end
                end
                table.insert(groupsArr, {
                    id      = note,
                    name    = note,
                    helpers = cleanHelpers,
                })
            end
        end

        local isTrain = _v4Cache.needsTraining == true
        local isBuy   = _v4Cache.needsPurchase == true
        local isTrial = _v4Cache.canTrial      == true
        local isDone  = _v4Cache.complete      == true
        local syncStatus = currentStatus
        if isTrain then syncStatus = "training"
        elseif isBuy  then syncStatus = "buy gear"
        elseif isTrial then syncStatus = "trial"
        elseif isDone  then syncStatus = "complete"
        end

        local limitMain = math.max(1, math.min(50, tonumber(CFG["LimitMainPerGroup"]) or 10))
        local numGroups = #helperGroups

        return {
            username      = USERNAME,
            role          = isHelper and "helper" or "main",
            groupId       = gid,
            jobId         = tostring(game.JobId),
            placeId       = tostring(game.PlaceId),
            fullMoon      = hasFM,
            nearFM        = isPreFMReady(),
            fullmoon      = hasFM,
            nearfm        = isPreFMReady(),
            jobid         = tostring(game.JobId),
            status        = syncStatus,
            ready         = hasFM,
            alive         = true,
            needsTraining = isTrain,
            needsPurchase = isBuy,
            canTrial      = isTrial,
            complete      = isDone,
            groups        = groupsArr,
            limitMainUp   = limitMain,
            soluonggroup  = numGroups,
        }
    end

    local function syncToAPI()
        local hasFM = isNight() and isFullMoon()
        return httpPost(API_BASE .. "/data", buildPayload(hasFM))
    end

    -- STATUS TEXT
    local function setStatus(txt)
        currentStatus = tostring(txt or "")
    end

    -- ══════════════════════════════════════════════════════════════════
    -- JOINV4 DYNAMIC ISLAND UI (adapted from dynamic.lua)
    -- Keeps the Dynamic Island expand/collapse, rubber-band and live animations.
    -- ══════════════════════════════════════════════════════════════════
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local function makeSFFont(weight)
        local ok, face = pcall(function()
            return Font.new("rbxasset://fonts/families/Inter.json", weight)
        end)
        if ok and face then return face end
        local fallbackOk, fallback = pcall(function()
            return Font.fromEnum(Enum.Font.Gotham)
        end)
        return fallbackOk and fallback or nil
    end
    local FONT_SF_BOLD = makeSFFont(Enum.FontWeight.Bold)
    local FONT_SF_SEMI = makeSFFont(Enum.FontWeight.SemiBold)
    local FONT_SF_MED  = makeSFFont(Enum.FontWeight.Medium)
    local FONT_SF_REG  = makeSFFont(Enum.FontWeight.Regular)

    local C_ORANGE = Color3.fromRGB(255, 159, 10)
    local C_GREEN  = Color3.fromRGB(48, 209, 88)
    local C_RED    = Color3.fromRGB(255, 59, 48)
    local C_BLUE   = Color3.fromRGB(10, 132, 255)
    local C_PURPLE = Color3.fromRGB(191, 90, 242)
    local C_MUTED  = Color3.fromRGB(142, 142, 147)
    local C_WHITE  = Color3.fromRGB(245, 245, 247)
    local C_BG     = Color3.fromRGB(0, 0, 0)

    local HOME_POSITION = UDim2.new(0.5, 0, 0, 11)
    local COMPACT_SIZE  = UDim2.new(0, 286, 0, 40)
    local EXPANDED_SIZE = UDim2.new(0, 390, 0, 210)

    local ScreenGui, MainCard, RolePill, GroupPill, MoonLabel, StatusLabel
    local CompactRole, CompactStatus, StatusDot, IslandStroke, IslandCorner
    local CompactContent, ExpandedContent
    local isExpanded, isAnimating = false, false
    local statusColor = C_ORANGE

    local function applyFont(label, face, size)
        if face then
            pcall(function() label.FontFace = face end)
        else
            label.Font = Enum.Font.Gotham
        end
        label.TextSize = size
    end

    local function round(instance, radius)
        local corner = Instance.new("UICorner")
        corner.CornerRadius = radius and UDim.new(0, radius) or UDim.new(1, 0)
        corner.Parent = instance
        return corner
    end

    local function newLabel(parent, name, value, face, size)
        local label = Instance.new("TextLabel")
        label.Name = name
        label.BackgroundTransparency = 1
        label.Text = value
        label.TextColor3 = C_WHITE
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextYAlignment = Enum.TextYAlignment.Center
        label.TextTruncate = Enum.TextTruncate.AtEnd
        applyFont(label, face, size)
        label.Parent = parent
        return label
    end

    local function colorForStatus(value)
        local s = tostring(value or ""):lower()
        if s:find("timeout") or s:find("fail") or s:find("error") or s:find("conflict") then
            return C_RED
        elseif s:find("trial") or s:find("done") or s:find("complete") or s:find("full moon") or s:find("fm active") then
            return C_GREEN
        elseif s:find("hop") or s:find("teleport") or s:find("join") then
            return C_BLUE
        elseif s:find("train") or s:find("buy") then
            return C_ORANGE
        elseif s:find("wait") or s:find("sett") or s:find("connect") or s:find("check") then
            return Color3.fromRGB(100, 210, 255)
        end
        return C_PURPLE
    end

    local function paintStatus(value)
        statusColor = colorForStatus(value)
        if StatusDot then StatusDot.BackgroundColor3 = statusColor end
        if IslandStroke then
            TweenService:Create(IslandStroke, TweenInfo.new(0.25), {
                Color = statusColor,
                Transparency = 0.18,
            }):Play()
        end
        if CompactStatus then
            CompactStatus.Text = tostring(value or "")
            CompactStatus.TextColor3 = statusColor
        end
        if StatusLabel then
            StatusLabel.Text = tostring(value or "")
            StatusLabel.TextColor3 = statusColor
        end
    end

    local function setStatus(txt)
        currentStatus = tostring(txt or "")
        getgenv().JoinV4RuntimeStatus = currentStatus
        paintStatus(currentStatus)
    end

    local function expandIsland()
        if isAnimating or isExpanded or not MainCard then return end
        isAnimating = true
        isExpanded = true
        local squeeze = TweenService:Create(MainCard, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, COMPACT_SIZE.X.Offset - 10, 0, COMPACT_SIZE.Y.Offset - 4),
        })
        squeeze:Play()
        squeeze.Completed:Connect(function()
            if not MainCard or not MainCard.Parent then return end
            CompactContent.Visible = false
            ExpandedContent.Visible = true
            ExpandedContent.GroupTransparency = 1
            TweenService:Create(MainCard, TweenInfo.new(0.48, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), { Size = EXPANDED_SIZE }):Play()
            TweenService:Create(IslandCorner, TweenInfo.new(0.48, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), { CornerRadius = UDim.new(0, 42) }):Play()
            TweenService:Create(ExpandedContent, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { GroupTransparency = 0 }):Play()
            task.delay(0.48, function() isAnimating = false end)
        end)
    end

    local function collapseIsland()
        if isAnimating or not isExpanded or not MainCard then return end
        isAnimating = true
        TweenService:Create(ExpandedContent, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { GroupTransparency = 1 }):Play()
        task.delay(0.08, function()
            if not MainCard or not MainCard.Parent then return end
            ExpandedContent.Visible = false
            CompactContent.Visible = true
            CompactContent.GroupTransparency = 1
            TweenService:Create(MainCard, TweenInfo.new(0.38, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), { Size = COMPACT_SIZE }):Play()
            TweenService:Create(IslandCorner, TweenInfo.new(0.38, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), { CornerRadius = UDim.new(1, 0) }):Play()
            TweenService:Create(CompactContent, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { GroupTransparency = 0 }):Play()
            task.delay(0.38, function()
                isExpanded = false
                isAnimating = false
            end)
        end)
    end

    local function createUI()
        local function resolveGuiParent()
            if gethui then
                local ok, result = pcall(gethui)
                if ok and result then return result end
            end
            local playerGui = Player:FindFirstChildOfClass("PlayerGui") or Player:FindFirstChild("PlayerGui")
            return playerGui or CoreGui
        end

        local guiParent = resolveGuiParent()
        pcall(function()
            local old = guiParent:FindFirstChild("JoinV4UI")
            if old then old:Destroy() end
        end)

        local sg = Instance.new("ScreenGui")
        sg.Name = "JoinV4UI"
        sg.ResetOnSpawn = false
        sg.IgnoreGuiInset = true
        sg.DisplayOrder = 999999
        sg.ZIndexBehavior = Enum.ZIndexBehavior.Global
        sg.Parent = guiParent
        ScreenGui = sg

        local island = Instance.new("Frame")
        island.Name = "IslandRoot"
        island.AnchorPoint = Vector2.new(0.5, 0)
        island.Position = HOME_POSITION
        island.Size = COMPACT_SIZE
        island.BackgroundColor3 = C_BG
        island.BorderSizePixel = 0
        island.ClipsDescendants = true
        island.Active = true
        island.ZIndex = 50
        island.Parent = sg
        MainCard = island
        IslandCorner = round(island)

        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 22)),
            ColorSequenceKeypoint.new(1, C_BG),
        })
        gradient.Rotation = 120
        gradient.Parent = island

        local stroke = Instance.new("UIStroke")
        stroke.Color = statusColor
        stroke.Thickness = 1.25
        stroke.Transparency = 0.18
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = island
        IslandStroke = stroke

        local compact = Instance.new("CanvasGroup")
        compact.Name = "Compact"
        compact.Size = UDim2.fromScale(1, 1)
        compact.BackgroundTransparency = 1
        compact.ZIndex = 51
        compact.Parent = island
        CompactContent = compact

        local dot = Instance.new("Frame")
        dot.Name = "LiveDot"
        dot.Size = UDim2.fromOffset(10, 10)
        dot.Position = UDim2.new(0, 15, 0.5, -5)
        dot.BackgroundColor3 = statusColor
        dot.BorderSizePixel = 0
        dot.ZIndex = 52
        dot.Parent = compact
        round(dot)
        StatusDot = dot

        CompactRole = newLabel(compact, "Role", "JOIN V4", FONT_SF_BOLD, 12)
        CompactRole.Size = UDim2.new(0, 105, 1, 0)
        CompactRole.Position = UDim2.new(0, 34, 0, 0)
        CompactRole.ZIndex = 52

        CompactStatus = newLabel(compact, "Status", "Starting...", FONT_SF_SEMI, 12)
        CompactStatus.Size = UDim2.new(1, -142, 1, 0)
        CompactStatus.Position = UDim2.new(0, 132, 0, 0)
        CompactStatus.TextXAlignment = Enum.TextXAlignment.Right
        CompactStatus.ZIndex = 52

        local expanded = Instance.new("CanvasGroup")
        expanded.Name = "Expanded"
        expanded.Size = UDim2.fromScale(1, 1)
        expanded.BackgroundTransparency = 1
        expanded.Visible = false
        expanded.GroupTransparency = 1
        expanded.ZIndex = 51
        expanded.Parent = island
        ExpandedContent = expanded

        local title = newLabel(expanded, "Title", "JOIN V4", FONT_SF_BOLD, 18)
        title.Size = UDim2.new(0, 130, 0, 26)
        title.Position = UDim2.new(0, 22, 0, 15)
        title.ZIndex = 52

        local user = newLabel(expanded, "User", USERNAME, FONT_SF_MED, 12)
        user.Size = UDim2.new(1, -175, 0, 26)
        user.Position = UDim2.new(0, 153, 0, 15)
        user.TextXAlignment = Enum.TextXAlignment.Right
        user.TextColor3 = C_MUTED
        user.ZIndex = 52

        local divider = Instance.new("Frame")
        divider.Size = UDim2.new(1, -44, 0, 1)
        divider.Position = UDim2.new(0, 22, 0, 48)
        divider.BackgroundColor3 = Color3.fromRGB(45, 45, 48)
        divider.BorderSizePixel = 0
        divider.ZIndex = 52
        divider.Parent = expanded

        local function makeInfoRow(y, caption)
            local cap = newLabel(expanded, caption .. "Caption", caption, FONT_SF_REG, 12)
            cap.Size = UDim2.new(0, 74, 0, 25)
            cap.Position = UDim2.new(0, 22, 0, y)
            cap.TextColor3 = C_MUTED
            cap.ZIndex = 52
            local val = newLabel(expanded, caption, "...", FONT_SF_SEMI, 13)
            val.Size = UDim2.new(1, -118, 0, 25)
            val.Position = UDim2.new(0, 96, 0, y)
            val.TextXAlignment = Enum.TextXAlignment.Right
            val.ZIndex = 52
            return val
        end

        RolePill = makeInfoRow(55, "Role")
        GroupPill = makeInfoRow(84, "Group")
        MoonLabel = makeInfoRow(113, "Moon")

        local statusBox = Instance.new("Frame")
        statusBox.Name = "JoinStatus"
        statusBox.Size = UDim2.new(1, -44, 0, 42)
        statusBox.Position = UDim2.new(0, 22, 1, -54)
        statusBox.BackgroundColor3 = Color3.fromRGB(24, 24, 27)
        statusBox.BorderSizePixel = 0
        statusBox.ZIndex = 52
        statusBox.Parent = expanded
        round(statusBox, 14)

        local statusAccent = Instance.new("Frame")
        statusAccent.Name = "Accent"
        statusAccent.Size = UDim2.new(0, 4, 0, 22)
        statusAccent.Position = UDim2.new(0, 10, 0.5, -11)
        statusAccent.BackgroundColor3 = statusColor
        statusAccent.BorderSizePixel = 0
        statusAccent.ZIndex = 53
        statusAccent.Parent = statusBox
        round(statusAccent)

        StatusLabel = newLabel(statusBox, "Status", currentStatus, FONT_SF_MED, 13)
        StatusLabel.Size = UDim2.new(1, -28, 1, 0)
        StatusLabel.Position = UDim2.new(0, 22, 0, 0)
        StatusLabel.TextWrapped = true
        StatusLabel.TextTruncate = Enum.TextTruncate.None
        StatusLabel.ZIndex = 53

        local isDragging = false
        local dragStart = Vector2.zero
        local dragDistance = 0
        local dragConnection
        local MAX_PULL_X, MAX_PULL_Y, RESISTANCE = 45, 35, 0.28

        local function rubber(delta, maxLimit)
            local sign = math.sign(delta)
            local amount = math.abs(delta)
            return sign * (1 - (1 / ((amount * RESISTANCE / maxLimit) + 1))) * maxLimit
        end

        island.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
            isDragging = true
            dragDistance = 0
            dragStart = Vector2.new(input.Position.X, input.Position.Y)
            local base = isExpanded and EXPANDED_SIZE or COMPACT_SIZE
            TweenService:Create(island, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {
                Size = UDim2.new(0, base.X.Offset * 0.97, 0, base.Y.Offset * 0.97),
            }):Play()
            if dragConnection then dragConnection:Disconnect() end
            dragConnection = UserInputService.InputChanged:Connect(function(changed)
                if not isDragging then return end
                if changed.UserInputType ~= Enum.UserInputType.MouseMovement and changed.UserInputType ~= Enum.UserInputType.Touch then return end
                local delta = Vector2.new(changed.Position.X, changed.Position.Y) - dragStart
                dragDistance = delta.Magnitude
                local rx, ry = rubber(delta.X, MAX_PULL_X), rubber(delta.Y, MAX_PULL_Y)
                island.Position = UDim2.new(HOME_POSITION.X.Scale, HOME_POSITION.X.Offset + rx, HOME_POSITION.Y.Scale, HOME_POSITION.Y.Offset + ry)
                island.Size = UDim2.new(0, base.X.Offset + math.abs(rx) * 0.12, 0, base.Y.Offset + math.abs(ry) * 0.10)
            end)
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
            if not isDragging then return end
            isDragging = false
            if dragConnection then dragConnection:Disconnect(); dragConnection = nil end
            local targetSize = isExpanded and EXPANDED_SIZE or COMPACT_SIZE
            TweenService:Create(island, TweenInfo.new(0.48, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Position = HOME_POSITION,
                Size = targetSize,
            }):Play()
            if dragDistance < 8 then
                if isExpanded then collapseIsland() else expandIsland() end
            end
        end)

        local phase = 0
        RunService.Heartbeat:Connect(function(dt)
            if not island.Parent then return end
            phase = (phase + dt * 3.2) % (math.pi * 2)
            local pulse = (math.sin(phase) + 1) * 0.5
            dot.Size = UDim2.fromOffset(9 + pulse * 3, 9 + pulse * 3)
            dot.Position = UDim2.new(0, 15 - pulse * 1.5, 0.5, -(9 + pulse * 3) / 2)
            dot.BackgroundTransparency = 0.05 + (1 - pulse) * 0.3
            statusAccent.BackgroundColor3 = statusColor
            gradient.Rotation = (gradient.Rotation + dt * 4) % 360
        end)

        paintStatus(currentStatus)
    end

    local function updateUI()
        if not ScreenGui or not ScreenGui.Parent or not MainCard or not MainCard.Parent then
            pcall(createUI)
            return
        end

        local roleText, roleColor
        if isMain then
            roleText, roleColor = "MAIN", C_PURPLE
        elseif isHopFM then
            roleText, roleColor = "HELPER (FM)", C_BLUE
        else
            roleText = "HELPER GR " .. tostring(MY_GROUP_IDX or "?")
            roleColor = Color3.fromRGB(100, 180, 255)
        end
        RolePill.Text = roleText
        RolePill.TextColor3 = roleColor
        CompactRole.Text = roleText
        CompactRole.TextColor3 = roleColor

        if isHelper then
            GroupPill.Text = tostring(MY_GROUP_NOTE or "?")
            GroupPill.TextColor3 = C_ORANGE
        elseif myAssignedGroupId and myAssignedGroupId ~= "" then
            GroupPill.Text = tostring(myAssignedGroupId)
            GroupPill.TextColor3 = C_GREEN
        else
            GroupPill.Text = "Assigning..."
            GroupPill.TextColor3 = C_MUTED
        end

        local hasFM = isNight() and isFullMoon()
        if hasFM then
            MoonLabel.Text = "FULL MOON · ACTIVE"
            MoonLabel.TextColor3 = C_GREEN
        else
            local moonText = ""
            pcall(function()
                if type(CheckMoon) == "function" then moonText = tostring(CheckMoon()) end
            end)
            if moonText == "" or moonText == "nil" then moonText = "No Full Moon" end
            MoonLabel.Text = moonText .. " · " .. string.format("%02d:%02d", math.floor(Lighting.ClockTime), math.floor((Lighting.ClockTime % 1) * 60))
            MoonLabel.TextColor3 = C_MUTED
        end

        paintStatus(currentStatus)
    end

    -- BOOT
    task.spawn(function()
        local ok, err = pcall(createUI)
        if not ok then
            warn("[JoinV4] Dynamic Island UI failed: " .. tostring(err))
        end
    end)
    pcall(function()
        if not Player:FindFirstChild("DataLoaded") then
            Player:WaitForChild("DataLoaded", 5)
        end
    end)
    setStatus("Loaded & Running")
    getgenv().JoinV4RuntimeStatus = "Loaded & Running"
    task.wait(0.5)

    task.spawn(function()
        while task.wait(0.4) do pcall(updateUI) end
    end)

    if not isHelper and not isMain then
        setStatus("Not in config - idle")
        return
    end

    -- HELPER: HOP FM LOOP
    if isHelper and isHopFM then
        task.spawn(function()
            task.wait(HOP_STARTUP_DELAY)
            local lastHopT   = ""
            local lastHopAt_ = 0
            local isFetching = false
            local takenJobIds        = {}
            local isHopping  = false   -- guard: khong retry khi dang teleport
            local lastConflictCheckAt = 0

            while task.wait(0.25) do
                local nowTick = tick()

                if isNight() and isFullMoon() then
                    local myGroupIdx = AllHopFMSet[USERNAME] or 999
                    local conflictWith = nil

                    if nowTick - lastConflictCheckAt >= SYNC_INTERVAL then
                        lastConflictCheckAt = nowTick
                        pcall(function()
                            local resp = syncToAPI()
                            takenJobIds = {}
                            if resp and resp.accounts then
                                for name, data in pairs(resp.accounts) do
                                    if AllHopFMSet[name] and name ~= USERNAME
                                        and AllHopFMSet[name] ~= myGroupIdx then
                                        local jid = tostring(data.jobid or data.jobId or "")
                                        if jid ~= "" then
                                            if jid == game.JobId then
                                                if AllHopFMSet[name] < myGroupIdx then
                                                    conflictWith = name
                                                end
                                            elseif jid ~= game.JobId then
                                                takenJobIds[jid] = name
                                            end
                                        end
                                    end
                                end
                            end
                        end)
                    end

                    if conflictWith then
                        warn("[JoinV4][HopFM] Conflict sau hop: " .. conflictWith
                            .. " (G" .. tostring(AllHopFMSet[conflictWith] or "?") .. ") cung o day"
                            .. " -> G" .. tostring(myGroupIdx) .. " roi di tim server khac")
                        fmJoinedCache[game.JobId] = os.time()
                        lastFmApiResult = nil
                        lastFmApiAt     = 0
                        lastHopT        = ""
                        setStatus("Conflict FM - tim server khac...")
                    else
                        setStatus("Full Moon - broadcasting...")
                        lastHopT = ""
                    end
                    task.wait(3); continue
                end
                if isPreFMReady() then
                    -- Kiem tra timetonight: neu > NEAR_MOON_MAX_TTN (300s) thi la fake moon -> hop di
                    if NEAR_MOON_ENABLED then
                        local ttn = getServerTimeToNight()
                        if ttn > NEAR_MOON_MAX_TTN then
                            warn("[JoinV4][HopFM] Near Moon fake: timetonight=" .. ttn .. "s > " .. NEAR_MOON_MAX_TTN .. "s -> hop away")
                            fmJoinedCache[game.JobId] = os.time()
                            lastFmApiResult = nil; lastFmApiAt = 0; lastHopT = ""
                            setStatus("Near Moon fake (" .. ttn .. "s) - tim server khac...")
                            task.wait(2); continue
                        end
                    end
                    setStatus("Pre-FM ready - waiting night (" .. getServerTimeToNight() .. "s)...")
                    task.wait(2); continue
                end

                if nowTick - lastConflictCheckAt >= SYNC_INTERVAL then
                    lastConflictCheckAt = nowTick
                    pcall(function()
                        local resp = syncToAPI()
                        takenJobIds = {}
                        if resp and resp.accounts then
                            for name, data in pairs(resp.accounts) do
                                if AllHopFMSet[name] and name ~= USERNAME
                                    and AllHopFMSet[name] ~= AllHopFMSet[USERNAME] then
                                    local jid = tostring(data.jobid or data.jobId or "")
                                    if jid ~= "" and jid ~= game.JobId then
                                        takenJobIds[jid] = name
                                    end
                                end
                            end
                        end
                    end)
                end

                if not isFetching and nowTick - lastFmApiAt >= FM_API_INTERVAL then
                    lastFmApiAt = nowTick; isFetching = true
                    task.spawn(function()
                        local found = findFMServer()
                        -- Fallback: neu FM API khong co server, thu Near Moon API
                        if not found and NEAR_MOON_ENABLED then
                            found = findNearMoonServer()
                            if found then
                                warn("[JoinV4][HopFM] Dung Near Moon server: " .. found:sub(1,8) .. "...")
                            end
                        end
                        if found and takenJobIds[found] then
                            warn("[JoinV4][HopFM] Server " .. found:sub(1,8) .. "... da bi " .. takenJobIds[found] .. " claim - tim server khac")
                            fmJoinedCache[found] = os.time()
                            lastFmApiResult = nil
                        else
                            lastFmApiResult = (found and found ~= game.JobId) and found or nil
                            if not lastFmApiResult then setStatus("No FM server, retrying...") end
                        end
                        isFetching = false
                    end)
                end

                if lastFmApiResult and lastFmApiResult ~= game.JobId then
                    local hopT = lastFmApiResult
                    if takenJobIds[hopT] then
                        warn("[JoinV4][HopFM] Truoc hop phat hien " .. takenJobIds[hopT] .. " dang o server nay - bo qua")
                        fmJoinedCache[hopT] = os.time()
                        lastFmApiResult = nil; lastHopT = ""
                    elseif hopT ~= lastHopT then
                        lastHopAt_ = nowTick; lastHopT = hopT
                        isHopping = true
                        setStatus("Hop FM: " .. hopT:sub(1,8) .. "...")
                        pcall(function() writefile("jv4_fmhop_pending.txt", "true") end)
                        task.spawn(function()
                            hopTo(hopT)
                            task.wait(12)   -- cho teleport hoan tat (toi da 12s)
                            isHopping = false
                        end)
                    else
                        if _failedHopJobId == hopT then
                            _failedHopJobId = ""
                            isHopping = false
                            lastFmApiResult = nil; lastFmApiAt = 0; lastHopT = ""
                        elseif isHopping then
                            setStatus("Teleporting to " .. hopT:sub(1,8) .. "...")
                        else
                            local el = nowTick - lastHopAt_
                            if el >= 10 then
                                setStatus("Hop timeout - try next server")
                                fmJoinedCache[hopT] = os.time() - (FM_CACHE_EXPIRE - 60)
                                lastFmApiResult = nil; lastFmApiAt = 0; lastHopT = ""
                            else
                                setStatus("Waiting teleport " .. hopT:sub(1,8) .. " (" .. math.floor(el) .. "s)...")
                            end
                        end
                    end
                end
            end
        end)
    end

    -- HELPER: SYNC STATUS + JOIN FM
    if isHelper then
        task.spawn(function()
            task.wait(HOP_STARTUP_DELAY + 1)
            pcall(function()
                if isfile("jv4_fmhop_pending.txt") and readfile("jv4_fmhop_pending.txt") == "true" then
                    fmHopPending = true
                    writefile("jv4_fmhop_pending.txt", "false")
                    fmPendingCheckAt = tick() + 20
                    setStatus("FM server settling...")
                end
            end)

            local lastHopTHelper  = ""
            local lastHopAtHelper = 0

            while task.wait(SYNC_INTERVAL) do
                pcall(function()
                    if fmHopPending and tick() < fmPendingCheckAt then
                        setStatus(string.format("Settling... %ds", math.ceil(fmPendingCheckAt - tick())))
                        return
                    end
                    fmHopPending = false
                    local hasFM = isNight() and isFullMoon()

                    local resp = syncToAPI()

                    if isHopFM then
                        setStatus(hasFM and "FM active - broadcast jobId" or "Waiting Full Moon...")
                        return
                    end

                    if not resp or not resp.accounts then
                        setStatus("Connecting...")
                        return
                    end

                    local fmJobId = nil
                    local fmWho   = nil
                    local hopFMFound = false   -- debug: co tim thay HopFM trong accounts khong
                    local hopFMFMState = "?"  -- debug: fullMoon cua HopFM la gi
                    local accCount = 0

                    for name, data in pairs(resp.accounts) do
                        accCount = accCount + 1
                        if MY_HopFMSet[name] and name ~= USERNAME then
                            hopFMFound = true
                            local helperHasFM  = (data.fullMoon  == true) or (data.fullmoon  == true)
                            local helperNearFM = (data.nearFM    == true) or (data.nearfm    == true)
                            hopFMFMState = tostring(data.fullMoon or data.fullmoon or "nil")
                            if helperHasFM then
                                local jid = tostring(data.jobid or data.jobId or "")
                                if jid ~= "" then
                                    fmJobId = jid; fmWho = name; break
                                end
                            elseif helperNearFM then
                                -- HopFM dang o near-moon server, follow vao de chuan bi
                                local jid = tostring(data.jobid or data.jobId or "")
                                if jid ~= "" and jid ~= game.JobId then
                                    fmJobId = jid; fmWho = name .. "[NearFM]"; break
                                end
                            end
                        end
                    end

                    if not fmJobId then
                        if hopFMFound then
                            setStatus("Waiting HopFM FM: " .. hopFMFMState .. " | acc=" .. accCount)
                        else
                            setStatus("HopFM not in group | acc=" .. accCount .. (hasFM and " [FM here]" or ""))
                        end
                        lastHopTHelper = ""; return
                    end

                    if fmJobId == game.JobId then
                        setStatus("In FM server with " .. (fmWho or "HopFM"))
                        lastHopTHelper = ""; return
                    end

                    local nowTick = tick()
                    if fmJobId ~= lastHopTHelper then
                        lastHopAtHelper = nowTick; lastHopTHelper = fmJobId
                        setStatus("Join " .. (fmWho or "HopFM") .. " -> " .. fmJobId:sub(1,8) .. "...")
                        hopTo(fmJobId); task.wait(0.5)
                    else
                        local el = nowTick - lastHopAtHelper
                        if el >= 8 then
                            warn("[JoinV4][Helper] hopTo timeout (8s) -> reset | target=" .. tostring(lastHopTHelper):sub(1,8))
                            setStatus("Hop timeout - retry")
                            lastHopTHelper = ""; lastHopAtHelper = 0
                        else
                            setStatus("Hopping -> " .. fmJobId:sub(1,8) .. " (" .. math.floor(el) .. "s)...")
                            hopTo(fmJobId); task.wait(0.5)
                        end
                    end
                end)
            end
        end)
    end

    -- MAIN: JOIN FM SERVER
    if isMain then
        task.spawn(function()
            task.wait(HOP_STARTUP_DELAY + 2)
            local lastHopTMain  = ""
            local lastHopAtMain = 0

            while task.wait(1.5) do
                pcall(function()
                    local resp = syncToAPI()
                    if resp and resp.group and type(resp.group.id) == "string" and resp.group.id ~= "" then
                        local assignedId = trim(resp.group.id)
                        for _, note in ipairs(noteList) do
                            if trim(note):lower() == assignedId:lower() then
                                myAssignedGroupId = trim(note)
                                break
                            end
                        end
                    end
                    if myAssignedGroupId == nil or myAssignedGroupId == "" then
                        myAssignedGroupId = myDefaultGroup or trim(noteList[1] or "group1")
                    end

                    if not resp or not resp.accounts then
                        setStatus("Connecting...")
                        return
                    end

                    updateV4Cache()
                    local v4s = _v4Cache

                    if v4s and v4s.needsTraining == false and v4s.needsPurchase == false then
                        rawset(getgenv(), "isCurrentlyTraining", nil)
                    end

                    local skipHop    = false
                    local skipReason = ""

                    if _v4CacheAt == 0 then
                        setStatus("Checking V4 status...")
                        lastHopTMain = ""; return
                    end

                    if v4s and v4s.needsTraining == true then
                        skipHop = true
                        skipReason = "Training (" .. tostring(v4s.key or "?") .. ") - skip join"

                    elseif v4s and v4s.needsPurchase == true then
                        skipHop = true
                        skipReason = "Buy Gear (" .. tostring(v4s.key or "?") .. ") - skip join"

                    elseif v4s and not v4s.complete and v4s.canTrial == false
                        and v4s.needsTraining == false and v4s.key ~= nil then
                        skipHop = true
                        skipReason = "V4 busy (" .. tostring(v4s.key) .. ") - skip join"

                    else
                        local me = resp.accounts[USERNAME]
                        if me then
                            local mySt = tostring(me.status or ""):lower()
                            if mySt == "training" or mySt == "buy gear" then
                                skipHop = true; skipReason = "Training (API: " .. mySt .. ") - skip join"
                            elseif me.needsTraining == true then
                                skipHop = true; skipReason = "Training (API flag) - skip join"
                            elseif me.needsPurchase == true then
                                skipHop = true; skipReason = "Buy Gear (API flag) - skip join"
                            end
                        else
                            -- Không có trong accounts → group đã full / chưa gán
                            -- Reset để sync tiếp theo tự assign group mới
                            myAssignedGroupId = ""
                            setStatus("Group full - reassigning...")
                            lastHopTMain = ""; return
                        end
                    end

                    if getgenv().JoinV4_skipHop == true then
                        skipHop = true; skipReason = "JoinV4_skipHop=true - paused"
                    end

                    if skipHop then
                        setStatus(skipReason)
                        lastHopTMain = ""; return
                    end

                    local myGroupHelpers = {}
                    local myGroupHopFMs  = {}

                    -- Ưu tiên lấy helpers của myAssignedGroupId từ local config
                    for i, helperList in ipairs(helperGroups) do
                        if type(helperList) == "table" then
                            local note = trim(noteList[i] or ("group" .. i))
                            if (myAssignedGroupId or ""):lower() == note:lower() then
                                for _, h in ipairs(helperList) do
                                    h = trim(tostring(h))
                                    if h ~= "" then
                                        myGroupHelpers[h] = true
                                        if AllHopFMSet[h] ~= nil then
                                            myGroupHopFMs[h] = true
                                        end
                                    end
                                end
                                break
                            end
                        end
                    end

                    -- Fallback nếu local config không tìm thấy
                    if next(myGroupHelpers) == nil and resp.group and resp.group.helpers then
                        for _, h in ipairs(resp.group.helpers) do
                            h = trim(tostring(h))
                            if h ~= "" then
                                myGroupHelpers[h] = true
                                if AllHopFMSet[h] ~= nil then
                                    myGroupHopFMs[h] = true
                                end
                            end
                        end
                    end

                    local fmJobId    = nil
                    local notReady   = {}
                    local helperTotal = 0

                    for name, _ in pairs(myGroupHelpers) do
                        helperTotal = helperTotal + 1
                        local data  = resp.accounts[name]
                        if not data then
                            table.insert(notReady, name .. "(no data)")
                        else
                            local helperHasFM = (data.fullMoon == true) or (data.fullmoon == true)
                            local jid = tostring(data.jobid or data.jobId or "")
                            if not helperHasFM or jid == "" then
                                table.insert(notReady, name .. "(no FM)")
                            elseif fmJobId == nil then
                                fmJobId = jid
                            elseif fmJobId ~= jid then
                                table.insert(notReady, name .. "(diff server)")
                            end
                        end
                    end

                    if not fmJobId then
                        setStatus("Waiting helpers FM...")
                        lastHopTMain = ""; return
                    end

                    if #notReady > 0 then
                        setStatus("Waiting " .. #notReady .. "/" .. helperTotal .. " helpers: " .. table.concat(notReady, ", "):sub(1, 40))
                        lastHopTMain = ""; return
                    end

                    if fmJobId == game.JobId then
                        setStatus("In FM server with all helpers")
                        lastHopTMain = ""; return
                    end

                    local nowTick = tick()
                    if fmJobId ~= lastHopTMain then
                        lastHopAtMain = nowTick; lastHopTMain = fmJobId
                        setStatus("Join FM (all helpers ready)...")
                        hopTo(fmJobId); task.wait(0.5)
                    else
                        local el = nowTick - lastHopAtMain
                        if el >= 8 then
                            setStatus("Join timeout - retry")
                            lastHopTMain = ""; lastHopAtMain = 0
                        else
                            setStatus("Retry join: " .. fmJobId:sub(1,8) .. "...")
                            hopTo(fmJobId); task.wait(0.5)
                        end
                    end

                end)
            end
        end)
    end

    local roleLog = "Main"
    if isHelper then
        roleLog = isHopFM
            and ("Helper+HopFM [G" .. (MY_GROUP_IDX or "?") .. "] grp=" .. (MY_GROUP_NOTE or "?"))
            or  ("Helper [G"       .. (MY_GROUP_IDX or "?") .. "] grp=" .. (MY_GROUP_NOTE or "?"))
    end
    print("[JoinV4] Loaded | " .. USERNAME .. " | " .. roleLog)
end)()
uiLibrary.CreateNoti({ Title = "Skider Hub V4", Desc = "Script loaded successfully", ShowTime = 5 })
