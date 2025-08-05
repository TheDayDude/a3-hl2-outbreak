[player] spawn {
    params ["_unit"];

    while {alive _unit} do {
        private _cid = _unit getVariable ["CID_Number", "Unregistered"];
        private _mp = CID_Malcompliance getOrDefault [_cid, 0];

        if (_mp >= 5 && rating _unit >= 0) then {
            [_unit]  joinSilent createGroup east;
            hint format ["%1 has been marked an Anti-Citizen due to a high Malcompliance Score.", name _unit];
			playSound "Alarm";
        };

        sleep 10;
    };
};

[] spawn {
    while {true} do {
        sleep 5;
        if ("Civilain_IDCard_6" in magazines player) then {
            if !(player getVariable ["isLoyalist", false]) then {
                player setVariable ["isLoyalist", true, true];
                systemChat "Loyalist status granted.";
            };
        } else {
            if (player getVariable ["isLoyalist", false]) then {
                player setVariable ["isLoyalist", false, true];
                systemChat "Loyalist status revoked.";
            };
        };
    };
};

[] spawn {
    while {true} do {
        {
            private _civ = _x;

            if (
                side _civ == civilian &&
                alive _civ &&
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
                        (_x distance _unit) < 100
                    };

                    if (count _combineNearby > 0) then {
                        [_unit] joinSilent createGroup east;
                        hint format ["%1 has been flagged as hostile for firing near Combine forces!", name _unit];
						["Individual, you are convicted of multi-anticivil violations. Implicit citizenship revoked, status: malignant."] remoteExec ["systemChat", 0];
						["fcitizenshiprevoked6spkr"] remoteExec ["playSound", 0];
                    };
                }];
            };
        } forEach allPlayers;

        sleep 5;
    };
};



