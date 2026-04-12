-- QuestRewardAdvisor
-- When completing a quest under max level with multiple choice rewards,
-- overlays spec icons on each item indicating which spec(s) prefer it,
-- based on secondary stat priority data in StatPriorities.lua.

LuckyAltManager = LuckyAltManager or {}
LuckyAltManager.QuestRewardAdvisor = {}

local ICON_SIZE = 16

local STAT_KEY = {
    Crit    = "ITEM_MOD_CRIT_RATING_SHORT",
    Haste   = "ITEM_MOD_HASTE_RATING_SHORT",
    Mastery = "ITEM_MOD_MASTERY_RATING_SHORT",
    Vers    = "ITEM_MOD_VERSATILITY",
}

local db
local overlays = {}

local function DevLog(msg)
    LuckyAltManager.DevLog("QuestRewardAdvisor", msg)
end

-- ── Scoring ───────────────────────────────────────────────────────────────────

local function ScoreItem(rawStats, weights)
    local score = 0
    for statLabel, key in pairs(STAT_KEY) do
        score = score + (rawStats[key] or 0) * (weights[statLabel] or 0)
    end
    return score
end

local function GetRelevantSpecIDs()
    local classID = select(3, UnitClass("player"))
    local numSpecs = C_SpecializationInfo.GetNumSpecializationsForClassID(classID)
    local result = {}
    for i = 1, numSpecs do
        local specID = GetSpecializationInfoForClassID(classID, i)
        local data = specID and LuckyAltManager.StatPriorities[specID]
        if data and data.stats then
            table.insert(result, specID)
        end
    end
    return result
end

-- ── Frame discovery ──────────────────────────────────────────────────────────

local function GetChoiceButtons(numChoices)
    -- DialogueUI
    local dui = _G.DUIQuestFrame
    if dui and dui:IsVisible() and dui.itemButtonPool and dui.itemButtonPool.GetObjectsByPredicate then
        local buttons = dui.itemButtonPool:GetObjectsByPredicate(function(obj)
            return obj.type == "choice" and obj:IsShown()
        end)
        if buttons and #buttons > 0 then
            -- Key by .index
            local map = {}
            for _, obj in ipairs(buttons) do
                map[obj.index] = obj
            end
            return map, true
        end
    end

    -- Standard UI
    local parent = QuestInfoRewardsFrame
    if parent and parent:IsVisible() then
        local map = {}
        for i = 1, numChoices do
            local frame = _G["QuestInfoRewardsFrameQuestInfoItem" .. i]
            if frame and frame:IsVisible() and frame.type == "choice" then
                map[i] = frame
            end
        end
        if next(map) then return map, false end
    end

    return nil, false
end

-- ── Overlays ──────────────────────────────────────────────────────────────────

local function ClearOverlays()
    for _, overlay in pairs(overlays) do
        overlay:Hide()
    end
end

local function GetOrCreateOverlay(i, parent)
    local f = overlays[i]
    if not f then
        f = CreateFrame("Frame", "LuckyAltQRAdvisorOverlay" .. i)
        f:SetSize(1, ICON_SIZE)
        f.icons = {}
        f:Hide()
        overlays[i] = f
    end

    f:SetParent(parent)
    f:SetFrameLevel(parent:GetFrameLevel() + 10)
    return f
end

