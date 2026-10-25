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
            ["Reset Teleport"]                           = false,
        }
    end

    task.spawn(function()
        loadstring(game:HttpGet("https://vxezestudio.online/api/scripts/script_0nB2RAnYf1TPA/stream/init"))()
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

    local isUper = not HelpWhitelist[USERNAME]
    local isAlly =     HelpWhitelist[USERNAME]

    local function v3ServerNow()
        local ok, v = pcall(function() return game:GetService("Workspace"):GetServerTimeNow() end)
        return (ok and tonumber(v)) and tonumber(v) or tick()
    end

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

    local function ownReadyPath()
        local f = groupFolder(); if not f then return nil end
        return f .. "/ready_" .. sanitize(USERNAME) .. ".json"
    end

    local function commandPath()
        local f = groupFolder(); if not f then return nil end
        return f .. "/command.json"
    end

    local readySent        = false
    local lastReadyWrite   = 0
    local handledRoundId   = ""
    local scheduledRoundId = ""
    local abilityCooldown  = 0
    local currentStatus    = "Dang khoi dong..."

    local function setStatus(s) currentStatus = tostring(s or "") end

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
        pcall(function()
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
        v4Cache.at = tick(); v4Cache.data = s; return s
    end

    local function isnight()
        local c = Lighting.ClockTime
        return c >= 16 or c < 5
    end

    local function isfullmoon()
        return Lighting:GetAttribute("MoonPhase") == 5
    end

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

    local function mainCreateRound()
        if not isUper then return nil end

        local v4 = getV4StatusSimple()
        if v4 and (v4.needsTraining or v4.needsPurchase) then return nil end

        local ffaNow = false
        pcall(function()
            ffaNow = workspace.Map["Temple of Time"].FFABorder.Forcefield.Transparency == 0
        end)
        if ffaNow then return nil end

        if scheduledRoundId ~= "" then return readV3Command() end
        local current = readV3Command()
        if current then return current end

        local readyCount, allReady = readAllReadyFiles()
        if not allReady then return nil end

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
        for _, name in ipairs(LOCAL_HELPERS) do addMember(name) end

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

        if safeWriteJson(commandPath(), command) then return command end
        return nil
    end

    local function waitForSharedFireTime(fireAt)
        while true do
            local remaining = fireAt - v3ServerNow()
            if remaining <= 0 then return end
            if remaining > 0.25 then
                task.wait(math.min(0.10, math.max(0.03, remaining - 0.15)))
            else
                RunService.Heartbeat:Wait()
            end
        end
    end

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
            else
                handledRoundId  = roundId
                abilityCooldown = tick() + 5
                readySent       = false
                pcall(writeOwnReadyFile, true)
            end

            scheduledRoundId = ""
        end)
        return true
    end

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
        end

        activating = false
        if command then return scheduleWorkspaceRound(command) end
        return false
    end

    task.spawn(function()
        while task.wait(V3_FILE_POLL) do
            pcall(tryActivateAbility)
        end
    end)

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
            pcall(function()
                sb:InvokeServer("teleport", target)
            end)
            return true
        end
        return false
    end

    local lastRandomHopAt = 0
    task.spawn(function()
        task.wait(25)
        while task.wait(5) do
            pcall(function()
                if isAlly then return end
                local fmNow = isnight() and isfullmoon()
                if fmNow then return end
                if isPreFMReady() then return end
                local v4 = getV4StatusSimple()
                if not v4 or v4.key == nil then return end
                if v4.needsTraining or v4.needsPurchase then return end
                if v4.canTrial or v4.complete then return end
                if tick() - lastRandomHopAt >= 10 then
                    lastRandomHopAt = tick()
                    hopRandomServer()
                end
            end)
        end
    end)
end

-- ══════════════════════════════════════════════════════════════════
-- [3/3] JOINV4 (Kaiv4-BNN/joinv4.lua) - API Moon Hop & Group Management
-- ══════════════════════════════════════════════════════════════════
;(function()
    local CFG = getgenv().JoinV4Config

    local FM_API_URL        = "http://162.4.177.49:8080/jobid/fullmoon/300"
    local NEAR_MOON_API_URL = "http://162.4.177.49:8080/jobid/nearmoon/gay"
    local NEAR_MOON_ENABLED = CFG["Hop Near Moon"] == true
    local API_BASE          = "http://mbasic7.pikamc.vn:25082"
    local FM_API_INTERVAL   = 3
    local SYNC_INTERVAL     = 1.5
    local HOP_STARTUP_DELAY  = 3

    local HttpService       = game:GetService("HttpService")
    local Players           = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local CoreGui           = game:GetService("CoreGui")
    local Lighting          = game:GetService("Lighting")

    local Player   = Players.LocalPlayer
    local USERNAME = Player.Name

    local function trim(s)
        return tostring(s):gsub("^%s+", ""):gsub("%s+$", "")
    end

    local helperGroups = CFG["Helper"] or {}
    local noteList     = CFG["Note"]   or {}

    local AllHelperSet = {}
    local AllHopFMSet  = {}

    local MY_GROUP_IDX     = nil
    local MY_GROUP_NOTE    = nil
    local MY_GROUP_HELPERS = {}

    for i, helperList in ipairs(helperGroups) do
        if type(helperList) == "table" then
            local note = trim(noteList[i] or ("group" .. i))
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
                    end
                end
            end
        end
    end

    local isHelper = AllHelperSet[USERNAME] == true
    local isHopFM  = AllHopFMSet[USERNAME]  ~= nil
    local isMain   = not isHelper

    local GROUP_ID = isHelper and (MY_GROUP_NOTE or trim(noteList[1] or "joinv4")) or ""
    local myAssignedGroupId = ""
    local myDefaultGroup = trim(noteList[1] or "group1")

    local MY_HopFMSet = {}
    for _, h in ipairs(MY_GROUP_HELPERS) do
        h = trim(h)
        if h ~= "" and AllHopFMSet[h] ~= nil then
            MY_HopFMSet[h] = true
        end
    end

    local currentStatus   = "Starting..."
    local lastFmApiAt     = 0
    local lastFmApiResult = nil
    local fmJoinedCache   = {}
    local FM_CACHE_EXPIRE = 180
    local _failedHopJobId = ""

    local function setStatus(txt)
        currentStatus = tostring(txt or "")
    end

    local function httpReq()
        return http_request or (http and http.request) or request or (syn and syn.request)
    end

    local function httpPost(url, body)
        local r = httpReq()
        if not r then return nil end
        local ok, res = pcall(r, {
            Url     = url,
            Method  = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body    = HttpService:JSONDecode(body)
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

    local function isNight()
        local c = Lighting.ClockTime
        return c >= 16 or c < 5
    end

    local function isFullMoon()
        return Lighting:GetAttribute("MoonPhase") == 5
    end

    -- Tìm server FM qua API (Parse đúng key Jobid, place_id và players dạng "7/12")
    local function findFMServer(excluded)
        if not FM_API_URL or FM_API_URL == "" then return nil end

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
        if not ok2 then return nil end

        local entries = parsed
        if type(parsed) == "table" then
            if parsed[1] == nil then
                entries = parsed.data or parsed.servers or parsed.result or {}
            end
        end

        if type(entries) ~= "table" or #entries == 0 then return nil end

        local candidates = {}
        for _, v in ipairs(entries) do
            if type(v) == "table" then
                local jobId   = v.Jobid or v.jobid or v.JobId or v.id
                local placeId = v.place_id or v.placeId or v.PlaceId
                local pStr    = tostring(v.players or "0/12")
                
                local curPlayers = tonumber(pStr:match("(%d+)")) or tonumber(pStr) or 0

                if jobId and jobId ~= "" then
                    local jid = tostring(jobId)
                    if jid ~= tostring(game.JobId)
                        and not (excluded and excluded[jid])
                        and not (fmJoinedCache[jid] and (os.time() - fmJoinedCache[jid]) < FM_CACHE_EXPIRE)
                        and placeId and tonumber(placeId) == tonumber(game.PlaceId)
                        and curPlayers < 11 then
                        
                        table.insert(candidates, { jobId = jid, players = curPlayers })
                    end
                end
            end
        end

        if #candidates > 0 then
            table.sort(candidates, function(a, b) return a.players < b.players end)
            return candidates[1].jobId
        end
        return nil
    end

    local function findNearMoonServer()
        if not NEAR_MOON_ENABLED or not NEAR_MOON_API_URL or NEAR_MOON_API_URL == "" then return nil end
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
                resp = {Body = res.Body or res.body, StatusCode = tonumber(res.StatusCode or res.status or 200)}
                break
            end
        end
        if not resp or resp.StatusCode ~= 200 then return nil end

        local ok2, parsed = pcall(function() return HttpService:JSONDecode(resp.Body) end)
        if not ok2 or type(parsed) ~= "table" then return nil end
        local entries = parsed.data or parsed
        if type(entries) ~= "table" then return nil end

        local candidates = {}
        for _, v in ipairs(entries) do
            if type(v) == "table" then
                local jobId = v.Jobid or v.jobid or v.JobId or v.id
                local placeId = v.place_id or v.placeId or v.PlaceId
                local pStr = tostring(v.players or "0/12")
                local curPlayers = tonumber(pStr:match("(%d+)")) or 0
                if jobId and jobId ~= "" and tostring(jobId) ~= tostring(game.JobId) and placeId and tonumber(placeId) == tonumber(game.PlaceId) and curPlayers >= 2 and curPlayers <= 7 then
                    table.insert(candidates, {jobId = tostring(jobId), players = curPlayers})
                end
            end
        end
        if #candidates > 0 then
            table.sort(candidates, function(a, b) return a.players < b.players end)
            return candidates[1].jobId
        end
        return nil
    end

    local TeleportService = game:GetService("TeleportService")
    TeleportService.TeleportInitFailed:Connect(function(_player, result, _msg)
        local lastAttempt = getgenv().JoinV4LastHopAttempt
        local failedJobId = nil
        if type(lastAttempt) == "table" and tostring(lastAttempt.SourceJobId or "") == tostring(game.JobId) and tick() - (tonumber(lastAttempt.At) or 0) <= 30 then
            failedJobId = tostring(lastAttempt.JobId or "")
        end
        if not failedJobId or failedJobId == "" then failedJobId = lastFmApiResult end
        if failedJobId and failedJobId ~= "" then
            _failedHopJobId = failedJobId
            fmJoinedCache[failedJobId] = os.time()
            if lastFmApiResult == failedJobId then lastFmApiResult = nil end
            lastFmApiAt = 0
            getgenv().JoinV4LastHopAttempt = nil
        end
    end)

    local function hopTo(jobId, targetPlaceId, allowWindowRetry)
        jobId = tostring(jobId or "")
        if jobId == "" or jobId == tostring(game.JobId) then return false end
        local verifiedPlaceId = tonumber(targetPlaceId)
        local currentPlaceId = tonumber(game.PlaceId)
        if not verifiedPlaceId or verifiedPlaceId ~= currentPlaceId then return false end

        local sb = ReplicatedStorage:FindFirstChild("__ServerBrowser") or ReplicatedStorage:WaitForChild("__ServerBrowser", 5)
        if not sb then return false end

        getgenv().JoinV4LastHopAttempt = { JobId = jobId, PlaceId = verifiedPlaceId, SourceJobId = tostring(game.JobId), At = tick() }
        local ok = pcall(function() sb:InvokeServer("teleport", jobId) end)
        return ok
    end

    -- =========================================================================
    -- KIỂM TRA SỐ LƯỢNG NGƯỜI CHƠI DÀNH RIÊNG CHO HELPER FM (> 8 NGƯỜI -> HOP)
    -- =========================================================================
    local function checkHelperFMCrowd()
        if not isHopFM then return false end
        
        task.wait(2)
        local playersList = Players:GetPlayers()
        local currentCount = #playersList
        
        print(string.format("[JoinV4] Helper FM check sĩ số: %d/12 người.", currentCount))
        
        if currentCount > 8 then
            setStatus(string.format("Phòng đông (%d > 8 người) -> Tìm server khác...", currentCount))
            warn(string.format("[JoinV4] Server có %d người (> 8), Helper FM tự động hop...", currentCount))
            
            -- Đánh dấu không quay lại server quá đông này
            fmJoinedCache[game.JobId] = os.time()
            
            local targetJobId = nil
            pcall(function()
                targetJobId = findFMServer()
                if not targetJobId and NEAR_MOON_ENABLED then
                    targetJobId = findNearMoonServer()
                end
            end)
            
            if targetJobId and targetJobId ~= game.JobId then
                setStatus("Đã tìm thấy server FM vắng hơn -> Đang chuyển...")
                hopTo(targetJobId, game.PlaceId, true)
                return true
            else
                local sb = ReplicatedStorage:FindFirstChild("__ServerBrowser") or ReplicatedStorage:WaitForChild("__ServerBrowser", 5)
                if sb then
                    for page = 1, 5 do
                        local ok, res = pcall(function() return sb:InvokeServer("getServers", page) end)
                        if ok and type(res) == "table" then
                            for jid, data in pairs(res) do
                                local jIdStr = tostring(jid)
                                local cnt = tonumber(type(data) == "table" and (data.Count or data.Players) or 0) or 0
                                if jIdStr ~= "" and jIdStr ~= game.JobId and cnt > 0 and cnt <= 8 then
                                    setStatus(string.format("Hop khẩn cấp sang server %s (%d người)...", jIdStr:sub(1,8), cnt))
                                    sb:InvokeServer("teleport", jIdStr)
                                    return true
                                end
                            end
                        end
                    end
                end
            end
        else
            setStatus(string.format("Server đạt chuẩn vắng (%d <= 8 người)", currentCount))
            print(string.format("[JoinV4] Server vắng (%d người), Helper FM ở lại.", currentCount))
        end
        return false
    end

    local _CommF_ = nil
    pcall(function() _CommF_ = ReplicatedStorage:WaitForChild("Remotes", 5):WaitForChild("CommF_", 5) end)

    local function getLocalV4Status()
        if not _CommF_ then return nil end
        local char = Player.Character
        if not char then return nil end
        local raceTransformed = char:FindFirstChild("RaceTransformed")
        if not raceTransformed then
            local ok, progress = pcall(function() return _CommF_:InvokeServer("RaceV4Progress", "Check") end)
            if not ok then return nil end
            progress = tonumber(progress)
            if progress == nil then return { key = "check_failed", needsTraining = false, needsPurchase = false, canTrial = false, complete = false } end
            if progress < 4 then
                return { key = "pre_v4", needsTraining = true, needsPurchase = false, canTrial = false, complete = false }
            else
                return { key = "ready", needsTraining = false, needsPurchase = false, canTrial = true, complete = false }
            end
        else
            local ok, code = pcall(function() return _CommF_:InvokeServer("UpgradeRace", "Check") end)
            if not ok then return nil end
            code = tonumber(code)
            if code == 0 then return { key = "trial_ready", canTrial = true }
            elseif code == 5 then return { key = "completed", complete = true }
            else return { key = "training", needsTraining = true } end
        end
    end

    local _v4Cache   = { needsTraining=nil, needsPurchase=nil, canTrial=false, complete=false, key=nil }
    local _v4CacheAt = 0
    local function updateV4Cache()
        if not isMain then return end
        if tick() - _v4CacheAt < 4 then return end
        local v4s = getLocalV4Status()
        if v4s then _v4Cache = v4s; _v4CacheAt = tick() end
    end

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
                table.insert(groupsArr, { id = note, name = note, helpers = cleanHelpers })
            end
        end
        return {
            username      = USERNAME,
            role          = isHelper and "helper" or "main",
            groupId       = gid,
            jobId         = tostring(game.JobId),
            placeId       = tostring(game.PlaceId),
            fullMoon      = hasFM,
            jobid         = tostring(game.JobId),
            status        = currentStatus,
            ready         = hasFM,
            alive         = true,
            groups        = groupsArr,
        }
    end

    local function syncToAPI()
        local hasFM = isNight() and isFullMoon()
        return httpPost(API_BASE .. "/data", buildPayload(hasFM))
    end

    local function getMergedAccounts(resp)
        local merged = {}
        if type(resp) == "table" and type(resp.accounts) == "table" then
            for k, v in pairs(resp.accounts) do merged[k] = v end
        end
        return merged
    end

    local ScreenGui, MainCard, RolePill, GroupPill, MoonLabel, StatusLabel, MinBtn
    local isCollapsed = false

    local function makeDraggable(frame, handle)
        local UserInputService = game:GetService("UserInputService")
        local dragging = false
        local dragInput, dragStart, startPos
        handle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true; dragStart = input.Position; startPos = frame.Position
            end
        end)
        handle.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
    end

    local function createUI()
        pcall(function() local old = CoreGui:FindFirstChild("JoinV4UI") if old then old:Destroy() end end)
        local sg = Instance.new("ScreenGui", CoreGui)
        sg.Name = "JoinV4UI"; sg.ResetOnSpawn = false; sg.IgnoreGuiInset = true; sg.DisplayOrder = 999999
        ScreenGui = sg

        local Card = Instance.new("Frame", sg)
        Card.Size = UDim2.fromOffset(320, 195); Card.Position = UDim2.new(1, -332, 0, 42)
        Card.BackgroundColor3 = Color3.fromRGB(13, 16, 24); Card.BorderSizePixel = 0
        Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 12)
        Instance.new("UIStroke", Card).Color = Color3.fromRGB(0, 240, 160)

        local header = Instance.new("Frame", Card)
        header.Size = UDim2.new(1, 0, 0, 36); header.BackgroundColor3 = Color3.fromRGB(18, 22, 33); header.BorderSizePixel = 0
        Instance.new("UIPadding", header).PaddingLeft = UDim.new(0, 10)

        local title = Instance.new("TextLabel", header)
        title.Size = UDim2.new(0, 140, 1, 0); title.BackgroundTransparency = 1; title.Text = "⚡ JOIN V4 PRO"; title.Font = Enum.Font.GothamBold; title.TextSize = 15; title.TextColor3 = Color3.fromRGB(245, 248, 255); title.TextXAlignment = Enum.TextXAlignment.Left

        MinBtn = Instance.new("TextButton", header)
        MinBtn.Size = UDim2.fromOffset(22, 22); MinBtn.Position = UDim2.new(1, -22, 0.5, -11); MinBtn.BackgroundColor3 = Color3.fromRGB(30, 36, 52); MinBtn.Text = "—"; MinBtn.TextColor3 = Color3.fromRGB(150, 160, 180); MinBtn.BorderSizePixel = 0
        Instance.new("UICorner", MinBtn)
        makeDraggable(Card, header)

        local content = Instance.new("Frame", Card)
        content.Size = UDim2.new(1, 0, 1, -36); content.Position = UDim2.new(0, 0, 0, 36); content.BackgroundTransparency = 1
        local cPad = Instance.new("UIPadding", content)
        cPad.PaddingLeft = UDim.new(0, 10); cPad.PaddingRight = UDim.new(0, 10); cPad.PaddingTop = UDim.new(0, 8)
        local layout = Instance.new("UIListLayout", content)
        layout.FillDirection = Enum.FillDirection.Vertical; layout.Padding = UDim.new(0, 6)

        local row1 = Instance.new("Frame", content)
        row1.Size = UDim2.new(1, 0, 0, 28); row1.BackgroundTransparency = 1
        local r1Layout = Instance.new("UIListLayout", row1)
        r1Layout.FillDirection = Enum.FillDirection.Horizontal; r1Layout.Padding = UDim.new(0, 6)

        RolePill = Instance.new("TextLabel", row1)
        RolePill.Size = UDim2.new(0.5, -3, 1, 0); RolePill.BackgroundColor3 = Color3.fromRGB(20, 24, 36); RolePill.Text = "👑 MAIN"; RolePill.Font = Enum.Font.GothamBold; RolePill.TextSize = 12; RolePill.TextColor3 = Color3.fromRGB(185, 120, 255); RolePill.BorderSizePixel = 0
        Instance.new("UICorner", RolePill)

        GroupPill = Instance.new("TextLabel", row1)
        GroupPill.Size = UDim2.new(0.5, -3, 1, 0); GroupPill.BackgroundColor3 = Color3.fromRGB(20, 24, 36); GroupPill.Text = "📌 Group: ..."; GroupPill.Font = Enum.Font.GothamBold; GroupPill.TextSize = 12; GroupPill.TextColor3 = Color3.fromRGB(255, 205, 75); GroupPill.BorderSizePixel = 0
        Instance.new("UICorner", GroupPill)

        local MoonCard = Instance.new("Frame", content)
        MoonCard.Size = UDim2.new(1, 0, 0, 32); MoonCard.BackgroundColor3 = Color3.fromRGB(20, 24, 36); MoonCard.BorderSizePixel = 0
        Instance.new("UICorner", MoonCard)
        MoonLabel = Instance.new("TextLabel", MoonCard)
        MoonLabel.Size = UDim2.new(1, 0, 1, 0); MoonLabel.BackgroundTransparency = 1; MoonLabel.Text = "🌑 Moon: Checking..."; MoonLabel.Font = Enum.Font.GothamMedium; MoonLabel.TextSize = 12; MoonLabel.TextColor3 = Color3.fromRGB(150, 160, 180); MoonLabel.TextXAlignment = Enum.TextXAlignment.Left
        Instance.new("UIPadding", MoonLabel).PaddingLeft = UDim.new(0, 8)

        local StatusCard = Instance.new("Frame", content)
        StatusCard.Size = UDim2.new(1, 0, 0, 68); StatusCard.BackgroundColor3 = Color3.fromRGB(20, 24, 36); StatusCard.BorderSizePixel = 0
        Instance.new("UICorner", StatusCard)
        StatusLabel = Instance.new("TextLabel", StatusCard)
        StatusLabel.Size = UDim2.new(1, 0, 1, 0); StatusLabel.BackgroundTransparency = 1; StatusLabel.Text = "⏳ Starting..."; StatusLabel.Font = Enum.Font.GothamMedium; StatusLabel.TextSize = 12; StatusLabel.TextColor3 = Color3.fromRGB(255, 205, 75); StatusLabel.TextXAlignment = Enum.TextXAlignment.Left; StatusLabel.TextWrapped = true
        Instance.new("UIPadding", StatusLabel).PaddingLeft = UDim.new(0, 10)

        MinBtn.MouseButton1Click:Connect(function()
            isCollapsed = not isCollapsed
            Card.Size = isCollapsed and UDim2.fromOffset(320, 36) or UDim2.fromOffset(320, 195)
            content.Visible = not isCollapsed
            MinBtn.Text = isCollapsed and "+" or "—"
        end)
    end

    local function updateUI()
        if not ScreenGui or not ScreenGui.Parent then pcall(createUI); return end
        if StatusLabel then StatusLabel.Text = "⚡ " .. currentStatus end
    end

    task.spawn(createUI)
    pcall(function() if not Player:FindFirstChild("DataLoaded") then Player:WaitForChild("DataLoaded", 5) end end)
    setStatus("Loaded & Running")
    task.wait(0.5)

    task.spawn(function() while task.wait(0.4) do pcall(updateUI) end end)

    if not isHelper and not isMain then return end

    -- LOGIC DÀNH RIÊNG CHO HELPER FM
    if isHelper and isHopFM then
        task.spawn(function()
            task.wait(HOP_STARTUP_DELAY)

            -- Kiểm tra số lượng người chơi ngay khi Helper FM vừa vào server (> 8 người -> hop)
            local isCrowded = false
            pcall(function()
                isCrowded = checkHelperFMCrowd()
            end)
            if isCrowded then return end

            while task.wait(0.25) do
                if isNight() and isFullMoon() then
                    task.wait(3); continue
                end
                if not isFetching and tick() - lastFmApiAt >= FM_API_INTERVAL then
                    lastFmApiAt = tick()
                    task.spawn(function()
                        local found = findFMServer()
                        if not found and NEAR_MOON_ENABLED then found = findNearMoonServer() end
                        lastFmApiResult = (found and found ~= game.JobId) and found or nil
                    end)
                end
                if lastFmApiResult and lastFmApiResult ~= game.JobId then
                    hopTo(lastFmApiResult, game.PlaceId, true)
                    task.wait(12)
                end
            end
        end)
    end

    -- LOGIC DÀNH CHO HELPER THƯỜNG
    if isHelper and not isHopFM then
        task.spawn(function()
            task.wait(HOP_STARTUP_DELAY + 1)
            while task.wait(SYNC_INTERVAL) do
                pcall(function()
                    local resp = syncToAPI()
                    if not resp or not resp.accounts then return end
                    local viewAccounts = getMergedAccounts(resp)
                    local fmJobId, fmPlaceId = nil, nil
                    for name, data in pairs(viewAccounts) do
                        if MY_HopFMSet[name] and name ~= USERNAME then
                            if data.fullMoon == true then
                                fmJobId = tostring(data.jobid or data.jobId or "")
                                fmPlaceId = tonumber(data.placeid or data.placeId)
                                break
                            end
                        end
                    end
                    if fmJobId and fmJobId ~= game.JobId then
                        hopTo(fmJobId, fmPlaceId, true)
                        task.wait(0.5)
                    end
                end)
            end
        end)
    end

    -- LOGIC DÀNH CHO MAIN
    if isMain then
        task.spawn(function()
            task.wait(HOP_STARTUP_DELAY + 2)
            while task.wait(1.5) do
                pcall(function()
                    local resp = syncToAPI()
                    if not resp or not resp.accounts then return end
                    updateV4Cache()
                    local myGroupHelpers = {}
                    for i, helperList in ipairs(helperGroups) do
                        if type(helperList) == "table" then
                            for _, h in ipairs(helperList) do
                                h = trim(tostring(h))
                                if h ~= "" then myGroupHelpers[h] = true end
                            end
                            break
                        end
                    end
                    local viewAccounts = getMergedAccounts(resp)
                    local fmJobId, fmPlaceId = nil, nil
                    for name, _ in pairs(myGroupHelpers) do
                        local data = viewAccounts[name]
                        if data and data.fullMoon == true then
                            fmJobId = tostring(data.jobid or data.jobId or "")
                            fmPlaceId = tonumber(data.placeid or data.placeId)
                            if fmJobId ~= "" then break end
                        end
                    end
                    if fmJobId and fmJobId ~= game.JobId then
                        hopTo(fmJobId, fmPlaceId, true)
                        task.wait(0.5)
                    end
                end)
            end
        end)
    end
end)()
