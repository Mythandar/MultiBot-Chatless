if not MultiBot then return end

local T = MultiBot.TeleportBrowser or {}
MultiBot.TeleportBrowser = T

local VISIBLE_ROWS, PAGE_SIZE = 18, 18
local VIEW_W, VIEW_H = 610, 405

local CONTINENTS = {
    world = { key = "world", label = "World", uiIndex = 0, art = "World" },
    ek = { key = "ek", label = "Eastern Kingdoms", mapId = 0, uiIndex = 2, art = "Azeroth", bounds = { -15973.34375, 11176.34375, -18171.970703125, 22569.2109375 } },
    kalimdor = { key = "kalimdor", label = "Kalimdor", mapId = 1, uiIndex = 1, art = "Kalimdor", bounds = { -11733.2998046875, 12799.900390625, -17066.599609375, 19733.2109375 } },
    outland = { key = "outland", label = "Outland", mapId = 530, uiIndex = 3, art = "Expansion01", bounds = { -5821.359375, 5821.359375, -12996.0390625, 4468.0390625 } },
    northrend = { key = "northrend", label = "Northrend", mapId = 571, uiIndex = 4, art = "Northrend", bounds = { -1240.8900146484375, 10593.375, -9217.15234375, 8534.24609375 } },
}

-- Curated faction settlements are hidden from characters of the opposing
-- faction. Neutral destinations and broad zone teleports remain available to
-- both factions. Keep this keyed by the AzerothCore game_tele name so the same
-- rule also applies when a known destination is returned by server search.
local FACTION_TELEPORTS = {
    -- Eastern Kingdoms
    Stormwind = "Alliance", Ironforge = "Alliance", Goldshire = "Alliance", EastvaleLoggingCamp = "Alliance", WestbrookGarrison = "Alliance",
    SentinelHill = "Alliance", Lakeshire = "Alliance", Darkshire = "Alliance", RavenHill = "Alliance", RebelCamp = "Alliance",
    Kharanos = "Alliance", Anvilmar = "Alliance", Thelsamar = "Alliance", MenethilHarbor = "Alliance", RefugePointe = "Alliance",
    AeriePeak = "Alliance", ChillwindCamp = "Alliance", Southshore = "Alliance", MorgansVigil = "Alliance", NethergardeKeep = "Alliance", TheHarborage = "Alliance",
    Undercity = "Horde", SilvermoonCity = "Horde", SunstriderIsle = "Horde", FalconwingSquare = "Horde", FairbreezeVillage = "Horde",
    FarstriderRetreat = "Horde", farstriderEnclave = "Horde", Tranquillien = "Horde", Deathknell = "Horde", Brill = "Horde",
    TheBulwark = "Horde", TheSepulcher = "Horde", TarrenMill = "Horde", GromgolBaseCamp = "Horde", Hammerfall = "Horde",
    RevantuskVillage = "Horde", Kargath = "Horde", FlameCrest = "Horde", Stonard = "Horde",

    -- Kalimdor
    Darnassus = "Alliance", TheExodar = "Alliance", Dolanaar = "Alliance", Auberdine = "Alliance", AzureWatch = "Alliance",
    BloodWatch = "Alliance", TalonbranchGlade = "Alliance", Astranaar = "Alliance", ForestSong = "Alliance", SilverwindRefuge = "Alliance",
    TalrendisPoint = "Alliance", StonetalonPeak = "Alliance", NijelsPoint = "Alliance", Theramore = "Alliance",
    FeathermoonStronghold = "Alliance", Thalanaar = "Alliance",
    Orgrimmar = "Horde", ThunderBluff = "Horde", ValleyOfTrials = "Horde", RazorHill = "Horde", SenjinVillage = "Horde",
    TheCrossroads = "Horde", CampTaurajo = "Horde", BloodhoofVillage = "Horde", CampNarache = "Horde", SplintertreePost = "Horde",
    ZoramgarOutpost = "Horde", Valormok = "Horde", BloodvenomPost = "Horde", SunRockRetreat = "Horde",
    ShadowpreyVillage = "Horde", BrackenwallVillage = "Horde", CampMojache = "Horde", FreewindPost = "Horde",

    -- Outland
    HonorHold = "Alliance", TempleOfTelhamat = "Alliance", Telredor = "Alliance", OreborHarborage = "Alliance",
    AllerianStronghold = "Alliance", Telaar = "Alliance", Sylvanaar = "Alliance", ToshleysStation = "Alliance", WildhammerStronghold = "Alliance",
    Thrallmar = "Horde", FalconWatch = "Horde", Zabrajin = "Horde", SwampratPost = "Horde", StonebreakerHold = "Horde",
    Garadar = "Horde", ThunderlordStronghold = "Horde", MokNathalVillage = "Horde", ShadowmoonVillage = "Horde",

    -- Northrend
    ValianceKeep = "Alliance", FizzcrankAirstrip = "Alliance", Valgarde = "Alliance", WestguardKeep = "Alliance", FortWildervar = "Alliance",
    StarsRest = "Alliance", WintergardeKeep = "Alliance", AmberpineLodge = "Alliance", WestfallBrigadeEncampment = "Alliance",
    Frosthold = "Alliance", TheSilverEnclave = "Alliance",
    WarsongHold = "Horde", BorgorokOutpost = "Horde", VengeanceLanding = "Horde", NewAgamand = "Horde", CampWinterhoof = "Horde",
    ApothecaryCamp = "Horde", AgmarsHammer = "Horde", Venomspite = "Horde", ConquestHold = "Horde", CampOneqwah = "Horde",
    WindrunnersOverlook = "Alliance", CampTunkalo = "Horde", SunreaversCommand = "Horde", SunreaversSanctuary = "Horde",
}

local CAPITALS = {
    { "Stormwind", "Stormwind", "ek", -8833, 629 }, { "Ironforge", "Ironforge", "ek", -4919, -940 },
    { "Undercity", "Undercity", "ek", 1584, 240 }, { "Silvermoon City", "SilvermoonCity", "ek", 9488, -7279 },
    { "Darnassus", "Darnassus", "kalimdor", 9950, 2284 }, { "The Exodar", "TheExodar", "kalimdor", -3966, -11654 },
    { "Orgrimmar", "Orgrimmar", "kalimdor", 1630, -4374 }, { "Thunder Bluff", "ThunderBluff", "kalimdor", -1277, 125 },
    { "Shattrath", "Shattrath", "outland", -1838, 5302 }, { "Dalaran", "Dalaran", "northrend", 5808, 588 },
}

local HUBS = {
    ek = {
        { "Aerie Peak", "AeriePeak", 260, -2125 }, { "Chillwind Camp", "ChillwindCamp", 968, -1444 },
        { "Menethil Harbor", "MenethilHarbor", -3769, -744 }, { "Thelsamar", "Thelsamar", -5353, -2949 },
        { "Sentinel Hill", "SentinelHill", -10624, 1097 }, { "Lakeshire", "Lakeshire", -9267, -2189 },
        { "Darkshire", "Darkshire", -10573, -1183 }, { "Booty Bay", "BootyBay", -14297, 531 },
    },
    kalimdor = {
        { "Auberdine", "Auberdine", 6501, 482 }, { "Astranaar", "Astranaar", 2676, -423 },
        { "Ratchet", "Ratchet", -957, -3755 }, { "Gadgetzan", "Gadgetzan", -7177, -3785 },
        { "Cenarion Hold", "CenarionHold", -6818, 734 },
    },
    outland = {
        { "Honor Hold", "HonorHold", -748, 2682 }, { "Thrallmar", "Thrallmar", 156, 2673 },
        { "Cenarion Refuge", "CenarionRefuge", -224, 5488 }, { "Area 52", "Area52", 3043, 3681 },
        { "Wildhammer Stronghold", "WildhammerStronghold", -3989, 2168 }, { "Shadowmoon Village", "ShadowmoonVillage", -2999, 2569 },
    },
    northrend = {
        { "Valiance Keep", "ValianceKeep", 2214, 5273 }, { "Warsong Hold", "WarsongHold", 2741, 6097 },
        { "Wyrmrest Temple", "WyrmrestTemple", 3556, 265 }, { "Argent Tournament", "ArgentTournament", 8516, 629 },
    },
}

