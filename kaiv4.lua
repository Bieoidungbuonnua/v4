if not game:IsLoaded() then
    pcall(function() game.Loaded:Wait() end)
end

local _Players_init = game:GetService("Players")
local _LP_init = _Players_init.LocalPlayer
while not _LP_init do
    task.wait(0.1)
    _LP_init = _Players_init.LocalPlayer
end

pcall(function()
    if not _LP_init:FindFirstChild("DataLoaded") then
        _LP_init:WaitForChild("DataLoaded", 15)
    end
end)

-- ══════════════════════════════════════════════════════════════════
-- CẤU HÌNH DÙNG CHUNG (Tất cả 3 script tự động nhận từ JoinV4Config)
-- ══════════════════════════════════════════════════════════════════
local _DEFAULT_CFG = {
    ["Key-Banana"]        = "31d4bebb966b95e8bd94d7a6",
    ["Helper"]            = {
        {"Cart3rRid3rDrag0n", "penel0peScott1"},
    },
    ["Note"]              = {"trietautov4"},
    ["LimitMainPerGroup"] = 10,   -- tối đa main được vào mỗi group
}

if not getgenv().JoinV4Config or type(getgenv().JoinV4Config) ~= "table" then
    getgenv().JoinV4Config = _DEFAULT_CFG
else
    for k, v in pairs(_DEFAULT_CFG) do
        if getgenv().JoinV4Config[k] == nil then
            getgenv().JoinV4Config[k] = v
        end
    end
end

-- Tự động build HelperList phẳng từ JoinV4Config.Helper cho BNN & TurnV3
do
    local seen, list = {}, {}
    for _, grp in ipairs(getgenv().JoinV4Config["Helper"] or {}) do
        if type(grp) == "table" then
            for _, name in ipairs(grp) do
                local clean = tostring(name):gsub("^%s+", ""):gsub("%s+$", "")
                if clean ~= "" and not seen[clean] then
                    seen[clean] = true
                    table.insert(list, clean)
                end
            end
        elseif type(grp) == "string" then
            local clean = grp:gsub("^%s+", ""):gsub("%s+$", "")
            if clean ~= "" and not seen[clean] then
                seen[clean] = true
                table.insert(list, clean)
            end
        end
    end
    getgenv().HelperList = list
end

-- ══════════════════════════════════════════════════════════════════
-- [MOONCHECK] (mooncheck.lua) - Moon Texture & MoonPhase GUI
-- ══════════════════════════════════════════════════════════════════
do
    local P = game:GetService("Players")
    local L = P.LocalPlayer
    local RS = game:GetService("RunService")

    local function CheckSea(v)
        local attr = workspace:GetAttribute("MAP")
        if not attr then return false end
        return v == tonumber(tostring(attr):match("%d+"))
    end
    getgenv().CheckSea = CheckSea

    local CheckMoon = newcclosure(function()
        local t = (CheckSea(1) or CheckSea(3))
            and ((game.Lighting:FindFirstChild("Sky") and game.Lighting.Sky.MoonTextureId)
            or (game.Lighting:FindFirstChild("Space_Skybox") and game.Lighting.Space_Skybox.MoonTextureId))
            or (CheckSea(2) and game.Lighting:FindFirstChild("FantasySky") and game.Lighting.FantasySky.MoonTextureId)
            or ""
        t = t:gsub("rbxassetid://","http://www.roblox.com/asset/?id=")
        return ({
            ["http://www.roblox.com/asset/?id=15493317929"]="Blue Moon",
            ["http://www.roblox.com/asset/?id=9709149431"]="8/8",
            ["http://www.roblox.com/asset/?id=9709149052"]="7/8",
            ["http://www.roblox.com/asset/?id=9709143733"]="6/8",
            ["http://www.roblox.com/asset/?id=9709150401"]="5/8",
            ["http://www.roblox.com/asset/?id=9709135895"]="4/8",
            ["http://www.roblox.com/asset/?id=9709150086"]="2/8",
            ["http://www.roblox.com/asset/?id=9709139597"]="1/8",
            ["http://www.roblox.com/asset/?id=9709149680"]="0/8",
        })[t] or "nil"
    end)
    getgenv().CheckMoon = CheckMoon

    local CheckMoonPhase = newcclosure(function()
        local m = game.Lighting:GetAttribute("MoonPhase")
        if not m then return "Unknown","Unknown Phase",nil end
        if m > 5 then return "Fake Moon","Fake Moon",m
        elseif m < 5 then return "Bad Moon","Bad Moon",m
        elseif m == 5 and not getgenv().isfmended then return "Full Moon","Full Moon Up",m
        elseif m == 5 and getgenv().isfmended then return "Ended","Full Moon End",m end
    end)
    getgenv().CheckMoonPhase = CheckMoonPhase

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

    getgenv().IsNight = IsNight
    getgenv().ToStart = ToStart
    getgenv().ToEnd   = ToEnd
    getgenv().S2T     = S2T
    getgenv().HMS     = HMS

    -- HÀM TRUY XUẤT DỮ LIỆU MOON DÙNG CHUNG CHO TOÀN BỘ SCRIPT
    local function GetMoonData()
        local ms = "nil"
        if type(CheckMoon) == "function" then
            ms = CheckMoon() or "nil"
        end

        local ps, phaseName, pv = "Unknown", "Unknown Phase", nil
        if type(CheckMoonPhase) == "function" then
            ps, phaseName, pv = CheckMoonPhase()
        end

        local ct = game.Lighting.ClockTime
        local ts = ToStart()
        local te = ToEnd()
        local isNightNow = IsNight(ct)
        local isFM = (ms == "8/8" or ms == "Blue Moon") and (ps == "Full Moon") and not getgenv().isfmended
        -- Server được coi là hợp lệ (ở lại) nếu có Full Moon và (đang đêm ts == 0 HOẶC time to night ts <= 300s)
        local isValidFM = isFM and (isNightNow or (ts >= 0 and ts <= 300))

        return {
            MoonStatus  = ms,
            PhaseStatus = ps,
            PhaseName   = phaseName,
            PhaseValue  = pv,
            ClockTime   = ct,
            ToStart     = ts,
            ToEnd       = te,
            IsNight     = isNightNow,
            IsFullMoon  = isFM,
            IsValidFM   = isValidFM,
        }
    end
    getgenv().GetMoonData = GetMoonData

    local function CreateGUI()
        local pg = L:FindFirstChildOfClass("PlayerGui") or L:WaitForChild("PlayerGui", 10)
        if not pg then return nil, nil end
        local g = pg:FindFirstChild("MoonStatusGUI")
        if g then g:Destroy() end
        g = Instance.new("ScreenGui")
        g.Name = "MoonStatusGUI"
        g.ResetOnSpawn = false
        g.IgnoreGuiInset = true
        g.DisplayOrder = 999999999
        g.ZIndexBehavior = Enum.ZIndexBehavior.Global
        g.Enabled = false
        g.Parent = pg
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

    local G, Lb = CreateGUI()

    local function Upd()
        if not G or not G.Parent or not Lb or not Lb.Parent then
            G, Lb = CreateGUI()
            if not G then return end
        end
        local data = GetMoonData()
        local ms = data.MoonStatus
        local ps = data.PhaseStatus
        local pv = data.PhaseValue
        local ct = data.ClockTime
        local ts = data.ToStart
        local te = data.ToEnd
        local tsStr, teStr = S2T(ts), S2T(te)
        local pc = #P:GetPlayers()
        local isFull = data.IsFullMoon
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
end

