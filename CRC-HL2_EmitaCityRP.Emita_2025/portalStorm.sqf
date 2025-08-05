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
	["<t color='#9ACD32' size='2'>PORTAL STORM INCOMING!</t>", "PLAIN", 1, true, true] remoteExec ["cutText", 0];  
	["Alert: Nonstandard Exogen activity detected. Execute containment procedure and report."] remoteExec ["systemChat", 0];
	["Fprisonnonstandardexogen"] remoteExec ["playSound", 0];

    sleep 150;
	
{
    private _player = _x;
    private _pos = getPos _player;
    private _dir = random 360;
    private _spawnPos = _pos vectorAdd [100 * cos _dir, 100 * sin _dir, 0];

    private _grp = createGroup resistance;

    for "_i" from 1 to (3 + floor random 5) do {
        private _type = selectRandom _xenClassnames;
        private _unit = _grp createUnit [_type, _spawnPos, [], 0, "FORM"];
		
		_unit addEventHandler ["Killed", {
			params ["_dead", "_killer"];
			private _meatCount = selectRandom [0,1,1,2];
			for "_i" from 1 to _meatCount do {
				private _item = createVehicle ["GroundWeaponHolder", getPosATL _dead, [], 0, "NONE"];
				_item addItemCargoGlobal ["VRP_StrangeMeat", 1];
		};
	}];
		
		private _soundSource = createSoundSource ["XenTele", _spawnPos, [], 0];

		private _light = "#lightpoint" createVehicleLocal _spawnPos;
		_light setLightColor [0.2, 1, 0.6];
		_light setLightBrightness 10;
		_light setLightAmbient [0.1, 0.6, 0.3];
		_light setLightAttenuation [0.5, 0, 100, 130];
		_light setLightDayLight true;

		[_light] spawn {
			sleep 5;
			deleteVehicle (_this select 0);
		};
		[_soundSource] spawn {
			sleep 5;
			deleteVehicle (_this select 0);
		};
    };
} forEach allPlayers;

	
    sleep 20;
    portalStormActive = false;
};
