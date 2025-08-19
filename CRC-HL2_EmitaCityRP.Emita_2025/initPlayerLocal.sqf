if (isNil "MRC_fnc_applyPlayerState") then {
    MRC_fnc_applyPlayerState = {
        params ["_pos", "_loadout", "_combine", "_arm", "_armMax", "_isOTA", "_canFakeID"];
        [_pos, _loadout, _combine, _arm, _armMax, _isOTA, _canFakeID] spawn {
            params ["_pos", "_loadout", "_combine", "_arm", "_armMax", "_isOTA", "_canFakeID"];
            hint "Restoring position";
            player setPosATL _pos;
            sleep 1;
            hint "Restoring loadout";
            player setUnitLoadout _loadout;
            sleep 1;
            hint "Restoring WBK variables";
            player setVariable ["WBK_CombineType", _combine, true];
            player setVariable ["WBK_HL_CustomArmour", _arm, true];
            player setVariable ["WBK_HL_CustomArmour_Max", _armMax, true];
            player setVariable ["isOTA", _isOTA, true];
            player setVariable ["CanBuyFakeID", _canFakeID, true];
            sleep 1;
            hint "State restore complete";
        };
    };
};

[] spawn {
    waitUntil {sleep 1; !isNull player};
    hint "Requesting saved state";
    [player] remoteExec ["MRC_fnc_restorePlayerState", 2];
};

[] spawn {
    waitUntil { player getVariable ["MRC_stateRestored", false] };
    if (isNil { player getVariable ["CID_Number", nil] }) then {
        [player] remoteExec ["MRC_fnc_assignCID", 2];
    };
};


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
        private _cidNum = player getVariable ["CID_Number", "-"];
        private _prefix = switch (side player) do {
            case civilian: {"CIT"};
            case west: {"UNIT"};
            case independent: {"???"};
            case east: {"MAL"};
            default {"???"};
        };
        private _cidText = format ["%1-%2", _prefix, _cidNum];
        private _text = format [
            "<t size='0.5' color='#00D0FF' align='center' shadow='1' font='LCD14'> %1 | SOCIOSTABILITY: %2%% | INFESTATION: %3%% | TOKENS: %4 | BANK: %5</t>",
            _cidText,
            round _socio,
            round _inf,
            _invTokens,
            _bankTokens
        ];
        [_text, safeZoneX + safeZoneW / 2 - 0.7, safeZoneY + 0.02, 30, 0, 0] spawn BIS_fnc_dynamicText;
        sleep 2;
    };
};