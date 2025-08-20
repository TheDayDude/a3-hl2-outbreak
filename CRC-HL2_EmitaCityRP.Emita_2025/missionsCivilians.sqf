if (!isServer) exitWith {};

// Pick a random mission ID (1–3 here)
private _missionIndex = selectRandom [1, 2, 3, 4];

switch (_missionIndex) do {
// === Mission 1: Repair Combine Cargo Truck ===
case 1: {
    if (!isServer) exitWith {};

    // Find city_ markers
    private _cityMarkers = allMapMarkers select { toLower _x find "city_" == 0 };
    if (_cityMarkers isEqualTo []) exitWith {
        ["[Civilian Mission] No city_ markers found — mission skipped."] remoteExec ["systemChat", 0];
    };

    private _chosen = selectRandom _cityMarkers;
    private _mPos   = getMarkerPos _chosen;

    // Safe truck spawn close to the marker (not in water)
    private _truckPos = [_mPos, 30, 120, 0, 0, 20, 0] call BIS_fnc_findSafePos;

    // Create damaged cargo truck (unlocked so players can repair/enter)
    private _truck = createVehicle ["B_Truck_01_cargo_F", _truckPos, [], 0, "NONE"];
    _truck setDir random 360;
    _truck lock false;
	 // --- Damage profile (separate + randomized) ---
	_truck setFuel 0.4;
	_truck setDamage 0.65;

	// Discover the truck's hitpoint names
	private _hpData  = getAllHitPointsDamage _truck;       // [names, selections, damages]
	private _hpNames = _hpData select 0;

	// Helper: set a hitpoint by (case-insensitive) name if it exists
	private _setHP = {
		params ["_veh","_hpName","_val","_names"];
		private _idx = _names findIf { toLower _x == toLower _hpName };
		if (_idx >= 0) then { _veh setHitPointDamage [_names select _idx, _val]; };
	};

	// 1) Engine totally busted
	[_truck, "HitEngine", 1.0, _hpNames] call _setHP;

	// 2) Fuel tank damaged but not over 0.9
	private _fuelDmg = 0.5 + random 0.4;  // 0.4–0.7
	[_truck, "HitFuel", _fuelDmg, _hpNames] call _setHP;

	// 3) Blow exactly one random wheel (works with any truck that names wheels)
	private _wheelIdxs = [];
	{
		if (toLower _x find "wheel" > -1) then { _wheelIdxs pushBack _forEachIndex; };
	} forEach _hpNames;

	if (!(_wheelIdxs isEqualTo [])) then {
		private _w = selectRandom _wheelIdxs;
		_truck setHitPointDamage [_hpNames select _w, 1.0];
	};


    // Place + attach a headcrab canister into the bed
    private _can = createVehicle ["HL_CMB_Static_headcrabcannister01a", _truckPos, [], 0, "NONE"];
    _can setDir (getDir _truck);
    // Offset tuned for HEMTT cargo bed: [X (left/right), Y (back/forward), Z (up)]
    _can attachTo [_truck, [0, -1.6, 0.35]];
    _can setVectorUp [0,0,1];
	// Rotate 90° sideways
	private _dirVec = [1, 0, 0];   // forward direction vector (right side of truck)
	private _upVec  = [0, 0, 1];   // up vector (keep upright)
	_can setVectorDirAndUp [_dirVec, _upVec];

    // Spawn 2–5 headcrabs (resistance) around the truck, nudge toward it
    private _hcGrp  = createGroup resistance;
    private _hcCnt  = 2 + floor random 4;
    private _hcList = [];
    for "_i" from 1 to _hcCnt do {
        private _p = [_truckPos, 5, 20, 0, 5, 0.3, 0] call BIS_fnc_findSafePos;
        private _u = _hcGrp createUnit ["WBK_Headcrab_Normal", _p, [], 0, "FORM"];
        _u doMove _truckPos;
        _hcList pushBack _u;
    };
    _hcGrp setBehaviour "AWARE";
    _hcGrp setCombatMode "RED";

    // Task for Civilians
    private _taskId = format ["task_repairCargo_%1", diag_tickTime];
    [civilian, _taskId,
        ["Greetings Citizen. You have chosen, or been chosen, to assist as a Civil Engineer. Find yourself a toolkit if you haven't already and make your way to the broken vehicle designated here. Repair it and drive it to the garage next to the Civil Administration Center. Toolkits can be purchased from CWU approved shopkeeps.",
         "Repair Combine Cargo Truck", ""],
        _truckPos, true
    ] call BIS_fnc_taskCreate;

    // Monitor success/fail
    [_taskId, _truck, _hcGrp, _hcList, _can] spawn {
        params ["_taskId","_truck","_hcGrp","_hcList","_can"];

        private _deadline = time + 2700;
        private _success  = false;

        waitUntil {
            sleep 2;
            _success = (alive _truck) && (_truck inArea CombineGarage);
            _success || !alive _truck || (time > _deadline)
        };

        if (_success) then {
            [_taskId, "SUCCEEDED", true] call BIS_fnc_taskSetState;

            private _amt = 3 + floor random 5; // 3–7
            {
                if (side _x == civilian && alive _x) then {
                    for "_i" from 1 to _amt do { _x addItem "VRP_HL_Token_Item"; };
                };
            } forEach allPlayers;
            [format ["Truck delivered. You receive %1 Tokens.", _amt]]
                remoteExec ["hintSilent", (allPlayers select { side _x == civilian }) apply { owner _x }];
                missionNamespace setVariable ["Sociostability", (missionNamespace getVariable ["Sociostability",0]) + 1, true];

            // Keep the truck; clean up creatures/prop after 5 min
            sleep 300;
            { if (!isNull _x) then { deleteVehicle _x } } forEach units _hcGrp;
            deleteGroup _hcGrp;
            if (!isNull _can) then { detach _can; deleteVehicle _can; };

        } else {
            [_taskId, "FAILED", true] call BIS_fnc_taskSetState;
            ["Cargo recovery failed."] remoteExec ["systemChat", (allPlayers select { side _x == civilian }) apply { owner _x }];
			["Attention occupants: your block is now charged with permissive inaction coercion. 5 ration units deducted."] remoteExec ["systemChat", 0];
			["Frationunitsdeduct3spkr"] remoteExec ["playSound", 0];
            missionNamespace setVariable ["Sociostability", (missionNamespace getVariable ["Sociostability",0]) - 1, true];
            missionNamespace setVariable ["RationStock", (missionNamespace getVariable ["RationStock",0]) - 5, true];

            // Cleanup all after 5 min (truck if still alive, headcrabs, prop)
            sleep 300;
            { if (!isNull _x) then { deleteVehicle _x } } forEach units _hcGrp;
            deleteGroup _hcGrp;
            if (!isNull _can) then { detach _can; deleteVehicle _can; };
            if (!isNull _truck) then { deleteVehicle _truck; };
        };

        sleep 10;
        [_taskId] call BIS_fnc_deleteTask;
    };
};

// === Case 2: Treat CPF Officers (Civilians w/ medical item) ===
case 2: {
    if (!isServer) exitWith {};
	
	// Runs on CLIENT: attach the Treat action to a given unit
	if (isNil "CIV_fnc_addTreatAction") then {
		CIV_fnc_addTreatAction = {
			params ["_u"];
			if (isNull _u) exitWith {};

			_u addAction [
				"<t color='#80FF80'>Treat Officer (uses 1 medical item)</t>",
				{
					params ["_target", "_caller"];

					if (side _caller != civilian) exitWith { hint "Civilians only."; };
					if (_target getVariable ["treated", false]) exitWith { hint "Already treated."; };

					private _items      = items _caller;
					private _fakClasses = ["FirstAidKit","rds_car_FirstAidKit"];
					private _hasMedKit  = ("Medikit" in _items) || ("Medikit_Civilian_01" in _items);
					private _hasFAK     = (_items findIf { _x in _fakClasses }) > -1;
					private _hasStim    = "WBK_Health_Syringe" in _items;

					if (!(_hasMedKit || _hasFAK || _hasStim)) exitWith {
						hint "You need a Medikit, First Aid Kit (vanilla or RDS), or Stim.";
					};

					// Local treat animation on caller
					_caller playMoveNow "AinvPknlMstpSnonWnonDnon_medic_1";
					uiSleep 8;
					_caller switchMove "";
					sleep 2;

					// Consume: FAK > Stim; Medikit reusable
					if (_hasFAK) then {
						private _fakToUse = (_items select { _x in _fakClasses }) param [0, ""];
						if (_fakToUse != "") then { _caller removeItem _fakToUse; };
					} else {
						if (_hasStim) then { _caller removeItem "WBK_Health_Syringe"; };
					};

					// Do the revive on the server
					[_target] remoteExec ["CIV_fnc_treatServer", 2];

					hint "Officer treated.";
				},
				nil, 1.5, true, true, "",
				// condition runs client-side; _this is player, _target is officer
				"side _this == civilian && !(_target getVariable ['treated', false])"
			];
		};
		publicVariable "CIV_fnc_addTreatAction";
	};
	
	// Runs on SERVER: actually “revive” the target
	if (isNil "CIV_fnc_treatServer") then {
		CIV_fnc_treatServer = {
			params ["_t"];
			if (isNull _t) exitWith {};
			_t setDamage 0.2;
			_t enableAI "MOVE";
			_t enableAI "TARGET";
			_t enableAI "AUTOTARGET";
			_t switchMove "";
			_t setVariable ["treated", true, true];
			_t doMove (_t getPos [5 + random 5, random 360]);
		};
		publicVariable "CIV_fnc_treatServer";
	};

    private _ptMarkers = allMapMarkers select { toLower _x find "patient_" == 0 };
    if (_ptMarkers isEqualTo []) exitWith {
        ["[CIV Mission] No patient_ markers found — mission skipped."] remoteExec ["systemChat", 0];
    };

    private _count   = 3 + floor random 4;                 // 3–6 patients
    _ptMarkers       = _ptMarkers call BIS_fnc_arrayShuffle;
    private _chosen  = _ptMarkers select [0, (_count min (count _ptMarkers))];

    private _taskId  = format ["task_treatCPF_%1", diag_tickTime];
    private _taskPos = getMarkerPos (_chosen select 0);
    [civilian, _taskId,
        ["Stabilize all downed Civil Protection officers. Civilians must use a medical item (Medikit / FirstAidKit / Stim).",
         "Treat CPF Officers", ""],
        _taskPos, true
    ] call BIS_fnc_taskCreate;

    private _cpTypes = ["WBK_Combine_CP_P","WBK_Combine_CP_SMG"];

    private _grp       = createGroup west;
    private _patients  = [];
    missionNamespace setVariable ["CIV_PATIENTS_DEAD", 0, true];

    {
        private _mPos   = getMarkerPos _x;
        private _posATL = _mPos vectorAdd [0,0,0.25];     // sit on stretcher a bit better

        private _u = _grp createUnit [selectRandom _cpTypes, _posATL, [], 0, "NONE"];
        _u setPosATL _posATL;
        _u setDir (random 360);

        // Downed state
        _u disableAI "MOVE";
        _u disableAI "TARGET";
        _u disableAI "AUTOTARGET";
        _u setDamage 0.75;
        _u switchMove "AinjPpneMstpSnonWnonDnon";
        _u setVariable ["treated", false, true];

		// Add the action on all clients (JIP-safe)
		[_u] remoteExec ["CIV_fnc_addTreatAction", 0, true];


        // Deaths count toward failure (server-local object, fine here)
        _u addEventHandler ["Killed", {
            missionNamespace setVariable [
                "CIV_PATIENTS_DEAD",
                1 + (missionNamespace getVariable ["CIV_PATIENTS_DEAD", 0]),
                true
            ];
        }];

        _patients pushBack _u;
    } forEach _chosen;

    // Monitor success/fail and clean up
    [_taskId,_patients,_grp] spawn {
        params ["_taskId","_patients","_grp"];
        private _deadline = time + 2700;

        waitUntil {
            sleep 3;
            private _treated = { _x getVariable ["treated", false] } count _patients;
            private _dead    = missionNamespace getVariable ["CIV_PATIENTS_DEAD", 0];

            if (_treated >= (count _patients)) exitWith {
                [_taskId, "SUCCEEDED", true] call BIS_fnc_taskSetState;
                missionNamespace setVariable ["Sociostability", (missionNamespace getVariable ["Sociostability",0]) + 1, true];

                // Reward civilians present (2–5 tokens each)
                private _amt = 3 + floor random 6;
                {
                    if (side _x == civilian && alive _x) then {
                        for "_i" from 1 to _amt do { _x addItem "VRP_HL_Token_Item"; };
                    };
                } forEach allPlayers;

                [format ["All officers stabilized. You received %1 token(s).", _amt]]
                    remoteExec ["hintSilent", (allPlayers select { side _x == civilian }) apply { owner _x }];
                true
            };

            if (_dead >= 2 || time > _deadline) exitWith {
                [_taskId, "FAILED", true] call BIS_fnc_taskSetState;
                ["Medical response failed — insufficient successful treatments."] remoteExec ["systemChat", 0];
                ["Attention occupants: your block is now charged with permissive inaction coercion. 5 ration units deducted."] remoteExec ["systemChat", 0];
                ["Frationunitsdeduct3spkr"] remoteExec ["playSound", 0];
                missionNamespace setVariable ["Sociostability", (missionNamespace getVariable ["Sociostability",0]) - 1, true];
                missionNamespace setVariable ["RationStock", (missionNamespace getVariable ["RationStock",0]) - 5, true];
                true
            };

            false
        };

        // Cleanup after 60s
        sleep 60;
        { if (!isNull _x) then { deleteVehicle _x }; } forEach _patients;
        deleteGroup _grp;

        sleep 5;
        [_taskId] call BIS_fnc_deleteTask;
        missionNamespace setVariable ["CIV_PATIENTS_DEAD", 0, true];
    };
};

// === Case 3: Cleanup Detail 
case 3: {
    if (!isServer) exitWith {};

    // ----- Helpers (client addAction + server corpse->bag) -----
    if (isNil "CIV_fnc_addCleanupBagAction") then {
        CIV_fnc_addCleanupBagAction = {
            params ["_corpse"];
            if (isNull _corpse || alive _corpse) exitWith {};
            if (_corpse getVariable ["hasCleanupBagActions", false]) exitWith {};
            _corpse setVariable ["hasCleanupBagActions", true, true];

            _corpse addAction [
                "<t color='#FFD700'>Bag body</t>",
                {
                    params ["_corpse","_caller"];
                    if (isNull _corpse || alive _corpse) exitWith {};

                    // small “work” animation on the caller (client-local)
                    _caller playMoveNow "AinvPknlMstpSnonWnonDnon_medic_1";
                    uiSleep 3.5;
                    _caller switchMove "";

                    // do the actual spawn/delete on the server
                    [_corpse] remoteExec ["CIV_fnc_bagCorpseServer", 2];
                },
                nil, 1.5, true, true, "",
                "!(alive _target)"   // condition runs client-side
            ];
        };
        publicVariable "CIV_fnc_addCleanupBagAction";
    };

    if (isNil "CIV_fnc_bagCorpseServer") then {
        CIV_fnc_bagCorpseServer = {
            params ["_c"];
            if (isNull _c) exitWith {};
            private _pos = getPosATL _c;
            private _dir = getDir _c;

            private _bag = createVehicle ["CBRN_Bodybag_Closed", _pos, [], 0, "NONE"];
            _bag setDir _dir;

            // ACE friendliness if available
			[_bag, true] remoteExecCall ["ACE_dragging_fnc_setDraggable", 0, _bag];
			[_bag, 2]    remoteExecCall ["ACE_cargo_fnc_setSize",        0, _bag];

            hideBody _c; deleteVehicle _c;
        };
        publicVariable "CIV_fnc_bagCorpseServer";
    };
    // -----------------------------------------------------------

    // Pick a city_ marker and center the job nearby (tight cluster)
    private _cityMarkers = allMapMarkers select { toLower _x find "city_" == 0 };
    if (_cityMarkers isEqualTo []) exitWith {
        ["[CIV Mission] No city_ markers found — mission skipped."] remoteExec ["systemChat", 0];
    };

    private _chosenMarker = selectRandom _cityMarkers;
    private _center       = getMarkerPos _chosenMarker;

    // Civ task
    private _taskId = format ["task_cleanup_%1", diag_tickTime];
    [civilian, _taskId,
        ["You have been selected to work with the wonderful SANITATION arm of the Civil Workers Union. What a glorious opportunity! Please report to the location and begin bagging the BIOTIC WASTE into UU approved containment bags. Take these bags to the CREMATORIUM and drop them in the furnace for a well deserved reward. Remember citizen: a clean city is a productive city.",
         "Sanitation Duty", ""],
        _center, true
    ] call BIS_fnc_taskCreate;

    // Spawn corpses + a few props close to center
    private _toSpawn = 8 + floor random 6; // 8–12
    private _classes = [
        "cmb_worker","cmb_hz_worker","Civilian_Jumpsuit_Unit_4","HL_CIV_Man_01","HL_CIV_Man_02",
        "WBK_Rebel_SMG_1","WBK_HECU_Hazmat_2","WBK_Rebel_HL2_Refugee_4","WBK_HL_Conscript_6",
        "WBK_ClassicZombie_HLA_1","WBK_ClassicZombie_HLA_2","WBK_ClassicZombie_HLA_3",
        "WBK_ClassicZombie_HLA_4","WBK_ClassicZombie_HLA_5","WBK_ClassicZombie_HLA_6",
        "WBK_ClassicZombie_HLA_8","WBK_ClassicZombie_HLA_9"
    ];

    private _props = [];
    {
        private _p = [_center, 5, 30, 3, 0, 20, 0] call BIS_fnc_findSafePos;
        private _obj = createVehicle [_x, _p, [], 0, "NONE"];
        _obj setDir random 360;
        _props pushBack _obj;
    } forEach ["Land_Wreck_CarDismantled_F","Land_Garbage_square3_F","Land_Tyres_F"];

    private _corpses = [];
    for "_i" from 1 to _toSpawn do {
        private _pos = [_center, 5, 30, 1, 0, 20, 0] call BIS_fnc_findSafePos;
        private _grp = createGroup civilian;
        private _u   = _grp createUnit [selectRandom _classes, _pos, [], 0, "NONE"];
        uiSleep 0.1;
        _u setDamage 1;

        if (random 1 < 0.9) then {
            removeAllWeapons _u;
            removeAllItems _u;
            removeAllAssignedItems _u;
        };

        if (typeOf _u == "cmb_hz_worker") then { _u forceAddUniform "CombainCIV_Uniform_2"; };
        if (typeOf _u == "cmb_worker")     then { _u forceAddUniform "CombainCIV_Uniform_1"; };

        _corpses pushBack _u;

        // Add the action on all clients (JIP-safe)
        [_u] remoteExec ["CIV_fnc_addCleanupBagAction", 0, true];
    };
	
	private _required = ((count _corpses) - 1) max 1;  // need one fewer than spawned, but at least 1

    // Optional Strange Meat drops near the cleanup center
    private _meatDrops = [];
    if (random 1 < 0.80) then {
        private _count = 0 + floor random 5;  // 0–5 holders
        for "_i" from 1 to _count do {
            private _mPos = [_center, 3, 12, 1, 0, 20, 0] call BIS_fnc_findSafePos;
            private _holder = createVehicle ["GroundWeaponHolder_Scripted", _mPos, [], 0, "CAN_COLLIDE"];
            _holder addItemCargoGlobal ["VRP_StrangeMeat", 1 + floor random 2];
            _meatDrops pushBack _holder;
        };
    };

    // Progress: count actual body bag props in furnace
    private _counted = [];
    private _delivered = 0;
    private _deadline  = time + 2700;
    private _lastTick  = -1;

    {
        if (side _x == civilian) then {
            _x sideChat format ["Cleanup started near %1. Bag bodies and deliver to the Crematorium.", _chosenMarker];
        };
    } forEach allPlayers;

    while { _delivered < _required && time < _deadline } do {
        sleep 2;
        private _bags = allMissionObjects "CBRN_Bodybag_Closed";
        {
            if (!isNull _x && {_x inArea furnace} && {!(_x in _counted)}) then {
                _counted pushBack _x;
                _delivered = _delivered + 1;
                [_x] spawn { params["_b"]; uiSleep 3; if (!isNull _b) then { deleteVehicle _b; }; };
            };
        } forEach _bags;

        if (time > _lastTick + 10) then {
            [format ["Cleanup progress: %1 / %2 bodies delivered.", _delivered, _required]]
                remoteExec ["hintSilent", (allPlayers select { side _x == civilian }) apply { owner _x }];
            _lastTick = time;
        };
    };

    // Outcome
    if (_delivered >= _required) then {
        [_taskId, "SUCCEEDED", true] call BIS_fnc_taskSetState;

        private _amt = _required;
        {
            if (side _x == civilian && alive _x) then {
                for "_i" from 1 to _amt do { _x addItem "VRP_HL_Token_Item"; };
            };
        } forEach allPlayers;

        [format ["Cleanup complete. You received %1 Tokens.", _amt]]
            remoteExec ["hintSilent", (allPlayers select { side _x == civilian }) apply { owner _x }];
            missionNamespace setVariable ["Infestation", (missionNamespace getVariable ["Infestation",0]) - 1, true];
    } else {
        [_taskId, "FAILED", true] call BIS_fnc_taskSetState;
        ["Cleanup failed — time limit exceeded."]
            remoteExec ["systemChat", (allPlayers select { side _x == civilian }) apply { owner _x }];
            missionNamespace setVariable ["Infestation", (missionNamespace getVariable ["Infestation",0]) + 1, true];
    };

    // Cleanup spawned props (bags are removed when delivered)
    { if (!isNull _x) then { deleteVehicle _x }; } forEach _props;

    sleep 5;
    [_taskId] call BIS_fnc_deleteTask;
};

// === Case 4: Spread Propaganda ===
case 4: {
    if (!isServer) exitWith {};

    if (isNil "CIV_fnc_addPropagandaAction") then {
        CIV_fnc_addPropagandaAction = {
            params ["_civ"];
            if (isNull _civ) exitWith {};
            _civ addAction [
                "<t color='#FFFF80'>Praise Universal Union</t>",
                {
                    params ["_target", "_caller"];
                    if (side _caller != civilian) exitWith { hint "Civilians only."; };
                    if (_target getVariable ["prop_result",0] != 0) exitWith {};
                    _caller playMoveNow "Acts_CivilTalking_1";
                    [_caller] spawn { params ["_c"]; uiSleep 8; _c switchMove ""; };
                    [_target,_caller] remoteExec ["CIV_fnc_propagandaServer",2];
                },
                nil, 1.5, true, true, "",
                "side _this == civilian && {_target getVariable ['prop_result',0] == 0}",
                4
            ];
            _civ addAction [
                "<t color='#FF4040'>Incite Rebellion</t>",
                {
                    params ["_target", "_caller"];
                    if (side _caller != civilian) exitWith { hint "Civilians only."; };
                    if (_target getVariable ["prop_result",0] != 0) exitWith {};
                    _caller playMoveNow "Acts_CivilTalking_1";
                    [_caller] spawn { params ["_c"]; uiSleep 8; _c switchMove ""; };
                    [_target,_caller] remoteExec ["CIV_fnc_inciteServer",2];
                },
                nil, 1.5, true, true, "",
                "side _this == civilian && {_target getVariable ['prop_result',0] == 0}",
                4
            ];
        };
        publicVariable "CIV_fnc_addPropagandaAction";
    };

    if (isNil "CIV_fnc_removePropagandaAction") then {
        CIV_fnc_removePropagandaAction = {
            params ["_u"];
            if (isNull _u) exitWith {};
            removeAllActions _u;
        };
        publicVariable "CIV_fnc_removePropagandaAction";
    };

    // Helper to make a civilian walk away and despawn
    if (isNil "CIV_fnc_walkAwayAndDespawn") then {
        CIV_fnc_walkAwayAndDespawn = {
            params ["_u"];
            if (isNull _u) exitWith {};
            private _far = [getPos _u, 500, 800, 0, 0, 20, 0] call BIS_fnc_findSafePos;
            _u doMove _far;
            [_u] spawn {
                params ["_c"];
                sleep 60;
                if (!isNull _c) then { deleteVehicle _c };
            };
        };
        publicVariable "CIV_fnc_walkAwayAndDespawn";
    };

    missionNamespace setVariable ["CIV_Prop_PosCount",0];
    missionNamespace setVariable ["CIV_Prop_NegCount",0];

    if (isNil "CIV_fnc_propagandaServer") then {
        CIV_fnc_propagandaServer = {
            params ["_target","_caller"];
            if (isNull _target || isNull _caller) exitWith {};
            if (_target getVariable ["prop_result",0] != 0) exitWith {};
            removeAllActions _target;
            [_target] remoteExec ["CIV_fnc_removePropagandaAction",0,true];
            _target playMoveNow "Acts_CivilListening_1";
            uiSleep 8;
            _target switchMove "";
            if (random 1 < 0.62) then {
                [_target, "rebel_announcekill_07"] remoteExecCall ["say3D", 0];
                _target setVariable ["prop_result", 1, true];
                ["Citizen: You're right, if we just keep our heads down and work hard, the Union will reward us."] remoteExec ["systemChat", owner _caller];
                missionNamespace setVariable ["Sociostability", (missionNamespace getVariable ["Sociostability",0]) + 0.1, true];
                missionNamespace setVariable ["CIV_Prop_PosCount", (missionNamespace getVariable ["CIV_Prop_PosCount",0]) + 1];
            } else {
                [_target, "rebel_squadmemberlost_01"] remoteExecCall ["say3D", 0];
                _target setVariable ["prop_result", -1, true];
                ["Citizen: Get lost - loyalist scum."] remoteExec ["systemChat", owner _caller];
                missionNamespace setVariable ["CIV_Prop_NegCount", (missionNamespace getVariable ["CIV_Prop_NegCount",0]) + 1];
            };
            [_target] call CIV_fnc_walkAwayAndDespawn;
        };
        publicVariable "CIV_fnc_propagandaServer";
    };

    if (isNil "CIV_fnc_inciteServer") then {
        CIV_fnc_inciteServer = {
            params ["_target","_caller"];
            if (isNull _target || isNull _caller) exitWith {};
            if (_target getVariable ["prop_result",0] != 0) exitWith {};
            removeAllActions _target;
            [_target] remoteExec ["CIV_fnc_removePropagandaAction",0,true];
            _target playMoveNow "Acts_CivilListening_1";
            uiSleep 8;
            _target switchMove "";
            if (random 1 < 0.7) then {
                [_target, "rebel_announcekill_07"] remoteExecCall ["say3D", 0];
                _target setVariable ["prop_result", -1, true];
                ["Citizen: The Combine will fall!"] remoteExec ["systemChat", owner _caller];
                missionNamespace setVariable ["Sociostability", (missionNamespace getVariable ["Sociostability",0]) - 0.1, true];
                missionNamespace setVariable ["CIV_Prop_NegCount", (missionNamespace getVariable ["CIV_Prop_NegCount",0]) + 1];
            } else {
                [_target, "rebel_fireAt_CP_2"] remoteExecCall ["say3D", 0];
                _target setVariable ["prop_result", 1, true];
                ["Citizen: I'm reporting you to Civil Protection!"] remoteExec ["systemChat", owner _caller];
                if (random 1 < 0.7) then {
                    [_caller] joinSilent createGroup east;
                    private _callerPos = position _caller;
                    private _huntPos = [_callerPos, 200, 200, 0, 0, 20, 0] call BIS_fnc_findSafePos;
                    private _huntGrp = createGroup west;
                    for "_i" from 1 to (2 + floor random 2) do {
                        _huntGrp createUnit [selectRandom ["WBK_Combine_CP_P","WBK_Combine_CP_SMG"], _huntPos, [], 5, "FORM"];
                    };
                    _huntGrp setBehaviour "COMBAT";
                    _huntGrp setCombatMode "RED";
                     _huntGrp move _callerPos;
                    [_huntGrp,_caller] spawn {
                        params ["_grp","_tgt"];
                        while {alive _tgt && {count units _grp > 0}} do {
                            _grp move position _tgt;
                            sleep 15;
                        };
                    };
                };
                missionNamespace setVariable ["CIV_Prop_PosCount", (missionNamespace getVariable ["CIV_Prop_PosCount",0]) + 1];
            };
            [_target] call CIV_fnc_walkAwayAndDespawn;
        };
        publicVariable "CIV_fnc_inciteServer";
    };

    private _cityMarkers = allMapMarkers select { toLower _x find "city_" == 0 };
    if (_cityMarkers isEqualTo []) exitWith {
        ["[CIV Mission] No city_ markers found — mission skipped."] remoteExec ["systemChat", 0];
    };

    private _chosen = selectRandom _cityMarkers;
    private _center = getMarkerPos _chosen;

    private _taskId = format ["task_propaganda_%1", diag_tickTime];
    [civilian, _taskId,
        ["Citizen, spread glorious words of the Universal Union. Workers are gathering at this location - dissuade them from anticivil acts.",
         "Spread Propaganda", ""],
        _center, true
    ] call BIS_fnc_taskCreate;

    private _cnt = 10;
    private _civs = [];
    for "_i" from 1 to _cnt do {
        private _pos = [_center, 5, 80, 0, 0, 20, 0] call BIS_fnc_findSafePos;
        private _grp = createGroup civilian;
        private _c = _grp createUnit ["CombainCIV_Uniform_1_Body", _pos, [], 0, "FORM"];
        _grp setBehaviour "SAFE";
        _grp setSpeedMode "LIMITED";
        _c setVariable ["prop_result", 0, true];
        [_c] remoteExec ["CIV_fnc_addPropagandaAction", 0, true];
        [_grp, _center, 40] call BIS_fnc_taskPatrol;
        _civs pushBack _c;
    };

    private _deadline = time + 2700;
    private _posCount = 0;
    waitUntil {
        sleep 5;
        _posCount = missionNamespace getVariable ["CIV_Prop_PosCount",0];
        (_posCount >= 5) || (time > _deadline)
    };

    if (_posCount >= 5) then {
        [_taskId, "SUCCEEDED", true] call BIS_fnc_taskSetState;
        missionNamespace setVariable ["Sociostability", (missionNamespace getVariable ["Sociostability",0]) + 1, true];
        private _amt = 2 + floor random 3; // 2–4 tokens
        {
            if (side _x == civilian && alive _x) then {
                for "_i" from 1 to _amt do { _x addItem "VRP_HL_Token_Item"; };
            };
        } forEach allPlayers;
        [format ["Propaganda successful. You received %1 Tokens.", _amt]]
            remoteExec ["hintSilent", (allPlayers select { side _x == civilian }) apply { owner _x }];
    } else {
        [_taskId, "FAILED", true] call BIS_fnc_taskSetState;
        ["Propaganda attempt failed."] remoteExec ["systemChat", (allPlayers select { side _x == civilian }) apply { owner _x }];
        missionNamespace setVariable ["Sociostability", (missionNamespace getVariable ["Sociostability",0]) - 1, true];
    };

    { if (!isNull _x) then { deleteVehicle _x } } forEach _civs;
    missionNamespace setVariable ["CIV_Prop_PosCount",nil];
    missionNamespace setVariable ["CIV_Prop_NegCount",nil];
    sleep 5;
    [_taskId] call BIS_fnc_deleteTask;
};


};