require "Items/ProceduralDistributions"
require "Items/Distributions"

-- Simple Vaccines (Build 42) loot.
-- Every insert is guarded so a renamed/removed list in a future game update can't break loading.

local function addProc(listName, item, weight)
    local list = ProceduralDistributions.list[listName]
    if list and list.items then
        table.insert(list.items, item)
        table.insert(list.items, weight)
    end
end

local function addZombie(outfit, item, weight)
    local all = SuburbsDistributions and SuburbsDistributions["all"]
    local list = all and all[outfit]
    if list and list.items then
        table.insert(list.items, item)
        table.insert(list.items, weight)
    end
end

local EMPTY = "FAVACCINE.EmptySyringe"
local DIRTY = "FAVACCINE.DirtySyringe"

-- Empty syringes: clinics, hospitals, labs, pharmacies, safehouses (original lists)
addProc("MedicalClinicDrugs", EMPTY, 30)
addProc("MedicalClinicOutfit", EMPTY, 30)
addProc("MedicalStorageDrugs", EMPTY, 35)
addProc("MedicalStorageOutfit", EMPTY, 15)
addProc("MedicalStorageTools", EMPTY, 15)
addProc("SafehouseMedical", EMPTY, 25)
addProc("ScienceMisc", EMPTY, 15)
addProc("TestingLab", EMPTY, 15)
addProc("MedicalClinicTools", EMPTY, 10)
addProc("StoreShelfMedical", EMPTY, 10)
addProc("ArmyStorageMedical", EMPTY, 10)
addProc("BathroomCabinet", EMPTY, 2)
addProc("BathroomCounter", EMPTY, 2)
addProc("BathroomShelf", EMPTY, 2)
addProc("HospitalLockers", EMPTY, 20)

-- Empty syringes: Build 42 medical containers
addProc("HospitalRoomCounter", EMPTY, 10)
addProc("HospitalRoomShelves", EMPTY, 8)
addProc("MedicalCabinet", EMPTY, 10)
addProc("MedicalOfficeCounter", EMPTY, 6)
addProc("DoctorTools", EMPTY, 15)
addProc("AmbulanceDriverTools", EMPTY, 15)
addProc("MorgueTools", EMPTY, 10)
addProc("LaboratoryLockers", EMPTY, 6)
addProc("ArmyBunkerMedical", EMPTY, 10)
addProc("SafehouseMedical_Mid", EMPTY, 15)
addProc("SafehouseMedical_Late", EMPTY, 15)
addProc("DrugLabSupplies", EMPTY, 15)

-- Dirty syringes: bins, prisons, drug labs
addProc("BinDumpster", DIRTY, 20)
addProc("BinGeneric", DIRTY, 4)
addProc("BinBar", DIRTY, 5)
addProc("PrisonCellRandom", DIRTY, 4)
addProc("BinHospital", DIRTY, 15)
addProc("DrugLabSupplies", DIRTY, 10)

-- Zombies in medical outfits sometimes carry a syringe
addZombie("Outfit_Doctor", EMPTY, 8)
addZombie("Outfit_Nurse", EMPTY, 8)
addZombie("Outfit_AmbulanceDriver", EMPTY, 6)
addZombie("Outfit_Pharmacist", EMPTY, 4)
