//Escaping the city
[] spawn {
    while {true} do {
        {
            if (
                side _x == civilian &&
                alive _x &&
                damage _x < 0.9 &&
				!captive _x &&
                {!(_x inArea City18)}
            ) then {
                private _target = _x;
                [_target] joinSilent createGroup east;

                hint format ["%1 is now malcompliant. Reason: Evasion Behavior.", name _target];
                ["Attention please: Evasion behavior consistent with malcompliant defendent. Ground Protection team: alert, code: isolate, expose, administer."] remoteExec ["systemChat", 0];
                ["Fevasionbehavior2spkr"] remoteExec ["playSound", 0];

                // Spawn assassin squad
                private _assassinTypes = [
                    "WBK_Combine_ASS_SMG",
                    "WBK_HL_Conscript_1",
					"WBK_HL_Conscript_2",
                    "WBK_HL_Conscript_6"
                ];

                private _spawnPos = _target getPos [300 + random 100, random 360];
                private _grp = createGroup west;

                private _units = [];
                {
                    private _unit = _grp createUnit [_x, _spawnPos, [], 0, "FORM"];
                    _units pushBack _unit;
                } forEach _assassinTypes;

                _grp setBehaviour "AWARE";
                _grp setCombatMode "RED";

                // Continuous tracking loop
                [_grp, _target] spawn {
                    params ["_grp", "_target"];
                    while {alive _target && ({alive _x} count units _grp > 0)} do {
                        private _pos = getPos _target;
                        private _wp = _grp addWaypoint [_pos, 0];
                        _wp setWaypointType "MOVE";
                        _wp setWaypointSpeed "FULL";
                        _wp setWaypointBehaviour "AWARE";
                        sleep 60;
                    };
                };

                // Watch for target death and cleanup
                [_units, _target] spawn {
                    params ["_units", "_target"];
                    waitUntil { !alive _target };
                    sleep 30;
                    {
                        if (!isNull _x) then { deleteVehicle _x };
                    } forEach _units;
                };
            };
        } forEach allPlayers;

        sleep 10;
    };
};

//Restricted Areas

[] spawn {
    while {true} do {
        {
            private _civ = _x;

            if (
                side _civ == civilian &&
                alive _civ &&
                damage _civ < 0.9 &&
                !captive _civ &&
                (
                    _civ inArea RestrictedZone1 ||
                    _civ inArea RestrictedZone2 ||
                    _civ inArea RestrictedZone3 ||
                    _civ inArea RestrictedZone4 ||
                    _civ inArea RestrictedZone5
                )
            ) then {
                // Mark civilian and swap
                [_civ] joinSilent createGroup east;

                hint format ["%1 is now malcompliant. Reason: Unauthorized access.", name _civ];
                ["Individual, you are now charged with Socio-Endangerment, Level 5. Cease evasion immediately, receive your verdict."] remoteExec ["systemChat", 0];
                ["Fceaseevasionlevelfivespkr"] remoteExec ["playSound", 0];

                // Spawn Combine squad to hunt them
                private _patrolTypes = [
                    "WBK_Combine_Ordinal",
                    "WBK_Combine_Walhammer",
                    "WBK_Combine_APF",
                    "WBK_Combine_Grunt",
                    "WBK_Combine_Grunt_White"
                ];

                private _spawnPos = _civ getPos [25 + random 25, random 360];
                private _grp = createGroup west;
                private _units = [];

                {
                    private _unit = _grp createUnit [_x, _spawnPos, [], 0, "FORM"];
                    _units pushBack _unit;
                } forEach _patrolTypes;

                _grp setBehaviour "AWARE";
                _grp setCombatMode "RED";

                // Tracking loop
                [_grp, _civ] spawn {
                    params ["_grp", "_target"];
                    while {alive _target && ({alive _x} count units _grp > 0)} do {
                        private _wp = _grp addWaypoint [getPos _target, 0];
                        _wp setWaypointType "MOVE";
                        _wp setWaypointSpeed "FULL";
                        _wp setWaypointBehaviour "AWARE";
                        sleep 60;
                    };
                };

                // Cleanup logic after target death
                [_units, _civ] spawn {
                    params ["_units", "_target"];
                    waitUntil { !alive _target };
                    sleep 30;
                    {
                        if (!isNull _x) then { deleteVehicle _x };
                    } forEach _units;
                };
            };
        } forEach allPlayers;

        sleep 10;
    };
};



[] spawn {
    while {true} do {
        {
            private _civ = _x;

            if (
                side _civ == civilian &&
                alive _civ &&
				!captive _x &&
                damage _civ < 0.9 // Skip downed/incapacitated units
            ) then {

                // 1. Weapon brandishing near Combine
                if (currentWeapon _civ != "") then {
                    private _combineNearby = allUnits select {
                        side _x == west &&
                        alive _x &&
                        (_x distance _civ) < 30
                    };

                    if (count _combineNearby > 0) then {
                        [_civ] joinSilent createGroup east;
                        hint format ["%1 is now malcompliant. Reason: Socio-Endangerment.", name _civ];
						["Individual: you are charged with Socio-endagerment, level1. Protection Units: prosecution code: duty, sword, midnight."] remoteExec ["systemChat", 0];
						["Fsociolevel14spkr"] remoteExec ["playSound", 0];
                    };
                };

				// 2. Has damaged a Combine unit
				{
					if (
						side _x == west &&
						alive _x
					) then {
						private _damager = _x getVariable ["lastDamager", objNull];
						if (_damager == _civ) then {
							[_civ] joinSilent createGroup east;
							hint format ["%1 is now malcompliant. Reason: Capital Malcompliance.", name _civ];
							["Individual, you are charged with capital malcompliance. Anti-citizen status approved."] remoteExec ["systemChat", 0];
							["fcapitalmalcompliancespkr"] remoteExec ["playSound", 0];

							// Clear variable so it doesn’t repeat
							_x setVariable ["lastDamager", objNull, true];
						};
					};
				} forEach allUnits;

            };
        } forEach allPlayers;

        sleep 2;
    };
};

