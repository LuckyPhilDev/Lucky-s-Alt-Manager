-- SkipCinematics
-- Automatically skips in-game cinematics and movies.

LuckyAltManager = LuckyAltManager or {}
LuckyAltManager.SkipCinematics = {}

local db

local function DevLog(msg)
    LuckyAltManager.DevLog("SkipCinematics", msg)
end

local frame = CreateFrame("Frame")

frame:SetScript("OnEvent", function(_, event, ...)
    if not LuckyAltManager.IsFeatureActive(db.enabled) then return end

    if event == "CINEMATIC_START" then
        DevLog("Cinematic started — skipping")
        CinematicFrame_CancelCinematic()
    elseif event == "PLAY_MOVIE" then
        local movieID = ...
        DevLog("Movie " .. tostring(movieID) .. " started — skipping")
        GameMovieFinished()
    end
end)

function LuckyAltManager.SkipCinematics:Init(database)
    db = database
    frame:RegisterEvent("CINEMATIC_START")
    frame:RegisterEvent("PLAY_MOVIE")
end

function LuckyAltManager.SkipCinematics:SetEnabled(value)
    db.enabled = value
end
