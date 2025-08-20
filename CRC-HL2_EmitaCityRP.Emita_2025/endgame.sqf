if (!isServer) exitWith {};

// Function to reset persistent mission variables and end mission
endgame_fnc_finish = {
    params ["_winner"];

    // Display victory message
    private _msg = switch (_winner) do {
        case "Rebels": {"Rebel victory: Sociostability has collapsed to 0%. This sector has broken free from Combine control!"};
        case "Xenians": {"Xenian victory: Infestation has reached 100%. This sector has become uninhabitable..."};
        default {"Mission complete"};
    };
    [_msg] remoteExec ["hint", 0];
    ["The game has ended, resetting stats..."] remoteExec ["systemChat", 0];
    ["WBK_hl_singularity"] remoteExec ["playSound", 0];

    sleep 30;

    // Reset persistent variables to defaults
    private _defaults = [
        ["RationStock", 10],
        ["Biomass", 5],
        ["PlasmaLevel", 5],
        ["Infestation", 50],
        ["Sociostability", 50]
    ];
    {
        missionNamespace setVariable [_x select 0, _x select 1, true];
        profileNamespace setVariable [_x select 0, _x select 1];
    } forEach _defaults;

    // Reset time of day to 6:00 AM
    private _date = date;
    setDate [_date select 0, _date select 1, _date select 2, 6, 0];

    // Wipe all player bank balances from persistence and memory
    {
        if (_x find "BANK_" == 0) then {
            profileNamespace setVariable [_x, nil];
        };
    } forEach allVariables profileNamespace;

    {
        private _var = format ["BANK_%1", getPlayerUID _x];
        profileNamespace setVariable [_var, nil];
        _x setVariable ["bankTokens", 0, true];
    } forEach allPlayers;

    saveProfileNamespace;

    sleep 5; // allow players to read the message
    saveProfileNamespace;
    ["END1", true] remoteExecCall ["BIS_fnc_endMission", 0];
};

// Monitor victory conditions
[] spawn {
    while {true} do {
        private _socio = missionNamespace getVariable ["Sociostability", 50];
        private _inf = missionNamespace getVariable ["Infestation", 50];

        if (_socio <= 0) exitWith { ["Rebels"] call endgame_fnc_finish; };
        if (_inf >= 100) exitWith { ["Xenians"] call endgame_fnc_finish; };

        sleep 10;
    };
};