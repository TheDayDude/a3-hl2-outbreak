// quartermaster.sqf
// Spawns a Combine-only quartermaster merchant with tiered supplies
if (!isServer) exitWith {};

// Initialise supply variable (3 = all tiers available)
if (isNil { missionNamespace getVariable "combineSupply" }) then {
    missionNamespace setVariable ["combineSupply", 3, true];
};

// --- Server-side purchase handler ---
if (isNil "MRC_fnc_quartermasterServer") then {
    MRC_fnc_quartermasterServer = {
        params ["_op", "_merchant", "_caller", "_cls", "_name", "_price"];
        if (_op != "BUY") exitWith {};
        if (isNull _merchant || {isNull _caller}) exitWith {};
        if (!alive _caller) exitWith {};
        if (side _caller != west) exitWith {};

        private _tokens = { _x == "VRP_HL_Token_Item" } count (items _caller);
        if (_tokens < _price) exitWith {
            ["Not enough tokens."] remoteExec ["hintSilent", owner _caller];
        };

        for "_i" from 1 to _price do { _caller removeItem "VRP_HL_Token_Item"; };

        private _crate = missionNamespace getVariable ["quartermaster_crate", objNull];
        if (isNull _crate) exitWith {
            ["Supply crate missing."] remoteExec ["hintSilent", owner _caller];
        };

        private _added = false;
        if (isClass (configFile >> "CfgMagazines" >> _cls)) then {
            _crate addMagazineCargoGlobal [_cls, 1];
            _added = true;
        } else {
            if (isClass (configFile >> "CfgWeapons" >> _cls)) then {
                private _type = getNumber (configFile >> "CfgWeapons" >> _cls >> "type");
                if (_type in [1,2,4,5]) then {
                    _crate addWeaponCargoGlobal [_cls, 1];
                } else {
                    _crate addItemCargoGlobal [_cls, 1];
                };
                _added = true;
            } else {
                if (isClass (configFile >> "CfgVehicles" >> _cls) && { getNumber (configFile >> "CfgVehicles" >> _cls >> "isBackpack") == 1 }) then {
                    _crate addBackpackCargoGlobal [_cls, 1];
                    _added = true;
                } else {
                    _crate addItemCargoGlobal [_cls, 1];
                    _added = true;
                };
            };
        };

        if (_added) then {
            [format ["%1 purchased. Retrieve it from the supply crate.", _name]] remoteExec ["hintSilent", owner _caller];
        };
    };
};

// --- Client-side actions ---
if (isNil "MRC_fnc_addQuartermasterActions") then {
    MRC_fnc_addQuartermasterActions = {
        params ["_qm", "_entries"];
        if (isNull _qm) exitWith {};

        {
            _x params ["_cls","_name","_price"];
            _qm addAction [
                format ["Buy %1  <t color='#FFD700'>(%2 tokens)</t>", _name, _price],
                {
                    params ["_target","_caller","","_args"];
                    _args params ["_merchant","_cls","_name","_price"];
                    ["BUY", _merchant, _caller, _cls, _name, _price] remoteExecCall ["MRC_fnc_quartermasterServer", 2];
                },
                [_qm,_cls,_name,_price],
                1.5, true, true, "",
                "_this distance _target < 4 && side _this == west"
            ];
        } forEach _entries;

    };
    publicVariable "MRC_fnc_addQuartermasterActions";
};

// --- Spawner ---
[] spawn {
    waitUntil { !isNil "MRC_fnc_addQuartermasterActions" && !isNil "MRC_fnc_quartermasterServer" };

       private _marker = "quartermaster";
    private _spawnRadius  = 100;
    private _despawnGrace = 30;
    private _qm = objNull;
    private _crate = objNull;
    private _lastSeen = 0;

    private _spawnQuartermaster = {
        private _pos = getMarkerPos _marker;
        if (_pos isEqualTo [0,0,0]) exitWith { diag_log "[QUARTERMASTER] Marker 'quartermaster' not found."; [objNull,objNull] };

        private _grp = createGroup west;
        private _q   = _grp createUnit ["WBK_Combine_CP_P", _pos, [], 0, "NONE"];
        _q setPosATL (_pos vectorAdd [0,0,1]);
        _q disableAI "MOVE";
        _q disableAI "PATH";
        _q disableAI "TARGET";
        _q disableAI "AUTOTARGET";
        _q allowFleeing 0;
        _q setUnitPos "UP";
        _q setBehaviour "SAFE";
        _q setCaptive true;
        removeAllWeapons _q;
        removeBackpack _q;
        removeUniform _q;
        removeHeadgear _q;
        _q forceAddUniform "U_C18_Uniform_3";
        _q addHeadgear "H_SM_BlackMask_2";

        // Create supply crate at marker or fallback near the quartermaster
        private _cratePos = getMarkerPos "quartermaster_crate";
        if (_cratePos isEqualTo [0,0,0]) then {
            _cratePos = _pos getPos [1.5, 90];
        };
        private _c = "Box_NATO_Ammo_F" createVehicle _cratePos;
        missionNamespace setVariable ["quartermaster_crate", _c, true];
        clearItemCargoGlobal _c;
        clearWeaponCargoGlobal _c;
        clearMagazineCargoGlobal _c;
        clearBackpackCargoGlobal _c;

        // Face the quartermaster toward the crate
        private _dir = [_pos, _cratePos] call BIS_fnc_dirTo;
        _q setDir _dir;

        // Define stock tiers
        private _tier1 = [
            ["HLA_Grunt_AR1SMG","Pulse SMG",3],
            ["HL_CMB_30Rnd_AR2_Mag","Pulse Magazine",1],
            ["WBK_OICW_Rifle","OICW Rifle",5],
            ["HLB_OICW_Mag","OICW Magazine",3]
        ];
        private _tier2 = [
            ["HLA_Ordinal_AR1","AR1 Pulse Rifle",5],
            ["HLA_ChargerShotGun","Charger Shotgun",5],
            ["HL_CMB_6Rnd_12gBuckshot","Charger Buckshot",2],
            ["WRS_Weapon_Sniper_Bolt","Boomslang Sniper",10],
            ["WRS_Boomslang_Magazine","Boomslang Magazine",1],
            ["HLA_ChargerShotGun","Charger Shotgun",5]
        ];
        private _tier3 = [
            ["launch_RPG32_green_F","RPG-32",20],
            ["RPG32_F","RPG Rocket",5],
            ["DemoCharge_Remote_Mag","M112 Demo Block",5]
        ];

        private _supply = missionNamespace getVariable ["combineSupply",3];
        private _entries = [];
        if (_supply >= 1) then { _entries append _tier1; };
        if (_supply >= 2) then { _entries append _tier2; };
        if (_supply >= 3) then { _entries append _tier3; };

        [_q, _entries] remoteExec ["MRC_fnc_addQuartermasterActions", 0, true];

        [_q, _c]
    };

    while { true } do {
        private _pos = getMarkerPos _marker;
        private _near = allPlayers select { alive _x && (_x distance2D _pos) < _spawnRadius };

        if ((count _near) > 0) then {
            if (isNull _qm) then {
                private _res = call _spawnQuartermaster;
                _qm    = _res select 0;
                _crate = _res select 1;
            };
            _lastSeen = time;
        } else {
            if (!isNull _qm && { (time - _lastSeen) > _despawnGrace }) then {
                private _grp = group _qm;
                deleteVehicle _qm;
                deleteGroup _grp;
                deleteVehicle _crate;
                missionNamespace setVariable ["quartermaster_crate", objNull, true];
                _qm = objNull;
                _crate = objNull;
            };
        };

        sleep 5;
    };
};