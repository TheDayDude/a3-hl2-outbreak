while {true} do {
    {
        if (side _x == resistance && alive _x) then {
            private _xen = _x;
            private _xenPos = getPos _xen;

            {
                if (side _x == civilian && alive _x) then {
                    private _dist = _xen distance _x;
                    
                    if (_dist < 10) then {
                        if (!(_x getVariable ["isXenHostile", false])) then {
                            _x addRating -10000;
                            _x setVariable ["isXenHostile", true, false];
							_x forceSpeed 4;
							_x doMove (position _xen vectorAdd [(random 30) - 15, (random 30) - 15, 0]);

                        };
                    } else {
                        if (_x getVariable ["isXenHostile", false]) then {
                            _x addRating 10000;
                            _x setVariable ["isXenHostile", false, false];
                        };
                    };
                };
            } forEach allUnits;
        };
    } forEach allUnits;

    sleep 5;
};