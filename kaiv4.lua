getgenv().Config = {
    ["Team"] = "Marines",
    ["Farm Fragments"] = { autoraid = false, autotyrant = false },
    ["Gear"] = "A-B-B",
    ["ChangeBestGear"] = true,
    ["V3 Door Distance"] = 50,
    ["API Base URL"] = "http://matrix.pikamc.vn:25932",
    ["V3 Countdown"] = 6,
    ["V3 File Poll"] = 0.10,
    ["V3 Ready Freshness"] = 2.0,
    ["V3 Require Different Races"] = true,
    ["V3 Fire Count"] = 1,
    ["V3 Fire Interval"] = 0.05,
    ["Pair Temple Timeout"] = 35,
    ["Pair Sticky Until Trial Complete"] = true,
    ["Pair Release After Trial"] = true,
    ["Pair Requeue Delay"] = 15,
    ["Pair Force Temple Interval"] = 0.8,
    ["Training Islands"] = { "Tiki Outpost", "Ice Cream Island", "Haunted Castle", "Great Tree", "Port Town", "Peanut Island" }
}

-- ============================================================
--   CẤU HÌNH GROUP HOP
--   Soluonggroup  = số group chạy song song tối đa
--   Group-1       = tên config group dùng (lookup Namegroup-...)
--   Namegroup-X   = danh sách 2 helper của group đó
-- ============================================================
getgenv().ConfigGroupHop = getgenv().ConfigGroupHop or {
    ["Soluonggroup"] = 1,
    ["Group-1"] = {"NhomA"},
    ["Namegroup-NhomA"] = {"ohhheh284", "hibrohfbd"},
    -- ["Group-2"] = {"NhomB"},
    -- ["Namegroup-NhomB"] = {"helper3", "helper4"},
}

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")
local CollectionService = game:GetService("CollectionService")

ReplicatedStorage:WaitForChild("MapStash"):WaitForChild("Temple of Time").Parent = workspace:WaitForChild("Map")

local Player = Players.LocalPlayer
local LocalPlayer = Players.LocalPlayer

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Net = Modules:WaitForChild("Net")
local RegisterAttack = Net:WaitForChild("RE/RegisterAttack")
local RegisterHit = Net:WaitForChild("RE/RegisterHit")
local ShootGunEvent = Net:WaitForChild("RE/ShootGunEvent")
local GunValidator = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Validator2")
local CommF_ = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

local cfg = getgenv().Config or {}
local team = cfg["Team"] or getgenv().Team or "Marines"
team = tostring(team)
if team == "Pirate" then team = "Pirates" end
if team ~= "Marines" and team ~= "Pirates" then team = "Marines" end

repeat
    pcall(function() CommF_:InvokeServer("SetTeam", team) end)
    task.wait(1)
until Player.Team and Player.Team.Name == team
task.wait(2)

if workspace:GetAttribute("MAP") and workspace:GetAttribute("MAP") ~= "Sea3" then
    ReplicatedStorage.Remotes.CommF_:InvokeServer("TravelZou")
end

if not isfile("cache_iron.json") then writefile("cache_iron.json", "{}") end
local ok, cache = pcall(function() return HttpService:JSONDecode(readfile("cache_iron.json")) end)
if not ok then cache = {} end
cache[game.JobId] = math.floor(tick())
writefile("cache_iron.json", HttpService:JSONEncode(cache))

getgenv().TyrantConfig = getgenv().TyrantConfig or {
    Team = "Marines",
    Weapon = "Dragon Talon",
    AutoBuyDragonTalon = true,
    AutoBuso = true,
    TweenSpeed = 330,
    FarmHeight = 18,
    BossHeight = 25,
    AttackDistance = 105,
    AttackDelay = 0.03,
    BringMobs = true
}

if not getgenv().Config then
    getgenv().Config = {
        ["Team"] = "Marines",
        ["ChangeBestGear"] = true,
        ["Gear"] = "A-B-B",
        ["Farm Fragments"] = { autoraid = false, autotyrant = true },
        ["V3 Door Distance"] = 50,
        ["API Base URL"] = "http://localhost:3000",
        ["V3 Countdown"] = 6,
        ["V3 File Poll"] = 0.10,
        ["V3 Ready Freshness"] = 2.0,
        ["V3 Require Different Races"] = true,
        ["V3 Fire Count"] = 1,
        ["V3 Fire Interval"] = 0.05,
        ["Pair Temple Timeout"] = 35,
        ["Pair Sticky Until Trial Complete"] = true,
        ["Pair Release After Trial"] = true,
        ["Pair Requeue Delay"] = 15,
        ["Pair Force Temple Interval"] = 0.8,
        ["Training Islands"] = { "Tiki Outpost", "Ice Cream Island", "Haunted Castle", "Great Tree", "Port Town", "Peanut Island" }
    }
end

local bestGearForRace = {
    Ghoul = "B-B-A", Cyborg = "A-B-B", Mink = "B-B-A",
    Skypiea = "B-B-A", Human = "B-A-A", Fishman = "B-A-A"
}

if not getgenv().Config["Gear"] or #getgenv().Config["Gear"] ~= 5 then
    getgenv().Config["Gear"] = getgenv().Config["Gear"] or "A-B-B"
end

-- ============================================================
--   WHITELIST MAIN / HELP THEO USERNAME
--   Paste tên acc vào giữa [[ ]], MỖI TÊN 1 DÒNG
--   Không cần dấu phẩy, không cần ngoặc kép
--
--   QUAN TRỌNG: rawMainList có thể chứa NHIỀU tên (nhiều acc có thể
--   làm Main), nhưng chỉ acc đứng ĐẦU TIÊN trong list MÀ ĐANG CÓ MẶT
--   trong server mới được active làm Main thật. Các acc Main khác
--   (có tên trong whitelist nhưng không phải acc ưu tiên cao nhất
--   đang có mặt) sẽ tự lùi xuống đóng vai Help cho Main đang active,
--   tránh tình trạng 2 acc cùng nhận mình là Main.
-- ============================================================
local isUper = false
local isAlly = false
local mainAccountName = ""
local isMain = false
local isallies = {}

local MainPriorityList = {}
local HelpWhitelist = {}

do
    -- Helper whitelist lấy từ ConfigGroupHop: gộp tất cả Namegroup-* lại
    -- Bất kỳ tên nào không có trong danh sách helper → 100% được coi là mainup
    local ghConfig = getgenv().ConfigGroupHop or {}
    local soluonggroup = tonumber(ghConfig["Soluonggroup"]) or 1

    for i = 1, soluonggroup do
        local groupKey      = "Group-" .. i
        local groupNameList = ghConfig[groupKey] or {}
        for _, groupName in ipairs(groupNameList) do
            local helpersKey = "Namegroup-" .. groupName
            for _, helperName in ipairs(ghConfig[helpersKey] or {}) do
                helperName = tostring(helperName):gsub("^%s+", ""):gsub("%s+$", "")
                if helperName ~= "" then
                    HelpWhitelist[helperName] = true
                end
            end
        end
    end
end

getgenv().UpdateRoles = function()
    -- Logic mới: nếu tên hiện tại nằm trong HelpWhitelist (lấy từ ConfigGroupHop)
    -- → role = helper. Ngược lại, 100% là mainup.
    if HelpWhitelist[Player.Name] == true then
        -- Acc là helper - tìm main hiện tại trong server từ ConfigGroupHop
        local ghConfig      = getgenv().ConfigGroupHop or {}
        local soluonggroup  = tonumber(ghConfig["Soluonggroup"]) or 1
        local foundMain     = ""
        -- Dượt qua các group, tìm main nào đang có mặt trong server
        -- (main = bất kỳ player nào không có trong HelpWhitelist)
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= Player and not HelpWhitelist[p.Name] then
                foundMain = p.Name
                break
            end
        end
        isUper = false
        isAlly = true
        mainAccountName = foundMain
    else
        -- Acc không có trong helper list → 100% được coi là mainup
        isUper = true
        isAlly = false
        mainAccountName = Player.Name
    end

    isMain = isUper

    -- Cập nhật danh sách đồng minh
    isallies = {}
    if isUper then
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name ~= Player.Name and HelpWhitelist[p.Name] then
                isallies[p.Name] = true
            end
        end
    elseif isAlly then
        if mainAccountName ~= "" then isallies[mainAccountName] = true end
    end
end

-- Chạy lần đầu tiên
getgenv().UpdateRoles()

getgenv().Config["Team"] = getgenv().Config["Team"]
    and (getgenv().Config["Team"] == "Marines" or getgenv().Config["Team"] == "Pirates")
    and getgenv().Config["Team"] or "Marines"

function thuaaa()
    if Player.Team then return end
    if getgenv().Team == "Marines" or not getgenv().Team then
        ReplicatedStorage.Remotes.CommF_:InvokeServer("SetTeam", "Marines")
    elseif getgenv().Team == "Pirates" then
        ReplicatedStorage.Remotes.CommF_:InvokeServer("SetTeam", "Pirates")
    end
end

if getgenv().Team == "Marines" or not getgenv().Team then
    thuaaa()
elseif getgenv().Team == "Pirates" then
    thuaaa()
end

task.spawn(function()
    while task.wait() do
        local char = Player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local bv = hrp:FindFirstChild("BodyClip")
            if not bv then
                bv = Instance.new("BodyVelocity")
                bv.Name = "BodyClip"
                bv.Parent = hrp
                bv.MaxForce = Vector3.new(100000, 100000, 100000)
            end
            bv.Velocity = Vector3.new(0, 0, 0)
        end
    end
end)

local L_207_ = Player:WaitForChild("PlayerGui"):FindFirstChild("ChooseTeam", true)
local L_208_ = Player:WaitForChild("PlayerGui"):FindFirstChild("UIController", true)
if L_207_ and L_207_.Visible then
    repeat
        task.wait(1)
        if L_207_ and L_207_.Visible and L_208_ then
            for _, f in pairs(getgc(true)) do
                if type(f) == "function" and getfenv(f).script == L_208_ then
                    local c = getconstants(f)
                    pcall(function()
                        if (c[1] == "Pirates" or c[1] == "Marines") and #c == 1 then
                            if c[1] == getgenv().Team then f(getgenv().Team) end
                        end
                    end)
                end
            end
        end
    until Player.Team
end

for i, v in pairs(Player.PlayerGui:GetChildren()) do
    if v:FindFirstChild("ChooseTeam") then
        local thua = v.ChooseTeam.Container[getgenv().Config["Team"]].Frame.TextButton
        firesignal(thua.Activated)
    end
end

local module = {}
repeat task.wait() until game:IsLoaded() and Player

local toidangkiemtraloadingscreen = tick()
repeat
    task.wait()
    if tick() - toidangkiemtraloadingscreen > 5 then
        ReplicatedStorage.__ServerBrowser:InvokeServer("teleport", game.JobId)
    end
until not Player.PlayerGui:FindFirstChild("LoadingScreen")

local player = Player
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")

function module:eq()
    for _, L in pairs(player.Backpack:GetChildren()) do
        if L:IsA("Tool") and L["ToolTip"] == "Melee" and not _G.USESWORD then
            local a = pcall(function() player.Character.Humanoid:EquipTool(L) end)
            if a then break end
        elseif L:IsA("Tool") and L["ToolTip"] == "Sword" and _G.USESWORD then
            local a = pcall(function() player.Character.Humanoid:EquipTool(L) end)
            if a then break end
        end
    end
end

function module:haki()
    if not player.Character:FindFirstChild("HasBuso") then
        ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso")
    end
end

