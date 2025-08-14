if (!isServer) exitWith {};

// Pick a random mission ID (1–3 here)
private _missionIndex = selectRandom [1, 2, 3];

switch (_missionIndex) do {
// === Mission 1: Quell Worker Riot  ===
case 1: {
    if (!isServer) exitWith {};

    // New marker set
    private _cityMarkers = allMapMarkers select { toLower _x find "city_" == 0 };
    if (_cityMarkers isEqualTo []) exitWith {
        ["[Riot] No city_ markers found — mission skipped."] remoteExec ["systemChat", 0];
    };

    // Loadout pools
    private _Uniforms = [
        "CombainCIV_Uniform_1","CombainCIV_Uniform_2","HL_CIV_U_Civilian_02","U_bms_civ_jean_rot_ligt_tuck"
    ];
    private _Helmets = [
        "CombainCIV1","H_bms_hat_trop_rood_2","H_Bandanna_blu","H_Construction_basic_orange_F",
        "H_Construction_earprot_yellow_F","H_HeadBandage_stained_F","rds_rocker_hair3","Cytech_Miners_Hat_Flashlight"
    ];
    private _Melee = [
        "Pipe_aluminium","Crowbar","FireAxe","WBK_survival_weapon_2","WBK_survival_weapon_1",
        "WBK_pipeStyledSword","Shovel_Russian","WBK_SmallHammer","Axe","WBK_ww1_Club"
    ];

    private _chosenMarker = selectRandom _cityMarkers;
    private _centerPos    = getMarkerPos _chosenMarker;

    // WEST task
    private _taskId = format ["task_quellRiot_%1", diag_tickTime];
    [west, _taskId,
        ["Quell the worker riot near this checkpoint. Neutralize or detain all rioters.",
         "Pacify Worker Riot", ""],
        _centerPos, true
    ] call BIS_fnc_taskCreate;

    // Spawn 3–6 groups within 100m, patrol around spawn
    private _numGroups = 3 + floor random 4; // 3–6
    private _spawnedGroups = [];
    private _spawnedUnits  = [];
    private _rebelClass    = "WBK_Rebel_HL2_refugee_6";

    for "_g" from 1 to _numGroups do {
        private _grp = createGroup east;

        // 5–8 per group
        private _count = 5 + floor random 4;
        for "_i" from 1 to _count do {
            private _pos = [_centerPos, random 100, random 360] call BIS_fnc_relPos;
            private _u = _grp createUnit [_rebelClass, _pos, [], 2, "FORM"];

            // Loadout tweaks
            _u forceAddUniform (selectRandom _Uniforms);
            removeHeadgear _u; _u addHeadgear (selectRandom _Helmets);
            private _sec = secondaryWeapon _u; if (_sec != "") then { _u removeWeapon _sec; };
            _u addWeapon (selectRandom _Melee);

            _spawnedUnits pushBack _u;
        };

        _grp setBehaviour "AWARE";
        _grp setCombatMode "RED";

        // Local patrol (radius ~120m around center)
        [_grp, _centerPos, 120] call BIS_fnc_taskPatrol;

        _spawnedGroups pushBack _grp;
    };

    // Notify BLUFOR
    [ "Rioters reported near a checkpoint. Patrol the area and neutralize or detain them." ]
        remoteExec ["hintSilent", (allPlayers select {side _x == west}) apply { owner _x }];

 // Monitor for success OR fail after 1 hour
    [_spawnedUnits, _spawnedGroups, _taskId] spawn {
        params ["_units","_groups","_taskId"];

        private _timeLimit = time + 3600; // 1 hour

        waitUntil {
            sleep 5;
            ({ alive _x && {!captive _x} } count _units) == 0 || { time > _timeLimit }
        };

        if (({ alive _x && {!captive _x} } count _units) == 0) then {
            // Success
            [_taskId, "SUCCEEDED", true] call BIS_fnc_taskSetState;

            // Reward BLUFOR (2–5 tokens each)
            private _amount  = 2 + floor random 5;
            private _targets = allPlayers select { side _x == west && alive _x };
            {
                for "_i" from 1 to _amount do { _x addItem "VRP_HL_Token_Item"; };
            } forEach _targets;

            [format ["Riot Quelled. You received %1 tokens.", _amount]]
                remoteExec ["hintSilent", _targets apply { owner _x }];
        } else {
            // Fail
            [_taskId, "FAILED", true] call BIS_fnc_taskSetState;
        };

        // Cleanup
        { { if (!isNull _x) then { deleteVehicle _x }; } forEach units _x; } forEach _groups;

        sleep 15;
        [_taskId] call BIS_fnc_deleteTask;
    };
};




// === Mission 2: Rebel Captain Assassination ===
case 2: {
    if (!isServer) exitWith {};

    private _rebelMarkers = allMapMarkers select { toLower _x find "rebel_" == 0 };
    if (_rebelMarkers isEqualTo []) exitWith {
        ["[Assassination] No rebel_ markers found — mission skipped."] remoteExec ["systemChat", 0];
    };

    private _chosenMarker = selectRandom _rebelMarkers;
    private _center       = getMarkerPos _chosenMarker;

    private _captainClass   = "WBK_Rebel_SL_1";  // officer/captain class
    private _rebelInfantry  = [
        "WBK_Rebel_Rifleman_1","WBK_Rebel_SMG_3","WBK_Rebel_SMG_2", "UU_Sniper", "UU_CP",
        "WBK_Rebel_Medic_1","WBK_Rebel_WP_3","WBK_Rebel_Shotgunner"
    ];
    private _rebelVehicleClasses = ["HL_RES_DVP_HMG", "O_G_Offroad_01_Armed_F", "O_G_Offroad_01_AT_F"]; // add more if you like

    // Place task slightly offset from the real position so it's not exact
    private _taskPos = [_center, 120 + random 120, random 360] call BIS_fnc_relPos;

    // Create WEST task
    private _taskId = format ["task_assassin_%1", diag_tickTime];
    [west, _taskId,
        ["Locate and eliminate the Anticitizen in this area. They are leading a cell of malignants in our sector.",
         "Amputate Anticitizen", ""],
        _taskPos, true
    ] call BIS_fnc_taskCreate;

    // Spawn the Captain at a safe position near the center
    private _capPos = _center;
    private _capGrp = createGroup east;
    private _captain = _capGrp createUnit [_captainClass, _capPos, [], 2, "FORM"];
    _capGrp setBehaviour "AWARE";
    _capGrp setCombatMode "RED";

    // Spawn 3–4 rebel groups around the area
    private _numGroups = 3 + floor random 3; // 3–4
    private _groups = [];
    private _units  = [];
    _units pushBack _captain;
    _groups pushBack _capGrp;

    for "_g" from 1 to _numGroups do {
        private _spawnPos = [_center, 60, 140, 5, 0, 0.4, 0] call BIS_fnc_findSafePos; // ring around the center
        private _grp = createGroup east;

        private _count = 4 + floor random 3; // 4–6 per group
        for "_i" from 1 to _count do {
            private _pos = [_spawnPos, random 20, random 360] call BIS_fnc_relPos;
            private _u = _grp createUnit [selectRandom _rebelInfantry, _pos, [], 2, "FORM"];
            _units pushBack _u;
        };

        _grp setBehaviour "AWARE";
        _grp setCombatMode "RED";

        // First group defends tighter around the captain, others patrol the area
        if (_g == 1) then {
            [_grp, _capPos, 80] call BIS_fnc_taskDefend;     // defend captain area
        } else {
            [_grp, _center, 150] call BIS_fnc_taskPatrol;    // patrol city block
        };

        _groups pushBack _grp;
    };

    // Chance for a rebel patrol vehicle
    if (random 1 < 0.35) then {
        private _vehPos = [_center, 80, 200, 5, 0, 0.4, 0] call BIS_fnc_findSafePos;
        private _vehCls = selectRandom _rebelVehicleClasses;
        private _veh = createVehicle [_vehCls, _vehPos, [], 0, "NONE"];
        createVehicleCrew _veh;
        private _vehGrp = group (driver _veh);
        _vehGrp setBehaviour "AWARE";
        _vehGrp setCombatMode "RED";
        [_vehGrp, _center, 220] call BIS_fnc_taskPatrol;

        _groups pushBack _vehGrp;
        { _units pushBack _x } forEach (crew _veh);
        _units pushBack _veh; // track the vehicle for cleanup, too
    };


    // Monitor success (captain dead or captive) OR time out (1 hour)
    [_captain, _groups, _units, _taskId] spawn {
        params ["_captain","_groups","_units","_taskId"];

        private _deadline = time + 3600; // 1-hour fail-safe

        waitUntil {
            sleep 5;
            !alive _captain || (captive _captain) || { time > _deadline }
        };

        if (!alive _captain || captive _captain) then {
            // Success
            [_taskId, "SUCCEEDED", true] call BIS_fnc_taskSetState;

            // Optional reward to BLUFOR (tweak/remove if not desired):
            private _amount  = 4 + floor random 9; // 4–8 tokens
            private _targets = allPlayers select { side _x == west && alive _x };
            {
                for "_i" from 1 to _amount do { _x addItem "VRP_HL_Token_Item"; };
            } forEach _targets;

            [format ["Target Down. You were awarded %1 tokens.", _amount]]
                remoteExec ["hintSilent", _targets apply { owner _x }];
        } else {
            // Fail
            [_taskId, "FAILED", true] call BIS_fnc_taskSetState;
                remoteExec ["hintSilent", (allPlayers select {side _x == west}) apply { owner _x }];
        };
		
		sleep 300;
        // Cleanup units/vehicles
        {
            if (!isNull _x) then {
                if (_x isKindOf "Man") then { deleteVehicle _x } else {
                    // delete vehicle + crew
                    { if (!isNull _x) then { deleteVehicle _x } } forEach crew _x;
                    deleteVehicle _x;
                };
            };
        } forEach _units;

        sleep 15;
        [_taskId] call BIS_fnc_deleteTask;
    };
};


// === Mission 3: Clear Antlion Hive (fixed proxy + spawns) ===
case 3: {
    if (!isServer) exitWith {};

    private _hiveMarkers = allMapMarkers select { toLower _x find "hive_" == 0 };
    if (_hiveMarkers isEqualTo []) exitWith {
        ["[Hive] No hive_ markers found — mission skipped."] remoteExec ["systemChat", 0];
    };

    private _chosenMarker = selectRandom _hiveMarkers;
    private _hivePos      = getMarkerPos _chosenMarker;

    // Task offset so location isn't exact
    private _taskId  = format ["task_clearHive_%1", diag_tickTime];
    private _taskPos = [_hivePos, 80 + random 80, random 360] call BIS_fnc_relPos;
    [west, _taskId,
        ["Destroy the Antlion Hive. Expect heavy resistance until the nest is neutralized.",
         "Clear Biotic Hive", ""],
        _taskPos, true
    ] call BIS_fnc_taskCreate;

    // Spawn the (indestructible) hive
    private _hive = createVehicle ["xen_antlionhive_large", _hivePos, [], 0, "NONE"];
    _hive setDir random 360;

    // Destructible proxy: fence pole (no attach)
    private _proxy = createVehicle ["Land_Net_fence_pole_F", _hivePos, [], 0, "NONE"];
    _proxy allowDamage true;
    _proxy enableSimulationGlobal true;

    // Antlion spawn management
    private _grp          = createGroup resistance;
    private _spawnedUnits = [];
    private _capAlive     = 15;
    private _spawnRadius  = 50;

    // Spawner loop — runs while the proxy is alive
    [_proxy, _hive, _grp, _spawnedUnits, _capAlive, _spawnRadius, _taskId] spawn {
        params ["_proxy","_hive","_grp","_units","_cap","_rad","_taskId"];

        while { alive _proxy } do {
            // prune dead entries
            _units = _units select { alive _x };

            if ((count _units) < _cap) then {
                private _pos = [getPos _hive, _rad, random 360] call BIS_fnc_relPos;   // <-- FIXED
                private _u   = _grp createUnit ["WBK_Antlion_1", _pos, [], 2, "FORM"]; // <-- correct class
                _u setBehaviour "AWARE";
                _u setCombatMode "RED";

                // Nudge toward nearest player if any
                private _idx = allPlayers findIf { alive _x };
                if (_idx > -1) then { _u doMove (getPos (allPlayers select _idx)); };

                _units pushBack _u;
            };

            sleep 30;
        };

        // Proxy dead => hive destroyed => success
        if (!alive _proxy) then {
            [_taskId, "SUCCEEDED", true] call BIS_fnc_taskSetState;
            if (!isNull _hive) then { deleteVehicle _hive; };

            // grace period then cleanup any surviving ants
            sleep 300;
            { if (!isNull _x) then { deleteVehicle _x }; } forEach _units;

            sleep 10;
            [_taskId] call BIS_fnc_deleteTask;
        };
    };

    // Safety timeout: 1 hour
    [_proxy, _hive, _grp, _taskId] spawn {
        params ["_proxy","_hive","_grp","_taskId"];
        private _deadline = time + 3600;

        waitUntil { sleep 5; (!alive _proxy) || (time > _deadline) };
        if (time > _deadline && alive _proxy) then {
            [_taskId, "FAILED", true] call BIS_fnc_taskSetState;
            if (!isNull _proxy) then { deleteVehicle _proxy; };
            if (!isNull _hive)  then { deleteVehicle _hive; };
            { if (!isNull _x) then { deleteVehicle _x }; } forEach units _grp;
            deleteGroup _grp;
            sleep 10;
            [_taskId] call BIS_fnc_deleteTask;
        };
    };
};


};
