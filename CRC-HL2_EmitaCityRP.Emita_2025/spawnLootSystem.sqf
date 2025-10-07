[] spawn {
    private _configFile = "cfgLootTables.sqf";
    call compile preprocessFileLineNumbers _configFile;

    private _lootTables = missionNamespace getVariable ["MRC_LootTables", createHashMap];

    private _containersByPool = createHashMapFromArray [
        ["military", ["Box_FIA_Support_F", "Box_Syndicate_Ammo_F", "Box_EAF_Wps_F", "Box_EAF_Ammo_F"]],
        ["medical", ["Box_B_UAV_06_medical_F", "Box_EAF_Support_F", "Hazard_Crate", "Box_B_UAV_06_F"]],
        ["food", ["Land_WoodenCrate_01_F", "Hazard_Crate", "Box_B_UAV_06_F"]],
        ["equipment", ["Land_WoodenCrate_01_F", "Box_EAF_Equip_F", "Hazard_Crate", "Box_B_UAV_06_F"]]
    ];

    private _spawnChances = createHashMapFromArray [
        ["military", 0.4],
        ["medical", 0.5],
        ["food", 0.5],
        ["equipment", 0.7]
    ];

    private _rollRanges = createHashMapFromArray [
        ["military", [1, 3]],   // Military crates roll 1-3 times
        ["medical", [3, 5]],    // Medical crates roll 3-5 times
        ["food", [1, 4]],       // Food crates roll 1-4 times
        ["equipment", [5, 10]]  // Equipment crates roll 5-10 times
    ];

    private _doubleRollChance = 0.05; // 5% chance to double the rolls for a crate

    private _selectWeightedEntry = {
        params ["_entries"];
        private _validEntries = [];
        private _totalWeight = 0;

        {
            private _weight = _x param [1, 0];
            if ((_weight isEqualType 0) && {_weight > 0}) then {
                _validEntries pushBack [_x, _weight];
                _totalWeight = _totalWeight + _weight;
            };
        } forEach _entries;

        if (_validEntries isEqualTo [] || {_totalWeight <= 0}) exitWith {[]};

        private _roll = random _totalWeight;
        private _result = [];

        {
            _x params ["_entry", "_weight"];
            if (_roll < _weight) exitWith { _result = _entry; };
            _roll = _roll - _weight;
        } forEach _validEntries;

        if (!(_result isEqualTo [])) exitWith { _result };

        (_validEntries select ((count _validEntries) - 1)) select 0;
    };

    private _spawnPrimaryMagazines = {
        params ["_box", "_magazines"];
        if (_magazines isEqualTo []) exitWith {};
        private _magazine = selectRandom _magazines;
        private _count = 2 + floor random 4; // 2-5 magazines of the same type
        _box addMagazineCargoGlobal [_magazine, _count];
    };

    private _spawnSecondaryMagazines = {
        params ["_box", "_magazines"];
        if (_magazines isEqualTo []) exitWith {};
        private _magazine = selectRandom _magazines;
        private _count = floor random 4; // 0-3 magazines of the same type
        if (_count <= 0) exitWith {};
        _box addMagazineCargoGlobal [_magazine, _count];
    };

    private _spawnAttachments = {
        params ["_box", "_attachments"];
        if (_attachments isEqualTo []) exitWith {};
        private _available = +_attachments;
        private _max = (count _available) min 3;
        if (_max <= 0) exitWith {};
        private _count = 1 + floor random _max; // 1-3 random attachments, no duplicates
        for "_i" from 1 to _count do {
            private _index = floor random (count _available);
            private _attachment = _available deleteAt _index;
            if (isNil "_attachment") exitWith {};
            _box addItemCargoGlobal [_attachment, 1];
            if (_available isEqualTo []) exitWith {};
        };
    };

    private _markers = allMapMarkers select {
        private _name = toLower _x;
        (_name find "loot_military_" == 0) ||
        (_name find "loot_medical_" == 0) ||
        (_name find "loot_food_" == 0) ||
        (_name find "loot_equipment_" == 0)
    };

    while {true} do {
        {
            private _marker = _x;
            private _pos = getMarkerPos _marker;

            if ((allPlayers findIf { _x distance2D _pos < 100 }) > -1) then {
                private _nameLower = toLower _marker;
                private _poolKey = "";

                if (_nameLower find "loot_military_" == 0) then {
                    _poolKey = "military";
                } else {
                    if (_nameLower find "loot_medical_" == 0) then {
                        _poolKey = "medical";
                    } else {
                        if (_nameLower find "loot_food_" == 0) then {
                            _poolKey = "food";
                        } else {
                            if (_nameLower find "loot_equipment_" == 0) then {
                                _poolKey = "equipment";
                            };
                        };
                    };
                };

                private _poolEntries = _lootTables getOrDefault [_poolKey, []];
                private _containers = _containersByPool getOrDefault [_poolKey, []];
                if (!(_poolEntries isEqualTo []) && !(_containers isEqualTo [])) then {
                    private _spawnChance = _spawnChances getOrDefault [_poolKey, 0];
                    if (random 1 < _spawnChance) then {
                        private _rollRange = _rollRanges getOrDefault [_poolKey, [0, 0]];
                        private _minRolls = _rollRange select 0;
                        private _maxRolls = _rollRange select 1;
                        private _rollCount = _minRolls;
                        if (_maxRolls > _minRolls) then {
                            _rollCount = _minRolls + floor random ((_maxRolls - _minRolls) + 1);
                        };
                        if (random 1 < _doubleRollChance) then {
                            _rollCount = _rollCount * 2;
                        };

                        private _crateClass = selectRandom _containers;
                        private _box = _crateClass createVehicle _pos;

                        clearItemCargoGlobal _box;
                        clearWeaponCargoGlobal _box;
                        clearMagazineCargoGlobal _box;
                        clearBackpackCargoGlobal _box;

                        for "_i" from 1 to _rollCount do {
                            private _entry = [_poolEntries] call _selectWeightedEntry;
                            if (!(_entry isEqualTo [])) then {
                                _entry params [
                                    "_itemClass",
                                    "_weight",
                                    ["_primaryMagazines", []],
                                    ["_secondaryMagazines", []],
                                    ["_attachments", []]
                                ];

                                private _itemCfg = configFile >> "CfgWeapons" >> _itemClass;
                                if (isClass _itemCfg) then {
                                    _box addWeaponCargoGlobal [_itemClass, 1];
                                } else {
                                    private _magCfg = configFile >> "CfgMagazines" >> _itemClass;
                                    if (isClass _magCfg) then {
                                        _box addMagazineCargoGlobal [_itemClass, 1];
                                    } else {
                                        private _backpackCfg = configFile >> "CfgVehicles" >> _itemClass;
                                        if (isClass _backpackCfg && {getNumber (_backpackCfg >> "isBackpack") > 0}) then {
                                            _box addBackpackCargoGlobal [_itemClass, 1];
                                        } else {
                                            _box addItemCargoGlobal [_itemClass, 1];
                                        };
                                    };
                                };

                                [_box, _primaryMagazines] call _spawnPrimaryMagazines;
                                [_box, _secondaryMagazines] call _spawnSecondaryMagazines;
                                [_box, _attachments] call _spawnAttachments;
                            };
                        };

                        _box addEventHandler ["Killed", {
                            private _amount  = 2 + floor random 4;
                            private _targets = allPlayers select { side _x == west && alive _x };
                            {
                                for "_i" from 1 to _amount do { _x addItem "VRP_HL_Token_Item"; };
                            } forEach _targets;
                            [format ["Malignant cache destroyed. You are awarded %1 Tokens.", _amount]]
                                remoteExec ["hintSilent", _targets apply { owner _x }];
                        }];
                    };
                };

                deleteMarker _marker;
            };
        } forEach _markers;

        sleep 10;
    };
};