[] spawn {
    while {true} do {
        {
            private _civ = _x;

            if (
                side _civ == civilian &&
                alive _civ &&
				!captive _x &&
                isNil {_civ getVariable "firedEHAdded"}
            ) then {
                _civ setVariable ["firedEHAdded", true];

                _civ addEventHandler ["Fired", {
                    params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile"];

                    // Ensure unit is still civilian when firing
                    if (side _unit != civilian) exitWith {};

                    // Check for nearby Combine (west) units
                    private _combineNearby = allUnits select {
                        side _x == west &&
                        alive _x &&
                        (_x distance _unit) < 150
                    };

                    if (count _combineNearby > 0) then {
                        [_unit] joinSilent createGroup east;
                        hint format ["%1 is now malcompliant. Reason: Anticvil Violations.", name _unit];
						["Individual, you are convicted of multi-anticivil violations. Implicit citizenship revoked, status: malignant."] remoteExec ["systemChat", 0];
						["fcitizenshiprevoked6spkr"] remoteExec ["playSound", 0];
                    };
                }];
            };
        } forEach allPlayers;

        sleep 5;
    };
};

[] spawn {
    while {true} do {
        {
            if (
                side _x == west &&
                alive _x &&
				!captive _x &&
                isNil {_x getVariable "hasKilledEH"}
            ) then {
                _x addEventHandler ["Killed", {
                    params ["_unit", "_killer"];

                    if (
                        !isNull _killer &&
                        {side _killer == civilian} &&
                        {isPlayer _killer}
                    ) then {
                        [_killer] joinSilent createGroup east;
                        hint format ["%1 is now malcompliant. Reason: Capital Malcompliance.", name _killer];
                        ["Individual, you are charged with capital malcompliance. Anti-citizen status approved."] remoteExec ["systemChat", 0];
                        ["fcapitalmalcompliancespkr"] remoteExec ["playSound", 0];
                    };
                }];
                _x setVariable ["hasKilledEH", true];
            };
        } forEach allUnits;

        sleep 5;
    };
};

[] spawn {
    private _spawnInterval = 300 + random 300; // seconds
    private _combineTypes = [
        "WBK_Combine_CP_SMG",
        "WBK_Combine_CP_SMG",
		"WBK_Combine_CP_SMG",
        "WBK_Combine_Wallhammer",
        "WBK_Combine_APF",
        "WBK_Combine_Ordinal"
		
    ];

    while {true} do {
        private _targets = allPlayers select {
            side _x == east &&
            alive _x &&
            (_x inArea City18)
        };

        if (count _targets > 0) then {
            {
                private _target = _x;

                // Spawn Combine Squad near the target
                private _spawnPos = _target getPos [100 + random 50, random 360];
                private _grp = createGroup west;
                private _units = [];

                for "_i" from 1 to (3 + floor random 3) do {
                    private _unit = _grp createUnit [selectRandom _combineTypes, _spawnPos, [], 0, "FORM"];
                    _units pushBack _unit;
					if (typeOf _unit == "WBK_Combine_CP_SMG") then {
						_unit forceAddUniform "U_C18_Uniform_7";
						removeHeadgear _unit;
						_unit addHeadgear "H_SM_OVSMask2";
						_unit removeWeapon (primaryWeapon _unit);
						_unit addWeapon "hlc_rifle_416D10_st6";
						_unit addMagazines ["30Rnd_556x45_Stanag_Tracer_Blue", 6];					
					};
                };

                _grp setBehaviour "AWARE";
                _grp setCombatMode "RED";

                // Initial waypoint toward target
                private _wp = _grp addWaypoint [getPos _target, 0];
                _wp setWaypointType "MOVE";
                _wp setWaypointSpeed "FULL";
                _wp setWaypointBehaviour "AWARE";

                ["Attention Ground Units. Mission failure will result in permanent offworld assignment. Code reminder: sacrifice, coagulate, clamp."] remoteExec ["systemChat", 0];
                ["fprisonmissionfailurereminder"] remoteExec ["playSound", 0];

                // Cleanup when target dies or escapes
                [_units, _target] spawn {
                    params ["_units", "_target"];
                    waitUntil {
                        sleep 5;
                        !alive _target || {!(_target inArea City18)}
                    };

                    sleep 30; // Give them time to notice
                    {
                        if (!isNull _x) then { deleteVehicle _x };
                    } forEach _units;
                };

            } forEach _targets;
        };

        sleep _spawnInterval;
    };
};
