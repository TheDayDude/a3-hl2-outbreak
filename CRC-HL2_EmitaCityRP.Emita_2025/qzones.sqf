[] spawn {
    // === QZONE 1: Zombies, Headcrabs, Rare Bullsquid/Houndeye ===
    [] spawn {
        while {true} do {
            private _players = allPlayers select {alive _x && _x inArea qzone_1};
            if (!(_players isEqualTo [])) then {
                private _target = selectRandom _players;
                private _spawnPos = _target getPos [random 50, random 360];
                private _grp = createGroup resistance;

                private _types = ["WBK_Zombine_HLA_1", "WBK_Classic_Zombie_HLA_1", "WBK_Classic_Zombie_HLA_2","WBK_Classic_Zombie_HLA_3","WBK_Classic_Zombie_HLA_4","WBK_Classic_Zombie_HLA_5","WBK_Classic_Zombie_HLA_6","WBK_Classic_Zombie_HLA_7","WBK_Classic_Zombie_HLA_8","WBK_Headcrab_Normal"];
                for "_i" from 1 to (5 + floor random 5) do {
                    private _unit = _grp createUnit [selectRandom _types, _spawnPos, [], 5, "FORM"];
                    _unit doMove getPos _target;
					_unit addEventHandler ["Killed", {
						params ["_dead", "_killer"];
						private _meatCount = selectRandom [0,0,1,1];
						for "_i" from 1 to _meatCount do {
							private _item = createVehicle ["GroundWeaponHolder", getPosATL _dead, [], 0, "NONE"];
							_item addItemCargoGlobal ["VRP_StrangeMeat", 1];
					};
				}];					
                };

                if (random 1 < 0.2) then {
                    private _rareType = selectRandom ["WBK_Bullsquid_1", "WBK_Houndeye_1"];
                    private _rare = _grp createUnit [_rareType, _spawnPos, [], 5, "FORM"];
                    _rare doMove getPos _target;
					_rare addEventHandler ["Killed", {
						params ["_dead", "_killer"];
						private _meatCount = selectRandom [0,1,1,2];
						for "_i" from 1 to _meatCount do {
							private _item = createVehicle ["GroundWeaponHolder", getPosATL _dead, [], 0, "NONE"];
							_item addItemCargoGlobal ["VRP_StrangeMeat", 1];
					};
				}];
                };
            };
			private _delay = 100 + random 100;
			sleep _delay;
        };
    };

    // === QZONE 2: Antlions, Rare Guardian ===
    [] spawn {
        while {true} do {
            private _players = allPlayers select {alive _x && _x inArea qzone_2};
            if (!(_players isEqualTo [])) then {
                private _target = selectRandom _players;
                private _spawnPos = _target getPos [random 50, random 360];
                private _grp = createGroup resistance;

                for "_i" from 1 to (4 + floor random 5) do {
                    private _unit = _grp createUnit ["WBK_Antlion_1", _spawnPos, [], 5, "FORM"];
                    _unit doMove getPos _target;
					_unit addEventHandler ["Killed", {
						params ["_dead", "_killer"];
						private _meatCount = selectRandom [0,1,1,2];
						for "_i" from 1 to _meatCount do {
							private _item = createVehicle ["GroundWeaponHolder", getPosATL _dead, [], 0, "NONE"];
							_item addItemCargoGlobal ["VRP_AntlionMeat", 1];
					};
				}];	
                };

                if (random 1 < 0.15) then {
                    private _guardian = _grp createUnit ["WBK_AntlionGuardian_1", _spawnPos, [], 5, "FORM"];
                    _guardian doMove getPos _target;
					_guardian addEventHandler ["Killed", {
						params ["_dead", "_killer"];
						private _meatCount = selectRandom [5,7,7,9];
						for "_i" from 1 to _meatCount do {
							private _item = createVehicle ["GroundWeaponHolder", getPosATL _dead, [], 0, "NONE"];
							_item addItemCargoGlobal ["VRP_AntlionMeat", 1];
					};
				}];						
					
                };
            };
			private _delay = 100 + random 100;
			sleep _delay;
        };
    };

    // === QZONE 3: Mixed Xen, with Portal FX ===
    [] spawn {
        while {true} do {
            private _players = allPlayers select {alive _x && _x inArea qzone_3};
            if (!(_players isEqualTo [])) then {
                private _target = selectRandom _players;
                private _spawnPos = _target getPos [random 50, random 360];
                private _grp = createGroup resistance;

                // Portal storm FX
                private _soundSource = createSoundSource ["XenTele", _spawnPos, [], 0];
                private _light = "#lightpoint" createVehicleLocal _spawnPos;
                _light setLightBrightness 0.5;
                _light setLightColor [0.5, 0.1, 1];
                _light setLightAmbient [0.2, 0.1, 0.5];
                _light lightAttachObject [objNull, [0,0,5]];
				[_light] spawn {
					sleep 5;
					deleteVehicle (_this select 0);
				};
				[_soundSource] spawn {
					sleep 5;
					deleteVehicle (_this select 0);
				};

                private _types = [
                    "WBK_Zombine_HLA_2", "WBK_Classic_Zombie_HLA_9", "WBK_Bullsquid_1", "WBK_Houndeye_1",
                    "WBK_Antlion_1", "WBK_Zombie_HECU_2", "WBK_Zombie_Scien_3"
                ];
                for "_i" from 1 to (4 + floor random 3) do {
                    private _unit = _grp createUnit [selectRandom _types, _spawnPos, [], 5, "FORM"];
                    _unit doMove getPos _target;
					_unit addEventHandler ["Killed", {
						params ["_dead", "_killer"];
						private _meatCount = selectRandom [0,1,1,2];
						for "_i" from 1 to _meatCount do {
							private _item = createVehicle ["GroundWeaponHolder", getPosATL _dead, [], 0, "NONE"];
							_item addItemCargoGlobal ["VRP_StrangeMeat", 1];
					};
				}];	
                };
            };
			private _delay = 100 + random 100;
			sleep _delay;
        };
    };
};
