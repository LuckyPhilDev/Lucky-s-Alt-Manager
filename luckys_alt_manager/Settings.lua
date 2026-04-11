-- Settings
-- Registers Lucky's Alt Manager options in the WoW settings panel.

LuckyAltManager = LuckyAltManager or {}
LuckyAltManager.Settings = {}

local function AddFeatureToggle(content, prevAnchor, opts)
    local anchor = prevAnchor.desc or prevAnchor
    local leftInset = 16 + (opts.indent or 0)
    local check = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    check:SetPoint("LEFT", content, "LEFT", leftInset, 0)
    check:SetPoint("TOP", anchor, "BOTTOM", 0, -(opts.gap or 8))
    check:SetChecked(opts.checked)
    check.text:SetText(opts.label)
    check:SetScript("OnClick", function(btn)
        opts.onToggle(btn:GetChecked())
    end)

    if opts.tooltip then
        check:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(opts.label, 1, 1, 1)
            GameTooltip:AddLine(opts.tooltip, 0.7, 0.7, 0.7, true)
            GameTooltip:Show()
        end)
        check:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    local desc = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    desc:SetPoint("TOPLEFT", check, "BOTTOMLEFT", 26, -2)
    desc:SetWidth(400)
    desc:SetJustifyH("LEFT")
    desc:SetTextColor(0.54, 0.49, 0.42)
    desc:SetText(opts.desc)

    check.desc = desc
    return check
end

local function CreateScrollFrame(panel)
    local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", -26, 0)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetWidth(scrollFrame:GetWidth() or 500)
    scrollFrame:SetScrollChild(content)

    scrollFrame:HookScript("OnSizeChanged", function(self, width)
        content:SetWidth(width)
    end)

    return scrollFrame, content
end

local function UpdateContentHeight(content)
    local bottom = 0
    for _, child in pairs({ content:GetRegions() }) do
        local _, _, _, _, y = child:GetPoint()
        if y then
            local childBottom = -y + (child.GetHeight and child:GetHeight() or 0)
            if childBottom > bottom then bottom = childBottom end
        end
    end
    for _, child in pairs({ content:GetChildren() }) do
        local _, _, _, _, y = child:GetPoint()
        if y then
            local childBottom = -y + child:GetHeight()
            if childBottom > bottom then bottom = childBottom end
        end
    end
    content:SetHeight(bottom + 60)
end

function LuckyAltManager.Settings:Init(db)
    local panel = CreateFrame("Frame")
    panel.name = "Lucky's Alt Manager"

    local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    Settings.RegisterAddOnCategory(category)

    local _, content = CreateScrollFrame(panel)

    local title = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Lucky's Alt Manager")

    ---------------------------------------------------------------------------
    -- Delver's Call
    ---------------------------------------------------------------------------
    AddFeatureToggle(content, title, {
        label    = "Show Delver's Call Window",
        desc     = "Show the Delver's Call quest tracker window.",
        tooltip  = "Toggles the floating window that tracks weekly Delver's Call quest completions and XP potential.",
        checked  = db.delversCall.shown,
        gap      = 16,
        onToggle = function(checked)
            LuckyAltManager.DelversCall:SetShown(checked)
        end,
    })

    panel:HookScript("OnShow", function()
        UpdateContentHeight(content)
    end)
end
