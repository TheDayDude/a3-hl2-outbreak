if (!isServer) exitWith {};

// === Configuration ===
unitLists = [
    [],
    ["WBK_Combine_CP_SMG","WBK_Combine_CP_SMG","WBK_Combine_CP_SMG","WBK_Combine_CP_P","WBK_Combine_CP_P","WBK_Combine_CP_P","WBK_Combine_CP_P"],
    ["WBK_Combine_Ordinal","WBK_Combine_Grunt","WBK_Combine_Grunt_White","WBK_Combine_HL2_Type_WastelandPatrol","WBK_HL_Conscript_6","WBK_HL_Conscript_3","WBK_Combine_Grunt","WBK_Combine_Grunt_White","WBK_Combine_Grunt_White"],
    ["WBK_Combine_Ordinal","WBK_Combine_APF","WBK_Combine_Walhammer","WBK_Combine_ASS_SMG","WBK_Combine_HL2_Type","WBK_Combine_HL2_Type_WastelandPatrol","WBK_Combine_HL2_Type"],
    ["WBK_Combine_Ordinal","WBK_Combine_APF","WBK_Combine_Walhammer","WBK_Combine_ASS_SMG","WBK_Combine_HL2_Type","WBK_Combine_HL2_Type_WastelandPatrol","WBK_Combine_HL2_Type_AR","WBK_Combine_APF","WBK_Combine_Walhammer","WBK_Combine_ASS_SMG","WBK_Combine_HL2_Type","WBK_Combine_HL2_Type_WastelandPatrol","WBK_Combine_HL2_Type_AR","WBK_Combine_APF"],
    ["WBK_Combine_HL2_Type_Elite","WBK_Combine_APF","WBK_Combine_Walhammer","WBK_Combine_ASS_Sniper","WBK_Combine_HL2_Type","WBK_Combine_HL2_Type_WastelandPatrol","WBK_Combine_HL2_Type_AR","WBK_Combine_APF","WBK_Combine_Walhammer","WBK_Combine_ASS_Sniper","WBK_Combine_HL2_Type","WBK_Combine_HL2_Type_WastelandPatrol","WBK_Combine_HL2_Type_AR","WBK_Combine_APF"]
];

transport = ["","GT_Prowler","GT_APC","HL_CMB_OW_APC","B_Heli_Transport_03_unarmed_F","B_Heli_Transport_03_F"];

respCity = [0,5,5,5,5,5];
respOut  = [0,5,5,5,5,5];
 
// === Utility functions ===
MRC_fnc_updateWantedLevel = {
    params ["_unit"];
    private _k = _unit getVariable ["antiKills",0];
    private _lvl = 0;
    if (_k >= 200) then {_lvl = 5} else {if (_k >= 100) then {_lvl = 4} else {if (_k >= 50) then {_lvl = 3} else {if (_k >= 25) then {_lvl = 2} else {if (_k >= 1) then {_lvl = 1};};};};};
    _unit setVariable ["wantedLevel",_lvl,true];
};

MRC_fnc_resetWanted = {
    params ["_unit"];
    _unit setVariable ["antiKills",0,true];
    _unit setVariable ["wantedLevel",0,true];
    _unit setVariable ["qrfPending",false];
    private _grp = _unit getVariable ["qrfGroup",objNull];
    private _veh = _unit getVariable ["qrfVehicle",objNull];
    if (!isNull _grp || !isNull _veh) then {
        [_grp,_veh] spawn {
            params ["_grp","_veh"];
            sleep 300;
            if (!isNull _grp) then {{deleteVehicle _x} forEach units _grp; deleteGroup _grp;};
            if (!isNull _veh) then {deleteVehicle _veh};
        };
    };
    _unit setVariable ["qrfGroup",objNull];
    _unit setVariable ["qrfVehicle",objNull];
};

