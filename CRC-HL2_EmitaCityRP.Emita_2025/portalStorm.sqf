portalStorm_fnc_cleanupGetAreas = {
    private _areas = [];
    {
        private _area = missionNamespace getVariable [_x, objNull];
        if (!isNull _area) then { _areas pushBack _area; };
    } forEach ["City18", "slums"];
    _areas
};

portalStorm_fnc_cleanupIsInCity = {
    params ["_unit", "_areas"];
    private _inCity = false;
    {
        if (_unit inArea _x) exitWith { _inCity = true; };
    } forEach _areas;
    _inCity
};

portalStorm_fnc_cleanupFindTarget = {
    params ["_grp", "_areas"];
    private _leader = leader _grp;
    if (isNull _leader) exitWith { objNull };

    private _target  = objNull;
    private _minDist = 1e12;
    {
        private _unit = _x;
        if (side _unit == resistance && alive _unit) then {
            if ([_unit, _areas] call portalStorm_fnc_cleanupIsInCity) then {
                private _dist = _leader distance _unit;
                if (isNull _target || { _dist < _minDist }) then {
                    _target  = _unit;
                    _minDist = _dist;
                };
            };
        };
    } forEach allUnits;
    _target
};

portalStorm_fnc_cleanupHunt = {
    params ["_grp", "_homePos"];
    if (isNull _grp) exitWith {};

    private _areas = call portalStorm_fnc_cleanupGetAreas;
    if (_areas isEqualTo []) exitWith {
        { if (!isNull _x) then { deleteVehicle _x; }; } forEach units _grp;
        deleteGroup _grp;
    };

    _grp setSpeedMode "FULL";
    _grp setCombatMode "YELLOW";
    _grp setBehaviour "COMBAT";

    private _currentWp = [];

    while {({alive _x} count units _grp) > 0} do {
        private _target = [_grp, _areas] call portalStorm_fnc_cleanupFindTarget;
        if (isNull _target) exitWith {};

        if (!(_currentWp isEqualTo [])) then {
            deleteWaypoint _currentWp;
            _currentWp = [];
        };

        _grp reveal [_target, 4];
        _currentWp = _grp addWaypoint [getPos _target, 0];
        _currentWp setWaypointType "SAD";
        _currentWp setWaypointSpeed "FULL";

        while {
            ({alive _x} count units _grp) > 0 &&
            alive _target &&
            {[_target, _areas] call portalStorm_fnc_cleanupIsInCity}
        } do {
            if (_target distance (waypointPosition _currentWp) > 30) then {
                deleteWaypoint _currentWp;
                _currentWp = _grp addWaypoint [getPos _target, 0];
                _currentWp setWaypointType "SAD";
                _currentWp setWaypointSpeed "FULL";
            };
            sleep 5;
        };

        if (!(_currentWp isEqualTo [])) then {
            deleteWaypoint _currentWp;
            _currentWp = [];
        };

        if ({alive _x} count units _grp == 0) exitWith {};
    };

    if ({alive _x} count units _grp > 0) then {
        private _rtbWp = _grp addWaypoint [_homePos, 0];
        _rtbWp setWaypointType "MOVE";
        _rtbWp setWaypointSpeed "FULL";
        waitUntil {
            sleep 5;
            if ({alive _x} count units _grp == 0) exitWith { true };
            private _leader = leader _grp;
            if (isNull _leader) exitWith { true };
            (_leader distance _homePos) < 25
        };
    };

    { if (!isNull _x) then { deleteVehicle _x; }; } forEach units _grp;
    deleteGroup _grp;
};

