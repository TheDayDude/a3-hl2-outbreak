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
        private _count = 4 + floor random 3; // 4–6 per group
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
    if (random 1 < 0.25) then {
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

// === Mission 2: Hack Combine Terminal  ===
case 2: {
    if (!isServer) exitWith {};

    private _cmbMarkers = allMapMarkers select { toLower _x find "combine_" == 0 };
    if (_cmbMarkers isEqualTo []) exitWith {
        ["[Rebel Mission] No combine_ markers found — mission skipped."] remoteExec ["systemChat", 0];
    };

    private _chosenMarker = selectRandom _cmbMarkers;
    private _center       = getMarkerPos _chosenMarker;

    // Track for cleanup
    private _groups = [];
    private _units  = [];
    private _props  = [];

    // Terminal prop
    private _terminal = createVehicle ["HL_CMB_Static_interface002", _center, [], 0, "NONE"];
    _terminal setDir random 360;
    _props pushBack _terminal;
	
	// Initial Combine guards at the terminal
	private _guardGrp = createGroup west;
	for "_i" from 1 to (3 + floor random 3) do { // 3–5 guards
		private _pos = _center getPos [5 + random 3, random 360]; // 5–8m from terminal
		private _u = _guardGrp createUnit ["WBK_Combine_HL2_Type", _pos, [], 0, "NONE"];
		_u setDir ([_u, _terminal] call BIS_fnc_dirTo);
		_units pushBack _u; // track for cleanup
	};
	_guardGrp setBehaviour "AWARE";
	_guardGrp setCombatMode "RED";
	_groups pushBack _guardGrp; // track for cleanup

    // EAST task
    private _taskId  = format ["task_hackTerminal_%1", diag_tickTime];
    [east, _taskId,
        ["Hack the Combine terminal (5:00). Defend the area and resume the hack when it pauses.",
         "Hack Combine Terminal", ""],
        _center, true
    ] call BIS_fnc_taskCreate;

    // Action flags
    _terminal setVariable ["hackStartRequest", false, true];
    _terminal setVariable ["hackResumeRequest", false, true];

    // Start action (EAST only)
    private _startActId = _terminal addAction [
        "<t color='#00FF88'>Start Hacking</t>",
        {
            params ["_t","_c"];
            if (side _c == east) then { _t setVariable ["hackStartRequest", true, true]; }
            else { _c sideChat "Only rebels can start the hack."; };
        },
        nil, 1.5, true, true, "", "side _this == east"
    ];

    // Pools
    private _combInf = [
        "WBK_Combine_Grunt",
        "WBK_Combine_Grunt_white",
        "WBK_Combine_HL2_Type_WastelandPatrol",
        "WBK_Combine_HL2_Type_WastelandPatrol",
        "WBK_Combine_HL2_Type",
        "WBK_Combine_HL2_Type_AR"
    ];
    private _combElite = [
        "WBK_Combine_HL2_Type_Elite","WBK_Combine_ASS_SMG",
        "WBK_Combine_Ordinal","WBK_Combine_APF"
    ];

    // Helpers
    private _fmtTime = {
        params ["_t"];
        private _m = floor (_t / 60);
        private _s = _t mod 60;
        private _pad = { params ["_n"]; if (_n < 10) then { format ["0%1", _n] } else { str _n } };
        format ["%1:%2", [_m] call _pad, [_s] call _pad]
    };
    private _showUi = {
        params ["_txt"];
        private _targets = (allPlayers select { side _x == east }) apply { owner _x };
        [_txt] remoteExec ["hintSilent", _targets];
    };
    private _defendersNear = {
        params ["_pos"];
        count (allUnits select { side _x == east && alive _x && _x distance2D _pos < 100 })
    };

    // Spawn one ground wave; return the group so caller can track it
    private _spawnWave = {
        params ["_towardPos","_combInf"];
        private _grp = createGroup west;
        private _n   = 6 + floor random 5; 
        for "_i" from 1 to _n do {
            private _pos = [_towardPos, 250 + random 100, random 360, 0, 20, 0.3, 0] call BIS_fnc_findSafePos;
            private _u   = _grp createUnit [selectRandom _combInf, _pos, [], 5, "FORM"];
            _units pushBack _u;
        };
        _grp setBehaviour "AWARE";
        _grp setCombatMode "RED";
        _grp addWaypoint [_towardPos, 0] setWaypointType "SAD";
        _groups pushBack _grp;
        _grp
    };

    // One-time elite heli fly-by drop (no landing)
    private _callEliteHelo = {
        params ["_objPos","_combElite"];
        private _spawn2D = [_objPos, 1200 + random 600, random 360] call BIS_fnc_relPos;
        private _spawn3D = _spawn2D vectorAdd [0,0,120];

        private _heli = createVehicle ["B_Heli_Transport_03_unarmed_F", _spawn3D, [], 0, "FLY"];
        createVehicleCrew _heli;
        _heli setDir ([_heli, _objPos] call BIS_fnc_dirTo);
        _heli flyInHeight 100;
        _heli lock true;
        _props pushBack _heli;
        { _units pushBack _x } forEach (crew _heli);

        // Cargo (6–8 elites)
        private _eliteGrp = createGroup west;
        for "_i" from 1 to (6 + floor random 3) do {
            private _u = _eliteGrp createUnit [selectRandom _combElite, _spawn2D, [], 0, "NONE"];
            _u moveInCargo _heli;
            _units pushBack _u;
        };
        _eliteGrp setBehaviour "COMBAT";
        _eliteGrp setCombatMode "RED";
        _groups pushBack _eliteGrp;

        // Pilot route: pass over then exit
        private _pilotGrp = group driver _heli;
        _groups pushBack _pilotGrp;
        (_pilotGrp addWaypoint [_objPos, 0]) setWaypointType "MOVE";
        private _exit = _objPos getPos [3000 + random 1000, random 360];
        (_pilotGrp addWaypoint [_exit, 0]) setWaypointType "MOVE";

        // Fly-by eject
        [_heli, _eliteGrp, _objPos] spawn {
            params ["_heli","_grp","_objPos"];
            waitUntil { sleep 0.25; (_heli distance2D _objPos) < 150 };
            {
                if (vehicle _x == _heli) then {
                    unassignVehicle _x; moveOut _x;
                    _x setUnitPos "MIDDLE"; _x doMove _objPos;
                };
            } forEach units _grp;

            // Let the heli leave; mission cleanup will delete it
        };
    };

    // === Main mission thread ===
    [_terminal,_center,_taskId,_combInf,_combElite,_spawnWave,_callEliteHelo,_startActId,_fmtTime,_showUi,_defendersNear,_groups,_units,_props] spawn {
        params ["_terminal","_center","_taskId","_combInf","_combElite","_spawnWave","_callEliteHelo","_startActId","_fmtTime","_showUi","_defendersNear","_groups","_units","_props"];
        scopeName "HACK_SCOPE";

        private _hackTime    = 300;        // 5 minutes
        private _deadline    = time + 3600;
        private _active      = false;
        private _paused      = false;
        private _lastWave    = 0;
        private _waveGap     = 75;
        private _graceStart  = -1;
        private _resumeActId = -1;
        private _nextUiTick  = 0;
        private _heliCalled  = false;

        while {true} do {
            sleep 1;

            // Start?
            if (!_active && _terminal getVariable ["hackStartRequest", false]) then {
                _active = true;
                _terminal setVariable ["hackStartRequest", false, true];
                if (_startActId >= 0) then { _terminal removeAction _startActId; };
                [format ["Hacking. Time Left: %1", [_hackTime] call _fmtTime]] call _showUi;
                ["Hack started. Hold the area!"] remoteExec ["systemChat", (allPlayers select { side _x == east }) apply { owner _x }];
				["Attention, ground units - anticitizen reported in this community. Code: lock, cauterize, stabilize."] remoteExec ["systemChat", 0];
				["Fanticitizenreportspkr"] remoteExec ["playSound", 0];
            };

            if (_active) then {
                // Defender check (30s grace if empty)
                if ([_center] call _defendersNear == 0) then {
                    if (_graceStart < 0) then { _graceStart = time };
                    if ((time - _graceStart) > 30) then {
                        [_taskId, "FAILED", true] call BIS_fnc_taskSetState;
                        ["Hack failed — no rebels defending the terminal."] remoteExec ["systemChat", 0];
                        ["" ] call _showUi;
						{
							{ if (!isNull _x) then { deleteVehicle _x }; } forEach units _x;
							deleteGroup _x;
						} forEach _groups;

						{ if (!isNull _x) then { deleteVehicle _x }; } forEach _props;

						{
							if (!isNull _x && {!alive _x || {!(_x isKindOf 'Man')}}) then { deleteVehicle _x };
						} forEach _units;

						// remove the task
						sleep 10;
						[_taskId] call BIS_fnc_deleteTask;
                        breakOut "HACK_SCOPE";
                    };
                } else { _graceStart = -1; };

                // Random pauses
                if (!_paused && (random 1) < 0.01) then {
                    _paused = true;
                    _resumeActId = _terminal addAction [
                        "<t color='#FFA500'>Resume Hacking</t>",
                        { (_this select 0) setVariable ["hackResumeRequest", true, true]; },
                        nil, 1.5, true, true, "", "side _this == east"
                    ];
                    [format ["Hack paused at %1", [_hackTime] call _fmtTime]] call _showUi;
                    ["Hack paused! Resume at terminal."] remoteExec ["systemChat", (allPlayers select { side _x == east }) apply { owner _x }];
                };

                // Resume?
                if (_paused && _terminal getVariable ["hackResumeRequest", false]) then {
                    _paused = false;
                    _terminal setVariable ["hackResumeRequest", false, true];
                    if (_resumeActId >= 0) then { _terminal removeAction _resumeActId; _resumeActId = -1; };
                    [format ["Hack resumed. Time remaining: %1", [_hackTime] call _fmtTime]] call _showUi;
                    ["Hack resumed."] remoteExec ["systemChat", (allPlayers select { side _x == east }) apply { owner _x }];
                };

                // Tick when not paused
                if (!_paused) then { _hackTime = _hackTime - 1; };

                // UI every 1s
                if (time >= _nextUiTick) then {
                    private _mmss = [_hackTime] call _fmtTime;
                    private _label = if (_paused) then {"Paused"} else {"Hacking"};
                    [format ["%1 %2", _label, _mmss]] call _showUi;
                    _nextUiTick = time + 1;
                };

                // Waves
                if ((time - _lastWave) > _waveGap) then {
                    [_center,_combInf] call _spawnWave;
                    _lastWave = time;
                };

                // Final-minute heli (once)
                if (_hackTime <= 120 && !_heliCalled) then {
                    _heliCalled = true;
                    [_center,_combElite] call _callEliteHelo;
                };

                // Success
                if (_hackTime <= 0) then {
                    [_taskId, "SUCCEEDED", true] call BIS_fnc_taskSetState;
                    private _amt = 6 + floor random 4; // 6–9 tokens
                    {
                        if (side _x == east && alive _x) then {
                            for "_i" from 1 to _amt do { _x addItem "VRP_HL_Token_Item"; };
                        };
                    } forEach allPlayers;
                    [format ["Terminal hacked! You pilfer %1 Tokens.", _amt]] call _showUi;
                    sleep 3; ["" ] call _showUi;
					// clear UI + actions
					[""] call _showUi;
					if (!isNull _terminal) then {
						{ if (_x isEqualType 0 && _x >= 0) then { _terminal removeAction _x; } } forEach [_startActId, _resumeActId];
					};

					// let the immediate fight resolve a touch
					sleep 300;

					// delete groups (units inside) then props/loose units
					{
						{ if (!isNull _x) then { deleteVehicle _x }; } forEach units _x;
						deleteGroup _x;
					} forEach _groups;

					{ if (!isNull _x) then { deleteVehicle _x }; } forEach _props;

					{
						if (!isNull _x && {!alive _x || {!(_x isKindOf 'Man')}}) then { deleteVehicle _x };
					} forEach _units;

					[_taskId] call BIS_fnc_deleteTask;
                    breakOut "HACK_SCOPE";
                };
            };

            // Timeout
            if (time > _deadline) then {
                [_taskId, "FAILED", true] call BIS_fnc_taskSetState;
                ["Hack failed — time limit exceeded."] remoteExec ["systemChat", 0];
                ["" ] call _showUi;
				// clear UI + actions
				[""] call _showUi;
				if (!isNull _terminal) then {
					{ if (_x isEqualType 0 && _x >= 0) then { _terminal removeAction _x; } } forEach [_startActId, _resumeActId];
				};

				// let the immediate fight resolve a touch
				sleep 300;

				// delete groups (units inside) then props/loose units
				{
					{ if (!isNull _x) then { deleteVehicle _x }; } forEach units _x;
					deleteGroup _x;
				} forEach _groups;

				{ if (!isNull _x) then { deleteVehicle _x }; } forEach _props;

				{
					if (!isNull _x && {!alive _x || {!(_x isKindOf 'Man')}}) then { deleteVehicle _x };
				} forEach _units;
				[_taskId] call BIS_fnc_deleteTask;
                breakOut "HACK_SCOPE";
            };
        };
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
    private _tightCount = 4 + floor random 3; // 4–6
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
        private _count = 4 + floor random 3; // 4–6 per group
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


