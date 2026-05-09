-- Settings
-- Registers Lucky's Alt Toolkit options in the WoW settings panel.

LuckyAltToolkit = LuckyAltToolkit or {}
LuckyAltToolkit.Settings = {}

local TRI_CHOICES = {
    { value = "on",       label = "On" },
    { value = "off",      label = "Off" },
    { value = "leveling", label = "While Leveling" },
}

function LuckyAltToolkit.Settings:Init(db, charDB)
    local panel = LuckySettings:NewPanel("Lucky's Alt Toolkit")
    self.category = panel.category

    panel:Section("Windows")

    panel:Slider({
        label     = "Inactive Window Opacity",
        desc      = "How visible the floating windows are when your cursor is not over them.",
        key       = "AltMgrWindowAlpha",
        min       = 0,
        max       = 100,
        value     = db.windowAlpha,
        suffix    = "%",
        onChanged = function(val)
            db.windowAlpha = val
            LuckyAltToolkit.SpecStats:ApplyAlpha()
            LuckyAltToolkit.DelversCall:ApplyAlpha()
        end,
    })

    panel:Selector({
        label    = "Show Stat Priority Window |cff8a7e6a(per character)|r",
        desc     = "Show a small floating window with your current spec's secondary stat priority. This setting is saved per character.",
        tooltip  = "Displays stat priority for specs that have data. Hides automatically for unsupported specs.",
        value    = charDB.specStats.shown,
        choices  = TRI_CHOICES,
        gap      = 16,
        onChange = function(val)
            charDB.specStats.shown = val
            LuckyAltToolkit.SpecStats:SetShown(val)
        end,
    })

    -- Stat weight override button (positioned below the selector's description)
    local anchor = panel.lastAnchor.desc or panel.lastAnchor
    local overrideBtn = LuckyUI.CreateButton(panel.content, "Customise Stat Weights", 160, 24)
    overrideBtn:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -6)
    overrideBtn:SetScript("OnClick", function()
        LuckyAltToolkit.StatWeightOverrides:Open()
    end)

    local note = panel.content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    note:SetTextColor(0.54, 0.49, 0.42)
    note:SetJustifyH("LEFT")
    note:SetJustifyV("TOP")
    note:SetPoint("TOPLEFT", overrideBtn, "TOPRIGHT", 12, 0)
    note:SetPoint("RIGHT", panel.content, "RIGHT", -16, 0)
    note:SetWordWrap(true)
    note:SetText("Stat weights derived from Wowhead on 19 April 2026. Override them here if they're out of date or you're playing a different build.")

    panel.lastAnchor = overrideBtn

    panel:Section("Quest Rewards")

    panel:Selector({
        label    = "Quest Reward Spec Hints",
        desc     = "Overlay spec icons on quest choice rewards to show which spec prefers each item.",
        tooltip  = "Icons appear based on secondary stat priority data. Hides automatically for specs or items with no relevant data.",
        value    = db.questRewardAdvisor.shown,
        choices  = TRI_CHOICES,
        onChange = function(val)
            db.questRewardAdvisor.shown = val
            LuckyAltToolkit.QuestRewardAdvisor:SetShown(val)
        end,
    })

    panel:Section("Quests")

    panel:Selector({
        label    = "Auto Accept & Hand In Quests",
        desc     = "Automatically accept and hand in quests. Hold Shift to pause.",
        tooltip  = "Skips Delver's Call quests and quests with a reward choice. Hold Shift while interacting with an NPC to temporarily disable.",
        value    = db.autoQuest.enabled,
        choices  = TRI_CHOICES,
        onChange = function(val)
            db.autoQuest.enabled = val
        end,
    })

    panel:Section("Cinematics")

    panel:Selector({
        label    = "Skip Cinematics",
        desc     = "Automatically skip in-game cinematics and movies.",
        value    = db.skipCinematics.enabled,
        choices  = TRI_CHOICES,
        onChange = function(val)
            db.skipCinematics.enabled = val
        end,
    })

    panel:Section("Delver's Call")

    panel:Selector({
        label    = "Show Delver's Call Window",
        desc     = "Show the Delver's Call quest tracker window.",
        tooltip  = "Toggles the floating window that tracks weekly Delver's Call quest completions and XP potential.",
        value    = db.delversCall.shown,
        choices  = TRI_CHOICES,
        onChange = function(val)
            db.delversCall.shown = val
            LuckyAltToolkit.DelversCall:SetShown(val)
        end,
    })

    panel:Section("Developer")

    panel:Toggle({
        label    = "Dev Mode",
        desc     = "Print debug messages to chat.",
        checked  = db.devMode,
        onToggle = function(checked)
            db.devMode = checked
        end,
    })
end