local ZONE_VIEWS = {
    ["Eversong Woods"] = { continent = "ek", overlay = "EversongWoods", bounds = { 7758.333, 11041.666, 4487.5, 9412.5 }, overview = false, destinations = { { "Eversong Woods", "EversongWoods", 9079.92, -7193.23 }, { "Fairbreeze Village", "FairbreezeVillage", 8714.14, -6650.33 } } },
    ["Ghostlands"] = { continent = "ek", overlay = "Ghostlands", bounds = { 6066.666, 8266.666, 5283.333, 8583.333 }, overview = false, destinations = { { "Ghostlands", "Ghostlands", 7360.86, -6803.3 }, { "Tranquillien", "Tranquillien", 7564.25, -6872.23 } } },
    ["Tirisfal Glades"] = { continent = "ek", mapName = "Tirisfal Glades", overlay = "Tirisfal", bounds = { 825, 3837.5, -3033.333, 1485.416 }, destinations = { { "Tirisfal Glades", "TirisfalGlades", 2036.02, 161.331 }, { "Brill", "Brill", 2259.25, 290.43 } } },
    ["Silverpine Forest"] = { continent = "ek", overlay = "Silverpine", bounds = { -1133.333, 1666.666, -3450, 750 }, destinations = { { "Silverpine Forest", "SilverpineForest", 878.74, 1359.33 }, { "The Sepulcher", "TheSepulcher", 504.534, 1539.08 } } },
    ["Hillsbrad Foothills"] = { continent = "ek", mapName = "Hillsbrad Foothills", overlay = "Hilsbrad", bounds = { -1733.333, 400, -1066.666, 2133.333 }, destinations = { { "Hillsbrad Foothills", "HillsbradFoothills", -436.657, -581.254 }, { "Southshore", "Southshore", -853.221, -533.529 }, { "Tarren Mill", "TarrenMill", -34.1467, -923.366 } } },
    ["Alterac Mountains"] = { continent = "ek", overlay = "Alterac", bounds = { -366.666, 1500, -783.333, 2016.666 }, destinations = { { "Alterac Mountains", "AlteracMountains", 370.763, -491.355 }, { "Strahnbrad", "Strahnbrad", 659.762, -959.316 } } },
    ["Elwynn Forest"] = { continent = "ek", overlay = "Elwynn", bounds = { -10254.166, -7939.583, -1535.416, 1935.416 }, destinations = { { "Elwynn Forest", "ElwynnForest", -9617, -289 }, { "Goldshire", "Goldshire", -9449, 68 } } },
    ["Westfall"] = { continent = "ek", overlay = "Westfall", bounds = { -11733.333, -9400, -3016.666, 483.333 }, destinations = { { "Westfall", "Westfall", -10235, 1222 }, { "Sentinel Hill", "SentinelHill", -10624, 1097 } } },
    ["Redridge Mountains"] = { continent = "ek", overlay = "Redridge", bounds = { -10227.083, -8514.583, 1479.166, 4047.916 }, destinations = { { "Redridge Mountains", "RedridgeMountains", -9552, -2205 }, { "Lakeshire", "Lakeshire", -9267, -2189 } } },
    ["Duskwood"] = { continent = "ek", overlay = "Duskwood", bounds = { -11516.666, -9716.666, -833.333, 1866.666 }, destinations = { { "Duskwood", "Duskwood", -10898, -365 }, { "Darkshire", "Darkshire", -10573, -1183 } } },
    ["Stranglethorn Vale"] = { continent = "ek", overlay = "Stranglethorn", bounds = { -15422.916, -11168.75, -2220.833, 4160.416 }, destinations = { { "Stranglethorn Vale", "StranglethornVale", -12644, -377 }, { "Booty Bay", "BootyBay", -14297, 531 } } },
    ["Dun Morogh"] = { continent = "ek", overlay = "DunMorogh", bounds = { -7206.249, -3941.666, -2137.5, 2760.416 }, destinations = { { "Dun Morogh", "DunMorogh", -5452, -657 }, { "Kharanos", "Kharanos", -5597, -483 } } },
    ["Loch Modan"] = { continent = "ek", overlay = "LochModan", bounds = { -6327.083, -4487.5, 1993.749, 4752.083 }, destinations = { { "Loch Modan", "LochModan", -5203, -2855 }, { "Thelsamar", "Thelsamar", -5353, -2949 } } },
    ["Wetlands"] = { continent = "ek", overlay = "Wetlands", bounds = { -4904.166, -2147.916, 389.583, 4525 }, destinations = { { "Wetlands", "Wetlands", -3243, -2469 }, { "Menethil Harbor", "MenethilHarbor", -3769, -744 } } },
    ["Arathi Highlands"] = { continent = "ek", overlay = "Arathi", bounds = { -2460.416, -141.666, 1127.083, 4604.166 }, destinations = { { "Arathi Highlands", "ArathiHighlands", -1509, -2732 }, { "Refuge Pointe", "RefugePointe", -1247, -2529 } } },
    ["Hinterlands"] = { continent = "ek", mapName = "The Hinterlands", overlay = "Hinterlands", bounds = { -1100, 1466.666, 1575, 5425 }, destinations = { { "The Hinterlands", "AeriePeak", 120, -3190 }, { "Aerie Peak", "AeriePeak", 260, -2125 } } },
    ["Western Plaguelands"] = { continent = "ek", overlay = "WesternPlaguelands", bounds = { 499.999, 3366.666, -416.666, 3883.333 }, destinations = { { "Western Plaguelands", "WesternPlaguelands", 1729, -1602 }, { "Chillwind Camp", "ChillwindCamp", 968, -1444 } } },
    ["Eastern Plaguelands"] = { continent = "ek", overlay = "EasternPlaguelands", bounds = { 1016.666, 3704.166, 2287.5, 6318.75 }, destinations = { { "Eastern Plaguelands", "EasternPlaguelands", 2301, -4613 }, { "Light's Hope Chapel", "LightsHopeChapel", 2280, -5310 } } },
    ["Badlands"] = { continent = "ek", overlay = "Badlands", bounds = { -7899.999, -5854.166, 1902.083, 4972.916 }, destinations = { { "Badlands", "Badlands", -6779, -3424 }, { "Kargath", "Kargath", -6692, -2175 } } },
    ["Searing Gorge"] = { continent = "ek", overlay = "SearingGorge", bounds = { -7587.499, -6100, 322.916, 2554.166 }, destinations = { { "Searing Gorge", "SearingGorge", -7012, -1065 }, { "Thorium Point", "ThoriumPoint", -6506, -1150 } } },
    ["Burning Steppes"] = { continent = "ek", overlay = "BurningSteppes", bounds = { -9085.416, -6985.416, 464.583, 3616.666 }, destinations = { { "Burning Steppes", "BurningSteppes", -8119, -1634 }, { "Morgan's Vigil", "MorgansVigil", -8373, -2754 } } },
    ["Swamp of Sorrows"] = { continent = "ek", overlay = "SwampOfSorrows", bounds = { -11208.333, -9535.416, 2081.25, 4589.583 }, destinations = { { "Swamp of Sorrows", "SwampOfSorrows", -10345, -2773 }, { "Stonard", "Stonard", -10447, -3262 } } },
    ["Blasted Lands"] = { continent = "ek", overlay = "BlastedLands", bounds = { -13024.999, -10583.333, 1193.75, 4856.25 }, destinations = { { "Blasted Lands", "BlastedLands", -11182, -3017 }, { "Nethergarde Keep", "NethergardeKeep", -11000, -3380 } } },
    ["Deadwind Pass"] = { continent = "ek", overlay = "DeadwindPass", bounds = { -11533.333, -9866.666, 833.333, 3333.333 }, destinations = { { "Deadwind Pass", "DeadwindPass", -10438.8, -1932.75 }, { "Karazhan", "Karazhan", -11118.9, -2010.33 } } },
    ["Isle of Quel'Danas"] = { continent = "ek", mapName = "Isle of Quel'Danas", overlay = "Sunwell", bounds = { 11350, 13568.749, 5302.083, 8629.166 }, overview = false, destinations = { { "Isle of Quel'Danas", "IsleOfQuelDanas", 12947.4, -6893.31 }, { "Shattered Sun Staging Area", "ShatteredSunStaging", 12947.4, -6893.31 } } },

    ["Teldrassil"] = { continent = "kalimdor", overlay = "Teldrassil", bounds = { 8437.5, 11831.25, -3814.583, 1277.083 }, destinations = { { "Teldrassil", "Teldrassil", 10111.3, 1557.73 }, { "Dolanaar", "Dolanaar", 9848.37, 966.953 } } },
    ["Darkshore"] = { continent = "kalimdor", overlay = "Darkshore", bounds = { 3966.666, 8333.333, -2941.666, 3608.333 }, destinations = { { "Darkshore", "Darkshore", 5756.25, 298.505 }, { "Auberdine", "Auberdine", 6501.4, 481.607 } } },
    ["Azuremyst Isle"] = { continent = "kalimdor", overlay = "AzuremystIsle", bounds = { -5508.333, -2793.75, 10500, 14570.833 }, overview = false, destinations = { { "Azuremyst Isle", "AzuremystIsle", -4216.87, -12336.9 }, { "Azure Watch", "AzureWatch", -4190.85, -12516.5 } } },
    ["Bloodmyst Isle"] = { continent = "kalimdor", overlay = "BloodmystIsle", bounds = { -2933.333, -758.333, 10075, 13337.499 }, overview = false, destinations = { { "Bloodmyst Isle", "BloodmystIsle", -1993.62, -11475.8 }, { "Blood Watch", "BloodWatch", -1944.5, -11873.7 } } },
    ["Winterspring"] = { continent = "kalimdor", overlay = "Winterspring", bounds = { 3800, 8533.333, 316.666, 7416.666 }, destinations = { { "Winterspring", "Winterspring", 6759.18, -4419.63 }, { "Everlook", "Everlook", 6725.69, -4619.44 } } },
    ["Moonglade"] = { continent = "kalimdor", overlay = "Moonglade", bounds = { 6952.083, 8491.666, 1381.25, 3689.583 }, destinations = { { "Moonglade", "Moonglade", 7654.3, -2232.87 }, { "Nighthaven", "Nighthaven", 7966.85, -2491.04 } } },
    ["Felwood"] = { continent = "kalimdor", overlay = "Felwood", bounds = { 3300, 7133.333, -1641.666, 4108.333 }, destinations = { { "Felwood", "Felwood", 4102.25, -1006.79 }, { "Emerald Sanctuary", "EmeraldSanctuary", 3986.71, -1293.58 } } },
    ["Ashenvale"] = { continent = "kalimdor", overlay = "Ashenvale", bounds = { 829.166, 4672.916, -1700, 4066.666 }, destinations = { { "Ashenvale", "Ashenvale", 1928.34, -2165.95 }, { "Astranaar", "Astranaar", 2676.19, -422.905 }, { "Splintertree Post", "SplintertreePost", 2270.94, -2538.19 } } },
    ["Azshara"] = { continent = "kalimdor", overlay = "Aszhara", bounds = { 1960.416, 5341.666, 3277.083, 8347.916 }, destinations = { { "Azshara", "Azshara", 3341.36, -4603.79 }, { "Valormok", "Valormok", 3608.59, -4414.43 } } },
    ["Durotar"] = { continent = "kalimdor", overlay = "Durotar", bounds = { -1716.666, 1808.333, 1962.499, 7249.999 }, destinations = { { "Durotar", "Durotar", 1007.78, -4446.22 }, { "Razor Hill", "RazorHill", 326.81, -4706.65 } } },
    ["The Barrens"] = { continent = "kalimdor", mapName = "The Barrens", overlay = "Barrens", bounds = { -5143.75, 1612.499, -2622.916, 7510.416 }, destinations = { { "The Barrens", "TheBarrens", 884.54, -3548.45 }, { "The Crossroads", "TheCrossroads", -452.84, -2650.76 }, { "Ratchet", "Ratchet", -956.664, -3754.71 } } },
    ["Mulgore"] = { continent = "kalimdor", overlay = "Mulgore", bounds = { -3697.916, -272.916, -2047.916, 3089.583 }, destinations = { { "Mulgore", "Mulgore", -2192.62, -736.317 }, { "Bloodhoof Village", "BloodhoofVillage", -2240.91, -399.174 } } },
    ["Stonetalon Mountains"] = { continent = "kalimdor", overlay = "StonetalonMountains", bounds = { -339.583, 2916.666, -3245.833, 1637.499 }, destinations = { { "Stonetalon Mountains", "StonetalonMountains", 1570.92, 1031.52 }, { "Sun Rock Retreat", "SunRockRetreat", 966.147, 926.499 } } },
    ["Desolace"] = { continent = "kalimdor", overlay = "Desolace", bounds = { -2545.833, 452.083, -4233.333, 262.5 }, destinations = { { "Desolace", "Desolace", -606.395, 2211.75 }, { "Nijel's Point", "NijelsPoint", 176.426, 1309.76 }, { "Shadowprey Village", "ShadowpreyVillage", -1664.79, 3091.67 } } },
    ["Dustwallow Marsh"] = { continent = "kalimdor", overlay = "Dustwallow", bounds = { -5533.333, -2033.333, 975, 6225 }, destinations = { { "Dustwallow Marsh", "DustwallowMarsh", -4043.65, -2991.32 }, { "Theramore", "Theramore", -3641.3, -4358.93 }, { "Brackenwall Village", "BrackenwallVillage", -3130.67, -2908.43 } } },
    ["Feralas"] = { continent = "kalimdor", overlay = "Feralas", bounds = { -7000, -2366.666, -5441.666, 1508.333 }, destinations = { { "Feralas", "Feralas", -4841.19, 1309.44 }, { "Feathermoon Stronghold", "FeathermoonStronghold", -4317.47, 3287.35 }, { "Camp Mojache", "CampMojache", -4396.7, 224.841 } } },
    ["Thousand Needles"] = { continent = "kalimdor", overlay = "ThousandNeedles", bounds = { -6900, -3966.666, 433.333, 4833.333 }, destinations = { { "Thousand Needles", "ThousandNeedles", -4969.02, -1726.89 }, { "Freewind Post", "FreewindPost", -5431.78, -2449.38 } } },
    ["Tanaris"] = { continent = "kalimdor", overlay = "Tanaris", bounds = { -10475, -5875, 218.749, 7118.749 }, destinations = { { "Tanaris", "Tanaris", -7931.2, -3414.28 }, { "Gadgetzan", "Gadgetzan", -7177.15, -3785.34 }, { "Steamwheedle Port", "SteamwheedlePort", -6908.08, -4801.39 } } },
    ["Un'Goro Crater"] = { continent = "kalimdor", overlay = "UngoroCrater", bounds = { -8433.333, -5966.666, -533.333, 3166.666 }, destinations = { { "Un'Goro Crater", "UnGoroCrater", -7943.22, -2119.09 }, { "Marshal's Refuge", "MarshalsRefuge", -6152.25, -1087.6 } } },
    ["Silithus"] = { continent = "kalimdor", overlay = "Silithus", bounds = { -8281.25, -5958.333, -2537.5, 945.833 }, destinations = { { "Silithus", "Silithus", -7426.87, 1005.31 }, { "Cenarion Hold", "CenarionHold", -6818.09, 733.814 } } },

    ["Hellfire Peninsula"] = { continent = "outland", overlay = "Hellfire", bounds = { -1962.5, 1481.25, -5539.583, -375 }, destinations = { { "Hellfire Peninsula", "HellfirePeninsula", -211.237, 4278.54 }, { "Honor Hold", "HonorHold", -748.211, 2681.52 }, { "Thrallmar", "Thrallmar", 156.251, 2673.45 } } },
    ["Zangarmarsh"] = { continent = "outland", overlay = "Zangarmarsh", bounds = { -1416.666, 1935.416, -9475, -4447.916 }, destinations = { { "Zangarmarsh", "Zangarmarsh", -54.862, 5813.44 }, { "Cenarion Refuge", "CenarionRefuge", -223.541, 5487.99 }, { "Telredor", "Telredor", 278.582, 6001.27 }, { "Zabra'jin", "Zabrajin", 260.28, 7860.4 } } },
    ["Terokkar Forest"] = { continent = "outland", overlay = "TerokkarForest", bounds = { -4600, -1000, -7083.333, -1683.333 }, destinations = { { "Terokkar Forest", "TerokkarForest", -2000.47, 4451.54 }, { "Allerian Stronghold", "AllerianStronghold", -2949.27, 3958.32 }, { "Stonebreaker Hold", "StonebreakerHold", -2640.08, 4404.38 } } },
    ["Nagrand"] = { continent = "outland", overlay = "Nagrand", bounds = { -3641.666, 41.666, -10295.833, -4770.833 }, destinations = { { "Nagrand", "Nagrand", -1145.95, 8182.35 }, { "Telaar", "Telaar", -2560.76, 7300.72 }, { "Garadar", "Garadar", -1321.34, 7239.12 } } },
    ["Blade's Edge Mountains"] = { continent = "outland", overlay = "BladesEdgeMountains", bounds = { 791.666, 4408.333, -8845.833, -3420.833 }, destinations = { { "Blade's Edge Mountains", "BladesEdgeMountains", 3037.67, 5962.86 }, { "Sylvanaar", "Sylvanaar", 2018.91, 6854.47 }, { "Thunderlord Stronghold", "ThunderlordStronghold", 2314.75, 6041.96 } } },
    ["Netherstorm"] = { continent = "outland", overlay = "Netherstorm", bounds = { 1739.583, 5456.25, -5483.333, 91.666 }, destinations = { { "Netherstorm", "Netherstorm", 3830.23, 3426.5 }, { "Area 52", "Area52", 3043.33, 3681.33 }, { "The Stormspire", "TheStormspire", 4150.19, 3015.92 } } },
    ["Shadowmoon Valley"] = { continent = "outland", overlay = "ShadowmoonValley", bounds = { -5614.583, -1947.916, -4225, 1275 }, destinations = { { "Shadowmoon Valley", "LegionHold", -3291.28, 2888 }, { "Wildhammer Stronghold", "WildhammerStronghold", -3989.47, 2168.39 }, { "Shadowmoon Village", "ShadowmoonVillage", -2998.66, 2568.9 } } },

    ["Borean Tundra"] = { continent = "northrend", overlay = "BoreanTundra", bounds = { 1054.166, 4897.916, -8570.833, -2806.25 }, destinations = { { "Borean Tundra", "BoreanTundra", 3256.57, 5278.23 }, { "Valiance Keep", "ValianceKeep", 2213.95, 5273.15 }, { "Warsong Hold", "WarsongHold", 2741.29, 6097.16 } } },
    ["Howling Fjord"] = { continent = "northrend", overlay = "HowlingFjord", bounds = { -914.583, 3116.666, 1397.916, 7443.749 }, destinations = { { "Howling Fjord", "HowlingFjord", 1902.15, -4883.91 }, { "Valgarde", "Valgarde", 564.401, -4944.94 }, { "Vengeance Landing", "VengeanceLanding", 1942.86, -6167.11 } } },
    ["Dragonblight"] = { continent = "northrend", overlay = "Dragonblight", bounds = { 1835.416, 5575, -3627.083, 1981.249 }, destinations = { { "Dragonblight", "Dragonblight", 4379.66, 1056.62 }, { "Wyrmrest Temple", "WyrmrestTemple", 3556.22, 264.514 }, { "Stars' Rest", "StarsRest", 3480.7, 2000.06 }, { "Agmar's Hammer", "AgmarsHammer", 3841.51, 1534.04 } } },
    ["Grizzly Hills"] = { continent = "northrend", overlay = "GrizzlyHills", bounds = { 2016.666, 5516.666, 1110.416, 6360.416 }, destinations = { { "Grizzly Hills", "GrizzlyHills", 4391.73, -3587.92 }, { "Amberpine Lodge", "AmberpineLodge", 3412.88, -2791.17 }, { "Conquest Hold", "ConquestHold", 3251.86, -2244.98 } } },
    ["Zul'Drak"] = { continent = "northrend", overlay = "ZulDrak", bounds = { 4339.583, 7668.749, 600, 5593.75 }, destinations = { { "Zul'Drak", "ZulDrak", 5560.23, -3211.66 }, { "The Argent Stand", "TheArgentStand", 5450.38, -2422.65 }, { "Ebon Watch", "EbonWatch", 5228.59, -1328.17 } } },
    ["Sholazar Basin"] = { continent = "northrend", overlay = "SholazarBasin", bounds = { 4383.333, 7287.499, -6929.166, -2572.916 }, destinations = { { "Sholazar Basin", "SholazarBasin", 4857.14, 5529.11 }, { "River's Heart", "RiversHeart", 5368.05, 4843.58 }, { "Nesingwary Base Camp", "NesingwaryBaseCamp", 5561.69, 5748.65 } } },
    ["The Storm Peaks"] = { continent = "northrend", overlay = "TheStormPeaks", bounds = { 5456.25, 10197.916, -1841.666, 5270.833 }, destinations = { { "The Storm Peaks", "StormPeaks", 7527.14, -1260.89 }, { "K3", "K3", 6123.7, -1059.19 }, { "Frosthold", "Frosthold", 6666.43, -211.341 }, { "Camp Tunka'lo", "CampTunkalo", 7808.82, -2949.29 } } },
    ["Icecrown"] = { continent = "northrend", overlay = "IcecrownGlacier", bounds = { 5245.833, 9427.083, -5443.75, 827.083 }, destinations = { { "Icecrown", "Icecrown", 7374.96, 1991.1 }, { "Argent Tournament", "ArgentTournament", 8515.89, 629.25 }, { "The Shadow Vault", "TheShadowVault", 8427.88, 2706.33 } } },
    ["Wintergrasp"] = { continent = "northrend", mapName = "Wintergrasp", overlay = "LakeWintergrasp", bounds = { 3733.333, 5716.666, -4329.166, -1354.166 }, destinations = { { "Wintergrasp", "Wintergrasp", 4760.7, 2143.7 }, { "Wintergrasp Fortress", "WintergraspFortress", 5348.02, 2839.27 } } },
    ["Crystalsong Forest"] = { continent = "northrend", overlay = "CrystalsongForest", bounds = { 4687.5, 6502.083, -1443.75, 1279.166 }, destinations = { { "Crystalsong Forest", "CrystalsongForest", 5258.39, 156.958 }, { "The Violet Stand", "VioletStand", 5744.35, 1017.14 } } },
}

