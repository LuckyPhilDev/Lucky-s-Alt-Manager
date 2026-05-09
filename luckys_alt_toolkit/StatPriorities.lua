-- StatPriorities
-- Secondary stat priority table, keyed by specialization ID.
--
-- stats: ordered list from highest to lowest priority.
-- rels:  operator between each adjacent pair.
--   "="  = equal (interchangeable)
--   ">=" = marginally better (roughly equal)
--   ">"  = clearly better
--   ">>" = much better (significant gap, avoid the lower stat)

LuckyAltToolkit = LuckyAltToolkit or {}

LuckyAltToolkit.StatPriorities = {

    -- ── Death Knight ──────────────────────────────────────────────────────────
    [250] = {  -- Blood
        label = "Blood Death Knight",
        stats = { "Haste", "Crit", "Mastery", "Vers" },
        rels  = { ">=", ">=", "=" },
    },
    [251] = {  -- Frost
        label = "Frost Death Knight",
        stats = { "Crit", "Mastery", "Haste", "Vers" },
        rels  = { ">=", ">>", ">" },
    },
    [252] = {  -- Unholy
        label = "Unholy Death Knight",
        stats = { "Mastery", "Crit", "Haste", "Vers" },
        rels  = { ">=", ">>", ">>" },
    },

    -- ── Demon Hunter ──────────────────────────────────────────────────────────
    [577] = {  -- Havoc
        label = "Havoc Demon Hunter",
        stats = { "Crit", "Mastery", "Haste", "Vers" },
        rels  = { ">", ">>", ">" },
    },
    [581] = {  -- Vengeance
        label = "Vengeance Demon Hunter",
        stats = { "Haste", "Crit", "Vers", "Mastery" },
        rels  = { "=", "=", ">=" },
    },

    [1480] = {  -- Devourer
        label = "Devourer Demon Hunter",
        stats = { "Haste", "Mastery", "Crit", "Vers" },
        rels  = { ">=", ">>", ">>" },
    },

    -- ── Druid ─────────────────────────────────────────────────────────────────
    [102] = {  -- Balance
        label = "Balance Druid",
        stats = { "Mastery", "Crit", "Haste", "Vers" },
        rels  = { ">", "=", ">" },
    },
    [103] = {  -- Feral
        label = "Feral Druid",
        stats = { "Mastery", "Haste", "Crit", "Vers" },
        rels  = { ">", ">", ">" },
    },
    [104] = {  -- Guardian
        label = "Guardian Druid",
        stats = { "Haste", "Vers", "Crit", "Mastery" },
        rels  = { ">", ">", ">" },
    },
    [105] = {  -- Restoration
        label = "Restoration Druid",
        stats = { "Haste", "Mastery", "Vers", "Crit" },
        rels  = { "=", ">", ">>" },
    },

    -- ── Evoker ────────────────────────────────────────────────────────────────
    [1467] = {  -- Devastation
        label = "Devastation Evoker",
        stats = { "Crit", "Haste", "Mastery", "Vers" },
        rels  = { ">=", "=", ">" },
    },
    [1468] = {  -- Preservation
        label = "Preservation Evoker",
        stats = { "Mastery", "Crit", "Haste", "Vers" },
        rels  = { ">", "=", ">" },
    },
    [1473] = {  -- Augmentation
        label = "Augmentation Evoker",
        stats = { "Crit", "Haste", "Mastery", "Vers" },
        rels  = { ">", ">", ">" },
    },

    -- ── Hunter ────────────────────────────────────────────────────────────────
    [253] = {  -- Beast Mastery
        label = "Beast Mastery Hunter",
        stats = { "Mastery", "Haste", "Crit", "Vers" },
        rels  = { ">", ">", ">" },
    },
    [254] = {  -- Marksmanship
        label = "Marksmanship Hunter",
        stats = { "Crit", "Mastery", "Haste", "Vers" },
        rels  = { ">", ">", ">" },
    },
    [255] = {  -- Survival
        label = "Survival Hunter",
        stats = { "Mastery", "Crit", "Haste", "Vers" },
        rels  = { ">", ">", ">" },
    },

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

    -- ── Monk ──────────────────────────────────────────────────────────────────
    [268] = {  -- Brewmaster
        label = "Brewmaster Monk",
        stats = { "Crit", "Vers", "Mastery", "Haste" },
        rels  = { ">=", ">=", ">>" },
    },
    [270] = {  -- Mistweaver
        label = "Mistweaver Monk",
        stats = { "Haste", "Crit", "Vers", "Mastery" },
        rels  = { ">", ">", ">>" },
    },
    [269] = {  -- Windwalker
        label = "Windwalker Monk",
        stats = { "Haste", "Crit", "Mastery", "Vers" },
        rels  = { ">", ">=", ">>" },
    },

    -- ── Paladin ───────────────────────────────────────────────────────────────
    [65] = {  -- Holy
        label = "Holy Paladin",
        stats = { "Mastery", "Crit", "Haste", "Vers" },
        rels  = { ">", "=", ">" },
    },
    [66] = {  -- Protection
        label = "Protection Paladin",
        stats = { "Haste", "Vers", "Crit", "Mastery" },
        rels  = { "=", ">", ">" },
    },
    [70] = {  -- Retribution
        label = "Retribution Paladin",
        stats = { "Mastery", "Crit", "Haste", "Vers" },
        rels  = { ">", ">", ">" },
    },

    -- ── Priest ────────────────────────────────────────────────────────────────
    [256] = {  -- Discipline
        label = "Discipline Priest",
        stats = { "Haste", "Crit", "Mastery", "Vers" },
        rels  = { ">", ">", ">" },
    },
    [257] = {  -- Holy
        label = "Holy Priest",
        stats = { "Crit", "Vers", "Mastery", "Haste" },
        rels  = { ">", "=", ">" },
    },
    [258] = {  -- Shadow
        label = "Shadow Priest",
        stats = { "Haste", "Mastery", "Crit", "Vers" },
        rels  = { ">", ">", ">" },
    },

    -- ── Rogue ─────────────────────────────────────────────────────────────────
    [259] = {  -- Assassination
        label = "Assassination Rogue",
        stats = { "Crit", "Haste", "Mastery", "Vers" },
        rels  = { ">", ">", ">" },
    },
    [260] = {  -- Outlaw
        label = "Outlaw Rogue",
        stats = { "Haste", "Crit", "Vers", "Mastery" },
        rels  = { "=", ">", ">" },
    },
    [261] = {  -- Subtlety
        label = "Subtlety Rogue",
        stats = { "Mastery", "Haste", "Crit", "Vers" },
        rels  = { ">", ">=", ">" },
    },

    -- ── Shaman ────────────────────────────────────────────────────────────────
    [262] = {  -- Elemental
        label = "Elemental Shaman",
        stats = { "Mastery", "Haste", "Crit", "Vers" },
        rels  = { ">", "=", ">" },
    },
    [263] = {  -- Enhancement
        label = "Enhancement Shaman",
        stats = { "Mastery", "Haste", "Crit", "Vers" },
        rels  = { ">", ">", ">" },
    },
    [264] = {  -- Restoration
        label = "Restoration Shaman",
        stats = { "Crit", "Vers", "Mastery", "Haste" },
        rels  = { ">", "=", ">" },
    },

    -- ── Warlock ───────────────────────────────────────────────────────────────
    [265] = {  -- Affliction
        label = "Affliction Warlock",
        stats = { "Mastery", "Crit", "Haste", "Vers" },
        rels  = { ">", ">", ">" },
    },
    [266] = {  -- Demonology
        label = "Demonology Warlock",
        stats = { "Haste", "Crit", "Mastery", "Vers" },
        rels  = { "=", ">", ">" },
    },
    [267] = {  -- Destruction
        label = "Destruction Warlock",
        stats = { "Haste", "Mastery", "Crit", "Vers" },
        rels  = { ">", ">=", ">" },
    },

    -- ── Warrior ───────────────────────────────────────────────────────────────
    [71] = {  -- Arms
        label = "Arms Warrior",
        stats = { "Crit", "Haste", "Mastery", "Vers" },
        rels  = { ">", ">", ">" },
    },
    [72] = {  -- Fury
        label = "Fury Warrior",
        stats = { "Mastery", "Haste", "Crit", "Vers" },
        rels  = { ">", ">", ">" },
    },
    [73] = {  -- Protection
        label = "Protection Warrior",
        stats = { "Haste", "Crit", "Vers", "Mastery" },
        rels  = { ">", ">=", ">" },
    },

}
