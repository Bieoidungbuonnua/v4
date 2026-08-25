repeat task.wait() until game:IsLoaded()
    and game:GetService("Players").LocalPlayer
    and game:GetService("Players").LocalPlayer:FindFirstChild("DataLoaded")

-- ══════════════════════════════════════════════════════════════════
-- CẤU HÌNH DÙNG CHUNG (Tất cả 3 script tự động nhận từ JoinV4Config)
-- ══════════════════════════════════════════════════════════════════
local _DEFAULT_CFG = {
    ["Helper"] = {
        {"BradyLang6806", "Bytef8Star41673"},
        {"MichaelLak17906", "FloralHampton91506"},
    },
    ["Note"]             = {"groupNote1111111", "groupNote2222222"},
    ["LimitMainPerGroup"] = 8,   -- tối đa main được vào mỗi group
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
-- [1/3] BNN (Banana Hub) - Whitelist từ HelperList chung
-- ══════════════════════════════════════════════════════════════════
do
    local player = game:GetService("Players").LocalPlayer
    local username = player.Name

    local specialUsers = {}
    for _, name in ipairs(getgenv().HelperList or {}) do
        specialUsers[name] = true
    end

    getgenv().Key = "31d4bebb966b95e8bd94d7a6" 

    if specialUsers[username] then
        -- CONFIG 1 (Cho acc Helper)
        print("[Config] Applying Config 1 for Helper")
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
        print("[Config] Applying Config 2 for Main")
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
-- [2/3] TURNV3 (pairv4/turnv3.lua) - Đồng bộ V3 Countdown & Watchdog
-- ══════════════════════════════════════════════════════════════════
do
    local V3_COUNTDOWN     = 3      -- giây countdown từ khi main tạo round đến fire
    local V3_FILE_POLL     = 0.08   -- poll file mỗi bao nhiêu giây
    local V3_READY_FRESH   = 3.0    -- file ready tối đa bao nhiêu giây còn hợp lệ
    local V3_FIRE_COUNT    = 1      -- số lần FireServer ActivateAbility
    local V3_FIRE_INTERVAL = 0.05   -- khoảng cách giữa các lần fire (s)
    local V3_DOOR_DIST     = 65     -- khoảng cách tối đa tới cửa (studs)
    local FILE_ROOT        = "TurnV3"

    -- SERVICES
    local Players           = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local RunService        = game:GetService("RunService")
    local HttpService       = game:GetService("HttpService")
    local Lighting          = game:GetService("Lighting")
    local LocalPlayer       = Players.LocalPlayer
    local USERNAME          = LocalPlayer.Name

    local Remotes = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:WaitForChild("Remotes", 10)
    local CommE   = Remotes and (Remotes:FindFirstChild("CommE")  or Remotes:WaitForChild("CommE",  10))
    local CommF   = Remotes and (Remotes:FindFirstChild("CommF_") or Remotes:WaitForChild("CommF_", 10))

    -- ROLE DETECTION
    local function isInHelperList(name)
        for _, n in ipairs(getgenv().HelperList or {}) do
            if n == name then return true end
        end
        return false
    end

    local function findMainInServer()
        for _, name in ipairs(getgenv().HelperList or {}) do
            if Players:FindFirstChild(name) then return name end
        end
        return nil
    end

    local isMain   = (findMainInServer() == USERNAME)
    local isHelper = isInHelperList(USERNAME) and not isMain

    -- SERVER CLOCK
    local function serverNow()
        local ok, v = pcall(function() return game:GetService("Workspace"):GetServerTimeNow() end)
        return (ok and tonumber(v)) and tonumber(v) or tick()
    end

    -- FILE SYNC API
    local FILE_SYNC_AVAILABLE = type(writefile)  == "function"
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
        local folder = groupFolder()
        if not folder then return nil end
        return folder .. "/ready_" .. sanitize(USERNAME) .. ".json"
    end

    local function commandPath()
        local folder = groupFolder()
        if not folder then return nil end
        return folder .. "/command.json"
    end

    -- STATE
    local readySent        = false
    local lastReadyWrite   = 0
    local handledRoundId   = ""
    local scheduledRoundId = ""
    local abilityCooldown  = 0
    local currentStatus    = "Dang khoi dong..."

    local function setStatus(s)
        currentStatus = tostring(s or "")
    end

    -- FULL MOON CHECK
    local function isFullMoon()
        for _, obj in ipairs(Lighting:GetChildren()) do
            if obj:IsA("Sky") then
                if tostring(obj.MoonTextureId):find("9709149431") then return true end
            end
        end
        return false
    end

    -- DOOR CHECK
    local function getDoor(playerName)
        local plr = playerName and Players:FindFirstChild(playerName) or LocalPlayer
        if not plr then return nil end
        local char = plr.Character
        if not char then return nil end
        local data = plr:FindFirstChild("Data")
        local race = data and data:FindFirstChild("Race")
        if not race then return nil end
        local raceVal = race.Value

        local temple = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Temple of Time")
        if not temple then
            local ms = ReplicatedStorage:FindFirstChild("MapStash")
            temple = ms and ms:FindFirstChild("Temple of Time")
        end
        if not temple then return nil end

        local corridor = temple:FindFirstChild(raceVal .. "Corridor")
        if not corridor then
            local rLow = raceVal:lower()
            for _, c in ipairs(temple:GetChildren()) do
                if c.Name:lower():find(rLow, 1, true) then corridor = c; break end
            end
        end
        if not corridor then return nil end

        local door = corridor:FindFirstChild("Door")
        if not door then return nil end
        local entrance = door:FindFirstChild("Entrance") or door
        if entrance:IsA("BasePart") then return entrance end
        local pivot = pcall(function() return entrance:GetPivot() end)
        return entrance:FindFirstChildWhichIsA("BasePart") or nil
    end

    local function localDoorState(playerName)
        local plr = playerName and Players:FindFirstChild(playerName) or LocalPlayer
        local char = plr and plr.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        local door = getDoor(playerName)

        local distance = math.huge
        if door and hrp then
            distance = (door.Position - hrp.Position).Magnitude
        end

        local timerVisible = false
        pcall(function()
            timerVisible = LocalPlayer.PlayerGui.Main.Timer.Visible == true
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

        local st    = localDoorState()
        local ready = tick() >= abilityCooldown
            and st.alive
            and st.nearDoor
            and not st.timerVisible
            and isFullMoon()

        readySent = ready
        safeWriteJson(path, {
            username    = USERNAME,
            job_id      = game.JobId,
            ready       = ready,
            near_door   = st.nearDoor,
            updated_at  = serverNow(),
            fired_round = handledRoundId,
        })
        return ready
    end

    -- READ ALL READY FILES
    local function readAllReadyFiles()
        local folder = groupFolder()
        if not folder then return 0, false end

        local readyCount = 0
        local total = 0
        local now = serverNow()

        for _, name in ipairs(getgenv().HelperList or {}) do
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

        return readyCount, total >= 2 and readyCount >= total
    end

    -- READ V3 COMMAND
    local function readV3Command()
        local path = commandPath()
        if not path then return nil end
        local data = safeReadJson(path)
        if not data then return nil end
        if tostring(data.job_id or "") ~= tostring(game.JobId) then return nil end

        local now       = serverNow()
        local expiresAt = tonumber(data.expires_at) or 0
        local fireAt    = tonumber(data.fire_at) or 0

        if fireAt < now - 0.5 then return nil end
        if expiresAt <= now then return nil end

        if data.members then
            local found = false
            for _, m in ipairs(data.members) do
                if tostring(m) == USERNAME then found = true; break end
            end
            if not found then return nil end
        end
        return data
    end

    -- MAIN CREATE ROUND
    local function mainCreateRound()
        if not isMain then return nil end

        local ffaNow = false
        pcall(function()
            ffaNow = workspace.Map["Temple of Time"].FFABorder.Forcefield.Transparency == 0
        end)
        if ffaNow then return nil end

        local current = readV3Command()
        if current then return current end

        local readyCount, allReady = readAllReadyFiles()
        if not allReady then
            setStatus(string.format("Main | Cho helper ready %d/%d...", readyCount,
                (function()
                    local t = 0
                    for _, n in ipairs(getgenv().HelperList or {}) do
                        if Players:FindFirstChild(n) then t = t + 1 end
                    end
                    return t
                end)()))
            return nil
        end

        local now    = serverNow()
        local fireAt = now + V3_COUNTDOWN
        local roundId = sanitize(USERNAME) .. "_" .. tostring(math.floor(fireAt * 1000))

        local members = {}
        for _, name in ipairs(getgenv().HelperList or {}) do
            if Players:FindFirstChild(name) then
                table.insert(members, name)
            end
        end

        local command = {
            job_id     = game.JobId,
            round_id   = roundId,
            main       = USERNAME,
            members    = members,
            created_at = now,
            fire_at    = fireAt,
            expires_at = fireAt + 8,
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
            local remaining = fireAt - serverNow()
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

        scheduledRoundId = roundId

        task.spawn(function()
            if fireAt < serverNow() - 2 then
                warn("[TurnV3][SKIP] Command cu (fireAt da qua " ..
                    string.format("%.1f", serverNow() - fireAt) .. "s truoc) -> bo")
                scheduledRoundId = ""
                return
            end

            waitForSharedFireTime(fireAt)

            local st    = localDoorState()
            local jobOk = tostring(command.job_id or "") == tostring(game.JobId)
            local fired = false

            if jobOk and st.nearDoor and not st.timerVisible then
                setStatus(isMain and "Main | Kich hoat V3!" or "Helper | Kich hoat V3!")
                for i = 1, V3_FIRE_COUNT do
                    pcall(function()
                        ReplicatedStorage.Remotes.CommE:FireServer("ActivateAbility")
                    end)
                    if i < V3_FIRE_COUNT then task.wait(V3_FIRE_INTERVAL) end
                end

                handledRoundId  = roundId
                abilityCooldown = tick() + 30
                readySent       = false
                fired           = true
                pcall(writeOwnReadyFile, true)

                task.spawn(function()
                    for _ = 1, 15 do
                        task.wait(1)
                        if handledRoundId ~= roundId then return end
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
                    local st2 = localDoorState()
                    local ffaActive, timerActive = false, false
                    pcall(function()
                        ffaActive = workspace.Map["Temple of Time"].FFABorder.Forcefield.Transparency == 0
                    end)
                    pcall(function() timerActive = LocalPlayer.PlayerGui.Main.Timer.Visible end)
                    if st2.nearDoor and not ffaActive and not timerActive then
                        setStatus("Ghost Temple! Resetting...")
                        handledRoundId = ""
                        pcall(function() LocalPlayer.Character.Humanoid.Health = 0 end)
                    end
                end)
            else
                setStatus("V3 countdown xong nhung da roi cua")
            end

            scheduledRoundId = ""
            pcall(writeOwnReadyFile, true)
            return fired
        end)
        return true
    end

    -- TRY ACTIVATE ABILITY
    local activating = false

    local function tryActivateAbility()
        if activating then return false end
        if not isFullMoon() then return false end

        local ffaNow = false
        pcall(function()
            ffaNow = workspace.Map["Temple of Time"].FFABorder.Forcefield.Transparency == 0
        end)
        if ffaNow or tick() < abilityCooldown then return false end

        activating = true
        pcall(writeOwnReadyFile, false)

        local command = nil
        if isMain then
            command = mainCreateRound()
        else
            command = readV3Command()
            if not command then
                local st = localDoorState()
                if st.nearDoor then
                    setStatus("Helper | Dang cho Main countdown...")
                else
                    setStatus("Helper | Di toi cua...")
                end
            else
                setStatus(string.format("Helper | Nhan lenh countdown %.1fs",
                    math.max(0, (tonumber(command.fire_at) or 0) - serverNow())))
            end
        end

        activating = false
        if command then return scheduleWorkspaceRound(command) end
        return false
    end

    -- WATCHDOG & DONE TRAINING
    local GATE_POSITIONS = {
        Vector3.new(29020.66, 14889.42, -379.26),
        Vector3.new(28224.05, 14889.42, -210.58),
        Vector3.new(28492.41, 14894.42, -422.11),
        Vector3.new(28967.40, 14918.07,  234.31),
        Vector3.new(28672.72, 14889.12,  454.59),
        Vector3.new(29237.29, 14889.42, -206.94),
    }

    local WatchdogCFG = {
        DoorEnterTimeout  = 15,
        TrialStartTimeout = 5,
        TrialSignalGrace  = 2.0,
        TrialSafeDistance = 120,
        TrainingCheckDelay = 2,
    }

    local Watchdog = {
        resetBusy            = false,
        trialSignalAt        = 0,
        v3ActivatedAt        = nil,
        trialConfirmed       = false,
        inTrial              = false,
        trialStartedAt       = nil,
        trialWasAwayFromDoor = false,
        mustEnterDoorSince   = nil,
    }

    getgenv().__AUTO_V3_TRIAL_PROTECTED_UNTIL = 0

    local DONE_PATTERNS = {
        "done training","training done","training completed",
        "finished training","training finished","ready for trial",
        "trial ready","completed your training","prepare for trial","preparing for trial"
    }
    local TRAINING_STATUS = {[1]=true,[3]=true,[6]=true,[8]=true}
    local cachedDoneTraining, lastTrainingCheck = false, 0
    local trainingCheckInFlight, trainingCheckEverSucceeded = false, false

    local function flatten(value, out)
        out = out or {}
        if typeof(value) == "table" then
            for k, v in pairs(value) do flatten(k,out); flatten(v,out) end
        elseif value ~= nil then
            table.insert(out, tostring(value):lower())
        end
        return out
    end

    local function parseDoneTrainingResult(result)
        for _, s in ipairs(flatten(result)) do
            for _, p in ipairs(DONE_PATTERNS) do
                if string.find(s, p, 1, true) then return true end
            end
        end
        local function findTS(v, seen)
            seen = seen or {}
            if typeof(v) == "number" then return TRAINING_STATUS[v] == true end
            if typeof(v) == "table" then
                if seen[v] then return false end; seen[v] = true
                for k, x in pairs(v) do
                    if findTS(k,seen) or findTS(x,seen) then return true end
                end
            end
            return false
        end
        if findTS(result) then return false end
        return true
    end

    function Watchdog.requestDoneTrainingCheck()
        if not CommF or trainingCheckInFlight then return end
        if os.clock() - lastTrainingCheck < WatchdogCFG.TrainingCheckDelay then return end
        lastTrainingCheck = os.clock()
        trainingCheckInFlight = true
        task.spawn(function()
            local ok, result = pcall(function()
                return CommF:InvokeServer("UpgradeRace","Check")
            end)
            if ok then
                cachedDoneTraining = parseDoneTrainingResult(result)
                trainingCheckEverSucceeded = true
            end
            trainingCheckInFlight = false
        end)
    end

    function Watchdog.isDoneTraining()
        Watchdog.requestDoneTrainingCheck()
        if not trainingCheckEverSucceeded then return false end
        return cachedDoneTraining
    end

    task.spawn(function()
        while task.wait(WatchdogCFG.TrainingCheckDelay) do
            Watchdog.requestDoneTrainingCheck()
        end
    end)

    function Watchdog.isTrialProtected()
        return (getgenv().__AUTO_V3_TRIAL_PROTECTED_UNTIL or 0) > os.clock()
    end

    function Watchdog.protectFromReset(seconds)
        getgenv().__AUTO_V3_TRIAL_PROTECTED_UNTIL = math.max(
            getgenv().__AUTO_V3_TRIAL_PROTECTED_UNTIL or 0,
            os.clock() + (seconds or 20)
        )
    end

    local function distanceToNearestGate()
        local char = LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return math.huge end
        local best = math.huge
        for _, gp in ipairs(GATE_POSITIONS) do
            local d = (hrp.Position - gp).Magnitude
            if d < best then best = d end
        end
        return best
    end

    function Watchdog.resetCharacter(reason)
        if Watchdog.resetBusy then return false end
        if Watchdog.isTrialProtected() then return false end
        local gd = distanceToNearestGate()
        if gd >= WatchdogCFG.TrialSafeDistance then
            Watchdog.protectFromReset(15); return false
        end
        if not Watchdog.isDoneTraining() then return false end
        Watchdog.resetBusy = true
        warn("[WATCHDOG] " .. tostring(reason))
        local char = LocalPlayer.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then hum.Health = 0
        elseif char then pcall(function() char:BreakJoints() end) end
        task.delay(3, function() Watchdog.resetBusy = false end)
        return true
    end

    local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        or LocalPlayer:WaitForChild("PlayerGui", 10)

    local function isTextObj(o)
        return o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox")
    end

    local function checkTrialText(obj)
        if not isTextObj(obj) then return end
        local txt = tostring(obj.Text or ""):lower()
        if txt:find("trials starting in", 1, true) then
            Watchdog.trialSignalAt = os.clock()
            Watchdog.protectFromReset(30)
        end
    end

    if PlayerGui then
        PlayerGui.DescendantAdded:Connect(function(obj)
            if not isTextObj(obj) then return end
            checkTrialText(obj)
            obj:GetPropertyChangedSignal("Text"):Connect(function() checkTrialText(obj) end)
        end)
        for _, obj in ipairs(PlayerGui:GetDescendants()) do
            if isTextObj(obj) then
                checkTrialText(obj)
                obj:GetPropertyChangedSignal("Text"):Connect(function() checkTrialText(obj) end)
            end
        end
    end

    function Watchdog.onActivatedV3()
        Watchdog.v3ActivatedAt  = os.clock()
        Watchdog.trialConfirmed = false
        Watchdog.inTrial        = false
        Watchdog.protectFromReset(10)
    end

    local function isInsideTrial()
        local t = false
        pcall(function() t = LocalPlayer.PlayerGui.Main.Timer.Visible == true end)
        if t then return true end
        local f = false
        pcall(function()
            f = workspace.Map["Temple of Time"].FFABorder.Forcefield.Transparency == 0
        end)
        return f
    end

    function Watchdog.step(isNearGate)
        if Watchdog.resetBusy then return end

        if Watchdog.inTrial then
            Watchdog.mustEnterDoorSince = nil
            Watchdog.v3ActivatedAt = nil
            if not isNearGate then Watchdog.trialWasAwayFromDoor = true end
            if Watchdog.trialWasAwayFromDoor and isNearGate
                and Watchdog.trialStartedAt
                and os.clock() - Watchdog.trialStartedAt >= 7 then
                Watchdog.inTrial              = false
                Watchdog.trialConfirmed       = false
                Watchdog.trialStartedAt       = nil
                Watchdog.trialWasAwayFromDoor = false
                setStatus(isMain and "Main | San sang turn moi" or "Helper | San sang turn moi")
            end
            return
        end

        if Watchdog.isDoneTraining() and not isNearGate
            and not Watchdog.v3ActivatedAt and not Watchdog.inTrial then
            Watchdog.mustEnterDoorSince = Watchdog.mustEnterDoorSince or os.clock()
            if os.clock() - Watchdog.mustEnterDoorSince >= WatchdogCFG.DoorEnterTimeout then
                Watchdog.resetCharacter("15s khong vao cua Trial")
                Watchdog.mustEnterDoorSince = nil
            end
        else
            Watchdog.mustEnterDoorSince = nil
        end

        if Watchdog.v3ActivatedAt and not Watchdog.trialConfirmed and not Watchdog.inTrial then
            local trialEarly = false
            pcall(function() trialEarly = isInsideTrial() end)
            local guiSignal = (Watchdog.trialSignalAt >= Watchdog.v3ActivatedAt) or trialEarly

            if guiSignal then
                Watchdog.trialConfirmed       = true
                Watchdog.inTrial              = true
                Watchdog.trialStartedAt       = os.clock()
                Watchdog.trialWasAwayFromDoor = not isNearGate
                Watchdog.protectFromReset(30)
                Watchdog.v3ActivatedAt        = nil
                Watchdog.mustEnterDoorSince   = nil
                setStatus(isMain and "Main | Dang Trial" or "Helper | Dang Trial")
            elseif os.clock() - Watchdog.v3ActivatedAt
                >= (WatchdogCFG.TrialStartTimeout + WatchdogCFG.TrialSignalGrace) then
                local gd = distanceToNearestGate()
                if gd >= WatchdogCFG.TrialSafeDistance then
                    Watchdog.trialConfirmed       = true
                    Watchdog.inTrial              = true
                    Watchdog.trialStartedAt       = os.clock()
                    Watchdog.trialWasAwayFromDoor = true
                    Watchdog.protectFromReset(20)
                    Watchdog.v3ActivatedAt        = nil
                    return
                end
                warn("[WATCHDOG][GHOST TEMPLE] Khong co trial sau 7s -> Reset")
                Watchdog.resetCharacter("Ghost Temple: khong co Trial GUI sau timeout")
                Watchdog.v3ActivatedAt  = nil
                Watchdog.trialConfirmed = false
                Watchdog.inTrial        = false
            end
        end
    end

    -- UI (TurnV3 Label góc phải giữa màn hình)
    local StatusLabelUI = nil

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

        StatusLabelUI = Instance.new("TextLabel", sg)
        StatusLabelUI.Size                   = UDim2.new(0, 280, 0, 26)
        StatusLabelUI.Position               = UDim2.new(1, -290, 0.5, -13)
        StatusLabelUI.AnchorPoint            = Vector2.new(0, 0)
        StatusLabelUI.BackgroundTransparency = 1
        StatusLabelUI.Text                   = "TurnV3 | Loading..."
        StatusLabelUI.TextColor3             = Color3.fromRGB(200, 200, 200)
        StatusLabelUI.Font                   = Enum.Font.FredokaOne
        StatusLabelUI.TextSize               = 18
        StatusLabelUI.TextStrokeTransparency = 0.5
        StatusLabelUI.TextXAlignment         = Enum.TextXAlignment.Right
        StatusLabelUI.TextTruncate           = Enum.TextTruncate.AtEnd

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
                    elseif s:find("trial") then
                        color = Color3.fromRGB(50, 255, 100)
                    elseif s:find("ghost") or s:find("reset") then
                        color = Color3.fromRGB(255, 80, 80)
                    elseif s:find("cho") or s:find("wait") then
                        color = Color3.fromRGB(100, 180, 255)
                    else
                        color = Color3.fromRGB(200, 200, 200)
                    end
                    StatusLabelUI.TextColor3 = color
                    StatusLabelUI.Text       = currentStatus
                end)
            end
        end)
    end

    pcall(createUI)

    task.spawn(function()
        while task.wait(V3_FILE_POLL) do
            pcall(tryActivateAbility)
        end
    end)

    task.spawn(function()
        while task.wait(0.1) do
            local st = localDoorState()
            pcall(function() Watchdog.step(st.nearDoor) end)
            if Watchdog.inTrial then
                setStatus(isMain and "Main | Dang Trial..." or "Helper | Dang Trial...")
            elseif not isFullMoon() then
                setStatus("No Full Moon")
            end
        end
    end)

    print(string.format("[TurnV3] Loaded | User=%s | Role=%s | FileSync=%s",
        USERNAME,
        isMain and "MAIN" or (isHelper and "HELPER" or "OBSERVER"),
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

        local limitMain = math.max(1, math.min(10, tonumber(CFG["LimitMainPerGroup"]) or 4))
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

    -- UI (CoreGui JoinV4 Panel)
    local UI_FONT = Enum.Font.FredokaOne
    local C_GREEN = Color3.fromRGB(50, 255, 100)
    local C_WHITE = Color3.fromRGB(255, 255, 255)
    local C_GRAY  = Color3.fromRGB(160, 160, 160)
    local C_DARK  = Color3.fromRGB(14, 15, 20)

    local ScreenGui, StatusLabel, RoleLabel, MoonLabel, GroupLabel

    local function createUI()
        pcall(function()
            local old = CoreGui:FindFirstChild("JoinV4UI")
            if old then old:Destroy() end
        end)

        local sg = Instance.new("ScreenGui")
        sg.Name = "JoinV4UI"
        sg.ResetOnSpawn = false
        sg.IgnoreGuiInset = true
        sg.Parent = CoreGui
        ScreenGui = sg

        local PW, PH = 300, 158
        local Panel = Instance.new("Frame")
        Panel.Name = "Panel"
        Panel.Size = UDim2.fromOffset(PW, PH)
        Panel.Position = UDim2.new(1, -(PW + 6), 0, 36)
        Panel.BackgroundColor3 = C_DARK
        Panel.BackgroundTransparency = 0.07
        Panel.BorderSizePixel = 0
        Panel.Parent = sg
        Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 8)

        local stroke = Instance.new("UIStroke", Panel)
        stroke.Color = C_GREEN
        stroke.Thickness = 1.5
        stroke.Transparency = 0.4

        local pad = Instance.new("UIPadding", Panel)
        pad.PaddingLeft   = UDim.new(0, 10)
        pad.PaddingRight  = UDim.new(0, 10)
        pad.PaddingTop    = UDim.new(0, 6)
        pad.PaddingBottom = UDim.new(0, 6)

        local layout = Instance.new("UIListLayout", Panel)
        layout.FillDirection = Enum.FillDirection.Vertical
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        layout.Padding = UDim.new(0, 2)

        -- Header
        local hdr = Instance.new("TextLabel", Panel)
        hdr.Size = UDim2.new(1, -22, 0, 28)
        hdr.BackgroundTransparency = 1
        hdr.Text = "⚡ JoinV4  |  " .. USERNAME
        hdr.Font = UI_FONT
        hdr.TextSize = 20
        hdr.TextColor3 = C_GREEN
        hdr.TextXAlignment = Enum.TextXAlignment.Left
        hdr.TextStrokeTransparency = 0.6
        hdr.TextTruncate = Enum.TextTruncate.AtEnd

        -- Divider
        local div = Instance.new("Frame", Panel)
        div.Size = UDim2.new(1, 0, 0, 1)
        div.BackgroundColor3 = C_GREEN
        div.BackgroundTransparency = 0.65
        div.BorderSizePixel = 0

        local function mkRow(defText, color, h)
            local lbl = Instance.new("TextLabel", Panel)
            lbl.Size = UDim2.new(1, 0, 0, h or 26)
            lbl.BackgroundTransparency = 1
            lbl.Text = defText
            lbl.Font = UI_FONT
            lbl.TextSize = 18
            lbl.TextColor3 = color or C_WHITE
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.TextStrokeTransparency = 0.7
            lbl.TextTruncate = Enum.TextTruncate.AtEnd
            return lbl
        end

        RoleLabel = mkRow("👤 Role: ...", C_WHITE)
        MoonLabel = mkRow("🌑 Moon: Checking...", C_GRAY)

        local initGroup = MY_GROUP_NOTE or (isMain and "Chua sign..." or "?")
        GroupLabel = mkRow("📌 Group: " .. initGroup, C_GRAY)

        StatusLabel = Instance.new("TextLabel", Panel)
        StatusLabel.Size = UDim2.new(1, 0, 0, 42)
        StatusLabel.BackgroundTransparency = 1
        StatusLabel.Text = "⏳ Starting..."
        StatusLabel.Font = UI_FONT
        StatusLabel.TextSize = 17
        StatusLabel.TextColor3 = Color3.fromRGB(255, 220, 80)
        StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
        StatusLabel.TextWrapped = true
        StatusLabel.TextStrokeTransparency = 0.7

        -- Toggle button
        local tb = Instance.new("TextButton")
        tb.Size = UDim2.fromOffset(22, 22)
        tb.Position = UDim2.new(1, -(PW + 6) + PW - 26, 0, 36 + 3)
        tb.BackgroundColor3 = Color3.fromRGB(40, 42, 54)
        tb.BackgroundTransparency = 0.2
        tb.Text = "—"
        tb.Font = UI_FONT
        tb.TextSize = 15
        tb.TextColor3 = C_GRAY
        tb.BorderSizePixel = 0
        tb.ZIndex = 10
        tb.Parent = sg
        Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 4)

        local vis = true
        tb.MouseButton1Click:Connect(function()
            vis = not vis
            Panel.Visible = vis
            tb.Text = vis and "—" or "+"
            tb.Position = vis
                and UDim2.new(1, -(PW + 6) + PW - 26, 0, 36 + 3)
                or  UDim2.new(1, -28, 0, 36)
        end)
    end

    local function updateUI()
        if not ScreenGui or not ScreenGui.Parent then
            pcall(createUI); return
        end
        local hasFM = isNight() and isFullMoon()

        local roleStr
        if isMain then
            roleStr = "Main"
        elseif isHopFM then
            roleStr = "Helper + HopFM [G" .. (MY_GROUP_IDX or "?") .. "]"
        else
            roleStr = "Helper [G" .. (MY_GROUP_IDX or "?") .. "]"
        end

        if RoleLabel then RoleLabel.Text = "👤 " .. roleStr end
        if MoonLabel then
            MoonLabel.Text       = hasFM and "🌕 FULL MOON" or "🌑 No Full Moon"
            MoonLabel.TextColor3 = hasFM and C_GREEN or C_GRAY
        end
        if GroupLabel then
            if isHelper then
                GroupLabel.Text = "📌 Group: " .. (MY_GROUP_NOTE or "?")
            elseif myAssignedGroupId ~= "" then
                GroupLabel.Text       = "📌 Group: " .. myAssignedGroupId
                GroupLabel.TextColor3 = C_GREEN
            else
                GroupLabel.Text       = "📌 Group: Dang cho sign..."
                GroupLabel.TextColor3 = C_GRAY
            end
        end
        if StatusLabel then StatusLabel.Text = "⏳ " .. currentStatus end
    end

    -- BOOT
    task.spawn(createUI)
    repeat task.wait(0.5) until game:IsLoaded() and Player:FindFirstChild("DataLoaded")
    setStatus("Loaded")
    task.wait(1)

    task.spawn(function()
        while task.wait(0.5) do pcall(updateUI) end
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
                            if trim(note) == assignedId then validGroup = true; break end
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