-- Additional high-value quest hubs and flight points. The first two entries in
-- each ZONE_VIEWS record remain the broad area and primary settlement; these
-- entries fill out the useful leveling route without turning the map into a
-- list of every minor camp in game_tele.
local QUEST_HUBS = {
    ["Eversong Woods"] = {
        { "Sunstrider Isle", "SunstriderIsle", 10331.1, -6235.42, "Quest hub" },
        { "Falconwing Square", "FalconwingSquare", 9514.33, -6822.1, "Quest hub" },
        { "Farstrider Retreat", "FarstriderRetreat", 9041.51, -7456.05, "Quest hub" },
    },
    ["Ghostlands"] = { { "Farstrider Enclave", "farstriderEnclave", 7544.57, -7667.85, "Quest hub" } },
    ["Tirisfal Glades"] = {
        { "Deathknell", "Deathknell", 1843.5, 1590, "Quest hub" },
        { "The Bulwark", "TheBulwark", 1711.99, -719.761, "Quest hub / flight master" },
    },
    ["Western Plaguelands"] = { { "The Bulwark", "TheBulwark", 1711.99, -719.761, "Quest hub / flight master" } },
    ["Elwynn Forest"] = {
        { "Eastvale Logging Camp", "EastvaleLoggingCamp", -9450.82, -1299.92, "Quest hub" },
        { "Westbrook Garrison", "WestbrookGarrison", -9663.01, 686.769, "Quest hub" },
    },
    ["Duskwood"] = { { "Raven Hill", "RavenHill", -10742.2, 330.574, "Quest hub" } },
    ["Stranglethorn Vale"] = {
        { "Rebel Camp", "RebelCamp", -11322.4, -202.492, "Alliance quest hub / flight master" },
        { "Grom'gol Base Camp", "GromgolBaseCamp", -12388.9, 172.578, "Horde quest hub / flight master" },
        { "Nesingwary's Expedition", "NesingwarysExpedition", -11609.3, -52.9532, "Neutral quest hub" },
    },
    ["Dun Morogh"] = { { "Anvilmar", "Anvilmar", -6165.16, 383.46, "Quest hub" } },
    ["Arathi Highlands"] = { { "Hammerfall", "Hammerfall", -941.007, -3526.66, "Horde quest hub / flight master" } },
    ["Hinterlands"] = { { "Revantusk Village", "RevantuskVillage", -557.226, -4581.27, "Horde quest hub / flight master" } },
    ["Burning Steppes"] = { { "Flame Crest", "FlameCrest", -7501.51, -2183.08, "Horde quest hub / flight master" } },
    ["Swamp of Sorrows"] = { { "The Harborage", "TheHarborage", -10126, -2834.73, "Alliance quest hub" } },

    ["Felwood"] = {
        { "Talonbranch Glade", "TalonbranchGlade", 6209.51, -1927.01, "Alliance flight master" },
        { "Bloodvenom Post", "BloodvenomPost", 5128.91, -343.506, "Horde quest hub / flight master" },
    },
    ["Ashenvale"] = {
        { "Forest Song", "ForestSong", 3011.16, -3359.08, "Alliance quest hub / flight master" },
        { "Silverwind Refuge", "SilverwindRefuge", 2137.3, -1189.05, "Alliance quest hub" },
        { "Zoram'gar Outpost", "ZoramgarOutpost", 3376.86, 1013.05, "Horde quest hub / flight master" },
    },
    ["Azshara"] = { { "Talrendis Point", "TalrendisPoint", 2735.06, -3867.44, "Alliance quest hub / flight master" } },
    ["Durotar"] = {
        { "Valley of Trials", "ValleyOfTrials", -601.294, -4296.76, "Quest hub" },
        { "Sen'jin Village", "SenjinVillage", -813.097, -4880.08, "Quest hub" },
    },
    ["The Barrens"] = { { "Camp Taurajo", "CampTaurajo", -2363.11, -1913.78, "Horde quest hub / flight master" } },
    ["Mulgore"] = { { "Camp Narache", "CampNarache", -2919.35, -264.535, "Quest hub" } },
    ["Stonetalon Mountains"] = { { "Stonetalon Peak", "StonetalonPeak", 2678.38, 1497.46, "Alliance quest hub / flight master" } },
    ["Dustwallow Marsh"] = { { "Mudsprocket", "Mudsprocket", -4573.79, -3173.15, "Neutral quest hub / flight master" } },
    ["Feralas"] = { { "Thalanaar", "Thalanaar", -4525.63, -791.364, "Alliance quest hub / flight master" } },
    ["Thousand Needles"] = { { "Mirage Raceway", "TheShimmeringFlats", -5588.82, -3752.19, "Neutral quest hub" } },

    ["Hellfire Peninsula"] = {
        { "Temple of Telhamat", "TempleOfTelhamat", 78.9769, 4333.58, "Alliance quest hub / flight master" },
        { "Falcon Watch", "FalconWatch", -600.782, 4100.1, "Horde quest hub / flight master" },
    },
    ["Zangarmarsh"] = {
        { "Orebor Harborage", "OreborHarborage", 958.66, 7374.02, "Alliance quest hub / flight master" },
        { "Swamprat Post", "SwampratPost", 104.534, 5199.31, "Horde quest hub / flight master" },
    },
    ["Blade's Edge Mountains"] = {
        { "Toshley's Station", "ToshleysStation", 1910.63, 5556.25, "Alliance quest hub / flight master" },
        { "Mok'Nathal Village", "MokNathalVillage", 2210.93, 4763.72, "Horde quest hub / flight master" },
        { "Evergrove", "Evergrove", 2976.85, 5511.01, "Neutral quest hub / flight master" },
    },
    ["Netherstorm"] = { { "Cosmowrench", "Cosmowrench", 2988.21, 1806.9, "Neutral quest hub / flight master" } },
    ["Shadowmoon Valley"] = {
        { "Altar of Sha'tar", "AltarOfShatar", -3053.96, 828.896, "Neutral quest hub / flight master" },
        { "Sanctum of the Stars", "SanctumOfTheStars", -4115.51, 1120.54, "Neutral quest hub / flight master" },
    },

    ["Borean Tundra"] = {
        { "Fizzcrank Airstrip", "FizzcrankAirstrip", 4147.98, 5278.79, "Alliance quest hub / flight master" },
        { "Bor'gorok Outpost", "BorgorokOutpost", 4488.76, 5736.18, "Horde quest hub / flight master" },
        { "Amber Ledge", "AmberLedge", 3601.73, 5941.81, "Neutral quest hub / flight master" },
        { "Unu'pe", "Unupe", 2925.02, 4065.63, "Neutral quest hub / flight master" },
    },
    ["Howling Fjord"] = {
        { "Westguard Keep", "WestguardKeep", 1391.04, -3284.63, "Alliance quest hub / flight master" },
        { "Fort Wildervar", "FortWildervar", 2469.09, -5086.4, "Alliance quest hub / flight master" },
        { "New Agamand", "NewAgamand", 424.405, -4548.76, "Horde quest hub / flight master" },
        { "Camp Winterhoof", "CampWinterhoof", 2649.82, -4362.69, "Horde quest hub / flight master" },
        { "Apothecary Camp", "ApothecaryCamp", 2134.33, -2979.44, "Horde quest hub / flight master" },
        { "Kamagua", "Kamagua", 774.043, -2940.65, "Neutral quest hub / flight master" },
    },
    ["Dragonblight"] = {
        { "Wintergarde Keep", "WintergardeKeep", 3682.71, -722.635, "Alliance quest hub / flight master" },
        { "Venomspite", "Venomspite", 3241.29, -699.767, "Horde quest hub / flight master" },
    },
    ["Grizzly Hills"] = {
        { "Westfall Brigade Encampment", "WestfallBrigadeEncampment", 4529.59, -4233.93, "Alliance quest hub / flight master" },
        { "Camp Oneqwah", "CampOneqwah", 3848.7, -4543.46, "Horde quest hub / flight master" },
    },
    ["Zul'Drak"] = {
        { "Light's Breach", "LightsBreach", 5154.52, -2188.33, "Neutral quest hub / flight master" },
        { "Zim'Torga", "ZimTorga", 5757.21, -3528.22, "Neutral quest hub / flight master" },
    },
    ["The Storm Peaks"] = {
        { "Brunnhildar Village", "BrunnhildarVillage", 7056.37, -1698, "Neutral quest hub" },
        { "Dun Niffelem", "DunNiffelem", 7165.42, -2729.01, "Neutral quest hub" },
    },
    ["Crystalsong Forest"] = {
        { "Windrunner's Overlook", "WindrunnersOverlook", 5057.03, -560.349, "Alliance quest hub / flight master" },
        { "Sunreaver's Command", "SunreaversCommand", 5595.35, -704.415, "Horde quest hub / flight master" },
    },
}