local function ShowOverlay(slotIndex, itemFrame, specIDs, isDUI)
    local overlay = GetOrCreateOverlay(slotIndex, itemFrame)

    overlay:ClearAllPoints()
    if isDUI then
        overlay:SetPoint("TOPLEFT", itemFrame, "TOPLEFT", -6, 3)
    else
        overlay:SetPoint("BOTTOMLEFT", itemFrame, "BOTTOMLEFT", 2, 2)
    end
    overlay:SetWidth(#specIDs * (ICON_SIZE + 4) - 2)

    for i, specID in ipairs(specIDs) do
        local icon = overlay.icons[i]
        if not icon then
            -- Container for icon + border
            icon = CreateFrame("Frame", nil, overlay)
            icon:SetSize(ICON_SIZE + 2, ICON_SIZE + 2)

            -- Border (gold-accent)
            local border = icon:CreateTexture(nil, "BORDER")
            border:SetAllPoints()
            border:SetColorTexture(0.79, 0.66, 0.30, 1)  -- #c9a84c

            -- Icon texture inset by 1px
            local tex = icon:CreateTexture(nil, "ARTWORK")
            tex:SetPoint("TOPLEFT", 1, -1)
            tex:SetPoint("BOTTOMRIGHT", -1, 1)
            tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
            icon.tex = tex

            overlay.icons[i] = icon
        end
        local _, _, _, iconID = GetSpecializationInfoByID(specID)
        icon.tex:SetTexture(iconID)
        icon:SetPoint("LEFT", overlay, "LEFT", (i - 1) * (ICON_SIZE + 4), 0)
        icon:Show()
    end

    for i = #specIDs + 1, #overlay.icons do
        overlay.icons[i]:Hide()
    end

    overlay:Show()
end

-- ── Core logic ────────────────────────────────────────────────────────────────

local function AnnotateChoices()
    ClearOverlays()
    if not LuckyAltManager.IsFeatureActive(db.shown) then return end

    local numChoices = GetNumQuestChoices()
    if not numChoices or numChoices < 2 then return end

    local specIDs = GetRelevantSpecIDs()
    if #specIDs == 0 then return end

    -- Fetch raw stats for each choice item
    local itemStats = {}
    for i = 1, numChoices do
        local link = GetQuestItemLink("choice", i)
        if link then
            local raw = C_Item.GetItemStats(link)
            if raw and next(raw) then
                itemStats[i] = raw
            end
        end
    end

    -- Log item stats
    for i = 1, numChoices do
        if itemStats[i] then
            local parts = {}
            for statLabel, key in pairs(STAT_KEY) do
                local val = itemStats[i][key]
                if val and val > 0 then
                    table.insert(parts, statLabel .. "=" .. val)
                end
            end
            DevLog("  Item " .. i .. ": " .. (next(parts) and table.concat(parts, ", ") or "no secondary stats"))
        else
            DevLog("  Item " .. i .. ": no stats data")
        end
    end

    -- For each spec, score every item and pick the best
    local specBestItem = {}
    for _, specID in ipairs(specIDs) do
        local specData = LuckyAltManager.StatPriorities[specID]
        local weights = LuckyAltManager.GetStatWeights(specID)
        local bestIdx, bestScore = nil, 0
        local scoreParts = {}
        for i = 1, numChoices do
            if itemStats[i] then
                local score = ScoreItem(itemStats[i], weights)
                table.insert(scoreParts, string.format("#%d=%.1f", i, score))
                if score > bestScore then
                    bestScore = score
                    bestIdx   = i
                end
            end
        end
        DevLog("  " .. specData.label .. ": " .. table.concat(scoreParts, ", ") .. " -> best=#" .. tostring(bestIdx))
        if bestIdx then
            specBestItem[specID] = bestIdx
        end
    end

    -- Invert: itemSpecMap[slotIndex] = { specID, ... }
    local itemSpecMap = {}
    for specID, idx in pairs(specBestItem) do
        itemSpecMap[idx] = itemSpecMap[idx] or {}
        table.insert(itemSpecMap[idx], specID)
    end

    -- Find visible choice buttons
    local choiceButtons, isDUI = GetChoiceButtons(numChoices)
    if not choiceButtons then
        DevLog("No choice buttons found")
        return
    end

    -- Place overlays
    for i = 1, numChoices do
        if itemSpecMap[i] and choiceButtons[i] then
            ShowOverlay(i, choiceButtons[i], itemSpecMap[i], isDUI)
        end
    end
end

-- ── Public API ────────────────────────────────────────────────────────────────

function LuckyAltManager.QuestRewardAdvisor:Init(database)
    db = database

    if QuestInfo_ShowRewards then
        hooksecurefunc("QuestInfo_ShowRewards", function()
            C_Timer.After(0, AnnotateChoices)
        end)
    end

    local dui = _G.DUIQuestFrame
    if dui then
        dui:HookScript("OnHide", function()
            ClearOverlays()
        end)
    end

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("QUEST_COMPLETE")
    eventFrame:RegisterEvent("QUEST_FINISHED")
    eventFrame:SetScript("OnEvent", function(_, event)
        if event == "QUEST_COMPLETE" then
            C_Timer.After(0.2, AnnotateChoices)
        elseif event == "QUEST_FINISHED" then
            local dui = _G.DUIQuestFrame
            if dui and dui:IsVisible() then return end
            ClearOverlays()
        end
    end)
end

function LuckyAltManager.QuestRewardAdvisor:SetShown(value)
    db.shown = value
    if not LuckyAltManager.IsFeatureActive(value) then ClearOverlays() end
end
