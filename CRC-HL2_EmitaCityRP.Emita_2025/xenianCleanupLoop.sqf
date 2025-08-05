while {true} do {
    {
        private _group = _x;
        if (side _group == resistance) then {
            {
                private _unit = _x;
                if (alive _unit) then {
                    private _nearbyPlayers = allPlayers select { alive _x && (_x distance _unit) < 500 };
                    if (_nearbyPlayers isEqualTo []) then {
                        deleteVehicle _unit;
                    };
                };
            } forEach units _group;

            if (({alive _x} count units _group) == 0) then {
                deleteGroup _group;
            };
        };
    } forEach allGroups;

    sleep 60;
};