local REGIONS = {
    ek = {
        { "Northern Kingdoms", { "Eversong Woods", "Ghostlands", "Isle of Quel'Danas", "Tirisfal Glades", "Silverpine Forest", "Western Plaguelands", "Eastern Plaguelands", "Hinterlands" } },
        { "Central Kingdoms", { "Dun Morogh", "Loch Modan", "Wetlands", "Arathi Highlands", "Hillsbrad Foothills", "Alterac Mountains" } },
        { "Southern Kingdoms", { "Elwynn Forest", "Westfall", "Redridge Mountains", "Duskwood", "Stranglethorn Vale", "Deadwind Pass", "Badlands", "Searing Gorge", "Burning Steppes", "Swamp of Sorrows", "Blasted Lands" } },
    },
    kalimdor = {
        { "Northern Kalimdor", { "Teldrassil", "Darkshore", "Azuremyst Isle", "Bloodmyst Isle", "Winterspring", "Moonglade", "Felwood", "Ashenvale", "Azshara" } },
        { "Central Kalimdor", { "Durotar", "The Barrens", "Mulgore", "Stonetalon Mountains", "Desolace", "Dustwallow Marsh" } },
        { "Southern Kalimdor", { "Feralas", "Thousand Needles", "Tanaris", "Un'Goro Crater", "Silithus" } },
    },
    outland = {
        { "Outland Regions", { "Hellfire Peninsula", "Zangarmarsh", "Terokkar Forest", "Nagrand", "Blade's Edge Mountains", "Netherstorm", "Shadowmoon Valley" } },
        { "Major Hubs", { "Honor Hold", "Thrallmar", "Cenarion Refuge", "Area 52", "Wildhammer Stronghold", "Shadowmoon Village" } },
    },
    northrend = {
        { "Southern Northrend", { "Borean Tundra", "Howling Fjord", "Dragonblight", "Grizzly Hills" } },
        { "Northern Northrend", { "Zul'Drak", "Sholazar Basin", "The Storm Peaks", "Icecrown", "Wintergrasp", "Crystalsong Forest" } },
        { "Major Hubs", { "Valiance Keep", "Warsong Hold", "Wyrmrest Temple", "Argent Tournament" } },
    },
}

