params ["_shield"];

private _radius = 7;     // detection radius in meters

while {alive _shield} do {

    // Find BLUFOR units within the radius
    private _nearBlu = allUnits select { side _x == west && _x distance _shield < _radius };

    if (_nearBlu isNotEqualTo []) then {
        // BLUFOR nearby → “Disable shield” (open)
        if (_shield animationPhase "Shield_HideCC" > 0.5) then {
            _shield animate ["Shield_HideCC", 0];
        };
    } else {
        // No BLUFOR → “Enable shield” (close)
        if (_shield animationPhase "Shield_HideCC" < 0.5) then {
            _shield animate ["Shield_HideCC", 1];
        };
    };

    sleep 1;
};
