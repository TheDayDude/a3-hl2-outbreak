if (!hasInterface) exitWith {};
if (missionNamespace getVariable ["HL2_CommandMenu_Configured", false]) exitWith {};
missionNamespace setVariable ["HL2_CommandMenu_Configured", true];

private _tokenClass = "VRP_HL_Token_Item";
private _buttonIds = [9200, 9201, 9202, 9203, 9204, 9205, 9206, 9207];

private _themes = createHashMapFromArray [
    [west,       createHashMapFromArray [["background", [0.05, 0.11, 0.32, 0.94]], ["buttonText", [0, 0, 0, 1]], ["buttonBackground", [1, 1, 1, 0.95]], ["buttonDisabled", [0.3, 0.3, 0.3, 0.6]]]],
    [east,       createHashMapFromArray [["background", [0.35, 0.16, 0.02, 0.94]], ["buttonText", [0.7, 0, 0, 1]], ["buttonBackground", [1, 1, 1, 0.95]], ["buttonDisabled", [0.3, 0.3, 0.3, 0.6]]]],
    [civilian,   createHashMapFromArray [["background", [0.2, 0.0, 0.33, 0.94]], ["buttonText", [0, 0, 0, 1]], ["buttonBackground", [1, 1, 1, 0.95]], ["buttonDisabled", [0.3, 0.3, 0.3, 0.6]]]],
    [independent,createHashMapFromArray [["background", [0.03, 0.18, 0.07, 0.94]], ["buttonText", [0, 0, 0, 1]], ["buttonBackground", [0.8, 1, 0.8, 0.95]], ["buttonDisabled", [0.3, 0.3, 0.3, 0.6]]]]
];

private _titles = createHashMapFromArray [
    [west, "Civil Protection Force"],
    [east, "Rebel Radio Online"],
    [civilian, "Civil Worker's Union Public Information Channel"],
    [independent, "The                Beckons"]
];

private _subtitles = createHashMapFromArray [
    [west, [
        "UU.CPF Network Connection: Stable. Unit Biometric Credentials: Accepted.",
        "Reminder: Mission failure will result in permanent off-world assignment.",
        "Reminder: 100 sterilized credits qualifies non-mechanical reproduction simulation.",
        "Reminder: Memory replacement is the first step toward rank privileges.",
        "Reminder: Protection Team member: your family cohesion is preserved."
    ]],
    [east, [
        "Need Firepower? Outlander Outfitters has you covered.",
        "Resist to Exist. LambdaNet Lives.",
        "Visit Odessa. We have cabbages.",
        "This isn't your grandma's radio station.",
        "Is this thing on?"
    ]],
    [civilian, [
        "Strength. Unity. Obedience.",
        "Join the CWU Today!",
        "Citizen Reminder: Visit your local CWU Office to volunteer for Infestation Control duty!",
        "Citizen Reminder: a civilized society demands swift and targeted oversight.",
        "Citizen Reminder: inaction is conspiracy."
    ]],
    [independent, [
        "The Veil Breathes Still.",
        "All Paths Spiral Inward.",
        "It Waits Beneath the Pulse.",
        "Your Echo Is Not Alone.",
        "The Maw Remembers Us."
    ]]
];

missionNamespace setVariable ["HL2_CommandMenu_Themes", _themes];
missionNamespace setVariable ["HL2_CommandMenu_Titles", _titles];
missionNamespace setVariable ["HL2_CommandMenu_Subtitles", _subtitles];
missionNamespace setVariable ["HL2_CommandMenu_ButtonIds", _buttonIds];
missionNamespace setVariable ["HL2_CommandMenu_TokenClass", _tokenClass];

HL2_fnc_commandMenuGetTheme = {
    params ["_side"];
    private _themes = missionNamespace getVariable ["HL2_CommandMenu_Themes", createHashMap];
    private _theme = _themes getOrDefault [_side, objNull];
    if (isNil "_theme" || { _theme isEqualTo objNull }) then {
        _theme = createHashMapFromArray [["background", [0,0,0,0.9]], ["buttonText", [1,1,1,1]], ["buttonBackground", [0.2,0.2,0.2,1]], ["buttonDisabled", [0.2,0.2,0.2,0.4]]];
    };
    _theme
};

HL2_fnc_commandMenuPickSubtitle = {
    params ["_side"];
    private _subs = missionNamespace getVariable ["HL2_CommandMenu_Subtitles", createHashMap];
    private _pool = _subs getOrDefault [_side, []];
    if (_pool isEqualTo []) exitWith { "" };
    selectRandom _pool
};