local DUNGEON_EXPANSIONS = {
    { key = "classic", label = "Classic", minimum = 13, maximum = 60, ranges = { { 13, 25 }, { 26, 40 }, { 41, 50 }, { 51, 60 } } },
    { key = "tbc", label = "The Burning Crusade", minimum = 58, maximum = 70, ranges = { { 58, 64 }, { 65, 67 }, { 68, 70 } } },
    { key = "wrath", label = "Wrath of the Lich King", minimum = 68, maximum = 80, ranges = { { 68, 73 }, { 74, 77 }, { 78, 79 }, { 80, 80 } } },
}

local DUNGEONS = {
    classic = {
        { "Ragefire Chasm", "RagefireChasm", 13, 20 }, { "The Deadmines", "Deadmines", 15, 25 }, { "Wailing Caverns", "WailingCaverns", 15, 25 },
        { "Shadowfang Keep", "ShadowFangKeep", 18, 30 }, { "Blackfathom Deeps", "BlackfathomDeeps", 20, 30 }, { "The Stockade", "TheStockade", 22, 32 },
        { "Gnomeregan", "Gnomeregan", 24, 34 }, { "Razorfen Kraul", "RazorfenKraul", 25, 35 }, { "Scarlet Monastery", "ScarletMonastery", 26, 45 },
        { "Razorfen Downs", "RazorfenDowns", 35, 45 }, { "Uldaman", "Uldaman", 35, 45 }, { "Zul'Farrak", "ZulFarrak", 44, 54 },
        { "Maraudon", "Maraudon", 46, 55 }, { "The Sunken Temple", "TheSunkenTemple", 50, 60 }, { "Blackrock Depths", "BlackrockDepths", 52, 60 },
        { "Dire Maul", "DireMaulNorth", 55, 60 }, { "Scholomance", "Scholomance", 55, 60 }, { "Stratholme", "Stratholme", 55, 60 },
        { "Blackrock Spire", "BlackrockSpire", 55, 60 },
    },
    tbc = {
        { "Hellfire Ramparts", "HellfireRamparts", 58, 70 }, { "The Blood Furnace", "TheBloodFurnace", 59, 70 }, { "The Slave Pens", "TheSlavePens", 60, 70 },
        { "The Underbog", "TheUnderbog", 61, 70 }, { "Mana-Tombs", "ManaTombs", 63, 70 }, { "Auchenai Crypts", "AuchenaiCrypts", 64, 70 },
        { "Sethekk Halls", "SethekkHalls", 65, 70 }, { "Old Hillsbrad", "OldHillsbradFoothills", 66, 70 }, { "The Steamvault", "TheSteamvault", 67, 70 },
        { "Shadow Labyrinth", "ShadowLabyrinth", 67, 70 }, { "The Shattered Halls", "TheShatteredHalls", 67, 70 },
        { "The Mechanar", "TheMechanar", 68, 70 }, { "The Botanica", "TheBotanica", 68, 70 }, { "The Arcatraz", "TheArcatraz", 68, 70 },
        { "The Black Morass", "TheBlackMorass", 68, 70 }, { "Magisters' Terrace", "MagistersTerrace", 68, 70 },
    },
    wrath = {
        { "Utgarde Keep", "UtgardeKeep", 68, 75 }, { "The Nexus", "TheNexus", 69, 75 },
        { "Azjol-Nerub", "AzjolNerub", 72, 77 }, { "Ahn'kahet", "AhnKahet", 73, 78 }, { "Drak'Tharon Keep", "DrakTharonKeep", 74, 79 },
        { "The Violet Hold", "TheVioletHold", 75, 80 }, { "Gundrak", "Gundrak", 76, 80 }, { "Halls of Stone", "HallsOfStone", 77, 80 },
        { "Halls of Lightning", "HallsOfLightning", 78, 80 }, { "The Oculus", "TheOculus", 78, 80 },
        { "Utgarde Pinnacle", "UtgardePinnacle", 78, 80 }, { "The Culling of Stratholme", "TheCullingOfStratholme", 78, 80 },
        { "Trial of the Champion", "TrialOfTheChampion", 80, 80 }, { "The Forge of Souls", "TheForgeOfSouls", 80, 80 },
        { "Pit of Saron", "PitOfSaron", 80, 80 }, { "Halls of Reflection", "HallsOfReflection", 80, 80 },
    },
}

local function dungeonExpansion(key)
    for _, expansion in ipairs(DUNGEON_EXPANSIONS) do
        if expansion.key == key then return expansion end
    end
end

local RAIDS = {
    { "Molten Core", "MoltenCore", 60 }, { "Onyxia's Lair", "OnyxiasLair", 60 }, { "Blackwing Lair", "BlackwingLair", 60 },
    { "Zul'Gurub", "ZulGurub", 60 }, { "Ruins of Ahn'Qiraj", "TheRuinsOfAhnQiraj", 60 }, { "Temple of Ahn'Qiraj", "TheTempleOfAhnQiraj", 60 },
    { "Karazhan", "Karazhan", 70 }, { "Gruul's Lair", "GruulsLair", 70 }, { "Magtheridon's Lair", "MagtheridonsLair", 70 },
    { "Serpentshrine Cavern", "SerpentshrineCavern", 70 }, { "Tempest Keep", "TempestKeep", 70 }, { "Battle for Mount Hyjal", "HyjalSummit", 70 },
    { "Black Temple", "BlackTemple", 70 }, { "Sunwell Plateau", "SunwellPlateau", 70 },
    { "Naxxramas", "Naxxramas", 80 }, { "The Eye of Eternity", "TheEyeOfEternity", 80 }, { "Ulduar", "Ulduar", 80 },
    { "The Obsidian Sanctum", "TheObsidianSanctum", 80 }, { "Vault of Archavon", "VaultOfArchavon", 80 },
    { "Trial of the Crusader", "TrialOfTheCrusader", 80 }, { "Icecrown Citadel", "IcecrownCitadelRaid", 80 }, { "Ruby Sanctum", "TheRubySanctum", 80 },
}

local function makeButton(parent, text, width, height)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, height); button:SetText(text)
    local label = button:GetFontString()
    if label then local font, size, flags = label:GetFont(); if font and size then label:SetFont(font, size + 2, flags) end end
    return button
end

local function bumpFont(fontString)
    if not fontString then return end
    local font, size, flags = fontString:GetFont()
    if font and size then fontString:SetFont(font, size + 2, flags) end
end

local function playerFaction()
    local faction = UnitFactionGroup and UnitFactionGroup("player")
    if faction == "Alliance" or faction == "Horde" then return faction end
    return nil
end

local function destinationAllowed(name)
    local requiredFaction = name and FACTION_TELEPORTS[name]
    local faction = playerFaction()
    return not requiredFaction or not faction or requiredFaction == faction
end

local function getCloseAfterTeleport()
    local settings = MultiBot.Store and MultiBot.Store.GetUIChildStore and MultiBot.Store.GetUIChildStore("teleport")
    return not settings or settings.closeAfterTeleport ~= false
end

local function setCloseAfterTeleport(value)
    local settings = MultiBot.Store and MultiBot.Store.EnsureUIChildStore and MultiBot.Store.EnsureUIChildStore("teleport")
    if settings then settings.closeAfterTeleport = value and true or false end
end

local function summonAltBots()
    if not MultiBot.ActionToGroup then return end
    if (GetNumRaidMembers() or 0) <= 5 and (GetNumPartyMembers() or 0) <= 0 then return end
    MultiBot.ActionToGroup("summon")
end

local function teleport(name)
    if not name or name == "" then return end
    if not destinationAllowed(name) then
        if UIErrorsFrame then UIErrorsFrame:AddMessage("That destination belongs to the opposing faction.", 1, .2, .2, 1) end
        return
    end
    SendChatMessage(".tele " .. name, "SAY")
    if getCloseAfterTeleport() and T.frame then T.frame:Hide() end
    if MultiBot.TimerAfter then MultiBot.TimerAfter(1, summonAltBots) else summonAltBots() end
end

local function capitalFor(key)
    local values = {}
    for _, capital in ipairs(CAPITALS) do
        if capital[3] == key and destinationAllowed(capital[2]) then table.insert(values, capital) end
    end
    return values
end

local function hubFor(key, label)
    for _, hub in ipairs(HUBS[key] or {}) do
        if hub[1] == label then return hub end
    end
end

local function destinationsFor(zoneName)
    local zone = ZONE_VIEWS[zoneName]
    local values, seen = {}, {}

    local function append(destination)
        local tele = destination and destination[2]
        if tele and not seen[tele] and destinationAllowed(tele) then
            seen[tele] = true
            table.insert(values, destination)
        end
    end

    for _, destination in ipairs(zone and zone.destinations or {}) do append(destination) end
    for _, destination in ipairs(QUEST_HUBS[zoneName] or {}) do append(destination) end
    return values
end

function T:Message(text) if self.status then self.status:SetText(text or "") end end

function T:SetBreadcrumb(text)
    self.breadcrumb:SetText("World" .. (text and text ~= "" and ("  >  " .. text) or ""))
end

function T:ClearPins()
    for _, pin in ipairs(self.pins or {}) do pin:Hide() end
    self.pins = {}
end

function T:ClearExploration()
    for _, texture in ipairs(self.explorationTiles or {}) do texture:Hide() end
    self.explorationTiles = {}
end

function T:ClearMapHighlight()
    self.hoverElapsed, self.hoverName = 0, nil
    if self.mapHighlight then self.mapHighlight:Hide() end
    if self.mapAreaLabel then self.mapAreaLabel:SetText(self.selectedZone and ("Region: " .. self.selectedZone) or "Region: —") end
end

function T:CursorMapPoint()
    if not self.mapContent or not self.mapScroll or not self.mapScroll:IsMouseOver() then return end
    local scale = self.mapContent:GetEffectiveScale()
    local cursorX, cursorY = GetCursorPosition()
    cursorX, cursorY = cursorX / scale, cursorY / scale
    local left, top = self.mapContent:GetLeft(), self.mapContent:GetTop()
    if not left or not top then return end
    local x = (cursorX - left) / self.mapWidth
    local y = (top - cursorY) / self.mapHeight
    if x < 0 or x > 1 or y < 0 or y > 1 then return end
    return x, y
end

function T:SetNativeMapContext(continent)
    if not continent or not SetMapZoom then return end
    if continent.key == "world" then
        SetMapZoom(WORLDMAP_WORLD_ID or 0)
    else
        SetMapZoom(continent.uiIndex, 0)
    end
