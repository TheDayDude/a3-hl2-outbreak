if (!isServer) exitWith {};

if (isNil "MRC_fnc_savePlayerState") then {
    MRC_fnc_savePlayerState = {
        params ["_unit"];
        if !(_unit getVariable ["MRC_stateRestored", false]) exitWith {
            ["State not restored yet - skipping save"] remoteExec ["hint", _unit];
        };
        private _uid = getPlayerUID _unit;
        if (_uid == "") exitWith {
            ["No UID - state not saved"] remoteExec ["hint", _unit];
        };
        ["Saving state"] remoteExec ["hint", _unit];
        private _key = format ["PSTATE_%1", _uid];
        profileNamespace setVariable [_key, [
            str side _unit,
            getPosATL _unit,
            getUnitLoadout _unit,
            _unit getVariable ["WBK_CombineType", ""],
            _unit getVariable ["WBK_HL_CustomArmour", 0],
            _unit getVariable ["WBK_HL_CustomArmour_Max", 0],
            _unit getVariable ["isOTA", false],
            _unit getVariable ["CanBuyFakeID", false],
            _unit getVariable ["HasCID", false],
            _unit getVariable ["CID_Number", nil]
        ]];
        saveProfileNamespace;
        ["State saved"] remoteExec ["hint", _unit];
    };
};

if (isNil "MRC_fnc_restorePlayerState") then {
    MRC_fnc_restorePlayerState = {
        params ["_unit"];
        ["Restoring state"] remoteExec ["hint", _unit];
        private _uid = getPlayerUID _unit;
        if (_uid == "") exitWith {
            ["No UID - restore aborted"] remoteExec ["hint", _unit];
        };
        private _key = format ["PSTATE_%1", _uid];
        private _data = profileNamespace getVariable [_key, []];
        if (_data isEqualTo []) then {
            ["No saved state found"] remoteExec ["hint", _unit];
            [_unit] call MRC_fnc_assignCID;
        } else {
            _data params ["_sideStr", "_pos", "_loadout", "_combine", "_arm", "_armMax", "_isOTA", "_canFake", "_hasCID", "_cid"];
            private _side = missionNamespace getVariable [toLower _sideStr, civilian];
            if (side _unit != _side) then {
                ["Switching side"] remoteExec ["hint", _unit];
                [_unit] joinSilent createGroup _side;
            };
            ["Applying saved data"] remoteExec ["hint", _unit];
            [_pos, _loadout, _combine, _arm, _armMax, _isOTA, _canFake] remoteExec ["MRC_fnc_applyPlayerState", _unit];
                        if (_hasCID && !isNil "_cid") then {
                _unit setVariable ["HasCID", true, true];
                _unit setVariable ["CID_Number", _cid, true];
                if (isNil "Global_CID_Registry") then {
                    Global_CID_Registry = [];
                    publicVariable "Global_CID_Registry";
                };
                if !(_cid in Global_CID_Registry) then {
                    Global_CID_Registry pushBack _cid;
                    publicVariable "Global_CID_Registry";
                };
                CID_Loyalty set [_cid, CID_Loyalty getOrDefault [_cid, 0]];
                CID_Malcompliance set [_cid, CID_Malcompliance getOrDefault [_cid, 0]];
            } else {
                [_unit] call MRC_fnc_assignCID;
            };
        };
        _unit setVariable ["MRC_stateRestored", true];
        ["Restore complete"] remoteExec ["hint", _unit];
    };
    publicVariable "MRC_fnc_restorePlayerState";
};

[] spawn {
    // Allow time for players to request and receive their state before the first save
    sleep 30;
    while {true} do {
        {
            [_x] call MRC_fnc_savePlayerState;
        } forEach allPlayers;
        sleep 120;
    };
};