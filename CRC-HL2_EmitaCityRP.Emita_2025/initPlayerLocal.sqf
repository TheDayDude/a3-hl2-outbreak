[player] spawn {
    params ["_unit"];

    while {alive _unit} do {
        private _cid = _unit getVariable ["CID_Number", "Unregistered"];
        private _mp = CID_Malcompliance getOrDefault [_cid, 0];

        if (_mp >= 5 && rating _unit >= 0) then {
            [_unit]  joinSilent createGroup east;
            hint format ["%1 has been marked an Anti-Citizen due to a high Malcompliance Score.", name _unit];
			playSound "Alarm";
        };

        sleep 10;
    };
};

[] spawn {
    while {true} do {
        sleep 5;
        if ("Civilain_IDCard_6" in magazines player) then {
            if !(player getVariable ["isLoyalist", false]) then {
                player setVariable ["isLoyalist", true, true];
                systemChat "Loyalist status granted.";
            };
        } else {
            if (player getVariable ["isLoyalist", false]) then {
                player setVariable ["isLoyalist", false, true];
                systemChat "Loyalist status revoked.";
            };
        };
    };
};

sleep 2;

// Initialise bank balance for the player
["INIT",0,player] remoteExec ["MRC_fnc_bankServer",2];


sleep 2;

[] spawn {
    while {true} do {
        private _socio = missionNamespace getVariable ["Sociostability", 0];
        private _inf = missionNamespace getVariable ["Infestation", 0];
        private _invTokens = { _x == "VRP_HL_Token_Item" } count (items player);
        private _bankTokens = player getVariable ["bankTokens", 0];
        private _text = format [
            "<t size='0.5' color='#00D0FF' align='center' shadow='1' font='LCD14'>SOCIOSTABILITY: %1%% | INFESTATION: %2%% | TOKENS: %3 | BANK BALANCE: %4</t>",
            round _socio,
            round _inf,
            _invTokens,
            _bankTokens
        ];
        [_text, safeZoneX + safeZoneW / 2, safeZoneY + 0.02, 30, 0, 0] spawn BIS_fnc_dynamicText;
        sleep 2;
    };
};