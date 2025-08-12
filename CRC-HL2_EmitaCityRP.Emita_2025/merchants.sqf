// merchants.sqf
if (!isServer) exitWith {};

[] spawn {
    // --- Config ---
    private _merchantClass = "HL_CIV_Man_01";
    private _spawnRadius   = 100;
    private _despawnGrace  = 30;
    private _tokenClass    = "VRP_HL_Token_Item";
    private _packClass     = "Combaine_backpack_NB";

    // --- Stock ---
    private _stock_equip = [
        ["Binocular","Binoculars",4],
        ["ItemRadio","Radio",6],
        ["ItemMap","Map",2],
        ["ItemGPS","GPS",4],
        ["ItemAndroid","Android",4],
        ["Rugged Tablet","Ctab",4],
        ["Toolkit","Toolkit",8],
        ["ACE_Flashlight_XL50","XL50 Flashlight",3],
        ["Civilian_Jumpsuit_2","Luxury Jumpsuit",10],
        ["H_Watchcap_blk","Beanie",1],
        ["H_Cap_grn","Cap",1],
        ["H_Construction_basic_orange_F","Hard Hat",3],
        ["Rugged Tablet","CTab",4],
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

    // Price roll per merchant (with RationStock influence)
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
        // (server function doesn't need publicVariable)
    };

    // CLIENT: add the actions to a merchant (MUST be published so clients know it)
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
                        ["BUY", _merchant, _caller, _cls, _name, _price] remoteExecCall ["MRC_fnc_merchantServer", 2];
                    },
                    [_m,_cls,_name,_price],
                    1.5, true, true, "",
                    "_this distance _target < 4"
                ];
            } forEach _entries;

            _m addAction [
                "<t color='#88CCFF'>Check Token Balance</t>",
                {
                    params ["_t","_caller"];
                    private _c = { _x == 'VRP_HL_Token_Item' } count (items _caller);
                    hintSilent format ["You have %1 token(s).", _c];
                },
                nil, 1.5, true, true, "",
                "_this distance _target < 4"
            ];

            _m addAction [
                "<t color='#A0FFA0'>Access Merchant Pack</t>",
                {
                    params ["_t","_caller"];
                    private _pack = unitBackpack _t;
                    if (isNull _pack) exitWith { hint "Merchant has no backpack." };
                    _caller action ["Gear", _pack];
                },
                nil, 1.5, true, true, "",
                "_this distance _target < 4"
            ];
        };
        publicVariable "MRC_fnc_addMerchantActions";   // <-- THIS was missing
    };
	
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

        removeUniform _unit;
        switch (_type) do {
            case "equip": { _unit forceAddUniform "Civilian_Jumpsuit_4"; };
            case "medic": { _unit forceAddUniform "Civilian_Jumpsuit_3"; };
            default      { _unit forceAddUniform "Civilian_Jumpsuit_2"; };
        };

        removeBackpack _unit;
        _unit addBackpack _packClass;

        private _stock = switch (_type) do {
            case "equip": { _stock_equip };
            case "medic": { _stock_medic };
            default      { _stock_food  };
        };
        private _count   = 4 + floor random 3;
        private _entries = ([_stock,_count] call _rollInventory);

        // Add actions on every client (and JIP)
        [_unit, _entries] remoteExec ["MRC_fnc_addMerchantActions", 0, true];

        _unit
    };

    // Live registry: [markerName, unit, lastSeenTime]
    private _live = [];

    while { true } do {
        private _equipMarkers = allMapMarkers select { toLower _x find "merchant_equip_" == 0 };
        private _medicMarkers = allMapMarkers select { toLower _x find "merchant_medic_" == 0 };
        private _foodMarkers  = allMapMarkers select { toLower _x find "merchant_food_"  == 0 };

        private _process = {
            params ["_markers","_type"];
            {
                private _m   = _x;
                private _pos = getMarkerPos _m;
                private _near = allPlayers select { alive _x && (_x distance2D _pos) < _spawnRadius };

                private _idx = _live findIf { (_x select 0) == _m };
                private _has = _idx >= 0;

                if ((count _near) > 0 && !_has) then {
                    private _u = [_m,_type] call _spawnOne;
                    _live pushBack [_m,_u,time];
                };

                if ((count _near) > 0 && _has) then {
                    (_live select _idx) set [2, time];
                };

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

        [_equipMarkers,"equip"] call _process;
        [_medicMarkers,"medic"] call _process;
        [_foodMarkers,"food"]   call _process;

        sleep 5;
    };
};
