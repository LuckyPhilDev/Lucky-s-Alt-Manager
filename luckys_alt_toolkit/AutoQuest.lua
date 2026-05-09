-- AutoQuest
-- Automatically accepts and hands in quests.
-- Skips quests with "Delver's Call:" in the title, quests with reward
-- choices, and any interaction while the Shift key is held.

LuckyAltToolkit = LuckyAltToolkit or {}
LuckyAltToolkit.AutoQuest = {}

local db

local function DevLog(msg)
    LuckyAltToolkit.DevLog("AutoQuest", msg)
end

local function IsExcluded()
    local title = GetTitleText()
    if title and title:find("Delver's Call:") then
        DevLog("Skipped (Delver's Call): " .. title)
        return true
    end
    return false
end

local frame = CreateFrame("Frame")

frame:SetScript("OnEvent", function(_, event)
    if not LuckyAltToolkit.IsFeatureActive(db.enabled) then return end
    if IsShiftKeyDown() then
        DevLog("Shift held — skipping " .. event)
        return
    end

    if event == "QUEST_DETAIL" then
        if IsExcluded() then return end
        DevLog("Auto-accepting: " .. (GetTitleText() or "?"))
        AcceptQuest()

    elseif event == "QUEST_PROGRESS" then
        if IsExcluded() then return end
        if not IsQuestCompletable() then return end
        DevLog("Auto-continuing: " .. (GetTitleText() or "?"))
        CompleteQuest()

    elseif event == "QUEST_COMPLETE" then
        if IsExcluded() then return end
        if GetNumQuestChoices() > 1 then
            DevLog("Has reward choices — skipping auto hand-in")
            return
        end
        DevLog("Auto-completing: " .. (GetTitleText() or "?"))
        GetQuestReward()
    end
end)

function LuckyAltToolkit.AutoQuest:Init(database)
    db = database
    frame:RegisterEvent("QUEST_DETAIL")
    frame:RegisterEvent("QUEST_PROGRESS")
    frame:RegisterEvent("QUEST_COMPLETE")
end

function LuckyAltToolkit.AutoQuest:SetEnabled(value)
    db.enabled = value
end
