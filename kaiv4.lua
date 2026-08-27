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
        loadstring(game:HttpGet("https://raw.githubusercontent.com/obiiyeuem/vthangsitink/main/BananaHub.lua"))()
    end)
end

-- ══════════════════════════════════════════════════════════════════
-- [2/3] TURNV3 (Đồng bộ V3 Countdown & Watchdog Ghost Temple)
-- ══════════════════════════════════════════════════════════════════
do
    local V3_COUNTDOWN      = 4
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
    -- Helper = có trong HelperList
    -- Main   = KHÔNG có trong HelperList
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
                -- Nếu đang Full Moon: KHÔNG hop random, ở lại làm trial
                local fmNow = isnight() and isfullmoon()
                if fmNow then return end

                -- Kiểm tra trạng thái V4
                local v4 = getV4StatusSimple()
                -- Skip hop khi đang training hoặc cần mua upgrade
                if v4 and (v4.needsTraining or v4.needsPurchase) then
                    setStatus((isUper and "Main" or "Helper") .. " | Dang training...")
                    return
                end

                -- Khi không có Full Moon và đã xong training / sẵn sàng trial -> Hop random tìm server mới
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
-- [3/3] JOINV4 (Kaiv4-BNN/joinv4.lua) - API Moon Hop & Group Management
-- ══════════════════════════════════════════════════════════════════
;(function()
    local CFG = getgenv().JoinV4Config

    -- API / TIMING CONSTANTS
    local FM_API_URL      = "http://103.77.241.138:1901/xOKcICjhMvaZ1NCqj0yd7KW1n6as960lopwwBLr6/server/api/moon?X-API-Key=all_zPRS9PQT7PqAI4VTvximZTOBqv2lMiWgzLMh2GXR"
    local API_BASE        = "http://matrix.pikamc.vn:25932"
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

        for _, v in ipairs(entries) do
            if type(v) ~= "table" then continue end
            local jobId   = getField(v, "jobid","JobId","JobID","jobId","job_id")
            local placeId = getField(v, "placeid","PlaceId","placeId","place_id")
            local players = parsePlayers(getField(v, "players","Players","playerCount","PlayerCount"))
            local tt = parseTimeToNight(v)
            if not jobId or jobId == "" then continue end
            if tostring(jobId) == tostring(game.JobId) then continue end
            local cached = fmJoinedCache[tostring(jobId)]
            if cached and (os.time() - cached) < FM_CACHE_EXPIRE then continue end
            if not placeId or tonumber(placeId) ~= tonumber(game.PlaceId) then continue end
            -- Lọc chuẩn: timetonight 15..220 và players 2..5
            if tt and tonumber(tt) >= 15 and tonumber(tt) <= 220
                and players and tonumber(players) >= 2 and tonumber(players) <= 5 then
                return tostring(jobId)
            end
        end
        return nil
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

        -- Make Card draggable from Header
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

        -- Left Accent Bar
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

        -- Toggle Collapse Logic
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
        local hasFM = isNight() and isFullMoon()

        -- Update Role
        if RolePill then
            if isMain then
                RolePill.Text = "👑 MAIN"
                RolePill.TextColor3 = C_PURPLE
            elseif isHopFM then
                RolePill.Text = "🚀 HELPER [FM]"
                RolePill.TextColor3 = C_CYAN
            else
                RolePill.Text = "🛡️ HELPER [G" .. tostring(MY_GROUP_IDX or "?") .. "]"
                RolePill.TextColor3 = Color3.fromRGB(100, 180, 255)
            end
        end

        -- Update Group
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

        -- Update Moon Card
        if MoonLabel then
            if hasFM then
                MoonLabel.Text = "🌕 FULL MOON (ACTIVE)"
                MoonLabel.TextColor3 = C_GREEN
            else
                local mTex = type(getgenv().CheckMoon) == "function" and getgenv().CheckMoon() or ""
                if mTex ~= "" and mTex ~= "nil" then
                    MoonLabel.Text = "🌑 Moon: " .. tostring(mTex) .. " (No Full Moon)"
                else
                    MoonLabel.Text = "🌑 No Full Moon"
                end
                MoonLabel.TextColor3 = C_MUTED
            end
        end

        -- Update Status Card
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

    -- HELPER: HOP FM LOOP
    if isHelper and isHopFM then
        task.spawn(function()
            task.wait(HOP_STARTUP_DELAY)
            local lastHopT   = ""
            local lastHopAt_ = 0
            local isFetching = false
            local takenJobIds        = {}
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
                    setStatus("Pre-FM ready - waiting night...")
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
                        setStatus("Hop FM: " .. hopT:sub(1,8) .. "...")
                        pcall(function() writefile("jv4_fmhop_pending.txt", "true") end)
                        hopTo(hopT); task.wait(0.5)
                    else
                        if _failedHopJobId == hopT then
                            _failedHopJobId = ""
                            lastFmApiResult = nil; lastFmApiAt = 0; lastHopT = ""
                        else
                            local el = nowTick - lastHopAt_
                            if el >= 3 then
                                setStatus("Hop timeout - retry")
                                fmJoinedCache[hopT] = os.time()
                                lastFmApiResult = nil; lastFmApiAt = 0; lastHopT = ""
                            else
                                setStatus("Retry: " .. hopT:sub(1,8) .. "...")
                                hopTo(hopT); task.wait(0.5)
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
                    for name, data in pairs(resp.accounts) do
                        if MY_HopFMSet[name] and name ~= USERNAME then
                            local helperHasFM = (data.fullMoon == true) or (data.fullmoon == true)
                            if helperHasFM then
                                local jid = tostring(data.jobid or data.jobId or "")
                                if jid ~= "" then
                                    fmJobId = jid; fmWho = name; break
                                end
                            end
                        end
                    end

                    if not fmJobId then
                        setStatus(hasFM and "FM here - waiting HopFM confirm..." or "Waiting HopFM helper...")
                        lastHopTHelper = ""; return
                    end

                    if fmJobId == game.JobId then
                        setStatus("In FM server with " .. (fmWho or "HopFM"))
                        lastHopTHelper = ""; return
                    end

                    local nowTick = tick()
                    if fmJobId ~= lastHopTHelper then
                        lastHopAtHelper = nowTick; lastHopTHelper = fmJobId
                        setStatus("Join " .. (fmWho or "HopFM") .. " at " .. fmJobId:sub(1,6) .. "...")
                        hopTo(fmJobId); task.wait(0.5)
                    else
                        local el = nowTick - lastHopAtHelper
                        if el >= 8 then
                            setStatus("Join timeout - clear & retry")
                            lastHopTHelper = ""; lastHopAtHelper = 0
                        else
                            setStatus("Retry join " .. fmJobId:sub(1,6) .. "...")
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
                    if resp and resp.group and type(resp.group.id) == "string"
                        and resp.group.id ~= "" and myAssignedGroupId == "" then
                        local assignedId = resp.group.id
                        local validGroup = false
                        for _, note in ipairs(noteList) do
                            if trim(note):lower() == trim(assignedId):lower() then
                                assignedId = trim(note)
                                validGroup = true
                                break
                            end
                        end
                        if validGroup then
                            myAssignedGroupId = assignedId
                        else
                            warn("[JoinV4] Rejected stale groupId from server: " .. assignedId
                                .. " (not in current noteList) - waiting for valid group...")
                            setStatus("Bad group assign (" .. assignedId .. ") - retrying...")
                        end
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
                            setStatus("Waiting server assign group...")
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

                    if resp.group and resp.group.helpers then
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