HL2_fnc_attemptPurchase = {
    params ["_cost"];
    if (_cost <= 0) exitWith { true };

    private _tokenClass = missionNamespace getVariable ["HL2_CommandMenu_TokenClass", "VRP_HL_Token_Item"];
    private _have = { _x == _tokenClass } count (items player);
    private _bank = player getVariable ["bankTokens", 0];

    if ((_have + _bank) < _cost) exitWith {
        hint format ["You need %1 tokens. Inventory: %2. Bank: %3.", _cost, _have, _bank];
        false
    };

    private _fromInventory = _have min _cost;
    private _fromBank = _cost - _fromInventory;

    for "_i" from 1 to _fromInventory do {
        player removeItem _tokenClass;
    };

    if (_fromBank > 0) then {
        ["SPEND", _fromBank, player] remoteExecCall ["MRC_fnc_bankServer", 2];
    };

    true
};

HL2_fnc_commandMenuOnButton = {
    params ["_control"];
    private _action = _control getVariable ["HL2_CommandMenu_Action", {}];
    private _context = _control getVariable ["HL2_CommandMenu_Context", createHashMap];
    private _data = _control getVariable ["HL2_CommandMenu_Data", nil];
    if (!(_action isEqualType {})) exitWith {};
    [_control, _context, _data] call _action;
};

HL2_fnc_commandMenuSetButtons = {
    params ["_display", "_menuId", "_menuContext", "_buttons", "_theme"];

    private _buttonIds = missionNamespace getVariable ["HL2_CommandMenu_ButtonIds", []];

    {
        private _control = _display displayCtrl _x;
        _control ctrlShow false;
        _control ctrlSetText "";
        _control ctrlEnable false;
        _control ctrlSetTooltip "";
        _control ctrlSetBackgroundColor [0,0,0,0.6];
        _control ctrlSetTextColor [1,1,1,1];
        _control ctrlRemoveAllEventHandlers "ButtonClick";
    } forEach _buttonIds;

    private _textColor = _theme getOrDefault ["buttonText", [1,1,1,1]];
    private _bgColor = _theme getOrDefault ["buttonBackground", [0.2,0.2,0.2,0.9]];
    private _disabledColor = _theme getOrDefault ["buttonDisabled", [0.2,0.2,0.2,0.5]];

    {
        private _index = _forEachIndex;
        if (_index >= count _buttonIds) exitWith {};
        private _idc = _buttonIds select _index;
        private _control = _display displayCtrl _idc;

        private _label = "";
        private _action = { params ["_control", "_context", "_data"]; };
        private _condition = { true };
        private _tooltip = "";
        private _data = nil;

        if (_x isEqualType []) then {
            private _entry = _x;
            if ((count _entry) > 0) then { _label = _entry select 0; };
            if ((count _entry) > 1) then { _action = _entry select 1; };
            if ((count _entry) > 2) then { _condition = _entry select 2; };
            if ((count _entry) > 3) then { _tooltip = _entry select 3; };
            if ((count _entry) > 4) then { _data = _entry select 4; };
        };

        private _enabled = true;
        if (_condition isEqualType {}) then {
            _enabled = [_menuContext, _data] call _condition;
        } else {
            _enabled = _condition;
        };

        _control ctrlSetText _label;
        _control ctrlSetTextColor (_enabled then { _textColor } else { [0.5,0.5,0.5,0.8] });
        _control ctrlSetBackgroundColor (_enabled then { _bgColor } else { _disabledColor });
        _control ctrlEnable _enabled;
        _control ctrlShow true;
        _control ctrlSetTooltip _tooltip;
        _control setVariable ["HL2_CommandMenu_Action", _action];
        _control setVariable ["HL2_CommandMenu_Context", _menuContext];
        _control setVariable ["HL2_CommandMenu_Data", _data];
        _control ctrlRemoveAllEventHandlers "ButtonClick";
        _control ctrlAddEventHandler ["ButtonClick", "_this select 0 call HL2_fnc_commandMenuOnButton;"];
    } forEach _buttons;
};

