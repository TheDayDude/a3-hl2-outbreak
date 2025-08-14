// File: outlandsThreatSpawner.sqf
[] spawn {
    private _xenCommon = [
        "WBK_ClassicZombie_HLA_3",
		"WBK_ClassicZombie_HLA_4",
		"WBK_ClassicZombie_HLA_5",
        "WBK_Zombine_HLA_1",
        "WBK_Headcrab_Normal",
        "WBK_Antlion_1",
		"WBK_Antlion_1",
		"WBK_Antlion_1",
		"WBK_Antlion_1"
    ];
    private _xenRare = [
        "WBK_Bullsquid_1",
        "WBK_Houndeye_1"
    ];

    private _combineInfantry = [
        "WBK_Combine_HL2_Type_WastelandPatrol",
        "WBK_Combine_Grunt",
        "WBK_Combine_Grunt_white",
        "WBK_HL_Conscript_2",
        "WBK_HL_Conscript_6",
        "WBK_Combine_HL2_Type",
        "WBK_Combine_Ordinal"
    ];
    private _combineSpecial = [
        "WBK_Combine_ASS_SMG",
		"WBK_Combine_ASS_Sniper",
        "WBK_HunterSynth_1",
        "WBK_HumanSynth_1",
        "WBK_Combine_APF",
        "WBK_Combine_HL2_Type_Elite"
    ];
    private _combineVehicles = ["HL_CMB_OW_APC"];
    private _combineHeli = "HL_CMB_Hunter";

    private _rebelInfantry = [
        "WBK_Rebel_Medic_1","WBK_Rebel_Rifleman_1","WBK_Rebel_Rifleman_2","WBK_Rebel_Rifleman_3",
        "WBK_Rebel_WP_1","WBK_Rebel_WP_2","WBK_Rebel_WP_3","WBK_Rebel_SMG_1","WBK_Rebel_SMG_2","WBK_Rebel_SMG_3",
        "UU_Melee"
    ];
    private _rebelSpecial = [
        "WBK_Rebel_Sniper","WBK_Rebel_HL2_RPG","UU_CP_HeavySMG","WBK_Rebel_SL_1","WBK_Rebel_SL_2"
    ];
    private _rebelVehicles = ["HL_RES_DVP_HMG"];

    private _spawnedUnits = [];

    while {true} do {
        private _players = allPlayers select { alive _x && !(_x inArea City18) && !(_x inArea nexus) && !(_x inArea slums)};
        if !(_players isEqualTo []) then {
            private _target = selectRandom _players;
            private _side = side _target;
            private _spawnDir = random 360;
            private _spawnPos = getPos _target vectorAdd [200 * cos _spawnDir, 200 * sin _spawnDir, 0];
            private _group = objNull;

            switch (_side) do {
                case opfor: {
                    private _roll = random 1;
                    if (_roll < 0.2) then {
                        _group = createGroup west;
                        for "_i" from 1 to 5 do { _group createUnit [selectRandom _combineInfantry, _spawnPos, [], 0, "FORM"]; };
                    } else {
                        if (_roll < 0.3) then {
                            _group = createGroup west;
                            for "_i" from 1 to 3 do { _group createUnit [selectRandom _combineSpecial, _spawnPos, [], 0, "FORM"]; };
                        } else {
                            if (_roll < 0.4) then {
                                private _apc = createVehicle [selectRandom _combineVehicles, _spawnPos, [], 0, "NONE"];
                                createVehicleCrew _apc;
                                _apc setDir random 360;
                                _apc setCombatMode "RED";
                                _apc setBehaviour "AWARE";
                                _apc lock true;
                                (group (crew _apc select 0)) addWaypoint [getPos _target, 0];
                                _spawnedUnits pushBack _apc;
                                { _spawnedUnits pushBack _x } forEach crew _apc;
                            } else {
                                if (_roll < 0.5) then {
                                    private _heli = createVehicle [_combineHeli, _spawnPos vectorAdd [0,0,120], [], 0, "FLY"];
                                    createVehicleCrew _heli;
                                    _heli setDir random 360;
                                    _heli flyInHeight 120;
                                    _heli lock true;
                                    private _hGrp = group (driver _heli);
                                    _hGrp setBehaviour "AWARE";
                                    _hGrp setCombatMode "GREEN";
                                    _spawnedUnits pushBack _heli;
                                    { _spawnedUnits pushBack _x } forEach crew _heli;
									[_heli, _target] spawn {
										params ["_heli","_target"];
										private _grp = group driver _heli;

										// 4 passes around/near the target
										for "_i" from 1 to 6 do {
											private _pos = _target getPos [200 + random 300, random 360];
											private _wp  = _grp addWaypoint [_pos, 0];
											_wp setWaypointType "MOVE";
											_wp setWaypointSpeed "NORMAL";
											_wp setWaypointBehaviour "AWARE";
											_wp setWaypointCompletionRadius 80;
										};
										// exit
										private _exit = _target getPos [2500 + random 1000, random 360];
										private _wpExit = _grp addWaypoint [_exit, 0];
										_wpExit setWaypointType "MOVE";
										_wpExit setWaypointSpeed "FULL";
										_wpExit setWaypointBehaviour "SAFE";

										_heli flyInHeight 150;
									};

                                } else {
                                    private _sub = random 1;
                                    _group = createGroup resistance;
                                    if (_sub < 0.8) then {
                                        for "_i" from 1 to (3 + floor random 3) do {
                                            private _type = selectRandom _xenCommon;
                                            private _u = _group createUnit [_type, _spawnPos, [], 0, "FORM"];
                                            _u setBehaviour "AWARE"; _u setCombatMode "RED";
                                            _u addEventHandler ["Killed", {
                                                params ["_dead"];
                                                for "_k" from 1 to selectRandom [0,0,1,1] do {
                                                    private _item = createVehicle ["GroundWeaponHolder", getPosATL _dead, [], 0, "NONE"];
                                                    _item addItemCargoGlobal ["VRP_StrangeMeat", 1];
                                                };
                                            }];
                                        };
                                    } else {
                                        for "_i" from 1 to (1 + floor random 2) do {
                                            private _type = selectRandom _xenRare;
                                            private _u = _group createUnit [_type, _spawnPos, [], 0, "FORM"];
                                            _u setBehaviour "AWARE"; _u setCombatMode "RED";
                                            _u addEventHandler ["Killed", {
                                                params ["_dead"];
                                                for "_k" from 1 to selectRandom [0,1,1,2] do {
                                                    private _item = createVehicle ["GroundWeaponHolder", getPosATL _dead, [], 0, "NONE"];
                                                    _item addItemCargoGlobal ["VRP_StrangeMeat", 1];
                                                };
                                            }];
                                        };
                                    };
                                };
                            };
                        };
                    };
                };

                case west: {
                    private _roll = random 1;
                    if (_roll < 0.20) then {
                        _group = createGroup east;
                        for "_i" from 1 to 7 do { _group createUnit [selectRandom _rebelInfantry, _spawnPos, [], 0, "FORM"]; };
                    } else {
                        if (_roll < 0.35) then {
                            private _ambushPos = _target getPos [200, getDir _target];
                            _group = createGroup east;
                            for "_i" from 1 to 5 do { _group createUnit [selectRandom _rebelSpecial, _ambushPos, [], 0, "FORM"]; };
                        } else {
                            if (_roll < 0.50) then {
                                private _veh = createVehicle [selectRandom _rebelVehicles, _spawnPos, [], 0, "NONE"];
                                createVehicleCrew _veh;
                                _veh setDir random 360;
                                _veh setCombatMode "RED";
                                _veh setBehaviour "AWARE";
                                _veh lock true;
                                (group (crew _veh select 0)) addWaypoint [getPos _target, 0];
                                _spawnedUnits pushBack _veh;
                                { _spawnedUnits pushBack _x } forEach crew _veh;
                            } else {
                                private _sub = random 1;
                                _group = createGroup resistance;
                                if (_sub < 0.8) then {
                                    for "_i" from 1 to (3 + floor random 3) do {
                                        private _type = selectRandom _xenCommon;
                                        private _u = _group createUnit [_type, _spawnPos, [], 0, "FORM"];
                                        _u setBehaviour "AWARE"; _u setCombatMode "RED";
                                        _u addEventHandler ["Killed", {
                                            params ["_dead"];
                                            for "_k" from 1 to selectRandom [0,0,1,1] do {
                                                private _item = createVehicle ["GroundWeaponHolder", getPosATL _dead, [], 0, "NONE"];
                                                _item addItemCargoGlobal ["VRP_StrangeMeat", 1];
                                            };
                                        }];
                                    };
                                } else {
                                    for "_i" from 1 to (1 + floor random 2) do {
                                        private _type = selectRandom _xenRare;
                                        private _u = _group createUnit [_type, _spawnPos, [], 0, "FORM"];
                                        _u setBehaviour "AWARE"; _u setCombatMode "RED";
                                        _u addEventHandler ["Killed", {
                                            params ["_dead"];
                                            for "_k" from 1 to selectRandom [0,1,1,2] do {
                                                private _item = createVehicle ["GroundWeaponHolder", getPosATL _dead, [], 0, "NONE"];
                                                _item addItemCargoGlobal ["VRP_StrangeMeat", 1];
                                            };
                                        }];
                                    };
                                };
                            };
                        };
                    };
                };
            };

            if (!isNull _group) then {
                _group setBehaviour "AWARE";
                _group setCombatMode "RED";
                _group addWaypoint [getPos _target, 0];
                { _spawnedUnits pushBack _x } forEach units _group;
            };
        };

        sleep (300 + random 300);

        private _kept = [];
        {
            private _unit = _x;
            if (alive _unit) then {
                private _nearby = allPlayers select { alive _x && (_x distance2D _unit) < 300 };
                if (count _nearby > 0) then {
                    _kept pushBack _unit;
                } else {
                    deleteVehicle _unit;
                };
            } else {
                deleteVehicle _unit;
            };
        } forEach _spawnedUnits;
        _spawnedUnits = _kept;
    };
};