end

function T:RestoreMapContext(oldContinent, oldZone)
    if oldContinent and oldContinent > 0 then
        SetMapZoom(oldContinent, oldZone or 0)
    elseif SetMapToCurrentZone then
        SetMapToCurrentZone()
    end
end

function T:UpdateNativeMapHighlight(elapsed, force)
    self.hoverElapsed = (self.hoverElapsed or 0) + (elapsed or 0)
    if not force and self.hoverElapsed < .08 then return end
    self.hoverElapsed = 0

    local continent = CONTINENTS[self.continentKey]
    local x, y = self:CursorMapPoint()
    if self.selectedZone or not continent or not x or not UpdateMapHighlight then
        self:ClearMapHighlight()
        return
    end

    local oldContinent = GetCurrentMapContinent and GetCurrentMapContinent()
    local oldZone = GetCurrentMapZone and GetCurrentMapZone()
    self:SetNativeMapContext(continent)
    local name, fileName, texX, texY, width, height, offsetX, offsetY = UpdateMapHighlight(x, y)
    self:RestoreMapContext(oldContinent, oldZone)

    self.hoverName = name
    if not fileName or not width or width <= 0 or not height or height <= 0 then
        self.mapHighlight:Hide(); self.mapAreaLabel:SetText(name and ("Region: " .. name) or "Region: —")
        return
    end

    self.mapHighlight:ClearAllPoints()
    self.mapHighlight:SetTexture("Interface\\WorldMap\\" .. fileName .. "\\" .. fileName .. "Highlight")
    self.mapHighlight:SetTexCoord(0, texX, 0, texY)
    self.mapHighlight:SetSize(width * self.mapWidth, height * self.mapHeight)
    self.mapHighlight:SetPoint("TOPLEFT", self.mapContent, "TOPLEFT", offsetX * self.mapWidth, -offsetY * self.mapHeight)
    self.mapHighlight:SetVertexColor(1, .78, .08); self.mapHighlight:SetBlendMode("ADD")
    self.mapHighlight:SetAlpha(.6); self.mapHighlight:Show()
    self.mapAreaLabel:SetText(name and ("Region: " .. name) or "Region: —")
end

function T:HandleNativeMapClick()
    if self.selectedZone or not ProcessMapClick then return end
    local continent = CONTINENTS[self.continentKey]
    local x, y = self:CursorMapPoint()
    if not continent or not x then return end

    local oldContinent = GetCurrentMapContinent and GetCurrentMapContinent()
    local oldZone = GetCurrentMapZone and GetCurrentMapZone()
    self:SetNativeMapContext(continent)
    ProcessMapClick(x, y)
    local clickedContinent = GetCurrentMapContinent and GetCurrentMapContinent()
    local clickedZone = GetCurrentMapZone and GetCurrentMapZone()
    local zoneNames = clickedContinent and clickedContinent > 0 and { GetMapZones(clickedContinent) } or {}
    local zoneName = clickedZone and clickedZone > 0 and zoneNames[clickedZone]
    self:RestoreMapContext(oldContinent, oldZone)

    if continent.key == "world" then
        for key, candidate in pairs(CONTINENTS) do
            if candidate.uiIndex == clickedContinent and key ~= "world" then return self:ShowContinent(key) end
        end
    elseif clickedContinent == continent.uiIndex and zoneName and ZONE_VIEWS[zoneName] then
        self:ShowZone(zoneName)
    end
end

function T:DrawExploration(overlays)
    self:ClearExploration()
    for _, overlay in ipairs(overlays or {}) do
        local columns, rows = math.ceil(overlay.width / 256), math.ceil(overlay.height / 256)
        for index = 1, columns * rows do
            local column, row = (index - 1) % columns, math.floor((index - 1) / columns)
            local width, height = math.min(256, overlay.width - column * 256), math.min(256, overlay.height - row * 256)
            local texture = self.mapContent:CreateTexture(nil, "BORDER")
            texture:SetPoint("TOPLEFT", self.mapContent, "TOPLEFT", (overlay.x + column * 256) * self.mapWidth / 1002, -(overlay.y + row * 256) * self.mapHeight / 668)
            texture:SetSize(width * self.mapWidth / 1002 + 1, height * self.mapHeight / 668 + 1)
            texture:SetTexture(overlay.texture .. index); texture:SetTexCoord(0, width / 256, 0, height / 256); texture:Show()
            table.insert(self.explorationTiles, texture)
        end
    end
end

function T:MapPoint(continent, x, y)
    if not continent or not continent.bounds or not x or not y then return end
    local minX, maxX, minY, maxY = unpack(continent.bounds)
    return (-y - minY) / (maxY - minY), (maxX - x) / (maxX - minX)
end

function T:AddPin(item, labeled, bounds, red)
    local continent = CONTINENTS[self.continentKey]
    if not continent or item.mapId ~= continent.mapId then return end
    local pointSource = bounds and { bounds = bounds } or continent
    local px, py = self:MapPoint(pointSource, item.x, item.y)
    if not px or px < 0 or px > 1 or py < 0 or py > 1 then return end
    local pin = CreateFrame("Button", nil, self.mapContent)
    pin:SetSize(labeled and 175 or 30, labeled and 32 or 30)
    pin:SetPoint("LEFT", self.mapContent, "TOPLEFT", px * self.mapWidth - (labeled and 16 or 15), -py * self.mapHeight)
    local marker = pin:CreateTexture(nil, "OVERLAY"); marker:SetSize(labeled and 30 or 28, labeled and 30 or 28); marker:SetPoint("LEFT")
    marker:SetTexture("Interface\\AddOns\\MultiBot\\Textures\\TeleportDestinationMarker")
    if labeled then
        local label = pin:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("LEFT", marker, "RIGHT", 3, 0); label:SetText(item.label or item.name); label:SetJustifyH("LEFT")
        label:SetShadowColor(0, 0, 0, 1); label:SetShadowOffset(1, -1); bumpFont(label)
    end
    pin:SetScript("OnClick", function() teleport(item.tele or item.name) end)
    pin:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText(item.label or item.name); GameTooltip:AddLine("Click to teleport", .4, 1, .4); GameTooltip:Show()
    end)
    pin:SetScript("OnLeave", function() GameTooltip:Hide() end)
    table.insert(self.pins, pin)
end


function T:AcquireMapTextures(continent, zoneName)
    local textures, overlays = {}, {}
    if continent and continent.uiIndex and SetMapZoom then
        local oldContinent = GetCurrentMapContinent and GetCurrentMapContinent()
        local oldZone = GetCurrentMapZone and GetCurrentMapZone()
        local zoneIndex
        if zoneName and GetMapZones then
            local zones = { GetMapZones(continent.uiIndex) }
            for index, name in ipairs(zones) do if name == zoneName then zoneIndex = index; break end end
        end
        SetMapZoom(continent.uiIndex, zoneIndex or 0)
        if WorldMapFrame_Update then WorldMapFrame_Update() end
        for index = 1, 12 do
            local source = _G["WorldMapDetailTile" .. index]
            textures[index] = source and source:GetTexture()
        end
        if GetNumMapOverlays and GetMapOverlayInfo then
            for index = 1, GetNumMapOverlays() do
                local texture, width, height, x, y = GetMapOverlayInfo(index)
                if texture then table.insert(overlays, { texture = texture, width = width, height = height, x = x, y = y }) end
            end
        end
        if oldContinent and oldContinent > 0 then SetMapZoom(oldContinent, oldZone or 0) elseif SetMapToCurrentZone then SetMapToCurrentZone() end
    end
    return textures, overlays
end

function T:RenderMap()
    local continent = CONTINENTS[self.continentKey]
    self:ClearPins(); self:ClearExploration(); self:ClearMapHighlight()
    if not continent then
        for _, tile in ipairs(self.mapTiles) do tile:Hide() end
        self.mapHint:SetText("Choose a continent"); self.mapHint:Show(); return
    end
    self.mapHint:Hide()
    if self.outlandButton then
        if continent.key == "world" then self.outlandButton:Show() else self.outlandButton:Hide() end
    end
    local oldWidth, oldHeight = self.mapWidth or VIEW_W, self.mapHeight or VIEW_H
    local oldX, oldY = self.mapScroll:GetHorizontalScroll(), self.mapScroll:GetVerticalScroll()
    local centerX, centerY = (oldX + VIEW_W / 2) / oldWidth, (oldY + VIEW_H / 2) / oldHeight
    self.mapWidth, self.mapHeight = VIEW_W * self.zoom, VIEW_H * self.zoom
    self.mapContent:SetSize(self.mapWidth, self.mapHeight)
    local zone = self.selectedZone and ZONE_VIEWS[self.selectedZone]
    local textures, overlays = self:AcquireMapTextures(continent, zone and (zone.mapName or self.selectedZone))
    self.mapOverlays = overlays
    for index, tile in ipairs(self.mapTiles) do
        local column, row = (index - 1) % 4, math.floor((index - 1) / 4)
        local sourceWidth, sourceHeight = column == 3 and 234 or 256, row == 2 and 156 or 256
        local x = (math.min(column, 3) * 256) * self.mapWidth / 1002
        local y = (math.min(row, 2) * 256) * self.mapHeight / 668
        tile:ClearAllPoints(); tile:SetSize(sourceWidth * self.mapWidth / 1002 + 1, sourceHeight * self.mapHeight / 668 + 1)
        tile:SetPoint("TOPLEFT", self.mapContent, "TOPLEFT", x, -y)
        tile:SetTexCoord(0, sourceWidth / 256, 0, sourceHeight / 256)
        tile:SetTexture(textures[index] or ("Interface\\WorldMap\\" .. continent.art .. "\\" .. continent.art .. index)); tile:Show()
    end
    if zone then self:DrawExploration(overlays) end
    self.mapScroll:SetHorizontalScroll(math.max(0, math.min(self.mapWidth - VIEW_W, centerX * self.mapWidth - VIEW_W / 2)))
    self.mapScroll:SetVerticalScroll(math.max(0, math.min(self.mapHeight - VIEW_H, centerY * self.mapHeight - VIEW_H / 2)))
    if zone then
        for _, destination in ipairs(destinationsFor(self.selectedZone)) do
            self:AddPin({ label = destination[1], tele = destination[2], mapId = continent.mapId, x = destination[3], y = destination[4] }, true, zone.bounds, true)
        end
    else
        for _, capital in ipairs(capitalFor(self.continentKey)) do
            if capital[1] ~= "Silvermoon City" and capital[1] ~= "The Exodar" then
                self:AddPin({ label = capital[1], tele = capital[2], mapId = continent.mapId, x = capital[4], y = capital[5] }, true)
            end
        end
        if self.zoom >= 2 then
            for _, hub in ipairs(HUBS[self.continentKey] or {}) do
                if destinationAllowed(hub[2]) then
                    self:AddPin({ label = hub[1], tele = hub[2], mapId = continent.mapId, x = hub[3], y = hub[4] }, true)
                end
            end
        end
    end
    self.zoomText:SetText("Zoom " .. self.zoom .. "/3")
