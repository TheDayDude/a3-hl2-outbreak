if (isNil "XEN_fnc_ritualEffects") then {
    XEN_fnc_ritualEffects = {
        params ["_obj", "_caller"];
        if (!hasInterface) exitWith {};

        private _pos = getPosATL _obj;
        private _ps = "#particlesource" createVehicleLocal _pos;
        _ps setParticleParams [["\A3\Data_F\ParticleEffects\Universal\Universal",16,12,8,0],"","Billboard",1,2,[0,0,0],[0,0,0],1,0.5,0.5,0.1,[1],[ [0,1,0,0.5] ],[0],1,0,"","",_obj];
        _ps setParticleRandom [0,[0.5,0.5,0.5],[0,0,0],0,0,[0,0,0,0],0,0];
        _ps setDropInterval 0.02;
        [_ps] spawn { params ["_p"]; sleep 5; deleteVehicle _p; };
		[_caller, "WBK_HoundEye_Warning"] remoteExecCall ["say3D", 0];
		_caller playMoveNow "Acts_CivilTalking_2";
		uiSleep 2;
		["Void"] remoteExec ["playSound", _caller];
		["applyBlur", _caller] remoteExec ["fnc_applyBlur", _caller];
		uiSleep 3;
		_caller switchMove "";
    };
    publicVariable "XEN_fnc_ritualEffects";
};

if (isNil "XEN_fnc_removeCommuneAction") then {
    XEN_fnc_removeCommuneAction = {
        params ["_obj"];
        private _id = _obj getVariable ["communeActionId", -1];
        if (_id >= 0) then { _obj removeAction _id; };
    };
    publicVariable "XEN_fnc_removeCommuneAction";
};

if (isNil "XEN_fnc_removeForecastAction") then {
    XEN_fnc_removeForecastAction = {
        params ["_obj"];
        private _id = _obj getVariable ["forecastActionId", -1];
        if (_id >= 0) then { _obj removeAction _id; };
    };
    publicVariable "XEN_fnc_removeForecastAction";
};

if (isNil "XEN_fnc_addRitualActions") then {
    XEN_fnc_addRitualActions = {
        params ["_obj"];
        if (isNull _obj) exitWith {};

        if (!(_obj getVariable ["communeUsed", false])) then {
            private _cId = _obj addAction [
                "<t color='#27c707ff'>C !  # o  & m  M u %   N # \  E?</t>",
                {
                    params ["_target", "_caller"];
                    [_target, _caller] remoteExec ["XEN_fnc_communeServer", 2];
                },
                nil, 1.5, true, true, "", "_this distance _target < 4", 5, true
            ];
            _obj setVariable ["communeActionId", _cId];
        };

        private _sId = _obj addAction [
            "<t color='#27c707ff'> S  #  u   $  ^ M #  m  & o  #  $  N</t>",
            {
                params ["_target", "_caller"];
                [_target, _caller] remoteExec ["XEN_fnc_summonPortalServer", 2];
            },
            nil, 1.5, true, true, "", "_this distance _target < 4 && side _this == resistance", 5, true
        ];
        _obj setVariable ["summonActionId", _sId];

        if (!(_obj getVariable ["forecastUsed", false])) then {
            private _fId = _obj addAction [
                "<t color='#27c707ff'>F #  o # R  %  $ c A S  * t</t>",
                {
                    params ["_target", "_caller"];
                    [_target, _caller] remoteExec ["XEN_fnc_forecastServer", 2];
                },
                nil, 1.5, true, true, "", "_this distance _target < 4 && side _this == resistance", 5, true
            ];
            _obj setVariable ["forecastActionId", _fId];
        };		
    };
    publicVariable "XEN_fnc_addRitualActions";
};

