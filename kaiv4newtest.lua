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
