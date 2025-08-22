if (isNil "XEN_fnc_addRitualActions") then {
    XEN_fnc_addRitualActions = {
        params ["_obj"];
        if (isNull _obj) exitWith {};

        _obj addAction [
            "C o M m U n e",
            {
                params ["_target", "_caller"];
                [_target, _caller] remoteExec ["XEN_fnc_communeServer", 2];
            },
            nil, 1.5, true, true, "", "_this distance _target < 4", 5, true
        ];

        _obj addAction [
            "S u m M o N",
            {
                params ["_target", "_caller"];
                [_target, _caller] remoteExec ["XEN_fnc_summonPortalServer", 2];
            },
            nil, 1.5, true, true, "", "_this distance _target < 4 && side _this == resistance", 5, true
        ];
    };
    publicVariable "XEN_fnc_addRitualActions";
};

// Server-side handling of communing
if (isNil "XEN_fnc_communeServer") then {
    XEN_fnc_communeServer = {
        params ["_obj", "_caller"];
        if (isNull _caller) exitWith {};

        private _favor = _caller getVariable ["favor", 0];
        _favor = _favor + 1;
        _caller setVariable ["favor", _favor, true];
        [format ["You commune with the Xen. Favor: %1", _favor]] remoteExec ["hint", _caller];

        if (_favor >= 5 && { side _caller != resistance }) then {
            [[_caller], createGroup resistance] remoteExec ["joinSilent", _caller];
            ["You have become a Xen Cultist!"] remoteExec ["hint", _caller];
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

        private _pos = getPosATL _obj;
        private _grp = group _caller;
        private _types = [
            "WBK_Zombine_HLA_1",
            "WBK_Antlion_1",
            "WBK_Houndeye_1",
            "WBK_Bullsquid_1"
        ];
        private _count = 3 + floor random 2;

        private _soundSource = createSoundSource ["XenTele", _pos, [], 0];
        [_soundSource] spawn { params ["_s"]; sleep 10; deleteVehicle _s; };

        for "_i" from 1 to _count do {
            private _unitPos = _pos getPos [3 + random 3, random 360];
            private _u = _grp createUnit [selectRandom _types, _unitPos, [], 0, "FORM"];
            _u setBehaviour "AWARE";
            _u setCombatMode "RED";
        };
    };
    publicVariable "XEN_fnc_summonPortalServer";
};

// Spawn ritual objects at markers
[] spawn {
    private _markers = allMapMarkers select { (_x select [0,7]) == "ritual_" };
    {
        if (random 1 < 0.99) then {
            private _coco = createVehicle ["xen_coconut", getMarkerPos _x, [], 0, "NONE"];
            [_coco] remoteExec ["XEN_fnc_addRitualActions", 0, true];
        };
    } forEach _markers;
};