if (!isServer) exitWith {};

if (isNil "MRC_fnc_augTermServer") then {
    MRC_fnc_augTermServer = {
        params ["_op","_terminal","_caller","_type","_armor","_price"];
        if (_op != "BUY") exitWith {};
        if (isNull _terminal || {isNull _caller}) exitWith {};
        if (!alive _caller) exitWith {};
        if (side _caller != west) exitWith {};

        private _tokens = { _x == "VRP_HL_Token_Item" } count (items _caller);
        if (_tokens < _price) exitWith {
            ["Not enough tokens."] remoteExec ["hintSilent", owner _caller];
        };

        for "_i" from 1 to _price do { _caller removeItem "VRP_HL_Token_Item"; };

        _caller setVariable ["combineType", _type, true];
        _caller setVariable ["combineArmor", _armor, true];
        _caller setArmor _armor;

        [format ["Augment applied: %1", _type]] remoteExec ["hintSilent", owner _caller];
    };
};

if (isNil "MRC_fnc_addAugTermActions") then {
    MRC_fnc_addAugTermActions = {
        params ["_terminal","_entries"];
        if (isNull _terminal) exitWith {};
        {
            _x params ["_type","_armor","_name","_price"];
            _terminal addAction [
                format ["Purchase %1 <t color='#FFD700'>(%2 tokens)</t>",_name,_price],
                {
                    params ["_target","_caller","_actionId","_args"];
                    _args params ["_terminal","_type","_armor","_price"];
                    ["BUY",_terminal,_caller,_type,_armor,_price] remoteExecCall ["MRC_fnc_augTermServer",2];
                },
                [_terminal,_type,_armor,_price],
                1.5,true,true,"",
                "_this distance _target < 4 && side _this == west"
            ];
        } forEach _entries;
    };
    publicVariable "MRC_fnc_addAugTermActions";
};

[] spawn {
    waitUntil { !isNil "MRC_fnc_augTermServer" && !isNil "MRC_fnc_addAugTermActions" };

    private _pos = getMarkerPos "augment_terminal_1";
    if (_pos isEqualTo [0,0,0]) exitWith { diag_log "[AUGTERM] Marker 'augment_terminal_1' not found."; };

    private _terminal = "Land_Laptop_unfolded_F" createVehicle _pos;
    _terminal setDir 90;
    _terminal allowDamage false;

    private _entries = [
        // ["CombineType", ArmorValue, "Display Name", TokenCost]
        [" charger_", 150, "Wallhammer Augment", 5],
        [" assasin_", 100, "Ghost Augment", 10],
        [" ordinal_", 125, "Oridnal Augment", 15]
    ];

    [_terminal,_entries] remoteExec ["MRC_fnc_addAugTermActions",0,true];
};