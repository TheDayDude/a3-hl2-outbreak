if (isServer) then {
    addMissionEventHandler ["EntityKilled", {
        params ["_dead", "_killer"];
        private _deadSide = _dead getVariable ["OriginalSide", side _dead];
        private _killerSide = side _killer;
        if (!isPlayer _killer) exitWith {};
        if (_killerSide == west) exitWith {};
        if (_deadSide != west) exitWith {};
        if (_killerSide == civilian) then { [_killer] joinSilent createGroup east };
        [_killer] call MRC_fnc_registerKill;
    }];
};

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

respCity = [0,300,240,180,120,60];
respOut  = [0,1800,1500,1200,900,300];
 
// === Utility functions ===
MRC_fnc_updateWantedLevel = {
    params ["_unit"];
    private _k = _unit getVariable ["antiKills",0];
    private _lvl = 0;
    if (_k >= 100) then {_lvl = 5} else {if (_k >= 50) then {_lvl = 4} else {if (_k >= 25) then {_lvl = 3} else {if (_k >= 15) then {_lvl = 2} else {if (_k >= 1) then {_lvl = 1};};};};};
    _unit setVariable ["wantedLevel",_lvl,true];
};

MRC_fnc_resetWanted = {
    params ["_unit"];
    _unit setVariable ["antiKills",0,true];
    _unit setVariable ["wantedLevel",0,true];
    _unit setVariable ["qrfPending",false];
    _unit setVariable ["backUpPending",false];
    private _grp = _unit getVariable ["qrfGroup",objNull];
    private _veh = _unit getVariable ["qrfVehicle",objNull];
    private _back = _unit getVariable ["backUpGroup",objNull];
    if (!isNull _grp || !isNull _veh || !isNull _back) then {
        [_grp,_veh,_back] spawn {
            params ["_grp","_veh","_back"];
            sleep 300;
            if (!isNull _grp) then {{deleteVehicle _x} forEach units _grp; deleteGroup _grp;};
            if (!isNull _veh) then {deleteVehicle _veh};
            if (!isNull _back) then {{deleteVehicle _x} forEach units _back; deleteGroup _back;};
        };
    };
    _unit setVariable ["qrfGroup",objNull];
    _unit setVariable ["qrfVehicle",objNull];
    _unit setVariable ["backUpGroup",objNull];
};

// Server side handler for a player killing a Combine unit
MRC_fnc_registerKill = {
    params ["_killer"];
    private _k = (_killer getVariable ["antiKills",0]) + 1;
    _killer setVariable ["antiKills",_k,true];
    [_killer] call MRC_fnc_updateWantedLevel;
    [_killer] call MRC_fnc_scheduleQRF;
    [_killer] call MRC_fnc_scheduleBackUp;
};
publicVariable "MRC_fnc_registerKill";