HL2_fnc_commandMenuRender = {
    params ["_menuId", "_context"];
    disableSerialization;

    private _display = findDisplay 9000;
    if (isNull _display) exitWith {};

    private _side = _context getOrDefault ["side", sideUnknown];
    private _theme = [_side] call HL2_fnc_commandMenuGetTheme;
    private _titles = missionNamespace getVariable ["HL2_CommandMenu_Titles", createHashMap];
    private _title = _titles getOrDefault [_side, "Field Support"];
    private _subtitle = "";
    private _infoText = "";
    private _buttons = [];

    private _builder = missionNamespace getVariable ["HL2_CommandMenu_Builder", {}];
    private _result = [_menuId, _context] call _builder;

    if (_result isEqualType createHashMap) then {
        _title = _result getOrDefault ["title", _title];
        _subtitle = _result getOrDefault ["subtitle", ""];
        if (_subtitle isEqualTo "" && { _result getOrDefault ["useRandomSubtitle", false] }) then {
            _subtitle = [_side] call HL2_fnc_commandMenuPickSubtitle;
        };
        if (_subtitle isEqualTo "" && { _menuId find "main" >= 0 }) then {
            _subtitle = [_side] call HL2_fnc_commandMenuPickSubtitle;
        };
        _infoText = _result getOrDefault ["info", ""];
        _buttons = _result getOrDefault ["buttons", []];
    } else {
        _buttons = [];
    };

    private _background = _display displayCtrl 9004;
    if (!isNull _background) then {
        _background ctrlSetBackgroundColor (_theme getOrDefault ["background", [0,0,0,0.9]]);
    };

    private _titleCtrl = _display displayCtrl 9001;
    _titleCtrl ctrlSetText _title;

    private _subtitleCtrl = _display displayCtrl 9002;
    private _subtitleText = if (_subtitle isEqualTo "") then { "" } else { format ["<t align='center'>%1</t>", _subtitle] };
    _subtitleCtrl ctrlSetStructuredText parseText _subtitleText;

    private _tokenCount = { _x == (missionNamespace getVariable ["HL2_CommandMenu_TokenClass", "VRP_HL_Token_Item"]) } count (items player);
    private _bankCount = player getVariable ["bankTokens", 0];
    private _infoFinal = if (_infoText isEqualTo "") then {
        format ["<t align='center'>Tokens: %1 | Bank: %2</t>", _tokenCount, _bankCount]
    } else {
        format ["<t align='center'>Tokens: %1 | Bank: %2</t><br/><t size='0.9' align='center'>%3</t>", _tokenCount, _bankCount, _infoText]
    };
    private _infoCtrl = _display displayCtrl 9003;
    _infoCtrl ctrlSetStructuredText parseText _infoFinal;

    [_display, _menuId, _context, _buttons, _theme] call HL2_fnc_commandMenuSetButtons;
};

HL2_fnc_commandMenuPush = {
    params ["_menuId", "_context"];
    private _stack = missionNamespace getVariable ["HL2_CommandMenu_Stack", []];
    _stack pushBack [_menuId, _context];
    missionNamespace setVariable ["HL2_CommandMenu_Stack", _stack];
    [_menuId, _context] call HL2_fnc_commandMenuRender;
};

HL2_fnc_commandMenuPop = {
    private _stack = missionNamespace getVariable ["HL2_CommandMenu_Stack", []];
    if (_stack isEqualTo []) exitWith { closeDialog 0; };
    _stack deleteAt ((count _stack) - 1);
    missionNamespace setVariable ["HL2_CommandMenu_Stack", _stack];
    if (_stack isEqualTo []) then {
        closeDialog 0;
    } else {
        private _entry = _stack select ((count _stack) - 1);
        [_entry select 0, _entry select 1] call HL2_fnc_commandMenuRender;
    };
};

HL2_fnc_commandMenuRefresh = {
    private _stack = missionNamespace getVariable ["HL2_CommandMenu_Stack", []];
    if (_stack isEqualTo []) exitWith {};
    private _entry = _stack select ((count _stack) - 1);
    [_entry select 0, _entry select 1] call HL2_fnc_commandMenuRender;
};

HL2_fnc_requestFactionMission = {
    params ["_side"];
    private _func = switch (_side) do {
        case west: { "TAG_fnc_requestCombineMission" };
        case east: { "TAG_fnc_requestRebelsMission" };
        case civilian: { "TAG_fnc_requestCivMission" };
        case independent: { "TAG_fnc_requestCultMission" };
        default { "" };
    };
    if (_func isEqualTo "") exitWith {
        hint "No mission requests available for your faction.";
    };
    [player] remoteExecCall [_func, 2];
};

