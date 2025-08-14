// smuggler.sqf — spawns a roaming smuggler merchant in the Slums
if (!isServer) exitWith {};

[] spawn {
    private _smugglerClass = "HL_CIV_Man_01";
    private _packClass     = "Combaine_backpack_NB";
    private _activeTime    = 1800;  // 30 minutes active
    private _respawnMin    = 1800;  // 30 minutes
    private _respawnMax    = 2700;  // 45 minutes

    private _stock_smuggler = [
        ["WBK_CP_HeavySmg_Resist","Heavy SMG (Resist)",45],
        ["hlc_rifle_akm","AKM",48],
        ["Crowbar","Crowbar",5],
        ["ACE_Canteen","Canteen",1],
        ["ACE_MRE_MeatballsPasta","MRE: Meatballs & Pasta",1],
        ["Medikit","Medikit",10]
    ];

    private _rollInventory = {
        params ["_stock","_count"];
        private _pool = +_stock call BIS_fnc_arrayShuffle;
        private _pick = _pool select [0, _count min (count _pool)];
        private _out  = [];
        {
            _out pushBack [_x select 0, _x select 1, _x select 2];
        } forEach _pick;
        _out
    };

    private _giveTask = {
        params ["_players", "_pos", "_smug"];
        if (_players isEqualTo []) exitWith {};
        private _ply = selectRandom _players;
        private _taskId = format ["task_smuggler_%1_%2", side _ply, diag_tickTime];
        [_ply, _taskId,
            ["Find the smuggler rumored to be in the Slums.", "Rumors of a Smuggler", ""],
            _pos, true
        ] remoteExec ["BIS_fnc_taskCreate", _ply];

        [_taskId, _smug, _ply] spawn {
            params ["_taskId","_smug","_ply"];
            waitUntil {
                sleep 3;
                isNull _smug || isNull _ply || !alive _ply || ((_ply distance2D _smug) < 3)
            };
            private _state = if (!isNull _smug && !isNull _ply && alive _ply && ((_ply distance2D _smug) < 3)) then { "SUCCEEDED" } else { "FAILED" };
            [_taskId, _state, true] remoteExec ["BIS_fnc_taskSetState", _ply];
            sleep 10;
            [_taskId] remoteExec ["BIS_fnc_deleteTask", _ply];
        };
    };

    while { true } do {
        private _markers = allMapMarkers select { toLower _x find "slums_" == 0 };
        if (_markers isEqualTo []) exitWith { diag_log "[SMUGGLER] No slums_ markers found."; };
        private _chosen = selectRandom _markers;
        private _pos    = getMarkerPos _chosen;

        private _grp = createGroup civilian;
        private _u = _grp createUnit [_smugglerClass, _pos, [], 0, "NONE"];
        _u disableAI "MOVE";
        _u disableAI "PATH";
        _u disableAI "TARGET";
        _u disableAI "AUTOTARGET";
        _u allowFleeing 0;
        _u setUnitPos "UP";
        _u setBehaviour "SAFE";
        _u setCaptive true;
        removeAllWeapons _u;
        removeBackpack _u;
        _u addBackpack _packClass;

        private _entries = ([_stock_smuggler, 6] call _rollInventory);
        [_u, _entries] remoteExec ["MRC_fnc_addMerchantActions", 0, true];

        [(allPlayers select { side _x == civilian }), _pos, _u] call _giveTask;
        [(allPlayers select { side _x == east }),      _pos, _u] call _giveTask;

        private _end = time + _activeTime;
        waitUntil { sleep 5; time >= _end };
        if (!isNull _u) then { deleteVehicle _u; };
        if (!isNull _grp) then { deleteGroup _grp; };

        sleep (_respawnMin + random (_respawnMax - _respawnMin));
    };
};