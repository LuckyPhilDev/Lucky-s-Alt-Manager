-- QuestRewardAdvisor
-- When completing a quest under max level with multiple choice rewards,
-- overlays spec icons on each item indicating which spec(s) prefer it,
-- based on secondary stat priority data in StatPriorities.lua.

LuckyAltToolkit = LuckyAltToolkit or {}
LuckyAltToolkit.QuestRewardAdvisor = {}

local ICON_SIZE = 16

local STAT_KEY = {
    Crit    = "ITEM_MOD_CRIT_RATING_SHORT",
    Haste   = "ITEM_MOD_HASTE_RATING_SHORT",
    Mastery = "ITEM_MOD_MASTERY_RATING_SHORT",
    Vers    = "ITEM_MOD_VERSATILITY",
}

local PRIMARY_KEY = {
    Agi = "ITEM_MOD_AGILITY_SHORT",
    Str = "ITEM_MOD_STRENGTH_SHORT",
    Int = "ITEM_MOD_INTELLECT_SHORT",
}

-- Slot-bucket lookup. Items group into "mainHand" or "offHand" so a quest
-- offering both can highlight the best of each per spec.
-- Eligibility for a given equipLoc is decided by SLOT_RULE.
local SLOT_BUCKET = {
    INVTYPE_2HWEAPON       = "mainHand",
    INVTYPE_WEAPONMAINHAND = "mainHand",
    INVTYPE_RANGED         = "mainHand",
    INVTYPE_RANGEDRIGHT    = "mainHand",
    INVTYPE_WEAPON         = "mainHand",  -- generic 1H, treated as MH
    INVTYPE_WEAPONOFFHAND  = "offHand",
    INVTYPE_SHIELD         = "offHand",
    INVTYPE_HOLDABLE       = "offHand",
}

-- Slots where the primary-stat filter is meaningful. Armor slots are excluded
-- because modern adapting items report only the current spec's primary via
-- C_Item.GetItemStats, which would falsely filter out other specs.
local PRIMARY_FILTER_SLOTS = {
    INVTYPE_2HWEAPON       = true,
    INVTYPE_WEAPON         = true,
    INVTYPE_WEAPONMAINHAND = true,
    INVTYPE_WEAPONOFFHAND  = true,
    INVTYPE_RANGED         = true,
    INVTYPE_RANGEDRIGHT    = true,
    INVTYPE_HOLDABLE       = true,
}

-- Returns true if the spec's SpecWeapons flags allow this equipLoc.
local function CanEquip(equipLoc, rules)
    if not rules then return false end
    if equipLoc == "INVTYPE_2HWEAPON"       then return rules.twoH == true end
    if equipLoc == "INVTYPE_WEAPONMAINHAND" then return rules.oneH == true or rules.dualWield == true end
    if equipLoc == "INVTYPE_WEAPON"         then return rules.oneH == true or rules.dualWield == true end
    if equipLoc == "INVTYPE_WEAPONOFFHAND"  then return rules.dualWield == true end
    if equipLoc == "INVTYPE_SHIELD"         then return rules.shield == true end
    if equipLoc == "INVTYPE_HOLDABLE"       then return rules.offhand == true end
    if equipLoc == "INVTYPE_RANGED"         then return rules.ranged == true end
    if equipLoc == "INVTYPE_RANGEDRIGHT"    then return rules.ranged == true end
    return true  -- armor and accessories: no weapon-slot restriction
end

-- Returns "Agi" / "Str" / "Int" if the item carries exactly one primary stat.
-- Returns nil for items with no primary (rings, neck, trinkets, cloak, shields)
-- or for stat-adapting items that report multiple primaries.
local function GetItemPrimary(rawStats)
    local found
    for label, key in pairs(PRIMARY_KEY) do
        local v = rawStats[key]
        if v and v > 0 then
            if found then return nil end  -- multiple primaries: treat as adaptive
            found = label
        end
    end
    return found
end

local db
local overlays = {}

