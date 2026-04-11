-- Settings
-- Registers Lucky's Alt Manager options in the WoW settings panel.

LuckyAltManager = LuckyAltManager or {}
LuckyAltManager.Settings = {}

function LuckyAltManager.Settings:Init(db)
    local panel = LuckySettings:NewPanel("Lucky's Alt Manager")

    panel:Toggle({
        label    = "Show Stat Priority Window",
        desc     = "Show a small floating window with your current spec's secondary stat priority.",
        tooltip  = "Displays stat priority for specs that have data. Hides automatically for unsupported specs.",
        checked  = db.specStats.shown,
        gap      = 16,
        onToggle = function(checked)
            LuckyAltManager.SpecStats:SetShown(checked)
        end,
    })

    panel:Section("Quest Rewards")

    panel:Toggle({
        label    = "Quest Reward Spec Hints",
        desc     = "Overlay spec icons on quest choice rewards to show which spec prefers each item.",
        tooltip  = "Only active while under max level. Icons appear based on secondary stat priority data. Hides automatically for specs or items with no relevant data.",
        checked  = db.questRewardAdvisor.shown,
        onToggle = function(checked)
            LuckyAltManager.QuestRewardAdvisor:SetShown(checked)
        end,
    })

    panel:Section("Delver's Call")

    panel:Toggle({
        label    = "Show Delver's Call Window",
        desc     = "Show the Delver's Call quest tracker window.",
        tooltip  = "Toggles the floating window that tracks weekly Delver's Call quest completions and XP potential.",
        checked  = db.delversCall.shown,
        onToggle = function(checked)
            LuckyAltManager.DelversCall:SetShown(checked)
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
