if (!hasInterface) exitWith {};
if (missionNamespace getVariable ["HL2_CommandMenu_Configured", false]) exitWith {};
missionNamespace setVariable ["HL2_CommandMenu_Configured", true];

private _configs = createHashMap;

private _donationMenu = [
    ["Back", "pop", nil, "Return to the previous menu."],
    ["Give 1 Token", "hint", "Token dispensers are currently offline pending banking overhaul."],
    ["Give 5 Tokens", "hint", "Token dispensers are currently offline pending banking overhaul."],
    ["Give 10 Tokens", "hint", "Token dispensers are currently offline pending banking overhaul."],
    ["Give 20 Tokens", "hint", "Token dispensers are currently offline pending banking overhaul."],
    ["Give 100 Tokens", "hint", "Token dispensers are currently offline pending banking overhaul."]
];

private _westMenus = createHashMapFromArray [
    ["main", [
        ["Request Mission", "code", { [] call HL2_fnc_requestMission; }, "Request a mission assignment from the Combine command network."],
        ["Support Menu", "push", "support", "Open tactical support requisition options."],
        ["Civil Actions", "push", "civilActions", "Open civil administration utilities."],
        ["Manage Outpost", "hint", "Outpost management console is currently under maintenance.", "Placeholder action for testing."],
        ["Garage Vehicle", "hint", "Motor pool automation is currently offline.", "Placeholder action for testing."],
        ["Exit", "close", nil, "Close the command interface."]
    ]],
    ["donations", _donationMenu],
    ["civilActions", [
        ["Back", "pop", nil, "Return to the main menu."],
        ["Donate Tokens to Player", "push", "donations", "Reward a Loyal citizen with a donation of your payroll."],
        ["Access Civil Registry", "code", { [] call HL2_fnc_openCivilRegistry; }, "Review the current CID registry."],
        ["Award Loyalty Point", "code", { [] call HL2_fnc_awardLoyaltyPoint; }, "Grant the focused citizen a Loyalty Point."],
        ["Award Malcompliance Point", "code", { [] call HL2_fnc_awardMalcompliancePoint; }, "Issue a Malcompliance Point to the focused citizen."]
    ]],
    ["support", [
        ["Back", "pop", nil, "Return to the main menu."],
        ["Request Backup", "push", "backup", "Radio for additional Protection Team units."],
        ["Request Strike", "push", "strike", "Request a strike package from command."],
        ["Request Recon", "hint", "Recon flight scheduling is not yet available.", "Placeholder action for testing."],
        ["Synth Deployment", "push", "synth", "Requisition specialized synth assets."]
    ]],
    ["backup", [
        ["Back", "pop", nil, "Return to the support menu."],
        ["Protection Squad", "code", {
            missionNamespace setVariable ["HL2_CommandMenu_CombineBackupSelection", "Protection Squad"];
            ["insertion"] call HL2_fnc_commandMenuPush;
        }, "Deploy a Protection Team via insertion."],
        ["Conscript Squad", "code", {
            missionNamespace setVariable ["HL2_CommandMenu_CombineBackupSelection", "Conscript Squad"];
            ["insertion"] call HL2_fnc_commandMenuPush;
        }, "Deploy a Conscript squad via insertion."],
        ["Riot Squad", "code", {
            missionNamespace setVariable ["HL2_CommandMenu_CombineBackupSelection", "Riot Squad"];
            ["insertion"] call HL2_fnc_commandMenuPush;
        }, "Deploy a Riot squad via insertion."],
        ["AT/AA Squad", "code", {
            missionNamespace setVariable ["HL2_CommandMenu_CombineBackupSelection", "AT/AA Squad"];
            ["insertion"] call HL2_fnc_commandMenuPush;
        }, "Deploy an anti-armor/anti-air squad via insertion."],
        ["Overwatch", "code", {
            missionNamespace setVariable ["HL2_CommandMenu_CombineBackupSelection", "Overwatch"];
            ["insertion"] call HL2_fnc_commandMenuPush;
        }, "Request an Overwatch unit for insertion."]
    ]],
    ["insertion", [
        ["Back", "pop", nil, "Return to squad selection."],
        ["Land", "hint", "Insertion routing pending tactical approval."],
        ["Sea", "hint", "Insertion routing pending tactical approval."],
        ["Air", "hint", "Insertion routing pending tactical approval."]
    ]],
    ["strike", [
        ["Back", "pop", nil, "Return to the support menu."],
        ["Plasma Mortar", "hint", "Strike package not yet available. Await further instructions."],
        ["Biotic Cannister", "hint", "Strike package not yet available. Await further instructions."],
        ["Illumination Mortar", "hint", "Strike package not yet available. Await further instructions."],
        ["Smoke Mortar", "hint", "Strike package not yet available. Await further instructions."],
        ["Gunship Strike", "hint", "Strike package not yet available. Await further instructions."]
    ]],
    ["synth", [
        ["Back", "pop", nil, "Return to the support menu."],
        ["Elite Synth Squad", "hint", "Synth deployment authorization pending."],
        ["Hunter Pack", "hint", "Synth deployment authorization pending."],
        ["Strider", "hint", "Synth deployment authorization pending."]
    ]]
];

