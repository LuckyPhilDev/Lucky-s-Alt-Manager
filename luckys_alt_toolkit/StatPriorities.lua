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

-- Primary stat per spec ("Agi" / "Str" / "Int").
-- Used to filter quest reward weapons that carry a primary stat the spec can't use.
LuckyAltToolkit.SpecPrimaryStat = {
    [250]="Str", [251]="Str", [252]="Str",       -- Death Knight
    [577]="Agi", [581]="Agi", [1480]="Agi",      -- Demon Hunter
    [102]="Int", [103]="Agi", [104]="Agi", [105]="Int",  -- Druid
    [1467]="Int", [1468]="Int", [1473]="Int",    -- Evoker
    [253]="Agi", [254]="Agi", [255]="Agi",       -- Hunter
    [62]="Int",  [63]="Int",  [64]="Int",        -- Mage
    [268]="Agi", [269]="Agi", [270]="Int",       -- Monk
    [65]="Int",  [66]="Str",  [70]="Str",        -- Paladin
    [256]="Int", [257]="Int", [258]="Int",       -- Priest
    [259]="Agi", [260]="Agi", [261]="Agi",       -- Rogue
    [262]="Int", [263]="Agi", [264]="Int",       -- Shaman
    [265]="Int", [266]="Int", [267]="Int",       -- Warlock
    [71]="Str",  [72]="Str",  [73]="Str",        -- Warrior
}

-- Weapon eligibility per spec. Flags:
--   twoH       - 2H weapons (INVTYPE_2HWEAPON)
--   oneH       - single 1H without dual wield (uses one MH slot)
--   dualWield  - dual wields 1H weapons
--   shield     - can equip a shield as off-hand
--   offhand    - can equip a caster off-hand frill (INVTYPE_HOLDABLE)
--   ranged    - bows / guns / crossbows (INVTYPE_RANGED / RANGEDRIGHT)
LuckyAltToolkit.SpecWeapons = {
    [250] = { twoH=true, dualWield=true },                  -- Blood DK
    [251] = { twoH=true, dualWield=true },                  -- Frost DK
    [252] = { twoH=true, dualWield=true },                  -- Unholy DK
    [577] = { dualWield=true },                             -- Havoc DH
    [581] = { dualWield=true },                             -- Vengeance DH
    [1480]= { dualWield=true },                             -- Devourer DH
    [102] = { twoH=true },                                  -- Balance Druid
    [103] = { twoH=true },                                  -- Feral
    [104] = { twoH=true },                                  -- Guardian
    [105] = { twoH=true },                                  -- Restoration Druid
    [1467]= { oneH=true, offhand=true, twoH=true },         -- Devastation Evoker
    [1468]= { oneH=true, offhand=true, twoH=true },         -- Preservation
    [1473]= { oneH=true, offhand=true, twoH=true },         -- Augmentation
    [253] = { ranged=true },                                -- BM Hunter
    [254] = { ranged=true },                                -- MM Hunter
    [255] = { twoH=true },                                  -- Survival Hunter
    [62]  = { oneH=true, offhand=true, twoH=true },         -- Arcane Mage
    [63]  = { oneH=true, offhand=true, twoH=true },         -- Fire Mage
    [64]  = { oneH=true, offhand=true, twoH=true },         -- Frost Mage
    [268] = { twoH=true },                                  -- Brewmaster Monk
    [269] = { twoH=true, dualWield=true },                  -- Windwalker
    [270] = { oneH=true, offhand=true, twoH=true },         -- Mistweaver
    [65]  = { oneH=true, shield=true, offhand=true },       -- Holy Paladin
    [66]  = { oneH=true, shield=true },                     -- Protection Paladin
    [70]  = { twoH=true },                                  -- Retribution
    [256] = { oneH=true, offhand=true, twoH=true },         -- Discipline
    [257] = { oneH=true, offhand=true, twoH=true },         -- Holy Priest
    [258] = { oneH=true, offhand=true, twoH=true },         -- Shadow
    [259] = { dualWield=true },                             -- Assassination
    [260] = { dualWield=true },                             -- Outlaw
    [261] = { dualWield=true },                             -- Subtlety
    [262] = { oneH=true, offhand=true, twoH=true },         -- Elemental
    [263] = { dualWield=true },                             -- Enhancement
    [264] = { oneH=true, shield=true, offhand=true },       -- Restoration Shaman
    [265] = { oneH=true, offhand=true, twoH=true },         -- Affliction
    [266] = { oneH=true, offhand=true, twoH=true },         -- Demonology
    [267] = { oneH=true, offhand=true, twoH=true },         -- Destruction
    [71]  = { twoH=true },                                  -- Arms
    [72]  = { twoH=true, dualWield=true },                  -- Fury (Titan's Grip)
    [73]  = { oneH=true, shield=true },                     -- Protection Warrior
}

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
