// recruiter.sqf
// Spawns a Civil Protection recruiter NPC at marker "recruiter".
// Civilians can talk to the recruiter to join the Civil Protection Force for 2 tokens.

if (!isServer) exitWith {};

// --- Client-side action helper ---
if (isNil "CPF_fnc_addRecruiterAction") then {
    CPF_fnc_addRecruiterAction = {
        params ["_rec"];
        if (isNull _rec) exitWith {};
        _rec addAction [
            "Join the Civil Protection Force <t color='#FFD700'>(2 token admin fee)</t>",
            {
                params ["_target","_caller"];
                if (side _caller != civilian) exitWith {};
                _caller playMoveNow "Acts_CivilTalking_1";
                [_caller] spawn { params ["_c"]; uiSleep 8; _c switchMove ""; };
                [_target, _caller] remoteExecCall ["CPF_fnc_recruitServer", 2];
            },
            nil, 1.5, true, true, "",
            "side _this == civilian"
        ];
    };
    publicVariable "CPF_fnc_addRecruiterAction";
};

// --- Server-side recruit handler ---
if (isNil "CPF_fnc_recruitServer") then {
    CPF_fnc_recruitServer = {
        params ["_rec","_plr"];
        if (isNull _rec || isNull _plr) exitWith {};
        if (side _plr != civilian) exitWith {};

        private _tokens = { _x == "VRP_HL_Token_Item" } count (items _plr);
        if (_tokens < 2) exitWith {
            ["Not enough tokens."] remoteExec ["hintSilent", owner _plr];
        };

        for "_i" from 1 to 2 do { _plr removeItem "VRP_HL_Token_Item"; };

        _rec setDir ([_rec, _plr] call BIS_fnc_dirTo);
        _rec doWatch _plr;
        _rec playMoveNow "Acts_CivilListening_1";
        [_rec] spawn { params ["_r"]; uiSleep 8; _r switchMove ""; };

        [_rec, _plr] spawn {
            params ["_r","_p"];
            uiSleep 8;
            private _grp = createGroup [west, true];
            [_p] joinSilent _grp;
            _p setVariable ["WBK_CombineType","  cp_",true];
            _p setVariable ["WBK_HL_CustomArmour",75,true];
            _p setVariable ["WBK_HL_CustomArmour_MAX",75,true];
            ["Welcome to the Civil Protectio Force, unit. Suit up at the arsenal inside the station."] remoteExec ["hintSilent", owner _p];
        };
    };
    publicVariable "CPF_fnc_recruitServer";
};

// --- Spawner ---
[] spawn {
    waitUntil { !isNil "CPF_fnc_addRecruiterAction" && !isNil "CPF_fnc_recruitServer" };

    private _marker = "recruiter";
    private _spawnRadius  = 100;
    private _despawnGrace = 30;
    private _rec = objNull;
    private _lastSeen = 0;

        private _spawnRecruiter = {
        private _pos = getMarkerPos _marker;
        if (_pos isEqualTo [0,0,0]) exitWith { diag_log "[RECRUITER] Marker 'recruiter' not found."; objNull };

        private _grp = createGroup west;
        private _r   = _grp createUnit ["WBK_Combine_CP_P", _pos, [], 0, "NONE"];
        _r setPosATL (_pos vectorAdd [0,0,1]);
        _r disableAI "MOVE";
        _r disableAI "PATH";
        _r disableAI "TARGET";
        _r disableAI "AUTOTARGET";
        _r allowFleeing 0;
        _r setUnitPos "UP";
        _r setBehaviour "SAFE";
        _r setCaptive true;
        removeAllWeapons _r;
        removeBackpack _r;
        removeUniform _r;
        removeHeadgear _r;
        _r forceAddUniform "Z_C18_Uniform_7";
        _r addHeadgear "H_SM_CMBMask";

        [_r] remoteExec ["CPF_fnc_addRecruiterAction", 0, true];
        _r
    };

    while { true } do {
        private _pos = getMarkerPos _marker;
        private _near = allPlayers select { alive _x && (_x distance2D _pos) < _spawnRadius };

        if ((count _near) > 0) then {
            if (isNull _rec) then {
                _rec = call _spawnRecruiter;
            };
            _lastSeen = time;
        } else {
            if (!isNull _rec && { (time - _lastSeen) > _despawnGrace }) then {
                private _grp = group _rec;
                deleteVehicle _rec;
                deleteGroup _grp;
                _rec = objNull;
            };
        };

        sleep 5;
    };
};