-- StatWeightOverrides
-- Per-spec stat weight customization dialog and shared weight computation.

LuckyAltToolkit = LuckyAltToolkit or {}
LuckyAltToolkit.StatWeightOverrides = {}

local STATS     = { "Crit", "Haste", "Mastery", "Vers" }
local SPEC_X    = 16
local STAT_X    = 152
local COL_WIDTH = 62
local EDIT_W    = 50
local EDIT_H    = 20
local ROW_H     = 26

local CLASS_SPECS = {
    { "Death Knight", { 250, 251, 252 } },
    { "Demon Hunter", { 577, 581, 1480 } },
    { "Druid",        { 102, 103, 104, 105 } },
    { "Evoker",       { 1467, 1468, 1473 } },
    { "Hunter",       { 253, 254, 255 } },
    { "Mage",         { 62, 63, 64 } },
    { "Monk",         { 268, 270, 269 } },
    { "Paladin",      { 65, 66, 70 } },
    { "Priest",       { 256, 257, 258 } },
    { "Rogue",        { 259, 260, 261 } },
    { "Shaman",       { 262, 263, 264 } },
    { "Warlock",      { 265, 266, 267 } },
    { "Warrior",      { 71, 72, 73 } },
}

local REL_PENALTY = {
    ["="]  = 0.00,
    [">="] = 0.05,
    [">"]  = 0.10,
    [">>"] = 0.15,
}

local db
local dialog
local editBoxes = {}

-- ── Weight computation ───────────────────────────────────────────────────────

local function ComputeDefaultWeights(specID)
    local data = LuckyAltToolkit.StatPriorities[specID]
    if not data then return nil end
    local weights = {}
    local w = 1.0
    for i, stat in ipairs(data.stats) do
        weights[stat] = w
        local rel = data.rels[i]
        if rel then
            w = math.max(0, w - (REL_PENALTY[rel] or 0))
        end
    end
    return weights
end

--- Returns effective stat weights for a spec, applying user overrides.
--- Second return value is true when overrides are active.
function LuckyAltToolkit.GetStatWeights(specID)
    if db then
        local overrides = db.statWeightOverrides and db.statWeightOverrides[specID]
        if overrides and next(overrides) then
            local defaults = ComputeDefaultWeights(specID)
            if not defaults then return nil, false end
            for stat, val in pairs(overrides) do
                defaults[stat] = val
            end
            return defaults, true
        end
    end
    return ComputeDefaultWeights(specID), false
end

--- Returns default computed weights (ignoring overrides).
function LuckyAltToolkit.GetDefaultStatWeights(specID)
    return ComputeDefaultWeights(specID)
end

-- ── Helpers ──────────────────────────────────────────────────────────────────

local function GetSpecShortName(specID, className)
    local data = LuckyAltToolkit.StatPriorities[specID]
    if not data then return tostring(specID) end
    local escaped = className:gsub("([%-%^%$%(%)%%%.%[%]%*%+%?])", "%%%1")
    return data.label:gsub("%s+" .. escaped .. "$", "")
end

local function SaveEditBoxValue(specID, stat, text)
    local val = tonumber(text)
    if val and val > 0 then
        db.statWeightOverrides[specID] = db.statWeightOverrides[specID] or {}
        db.statWeightOverrides[specID][stat] = val
    else
        if db.statWeightOverrides[specID] then
            db.statWeightOverrides[specID][stat] = nil
            if not next(db.statWeightOverrides[specID]) then
                db.statWeightOverrides[specID] = nil
            end
        end
    end
    if LuckyAltToolkit.SpecStats.RefreshDisplay then
        LuckyAltToolkit.SpecStats:RefreshDisplay()
    end
end

-- ── Dialog ───────────────────────────────────────────────────────────────────

local boxCounter = 0

local function CreateStatEditBox(parent, specID, stat, defaultWeight)
    boxCounter = boxCounter + 1
    local box = CreateFrame("EditBox", "LuckyAltMgrStatBox" .. boxCounter, parent, "InputBoxTemplate")
    box:SetSize(EDIT_W, EDIT_H)
    box:SetAutoFocus(false)
    box:SetMaxLetters(5)
    box:SetJustifyH("CENTER")
    box:SetTextInsets(2, 2, 0, 0)

    -- Placeholder (visible when box is empty)
    local ph = box:CreateFontString(nil, "ARTWORK")
    ph:SetFont(LuckyUI.BODY_FONT, 11)
    ph:SetTextColor(LuckyUI.C.textMuted[1], LuckyUI.C.textMuted[2], LuckyUI.C.textMuted[3])
    ph:SetPoint("CENTER")
    ph:SetText(string.format("%.2f", defaultWeight))
    box.placeholder = ph

    box:SetScript("OnTextChanged", function(self)
        ph:SetShown(self:GetText() == "")
    end)
    box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEditFocusLost", function(self)
        SaveEditBoxValue(specID, stat, self:GetText())
    end)

    return box
