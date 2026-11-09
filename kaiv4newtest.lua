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
