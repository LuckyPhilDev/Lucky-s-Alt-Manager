-- Lucky's Alt Manager
-- Entry point and initialization.

LuckyAltManager = LuckyAltManager or {}

local ADDON_NAME = "luckys_alt_manager"

local DB_DEFAULTS = {
    devMode = false,
    delversCall = {
        devMode    = false,
        xpPerQuest = 0,
        shown      = true,
        framePos   = nil,
    },
    specStats = {
        shown    = true,
        framePos = nil,
    },
    questRewardAdvisor = {
        shown = true,
    },
    skipCinematics = {
        enabled = true,
    },
}

local PREFIX = "|cffc9a84cAlt Manager|r:"

function LuckyAltManager.DevLog(module, msg)
    if LuckyAltManagerDB and LuckyAltManagerDB.devMode then
        print(PREFIX .. " |cff8a7e6a[" .. module .. "]|r " .. tostring(msg))
    end
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

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, addonName)
    if event ~= "ADDON_LOADED" or addonName ~= ADDON_NAME then return end

    LuckyAltManagerDB = LuckyAltManagerDB or {}  ---@diagnostic disable-line: lowercase-global
    ApplyDefaults(LuckyAltManagerDB, DB_DEFAULTS)

    LuckyAltManager.DelversCall:Init(LuckyAltManagerDB.delversCall)
    LuckyAltManager.SpecStats:Init(LuckyAltManagerDB.specStats)
    LuckyAltManager.QuestRewardAdvisor:Init(LuckyAltManagerDB.questRewardAdvisor)
    LuckyAltManager.SkipCinematics:Init(LuckyAltManagerDB.skipCinematics)
    LuckyAltManager.Settings:Init(LuckyAltManagerDB)

    self:UnregisterEvent("ADDON_LOADED")
end)
