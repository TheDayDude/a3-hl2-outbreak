[] spawn {
    private _markers = allMapMarkers select {
        private _n = toLower _x;
        (_n find "loot_military_" == 0) ||
        (_n find "loot_medical_"  == 0) ||
        (_n find "loot_food_"     == 0) ||
        (_n find "loot_equipment_"== 0)
    };

    private _lootMilitary = ["WBK_Revolver_HL1_2","WBK_Glock_HL1","Cytech_Makeshift_Argument","HL_CMB_hgun_USP","WBK_CP_HeavySmg_Resist","hlc_rifle_ak74_dirty2","hlc_rifle_M14_Bipod_Rail","hlc_rifle_ACR_SBR_cliffhanger","hlc_rifle_RPK12","hlc_rifle_aks74","WBK_BearRebel_Rifle","hlc_rifle_M4","hlc_optic_goshawk","optic_DMS_s","optic_MRCO","optic_Yorris","hlc_optic_ATACR_Offset","HLC_optic_DocterV","hlc_optic_kobra","hlc_optic_HensoldtZO_Lo","hlc_optic_ZF95Base","HLC_optic_DocterR","hlc_optic_VOMZ","HLC_optic_ISM1400A7","optic_KHS_tan","HLC_optic_RomeoV","hlc_optic_VOMZ3d","optic_SRS","HLC_Optic_PSO1","HLC_Optic_1p29","hlc_optic_LeupoldM3A","HLC_optic_Aimpoint3000_Magnifier","optic_Aco","WBK_BearRebel_Rifle_Scope","hlc_optic_ATACR","hlc_optic_PVS4FAL","hlc_rifle_FAL5000","hlc_smg_mp5k","hlc_pistol_C96_Bolo_Worn_stock","hlc_acc_AIM1D_Generic","HLC_Charm_Teethgang","HLC_Charm_Izhmash","Cytech_flashlight_Normal","acc_pointer_IR","hlc_acc_TLR1","Cytech_flashlight_Bright","HLC_Charm_Herstal","acc_flashlightMax","acc_flashlight_pistol","Cytech_flashlight_Dim","hlc_acc_SF660","hlc_acc_SF660_Barrel","hlc_acc_DBALPL_FL","hlc_acc_LS321G","hlc_acc_DBALPL","hlc_acc_TLR1_Side","hlc_acc_DBALPL_Side","ACE_SPIR","ACE_acc_pointer_green","hlc_acc_DBALPL_side_FL","HLC_bipod_UTGShooters","HLC_ISOPOD","HLC_Bipod_G36","hlc_rifle_G36A1","HL_CivHuntingRifle_Mag","HLB_HSMG_Mag","200Rnd_556x45_Box_Mixed_Tracer_Blue_F","200Rnd_556x45_Box_Tracer_Blue_F","30Rnd_556x45_Stanag_Tracer_Blue","150Rnd_762x51_Box_Mixed_Tracer_Blue","150Rnd_762x51_Box_Tracer_Blue","20Rnd_762x51_Mag_Tracer_Blue","hlc_45Rnd_545x39_b_rpkm","hlc_30Rnd_545x39_B_AK","hlc_60Rnd_545x39_b_rpk","hlc_rifle_akm","hlc_rifle_ak47","hlc_30Rnd_762x39_b_ak","hlc_100rnd_556x45_EPR_G36","hlc_30rnd_556x45_EPR_G36","16Rnd_9x21_Mag","HL_CMB_18Rnd_9x19_Mag","Cytech_14Rnd_9x18_Mag","Cytech_Makeshift_PM","Cytech_Makeshift_APS","Cytech_35Rnd_9x18_Mag","Cytech_6Rnd_45ACP","H_combine_helmet_1","H_bms_helmet_1","H_hecu_pasgt_green_b_nvo","U_BDU_Raid_urban","U_raincoat_urban","U_hecu_mopp","U_BMS_Shirt","U_BDU_Raid_zwart","U_bms_swetr1_trop","U_bms_veldjas_blauw_trop","V_bms_mk56","V_resistance_vest_bms_5","V_resistance_vest_pcv_1","V_resistance_vest_rba","V_bms_vest","V_bms_vest_rig","V_bms_vest_lbv","V_hecu_vest_collar","V_resistance_vest_bms","bms_rebel_asspack","bms_rebel_rearpack","B_hecu_survival_m81","DemoCharge_Remote_Mag","ATMine_Range_Mag","ClaymoreDirectionalMine_Remote_Mag","SatchelCharge_Remote_Mag","SLAMDirectionalMine_Wire_Mag","ACE_M26_Clacker", "launch_RPG7_F", "RPG7_F"];
    private _lootMedical = ["WBK_Health_Bandage","WBK_Health_ArmourPlate","FirstAidKit","Medikit"];
    private _lootFood = ["VRP_AntlionMeat","VRP_HeadcrabMeat","VRP_HoundMeat","VRP_Bread","VRP_Watermelon","VRP_HL_Token_Item","ACE_WaterBottle","ACE_WaterBottle_Half","ACE_Canteen","ACE_Canteen_Half","ACE_Can_Franta","ACE_Can_RedGull","ACE_Can_Spirit","plp_bo_w_BottleTequila","plp_bo_w_BottleLiqOrange","plp_bo_w_BottleGin","plp_bo_w_BottleLiqCream","plp_bo_w_BottleBlueCorazol","plp_bo_w_BottleBitters","ACE_Banana","ACE_MRE_BeefStew","ACE_MRE_ChickenTikkaMasala","ACE_MRE_ChickenHerbDumplings","ACE_MRE_CreamChickenSoup","ACE_MRE_CreamTomatoSoup","ACE_MRE_LambCurry","ACE_MRE_MeatballsPasta","ACE_MRE_SteakVegetables","ACE_Sunflower_Seeds","VRP_Humanitarian_Ration_Item","VRP_HL2_BreenWater"];
    private _lootEquipment = ["H_bms_helmet_1","H_hecu_pasgt_urban_b_nvo","U_bms_civ_jean_grun_tuck","U_bms_civ_jean_khk_tuck","U_bms_civ_jean_rot_tuck","U_bms_civ_jean_blau_tuck","V_resistance_vest_rba","V_resistance_vest_bms","B_simc_rajio_base","B_hecu_survival_m81_2","B_hecu_survival_m81","bms_rebel_rearpack_ass","bms_rebel_asspack","B_Carryall_blk","RDS_Sparewheel_gaz24","B_Kitbag_cbr","RDS_MMT_packed_Civ_01","B_TacticalPack_rgr","G_bms_Nomex_1_lang","M40_Gas_mask_nbc_hood_v6_s","BMS_X800","O_NVGoggles_black","Cyt_Binocular","Binocular","Rangefinder","ItemCompass","ItemRadio","ChemicalDetector_01_watch_F","ItemWatch","ItemGPS","ItemAndroid","ItemMicroDAGR","ItemcTab","GrenadeMolotovPSRUS","SmokeShellRed","ACE_M84","IEDLandSmall_Remote_Mag","IEDUrbanSmall_Remote_Mag","IEDLandBig_Remote_Mag","IEDUrbanBig_Remote_Mag","ACE_CableTie","ACE_Cellphone","ACE_DeadManSwitch","ACE_DefusalKit","ACE_EntrenchingTool","CBRN_gasmaskFilter","ToolKit","ACE_RangeCard","MineDetector","ACE_Flashlight_XL50","ACE_MapTools","plp_bo_w_BottleTequila"];

    private _containersMilitary  = ["Box_FIA_Support_F","Box_Syndicate_Ammo_F","Box_EAF_Wps_F","Box_EAF_Ammo_F", "I_e_CargoNet_01_ammo_F"];
    private _containersMedical   = ["Box_B_UAV_06_medical_F","Box_EAF_Support_F","Hazard_Crate", "Box_B_UAV_06_F"];
    private _containersEquipment = ["Land_WoodenCrate_01_F","Box_EAF_Equip_F","Hazard_Crate", "I_e_CargoNet_01_ammo_F", "Box_B_UAV_06_F"];
    private _containersFood      = ["Land_WoodenCrate_01_F","Hazard_Crate", "Box_B_UAV_06_F"];

    while {true} do {
        {
            private _m = _x;
            private _pos = getMarkerPos _m;

            if ((allPlayers findIf { _x distance2D _pos < 100 }) > -1) then {
                private _nameLower = toLower _m;
                private _pool = [];
                private _containers = [];
                private _count = 0;
                private _spawnChance = 0.3;

                if (_nameLower find "loot_equipment_" == 0) then {
                    _pool = _lootEquipment; _containers = _containersEquipment; _count = 4 + floor random 12; _spawnChance = 0.7;
                } else {
                    if (_nameLower find "loot_medical_" == 0) then {
                        _pool = _lootMedical; _containers = _containersMedical; _count = 3 + floor random 7; _spawnChance = 0.5;
                    } else {
                        if (_nameLower find "loot_food_" == 0) then {
                            _pool = _lootFood; _containers = _containersFood; _count = 1 + floor random 4; _spawnChance = 0.5;
                        } else {
                            if (_nameLower find "loot_military_" == 0) then {
                                _pool = _lootMilitary; _containers = _containersMilitary; _count = 10 + floor random 12; _spawnChance = 0.4;
                            };
                        };
                    };
                };

                if (!(_pool isEqualTo []) && {random 1 < _spawnChance}) then {
                    private _crateClass = selectRandom _containers;
                    private _box = _crateClass createVehicle _pos;

                    clearItemCargoGlobal _box;
                    clearWeaponCargoGlobal _box;
                    clearMagazineCargoGlobal _box;
                    clearBackpackCargoGlobal _box;

                    for "_i" from 1 to _count do {
                        _box addItemCargoGlobal [selectRandom _pool, 1];
                    };

                    if (_nameLower find "loot_military_" == 0 && {random 1 < 0.25}) then {
                        _box addItemCargoGlobal [selectRandom _lootEquipment, 1];
                    };
                    if (_nameLower find "loot_food_" == 0 && {random 1 < 0.20}) then {
                        _box addItemCargoGlobal [selectRandom _lootMedical, 1];
                    };
                };

                deleteMarker _m;
            };
        } forEach _markers;

        sleep 10;
    };
};
