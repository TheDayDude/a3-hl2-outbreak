if (isNil "fnc_applyBlur") then {
    fnc_applyBlur = {
        params ["_id", "_unit"];
        if (!hasInterface) exitWith {};

        [_unit] spawn {
            private _chrom = ppEffectCreate ["ChromAberration", 200];
            _chrom ppEffectEnable true;
            _chrom ppEffectAdjust [0.05, 0.05, true];
            _chrom ppEffectCommit 0;

            private _wet = ppEffectCreate ["WetDistortion", 201];
            _wet ppEffectEnable true;
            // WetDistortion requires 15 parameters, use defaults for remaining slots
            _wet ppEffectAdjust [1, 1, 0.1, 0.1, 1, 1, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5];
            _wet ppEffectCommit 0;

            private _grain = ppEffectCreate ["FilmGrain", 202];
            _grain ppEffectEnable true;
            _grain ppEffectAdjust [0.2, 1, 1, 0, 1];
            _grain ppEffectCommit 0;

            [_wet] spawn {
                params ["_eff"];
                uiSleep 5;
                _eff ppEffectEnable false;
                ppEffectDestroy _eff;
            };

            [_chrom] spawn {
                params ["_eff"];
                uiSleep 60;
                _eff ppEffectEnable false;
                ppEffectDestroy _eff;
            };

            [_grain] spawn {
                params ["_eff"];
                uiSleep 120;
                _eff ppEffectEnable false;
                ppEffectDestroy _eff;
            };
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
        sleep 1;
        if (isNil { player getVariable ["CID_Number", nil] }) then {
            [player] remoteExec ["MRC_fnc_assignCID", 2];
        };
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
        [_text, safeZoneX + safeZoneW / 2 - 0.5, safeZoneY + 0.02, 30, 0, 0] spawn BIS_fnc_dynamicText;
        sleep 2;
    };
};