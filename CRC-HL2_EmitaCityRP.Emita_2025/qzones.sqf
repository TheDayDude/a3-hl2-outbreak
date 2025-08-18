if (isNil "XEN_fnc_addAnchorAction") then {
    XEN_fnc_addAnchorAction = {
        params ["_anchor"];
        if (isNull _anchor) exitWith {};
        _anchor addAction [
            "Clear Xen Anchor",
            {
                params ["_target", "_caller"];
                [_target, _caller] spawn {
                    params ["_t", "_c"];
                    _c playMove "AinvPknlMstpSnonWnonDnon_medic_1";
                    uisleep 6;
                    [_t, _c] remoteExecCall ["XEN_fnc_clearAnchorServer", 2];
                };
            },
            nil, 1.5, true, true, "", "_this distance _target < 4", 5, true
        ];
    };
    publicVariable "XEN_fnc_addAnchorAction";
};

if (isNil "XEN_fnc_clearAnchorServer") then {
    XEN_fnc_clearAnchorServer = {
        params ["_anchor", "_caller"];
        if (isNull _anchor || isNull _caller) exitWith {};
        private _tokenCount = 1 + floor random 2;
        for "_i" from 1 to _tokenCount do { _caller addItem "VRP_HL_Token_Item"; };
        private _meatCount = 3 + floor random 3;
        for "_i" from 1 to _meatCount do { _caller addItem "VRP_StrangeMeat"; };
		[format ["Xen Anchor cleared. You are awarded %1 Tokens for Infestation Control duty. You also scavenge %2 Strange Meat.", _tokenCount, _meatCount]]
		remoteExec ["hintSilent", _caller];		
        if (uniform _caller != "CombainCIV_Uniform_2" && random 1 < 0.7) then {
            _caller setDamage (damage _caller + 0.4);
            [format ["Lacking hazard protection, your skin burns from corrosive exogen material. But you still are awarded %1 Tokens for Infestation Control duty and manage to scavenge %2 Strange Meat. "], _tokenCount, _meatCount]
            remoteExec ["hintSilent", _caller];			
        };
        deleteVehicle _anchor;
        missionNamespace setVariable ["Infestation", (missionNamespace getVariable ["Infestation",0]) - 1, true];
    };
    publicVariable "XEN_fnc_clearAnchorServer";
};

