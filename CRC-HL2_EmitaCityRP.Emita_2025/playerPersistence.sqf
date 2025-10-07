if (!isServer) exitWith {};

if (isNil "MRC_fnc_applyPlayerState") then {
    MRC_fnc_applyPlayerState = {
        params ["_unit", "_pos", "_loadout", "_combine", "_arm", "_armMax", "_isOTA", "_canFake", "_hasCID", "_cid"];
        if (!local _unit) exitWith {};
        [_unit, _pos, _loadout, _combine, _arm, _armMax, _isOTA, _canFake, _hasCID, _cid] spawn {
            params ["_unit", "_pos", "_loadout", "_combine", "_arm", "_armMax", "_isOTA", "_canFake", "_hasCID", "_cid"];
            hint "Restoring position";
            _unit setPosATL _pos;
            sleep 1;
            hint "Restoring loadout";
            _unit setUnitLoadout _loadout;
            sleep 1;
            hint "Restoring WBK variables";
            _unit setVariable ["WBK_CombineType", _combine, true];
            _unit setVariable ["WBK_HL_CustomArmour", _arm, true];
            _unit setVariable ["WBK_HL_CustomArmour_MAX", _armMax, true];
            _unit setVariable ["isOTA", _isOTA, true];
            _unit setVariable ["CanBuyFakeID", _canFake, true];
            _unit setVariable ["HasCID", _hasCID, true];
            _unit setVariable ["CID_Number", _cid, true];
            sleep 1;
            hint "State restore complete";
        };
    };
    publicVariable "MRC_fnc_applyPlayerState";
};

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
        private _squadData = [];
        if (!isNull group _unit && {leader (group _unit) isEqualTo _unit}) then {
            {
                if (!isNull _x && {_x != _unit} && {!isPlayer _x} && {alive _x}) then {
                    _squadData pushBack [typeOf _x, getUnitLoadout _x];
                };
            } forEach (units group _unit);
        };
        private _vehicleData = [];
        private _veh = vehicle _unit;
        if (_veh != _unit && {driver _veh isEqualTo _unit}) then {
            private _hitData = getAllHitPointsDamage _veh;
            private _hitNames = [];
            private _hitDamages = [];
            if (_hitData isEqualType [] && {count _hitData >= 3}) then {
                _hitNames = _hitData select 0;
                _hitDamages = _hitData select 2;
            };
            _vehicleData = [
                typeOf _veh,
                getPosWorld _veh,
                vectorDir _veh,
                vectorUp _veh,
                damage _veh,
                _hitNames,
                _hitDamages,
                fuel _veh
            ];
        };
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
            _unit getVariable ["favor", 0],
            _unit getVariable ["antiKills", 0],
            _unit getVariable ["wantedLevel", 0],
            _squadData,
            _vehicleData
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
            _data params [
                "_sideStr",
                "_pos",
                "_loadout",
                "_combine",
                "_arm",
                "_armMax",
                "_isOTA",
                "_canFake",
                "_hasCID",
                "_cid",
                "_favor",
                ["_kills",0],
                ["_wlevel",0],
                ["_squadData", []],
                ["_vehicleData", []]
            ];            
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
            _unit setVariable ["WBK_CombineType", _combine, true];
            _unit setVariable ["WBK_HL_CustomArmour", _arm, true];
            _unit setVariable ["WBK_HL_CustomArmour_MAX", _armMax, true];
            _unit setVariable ["favor", _favor, true];
            _unit setVariable ["antiKills", _kills, true];
            _unit setVariable ["wantedLevel", _wlevel, true];
            [_unit, _pos, _loadout, _combine, _arm, _armMax, _isOTA, _canFake, _hasCID, _cid] remoteExecCall ["MRC_fnc_applyPlayerState", owner _unit];
            if (_squadData isNotEqualTo []) then {
                private _grp = group _unit;
                if (isNull _grp) then {
                    _grp = createGroup _side;
                    [_unit] joinSilent _grp;
                };
                {
                    if (_x != _unit && {!isPlayer _x}) then {
                        deleteVehicle _x;
                    };
                } forEach units _grp;
                private _ensureLeader = false;
                {
                    _x params ["_cls", "_ldout"];
                    if (!isNil "_cls" && {_cls != ""}) then {
                        private _spawnPos = if (_pos isEqualType []) then {_pos} else {getPosATL _unit};
                        private _offset = [random 3 - 1.5, random 3 - 1.5, 0];
                        private _spawnAt = _spawnPos vectorAdd _offset;
                        private _ai = _grp createUnit [_cls, _spawnAt, [], 0, "FORM"];
                        if (!isNull _ai) then {
                            _ai setUnitLoadout _ldout;
                            _ensureLeader = true;
                        };
                    };
                } forEach _squadData;
                if (_ensureLeader && {leader _grp != _unit}) then {
                    _grp selectLeader _unit;
                };
            };
            private _restoredVehicle = objNull;
            if (_vehicleData isEqualType [] && {_vehicleData isNotEqualTo []}) then {
                _vehicleData params [
                    "_vehClass",
                    "_vehPos",
                    "_vehDir",
                    "_vehUp",
                    ["_vehDamage", 0],
                    ["_hitNames", []],
                    ["_hitDamages", []],
                    ["_vehFuel", 1]
                ];
                if (!isNil "_vehClass" && {_vehClass != ""}) then {
                    _restoredVehicle = createVehicle [_vehClass, [0,0,0], [], 0, "CAN_COLLIDE"];
                    if (!isNull _restoredVehicle) then {
                        if (_vehPos isEqualType []) then {
                            _restoredVehicle setPosWorld _vehPos;
                        };
                        if (_vehDir isEqualType [] && {_vehUp isEqualType []}) then {
                            _restoredVehicle setVectorDirAndUp [_vehDir, _vehUp];
                        };
                        _restoredVehicle setDamage _vehDamage;
                        if (_hitNames isEqualType [] && {_hitDamages isEqualType []}) then {
                            {
                                private _hitName = _hitNames param [_forEachIndex, ""];
                                if (_hitName != "") then {
                                    _restoredVehicle setHitPointDamage [_hitName, _x];
                                };
                            } forEach _hitDamages;
                        };
                        _restoredVehicle setFuel _vehFuel;
                    };
                };
            };
            if (!isNull _restoredVehicle) then {
                [_unit, _restoredVehicle] spawn {
                    params ["_unit", "_veh"];
                    waitUntil {sleep 0.1; alive _unit && {!isNull _veh}};
                    if (driver _veh != _unit) then {
                        _unit moveInDriver _veh;
                    };
                };
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