// File: judgementWaiver.sqf
// Prototype for Judgement Waiver global event.
// Periodically converts non-loyalist civilians to OPFOR for testing.

if (!isServer) exitWith {};

// Public variable to allow audio/visual cues
waiverActive = false;
publicVariable "waiverActive";

JW_fnc_start = {
    waiverActive = true;
    publicVariable "waiverActive";

    private _targets = allUnits select {
        side _x isEqualTo civilian &&
        alive _x &&
        !captive _x &&
        !(_x getVariable ["ACE_isUnconscious", false]) &&
        !(_x getVariable ["isLoyalist", false])
    };

    {
        [_x] joinSilent createGroup east;
    } forEach _targets;
	
    // Allow SFX or other systems to react
	["Attention all Ground Protection Teams: JUDGEMENT WAIVER is now in effect. Capital prosecution is discretionary."] remoteExec ["systemChat", 0];
	["Fprotectionresponse5spkr"] remoteExec ["playSound", 0];
    sleep 20;
	["Attention all Ground Protection Teams: Autonomous judgement is now in effect. Sentencing is now discretionary. Code: amputate, zero, confirm."] remoteExec ["systemChat", 0];
	["Fprotectionresponse4spkr"] remoteExec ["playSound", 0];
	sleep 20;
    waiverActive = false;
    publicVariable "waiverActive";
	["Judgement Waiver is now ending..."] remoteExec ["systemChat", 0];
	
	{
        [_x] joinSilent createGroup civilian;
    } forEach _targets;
};

[] spawn {
    while {true} do {
        // Delay between potential activations (10-20 minutes)
        private _delay = 3600 + random 3600;
        sleep _delay;

        // 50% chance to trigger each cycle
        if (random 1 < 0.2) then {
            [] call JW_fnc_start;
        };
    };
};