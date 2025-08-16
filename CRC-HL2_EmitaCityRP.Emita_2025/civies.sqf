// File: dynamicCivilians.sqf
// Spawns civilians near city_ markers when players approach.
// Civilians wander toward random city markers and despawn when players leave.

if (!isServer) exitWith {};

private _civTypes = ["HL_CIV_Man_01","HL_CIV_Man_02","CombainCIV_Uniform_1_Body"];

private _cityMarkers = allMapMarkers select { toLower _x find "city_" == 0 };
if (_cityMarkers isEqualTo []) exitWith {};

[_civTypes, _cityMarkers] spawn {
    params ["_civTypes", "_markers"];
    private _active = [];

    while {true} do {
        {
            private _m    = _x;
            private _pos  = getMarkerPos _m;
            private _idx  = _active findIf { (_x select 0) == _m };
            private _near = allPlayers findIf { _pos distance2D _x < 300 } >= 0;
            private _far  = allPlayers findIf { _pos distance2D _x < 500 } == -1;

            if (_near) then {
                if (_idx < 0) then {
                    private _grp  = createGroup civilian;
                    private _cnt  = 1 + floor random 3;
                    for "_i" from 1 to _cnt do {
                        private _sp = [_pos, 5, 30, 0, 0, 20, 0] call BIS_fnc_findSafePos;
                        private _u  = _grp createUnit [selectRandom _civTypes, _sp, [], 0, "FORM"];
                        _u setBehaviour "SAFE";
                        _u setSpeedMode "LIMITED";
						_u setUnitPos "up";
                    };
                    [_grp, _markers] spawn {
                        params ["_grp", "_markers"];
                        while { count units _grp > 0 } do {
                            private _dest = getMarkerPos (selectRandom _markers);
                            { _x doMove _dest } forEach units _grp;
                            sleep (60 + random 60);
                        };
                    };
                    _active pushBack [_m, _grp];
                };
            } else {
                if (_far && { _idx >= 0 }) then {
                    private _grp = _active select _idx select 1;
                    { deleteVehicle _x } forEach units _grp;
                    deleteGroup _grp;
                    _active deleteAt _idx;
                };
            };
        } forEach _markers;

        sleep 10;
    };
};