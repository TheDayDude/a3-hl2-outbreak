publicVariable "Global_CID_Registry";
publicVariable "CID_Loyalty";
publicVariable "CID_Malcompliance";
publicVariable "AntiCitizen";
publicVariable "WasCitizen";
CID_Loyalty = createHashMap;
CID_Malcompliance = createHashMap;

{
    if (isPlayer _x) then {
        _x addEventHandler ["Killed", {
            params ["_unit", "_killer"];

            if (side _unit == east) then {
                [_unit] spawn {
                    waitUntil { !alive _this };
                    sleep 1; // Allow time for death animations/logic
                    [_this] joinSilent createGroup east;
                };
            };
        }];
    };
} forEach allUnits;

