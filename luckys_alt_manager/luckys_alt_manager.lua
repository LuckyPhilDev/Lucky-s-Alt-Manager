-- Lucky's Alt Manager
-- Entry point and initialization.

LuckyAltManager = LuckyAltManager or {}

local ADDON_NAME = "luckys_alt_manager"

local DB_DEFAULTS = {
    devMode = false,
    statWeightOverrides = {},
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
    autoQuest = {
        enabled = true,
    },
    minimap = {},
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

    LuckyAltManager.StatWeightOverrides:Init(LuckyAltManagerDB)
    LuckyAltManager.DelversCall:Init(LuckyAltManagerDB.delversCall)
    LuckyAltManager.SpecStats:Init(LuckyAltManagerDB.specStats)
    LuckyAltManager.QuestRewardAdvisor:Init(LuckyAltManagerDB.questRewardAdvisor)
    LuckyAltManager.SkipCinematics:Init(LuckyAltManagerDB.skipCinematics)
    LuckyAltManager.AutoQuest:Init(LuckyAltManagerDB.autoQuest)
    LuckyAltManager.Settings:Init(LuckyAltManagerDB)

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
end)