local function DevLog(msg)
    LuckyAltToolkit.DevLog("QuestRewardAdvisor", msg)
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
        local data = specID and LuckyAltToolkit.StatPriorities[specID]
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
    if not LuckyAltToolkit.IsFeatureActive(db.shown) then return end

    local numChoices = GetNumQuestChoices()
    if not numChoices or numChoices < 2 then return end

    local specIDs = GetRelevantSpecIDs()
    if #specIDs == 0 then return end

    -- Fetch raw stats and equipLoc for each choice item
    local items = {}
    for i = 1, numChoices do
        local link = GetQuestItemLink("choice", i)
        if link then
            local raw = C_Item.GetItemStats(link)
            if raw and next(raw) then
                local _, _, _, _, _, _, _, _, equipLoc = GetItemInfo(link)
                items[i] = {
                    stats    = raw,
                    equipLoc = equipLoc or "",
                    primary  = GetItemPrimary(raw),
                }
            end
        end
    end

    -- Log item stats
    for i = 1, numChoices do
        local item = items[i]
        if item then
            local parts = {}
            for statLabel, key in pairs(STAT_KEY) do
                local val = item.stats[key]
                if val and val > 0 then
                    table.insert(parts, statLabel .. "=" .. val)
                end
            end
            local secondaries = next(parts) and table.concat(parts, ", ") or "no secondary stats"
            DevLog(string.format("  Item %d [%s, primary=%s]: %s",
                i, item.equipLoc ~= "" and item.equipLoc or "?", item.primary or "none", secondaries))
        else
            DevLog("  Item " .. i .. ": no stats data")
        end
    end

    -- For each spec, bucket eligible items by mainHand / offHand (or other)
    -- and pick the best in each bucket. Items with no slot bucket (armor,
    -- accessories) compete in their own implicit bucket.
    local specBestItems = {}  -- specID -> { idx, idx, ... } (1-2 entries)
    for _, specID in ipairs(specIDs) do
        local specData    = LuckyAltToolkit.StatPriorities[specID]
        local weights     = LuckyAltToolkit.GetStatWeights(specID)
        local rules       = LuckyAltToolkit.SpecWeapons[specID]
        local primaryNeed = LuckyAltToolkit.SpecPrimaryStat[specID]

        -- bucket key -> { idx, score }
        local best = {}
        local logParts = {}

        for i = 1, numChoices do
            local item = items[i]
            if item then
                local primaryOK = (not PRIMARY_FILTER_SLOTS[item.equipLoc])
                                  or (item.primary == nil)
                                  or (item.primary == primaryNeed)
                local slotOK    = CanEquip(item.equipLoc, rules)
                if primaryOK and slotOK then
                    local bucket = SLOT_BUCKET[item.equipLoc] or "other"
                    local score  = ScoreItem(item.stats, weights)
                    table.insert(logParts, string.format("#%d[%s]=%.1f", i, bucket, score))
                    local cur = best[bucket]
                    if not cur or score > cur.score then
                        best[bucket] = { idx = i, score = score }
                    end
                else
                    local reason = (not primaryOK and "primary" or "") .. (not slotOK and "/slot" or "")
                    table.insert(logParts, string.format("#%d[skip:%s]", i, reason))
                end
            end
        end

        local picks = {}
        for _, entry in pairs(best) do
            table.insert(picks, entry.idx)
        end
        DevLog(string.format("  %s: %s -> picks=%s",
            specData.label,
            table.concat(logParts, ", "),
            #picks > 0 and table.concat(picks, ",") or "none"))

        if #picks > 0 then
            specBestItems[specID] = picks
        end
    end

    -- Invert: itemSpecMap[slotIndex] = { specID, ... }
    local itemSpecMap = {}
    for specID, idxList in pairs(specBestItems) do
        for _, idx in ipairs(idxList) do
            itemSpecMap[idx] = itemSpecMap[idx] or {}
            table.insert(itemSpecMap[idx], specID)
        end
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

function LuckyAltToolkit.QuestRewardAdvisor:Init(database)
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

function LuckyAltToolkit.QuestRewardAdvisor:SetShown(value)
    db.shown = value
    if not LuckyAltToolkit.IsFeatureActive(value) then ClearOverlays() end
end