end

local function BuildDialog()
    local panel = LuckyUI.CreatePanel("LuckyAltMgrStatWeights", UIParent, 460, 520)
    panel:SetPoint("CENTER")
    panel:SetFrameStrata("DIALOG")
    LuckyUI.CreateHeader(panel, "Stat Weight Overrides")
    tinsert(UISpecialFrames, "LuckyAltMgrStatWeights")

    -- Column headers
    for i, stat in ipairs(STATS) do
        local hdr = panel:CreateFontString(nil, "OVERLAY")
        hdr:SetFont(LuckyUI.BODY_FONT, 11)
        hdr:SetTextColor(LuckyUI.C.goldAccent[1], LuckyUI.C.goldAccent[2], LuckyUI.C.goldAccent[3])
        hdr:SetPoint("TOPLEFT", panel, "TOPLEFT", STAT_X + (i - 1) * COL_WIDTH, -42)
        hdr:SetWidth(EDIT_W)
        hdr:SetJustifyH("CENTER")
        hdr:SetText(stat)
    end

    -- Scroll frame (Character Mount pattern)
    local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -58)
    scrollFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -30, 44)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetWidth(420)
    content:SetHeight(1500)
    scrollFrame:SetScrollChild(content)

    -- Spec rows grouped by class
    local y = 0

    for _, classInfo in ipairs(CLASS_SPECS) do
        local className, specIDs = classInfo[1], classInfo[2]

        -- Class heading
        local heading = content:CreateFontString(nil, "ARTWORK")
        heading:SetFont(LuckyUI.TITLE_FONT, 12)
        heading:SetTextColor(LuckyUI.C.goldPrimary[1], LuckyUI.C.goldPrimary[2], LuckyUI.C.goldPrimary[3])
        heading:SetPoint("TOPLEFT", content, "TOPLEFT", SPEC_X, -y)
        heading:SetText(className)

        local rule = content:CreateTexture(nil, "ARTWORK")
        rule:SetHeight(1)
        rule:SetPoint("LEFT", heading, "RIGHT", 8, 0)
        rule:SetPoint("RIGHT", content, "RIGHT", -8, 0)
        rule:SetColorTexture(LuckyUI.C.borderDark[1], LuckyUI.C.borderDark[2], LuckyUI.C.borderDark[3])

        y = y + 22

        for _, specID in ipairs(specIDs) do
            local data = LuckyAltToolkit.StatPriorities[specID]
            if data then
                local defaults = ComputeDefaultWeights(specID)

                local label = content:CreateFontString(nil, "OVERLAY")
                label:SetFont(LuckyUI.BODY_FONT, 11)
                label:SetTextColor(LuckyUI.C.textLight[1], LuckyUI.C.textLight[2], LuckyUI.C.textLight[3])
                label:SetPoint("TOPLEFT", content, "TOPLEFT", SPEC_X + 8, -(y + 3))
                label:SetText(GetSpecShortName(specID, className))

                editBoxes[specID] = {}
                for i, stat in ipairs(STATS) do
                    local box = CreateStatEditBox(content, specID, stat, defaults[stat] or 0)
                    box:SetPoint("TOPLEFT", content, "TOPLEFT",
                        STAT_X + (i - 1) * COL_WIDTH, -y)
                    editBoxes[specID][stat] = box
                end

                y = y + ROW_H
            end
        end

        y = y + 6
    end

    content:SetHeight(math.max(200, y + 20))

    -- Footer
    local resetBtn = LuckyUI.CreateButton(panel, "Reset All", 80, 26, "danger")
    resetBtn:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 16, 10)
    resetBtn:SetScript("OnClick", function()
        wipe(db.statWeightOverrides)
        for _, stats in pairs(editBoxes) do
            for _, box in pairs(stats) do
                box:SetText("")
                box.placeholder:Show()
            end
        end
        if LuckyAltToolkit.SpecStats.RefreshDisplay then
            LuckyAltToolkit.SpecStats:RefreshDisplay()
        end
    end)

    local closeBtn = LuckyUI.CreateButton(panel, "Close", 80, 26)
    closeBtn:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -16, 10)
    closeBtn:SetScript("OnClick", function() panel:Hide() end)

    dialog = panel
end

-- ── Public API ───────────────────────────────────────────────────────────────

function LuckyAltToolkit.StatWeightOverrides:Init(database)
    db = database
end

function LuckyAltToolkit.StatWeightOverrides:Open()
    if not dialog then
        BuildDialog()
    end

    -- Populate from saved overrides
    for specID, stats in pairs(editBoxes) do
        local overrides = db.statWeightOverrides and db.statWeightOverrides[specID]
        for stat, box in pairs(stats) do
            if overrides and overrides[stat] then
                box:SetText(string.format("%.2f", overrides[stat]))
            else
                box:SetText("")
            end
        end
    end

    dialog:Show()
end
