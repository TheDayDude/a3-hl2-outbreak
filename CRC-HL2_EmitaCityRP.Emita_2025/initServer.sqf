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

if (isNil "RationStock") then { RationStock = 5; publicVariable "RationStock"; };
if (isNil "Biomass") then { Biomass = 5; publicVariable "Biomass"; };
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

_safeMarkers = allMapMarkers select {["lootZone_safe_", _x] call BIS_fnc_inString};
_dangerMarkers = allMapMarkers select {["lootZone_danger_", _x] call BIS_fnc_inString};
missionNamespace setVariable ["lootMarkers_safe", _safeMarkers, true];
missionNamespace setVariable ["lootMarkers_danger", _dangerMarkers, true];