private _eastMenus = createHashMapFromArray [
    ["main", [
        ["Request Mission", "code", { [] call HL2_fnc_requestMission; }, "Request a mission briefing from the resistance network."],
        ["Support Menu", "push", "support", "Open the guerrilla support board."],
        ["Donate Tokens to Player", "push", "donations", "Share tokens with a comrade."],
        ["Manage Outpost", "hint", "Outpost coordination terminal under construction.", "Placeholder action for testing."],
        ["Garage Vehicle", "hint", "Safehouse garage controls are being rewired.", "Placeholder action for testing."],
        ["Exit", "close", nil, "Close the command interface."]
    ]],
    ["donations", _donationMenu],
    ["support", [
        ["Back", "pop", nil, "Return to the main menu."],
        ["Request Backup", "push", "backup", "Raise local cells for reinforcements."],
        ["Request Strike", "push", "strike", "Call in a resistance strike package."],
        ["Request Recon", "hint", "Recon drone deployment coming soon.", "Placeholder action for testing."]
    ]],
    ["backup", [
        ["Back", "pop", nil, "Return to the support menu."],
        ["Militia Squad", "code", {
            missionNamespace setVariable ["HL2_CommandMenu_RebelBackupSelection", "Militia Squad"];
            ["insertion"] call HL2_fnc_commandMenuPush;
        }, "Assemble a militia squad for insertion."],
        ["Sniper Squad", "code", {
            missionNamespace setVariable ["HL2_CommandMenu_RebelBackupSelection", "Sniper Squad"];
            ["insertion"] call HL2_fnc_commandMenuPush;
        }, "Assemble a sniper team for insertion."],
        ["AT Squad", "code", {
            missionNamespace setVariable ["HL2_CommandMenu_RebelBackupSelection", "AT Squad"];
            ["insertion"] call HL2_fnc_commandMenuPush;
        }, "Assemble an anti-armor squad for insertion."],
        ["AA Squad", "code", {
            missionNamespace setVariable ["HL2_CommandMenu_RebelBackupSelection", "AA Squad"];
            ["insertion"] call HL2_fnc_commandMenuPush;
        }, "Assemble an anti-air squad for insertion."],
        ["Lambda Squad", "code", {
            missionNamespace setVariable ["HL2_CommandMenu_RebelBackupSelection", "Lambda Squad"];
            ["insertion"] call HL2_fnc_commandMenuPush;
        }, "Assemble a Lambda squad for insertion."]
    ]],
    ["insertion", [
        ["Back", "pop", nil, "Return to squad selection."],
        ["Land", "hint", "Insertion routes are being scouted."],
        ["Sea", "hint", "Insertion routes are being scouted."],
        ["Air", "hint", "Insertion routes are being scouted."]
    ]],
    ["strike", [
        ["Back", "pop", nil, "Return to the support menu."],
        ["Mortar Strike", "hint", "Strike support is still being coordinated."],
        ["Illumination Strike", "hint", "Strike support is still being coordinated."],
        ["Smoke Strike", "hint", "Strike support is still being coordinated."],
        ["Helicopter Strafe", "hint", "Strike support is still being coordinated."],
        ["Tactical Xen Portal", "hint", "Strike support is still being coordinated."]
    ]]
];