HL2_fnc_commandMenuBuild = {
    params ["_menuId", "_context"];
    private _side = _context getOrDefault ["side", side player];
    private _result = createHashMap;
    _result set ["title", (missionNamespace getVariable ["HL2_CommandMenu_Titles", createHashMap]) getOrDefault [_side, "Field Support"]];
    _result set ["useRandomSubtitle", true];

    switch (_menuId) do {
        case "west_main": {
            _result set ["buttons", [
                ["Request Mission", {
                    params ["_control", "_ctx", "_data"];
                    [(_ctx getOrDefault ["side", west])] call HL2_fnc_requestFactionMission;
                    hintSilent "Mission request transmitted.";
                }, { true }, "Transmit a directive request to Overwatch."],
                ["Support Menu", {
                    params ["_control", "_ctx", "_data"];
                    ["west_support", _ctx] call HL2_fnc_commandMenuPush;
                }, { true }, "Access tactical requisitions."],
                ["Exit", { closeDialog 0; }, { true }]
            ]];
        };
        case "west_support": {
            _result set ["useRandomSubtitle", false];
            _result set ["subtitle", "Union tactical support interface online."];
            _result set ["buttons", [
                ["Back", { [] call HL2_fnc_commandMenuPop; }, { true }],
                ["Request Backup", {
                    params ["_control", "_ctx", "_data"];
                    ["west_reinforce", _ctx] call HL2_fnc_commandMenuPush;
                }, { true }, "Radio in a supporting squad."],
                ["Exit", { closeDialog 0; }, { true }]
            ]];
        };
        case "west_reinforce": {
            _result set ["useRandomSubtitle", false];
            _result set ["subtitle", "Select reinforcement package."];
            private _squads = [
                ["Patrol Squad (10 Tokens)", "patrol", 10, "Patrol CP detachment."],
                ["Conscript Squad (12 Tokens)", "conscript", 12, "Conscript fireteam with medical support."],
                ["Riot Squad (15 Tokens)", "riot", 15, "Riot team equipped for suppression."],
                ["Demo Squad (17 Tokens)", "demo", 17, "Demolition specialists with AA launchers."],
                ["Overwatch Deployment (20 Tokens)", "overwatch", 20, "High-priority Overwatch unit."]
            ];
            private _buttons = [["Cancel", { [] call HL2_fnc_commandMenuPop; }, { true }]];
            {
                _x params ["_label", "_id", "_cost", "_tip"];
                private _entry = [
                    _label,
                    {
                        params ["_control", "_ctx", "_data"];
                        _data params ["_squadId", "_cost"];
                        if ([ _cost ] call HL2_fnc_attemptPurchase) then {
                            private _next = createHashMapFromArray [["side", _ctx getOrDefault ["side", west]], ["squad", _squadId], ["cost", _cost]];
                            ["west_insertion", _next] call HL2_fnc_commandMenuPush;
                            hintSilent "Reinforcement authorization accepted.";
                        };
                        [] call HL2_fnc_commandMenuRefresh;
                    },
                    { params ["_ctx", "_data"]; true },
                    _tip,
                    [_id, _cost]
                ];
                _buttons pushBack _entry;
            } forEach _squads;
            _result set ["buttons", _buttons];
        };
        case "west_insertion": {
            _result set ["useRandomSubtitle", false];
            _result set ["subtitle", "Select insertion method."];
            private _buttons = [
                ["Land Insertion", {
                    params ["_control", "_ctx", "_data"];
                    [_ctx, "land"] call HL2_fnc_sendReinforcementRequest;
                }, { params ["_ctx", "_data"]; true }, "Deploy via armored transport."],
                ["Air Insertion", {
                    params ["_control", "_ctx", "_data"];
                    [_ctx, "air"] call HL2_fnc_sendReinforcementRequest;
                }, { params ["_ctx", "_data"]; true }, "Deploy via helicopter."],
                ["Sea Insertion", {
                    params ["_control", "_ctx", "_data"];
                    [_ctx, "sea"] call HL2_fnc_sendReinforcementRequest;
                }, { params ["_ctx", "_data"]; true }, "Deploy via RHIB."],
                ["Cancel", { [] call HL2_fnc_commandMenuPop; }, { true }]
            ];
            _result set ["buttons", _buttons];
        };
        case "east_main": {
            _result set ["buttons", [
                ["Request Mission", {
                    params ["_control", "_ctx", "_data"];
                    [(_ctx getOrDefault ["side", east])] call HL2_fnc_requestFactionMission;
                    hintSilent "Mission request sent over LambdaNet.";
                }],
                ["Support Menu", {
                    params ["_control", "_ctx", "_data"];
                    ["east_support", _ctx] call HL2_fnc_commandMenuPush;
                }],
                ["Exit", { closeDialog 0; }]
            ]];
        };
        case "east_support": {
            _result set ["useRandomSubtitle", false];
            _result set ["subtitle", "Call in what you need." ];
            _result set ["buttons", [
                ["Back", { [] call HL2_fnc_commandMenuPop; }, { true }],
                ["Request Reinforcements", {
                    params ["_control", "_ctx", "_data"];
                    ["east_reinforce", _ctx] call HL2_fnc_commandMenuPush;
                }, { true }, "Signal friendly cells."],
                ["Exit", { closeDialog 0; }]
            ]];
        };
        case "east_reinforce": {
            _result set ["useRandomSubtitle", false];
            _result set ["subtitle", "Select the cell you're rallying." ];
            private _squads = [
                ["Militia Squad (12 Tokens)", "militia", 12, "Mixed militia with medic."],
                ["Sniper Squad (13 Tokens)", "sniper", 13, "Dedicated marksmen."],
                ["AT Squad (15 Tokens)", "at", 15, "Rocket squad ready for armor."],
                ["AA Squad (18 Tokens)", "aa", 18, "Surface-to-air team."],
                ["Elite Lambda Squad (20 Tokens)", "lambda", 20, "Top-tier Lambda operatives." ]
            ];
            private _buttons = [["Cancel", { [] call HL2_fnc_commandMenuPop; }, { true }]];
            {
                _x params ["_label", "_id", "_cost", "_tip"];
                private _entry = [
                    _label,
                    {
                        params ["_control", "_ctx", "_data"];
                        _data params ["_squadId", "_cost"];
                        if ([ _cost ] call HL2_fnc_attemptPurchase) then {
                            private _next = createHashMapFromArray [["side", _ctx getOrDefault ["side", east]], ["squad", _squadId], ["cost", _cost]];
                            ["east_insertion", _next] call HL2_fnc_commandMenuPush;
                            hintSilent "Resistance reinforcements inbound.";
                        };
                        [] call HL2_fnc_commandMenuRefresh;
                    },
                    { params ["_ctx", "_data"]; true },
                    _tip,
                    [_id, _cost]
                ];
                _buttons pushBack _entry;
            } forEach _squads;
            _result set ["buttons", _buttons];
        };
        case "east_insertion": {
            _result set ["useRandomSubtitle", false];
            _result set ["subtitle", "Pick their approach route." ];
            private _buttons = [
                ["Land Insertion", {
                    params ["_control", "_ctx", "_data"];
                    [_ctx, "land"] call HL2_fnc_sendReinforcementRequest;
                }],
                ["Air Insertion", {
                    params ["_control", "_ctx", "_data"];
                    [_ctx, "air"] call HL2_fnc_sendReinforcementRequest;
                }],
                ["Sea Insertion", {
                    params ["_control", "_ctx", "_data"];
                    [_ctx, "sea"] call HL2_fnc_sendReinforcementRequest;
                }],
                ["Cancel", { [] call HL2_fnc_commandMenuPop; }, { true }]
            ];
            _result set ["buttons", _buttons];
        };
        case "civ_main": {
            _result set ["buttons", [
                ["Request Mission", {
                    params ["_control", "_ctx", "_data"];
                    [civilian] call HL2_fnc_requestFactionMission;
                    hintSilent "CWU assignment request submitted.";
                }],
                ["Exit", { closeDialog 0; }]
            ]];
        };
        case "ind_main": {
            _result set ["buttons", [
                ["Request Mission", {
                    params ["_control", "_ctx", "_data"];
                    [independent] call HL2_fnc_requestFactionMission;
                    hintSilent "The whisper grows louder.";
                }],
                ["Exit", { closeDialog 0; }]
            ]];
        };
        default {
            _result set ["buttons", [["Exit", { closeDialog 0; }]]];
        };
    };

    _result
};
missionNamespace setVariable ["HL2_CommandMenu_Builder", HL2_fnc_commandMenuBuild];

HL2_fnc_sendReinforcementRequest = {
    params ["_context", "_method"];
    private _side = _context getOrDefault ["side", sideUnknown];
    private _squad = _context getOrDefault ["squad", ""];
    if (_squad isEqualTo "") exitWith {};
    [player, _side, _squad, _method] remoteExecCall ["HL2_fnc_dispatchReinforcements", 2];
    hintSilent "Insertion data transmitted.";
    [] call HL2_fnc_commandMenuPop;
};

HL2_fnc_openCommandMenu = {
    if (!hasInterface) exitWith {};
    if (!isNull findDisplay 9000) exitWith {};

    createDialog "HL2_CommandMenu";
    missionNamespace setVariable ["HL2_CommandMenu_Stack", []];

    private _side = side player;
    private _menuId = switch (_side) do {
        case west: { "west_main" };
        case east: { "east_main" };
        case civilian: { "civ_main" };
        case independent: { "ind_main" };
        default { "ind_main" };
    };
    private _context = createHashMapFromArray [["side", _side]];
    [_menuId, _context] call HL2_fnc_commandMenuPush;
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