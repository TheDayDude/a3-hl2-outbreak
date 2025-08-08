while {true} do {
    // Get all Xenian units (resistance side)
    private _xenians = allUnits select {
        side _x == resistance && alive _x
    };

    // Get all valid civilian players
    private _civilians = allUnits select {
        side _x == civilian && alive _x && damage _x < 0.9
    };

    {
        private _xen = _x;
        private _xenPos = getPos _xen;

        {
            private _civ = _x;
            private _dist = _xen distance _civ;

            if (_dist < 8) then {
                if (!(_civ getVariable ["isXenHostile", false])) then {
                    _civ addRating -10000;  // Civ becomes hostile to Resistance
                    _civ setVariable ["isXenHostile", true, false];
                };
            } else {
                // Random chance to stalk within 30m
                if (_dist < 50 && random 1 < 0.8) then {
                    _xen doMove getPos _civ;
					_xen doTarget _civ;
					_xen doFire _civ;
                };

                if (_civ getVariable ["isXenHostile", false] && _dist > 10) then {
                    _civ addRating 10000;  // Restore rating when far
                    _civ setVariable ["isXenHostile", false, false];
                };
            };

        } forEach _civilians;

    } forEach _xenians;

    sleep 3;
};