MRC_fnc_trackQRF = {
    params ["_grp","_target","_veh"];
    private _onFoot = false;
    private _lostStart = 0;

    private _findSafePos = {
        params ["_obj"];
        private _p = [getPos _obj, 0, 100, 5, 0, 20, 0] call BIS_fnc_findSafePos;
        _p set [2,0];
        _p
    };

    if (!isNull _veh) then {
        sleep 3;
        _veh engineOn true;
        private _dir = vectorDir _veh;
        _veh setVelocity [(_dir select 0) * 5, (_dir select 1) * 5, (_dir select 2) * 5];
        sleep 3;
    };

    private _wpPos = [_target] call _findSafePos;
    private _wp = _grp addWaypoint [_wpPos,0];
    _wp setWaypointType "MOVE";
    _wp setWaypointSpeed "FULL";

    while {alive _target && ({alive _x} count units _grp > 0)} do {
        if (!_onFoot) then {
            if (!isNull _veh && {_veh distance _target < 100}) then {
                {
                    private _role = assignedVehicleRole _x;
                    if (_role isEqualTo [] || {_role select 0 != "Turret"}) then {
                        unassignVehicle _x;
                        [_x] allowGetIn false;
                        doGetOut _x;
                    };
                } forEach units _grp;
                [_grp] orderGetIn false;
                _grp setCombatMode "RED";
                _grp setBehaviour "COMBAT";
                _onFoot = true;
                _lostStart = 0;
            } else {
                private _leader = leader _grp;
                if (_leader distance _wpPos < 20 && _leader distance _target > 100) then {
                    sleep 10;
                    _wpPos = [_target] call _findSafePos;
                    _wp = _grp addWaypoint [_wpPos,0];
                    _wp setWaypointType "MOVE";
                    _wp setWaypointSpeed "FULL";
                };
            };
        } else {
            _grp move getPos _target;
            private _dist = (leader _grp) distance _target;
            if (_dist > 500) then {
                if (_lostStart == 0) then {_lostStart = time;};
                if (time - _lostStart > 300) then {
                    if (!isNull _veh && {alive _veh}) then {
                        private _driver = leader _grp;
                        _driver moveInDriver _veh;
                        {
                            if (_x != _driver && {_x != gunner _veh}) then {_x moveInCargo _veh;};
                        } forEach units _grp;
                        _onFoot = false;
                        _lostStart = 0;
                        _wpPos = [_target] call _findSafePos;
                        _wp = _grp addWaypoint [_wpPos,0];
                        _wp setWaypointType "MOVE";
                        _wp setWaypointSpeed "FULL";
                    };
                };
            } else {
                _lostStart = 0;
            };
        };
        sleep 5;
    };

    sleep 300;
    {deleteVehicle _x} forEach units _grp;
    if (!isNull _veh) then {deleteVehicle _veh};
    deleteGroup _grp;
    _target setVariable ["qrfGroup", objNull];
    _target setVariable ["qrfVehicle", objNull];
    [_target] call MRC_fnc_scheduleQRF;
};

MRC_fnc_spawnSynth = {
    params ["_target","_lvl"];
    private _spawnMarker = if (_target inArea City18) then {"Nexus"} else {"wasteland_Patrol"};
    private _pos = getMarkerPos _spawnMarker;
    private _type = switch (_lvl) do {
        case 3: {"WBK_HumanSynth_1"};
        case 4: {if (random 1 < 0.7) then {"WBK_HumanSynth_1"} else {"WBK_HunterSynth_1"}};
        case 5: {
            private _r = random 1;
            if (_r < 0.5) then {"WBK_HumanSynth_1"} else {if (_r < 0.8) then {"WBK_HunterSynth_1"} else {"WBK_Strider_HL2"}};
        };
    };
    private _grp = createGroup west;
    _grp createUnit [_type,_pos,[],0,"FORM"];
    [_grp,_target,objNull] spawn MRC_fnc_trackQRF;
};

MRC_fnc_spawnAirSupport = {
    params ["_target","_lvl"];
    private _spawnMarker = if (_target inArea City18) then {"Nexus"} else {"wasteland_Patrol"};
    private _pos = getMarkerPos _spawnMarker;
    private _type = if (_lvl == 4) then {"HL_CMB_Hunter"} else {selectRandom ["HL_CMB_Gunship","HL_Gunship_01"]};
    private _grp = createGroup west;
    private _veh = createVehicle [_type,_pos,[],0,"FLY"];
    private _pilot = _grp createUnit ["WBK_Combine_CP_SMG",_pos,[],0,"FORM"];
    _pilot moveInDriver _veh;
    _veh flyInHeight 200;
    [_veh,_grp,_target] spawn {
        params ["_veh","_grp","_target"];
        private _start = time;
        while {time - _start < 900 && alive _veh && alive _target} do {
            private _wp = _grp addWaypoint [_target getPos [500, random 360],0];
            _wp setWaypointType "MOVE";
            sleep 60;
        };
        if (alive _veh) then {
            _grp move (_veh getPos [2000, random 360]);
            sleep 60;
        };
        {deleteVehicle _x} forEach crew _veh;
        deleteVehicle _veh;
        deleteGroup _grp;
    };
};