MRC_fnc_trackQRF = {
    params ["_grp","_target","_veh"];
    private _origVeh = _veh;
    private _onFoot = isNull _veh || {({vehicle _x != _veh} count units _grp) > 0};
    private _lostStart = 0;
    private _noPlayerTime = -1;
    private _abandon = false;
    private _stuckPos = if (isNull _veh) then {[0,0,0]} else {getPos _veh};
    private _stuckStart = time;

    private _findSafePos = {
        params ["_obj"];
        private _p = [getPos _obj, 0, 100, 5, 0, 20, 0] call BIS_fnc_findSafePos;
        _p set [2,0];
        _p
    };

    if (!isNull _veh) then {
        sleep 10;
        _veh engineOn true;
        private _dir = vectorDir _veh;
        _veh setVelocity [(_dir select 0) * 5, (_dir select 1) * 5, (_dir select 2) * 5];
        sleep 5;
    };

    private _wpPos = [_target] call _findSafePos;
    private _wp = _grp addWaypoint [_wpPos,0];
    _wp setWaypointType "MOVE";
    _wp setWaypointSpeed "FULL";

        while {alive _target && ({alive _x} count units _grp > 0) && !_abandon} do {
        if (!_onFoot && {!isNull _veh} && {(!alive _veh) || {!canMove _veh}}) then {
            {
                unassignVehicle _x;
                [_x] allowGetIn false;
                doGetOut _x;
            } forEach units _grp;
            [_grp] orderGetIn false;
            _grp setCombatMode "RED";
            _grp setBehaviour "COMBAT";
            deleteWaypoint _wp;
            _onFoot = true;
            _lostStart = 0;
        };
        
        if (!_onFoot && {({vehicle _x != _veh} count units _grp) > 0}) then {
            _grp setCombatMode "RED";
            _grp setBehaviour "COMBAT";
            deleteWaypoint _wp;
            _onFoot = true;
            _lostStart = 0;
        };

        if (!_onFoot) then {
            if (!isNull _veh && {alive _veh}) then {
                if (_veh distance _stuckPos > 5) then {
                    _stuckPos = getPos _veh;
                    _stuckStart = time;
                } else {
                    if (time - _stuckStart > 300) then {
                        {
                            unassignVehicle _x;
                            [_x] allowGetIn false;
                            doGetOut _x;
                        } forEach units _grp;
                        [_grp] orderGetIn false;
                        _grp setCombatMode "RED";
                        _grp setBehaviour "COMBAT";
                        deleteWaypoint _wp;
                        _onFoot = true;
                        _veh = objNull;
                        _lostStart = 0;
                    };
                };
            };
            if (!_onFoot) then {
                if (!isNull _veh && {_veh distance _target < 50}) then {
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
                    deleteWaypoint _wp;
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
            };
        } else {
            _grp move getPos _target;
            private _dist = (leader _grp) distance _target;
            if (_dist > 500) then {
                if (_lostStart == 0) then {_lostStart = time;};
                if (time - _lostStart > 60) then {
                    if (!isNull _veh && {alive _veh}) then {
                        private _driver = leader _grp;
                        _driver assignAsDriver _veh;
                        _driver moveInDriver _veh;
                        {
                            if (_x != _driver && {_x != gunner _veh}) then {
                                _x assignAsCargo _veh;
                                _x moveInCargo _veh;
                            };
                            [_x] allowGetIn true;
                        } forEach units _grp;
                        [_grp] orderGetIn true;
                        _onFoot = false;
                        _stuckPos = getPos _veh;
                        _stuckStart = time;
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
        
        if (!isNull _veh && {(!alive _veh) || {!canMove _veh}}) then {
            private _near = allPlayers select {alive _x && {_x distance (leader _grp) < 500}};
            if (_near isEqualTo []) then {
                if (_noPlayerTime == -1) then {
                    _noPlayerTime = time;
                } else {
                    if (time - _noPlayerTime > 600) then {_abandon = true;};
                };
            } else {
                _noPlayerTime = -1;
            };
        } else {
            _noPlayerTime = -1;
        };

        sleep 5;
    };

    private _delay = if (_abandon) then {0} else {300};
    sleep _delay;
    {deleteVehicle _x} forEach units _grp;
    if (!isNull _origVeh) then {deleteVehicle _origVeh};
    deleteGroup _grp;
    _target setVariable ["qrfGroup", objNull];
    _target setVariable ["qrfVehicle", objNull];
    [_target] call MRC_fnc_scheduleQRF;
};

MRC_fnc_trackSynth = {
    params ["_grp","_target"];
    sleep 5;
    private _wp = _grp addWaypoint [getPos _target,0];
    _wp setWaypointType "MOVE";
    _wp setWaypointSpeed "FULL";
    while {alive _target && ({alive _x} count units _grp > 0)} do {
        private _leader = leader _grp;
        if (_leader distance waypointPosition _wp < 20) then {
            private _near = allPlayers select {alive _x && {_x distance _leader < 100}};
            if (_near isEqualTo []) then {
                deleteWaypoint _wp;
                _wp = _grp addWaypoint [getPos _target,0];
                _wp setWaypointType "MOVE";
                _wp setWaypointSpeed "FULL";
            } else {
                deleteWaypoint _wp;
                _grp setCombatMode "RED";
                _grp setBehaviour "COMBAT";
                waitUntil {
                    sleep 5;
                    (!alive _target) || ({alive _x} count units _grp == 0) || ((allPlayers select {alive _x && {_x distance (leader _grp) < 100}}) isEqualTo [])
                };
                if (!alive _target || {({alive _x} count units _grp == 0)}) exitWith {};
                _wp = _grp addWaypoint [getPos _target,0];
                _wp setWaypointType "MOVE";
                _wp setWaypointSpeed "FULL";
            };
        };
        sleep 5;
    };
    {deleteVehicle _x} forEach units _grp;
    deleteGroup _grp;
};

MRC_fnc_spawnSynth = {
    params ["_target","_lvl"];
    private _spawnMarker = if (_target inArea City18 || _target inArea slums) then {"Nexus"} else {"wasteland_Patrol"};
    private _pos = getMarkerPos _spawnMarker;
    private _type = switch (_lvl) do {
        case 3: {"WBK_HumanSynth_1"};
        case 4: {if (random 1 < 0.6) then {"WBK_HumanSynth_1"} else {"WBK_HunterSynth_1"}};
        case 5: {
            private _r = random 1;
            if (_r < 0.5) then {"WBK_HumanSynth_1"} else {if (_r < 0.8) then {"WBK_HunterSynth_1"} else {"WBK_Strider_HL2"}};
        };
    };
    private _grp = createGroup west;
    _grp createUnit [_type,_pos,[],0,"FORM"];
    [_grp,_target] spawn MRC_fnc_trackSynth;
};

MRC_fnc_spawnAirSupport = {
    params ["_target","_lvl"];
    private _spawnMarker = if (_target inArea City18 || _target inArea slums) then {"Nexus"} else {"wasteland_Patrol"};
    private _pos = getMarkerPos _spawnMarker;
    private _type = if (_lvl == 4) then {"HL_CMB_Hunter"} else {selectRandom ["HL_CMB_Gunship","HL_Gunship_01"]};
    private _grp = createGroup west;
    private _veh = createVehicle [_type,_pos,[],0,"FLY"];
    private _pilot = _grp createUnit ["WBK_Combine_CP_SMG",_pos,[],0,"FORM"];
    _pilot moveInDriver _veh;
    _veh flyInHeight 200;
    [_veh,_grp,_target,_pos] spawn {
        params ["_veh","_grp","_target","_home"];
        private _radius = 500;
        for "_i" from 0 to 12 do {
            private _wpPos = _target getPos [_radius, _i * 45];
            private _wp = _grp addWaypoint [_wpPos,0];
            _wp setWaypointType "MOVE";
            _wp setWaypointSpeed "FULL";
        };
        private _wpHome = _grp addWaypoint [_home,0];
        _wpHome setWaypointType "MOVE";
        waitUntil {sleep 5; !alive _veh || {_veh distance _home < 100}};        
        if (alive _veh) then {
            {deleteVehicle _x} forEach crew _veh;
            deleteVehicle _veh;
        };
    };
};

MRC_fnc_trackBackUp = {
    params ["_grp","_target"];
    _grp setCombatMode "RED";
    _grp setBehaviour "COMBAT";
    private _wp = _grp addWaypoint [getPos _target,0];
    _wp setWaypointType "MOVE";
    _wp setWaypointSpeed "FULL";
    while {alive _target && ({alive _x} count units _grp > 0)} do {
        private _leader = leader _grp;
        if (_leader distance waypointPosition _wp < 20 && {_leader distance _target > 100}) then {
            deleteWaypoint _wp;
            _wp = _grp addWaypoint [getPos _target,0];
            _wp setWaypointType "MOVE";
            _wp setWaypointSpeed "FULL";
        };
        sleep 5;
    };
    {deleteVehicle _x} forEach units _grp;
    deleteGroup _grp;
    _target setVariable ["backUpGroup", objNull];
    [_target] call MRC_fnc_scheduleBackUp;
};

MRC_fnc_spawnBackUp = {
    params ["_target","_lvl"];
    private _pos = getMarkerPos "Nexus";
    private _grp = createGroup west;
    {
        private _unit = _grp createUnit [_x,_pos,[],0,"FORM"];
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
    } forEach ((unitLists select 1) select [0,5]);
    _target setVariable ["backUpGroup", _grp];
    [_grp,_target] spawn MRC_fnc_trackBackUp;
};

MRC_fnc_scheduleBackUp = {
    params ["_target"];
    private _lvl = _target getVariable ["wantedLevel",0];
    if (_lvl == 0) exitWith {};
    if (!(_target inArea City18) && !(_target inArea slums)) exitWith {};
    private _existing = _target getVariable ["backUpGroup",objNull];
    if (!isNull _existing && {count units _existing > 0}) exitWith {};
    if (_target getVariable ["backUpPending",false]) exitWith {};
    _target setVariable ["backUpPending",true];
    private _delay = respCity select _lvl;
    [_target,_lvl,_delay] spawn {
        params ["_t","_l","_d"];
        sleep _d;
        if (_t getVariable ["wantedLevel",0] != _l || { !(_t inArea City18) && !(_t inArea slums) }) exitWith {_t setVariable ["backUpPending",false];};
        [_t,_l] call MRC_fnc_spawnBackUp;
        _t setVariable ["backUpPending",false];
    };
};

MRC_fnc_spawnQRF = {
    params ["_target","_lvl"];
    private _spawnMarker = if (_target inArea City18 || _target inArea slums) then {"Nexus"} else {"wasteland_Patrol"};
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
            _driver assignAsDriver _veh;
            _driver moveInDriver _veh;
            {
                if (_x != _driver) then {
                    _x assignAsCargo _veh;
                    _x moveInCargo _veh;
                };
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
    [_target] call MRC_fnc_scheduleBackUp;
    private _lvl = _target getVariable ["wantedLevel",0];
    if (_lvl == 0) exitWith {};
    private _existing = _target getVariable ["qrfGroup",objNull];
    if (!isNull _existing && {count units _existing > 0}) exitWith {};
    if (_target getVariable ["qrfPending",false]) exitWith {};
    _target setVariable ["qrfPending",true];
    private _delay = if (_target inArea City18 || _target inArea slums) then {respCity select _lvl} else {respOut select _lvl};
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
                    if (!isPlayer _killer) exitWith {};
                    if (_killerSide == west) exitWith {};
                    if (_deadSide != west) exitWith {};
                    if (_killerSide == civilian) then {[_killer] joinSilent createGroup east};
                    [_killer] call MRC_fnc_registerKill;
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