// Server-side handling of communing
if (isNil "XEN_fnc_communeServer") then {
    XEN_fnc_communeServer = {
        params ["_obj", "_caller"];
        if (isNull _caller || { _obj getVariable ["communeUsed", false] }) exitWith {};

        _obj setVariable ["communeUsed", true, true];
        [_obj] remoteExec ["XEN_fnc_removeCommuneAction", 0, true];
        [_obj, _caller] remoteExec ["XEN_fnc_ritualEffects", 0];

        private _favor = _caller getVariable ["favor", 0];
        _favor = _favor + 1;
        _caller setVariable ["favor", _favor, true];
		private _inf = missionNamespace getVariable ["Infestation", 0];
        missionNamespace setVariable ["Infestation", _inf + 0.5, true];

        if (_favor >= 5 && { side _caller != resistance }) then {
            [[_caller], createGroup resistance] remoteExec ["joinSilent", _caller];
            ["You have become one with it."] remoteExec ["hint", _caller];
			_caller addItem "rds_uniform_priest";  
			private _pos = getPosATL _caller;
			private _ps = "#particlesource" createVehicleLocal _pos;
			_ps setParticleParams [["\A3\Data_F\ParticleEffects\Universal\Universal",16,12,8,0],"","Billboard",1,2,[0,0,0],[0,0,0],1,0.5,0.5,0.1,[1],[ [0,1,0,0.5] ],[0],1,0,"","",_caller];
			_ps setParticleRandom [0,[0.5,0.5,0.5],[0,0,0],0,0,[0,0,0,0],0,0];
			_ps setDropInterval 0.02;
        };

        [_caller] remoteExec ["MRC_fnc_savePlayerState", 2];
    };
    publicVariable "XEN_fnc_communeServer";
};

// Server-side handling of portal summoning
if (isNil "XEN_fnc_summonPortalServer") then {
    XEN_fnc_summonPortalServer = {
        params ["_obj", "_caller"];
        if (side _caller != resistance) exitWith {};

        private _last = missionNamespace getVariable ["XEN_lastSummon", 0];
        if ((serverTime - _last) < 1800) exitWith {
            ["The rift resists your call. Try again later."] remoteExec ["hint", _caller];
        };
        missionNamespace setVariable ["XEN_lastSummon", serverTime, true];

        [_obj, _caller] remoteExec ["XEN_fnc_ritualEffects", 0];		

        private _pos = getPosATL _obj;
        private _grp = group _caller;
        private _types = [
            "WBK_Zombine_HLA_2",
            "WBK_Antlion_1",
			"WBK_Antlion_1",
			"WBK_Antlion_1",
            "WBK_Houndeye_1",
			"WBK_Houndeye_1",
            "WBK_Bullsquid_1"
        ];
        private _count = 2 + floor random 2;

        private _soundSource = createSoundSource ["XenTele", _pos, [], 0];
        [_soundSource] spawn { params ["_s"]; sleep 7; deleteVehicle _s; };

        for "_i" from 1 to _count do {
            private _unitPos = _pos getPos [3 + random 3, random 360];
            private _u = _grp createUnit [selectRandom _types, _unitPos, [], 0, "FORM"];
            _u setBehaviour "AWARE";
            _u setCombatMode "RED";
			private _ps = "#particlesource" createVehicleLocal _unitPos;
			_ps setParticleParams [["\A3\Data_F\ParticleEffects\Universal\Universal",16,12,8,0],"","Billboard",1,2,[0,0,0],[0,0,0],1,0.5,0.5,0.1,[1],[ [0,1,0,0.5] ],[0],1,0,"","",_u];
			_ps setParticleRandom [0,[0.5,0.5,0.5],[0,0,0],0,0,[0,0,0,0],0,0];
			_ps setDropInterval 0.02;
			[_ps] spawn { params ["_p"]; sleep 5; deleteVehicle _p; };
        };
        private _inf = missionNamespace getVariable ["Infestation", 0];
        missionNamespace setVariable ["Infestation", _inf + 0.1, true];
    };
    publicVariable "XEN_fnc_summonPortalServer";
};

if (isNil "XEN_fnc_forecastServer") then {
    XEN_fnc_forecastServer = {
        params ["_obj", "_caller"];
        if (_obj getVariable ["forecastUsed", false]) exitWith {};

        _obj setVariable ["forecastUsed", true, true];
        [_obj] remoteExec ["XEN_fnc_removeForecastAction", 0, true];
        [_obj, _caller] remoteExec ["XEN_fnc_ritualEffects", 0];

        private _timer = missionNamespace getVariable ["PortalStormTimer", 0];
        private _prediction = (_timer + (random 600) - (random 600)) max 0;
        private _mins = floor (_prediction / 60);
        [format ["You foresee a storm in %1 minutes.", _mins]] remoteExec ["hint", _caller];
    };
    publicVariable "XEN_fnc_forecastServer";
};

// Spawn ritual objects at markers
[] spawn {
    private _markers = allMapMarkers select { (_x select [0,7]) == "ritual_" };
    {
        if (random 1 < 0.2) then {
            private _coco = createVehicle ["xen_coconut", getMarkerPos _x, [], 0, "NONE"];
            [_coco] remoteExec ["XEN_fnc_addRitualActions", 0, true];
        };
    } forEach _markers;
};