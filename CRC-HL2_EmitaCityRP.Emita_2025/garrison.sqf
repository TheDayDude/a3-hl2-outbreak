// File: garrisonSystem.sqf

[] spawn {
    private _cpTypes = [
        "WBK_Combine_CP_P",
        "WBK_Combine_CP_SB",
        "WBK_Combine_CP_SMG"
    ];

    private _patrolMarkers = allMapMarkers select { toLower _x find "patrol_" == 0 };
    private _guardMarkers = allMapMarkers select { toLower _x find "guard_" == 0 };

    private _activeGarrisons = [];

    while {true} do {
        {
            private _marker = _x;
            private _markerPos = getMarkerPos _marker;
            private _nearbyPlayers = allPlayers select { _x distance2D _markerPos < 150 };

            if (count _nearbyPlayers > 0) then {
                private _existing = _activeGarrisons select { _x select 0 == _marker };

                if (count _existing == 0) then {
                    private _grp = createGroup west;
                    private _units = [];

                    for "_i" from 1 to 3 do {
                        private _unit = _grp createUnit [selectRandom _cpTypes, _markerPos, [], 0, "FORM"];
                        if (!isNull _unit) then {
							if (typeOf _unit == "WBK_Combine_CP_P") then {
								_unit forceAddUniform "Z_C18_Uniform_1";
								sleep 5;
								_unit action ["SwitchWeapon", _unit, _unit, 100];
							};
							if (typeOf _unit == "WBK_Combine_CP_SMG") then {
								_unit forceAddUniform "U_C18_Uniform_6";
								removeHeadgear _unit;
								_unit addHeadgear "H_SM_CMBMask";
							};
							if (typeOf _unit == "WBK_Combine_CP_SB") then {
								_unit forceAddUniform "Z_C18_Uniform_5";
							};			
                            private _id = floor (1000 + random 9000);
                            _unit setName format ["UU-CPF-%1", _id];
                            _units pushBack _unit;
                            if (toLower _marker find "guard_" == 0) then {
                                _unit setDir (random 360);
                            };
                        };
                    };

                    _grp setBehaviour "SAFE";
                    _grp setCombatMode "RED";

                    if (toLower _marker find "patrol_" == 0) then {
                        for "_i" from 1 to 3 do {
                            private _wpPos = _markerPos getPos [random 30 + 20, random 360];
                            private _wp = _grp addWaypoint [_wpPos, 0];
                            _wp setWaypointType "MOVE";
                            _wp setWaypointSpeed "LIMITED";
                            _wp setWaypointBehaviour "SAFE";
                        };
                        private _cycleWP = _grp addWaypoint [_markerPos, 0];
                        _cycleWP setWaypointType "CYCLE";
                    };

                    _activeGarrisons pushBack [_marker, _units, time];
                };
            } else {
                private _index = _activeGarrisons findIf { _x select 0 == _marker };
                if (_index >= 0) then {
                    private _entry = _activeGarrisons select _index;
                    private _units = _entry select 1;
                    {
                        if (!isNull _x) then { deleteVehicle _x }; 
                    } forEach _units;
                    _activeGarrisons deleteAt _index;
                };
            };
        } forEach (_patrolMarkers + _guardMarkers);

        {
            private _entry = _x;
            private _marker = _entry select 0;
            private _units = _entry select 1;
            private _spawnTime = _entry select 2;
            private _anyAlive = {
                alive _x
            } count _units > 0;

            private _markerPos = getMarkerPos _marker;
            private _playersNearby = allPlayers select { _x distance2D _markerPos < 200 };

            if (!_anyAlive && count _playersNearby > 0 && time - _spawnTime > 1800) then {
                private _grp = createGroup west;
                private _newUnits = [];

                for "_i" from 1 to 4 do {
                    private _unit = _grp createUnit [selectRandom _cpTypes, _markerPos, [], 0, "FORM"];
                    if (!isNull _unit) then {
                        if (typeOf _unit == "WBK_Combine_CP_P") then {
                            _unit forceAddUniform "Z_C18_Uniform_1";
							sleep 5;
							_unit action ["SwitchWeapon", _unit, _unit, 100];
                        };
						if (typeOf _unit == "WBK_Combine_CP_SMG") then {
                            _unit forceAddUniform "U_C18_Uniform_6";
							removeHeadgear _unit;
							_unit addHeadgear "H_SM_CMBMask";
                        };
						if (typeOf _unit == "WBK_Combine_CP_SB") then {
                            _unit forceAddUniform "Z_C18_Uniform_5";
                        };						
                        private _id = floor (1000 + random 9000);
                        _unit setName format ["UU-CPF-%1", _id];
                        _newUnits pushBack _unit;
						if (toLower _marker find "guard_" == 0) then {
							_unit setDir (random 360);
						};
                    };
                };

                _grp setBehaviour "SAFE";
                _grp setCombatMode "RED";

                _entry set [1, _newUnits];
                _entry set [2, time];

                if (toLower _marker find "patrol_" == 0) then {
                    for "_i" from 1 to 3 do {
                        private _wpPos = _markerPos getPos [random 30 + 20, random 360];
                        private _wp = _grp addWaypoint [_wpPos, 0];
                        _wp setWaypointType "MOVE";
                        _wp setWaypointSpeed "LIMITED";
                        _wp setWaypointBehaviour "SAFE";
                    };
                    private _cycleWP = _grp addWaypoint [_markerPos, 0];
                    _cycleWP setWaypointType "CYCLE";
                };
            };
        } forEach _activeGarrisons;

        sleep 15;
    };
};
