-- Lucky's Alt Manager
-- Entry point and initialization.

LuckyAltManager = LuckyAltManager or {}

local ADDON_NAME = "luckys_alt_manager"

LuckyAltManager.MAX_LEVEL = 90

local DB_DEFAULTS = {
    devMode = false,
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

function LuckyAltManager.DevLog(module, msg)
    if LuckyAltManagerDB and LuckyAltManagerDB.devMode then
        print(PREFIX .. " |cff8a7e6a[" .. module .. "]|r " .. tostring(msg))
    end
end

--- Resolve a 3-way setting ("on", "off", "leveling") to a boolean.
function LuckyAltManager.IsFeatureActive(settingValue)
    if settingValue == "on" then return true end
    if settingValue == "leveling" then
        return UnitLevel("player") < LuckyAltManager.MAX_LEVEL
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
        if UnitLevel("player") >= LuckyAltManager.MAX_LEVEL then
            if LuckyAltManagerCharDB.specStats.shown == "leveling" then
                LuckyAltManager.SpecStats:SetShown("leveling")
            end
            if LuckyAltManagerDB.delversCall.shown == "leveling" then
                LuckyAltManager.DelversCall:SetShown("leveling")
            end
        end
        return
    end

    if event ~= "ADDON_LOADED" or addonName ~= ADDON_NAME then return end

    LuckyAltManagerDB = LuckyAltManagerDB or {}  ---@diagnostic disable-line: lowercase-global
    ApplyDefaults(LuckyAltManagerDB, DB_DEFAULTS)

    LuckyAltManagerCharDB = LuckyAltManagerCharDB or {}  ---@diagnostic disable-line: lowercase-global

    -- One-time migration: move the (previously global) stat-priority window
    -- settings into per-character storage so existing users keep their state.
    if LuckyAltManagerDB.specStats and not LuckyAltManagerCharDB._migratedSpecStats then
        LuckyAltManagerCharDB.specStats = {
            shown    = LuckyAltManagerDB.specStats.shown,
            framePos = LuckyAltManagerDB.specStats.framePos,
        }
        LuckyAltManagerCharDB._migratedSpecStats = true
        LuckyAltManagerDB.specStats = nil
    end

    ApplyDefaults(LuckyAltManagerCharDB, CHAR_DB_DEFAULTS)

    -- Migrate boolean -> tri-state for existing installs
    MigrateBoolToTriState(LuckyAltManagerCharDB.specStats, "shown")
    MigrateBoolToTriState(LuckyAltManagerDB.questRewardAdvisor, "shown")
    MigrateBoolToTriState(LuckyAltManagerDB.autoQuest, "enabled")
    MigrateBoolToTriState(LuckyAltManagerDB.skipCinematics, "enabled")
    MigrateBoolToTriState(LuckyAltManagerDB.delversCall, "shown")

    LuckyAltManager.StatWeightOverrides:Init(LuckyAltManagerDB)
    LuckyAltManager.DelversCall:Init(LuckyAltManagerDB.delversCall)
    LuckyAltManager.SpecStats:Init(LuckyAltManagerCharDB.specStats)
    LuckyAltManager.QuestRewardAdvisor:Init(LuckyAltManagerDB.questRewardAdvisor)
    LuckyAltManager.SkipCinematics:Init(LuckyAltManagerDB.skipCinematics)
    LuckyAltManager.AutoQuest:Init(LuckyAltManagerDB.autoQuest)
    LuckyAltManager.Settings:Init(LuckyAltManagerDB, LuckyAltManagerCharDB)

    LuckyMinimap:Create({
        name    = "LuckyAltManagerMinimapButton",
        icon    = "Interface\\Icons\\Achievement_Character_Human_Male",
        dbKey   = "minimap",
        db      = LuckyAltManagerDB,
        onClick = function(_, mouseBtn)
            if mouseBtn == "MiddleButton" then
                LuckyAltManagerDB.devMode = not LuckyAltManagerDB.devMode
                local state = LuckyAltManagerDB.devMode and "ON" or "OFF"
                print(PREFIX .. " Dev mode " .. state)
            else
                LuckySettings:Open(LuckyAltManager.Settings.category)
            end
        end,
        tooltip = function(tt)
            tt:AddLine(LuckyUI.WC.goldPrimary .. "Lucky's Alt Manager" .. LuckyUI.WC.reset)
            tt:AddLine(" ")
            tt:AddLine("Click: Open settings", 0.91, 0.86, 0.78)
            tt:AddLine("Middle-click: Toggle dev mode", 0.54, 0.49, 0.42)
            tt:AddLine("Shift+drag: Move button", 0.54, 0.49, 0.42)
        end,
    })

    self:UnregisterEvent("ADDON_LOADED")
    self:RegisterEvent("PLAYER_LEVEL_UP")
end)
