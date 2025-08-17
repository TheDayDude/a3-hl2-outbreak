// File: judgementWaiver.sqf
// Prototype for Judgement Waiver global event.
// Periodically converts non-loyalist civilians to OPFOR for testing.

if (!isServer) exitWith {};

// Public variable to allow audio/visual cues
waiverActive = false;
publicVariable "waiverActive";
lastWaiverEndTime = -3600; // allows immediate trigger on mission start

JW_fnc_start = {
    waiverActive = true;
    publicVariable "waiverActive";
    [] remoteExec ["JW_fnc_playJudgement", 0];

    private _targets = [];
    private _otaGroups = [];

    // Continuously convert non-loyalist civilians to OPFOR
    [_targets] spawn {
        params ["_targets"];
        while {waiverActive} do {
            private _new = allUnits select {
                side _x isEqualTo civilian &&
                alive _x &&
                !captive _x &&
                !(_x getVariable ["ACE_isUnconscious", false]) &&
                !(_x getVariable ["isLoyalist", false])
            };
            {
                [_x] joinSilent createGroup east;
                if !(_x in _targets) then { _targets pushBack _x };
            } forEach _new;
            sleep 60;
        };
    };

    // Allow SFX or other systems to react
    ["Attention all Ground Protection Teams: JUDGEMENT WAIVER is now in effect. Capital prosecution is discretionary."] remoteExec ["systemChat", 0];
    ["Fprotectionresponse5spkr"] remoteExec ["playSound", 0];
    sleep 20;
    ["Attention all Ground Protection Teams: Autonomous judgement is now in effect. Sentencing is now discretionary. Code: amputate, zero, confirm."] remoteExec ["systemChat", 0];
    ["Fprotectionresponse4spkr"] remoteExec ["playSound", 0];

    // Spawn exactly five Overwatch squads at random patrol markers
    private _patrolMarkers = allMapMarkers select { toLower _x find "patrol_" == 0 };
    private _otaTypes = [
        "WBK_Combine_HL2_Type",
        "WBK_Combine_HL2_Type",
        "WBK_Combine_APF",
        "WBK_Combine_HL2_Type_Elite"
    ];
    for "_i" from 1 to 5 do {
        if (_patrolMarkers isEqualTo []) exitWith {};
        private _marker = selectRandom _patrolMarkers;
        _patrolMarkers deleteAt (_patrolMarkers find _marker);
        private _grp = createGroup west;
        private _pos = getMarkerPos _marker;
        for "_j" from 1 to 4 do {
            _grp createUnit [selectRandom _otaTypes, _pos, [], 0, "FORM"];
        };
        _grp setBehaviour "AWARE";
        _grp setCombatMode "RED";
        _otaGroups pushBack _grp;
    };

    // Event duration
    sleep 1800;

    waiverActive = false;
    publicVariable "waiverActive";
    ["Judgement Waiver is now ending..."] remoteExec ["systemChat", 0];

    {
        [_x] joinSilent createGroup civilian;
    } forEach _targets;

    {
        { deleteVehicle _x } forEach units _x;
    } forEach _otaGroups;

    lastWaiverEndTime = time;
};

[] spawn {
    while {true} do {
        if (!waiverActive && (time - lastWaiverEndTime) >= 3600 && (missionNamespace getVariable ["Sociostability", 100]) <= 20) then {
            [] call JW_fnc_start;
        };
        sleep 60;
    };
};