-- ══════════════════════════════════════════════════════════════════
-- [1/3] BNN (Banana Hub) - Whitelist từ HelperList chung
-- ══════════════════════════════════════════════════════════════════
do
    local player = game:GetService("Players").LocalPlayer
    local username = player.Name

    local specialUsers = {}
    for _, name in ipairs(getgenv().HelperList or {}) do
        specialUsers[name] = true
    end

    local cfgJoin = getgenv().JoinV4Config or {}
    local rawKey = cfgJoin["Key-Banana"] or cfgJoin["KeyBanana"] or cfgJoin["Key_Banana"] or cfgJoin["Key"] or getgenv().Key
    getgenv().Key = (type(rawKey) == "string" and rawKey ~= "") and rawKey or "31d4bebb966b95e8bd94d7a6"

    if specialUsers[username] then
        -- CONFIG 1 (Cho acc Helper)
        print("[Config] Applying Config 1 for Helper: " .. username)
        getgenv().Config = {
            ["Select Team"]                = "Marine",
            ["Auto Reset Character"]       = true,
            ["Auto Choose Gears"]          = true,
            ["Auto Buy Gear"]              = true,
            ["Auto Finish Train Quest"]    = true,
            ["Stack Train With Trial Race"] = true,
            ["Auto Trial"]                 = true,
        }
    else
        -- CONFIG 2 (Cho acc Chính / Main)
        print("[Config] Applying Config 2 for Main: " .. username)
        getgenv().Config = {
            ["Select Team"]                              = "Marine",
            ["Stack Train With Trial Race"]              = true,
            ["Auto Trial"]                               = true,
            ["Auto Buy Gear"]                            = true,
            ["Auto Choose Gears"]                        = true,
            ["Select Weapon Attack Trial"]               = "Melee",
            ["Kill players When complete Trial"]         = true,
            ["Just Use Skill when Player Active Ken"]    = true,
            ["Use Skill when Kill Player"]               = false,
            ["Auto Finish Train Quest"]                  = true,
            ["Auto Store Fruit"]                         = true,
            ["Select Weapon"]                            = "Melee",
            ["Auto Turn On V3 Near Door"]                = true,
            ["Bring Mob Count"]                          = 6,
            ["Auto Click"]                               = true,
            ["Use skill fast dont hold"]                 = true,
            ["Reset Teleport"]                           = true,
        }
    end

    task.spawn(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/x2RunE/Immortal/refs/heads/main/Lotus_BF_Main.lua"))()
    end)
end

