// smuggler.sqf — spawns a roaming smuggler merchant in the Slums
if (!isServer) exitWith {};

[] spawn {
    private _smugglerClass = "RDS_PL_Profiteer_Random";
    private _packClass     = "B_Carryall_blk";
    private _activeTime    = 1800;  // 30 minutes active
    private _respawnMin    = 1800;  // 30 minutes
    private _respawnMax    = 3600;  // 45 minutes
    private _fakeCIDPrice  = 30;    // tokens for fake CID

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
            ["Find the smuggler rumored to be in the Slums. He will not stay for very long.", "Rumors of a Smuggler", ""],
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

    if (isNil "MRC_fnc_addFakeCIDAction") then {
        MRC_fnc_addFakeCIDAction = {
            params ["_m", "_price"];
            if (isNull _m) exitWith {};
            _m addAction [
                format ["Buy Fake CID (Join Civilians) <t color='#FFD700'>(%1 tokens)</t>", _price],
                {
                    params ["_target","_caller","","_args"];
                    _args params ["_price"];
                    [_caller, _target, _price] remoteExecCall ["MRC_fnc_buyFakeCID", 2];
                },
                [_price], 1.5, true, true, "",
                "_this distance _target < 4"
            ];
        };
        publicVariable "MRC_fnc_addFakeCIDAction";
    };

    if (isNil "MRC_fnc_buyFakeCID") then {
        MRC_fnc_buyFakeCID = {
            params ["_plr", "_smug", "_price"];
            if (isNull _plr || { !alive _plr }) exitWith {};
            private _tokens = { _x == "VRP_HL_Token_Item" } count (items _plr);
            if (_tokens < _price) exitWith {
                ["Not enough tokens."] remoteExec ["hintSilent", owner _plr];
            };

            private _wasCPF = side _plr == west;

            for "_i" from 1 to _price do { _plr removeItem "VRP_HL_Token_Item"; };
            _plr addMagazine "Civilain_IDCard_1";

            private _grp = createGroup [civilian, true];
            [_plr] joinSilent _grp;

            if (_wasCPF && {!isNull _smug}) then {
                _smug addItemToBackpack "U_C18_Uniform_8";
            };

            if (isNil "Global_CID_Registry") then {
                Global_CID_Registry = [];
                publicVariable "Global_CID_Registry";
            };
            private _cid = "";
            private _unique = false;
            while { !_unique } do {
                _cid = format ["CID-%1", floor (random [1000, 9999, 9999])];
                _unique = !(_cid in Global_CID_Registry);
            };
            Global_CID_Registry pushBack _cid;
            publicVariable "Global_CID_Registry";

            _plr setVariable ["CID_Number", _cid, true];
            _plr setVariable ["HasCID", true, false];

            private _msg = format ["Fake CID purchased. New CID: %1", _cid];
            if (_wasCPF) then {
                _msg = _msg + "\n You dirty cop... the merchant has a free uniform for you in his pack.";
				["Vital Alert: Autonomous unit subsumed. Mandatory compliance with tenets of advisorial assistance act. Threat level adjustment. Probe. Expunge."] remoteExec ["systemChat", 0];
				["Overbarn"] remoteExec ["playSound", 0];
				_plr setVariable ["WBK_CombineType"," g_hecu_",true];				
            };
            [_msg] remoteExec ["hintSilent", owner _plr];
        };
        publicVariable "MRC_fnc_buyFakeCID";
    };

    // Wait for merchant helpers from merchants.sqf to be present
    waitUntil { !isNil "MRC_fnc_addMerchantActions" && !isNil "MRC_fnc_merchantServer" };

    while { true } do {
        private _markers = allMapMarkers select { toLower _x find "slums_" == 0 && { toLower _x != "slums_guard" } };
        if (_markers isEqualTo []) exitWith { diag_log "[SMUGGLER] No slums_ markers found."; };
        private _chosen = selectRandom _markers;
        private _pos    = getMarkerPos _chosen;

        private _grp = createGroup civilian;
        private _u = _grp createUnit [_smugglerClass, _pos, [], 0, "NONE"];
        _u setDir (random 360);
        _u setPosATL (_pos vectorAdd [0,0,1]);
        _u switchMove "";
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
        [_u, _fakeCIDPrice] remoteExec ["MRC_fnc_addFakeCIDAction", 0, true];

        [(allPlayers select { side _x == civilian }), _pos, _u] call _giveTask;
        [(allPlayers select { side _x == east }),      _pos, _u] call _giveTask;

        private _end = time + _activeTime;
        waitUntil { sleep 5; time >= _end };
        if (!isNull _u) then { deleteVehicle _u; };
        if (!isNull _grp) then { deleteGroup _grp; };

        sleep (_respawnMin + random (_respawnMax - _respawnMin));
    };
};