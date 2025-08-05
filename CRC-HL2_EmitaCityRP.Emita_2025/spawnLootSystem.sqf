[] spawn {
    private _markers = allMapMarkers select {["lootzone_", _x] call BIS_fnc_inString};

    while {true} do {
        {
            private _marker = _x;
            private _pos = getMarkerPos _marker;
            private _nearby = allPlayers select {_x distance2D _pos < 100};


            if (count _nearby > 0) then {

                private _isDanger = ["danger", _marker] call BIS_fnc_inString;

                private _lootChance = if (_isDanger) then {0.8} else {0.5};
                private _rebelChance = if (_isDanger) then {0.3} else {0.4};
                private _xenChance   = if (_isDanger) then {0.5} else {0.3};

                private _roll = random 1;

                if (_roll < _lootChance) then {
                    private _box = "Box_FIA_Support_F" createVehicle _pos;
                    clearWeaponCargoGlobal _box;
					private _lootItems = [
							"FirstAidKit",
							"WBK_CP_HeavySmg_Resist",
							"WBK_HSMG_Mag",
							"WBK_BearRebel_Rifle",
							"HL_CivHuntingRifle_Mag",
							"hlc_rifle_ak74_dirty",
							"hlc_30rnd_545x39_B_AK",
							"hlc_Optic_kobra",
							"hlc_Optic_1p29",
							"hlc_Optic_PSO1",
							"HLC_CMB_hgun_USP",
							"HL_CMB_18Rnd_9x19_Mag",
							"Crowbar",
							"GrenadeMolotovPSRUS",
							"Binocular",
							"Itemctab",
							"ItemAndroid",
							"ItemGPS",
							"ItemRadio",
							"M40_Gas_mask_nbc_c2_NVG_02",
							"B_hecu_survival_m81",
							"V_resistance_vest_bms",
							"U_bms_swetr1",
							"H_combine_helmet_1",
							"ACE_CableTie",
							"IEDLandBig_Remote_Mag",
							"IEDUrbanBig_Remote_Mag",
							"IEDLandSmall_Remote_Mag",
							"IEDUrbanSmall_Remote_Mag",
							"SLAMDirectionalMine_Wire_Mag",
							"ACE_Cellphone",
							"VRP_HoundMeat",
							"VRP_HeadcrabMeat",
							"VRP_AntlionMeat",
							"ACE_Banana",
							"VRP_Canteen",
							"VRP_Can_Franta",
							"ACE_Earplugs",
							"VRP_ACE_Clacker",
							"WBK_Health_Bandage",
							"WBK_Health_ArmourPlate"
						];

						private _lootCount = 10 + floor random 10; 

						for "_i" from 1 to _lootCount do {
							_box addItemCargoGlobal [selectRandom _lootItems, 1];
						};
                } else {
                    _roll = random 1;
                    if (_roll < _rebelChance) then {

                        private _rebelTypes = [
                            "WBK_Rebel_SL_1", "WBK_Rebel_Rifleman_3", "WBK_Rebel_Medic_1",
                            "WBK_Rebel_SMG_1", "WBK_Rebel_SMG_2", "WBK_Rebel_Sniper",
                            "WBK_Rebel_Shotgunner", "WBK_Rebel_HL2_RPG"
                        ];

                        private _grp = createGroup east;
                        for "_i" from 1 to (4 + floor random 4) do {
                            _grp createUnit [selectRandom _rebelTypes, _pos, [], 0, "FORM"];
                        };

                        _grp setBehaviour "AWARE";
                        _grp setCombatMode "RED";
                        _grp addWaypoint [_pos vectorAdd [random 20 - 10, random 20 - 10, 0], 0];

                    } else {
                        if (_roll < _xenChance) then {

                            private _xenTypes = [
                                "WBK_Bullsquid_1", "WBK_Houndeye_1", "WBK_Antlion_1",
                                "WBK_ClassicZombie_HLA_9", "WBK_Zombine_HLA_2", "WBK_Headcrab_Normal"
                            ];

                            private _grp = createGroup resistance;
                            for "_i" from 1 to (3 + floor random 3) do {
                                _grp createUnit [selectRandom _xenTypes, _pos, [], 0, "FORM"];
                            };

                            _grp setBehaviour "AWARE";
                            _grp setCombatMode "RED";
                            _grp addWaypoint [_pos vectorAdd [random 20 - 10, random 20 - 10, 0], 0];
                        } else {
                        };
                    };
                };

                deleteMarker _marker;
            };
        } forEach _markers;

        sleep 10;
    };
};