end

function T:SetZoom(value)
    self.zoom = math.max(1, math.min(3, tonumber(value) or 1))
    self:RenderMap()
end

function T:Display(entries, total, offset)
    self.displayItems, self.total, self.offset = entries or {}, total or #(entries or {}), offset or 0
    for index, row in ipairs(self.rows) do
        local item = self.displayItems[index]; row.item = item
        if item then
            local prefix = item.indent and string.rep("   ", item.indent) or ""
            row.name:SetText(prefix .. (item.header and "|cffffd100" or "") .. (item.arrow or "") .. item.label .. (item.header and "|r" or ""))
            row.detail:SetText(item.detail or "")
            if item.header then row:Disable() else row:Enable() end
            row:Show()
        else row:Hide() end
    end
    self.pageText:SetText(self.total > VISIBLE_ROWS and ((math.floor(self.offset / PAGE_SIZE) + 1) .. " / " .. math.max(1, math.ceil(self.total / PAGE_SIZE))) or "")
end

function T:ShowContinent(key)
    self.category, self.continentKey, self.selectedZone, self.zoom = "world", key, nil, 1
    local continent = CONTINENTS[key]; self:SetBreadcrumb(continent.label)
    local entries = { { label = continent.label:upper(), header = true }, { label = "CAPITALS", header = true } }
    for _, capital in ipairs(capitalFor(key)) do table.insert(entries, { label = capital[1], tele = capital[2], indent = 1, detail = "Capital" }) end
    table.insert(entries, { label = "REGIONS", header = true })
    for _, group in ipairs(REGIONS[key] or {}) do table.insert(entries, { label = group[1], group = group, arrow = "|cffffd100> |r", indent = 1, detail = "Region" }) end
    self:Display(entries); self:Message("Hover over a map region or choose one from the list"); self:RenderMap()
end

function T:ShowRegion(group)
    local continent = CONTINENTS[self.continentKey]
    self.zoom = 2; self:SetBreadcrumb(continent.label .. "  >  " .. group[1])
    local entries = { { label = "<  " .. continent.label, back = true }, { label = group[1]:upper(), header = true } }
    for _, zone in ipairs(group[2]) do
        if ZONE_VIEWS[zone] then
            table.insert(entries, { label = zone, zone = zone, indent = 1, detail = "Open map" })
        else
            local hub = hubFor(self.continentKey, zone)
            if hub and destinationAllowed(hub[2]) then table.insert(entries, { label = hub[1], tele = hub[2], indent = 1, detail = "Teleport" }) end
        end
    end
    self:Display(entries); self:Message("Choose a zone to show specific teleport destinations"); self:RenderMap()
end

function T:ShowZone(name)
    local zone = ZONE_VIEWS[name]
    if not zone then return self:Request(name, 0) end
    self.continentKey, self.selectedZone, self.zoom = zone.continent, name, 1
    local continent = CONTINENTS[self.continentKey]
    self:SetBreadcrumb(continent.label .. "  >  " .. name)
    local entries = { { label = "<  " .. continent.label, back = true }, { label = name:upper(), header = true } }
    local destinations = destinationsFor(name)
    for index, destination in ipairs(destinations) do
        table.insert(entries, { label = destination[1], tele = destination[2], indent = 1, detail = destination[5] or (index == 1 and "Area" or "Town / hub") })
    end
    self:Display(entries); self:Message("Select a red destination marker or use the list"); self:RenderMap()
end

function T:ShowWorld()
    self.category, self.continentKey, self.selectedZone, self.zoom = "world", "world", nil, 1; self:SetBreadcrumb(nil)
    local entries = { { label = "CONTINENTS", header = true } }
    for _, key in ipairs({ "ek", "kalimdor", "outland", "northrend" }) do table.insert(entries, { label = CONTINENTS[key].label, continent = key, arrow = ">  ", detail = "Open" }) end
    table.insert(entries, { label = "MAIN CAPITALS", header = true })
    for _, capital in ipairs(CAPITALS) do
        if destinationAllowed(capital[2]) then table.insert(entries, { label = capital[1], tele = capital[2], indent = 1 }) end
    end
    self:Display(entries); self:Message("Click a continent on the map; use the Outland button for Outland"); self:RenderMap()
end

function T:ShowInstances(kind, selection, minimum, maximum)
    self.category, self.continentKey = kind, nil; self:SetBreadcrumb(kind == "dungeons" and "Dungeons" or "Raids")
    local level = UnitLevel("player") or 1; local entries = {}
    if kind == "dungeons" then
        local expansion = dungeonExpansion(selection)
        if expansion and minimum then
            self:SetBreadcrumb("Dungeons  >  " .. expansion.label .. "  >  Level " .. minimum .. "-" .. maximum)
            table.insert(entries, { label = "<  " .. expansion.label .. " level ranges", dungeonExpansion = expansion.key })
            table.insert(entries, { label = "LEVEL " .. minimum .. (minimum == maximum and "" or (" - " .. maximum)), header = true })
            for _, item in ipairs(DUNGEONS[expansion.key]) do
                if item[3] >= minimum and item[3] <= maximum then
                    table.insert(entries, { label = item[1], tele = item[2], indent = 1, detail = item[3] .. "-" .. item[4] })
                end
            end
        elseif expansion then
            self:SetBreadcrumb("Dungeons  >  " .. expansion.label)
            table.insert(entries, { label = "<  All expansions", dungeonHome = true })
            table.insert(entries, { label = expansion.label:upper(), header = true })
            for _, range in ipairs(expansion.ranges) do
                local rangeLabel = range[1] == range[2] and ("Level " .. range[1]) or ("Levels " .. range[1] .. " - " .. range[2])
                table.insert(entries, {
                    label = rangeLabel,
                    dungeonExpansion = expansion.key,
                    dungeonRange = range,
                    arrow = ">  ",
                    detail = level >= range[1] and "" or "Above level",
                })
            end
        else
            table.insert(entries, { label = "DUNGEONS BY EXPANSION", header = true })
            for _, item in ipairs(DUNGEON_EXPANSIONS) do
                table.insert(entries, {
                    label = item.label,
                    dungeonExpansion = item.key,
                    arrow = ">  ",
                    detail = "Levels " .. item.minimum .. "-" .. item.maximum,
                })
            end
        end
        self:Message("Dungeons grouped by expansion and recommended level")
    else
        minimum = selection
        if minimum then
            table.insert(entries, { label = "<  All raid tiers", raidHome = true })
            table.insert(entries, { label = "LEVEL " .. minimum .. " RAIDS", header = true })
            for _, item in ipairs(RAIDS) do if item[3] == minimum then table.insert(entries, { label = item[1], tele = item[2], indent = 1, detail = "Level " .. item[3] }) end end
        else
            table.insert(entries, { label = "RAIDS BY TIER", header = true })
            for _, tier in ipairs({ { 60, "Classic" }, { 70, "Outland" }, { 80, "Northrend" } }) do
                if level >= tier[1] - 10 then table.insert(entries, { label = tier[2] .. " raids", raidLevel = tier[1], arrow = ">  ", detail = "Level " .. tier[1] }) end
            end
        end
        self:Message("Raid destinations by expansion tier")
    end
    self:Display(entries); self:RenderMap()
end

function T:Request(search, offset)
    local continent = CONTINENTS[self.continentKey]
    if not continent or not MultiBot.Comm or not MultiBot.Comm.RequestTeleports then self:Message("Teleport bridge unavailable"); return end
    self.pendingLabel = search or ""
    self.pendingSearch = self.pendingLabel:gsub("[^%w]", "")
    self.offset = math.max(0, tonumber(offset) or 0); self.loadingPins = nil
    self.search:SetText(self.pendingLabel); self.zoom = 3; self:RenderMap(); self:Message("Loading " .. self.pendingLabel .. "...")
    MultiBot.Comm.RequestTeleports(self.pendingSearch, continent.mapId, self.offset)
end

function T:LoadMapPins(key)
    local continent = CONTINENTS[key]
    if not continent or not MultiBot.Comm or not MultiBot.Comm.RequestTeleports then return end
    self.loadingPins, self.pinLoadKey, self.pinLoadItems = true, key, {}
    MultiBot.Comm.RequestTeleports("", continent.mapId, 0)
end

