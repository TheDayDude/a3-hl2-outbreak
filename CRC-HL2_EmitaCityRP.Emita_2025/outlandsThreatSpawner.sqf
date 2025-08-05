[] spawn {
    private _xenClassnames = [
        "WBK_Bullsquid_1",
        "WBK_Houndeye_1",
        "WBK_Antlion_1",
        "WBK_ClassicZombie_HLA_9",
        "WBK_Zombine_HLA_2",
        "WBK_Headcrab_Normal"
    ];

    private _combineUnits = ["WBK_Combine_HL2_Type_WastelandPatrol", "WBK_Combine_Ordinal", "WBK_Combine_Grunt",  "WBK_HumanSynth_1", "WBK_HunterSynth_1", "WBK_Combine_ASS_smg"];

    while {true} do {
        private _players = allPlayers select { alive _x && _x inArea outlands };

        if !(_players isEqualTo []) then {
            private _opforPlayers = _players select { side _x == opfor };
            private _target = selectRandom _players;

            private _spawnDir = random 360;
            private _spawnPos = getPos _target vectorAdd [200 * cos _spawnDir, 200 * sin _spawnDir, 0];

            if (!(_opforPlayers isEqualTo []) && (random 1 < 0.5)) then {
                private _grp = createGroup west;
                for "_i" from 1 to (2 + floor random 3) do {
                    private _type = selectRandom _combineUnits;
                    _grp createUnit [_type, _spawnPos, [], 0, "FORM"];
                };

                _grp setBehaviour "AWARE";
                _grp setCombatMode "RED";
                _grp addWaypoint [position _target, 0];

                private _vehicleChance = random 1;

                if (_vehicleChance < 0.4) then {
                    private _apc = createVehicle ["HL_CMB_OW_APC", _spawnPos vectorAdd [10,10,0], [], 0, "NONE"];
                    createVehicleCrew _apc;
                    _apc setDir random 500;
                    _apc setCombatMode "RED";
                    _apc setBehaviour "AWARE";
                    _apc lock true;

                    private _wp = (group (crew _apc select 0)) addWaypoint [position _target, 0];
                    _wp setWaypointType "SAD";
                };

                if (_vehicleChance >= 0.4 && _vehicleChance < 0.5) then {
                    private _heli = createVehicle ["HL_CMB_Hunter", _spawnPos vectorAdd [0,0,100], [], 0, "FLY"];
                    createVehicleCrew _heli;
                    _heli setDir random 500;
                    _heli setCombatMode "RED";
                    _heli setBehaviour "COMBAT";
                    _heli lock true;

                    private _wp = (group (crew _heli select 0)) addWaypoint [position _target, 0];
                    _wp setWaypointType "SAD";
                };
            } else {
                private _grp = createGroup resistance;
                for "_i" from 1 to (1 + floor random 4) do {
                    private _type = selectRandom _xenClassnames;
                    private _unit = _grp createUnit [_type, _spawnPos, [], 0, "FORM"];
                    _unit setBehaviour "AWARE";
                    _unit setCombatMode "RED";

                    _unit addEventHandler ["Killed", {
                        params ["_dead", "_killer"];
                        private _meatCount = selectRandom [0,1,1,2];
                        for "_i" from 1 to _meatCount do {
                            private _item = createVehicle ["GroundWeaponHolder", getPosATL _dead, [], 0, "NONE"];
                            _item addItemCargoGlobal ["VRP_StrangeMeat", 1];
                        };
                    }];
                };
                _grp addWaypoint [position _target, 0];
            };
        };

        sleep (300 + random 900);
    };
};
