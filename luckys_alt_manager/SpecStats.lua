-- SpecStats
-- Displays a small floating window showing the secondary stat priority
-- for the player's current specialization.

LuckyAltManager = LuckyAltManager or {}
LuckyAltManager.SpecStats = {}

local FRAME_WIDTH  = 260
local FRAME_HEIGHT = 52

local db
local statsFrame

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function GetCurrentSpecID()
    local specIndex = GetSpecialization()
    if not specIndex then return nil end
    return (GetSpecializationInfo(specIndex))  -- first return value is specID
end

-- Builds a colored priority string, e.g.:
--   "Haste |cff8a7e6a>=|r Mastery |cffffd100>|r Vers |cffff6b6b>>|r Crit"
-- ">=" (marginal) is muted; ">" (clear) is gold; ">>" (large gap) is red.
local function BuildPriorityString(data)
    local parts = {}
    for i, stat in ipairs(data.stats) do
        parts[#parts + 1] = "|cffe8dcc8" .. stat .. "|r"
        local rel = data.rels[i]
        if rel then
            if rel == ">>" then
                parts[#parts + 1] = " |cffff6b6b" .. rel .. "|r "
            elseif rel == ">" then
                parts[#parts + 1] = " |cffffd100" .. rel .. "|r "
            elseif rel == ">=" then
                parts[#parts + 1] = " |cff8a7e6a" .. rel .. "|r "
            else  -- "="
                parts[#parts + 1] = " |cff4fc3f7" .. rel .. "|r "
            end
        end
    end
    return table.concat(parts)
end

-- Builds a weight display string for overridden specs, e.g.:
--   "Haste 1.10  Crit 0.95  Mastery 0.90  Vers 0.85"
local function BuildWeightString(weights)
    local sorted = {}
    for stat, w in pairs(weights) do
        sorted[#sorted + 1] = { stat = stat, weight = w }
    end
    table.sort(sorted, function(a, b) return a.weight > b.weight end)

    local parts = {}
    for _, entry in ipairs(sorted) do
        parts[#parts + 1] = string.format("|cffe8dcc8%s|r |cffffd100%.2f|r", entry.stat, entry.weight)
    end
    return table.concat(parts, "  ")
end

-- ── UI ────────────────────────────────────────────────────────────────────────

local function UpdateDisplay()
    if not statsFrame then return end

    local specID = GetCurrentSpecID()
    local data   = specID and LuckyAltManager.StatPriorities[specID]

    if not LuckyAltManager.IsFeatureActive(db.shown) or not data then
        statsFrame:Hide()
        return
    end

    local weights, hasOverrides = LuckyAltManager.GetStatWeights(specID)
    if hasOverrides and weights then
        statsFrame.specText:SetText("|cffffd100" .. data.label .. "|r |cff8a7e6a(Custom)|r")
        statsFrame.priorityText:SetText(BuildWeightString(weights))
    else
        statsFrame.specText:SetText("|cffffd100" .. data.label .. "|r")
        statsFrame.priorityText:SetText(BuildPriorityString(data))
    end
    statsFrame:Show()
end

local function BuildFrame()
    local f = CreateFrame("Frame", "LuckyAltManagerSpecStatsFrame", UIParent, "BackdropTemplate")
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
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 300)
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

    f:SetScript("OnEnter", function(self)
        self:SetAlpha(1)
        GameTooltip:SetOwner(self, "ANCHOR_NONE")
        GameTooltip:ClearAllPoints()
        GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -2)
        GameTooltip:AddLine("|cffffd100Stat Priority|r")
        GameTooltip:AddLine("|cff4fc3f7=|r   equal (interchangeable)", 1, 1, 1)
        GameTooltip:AddLine("|cff8a7e6a>=|r  marginally better", 1, 1, 1)
        GameTooltip:AddLine("|cffffd100>|r   clearly better", 1, 1, 1)
        GameTooltip:AddLine("|cffff6b6b>>|r  much better (significant gap)", 1, 1, 1)
        GameTooltip:Show()
    end)
    f:SetScript("OnLeave", function(self)
        self:SetAlpha(LuckyAltManagerDB.windowAlpha / 100)
        GameTooltip:Hide()
    end)

    f:SetAlpha(LuckyAltManagerDB.windowAlpha / 100)

    -- Close button
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetSize(18, 18)
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", 1, 1)
    closeBtn:SetScript("OnClick", function()
        db.shown = "off"
        f:Hide()
    end)

    -- Spec name
    local specText = f:CreateFontString(nil, "OVERLAY")
    specText:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    specText:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -8)
    f.specText = specText

    -- Separator
    local sep = f:CreateTexture(nil, "ARTWORK")
    sep:SetColorTexture(0.788, 0.659, 0.298, 0.25)
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT",  f, "TOPLEFT",  1, -22)
    sep:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -22)

    -- Priority string
    local priorityText = f:CreateFontString(nil, "OVERLAY")
    priorityText:SetFont("Fonts\\ARIALN.TTF", 11, "")
    priorityText:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -28)
    priorityText:SetWidth(FRAME_WIDTH - 20)
    f.priorityText = priorityText

    statsFrame = f
end

-- ── Public API ────────────────────────────────────────────────────────────────

function LuckyAltManager.SpecStats:Init(database)
    db = database

    BuildFrame()
    UpdateDisplay()

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_ENTERING_WORLD" then
            C_Timer.After(1, UpdateDisplay)
        else
            UpdateDisplay()
        end
    end)
end

function LuckyAltManager.SpecStats:SetShown(value)
    db.shown = value
    UpdateDisplay()
end

function LuckyAltManager.SpecStats:RefreshDisplay()
    UpdateDisplay()
end

function LuckyAltManager.SpecStats:ApplyAlpha()
    if statsFrame then
        statsFrame:SetAlpha(LuckyAltManagerDB.windowAlpha / 100)
    end
end
