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
        private _key = format ["PSTATE_%1", _uid];
        profileNamespace setVariable [_key, [
            str side _unit,
            getPosATL _unit,
            getUnitLoadout _unit,
            _unit getVariable ["WBK_CombineType", ""],
            _unit getVariable ["WBK_HL_CustomArmour", 0],
            _unit getVariable ["WBK_HL_CustomArmour_MAX", 0],
            _unit getVariable ["isOTA", false],
            _unit getVariable ["CanBuyFakeID", false],
            _unit getVariable ["HasCID", false],
            _unit getVariable ["CID_Number", nil],
            _unit getVariable ["favor", 0]
        ]];
        saveProfileNamespace;
        ["Autosave Complete."] remoteExec ["systemChat", _unit];
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
            _unit setVariable ["favor", 0, true];
        } else {
            _data params ["_sideStr", "_pos", "_loadout", "_combine", "_arm", "_armMax", "_isOTA", "_canFake", "_hasCID", "_cid", "_favor"];
            private _side = switch (_sideStr) do {
                case "WEST": {west};
                case "EAST": {east};
                case "GUER": {independent};
                case "CIV": {civilian};
                default {civilian};
            };
            if (side _unit != _side) then {
                ["Switching side"] remoteExec ["hint", _unit];
                [_unit] joinSilent createGroup _side;
            };
            ["Applying saved data"] remoteExec ["hint", _unit];
            _unit setVariable ["HasCID", _hasCID, true];
            _unit setVariable ["CID_Number", _cid, true];
            _unit setVariable ["favor", _favor, true];
            [_unit, _pos, _loadout, _combine, _arm, _armMax, _isOTA, _canFake, _hasCID, _cid] remoteExec ["MRC_fnc_applyPlayerState", _unit];
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