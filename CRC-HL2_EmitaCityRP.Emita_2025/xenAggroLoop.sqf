while {true} do {
    // Gather all Xenian units (Resistance)
    private _xenians = allUnits select {
        side _x == resistance && alive _x
    };

    // Gather all valid civilians
    private _civilians = allUnits select {
        side _x == civilian && alive _x && damage _x < 0.9
    };

    {
        private _civ = _x;

        // Find nearby xenians within 30 meters
        private _nearXenians = _xenians select {
            _civ distance _x < 30
        };

        // Make each xenian move toward this civilian
        {
            _x doMove (getPos _civ);
        } forEach _nearXenians;

        // Check for close contact (within 5 meters)
        private _closeXenians = _nearXenians select {
            _civ distance _x < 3
        };

        if ((count _closeXenians) > 0) then {
            if (!(_civ getVariable ["isXenHostile", false])) then {
                [[_civ], createGroup west] remoteExec ["joinSilent", _civ];
                _civ setVariable ["isXenHostile", true, false];

                // Revert back to civilian after 5 seconds
                [_civ] spawn {
                    params ["_unit"]; 
                    sleep 5;
                    if (alive _unit) then {
                        [[_unit], createGroup civilian] remoteExec ["joinSilent", _unit];
                        _unit setVariable ["isXenHostile", false, false];
                    };
                };
            };
        };

    } forEach _civilians;

    sleep 2;
};
