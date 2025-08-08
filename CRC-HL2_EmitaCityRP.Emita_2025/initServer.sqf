publicVariable "Global_CID_Registry";
publicVariable "CID_Loyalty";
publicVariable "CID_Malcompliance";
publicVariable "AntiCitizen";
publicVariable "WasCitizen";
CID_Loyalty = createHashMap;
CID_Malcompliance = createHashMap;
[] execVM "xenAggroLoop.sqf";
[] execVM "xenianCleanupLoop.sqf";
[] execVM "outlandsThreatSpawner.sqf";
[] execVM "rebelIncursion.sqf";
[] execVM "spawnLootSystem.sqf";
[] execVM "malcompliant.sqf";
[] execVM "qzones.sqf";
[] execVM "garrison.sqf";

if (isNil { missionNamespace getVariable "RationStock" }) then {
    missionNamespace setVariable ["RationStock", 5, true]; // true = publicVariable
};

if (isNil { missionNamespace getVariable "Biomass" }) then {
    missionNamespace setVariable ["Biomass", 5, true];
};

PlasmaLevel = 10;
publicVariable "PlasmaLevel";

call compile preprocessFileLineNumbers "portalStorm.sqf";

[] spawn {
    while {true} do {
        private _delay = 3000 + random 3000;
        sleep _delay;
        [] spawn portalStorm_fnc_start;
    };
};

[] spawn {
    while {true} do {
        if (PlasmaLevel < 100) then {
            PlasmaLevel = PlasmaLevel + 1;
            publicVariable "PlasmaLevel";
        };
        sleep 300; 
    };
};

[] spawn {
    while {true} do {
        if (Biomass < 100) then {
            Biomass = Biomass + 1;
            publicVariable "Biomass";
        };
        sleep 300; 
    };
};

[] spawn {
    while {true} do {
        // Wait 55 minutes (3300 seconds)
        sleep 3300;

        // 5-minute warning
        ["Cleanup Warning: All corpses, wrecks, and loose items will be removed in 5 minutes."] remoteExec ["hint", 0];
        ["Cleanup Warning: All corpses, wrecks, and loose items will be removed in 5 minutes."] remoteExec ["systemChat", 0];

        // Wait another 5 minutes (300 seconds)
        sleep 300;

        // Perform cleanup
        {
            deleteVehicle _x;
        } forEach (
            allDeadMen +
            allDead +
            allMissionObjects "GroundWeaponHolder" +
            allMissionObjects "WeaponHolderSimulated" +
            allMissionObjects "WeaponHolder" +
            allMissionObjects "WeaponHolderAmmoBox"
        );

        {
            if (!alive _x && !isPlayer _x) then {
                deleteVehicle _x;
            };
        } forEach vehicles;

        // Notify players
        ["Cleanup complete. All corpses, wrecks, and items have been removed."] remoteExec ["hint", 0];
        ["Cleanup complete. All corpses, wrecks, and items have been removed."] remoteExec ["systemChat", 0];
    };
};


_safeMarkers = allMapMarkers select {["lootZone_safe_", _x] call BIS_fnc_inString};
_dangerMarkers = allMapMarkers select {["lootZone_danger_", _x] call BIS_fnc_inString};
missionNamespace setVariable ["lootMarkers_safe", _safeMarkers, true];
missionNamespace setVariable ["lootMarkers_danger", _dangerMarkers, true];
