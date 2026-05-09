-- Delver's Call Tracker module
-- Shows incomplete quests, completion progress, and remaining XP potential.

LuckyAltToolkit = LuckyAltToolkit or {}
LuckyAltToolkit.DelversCall = {}

local QUEST_PREFIX     = "Delver's Call"
local TOTAL_QUESTS     = 10
local SHORT_NAME_START = #(QUEST_PREFIX .. ": ") + 1

local KNOWN_QUEST_IDS = {
    93372,  -- Shadow Enclave
    93384,  -- Collegiate Calamity
    93385,  -- The Darkway
    93386,  -- Parhelion Plaza
    93409,  -- Atal'Aman
    93410,  -- Twilight Crypts
    93416,  -- The Gulf of Memory
    93421,  -- The Grudge Pit
    93427,  -- Sunkiller Sanctum
    93428,  -- Shadowguard Point
}

local QUEST_SHORT_NAMES = {
    [93372] = "Shadow Enclave",
    [93384] = "Collegiate Calamity",
    [93385] = "The Darkway",
    [93386] = "Parhelion Plaza",
    [93409] = "Atal'Aman",
    [93410] = "Twilight Crypts",
    [93416] = "The Gulf of Memory",
    [93421] = "The Grudge Pit",
    [93427] = "Sunkiller Sanctum",
    [93428] = "Shadowguard Point",
}

local QUEST_ZONES = {
    [93372] = "Eversong Woods",
    [93384] = "Silvermoon City",
    [93385] = "Silvermoon City",
    [93386] = "Isle of Quel'Danas",
    [93409] = "Zul'Aman",
    [93410] = "Zul'Aman",
    [93416] = "Harandar",
    [93421] = "Harandar",
    [93427] = "Voidstorm",
    [93428] = "Voidstorm",
}

-- Layout
local FRAME_WIDTH  = 265
local TOP_H        = 64
local QUEST_ROW_H  = 14
local BOTTOM_H     = 28

local db
local trackerFrame

-- ── Utilities ────────────────────────────────────────────────────────────────

local function DevLog(msg)
    if db and db.devMode then
        print("|cffC9A84C[AltManager:Delvers]|r " .. tostring(msg))
    end
end

local function ToLevelPct(xp)
    local max = UnitXPMax("player")
    if not max or max == 0 then return 0 end
    return (xp / max) * 100
end

local function GetShortName(questID)
    local full = C_QuestLog.GetTitleForQuestID(questID)
    if full and #full >= SHORT_NAME_START then
        return full:sub(SHORT_NAME_START)
    end
    return QUEST_SHORT_NAMES[questID] or ("Quest " .. questID)
end

-- ── Quest data ────────────────────────────────────────────────────────────────

