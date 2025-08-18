// merchants.sqf
if (!isServer) exitWith {};

if (isNil "MRC_fnc_facePlayer") then {
    MRC_fnc_facePlayer = {
        params ["_npc", "_caller"];
        if (isNull _npc || isNull _caller) exitWith {};
        _npc setDir ([_npc, _caller] call BIS_fnc_dirTo);
    };
};

[] spawn {
    // --- Config ---
    private _merchantClass = "HL_CIV_Man_01";
    private _spawnRadius   = 100;
    private _despawnGrace  = 30;
    private _tokenClass    = "VRP_HL_Token_Item";
    private _packClass     = "Combaine_backpack_NB";
	private _outlandsSpawnChance = 0.4;   // 50% chance to spawn when players are near
	private _outlandsDeny = [];           // [markerName, denyUntilTime] so we don't re-roll too often


    // --- Stock ---
    private _stock_equip = [
        ["Binocular","Binoculars",4],
        ["ItemRadio","Radio",6],
        ["ItemMap","Map",2],
        ["ItemGPS","GPS",4],
        ["ItemAndroid","Android",4],
        ["ItemcTab","Rugged Tablet",4],
        ["Toolkit","Toolkit",8],
        ["ACE_Flashlight_XL50","XL50 Flashlight",3],
        ["Civilian_Jumpsuit_2","Luxury Jumpsuit",10],
        ["H_Watchcap_blk","Beanie",1],
        ["H_Cap_grn","Cap",1],
        ["H_Construction_basic_orange_F","Hard Hat",3],
        ["B_Bag_Sundown","UU Bag",5],
        ["Civ_Backpack_1","UU Throwbag",5],
        ["Civ_Backpack_2","Satchel Bag",3],
        ["B_FieldPack_khk","Field Pack",7],
        ["G_Squares","Spectacles",1],
        ["rds_weap_latarka_janta","Janta Flashlight",1],
        ["ACE_Cellphone","Cellphone",3]
    ];
    private _stock_medic = [
        ["FirstAidKit","First Aid Kit",3],
        ["Medikit","Medikit",8],
        ["Medikit_Civilian_01","Medikit (Civ)",6],
        ["WBK_Health_Bandage","Bandage",1]
    ];
    private _stock_food = [
        ["ACE_Canteen","Canteen",5],
        ["VRP_HL2_BreenWater","Breen Water",2],
        ["VRP_HL2_RedWater","Breen Water (Red)",3],
        ["VRP_HL2_YellowWater","Breen Water (Gold)",4],
        ["VRP_Humanitarian_Ration_Item","Water Flavored Ration",3],
        ["VRP_Loyalist_Ration_Item","Egg Flavored Rations",4],
        ["VRP_Loyalist2_Ration_Item","Noodle Flavored Rations",5]
    ];
    private _stock_outlands = [
		["WBK_CP_HeavySmg_Resist","Heavy SMG (Resist)",18],
		["hlc_rifle_ak47","AK-47",20],
		["hlc_rifle_ak74_dirty2","AK-74 (Worn)",18],
		["hlc_rifle_ak74m","AK-74M",25],
		["hlc_rifle_ak74m_gl","AK-74M GL",30],
		["hlc_rifle_akm","AKM",25],
		["hlc_rifle_akmgl","AKM GL",27],
		["hlc_rifle_aks74","AKS-74",30],
		["hlc_rifle_aks74_GL","AKS-74 GL",35],
		["hlc_rifle_aks74u","AKS-74U",32],
		["hlc_rifle_RPK12","RPK-12",40],
		["launch_RPG7_F","RPG-7 Launcher",50],
		["optic_MRCO","MRCO Optic",15],
		["hlc_optic_kobra","Kobra Sight",12],
		["hlc_optic_VOMZ","VOMZ Optic",15],
		["HLC_optic_ISM1400A7","ISM1400A7 Optic",18],
		["hlc_optic_LeupoldM3A","Leupold M3A Optic",20],
		["HLC_Optic_PSO1","PSO-1 Scope",18],
		["HLC_Optic_1p29","1P29 Scope",16],
		["hlc_optic_VOMZ3d","VOMZ 3D Optic",17],
		["hlc_optic_HensoldtZO_lo_Docter","HensoldtZO Docter Optic",22],
		["HLC_optic_Aimpoint3000","Aimpoint 3000",15],
		["HLC_optic_Aimpoint3000_Magnifier","Aimpoint 3000 + Magnifier",18],
		["HLC_optic_Aimpoint5000","Aimpoint 5000",16],
		["HLC_optic_Aimpoint5000_Magnifier","Aimpoint 5000 + Magnifier",19],
		["hlc_acc_AIM1D_Generic","AIM1D Laser",8],
		["HLC_Charm_Teethgang","Weapon Charm: Teethgang",5],
		["HLC_Charm_Izhmash","Weapon Charm: Izhmash",5],
		["acc_pointer_IR","IR Pointer",7],
		["HLC_Charm_Herstal","Weapon Charm: Herstal",5],
		["RPG7_F","PG-7VM HEAT Rocket",10],
		["ACE_acc_pointer_green","Green Laser Pointer",7],
		["hlc_30Rnd_762x39_b_ak","30Rnd 7.62mm AK Mag",3],
		["hlc_30Rnd_545x39_B_AK","30Rnd 5.45mm AK Mag",3],
		["hlc_45Rnd_545x39_b_rpkm","45Rnd 5.45mm RPK Mag",4],
		["hlc_60Rnd_545x39_b_rpk","60Rnd 5.45mm RPK Mag",5],
		["hlc_40Rnd_762x39_b_rpk","40Rnd 7.62mm RPK Mag",4],
		["hlc_75Rnd_762x39_b_rpk","75Rnd 7.62mm RPK Drum",6],
		["hlc_75Rnd_762x39_AP_rpk","75Rnd AP 7.62mm RPK Drum",8],
		["H_bms_helmet_1","BMS Helmet",10],
		["H_hecu_pasgt_urban_nvo_strap_swdg","Urban PASGT Helmet",10],
		["HL_RES_U_Rebel_03","Rebel Uniform 03",5],
		["HL_RES_U_Rebel_02","Rebel Uniform 02",5],
		["HL_RES_U_Rebel_01","Rebel Uniform 01",5],
		["HL_RES_U_Rebel_Medic","Rebel Medic Uniform",5],
		["HL_RES_U_HEV_MK5","HEV Mk5 Suit",100],
		["Crowbar","Crowbar",5],
		["VRP_HoundMeat","Houndeye Meat",2],
		["VRP_HeadcrabMeat","Headcrab Meat",2],
		["VRP_AntlionMeat","Antlion Meat",2],
		["ACE_MRE_MeatballsPasta","MRE: Meatballs and Pasta",2],
		["ACE_Canteen","Canteen",3],
		["ACE_WaterBottle","Water Bottle",2],
		["ToolKit","Toolkit",10],
		["Medikit","Medikit",10],
		["FirstAidKit","First Aid Kit",2],
		["ACE_EntrenchingTool","Entrenching Tool",3],
		["ACE_DefusalKit","Defusal Kit",5],
		["ACE_DeadManSwitch","Dead Man's Switch",5],
		["ACE_CableTie","Cable Tie",1]
    ];

    // Price roll per merchant
    private _rollInventory = {
        params ["_stock","_count"];
        private _pool = +_stock call BIS_fnc_arrayShuffle;
        private _pick = _pool select [0, _count min (count _pool)];
        private _out  = [];

        private _rationStock = missionNamespace getVariable ["RationStock", 0];
        private _rationMod = 0;
        switch (true) do {
            case (_rationStock < 10):                        { _rationMod = 3; };
            case (_rationStock >= 10 && _rationStock < 20):  { _rationMod = 2; };
            case (_rationStock >= 20 && _rationStock < 30):  { _rationMod = 1; };
            case (_rationStock >= 30 && _rationStock < 60):  { _rationMod = 0; };
            case (_rationStock >= 60 && _rationStock <= 80): { _rationMod = -1; };
            case (_rationStock > 80):                        { _rationMod = -2; };
        };

        {
            private _cls  = _x select 0;
            private _name = _x select 1;
            private _base = _x select 2;
            private _p = _base + _rationMod + ((floor (random 5)) - 2); // ±2
            if (_p < 1) then { _p = 1 };
            _out pushBack [_cls,_name,_p];
        } forEach _pick;

        _out
    };

    // === DEFINE HELPERS FIRST ===
    // SERVER: purchase handler (server-only is fine)
    if (isNil "MRC_fnc_merchantServer") then {
        MRC_fnc_merchantServer = {
            params ["_op", "_merchant", "_caller", "_cls", "_name", "_price"];
            if (_op != "BUY") exitWith {};
            if (isNull _merchant || {isNull _caller}) exitWith {};
            if (!alive _caller) exitWith {};
            private _tokens = { _x == "VRP_HL_Token_Item" } count (items _caller);
            if (_tokens < _price) exitWith {
                ["Not enough tokens."] remoteExec ["hintSilent", owner _caller];
            };

            // Take payment
            for "_i" from 1 to _price do { _caller removeItem "VRP_HL_Token_Item"; };

            // Class helpers
            private _isBackpack = (isClass (configFile >> "CfgVehicles" >> _cls)) && { getNumber (configFile >> "CfgVehicles" >> _cls >> "isBackpack") == 1 };
            private _isWeapon   = (isClass (configFile >> "CfgWeapons"  >> _cls)) && { (getNumber (configFile >> "CfgWeapons" >> _cls >> "type")) in [1,2,4,5] };

            // 1) Backpacks: equip on the buyer's client
            if (_isBackpack) exitWith {
                [_caller, _cls] remoteExec ["MRC_fnc_equipBackpack", owner _caller];
                [format ["%1 purchased. New backpack equipped.", _name]] remoteExec ["hintSilent", owner _caller];
            };

            // 2) Weapons: drop at merchant
            if (_isWeapon) exitWith {
                private _pos = getPosATL _merchant;
                private _holder = createVehicle ["GroundWeaponHolder", _pos, [], 0, "NONE"];
                private _p = getPosATL _holder; _p set [2, (_p select 2) + 0.3];
                _holder setPosATL _p;
                _holder addWeaponCargoGlobal [_cls, 1];
                [format ["%1 purchased. Pick it up next to the merchant.", _name]] remoteExec ["hintSilent", owner _caller];
            };

            // 3) Everything else: into merchant’s backpack (or drop if full)
            if (isNull (unitBackpack _merchant)) then { _merchant addBackpack "Combaine_backpack_NB"; };
            private _pack = unitBackpack _merchant;

            private _added = false;
            if (isClass (configFile >> "CfgMagazines" >> _cls)) then {
                _pack addMagazineCargoGlobal [_cls, 1];
                _added = true;
            } else {
                if (isClass (configFile >> "CfgWeapons" >> _cls)) then {
                    private _type = getNumber (configFile >> "CfgWeapons" >> _cls >> "type");
                    if (!(_type in [1,2,4,5])) then { _pack addItemCargoGlobal [_cls, 1]; _added = true; };
                } else {
                    if (isClass (configFile >> "CfgVehicles" >> _cls) && { getNumber (configFile >> "CfgVehicles" >> _cls >> "isBackpack") == 1 }) then {
                        _added = false; // no packs-in-packs
                    } else {
                        _pack addItemCargoGlobal [_cls, 1];
                        _added = true;
                    };
                };
            };

            if (_added) then {
                [format ["%1 purchased. Retrieve it from the merchant’s backpack.", _name]] remoteExec ["hintSilent", owner _caller];
            } else {
                private _pos = getPosATL _merchant;
                private _holder = createVehicle ["GroundWeaponHolder", _pos, [], 0, "NONE"];
                private _p = getPosATL _holder; _p set [2, (_p select 2) + 0.3];
                _holder setPosATL _p;
                if (isClass (configFile >> "CfgMagazines" >> _cls)) then {
                    _holder addMagazineCargoGlobal [_cls, 1];
                } else {
                    _holder addItemCargoGlobal [_cls, 1];
                };
                [format ["%1 purchased. Merchant pack full — item dropped next to the merchant.", _name]] remoteExec ["hintSilent", owner _caller];
            };
        };
        // server fn: no need to publicVariable
    };

    // CLIENT: add the actions to a merchant
    if (isNil "MRC_fnc_addMerchantActions") then {
        MRC_fnc_addMerchantActions = {
            params ["_m", "_entries"];
            if (isNull _m) exitWith {};

            {
                _x params ["_cls","_name","_price"];
                private _title = format ["Buy %1  <t color='#FFD700'>(%2 tokens)</t>", _name, _price];

                _m addAction [
                    _title,
                    {
                        params ["_target","_caller","_actionId","_args"];
                        _args params ["_merchant","_cls","_name","_price"];
                        [_target, _caller] remoteExecCall ["MRC_fnc_facePlayer", 2];
                        ["BUY", _merchant, _caller, _cls, _name, _price] remoteExecCall ["MRC_fnc_merchantServer", 2];
                    },
                    [_m,_cls,_name,_price],
                    1.5, true, true, "",
                    "_this distance _target < 4"
                ];
            } forEach _entries;

            _m addAction [
                "<t color='#A0FFA0'>Access Merchant Pack</t>",
                {
                    params ["_t","_caller"];
                    [_t, _caller] remoteExecCall ["MRC_fnc_facePlayer", 2];
                    private _pack = unitBackpack _t;
                    if (isNull _pack) exitWith { hint "Merchant has no backpack." };
                    _caller action ["Gear", _pack];
                },
                nil, 1.5, true, true, "",
                "_this distance _target < 4"
            ];
        };
        publicVariable "MRC_fnc_addMerchantActions";
    };

    // CLIENT: equip backpack on buyer (runs on buyer's client)
    if (isNil "MRC_fnc_equipBackpack") then {
        MRC_fnc_equipBackpack = {
            params ["_plr","_cls"];
            if (isNull _plr) exitWith {};

            private _old = unitBackpack _plr;
            if (!isNull _old) then {
                private _pos = getPosATL _plr;
                private _holder = createVehicle ["GroundWeaponHolder", _pos, [], 0, "NONE"];
                private _p = getPosATL _holder; _p set [2, (_p select 2) + 0.5];
                _holder setPosATL _p;
                _holder addBackpackCargoGlobal [typeOf _old, 1];
                removeBackpack _plr;
            };

            _plr addBackpack _cls;
        };
        publicVariable "MRC_fnc_equipBackpack";
    };

    // === Spawner ===
    private _spawnOne = {
        params ["_markerName","_type"];

        private _pos = getMarkerPos _markerName;
        private _grp  = createGroup civilian;
        private _unit = _grp createUnit [_merchantClass, _pos, [], 0, "NONE"];

        _unit setDir (random 360);
        _unit setPosATL (_pos vectorAdd [0,0,1]);

        _unit disableAI "MOVE";
        _unit disableAI "PATH";
        _unit disableAI "TARGET";
        _unit disableAI "AUTOTARGET";
        _unit allowFleeing 0;
        _unit setUnitPos "UP";
        _unit switchMove "";
        _unit setBehaviour "SAFE";
        _unit setCaptive true;

        // Uniform by type (Outlands gets a distinct look)
        removeUniform _unit;
        switch (_type) do {
            case "equip":    { _unit forceAddUniform "Civilian_Jumpsuit_4"; };
            case "medic":    { _unit forceAddUniform "Civilian_Jumpsuit_3"; };
            case "outlands": { _unit forceAddUniform "Civilian_Jumpsuit_1"; };
            default          { _unit forceAddUniform "Civilian_Jumpsuit_2"; };
        };

        removeBackpack _unit;
        _unit addBackpack _packClass;

        private _stock = switch (_type) do {
            case "equip":    { _stock_equip };
            case "medic":    { _stock_medic };
            case "outlands": { _stock_outlands };
            default          { _stock_food  };
        };
        private _count   = 4 + floor random 3;
        private _entries;
        if (_type == "outlands") then {
            private _ammo  = _stock select { isClass (configFile >> "CfgMagazines" >> (_x select 0)) };
            private _other = _stock select { !isClass (configFile >> "CfgMagazines" >> (_x select 0)) };
            _entries = ([_other, _count] call _rollInventory);
            _entries append ([_ammo, count _ammo] call _rollInventory);
        } else {
            _entries = ([_stock,_count] call _rollInventory);
        };

        // Add actions on every client (and JIP)
        [_unit, _entries] remoteExec ["MRC_fnc_addMerchantActions", 0, true];

        _unit
    };

    // Live registry: [markerName, unit, lastSeenTime]
    private _live = [];

    while { true } do {
        private _equipMarkers    = allMapMarkers select { toLower _x find "merchant_equip_"    == 0 };
        private _medicMarkers    = allMapMarkers select { toLower _x find "merchant_medic_"    == 0 };
        private _foodMarkers     = allMapMarkers select { toLower _x find "merchant_food_"     == 0 };
        private _outlandsMarkers = allMapMarkers select { toLower _x find "merchant_outlands_" == 0 };

		private _process = {
			params ["_markers","_type"];
			{
				private _m   = _x;
				private _pos = getMarkerPos _m;
				private _near = allPlayers select { alive _x && (_x distance2D _pos) < _spawnRadius };

				private _idx = _live findIf { (_x select 0) == _m };
				private _has = _idx >= 0;

				// Outlands: honor a deny window to avoid reroll spam
				private _denyIdx = -1;
				private _denyActive = false;
				if (_type == "outlands") then {
					_denyIdx = _outlandsDeny findIf { (_x select 0) == _m };
					if (_denyIdx >= 0) then {
						_denyActive = (time < ((_outlandsDeny select _denyIdx) select 1));
					};
				};

				// Try to spawn
				if ((count _near) > 0 && !_has) then {
					private _canSpawn = true;

					if (_type == "outlands") then {
						// if in deny window, skip; otherwise roll chance
						if (_denyActive) then {
							_canSpawn = false;
						} else {
							if !(random 1 < _outlandsSpawnChance) then {
								_canSpawn = false;
								// set/refresh a brief deny window (e.g., 2 minutes)
								private _until = time + 120;
								if (_denyIdx >= 0) then {
									(_outlandsDeny select _denyIdx) set [1, _until];
								} else {
									_outlandsDeny pushBack [_m, _until];
								};
							};
						};
					};

					if (_canSpawn) then {
						private _u = [_m,_type] call _spawnOne;
						_live pushBack [_m,_u,time];
					};
				};

				// Keepalive ping when players nearby
				if ((count _near) > 0 && _has) then {
					(_live select _idx) set [2, time];
				};

				// Despawn if empty for grace period
				if ((count _near) == 0 && _has) then {
					private _entry = _live select _idx;
					if ((time - (_entry select 2)) > _despawnGrace) then {
						private _u = _entry select 1;
						if (!isNull _u) then { deleteVehicle _u };
						_live deleteAt _idx;
					};
				};
			} forEach _markers;
		};


        [_equipMarkers,"equip"]       call _process;
        [_medicMarkers,"medic"]       call _process;
        [_foodMarkers,"food"]         call _process;
        [_outlandsMarkers,"outlands"] call _process;

        sleep 5;
    };
};