function module:topos(targetCFrame, v36)
    pcall(function() if not v36 then player.Character.Humanoid.Sit = false end end)
    local char__ = player.Character or player.CharacterAdded:Wait()
    local hrp__ = char__:WaitForChild("HumanoidRootPart")
    local distance = (hrp__.Position - targetCFrame.Position).Magnitude
    local speed = distance / 300
    local tweenInfo = TweenInfo.new(speed, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    local tween = TweenService:Create(hrp__, tweenInfo, { CFrame = targetCFrame })
    tween:Play()
    return tween
end

function module:join(v2)
    v2 = v2 and (v2 == "Marines" or v2 == "Pirates") and v2 or "Marines"
    for i, v in pairs(player.PlayerGui:GetChildren()) do
        if v:FindFirstChild("ChooseTeam") then
            local thua = v.ChooseTeam.Container[v2].Frame.TextButton
            firesignal(thua.Activated)
        end
    end
end

function module:tele(v)
    if v then
        ReplicatedStorage.__ServerBrowser:InvokeServer("teleport", v)
    else
        ReplicatedStorage.__ServerBrowser:InvokeServer("teleport", game.JobId)
    end
end

function module:noclip(v)
    spawn(function()
        while task.wait(0.1) do
            if loadstring(v)() and not player.Character.Humanoid.Sit then
                if not player.Character.HumanoidRootPart:FindFirstChild("BodyClip") then
                    local L_348_ = Instance.new("BodyVelocity")
                    L_348_["Name"] = "BodyClip"
                    L_348_["Parent"] = player.Character.HumanoidRootPart
                    L_348_["MaxForce"] = Vector3.new(100000, 100000, 100000)
                    L_348_["Velocity"] = Vector3.new(0, 0, 0)
                end
                for _, d in pairs(player.Character:GetDescendants()) do
                    if d:IsA("BasePart") then d["CanCollide"] = false end
                end
            else
                pcall(function() player.Character.HumanoidRootPart:FindFirstChild("BodyClip"):Destroy() end)
            end
        end
    end)
end

function module:getdis(x, y)
    y = y or player.Character.HumanoidRootPart.CFrame
    return (x.Position - y.Position).Magnitude
end

player.Idled:connect(function()
    game:GetService("VirtualUser"):Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    game:GetService("VirtualUser"):Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
end)

local topofgreattree = CFrame.new(3035.15137, 2281.15918, -7325.19189)

function getdoor(vv)
    vv = vv or player.Data.Race.Value
    local temple = workspace.Map:FindFirstChild("Temple of Time")
    if not temple then return nil end
    local corridor = temple:FindFirstChild(vv .. "Corridor")
    if not corridor then return nil end
    local door = corridor:FindFirstChild("Door")
    if not door then return nil end
    return door:FindFirstChild("Entrance")
end

function getdis(...) return module:getdis(...) end

local topos = function(v)
    pcall(function()
        if getdis(v) > 2500 and getdis(CFrame.new(28310.0234, 14895.1123, 109.456741)) < 1500 then
        end
    end)
    return module:topos(v)
end

local pos_plr_trial = {
    CFrame.new(28692.3477, 14887.5605, -53.7669983),
    CFrame.new(28782.7246, 14898.9902, -59.6069946),
    CFrame.new(28700.875, 14888.2598, -154.110992),
    CFrame.new(28795.7715, 14888.2598, -112.917999),
    CFrame.new(28658.4551, 14888.2598, -121.372009),
    CFrame.new(28742.4688, 14887.5596, -18.2120056)
}

function isplrshouldkill(plr)
    if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
        and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
        for i, v in pairs(pos_plr_trial) do
            if getdis(plr.Character.HumanoidRootPart.CFrame, v) < 5 then return true end
        end
    end
    return false
end

local race_abilities = {
    ["Human"] = "Last Resort",
    ["Mink"] = "Agility",
    ["Fishman"] = "Water Body",
    ["Skypiea"] = "Heavenly Blood",
    ["Ghoul"] = "Heightened Senses",
    ["Cyborg"] = "Energy Core"
}

local races_trial_place = {
    ["Human"] = workspace._WorldOrigin.Locations:WaitForChild("Trial of Strength"),
    ["Mink"] = workspace._WorldOrigin.Locations:WaitForChild("Trial of Speed"),
    ["Fishman"] = workspace._WorldOrigin.Locations:WaitForChild("Trial of Water"),
    ["Skypiea"] = workspace._WorldOrigin.Locations:WaitForChild("Trial of the King"),
    ["Ghoul"] = workspace._WorldOrigin.Locations:WaitForChild("Trial of Carnage"),
    ["Cyborg"] = workspace._WorldOrigin.Locations:WaitForChild("Trial of the Machine")
}

_G.playersinserver = {}
function updateplayers()
    if not _G.playersinserver then _G.playersinserver = {} end
    local players = {}
    for i, v in pairs(game.Players:GetChildren()) do
        players[v] = {
            ["Race"] = v.Data.Race.Value,
            ["Door"] = (function()
                local x, y = pcall(function()
                    return workspace.Map["Temple of Time"]:WaitForChild(v.Data.Race.Value .. "Corridor"):WaitForChild("Door"):WaitForChild("Entrance")
                end)
                if x then return y end
                return nil
            end)()
        }
    end
    _G.playersinserver = players
end

function isshouldturnonability()
    local count = 0
    for i, v in pairs(workspace.Characters:GetChildren()) do
        if v.Name ~= player.Name and v:FindFirstChild("HumanoidRootPart") then
            local theirrace = game.Players:FindFirstChild(v.Name).Data.Race.Value
            local corridor = workspace.Map["Temple of Time"]:FindFirstChild(theirrace .. "Corridor")
            local race_door = corridor and corridor:FindFirstChild("Door")
            race_door = race_door and race_door:FindFirstChild("Entrance")
            local abilityName = race_abilities[theirrace]
            if race_door and abilityName and getdis(race_door.CFrame, v.HumanoidRootPart.CFrame) < 10 then
                if v.HumanoidRootPart:FindFirstChild(abilityName) then
                    count = count + 1
                end
            end
        end
    end
    return count >= 2
end

local v4Started = false
function talktoonggianaodo()
    if v4Started then return end
    v4Started = true
    local thua = ReplicatedStorage.Remotes.CommF_:InvokeServer("RaceV4Progress", "Check")
    if thua == 1 then
        ReplicatedStorage.Remotes.CommF_:InvokeServer("RaceV4Progress", "Check")
        ReplicatedStorage.Remotes.CommF_:InvokeServer("RaceV4Progress", "Begin")
    elseif thua == 2 then
        repeat
            task.wait()
            ReplicatedStorage.Remotes.CommF_:InvokeServer("RaceV4Progress", "Teleport")
            topos(CFrame.new(3028, 2281, -7325))
        until module:getdis(CFrame.new(28286.35546875, 14896.5078125, 102.62469482422)) <= 15
    else
        ReplicatedStorage.Remotes.CommF_:InvokeServer("RaceV4Progress", "Check")
        task.wait(1)
        ReplicatedStorage.Remotes.CommF_:InvokeServer("RaceV4Progress", "Continue")
    end
    v4Started = false
end

function getBlueGear()
    if not game.workspace.Map:FindFirstChild("MysticIsland") then return nil end
    for o, c in pairs(game.workspace.Map.MysticIsland:GetChildren()) do
        if c:IsA("MeshPart") and c.MeshId == "rbxassetid://10153114969" then return c end
    end
end

function isnight()
    local c = game.Lighting.ClockTime
    return c >= 16 or c < 5
end

function isfullmoon()
    return game:GetService("Lighting"):GetAttribute("MoonPhase") == 5
end

module:noclip([[return true]])

function getmob1(pos)
    local allmobs = {}
    for i, v in pairs(workspace.Enemies:GetChildren()) do
        if v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid")
            and v.Humanoid.Health > 0 and getdis(v.HumanoidRootPart.CFrame, pos) < 1000 then
            table.insert(allmobs, v)
        end
    end
    return allmobs
end

function checkmob_(v)
    return v and v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0
end

function noideaforname(v)
    if isallies[v.Name] then return false end
    return true
end

function getplayers(all)
    local plrs = {}
    for i, v in pairs(game.Players:GetPlayers()) do
        if v ~= player and v.Character then
            if all then
                if v.Character:FindFirstChild("Humanoid") and v.Character:FindFirstChild("HumanoidRootPart") and v.Character.Humanoid.Health > 0 then
                    for _, pos in pairs(pos_plr_trial) do
                        if getdis(v.Character.HumanoidRootPart.CFrame, pos) < 10 then plrs[v.Character] = true end
                    end
                end
            else
                if v ~= game.Players:FindFirstChild(mainAccountName) and noideaforname(v) then
                    if v.Character:FindFirstChild("Humanoid") and v.Character:FindFirstChild("HumanoidRootPart") and v.Character.Humanoid.Health > 0 then
                        for _, pos in pairs(pos_plr_trial) do
                            if getdis(v.Character.HumanoidRootPart.CFrame, pos) < 10 then plrs[v.Character] = true end
                        end
                    end
                end
            end
        end
    end
    return plrs
end

function checkbackpack(v)
    return player.Backpack:FindFirstChild(v) or player.Character:FindFirstChild(v)
end

local V4StatusCache = { at = 0, data = nil }
local V4_STATUS_CACHE_TIME = 0.75

function getLocalRaceName()
    local race = "Unknown"
    pcall(function() race = tostring(Players.LocalPlayer.Data.Race.Value) end)
    return race
end

function invokeUpgradeRace(action)
    return CommF_:InvokeServer("UpgradeRace", action)
end

function invalidateV4Status()
    V4StatusCache.at = 0
    V4StatusCache.data = nil
end

function readRaceV4Progress()
    local ok, progress = pcall(function()
        return CommF_:InvokeServer("RaceV4Progress", "Check")
    end)
    if ok then return tonumber(progress) end
    return nil
end

function getV4Status(forceRefresh)
    if not forceRefresh and V4StatusCache.data and tick() - V4StatusCache.at < V4_STATUS_CACHE_TIME then
        return V4StatusCache.data
    end

    local state = {
        key = "unknown", 
        label = "UNKNOWN",
        detail = "Unable to read Race V4 status",
        code = nil, 
        progress = nil, 
        cost = 0,
        canTrial = false, 
        needsTraining = false, 
        needsPurchase = false, 
        complete = false,
        remainingTraining = nil, 
        completedTraining = nil, 
        gear = nil,
        race = getLocalRaceName(), 
        energy = 0, 
        transformed = false
    }

    local character = Players.LocalPlayer.Character
    if not character then
        state.key = "waiting_character"
        state.label = "WAITING CHARACTER"
        state.detail = "Waiting for character to load"
        V4StatusCache.at = tick()
        V4StatusCache.data = state
        return state
    end

    local raceEnergy = character:FindFirstChild("RaceEnergy")
    local raceTransformed = character:FindFirstChild("RaceTransformed")
    if raceEnergy then state.energy = tonumber(raceEnergy.Value) or 0 end
    if raceTransformed then state.transformed = raceTransformed.Value == true end

    if not raceTransformed then
        local progress = readRaceV4Progress()
        local abilityName = race_abilities[state.race]
        local hasV3Ability = abilityName and checkbackpack(abilityName) ~= nil
        state.progress = progress

        if progress == nil then
            state.key = "check_failed"
            state.label = "V4 CHECK FAILED"
            state.detail = "RaceV4Progress Check returned no valid status"
        elseif hasV3Ability and progress >= 4 then
            state.key = "first_trial_ready"
            state.label = "FIRST TRIAL READY"
            state.detail = "V3 is ready; waiting for Full Moon trial"
            state.canTrial = true
        elseif progress == 0 then
            state.key = "v4_quest_not_started"
            state.label = "V4 QUEST NOT STARTED"
            state.detail = "Defeat rip_indra and begin the Race V4 quest"
        elseif progress == 1 then
            state.key = "v4_quest_begin"
            state.label = "BEGIN V4 QUEST"
            state.detail = "Talk to Sealed King to begin the Great Tree step"
        elseif progress == 2 then
            state.key = "go_great_tree"
            state.label = "GO TO GREAT TREE"
            state.detail = "Use the Great Tree entrance to reach Temple of Time"
        elseif progress == 3 then
            state.key = "continue_v4_quest"
            state.label = "CONTINUE V4 QUEST"
            state.detail = "Return to Sealed King and continue the quest"
        elseif progress == 4 or progress == 5 then
            state.key = "first_trial_preparation"
            state.label = "FIRST TRIAL PREPARATION"
            state.detail = hasV3Ability and "V3 detected; preparing first trial" or "V3 ability was not detected"
            state.canTrial = hasV3Ability
        else
            state.key = "starting_v4"
            state.label = "STARTING V4 PROCESS"
            state.detail = "Completing the Race V4 prerequisite steps"
        end

        V4StatusCache.at = tick()
        V4StatusCache.data = state
        return state
    end

    local ok, code, progress, cost = pcall(function()
        return invokeUpgradeRace("Check")
    end)
    if not ok then
        state.key = "check_failed"
        state.label = "V4 CHECK FAILED"
        state.detail = "UpgradeRace Check remote failed"
        V4StatusCache.at = tick()
        V4StatusCache.data = state
        return state
    end

    code = tonumber(code)
    progress = tonumber(progress)
    cost = tonumber(cost) or 0
    state.code = code
    state.progress = progress
    state.cost = cost

    if code == 0 then
        state.key = "trial_ready"
        state.label = "READY FOR TRIAL"
        state.detail = "Training requirement completed"
        state.canTrial = true
        state.gear = progress
    elseif code == 1 then
        state.key = "training_stage_1"
        state.label = "TRAINING REQUIRED"
        state.detail = "Train Race V4 energy before the next upgrade"
        state.needsTraining = true
    elseif code == 2 then
        state.key = "buy_gear_1"
        state.label = "BUY NEXT GEAR"
        state.detail = "First Race V4 gear upgrade is available"
        state.needsPurchase = true
    elseif code == 3 then
        state.key = "training_stage_2"
        state.label = "TRAINING REQUIRED"
        state.detail = "Train again to improve transformation duration"
        state.needsTraining = true
    elseif code == 4 then
        state.key = "buy_duration_upgrade"
        state.label = "BUY DURATION UPGRADE"
        state.detail = "Transformation limit upgrade is available"
        state.needsPurchase = true
    elseif code == 5 then
        state.key = "completed"
        state.label = "RACE V4 COMPLETED"
        state.detail = "All Race V4 upgrades are complete"
        state.complete = true
    elseif code == 6 then
        local completed = math.clamp((progress or 2) - 2, 0, 3)
        local remaining = math.max(0, 3 - completed)
        state.key = "three_session_training"
        state.label = remaining > 0 and "TRAINING REQUIRED" or "TRAINING CHECKING"
        state.completedTraining = completed
        state.remainingTraining = remaining
        state.detail = "Additional sessions: " .. tostring(completed) .. "/3 completed"
        state.needsTraining = remaining > 0
    elseif code == 7 then
        state.key = "buy_next_upgrade"
        state.label = "BUY NEXT UPGRADE"
        state.detail = "The next Race V4 upgrade is available"
        state.needsPurchase = true
    elseif code == 8 then
        local remaining = math.max(0, 10 - (progress or 0))
        state.key = "mastery_training"
        state.label = remaining > 0 and "MASTERY TRAINING" or "MASTERY COMPLETE"
        state.remainingTraining = remaining
        state.completedTraining = math.clamp(progress or 0, 0, 10)
        state.detail = remaining > 0
            and (tostring(remaining) .. " mastery training sessions remaining")
            or "All optional mastery sessions are complete"
        state.needsTraining = remaining > 0
        state.complete = remaining <= 0
    elseif code == 9 then
        state.key = "special_race_path"
        state.label = "SPECIAL RACE PATH"
        state.detail = "This race uses a different V4 upgrade path"
    else
        state.key = "not_ready"
        state.label = "NOT TRIAL READY"
        state.detail = "Unknown UpgradeRace state: " .. tostring(code)
    end

    -- BẢN FIX MẠNH NHẤT: Bịp script, ép acc Help phải làm đệ dù Max V4
    if isAlly then
        state.complete = false
        state.canTrial = true
        state.needsPurchase = false
        state.needsTraining = false
        state.key = "trial_ready"
        state.label = "READY FOR TRIAL"
        state.detail = "Helper is ready to support"
    end
    --[[
    if npcText:match("train") or npcText:match("mastery") or npcText:match("use your powers") then
        state.needsTraining = true
        state.canTrial = false
        state.needsPurchase = false
        state.label = "NEEDS TRAINING"
    end]]
    V4StatusCache.at = tick()
    V4StatusCache.data = state
    return state
end

function getdialogoftemple()
    return getV4Status(true).detail
end

function trialable(forceRefresh)
    local state = getV4Status(forceRefresh == true)
    if isAlly then
        return true, state.gear or 5
    end

    if state.canTrial then
        return true, state.gear
    end
    if state.complete then
        return false, "completed"
    end
    if state.needsPurchase then
        local fragments = 0
        pcall(function() fragments = tonumber(Players.LocalPlayer.Data.Fragments.Value) or 0 end)
        if state.cost > 0 and fragments >= state.cost then
            local ok, bought = pcall(function()
                return invokeUpgradeRace("Buy")
            end)
            invalidateV4Status()
            if ok and bought then return false, "upgrade_bought" end
            return false, "buy_failed"
        end
        return false, "raiding"
    end
    if state.needsTraining then
        return false, 
        state.remainingTraining or "training"
    end
    return false, 
    state.key
end

local AttackConfig = {
    AttackDistance = 1000000, AttackMobs = true, AttackPlayers = true,
    AttackCooldown = 0.2, ComboResetTime = 0.3, MaxCombo = 4,
    HitboxLimbs = { "RightLowerArm", "RightUpperArm", "LeftLowerArm", "LeftUpperArm", "RightHand", "LeftHand" },
    AutoClickEnabled = true
}

local FastAttack = {}
FastAttack.__index = FastAttack

function FastAttack.new()
    local self = setmetatable({
        Debounce = 0, ComboDebounce = 0, ShootDebounce = 0, M1Combo = 0,
        EnemyRootPart = nil, Connections = {},
        Overheat = { Dragonstorm = { MaxOverheat = 3, Cooldown = 0, TotalOverheat = 0, Distance = 350, Shooting = false } },
        ShootsPerTarget = { ["Dual Flintlock"] = 2 },
        SpecialShoots = { ["Skull Guitar"] = "TAP", ["Bazooka"] = "Position", ["Cannon"] = "Position", ["Dragonstorm"] = "Overheat" }
    }, FastAttack)
    pcall(function()
        self.CombatFlags = require(Modules.Flags).COMBAT_REMOTE_THREAD
        self.ShootFunction = getupvalue(require(ReplicatedStorage.Controllers.CombatController).Attack, 9)
        local LocalScript = Player:WaitForChild("PlayerScripts"):FindFirstChildOfClass("LocalScript")
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

function FastAttack:CheckStun(Character, Humanoid, ToolTip)
    local Stun = Character:FindFirstChild("Stun")
    local Busy = Character:FindFirstChild("Busy")
    if Humanoid.Sit and (ToolTip == "Sword" or ToolTip == "Melee" or ToolTip == "Blox Fruit") then
        return false
    elseif Stun and Stun.Value > 0 or Busy and Busy.Value then
        return false
    end
    return true
end

function FastAttack:GetBladeHits(Character, Distance)
    local Position = Character:GetPivot().Position
    local BladeHits = {}
    Distance = Distance or AttackConfig.AttackDistance
    function ProcessTargets(Folder)
        for _, Enemy in ipairs(Folder:GetChildren()) do
            pcall(function()
                if Enemy ~= Character and self:IsEntityAlive(Enemy) then
                    local BasePart = Enemy:FindFirstChild(AttackConfig.HitboxLimbs[math.random(#AttackConfig.HitboxLimbs)]) or Enemy:FindFirstChild("HumanoidRootPart")
                    if BasePart and (Position - BasePart.Position).Magnitude <= Distance then
                        if not self.EnemyRootPart then
                            self.EnemyRootPart = BasePart
                        else
                            table.insert(BladeHits, { Enemy, BasePart })
                            table.insert(BladeHits, {})
                        end
                    end
                end
            end)
        end
    end
    if AttackConfig.AttackMobs then pcall(ProcessTargets, Workspace:WaitForChild("Enemies")) end
    if AttackConfig.AttackPlayers then pcall(ProcessTargets, Workspace:WaitForChild("Characters")) end
    return BladeHits
end

function FastAttack:GetClosestEnemy(Character, Distance)
    local BladeHits = self:GetBladeHits(Character, Distance)
    local Closest, MinDistance = nil, math.huge
    for _, Hit in ipairs(BladeHits) do
        local Magnitude = (Character:GetPivot().Position - Hit[2].Position).Magnitude
        if Magnitude < MinDistance then MinDistance = Magnitude; Closest = Hit[2] end
    end
    return Closest
end

function FastAttack:GetCombo()
    local Combo = (tick() - self.ComboDebounce) <= AttackConfig.ComboResetTime and self.M1Combo or 0
    Combo = Combo >= AttackConfig.MaxCombo and 1 or Combo + 1
    self.ComboDebounce = tick()
    self.M1Combo = Combo
    return Combo
end

function FastAttack:ShootInTarget(TargetPosition)
    local Character = Player.Character
    if not self:IsEntityAlive(Character) then return end
    local Equipped = Character:FindFirstChildOfClass("Tool")
    if not Equipped or Equipped.ToolTip ~= "Gun" then return end
    local Cooldown = Equipped:FindFirstChild("Cooldown") and Equipped.Cooldown.Value or 0.3
    if (tick() - self.ShootDebounce) < Cooldown then return end
    local ShootType = self.SpecialShoots[Equipped.Name] or "Normal"
    if ShootType == "Position" or (ShootType == "TAP" and Equipped:FindFirstChild("RemoteEvent")) then
        Equipped:SetAttribute("LocalTotalShots", (Equipped:GetAttribute("LocalTotalShots") or 0) + 1)
        GunValidator:FireServer(self:GetValidator2())
        if ShootType == "TAP" then
            Equipped.RemoteEvent:FireServer("TAP", TargetPosition)
        else
            ShootGunEvent:FireServer(TargetPosition)
        end
        self.ShootDebounce = tick()
    else
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
        self.ShootDebounce = tick()
    end
end

function FastAttack:GetValidator2()
    local v1 = getupvalue(self.ShootFunction, 15)
    local v2 = getupvalue(self.ShootFunction, 13)
    local v3 = getupvalue(self.ShootFunction, 16)
    local v4 = getupvalue(self.ShootFunction, 17)
    local v5 = getupvalue(self.ShootFunction, 14)
    local v6 = getupvalue(self.ShootFunction, 12)
    local v7 = getupvalue(self.ShootFunction, 18)
    local v8 = v6 * v2
    local v9 = (v5 * v2 + v6 * v1) % v3
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

function FastAttack:UseNormalClick(Character, Humanoid, Cooldown)
    self.EnemyRootPart = nil
    local BladeHits = self:GetBladeHits(Character)
    if self.EnemyRootPart then
        RegisterAttack:FireServer(Cooldown)
        if self.CombatFlags and self.HitFunction then
            self.HitFunction(self.EnemyRootPart, BladeHits)
        else
            RegisterHit:FireServer(self.EnemyRootPart, BladeHits)
        end
    end
end

function FastAttack:UseFruitM1(Character, Equipped, Combo)
    local Targets = self:GetBladeHits(Character)
    if not Targets[1] then return end
    local Direction = (Targets[1][2].Position - Character:GetPivot().Position).Unit
    Equipped.LeftClickRemote:FireServer(Direction, Combo)
end

function FastAttack:Attack()
    if not AttackConfig.AutoClickEnabled or (tick() - self.Debounce) < AttackConfig.AttackCooldown then return end
    local Character = Player.Character
    if not Character or not self:IsEntityAlive(Character) then return end
    local Humanoid = Character.Humanoid
    local Equipped = Character:FindFirstChildOfClass("Tool")
    if not Equipped then return end
    local ToolTip = Equipped.ToolTip
    if not table.find({ "Melee", "Blox Fruit", "Sword", "Gun" }, ToolTip) then return end
    local Cooldown = Equipped:FindFirstChild("Cooldown") and Equipped.Cooldown.Value or AttackConfig.AttackCooldown
    if not self:CheckStun(Character, Humanoid, ToolTip) then return end
    local Combo = self:GetCombo()
    Cooldown = Cooldown + (Combo >= AttackConfig.MaxCombo and 0.05 or 0)
    self.Debounce = Combo >= AttackConfig.MaxCombo and ToolTip ~= "Gun" and (tick() + 0.05) or tick()
    if ToolTip == "Blox Fruit" and Equipped:FindFirstChild("LeftClickRemote") then
        self:UseFruitM1(Character, Equipped, Combo)
    elseif ToolTip == "Gun" then
        local Target = self:GetClosestEnemy(Character, 120)
        if Target then self:ShootInTarget(Target.Position) end
    else
        self:UseNormalClick(Character, Humanoid, Cooldown)
    end
end

local AttackInstance = FastAttack.new()
table.insert(AttackInstance.Connections, RunService.Stepped:Connect(function()
    module:haki()
    AttackInstance:Attack()
end))

_G.ShouldSendData = false
local issobusy = false

loadstring(game:HttpGet("https://raw.githubusercontent.com/SkibidiHub111/fast/refs/heads/main/.luau"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/SkibidiHub111/luau/refs/heads/main/abcyzojeb"))()

local JOB_ID = game.JobId
local USERNAME = Players.LocalPlayer.Name
local readySent = false
local abilityCooldown = 0

-- ============================================================
--   LOCAL GROUP (thay thế hệ thống ghép cặp qua server API)
--   matchState giờ luôn = 1 object cố định, không gọi API nữa.
--   Main = chính username trong MainWhitelist phía trên.
--   Help = tất cả username trong HelpWhitelist.
--   isallies đã được set sẵn từ block whitelist phía trên.
-- ============================================================
-- ============================================================
--   BIẾN GROUP (được gán bởi API server khi script execute)
-- ============================================================
local myGroupId           = ""
local myGroupHelpers      = {}
local myGroupMainUsername = mainAccountName
local matchState = {
    assigned      = false,
    group_id      = "",
    main_username = mainAccountName,
    main_job_id   = game.JobId,
    helpers       = {},
    all_in_job    = false,
}

task.spawn(function()
    while task.wait(2) do
        if getgenv().UpdateRoles then
            getgenv().UpdateRoles()
        end

        -- Gán group qua API nếu chưa có và acc có role hợp lệ
        if myGroupId == "" and (isUper or isAlly) then
            pcall(assignToGroup)
        end

        if matchState then
            local v4s = nil
            pcall(function() v4s = getV4Status(true) end)
            local needsIndependentWork = v4s and (v4s.needsTraining or v4s.needsPurchase)
            local alreadyReady = v4s and (v4s.canTrial or v4s.complete)

            if needsIndependentWork and not alreadyReady then
                matchState.assigned = false
            else
                matchState.assigned = (myGroupId ~= "")
            end
            matchState.group_id      = myGroupId
            matchState.main_username = myGroupMainUsername

            local list = {}
            for _, h in ipairs(myGroupHelpers) do table.insert(list, h) end
            matchState.helpers = list
        end
    end
end)
local mainJobId = game.JobId
local matchTeleportAt = 0
local scheduledRoundId = ""
local handledRoundId = ""
local lastReadyWrite = 0
local currentTaskStatus = "starting"
local pairAssignedAt = tick()
local pairAllInJobAt = tick()
local pairTempleReadyAt = 0
local lastTempleReadyCount = 0
local lastPairGroupId = ""
local localRequeueBlockUntil = 0
local releasingGroup = false
local gearClaimInProgress = false
local lastTempleForceAt = 0
local lastTempleProgressAt = 0
local lastTempleDistance = math.huge
local pairTrialCycleStarted = false
local pairV3ActivatedAt = 0
local PAIR_TEMPLE_TIMEOUT = math.max(15, tonumber(getgenv().Config["Pair Temple Timeout"]) or 35)
local stickyPairSetting = getgenv().Config["Pair Sticky Until Trial Complete"]
if stickyPairSetting == nil then
    stickyPairSetting = getgenv().Config["Pair Sticky Until Gear"]
end
local PAIR_STICKY_UNTIL_TRIAL_COMPLETE = stickyPairSetting ~= false
local PAIR_RELEASE_AFTER_TRIAL = getgenv().Config["Pair Release After Trial"] ~= false
local PAIR_REQUEUE_DELAY = math.max(5, tonumber(getgenv().Config["Pair Requeue Delay"]) or 15)
local PAIR_FORCE_TEMPLE_INTERVAL = math.max(0.25, tonumber(getgenv().Config["Pair Force Temple Interval"]) or 0.8)
local V3_DOOR_DISTANCE = math.max(10, tonumber(getgenv().Config["V3 Door Distance"]) or 50)
local API_BASE = tostring(getgenv().Config["API Base URL"] or "http://localhost:3000")
local V3_COUNTDOWN = math.max(1, tonumber(getgenv().Config["V3 Countdown"]) or 6)
local V3_FILE_POLL = math.max(0.05, tonumber(getgenv().Config["V3 File Poll"]) or 0.10)
local V3_READY_FRESHNESS = math.max(0.8, tonumber(getgenv().Config["V3 Ready Freshness"]) or 2.0)
local V3_REQUIRE_DIFFERENT_RACES = getgenv().Config["V3 Require Different Races"] ~= false
local V3_FIRE_COUNT = math.max(1, math.floor(tonumber(getgenv().Config["V3 Fire Count"]) or 1))
local V3_FIRE_INTERVAL = math.max(0.03, tonumber(getgenv().Config["V3 Fire Interval"]) or 0.05)

function req()
    return http_request or http and http.request or request or syn and syn.request
end

function jsonEncode(t)
    return HttpService:JSONEncode(t)
end

function jsonDecode(s)
    return HttpService:JSONDecode(s)
end

function getRole()
    if isUper then return "main" end
    if isAlly then return "helper" end
    return "none"
end

-- ============================================================
--   STATUS API — thay thế hoàn toàn cơ chế workspace file sync
-- ============================================================
function apiPost(path, body)
    local r = req()
    if not r then return nil end
    local ok, result = pcall(function()
        local response = r({
            Url     = API_BASE .. path,
            Method  = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body    = jsonEncode(body)
        })
        if response and response.StatusCode == 200 then
            local ok2, data = pcall(jsonDecode, response.Body)
            if ok2 then return data end
        end
        return nil
    end)
    if ok then return result end
    return nil
end

function apiGet(path)
    local r = req()
    if not r then return nil end
    local ok, result = pcall(function()
        local response = r({
            Url     = API_BASE .. path,
            Method  = "GET",
            Headers = { ["Content-Type"] = "application/json" }
        })
        if response and response.StatusCode == 200 then
            local ok2, data = pcall(jsonDecode, response.Body)
            if ok2 then return data end
        end
        return nil
    end)
    if ok then return result end
    return nil
end

-- Phân tích ConfigGroupHop thành danh sách group để gửi lên API
function parseGroupHopConfig()
    local ghConfig    = getgenv().ConfigGroupHop or {}
    local soluonggroup = tonumber(ghConfig["Soluonggroup"]) or 1
    local groups      = {}
    for i = 1, soluonggroup do
        local groupKey      = "Group-" .. i
        local groupNameList = ghConfig[groupKey] or {}
        for _, groupName in ipairs(groupNameList) do
            local helpersKey = "Namegroup-" .. groupName
            local helpers    = ghConfig[helpersKey] or {}
            table.insert(groups, {
                id      = groupKey,
                name    = groupName,
                helpers = helpers
            })
        end
    end
    return soluonggroup, groups
end

-- Gán acc vào group qua API — gọi khi script load hoặc khi mất group
function assignToGroup()
    local role = getRole()
    if role == "none" then return end
    local soluonggroup, groups = parseGroupHopConfig()
    local result = apiPost("/api/group/assign", {
        username    = USERNAME,
        role        = role,
        soluonggroup = soluonggroup,
        groups      = groups
    })
    if result and result.groupId then
        myGroupId           = tostring(result.groupId)
        myGroupHelpers      = result.helpers or {}
        myGroupMainUsername = tostring(result.mainUsername or mainAccountName)
        matchState.group_id      = myGroupId
        matchState.main_username = myGroupMainUsername
        matchState.helpers       = myGroupHelpers
        matchState.assigned      = true
        matchState.main_job_id   = tostring(result.mainJobId or game.JobId)
    end
end

function resetLocalPairState()
    mainJobId        = game.JobId
    readySent        = false
    scheduledRoundId = ""
    handledRoundId = ""
    lastPairGroupId = myGroupId
    pairAssignedAt = tick()
    pairAllInJobAt = tick()
    pairTempleReadyAt = 0
    lastTempleReadyCount = 0
    lastTempleForceAt = 0
    lastTempleProgressAt = 0
    lastTempleDistance = math.huge
    pairTrialCycleStarted = false
    pairV3ActivatedAt = 0
end

function releaseCurrentGroup(reason)
    reason = tostring(reason or "completed")
    resetLocalPairState()
    return true
end

function computeQueueReady()
    if not (isnight() and isfullmoon()) then return false, "waiting_full_moon" end
    local ok, canTrial = pcall(function()
        local ready = trialable()
        return ready == true
    end)
    if ok and canTrial then return true, "ready_for_pair" end
    return false, "not_trial_ready"
end

function getCurrentUpgearTurn()
    if myGroupMainUsername ~= "" then return myGroupMainUsername end
    if mainAccountName ~= "" then return mainAccountName end
    if isUper then return USERNAME end
    return nil
end

function isOtherUpgearTraining()
    -- Helper: main của group (được gán từ API) đang train
    if not isAlly then return false end
    local mainName = myGroupMainUsername ~= "" and myGroupMainUsername or mainAccountName
    return mainName ~= ""
end

function isMyUpgearTurn()
    -- Main luôn được coi là đúng lượt của chính mình
    return isUper
end


function updateDynamicGroupConfig(response)
    -- Không còn dùng — group config giờ cố định từ whitelist, không
    -- nhận dữ liệu động từ server nữa.
end

function refreshMatch()
    -- Luôn đẩy status lên API
    pcall(writeOwnDoorFile, false)

    if myGroupId == "" then return matchState end

    -- Kiểm tra xem ai trong group đang có Full Moon
    -- Nếu có, toàn bộ (kể cả Main) hop về server đó
    local moonData = apiGet("/api/group/" .. myGroupId .. "/fullmoon")
    if moonData and moonData.found and moonData.jobId and moonData.jobId ~= "" then
        local moonJobId = tostring(moonData.jobId)
        -- Chỉ redirect nếu không phải chính mình đang có Full Moon
        if tostring(moonData.username or "") ~= tostring(USERNAME) then
            if matchState then matchState.main_job_id = moonJobId end
            status("[Hop] Full Moon tại " .. tostring(moonData.username) .. " → joining")
        end
    elseif isAlly and myGroupMainUsername ~= "" and myGroupMainUsername ~= USERNAME then
        -- Không ai có Full Moon → helper theo Main như cũ
        local mainStatus = apiGet("/api/status/" .. myGroupMainUsername)
        if mainStatus and mainStatus.jobId then
            if matchState then matchState.main_job_id = tostring(mainStatus.jobId) end
        end
    end

    return matchState
end

function sendMainJob()
    return refreshMatch()
end

function getMainJob()
    if isUper then return game.JobId end
    if matchState and matchState.main_job_id and matchState.main_job_id ~= "" then
        return matchState.main_job_id
    end
    if myGroupMainUsername ~= "" and myGroupMainUsername ~= USERNAME then
        local mainStatus = apiGet("/api/status/" .. myGroupMainUsername)
        if mainStatus and mainStatus.jobId then return tostring(mainStatus.jobId) end
    end
    return mainJobId
end

task.spawn(function()
    while task.wait(2) do
        pcall(refreshMatch)
    end
end)

-- Gán group ngay khi load (sau 0.5s để đợi hàm assignToGroup được định nghĩa)
task.spawn(function()
    task.wait(0.5)
    if isUper or isAlly then pcall(assignToGroup) end
end)

function autoEquipGear()
    local gearConfig = getgenv().Config["Gear"]
    if not gearConfig or #gearConfig ~= 5 then return end
    local slot1Type = string.sub(gearConfig, 1, 1)
    local slot2Type = string.sub(gearConfig, 3, 3)
    local slot3Type = string.sub(gearConfig, 5, 5)

    local accessoryMap = {
        ["A"] = { "Pale Scarf", "Pink Coat", "Valentine's Necklace", "Black Cape", "Swan Glasses", "Tomoe Ring", "Dark Coat", "Musketeer Hat", "Kitsune Mask", "Kitsune Ribbon", "Lei", "Pretty Helmet" },
        ["B"] = { "Ghoul Mask", "Winter Sky", "Black Spikey Coat", "Koko's Glasses", "Berserker Mask", "Warrior Helmet", "Water Key Necklace", "Pilot Helmet" },
        ["C"] = { "Marine Cap", "Swordsman Hat", "Usoap's Hat", "Choppa's Hat", "Robin's Glasses", "Namis Glasses", "Brook's Glasses", "Bobby's Glasses", "Jaw's Glasses", "Bear Ears", "Cool Shades", "Skeleton Mask" }
    }

    function getPriority(accessoryName)
        for tier, names in pairs(accessoryMap) do
            for _, name in ipairs(names) do
                if accessoryName:find(name) then
                    return tier == "A" and 3 or tier == "B" and 2 or 1
                end
            end
        end
        return 0
    end

    function findBestAccessoryInBackpack()
        local best, bestPriority = nil, -1
        for _, tool in ipairs(Players.LocalPlayer.Backpack:GetChildren()) do
            if tool:IsA("Accessory") then
                local priority = getPriority(tool.Name)
                if priority > bestPriority then bestPriority = priority; best = tool end
            end
        end
        return best
    end

    local character = Players.LocalPlayer.Character
    if not character then return end

    function equipToSlot(slotIndex, desiredType)
        local currentAccessory = character:FindFirstChildOfClass("Accessory")
        if currentAccessory and currentAccessory.Name:find("Accessory") then
            local currentPriority = getPriority(currentAccessory.Name)
            local desiredPriority = desiredType == "-" and 99 or (accessoryMap[desiredType] and (desiredType == "A" and 3 or desiredType == "B" and 2 or 1) or 0)
            if currentPriority >= desiredPriority then return end
        end
        local bestBackpack = findBestAccessoryInBackpack()
        if bestBackpack then
            local backpackPriority = getPriority(bestBackpack.Name)
            local desiredPriority = desiredType == "-" and 0 or (accessoryMap[desiredType] and (desiredType == "A" and 3 or desiredType == "B" and 2 or 1) or 0)
            if backpackPriority >= desiredPriority then
                Players.LocalPlayer.Character.Humanoid:EquipTool(bestBackpack)
            end
        end
    end

    if Players.LocalPlayer.Backpack:FindFirstChildOfClass("Accessory") then
        equipToSlot(1, slot1Type)
    end
end

function checkgear()
    if gearClaimInProgress or not CommF_ then return false end
    gearClaimInProgress = true

    function finish(result)
        gearClaimInProgress = false
        return result
    end

    function snapshot(clockData)
        local details = clockData and clockData.RaceDetails
        if type(details) ~= "table" then return nil end

        local gears = type(details.Gears) == "table" and details.Gears or {}
        local gearParts = {}
        for index = 1, 3 do
            gearParts[index] = tostring(gears[index] or "")
        end

        return {
            hadPoint = clockData.HadPoint == true,
            raceLevel = tonumber(clockData.RaceLevel) or 0,
            a = tonumber(details.A) or 0,
            b = tonumber(details.B) or 0,
            c = tonumber(details.C) or 0,
            completed = tonumber(details.Completed) or tonumber(clockData.Completed) or 0,
            gears = table.concat(gearParts, "|"),
            rawGears = { gearParts[1], gearParts[2], gearParts[3] }
        }
    end

    local ok, beforeData = pcall(function()
        return CommF_:InvokeServer("TempleClock", "Check")
    end)
    local before = ok and snapshot(beforeData) or nil
    if not before then return finish(false) end

    -- Lấy config gear (Mặc định hoặc Tối ưu theo tộc)
    local pattern = getgenv().Config and getgenv().Config["Gear"] or "B-B-A"
    if getgenv().Config and getgenv().Config["ChangeBestGear"] then
        local race = Players.LocalPlayer.Data.Race.Value
        if bestGearForRace and bestGearForRace[race] then 
            pattern = bestGearForRace[race] 
        end
    end

    local g1, g2, g3 = tostring(pattern):match("^([AB])%-([AB])%-([AB])$")
    if not g1 or not g2 or not g3 then
        g1, g2, g3 = "B", "B", "A"
    end

    local convert = { A = "Alpha", B = "Omega" }
    local targetGears = { convert[g1], convert[g2], convert[g3] }
    local installedCount = before.a + before.b

    -- === TÍNH NĂNG MỚI: TỰ ĐỘNG XOAY/ĐỔI GEAR KHI ĐÃ MAX V4 ===
    if installedCount >= 3 then
        local changedAny = false
        for i = 1, 3 do
            -- Nếu gear hiện tại khác với gear mong muốn trong Config, tiến hành đổi
            if before.rawGears[i] ~= "" and before.rawGears[i] ~= targetGears[i] then
                local slotNameToChange = "Gear" .. tostring(i + 1)
                pcall(function()
                    CommF_:InvokeServer("TempleClock", "ChangeGear", slotNameToChange, targetGears[i])
                end)
                changedAny = true
                task.wait(0.5)
            end
        end
        
        if changedAny then
            invalidateV4Status()
            finish(true)
            if isUper and isMyUpgearTurn() and matchState and matchState.assigned then
                task.spawn(function() releaseCurrentGroup("gear_changed") end)
            end
            return true
        end
        
        -- Nếu gear đã chuẩn theo Config -> Không cần đổi, pass qua
        finish(false)
        if isUper and isMyUpgearTurn() and matchState and matchState.assigned then
            task.spawn(function() releaseCurrentGroup("gear_maxed_and_perfect") end)
        end
        return false
    end

    -- === TÍNH NĂNG CŨ: CLAIM (LẤY) GEAR MỚI KHI CÓ POINT ===
    if beforeData.HadPoint ~= true then
        return finish(false)
    end

    local slotName = nil
    local choose = nil
    local isFirstGear = before.raceLevel < 2

    if isFirstGear then
        slotName = "Gear1"
    else
        if installedCount < 0 or installedCount > 2 then
            return finish(false)
        end

        local slotIndex = installedCount + 2
        local slotPattern = { g1, g2, g3 }
        slotName = "Gear" .. tostring(slotIndex)
        choose = convert[slotPattern[installedCount + 1]]

        -- Luật của Blox Fruits: Tối đa 2 Alpha hoặc 2 Omega
        if before.a >= 2 then
            choose = "Omega"
        elseif before.b >= 2 then
            choose = "Alpha"
        elseif choose ~= "Alpha" and choose ~= "Omega" then
            choose = "Omega"
        end
    end

    local spentOk, spentResult = pcall(function()
        if isFirstGear then
            return CommF_:InvokeServer("TempleClock", "SpendPoint")
        end
        return CommF_:InvokeServer("TempleClock", "SpendPoint", slotName, choose)
    end)

    if not spentOk or spentResult == false then
        return finish(false)
    end

    local claimed = false
    for _ = 1, 12 do
        task.wait(0.35)
        local verifyOk, verifyData = pcall(function()
            return CommF_:InvokeServer("TempleClock", "Check")
        end)
        local after = verifyOk and snapshot(verifyData) or nil

        if after and verifyData.HadPoint == false then
            local progressionChanged
            if isFirstGear then
                progressionChanged = after.raceLevel > before.raceLevel
                    or after.completed ~= before.completed
                    or after.gears ~= before.gears
            else
                progressionChanged = after.a ~= before.a
                    or after.b ~= before.b
                    or after.gears ~= before.gears
                    or after.completed ~= before.completed
            end

            if progressionChanged then
                claimed = true
                break
            end
        end
    end

    if claimed then
        invalidateV4Status()
        finish(true)
        if isUper and isMyUpgearTurn() and matchState and matchState.assigned then
            task.spawn(function() releaseCurrentGroup("gear_claimed") end)
        end
        return true
    end

    return finish(false)
end

task.spawn(function()
    while task.wait(5) do
        if Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
            pcall(autoEquipGear)
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        if isUper and isMyUpgearTurn() and matchState and matchState.assigned then
            pcall(checkgear)
        end
    end
end)

local isCurrentGroupInThisServer

function localDoorState()
    local door = getdoor()
    local char = Players.LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local distance = math.huge
    if door and hrp then
        distance = (door.Position - hrp.Position).Magnitude
    end
    local timerVisible = false
    pcall(function()
        timerVisible = Players.LocalPlayer.PlayerGui.Main.Timer.Visible == true
    end)
    local alive = hum ~= nil and hum.Health > 0
    local nearDoor = alive and door ~= nil and distance <= V3_DOOR_DISTANCE
    return {
        door = door,
        distance = distance,
        nearDoor = nearDoor,
        timerVisible = timerVisible,
        alive = alive
    }
end

local TEMPLE_ENTRY_POSITION = Vector3.new(28310.0234, 14895.1123, 109.456741)
function isInsideOwnTrial()
    local race = ""
    pcall(function() race = Players.LocalPlayer.Data.Race.Value end)
    local trialLocation = races_trial_place[race]
    if trialLocation then
        local ok, distance = pcall(function() return getdis(trialLocation.CFrame) end)
        if ok and distance < 1500 then return true end
    end
    local timerVisible = false
    pcall(function() timerVisible = Players.LocalPlayer.PlayerGui.Main.Timer.Visible == true end)
    return timerVisible
end

function forceMatchedAccountToTemple()
    if not isCurrentGroupInThisServer() or not (isnight() and isfullmoon()) then return false end
    if isInsideOwnTrial() then return true end
    if tick() - lastTempleForceAt < PAIR_FORCE_TEMPLE_INTERVAL then return false end
    lastTempleForceAt = tick()

    if not workspace.Map:FindFirstChild("Temple of Time") then
        local templeRef = ReplicatedStorage.MapStash:FindFirstChild("Temple of Time")
        if templeRef then templeRef.Parent = workspace.Map end
    end

    local door = getdoor()
    local char = Players.LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then
        status("Paired - waiting character before Temple")
        return false
    end

    local templeDistance = (root.Position - TEMPLE_ENTRY_POSITION).Magnitude
    if not door or templeDistance > 3000 then
        status("Paired - entering Temple of Time")
        pcall(function() CommF_:InvokeServer("requestEntrance", TEMPLE_ENTRY_POSITION) end)
        return false
    end

    local distance = (door.Position - root.Position).Magnitude
    if distance + 20 < lastTempleDistance then
        lastTempleDistance = distance
        lastTempleProgressAt = tick()
    elseif lastTempleProgressAt <= 0 then
        lastTempleProgressAt = tick()
    end

    if distance > V3_DOOR_DISTANCE then
        status(string.format("Paired - flying to race door (%.0f)", distance))
        pcall(function() topos(door.CFrame) end)
        if tick() - lastTempleProgressAt > 8 then
            lastTempleProgressAt = tick()
            pcall(function() CommF_:InvokeServer("requestEntrance", TEMPLE_ENTRY_POSITION) end)
            task.wait(0.25)
            pcall(function() topos(door.CFrame) end)
        end
        return false
    end

    pcall(function() topos(door.CFrame) end)
    status("Paired - at race door")
    return true
end

function v3ServerNow()
    local ok, value = pcall(function() return Workspace:GetServerTimeNow() end)
    if ok and tonumber(value) then return tonumber(value) end
    return tick()
end

function sanitizeFilePart(value)
    value = tostring(value or "unknown")
    value = value:gsub("[^%w%-%_%.]", "_")
    if value == "" then value = "unknown" end
    return value
end

-- ============================================================
--   API-based group utilities (thay thế hoàn toàn file sync)
-- ============================================================

function currentGroupId()
    return myGroupId
end

function currentGroupMembers()
    -- 1 main + 2 helper = 3 member cần cho V3 fire sync
    local members = {}
    local seen    = {}
    local function add(name)
        name = tostring(name or "")
        if name ~= "" and not seen[name] then
            seen[name] = true
            table.insert(members, name)
        end
    end
    add(myGroupMainUsername)
    for _, name in ipairs(myGroupHelpers) do add(name) end
    return members
end

isCurrentGroupInThisServer = function()
    if not matchState or not matchState.assigned or myGroupId == "" then return false end
    -- Main luôn coi mình ở đúng server của chính mình
    if isUper then return true end
    -- Helper: chỉ khi main đang ở cùng server
    return tostring(matchState.main_job_id or "") == tostring(game.JobId)
end

function writeOwnDoorFile(force)
    -- Gửi status lên API luôn dù có group hay chưa
    -- (bỏ gate myGroupId=='' trước, nếu không có API sẽ không bao giờ nhận được request)
    if not force and tick() - lastReadyWrite < V3_FILE_POLL then return readySent end
    lastReadyWrite = tick()

    local doorState = localDoorState()
    local race = ""
    pcall(function() race = Players.LocalPlayer.Data.Race.Value end)
    local ready = tick() >= abilityCooldown
        and doorState.alive
        and doorState.nearDoor
        and not doorState.timerVisible

    local v4s = nil
    pcall(function() v4s = getV4Status(false) end)
    local frags = 0
    pcall(function() frags = tonumber(Players.LocalPlayer.Data.Fragments.Value) or 0 end)
    local fullMoon = false
    pcall(function() fullMoon = isnight() and isfullmoon() end)

    readySent = ready
    -- POST status lên API
    apiPost("/api/status", {
        version      = 1,
        groupId      = currentGroupId(),
        placeId      = game.PlaceId,
        jobId        = game.JobId,
        username     = USERNAME,
        role         = getRole(),
        race         = race,
        ready        = ready,
        fullMoon     = fullMoon,
        doorDistance = doorState.distance == math.huge and -1 or math.floor(doorState.distance * 100) / 100,
        timerVisible = doorState.timerVisible,
        alive        = doorState.alive,
        canTrial     = v4s and v4s.canTrial     or false,
        needsTraining = v4s and v4s.needsTraining or false,
        needsPurchase = v4s and v4s.needsPurchase or false,
        complete     = v4s and v4s.complete      or false,
        energy       = v4s and v4s.energy        or 0,
        transformed  = v4s and v4s.transformed   or false,
        fragments    = frags,
        updatedAt    = v3ServerNow(),
        firedRound   = handledRoundId
    })
    return ready
end
-- Alias để các đoạn code cũ gọi được
apiPostStatus = writeOwnDoorFile

function readReadyFiles()
    -- Query API thay vì đọc workspace file
    if myGroupId == "" then return 0, false, {}, "no_group" end

    local url = "/api/group/" .. myGroupId .. "/ready"
        .. "?jobId="     .. tostring(game.JobId)
        .. "&freshness=" .. tostring(V3_READY_FRESHNESS)
        .. "&requireDiffRaces=" .. tostring(V3_REQUIRE_DIFFERENT_RACES)

    local result = apiGet(url)
    if not result then return 0, false, {}, "api_error" end

    local readyCount = tonumber(result.readyCount) or 0
    local allReady   = result.allReady == true
    local records    = result.records or {}
    local reason     = tostring(result.reason or "unknown")

    return readyCount, allReady, records, reason
end

function readV3Command()
    if myGroupId == "" then return nil end
    local data = apiGet("/api/command/" .. myGroupId)
    if not data then return nil end
    if tostring(data.group_id or "") ~= currentGroupId() then return nil end
    if tostring(data.job_id or "") ~= tostring(game.JobId) then return nil end
    local now = v3ServerNow()
    local expiresAt = tonumber(data.expires_at) or 0
    if expiresAt <= now then return nil end
    return data
end

function writeV3Command(command)
    if myGroupId == "" then return false end
    local result = apiPost("/api/command/" .. myGroupId, command)
    return result ~= nil
end

function mainCreateRound()
    if not isUper or not isMyUpgearTurn() or not isCurrentGroupInThisServer() then return nil end

    local current = readV3Command()
    if current then return current end

    local count, allReady, _, reason = readReadyFiles()
    if not allReady then
        if reason == "duplicate_race" then
            status("V3 API 3/3 but races are duplicated")
        elseif reason == "need_exactly_3_members" then
            status("V3 API needs exactly 1 Main + 2 Help")
        elseif reason == "api_error" or reason == "no_group" then
            status("Status API unavailable — check server")
        elseif reason == "group_not_found" then
            status("Group not found on API — re-assigning")
            pcall(assignToGroup)
        else
            status("V3 API ready " .. tostring(count) .. "/3")
        end
        return nil
    end

    local now = v3ServerNow()
    local fireAt = now + V3_COUNTDOWN
    local roundId = sanitizeFilePart(USERNAME) .. "_" .. tostring(math.floor(fireAt * 1000))
    local command = {
        version = 1,
        group_id = currentGroupId(),
        job_id = game.JobId,
        main_username = USERNAME,
        members = currentGroupMembers(),
        round_id = roundId,
        created_at = now,
        fire_at = fireAt,
        expires_at = fireAt + 10,
        countdown = V3_COUNTDOWN
    }

    if writeV3Command(command) then
        status("V3 workspace 3/3 - countdown " .. tostring(V3_COUNTDOWN) .. "s")
        return command
    end
    status("Failed to write V3 command file")
    return nil
end

function commandHasCurrentUser(command)
    for _, name in ipairs(command.members or {}) do
        if tostring(name) == USERNAME then return true end
    end
    return false
end

function waitForSharedFireTime(fireAt)
    while true do
        local remaining = fireAt - v3ServerNow()
        if remaining <= 0 then return end
        status(string.format("V3 countdown %.2fs", remaining))
        if remaining > 0.25 then
            task.wait(math.min(0.10, math.max(0.03, remaining - 0.15)))
        else
            RunService.Heartbeat:Wait()
        end
    end
end

function scheduleWorkspaceRound(command)
    local roundId = tostring(command and command.round_id or "")
    local fireAt = tonumber(command and command.fire_at) or 0
    if roundId == "" or fireAt <= 0 then return false end
    if roundId == handledRoundId or roundId == scheduledRoundId then return false end
    if not commandHasCurrentUser(command) then return false end

    scheduledRoundId = roundId
    task.spawn(function()
        waitForSharedFireTime(fireAt)

        local validGroup = isCurrentGroupInThisServer()
            and tostring(command.group_id or "") == currentGroupId()
            and tostring(command.job_id or "") == tostring(game.JobId)
        local doorState = localDoorState()
        local fired = false

        if validGroup and doorState.nearDoor and not doorState.timerVisible then
            status("Activating Race V3 from shared workspace time")
            for index = 1, V3_FIRE_COUNT do
                pcall(function()
                    ReplicatedStorage.Remotes.CommE:FireServer("ActivateAbility")
                end)
                if index < V3_FIRE_COUNT then task.wait(V3_FIRE_INTERVAL) end
            end
            handledRoundId = roundId
            abilityCooldown = tick() + 30
            readySent = false
            fired = true
            if isUper and isMyUpgearTurn() then
                pairTrialCycleStarted = true
                pairV3ActivatedAt = tick()
            end
        else
            status("V3 countdown ended but account left its race door")
        end

        scheduledRoundId = ""
        writeOwnDoorFile(true)
        return fired
    end)
    return true
end

local activatingAbility = false

function tryActivateAbility()
    if activatingAbility then return false end
    if not isCurrentGroupInThisServer() then return false end

    activatingAbility = true
    writeOwnDoorFile(false)

    local command = nil
    if isUper and isMyUpgearTurn() then
        command = mainCreateRound()
    else
        command = readV3Command()
        if not command then
            local _, ownReady = pcall(writeOwnDoorFile, false)
            if ownReady then status("At race door - waiting Main file countdown") end
        end
    end

    activatingAbility = false
    if command then return scheduleWorkspaceRound(command) end
    return false
end

task.spawn(function()
    while task.wait(V3_FILE_POLL) do
        pcall(tryActivateAbility)
    end
end)

local TyrState = {
    AttackLoaded = false, Farming = true, CurrentMode = "STARTING",
    CurrentTarget = nil, LastStatus = "",
    TrackedBreakables = setmetatable({}, { __mode = "k" }),
    CachedBreakables = {}, LastBreakableScan = 0
}

local TIKI_CENTER = CFrame.new(-16682.7, 215, 524.2)
local TYRANT_ENTRANCE = CFrame.new(-16342.5, 174, 1397)
local ARENA_CENTER = Vector3.new(-16335, 174, 1397)
local DRAGON_TALON_BUY_POS = CFrame.new(5661.616211, 1211.299438, 865.999451)

local TikiMobs = {
    ["Isle Outlaw"] = true, ["Island Boy"] = true, ["Sun-kissed Warrior"] = true,
    ["Isle Champion"] = true, ["Serpent Hunter"] = true, ["Skull Slayer"] = true
}

local TrainingIslandData = {
    ["Haunted Castle"] = {
        Position = CFrame.new(-9530.61035, 200.860657, 5763.13477),
        Mobs = { ["Reborn Skeleton"] = true, ["Living Zombie"] = true, ["Demonic Soul"] = true, ["Possessed Mummy"] = true }
    },
    ["Tiki Outpost"] = {
        Position = CFrame.new(-16490.9727, 98.1144867, 1245.58984, -0.034969449, 0, 0.999388516, 0, 1, 0, -0.999388516, 0, -0.034969449),
        Mobs = { ["Isle Outlaw"] = true, ["Island Boy"] = true, ["Sun-kissed Warrior"] = true, ["Isle Champion"] = true }
    },
    ["Great Tree"] = {
    Positions = {
        CFrame.new(2527.22119, 88.0126953, -7554.48096, -0.999390602, -0.0349089168, -1.05798244e-06, 1.05798244e-06, -6.05583191e-05, 1, -0.0349089168, 0.999390483, 6.05583191e-05),
        CFrame.new(2923.90332, 91.6738281, -7734.71631, 0.997561574, -0, -0.0697919354, 0, 1, -0, 0.0697919354, 0, 0.997561574),
        CFrame.new(3778.4248, 116.34375, -6938.81641, -0.667134643, -0.731317759, 0.141794443, -0.207926333, 2.65836716e-05, -0.978144467, 0.71533066, -0.682036817, -0.152077913)
    },    
    Mobs = {
        ["Marine Commodore"] = true,
        ["Marine Rear Admiral"] = true
    }
},
    ["Ice Cream Island"] = {
        Position = CFrame.new(-851.74633789062, 65.819496154785, -10932.150390625),
        Mobs = { ["Peanut Scout"] = true, ["Peanut President"] = true, ["Ice Cream Chef"] = true, ["Ice Cream Commander"] = true }
    },
    ["Port Town"] = {
        Positions = {
            CFrame.new(-172.031281, 52.8853912, 5851.12793, 0.965929627, -0, -0.258804798, 0, 1, -0, 0.258804798, 0, 0.965929627),
            CFrame.new(-638.581543, 50.9266357, 5627.74951, 0.258864343, 0, 0.965913713, 0, 1, 0, -0.965913713, 0, 0.258864343),
            CFrame.new(-61.3757935, 48.8545227, 6151.30762, 0.965929627, -0, -0.258804798, 0, 1, -0, 0.258804798, 0, 0.965929627),
            CFrame.new(-662.967041, 65.9991913, 5804.41699, 0.965938151, 0.050586991, -0.253780305, -4.01213765e-06, 0.980709016, 0.195473209, 0.258773029, -0.188813999, 0.947304487)
        },
        Mobs = { ["Pirate Millionaire"] = true, ["Pistol Billionaire"] = true }
    },
    ["Peanut Island"] = {
        Position = CFrame.new(-2087.0561523438, 11.722011566162, -10002.080078125),
        Mobs = { ["Peanut Scout"] = true, ["Peanut President"] = true }
    }
}

local TrainingIslandOrder = getgenv().Config["Training Islands"] or {
    "Tiki Outpost", "Ice Cream Island", "Haunted Castle", "Great Tree", "Port Town", "Peanut Island"
}

local MAX_ACCS_PER_ISLAND = 2
local myAssignedIsland = nil

local ISLAND_LEASE_SECONDS = 60

-- Đọc island list từ API (thay thế readIslandSyncFile từ file)
function readIslandSyncFile()
    local result = apiGet("/api/island/list")
    if type(result) ~= "table" then return {} end
    -- Convert format API → format cũ { island: {count, users, lastUpdate} }
    local formatted = {}
    for island, data in pairs(result) do
        formatted[island] = {
            count      = tonumber(data.count) or 0,
            users      = data.users or {},
            lastUpdate = tick()
        }
    end
    return formatted
end

function writeIslandSyncFile(data)
    -- Server tự quản lý state — không cần ghi toàn bộ
end

function assignTrainingIsland()
    local assignments = readIslandSyncFile()

    local bestIsland = nil
    local bestCount  = math.huge
    for _, islandName in ipairs(TrainingIslandOrder) do
        local entry = assignments[islandName] or { count = 0 }
        local count = entry.count or 0
        if count < MAX_ACCS_PER_ISLAND and count < bestCount then
            bestCount = count
            bestIsland = islandName
        end
    end
    if not bestIsland then
        for _, islandName in ipairs(TrainingIslandOrder) do
            local entry = assignments[islandName] or { count = 0 }
            local count = entry.count or 0
            if count < bestCount then
                bestCount = count
                bestIsland = islandName
            end
        end
    end

    bestIsland = bestIsland or TrainingIslandOrder[1]
    myAssignedIsland = bestIsland

    -- Đăng ký assignment với API
    apiPost("/api/island/assign", { username = USERNAME, island = bestIsland })

    return bestIsland
end

function updateIslandHeartbeat()
    if not myAssignedIsland then return end
    apiPost("/api/island/assign", { username = USERNAME, island = myAssignedIsland })
end

task.spawn(function()
    while task.wait(15) do
        pcall(updateIslandHeartbeat)
    end
end)

function countAccountsAtIsland(islandName)
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
        if plr ~= Players.LocalPlayer and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if hrp and (hrp.Position - islandPos).Magnitude < 1000 then
                count = count + 1
            end
        end
    end
    return count
end

function CheckMonster(...)
    local args = { ... }
    local containers = { workspace.Enemies, ReplicatedStorage }
    for i = 1, #args do
        local m = workspace.Enemies:FindFirstChild(args[i]) or ReplicatedStorage:FindFirstChild(args[i])
        if m and m:IsA("Model") and m.Name ~= "Blank Buddy" then
            local h = m:FindFirstChildWhichIsA("Humanoid")
            local r = m:FindFirstChild("HumanoidRootPart")
            if h and r and h.Health > 0 then return m end
        end
    end
    for _, container in ipairs(containers) do
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
    return false
end

function forceReassignIsland()
    myAssignedIsland = nil
end

function TyrTweenTo(targetCF, speed)
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root or not targetCF then return false end
    local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.Sit = false end
    local distance = (root.Position - targetCF.Position).Magnitude
    local duration = distance / (speed or getgenv().TyrantConfig.TweenSpeed)
    if duration < 0.05 then root.CFrame = targetCF; return true end
    local tween = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), { CFrame = targetCF })
    local completed = false
    local success = false
    local connection
    connection = tween.Completed:Connect(function(state)
        completed = true
        success = state == Enum.PlaybackState.Completed
        if connection then connection:Disconnect() end
    end)
    tween:Play()
    local started = tick()
    repeat
        task.wait(0.05)
        root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not root then break end
        if (root.Position - targetCF.Position).Magnitude <= 8 then success = true; break end
    until completed or tick() - started > math.max(duration + 2, 10)
    pcall(function() tween:Cancel() end)
    root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if root and (root.Position - targetCF.Position).Magnitude <= 12 then root.CFrame = targetCF; return true end
    return success
end

function TyrGetEnemyFolders()
    local folders = {}
    local enemies = Workspace:FindFirstChild("Enemies")
    if enemies then folders[#folders + 1] = enemies end
    local origin = Workspace:FindFirstChild("_WorldOrigin")
    if origin and origin:FindFirstChild("Enemies") then folders[#folders + 1] = origin.Enemies end
    return folders
end

function TyrBaseEnemyName(name)
    local clean = tostring(name or "")
    clean = clean:gsub("%s*%[Lv%.%s*%d+%]", ""):gsub("%s*%[Lv%s*%d+%]", "")
    clean = clean:gsub("%s*%[Boss%]", ""):gsub("%s*%[Raid Boss%]", "")
    return clean:gsub("%s+$", "")
end

function TyrIsTikiMob(enemy)
    return enemy and TikiMobs[TyrBaseEnemyName(enemy.Name)] == true
end

function TyrIsTyrant(enemy)
    if not enemy then return false end
    return string.find(string.lower(enemy.Name), "tyrant", 1, true) ~= nil
end

function TyrFindTyrant()
    for _, folder in ipairs(TyrGetEnemyFolders()) do
        for _, enemy in ipairs(folder:GetChildren()) do
            local hum = enemy:FindFirstChildOfClass("Humanoid")
            local root = enemy:FindFirstChild("HumanoidRootPart")
            if hum and root and hum.Health > 0 and TyrIsTyrant(enemy) then return enemy end
        end
    end
    return nil
end

function TyrGetNearestTikiMob()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local nearest, nearestDist = nil, math.huge
    for _, folder in ipairs(TyrGetEnemyFolders()) do
        for _, enemy in ipairs(folder:GetChildren()) do
            local hum = enemy:FindFirstChildOfClass("Humanoid")
            local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
            if hum and enemyRoot and hum.Health > 0 and TyrIsTikiMob(enemy) then
                local distance = (root.Position - enemyRoot.Position).Magnitude
                if distance < nearestDist then nearest = enemy; nearestDist = distance end
            end
        end
    end
    return nearest
end

function TyrFindTikiOutpost()
    local map = Workspace:FindFirstChild("Map")
    return map and map:FindFirstChild("TikiOutpost")
end

function TyrIsEyeActive(eye)
    if not eye or not eye:IsA("BasePart") then return false end
    local color = eye.Color
    return eye.Transparency < 0.85 and color.R >= 0.75 and color.R > color.G * 1.35 and color.R > color.B * 1.20
end

function TyrAreTyrantEyesReady()
    local tiki = TyrFindTikiOutpost()
    if not tiki then return false end
    local islandModel = tiki:FindFirstChild("IslandModel")
    if not islandModel then return false end
    local eye1 = islandModel:FindFirstChild("Eye1", true)
    local eye2 = islandModel:FindFirstChild("Eye2", true)
    return TyrIsEyeActive(eye1) and TyrIsEyeActive(eye2)
end

function TyrGetObjectPart(object)
    if not object or not object.Parent then return nil end
    if object:IsA("BasePart") then return object end
    if object:IsA("Model") then
        return object.PrimaryPart or object:FindFirstChild("HumanoidRootPart")
            or object:FindFirstChild("Head") or object:FindFirstChildWhichIsA("BasePart", true)
    end
    return object:FindFirstChildWhichIsA("BasePart", true)
end

function TyrIsNearArena(object, radius)
    local part = TyrGetObjectPart(object)
    return part and (part.Position - ARENA_CENTER).Magnitude <= (radius or 240)
end

function TyrHasBreakableName(object)
    local name = string.lower(object.Name)
    return string.find(name, "vase", 1, true) or string.find(name, "pot", 1, true)
        or string.find(name, "jar", 1, true) or string.find(name, "urn", 1, true)
        or string.find(name, "breakable", 1, true) or string.find(name, "destructible", 1, true)
end

function TyrHasBreakableData(object)
    for _, attribute in ipairs({ "Health", "HP", "HitPoints", "Breakable", "Destructible" }) do
        if object:GetAttribute(attribute) ~= nil then return true end
    end
    local ok, tags = pcall(function() return CollectionService:GetTags(object) end)
    if ok then
        for _, tag in ipairs(tags) do
            local lowerTag = string.lower(tag)
            if string.find(lowerTag, "break", 1, true) or string.find(lowerTag, "destroy", 1, true)
                or string.find(lowerTag, "vase", 1, true) or string.find(lowerTag, "pot", 1, true) then
                return true
            end
        end
    end
    return false
end

function TyrIsArenaBreakable(object)
    if not object or not object.Parent or not TyrIsNearArena(object, 260) then return false end
    local lowerName = string.lower(object.Name)
    if lowerName == "tyrantentrance" or lowerName == "bossarena1" or lowerName == "bossarena2"
        or lowerName == "eye1" or lowerName == "eye2" then return false end
    return TyrHasBreakableName(object) or TyrHasBreakableData(object) or TyrState.TrackedBreakables[object] == true
end

function TyrGetArenaBreakables(forceRefresh)
    if not forceRefresh and tick() - TyrState.LastBreakableScan < 0.45 then
        local validCache = {}
        for _, data in ipairs(TyrState.CachedBreakables) do
            if data.Object and data.Object.Parent and data.Part and data.Part.Parent then
                validCache[#validCache + 1] = data
            end
        end
        TyrState.CachedBreakables = validCache
        return TyrState.CachedBreakables
    end
    TyrState.LastBreakableScan = tick()
    local results = {}
    local added = {}
    function AddCandidate(object)
        if object and not added[object] and TyrIsArenaBreakable(object) then
            local part = TyrGetObjectPart(object)
            if part then added[object] = true; results[#results + 1] = { Object = object, Part = part } end
        end
    end
    for object in pairs(TyrState.TrackedBreakables) do AddCandidate(object) end
    local tiki = TyrFindTikiOutpost()
    if tiki then
        for _, object in ipairs(tiki:GetDescendants()) do
            if object:IsA("Model") or object:IsA("BasePart") then AddCandidate(object) end
        end
    end
    local origin = Workspace:FindFirstChild("_WorldOrigin")
    if origin then
        for _, object in ipairs(origin:GetDescendants()) do
            if object:IsA("Model") or object:IsA("BasePart") then
                if TyrIsNearArena(object, 260) then AddCandidate(object) end
            end
        end
    end
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if root then
        table.sort(results, function(a, b)
            return (a.Part.Position - root.Position).Magnitude < (b.Part.Position - root.Position).Magnitude
        end)
    end
    TyrState.CachedBreakables = results
    return TyrState.CachedBreakables
end

function TyrGetAttackTargets()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local targets = {}
    if not root then return targets end
    local config = getgenv().TyrantConfig
    if TyrState.CurrentMode == "VASES" then
        for _, data in ipairs(TyrGetArenaBreakables()) do
            if data.Part and data.Part.Parent and (data.Part.Position - root.Position).Magnitude <= config.AttackDistance then
                targets[#targets + 1] = { data.Object, data.Part }
            end
        end
        return targets
    end
    for _, folder in ipairs(TyrGetEnemyFolders()) do
        for _, enemy in ipairs(folder:GetChildren()) do
            local hum = enemy:FindFirstChildOfClass("Humanoid")
            local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
            local head = enemy:FindFirstChild("Head")
            local valid = false
            if hum and enemyRoot and hum.Health > 0 then
                if TyrState.CurrentMode == "BOSS" then valid = enemy == TyrState.CurrentTarget or TyrIsTyrant(enemy)
                elseif TyrState.CurrentMode == "MOBS" then valid = TyrIsTikiMob(enemy) end
            end
            if valid and (enemyRoot.Position - root.Position).Magnitude <= config.AttackDistance then
                targets[#targets + 1] = { enemy, head or enemyRoot }
            end
        end
    end
    return targets
end

function TyrLoadAttack()
    if TyrState.AttackLoaded then return end
    TyrState.AttackLoaded = true
    local modules = ReplicatedStorage:WaitForChild("Modules")
    local net = modules:WaitForChild("Net")
    local registerAttack = net:WaitForChild("RE/RegisterAttack")
    local registerHit = net:WaitForChild("RE/RegisterHit")
    local remoteAttack = nil
    local remoteId = nil
    local seed = nil
    local lastAttack = 0
    pcall(function() seed = net:WaitForChild("seed"):InvokeServer() end)

    function GetRemoteAttack()
        if remoteAttack and remoteAttack.Parent and remoteId then return true end
        remoteAttack = nil; remoteId = nil
        for _, folder in ipairs({
            ReplicatedStorage:FindFirstChild("Util"),
            ReplicatedStorage:FindFirstChild("Common"),
            ReplicatedStorage:FindFirstChild("Remotes"),
            ReplicatedStorage:FindFirstChild("Assets"),
            ReplicatedStorage:FindFirstChild("FX")
        }) do
            if folder then
                for _, object in ipairs(folder:GetChildren()) do
                    if object:IsA("RemoteEvent") and object:GetAttribute("Id") then
                        remoteAttack = object; remoteId = object:GetAttribute("Id"); return true
                    end
                end
            end
        end
        return false
    end

    function EncryptedRegisterHit(hitData)
        if not seed then pcall(function() seed = net:WaitForChild("seed"):InvokeServer() end) end
        if not GetRemoteAttack() or not seed then return end
        pcall(function()
            local encodedName = string.gsub("RE/RegisterHit", ".", function(character)
                return string.char(bit32.bxor(string.byte(character), math.floor(Workspace:GetServerTimeNow() / 10 % 10) + 1))
            end)
            remoteAttack:FireServer(encodedName, bit32.bxor(remoteId + 909090, seed * 2), unpack(hitData))
        end)
    end

    function TyrFastAttack()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not char or not hum or hum.Health <= 0 then return end
        if not char:FindFirstChildWhichIsA("Tool") then return end
        if tick() - lastAttack < getgenv().TyrantConfig.AttackDelay then return end
        local targets = TyrGetAttackTargets()
        if #targets == 0 then return end
        local hitData = { [1] = targets[1][2], [2] = {} }
        for _, target in ipairs(targets) do hitData[2][#hitData[2] + 1] = { target[1], target[2] } end
        pcall(function() registerAttack:FireServer() end)
        pcall(function() registerHit:FireServer(unpack(hitData)) end)
        EncryptedRegisterHit(hitData)
        lastAttack = tick()
    end

    getgenv().TyrantFastAttack = TyrFastAttack
    task.spawn(function()
        while task.wait() do
            if TyrState.Farming then pcall(TyrFastAttack) end
        end
    end)
end

function TyrNormalAttack(duration)
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local started = tick()
    repeat
        local tool = hum and char:FindFirstChildWhichIsA("Tool")
        if tool then pcall(function() tool:Activate() end) end
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
        end)
        if getgenv().TyrantFastAttack then pcall(getgenv().TyrantFastAttack) end
        task.wait(0.06)
    until tick() - started >= (duration or 0.6) or TyrFindTyrant()
end

function TyrBuyDragonTalon()
    local char = LocalPlayer.Character
    if char and (char:FindFirstChild("Dragon Talon") or char:FindFirstChild("DragonTalon")) then return true end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp and (bp:FindFirstChild("Dragon Talon") or bp:FindFirstChild("DragonTalon")) then return true end
    if not getgenv().TyrantConfig.AutoBuyDragonTalon then return false end
    local commf = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("CommF_")
    if not commf then return false end
    status("Buying Dragon Talon")
    TyrTweenTo(DRAGON_TALON_BUY_POS, getgenv().TyrantConfig.TweenSpeed)
    task.wait(0.8)
    for _ = 1, 15 do
        pcall(function() commf:InvokeServer("BuyDragonTalon") end)
        task.wait(0.5)
        local c = LocalPlayer.Character
        local b = LocalPlayer:FindFirstChild("Backpack")
        if (c and (c:FindFirstChild("Dragon Talon") or c:FindFirstChild("DragonTalon")))
            or (b and (b:FindFirstChild("Dragon Talon") or b:FindFirstChild("DragonTalon"))) then
            return true
        end
    end
    return false
end

function TyrNormalizeName(name)
    return tostring(name or ""):gsub("%s+", ""):lower()
end

function TyrEnsureWeapon()
    local char = LocalPlayer.Character
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return nil end
    local config = getgenv().TyrantConfig
    function findTool(toolName)
        if char then
            for _, tool in ipairs(char:GetChildren()) do
                if tool:IsA("Tool") and TyrNormalizeName(tool.Name) == TyrNormalizeName(toolName) then return tool end
            end
        end
        if bp then
            for _, tool in ipairs(bp:GetChildren()) do
                if tool:IsA("Tool") and TyrNormalizeName(tool.Name) == TyrNormalizeName(toolName) then return tool end
            end
        end
        return nil
    end
    local requested = findTool(config.Weapon)
    if requested then
        if requested.Parent ~= char then hum:EquipTool(requested); task.wait(0.15) end
        return findTool(config.Weapon)
    end
    if TyrNormalizeName(config.Weapon) == TyrNormalizeName("Dragon Talon") then TyrBuyDragonTalon() end
    local fallback = (char and char:FindFirstChildWhichIsA("Tool")) or (bp and bp:FindFirstChildWhichIsA("Tool"))
    if fallback and fallback.Parent ~= char then hum:EquipTool(fallback); task.wait(0.15) end
    return char and char:FindFirstChildWhichIsA("Tool")
end

function TyrFarmEnemy(enemy, isBoss)
    local hum = enemy and enemy:FindFirstChildOfClass("Humanoid")
    local enemyRoot = enemy and enemy:FindFirstChild("HumanoidRootPart")
    if not hum or not enemyRoot or hum.Health <= 0 then return end
    TyrState.CurrentTarget = enemy
    TyrState.CurrentMode = isBoss and "BOSS" or "MOBS"
    local config = getgenv().TyrantConfig
    local stuckAt = tick()
    local previousHealth = hum.Health
    while enemy.Parent and hum.Parent and enemyRoot.Parent and hum.Health > 0 do
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local playerHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if not root or not playerHum or playerHum.Health <= 0 then break end
        TyrEnsureWeapon()
        local height = isBoss and config.BossHeight or config.FarmHeight
        local target = CFrame.new(enemyRoot.Position + Vector3.new(0, height, 0), enemyRoot.Position)
        local distance = (root.Position - enemyRoot.Position).Magnitude
        if distance > 90 then
            TyrTweenTo(target, config.TweenSpeed)
        else
            local tween = TweenService:Create(root, TweenInfo.new(0.08, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), { CFrame = target })
            tween:Play()
        end
        if hum.Health < previousHealth then previousHealth = hum.Health; stuckAt = tick()
        elseif tick() - stuckAt > 15 then root.CFrame = target; TyrNormalAttack(0.5); stuckAt = tick() end
        task.wait(0.05)
    end
    TyrState.CurrentTarget = nil
end

function TyrBreakVases()
    TyrState.CurrentMode = "VASES"
    TyrState.CurrentTarget = nil
    status("Eyes red - breaking vases")
    TyrTweenTo(TYRANT_ENTRANCE, getgenv().TyrantConfig.TweenSpeed)
    task.wait(0.5)
    local round = 0
    while TyrAreTyrantEyesReady() and not TyrFindTyrant() do
        local breakables = TyrGetArenaBreakables()
        if #breakables > 0 then
            for _, data in ipairs(breakables) do
                if TyrFindTyrant() then return end
                if data.Part and data.Part.Parent then
                    local target = CFrame.new(data.Part.Position + Vector3.new(0, 6, 0), data.Part.Position)
                    TyrTweenTo(target, getgenv().TyrantConfig.TweenSpeed)
                    TyrNormalAttack(0.55)
                end
            end
        end
        round = round + 1
        local radius = 42
        local points = 12
        for index = 1, points do
            if TyrFindTyrant() then return end
            local angle = math.rad((index - 1) * (360 / points) + (round % 2) * 15)
            local point = ARENA_CENTER + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
            TyrTweenTo(CFrame.new(point + Vector3.new(0, 7, 0), ARENA_CENTER), getgenv().TyrantConfig.TweenSpeed)
            TyrNormalAttack(0.7)
        end
        TyrTweenTo(CFrame.new(ARENA_CENTER + Vector3.new(0, 8, 0)), getgenv().TyrantConfig.TweenSpeed)
        TyrNormalAttack(1)
        task.wait(0.8)
    end
end

function TyrSetupRegenTracker()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local regen = remotes and remotes:FindFirstChild("RegenModel")
    if not regen or not regen:IsA("RemoteEvent") then return end
    regen.OnClientEvent:Connect(function(encoded)
        local object = nil
        if typeof(encoded) == "Instance" then object = encoded
        elseif type(_G.Encode) == "function" then pcall(function() object = _G.Encode(encoded) end) end
        if object and typeof(object) == "Instance" and TyrIsNearArena(object, 280) then
            TyrState.TrackedBreakables[object] = true
        end
    end)
end

function TyrSetupBringMobs()
    if not getgenv().TyrantConfig.BringMobs then return end
    RunService.Heartbeat:Connect(function()
        if TyrState.CurrentMode ~= "MOBS" then return end
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        for _, folder in ipairs(TyrGetEnemyFolders()) do
            for _, enemy in ipairs(folder:GetChildren()) do
                local hum = enemy:FindFirstChildOfClass("Humanoid")
                local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
                if hum and enemyRoot and hum.Health > 0 and TyrIsTikiMob(enemy) then
                    local distance = (enemyRoot.Position - root.Position).Magnitude
                    if distance <= 300 then
                        pcall(function()
                            enemyRoot.CanCollide = false
                            enemyRoot.CFrame = CFrame.new(root.Position - Vector3.new(0, getgenv().TyrantConfig.FarmHeight, 0))
                            if hum:FindFirstChild("Animator") then hum.Animator:Destroy() end
                            sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)
                        end)
                    end
                end
            end
        end
    end)
end

local tyrantFarmingActive = false
local tyrantFarmingTask = nil
local tyrantSetupDone = false
local tyrantFragmentTarget = 10000

function stopTyrantFarming()
    tyrantFarmingActive = false
    TyrState.Farming = false
    tyrantFarmingTask = nil
end

function startTyrantFarming(targetFragments)
    tyrantFragmentTarget = math.max(0, tonumber(targetFragments) or tyrantFragmentTarget or 10000)
    if tyrantFarmingTask then return end
    if not tyrantSetupDone then
        tyrantSetupDone = true
        TyrSetupRegenTracker()
        TyrSetupBringMobs()
        TyrLoadAttack()
        TyrBuyDragonTalon()
    end
    tyrantFarmingActive = true
    TyrState.Farming = true
    tyrantFarmingTask = task.spawn(function()
        while tyrantFarmingActive do
            local v4State = getV4Status(false)
            local frags = tonumber(LocalPlayer.Data.Fragments.Value) or 0
            if v4State.canTrial or v4State.complete or frags >= tyrantFragmentTarget then break end

            local config = getgenv().TyrantConfig
            if config.AutoBuso then
                local c = LocalPlayer.Character
                if c and not c:FindFirstChild("HasBuso") then
                    pcall(function() CommF_:InvokeServer("Buso") end)
                end
            end
            local playerHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if not playerHum or playerHum.Health <= 0 then
                status("Respawning before fragment farm")
                task.wait(1)
            else
                local moonSuffix = (isnight() and isfullmoon()) and " | Full Moon" or ""
                local tyrant = TyrFindTyrant()
                if tyrant then
                    status("Fighting Tyrant for V4 fragments" .. moonSuffix)
                    TyrFarmEnemy(tyrant, true)
                elseif TyrAreTyrantEyesReady() then
                    status("Breaking vases for Tyrant" .. moonSuffix)
                    TyrBreakVases()
                else
                    TyrState.CurrentMode = "MOBS"
                    TyrState.CurrentTarget = nil
                    status("Farming V4 fragments " .. tostring(frags) .. "/" .. tostring(tyrantFragmentTarget) .. moonSuffix)
                    TyrEnsureWeapon()
                    local mob = TyrGetNearestTikiMob()
                    if mob then TyrFarmEnemy(mob, false)
                    else TyrTweenTo(TIKI_CENTER, config.TweenSpeed); task.wait(0.8) end
                end
            end
        end
        tyrantFarmingTask = nil
        tyrantFarmingActive = false
        TyrState.Farming = false
        invalidateV4Status()
    end)
end

function handleFragmentFarming(requiredFragments)
    local farmConfig = getgenv().Config["Farm Fragments"]
    if not farmConfig then return false end

    local state = getV4Status(false)
    if state.canTrial or state.complete then
        if tyrantFarmingActive then stopTyrantFarming() end
        return false
    end

    local target = math.max(0, tonumber(requiredFragments) or 10000)
    local frags = tonumber(LocalPlayer.Data.Fragments.Value) or 0
    if frags >= target then
        if tyrantFarmingActive then stopTyrantFarming() end
        return false
    end

    if type(farmConfig) == "table" and farmConfig.autotyrant then
        startTyrantFarming(target)
        return tyrantFarmingActive
    end
    return false
end

function buyPendingV4Upgrade(v4State, roleLabel)
    if not v4State or not v4State.needsPurchase then return false end
    roleLabel = tostring(roleLabel or "Account")
    local fragments = tonumber(LocalPlayer.Data.Fragments.Value) or 0
    local cost = tonumber(v4State.cost) or 0

    if cost > 0 and fragments < cost then
        if handleFragmentFarming(cost) then return true end
        status(roleLabel .. " needs " .. tostring(cost - fragments) .. " more fragments for V4")
        return true
    end

    if tyrantFarmingActive then stopTyrantFarming() end
    status(roleLabel .. " buying V4 upgrade")
    local ok, bought = pcall(function() return invokeUpgradeRace("Buy") end)
    invalidateV4Status()
    if ok and bought then
        status(roleLabel .. " V4 upgrade purchased")
    else
        status(roleLabel .. " V4 purchase failed - retrying")
    end
    task.wait(0.6)
    return true
end

function runRaceTrainingWork(trainingState, roleLabel)
    roleLabel = tostring(roleLabel or "Account")
    local character = Players.LocalPlayer.Character
    if not character then
        status(roleLabel .. " waiting character")
        task.wait(1)
        return false
    end

    local initialV4State = getV4Status(false)
    if initialV4State.complete then
        status(roleLabel .. " Race V4 completed")
        return true
    end
    if initialV4State.canTrial then
        status(roleLabel .. " training complete - ready for trial")
        return true
    end
    if initialV4State.needsPurchase then
        buyPendingV4Upgrade(initialV4State, roleLabel)
        return false
    end

    if not character:FindFirstChild("RaceTransformed") then
        status(roleLabel .. " " .. tostring(initialV4State.label))
        talktoonggianaodo()
        invalidateV4Status()
        return false
    end

    if tyrantFarmingActive then stopTyrantFarming() end

    local fullMoonTraining = isnight() and isfullmoon()
    local remainingText = type(trainingState) == "number" and (" (" .. tostring(trainingState) .. " left)") or ""
    status(roleLabel .. (fullMoonTraining and " Full Moon - continue training" or " training") .. remainingText)

    local nextReadyCheck = 0
    local cycleFinished = false
    function shouldStopTrainingCycle()
        if cycleFinished then return true end
        if tick() < nextReadyCheck then return false end
        nextReadyCheck = tick() + 0.8

        local state = getV4Status(true)
        if state.canTrial then
            cycleFinished = true
            status(roleLabel .. " training complete - ready for trial")
            return true
        end
        if state.complete then
            cycleFinished = true
            status(roleLabel .. " Race V4 completed")
            return true
        end
        if state.needsPurchase then
            cycleFinished = true
            status(roleLabel .. " training complete - V4 upgrade available")
            return true
        end
        return false
    end

    pcall(function()
        local energy = Players.LocalPlayer.Character:FindFirstChild("RaceEnergy")
        local transformed = Players.LocalPlayer.Character:FindFirstChild("RaceTransformed")
        if energy and energy.Value >= 1 and transformed and not transformed.Value then
            VirtualInputManager:SendKeyEvent(true, "Y", false, game)
            VirtualInputManager:SendKeyEvent(false, "Y", false, game)
        end
    end)

    local islandName = assignTrainingIsland()
    local islandData = TrainingIslandData[islandName]
    local trainingPositions = nil
    if islandData.Positions then
        trainingPositions = islandData.Positions
    elseif islandData.Position then
        trainingPositions = { islandData.Position }
    else
        status("Island has no position data")
        return false
    end

    local currentPosIndex = 1
    function getCurrentPos()
        return trainingPositions[currentPosIndex]
    end

    function advancePosition()
        currentPosIndex = currentPosIndex + 1
        if currentPosIndex > #trainingPositions then currentPosIndex = 1 end
    end

    local trainingPosition = getCurrentPos()
    if getdis(trainingPosition) >= 1500 then
        status(roleLabel .. " moving to [" .. tostring(islandName) .. "] for training")
        topos(trainingPosition)
        return false
    end

    local mobNames = {}
    for name in pairs(islandData.Mobs) do
        table.insert(mobNames, name)
    end

    while not shouldStopTrainingCycle() do
        local mob = CheckMonster(table.unpack(mobNames))
        if not mob then
            AttackConfig.AutoClickEnabled = true
            status(roleLabel .. " [" .. tostring(islandName) .. "] waiting for mobs...")
            topos(getCurrentPos())
            task.wait(0.8)
            advancePosition()
        else
            repeat
                task.wait()
                module:eq()
                module:haki()
                pcall(function()
                    local currentCharacter = Players.LocalPlayer.Character
                    local transformed = currentCharacter and currentCharacter:FindFirstChild("RaceTransformed")
                    local energy = currentCharacter and currentCharacter:FindFirstChild("RaceEnergy")
                    if transformed and transformed.Value then
                        AttackConfig.AutoClickEnabled = false
                        status(roleLabel .. " [" .. tostring(islandName) .. "] wait transform end")
                        topos(mob.HumanoidRootPart.CFrame * CFrame.new(0, 150, 0))
                    else
                        AttackConfig.AutoClickEnabled = true
                        status(roleLabel .. " [" .. tostring(islandName) .. "] killing mobs + charge")
                        topos(mob.HumanoidRootPart.CFrame * CFrame.new(0, 20, 0))
                        if energy and energy.Value >= 1 then
                            VirtualInputManager:SendKeyEvent(true, "Y", false, game)
                            VirtualInputManager:SendKeyEvent(false, "Y", false, game)
                        end
                    end
                end)
            until not checkmob_(mob) or shouldStopTrainingCycle()
        end
    end

    AttackConfig.AutoClickEnabled = true
    invalidateV4Status()
    forceReassignIsland()
    return cycleFinished
end

function runWaitingAccountWork()
    local roleLabel = isUper and "Main" or "Help"
    local fullMoonNow = isnight() and isfullmoon()
    local v4State = getV4Status(false)

    if v4State.canTrial then
        if tyrantFarmingActive then stopTyrantFarming() end
        if fullMoonNow then
            status("Full Moon + trial-ready - waiting auto pair 1 Main + 2 Help")
        else
            status("Ready for trial - waiting Full Moon and auto pair")
        end
        return
    end

    if v4State.complete then
        if tyrantFarmingActive then stopTyrantFarming() end
        status("Race V4 completed - no more training needed")
        return
    end

    if v4State.needsPurchase then
        buyPendingV4Upgrade(v4State, roleLabel)
        return
    end

    if tyrantFarmingActive then stopTyrantFarming() end
    local trainingState = v4State.remainingTraining or (v4State.needsTraining and "training" or v4State.key)
    local trainingDone = runRaceTrainingWork(trainingState, roleLabel)
    -- FIX: sau khi training xong, invalidate cache ngay để vòng lặp kế tiếp
    -- nhận canTrial=true và matchState.assigned được bật lại → trigger teleport Temple of Time
    if trainingDone then
        invalidateV4Status()
    end
end

spawn(function()
    while task.wait(0.1) do
        if not isUper and not isAlly then
            status("Set Main or Help = true")
            task.wait(2)
            continue
        end
        if not matchState or not matchState.assigned then
            runWaitingAccountWork()
            task.wait(0.2)
            continue
        end
        if matchState.main_job_id and matchState.main_job_id ~= game.JobId then
            status("Joining matched Main server")
            task.wait(1)
            continue
        end

        local pairedV4State = getV4Status(false)
        local pairedReady = pairedV4State.canTrial == true
        local pairedTrainingState = pairedV4State.remainingTraining
            or (pairedV4State.needsTraining and "training" or pairedV4State.key)

        if isUper and isMyUpgearTurn() then
            local trialOrTimerActive = isInsideOwnTrial()
            local ffaStarted = false
            pcall(function()
                ffaStarted = workspace.Map["Temple of Time"].FFABorder.Forcefield.Transparency == 0
            end)
            if trialOrTimerActive or ffaStarted then
                pairTrialCycleStarted = true
            end
        end

        if not pairedReady then
            pairTempleReadyAt = 0
            lastTempleReadyCount = 0
            local trialCycleConfirmed = pairTrialCycleStarted or pairV3ActivatedAt > 0 or handledRoundId ~= "" or isInsideOwnTrial()
            local postTrialWorkAvailable = pairedV4State.needsTraining == true or pairedV4State.needsPurchase == true
            if PAIR_RELEASE_AFTER_TRIAL and isUper and isMyUpgearTurn() and trialCycleConfirmed and postTrialWorkAvailable then
                pairTrialCycleStarted = true
                status("Trial completed - releasing pair for next Main")
                releaseCurrentGroup("trial_completed")
                task.wait(1)
                continue
            end

            if pairedV4State.complete then
                if tyrantFarmingActive then stopTyrantFarming() end
                status("Paired account has completed Race V4")
                if isUper and isMyUpgearTurn() then releaseCurrentGroup("race_v4_completed") end
                task.wait(1)
            elseif pairedV4State.needsPurchase then
                buyPendingV4Upgrade(pairedV4State, isUper and "Main" or "Help")
                task.wait(0.2)
            else
                if tyrantFarmingActive then stopTyrantFarming() end
                status("Paired but not trial-ready - continue training")
                runRaceTrainingWork(pairedTrainingState, isUper and "Main" or "Help")
                task.wait(0.2)
            end
            continue
        end

        local fullMoonNow = isnight() and isfullmoon()
        if not fullMoonNow then
            pairTempleReadyAt = 0
            lastTempleReadyCount = 0
            if PAIR_STICKY_UNTIL_TRIAL_COMPLETE then
                status("Trial-ready pair locked until this Trial is completed")
            elseif isUper and isMyUpgearTurn() and pairAssignedAt > 0 and tick() - pairAssignedAt > 8 then
                releaseCurrentGroup("full_moon_ended")
            else
                status("Trial-ready pair reserved - waiting Full Moon")
            end
            task.wait(1)
            continue
        end

        if tyrantFarmingActive then stopTyrantFarming() end

        if pairAllInJobAt > 0 and pairTempleReadyAt <= 0 then
            pairTempleReadyAt = tick()
            lastTempleReadyCount = 0
        end

        forceMatchedAccountToTemple()
        if isUper and isMyUpgearTurn() and pairTempleReadyAt > 0 then
            local timeoutAnchor = math.max(pairTempleReadyAt, lastTempleProgressAt or 0)
            if tick() - timeoutAnchor > PAIR_TEMPLE_TIMEOUT then
                local readyCount = 0
                pcall(function() readyCount = select(1, readReadyFiles()) end)

                if readyCount > lastTempleReadyCount then
                    lastTempleReadyCount = readyCount
                    pairTempleReadyAt = tick()
                elseif readyCount < 3 and not isInsideOwnTrial() then
                    if PAIR_STICKY_UNTIL_TRIAL_COMPLETE then
                        pairTempleReadyAt = tick()
                        lastTempleProgressAt = tick()
                        lastTempleDistance = math.huge
                        readySent = false
                        status("Temple ready timeout - keeping pair until Trial completes")
                    else
                        releaseCurrentGroup("temple_ready_timeout")
                        task.wait(1)
                        continue
                    end
                end
            end
        end

        local doorCallOk, doorResult = pcall(function()
            return ReplicatedStorage.Remotes.CommF_:InvokeServer("CheckTempleDoor")
        end)
        local checktempledoor = doorCallOk and doorResult == true
        if not checktempledoor then
            status(doorCallOk and "Temple door is not available yet" or "CheckTempleDoor remote failed")
            task.wait(0.5)
        else
            _G.ShouldSendData = false
            local ab, AB = trialable()
            if not ab then
                if AB == "raiding" then
                    local boss = workspace.Enemies:FindFirstChild("Cake Prince") 
                        or workspace.Enemies:FindFirstChild("Dough King")
                    if boss then
                        repeat wait()
                            pcall(function() topos(boss.HumanoidRootPart.CFrame * CFrame.new(0, 25, 0)) end)
                            module:eq()
                            module:haki()
                        until not checkmob_(boss)
                    end
                elseif AB == "training" or type(AB) == "number" then
                    -- Sau trial, needsTraining -> chạy training đúng island
                    status("Not trial-ready -> running training work")
                    runWaitingAccountWork()
                    task.wait(0.5)
                else
                    -- Các state khác (needsPurchase, v.v.)
                    runWaitingAccountWork()
                    task.wait(0.5)
                end
            end
            _G.ShouldSendData = true
            if not workspace.Map:FindFirstChild("Temple of Time") then
                local templeRef = ReplicatedStorage.MapStash:FindFirstChild("Temple of Time")
                if templeRef then templeRef.Parent = workspace.Map end
            elseif workspace.Map["Temple of Time"].FFABorder.Forcefield.Transparency == 0 then
                if isMain then
                    status("Killing players after trial...")
                    for plr, i in pairs(getplayers(true)) do
                        if plr then
                            repeat
                                task.wait()
                                pcall(function()
                                    topos(plr.HumanoidRootPart.CFrame * CFrame.new((function()
                                        local x, y, z = 0, 3, 0
                                        x = math.random(1, 4); z = math.random(1, 4)
                                        if math.random(1, 2) == 1 then x = x * -1 end
                                        if math.random(1, 2) == 1 then z = z * -1 end
                                        return x, y, z
                                    end)()))
                                end)
                            until not plr or not plr.Parent or not plr:FindFirstChild("Humanoid")
                                or not plr:FindFirstChild("HumanoidRootPart") or plr.Humanoid.Health <= 0
                                or workspace.Map["Temple of Time"].FFABorder.Forcefield.Transparency == 1
                        end
                    end
                -- Main (isUper and isMyUpgearTurn()) KHÔNG BAO GIỜ tự reset
                -- character trong lúc trial đang chạy, bất kể vai trò cũ
                -- của API trả về đúng/sai. Chỉ Help (Ally hoặc Helper không
                -- phải lượt) mới reset để dọn đường cho Main.
                elseif isUper and isMyUpgearTurn() then
                    status("Main is in trial - never auto-reset")
                elseif isAlly then
                    status("Resetting after trial...")
                    Players.LocalPlayer.Character.Humanoid.Health = 0
                elseif isUper and not isMyUpgearTurn() then
                    status("Helper - resetting after trial...")
                    Players.LocalPlayer.Character.Humanoid.Health = 0
                end
            else
                local race_trial_place
                if races_trial_place[Players.LocalPlayer.Data.Race.Value] then
                    race_trial_place = races_trial_place[Players.LocalPlayer.Data.Race.Value]
                end
                if race_trial_place and getdis(race_trial_place.CFrame) < 1500 then
                    status("Doing trial")
                    local myrace = Players.LocalPlayer.Data.Race.Value
                    if myrace == "Mink" then
                        topos(workspace.Map.MinkTrial.Ceiling.CFrame * CFrame.new(0, -20, 0))
                    elseif myrace == "Skypiea" then
                        pcall(function() topos(workspace.Map.SkyTrial.Model.FinishPart.CFrame) end)
                    elseif myrace == "Cyborg" then
                        pcall(function() topos(workspace.Map.CyborgTrial.Floor.CFrame * CFrame.new(0, 500, 0)) end)
                    elseif myrace == "Human" or myrace == "Ghoul" then
                        for i, v in pairs(workspace.Enemies:GetChildren()) do
                            if v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                                if getdis(v.HumanoidRootPart.CFrame, race_trial_place.CFrame) < 1500 then
                                    repeat
                                        task.wait(); module:eq(); module:haki()
                                        pcall(function() topos(v:FindFirstChild("HumanoidRootPart").CFrame * CFrame.new(0, 30, 0)) end)
                                    until not v or not v:FindFirstChild("HumanoidRootPart") or not v:FindFirstChild("Humanoid") or v.Humanoid.Health <= 0
                                end
                            end
                        end
                    elseif myrace == "Fishman" then
                        for i, v in pairs(workspace.SeaBeasts:GetChildren()) do
                            pcall(function()
                                if v:FindFirstChild("Health") and v.Health.Value > 0 and v:FindFirstChild("HumanoidRootPart") and getdis(v.HumanoidRootPart.CFrame, race_trial_place) < 1500 then
                                    repeat
                                        task.wait()
                                        if not Players.LocalPlayer.Backpack:FindFirstChild("Sharkman Karate") then
                                            ReplicatedStorage.Remotes.CommF_:InvokeServer("BuySharkmanKarate")
                                        end
                                        topos(v.HumanoidRootPart.CFrame * CFrame.new(0, 500, 0))
                                        _G.SHOULDSPAMSKILLS = true
                                    until not v or not v:FindFirstChild("Health") or v.Health.Value <= 0 or not v:FindFirstChild("HumanoidRootPart")
                                    _G.SHOULDSPAMSKILLS = false
                                end
                            end)
                        end
                    end
                else
                    if Players.LocalPlayer.PlayerGui.Main.Timer.Visible == false then
                        local khang = nil
                        local timeout = 0
                        repeat
                            task.wait(); khang = getdoor(); timeout = timeout + 1
                            if timeout > 300 then break end
                        until khang ~= nil
                        if khang and getdis(khang.CFrame) < 1500 then
                            topos(khang.CFrame)
                            status("At door - waiting")
                            if trialable() then
                                if isUper then
                                    if isMyUpgearTurn() then
                                        readySent = true
                                        status("Ready trials")
                                    else
                                        readySent = false
                                        status("waiting my turn")
                                        task.wait(1)
                                    end
                                elseif isAlly then
                                    readySent = true
                                    status("Helper ready")
                                end
                            else
                                if isUper and not isMyUpgearTurn() then
                                    status("waiting turn")
                                    task.wait(1)
                                end
                            end
                        else
                            ReplicatedStorage.Remotes.CommF_:InvokeServer("requestEntrance", Vector3.new(28310.0234, 14895.1123, 109.456741))
                        end
                    end
                end
            end

            if tryActivateAbility() then task.wait(0.2) end
        end
    end
end)

local fruits = {
    ["Buddha-Buddha"] = true, ["T-Rex-T-Rex"] = true, ["Dragon-Dragon"] = true, ["Yeti-Yeti"] = true,
    ["Leopard-Leopard"] = true, ["Venom-Venom"] = true, ["Phoenix-Phoenix"] = true, ["Kitsune-Kitsune"] = true,
    ["Mammoth-Mammoth"] = true, ["Gas-Gas"] = true, ["Portal-Portal"] = true
}
local isvalidtooltip = { ["Melee"] = true, ["Blox Fruit"] = true, ["Sword"] = true, ["Gun"] = true }
local isvalidnameui = { ["Z"] = true, ["X"] = true, ["C"] = true, ["V"] = true, ["F"] = true }

function getallweapon()
    local weapon = {}
    for i, v in pairs(Players.LocalPlayer.Backpack:GetChildren()) do
        if v:IsA("Tool") and isvalidtooltip[v.ToolTip] then table.insert(weapon, v) end
    end
    for i, v in pairs(Players.LocalPlayer.Character:GetChildren()) do
        if v:IsA("Tool") and isvalidtooltip[v.ToolTip] then table.insert(weapon, v) end
    end
    return weapon
end

function EquipTool(v)
    local thua = Players.LocalPlayer.Backpack:FindFirstChild(v)
    if thua then Players.LocalPlayer.Character.Humanoid:EquipTool(thua) end
end

_G.SHOULDSPAMSKILLS = false

spawn(function()
    while task.wait(0.1) do
        if _G.SHOULDSPAMSKILLS then
            local weapon = getallweapon()
            for i, v in pairs(weapon) do
                if not Players.LocalPlayer.PlayerGui.Main.Skills:FindFirstChild(v.Name) then EquipTool(v.Name) end
            end
            for i, v in pairs(weapon) do
                if v.Parent ~= Players.LocalPlayer.Character then EquipTool(v.Name) end
                local ui = Players.LocalPlayer.PlayerGui.Main.Skills:FindFirstChild(v.Name)
                if ui then
                    for _, vl in pairs(ui:GetChildren()) do
                        if isvalidnameui[vl.Name] then
                            local cooldown_frame = vl:WaitForChild("Cooldown")
                            local title_frame = vl:WaitForChild("Title")
                            if title_frame.TextColor3 == Color3.new(1, 1, 1) or title_frame.TextColor3 == Color3.fromRGB(255, 255, 255) then
                                if cooldown_frame.Size == UDim2.new(0, 0, 1, -1) then
                                    if vl.Name == "V" then
                                        if not fruits[ui.Name] then
                                            game:service("VirtualInputManager"):SendKeyEvent(true, "V", false, game)
                                            task.wait(0.1)
                                            game:service("VirtualInputManager"):SendKeyEvent(false, "V", false, game)
                                            task.wait(1.5)
                                        end
                                    else
                                        game:service("VirtualInputManager"):SendKeyEvent(true, vl.Name, false, game)
                                        task.wait(0.1)
                                        game:service("VirtualInputManager"):SendKeyEvent(false, vl.Name, false, game)
                                        task.wait(1.5)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

local Ec = Players.LocalPlayer
function Bc(x)
    if not x then return false end
    local L = x:FindFirstChild("Humanoid")
    return L and L["Health"] > 0
end
function Pc(x, L)
    local V = Players:GetPlayers()
    local H = {}
    local r = (x:GetPivot())["Position"]
    local leader = Players:FindFirstChild(mainAccountName)
    for _, a in ipairs(V) do
        if a ~= Ec and a ~= leader and a["Character"] and noideaforname(a) then
            local xp = a["Character"]:FindFirstChild("HumanoidRootPart")
            if xp and Bc(a["Character"]) then
                if (xp["Position"] - r)["Magnitude"] <= L then table["insert"](H, a["Character"]) end
            end
        end
    end
    for _, a in ipairs(workspace["Enemies"]:GetChildren()) do
        local xp = a:FindFirstChild("HumanoidRootPart")
        if a ~= leader and xp and Bc(a) then
            if (xp["Position"] - r)["Magnitude"] <= L then table["insert"](H, a) end
        end
    end
    return H
end
--https://fi12.bot-hosting.cloud:20777/noguchi?name=
function gettimeserver()
    return tonumber(game:HttpGet("https://fi12.bot-hosting.cloud:20777/timeserver"))
end

spawn(function()
    while task.wait(1) do
        if _G.ShouldSendData then
            (http_request or http and http.request or request)({
                Url = "https://baorph.x10.mx/data/apiv4.php?route=baor",
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = HttpService:JSONEncode({ 
                    username = Players.LocalPlayer.Name, 
                    jobid = game.JobId 
                })
            })
        end
    end
end)


function hopRandom()
    local ServerBrowser = ReplicatedStorage:WaitForChild("__ServerBrowser")
    for i = 1, 100 do
        local ok, servers = pcall(function() return ServerBrowser:InvokeServer(i) end)
        if ok and servers then
            for jobId, info in pairs(servers) do
                if jobId ~= game.JobId and (info.Count or 0) < 12 then
                    pcall(function() ServerBrowser:InvokeServer("teleport", jobId) end)
                    task.wait(0.3)
                    return true
                end
            end
        end
    end
    return false
end

local trialDoneHandled = false
local postTrialHopDone = false  -- *** THÊM FLAG NÀY ***

spawn(function()
    while task.wait(1) do
        if not isUper then
            trialDoneHandled = false
            postTrialHopDone = false
            continue
        end

        local v4state = nil
        pcall(function() v4state = getV4Status() end)
        if not v4state then continue end
        local trialJustDone = v4state.needsTraining == true or v4state.needsPurchase == true

        if trialJustDone and not trialDoneHandled and not postTrialHopDone then
            trialDoneHandled = true
            postTrialHopDone = true  -- *** LOCK, không hop nữa trong session này ***

            if v4state.needsTraining then
                status("Trial xong -> can training -> UpdateRoles + hop farm mob")
            elseif v4state.needsPurchase then
                status("Trial xong -> can mua upgrade -> UpdateRoles + hop")
            end

            if getgenv().UpdateRoles then
                pcall(getgenv().UpdateRoles)
            end

            -- Chờ 10s rồi reset character để respawn gần spawn point
            -- → rút ngắn khoảng cách tween đến training island sau trial
            task.spawn(function()
                task.wait(10)
                pcall(function()
                    local char = Players.LocalPlayer.Character
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        status("Auto-reset sau trial → rút ngắn tween đến training island")
                        hum.Health = 0
                    end
                end)
            end)

            matchState = {
                assigned = false,
                group_id = "",
                main_username = mainAccountName,
                main_job_id = game.JobId,
                helpers = {},
                all_in_job = false,
            }
            releaseCurrentGroup("trial_done_hop")
            task.wait(1)
        end

        -- *** CHỈ reset trialDoneHandled, KHÔNG reset postTrialHopDone ***
        -- postTrialHopDone chỉ reset khi v4 complete hoặc canTrial lại
        if not trialJustDone and v4state.complete ~= true then
            trialDoneHandled = false
            -- postTrialHopDone GIỮ NGUYÊN để không hop lại
        end

        -- Reset hoàn toàn khi v4 complete hoặc canTrial (vòng mới)
        if v4state.complete or v4state.canTrial then
            trialDoneHandled = false
            postTrialHopDone = false
        end
    end
end)
_G[Players.LocalPlayer.Name] = true
getgenv().UseSeaUi = true

function createUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "NoNameHubUI"
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = CoreGui

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 1, 0)
    Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Frame.BackgroundTransparency = 0.3
    Frame.Parent = ScreenGui

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0.12, 0)
    Title.Position = UDim2.new(0, 0, 0.10, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "kaitunv4"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextScaled = true
    Title.Font = Enum.Font.Arcade
    Title.Parent = Frame

    local Icon = Instance.new("ImageLabel")
    Icon.Size = UDim2.new(0, 220, 0, 220)
    Icon.Position = UDim2.new(0.5, -110, 0.12, 0)
    Icon.BackgroundTransparency = 1
    Icon.Image = "rbxassetid://"
    Icon.Parent = Frame

    local PlayerInfo = Instance.new("TextLabel")
    PlayerInfo.Size = UDim2.new(1, 0, 0.055, 0)
    PlayerInfo.Position = UDim2.new(0, 0, 0.49, 0)
    PlayerInfo.BackgroundTransparency = 1
    PlayerInfo.Text = "Player: Loading..."
    PlayerInfo.TextColor3 = Color3.fromRGB(255, 255, 255)
    PlayerInfo.TextScaled = true
    PlayerInfo.Font = Enum.Font.Arcade
    PlayerInfo.Parent = Frame

    local FragmentInfo = Instance.new("TextLabel")
    FragmentInfo.Size = UDim2.new(1, 0, 0.05, 0)
    FragmentInfo.Position = UDim2.new(0, 0, 0.54, 0)
    FragmentInfo.BackgroundTransparency = 1
    FragmentInfo.Text = "Fragments: 0"
    FragmentInfo.TextColor3 = Color3.fromRGB(255, 255, 255)
    FragmentInfo.TextScaled = true
    FragmentInfo.Font = Enum.Font.Arcade
    FragmentInfo.Parent = Frame

    local V4Info = Instance.new("TextLabel")
    V4Info.Size = UDim2.new(0.94, 0, 0.07, 0)
    V4Info.Position = UDim2.new(0.03, 0, 0.595, 0)
    V4Info.BackgroundTransparency = 1
    V4Info.Text = "V4: Checking..."
    V4Info.TextColor3 = Color3.fromRGB(255, 220, 90)
    V4Info.TextScaled = true
    V4Info.TextWrapped = true
    V4Info.Font = Enum.Font.Arcade
    V4Info.Parent = Frame

    local Status = Instance.new("TextLabel")
    Status.Size = UDim2.new(0.94, 0, 0.075, 0)
    Status.Position = UDim2.new(0.03, 0, 0.67, 0)
    Status.BackgroundTransparency = 1
    Status.Text = "Status: Loading..."
    Status.TextColor3 = Color3.fromRGB(255, 255, 255)
    Status.TextScaled = true
    Status.TextWrapped = true
    Status.Font = Enum.Font.Arcade
    Status.Parent = Frame

    local JobIdBox = Instance.new("TextBox")
    JobIdBox.Size = UDim2.new(0.46, 0, 0.065, 0)
    JobIdBox.Position = UDim2.new(0.27, 0, 0.78, 0)
    JobIdBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    JobIdBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    JobIdBox.PlaceholderText = "Input Job ID"
    JobIdBox.PlaceholderColor3 = Color3.fromRGB(170, 170, 170)
    JobIdBox.Text = ""
    JobIdBox.Font = Enum.Font.Arcade
    JobIdBox.TextScaled = true
    JobIdBox.ClearTextOnFocus = false
    JobIdBox.Parent = Frame

    local JoinButton = Instance.new("TextButton")
    JoinButton.Size = UDim2.new(0.24, 0, 0.065, 0)
    JoinButton.Position = UDim2.new(0.38, 0, 0.86, 0)
    JoinButton.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
    JoinButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    JoinButton.Text = "Join Job ID"
    JoinButton.Font = Enum.Font.Arcade
    JoinButton.TextScaled = true
    JoinButton.Parent = Frame

    return ScreenGui, Status, JobIdBox, JoinButton, PlayerInfo, FragmentInfo, V4Info
end

local UI, StatusLabel, JobIdBox, JoinButton, PlayerInfoLabel, FragmentInfoLabel, V4InfoLabel = createUI()

function status(text)
    currentTaskStatus = tostring(text or "idle")
    if StatusLabel then StatusLabel.Text = "Status: " .. currentTaskStatus end
end

status("idle")

function formatNumber(value)
    local text = tostring(math.floor(tonumber(value) or 0))
    while true do
        local replaced, count = text:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
        text = replaced
        if count == 0 then break end
    end
    return text
end

function formatV4Info(v4State)
    v4State = v4State or { label = "UNKNOWN", energy = 0, transformed = false }
    local energyPercent = math.floor(math.clamp(tonumber(v4State.energy) or 0, 0, 1) * 100 + 0.5)
    local transformText = v4State.transformed and "ON" or "OFF"
    local detail = ""

    if v4State.needsPurchase then
        detail = " | Cost: " .. formatNumber(v4State.cost) .. " F"
    elseif v4State.code == 6 then
        detail = " | Sessions: " .. tostring(v4State.completedTraining or 0) .. "/3"
    elseif v4State.code == 8 then
        detail = " | Remaining: " .. tostring(v4State.remainingTraining or 0)
    elseif v4State.canTrial and v4State.gear ~= nil then
        detail = " | Gear: " .. tostring(v4State.gear)
    elseif v4State.code ~= nil then
        detail = " | State: " .. tostring(v4State.code)
    elseif v4State.progress ~= nil then
        detail = " | Quest: " .. tostring(v4State.progress)
    end

    return "V4: " .. tostring(v4State.label or "UNKNOWN")
        .. detail
        .. " | Energy: " .. tostring(energyPercent) .. "%"
        .. " | Transform: " .. transformText
end

function getV4StatusColor(v4State)
    if v4State and v4State.complete then return Color3.fromRGB(90, 220, 255) end
    if v4State and v4State.canTrial then return Color3.fromRGB(90, 255, 130) end
    if v4State and v4State.needsPurchase then return Color3.fromRGB(255, 170, 70) end
    if v4State and v4State.needsTraining then return Color3.fromRGB(255, 220, 90) end
    return Color3.fromRGB(255, 255, 255)
end

task.spawn(function()
    while task.wait(0.5) do
        local fragments = 0
        local race = "Unknown"
        pcall(function()
            fragments = Players.LocalPlayer.Data.Fragments.Value
            race = Players.LocalPlayer.Data.Race.Value
        end)
        local roleText = isUper and "MAIN" or (isAlly and "HELP" or "NONE")
        local pairText = matchState and matchState.assigned and "PAIRED" or "WAITING"
        local moonText = (isnight() and isfullmoon()) and "FULL MOON" or "NO FULL MOON"
        local v4State = getV4Status(false)
        if PlayerInfoLabel then
            PlayerInfoLabel.Text = "Player: " .. USERNAME .. " | Role: " .. roleText .. " | Race: " .. tostring(race)
        end
        if FragmentInfoLabel then
            FragmentInfoLabel.Text = "Fragments: " .. formatNumber(fragments) .. " | Pair: " .. pairText .. " | " .. moonText
        end
        if V4InfoLabel then
            V4InfoLabel.Text = formatV4Info(v4State)
            V4InfoLabel.TextColor3 = getV4StatusColor(v4State)
        end
    end
end)

JoinButton.MouseButton1Click:Connect(function()
    local raw = JobIdBox.Text:gsub("%s+", "")
    if raw == "" then status("Input empty"); return end
    status("Joining...")
    local ok = pcall(function() ReplicatedStorage:WaitForChild("__ServerBrowser"):InvokeServer("teleport", raw) end)
    if not ok then status("Join failed") else status("Teleporting...") end
end)