local function ScanQuestLog()
    local inLog = {}
    local numEntries = C_QuestLog.GetNumQuestLogEntries()
    for i = 1, numEntries do
        local info = C_QuestLog.GetInfo(i)
        if info and not info.isHeader and info.title then
            if info.title:sub(1, #QUEST_PREFIX) == QUEST_PREFIX then
                inLog[info.questID] = true
            end
        end
    end
    return inLog
end

local function CompletedCount()
    local n = 0
    for _, questID in ipairs(KNOWN_QUEST_IDS) do
        if C_QuestLog.IsQuestFlaggedCompleted(questID) then
            n = n + 1
        end
    end
    return n
end

local function ProbeQuestXP()
    if db.xpPerQuest > 0 then return end

    local inLog = ScanQuestLog()
    local probeID = nil
    for _, qid in ipairs(KNOWN_QUEST_IDS) do
        if inLog[qid] then probeID = qid; break end
    end
    if not probeID then probeID = KNOWN_QUEST_IDS[1] end

    local ok, val = pcall(C_QuestLog.GetQuestRewardXP, probeID)
    if ok and type(val) == "number" and val > 0 then
        db.xpPerQuest = val
        DevLog("xpPerQuest = " .. val)
    end
end

-- ── UI ───────────────────────────────────────────────────────────────────────

local function UpdateDisplay()
    if not trackerFrame then return end

    local inLog = ScanQuestLog()
    local done  = CompletedCount()

    trackerFrame.summaryText:SetText(
        string.format("Done: |cff69db7c%d|r / |cffc9a84c%d|r", done, TOTAL_QUESTS))

    local remaining = TOTAL_QUESTS - done
    if db.xpPerQuest > 0 then
        local earnedPct = ToLevelPct(done      * db.xpPerQuest)
        local availPct  = ToLevelPct(remaining * db.xpPerQuest)
        trackerFrame.xpText:SetText(string.format(
            "Earned: |cff69db7c%.1f%%|r   Avail: |cffffd100~%.1f%%|r",
            earnedPct, availPct))
    else
        trackerFrame.xpText:SetText(string.format(
            "|cff8a7e6aEarned: %d quest%s   Avail: %d quest%s|r",
            done,      done      == 1 and "" or "s",
            remaining, remaining == 1 and "" or "s"))
    end

    for i, questID in ipairs(KNOWN_QUEST_IDS) do
        local line = trackerFrame.questLines[i]
        local name = GetShortName(questID)
        local zone = QUEST_ZONES[questID] or ""
        local zoneSuffix = zone ~= "" and ("  |cff8a7e6a" .. zone .. "|r") or ""
        if C_QuestLog.IsQuestFlaggedCompleted(questID) then
            line:SetText("|cff69db7c+ " .. name .. "|r" .. zoneSuffix)
        elseif inLog[questID] then
            line:SetText("|cffffd100> " .. name .. "|r" .. zoneSuffix)
        else
            line:SetText("|cff8a7e6a- " .. name .. "  " .. zone .. "|r")
        end
        line:Show()
    end

    local fillPct   = done / TOTAL_QUESTS
    local fillWidth = math.max(1, math.floor(trackerFrame.barMaxWidth * fillPct))
    trackerFrame.barFill:SetWidth(fillWidth)

    trackerFrame:SetShown(LuckyAltToolkit.IsFeatureActive(db.shown))
end

local function BuildTrackerFrame()
    local f = CreateFrame("Frame", "LuckyAltToolkitDelversCallFrame", UIParent, "BackdropTemplate")
    local FRAME_HEIGHT = TOP_H + TOTAL_QUESTS * QUEST_ROW_H + BOTTOM_H
    f:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    f:SetFrameStrata("MEDIUM")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")

    if db.framePos then
        local p = db.framePos
        f:SetPoint(p.point, UIParent, p.relPoint, p.x, p.y)
    else
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
    end

    f:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets   = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    f:SetBackdropColor(0.102, 0.071, 0.035, 0.95)
    f:SetBackdropBorderColor(0.788, 0.659, 0.298, 1)

    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        db.framePos = { point = point, relPoint = relPoint, x = x, y = y }
    end)

    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    title:SetTextColor(1.0, 0.820, 0.0)
    title:SetText("Delver's Calls")
    title:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -8)

    f:SetScript("OnEnter", function(self)
        self:SetAlpha(1)
        GameTooltip:SetOwner(self, "ANCHOR_NONE")
        GameTooltip:ClearAllPoints()
        GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -2)
        GameTooltip:AddLine("|cffffd100Delver's Call Tracker|r")
        GameTooltip:AddLine("|cffaaaaaa/delvers|r  or  |cffaaaaaa/dct|r — toggle", 1, 1, 1)
        GameTooltip:AddLine("|cffaaaaaa/dct reset|r — clear saved XP/quest value", 1, 1, 1)
        GameTooltip:Show()
    end)
    f:SetScript("OnLeave", function(self)
        self:SetAlpha(LuckyAltToolkitDB.windowAlpha / 100)
        GameTooltip:Hide()
    end)

    f:SetAlpha(LuckyAltToolkitDB.windowAlpha / 100)

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetSize(18, 18)
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", 1, 1)
    closeBtn:SetScript("OnClick", function()
        db.shown = "off"
        f:Hide()
    end)

    local sep1 = f:CreateTexture(nil, "ARTWORK")
    sep1:SetColorTexture(0.788, 0.659, 0.298, 0.35)
    sep1:SetHeight(1)
    sep1:SetPoint("TOPLEFT",  f, "TOPLEFT",  1, -22)
    sep1:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -22)

    local summary = f:CreateFontString(nil, "OVERLAY")
    summary:SetFont("Fonts\\ARIALN.TTF", 11, "")
    summary:SetTextColor(0.910, 0.863, 0.784)
    summary:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -28)
    f.summaryText = summary

    local xpLine = f:CreateFontString(nil, "OVERLAY")
    xpLine:SetFont("Fonts\\ARIALN.TTF", 11, "")
    xpLine:SetTextColor(0.910, 0.863, 0.784)
    xpLine:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -43)
    f.xpText = xpLine

    local sep2 = f:CreateTexture(nil, "ARTWORK")
    sep2:SetColorTexture(0.229, 0.180, 0.102, 1)
    sep2:SetHeight(1)
    sep2:SetPoint("TOPLEFT",  f, "TOPLEFT",  1, -58)
    sep2:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -58)

    f.questLines = {}
    for i = 1, TOTAL_QUESTS do
        local t = f:CreateFontString(nil, "OVERLAY")
        t:SetFont("Fonts\\ARIALN.TTF", 11, "")
        t:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -(TOP_H + (i - 1) * QUEST_ROW_H))
        t:Hide()
        f.questLines[i] = t
    end

    local sep3 = f:CreateTexture(nil, "ARTWORK")
    sep3:SetColorTexture(0.229, 0.180, 0.102, 1)
    sep3:SetHeight(1)
    sep3:SetPoint("BOTTOMLEFT",  f, "BOTTOMLEFT",  1, BOTTOM_H - 1)
    sep3:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, BOTTOM_H - 1)

    local BAR_MARGIN = 10
    local BAR_WIDTH  = FRAME_WIDTH - BAR_MARGIN * 2
    local BAR_HEIGHT = 5

    local barBg = f:CreateTexture(nil, "BACKGROUND")
    barBg:SetColorTexture(0.20, 0.15, 0.07, 1)
    barBg:SetSize(BAR_WIDTH, BAR_HEIGHT)
    barBg:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", BAR_MARGIN, 9)

    local barFill = f:CreateTexture(nil, "ARTWORK")
    barFill:SetColorTexture(0.788, 0.659, 0.298, 1)
    barFill:SetHeight(BAR_HEIGHT)
    barFill:SetWidth(1)
    barFill:SetPoint("LEFT", barBg, "LEFT", 0, 0)

    f.barFill     = barFill
    f.barMaxWidth = BAR_WIDTH

    trackerFrame = f
