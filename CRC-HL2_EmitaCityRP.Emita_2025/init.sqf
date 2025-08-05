missionNamespace setVariable ["loot1",  random 1 < 0.8];
missionNamespace setVariable ["loot2",  random 1 < 0.7];
missionNamespace setVariable ["loot3",  random 1 < 0.6];
missionNamespace setVariable ["loot4",  random 1 < 0.5];
missionNamespace setVariable ["loot5",  random 1 < 0.5];
missionNamespace setVariable ["loot6",  random 1 < 0.4];
missionNamespace setVariable ["loot7",  random 1 < 0.3];
missionNamespace setVariable ["loot8",  random 1 < 0.2];
missionNamespace setVariable ["loot9",  random 1 < 0.2];
missionNamespace setVariable ["loot10", random 1 < 0.1];

publicVariable "Global_CID_Registry";
publicVariable "CID_Loyalty";
publicVariable "CID_Malcompliance";
publicVariable "AntiCitizen";
publicVariable "WasCitizen";
CID_Loyalty = createHashMap;
CID_Malcompliance = createHashMap;

if (hasInterface) then {
    player addEventHandler ["Killed", {
        params ["_unit", "_killer"];

        _unit spawn {
            waitUntil {alive _this};
            [_this] joinSilent createGroup civilian;
            _this setVariable ["HasCID", false, false];
            _this setVariable ["CID_Number", nil, true];
            hint "You have been reassigned to the civilian population.";
        };
    }];
};

[] spawn {
    while {true} do {
        {
            private _civ = _x;

            if (
                side _civ == civilian &&
                alive _civ &&
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
                        hint format ["%1 has been flagged as hostile for brandishing a weapon near Combine forces!", name _civ];
						["Individual: you are charged with Socio-endagerment, level1. Protection Units: prosecution code: duty, sword, midnight."] remoteExec ["systemChat", 0];
						["Fsociolevel14spkr"] remoteExec ["playSound", 0];
                    };
                };

                // 2. Has damaged a Combine unit
                {
                    if (
                        side _x == west &&
                        alive _x &&
                        _x distance _civ < 50 &&
                        _x getVariable ["lastDamager", objNull] isEqualTo _civ
                    ) then {
                        [_civ] joinSilent createGroup east;
                        hint format ["%1 has been flagged as hostile for attacking Combine forces!", name _civ];
						["Individual, you are charged with capital malcompliance. Anti-citizen status approved."] remoteExec ["systemChat", 0];
						["fcapitalmalcompliancespkr"] remoteExec ["playSound", 0];
                    };
                } forEach allUnits;
            };
        } forEach allPlayers;

        sleep 2;
    };
};

missionNamespace setVariable ["loot1",  random 1 < 0.8];
missionNamespace setVariable ["loot2",  random 1 < 0.7];
missionNamespace setVariable ["loot3",  random 1 < 0.6];
missionNamespace setVariable ["loot4",  random 1 < 0.5];
missionNamespace setVariable ["loot5",  random 1 < 0.5];
missionNamespace setVariable ["loot6",  random 1 < 0.4];
missionNamespace setVariable ["loot7",  random 1 < 0.3];
missionNamespace setVariable ["loot8",  random 1 < 0.2];
missionNamespace setVariable ["loot9",  random 1 < 0.2];
missionNamespace setVariable ["loot10", random 1 < 0.1];