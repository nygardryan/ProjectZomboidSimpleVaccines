Distributions = Distributions or {};

local distributionTable = {

    -- =====================
    --    Room List (A-Z)
    -- =====================




    -- pharmacy = {
    --     isShop = true,
    --     counter = {
    --         procedural = true,
    --         procList = {
    --             {name="MedicalClinicDrugs", min=0, max=99, weightChance=100},
    --             {name="StoreCounterCleaning", min=0, max=99, forceForTiles="location_shop_accessories_01_0;location_shop_accessories_01_1;location_shop_accessories_01_2;location_shop_accessories_01_3;location_shop_accessories_01_20;location_shop_accessories_01_21;location_shop_accessories_01_22;location_shop_accessories_01_23;fixtures_sinks_01_0;fixtures_sinks_01_1;fixtures_sinks_01_2;fixtures_sinks_01_3;fixtures_sinks_01_4;fixtures_sinks_01_5;fixtures_sinks_01_6;fixtures_sinks_01_7;fixtures_sinks_01_8;fixtures_sinks_01_9;fixtures_sinks_01_10;fixtures_sinks_01_11;fixtures_sinks_01_16;fixtures_sinks_01_17;fixtures_sinks_01_18;fixtures_sinks_01_19"},
    --             {name="StoreCounterBags", min=0, max=1, weightChance=10},
    --         }
    --     },
    --     fridge = {
    --         procedural = true,
    --         procList = {
    --             {name="FridgeSnacks", min=0, max=2, weightChance=100},
    --             {name="FridgeSoda", min=0, max=6, weightChance=100},
    --             {name="FridgeWater", min=0, max=4, weightChance=100},
    --             {name="FridgeOther", min=0, max=2, weightChance=100},
    --         }
    --     },
    --     freezer = {
    --         rolls = 0,
    --         items = {

    --         }
    --     },
    --     metal_shelves = {
    --         procedural = true,
    --         procList = {
    --             {name="MedicalStorageDrugs", min=1, max=6, weightChance=100},
    --             {name="MedicalStorageTools", min=1, max=4, weightChance=100},
    --             {name="MedicalStorageOutfit", min=1, max=2, weightChance=100},
    --         }
    --     },
    --     shelves = {
    --         procedural = true,
    --         procList = {
    --             {name="PharmacyCosmetics", min=1, max=4, weightChance=60},
    --             {name="StoreShelfCombo", min=0, max=99, forceForTiles="location_shop_generic_01_0;location_shop_generic_01_1"},
    --             {name="StoreShelfDrinks", min=1, max=4, weightChance=40},
    --             {name="StoreShelfSnacks", min=1, max=4, weightChance=40},
    --             {name="StoreShelfMedical", min=4, max=24, weightChance=100},
    --         }
    --     },
    -- },

    -- =====================
    --        CACHES
    -- =====================
    MedicalCache1 = {
        MedicalBox = {
            rolls = 2,
            items = {
                "FAVACC.ConcentratedZombieCells"
            }
            }
        }
    }


    

table.insert(Distributions, 1, distributionTable);

--for mod compat:
SuburbsDistributions = distributionTable;