MRC_fnc_spawnQRF = {
    params ["_target","_lvl"];
    private _spawnMarker = if (_target inArea City18) then {"Nexus"} else {"wasteland_Patrol"};
    private _pos = getMarkerPos _spawnMarker;
    private _grp = createGroup west;
    {
        private _unit = _grp createUnit [_x,_pos,[],0,"FORM"];
        if (_lvl == 1) then {
            if (_x == "WBK_Combine_CP_SMG") then {
                removeAllWeapons _unit; removeAllItems _unit; removeAllAssignedItems _unit; removeUniform _unit; removeHeadgear _unit;
                _unit forceAddUniform "U_C18_Uniform_1";
                _unit addHeadgear "H_SM_OVSMask2";
                for "_i" from 1 to 4 do {_unit addMagazine "30Rnd_556x45_Stanag_Tracer_Blue";};
                _unit addWeapon "hlc_rifle_416D10C";
            } else {
                removeAllWeapons _unit; removeAllItems _unit; removeAllAssignedItems _unit; removeUniform _unit; removeHeadgear _unit;
                _unit forceAddUniform "Z_C18_Uniform_1";
                _unit addHeadgear "H_SM_CMBMask";
                for "_i" from 1 to 4 do {_unit addMagazine "HLB_HSMG";};
                _unit addWeapon "WBK_CP_HeavySMG";
            };
        };
    } forEach (unitLists select _lvl);

    private _vehType = transport select _lvl;
    private _veh = objNull;
    if (_vehType != "") then {
        _veh = createVehicle [_vehType,_pos,[],0,"NONE"];
        if (_lvl >= 4) then {
            private _pilotGrp = createGroup west;
            private _pilot = _pilotGrp createUnit ["WBK_Combine_CP_SMG",_pos,[],0,"FORM"];
            _pilot moveInDriver _veh;
            {
                _x moveInCargo _veh;
            } forEach units _grp;
            [_veh,_pilotGrp,_grp,_target] spawn {
                params ["_veh","_pilotGrp","_grp","_target"];
                while {alive _veh && alive _target && _veh distance _target > 100} do {
                    _pilotGrp move getPos _target;
                    sleep 5;
                };
                if (alive _veh) then {
                    {unassignVehicle _x; doGetOut _x;} forEach units _grp;
                    private _away = _veh getPos [2000, random 360];
                    _pilotGrp move _away;
                    sleep 60;
                };
                {deleteVehicle _x} forEach crew _veh;
                deleteVehicle _veh;
                deleteGroup _pilotGrp;
            };
        } else {
            private _driver = leader _grp;
            _driver moveInDriver _veh;
            {
                if (_x != _driver) then {_x moveInCargo _veh;};
            } forEach units _grp;
        };
    };

    _target setVariable ["qrfGroup",_grp];
    _target setVariable ["qrfVehicle",_veh];

    if (_lvl >= 3) then {[_target,_lvl] call MRC_fnc_spawnSynth;};
    if (_lvl >= 4) then {[_target,_lvl] call MRC_fnc_spawnAirSupport;};

    [_grp,_target,_veh] spawn MRC_fnc_trackQRF;
};

MRC_fnc_scheduleQRF = {
    params ["_target"];
    private _lvl = _target getVariable ["wantedLevel",0];
    if (_lvl == 0) exitWith {};
    private _existing = _target getVariable ["qrfGroup",objNull];
    if (!isNull _existing && {count units _existing > 0}) exitWith {};
    if (_target getVariable ["qrfPending",false]) exitWith {};
    _target setVariable ["qrfPending",true];
    private _delay = if (_target inArea City18) then {respCity select _lvl} else {respOut select _lvl};
    [_target,_lvl,_delay] spawn {
        _this params ["_t","_l","_d"];
        sleep _d;
        if (_t getVariable ["wantedLevel",0] != _l) exitWith {_t setVariable ["qrfPending",false];};
        private _grp = _t getVariable ["qrfGroup",objNull];
        if (!isNull _grp && {count units _grp > 0}) exitWith {_t setVariable ["qrfPending",false];};
        [_t,_l] call MRC_fnc_spawnQRF;
        _t setVariable ["qrfPending",false];
    };
};

// === Kill Tracking ===
[] spawn {
    while {true} do {
        {
            if (!isPlayer _x && {side _x == west} && {isNil {_x getVariable "MRC_killEH"}}) then {
                _x setVariable ["OriginalSide", side _x];
                private _id = _x addEventHandler ["Killed", {
                    params ["_dead", "_killer"];
                    private _deadSide = _dead getVariable ["OriginalSide", side _dead];
                    private _killerSide = side _killer;
                    systemChat format ["%1 (%2) was killed by %3 (%4).", name _dead, _deadSide, name _killer, _killerSide];
                    if (!isPlayer _killer) exitWith {};
                    if (_killerSide == west) exitWith {};
                    if (_deadSide != west) exitWith {};
                    if (_killerSide == civilian) then {[_killer] joinSilent createGroup east};
                    private _k = (_killer getVariable ["antiKills",0]) + 1;
                    _killer setVariable ["antiKills",_k,true];
                    [_killer] call MRC_fnc_updateWantedLevel;
                    [_killer] call MRC_fnc_scheduleQRF;
                }];
                _x setVariable ["MRC_killEH", _id];
            };
        } forEach allUnits;
        sleep 5;
    };
};

// === Wanted level maintenance ===
[] spawn {
    while {true} do {
        {
            [_x] call MRC_fnc_updateWantedLevel;
        } forEach allPlayers;
        sleep 10;
    };
};

addMissionEventHandler ["EntityKilled", {
    params ["_dead"];
    if (isPlayer _dead) then {[_dead] call MRC_fnc_resetWanted;};
}];

addMissionEventHandler ["HandleDisconnect", {
    params ["_unit"];
    if (isPlayer _unit) then {[_unit] call MRC_fnc_resetWanted;};
}];