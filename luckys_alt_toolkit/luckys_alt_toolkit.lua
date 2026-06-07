-- Lucky's Alt Toolkit
-- Entry point and initialization.

LuckyAltToolkit = LuckyAltToolkit or {}

local ADDON_NAME = "luckys_alt_toolkit"

LuckyAltToolkit.MAX_LEVEL = 90

local DB_DEFAULTS = {
    devMode = false,
    windowAlpha = 30,
    statWeightOverrides = {},
    delversCall = {
        devMode    = false,
        xpPerQuest = 0,
        shown      = "leveling",
        framePos   = nil,
    },
    questRewardAdvisor = {
        shown = "leveling",
    },
    skipCinematics = {
        enabled = "leveling",
    },
    autoQuest = {
        enabled = "leveling",
    },
    minimap = {},
}

-- Per-character saved variables. The stat-priority window is per-character
-- so each alt can toggle it and position it independently.
local CHAR_DB_DEFAULTS = {
    specStats = {
        shown    = "on",
        framePos = nil,
    },
}

local PREFIX = "|cffc9a84cAlt Manager|r:"

function LuckyAltToolkit.DevLog(module, msg)
    if LuckyAltToolkitDB and LuckyAltToolkitDB.devMode then
        print(PREFIX .. " |cff8a7e6a[" .. module .. "]|r " .. tostring(msg))
    end
end

--- Resolve a 3-way setting ("on", "off", "leveling") to a boolean.
function LuckyAltToolkit.IsFeatureActive(settingValue)
    if settingValue == "on" then return true end
    if settingValue == "leveling" then
        return UnitLevel("player") < LuckyAltToolkit.MAX_LEVEL
    end
    return false
end

local function ApplyDefaults(target, defaults)
    for key, default in pairs(defaults) do
        if target[key] == nil then
            if type(default) == "table" then
                target[key] = {}
                ApplyDefaults(target[key], default)
            else
                target[key] = default
            end
        end
    end
end

-- Migrate old boolean settings to 3-way string values.
local function MigrateBoolToTriState(tbl, key)
    if type(tbl[key]) == "boolean" then
        tbl[key] = tbl[key] and "on" or "off"
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, addonName)
    if event == "PLAYER_LEVEL_UP" then
        if UnitLevel("player") >= LuckyAltToolkit.MAX_LEVEL then
            if LuckyAltToolkitCharDB.specStats.shown == "leveling" then
                LuckyAltToolkit.SpecStats:SetShown("leveling")
            end
            if LuckyAltToolkitDB.delversCall.shown == "leveling" then
                LuckyAltToolkit.DelversCall:SetShown("leveling")
            end
        end
        return
    end

    if event ~= "ADDON_LOADED" or addonName ~= ADDON_NAME then return end

    LuckyAltToolkitDB = LuckyAltToolkitDB or {}  ---@diagnostic disable-line: lowercase-global
    ApplyDefaults(LuckyAltToolkitDB, DB_DEFAULTS)

    LuckyAltToolkitCharDB = LuckyAltToolkitCharDB or {}  ---@diagnostic disable-line: lowercase-global

    -- One-time migration: move the (previously global) stat-priority window
    -- settings into per-character storage so existing users keep their state.
    if LuckyAltToolkitDB.specStats and not LuckyAltToolkitCharDB._migratedSpecStats then
        LuckyAltToolkitCharDB.specStats = {
            shown    = LuckyAltToolkitDB.specStats.shown,
            framePos = LuckyAltToolkitDB.specStats.framePos,
        }
        LuckyAltToolkitCharDB._migratedSpecStats = true
        LuckyAltToolkitDB.specStats = nil
    end

    ApplyDefaults(LuckyAltToolkitCharDB, CHAR_DB_DEFAULTS)

    -- Migrate boolean -> tri-state for existing installs
    MigrateBoolToTriState(LuckyAltToolkitCharDB.specStats, "shown")
    MigrateBoolToTriState(LuckyAltToolkitDB.questRewardAdvisor, "shown")
    MigrateBoolToTriState(LuckyAltToolkitDB.autoQuest, "enabled")
    MigrateBoolToTriState(LuckyAltToolkitDB.skipCinematics, "enabled")
    MigrateBoolToTriState(LuckyAltToolkitDB.delversCall, "shown")

    LuckyAltToolkit.StatWeightOverrides:Init(LuckyAltToolkitDB)
    LuckyAltToolkit.DelversCall:Init(LuckyAltToolkitDB.delversCall)
    LuckyAltToolkit.SpecStats:Init(LuckyAltToolkitCharDB.specStats)
    LuckyAltToolkit.QuestRewardAdvisor:Init(LuckyAltToolkitDB.questRewardAdvisor)
    LuckyAltToolkit.SkipCinematics:Init(LuckyAltToolkitDB.skipCinematics)
    LuckyAltToolkit.AutoQuest:Init(LuckyAltToolkitDB.autoQuest)
    LuckyAltToolkit.Settings:Init(LuckyAltToolkitDB, LuckyAltToolkitCharDB)

    SLASH_LUCKYALTTOOLKIT1 = "/lat"
    SlashCmdList["LUCKYALTTOOLKIT"] = function()
        LuckySettings:Open(LuckyAltToolkit.Settings.category)
    end

    LuckyMinimap:Create({
        name    = "LuckyAltToolkitMinimapButton",
        icon    = "Interface\\Icons\\Achievement_Character_Human_Male",
        dbKey   = "minimap",
        db      = LuckyAltToolkitDB,
        onClick = function(_, mouseBtn)
            if mouseBtn == "MiddleButton" then
                LuckyAltToolkitDB.devMode = not LuckyAltToolkitDB.devMode
                local state = LuckyAltToolkitDB.devMode and "ON" or "OFF"
                print(PREFIX .. " Dev mode " .. state)
            else
                LuckySettings:Open(LuckyAltToolkit.Settings.category)
            end
        end,
        tooltip = function(tt)
            tt:AddLine(LuckyUI.WC.goldPrimary .. "Lucky's Alt Toolkit" .. LuckyUI.WC.reset)
            tt:AddLine(" ")
            tt:AddLine("Click: Open settings", 0.91, 0.86, 0.78)
            tt:AddLine("Middle-click: Toggle dev mode", 0.54, 0.49, 0.42)
            tt:AddLine("Drag: Move button", 0.54, 0.49, 0.42)
        end,
    })

    self:UnregisterEvent("ADDON_LOADED")
    self:RegisterEvent("PLAYER_LEVEL_UP")
end)
