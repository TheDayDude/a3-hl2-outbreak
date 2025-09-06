if (!isServer) exitWith {};

// Select a mission
private _missionIndex = selectRandom [1,2,3];

switch (_missionIndex) do {
    // === Mission 1: Raise the Flesh ===
    case 1: {
        // ----- Helpers (client addAction + server raise) -----
        if (isNil "CULT_fnc_addRaiseAction") then {
            CULT_fnc_addRaiseAction = {
                params ["_corpse","_side"];
                if (isNull _corpse || alive _corpse) exitWith {};
                if (_corpse getVariable ["hasRaiseAction", false]) exitWith {};
                _corpse setVariable ["hasRaiseAction", true, true];

                private _text = if (_side == west) then {
                    "<t color='#A0FFA0'>Raise Zombine</t>"
                } else {
                    "<t color='#A0FFA0'>Raise Zombie</t>"
                };
                _corpse addAction [
                    _text,
                    {
                        params ["_corpse","_caller","_id","_side"];
                        if (side _caller != resistance) exitWith {};
                        _corpse removeAction _id;
                        _caller playMoveNow "AinvPknlMstpSnonWnonDnon_medic_1";
                        [_caller] spawn { params ["_c"]; uiSleep 5; _c switchMove ""; };
                        [_caller, _corpse, _side] remoteExec ["CULT_fnc_raiseServer", 2];
                    },
                    _side, 1.5, true, true, "",
                    "side _this == resistance"
                ];
            };
            publicVariable "CULT_fnc_addRaiseAction";
        };

        if (isNil "CULT_fnc_raiseFX") then {
            CULT_fnc_raiseFX = {
                params ["_obj"];
                if (!hasInterface) exitWith {};

                private _pos = getPosATL _obj;
                private _ps = "#particlesource" createVehicleLocal _pos;
                _ps setParticleParams [["\A3\Data_F\ParticleEffects\Universal\Universal",16,12,8,0],"","Billboard",1,2,[0,0,0],[0,0,0],1,0.5,0.5,0.1,[1],[[0,1,0,0.5]],[0],1,0,"","",_obj];
                _ps setParticleRandom [0,[0.5,0.5,0.5],[0,0,0],0,0,[0,0,0,0],0,0];
                _ps setDropInterval 0.02;
                [_ps] spawn { params ["_p"]; sleep 5; deleteVehicle _p; };
            };
            publicVariable "CULT_fnc_raiseFX";
        };

        if (isNil "CULT_fnc_raiseServer") then {
            CULT_fnc_raiseServer = {
                params ["_caller","_corpse","_side"];
                if (isNull _corpse || alive _corpse) exitWith {};
                _corpse setVariable ["raised", true, true];

                sleep 3;
                private _hcPos = _caller modelToWorld [0,1,0];
                private _hc = createVehicle ["WBK_Headcrab_Normal", _hcPos, [], 0, "NONE"];
                _hc setDir (getDir _caller);
                _hc doMove (getPosATL _corpse);
				sleep 6;
                [_corpse] remoteExec ["CULT_fnc_raiseFX", 0];
                sleep 6;
                deleteVehicle _hc;

                private _grp = group _caller;
                private _type = if (_side == west) then {
                    selectRandom ["WBK_Zombine_HLA_1","WBK_Zombine_HLA_2"]
                } else {
                    selectRandom ["WBK_ClassicZombie_HLA_3","WBK_ClassicZombie_HLA_4","WBK_ClassicZombie_HLA_5"]
                };
                private _z = _grp createUnit [_type, getPosATL _corpse, [], 0, "NONE"];
                _z setDir (getDir _corpse);
                hideBody _corpse; deleteVehicle _corpse;

                missionNamespace setVariable ["cultRaised", (missionNamespace getVariable ["cultRaised",0]) + 1, true];
            };
            publicVariable "CULT_fnc_raiseServer";
        };
        // -----------------------------------------------------

        // Pick a rebel_ marker to stage the battle
        private _rebelMarkers = allMapMarkers select { (_x select [0,6]) == "rebel_" };
        if (_rebelMarkers isEqualTo []) exitWith {
            ["[Cult Mission] No rebel_ markers found — mission skipped."] remoteExec ["systemChat", 0];
            missionNamespace setVariable ["cultMissionActive", false, true];
        };

        missionNamespace setVariable ["cultRaised", 0, true];
        private _chosen = selectRandom _rebelMarkers;
        private _battlePos = getMarkerPos _chosen;
        private _taskId = format ["cult_raise_%1", diag_tickTime];
        [resistance, _taskId,
            ["Raise 8 of the fallen to serve you.",
             "Raise the Flesh", ""],
            _battlePos, true
        ] call BIS_fnc_taskCreate;

        private _spawned = [];
        private _groups  = [];

        // Wrecks and fires
        private _wreckTypes = ["HL_CMB_Static_Wreck_APC","Land_Cyt_Lada","Land_Wreck_Ural_F"]; 
        for "_i" from 1 to 5 do {
            private _pos = _battlePos getPos [random 25, random 360];
            private _w = createVehicle [selectRandom _wreckTypes, _pos, [], 0, "CAN_COLLIDE"];
			private _f = createVehicle ["Particle_MediumFire_F", _pos, [], 0, "CAN_COLLIDE"];
            _spawned pushBack _f;
            _spawned pushBack _w;
        };

        // Corpses
        private _corpseGrpW = createGroup west; _groups pushBack _corpseGrpW;
        private _corpseGrpE = createGroup east; _groups pushBack _corpseGrpE;
        private _combineClasses = ["WBK_Combine_Grunt","WBK_Combine_HL2_Type","WBK_Combine_HL2_Type_AR"];
        private _rebelClasses   = ["WBK_Rebel_Rifleman_1","WBK_Rebel_SMG_2","WBK_Rebel_Rifleman_2"];
        for "_i" from 1 to 3 do {
            private _pos = _battlePos getPos [random 20, random 360];
            private _cw = _corpseGrpW createUnit [selectRandom _combineClasses, _pos, [], 0, "NONE"];
            _cw setDamage 1;
            _spawned pushBack _cw;
            [_cw, west] remoteExec ["CULT_fnc_addRaiseAction", 0, true];
        };
        for "_i" from 1 to 3 do {
            private _pos = _battlePos getPos [random 20, random 360];
            private _ce = _corpseGrpE createUnit [selectRandom _rebelClasses, _pos, [], 0, "NONE"];
            _ce setDamage 1;
            _spawned pushBack _ce;
            [_ce, east] remoteExec ["CULT_fnc_addRaiseAction", 0, true];
        };

        // Wounded combatants still fighting
        for "_g" from 1 to 2 do {
            private _grp = createGroup west; _groups pushBack _grp;
            for "_i" from 1 to 3 do {
                private _pos = _battlePos getPos [random 30, random 360];
                private _u = _grp createUnit [selectRandom _combineClasses, _pos, [], 0, "FORM"];
                _u setDamage (0.5 + random 0.3);
                _u addEventHandler ["Killed", { params ["_u"]; [_u, west] remoteExec ["CULT_fnc_addRaiseAction", 0, true]; }];
                _spawned pushBack _u;
            };
        };
        for "_g" from 1 to 2 do {
            private _grp = createGroup east; _groups pushBack _grp;
            for "_i" from 1 to 3 do {
                private _pos = _battlePos getPos [random 30, random 360];
                private _u = _grp createUnit [selectRandom _rebelClasses, _pos, [], 0, "FORM"];
                _u setDamage (0.5 + random 0.3);
                _u addEventHandler ["Killed", { params ["_u"]; [_u, east] remoteExec ["CULT_fnc_addRaiseAction", 0, true]; }];
                _spawned pushBack _u;
            };
        };

        // Mission success/failure monitoring
        [_taskId, _spawned, _groups] spawn {
            params ["_taskId","_spawned","_groups"];
            private _deadline = time + 2700; // 45 minutes
            waitUntil {
                sleep 5;
                (missionNamespace getVariable ["cultRaised",0]) >= 8 || { time > _deadline }
            };
            if ((missionNamespace getVariable ["cultRaised",0]) >= 8) then {
                [_taskId, "SUCCEEDED", true] call BIS_fnc_taskSetState;
                missionNamespace setVariable ["Infestation", (missionNamespace getVariable ["Infestation",0]) + 1, true];

                // Reward independent players (4–8 tokens each)
                private _amount = 4 + floor random 5;
                private _targets = allPlayers select { side _x == resistance && alive _x };
                {
                    for "_i" from 1 to _amount do { _x addItem "VRP_HL_Token_Item"; };
                } forEach _targets;
                [format ["The       is pleased. You pillaged %1 token(s).", _amount]] remoteExec ["hintSilent", _targets apply { owner _x }];
            } else {
                [_taskId, "FAILED", true] call BIS_fnc_taskSetState;
            };

            // Cleanup and mark mission done
            missionNamespace setVariable ["cultMissionActive", false, true];
			sleep 300;
            { if (!isNull _x) then { deleteVehicle _x; }; } forEach _spawned;
            { if (!isNull _x) then { { deleteVehicle _x } forEach units _x; deleteGroup _x; }; } forEach _groups;
            [_taskId] call BIS_fnc_deleteTask;
        };
    };
    // === Mission 2: Cleanse the Ritual Site ===
    case 2: {
        // Pick a ritual marker
        private _ritualMarkers = allMapMarkers select { (_x select [0,7]) == "ritual_" };
        if (_ritualMarkers isEqualTo []) exitWith {
            ["[Cult Mission] No ritual_ markers found — mission skipped."] remoteExec ["systemChat", 0];
            missionNamespace setVariable ["cultMissionActive", false, true];
        };

        private _chosen = selectRandom _ritualMarkers;
        private _sitePos = getMarkerPos _chosen;
        private _taskId = format ["cult_cleanse_%1", diag_tickTime];
        [resistance, _taskId,
            ["Cleanse the ritual site by eliminating or driving off all Combine within 150 meters.",
             "Cleanse the Ritual Site", ""],
            _sitePos, true
        ] call BIS_fnc_taskCreate;

        private _spawned = [];
        private _groups  = [];
        private _units   = [];

        // Xen infestation props
        private _propTypes = ["xen_anchor_rock","xen_anchor_rock_2","xen_anchor_rock_3","xen_anchor_rock_4"];
        for "_i" from 1 to 4 do {
            private _p = _sitePos getPos [random 10, random 360];
            private _prop = createVehicle [selectRandom _propTypes, _p, [], 0, "CAN_COLLIDE"];
            _spawned pushBack _prop;
        };

        // Kamaz truck for cleanup crew
        private _truckPos = _sitePos getPos [random 12, random 360];
        private _truck = createVehicle ["I_E_Truck_02_F", _truckPos, [], 0, "NONE"];
        _spawned pushBack _truck;

        // Combine workers cleaning up
        private _workerGrp = createGroup west; _groups pushBack _workerGrp;
        for "_i" from 1 to 3 do {
            private _p = _sitePos getPos [random 8, random 360];
            private _w = _workerGrp createUnit ["cmb_Hz_worker", _p, [], 0, "FORM"];
            removeAllWeapons _w; removeAllAssignedItems _w;
            _w forceAddUniform "CombainCIV_Uniform_2";
            _w playMoveNow "Acts_carFixingWheel";
            _spawned pushBack _w; _units pushBack _w;
        };
        _workerGrp allowFleeing 1;

        // Patrolling Combine grunts
        for "_g" from 1 to 2 do {
            private _grp = createGroup west; _groups pushBack _grp;
            for "_i" from 1 to 4 do {
                private _p = _sitePos getPos [random 35, random 360];
                private _u = _grp createUnit [selectRandom ["WBK_Combine_Grunt","WBK_Combine_Grunt_White"], _p, [], 0, "FORM"];
                _spawned pushBack _u; _units pushBack _u;
            };
            [_grp, _sitePos, 50] call BIS_fnc_taskPatrol;
            _grp allowFleeing 1;
        };

        // Mission success/failure monitoring
        [_taskId, _sitePos, _spawned, _groups, _units] spawn {
            params ["_taskId","_center","_spawned","_groups","_units"];
            private _deadline = time + 2700; // 45 minutes
            waitUntil {
                sleep 5;
                ({alive _x && _x distance _center < 150} count _units) == 0 || { time > _deadline }
            };
            if (({alive _x && _x distance _center < 150} count _units) == 0) then {
                [_taskId, "SUCCEEDED", true] call BIS_fnc_taskSetState;
                missionNamespace setVariable ["Infestation", (missionNamespace getVariable ["Infestation",0]) + 1, true];
            } else {
                [_taskId, "FAILED", true] call BIS_fnc_taskSetState;
            };

            missionNamespace setVariable ["cultMissionActive", false, true];
            sleep 300;
            { if (!isNull _x) then { deleteVehicle _x; }; } forEach _spawned;
            { if (!isNull _x) then { { deleteVehicle _x } forEach units _x; deleteGroup _x; }; } forEach _groups;
            [_taskId] call BIS_fnc_deleteTask;
        };
    };
    // === Mission 3: Ritual: Summon Outer Beast ===
    case 3: {
        // Pick a ritual marker
        private _ritualMarkers = allMapMarkers select { (_x select [0,7]) == "ritual_" };
        if (_ritualMarkers isEqualTo []) exitWith {
            ["[Cult Mission] No ritual_ markers found — mission skipped."] remoteExec ["systemChat", 0];
            missionNamespace setVariable ["cultMissionActive", false, true];
        };

        private _chosen = selectRandom _ritualMarkers;
        private _sitePos = getMarkerPos _chosen;
        private _taskR = format ["cult_ritual_%1", diag_tickTime];
        [resistance, _taskR,
            ["Begin the ritual at the flesh altar and protect it for twelve minutes.",
             "Ritual: Summon Outer Beast", ""],
            _sitePos, true
        ] call BIS_fnc_taskCreate;
        private _taskW = format ["cult_ritual_w_%1", diag_tickTime];
        [west, _taskW,
            ["Warning: Anomalous Signal", "Warning: Anomalous Signal", ""],
            _sitePos, true
        ] call BIS_fnc_taskCreate;
        private _taskE = format ["cult_ritual_e_%1", diag_tickTime];
        [east, _taskE,
            ["Warning: Anomalous Signal", "Warning: Anomalous Signal", ""],
            _sitePos, true
        ] call BIS_fnc_taskCreate;

        private _spawned = [];
        private _groups  = [];

        // Flesh Altar
        private _altar = createVehicle ["xen_bioplant", _sitePos, [], 0, "NONE"];
        _spawned pushBack _altar;

        // Altar particle effect
        if (isNil "CULT_fnc_altarFX") then {
            CULT_fnc_altarFX = {
                params ["_altar"];
                private _pos = getPosATL _altar;
                private _ps = "#particlesource" createVehicleLocal _pos;
                _ps setParticleParams [["\A3\Data_F\ParticleEffects\Universal\Universal",16,12,8,0],"","Billboard",1,2,[0,0,0],[0,0,0],1,0.5,0.5,0.1,[1],[[0,1,0,0.5]],[0],1,0,"","",_altar];
                _ps setParticleRandom [0,[0.5,0.5,0.5],[0,0,0],0,0,[0,0,0,0],0,0];
                _ps setDropInterval 0.02;
                waitUntil { isNull _altar };
                deleteVehicle _ps;
            };
            publicVariable "CULT_fnc_altarFX";
        };
        [_altar] remoteExec ["CULT_fnc_altarFX", 0, true];

        // Cultist patrol
        private _cultGrp = createGroup resistance; _groups pushBack _cultGrp;
        for "_i" from 1 to 5 do {
            private _p = _sitePos getPos [random 10, random 360];
            private _u = _cultGrp createUnit ["I_C_Soldier_Bandit_4_F", _p, [], 0, "FORM"];
            removeAllWeapons _u; removeAllItems _u; removeAllAssignedItems _u;
            _u forceAddUniform "rds_Uniform_priest";
            _u addVest "V_bms_vest_rig";
            _u addWeapon "hlc_rifle_aks74";
            for "_m" from 1 to 3 do { _u addMagazine "hlc_30Rnd_545x39_B_AK"; };
            _u addGoggles "G_CBRN_M04_Hood";
            _u setVariable ["WBK_CombineType","  g_hecu_",true];
            _u setVariable ["WBK_HL_CustomArmour",200,true];
            _u setVariable ["WBK_HL_CustomArmour_MAX",200,true];
            _u addEventHandler ["Killed", {
                params ["_unit"];
                private _p = getPosATL _unit;
                "SmokeShellGreen" createVehicle _p;
                [_unit] spawn { deleteVehicle (_this select 0) };
                private _grp = group _unit;
                private _leaper = createAgent ["Zombie_Special_GREENFOR_Leaper_1", _p, [], 0, "NONE"];
                [_leaper] joinSilent _grp;
            }];
            _spawned pushBack _u;
        };
        [_cultGrp, _sitePos, 20] call BIS_fnc_taskPatrol;

        if (isNil "CULT_fnc_addRitualStart") then {
            CULT_fnc_addRitualStart = {
                params ["_altar","_taskR","_taskW","_taskE","_cultGrp"];
                _altar addAction [
                    "<t color='#FF00FF'>Begin Ritual</t>",
                    {
                        params ["_altar","_caller","_id","_args"];
                        _altar removeAction _id;
                        _caller playMoveNow "AinvPknlMstpSnonWnonDnon_medic_1";
                        [_caller] spawn { params ["_c"]; uiSleep 5; _c switchMove "" };
                        [_altar,_caller,_args select 0,_args select 1,_args select 2,_args select 3] remoteExec ["CULT_fnc_ritualServer", 2];
                    },
                    [_taskR,_taskW,_taskE,_cultGrp],
                    1.5, true, true, "", "side _this == resistance"
                ];
            };
            publicVariable "CULT_fnc_addRitualStart";
        };

        if (isNil "CULT_fnc_addInterrupt") then {
            CULT_fnc_addInterrupt = {
                params ["_altar"];
                _altar addAction [
                    "<t color='#FF0000'>Interrupt Ritual</t>",
                    {
                        params ["_altar","_caller","_id"];
                        _caller playMoveNow "AinvPknlMstpSnonWnonDnon_medic_1";
                        [_caller] spawn { params ["_c"]; uiSleep 20; _c switchMove "" };
                        _altar removeAction _id;
                        _altar setVariable ["ritualInterrupted", true, true];
                    },
                    nil, 1.5, true, true, "", "side _this in [west,east]"
                ];
            };
            publicVariable "CULT_fnc_addInterrupt";
        };

        if (isNil "CULT_fnc_ritualServer") then {
            CULT_fnc_ritualServer = {
                params ["_altar","_caller","_taskR","_taskW","_taskE","_cultGrp"];
                { [_x] joinSilent (group _caller); } forEach units _cultGrp;
                _altar setVariable ["ritualInterrupted", false, true];
                private _end = time + 720; // 12 minutes
                _altar setVariable ["ritualEnd", _end, true];

                ["psy_voices_01"] remoteExec ["playSound", 0];
                ["applyBlur", _caller] remoteExec ["fnc_applyBlur", _caller];

                [_altar,_caller] spawn {
                    params ["_a","_c"];
                    while { time < (_a getVariable ["ritualEnd",0]) && !(_a getVariable ["ritualInterrupted",false]) } do {
                        private _remain = ceil(((_a getVariable ["ritualEnd",0]) - time) / 60);
                        {
                            [format ["Ritual: %1 minute(s) remaining", _remain]] remoteExec ["systemChat", _x];
                        } forEach (units group _c select {isPlayer _x});
                        sleep 60;
                    };
                };

                // Weather and lightning
                0 setOvercast 1; 0 setLightnings 1; forceWeatherChange;
                [_altar] spawn {
                    params ["_a"];
                    while { time < (_a getVariable ["ritualEnd",0]) && !(_a getVariable ["ritualInterrupted",false]) } do {
                        private _p = _a getPos [20 + random 30, random 360];
                        "lightningbolt" createVehicle _p;
                        sleep (20 + random 10);
                    };
                };

                // Fog intensifies each minute
                [_altar] spawn {
                    params ["_a"];
                    private _fog = fog;
                    0 setFog [_fog,0,0];
                    while { time < (_a getVariable ["ritualEnd",0]) && !(_a getVariable ["ritualInterrupted",false]) } do {
                        _fog = _fog + 0.05;
                        if (_fog > 1) then { _fog = 1; };
                        0 setFog [_fog,0,0];
                        sleep 60;
                    };
                };

                // Attack waves
                [_altar] spawn {
                    params ["_a"];
                    private _combine = true;
                    while { time < (_a getVariable ["ritualEnd",0]) && !(_a getVariable ["ritualInterrupted",false]) } do {
                        private _type = if (_combine) then {"WBK_Combine_Grunt"} else {"WBK_Rebel_Rifleman_1"};
                        private _side = if (_combine) then {west} else {east};
                        private _grp = createGroup _side;
                        private _spawnPos = [getPosATL _a, 250, 400, 0, 0, 20, 0] call BIS_fnc_findSafePos;
                        for "_i" from 1 to 5 do {
                            private _p = [_spawnPos, 0, 5, 0, 0, 20, 0] call BIS_fnc_findSafePos;
                            _grp createUnit [_type, _p, [], 0, "FORM"];
                        };
                        _grp setBehaviour "COMBAT";
                        _grp setSpeedMode "FULL";
                        private _wp = _grp addWaypoint [getPosATL _a, 0];
                        _wp setWaypointType "SAD";
                        _wp setWaypointBehaviour "COMBAT";
                        _wp setWaypointSpeed "FULL";
                        _combine = !_combine;
                        sleep (120 + random 60);
                    };
                };

                // Random xen portals
                [_altar] spawn {
                    params ["_a"];
                    private _types = ["WBK_Bullsquid_1","WBK_Houndeye_1","WBK_Antlion_1"];
                    while { time < (_a getVariable ["ritualEnd",0]) && !(_a getVariable ["ritualInterrupted",false]) } do {
                        sleep (80 + random 40);
                        private _pos = _a getPos [10 + random 20, random 360];
                        private _grp = createGroup resistance;
                        private _u = _grp createUnit [selectRandom _types, _pos, [], 0, "FORM"];
                        [[_pos], {
                            params ["_spawnPos"];
                            private _soundSource = createSoundSource ["XenTele", _spawnPos, [], 0];
                            private _light = "#lightpoint" createVehicleLocal _spawnPos;
                            _light setLightColor [0.2, 1, 0.6];
                            _light setLightBrightness 10;
                            _light setLightAmbient [0.1, 0.6, 0.3];
                            _light setLightAttenuation [0.5, 0, 100, 130];
                            _light setLightDayLight true;
                            private _ps = "#particlesource" createVehicleLocal _spawnPos;
                            _ps setParticleParams [["\\A3\\data_f\\ParticleEffects\\Universal\\Universal",16,12,8,0],"","Billboard",1,3,[0,0,0],[0,0,0],1,1.2,1,0,[10,0],[[0,1,0,1],[0,1,0,0]],[0,1],1,0,"","",_spawnPos];
                            _ps setParticleRandom [0,[0.2,0.2,0.2],[0,0,0],0,0.2,[0,0,0,0],0,0];
                            _ps setDropInterval 0.02;
                            [_soundSource,_light,_ps] spawn { params ["_s","_l","_p"]; sleep 5; { deleteVehicle _x } forEach [_s,_l,_p]; };
                        }] remoteExec ["BIS_fnc_call", 0];
                        _u doMove (getPosATL _a);
                    };
                };

                // Fail if cultists abandon the altar
                [_altar] spawn {
                    params ["_a"];
                    while { time < (_a getVariable ["ritualEnd",0]) && !(_a getVariable ["ritualInterrupted",false]) } do {
                        private _near = allUnits select { side _x == resistance && alive _x && _x distance _a < 100 };
                        if (_near isEqualTo []) then {
                            private _deadline = time + 60;
                            waitUntil {
                                sleep 5;
                                !(allUnits select { side _x == resistance && alive _x && _x distance _a < 100 } isEqualTo []) ||
                                time > _deadline ||
                                _a getVariable ["ritualInterrupted",false]
                            };
                            if ((allUnits select { side _x == resistance && alive _x && _x distance _a < 100 }) isEqualTo [] &&
                                time > _deadline &&
                                !(_a getVariable ["ritualInterrupted",false])) exitWith {
                                _a setVariable ["ritualInterrupted", true, true];
                            };
                        };
                        sleep 10;
                    };
                };

                // Interrupt action for enemies
                [_altar] remoteExec ["CULT_fnc_addInterrupt", 0, true];

                waitUntil { time > (_altar getVariable ["ritualEnd",0]) || { _altar getVariable ["ritualInterrupted",false] } };

                if (_altar getVariable ["ritualInterrupted",false]) then {
                    [_taskR, "FAILED", true] call BIS_fnc_taskSetState;
                    [_taskW, "SUCCEEDED", true] call BIS_fnc_taskSetState;
                    [_taskE, "SUCCEEDED", true] call BIS_fnc_taskSetState;
                } else {
                    [_taskR, "SUCCEEDED", true] call BIS_fnc_taskSetState;
                    [_taskW, "FAILED", true] call BIS_fnc_taskSetState;
                    [_taskE, "FAILED", true] call BIS_fnc_taskSetState;
                    missionNamespace setVariable ["Infestation", (missionNamespace getVariable ["Infestation",0]) + 1, true];

                    ["smasher_idle_5"] remoteExec ["playSound", 0];

                    private _bGrp = createGroup resistance;
                    private _beast = _bGrp createUnit ["WBK_SpecialZombie_Smasher_Acid_1", getPosATL _altar, [], 0, "FORM"];
                    _beast setDamage 0;
                    _beast doMove (_altar getPos [25 + random 25, random 360]);
                    [_beast] spawn {
                        params ["_b"];
                        private _deadline = time + 2700;
                        while { time < _deadline } do {
                            private _targets = allUnits select { side _x in [west,east] && alive _x };
                            if (_targets isEqualTo []) exitWith { sleep 5 };
                            _b doMove (getPosATL selectRandom _targets);
                            sleep 30;
                        };
                        deleteVehicle _b;
                    };
                };

                // Clear fog after 45 minutes
                [] spawn {
                    sleep 2700;
                    0 setFog [0,0,0];
                };
            };
            publicVariable "CULT_fnc_ritualServer";
        };

        [_altar,_taskR,_taskW,_taskE,_cultGrp] remoteExec ["CULT_fnc_addRitualStart", 0, true];

        // Monitor mission for failure/success and cleanup
        [_taskR,_taskW,_taskE,_altar,_spawned,_groups] spawn {
            params ["_taskR","_taskW","_taskE","_altar","_spawned","_groups"];
            private _deadline = time + 2700; // 45 minutes to start ritual
            waitUntil { time > _deadline || { _altar getVariable ["ritualEnd",0] > 0 } };
            if (_altar getVariable ["ritualEnd",0] == 0) then {
                [_taskR, "FAILED", true] call BIS_fnc_taskSetState;
                [_taskW, "CANCELED", true] call BIS_fnc_taskSetState;
                [_taskE, "CANCELED", true] call BIS_fnc_taskSetState;
            } else {
                waitUntil { time > (_altar getVariable ["ritualEnd",0]) || { _altar getVariable ["ritualInterrupted",false] } };
            };

            missionNamespace setVariable ["cultMissionActive", false, true];
            sleep 300;
            { if (!isNull _x) then { deleteVehicle _x; }; } forEach _spawned;
            { if (!isNull _x) then { { deleteVehicle _x } forEach units _x; deleteGroup _x; }; } forEach _groups;
            [_taskR] call BIS_fnc_deleteTask;
            [_taskW] call BIS_fnc_deleteTask;
            [_taskE] call BIS_fnc_deleteTask;
        };
    };
};