private _civilMenus = createHashMapFromArray [
    ["main", [
        ["Request Mission", "code", { [] call HL2_fnc_requestMission; }, "Request a sanctioned task from the CWU dispatch office."],
        ["Manage Home", "hint", "Residential management services are being audited.", "Placeholder action for testing."],
        ["Donate Tokens to Player", "push", "donations", "Access token disbursement options."],
        ["Exit", "close", nil, "Close the command interface."]
    ]],
    ["donations", _donationMenu]
];

private _independentMenus = createHashMapFromArray [
    ["main", [
        ["Request Mission", "code", { [] call HL2_fnc_requestMission; }, "Seek new guidance from the abyssal network."],
        ["Manage Coven", "hint", "The coven stirs, but the ledger is unfinished.", "Placeholder action for testing."],
        ["Donate Tokens to Player", "push", "donations", "Share tithe among the faithful."],
        ["Exit", "close", nil, "Close the command interface."]
    ]],
    ["donations", _donationMenu]
];

_configs set [west, createHashMapFromArray [
    ["title", "Civil Protection Force"],
    ["subtitleOptions", [
        "UU.CPF Network Connection: Stable. Unit Biometric Credentials: Accepted.",
        "Reminder: Mission failure will result in permanent off-world assignment.",
        "Reminder: 100 sterilized credits qualifies non-mechanical reproduction simulation.",
        "Reminder: Memory replacement is the first step toward rank privileges.",
        "Protection Team member: your family cohesion is preserved."
    ]],
    ["theme", createHashMapFromArray [
        ["background", [0.02, 0.07, 0.18, 0.95]],
        ["titleBackground", [0.01, 0.04, 0.12, 0.95]],
        ["titleText", [1, 1, 1, 1]],
        ["subtitleText", [1, 1, 1, 0.9]],
        ["buttonBackground", [1, 1, 1, 0.95]],
        ["buttonText", [0, 0, 0, 1]]
    ]],
    ["menus", _westMenus]
]];

_configs set [east, createHashMapFromArray [
    ["title", "Rebel Radio Online"],
    ["subtitleOptions", [
        "Need Firepower? Outlander Outfitters has you covered.",
        "Resist to Exist. LambdaNet Lives.",
        "Visit Odessa. We have cabbages.",
        "This isn't your grandma's radio station.",
        "Is this thing on?"
    ]],
    ["theme", createHashMapFromArray [
        ["background", [0.85, 0.35, 0.05, 0.92]],
        ["titleBackground", [0.65, 0.18, 0.02, 0.95]],
        ["titleText", [1, 0.96, 0.9, 1]],
        ["subtitleText", [1, 0.95, 0.85, 0.95]],
        ["buttonBackground", [1, 1, 1, 0.95]],
        ["buttonText", [0.7, 0.05, 0.05, 1]]
    ]],
    ["menus", _eastMenus]
]];

_configs set [civilian, createHashMapFromArray [
    ["title", "CWU Public Information"],
    ["subtitleOptions", [
        "Strength. Unity. Obedience.",
        "Join the CWU Today!",
        "Visit your local CWU Office to volunteer for Infestation Control duty!",
        "Citizen Reminder: a civilized society demands swift and targeted oversight.",
        "Citizen Reminder: inaction is conspiracy."
    ]],
    ["theme", createHashMapFromArray [
        ["background", [0.12, 0.0, 0.2, 0.95]],
        ["titleBackground", [0.18, 0.0, 0.3, 0.95]],
        ["titleText", [1, 1, 1, 1]],
        ["subtitleText", [1, 1, 1, 0.9]],
        ["buttonBackground", [1, 1, 1, 0.95]],
        ["buttonText", [0, 0, 0, 1]]
    ]],
    ["menus", _civilMenus]
]];

_configs set [independent, createHashMapFromArray [
    ["title", "The                Beckons"],
    ["subtitleOptions", [
        "The Veil Breathes Still.",
        "All Paths Spiral Inward.",
        "It Waits Beneath the Pulse.",
        "Your Echo Is Not Alone.",
        "The Maw Remembers Us."
    ]],
    ["theme", createHashMapFromArray [
        ["background", [0.04, 0.14, 0.07, 0.95]],
        ["titleBackground", [0.02, 0.1, 0.05, 0.95]],
        ["titleText", [0.95, 0.98, 0.95, 1]],
        ["subtitleText", [0.9, 0.98, 0.9, 0.95]],
        ["buttonBackground", [0.75, 0.95, 0.75, 0.95]],
        ["buttonText", [0, 0, 0, 1]]
    ]],
    ["menus", _independentMenus]
]];

