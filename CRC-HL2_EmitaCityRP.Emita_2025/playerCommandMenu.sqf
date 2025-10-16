if (!hasInterface) exitWith {};
if (missionNamespace getVariable ["HL2_CommandMenu_Configured", false]) exitWith {};
missionNamespace setVariable ["HL2_CommandMenu_Configured", true];

HL2_fnc_updateCommandMenu = {
    if (!hasInterface) exitWith {};
    disableSerialization;

    private _display = findDisplay 9000;
    if (isNull _display) exitWith {};

    private _tokenClass = "VRP_HL_Token_Item";
    private _tokens = { _x == _tokenClass } count (items player);
    private _side = side player;
    private _group = group player;
    private _mates = [];
    if (!isNull _group) then {
        _mates = (units _group) select { _x != player && alive _x };
    };
    private _isLeader = (!isNull _group) && { leader _group isEqualTo player };

    private _btnMission = _display displayCtrl 9100;
    private _missionLabel = "";
    private _missionEnabled = true;
    switch (_side) do {
        case west: { _missionLabel = "Combine"; };
        case east: { _missionLabel = "Rebel"; };
        case civilian: { _missionLabel = "Civilian"; };
        case independent: { _missionLabel = "Independent"; };
        default {
            _missionEnabled = false;
        };
    };
    if (_missionLabel isEqualTo "") then { _missionEnabled = false; };
    _btnMission ctrlEnable _missionEnabled;
    private _missionTooltip = if (_missionEnabled) then {
        format ["Request a %1 mission for your faction.", _missionLabel]
    } else {
        "Your faction cannot request missions."
    };
    _btnMission ctrlSetTooltip _missionTooltip;

    private _btnRally = _display displayCtrl 9101;
    private _canRally = _isLeader && {_tokens >= 5} && {count _mates > 0};
    _btnRally ctrlEnable _canRally;
    private _rallyReasons = [];
    if (!_isLeader) then { _rallyReasons pushBack "Only group leaders can rally the squad."; };
    if (_tokens < 5) then { _rallyReasons pushBack "Requires 5 tokens."; };
    if (count _mates == 0) then { _rallyReasons pushBack "No squadmates available."; };
    if (_rallyReasons isEqualTo []) then {
        _rallyReasons pushBack "Teleport your squadmates to your position for 5 tokens.";
    };
    _btnRally ctrlSetTooltip (_rallyReasons joinString "\n");

    private _btnReinforce = _display displayCtrl 9102;
    private _reinforceAllowedSide = _side in [west, east];
    private _canReinforce = _reinforceAllowedSide && {_tokens >= 10};
    _btnReinforce ctrlEnable _canReinforce;
    private _reinforceTips = [];
    if (!_reinforceAllowedSide) then {
        _reinforceTips pushBack "Only Combine or Rebel forces may request reinforcements.";
    };
    if (_tokens < 10) then {
        _reinforceTips pushBack "Requires 10 tokens.";
    };
    if (_reinforceTips isEqualTo []) then {
        _reinforceTips pushBack "Call in a friendly squad that will join your group.";
    };
    _btnReinforce ctrlSetTooltip (_reinforceTips joinString "\n");

    private _btnRecon = _display displayCtrl 9103;
    private _reconAllowedSide = _side in [west, east];
    private _canRecon = _reconAllowedSide && {_tokens >= 5};
    _btnRecon ctrlEnable _canRecon;
    private _reconTips = [];
    if (!_reconAllowedSide) then {
        _reconTips pushBack "Only Combine or Rebel forces may request recon flights.";
    };
    if (_tokens < 5) then {
        _reconTips pushBack "Requires 5 tokens.";
    };
    if (_reconTips isEqualTo []) then {
        _reconTips pushBack "Dispatch a scout helicopter to mark enemies within 2 km.";
    };
    _btnRecon ctrlSetTooltip (_reconTips joinString "\n");
};

HL2_fnc_openCommandMenu = {
    if (!hasInterface) exitWith {};
    if (!isNull findDisplay 9000) exitWith {};

    createDialog "HL2_CommandMenu";
    [] call HL2_fnc_updateCommandMenu;

    [] spawn {
        waitUntil { isNull findDisplay 9000 };
        [] call HL2_fnc_updateCommandMenu;
    };

    [] spawn {
        while { !isNull findDisplay 9000 } do {
            uiSleep 0.5;
            [] call HL2_fnc_updateCommandMenu;
        };
    };
};

