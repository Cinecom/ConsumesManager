-- consumables.lua

consumablesCategories = {
    ["Elixirs"] = {
        { id = 13452, name = "Elixir of the Mongoose" },
        { id = 9187, name = "Elixir of Greater Agility" },
        { id = 13453, name = "Elixir of Brute Force" },
        { id = 13447, name = "Elixir of the Sages" },
        { id = 3825, name = "Elixir of Fortitude" },
        { id = 9179, name = "Elixir of Greater Intellect" },
        { id = 13454, name = "Greater Arcane Elixir" },
        { id = 17708, name = "Elixir of Frost Power" },
        { id = 9264, name = "Elixir of Shadow Power" },
        { id = 6373, name = "Elixir of Firepower" },
        { id = 21546, name = "Elixir of Greater Firepower" },
        { id = 18294, name = "Elixir of Greater Water Breathing" },
        { id = 9088, name = "Gift of Arthas" },
        { id = 9155, name = "Arcane Elixir" },
    },
    ["Protection Potions"] = {
        { id = 13457, name = "Greater Fire Protection Potion" },
        { id = 13456, name = "Greater Frost Protection Potion" },
        { id = 13458, name = "Greater Nature Protection Potion" },
        { id = 13459, name = "Greater Shadow Protection Potion" },
        { id = 13461, name = "Greater Arcane Protection Potion" },
        { id = 9036, name = "Magic Resistance Potion" },
    },
    ["Utility Potions"] = {
        { id = 20008, name = "Living Action Potion" },
        { id = 5634, name = "Free Action Potion" },
        { id = 3387, name = "Limited Invulnerability Potion" },
        { id = 9030, name = "Restorative Potion" },
        { id = 13462, name = "Purification Potion" },
        { id = 9172, name = "Invisibility Potion" },
        { id = 2459, name = "Swiftness Potion" },
    },
    ["Combat Potions"] = {
        { id = 13455, name = "Greater Stoneshield Potion" },
        { id = 13442, name = "Mighty Rage Potion" },
        { id = 5631, name = "Rage Potion" },
    },
    ["Mana & Health Potions"] = {
        { id = 13444, name = "Major Mana Potion" },
        { id = 13446, name = "Major Healing Potion" },
        { id = 12190, name = "Dreamless Sleep Potion" },
        { id = 2456, name = "Rejuvenation Potion" },
    },
    ["Juju & Other Buffs"] = {
        { id = 12460, name = "Juju Power" },
        { id = 12451, name = "Juju Might" },
        { id = 12457, name = "Juju Chill" },
        { id = 12455, name = "Juju Ember" },
        { id = 12450, name = "Juju Flurry" },
        { id = 8412, name = "Ground Scorpok Assay" },
        { id = 8410, name = "R.O.I.D.S." },
        { id = 8411, name = "Lung Juice Cocktail" },
        { id = 18284, name = "Kreeg's Stout Beatdown" },
        { id = 21151, name = "Rumsey Rum Black Label" },
        { id = 12820, name = "Winterfall Firewater" },
    },
    ["Food Buffs"] = {
        { id = 51711, name = "Sweet Mountain Berry (Agility)" },
        { id = 51714, name = "Sweet Mountain Berry (Stamina)" },
        { id = 12662, name = "Blasted Boar Lung" },
        { id = 21023, name = "Dirge's Kickin' Chimaerok Chops" },
        { id = 12210, name = "Tender Wolf Steak" },
        { id = 12217, name = "Dragonbreath Chili" },
        { id = 18254, name = "Runn Tum Tuber Surprise" },
        { id = 13931, name = "Nightfin Soup" },
        { id = 21217, name = "Sagefish Delight" },
        { id = 13928, name = "Grilled Squid" },
        { id = 20452, name = "Smoked Desert Dumplings" },
        { id = 12202, name = "Roast Raptor" },
    }
}

consumablesList = {}
consumablesNameToID = {}
for categoryName, consumables in pairs(consumablesCategories) do
    for _, consumable in ipairs(consumables) do
        consumablesList[consumable.id] = consumable.name
        consumablesNameToID[consumable.name] = consumable.id
    end
end