-- ══════════════════════════════════════════════════════════════════
-- [2/3] TURNV3 (Đồng bộ V3 Countdown & Watchdog Ghost Temple)
-- ══════════════════════════════════════════════════════════════════
do
    local V3_COUNTDOWN      = 6
    local V3_FILE_POLL      = 0.05
    local V3_READY_FRESH    = 5.0
    local V3_FIRE_COUNT     = 3
    local V3_FIRE_INTERVAL  = 0.05
    local V3_DOOR_DIST      = 65
    local FILE_ROOT         = "TurnV3"

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
    local LOCAL_HELPERS   = {}
    local HelpWhitelist   = {}
    do
        local seen = {}
        for _, raw in ipairs(getgenv().HelperList or {}) do
            local name = tostring(raw):match("^%s*(.-)%s*$")
            if name ~= "" and not seen[name] then
                seen[name] = true
                table.insert(LOCAL_HELPERS, name)
                HelpWhitelist[name] = true
            end
        end
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
                    invalidateV4Cache()
                    task.spawn(function()
                        task.wait(8)
                        invalidateV4Cache()
                    end)
                end
            end)
        end
    end)

    -- HOP RANDOM AFTER TRIAL / TRAINING LOOP (chạy mỗi 5s)
    local lastRandomHopAt = 0
    task.spawn(function()
        task.wait(25)
        while task.wait(5) do
            pcall(function()
                if isAlly then return end

                local fmNow = isnight() and isfullmoon()
                if fmNow then return end

                if type(getgenv().GetMoonData) == "function" then
                    local md = getgenv().GetMoonData()
                    if md and md.IsValidFM then return end
                end

                local v4 = getV4StatusSimple()
                if not v4 or v4.key == nil then return end
                if v4 and (v4.needsTraining or v4.needsPurchase) then
                    setStatus((isUper and "Main" or "Helper") .. " | Dang training...")
                    return
                end
                if v4.canTrial then setStatus("Main | Trial ready - stay"); return end
                if v4.complete then setStatus("Main | V4 complete - wait FM"); return end

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

-- ══════════════════════════════════════════════════════════════════
-- [3/3] JOINV4 (Kaiv4-BNN/joinv4.lua) - Full Group Parallel Hop & Stage Join
-- ══════════════════════════════════════════════════════════════════
;(function()
    local CFG = getgenv().JoinV4Config

    -- API / TIMING CONSTANTS
    local API_BASE          = "http://mbasic7.pikamc.vn:25082"
    local SYNC_INTERVAL     = 1.5   -- giây giữa các lần sync trạng thái lên API
    local HOP_STARTUP_DELAY = 3     -- giây trước khi bắt đầu hop
    local FILE_ROOT         = "JoinV4"

    -- SERVICES
    local HttpService       = game:GetService("HttpService")
    local Players           = game:GetService("Players")
    local TeleportService   = game:GetService("TeleportService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local CoreGui           = game:GetService("CoreGui")
    local Lighting          = game:GetService("Lighting")

    local Player   = Players.LocalPlayer
    local USERNAME = Player.Name

    -- PARSE CONFIG -> MULTI-GROUP ROLE DETECTION
    local function trim(s)
        return tostring(s):gsub("^%s+", ""):gsub("%s+$", "")
    end

    local helperGroups = CFG["Helper"] or {}
    local noteList     = CFG["Note"]   or {}

    local myDefaultGroup = trim(noteList[1] or "trietautov4")

    local AllHelperSet = {}
    local MY_GROUP_IDX     = nil
    local MY_GROUP_NOTE    = nil
    local MY_GROUP_HELPERS = {}

    for i, helperList in ipairs(helperGroups) do
        if type(helperList) == "table" then
            local note = trim(noteList[i] or ("group" .. i))
            for _, h in ipairs(helperList) do
                h = trim(h)
                if h ~= "" then
                    AllHelperSet[h] = true
                    if h == USERNAME then
                        MY_GROUP_IDX     = i
                        MY_GROUP_NOTE    = note
                        MY_GROUP_HELPERS = helperList
                    end
                end
            end
        end
    end

    local isHelper = AllHelperSet[USERNAME] == true
    local isMain   = not isHelper

    local GROUP_ID = isHelper and (MY_GROUP_NOTE or trim(noteList[1] or "joinv4")) or ""
    local myAssignedGroupId = ""

    local MY_HelperSet = {}
    for _, h in ipairs(MY_GROUP_HELPERS) do
        h = trim(h)
        if h ~= "" then
            MY_HelperSet[h] = true
        end
    end

    -- STATE
    local currentStatus = "Starting..."
    local function setStatus(txt)
        currentStatus = tostring(txt or "")
    end

    -- ════════════ FILE SYNC CHO JOINV4 WORKSPACE ════════════
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

    local function groupFolder()
        if not safeMakeFolder(FILE_ROOT) then return nil end
        local folder = FILE_ROOT .. "/group"
        if not safeMakeFolder(folder) then return nil end
        return folder
    end

    local function ownClaimPath()
        local f = groupFolder(); if not f then return nil end
        return f .. "/claim_" .. sanitize(USERNAME) .. ".json"
    end

    -- MOON CHECK HÀM LIÊN KẾT TRỰC TIẾP TỪ [MOONCHECK]
    local function isFMServerValid()
        local data = (type(getgenv().GetMoonData) == "function" and getgenv().GetMoonData()) or nil
        if data then
            return data.IsValidFM == true, (data.ToStart or 0), data
        end

        local ok, res, tt, fbData = pcall(function()
            local ms = "nil"
            if type(CheckMoon) == "function" then
                ms = CheckMoon() or "nil"
            end

            local ps, _, pv = "Unknown", nil, nil
            if type(CheckMoonPhase) == "function" then
                ps, _, pv = CheckMoonPhase()
            end

            local ct = Lighting.ClockTime
            local isNightNow = ct >= 18 or ct < 6
            local toStart = 0
            if not isNightNow then
                local d = ct < 18 and (18 - ct) or 0
                toStart = math.floor((d / 24) * 1200)
            end

            local isFull = (ms == "8/8" or ms == "Blue Moon") and (ps == "Full Moon") and not getgenv().isfmended
            local valid = isFull and (isNightNow or (toStart >= 0 and toStart <= 300))
            return valid, toStart, {
                MoonStatus = ms,
                PhaseStatus = ps,
                ClockTime = ct,
                ToStart = toStart,
                IsNight = isNightNow,
                IsFullMoon = isFull,
                IsValidFM = valid
            }
        end)
        if ok and res == true then
            return true, (tt or 0), fbData
        end
        return false, (tt or 0), fbData
    end

    local function isPreFMReady()
        local ok, tt = isFMServerValid()
        return ok and (tt > 0 and tt <= 300)
    end

    -- GHI CLAIM VÀO WORKSPACE FILE SYNC
    local lastClaimWrite = 0
    local function writeOwnFMClaim(isValidFM, toNight, isNightActive)
        if not FILE_SYNC_AVAILABLE then return end
        if tick() - lastClaimWrite < 0.3 then return end
        lastClaimWrite = tick()

        local path = ownClaimPath()
        if not path then return end

        local pCount = #Players:GetPlayers()
        safeWriteJson(path, {
            username    = USERNAME,
            role        = isHelper and "helper" or "main",
            group_id    = isHelper and GROUP_ID or myAssignedGroupId,
            job_id      = tostring(game.JobId),
            is_valid_fm = isValidFM == true,
            to_night    = tonumber(toNight) or 0,
            is_night    = isNightActive == true,
            player_count= pCount,
            updated_at  = tick(),
        })
    end

    -- ĐỌC TẤT CẢ CLAIM FILE TỪ WORKSPACE
    local function readAllFMClaims()
        local folder = groupFolder()
        if not folder then return {} end
        local claims = {}
        local now = tick()

        local list = pcall(function() return listfiles(folder) end)
        if list and type(list) == "table" then
            for _, filePath in ipairs(list) do
                if filePath:find("claim_") then
                    local data = safeReadJson(filePath)
                    if data and tonumber(data.updated_at) and (now - tonumber(data.updated_at)) <= 6.0 then
                        table.insert(claims, data)
                    end
                end
            end
        end
        return claims
    end

    -- HOP LOW CONFIG & STATE (y hệt hoplow.lua)
    getgenv().JOB_GUI_STATE = getgenv().JOB_GUI_STATE or {
        Job = "",
        SpamJoin = false,
        HopActive = false,
        HopToken = 0
    }
    local HopLowState = getgenv().JOB_GUI_STATE
    local HOPLOW_CFG = {
        MaxPages = 100,
        MaxPlayers = 8,
        PageRetries = 3,
        PageStartDelay = 0.02,
        RetryDelay = 0.2,
        ScanTimeout = 8,
        BrowserWait = 1.25,
        TeleportWait = 6,
        SpamDelay = 2
    }

    local TP = {StartedAt = 0, FailedAt = 0, Failure = ""}

    TeleportService.TeleportInitFailed:Connect(function(player, result, message)
        if player ~= Player then return end
        TP.FailedAt = os.clock()
        TP.Failure = tostring(result and result.Name or result) .. " | " .. tostring(message or "")
    end)

    Player.OnTeleport:Connect(function(state)
        local name = ""
        pcall(function() name = state.Name end)
        if name == "Failed" then
            TP.FailedAt = os.clock()
            TP.Failure = "OnTeleport: Failed"
        else
            TP.StartedAt = os.clock()
        end
    end)

    local function browserTeleport(jobId)
        jobId = tostring(jobId or ""):gsub("%s+", "")
        if jobId == "" then return false, "JobId is empty" end
        if jobId == tostring(game.JobId) then return false, "Already in this server" end

        local browser = ReplicatedStorage:FindFirstChild("__ServerBrowser")
        if browser then
            local ok = pcall(function()
                browser:InvokeServer("teleport", jobId)
            end)
            if ok then return true, "ServerBrowser invoked" end
        end

        local ok, err = pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, Player)
        end)
        return ok, ok and "TeleportService invoked" or tostring(err)
    end

    local function hopTo(jobId)
        browserTeleport(jobId)
    end

    local function scanServers(token)
        local browser = ReplicatedStorage:FindFirstChild("__ServerBrowser")
        if not browser then return {}, "__ServerBrowser not found" end

        local byJob = {}
        local completed = 0
        setStatus("Scanning " .. HOPLOW_CFG.MaxPages .. " pages...")

        for page = 1, HOPLOW_CFG.MaxPages do
            task.delay((page - 1) * HOPLOW_CFG.PageStartDelay, function()
                if not HopLowState.HopActive or HopLowState.HopToken ~= token or isFMServerValid() then
                    completed = completed + 1
                    return
                end

                local servers
                for attempt = 1, HOPLOW_CFG.PageRetries do
                    local ok, result = pcall(function()
                        return browser:InvokeServer(page)
                    end)
                    if ok and type(result) == "table" then
                        servers = result
                        break
                    end
                    if attempt < HOPLOW_CFG.PageRetries then
                        task.wait(HOPLOW_CFG.RetryDelay)
                    end
                end

                if type(servers) == "table" and HopLowState.HopActive and HopLowState.HopToken == token and not isFMServerValid() then
                    for jobId, data in pairs(servers) do
                        if type(data) == "table" then
                            local count = tonumber(data.Count) or 99
                            local id = tostring(jobId)
                            if id ~= tostring(game.JobId) and count <= HOPLOW_CFG.MaxPlayers then
                                local oldData = byJob[id]
                                if not oldData or count < oldData.Count then
                                    byJob[id] = {
                                        JobId = id,
                                        Count = count,
                                        Region = tostring(data.Region or "Unknown")
                                    }
                                end
                            end
                        end
                    end
                end

                completed = completed + 1
            end)
        end

        local deadline = os.clock() + HOPLOW_CFG.ScanTimeout
        repeat task.wait(0.03)
        until completed >= HOPLOW_CFG.MaxPages
            or os.clock() >= deadline
            or not HopLowState.HopActive
            or HopLowState.HopToken ~= token
            or isFMServerValid()

        local pool = {}
        for _, server in pairs(byJob) do
            pool[#pool + 1] = server
        end

        table.sort(pool, function(a, b)
            if a.Count == b.Count then
                return a.JobId < b.JobId
            end
            return a.Count < b.Count
        end)

        return pool
    end

    local function waitTeleport(token, duration)
        local deadline = os.clock() + duration
        repeat
            if not HopLowState.HopActive or HopLowState.HopToken ~= token or isFMServerValid() then
                HopLowState.HopActive = false
                return "cancelled"
            end
            if TP.FailedAt > 0 then return "failed" end
            if TP.StartedAt > 0 then return "started" end
            task.wait(0.05)
        until os.clock() >= deadline
        return "timeout"
    end

    local function tryServer(server, token, index, total)
        if not HopLowState.HopActive or HopLowState.HopToken ~= token or isFMServerValid() then
            HopLowState.HopActive = false
            return false
        end

        TP.StartedAt = 0
        TP.FailedAt = 0
        TP.Failure = ""

        setStatus("Joining " .. server.Count .. "/" .. Players.MaxPlayers .. " [" .. index .. "/" .. total .. "]")

        local browser = ReplicatedStorage:FindFirstChild("__ServerBrowser")
        local invoked = false
        if browser then
            invoked = pcall(function()
                browser:InvokeServer("teleport", server.JobId)
            end)
        end

        local state
        if invoked then
            state = waitTeleport(token, HOPLOW_CFG.BrowserWait)
        end

        if not HopLowState.HopActive or HopLowState.HopToken ~= token or isFMServerValid() then
            HopLowState.HopActive = false
            return false
        end

        if not invoked or state ~= "started" then
            if state == "failed" or state == "cancelled" or not HopLowState.HopActive or HopLowState.HopToken ~= token or isFMServerValid() then
                return false
            end
            local ok = pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, server.JobId, Player)
            end)
            if not ok then return false end
            state = waitTeleport(token, HOPLOW_CFG.TeleportWait)
        end

        if not HopLowState.HopActive or HopLowState.HopToken ~= token or isFMServerValid() then
            HopLowState.HopActive = false
            return false
        end

        if state == "started" then
            setStatus("Teleport started...")
            local deadline = os.clock() + 10
            repeat
                if not HopLowState.HopActive or HopLowState.HopToken ~= token or isFMServerValid() then
                    HopLowState.HopActive = false
                    return false
                end
                if TP.FailedAt > 0 then return false end
                task.wait(0.1)
            until os.clock() >= deadline
        end

        return false
    end

    local function startLowHop()
        if HopLowState.HopActive then
            return
        end

        local isValidNow, ttNow = isFMServerValid()
        if isValidNow then
            HopLowState.HopActive = false
            return
        end

        HopLowState.SpamJoin = false
        HopLowState.HopActive = true
        HopLowState.HopToken = HopLowState.HopToken + 1
        local token = HopLowState.HopToken

        task.spawn(function()
            while HopLowState.HopActive and HopLowState.HopToken == token do
                if isFMServerValid() then
                    HopLowState.HopActive = false
                    break
                end

                local pool, err = scanServers(token)

                if err then
                    setStatus(err)
                    break
                end

                if not HopLowState.HopActive or HopLowState.HopToken ~= token or isFMServerValid() then
                    HopLowState.HopActive = false
                    break
                end

                if #pool == 0 then
                    setStatus("No low-player server; rescanning...")
                    task.wait(0.75)
                else
                    setStatus("Found " .. #pool .. " suitable servers")
                    for i, server in ipairs(pool) do
                        if not HopLowState.HopActive or HopLowState.HopToken ~= token or isFMServerValid() then
                            HopLowState.HopActive = false
                            break
                        end
                        tryServer(server, token, i, #pool)
                    end

                    if HopLowState.HopActive and HopLowState.HopToken == token then
                        if isFMServerValid() then
                            HopLowState.HopActive = false
                            break
                        end
                        setStatus("All candidates failed; rescanning...")
                        task.wait(0.5)
                    end
                end
            end

            if HopLowState.HopToken == token then
                HopLowState.HopActive = false
            end
        end)
    end

    local function stopLowHop()
        HopLowState.HopActive = false
        HopLowState.HopToken = HopLowState.HopToken + 1
    end

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
        local isValidFM, tt = isFMServerValid()

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
            toNight       = tonumber(tt) or 0,
            playerCount   = #Players:GetPlayers(),
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
        local isValidFM, tt, moonInfo = isFMServerValid()
        local isNightActive = moonInfo and moonInfo.IsNight or (Lighting.ClockTime >= 18 or Lighting.ClockTime < 6)
        local hasFM = isValidFM and isNightActive

        -- Đồng bộ luôn vào file local
        writeOwnFMClaim(isValidFM, tt, isNightActive)

        return httpPost(API_BASE .. "/data", buildPayload(hasFM))
    end

    -- ════════════ THUẬT TOÁN BẦU CHỌN BEST FM SERVER CỦA GROUP ════════════
    local function isCandidateBetter(a, b)
        if not b then return true end
        if not a then return false end

        local aNight = (a.toNight == 0)
        local bNight = (b.toNight == 0)
        if aNight ~= bNight then
            return aNight
        end

        if not aNight then
            if a.toNight ~= b.toNight then
                return a.toNight < b.toNight
            end
        end

        if (a.playerCount or 12) ~= (b.playerCount or 12) then
            return (a.playerCount or 12) < (b.playerCount or 12)
        end

        return (a.foundAt or 0) < (b.foundAt or 0)
    end

    local function electBestFMServer(resp, targetGroupHelpers)
        local best = nil

        -- 1. Quét từ API response
        if resp and resp.accounts then
            for name, data in pairs(resp.accounts) do
                if targetGroupHelpers[name] or (data.groupId and myAssignedGroupId ~= "" and data.groupId:lower() == myAssignedGroupId:lower()) then
                    local hasFM = (data.fullMoon == true) or (data.fullmoon == true) or (data.nearFM == true) or (data.nearfm == true)
                    local jid = tostring(data.jobid or data.jobId or "")
                    if hasFM and jid ~= "" then
                        local cand = {
                            jobId       = jid,
                            finder      = name,
                            toNight     = tonumber(data.toNight or (data.fullMoon and 0 or 150)) or 0,
                            playerCount = tonumber(data.playerCount or 6) or 6,
                            foundAt     = tonumber(data.foundAt or 0) or 0,
                        }
                        if isCandidateBetter(cand, best) then
                            best = cand
                        end
                    end
                end
            end
        end

        -- 2. Quét bổ sung từ Local File Claims (dự phòng / đồng bộ tức thì)
        local fileClaims = readAllFMClaims()
        for _, claim in ipairs(fileClaims) do
            local name = claim.username
            if targetGroupHelpers[name] or (claim.group_id and myAssignedGroupId ~= "" and claim.group_id:lower() == myAssignedGroupId:lower()) then
                if claim.is_valid_fm == true and tostring(claim.job_id or "") ~= "" then
                    local cand = {
                        jobId       = tostring(claim.job_id),
                        finder      = name,
                        toNight     = tonumber(claim.to_night) or 0,
                        playerCount = tonumber(claim.player_count) or 6,
                        foundAt     = tonumber(claim.updated_at) or 0,
                    }
                    if isCandidateBetter(cand, best) then
                        best = cand
                    end
                end
            end
        end

        -- 3. Kiểm tra nếu chính bản thân đang ở server Full Moon
        local myValid, myTT, myInfo = isFMServerValid()
        if myValid then
            local myCand = {
                jobId       = tostring(game.JobId),
                finder      = USERNAME,
                toNight     = tonumber(myTT) or 0,
                playerCount = #Players:GetPlayers(),
                foundAt     = tick(),
            }
            if isCandidateBetter(myCand, best) then
                best = myCand
            end
        end

        return best
    end

    -- ══════════════════════════════════════════════════════════════════
    -- UI SYSTEM (Modern Cyber Glassmorphism HUD - Draggable & Sleek)
    -- ══════════════════════════════════════════════════════════════════
    local FONT_TITLE = Enum.Font.GothamBold
    local FONT_BODY  = Enum.Font.GothamMedium
    local FONT_TAG   = Enum.Font.GothamBold

    local C_BG       = Color3.fromRGB(13, 16, 24)
    local C_CARD     = Color3.fromRGB(20, 24, 36)
    local C_STROKE   = Color3.fromRGB(0, 240, 160)
    local C_CYAN     = Color3.fromRGB(0, 220, 255)
    local C_GOLD     = Color3.fromRGB(255, 205, 75)
    local C_PURPLE   = Color3.fromRGB(185, 120, 255)
    local C_WHITE    = Color3.fromRGB(245, 248, 255)
    local C_MUTED    = Color3.fromRGB(150, 160, 180)
    local C_GREEN    = Color3.fromRGB(0, 255, 150)
    local C_RED      = Color3.fromRGB(255, 90, 90)

    local ScreenGui, MainCard, RolePill, GroupPill, MoonCard, MoonLabel, StatusCard, StatusLabel, MinBtn
    local isCollapsed = false

    local function makeDraggable(frame, handle)
        local UserInputService = game:GetService("UserInputService")
        local dragging = false
        local dragInput, dragStart, startPos

        handle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = frame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)

        handle.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                frame.Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            end
        end)
    end

    local function createUI()
        pcall(function()
            local old = CoreGui:FindFirstChild("JoinV4UI")
            if old then old:Destroy() end
        end)

        local sg = Instance.new("ScreenGui")
        sg.Name = "JoinV4UI"
        sg.ResetOnSpawn = false
        sg.IgnoreGuiInset = true
        sg.DisplayOrder = 999999
        sg.ZIndexBehavior = Enum.ZIndexBehavior.Global
        sg.Parent = CoreGui
        ScreenGui = sg

        local PW, PH = 320, 195
        local Card = Instance.new("Frame")
        Card.Name = "MainCard"
        Card.Size = UDim2.fromOffset(PW, PH)
        Card.Position = UDim2.new(1, -(PW + 12), 0, 42)
        Card.BackgroundColor3 = C_BG
        Card.BackgroundTransparency = 0.05
        Card.BorderSizePixel = 0
        Card.ClipsDescendants = true
        Card.Parent = sg
        MainCard = Card
        Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 12)

        local stroke = Instance.new("UIStroke", Card)
        stroke.Color = C_STROKE
        stroke.Thickness = 1.5
        stroke.Transparency = 0.35

        -- Header Bar
        local header = Instance.new("Frame", Card)
        header.Name = "Header"
        header.Size = UDim2.new(1, 0, 0, 36)
        header.BackgroundColor3 = Color3.fromRGB(18, 22, 33)
        header.BorderSizePixel = 0

        local headerPad = Instance.new("UIPadding", header)
        headerPad.PaddingLeft = UDim.new(0, 10)
        headerPad.PaddingRight = UDim.new(0, 10)

        local title = Instance.new("TextLabel", header)
        title.Size = UDim2.new(0, 140, 1, 0)
        title.BackgroundTransparency = 1
        title.Text = "⚡ <font color=\"#00FF96\"><b>JOIN V4 PRO</b></font>"
        title.RichText = true
        title.Font = FONT_TITLE
        title.TextSize = 15
        title.TextColor3 = C_WHITE
        title.TextXAlignment = Enum.TextXAlignment.Left

        local userTag = Instance.new("TextLabel", header)
        userTag.Size = UDim2.new(0, 110, 0, 20)
        userTag.Position = UDim2.new(0, 142, 0.5, -10)
        userTag.BackgroundColor3 = Color3.fromRGB(26, 31, 46)
        userTag.Text = USERNAME
        userTag.Font = FONT_BODY
        userTag.TextSize = 11
        userTag.TextColor3 = C_CYAN
        userTag.TextTruncate = Enum.TextTruncate.AtEnd
        Instance.new("UICorner", userTag).CornerRadius = UDim.new(0, 5)

        MinBtn = Instance.new("TextButton", header)
        MinBtn.Size = UDim2.fromOffset(22, 22)
        MinBtn.Position = UDim2.new(1, -22, 0.5, -11)
        MinBtn.BackgroundColor3 = Color3.fromRGB(30, 36, 52)
        MinBtn.Text = "—"
        MinBtn.Font = FONT_TITLE
        MinBtn.TextSize = 13
        MinBtn.TextColor3 = C_MUTED
        MinBtn.BorderSizePixel = 0
        Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

        makeDraggable(Card, header)

        -- Content Container
        local content = Instance.new("Frame", Card)
        content.Name = "Content"
        content.Size = UDim2.new(1, 0, 1, -36)
        content.Position = UDim2.new(0, 0, 0, 36)
        content.BackgroundTransparency = 1

        local cPad = Instance.new("UIPadding", content)
        cPad.PaddingLeft   = UDim.new(0, 10)
        cPad.PaddingRight  = UDim.new(0, 10)
        cPad.PaddingTop    = UDim.new(0, 8)
        cPad.PaddingBottom = UDim.new(0, 8)

        local layout = Instance.new("UIListLayout", content)
        layout.FillDirection = Enum.FillDirection.Vertical
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 6)

        -- Row 1: Role & Group Badges
        local row1 = Instance.new("Frame", content)
        row1.Name = "Row1"
        row1.Size = UDim2.new(1, 0, 0, 28)
        row1.BackgroundTransparency = 1
        row1.LayoutOrder = 1

        local r1Layout = Instance.new("UIListLayout", row1)
        r1Layout.FillDirection = Enum.FillDirection.Horizontal
        r1Layout.Padding = UDim.new(0, 6)

        RolePill = Instance.new("TextLabel", row1)
        RolePill.Size = UDim2.new(0.5, -3, 1, 0)
        RolePill.BackgroundColor3 = C_CARD
        RolePill.Text = "👑 MAIN"
        RolePill.Font = FONT_TAG
        RolePill.TextSize = 12
        RolePill.TextColor3 = C_PURPLE
        RolePill.BorderSizePixel = 0
        Instance.new("UICorner", RolePill).CornerRadius = UDim.new(0, 6)
        local rPillStroke = Instance.new("UIStroke", RolePill)
        rPillStroke.Color = Color3.fromRGB(40, 46, 68)
        rPillStroke.Thickness = 1

        GroupPill = Instance.new("TextLabel", row1)
        GroupPill.Size = UDim2.new(0.5, -3, 1, 0)
        GroupPill.BackgroundColor3 = C_CARD
        GroupPill.Text = "📌 Group: ..."
        GroupPill.Font = FONT_TAG
        GroupPill.TextSize = 12
        GroupPill.TextColor3 = C_GOLD
        GroupPill.BorderSizePixel = 0
        GroupPill.TextTruncate = Enum.TextTruncate.AtEnd
        Instance.new("UICorner", GroupPill).CornerRadius = UDim.new(0, 6)
        local gPillStroke = Instance.new("UIStroke", GroupPill)
        gPillStroke.Color = Color3.fromRGB(40, 46, 68)
        gPillStroke.Thickness = 1

        -- Row 2: Moon Radar Card
        MoonCard = Instance.new("Frame", content)
        MoonCard.Name = "MoonCard"
        MoonCard.Size = UDim2.new(1, 0, 0, 32)
        MoonCard.BackgroundColor3 = C_CARD
        MoonCard.BorderSizePixel = 0
        MoonCard.LayoutOrder = 2
        Instance.new("UICorner", MoonCard).CornerRadius = UDim.new(0, 6)
        local mStroke = Instance.new("UIStroke", MoonCard)
        mStroke.Color = Color3.fromRGB(40, 46, 68)
        mStroke.Thickness = 1

        local mPad = Instance.new("UIPadding", MoonCard)
        mPad.PaddingLeft = UDim.new(0, 8)
        mPad.PaddingRight = UDim.new(0, 8)

        MoonLabel = Instance.new("TextLabel", MoonCard)
        MoonLabel.Size = UDim2.new(1, 0, 1, 0)
        MoonLabel.BackgroundTransparency = 1
        MoonLabel.Text = "🌑 Moon: Checking..."
        MoonLabel.Font = FONT_BODY
        MoonLabel.TextSize = 12
        MoonLabel.TextColor3 = C_MUTED
        MoonLabel.TextXAlignment = Enum.TextXAlignment.Left

        -- Row 3: Live Status Card
        StatusCard = Instance.new("Frame", content)
        StatusCard.Name = "StatusCard"
        StatusCard.Size = UDim2.new(1, 0, 0, 68)
        StatusCard.BackgroundColor3 = C_CARD
        StatusCard.BorderSizePixel = 0
        StatusCard.LayoutOrder = 3
        Instance.new("UICorner", StatusCard).CornerRadius = UDim.new(0, 6)
        local sStroke = Instance.new("UIStroke", StatusCard)
        sStroke.Color = Color3.fromRGB(40, 46, 68)
        sStroke.Thickness = 1

        local sBar = Instance.new("Frame", StatusCard)
        sBar.Size = UDim2.new(0, 3, 1, 0)
        sBar.BackgroundColor3 = C_CYAN
        sBar.BorderSizePixel = 0
        Instance.new("UICorner", sBar).CornerRadius = UDim.new(0, 3)

        local sPad = Instance.new("UIPadding", StatusCard)
        sPad.PaddingLeft   = UDim.new(0, 10)
        sPad.PaddingRight  = UDim.new(0, 8)
        sPad.PaddingTop    = UDim.new(0, 4)
        sPad.PaddingBottom = UDim.new(0, 4)

        StatusLabel = Instance.new("TextLabel", StatusCard)
        StatusLabel.Size = UDim2.new(1, 0, 1, 0)
        StatusLabel.BackgroundTransparency = 1
        StatusLabel.Text = "⏳ Starting JoinV4 System..."
        StatusLabel.Font = FONT_BODY
        StatusLabel.TextSize = 12
        StatusLabel.TextColor3 = C_GOLD
        StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
        StatusLabel.TextYAlignment = Enum.TextYAlignment.Center
        StatusLabel.TextWrapped = true

        MinBtn.MouseButton1Click:Connect(function()
            isCollapsed = not isCollapsed
            if isCollapsed then
                Card.Size = UDim2.fromOffset(PW, 36)
                content.Visible = false
                MinBtn.Text = "+"
            else
                Card.Size = UDim2.fromOffset(PW, PH)
                content.Visible = true
                MinBtn.Text = "—"
            end
        end)
    end

    local function updateUI()
        if not ScreenGui or not ScreenGui.Parent or not MainCard or not MainCard.Parent then
            pcall(createUI); return
        end
        local isValidFM, tt, moonInfo = isFMServerValid()

        if RolePill then
            if isMain then
                RolePill.Text = "👑 MAIN"
                RolePill.TextColor3 = C_PURPLE
            else
                RolePill.Text = "🛡️ HELPER [G" .. tostring(MY_GROUP_IDX or "?") .. "]"
                RolePill.TextColor3 = Color3.fromRGB(100, 180, 255)
            end
        end

        if GroupPill then
            if isHelper then
                GroupPill.Text = "📌 " .. tostring(MY_GROUP_NOTE or "?")
                GroupPill.TextColor3 = C_GOLD
            elseif myAssignedGroupId ~= "" then
                GroupPill.Text = "📌 " .. tostring(myAssignedGroupId)
                GroupPill.TextColor3 = C_GREEN
            else
                GroupPill.Text = "📌 Đang gán nhóm..."
                GroupPill.TextColor3 = C_MUTED
            end
        end

        if MoonLabel then
            if isValidFM then
                if tt == 0 then
                    MoonLabel.Text = "🌕 FULL MOON (ACTIVE)"
                else
                    MoonLabel.Text = string.format("🌔 PRE-FM (%ds to night)", tt)
                end
                MoonLabel.TextColor3 = C_GREEN
            else
                local ms = moonInfo and moonInfo.MoonStatus or ((type(CheckMoon) == "function" and CheckMoon()) or "?")
                MoonLabel.Text       = "🌑 Moon: " .. tostring(ms)
                MoonLabel.TextColor3 = C_MUTED
            end
        end

        if StatusLabel then
            local s = currentStatus:lower()
            local col = C_WHITE
            if s:find("hop") or s:find("teleport") then
                col = C_CYAN
            elseif s:find("training") or s:find("train") then
                col = C_GOLD
            elseif s:find("trial") or s:find("done") or s:find("complete") then
                col = C_GREEN
            elseif s:find("timeout") or s:find("fail") or s:find("error") then
                col = C_RED
            elseif s:find("wait") or s:find("cho") or s:find("settle") then
                col = Color3.fromRGB(130, 200, 255)
            else
                col = C_GOLD
            end
            StatusLabel.TextColor3 = col
            StatusLabel.Text = "⚡ " .. currentStatus
        end
    end

    -- BOOT
    task.spawn(createUI)
    pcall(function()
        if not Player:FindFirstChild("DataLoaded") then
            Player:WaitForChild("DataLoaded", 5)
        end
    end)
    setStatus("Loaded & Running")
    task.wait(0.5)

    task.spawn(function()
        while task.wait(0.4) do pcall(updateUI) end
    end)

    if not isHelper and not isMain then
        setStatus("Not in config - idle")
        return
    end

    -- ════════════ HELPER COORDINATOR LOOP (HOP TÌM MOON + JOIN SERVER CHUNG) ════════════
    if isHelper then
        task.spawn(function()
            task.wait(HOP_STARTUP_DELAY)
            local lastHopAt = 0
            local lastHopTarget = ""

            while task.wait(SYNC_INTERVAL) do
                pcall(function()
                    local resp = syncToAPI()
                    local targetHelpers = MY_HelperSet
                    local bestFM = electBestFMServer(resp, targetHelpers)

                    if not bestFM then
                        -- Không có server Full Moon nào được tìm thấy: Cả 2 Helper cùng chạy Hop Low tìm!
                        local isValidNow, ttNow, mInfo = isFMServerValid()
                        if isValidNow then
                            if HopLowState.HopActive then stopLowHop() end
                            setStatus(ttNow == 0 and "Full Moon here - claim anchor!" or string.format("Pre-FM here (%ds) - claim anchor!", ttNow))
                        else
                            if not HopLowState.HopActive then
                                setStatus("No FM in group - Hop low searching...")
                                startLowHop()
                            end
                        end
                        lastHopTarget = ""
                    else
                        -- Đã có 1 account (Helper hoặc Main) tìm thấy Full Moon tốt nhất!
                        if HopLowState.HopActive then
                            stopLowHop()
                        end

                        if bestFM.jobId == tostring(game.JobId) then
                            -- Helper đang ở trong server Full Moon mục tiêu: Giữ server và làm mốc!
                            setStatus("Anchor in FM server (" .. (bestFM.finder or "me") .. ")")
                            lastHopTarget = ""
                        else
                            -- Helper đang ở server khác: Lập tức join vào server mục tiêu trước!
                            local nowTick = tick()
                            if bestFM.jobId ~= lastHopTarget then
                                lastHopTarget = bestFM.jobId
                                lastHopAt = nowTick
                                setStatus("Helper joining FM server (" .. bestFM.jobId:sub(1,6) .. ")...")
                                hopTo(bestFM.jobId)
                                task.wait(0.5)
                            else
                                if nowTick - lastHopAt >= 8 then
                                    setStatus("Join timeout - retrying FM server...")
                                    lastHopAt = nowTick
                                    hopTo(bestFM.jobId)
                                    task.wait(0.5)
                                else
                                    setStatus("Waiting teleport -> FM server...")
                                end
                            end
                        end
                    end
                end)
            end
        end)
    end

    -- ════════════ MAIN COORDINATOR LOOP (HOP TÌM MOON + ĐỢI 2 HELPER VÀO ĐỦ RỒI MỚI JOIN) ════════════
    if isMain then
        task.spawn(function()
            task.wait(HOP_STARTUP_DELAY + 1)
            local lastHopAtMain = 0
            local lastHopTMain  = ""

            while task.wait(SYNC_INTERVAL) do
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
                    if myAssignedGroupId == "" then
                        myAssignedGroupId = myDefaultGroup
                    end

                    updateV4Cache()
                    local v4s = _v4Cache

                    if v4s and v4s.needsTraining == false and v4s.needsPurchase == false then
                        rawset(getgenv(), "isCurrentlyTraining", nil)
                    end

                    -- Kiểm tra Main có đang bận training / mua gear không
                    local isBusy = false
                    local busyReason = ""
                    if _v4CacheAt == 0 then
                        isBusy = true; busyReason = "Checking V4 status..."
                    elseif v4s and v4s.needsTraining == true then
                        isBusy = true; busyReason = "Training (" .. tostring(v4s.key or "?") .. ") - busy"
                    elseif v4s and v4s.needsPurchase == true then
                        isBusy = true; busyReason = "Buy Gear (" .. tostring(v4s.key or "?") .. ") - busy"
                    elseif v4s and not v4s.complete and v4s.canTrial == false and v4s.needsTraining == false and v4s.key ~= nil then
                        isBusy = true; busyReason = "V4 busy (" .. tostring(v4s.key) .. ")"
                    end

                    if getgenv().JoinV4_skipHop == true then
                        isBusy = true; busyReason = "JoinV4_skipHop=true - paused"
                    end

                    if isBusy then
                        if HopLowState.HopActive then stopLowHop() end
                        setStatus(busyReason)
                        lastHopTMain = ""; return
                    end

                    -- Lấy danh sách helpers của group
                    local myGroupHelpers = {}
                    if myAssignedGroupId ~= "" then
                        for i, helperList in ipairs(helperGroups) do
                            if type(helperList) == "table" then
                                local note = trim(noteList[i] or ("group" .. i))
                                if note:lower() == myAssignedGroupId:lower() then
                                    for _, h in ipairs(helperList) do
                                        h = trim(tostring(h))
                                        if h ~= "" then myGroupHelpers[h] = true end
                                    end
                                    break
                                end
                            end
                        end
                    end
                    if next(myGroupHelpers) == nil and resp and resp.group and resp.group.helpers then
                        for _, h in ipairs(resp.group.helpers) do
                            h = trim(tostring(h))
                            if h ~= "" then myGroupHelpers[h] = true end
                        end
                    end

                    -- Bầu chọn Best FM Server
                    local bestFM = electBestFMServer(resp, myGroupHelpers)

                    if not bestFM then
                        -- Không có server Full Moon: Main rảnh cùng tham gia Hop Low tìm server!
                        local isValidNow, ttNow = isFMServerValid()
                        if isValidNow then
                            if HopLowState.HopActive then stopLowHop() end
                            setStatus(ttNow == 0 and "Main found FM! Claim anchor..." or string.format("Main found Pre-FM (%ds)! Claim anchor...", ttNow))
                        else
                            if not HopLowState.HopActive then
                                setStatus("Main searching FM (Hop low)...")
                                startLowHop()
                            end
                        end
                        lastHopTMain = ""
                    else
                        -- Có server Full Moon được chốt!
                        if HopLowState.HopActive then
                            stopLowHop()
                        end

                        -- KIỂM TRA ĐIỀU KIỆN: 2 Helper phải có mặt trong FM server trước!
                        local helperInTargetCount = 0
                        local helperTotal = 0
                        local notInTarget = {}
                        local fileClaims = readAllFMClaims()
                        local claimByHelper = {}
                        for _, c in ipairs(fileClaims) do
                            if c.username then claimByHelper[c.username] = c end
                        end

                        for name, _ in pairs(myGroupHelpers) do
                            helperTotal = helperTotal + 1
                            local inServer = false

                            -- Nếu đang ở cùng server: kiểm tra trực tiếp player list
                            if tostring(game.JobId) == bestFM.jobId and Players:FindFirstChild(name) then
                                inServer = true
                            end

                            -- Kiểm tra từ API
                            if not inServer and resp and resp.accounts and resp.accounts[name] then
                                local jid = tostring(resp.accounts[name].jobid or resp.accounts[name].jobId or "")
                                if jid == bestFM.jobId then
                                    inServer = true
                                end
                            end

                            -- Kiểm tra từ File Sync
                            if not inServer and claimByHelper[name] then
                                if tostring(claimByHelper[name].job_id or "") == bestFM.jobId then
                                    inServer = true
                                end
                            end

                            if inServer then
                                helperInTargetCount = helperInTargetCount + 1
                            else
                                table.insert(notInTarget, name)
                            end
                        end

                        local allHelpersReady = (helperTotal > 0) and (helperInTargetCount >= helperTotal)

                        if not allHelpersReady then
                            -- Chưa đủ 2 Helper vào server: Main đứng chờ, không vào vội!
                            if bestFM.jobId == tostring(game.JobId) then
                                setStatus(string.format("In FM server - Waiting %d/%d helpers (%s)...",
                                    helperInTargetCount, helperTotal, table.concat(notInTarget, ", "):sub(1, 25)))
                            else
                                setStatus(string.format("Waiting 2 helpers join FM first (%d/%d ready)...",
                                    helperInTargetCount, helperTotal))
                            end
                            lastHopTMain = ""
                        else
                            -- CẢ 2 HELPER ĐÃ CÓ MẶT ĐỦ: Main tiến hành Join vào!
                            if bestFM.jobId == tostring(game.JobId) then
                                setStatus("In FM server with ALL 2 helpers - Ready Trial!")
                                lastHopTMain = ""
                            else
                                local nowTick = tick()
                                if bestFM.jobId ~= lastHopTMain then
                                    lastHopTMain = bestFM.jobId
                                    lastHopAtMain = nowTick
                                    setStatus("2 Helpers ready! Main joining FM server...")
                                    hopTo(bestFM.jobId)
                                    task.wait(0.5)
                                else
                                    if nowTick - lastHopAtMain >= 8 then
                                        setStatus("Main join timeout - retry...")
                                        lastHopAtMain = nowTick
                                        hopTo(bestFM.jobId)
                                        task.wait(0.5)
                                    else
                                        setStatus("Teleporting to FM server with 2 helpers...")
                                    end
                                end
                            end
                        end
                    end

                end)
            end
        end)
    end

    local roleLog = isMain and "Main" or ("Helper [G" .. (MY_GROUP_IDX or "?") .. "] grp=" .. (MY_GROUP_NOTE or "?"))
    print("[JoinV4] Loaded | " .. USERNAME .. " | " .. roleLog)
end)()