end

local function RegisterSlash()
    SLASH_LUCKYALTDELVERS1 = "/delvers"
    SLASH_LUCKYALTDELVERS2 = "/dct"
    SlashCmdList["LUCKYALTDELVERS"] = function(input)
        local msg = strtrim((input or ""):lower())
        if msg == "debug" then
            db.devMode = not db.devMode
            print(string.format("|cffc9a84cDelver's Call Tracker:|r Debug %s",
                db.devMode and "|cff69db7con|r" or "|cffff6b6boff|r"))
        elseif msg == "reset" then
            db.xpPerQuest = 0
            print("|cffc9a84cDelver's Call Tracker:|r XP data cleared.")
            UpdateDisplay()
        else
            db.shown = (db.shown == "off") and "on" or "off"
            if LuckyAltToolkit.IsFeatureActive(db.shown) then
                trackerFrame:Show()
                UpdateDisplay()
            else
                trackerFrame:Hide()
            end
        end
    end
end

-- ── Public API ────────────────────────────────────────────────────────────────

function LuckyAltToolkit.DelversCall:Init(database)
    db = database

    BuildTrackerFrame()
    RegisterSlash()
    ProbeQuestXP()
    UpdateDisplay()

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:SetScript("OnEvent", function(_, event)
        if event == "QUEST_LOG_UPDATE" then
            ProbeQuestXP()
            UpdateDisplay()
        elseif event == "PLAYER_ENTERING_WORLD" then
            C_Timer.After(1, function() ProbeQuestXP(); UpdateDisplay() end)
            C_Timer.After(5, function() ProbeQuestXP(); UpdateDisplay() end)
        end
    end)

    DevLog("Loaded — xpPerQuest=" .. tostring(db.xpPerQuest))
end

function LuckyAltToolkit.DelversCall:ApplyAlpha()
    if trackerFrame then
        trackerFrame:SetAlpha(LuckyAltToolkitDB.windowAlpha / 100)
    end
end

function LuckyAltToolkit.DelversCall:SetShown(value)
    db.shown = value
    if trackerFrame then
        local active = LuckyAltToolkit.IsFeatureActive(value)
        trackerFrame:SetShown(active)
        if active then UpdateDisplay() end
    end
end