portalStorm_fnc_spawnCleanup = {
    private _homePos = getMarkerPos "Nexus";
    if (_homePos isEqualTo [0,0,0]) exitWith {};

    private _grp = createGroup west;
    if (isNull _grp) exitWith {};

    _grp createUnit ["WBK_Combine_Ordinal", _homePos, [], 0, "FORM"];

    private _squad = [
        "WBK_Combine_Grunt",
        "WBK_Combine_Grunt",
        "WBK_Combine_Grunt_White",
        "WBK_Combine_Grunt_White",
        "WBK_Combine_HL2_Type_WastelandPatrol",
        "WBK_Combine_HL2_Type_WastelandPatrol",
        "WBK_Combine_HL2_Type",
        "WBK_Combine_HL2_Type_AR"
    ];

    {
        _grp createUnit [_x, _homePos, [], 0, "FORM"];
    } forEach _squad;

    _grp setFormation "WEDGE";
    _grp setSpeedMode "FULL";
    _grp setCombatMode "YELLOW";
    _grp setBehaviour "COMBAT";

    [_grp, _homePos] spawn portalStorm_fnc_cleanupHunt;
};

portalStorm_fnc_start = {
    portalStormActive = true;

    private _xenClassnames = [
        "WBK_Bullsquid_1",
        "WBK_Houndeye_1",
        "WBK_Antlion_1",
        "WBK_ClassicZombie_HLA_9",
        "WBK_Zombine_HLA_2",
		"WBK_Headcrab_Normal"
    ];  
	["Alert: Nonstandard Exogen activity detected. Execute containment procedure and report."] remoteExec ["systemChat", 0];
	["Fprisonnonstandardexogen"] remoteExec ["playSound", 0];

    sleep 60;
	missionNamespace setVariable ["Infestation", (missionNamespace getVariable ["Infestation",0]) + 2, true];
	
{
    private _player = _x;
    [_player, _xenClassnames] spawn {
        params ["_player", "_xenClassnames"];
        for "_g" from 1 to 5 do {
            private _pos = getPos _player;
            private _dir = random 360;
            private _spawnPos = _pos vectorAdd [100 * cos _dir, 100 * sin _dir, 0];

            private _grp = createGroup resistance;

            for "_i" from 1 to (1 + floor random 3) do {
                private _type = selectRandom _xenClassnames;
                private _unit = _grp createUnit [_type, _spawnPos, [], 0, "FORM"];

                _unit addEventHandler ["Killed", {
                    params ["_dead", "_killer"];
                    missionNamespace setVariable ["Infestation", (missionNamespace getVariable ["Infestation",0]) - 0.01, true];
                    private _meatCount = selectRandom [0,1,1,2];
                    for "_i" from 1 to _meatCount do {
                        private _item = createVehicle ["GroundWeaponHolder", getPosATL _dead, [], 0, "NONE"];
                        _item addItemCargoGlobal ["VRP_StrangeMeat", 1];
                    };
                }];
            };

            _grp setBehaviour "COMBAT";
            _grp setCombatMode "YELLOW";
            [_grp, _spawnPos, 200] call BIS_fnc_taskPatrol;

            [[_spawnPos], {
                params ["_spawnPos"];
                private _soundSource = createSoundSource ["XenTele", _spawnPos, [], 0];

                private _light = "#lightpoint" createVehicleLocal _spawnPos;
                _light setLightColor [0.2, 1, 0.6];
                _light setLightBrightness 10;
                _light setLightAmbient [0.1, 0.6, 0.3];
                _light setLightAttenuation [0.5, 0, 100, 130];
                _light setLightDayLight true;

                private _ps = "#particlesource" createVehicleLocal _spawnPos;
                _ps setParticleParams [["\A3\data_f\ParticleEffects\Universal\Universal",16,12,8,0],"","Billboard",1,3,[0,0,0],[0,0,0],1,1.2,1,0,[10,0],[[0,1,0,1],[0,1,0,0]],[0,1],1,0,"","",_spawnPos];
                _ps setParticleRandom [0,[0.2,0.2,0.2],[0,0,0],0,0.2,[0,0,0,0],0,0];
                _ps setDropInterval 0.02;

                [_soundSource, _light, _ps] spawn {
                    params ["_soundSource", "_light", "_ps"];
                    sleep 5;
                    { deleteVehicle _x; } forEach [_soundSource, _light, _ps];
                };
            }] remoteExec ["BIS_fnc_call", 0];

            if (_g < 5) then { sleep 30; };
        };
    };
} forEach allPlayers;


    sleep 160;
    [] spawn portalStorm_fnc_spawnCleanup;
    portalStormActive = false;
};
