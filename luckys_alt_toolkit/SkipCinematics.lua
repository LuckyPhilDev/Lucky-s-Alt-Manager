-- SkipCinematics
-- Automatically skips in-game cinematics and movies.

LuckyAltToolkit = LuckyAltToolkit or {}
LuckyAltToolkit.SkipCinematics = {}

local db

local function DevLog(msg)
    LuckyAltToolkit.DevLog("SkipCinematics", msg)
end

local frame = CreateFrame("Frame")

frame:SetScript("OnEvent", function(_, event, ...)
    if not LuckyAltToolkit.IsFeatureActive(db.enabled) then return end

    if event == "CINEMATIC_START" then
        DevLog("Cinematic started — skipping")
        CinematicFrame_CancelCinematic()
    elseif event == "PLAY_MOVIE" then
        local movieID = ...
        DevLog("Movie " .. tostring(movieID) .. " started — skipping")
        GameMovieFinished()
    end
end)

function LuckyAltToolkit.SkipCinematics:Init(database)
    db = database
    frame:RegisterEvent("CINEMATIC_START")
    frame:RegisterEvent("PLAY_MOVIE")
end

function LuckyAltToolkit.SkipCinematics:SetEnabled(value)
    db.enabled = value
end