consumablesTextures = {
    -- Elixirs
    [13452] = "Interface\\Icons\\INV_Potion_32",  -- Elixir of the Mongoose
    [9187]  = "Interface\\Icons\\INV_Potion_94",  -- Elixir of Greater Agility
    [13453] = "Interface\\Icons\\INV_Potion_80",  -- Elixir of Brute Force
    [13447] = "Interface\\Icons\\INV_Potion_29",  -- Elixir of the Sages
    [3825]  = "Interface\\Icons\\INV_Potion_43",  -- Elixir of Fortitude
    [9179]  = "Interface\\Icons\\INV_Potion_10",  -- Elixir of Greater Intellect
    [13454] = "Interface\\Icons\\INV_Potion_22",  -- Greater Arcane Elixir
    [17708] = "Interface\\Icons\\INV_Potion_20",  -- Elixir of Frost Power
    [9264]  = "Interface\\Icons\\INV_Potion_48",  -- Elixir of Shadow Power
    [6373]  = "Interface\\Icons\\INV_Potion_38",  -- Elixir of Firepower
    [21546] = "Interface\\Icons\\INV_Potion_24",  -- Elixir of Greater Firepower
    [18294] = "Interface\\Icons\\INV_Potion_13",  -- Elixir of Greater Water Breathing
    [9088]  = "Interface\\Icons\\INV_Potion_16",  -- Gift of Arthas
    [9155]  = "Interface\\Icons\\INV_Potion_83",  -- Arcane Elixir

    -- Protection Potions
    [13457] = "Interface\\Icons\\INV_Potion_24",  -- Greater Fire Protection Potion
    [13456] = "Interface\\Icons\\INV_Potion_20",  -- Greater Frost Protection Potion
    [13458] = "Interface\\Icons\\INV_Potion_22",  -- Greater Nature Protection Potion
    [13459] = "Interface\\Icons\\INV_Potion_23",  -- Greater Shadow Protection Potion
    [13461] = "Interface\\Icons\\INV_Potion_25",  -- Greater Arcane Protection Potion
    [9036]  = "Interface\\Icons\\INV_Potion_81",  -- Magic Resistance Potion

    -- Utility Potions
    [20008] = "Interface\\Icons\\INV_Potion_16",  -- Living Action Potion
    [5634]  = "Interface\\Icons\\INV_Potion_04",  -- Free Action Potion
    [3387]  = "Interface\\Icons\\INV_Potion_62",  -- Limited Invulnerability Potion
    [9030]  = "Interface\\Icons\\INV_Potion_68",  -- Restorative Potion
    [13462] = "Interface\\Icons\\INV_Potion_27",  -- Purification Potion
    [9172]  = "Interface\\Icons\\INV_Potion_31",  -- Invisibility Potion
    [2459]  = "Interface\\Icons\\INV_Potion_95",  -- Swiftness Potion

    -- Combat Potions
    [13455] = "Interface\\Icons\\INV_Potion_67",  -- Greater Stoneshield Potion
    [13442] = "Interface\\Icons\\INV_Potion_41",  -- Mighty Rage Potion
    [5631]  = "Interface\\Icons\\INV_Potion_24",  -- Rage Potion

    -- Mana & Health Potions
    [13444] = "Interface\\Icons\\INV_Potion_76",  -- Major Mana Potion
    [13446] = "Interface\\Icons\\INV_Potion_54",  -- Major Healing Potion
    [12190] = "Interface\\Icons\\INV_Potion_83",  -- Dreamless Sleep Potion
    [2456]  = "Interface\\Icons\\INV_Potion_01",  -- Minor Rejuvenation Potion

    -- Juju & Other Buffs
    [12460] = "Interface\\Icons\\INV_Misc_MonsterScales_07",  -- Juju Power
    [12451] = "Interface\\Icons\\INV_Misc_MonsterScales_11",  -- Juju Might
    [12457] = "Interface\\Icons\\INV_Misc_MonsterScales_09",  -- Juju Chill
    [12455] = "Interface\\Icons\\INV_Misc_MonsterScales_15",  -- Juju Ember
    [12450] = "Interface\\Icons\\INV_Misc_MonsterScales_17",  -- Juju Flurry
    [8412]  = "Interface\\Icons\\INV_Misc_Food_54",  -- Ground Scorpok Assay
    [8410]  = "Interface\\Icons\\INV_Misc_Food_54",  -- R.O.I.D.S.
    [8411]  = "Interface\\Icons\\INV_Drink_17",      -- Lung Juice Cocktail
    [18284] = "Interface\\Icons\\INV_Drink_05",      -- Kreeg's Stout Beatdown
    [21151] = "Interface\\Icons\\INV_Drink_04",      -- Rumsey Rum Black Label
    [12820] = "Interface\\Icons\\INV_Misc_Powder_Mana",  -- Winterfall Firewater

    -- Food Buffs
    [12662] = "Interface\\Icons\\INV_Misc_Organ_03",   -- Demonic Rune (Assuming for Blasted Boar Lung)
    [21023] = "Interface\\Icons\\INV_Misc_Food_47",    -- Dirge's Kickin' Chimaerok Chops
    [12210] = "Interface\\Icons\\INV_Misc_Food_47",    -- Roast Raptor
    [12217] = "Interface\\Icons\\INV_Misc_Food_41",    -- Dragonbreath Chili
    [18254] = "Interface\\Icons\\INV_Misc_Food_64",    -- Runn Tum Tuber Surprise
    [13931] = "Interface\\Icons\\INV_Misc_Food_47",    -- Nightfin Soup
    [21217] = "Interface\\Icons\\INV_Misc_Food_64",    -- Sagefish Delight
    [13928] = "Interface\\Icons\\INV_Misc_Food_51",    -- Grilled Squid
    [20452] = "Interface\\Icons\\INV_Misc_Food_62",    -- Smoked Desert Dumplings
    [12202] = "Interface\\Icons\\INV_Misc_Food_14",    -- Tiger Meat (Assuming for Roast Raptor)
}


