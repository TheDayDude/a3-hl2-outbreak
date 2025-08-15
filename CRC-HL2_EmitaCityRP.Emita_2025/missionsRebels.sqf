if (!isServer) exitWith {};

// Pick a random mission ID (1–3 here)
private _missionIndex = selectRandom [1, 2, 3];

switch (_missionIndex) do {
// === Mission 1: Assassinate Ordinal ===
case 1: {
    // Find a combine_ marker to host the target
    private _cmbMarkers = allMapMarkers select { toLower _x find "combine_" == 0 };
    if (_cmbMarkers isEqualTo []) exitWith {
        ["[Rebel Mission] No combine_ markers found — mission skipped."] remoteExec ["systemChat", 0];
    };

    private _chosenMarker = selectRandom _cmbMarkers;
    private _center       = getMarkerPos _chosenMarker;

    // Task for EAST (Rebels)
    private _taskId  = format ["task_assassinateOrdinal_%1", diag_tickTime];
    private _taskPos = [_center, 60 + random 60, random 360] call BIS_fnc_relPos; // offset so it's not too obvious
    [east, _taskId,
        ["Eliminate the Combine Ordinal leading operations in this sector.",
         "Assassinate Ordinal", ""],
        _taskPos, true
    ] call BIS_fnc_taskCreate;

    // Target & defenders
    private _defClasses = [
        "WBK_Combine_Grunt",
        "WBK_Combine_Grunt_white",
        "WBK_Combine_HL2_Type_WastelandPatrol",
        "WBK_Combine_HL2_Type",
        "WBK_Combine_HL2_Type_AR",
		"WBK_Combine_HL2_Type",
		"WBK_Combine_HL2_Type_AR"
    ];
    private _targetClass = "WBK_Combine_Ordinal";

    // Spawn the Ordinal directly on the marker
    private _targetGrp = createGroup west;
    private _ordinal   = _targetGrp createUnit [_targetClass, _center, [], 0, "NONE"];
    _targetGrp setBehaviour "AWARE";
    _targetGrp setCombatMode "RED";

    // Spawn small outpost props
    private _propTypes = [
        "combine_arsenal",
        "hazard_barrel",
        "HL_CMB_Static_generator01",
        "HL_CMB_Static_binocular01",
        "HL_CMB_Static_emitter01",
        "HL_CMB_Static_light001a",
        "HL_CMB_Static_headcrabcannister01a"
    ];
    private _props = [];
    private _propCount = 7 + floor random 10;

    for "_i" from 1 to _propCount do {
        private _pos = [_center, 8 + random 7, random 360] call BIS_fnc_relPos;
        private _obj = createVehicle [selectRandom _propTypes, _pos, [], 0, "NONE"];
        _obj setDir random 360;
        _props pushBack _obj;
    };

    // Spawn 3–4 defender groups around the area and have them patrol
    private _spawnedGroups = [];
    private _spawnedUnits  = [_ordinal];
    private _numGroups     = 3 + floor random 2; // 3–4

    for "_g" from 1 to _numGroups do {
        private _grp   = createGroup west;
        private _count = 3 + floor random 3; // 3–5 per group
        for "_i" from 1 to _count do {
            private _pos = [_center, 60 + random 120, random 360] call BIS_fnc_relPos;
            private _u   = _grp createUnit [selectRandom _defClasses, _pos, [], 2, "FORM"];
            _spawnedUnits pushBack _u;
        };
        _grp setBehaviour "AWARE";
        _grp setCombatMode "RED";
        [_grp, _center, 150] call BIS_fnc_taskPatrol;

        _spawnedGroups pushBack _grp;
    };
	
	// === Spawn watchtower + sniper ===
    private _towerPos = [_center, 20 + random 15, random 360] call BIS_fnc_findSafePos; // safer placement
    private _tower = createVehicle ["HL_CMB_Static_tower001", _towerPos, [], 0, "NONE"];
    _tower setDir random 360;
    _props pushBack _tower;

    // Optional: small chance of an APC patrol
    if (random 1 < 0.15) then {
        private _apcPos = [_center, 120 + random 120, random 360] call BIS_fnc_relPos;
        private _apc    = createVehicle ["HL_CMB_OW_APC", _apcPos, [], 0, "NONE"];
        createVehicleCrew _apc;
        _apc setDir random 360;
        _apc setBehaviour "AWARE";
        _apc setCombatMode "RED";
        private _crewGrp = group (driver _apc);
        [_crewGrp, _center, 200] call BIS_fnc_taskPatrol;
        _spawnedGroups pushBack _crewGrp;
        { _spawnedUnits pushBack _x } forEach (crew _apc);
        _spawnedUnits pushBack _apc;
    };

    // Success/Fail monitor
    [_taskId, _ordinal, _spawnedGroups, _spawnedUnits, _props] spawn {
        params ["_taskId","_ordinal","_groups","_units","_props"];

        private _deadline = time + 3600; // 1 hour fallback

        waitUntil {
            sleep 3;
            !alive _ordinal || captive _ordinal || time > _deadline
        };

        if (!alive _ordinal || captive _ordinal) then {
            // Success
            [_taskId, "SUCCEEDED", true] call BIS_fnc_taskSetState;

            // Reward EAST players (4–8 tokens)
            private _amt = 4 + floor random 5;
            {
                if (side _x == east && alive _x) then {
                    for "_i" from 1 to _amt do { _x addItem "VRP_HL_Token_Item"; };
                };
            } forEach allPlayers;
            [format ["Ordinal Eliminated. You pilfer %1 Tokens.", _amt]]
            remoteExec ["hintSilent", (allPlayers select { side _x == east }) apply { owner _x }];
			["Protection team alert: evidence of anti-civil activity in this community. Code: assemble, clamp, contain."] remoteExec ["systemChat", 0];
			["Fanticivilevidence3spkr"] remoteExec ["playSound", 0];
        } else {
            // Timeout fail
            [_taskId, "FAILED", true] call BIS_fnc_taskSetState;
            ["Target escaped the area. Mission failed."] remoteExec ["systemChat", (allPlayers select { side _x == east }) apply { owner _x }];
        };

        // Cleanup
		sleep 300;
        {
            { if (!isNull _x) then { deleteVehicle _x }; } forEach units _x;
        } forEach _groups;
        { if (!isNull _x) then { deleteVehicle _x }; } forEach _props;
        {
            if (!isNull _x && {!alive _x || {!(_x isKindOf 'Man')}}) then { deleteVehicle _x };
        } forEach _units;

        [_taskId] call BIS_fnc_deleteTask;
    };
};

// === Mission 2: Rally Rebels ===
case 2: {
    if (!isServer) exitWith {};

    private _slumMarkers = allMapMarkers select { toLower _x find "slums_" == 0 };
    if (_slumMarkers isEqualTo []) exitWith {
        ["[Rebel Mission] No slums_ markers found — mission skipped."] remoteExec ["systemChat", 0];
    };

    missionNamespace setVariable ["rr_recruited", 0];
    missionNamespace setVariable ["rr_failed", 0];

    private _spawnCount = 15 + floor random 6; // 15–20 civilians
    private _civClasses = ["HL_CIV_Man_01","HL_CIV_Man_02","CombainCIV_Uniform_1_Body"];
    private _civs = [];

    for "_i" from 1 to _spawnCount do {
        private _mkr = selectRandom _slumMarkers;
        private _pos = [getMarkerPos _mkr, 0, 150, 0, 0, 20, 0] call BIS_fnc_findSafePos;
        private _grp = createGroup civilian;
        private _civ = _grp createUnit [selectRandom _civClasses, _pos, [], 0, "FORM"];
        _civs pushBack _civ;
        _civ setVariable ["rr_state", "pending"];

        private _eh = _civ addEventHandler ["Killed", {
            missionNamespace setVariable ["rr_failed", (missionNamespace getVariable ["rr_failed",0]) + 1];
        }];
        _civ setVariable ["rr_killEh", _eh];

        [_grp, _pos, 80] call BIS_fnc_taskPatrol;

        _civ addAction ["Recruit", {
            params ["_target","_caller"];
            if (_target getVariable ["rr_state","pending"] != "pending") exitWith {};
            _target setVariable ["rr_state","used"];
            removeAllActions _target;
			_caller playMoveNow "Acts_CivilTalking_1";
			_target playMoveNow "Acts_CivilListening_1";
            uiSleep 8;
            _caller switchMove "";
			_target switchMove "";

            if (random 1 < 0.67) then {
                _target removeEventHandler ["Killed", _target getVariable ["rr_killEh",-1]];
                [_target] joinSilent (group _caller);
                removeAllWeapons _target;
                _target addWeapon "WBK_CP_HeavySmg_Resist";
                for "_m" from 1 to 3 do { _target addMagazine "HLB_HSMG_Mag"; };
                _target selectWeapon "WBK_CP_HeavySmg_Resist";
                missionNamespace setVariable ["rr_recruited", (missionNamespace getVariable ["rr_recruited",0]) + 1];
				["You're right. We can't just sit here and do nothing."] remoteExec ["systemChat", owner _caller];
				_target say3D "rebel_announcekill_01";
            } else {
                _target removeEventHandler ["Killed", _target getVariable ["rr_killEh",-1]];
                missionNamespace setVariable ["rr_failed", (missionNamespace getVariable ["rr_failed",0]) + 1];
				["Attention Residents: Miscount detected in your block. Cooperation with your Civil Protection team permits full ration reward."] remoteExec ["systemChat", 0];
				["Ftrainstationcooperationspkr"] remoteExec ["playSound", 0];
				["Are you crazy? Get out of here!"] remoteExec ["systemChat", owner _caller];
				_target say3D "rebel_squadmemberlost_01";
                private _runPos = _target getPos [100, _target getDir _caller];
                _target doMove _runPos;
                [_target] spawn { params ["_c"]; sleep 30; if (alive _c) then { deleteVehicle _c; }; };
            };
        }, [], 1.5, true, true, "", "side _this == east", 4];
    };

    private _taskId = format ["task_rallyRebels_%1", diag_tickTime];
    [east, _taskId,
        ["Rally citizens in the slums. Recruit at least ten to join the fight.","Rally Rebels",""],
        getMarkerPos (selectRandom _slumMarkers), true
    ] call BIS_fnc_taskCreate;

    [_taskId, _civs] spawn {
        params ["_taskId","_civs"];
        private _deadline = time + 3600; // 1 hour
        waitUntil {
            sleep 3;
            (missionNamespace getVariable ["rr_recruited",0] >= 10) ||
            (missionNamespace getVariable ["rr_failed",0] >= 10) ||
            (time > _deadline)
        };

        private _recruited = missionNamespace getVariable ["rr_recruited",0];
        private _failed = missionNamespace getVariable ["rr_failed",0];

        if (_recruited >= 10) then {
            [_taskId, "SUCCEEDED", true] call BIS_fnc_taskSetState;
            ["Enough citizens have joined the cause!"] remoteExec ["systemChat", (allPlayers select { side _x == east }) apply { owner _x }];
        } else {
            [_taskId, "FAILED", true] call BIS_fnc_taskSetState;
            ["Too few citizens were recruited. Mission failed."] remoteExec ["systemChat", (allPlayers select { side _x == east }) apply { owner _x }];
        };

        sleep 300;
        {
            if (alive _x && { side _x == civilian }) then { deleteVehicle _x };
        } forEach _civs;

        [_taskId] call BIS_fnc_deleteTask;
    };
};


// === Mission 3: Steal Conscript Supply Truck (center on truck) ===
case 3: {
    if (!isServer) exitWith {};

    private _cmbMarkers = allMapMarkers select { toLower _x find "combine_" == 0 };
    if (_cmbMarkers isEqualTo []) exitWith {
        ["[Rebel Mission] No combine_ markers found — mission skipped."] remoteExec ["systemChat", 0];
    };

    private _chosenMarker = selectRandom _cmbMarkers;
    private _markerPos    = getMarkerPos _chosenMarker;

    // Find a SAFE truck spawn near the marker (big radius)
    private _truckPos = [_markerPos, 200, 600, 0, 0, 30, 0] call BIS_fnc_findSafePos;

    // Create the truck (unmanned) — this becomes the encounter center
    private _truck = createVehicle ["I_E_Truck_02_Ammo_F", _truckPos, [], 0, "NONE"];
    _truck setDir random 360;
    _truck lock false;
    _truck setFuel 1;

    // Seed supplies
    clearWeaponCargoGlobal _truck;
    clearMagazineCargoGlobal _truck;
    clearItemCargoGlobal _truck;
    clearBackpackCargoGlobal _truck;
    private _supplyItems = ["hlc_rifle_aek971worn","hlc_30Rnd_545x39_B_AK","hlc_optic_goshawk","hlc_optic_kobra","HLC_Optic_PSO1","HLC_Optic_1p29","hlc_rifle_FAL5000","hlc_optic_PVS4FAL","hlc_optic_suit","30Rnd_556x45_Stanag_Tracer_Blue","20Rnd_762x51_Mag_Tracer_Blue","H_combine_helmet_1","H_combine_helmet_2","H_combine_helmet_low","U_raincoat_od7","U_BDU_Raid_od7","V_combine_pasgt_vest","B_hecu_survival_m81_2","M40_Gas_mask_nbc_v3_g","BMS_X800","Binocular","ItemRadio","ItemGPS","ItemAndroid","ItemMicroDAGR","ItemcTab","HandGrenade","hlc_rifle_M4","hlc_rifle_M14","DemoCharge_Remote_Mag","VRP_Cop_Ration_Item","VRP_Loyalist_Ration_Item","VRP_Loyalist_Ration_Item2","ACE_Canteen","VRP_HL2_RedWater","ACE_CableTie","ACE_DefusalKit","WBK_Health_ArmourPlate","WBK_Health_Bandage","ACE_Clacker","ACE_M26_Clacker","ACE_MRE_BeefStew","Medikit","ToolKit"];
    private _supplyBoxes = 18 + floor random 13; // 18–30 items
    for "_i" from 1 to _supplyBoxes do {
        _truck addItemCargoGlobal [selectRandom _supplyItems, 1 + floor random 2];
    };

    // Task for EAST — marker slightly offset from the TRUCK (not the map marker)
    private _taskPos = [_truckPos, 50 + random 60, random 360] call BIS_fnc_relPos;
    private _taskId  = format ["task_stealTruck_%1", diag_tickTime];
    [east, _taskId,
        ["Steal the conscript supply truck. Move it at least 1 km away from the depot.",
         "Steal Conscript Supply Truck", ""],
        _taskPos, true
    ] call BIS_fnc_taskCreate;

    // Conscript patrols centered on the TRUCK
    private _conscripts = ["WBK_HL_Conscript_1","WBK_HL_Conscript_2", "WBK_HL_Conscript_2","WBK_HL_Conscript_2", "WBK_HL_Conscript_6"];
    private _groups = [];
    private _units  = [];
    private _props  = [_truck];

    // --- Tight guard close to the truck (always spawns) ---
    private _tightGrp = createGroup west;
    private _tightCount = 3 + floor random 3; // 3–5
    for "_i" from 1 to _tightCount do {
        private _p = [_truckPos, 10, 25, 0, 0, 10, 0] call BIS_fnc_findSafePos;
        private _u = _tightGrp createUnit [selectRandom _conscripts, _p, [], 0, "FORM"];
        _units pushBack _u;
		
		// === CUSTOM WEAPON OVERRIDE ===
		if (typeOf _u == "WBK_HL_Conscript_2") then {
			removeAllWeapons _u;
			_u addWeapon "hlc_rifle_m4";
			for "_m" from 1 to 4 do { _u addMagazine "30Rnd_556x45_Stanag_Tracer_Blue"; };
			_u selectWeapon "hlc_rifle_m4";
		};
    };
    _tightGrp setBehaviour "AWARE";
    _tightGrp setCombatMode "RED";
    [_tightGrp, _truckPos, 40] call BIS_fnc_taskPatrol; // tight 40m patrol around truck
    _groups pushBack _tightGrp;

    // --- Additional roaming patrols around the truck (2–4 total groups including tight one) ---
    private _extraGroups = (3 + floor random 2) - 1 max 0; // 2–3 more, since tight group already spawned
    for "_g" from 1 to _extraGroups do {
        private _grp = createGroup west;
        private _count = 3 + floor random 3; // 4–5 per group
        for "_i" from 1 to _count do {
            private _p = [_truckPos, 120, 350, 0, 0, 20, 0] call BIS_fnc_findSafePos;
            private _u = _grp createUnit [selectRandom _conscripts, _p, [], 0, "FORM"];
            _units pushBack _u;
			// === CUSTOM WEAPON OVERRIDE ===
			if (typeOf _u == "WBK_HL_Conscript_2") then {
				removeAllWeapons _u;
				_u addWeapon "hlc_rifle_m4";
				for "_m" from 1 to 4 do { _u addMagazine "30Rnd_556x45_Stanag_Tracer_Blue"; };
				_u selectWeapon "hlc_rifle_m4";
			};
        };
        _grp setBehaviour "AWARE";
        _grp setCombatMode "RED";
        [_grp, _truckPos, 250] call BIS_fnc_taskPatrol; // wider around truck
        _groups pushBack _grp;
    };

    // Monitor success/failure (distance from TRUCK SPAWN)
    [_taskId, _truck, _truckPos, _groups, _units, _props] spawn {
        params ["_taskId","_truck","_spawnPos","_groups","_units","_props"];

        private _deadline = time + 3600; // 1 hour
        private _success  = false;

        waitUntil {
            sleep 3;
            _success = (alive _truck) && ((_truck distance2D _spawnPos) >= 1000);
            _success || !alive _truck || (time > _deadline)
        };

        if (_success) then {
            [_taskId, "SUCCEEDED", true] call BIS_fnc_taskSetState;

            // Optional reward for EAST
            private _amt = 2 + floor random 4; // 2–5 tokens
            {
                if (side _x == east && alive _x) then {
                    for "_i" from 1 to _amt do { _x addItem "VRP_HL_Token_Item"; };
                };
            } forEach allPlayers;
            [format ["Truck stolen! You pilfer %1 Tokens.", _amt]]
                remoteExec ["hintSilent", (allPlayers select { side _x == east }) apply { owner _x }];

            // Cleanup conscripts only (keep truck) after 5 minutes
            sleep 300;
            {
                { if (!isNull _x) then { deleteVehicle _x } } forEach units _x;
                deleteGroup _x;
            } forEach _groups;

        } else {
            [_taskId, "FAILED", true] call BIS_fnc_taskSetState;
            ["The truck was lost or time has expired. Mission failed."]
                remoteExec ["systemChat", (allPlayers select { side _x == east }) apply { owner _x }];

            // Cleanup conscripts AND the truck after 5 minutes
            sleep 300;
            {
                { if (!isNull _x) then { deleteVehicle _x } } forEach units _x;
                deleteGroup _x;
            } forEach _groups;
            if (!isNull _truck) then { deleteVehicle _truck; };
        };

        sleep 10;
        [_taskId] call BIS_fnc_deleteTask;
    };
};


};