missionNamespace setVariable ["HL2_CommandMenu_Configs", _configs];

HL2_fnc_commandMenuGetConfig = {
    params ["_side"];
    (missionNamespace getVariable ["HL2_CommandMenu_Configs", createHashMap]) getOrDefault [_side, objNull];
};

HL2_fnc_commandMenuRender = {
    if (!hasInterface) exitWith {};
    disableSerialization;

    private _display = findDisplay 9000;
    if (isNull _display) exitWith {};

    private _side = missionNamespace getVariable ["HL2_CommandMenu_CurrentSide", sideUnknown];
    private _config = [_side] call HL2_fnc_commandMenuGetConfig;
    if (isNil "_config") exitWith {};

    private _theme = _config getOrDefault ["theme", createHashMap];
    private _backgroundColor = _theme getOrDefault ["background", [0, 0, 0, 0.85]];
    private _titleBackground = _theme getOrDefault ["titleBackground", _backgroundColor];
    private _titleColor = _theme getOrDefault ["titleText", [1, 1, 1, 1]];
    private _subtitleColor = _theme getOrDefault ["subtitleText", [1, 1, 1, 0.9]];
    private _buttonBackground = _theme getOrDefault ["buttonBackground", [0.2, 0.2, 0.2, 1]];
    private _buttonText = _theme getOrDefault ["buttonText", [1, 1, 1, 1]];

    (_display displayCtrl 9005) ctrlSetBackgroundColor _backgroundColor;

    private _titleCtrl = _display displayCtrl 9001;
    _titleCtrl ctrlSetBackgroundColor _titleBackground;
    _titleCtrl ctrlSetTextColor _titleColor;
    _titleCtrl ctrlSetText (_config getOrDefault ["title", "Command"]);

    private _subtitleCtrl = _display displayCtrl 9002;
    _subtitleCtrl ctrlSetTextColor _subtitleColor;
    private _subtitleText = missionNamespace getVariable ["HL2_CommandMenu_CurrentSubtitle", ""];
    _subtitleCtrl ctrlSetText _subtitleText;
    _subtitleCtrl ctrlShow !(_subtitleText isEqualTo "");

    private _stack = missionNamespace getVariable ["HL2_CommandMenu_Stack", []];
    if (_stack isEqualTo []) then {
        _stack = ["main"];
        missionNamespace setVariable ["HL2_CommandMenu_Stack", _stack];
    };

    private _currentMenu = _stack select ((count _stack) - 1);
    private _menus = _config getOrDefault ["menus", createHashMap];
    private _buttons = _menus getOrDefault [_currentMenu, []];

    for "_i" from 0 to 5 do {
        private _idc = 9100 + _i;
        private _ctrl = _display displayCtrl _idc;
        if (_i < count _buttons) then {
            private _entry = _buttons select _i;
            private _label = _entry select 0;
            private _actionType = if ((count _entry) > 1) then { _entry select 1 } else { "" };
            private _actionData = if ((count _entry) > 2) then { _entry select 2 } else { nil };
            private _tooltip = if ((count _entry) > 3) then { _entry select 3 } else { "" };
            private _enabled = if ((count _entry) > 4) then { _entry select 4 } else { true };

            _ctrl ctrlShow true;
            _ctrl ctrlEnable _enabled;
            _ctrl ctrlSetText _label;
            _ctrl ctrlSetTooltip _tooltip;
            _ctrl ctrlSetTextColor _buttonText;
            _ctrl ctrlSetBackgroundColor _buttonBackground;
            _ctrl setVariable ["HL2_CommandMenu_Action", _actionType];
            _ctrl setVariable ["HL2_CommandMenu_Data", _actionData];
        } else {
            _ctrl ctrlShow false;
            _ctrl ctrlEnable false;
            _ctrl setVariable ["HL2_CommandMenu_Action", ""];
            _ctrl setVariable ["HL2_CommandMenu_Data", nil];
        };
    };
};

HL2_fnc_commandMenuPush = {
    params ["_menuName"];
    if (isNil "_menuName") exitWith {};

    private _stack = missionNamespace getVariable ["HL2_CommandMenu_Stack", []];
    _stack pushBack _menuName;
    missionNamespace setVariable ["HL2_CommandMenu_Stack", _stack];

    [] call HL2_fnc_commandMenuRender;
};