[] spawn {
    // === QZONE 1: Zombies, Headcrabs, Rare Bullsquid/Houndeye ===
    [] spawn {
        while {true} do {
            private _players = allPlayers select {alive _x && _x inArea qzone_1};
            if (!(_players isEqualTo [])) then {
                private _target   = selectRandom _players;
                private _spawnPos = _target getPos [random 50, random 360];
                private _grp      = createGroup resistance;

                private _types = [
                    "WBK_Zombine_HLA_1",
                    "WBK_ClassicZombie_HLA_1","WBK_ClassicZombie_HLA_2","WBK_ClassicZombie_HLA_3",
                    "WBK_ClassicZombie_HLA_4","WBK_ClassicZombie_HLA_5","WBK_ClassicZombie_HLA_6",
                    "WBK_ClassicZombie_HLA_7","WBK_ClassicZombie_HLA_8",
                    "WBK_Headcrab_Normal"
                ];
                for "_i" from 1 to (1 + floor random 2) do {
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

                if (random 1 < 0.1) then {
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

                // NEW: periodic re-target toward whoever is in qzone_1
                [_grp] spawn {
                    params ["_grp"];
                    while { ({alive _x} count units _grp) > 0 } do {
                        private _zonePlayers = allPlayers select {alive _x && _x inArea qzone_1};
                        if !(_zonePlayers isEqualTo []) then {
                            private _tgt = selectRandom _zonePlayers;
                            { if (alive _x) then { _x doMove (getPos _tgt) }; } forEach units _grp;
                        };
                        sleep (10 + random 20);
                    };
                };

                // Cleanup for this spawn: if no players in qzone_1 for 300s, delete group
                [_grp] spawn {
                    params ["_grp"];
                    while {({alive _x} count units _grp) > 0} do {
                        if ((allPlayers select {alive _x && _x inArea qzone_1}) isEqualTo []) then {
                            private _t0 = time;
                            waitUntil {
                                sleep 5;
                                ({alive _x} count units _grp) == 0
                                || ((allPlayers select {alive _x && _x inArea qzone_1}) isEqualTo [] && (time - _t0) >= 300)
                            };
                            if ((allPlayers select {alive _x && _x inArea qzone_1}) isEqualTo []) exitWith {
                                { if (!isNull _x) then { deleteVehicle _x } } forEach units _grp;
                                deleteGroup _grp;
                            };
                        };
                        sleep 10;
                    };
                };
            };
            private _delay = 15 + random 30;
            sleep _delay;
        };
    };

    // === QZONE 2: Antlions, Rare Guardian ===
    [] spawn {
        while {true} do {
            private _players = allPlayers select {alive _x && _x inArea qzone_2};
            if (!(_players isEqualTo [])) then {
                private _target   = selectRandom _players;
                private _spawnPos = _target getPos [random 200, random 360];
                private _grp      = createGroup resistance;

                for "_i" from 1 to (1 + floor random 2) do {
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

                if (random 1 < 0.05) then {
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

                // NEW: periodic re-target toward whoever is in qzone_2
                [_grp] spawn {
                    params ["_grp"];
                    while { ({alive _x} count units _grp) > 0 } do {
                        private _zonePlayers = allPlayers select {alive _x && _x inArea qzone_2};
                        if !(_zonePlayers isEqualTo []) then {
                            private _tgt = selectRandom _zonePlayers;
                            { if (alive _x) then { _x doMove (getPos _tgt) }; } forEach units _grp;
                        };
                        sleep (10 + random 10);
                    };
                };

                // Cleanup for this spawn: if no players in qzone_2 for 300s, delete group
                [_grp] spawn {
                    params ["_grp"];
                    while {({alive _x} count units _grp) > 0} do {
                        if ((allPlayers select {alive _x && _x inArea qzone_2}) isEqualTo []) then {
                            private _t0 = time;
                            waitUntil {
                                sleep 5;
                                ({alive _x} count units _grp) == 0
                                || ((allPlayers select {alive _x && _x inArea qzone_2}) isEqualTo [] && (time - _t0) >= 300)
                            };
                            if ((allPlayers select {alive _x && _x inArea qzone_2}) isEqualTo []) exitWith {
                                { if (!isNull _x) then { deleteVehicle _x } } forEach units _grp;
                                deleteGroup _grp;
                            };
                        };
                        sleep 10;
                    };
                };
            };
            private _delay = 90 + random 120;
            sleep _delay;
        };
    };

    // === QZONE 3: Mixed Xen, with Portal FX ===
    [] spawn {
        while {true} do {
            private _players = allPlayers select {alive _x && _x inArea qzone_3};
            if (!(_players isEqualTo [])) then {
                private _target   = selectRandom _players;
                private _spawnPos = _target getPos [random 50, random 360];
                private _grp      = createGroup resistance;

                // Portal storm FX
                private _soundSource = createSoundSource ["XenTele", _spawnPos, [], 0];
                private _light = "#lightpoint" createVehicleLocal _spawnPos;
                _light setLightBrightness 0.5;
                _light setLightColor [0.5, 0.1, 1];
                _light setLightAmbient [0.2, 0.1, 0.5];
                _light lightAttachObject [objNull, [0,0,5]];
                [_light] spawn { sleep 5; deleteVehicle (_this select 0) };
                [_soundSource] spawn { sleep 5; deleteVehicle (_this select 0) };

                private _types = [
                    "WBK_Zombine_HLA_2","WBK_ClassicZombie_HLA_9",
                    "WBK_Bullsquid_1","WBK_Houndeye_1","WBK_Antlion_1",
                    "WBK_Zombie_HECU_2","WBK_Zombie_Scien_3"
                ];
                for "_i" from 1 to (1 + floor random 2) do {
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

                // NEW: periodic re-target toward whoever is in qzone_3
                [_grp] spawn {
                    params ["_grp"];
                    while { ({alive _x} count units _grp) > 0 } do {
                        private _zonePlayers = allPlayers select {alive _x && _x inArea qzone_3};
                        if !(_zonePlayers isEqualTo []) then {
                            private _tgt = selectRandom _zonePlayers;
                            { if (alive _x) then { _x doMove (getPos _tgt) }; } forEach units _grp;
                        };
                        sleep (10 + random 20);
                    };
                };

                // Cleanup for this spawn: if no players in qzone_3 for 300s, delete group
                [_grp] spawn {
                    params ["_grp"];
                    while {({alive _x} count units _grp) > 0} do {
                        if ((allPlayers select {alive _x && _x inArea qzone_3}) isEqualTo []) then {
                            private _t0 = time;
                            waitUntil {
                                sleep 5;
                                ({alive _x} count units _grp) == 0
                                || ((allPlayers select {alive _x && _x inArea qzone_3}) isEqualTo [] && (time - _t0) >= 300)
                            };
                            if ((allPlayers select {alive _x && _x inArea qzone_3}) isEqualTo []) exitWith {
                                { if (!isNull _x) then { deleteVehicle _x } } forEach units _grp;
                                deleteGroup _grp;
                            };
                        };
                        sleep 10;
                    };
                };
            };
            private _delay = 90 + random 120;
            sleep _delay;
        };
    };
    
    // === Xen Anchor Spawner ===
    [] spawn {
        private _markers = allMapMarkers select { (_x select [0,7]) == "anchor_" };
        private _active  = [];
        private _max     = 6;
        while {true} do {
            _active = _active select { alive (_x select 1) };
            {
                if (count _active >= _max) exitWith {};
                private _m = _x;
                if (_active findIf { (_x select 0) == _m } == -1 && {random 1 < 0.2}) then {
                    private _anchor = createVehicle ["xen_anchor", getMarkerPos _m, [], 0, "NONE"];
                    _active pushBack [_m, _anchor];
                    [_anchor] remoteExec ["XEN_fnc_addAnchorAction", 0, true];
                    missionNamespace setVariable ["Infestation", (missionNamespace getVariable ["Infestation",0]) + 1, true];
                };
            } forEach _markers;
            sleep (300 + random 120);
        };
    };
};