HL2_fnc_requestMission = {
    if (!hasInterface) exitWith {};
    private _side = side player;
    private _targetFunc = switch (_side) do {
        case west: { "TAG_fnc_requestCombineMission" };
        case east: { "TAG_fnc_requestRebelsMission" };
        case civilian: { "TAG_fnc_requestCivMission" };
        case independent: { "TAG_fnc_requestCivMission" };
        default { "" };
    };
    if (_targetFunc isEqualTo "") exitWith {
        hint "No mission requests are available for your faction.";
    };
    [player] remoteExecCall [_targetFunc, 2];
    hintSilent "Mission request sent.";
};

HL2_fnc_rallySquad = {
    if (!hasInterface) exitWith {};
    private _tokenClass = "VRP_HL_Token_Item";
    private _cost = 5;
    private _group = group player;
    if (isNull _group) exitWith { hint "You are not in a group."; };
    if !(leader _group isEqualTo player) exitWith { hint "Only group leaders can rally the squad."; };

    private _mates = (units _group) select { _x != player && alive _x };
    if (_mates isEqualTo []) exitWith { hint "No squadmates available."; };

    private _tokens = { _x == _tokenClass } count (items player);
    if (_tokens < _cost) exitWith { hint format ["You need %1 tokens to rally the squad.", _cost]; };

    for "_i" from 1 to _cost do { player removeItem _tokenClass; };

    private _leaderPos = getPosATL player;
    {
        private _targetPos = [player, 3 + random 2, random 360] call BIS_fnc_relPos;
        if ((count _targetPos) < 3) then { _targetPos pushBack 0; };
        _targetPos set [2, _leaderPos select 2];
        [_x, _targetPos] remoteExec ["setPosATL", _x];
    } forEach _mates;

    [format ["%1 called a rally. Forming up!", name player]] remoteExec ["systemChat", units _group];
    [] call HL2_fnc_updateCommandMenu;
};

HL2_fnc_requestReinforcements = {
    if (!hasInterface) exitWith {};
    private _side = side player;
    if !(_side in [west, east]) exitWith { hint "Only Combine or Rebel forces may request reinforcements."; };

    private _tokenClass = "VRP_HL_Token_Item";
    private _cost = 10;
    private _tokens = { _x == _tokenClass } count (items player);
    if (_tokens < _cost) exitWith { hint format ["You need %1 tokens to request reinforcements.", _cost]; };

    for "_i" from 1 to _cost do { player removeItem _tokenClass; };

    [player, getPosATL player] remoteExec ["HL2_fnc_spawnReinforcements", 2];
    hintSilent "Reinforcements inbound.";
    [] call HL2_fnc_updateCommandMenu;
};

HL2_fnc_requestRecon = {
    if (!hasInterface) exitWith {};
    private _side = side player;
    if !(_side in [west, east]) exitWith { hint "Only Combine or Rebel forces may request recon flights."; };

    private _tokenClass = "VRP_HL_Token_Item";
    private _cost = 5;
    private _tokens = { _x == _tokenClass } count (items player);
    if (_tokens < _cost) exitWith { hint format ["You need %1 tokens to request recon.", _cost]; };

    for "_i" from 1 to _cost do { player removeItem _tokenClass; };

    [player, getPosATL player] remoteExec ["HL2_fnc_launchRecon", 2];
    hintSilent "Recon flight inbound.";
    [] call HL2_fnc_updateCommandMenu;
};

[] spawn {
    waitUntil { !isNull player };
    waitUntil { !isNull findDisplay 46 };
    if (isNil { missionNamespace getVariable "HL2_CommandMenu_KeyEH" }) then {
        private _eh = (findDisplay 46) displayAddEventHandler ["KeyDown", {
            params ["_display", "_key", "_shift", "_ctrl", "_alt"];
            if (_key isEqualTo 21 && { !_shift && !_ctrl && !_alt }) then {
                if (isNull findDisplay 9000) then {
                    [] call HL2_fnc_openCommandMenu;
                } else {
                    closeDialog 0;
                };
                true
            } else {
                false
            };
        }];
        missionNamespace setVariable ["HL2_CommandMenu_KeyEH", _eh];
    };
};