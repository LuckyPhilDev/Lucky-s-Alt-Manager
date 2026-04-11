-- StatPriorities
-- Secondary stat priority table, keyed by specialization ID.
--
-- stats: ordered list from highest to lowest priority.
-- rels:  operator between each adjacent pair.
--   "="  = equal (interchangeable)
--   ">=" = marginally better (roughly equal)
--   ">"  = clearly better
--   ">>" = much better (significant gap, avoid the lower stat)

LuckyAltManager = LuckyAltManager or {}

LuckyAltManager.StatPriorities = {

    -- ── Mage ──────────────────────────────────────────────────────────────────
    [62] = {  -- Arcane
        label = "Arcane Mage",
        stats = { "Mastery", "Haste", "Crit", "Vers" },
        rels  = { ">>", ">", "=" },
    },
    [63] = {  -- Fire
        label = "Fire Mage",
        stats = { "Haste", "Mastery", "Vers", "Crit" },
        rels  = { ">=", ">", ">>" },
    },
    [64] = {  -- Frost
        label = "Frost Mage",
        stats = { "Mastery", "Crit", "Haste", "Vers" },
        rels  = { ">=", ">", ">=" },
    },

}
