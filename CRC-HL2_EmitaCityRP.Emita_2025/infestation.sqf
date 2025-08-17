// Ensure infestation variable exists
if (isNil "Infestation") then {
    Infestation = 50;
};

// Monitor all unit deaths
addMissionEventHandler ["EntityKilled", {
    params ["_killed", "_killer", "_instigator"];
    private _side = side _killed;

    switch (_side) do {
        case east: {
            missionNamespace setVariable ["Infestation", (missionNamespace getVariable ["Infestation",0]) + 0.1, true];
        };
        case west: {
            missionNamespace setVariable ["Infestation", (missionNamespace getVariable ["Infestation",0]) + 0.1, true];
        };
        case resistance: {
            // Independent unit killed, reduce infestation
            missionNamespace setVariable ["Infestation", (missionNamespace getVariable ["Infestation",0]) - 0.1, true];
        };
    };
}];

// Passive infestation growth
[] spawn {
    while {true} do {
        sleep (600 + random 1200); // 10 to 30 minutes
        Infestation = (Infestation + 0.1) min 100;
        publicVariable "Infestation";
    };
};