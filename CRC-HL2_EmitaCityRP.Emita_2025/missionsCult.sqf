if (!isServer) exitWith {};

// Select a mission
private _missionIndex = selectRandom [1];

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
                    "<t color='#27c707ff'>Raise Zombine</t>"
                } else {
                    "<t color='#27c707ff'>Raise Zombie</t>"
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
				sleep 2;
                [_corpse] remoteExec ["CULT_fnc_raiseFX", 0];
                sleep 4;
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
        private _wreckTypes = ["Land_Wreck_Car2_F","Land_Wreck_Car3_F","Land_Wreck_Truck_F"]; 
        for "_i" from 1 to 3 do {
            private _pos = _battlePos getPos [random 25, random 360];
            private _w = createVehicle [selectRandom _wreckTypes, _pos, [], 0, "CAN_COLLIDE"];
            _spawned pushBack _w;
        };
        for "_i" from 1 to 3 do {
            private _pos = _battlePos getPos [random 25, random 360];
            private _f = createVehicle ["Particle_MediumFire_F", _pos, [], 0, "CAN_COLLIDE"];
            _spawned pushBack _f;
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
			sleep 300
            { if (!isNull _x) then { deleteVehicle _x; }; } forEach _spawned;
            { if (!isNull _x) then { { deleteVehicle _x } forEach units _x; deleteGroup _x; }; } forEach _groups;
            [_taskId] call BIS_fnc_deleteTask;
        };
    };
};