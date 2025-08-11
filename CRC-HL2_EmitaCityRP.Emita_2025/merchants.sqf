// merchants.sqf
if (!isServer) exitWith {};

[] spawn {
    // --- Config (now in-scope for the loop) ---
    private _merchantClass = "HL_CIV_Man_01";
    private _spawnRadius   = 100;   // spawn when player within this distance
    private _despawnGrace  = 30;    // seconds with no players before despawn
    private _tokenClass    = "VRP_HL_Token_Item";

    // --- Stock helpers (classname, display name, base price) ---
    private _stock_equip = [
        ["Binocular","Binoculars",3],
        ["ItemRadio","Radio",5],
        ["ItemMap","Map",1],
        ["ItemGPS","GPS",3],
		["ItemAndroid","Android",3],
		["Rugged Tablet","Ctab",3],
		["Toolkit","Toolkit",7],
		["ACE_Flashlight_XL50","Flashlight",2],
		["Civilian_Jumpsuit_2","Luxury Jumpsuit",10],
		["H_Watchcap_blk","Beanie",1],
		["H_Cap_grn","Cap",1],
		["Rugged Tablet","Ctab",3],
        ["B_Bag_Sundown","Bag",5],
        ["Civ_Backpack_2","Satchel Bag",3],
		["B_FieldPack_khk","Field Pack",7],
		["G_Squares","Spectacles",1],
        ["ACE_Cellphone","Cellphone",3]
    ];
    private _stock_medic = [
        ["FirstAidKit","First Aid Kit",3],
        ["Medikit","Medikit",7],
        ["Medikit_Civilian_01","Medikit (Civ)",5],
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

    // Roll per-merchant inventory
    private _rollInventory = {
        params ["_stock","_count"];
        private _pool = +_stock call BIS_fnc_arrayShuffle;
        private _pick = _pool select [0, _count min (count _pool)];
        private _out = [];
        {
            private _cls = _x select 0;
            private _nam = _x select 1;
            private _base = _x select 2;
            private _p = _base + (floor (random 5)) - 2; // -2..+2
            if (_p < 1) then { _p = 1 };
            _out pushBack [_cls,_nam,_p];
        } forEach _pick;
        _out
    };

    // Add a buy action for one item
	_addBuyAction = {
		params ["_merchant", "_entry"]; // _entry = [className, displayName, price]
		_entry params ["_cls","_name","_price"];

		private _title = format ["Buy %1  <t color='#FFD700'>(%2 tokens)</t>", _name, _price];

		_merchant addAction [
			_title,
			{
				params ["_target","_caller","_actionId","_args"];
				_args params ["_cls","_name","_price"];

				private _tokens = { _x == "VRP_HL_Token_Item" } count items _caller;
				if (_tokens < _price) exitWith {
					hint format ["You need %1 tokens for %2.", _price, _name];
				};

				// Take payment
				for "_i" from 1 to _price do { _caller removeItem "VRP_HL_Token_Item"; };

				// Drop holder at buyer's feet
				private _pos = getPosATL _caller;
				private _holder = createVehicle ["GroundWeaponHolder", _pos, [], 0, "NONE"];

				// Decide how to add the class
				private _added = false;
				if (isClass (configFile >> "CfgMagazines" >> _cls)) then {
					_holder addMagazineCargoGlobal [_cls, 1];
					_added = true;
				} else {
					if (isClass (configFile >> "CfgWeapons" >> _cls)) then {
						_holder addWeaponCargoGlobal [_cls, 1];
						_added = true;
					} else {
						if (
							isClass (configFile >> "CfgVehicles" >> _cls)
							&& { getNumber (configFile >> "CfgVehicles" >> _cls >> "isBackpack") == 1 }
						) then {
							_holder addBackpackCargoGlobal [_cls, 1];
							_added = true;
						} else {
							// Uniforms, vests, headgear, NVGs, misc items
							_holder addItemCargoGlobal [_cls, 1];
							_added = true;
						};
					};
				};

				if (_added) then {
					hint format ["%1 purchased. Dropped at your feet.", _name];
				} else {
					// Fallback refund (shouldn't happen unless bad classname)
					hint "Purchase failed (unknown class). Refunding tokens.";
					for "_i" from 1 to _price do { _caller addItem "VRP_HL_Token_Item"; };
					deleteVehicle _holder;
				};
			},
			[_cls,_name,_price],
			1.5, true, true, "",
			// Optional: limit purchase range to 4m
			"_this distance _target < 4"
		];
	};

    // Spawn one merchant at a marker
	private _spawnOne = {
		params ["_markerName","_type"];

		private _pos = getMarkerPos _markerName;

		private _grp  = createGroup civilian;
		private _unit = _grp createUnit [_merchantClass, _pos, [], 0, "NONE"];

		_unit setDir (random 360);
		_unit setPosATL (_pos vectorAdd [0,0,1]);   // lift ~1m off ground to avoid clipping

		// Lock them down + keep them upright
		_unit disableAI "MOVE";
		_unit disableAI "PATH";
		_unit disableAI "TARGET";
		_unit disableAI "AUTOTARGET";
		_unit allowFleeing 0;
		_unit setUnitPos "UP";
		_unit switchMove "";          // clear any weird anim
		_unit setBehaviour "SAFE";
		_unit setCaptive true;
		
		removeUniform _unit;
		switch (_type) do {
			case "equip": { _unit forceAddUniform "Civilian_Jumpsuit_4"; };
			case "medic": { _unit forceAddUniform "Civilian_Jumpsuit_3"; };
			case "food":  { _unit forceAddUniform "Civilian_Jumpsuit_2"; };
		};
		


		// Build stock & actions
		private _stock = switch (_type) do {
			case "equip": { _stock_equip };
			case "medic": { _stock_medic };
			default      { _stock_food  };
		};
		private _count = 4 + floor random 3; // 4–6 listings
		{
			[_unit, _x] call _addBuyAction;
		} forEach ([_stock,_count] call _rollInventory);

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
