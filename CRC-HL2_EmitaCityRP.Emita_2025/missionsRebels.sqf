if (!isServer) exitWith {};

// Pick a random mission ID (1–5 here)
private _missionIndex = selectRandom [1, 2, 3, 4, 5];

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
    if (random 1 < 0.10) then {
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

        private _deadline = time + 2700;

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
            missionNamespace setVariable ["Sociostability", (missionNamespace getVariable ["Sociostability",0]) - 1, true];
        } else {
            // Timeout fail
            [_taskId, "FAILED", true] call BIS_fnc_taskSetState;
            ["Target escaped the area. Mission failed."] remoteExec ["systemChat", (allPlayers select { side _x == east }) apply { owner _x }];
            missionNamespace setVariable ["Sociostability", (missionNamespace getVariable ["Sociostability",0]) + 1, true];
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

    // ---- Client/Server helpers for recruit action ----
    if (isNil "RBL_fnc_addRecruitAction") then {
        RBL_fnc_addRecruitAction = {
            params ["_u"];
            if (isNull _u) exitWith {};
            _u addAction [
                "Recruit",
                {
                    params ["_target","_caller"];
                    if (_target getVariable ["rr_state","pending"] != "pending") exitWith {};
                    _caller playMoveNow "Acts_CivilTalking_1";
                    [_caller] spawn { params ["_c"]; uiSleep 8; _c switchMove ""; };
                    [_target, _caller] remoteExec ["RBL_fnc_recruitServer", 2];
                },
                nil, 1.5, true, true, "",
                "side _this == east && {_target getVariable ['rr_state','pending'] == 'pending'}",
                4
            ];
        };
        publicVariable "RBL_fnc_addRecruitAction";
    };

    if (isNil "RBL_fnc_removeRecruitAction") then {
        RBL_fnc_removeRecruitAction = {
            params ["_u"];
            if (isNull _u) exitWith {};
            removeAllActions _u;
        };
        publicVariable "RBL_fnc_removeRecruitAction";
    };

    if (isNil "RBL_fnc_recruitServer") then {
        RBL_fnc_recruitServer = {
            params ["_target","_caller"];
            if (isNull _target || isNull _caller) exitWith {};
            if (_target getVariable ["rr_state","pending"] != "pending") exitWith {};
            _target setVariable ["rr_state","used", true];
            removeAllActions _target;
            [_target] remoteExec ["RBL_fnc_removeRecruitAction", 0, true];
            _target playMoveNow "Acts_CivilListening_1";
            uiSleep 8;
            _target switchMove "";
            if (random 1 < 0.7) then {
                private _pos = getPos _target;
                private _dir = getDir _target;
                private _grp = group _caller;
                deleteVehicle _target;
                private _rebelClasses = [
                    "WBK_Rebel_Rifleman_1","WBK_Rebel_Rifleman_2","WBK_Rebel_Rifleman_3",
                    "WBK_Rebel_SMG_1","WBK_Rebel_Shotgunner_2","WBK_Rebel_Medic_1"
                ];
                private _new = _grp createUnit [selectRandom _rebelClasses, _pos, [], 0, "FORM"];
                _new setDir _dir;
                missionNamespace setVariable ["rr_recruited", (missionNamespace getVariable ["rr_recruited",0]) + 1];
                ["You're right. We can't just sit here and do nothing."] remoteExec ["systemChat", owner _caller];
                [_new, "rebel_announcekill_01"] remoteExecCall ["say3D", 0];
            } else {
                ["Are you crazy? Get out of here!"] remoteExec ["systemChat", owner _caller];
				[_target, "rebel_squadmemberlost_01"] remoteExecCall ["say3D", 0];
                private _runPos = _target getPos [100, _target getDir _caller];
                _target doMove _runPos;
				sleep 10;
				["Attention Residents: Miscount detected in your block. Cooperation with your Civil Protection team permits full ration reward."] remoteExec ["systemChat", 0];
                ["Ftrainstationcooperationspkr"] remoteExec ["playSound", 0];
                [_target] spawn { params ["_c"]; sleep 30; if (alive _c) then { deleteVehicle _c; }; };
            };
        };
        publicVariable "RBL_fnc_recruitServer";
    };

    private _slumMarkers = allMapMarkers select { toLower _x find "slums_" == 0 };
    if (_slumMarkers isEqualTo []) exitWith {
        ["[Rebel Mission] No slums_ markers found — mission skipped."] remoteExec ["systemChat", 0];
    };

    missionNamespace setVariable ["rr_recruited", 0];

    private _spawnCount = 10;
    private _civClasses = ["HL_CIV_Man_01","HL_CIV_Man_02","CombainCIV_Uniform_1_Body"];
    private _civs = [];

    for "_i" from 1 to _spawnCount do {
        private _mkr = selectRandom _slumMarkers;
        private _pos = [getMarkerPos _mkr, 0, 150, 0, 0, 20, 0] call BIS_fnc_findSafePos;
        private _grp = createGroup civilian;
        private _civ = _grp createUnit [selectRandom _civClasses, _pos, [], 0, "FORM"];
        _grp setBehaviour "SAFE";
        _grp setSpeedMode "LIMITED";
        _civs pushBack _civ;
        _civ setVariable ["rr_state", "pending", true];

        [_grp, _pos, 80] call BIS_fnc_taskPatrol;

        [_civ] remoteExec ["RBL_fnc_addRecruitAction", 0, true];
    };

    private _taskId = format ["task_rallyRebels_%1", diag_tickTime];
    [east, _taskId,
        ["Rally citizens in the slums. Recruit at least five to join the fight.","Rally Rebels",""],
        getMarkerPos (selectRandom _slumMarkers), true
    ] call BIS_fnc_taskCreate;

    [_taskId, _civs] spawn {
        params ["_taskId","_civs"];
        private _deadline = time + 2700;
        waitUntil {
            sleep 3;
            (missionNamespace getVariable ["rr_recruited",0] >= 5) ||
            (time > _deadline)
        };

        private _recruited = missionNamespace getVariable ["rr_recruited",0];
        private _failed = missionNamespace getVariable ["rr_failed",0];

        if (_recruited >= 5) then {
            [_taskId, "SUCCEEDED", true] call BIS_fnc_taskSetState;
            ["Enough citizens have joined the cause!"] remoteExec ["systemChat", (allPlayers select { side _x == east }) apply { owner _x }];
            missionNamespace setVariable ["Sociostability", (missionNamespace getVariable ["Sociostability",0]) - 1, true];
        } else {
            [_taskId, "FAILED", true] call BIS_fnc_taskSetState;
            ["Too few citizens were recruited. Mission failed."] remoteExec ["systemChat", (allPlayers select { side _x == east }) apply { owner _x }];
            missionNamespace setVariable ["Sociostability", (missionNamespace getVariable ["Sociostability",0]) + 1, true];
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

        private _deadline = time + 2700;
        private _success  = false;

        waitUntil {
            sleep 3;
            _success = (alive _truck) && ((_truck distance2D _spawnPos) >= 1000);
            _success || !alive _truck || (time > _deadline)
        };

        if (_success) then {
            [_taskId, "SUCCEEDED", true] call BIS_fnc_taskSetState;

            private _amt = 4 + floor random 4;
            {
                if (side _x == east && alive _x) then {
                    for "_i" from 1 to _amt do { _x addItem "VRP_HL_Token_Item"; };
                };
            } forEach allPlayers;
            [format ["Truck stolen! You pilfer %1 Tokens.", _amt]]
                remoteExec ["hintSilent", (allPlayers select { side _x == east }) apply { owner _x }];
            missionNamespace setVariable ["Sociostability", (missionNamespace getVariable ["Sociostability",0]) - 1, true];

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
            missionNamespace setVariable ["Sociostability", (missionNamespace getVariable ["Sociostability",0]) + 1, true];

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

// === Mission 4: Rescue Rogue Unit ===
case 4: {
    if (!isServer) exitWith {};

    // --- Dedicated server-safe action helpers ---
    if (isNil "RRU_fnc_addFreeAction") then {
        RRU_fnc_addFreeAction = {
            params ["_u"];
            if (isNull _u) exitWith {};
            _u addAction [
                "Free Rogue Officer",
                {
                    params ["_target","_caller"];
                    [_target,_caller] remoteExec ["RRU_fnc_freeRogueServer",2];
                },
                nil,1.5,true,true,"",
                "side _this == east && captive _target",
                4
            ];
        };
        publicVariable "RRU_fnc_addFreeAction";
    };

    if (isNil "RRU_fnc_removeFreeAction") then {
        RRU_fnc_removeFreeAction = {
            params ["_u"];
            if (isNull _u) exitWith {};
            removeAllActions _u;
        };
        publicVariable "RRU_fnc_removeFreeAction";
    };

    if (isNil "RRU_fnc_freeRogueServer") then {
        RRU_fnc_freeRogueServer = {
            params ["_rogue","_caller"];
            if (isNull _rogue || isNull _caller) exitWith {};
            if (!captive _rogue) exitWith {};
            _caller playMoveNow "AinvPknlMstpSnonWnonDnon_medic_1";
            uiSleep 3.5;
            _caller switchMove "";
            _rogue setCaptive false;
            [_rogue,""] remoteExec ["switchMove",0,true];
            _rogue enableAI "MOVE";
            [_rogue] joinSilent (group _caller);
            [_rogue] remoteExec ["RRU_fnc_removeFreeAction",0,true];

            missionNamespace setVariable ["rru_freed",true,true];

            // spawn hunting squad
            private _huntPos = getMarkerPos "slums_guard";
            private _huntGrp = createGroup west;
            for "_i" from 1 to (3 + floor random 3) do {
                _huntGrp createUnit [selectRandom ["WBK_Combine_CP_P","WBK_Combine_CP_SMG"], _huntPos, [], 5, "FORM"];
            };
            _huntGrp setBehaviour "COMBAT";
            _huntGrp setCombatMode "RED";
            [_huntGrp,_rogue] spawn {
                params ["_grp","_vip"];
                while {alive _vip && {count units _grp > 0}} do {
                    _grp move position _vip;
                    sleep 15;
                };
            };
            missionNamespace setVariable ["rru_huntGrp",_huntGrp];
        };
        publicVariable "RRU_fnc_freeRogueServer";
    };

    if (isNil "RRU_fnc_createRescueMarker") then {
        RRU_fnc_createRescueMarker = {
            params ["_name","_pos"];
            if (!hasInterface || { side player != east }) exitWith {};
            private _m = createMarkerLocal [_name,_pos];
            _m setMarkerShapeLocal "ICON";
            _m setMarkerTypeLocal "mil_pickup";
            _m setMarkerTextLocal "VIP Rescue Point";
            _m setMarkerColorLocal "ColorGreen";
        };
        publicVariable "RRU_fnc_createRescueMarker";
    };

    if (isNil "RRU_fnc_deleteMarker") then {
        RRU_fnc_deleteMarker = {
            params ["_name"];
            if (!hasInterface || { side player != east }) exitWith {};
            deleteMarkerLocal _name;
        };
        publicVariable "RRU_fnc_deleteMarker";
    };

    // Gather possible markers
    private _slumMarkers = allMapMarkers select { toLower _x find "slums_" == 0 };
    private _rebelMarkers = allMapMarkers select { toLower _x find "rebel_" == 0 };
    if (_slumMarkers isEqualTo [] || _rebelMarkers isEqualTo []) exitWith {
        ["[Rebel Mission] Missing slums_ or rebel_ markers — mission skipped."] remoteExec ["systemChat",0];
    };

    private _spawnMarker = selectRandom _slumMarkers;
    private _spawnPos    = getMarkerPos _spawnMarker;

    // Rogue captive
    private _rogueGrp = createGroup west;
    private _rogue    = _rogueGrp createUnit ["UU_CP", _spawnPos, [], 0, "NONE"];
    _rogue setCaptive true;
    removeHeadgear _rogue;
    [_rogue,"Acts_ExecutionVictim_Loop"] remoteExec ["switchMove",0,true];
    _rogue setVariable ["rru_state","captive",true];
    [_rogue] remoteExec ["RRU_fnc_addFreeAction",0,true];

    // Guard squad
    private _guardGrp = createGroup west;
    private _guards   = [];
    for "_i" from 1 to 4 do {
        private _p = [_spawnPos,8 + random 5, random 360] call BIS_fnc_relPos;
        private _g = _guardGrp createUnit [selectRandom ["WBK_Combine_HL2_Type","WBK_Combine_CP_SMG"], _p, [], 0, "FORM"];
        _guards pushBack _g;
    };
    _guardGrp setBehaviour "AWARE";
    _guardGrp setCombatMode "RED";
    [_guardGrp,_spawnPos,40] call BIS_fnc_taskPatrol;

    // Rebel extraction team
    private _rebelMarker = selectRandom _rebelMarkers;
    private _rescuePos   = getMarkerPos _rebelMarker;
    private _rebelGrp    = createGroup east;
    private _rebels      = [];
    for "_i" from 1 to 4 do {
        private _rp = [_rescuePos,5 + random 5, random 360] call BIS_fnc_relPos;
        private _r  = _rebelGrp createUnit [selectRandom ["WBK_Rebel_Rifleman_1","WBK_Rebel_SMG_2","WBK_Rebel_Rifleman_2"], _rp, [], 0, "FORM"];
        _rebels pushBack _r;
    };
    _rebelGrp setBehaviour "SAFE";
    _rebelGrp setCombatMode "YELLOW";

    private _markerName = format ["vipRescue_%1",diag_tickTime];
    [_markerName,_rescuePos] remoteExec ["RRU_fnc_createRescueMarker",0,true];

    // Task setup
    private _taskId = format ["task_rescueRogue_%1", diag_tickTime];
    [east,_taskId,
        ["Free the rogue CPF officer and deliver him to the rebels.","Rescue Rogue Unit",""],
        _spawnPos,true
    ] call BIS_fnc_taskCreate;

    // Monitor success/failure
    [_taskId,_rogue,_guardGrp,_rebelGrp,_guards+_rebels,_rescuePos,_markerName] spawn {
        params ["_taskId","_rogue","_guardGrp","_rebelGrp","_units","_rescuePos","_markerName"];
        private _deadline = time + 2700; // 45 minutes
        private _success = false;

        waitUntil {
            sleep 5;
            _success = alive _rogue && !captive _rogue && (_rogue distance2D _rescuePos < 10);
            _success || !alive _rogue || time > _deadline
        };

        if (_success) then {
            [_taskId,"SUCCEEDED",true] call BIS_fnc_taskSetState;
            missionNamespace setVariable ["Sociostability", (missionNamespace getVariable ["Sociostability",0]) - 1, true];
            [_rogue] joinSilent _rebelGrp;
            [_markerName] remoteExec ["RRU_fnc_deleteMarker",0];
            private _amt = 4 + floor random 4;
            {
                if (side _x == east && alive _x) then {
                    for "_i" from 1 to _amt do { _x addItem "VRP_HL_Token_Item"; };
                };
            } forEach allPlayers;
            [format ["Rogue Unit Extracted! He contributes %1 Tokens to your cause.", _amt]]
                remoteExec ["hintSilent", (allPlayers select { side _x == east }) apply { owner _x }];
        } else {
            if (time > _deadline && alive _rogue && captive _rogue) then { _rogue setDamage 1; };
            [_taskId,"FAILED",true] call BIS_fnc_taskSetState;
            missionNamespace setVariable ["Sociostability", (missionNamespace getVariable ["Sociostability",0]) + 1, true];
            [_markerName] remoteExec ["RRU_fnc_deleteMarker",0];
        };

        // cleanup after 5 minutes
        sleep 300;
        { if (!isNull _x) then { deleteVehicle _x }; } forEach _units;
        { if (!isNull _x) then { deleteVehicle _x }; } forEach units _guardGrp;
        deleteGroup _guardGrp;
        { if (!isNull _x) then { deleteVehicle _x }; } forEach units _rebelGrp;
        deleteGroup _rebelGrp;
        private _huntGrp = missionNamespace getVariable ["rru_huntGrp",grpNull];
        if (!isNull _huntGrp) then {
            { if (!isNull _x) then { deleteVehicle _x }; } forEach units _huntGrp;
            deleteGroup _huntGrp;
        };
        if (!isNull _rogue) then { deleteVehicle _rogue; };
        [_taskId] call BIS_fnc_deleteTask;
    };
};

// === Mission 5: Hack Combine Terminal ===
case 5: {
    if (!isServer) exitWith {};

    // --- Dedicated server-safe hacking actions ---
    if (isNil "RBL_fnc_addHackActions") then {
        RBL_fnc_addHackActions = {
            params ["_term"];
            if (isNull _term) exitWith {};
            _term addAction [
                "Start Hacking",
                {
                    params ["_target","_caller"];
                    [_target,_caller] remoteExec ["RBL_fnc_startHackServer",2];
                },
                nil,1.5,true,true,"",
                "side _this == east && {_target getVariable ['hack_state','idle'] == 'idle'}",
                4
            ];
            _term addAction [
                "Resume Hacking",
                {
                    params ["_target","_caller"];
                    [_target,_caller] remoteExec ["RBL_fnc_resumeHackServer",2];
                },
                nil,1.5,true,true,"",
                "side _this == east && {_target getVariable ['hack_state',''] == 'paused'}",
                4
            ];
        };
        publicVariable "RBL_fnc_addHackActions";
    };

    if (isNil "RBL_fnc_startHackServer") then {
        RBL_fnc_startHackServer = {
            params ["_term","_caller"];
            if (_term getVariable ["hack_state","idle"] == "idle") then {
                _term setVariable ["hack_state","running", true];
                _term setVariable ["hack_lastPresence", time, true];
            };
        };
        publicVariable "RBL_fnc_startHackServer";
    };

    if (isNil "RBL_fnc_resumeHackServer") then {
        RBL_fnc_resumeHackServer = {
            params ["_term","_caller"];
            if (_term getVariable ["hack_state",""] == "paused") then {
                _term setVariable ["hack_state","running", true];
                _term setVariable ["hack_lastPresence", time, true];
            };
        };
        publicVariable "RBL_fnc_resumeHackServer";
    };

    if (isNil "RBL_fnc_monitorHackClient") then {
        RBL_fnc_monitorHackClient = {
            params ["_term"];
            if (!hasInterface || {side player != east}) exitWith {};
            private _shown = false;
            while { !isNull _term } do {
                private _state = _term getVariable ["hack_state","idle"];
                private _time = _term getVariable ["hack_time",0];
                switch (_state) do {
                    case "running": {
                        hintSilent format ["Hacking: %1", [_time,"MM:SS"] call BIS_fnc_secondsToString];
                        _shown = true;
                    };
                    case "paused": {
                        hintSilent format ["Hacking paused: %1", [_time,"MM:SS"] call BIS_fnc_secondsToString];
                        _shown = true;
                    };
                    default {
                        if (_shown) then { hintSilent ""; _shown = false; };
                    };
                };
                sleep 1;
            };
            hintSilent "";
        };
        publicVariable "RBL_fnc_monitorHackClient";
    };

    // pick combine marker
    private _cmbMarkers = allMapMarkers select { toLower _x find "combine_" == 0 };
    if (_cmbMarkers isEqualTo []) exitWith {
        ["[Rebel Mission] No combine_ markers found — mission skipped."] remoteExec ["systemChat",0];
    };

    private _marker = selectRandom _cmbMarkers;
    private _pos = getMarkerPos _marker;

    // spawn terminal
    private _terminal = createVehicle ["HL_CMB_Static_interface002", _pos, [], 0, "NONE"];
    _terminal setDir random 360;
    _terminal setVariable ["hack_state","idle", true];
    _terminal setVariable ["hack_time",300,true];
    _terminal setVariable ["hack_lastPresence", time, true];

    // initial protection squad
    private _guardGrp = createGroup west;
    for "_i" from 1 to 4 do {
        private _gPos = [_pos, 6 + random 4, random 360] call BIS_fnc_relPos;
        _guardGrp createUnit [selectRandom ["WBK_Combine_Grunt","WBK_Combine_HL2_Type","WBK_Combine_HL2_Type_AR"], _gPos, [], 0, "FORM"];
    };
    _guardGrp setBehaviour "AWARE";
    _guardGrp setCombatMode "RED";
    [_guardGrp, _pos, 40] call BIS_fnc_taskPatrol;

    // add actions for rebels
    [_terminal] remoteExec ["RBL_fnc_addHackActions",0,true];
    [_terminal] remoteExec ["RBL_fnc_monitorHackClient",0,true];

    // create task
    private _taskId = format ["task_hackTerminal_%1", diag_tickTime];
    [east,_taskId,
        ["Vital intel resides on this Overwatch terminal. Hack into it and stay nearby. Resume the process as needed.","Hack Combine Terminal",""],
        _pos,true
    ] call BIS_fnc_taskCreate;

    // monitor mission
    [_taskId,_terminal,_guardGrp] spawn {
        params ["_taskId","_terminal","_guardGrp"];
        private _deadline = time + 2700;
        private _timeLeft = 300;
        private _nextWave = -1;
        private _nextPause = -1;
        private _heliSpawned = false;
        private _allUnits = [_terminal];
        private _allGroups = [];
        if (!isNull _guardGrp) then {
            { _allUnits pushBack _x; } forEach units _guardGrp;
            _allGroups pushBack _guardGrp;
        };
        private _success = false;
        private _fail = false;
        private _lastPresence = time;

        while { !_success && !_fail } do {
            sleep 1;

            if (time > _deadline) exitWith { _fail = true; };

            private _state = _terminal getVariable ["hack_state","idle"];

            if (_state != "idle") then {
                if (_nextWave < 0) then {
                    _nextWave = time;
                    _nextPause = time + 60 + random 60;
                };
                private _rebels = allUnits select { side _x == east && alive _x && (_x distance2D _terminal) < 200 };
                if (_rebels isNotEqualTo []) then {
                    _lastPresence = time;
                } else {
                    if (time - _lastPresence > 200) exitWith { _fail = true; };
                };
            };

            if (_nextWave >= 0 && time >= _nextWave) then {
                _nextWave = time + 90;
                private _wpPos = getPos _terminal;
                private _spawnPos = [_wpPos, 250, 450, 0, 0, 20, 0] call BIS_fnc_findSafePos;
                private _grp = createGroup west;
                private _count = 4 + floor random 3;
                for "_i" from 1 to _count do {
                    private _p = [_spawnPos,5, random 360] call BIS_fnc_relPos;
                    private _u = _grp createUnit [selectRandom ["WBK_Combine_Grunt","WBK_Combine_HL2_Type","WBK_Combine_HL2_Type_AR"], _p, [], 0, "FORM"];
                    _allUnits pushBack _u;
                };
                _grp setBehaviour "AWARE";
                _grp setCombatMode "RED";
                private _wp = _grp addWaypoint [_wpPos,0];
                _wp setWaypointType "SAD";
                _allGroups pushBack _grp;
            };

            if (_state == "running") then {
                _timeLeft = _timeLeft - 1;
                _terminal setVariable ["hack_time",_timeLeft,true];
                if (_timeLeft <= 0) exitWith { _success = true; };

                if (!_heliSpawned && _timeLeft <= 150) then {
                    _heliSpawned = true;
                    private _spawn = [getPos _terminal, 1000, 1200, 0, 0, 20, 0] call BIS_fnc_findSafePos;
                    private _heli = createVehicle ["B_Heli_Transport_03_unarmed_F", _spawn, [], 0, "FLY"];
                    _heli flyInHeight 60;
                    _allUnits pushBack _heli;
                    createVehicleCrew _heli;
                    { _allUnits pushBack _x; } forEach crew _heli;
                    _allGroups pushBack group (driver _heli);

                    private _eliteGrp = createGroup west;
                    // mix of elite soldiers and assassins
                    for "_i" from 1 to 3 do {
                        private _e = _eliteGrp createUnit ["WBK_Combine_HL2_Type_Elite", _spawn, [], 0, "NONE"];
                        _e moveInCargo _heli;
                        _allUnits pushBack _e;
                    };
                    for "_i" from 1 to 3 do {
                        private _a = _eliteGrp createUnit ["WBK_Combine_ASS_SMG", _spawn, [], 0, "NONE"];
                        _a moveInCargo _heli;
                        _allUnits pushBack _a;
                    };
                    _allGroups pushBack _eliteGrp;

                    [_heli,_terminal,_eliteGrp] spawn {
                        params ["_heli","_term","_grp"];
                        private _dropPos = getPos _term;
                        private _exitPos = [_dropPos, 2000, 2500, 0, 0, 20, 0] call BIS_fnc_findSafePos;
                        _heli move (_dropPos vectorAdd [0,0,60]);
                        waitUntil { sleep 1; (_heli distance2D _dropPos) < 100 };
                        {
                            unassignVehicle _x;
                            _x action ["Eject", _heli];
                            _x allowDamage false;
                            [_x] spawn { params ["_u"]; waitUntil { sleep 0.5; isTouchingGround _u }; _u allowDamage true; };
                        } forEach units _grp;
                        _grp setBehaviour "AWARE";
                        _grp setCombatMode "RED";
                        private _wp = _grp addWaypoint [_dropPos, 0];
                        _wp setWaypointType "SAD";
                        _heli move (_exitPos vectorAdd [0,0,80]);
                        waitUntil { sleep 1; (_heli distance2D _dropPos) > 1500 || !canMove _heli };
                        { if (!isNull _x) then { deleteVehicle _x }; } forEach crew _heli;
                        deleteVehicle _heli;
                    };
                };

                if (time >= _nextPause) then {
                    _terminal setVariable ["hack_state","paused",true];
                    _nextPause = time + 60 + random 60;
                    ["Hacking paused! Use Resume Hacking."] remoteExec ["hint", (allPlayers select { side _x == east }) apply { owner _x }];
                };
            };
        };

        if (_success) then {
            [_taskId,"SUCCEEDED",true] call BIS_fnc_taskSetState;
            missionNamespace setVariable ["Sociostability", (missionNamespace getVariable ["Sociostability",0]) - 2, true];
            private _amt = 4 + floor random 5;
            {
                if (side _x == east && alive _x) then {
                    for "_i" from 1 to _amt do { _x addItem "VRP_HL_Token_Item"; };
                };
            } forEach allPlayers;
            [format ["Terminal hacked. You acquire %1 Tokens.", _amt]]
            remoteExec ["hintSilent", (allPlayers select { side _x == east }) apply { owner _x }];
        } else {
            [_taskId,"FAILED",true] call BIS_fnc_taskSetState;
            missionNamespace setVariable ["Sociostability", (missionNamespace getVariable ["Sociostability",0]) + 1, true];
        };

        sleep 300;
        { if (!isNull _x) then { deleteVehicle _x }; } forEach _allUnits;
        { if (!isNull _x) then { deleteGroup _x }; } forEach _allGroups;
        if (!isNull _terminal) then { deleteVehicle _terminal; };
        [_taskId] call BIS_fnc_deleteTask;
    };
};

};