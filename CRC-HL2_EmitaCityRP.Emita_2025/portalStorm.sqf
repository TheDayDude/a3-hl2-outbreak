portalStorm_fnc_start = {
    portalStormActive = true;

    private _xenClassnames = [
        "WBK_Bullsquid_1",
        "WBK_Houndeye_1",
        "WBK_Antlion_1",
        "WBK_ClassicZombie_HLA_9",
        "WBK_Zombine_HLA_2",
		"WBK_Headcrab_Normal"
    ];  
	["Alert: Nonstandard Exogen activity detected. Execute containment procedure and report."] remoteExec ["systemChat", 0];
	["Fprisonnonstandardexogen"] remoteExec ["playSound", 0];

    sleep 60;
	missionNamespace setVariable ["Infestation", (missionNamespace getVariable ["Infestation",0]) + 2, true];
	
{
    private _player = _x;
    [_player, _xenClassnames] spawn {
        params ["_player", "_xenClassnames"];
        for "_g" from 1 to 5 do {
            private _pos = getPos _player;
            private _dir = random 360;
            private _spawnPos = _pos vectorAdd [100 * cos _dir, 100 * sin _dir, 0];

            private _grp = createGroup resistance;

            for "_i" from 1 to (1 + floor random 3) do {
                private _type = selectRandom _xenClassnames;
                private _unit = _grp createUnit [_type, _spawnPos, [], 0, "FORM"];

                _unit addEventHandler ["Killed", {
                    params ["_dead", "_killer"];
                    missionNamespace setVariable ["Infestation", (missionNamespace getVariable ["Infestation",0]) - 0.01, true];
                    private _meatCount = selectRandom [0,1,1,2];
                    for "_i" from 1 to _meatCount do {
                        private _item = createVehicle ["GroundWeaponHolder", getPosATL _dead, [], 0, "NONE"];
                        _item addItemCargoGlobal ["VRP_StrangeMeat", 1];
                    };
                }];
            };

            _grp setBehaviour "COMBAT";
            _grp setCombatMode "RED";
            [_grp, _spawnPos, 200] call BIS_fnc_taskPatrol;

            [[_spawnPos], {
                params ["_spawnPos"];
                private _soundSource = createSoundSource ["XenTele", _spawnPos, [], 0];

                private _light = "#lightpoint" createVehicleLocal _spawnPos;
                _light setLightColor [0.2, 1, 0.6];
                _light setLightBrightness 10;
                _light setLightAmbient [0.1, 0.6, 0.3];
                _light setLightAttenuation [0.5, 0, 100, 130];
                _light setLightDayLight true;

                private _ps = "#particlesource" createVehicleLocal _spawnPos;
                _ps setParticleParams [["\A3\data_f\ParticleEffects\Universal\Universal",16,12,8,0],"","Billboard",1,3,[0,0,0],[0,0,0],1,1.2,1,0,[10,0],[[0,1,0,1],[0,1,0,0]],[0,1],1,0,"","",_spawnPos];
                _ps setParticleRandom [0,[0.2,0.2,0.2],[0,0,0],0,0.2,[0,0,0,0],0,0];
                _ps setDropInterval 0.02;

                [_soundSource, _light, _ps] spawn {
                    params ["_soundSource", "_light", "_ps"];
                    sleep 5;
                    { deleteVehicle _x; } forEach [_soundSource, _light, _ps];
                };
            }] remoteExec ["BIS_fnc_call", 0];

            if (_g < 5) then { sleep 30; };
        };
    };
} forEach allPlayers;


    sleep 160;
    portalStormActive = false;
};
