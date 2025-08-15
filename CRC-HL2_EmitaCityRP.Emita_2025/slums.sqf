// slums.sqf — Server-side persistent CPF patrol for Slums (Fire-at-will + hunt/return)
if (!isServer) exitWith {};

[] spawn {
	// ---------- Tunables ----------
	private _presenceRadius = 300;   // players within this of any slums_/slums_guard "count as in Slums"
	private _despawnGrace   = 60;    // seconds with no players before despawn

	private _pauseMin = 60;          // wait at guard before next 5-point sweep
	private _pauseMax = 120;

	private _detectWarn = 50;        // warn at <= 50m (assume inspection position)
	private _detectFlip = 10;        // flip to OPFOR / confiscate at <= 10m

        private _cpTypes     = ["WBK_Combine_CP_P","WBK_Combine_CP_SMG"];
        private _sweepCount  = 5;        // number of slums_ markers per sweep

        private _zombieTypes   = [
                "WBK_Zombine_HLA_1",
                "WBK_ClassicZombie_HLA_1","WBK_Headcrab_Normal","WBK_ClassicZombie_HLA_3",
                "WBK_ClassicZombie_HLA_4","WBK_ClassicZombie_HLA_5","WBK_ClassicZombie_HLA_6",
                "WBK_ClassicZombie_HLA_7","WBK_ClassicZombie_HLA_8","WBK_Zombie_HECU_1"
        ];
        private _hordeChance   = 0.1;    // 10% chance when players present
        private _hordeCooldown = 120;    // seconds between horde spawn checks

        private _qrfApcChance = 0.4;   // 40% chance a QRF includes APC support
        private _qrfCooldown  = 120;    // seconds between QRF waves
        private _apcClass     = "HL_CMB_CP_APC";
	

	// ---------- Marker helpers ----------
	private _getSlumsMarkers = {
		allMapMarkers select { toLower _x find "slums_" == 0 && { toLower _x != "slums_guard" } }
	};
	private _getGuardMarker = {
		private _g = allMapMarkers select { toLower _x == "slums_guard" };
		if (_g isEqualTo []) exitWith { "" };
		_g select 0
	};

	// ---------- Surrender / captive detection ----------
	private _isSurrendering = {
		params ["_u"];
		_u getVariable ["ace_captives_isSurrendering", (_u getVariable ["ACE_isSurrendering", false])]
	};
	private _isDownOrCaptive = {
		params ["_u"];
		(captive _u)
		|| (lifeState _u in ["INCAPACITATED","UNCONSCIOUS"])
		|| (_u getVariable ["ACE_isUnconscious", false])
		|| !(alive _u)
	};

	// ---------- Confiscation (server) ----------
	if (isNil "SLUMS_fnc_confiscate") then {
		SLUMS_fnc_confiscate = {
			params ["_u","_blacklist"];
			if (isNull _u) exitWith {};

			removeAllWeapons _u;
			removeAllAssignedItems _u;
			{ _u removeItems _x; _u unlinkItem _x; } forEach _blacklist;
		};
		publicVariable "SLUMS_fnc_confiscate";
	};
	
	// loyalty check
	fnc_cpfIsLoyalist = {
	  params ["_unit"];
	  _unit getVariable ["isLoyalist", false]
	};

	fnc_cpfIgnoreLoyalist = {
	  params ["_grp", "_ply"];

	  // Clear targeting on this player
	  {
		_x forgetTarget _ply;
		_x doTarget objNull;
		_x doWatch objNull;
	  } forEach units _grp;

	  // Lower their knowledge of the loyalist so they don't immediately re-acquire
	  _grp reveal [_ply, 0];

	  // (Optional) flavor: a short bark
	  private _spk = selectRandom (units _grp);
	  if (!isNull _spk) then {
		_spk sideChat "Citizen, move along.";
	  };
	};


	// Default contraband (override via missionNamespace setVariable ["SLUMS_Contraband",[...],true])
	private _defaultContraband = ["Cytech_Makeshift_Argument_Short","Cytech_Makeshift_PM","Cytech_Makeshift_Argument","Cytech_Makeshift_APS","Cytech_flashlight_Normal","Cytech_APS_Compensator","Cytech_PM_Amplifier","Cytech_14Rnd_9x18_Mag","Cytech_35Rnd_9x18_Mag","Cytech_6Rnd_45ACP","hlc_rifle_aks74u","hlc_30Rnd_545x39_B_AK","H_bms_helmet_1","V_resistance_vest_bms","V_BandollierB_blk","B_hecu_survival_m81_2","G_Bandanna_blk","G_Balaclava_cloth_blk_F","M40_Gas_mask_nbc_f4_d","BMS_X800","O_NVGoggles_urb_F","GrenadeMolotovPSRUS","IEDLandBig_Remote_Mag","IEDUrbanBig_Remote_Mag","IEDLandSmall_Remote_Mag","IEDUrbanSmall_Remote_Mag","VRP_AntlionMeat","WBK_Health_ArmourPlate","WBK_Health_Bandage","ACE_Banana","plp_bo_w_BottleLiqCream","plp_bo_w_BottleGin","plp_bo_w_BottleTequila","ACE_CableTie","ACE_Can_Spirit","ACE_Can_RedGull","ACE_Can_Franta","ACE_Canteen","ACE_DeadManSwitch","ACE_DefusalKit","VRP_Bread","VRP_HeadcrabMeat","VRP_HoundMeat","VRP_Watermelon","ACE_MRE_BeefStew","ACE_MRE_LambCurry","HLC_Optic_1p29","HLC_Optic_PSO1","WBK_BearRebel_Rifle_Scope","WBK_BearRebel_Rifle","HL_CivHuntingRifle_Mag"];

	// ---------- Presence check ----------
	private _playersInSlums = {
		params ["_slumMarkers","_guardName","_radius"];
		private _centers = (_slumMarkers apply { getMarkerPos _x }) + (if (_guardName == "") then {[]} else {[getMarkerPos _guardName]});
		allPlayers select {
			private _p = _x;
			alive _p && { (_centers findIf { _p distance2D _x < _radius }) >= 0 }
		}
	};

	// ---------- Clear all waypoints ----------
	private _clearWPs = {
		params ["_grp"];
		if (isNull _grp) exitWith {};
		for "_i" from ((count (waypoints _grp)) - 1) to 0 step -1 do {
			deleteWaypoint [_grp, _i];
		};
	};

	// ---------- In-slums check ----------
	private _inSlums = {
		params ["_unit","_slumsMarkers","_guardPos","_areaRadius"];
		if (isNull _unit) exitWith {false};
		private _pos = getPosATL _unit;
		if (_pos distance2D _guardPos < _areaRadius) exitWith {true};
		((_slumsMarkers findIf { _pos distance2D (getMarkerPos _x) < _areaRadius }) >= 0)
	};

	// ---------- Spawn patrol at guard ----------
	private _spawnPatrol = {
		params ["_guardPos"];
		private _grp   = createGroup west;
		private _count = 5 + floor (random 3); // 5–7

                private _units = [];
                for "_i" from 1 to _count do {
                        private _pos   = [_guardPos, 3, 12, 1, 0, 20, 0] call BIS_fnc_findSafePos;
                        private _class = selectRandom _cpTypes;
                        private _u     = _grp createUnit [_class, _pos, [], 0, "FORM"];
                        _u setDir random 360;
                        _u forceAddUniform "Z_C18_Uniform_1";
                        if (_class == "WBK_Combine_CP_P") then {
                                removeAllWeapons _u;
                                for "_m" from 1 to 3 do { _u addMagazine "HLB_HSMG_Mag"; };
                                _u addWeapon "WBK_CP_HeavySMG";
                        };
                        _units pushBack _u;
                };

		// Patrol defaults: SAFE stance, FIRE AT WILL
		_grp setSpeedMode "LIMITED";
		_grp setBehaviour "SAFE";
		_grp setCombatMode "RED";     // <— Fire at will
		_grp setFormation "LINE";

                [_grp,_units]
        };

        // ---------- Spawn a QRF toward a target position ----------
        private _spawnQRF = {
                params ["_guardPos","_targetPos"];
                private _spawn = [_guardPos] call _spawnPatrol;
                private _grp   = _spawn select 0;
                private _units = _spawn select 1;

                _grp setBehaviour "AWARE";
                _grp setSpeedMode "NORMAL";
                _grp setCombatMode "RED";
                [_grp] call _clearWPs;
                private _wp = _grp addWaypoint [_targetPos, 0];
                _wp setWaypointType "SAD";
                _wp setWaypointBehaviour "AWARE";
                _wp setWaypointSpeed "NORMAL";

                private _veh = objNull;
                private _vehGrp = grpNull;
                if (random 1 < _qrfApcChance) then {
                        _veh = createVehicle [_apcClass, _guardPos, [], 0, "NONE"];
                        createVehicleCrew _veh;
                        _veh setDir random 360;
                        _veh lock false;
                        _vehGrp = group (driver _veh);
                        _vehGrp setBehaviour "AWARE";
                        _vehGrp setCombatMode "RED";
                        [_vehGrp] call _clearWPs;
                        private _wpv = _vehGrp addWaypoint [_targetPos, 0];
                        _wpv setWaypointType "SAD";
                        _wpv setWaypointBehaviour "AWARE";
                        _wpv setWaypointSpeed "NORMAL";
                        { _units pushBack _x } forEach crew _veh;
                };
                [_grp,_units,_veh,_vehGrp]
        };

        // ---------- Make a sweep of N random slums_ markers then return ----------
        private _assignSweep = {
                params ["_grp","_guardPos","_slumMarkers","_count"];
                if (isNull _grp) exitWith {};
                private _pick = +_slumMarkers call BIS_fnc_arrayShuffle;
		_pick = _pick select [0, _count min (count _pick)];

                [_grp] call _clearWPs;

		{
			private _p = getMarkerPos _x;
			private _wp = _grp addWaypoint [_p, 0];
			_wp setWaypointType "MOVE";
			_wp setWaypointBehaviour "SAFE";
			_wp setWaypointSpeed "LIMITED";
			_wp setWaypointCompletionRadius 8;
		} forEach _pick;

		private _wpR = _grp addWaypoint [_guardPos, 0];
		_wpR setWaypointType "MOVE";
		_wpR setWaypointBehaviour "SAFE";
		_wpR setWaypointSpeed "LIMITED";
		_wpR setWaypointCompletionRadius 8;
	};

	// ---------- Pursue nearest civilian until resolved, then RTB ----------
        private _pursueTarget = {
                params ["_grp","_guardPos","_slumsMarkers","_areaRadius","_blacklist","_detectWarn","_detectFlip"];
                if (isNull _grp) exitWith {};

		private _lead = leader _grp;
		if (isNull _lead) exitWith {};

		// choose nearest civilian inside 50 m (caller already checked, but re-find at start)
		private _civs50 = (allPlayers select { side _x == civilian && alive _x && (_x distance2D _lead) <= _detectWarn });
		if (_civs50 isEqualTo []) exitWith {};
		private _target = [_civs50, [], { _lead distance2D _x }] call BIS_fnc_sortBy select 0;

                // Cancel patrol & switch to hunt posture
                [_grp] call _clearWPs;
                _grp setBehaviour "AWARE";
		_grp setSpeedMode "NORMAL";
		_grp setCombatMode "RED";   // ensure fire-at-will during chase

		private _warned = false;
		private _resolved = false;
		private _lastCmd = -999;

		while { !_resolved } do {
			sleep 0.5;
			if (isNull _target || {!alive _target}) exitWith { _resolved = true; };

			// target left slums → resolve
			if (!([_target,_slumsMarkers,_guardPos,_areaRadius] call _inSlums)) exitWith { _resolved = true; };

			// update move order every ~2s
			if (time > _lastCmd + 2) then {
				{ _x doMove (getPosATL _target) } forEach units _grp;
				_lastCmd = time;
			};

			// Warn once at 50 m
			private _d = (leader _grp) distance2D _target;
			if (!_warned && _d <= _detectWarn) then {
				["Civil Protection: Assume inspection position. Surrender immediately."] remoteExec ["systemChat", owner _target];
				["Attention Please: All citizens in local residential block (District 4), assume your inspection positions."] remoteExec ["systemChat", 0];
				["Ftrainstationassumepositionsspkr"] remoteExec ["playSound", 0];				
				_warned = true;
			};

			// Resolve at 10 m
			if (_d <= _detectFlip) then {
				// Loyalist exemption: drop engagement and reset patrol
				if (_target getVariable ['isLoyalist', false]) then {
					// Clear current targeting/knowledge so they don't re-acquire immediately
					{ _x forgetTarget _target; _x doTarget objNull; _x doWatch objNull; } forEach units _grp;
					_grp reveal [_target, 0];
					private _spk = selectRandom (units _grp);
					if (!isNull _spk) then { _spk sideChat "Citizen, move along."; };
					["You're recognized as a Loyalist. Move along."] remoteExec ["systemChat", owner _target];
					_resolved = true;
				} else {

			
				
				private _isSurr = ([_target] call _isSurrendering) || ([_target] call _isDownOrCaptive);
				if (_isSurr) then {
					// Confiscate on server
					private _black = missionNamespace getVariable ["SLUMS_Contraband", _defaultContraband];
					[_target,_black] remoteExec ["SLUMS_fnc_confiscate", 2];
					["Inspection complete. Contraband confiscated. Remain in position until the officers vacate."] remoteExec ["hintSilent", owner _target];
				} else {
					// Flip to OPFOR
					if (side _target == civilian) then {
						[_target] joinSilent (createGroup east);
						["You have been processed as malcompliant."] remoteExec ["systemChat", owner _target];
						["Attention Residents: This block (District 4) contains potential civil infection. Inform, cooperate, assemble."] remoteExec ["systemChat", 0];
						["Ftrainstationinformspkr"] remoteExec ["playSound", 0];	
						_target setCaptive false;
					};
				};
				};
				_resolved = true;
			};
		};

                // Return to guard, reset posture to SAFE patrol
                [_grp] call _clearWPs;
                private _wpHome = _grp addWaypoint [_guardPos, 0];
		_wpHome setWaypointType "MOVE";
                _grp setBehaviour "SAFE";
                _grp setSpeedMode "LIMITED";
                _grp setCombatMode "RED";    // keep fire-at-will even on patrol
        };

        // ---------- Spawn a zombie horde toward a target ----------
        private _spawnHorde = {
                params ["_target","_types"];
                private _spawnPos = _target getPos [50 + random 50, random 360];
                private _grp = createGroup resistance;
                for "_i" from 1 to (4 + floor random 4) do {
                        private _u = _grp createUnit [selectRandom _types, _spawnPos, [], 5, "FORM"];
                        _u setBehaviour "AWARE";
                        _u setCombatMode "RED";
                        _u doMove (getPos _target);
                };
                [_grp,_target] spawn {
                        params ["_grp","_target"];
                        while { ({alive _x} count units _grp) > 0 && alive _target } do {
                                { if (alive _x) then { _x doMove (getPos _target) }; } forEach units _grp;
                                sleep (10 + random 10);
                        };
                };
        };

	// ---------- Main supervisor loop ----------
        private _grp = grpNull;
        private _units = [];
        private _lastPresence = time;
        private _lastHorde = -_hordeCooldown;
        private _qrfGrp = grpNull;
        private _qrfUnits = [];
        private _qrfVeh = objNull;
        private _qrfVehGrp = grpNull;
        private _qrfTarget = [0,0,0];
        private _qrfLastPresence = time;
        private _lastQrf = -_qrfCooldown;
        private _lastPatrolPos = [0,0,0];

	while { true } do {
		private _slums     = call _getSlumsMarkers;
		private _guardName = call _getGuardMarker;

		if (_guardName == "") exitWith { diag_log "[SLUMS] Missing slums_guard marker."; };

                private _guardPos = getMarkerPos _guardName;
                private _near     = [_slums,_guardName,_presenceRadius] call _playersInSlums;

                if (!isNull _grp) then {
                        private _lp = leader _grp;
                        if (!isNull _lp) then { _lastPatrolPos = getPosATL _lp; };
                };
                if (!isNull _qrfGrp) then {
                        private _lq = leader _qrfGrp;
                        if (!isNull _lq) then { _qrfTarget = getPosATL _lq; };
                };
                if (!isNull _qrfVehGrp) then {
                        private _lv = leader _qrfVehGrp;
                        if (!isNull _lv) then { _qrfTarget = getPosATL _lv; };
                };

                // Random zombie horde spawn near a player
                if ((count _near) > 0 && {time > _lastHorde + _hordeCooldown}) then {
                        _lastHorde = time;
                        if (random 1 < _hordeChance) then {
                                private _tgt = selectRandom _near;
                                [_tgt,_zombieTypes] call _spawnHorde;
                        };
                };

                // Spawn patrol if players present and no patrol or QRF is active
                if ((count _near) > 0 && isNull _grp && isNull _qrfGrp && isNull _qrfVehGrp && { _qrfTarget distance2D [0,0,0] < 1 }) then {
                        private _spawn = [_guardPos] call _spawnPatrol;
			_grp   = _spawn select 0;
			_units = _spawn select 1;

			[_grp,_guardPos,_slums,_sweepCount] call _assignSweep;
		};

                // If patrol exists, maintain, hunt, or despawn
                if (!isNull _grp) then {
                        if ({alive _x} count _units == 0) then {
                                if ((_lastPatrolPos distance2D [0,0,0]) > 0) then { _qrfTarget = _lastPatrolPos; };
                                _lastQrf = time - _qrfCooldown;
                                if (!isNull _grp) then { deleteGroup _grp; };
                                _grp = grpNull; _units = [];
                        } else {
                                if ((count _near) == 0) then {
                                        // no players -> maybe despawn after grace
                                        if (time > _lastPresence + _despawnGrace) then {
                                                { if (!isNull _x) then { deleteVehicle _x } } forEach _units;
                                                if (!isNull _grp) then { deleteGroup _grp };
                                                _grp = grpNull; _units = [];
                                        };
                                } else {
                                        _lastPresence = time;

                                        // If patrol reached guard and finished its route, wait and assign new sweep
                                        private _ldr = leader _grp;
                                        if (!isNull _ldr) then {
                                                private _wpCur   = currentWaypoint _grp;
                                                private _wpTotal = count waypoints _grp;

                                                if ((_ldr distance2D _guardPos) < 12 && (_wpCur >= _wpTotal)) then {
                                                        sleep (_pauseMin + random (_pauseMax - _pauseMin));
                                                        [_grp,_guardPos,_slums,_sweepCount] call _assignSweep;
                                                };

                                                // HUNT: any civilian within 50 m? Break patrol and pursue until resolved
                                                private _closeCivs = allPlayers select { side _x == civilian && alive _x && (_x distance2D _ldr) <= _detectWarn };
                                                if !(_closeCivs isEqualTo []) then {
                                                        [_grp,_guardPos,_slums,_presenceRadius,
                                                                missionNamespace getVariable ["SLUMS_Contraband", _defaultContraband],
                                                                _detectWarn,_detectFlip
                                                        ] call _pursueTarget;

                                                        // After pursuit, short pause & start a fresh sweep
                                                        sleep (_pauseMin + random (_pauseMax - _pauseMin));
                                                        [_grp,_guardPos,_slums,_sweepCount] call _assignSweep;
                                                };
                                        };
                                };
                        };
                };

                // Spawn QRF waves
                if ((_qrfTarget distance2D [0,0,0]) > 0 && isNull _qrfGrp && isNull _qrfVehGrp && (count _near) > 0 && time >= _lastQrf + _qrfCooldown) then {
                        private _q = [_guardPos,_qrfTarget] call _spawnQRF;
                        _qrfGrp = _q select 0;
                        _qrfUnits = _q select 1;
                        _qrfVeh = _q select 2;
                        _qrfVehGrp = _q select 3;
                        _qrfLastPresence = time;
                        _lastQrf = time;
                };

                // Maintain QRF
                if (!isNull _qrfGrp || !isNull _qrfVehGrp) then {
                        private _alive = 0;
                        if (!isNull _qrfGrp) then { _alive = _alive + ({alive _x} count units _qrfGrp); };
                        if (!isNull _qrfVehGrp) then { _alive = _alive + ({alive _x} count units _qrfVehGrp); };
                        if (!isNull _qrfVeh && {!alive _qrfVeh}) then { _alive = 0; };
                        if (_alive == 0) then {
                                if (!isNull _qrfGrp) then { deleteGroup _qrfGrp; };
                                if (!isNull _qrfVehGrp) then { deleteGroup _qrfVehGrp; };
                                if (!isNull _qrfVeh) then { deleteVehicle _qrfVeh; };
                                _qrfGrp = grpNull; _qrfVehGrp = grpNull; _qrfVeh = objNull; _qrfUnits = [];
                                _lastQrf = time;
                        } else {
                                if ((count _near) == 0) then {
                                        if (time > _qrfLastPresence + _despawnGrace) then {
                                                { if (!isNull _x) then { deleteVehicle _x } } forEach _qrfUnits;
                                                if (!isNull _qrfVeh) then { deleteVehicle _qrfVeh; };
                                                if (!isNull _qrfGrp) then { deleteGroup _qrfGrp; };
                                                if (!isNull _qrfVehGrp) then { deleteGroup _qrfVehGrp; };
                                                _qrfGrp = grpNull; _qrfVehGrp = grpNull; _qrfVeh = objNull; _qrfUnits = [];
                                                _qrfTarget = [0,0,0];
                                        };
                                } else {
                                        _qrfLastPresence = time;
                                };
                        };
                };

                // idle tick rate
                if (isNull _grp && isNull _qrfGrp && isNull _qrfVehGrp && {(count _near) == 0}) then { sleep 5 } else { sleep 1 };
	};
};
