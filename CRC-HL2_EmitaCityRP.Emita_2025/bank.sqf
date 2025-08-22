// bank.sqf
// Simple banking system for token storage with persistence
if (!isServer) exitWith {};

if (isNil "MRC_fnc_facePlayer") then {
    MRC_fnc_facePlayer = {
        params ["_npc", "_caller"];
        if (isNull _npc || isNull _caller) exitWith {};
        _npc setDir ([_npc, _caller] call BIS_fnc_dirTo);
    };
};

// --- Server-side balance handler ---
if (isNil "MRC_fnc_bankServer") then {
    MRC_fnc_bankServer = {
        params ["_op", "_amt", "_caller"];
        if (isNull _caller) exitWith {};
        private _uid = getPlayerUID _caller;
        private _var = format ["BANK_%1", _uid];
        private _bal = profileNamespace getVariable [_var, 0];

        switch (_op) do {
            case "DEPOSIT": {
                private _have = { _x == "VRP_HL_Token_Item" } count (items _caller);
                if (_amt <= 0) exitWith {
                    ["No tokens to deposit."] remoteExec ["hintSilent", owner _caller];
                };
                if (_have < _amt) exitWith {
                    ["Not enough tokens."] remoteExec ["hintSilent", owner _caller];
                };
                for "_i" from 1 to _amt do { _caller removeItem "VRP_HL_Token_Item"; };
                _bal = _bal + _amt;
                profileNamespace setVariable [_var, _bal];
                saveProfileNamespace;
                _caller setVariable ["bankTokens", _bal, true];
                [format ["Deposited %1 token(s). Balance: %2.", _amt, _bal]] remoteExec ["hintSilent", owner _caller];
            };
            case "WITHDRAW": {
                if (_bal < _amt) exitWith {
                    ["Insufficient bank funds."] remoteExec ["hintSilent", owner _caller];
                };
                _bal = _bal - _amt;
                profileNamespace setVariable [_var, _bal];
                saveProfileNamespace;
                _caller setVariable ["bankTokens", _bal, true];
                for "_i" from 1 to _amt do { _caller addItem "VRP_HL_Token_Item"; };
                [format ["Withdrew %1 token(s). Balance: %2.", _amt, _bal]] remoteExec ["hintSilent", owner _caller];
            };
            case "BALANCE": {
                [format ["Bank balance: %1 token(s).", _bal]] remoteExec ["hintSilent", owner _caller];
            };
            case "INIT": {
                _caller setVariable ["bankTokens", _bal, true];
            };
        };
    };
};

// --- Client-side actions ---
if (isNil "MRC_fnc_addBankActions") then {
    MRC_fnc_addBankActions = {
        params ["_npc"];
        if (isNull _npc) exitWith {};
        private _acts = [
            ["Deposit 1 Token", "DEPOSIT", 1, '#FFD700'],
            ["Deposit 10 Tokens", "DEPOSIT", 10, '#FFD700'],
            ["Deposit 25 Tokens", "DEPOSIT", 25, '#FFD700'],
            ["Deposit 100 Tokens", "DEPOSIT", 100, '#FFD700'],
            ["Withdraw 1 Token", "WITHDRAW", 1, '#88CCFF'],
            ["Withdraw 10 Tokens", "WITHDRAW", 10, '#88CCFF'],
            ["Withdraw 25 Tokens", "WITHDRAW", 25, '#88CCFF'],
            ["Withdraw 100 Tokens", "WITHDRAW", 100, '#88CCFF']
        ];
        {
            _x params ["_title","_op","_amt","_col"];
            _npc addAction [
                format ["<t color='%3'>%1</t>", _title, _amt, _col],
                {
                    params ["_t","_caller","","_args"];
                    _args params ["_op","_amt"];
                    [_t, _caller] remoteExecCall ["MRC_fnc_facePlayer", 2];
                    [_op, _amt, _caller] remoteExecCall ["MRC_fnc_bankServer", 2];
                },
                [_op,_amt],
                1.5, true, true, "",
                "_this distance _target < 4"
            ];
        } forEach _acts;
        _npc addAction [
            "<t color='#FFD700'>Deposit All Tokens</t>",
            {
                params ["_t","_caller"];
                [_t, _caller] remoteExecCall ["MRC_fnc_facePlayer", 2];
                private _have = { _x == "VRP_HL_Token_Item" } count (items _caller);
                if (_have <= 0) exitWith {
                    ["No tokens to deposit."] remoteExec ["hintSilent", owner _caller];
                };
                ["DEPOSIT", _have, _caller] remoteExecCall ["MRC_fnc_bankServer", 2];
            },
            nil, 1.5, true, true, "",
            "_this distance _target < 4"
        ];
        _npc addAction [
            "<t color='#A0FFA0'>Check Bank Balance</t>",
            {
                params ["_t","_caller"];
                [_t, _caller] remoteExecCall ["MRC_fnc_facePlayer", 2];
                ["BALANCE",0,_caller] remoteExecCall ["MRC_fnc_bankServer",2];
            },
            nil, 1.5, true, true, "",
            "_this distance _target < 4"
        ];
    };
    publicVariable "MRC_fnc_addBankActions";
};

// --- Spawner ---
[] spawn {
    waitUntil { !isNil "MRC_fnc_addBankActions" && !isNil "MRC_fnc_bankServer" };
    private _npcClass     = "HL_CIV_Man_01";
    private _spawnRadius  = 150;      // meters
    private _despawnGrace = 180;      // seconds without players before despawn

    // Live banker registry: [markerName, unit, lastSeenTime]
    private _live = [];

    while { true } do {
        private _markers = allMapMarkers select { toLower _x find "bank_" == 0 };
        {
            private _m   = _x;
            private _pos = getMarkerPos _m;
            private _near = allPlayers select { alive _x && (_x distance2D _pos) < _spawnRadius };

            private _idx = -1;
            {
                if ((_x select 0) == _m) exitWith { _idx = _forEachIndex };
            } forEach _live;
            private _has = _idx >= 0;

            // Spawn if players are nearby and banker not present
            if ((count _near) > 0 && !_has) then {
                private _grp = createGroup civilian;
                private _npc = _grp createUnit [_npcClass, _pos, [], 0, "NONE"];
                _npc setPosATL (_pos vectorAdd [0,0,1]);
                _npc disableAI "MOVE";
                _npc disableAI "PATH";
                _npc disableAI "TARGET";
                _npc disableAI "AUTOTARGET";
                _npc allowFleeing 0;
                _npc setUnitPos "UP";
                _npc setBehaviour "SAFE";
                _npc setCaptive true;
                removeAllWeapons _npc;
                removeBackpack _npc;
                removeUniform _npc;
                removeHeadgear _npc;
                _npc forceAddUniform "U_C_FOrmalSuit_01_khaki_F";
                [_npc] remoteExec ["MRC_fnc_addBankActions", 0, _npc];
                _live pushBack [_m, _npc, time];
            };

            // Update last seen when players nearby
            if ((count _near) > 0 && _has) then {
                (_live select _idx) set [2, time];
            };

            // Despawn if no players for grace period
            if ((count _near) == 0 && _has) then {
                private _entry = _live select _idx;
                if ((time - (_entry select 2)) > _despawnGrace) then {
                    private _u = _entry select 1;
                    if (!isNull _u) then { deleteVehicle _u };
                    _live deleteAt _idx;
                };
            };
        } forEach _markers;

        sleep 5;
    };
};
