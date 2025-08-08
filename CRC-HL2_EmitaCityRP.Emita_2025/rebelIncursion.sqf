// File: rebelIncursion.sqf

[] spawn {
    private _rebelUnits = [
        "WBK_Rebel_SL_1", "WBK_Rebel_Rifleman_3", "WBK_Rebel_Medic_1",
        "WBK_Rebel_SMG_1", "WBK_Rebel_SMG_2", "WBK_Rebel_Sniper",
        "WBK_Rebel_Shotgunner", "WBK_Rebel_HL2_RPG"
    ];

    private _combineUnits = [
        "WBK_Combine_HL2_Type_WastelandPatrol", "WBK_Combine_Ordinal",
        "WBK_Combine_Grunt", "WBK_Combine_Grunt_white", "WBK_Combine_Wallhammer"
    ];

    waitUntil { sleep 30; (count allPlayers) > 0 };

    while {true} do {
        sleep (2000 + random 4000);

        ["Flocalunrestspkr"] remoteExec ["playSound", 0];

        private _battleCenter = getPos (selectRandom allPlayers);
        private _offset = [300, 400] call BIS_fnc_randomNum;
        private _rebelSpawn = _battleCenter vectorAdd [_offset, _offset, 0];
        private _combineSpawn = _battleCenter vectorAdd [-_offset, -_offset, 0];

        private _taskID = format ["task_rebelIncursion_%1", diag_tickTime];
        [west, _taskID, ["Eliminate the anticitizens in the area.", "Anticitizen Incursion", ""], _battleCenter, true] call BIS_fnc_taskCreate;
        [east, _taskID + "_opf", ["Reinforce your comrades against the incoming attack.", "Reinforce Rebels", ""], _battleCenter, true] call BIS_fnc_taskCreate;

        // === Rebel Squad ===
        private _rebelGrp = createGroup east;
        for "_i" from 1 to 5 do {
            _rebelGrp createUnit [selectRandom _rebelUnits, _rebelSpawn, [], 0, "FORM"];
        };
        _rebelGrp setBehaviour "AWARE";
        _rebelGrp setCombatMode "RED";
        _rebelGrp addWaypoint [_battleCenter, 0];

        // === Rebel Transport ===
        private _rebelVehicle = createVehicle ["cytech_rt_agrale", _rebelSpawn, [], 0, "NONE"];
        _rebelVehicle setDir random 360;
        _rebelVehicle lock false;

        private _rebelTransportGrp = createGroup east;
        private _rebelDriver = _rebelTransportGrp createUnit [selectRandom _rebelUnits, _rebelSpawn, [], 0, "NONE"];
        _rebelDriver moveInDriver _rebelVehicle;

        // Ensure driver assigned
        if (isNull driver _rebelVehicle) then {
            _rebelDriver assignAsDriver _rebelVehicle;
            _rebelDriver moveInDriver _rebelVehicle;
        };

        for "_i" from 1 to 5 do {
            private _unit = _rebelTransportGrp createUnit [selectRandom _rebelUnits, _rebelSpawn, [], 0, "NONE"];
            _unit moveInCargo _rebelVehicle;
        };

        _rebelTransportGrp setBehaviour "AWARE";
        _rebelTransportGrp setCombatMode "RED";
        _rebelTransportGrp addWaypoint [_battleCenter vectorAdd [15, -15, 0], 0] setWaypointType "MOVE";
        _rebelTransportGrp addWaypoint [_battleCenter, 0] setWaypointType "GETOUT";

        // === Combine APC ===
        private _apc = createVehicle ["cytech_rt_amv_black", _combineSpawn, [], 0, "NONE"];
        _apc setDir random 360;
        _apc lock false;

        private _combineGrp = createGroup west;
        private _driver = _combineGrp createUnit [selectRandom _combineUnits, _combineSpawn, [], 0, "NONE"];
        _driver moveInDriver _apc;

        if (isNull driver _apc) then {
            _driver assignAsDriver _apc;
            _driver moveInDriver _apc;
        };

        for "_i" from 1 to 7 do {
            private _unit = _combineGrp createUnit [selectRandom _combineUnits, _combineSpawn, [], 0, "NONE"];
            _unit moveInCargo _apc;
        };

        _combineGrp setBehaviour "AWARE";
        _combineGrp setCombatMode "RED";
        _combineGrp addWaypoint [_battleCenter, 0] setWaypointType "MOVE";
        _combineGrp addWaypoint [_battleCenter vectorAdd [20,20,0], 0] setWaypointType "GETOUT";

        // === Task Monitor ===
        [
            _taskID,
            _rebelGrp,
            _combineGrp
        ] spawn {
            params ["_taskID", "_rebelGrp", "_combineGrp"];

            waitUntil {
                sleep 5;
                ({alive _x} count units _rebelGrp == 0) || ({alive _x} count units _combineGrp == 0)
            };

            if ({alive _x} count units _rebelGrp == 0) then {
                [_taskID, "SUCCEEDED", true] call BIS_fnc_taskSetState;
                [_taskID + "_opf", "FAILED", true] call BIS_fnc_taskSetState;
                ["Anticitizens pacified."] remoteExec ["hint", west];
            } else {
                [_taskID, "FAILED", true] call BIS_fnc_taskSetState;
                [_taskID + "_opf", "SUCCEEDED", true] call BIS_fnc_taskSetState;
                ["Overwatch units neutralized. Protection Team: report for offworld reassignment."] remoteExec ["hint", west];
            };

            sleep 10;
            [_taskID] call BIS_fnc_deleteTask;
            [_taskID + "_opf"] call BIS_fnc_deleteTask;
        };

        systemChat "Alert: Community Ground Protection units: Local unrest structure detected. Assemble, administer, pacify.";
        ["Alert: Community Ground Protection units: Local unrest structure detected. Assemble, administer, pacify."] remoteExec ["systemChat", 0];
        private _grid = mapGridPosition _battleCenter;
        {
            _x sideChat format ["Anticitizen incursion detected at grid %1. Deploying intercept force.", _grid];
        } forEach allPlayers select {side _x == west};

        // === Cleanup Logic ===
        [
            _rebelGrp,
            _combineGrp,
            _rebelVehicle,
            _apc
        ] spawn {
            params ["_rebelGrp", "_combineGrp", "_rebelVehicle", "_apc"];

            // Wait 3000 seconds then cleanup as fallback
            sleep 3000;

            {
                deleteVehicle _x;
            } forEach ((units _rebelGrp) + (units _combineGrp) + [_rebelVehicle, _apc]);
        };
    };
};