HL2_fnc_commandMenuPop = {
    private _stack = missionNamespace getVariable ["HL2_CommandMenu_Stack", []];
    if ((count _stack) > 1) then {
        _stack deleteAt ((count _stack) - 1);
        missionNamespace setVariable ["HL2_CommandMenu_Stack", _stack];
    };

    [] call HL2_fnc_commandMenuRender;
};

HL2_fnc_commandMenuHandleButton = {
    params ["_control"];
    if (isNull _control) exitWith {};

    private _action = _control getVariable ["HL2_CommandMenu_Action", ""];
    private _data = _control getVariable ["HL2_CommandMenu_Data", nil];

    switch (_action) do {
        case "code": {
            if (!isNil "_data") then {
                call _data;
            };
            [] call HL2_fnc_commandMenuRender;
        };
        case "push": {
            if (!isNil "_data") then {
                [_data] call HL2_fnc_commandMenuPush;
            };
        };
        case "pop": {
            [] call HL2_fnc_commandMenuPop;
        };
        case "close": {
            closeDialog 0;
        };
        case "hint": {
            private _message = if ((typeName _data) isEqualTo "STRING") then { _data } else { "Placeholder action." };
            hint _message;
            [] call HL2_fnc_commandMenuRender;
        };
        default {
            [] call HL2_fnc_commandMenuRender;
        };
    };
};

HL2_fnc_updateCommandMenu = {
    [] call HL2_fnc_commandMenuRender;
};

HL2_fnc_openCommandMenu = {
    if (!hasInterface) exitWith {};
    if (!isNull findDisplay 9000) exitWith {};

    private _side = side player;
    private _config = [_side] call HL2_fnc_commandMenuGetConfig;
    if (isNil "_config") exitWith {
        hint "No command menu is available for your faction.";
    };

    private _subtitleOptions = _config getOrDefault ["subtitleOptions", []];
    private _subtitle = if (_subtitleOptions isEqualTo []) then { "" } else { selectRandom _subtitleOptions };

    missionNamespace setVariable ["HL2_CommandMenu_CurrentSide", _side];
    missionNamespace setVariable ["HL2_CommandMenu_CurrentSubtitle", _subtitle];
    missionNamespace setVariable ["HL2_CommandMenu_Stack", ["main"]];

    createDialog "HL2_CommandMenu";
    disableSerialization;
    private _display = findDisplay 9000;
    if (isNull _display) exitWith {};

    for "_i" from 0 to 5 do {
        private _ctrl = _display displayCtrl (9100 + _i);
        _ctrl ctrlAddEventHandler ["ButtonClick", { (_this select 0) call HL2_fnc_commandMenuHandleButton; }];
    };

    [] call HL2_fnc_commandMenuRender;
};

HL2_fnc_openCivilRegistry = {
    if (!hasInterface) exitWith {};
    [player] remoteExecCall ["HL2_fnc_serverShowCivilRegistry", 2];
};

HL2_fnc_awardCitizenPoint = {
    params ["_category"];
    if (!hasInterface) exitWith {};

    private _target = cursorTarget;
    if (isNull _target || {!isPlayer _target}) exitWith {
        hint "You must be looking at a registered citizen.";
    };

    private _cid = _target getVariable ["CID_Number", -1];
    if (_cid isEqualTo -1) exitWith {
        hint "The focused individual does not have an assigned CID.";
    };

    if ((player distance _target) > 10) exitWith {
        hint "Move closer to the citizen before issuing points.";
    };

    private _fncName = switch (_category) do {
        case "LOYALTY": { "HL2_fnc_serverAwardLoyaltyPoint" };
        case "MAL": { "HL2_fnc_serverAwardMalcompliancePoint" };
        default { "" };
    };

    if (_fncName isEqualTo "") exitWith {};

    [_target, player] remoteExecCall [_fncName, 2];
};

HL2_fnc_awardLoyaltyPoint = {
    ["LOYALTY"] call HL2_fnc_awardCitizenPoint;
};

HL2_fnc_awardMalcompliancePoint = {
    ["MAL"] call HL2_fnc_awardCitizenPoint;
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