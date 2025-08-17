addMissionEventHandler ["EntityKilled", {
    params ["_unit"];

    if (side _unit == east) then {
        missionNamespace setVariable ["Sociostability", (missionNamespace getVariable ["Sociostability",0]) + 0.1, true];
    } else {
        if (side _unit == west) then {
            missionNamespace setVariable ["Sociostability", (missionNamespace getVariable ["Sociostability",0]) - 1, true];
        };
    };

    publicVariable "Sociostability";
}];