function T:Build()
    if self.frame then return self.frame end
    local frame = CreateFrame("Frame", "MultiBotTeleportBrowser", UIParent)
    frame:SetSize(1000, 660); frame:SetPoint("CENTER"); frame:SetFrameStrata("DIALOG"); frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end); frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    frame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, insets = { left = 8, right = 8, top = 8, bottom = 8 } })
    frame:SetBackdropColor(0, 0, 0, .97)
    frame:Hide(); self.frame = frame
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); title:SetPoint("TOP", 0, -16); title:SetText("AzerothCore Teleport Browser"); bumpFont(title)
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton"); close:SetPoint("TOPRIGHT", -5, -5)
    self.search = CreateFrame("EditBox", nil, frame, "InputBoxTemplate"); self.search:SetSize(245, 25); self.search:SetPoint("TOPLEFT", 25, -47); self.search:SetAutoFocus(false); bumpFont(self.search)
    self.search:SetScript("OnEnterPressed", function(self) self:ClearFocus(); T:Request(self:GetText(), 0) end)
    local searchButton = makeButton(frame, "Search", 65, 25); searchButton:SetPoint("LEFT", self.search, "RIGHT", 7, 0); searchButton:SetScript("OnClick", function() T:Request(T.search:GetText(), 0) end)
    local back = makeButton(frame, "Back", 65, 25); back:SetPoint("LEFT", searchButton, "RIGHT", 10, 0); back:SetScript("OnClick", function() if T.continentKey then T:ShowContinent(T.continentKey) else T:ShowWorld() end end)
    local home = makeButton(frame, "Home", 65, 25); home:SetPoint("LEFT", back, "RIGHT", 7, 0); home:SetScript("OnClick", function() T:ShowWorld() end)
    self.closeAfterTeleport = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate"); self.closeAfterTeleport:SetSize(24, 24); self.closeAfterTeleport:SetPoint("TOPRIGHT", -202, -47)
    self.closeAfterTeleport:SetChecked(getCloseAfterTeleport())
    self.closeAfterTeleport.text = self.closeAfterTeleport:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); self.closeAfterTeleport.text:SetPoint("LEFT", self.closeAfterTeleport, "RIGHT", 2, 1); self.closeAfterTeleport.text:SetText("Close after teleport"); bumpFont(self.closeAfterTeleport.text)
    self.closeAfterTeleport:SetScript("OnClick", function(self) setCloseAfterTeleport(self:GetChecked()) end)
    self.closeAfterTeleport:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText("Close after teleport"); GameTooltip:AddLine("Altbots are summoned one second after every teleport.", 1, 1, 1, true); GameTooltip:Show()
    end)
    self.closeAfterTeleport:SetScript("OnLeave", function() GameTooltip:Hide() end)
    self.breadcrumb = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal"); self.breadcrumb:SetPoint("TOPLEFT", 25, -82); bumpFont(self.breadcrumb)
    local world = makeButton(frame, "WORLD", 95, 26); world:SetPoint("TOPLEFT", 25, -105); world:SetScript("OnClick", function() T:ShowWorld() end)
    local dungeons = makeButton(frame, "DUNGEONS", 105, 26); dungeons:SetPoint("LEFT", world, "RIGHT", 6, 0); dungeons:SetScript("OnClick", function() T:ShowInstances("dungeons") end)
    local raids = makeButton(frame, "RAIDS", 90, 26); raids:SetPoint("LEFT", dungeons, "RIGHT", 6, 0); raids:SetScript("OnClick", function() T:ShowInstances("raids") end)

    local leftPanel = CreateFrame("Frame", nil, frame); leftPanel:SetPoint("TOPLEFT", 18, -96); leftPanel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", 365, 62)
    leftPanel:SetFrameLevel(frame:GetFrameLevel()); leftPanel:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
    leftPanel:SetBackdropColor(.015, .02, .025, .94); leftPanel:SetBackdropBorderColor(.55, .42, .18, 1)

    self.rows = {}
    for index = 1, VISIBLE_ROWS do
        local row = CreateFrame("Button", nil, frame); row:SetSize(330, 24); row:SetPoint("TOPLEFT", 25, -141 - (index - 1) * 24); row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); row.name:SetPoint("LEFT", 5, 0); row.name:SetWidth(245); row.name:SetJustifyH("LEFT"); bumpFont(row.name)
        row.detail = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall"); row.detail:SetPoint("RIGHT", -4, 0); bumpFont(row.detail)
        row:SetScript("OnClick", function(self)
            local item = self.item; if not item then return end
            if item.tele then teleport(item.tele) elseif item.continent then T:ShowContinent(item.continent) elseif item.group then T:ShowRegion(item.group)
            elseif item.zone then T:ShowZone(item.zone) elseif item.search then T:Request(item.search, 0)
            elseif item.dungeonExpansion and item.dungeonRange then T:ShowInstances("dungeons", item.dungeonExpansion, item.dungeonRange[1], item.dungeonRange[2])
            elseif item.dungeonExpansion then T:ShowInstances("dungeons", item.dungeonExpansion) elseif item.dungeonHome then T:ShowInstances("dungeons")
            elseif item.raidLevel then T:ShowInstances("raids", item.raidLevel) elseif item.raidHome then T:ShowInstances("raids") elseif item.back then T:ShowContinent(T.continentKey) end
        end)
        self.rows[index] = row
    end

    self.mapScroll = CreateFrame("ScrollFrame", nil, frame); self.mapScroll:SetSize(VIEW_W, VIEW_H); self.mapScroll:SetPoint("TOPRIGHT", -25, -105); self.mapScroll:EnableMouse(true); self.mapScroll:EnableMouseWheel(true)
    self.mapScroll:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } }); self.mapScroll:SetBackdropColor(.02, .03, .05, 1)
    self.mapContent = CreateFrame("Frame", nil, self.mapScroll); self.mapContent:SetSize(VIEW_W, VIEW_H); self.mapScroll:SetScrollChild(self.mapContent)
    self.mapTiles = {}
    for index = 1, 12 do local tile = self.mapContent:CreateTexture(nil, "BACKGROUND"); self.mapTiles[index] = tile end
    self.mapHighlight = self.mapContent:CreateTexture(nil, "ARTWORK"); self.mapHighlight:Hide()
    self.mapAreaLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal"); self.mapAreaLabel:SetPoint("BOTTOMRIGHT", self.mapScroll, "TOPRIGHT", 0, 10)
    self.mapAreaLabel:SetWidth(310); self.mapAreaLabel:SetJustifyH("RIGHT"); self.mapAreaLabel:SetText("Region: —"); bumpFont(self.mapAreaLabel)
    self.outlandButton = makeButton(self.mapContent, "OUTLAND", 115, 28); self.outlandButton:SetPoint("BOTTOM", self.mapContent, "BOTTOM", 0, 18)
    self.outlandButton:SetScript("OnClick", function() T:ShowContinent("outland") end)
    self.outlandButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText("Outland"); GameTooltip:AddLine("Click to open Outland", .4, 1, .4); GameTooltip:Show()
    end)
    self.outlandButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
    self.mapHint = self.mapScroll:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); self.mapHint:SetPoint("CENTER"); self.mapHint:SetText("Choose a continent"); bumpFont(self.mapHint)
    self.pins, self.explorationTiles = {}, {}; self.zoom = 1; self.mapWidth, self.mapHeight = VIEW_W, VIEW_H
    self.mapScroll:SetScript("OnMouseWheel", function(_, delta) T:SetZoom(T.zoom + (delta > 0 and 1 or -1)) end)
    self.mapScroll:SetScript("OnMouseDown", function(self)
        local scale = UIParent:GetEffectiveScale(); local x, y = GetCursorPosition(); T.dragX, T.dragY = x / scale, y / scale; T.dragH, T.dragV = self:GetHorizontalScroll(), self:GetVerticalScroll(); T.dragMoved, T.dragging = nil, true
    end)
    self.mapScroll:SetScript("OnMouseUp", function()
        local clicked = T.dragging and not T.dragMoved
        T.dragging = nil
        if clicked then T:HandleNativeMapClick() end
    end)
    self.mapScroll:SetScript("OnUpdate", function(self, elapsed)
        T:UpdateNativeMapHighlight(elapsed)
        if not T.dragging then return end
        local scale = UIParent:GetEffectiveScale(); local x, y = GetCursorPosition(); x, y = x / scale, y / scale
        if math.abs(x - T.dragX) > 4 or math.abs(y - T.dragY) > 4 then T.dragMoved = true end
        self:SetHorizontalScroll(math.max(0, math.min(T.mapWidth - VIEW_W, T.dragH - (x - T.dragX))))
        self:SetVerticalScroll(math.max(0, math.min(T.mapHeight - VIEW_H, T.dragV + (y - T.dragY))))
    end)
    local zoomOut = makeButton(frame, "-", 28, 24); zoomOut:SetPoint("TOPRIGHT", self.mapScroll, "TOPRIGHT", -9, -10); zoomOut:SetScript("OnClick", function() T:SetZoom(T.zoom - 1) end)
    local zoomIn = makeButton(frame, "+", 28, 24); zoomIn:SetPoint("TOPRIGHT", zoomOut, "BOTTOMRIGHT", 0, -4); zoomIn:SetScript("OnClick", function() T:SetZoom(T.zoom + 1) end)
    self.zoomText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); self.zoomText:SetPoint("TOPRIGHT", zoomIn, "BOTTOMRIGHT", 0, -5); self.zoomText:SetText("Zoom 1/3"); bumpFont(self.zoomText)
    local previous = makeButton(frame, "Previous", 75, 24); previous:SetPoint("BOTTOMLEFT", 25, 25); previous:SetScript("OnClick", function() if T.offset > 0 then T:Request(T.pendingSearch, math.max(0, T.offset - PAGE_SIZE)) end end)
    local nextButton = makeButton(frame, "Next", 75, 24); nextButton:SetPoint("LEFT", previous, "RIGHT", 7, 0); nextButton:SetScript("OnClick", function() if T.offset + PAGE_SIZE < T.total then T:Request(T.pendingSearch, T.offset + PAGE_SIZE) end end)
    self.pageText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal"); self.pageText:SetPoint("LEFT", nextButton, "RIGHT", 10, 0); bumpFont(self.pageText)
    self.status = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); self.status:SetPoint("BOTTOMRIGHT", -25, 31); self.status:SetWidth(610); self.status:SetJustifyH("RIGHT"); bumpFont(self.status)
    return frame
end

function T:Toggle()
    local frame = self:Build()
    if frame:IsShown() then frame:Hide() else frame:Show(); self:ShowWorld() end
end

function MultiBot.OnBridgeTeleports(result)
    if T.loadingPins then
        if T.pinLoadKey ~= T.continentKey then T.loadingPins = nil; return end
        for _, item in ipairs(result.items or {}) do table.insert(T.pinLoadItems, item) end
        local nextOffset = (result.offset or 0) + (result.pageSize or 40)
        if nextOffset < (result.total or 0) and nextOffset < 240 then
            MultiBot.Comm.RequestTeleports("", CONTINENTS[T.pinLoadKey].mapId, nextOffset)
        else
            T.serverItems, T.loadingPins = T.pinLoadItems, nil; T:RenderMap()
        end
        return
    end
    T.serverItems = result.items or {}; local entries = { { label = (T.pendingLabel or "DESTINATIONS"):upper(), header = true } }
    for _, item in ipairs(T.serverItems) do
        if destinationAllowed(item.name) then table.insert(entries, { label = item.name, tele = item.name, detail = "Teleport" }) end
    end
    T:Display(entries, result.total, result.offset); T:Message((result.total or #entries) .. " matching destinations"); T:RenderMap()
end

function MultiBot.OnBridgeTeleportsError(reason)
    T:Message(reason == "UNAUTHORIZED" and "Your account cannot use .tele" or ("Teleport error: " .. tostring(reason)))
end

function MultiBot.InitializeTeleportBrowser() return T:Build() end
