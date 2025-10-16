publicVariable "Global_CID_Registry";
publicVariable "CID_Loyalty";
publicVariable "CID_Malcompliance";
publicVariable "AntiCitizen";
publicVariable "WasCitizen";
CID_Loyalty = createHashMap;
CID_Malcompliance = createHashMap;
[] execVM "xenAggroLoop.sqf";
[] execVM "randomEncounters.sqf";
[] execVM "rebelIncursion.sqf";
[] execVM "spawnLootSystem.sqf";
[] execVM "malcompliant.sqf";
[] execVM "wantedLevel.sqf";
[] execVM "qzones.sqf";
[] execVM "garrison.sqf";
[] execVM "merchants.sqf";
[] execVM "slums.sqf";
[] execVM "smuggler.sqf";
[] execVM "judgementWaiver.sqf";
[] execVM "quartermaster.sqf";
[] execVM "recruiter.sqf";
[] execVM "civies.sqf";
[] execVM "ota_functions.sqf";
[] execVM "sociostability.sqf";
[] execVM "infestation.sqf";
[] execVM "bank.sqf";
[] execVM "timeSkip.sqf";
[] execVM "endgame.sqf";
[] execVM "playerPersistence.sqf";
[] execVM "redacted.sqf";

if (isServer) then {
    {
        _x execVM "autoShieldDoor.sqf";
    } forEach (allMissionObjects "Combine_Shield_wall_F");
};

createVehicle ["Gravity_BeamGreen_Module", getMarkerPos "GravBeam", [], 0, "NONE"];

call compile preprocessFileLineNumbers "portalStorm.sqf";

if (isNil "Global_CID_Registry") then {
    Global_CID_Registry = [];
    publicVariable "Global_CID_Registry";
};

if (isNil "MRC_fnc_generateCID") then {
    MRC_fnc_generateCID = {
        if (isNil "Global_CID_Registry") then {
            Global_CID_Registry = [];
            publicVariable "Global_CID_Registry";
        };
        private _cid = -1;
        private _unique = false;
        while { !_unique } do {
            _cid = floor (random [1000, 9999, 9999]);
            _unique = !(_cid in Global_CID_Registry);
        };
        Global_CID_Registry pushBack _cid;
        publicVariable "Global_CID_Registry";
        _cid
    };
    publicVariable "MRC_fnc_generateCID";
};

if (isNil "MRC_fnc_assignCID") then {
    MRC_fnc_assignCID = {
        params ["_unit"];
        private _old = _unit getVariable ["CID_Number", nil];
        if (!isNil "_old") then {
            CID_Loyalty deleteAt _old;
            CID_Malcompliance deleteAt _old;
            if !(isNil "Global_CID_Registry") then {
                Global_CID_Registry = Global_CID_Registry - [_old];
                publicVariable "Global_CID_Registry";
            };
        };
        private _new = call MRC_fnc_generateCID;
        _unit setVariable ["CID_Number", _new, true];
        _unit setVariable ["HasCID", true, false];
        CID_Loyalty set [_new, 0];
        CID_Malcompliance set [_new, 0];
        _new
    };
    publicVariable "MRC_fnc_assignCID";
};

private _savedDate = profileNamespace getVariable ["SavedDate", []];
if !(_savedDate isEqualTo []) then {
    setDate _savedDate;
};

private _defaults = [
    ["RationStock", 10],
    ["Biomass", 5],
    ["PlasmaLevel", 5],
    ["Infestation", 50],
    ["Sociostability", 50],
    ["PortalStormTimer", 0]
];

{
    missionNamespace setVariable [
        _x select 0,
        profileNamespace getVariable [_x select 0, _x select 1],
        true
    ];
} forEach _defaults;

// === Persistence save loop ===
[] spawn {
    while {true} do {
        {
            profileNamespace setVariable [
                _x,
                missionNamespace getVariable [_x, 0]
            ];
        } forEach ["RationStock", "Biomass", "PlasmaLevel", "Infestation", "Sociostability"];
		profileNamespace setVariable ["SavedDate", date];
        saveProfileNamespace;
        sleep 30;
    };
};


[] spawn {
    while {true} do {
        private _timer = missionNamespace getVariable ["PortalStormTimer", 0];
        if (_timer <= 0) then {
            private _infestation = missionNamespace getVariable ["Infestation", 50];
            private _hours = (4 - (_infestation / 25)) max 0.5;
            private _interval = _hours * 3600;
            _timer = _interval + random (_interval * 0.25);
            missionNamespace setVariable ["PortalStormTimer", _timer, true];
        };
        while {_timer > 0} do {
            sleep 30;
            _timer = _timer - 30;
            missionNamespace setVariable ["PortalStormTimer", _timer, true];
        };
        [] spawn portalStorm_fnc_start;
        missionNamespace setVariable ["PortalStormTimer", 0, true];
    };
};

[] spawn {
    while {true} do {
        if (PlasmaLevel < 100) then {
            PlasmaLevel = PlasmaLevel + 1;
            publicVariable "PlasmaLevel";
        };
        sleep 300; 
    };
};

[] spawn {
    while {true} do {
        if (Biomass < 100) then {
            Biomass = Biomass + 1;
            publicVariable "Biomass";
        };
        sleep 300;
    };
};

// NPC ration distribution every hour
[] spawn {
    while {true} do {
        sleep 3600;

        private _stock = missionNamespace getVariable ["RationStock", 0];
        private _deduct = 5 + floor (random 11); // 5-15
        private _newStock = (_stock - _deduct) max 0;

        missionNamespace setVariable ["RationStock", _newStock, true];
    };
};

//garbagio cleanup
[] spawn {
    while {true} do {
        sleep 6600;

        // 5-minute warning
        ["Cleanup Warning: All corpses, wrecks, and loose items will be removed in 5 minutes."] remoteExec ["hint", 0];
        ["Cleanup Warning: All corpses, wrecks, and loose items will be removed in 5 minutes."] remoteExec ["systemChat", 0];

        // Wait another 5 minutes (300 seconds)
        sleep 300;

        // Perform cleanup
        {
            deleteVehicle _x;
        } forEach (
            allDeadMen +
            allDead +
            allMissionObjects "GroundWeaponHolder" +
            allMissionObjects "WeaponHolderSimulated" +
            allMissionObjects "WeaponHolder" +
            allMissionObjects "WeaponHolderAmmoBox"
        );

        {
            if (!alive _x && !isPlayer _x) then {
                deleteVehicle _x;
            };
        } forEach vehicles;

        // Notify players
        ["Cleanup complete. All corpses, wrecks, and items have been removed."] remoteExec ["hint", 0];
        ["Cleanup complete. All corpses, wrecks, and items have been removed."] remoteExec ["systemChat", 0];
    };
};

//  mission spawner
[] spawn {
    waitUntil {sleep 5; !isNil "allPlayers" && {count allPlayers > 0}};

    while {true} do {
        // Wait between missions (46 minutes, in case a side is idle so their missions don't pile up)
        private _delay = 2760;
        sleep _delay;

        // Run the mission selectors when idle
        if !(missionNamespace getVariable ["HL2_CombineMissionActive", false]) then {
            missionNamespace setVariable ["HL2_CombineMissionActive", true, true];
            private _handle = [] execVM "missionsCombine.sqf";
            ["Combine", _handle] call HL2_fnc_trackMissionCompletion;
        };
        if !(missionNamespace getVariable ["HL2_RebelMissionActive", false]) then {
            missionNamespace setVariable ["HL2_RebelMissionActive", true, true];
            private _handle = [] execVM "missionsRebels.sqf";
            ["Rebel", _handle] call HL2_fnc_trackMissionCompletion;
        };
        if !(missionNamespace getVariable ["HL2_CivilianMissionActive", false]) then {
            missionNamespace setVariable ["HL2_CivilianMissionActive", true, true];
            private _handle = [] execVM "missionsCivilians.sqf";
            ["Civilian", _handle] call HL2_fnc_trackMissionCompletion;
        };
    };
};

        if (!alive _heli) exitWith {
            ["Recon flight lost before reaching the target area."] remoteExec ["systemChat", _req];
            [_grp, _heli] call _cleanup;
        };

        if (isNull _req || { !alive _req }) exitWith {
            [_grp, _heli] call _cleanup;
        };

        if (!_reached) exitWith {
            [_grp, _heli] call _cleanup;
        };

        sleep 5;

        private _scanPos = getPosATL _req;
        private _sideReq = side _req;
        private _enemies = allUnits select {
            alive _x && {_x distance2D _scanPos <= 2000} && { side _x getFriend _sideReq < 0.6 }
        };

        if (_enemies isEqualTo []) then {
            ["Recon flight reports no hostiles within 2 km."] remoteExec ["systemChat", _req];
        } else {
            {
                private _pos = getPosATL _x;
                private _dist = round (_pos distance2D _scanPos);
                private _dir = round ([_scanPos, _pos] call BIS_fnc_dirTo);
                private _name = if (isPlayer _x) then { name _x } else { getText (configFile >> "CfgVehicles" >> typeOf _x >> "displayName") };
                [format ["Recon spots %1 at %2 m, bearing %3°.", _name, _dist, _dir]] remoteExec ["systemChat", _req];
            } forEach _enemies;
        };

        private _exitPos = [_scanPos, 1500, random 360] call BIS_fnc_relPos;
        _grp move _exitPos;
        _heli move _exitPos;

        sleep 30;

        [_grp, _heli] call _cleanup;
    };

    ["Recon flight dispatched."] remoteExec ["systemChat", _requester];
};
publicVariable "HL2_fnc_launchRecon";


// === Dynamic Civ Mission: Assemble & Deliver Rations ===
// Triggers every 30 sec if RationStock < 5, creates a CIVILIAN task at marker "rfactory".
// Task completes automatically when RationStock >= 10.

if (isServer) then {
    // Track whether the mission is currently active
    if (isNil "civRationMissionActive") then {
        civRationMissionActive = false;
        publicVariable "civRationMissionActive";
    };

    [] spawn {
        while {true} do {
            sleep 30;

            private _stock = missionNamespace getVariable ["RationStock", 0];
            if (_stock < 5 && {!civRationMissionActive}) then {
                civRationMissionActive = true; publicVariable "civRationMissionActive";

                // Broadcast the situation
                ["Citizen notice: failure to cooperate will result in permanent off-world relocation."] remoteExec ["systemChat", 0];
                ["Ftrainstationoffworldrelocationspkr"] remoteExec ["playSound", 0];

                // Create/assign the civilian task at the factory marker
                private _pos    = getMarkerPos "rfactory";
                private _taskId = format ["task_civ_rations_%1", diag_tickTime];

                [civilian, _taskId,
                    ["Attention Citizens: Ration Production is below quota. Report to the Ration Factory in District 3 and begin assembling rations. Restock Biomass as needed. Scavenge, if needed. Take the assembled rations and deliver them to the Ration Distribution Center in District 1, to the warehouse terminal on the left.",
                     "Assemble and Deliver Rations", ""],
                    _pos, true
                ] call BIS_fnc_taskCreate;

                // Monitor for success (RationStock >= 10), then wrap up
                [_taskId] spawn {
                    params ["_taskId"];
                    waitUntil {
                        sleep 5;
                        (missionNamespace getVariable ["RationStock", 0]) >= 10
                    };

                    [_taskId, "SUCCEEDED", true] call BIS_fnc_taskSetState;
                    ["Ration target met. Thank you for your cooperation."] remoteExec ["systemChat", 0];

                    sleep 10;
                    [_taskId] call BIS_fnc_deleteTask;

                    civRationMissionActive = false; publicVariable "civRationMissionActive";
                };
            };
        };
    };
};

// weird workarounds
[] spawn {
    while {true} do {
        {
            _x allowDamage true;
        } forEach allPlayers;
        sleep 5;
    };
};

[] spawn {
    while {true} do {
        {
            if (count units _x == 0) then {
                deleteGroup _x;
            };
        } forEach allGroups;
    sleep 30;
    }
}
HL2_fnc_prepareMissionRequest = {
    params ["_key", "_count", "_caller"];

    private _activeVar = format ["HL2_%1MissionActive", _key];
    if (missionNamespace getVariable [_activeVar, false]) exitWith {
        [format ["A %1 mission is already active.", _key]] remoteExec ["hintSilent", _caller];
        -1
    };

    private _cooldownVar = format ["HL2_%1MissionCooldown", _key];
    private _cooldown = missionNamespace getVariable [_cooldownVar, 0];
    if (time < _cooldown) exitWith {
        private _remaining = ceil (((_cooldown - time) / 60) max 1);
        [format ["Command is busy. Try again in %1 minute(s).", _remaining]] remoteExec ["hintSilent", _caller];
        -1
    };

    private _lastVar = format ["HL2_%1MissionLast", _key];
    private _last = missionNamespace getVariable [_lastVar, -1];

    private _pool = [];
    for "_i" from 1 to _count do { _pool pushBack _i; };
    if ((_pool find _last) >= 0 && { count _pool > 1 }) then {
        _pool = _pool - [_last];
    };

    if (_pool isEqualTo []) exitWith {
        ["No missions available right now."] remoteExec ["hintSilent", _caller];
        -1
    };

    private _choice = selectRandom _pool;

    missionNamespace setVariable [_lastVar, _choice, true];
    missionNamespace setVariable [_cooldownVar, time + 900, true];
    missionNamespace setVariable [format ["HL2_%1_ForcedIndex", _key], _choice, true];
    missionNamespace setVariable [_activeVar, true, true];

    _choice
};

HL2_fnc_trackMissionCompletion = {
    params ["_key", "_handle"];
    [_key, _handle] spawn {
        params ["_key", "_handle"];
        waitUntil {
            sleep 5;
            scriptDone _handle
        };
        missionNamespace setVariable [format ["HL2_%1MissionActive", _key], false, true];
        missionNamespace setVariable [format ["HL2_%1_ForcedIndex", _key], -1, true];
    };
};

TAG_fnc_requestCombineMission = {
    params ["_caller"];
    private _choice = ["Combine", 5, _caller] call HL2_fnc_prepareMissionRequest;
    if (_choice < 0) exitWith {};
    private _handle = [] execVM "missionsCombine.sqf";
    ["Combine", _handle] call HL2_fnc_trackMissionCompletion;
    ["Overwatch acknowledges your request."] remoteExec ["hintSilent", _caller];
};

TAG_fnc_requestRebelsMission = {
    params ["_caller"];
    private _choice = ["Rebel", 5, _caller] call HL2_fnc_prepareMissionRequest;
    if (_choice < 0) exitWith {};
    private _handle = [] execVM "missionsRebels.sqf";
    ["Rebel", _handle] call HL2_fnc_trackMissionCompletion;
    ["LambdaNet has queued your assignment."] remoteExec ["hintSilent", _caller];
};

TAG_fnc_requestCivMission = {
    params ["_caller"];
    private _choice = ["Civilian", 4, _caller] call HL2_fnc_prepareMissionRequest;
    if (_choice < 0) exitWith {};
    private _handle = [] execVM "missionsCivilians.sqf";
    ["Civilian", _handle] call HL2_fnc_trackMissionCompletion;
    ["CWU dispatch received your paperwork."] remoteExec ["hintSilent", _caller];
};

TAG_fnc_requestCultMission = {
    params ["_caller"];
    private _choice = ["Cult", 3, _caller] call HL2_fnc_prepareMissionRequest;
    if (_choice < 0) exitWith {};
    private _handle = [] execVM "missionsCult.sqf";
    ["Cult", _handle] call HL2_fnc_trackMissionCompletion;
    ["The Veil stirs at your summons."] remoteExec ["hintSilent", _caller];
};

HL2_fnc_setCombineLoadout = {
    params ["_unit", "_squadId"];
    switch (_squadId) do {
        case "riot": {
            removeAllWeapons _unit;
            removeAllItems _unit;
            removeAllAssignedItems _unit;
            removeUniform _unit;
            removeHeadgear _unit;
            _unit forceAddUniform "Z_C18_Uniform_4";
            _unit addHeadgear "H_SM_OVSMask2";
            for "_i" from 1 to 4 do { _unit addMagazine "30Rnd_556x45_Stanag_Tracer_Blue"; };
            _unit addWeapon "hlc_rifle_416D10C";
            _unit setSkill 0.7;
        };
        case "demo": {
            removeAllWeapons _unit;
            removeAllItems _unit;
            removeAllAssignedItems _unit;
            removeUniform _unit;
            removeHeadgear _unit;
            _unit forceAddUniform "U_C18_Uniform_6";
            _unit addHeadgear "H_SM_BlackMask_2";
            for "_i" from 1 to 4 do { _unit addMagazine "30Rnd_556x45_Stanag_Tracer_Blue"; };
            _unit addWeapon "hlc_rifle_416D10C";
            _unit addMagazine "ace_Missile_manpad_stinger_man";
            _unit addWeapon "launch_B_Titan_F";
            _unit setSkill 0.7;
        };
        case "overwatch": {
            _unit setSkill 1;
        };
    };
};

HL2_fnc_finalizeCombineGroup = {
    params ["_group", "_squadId"];
    if (_squadId isEqualTo "conscript") then {
        {
            private _class = typeOf _x;
            if (_class in ["WBK_HECU_Medic", "WBK_HECU_Sniper"]) then {
                removeUniform _x;
                _x forceAddUniform "U_BDU_Raid_od7_knee";
            };
        } forEach units _group;
    };
    if (_squadId isEqualTo "riot") then {
        { [_x, "riot"] call HL2_fnc_setCombineLoadout; } forEach units _group;
    };
    if (_squadId isEqualTo "demo") then {
        { [_x, "demo"] call HL2_fnc_setCombineLoadout; } forEach units _group;
    };
    if (_squadId isEqualTo "overwatch") then {
        { [_x, "overwatch"] call HL2_fnc_setCombineLoadout; } forEach units _group;
    };
    _group setBehaviour "AWARE";
    _group setCombatMode "YELLOW";
    _group setSpeedMode "NORMAL";
};

HL2_fnc_selectCombineClasses = {
    params ["_squadId"];
    switch (_squadId) do {
        case "patrol": { ["WBK_Combine_CP_SMG","WBK_Combine_CP_SMG","WBK_Combine_CP_SMG","WBK_Combine_CP_SMG","WBK_Combine_CP_P"] };
        case "conscript": { ["WBK_HL_Conscript_4","WBK_HL_Conscript_6","WBK_HL_Conscript_3","WBK_HL_Conscript_1","WBK_HECU_Medic","WBK_HECU_Sniper"] };
        case "riot": { ["WBK_Combine_CP_SMG","WBK_Combine_CP_SMG","WBK_Combine_CP_SMG","WBK_Combine_CP_SMG","WBK_Combine_CP_SMG","WBK_Combine_CP_SMG"] };
        case "demo": { ["WBK_Combine_CP_SMG","WBK_Combine_CP_SMG","WBK_Combine_CP_SMG","WBK_Combine_CP_SMG"] };
        case "overwatch": { ["WBK_Combine_Ordinal","WBK_Combine_APF","WBK_Combine_Walhammer","WBK_Combine_ASS_Sniper","WBK_Combine_HL2_Type","WBK_Combine_HL2_Type_AR"] };
        default { [] };
    }
};

HL2_fnc_spawnCombineSupport = {
    params ["_requester", "_squadId", "_method"];

    if (!isServer) exitWith {};
    if (isNull _requester) exitWith {};

    private _classes = [_squadId] call HL2_fnc_selectCombineClasses;
    if (_classes isEqualTo []) exitWith {};

    private _nexusPos = getMarkerPos "nexus";
    if (_nexusPos isEqualTo [0,0,0]) then { _nexusPos = getPosATL _requester; };

    private _target = getPosATL _requester;
    private _distance = _target distance2D _nexusPos;
    private _spawnAnchor = _nexusPos;
    if (_distance > 1000) then {
        _spawnAnchor = [_nexusPos, 1000, _nexusPos getDir _target] call BIS_fnc_relPos;
    };

    private _group = createGroup west;
    private _spawnPos = _spawnAnchor;
    private _vehicle = objNull;

    switch (_method) do {
        case "land": {
            _spawnPos = [_spawnAnchor, 50, 250, 5, 0, 0.6, 0] call BIS_fnc_findSafePos;
            if (_spawnPos isEqualTo []) then { _spawnPos = _spawnAnchor; };
            _vehicle = createVehicle ["GT_APC", _spawnPos, [], 0, "NONE"];
            _vehicle setDir (_spawnAnchor getDir _target);
            _vehicle setVehicleLock "UNLOCKED";
        };
        case "air": {
            _spawnPos = [_spawnAnchor, 0, 200, 0, 0, 40, 0] call BIS_fnc_findSafePos;
            if (_spawnPos isEqualTo []) then { _spawnPos = _spawnAnchor; };
            _vehicle = createVehicle ["B_Heli_Light_01_F", _spawnPos, [], 0, "FLY"];
            _vehicle setPosASL [(_spawnPos select 0), (_spawnPos select 1), 120];
            _vehicle setDir (_spawnAnchor getDir _target);
            _vehicle flyInHeight 80;
        };
        case "sea": {
            _spawnPos = [_spawnAnchor, 0, 2000, 0, 2, 20, 0] call BIS_fnc_findSafePos;
            if (_spawnPos isEqualTo []) then { _spawnPos = _spawnAnchor; };
            _vehicle = createVehicle ["I_C_Boat_Transport_02_F", _spawnPos, [], 0, "NONE"];
            _vehicle setDir (_spawnAnchor getDir _target);
        };
    };

    private _units = [];
    {
        private _unit = _group createUnit [_x, _spawnPos, [], 0, "FORM"];
        _units pushBack _unit;
    } forEach _classes;

    [_group, _squadId] call HL2_fnc_finalizeCombineGroup;

    private _leader = leader _group;

    switch (_method) do {
        case "land": {
            if (!isNull _vehicle) then {
                _leader assignAsDriver _vehicle;
                _leader moveInDriver _vehicle;
                {
                    if (_x != _leader) then {
                        _x assignAsCargo _vehicle;
                        _x moveInCargo _vehicle;
                    };
                } forEach _units;
                [_group, _vehicle, _requester] spawn {
                    params ["_grp", "_veh", "_req"];
                    private _lastKnown = getPosATL _req;
                    while { alive _veh && { !isNull _req } && { alive _req } } do {
                        _lastKnown = getPosATL _req;
                        _veh doMove _lastKnown;
                        if ((_veh distance2D _lastKnown) < 120) exitWith {};
                        sleep 5;
                    };
                    if (!alive _veh) exitWith {};
                    {
                        unassignVehicle _x;
                        doGetOut _x;
                    } forEach units _grp;
                    waitUntil {
                        sleep 1;
                        ({ vehicle _x == _x } count units _grp) == { alive _x } count units _grp
                    };
                    private _dest = if (!isNull _req && { alive _req }) then { getPosATL _req } else { _lastKnown };
                    { if (alive _x) then { _x doMove _dest; }; } forEach units _grp;
                };
            };
        };
        case "air": {
            if (!isNull _vehicle) then {
                {
                    _x assignAsCargo _vehicle;
                    _x moveInCargo _vehicle;
                } forEach _units;
                private _pilotGrp = createGroup west;
                private _pilot = _pilotGrp createUnit ["B_Helipilot_F", _spawnPos, [], 0, "FORM"];
                _pilot assignAsDriver _vehicle;
                _pilot moveInDriver _vehicle;
                _pilotGrp setBehaviour "AWARE";
                [_pilotGrp, _vehicle, _group, _requester] spawn {
                    params ["_pilotGrp", "_heli", "_sq", "_req"];
                    private _targetPos = getPosATL _req;
                    _pilotGrp move _targetPos;
                    _heli move _targetPos;
                    private _landed = false;
                    while { alive _heli && { !isNull _req } && { alive _req } } do {
                        _targetPos = getPosATL _req;
                        _pilotGrp move _targetPos;
                        _heli move _targetPos;
                        if ((_heli distance2D _targetPos) < 120) exitWith { _landed = true; };
                        sleep 2;
                    };
                    if (!_landed || {!alive _heli}) exitWith {
                        if (!isNull _pilotGrp) then { deleteGroup _pilotGrp; };
                    };
                    _heli land "GET OUT";
                    sleep 5;
                    {
                        unassignVehicle _x;
                        doGetOut _x;
                    } forEach units _sq;
                    waitUntil {
                        sleep 1;
                        ({ vehicle _x == _x } count units _sq) == { alive _x } count units _sq
                    };
                    private _dest = if (!isNull _req && { alive _req }) then { getPosATL _req } else { _targetPos };
                    { if (alive _x) then { _x doMove _dest; }; } forEach units _sq;
                    sleep 5;
                    private _escape = [_dest, 5000, random 360] call BIS_fnc_relPos;
                    _pilotGrp move _escape;
                    _heli move _escape;
                    sleep 30;
                    { deleteVehicle _x; } forEach crew _heli;
                    deleteVehicle _heli;
                    deleteGroup _pilotGrp;
                };
            };
        };
        case "sea": {
            if (!isNull _vehicle) then {
                _leader assignAsDriver _vehicle;
                _leader moveInDriver _vehicle;
                {
                    if (_x != _leader) then {
                        _x assignAsCargo _vehicle;
                        _x moveInCargo _vehicle;
                    };
                } forEach _units;
                [_group, _vehicle, _requester] spawn {
                    params ["_grp", "_boat", "_req"];
                    private _lastKnown = getPosATL _req;
                    private _disembark = [_lastKnown, 0, 3000, 0, 2, 20, 0] call BIS_fnc_findSafePos;
                    if (_disembark isEqualTo []) then { _disembark = _lastKnown; };
                    while { alive _boat && { !isNull _req } && { alive _req } } do {
                        _lastKnown = getPosATL _req;
                        _disembark = [_lastKnown, 0, 3000, 0, 2, 20, 0] call BIS_fnc_findSafePos;
                        if (_disembark isEqualTo []) then { _disembark = _lastKnown; };
                        _boat move _disembark;
                        if ((_boat distance2D _disembark) < 80) exitWith {};
                        sleep 4;
                    };
                    if (!alive _boat) exitWith {};
                    {
                        unassignVehicle _x;
                        doGetOut _x;
                    } forEach units _grp;
                    waitUntil {
                        sleep 1;
                        ({ vehicle _x == _x } count units _grp) == { alive _x } count units _grp
                    };
                    private _dest = if (!isNull _req && { alive _req }) then { getPosATL _req } else { _lastKnown };
                    { if (alive _x) then { _x doMove _dest; }; } forEach units _grp;
                };
            };
        };
    };
};

HL2_fnc_selectRebelClasses = {
    params ["_squadId"];
    switch (_squadId) do {
        case "militia": { ["WBK_Rebel_Sniper","WBK_Rebel_SMG_1","WBK_Rebel_Rifleman_1","WBK_Rebel_Medic_1","O_G_engineer_F"] };
        case "sniper": { ["UU_Sniper","UU_Sniper","UU_Sniper","WBK_Rebel_Sniper","WBK_Rebel_Sniper"] };
        case "at": { ["WBK_Rebel_HL2_RPG","WBK_Rebel_HL2_RPG","WBK_Rebel_HL2_RPG","WBK_Rebel_HL2_RPG"] };
        case "aa": { ["WBK_Rebel_HL2_RPG","WBK_Rebel_HL2_RPG","WBK_Rebel_HL2_RPG","WBK_Rebel_HL2_RPG"] };
        case "lambda": { ["WBK_Rebel_HL2_SquadLead_2","WBK_Rebel_HL2_RIFLEMAN_1","WBK_Rebel_HL2_SMG_3","WBK_Rebel_HL2_RPG","UU_CP_HeavySMG","Jungle_Jungle_Medic_Hazmat"] };
        default { [] };
    }
};

HL2_fnc_finalizeRebelGroup = {
    params ["_group", "_squadId"];
    if (_squadId isEqualTo "aa") then {
        {
            private _sec = secondaryWeapon _x;
            if (_sec != "") then { _x removeWeapon _sec; };
            removeBackpack _x;
            removeAllWeapons _x;
            removeAllItems _x;
            removeAllAssignedItems _x;
            private _uniform = uniform _x;
            if (_uniform == "") then { _x forceAddUniform "U_BG_Guerilla2_3"; } else { _x forceAddUniform _uniform; };
            _x addWeapon "launch_B_Titan_F";
            for "_i" from 1 to 4 do { _x addMagazine "AA_Titan"; };
            _x addWeapon "arifle_TRG21_F";
            for "_i" from 1 to 3 do { _x addMagazine "30Rnd_556x45_Stanag"; };
        } forEach units _group;
    };
    if (_squadId isEqualTo "lambda") then {
        { _x setSkill 1; } forEach units _group;
    };
    _group setBehaviour "AWARE";
    _group setCombatMode "YELLOW";
    _group setSpeedMode "NORMAL";
};

HL2_fnc_spawnRebelSupport = {
    params ["_requester", "_squadId", "_method"];

    if (!isServer) exitWith {};
    if (isNull _requester) exitWith {};

    private _classes = [_squadId] call HL2_fnc_selectRebelClasses;
    if (_classes isEqualTo []) exitWith {};

    private _group = createGroup east;
    private _target = getPosATL _requester;
    private _distance = 3000 + random 2000;
    private _spawnPos = [_target, _distance, random 360] call BIS_fnc_relPos;
    private _vehicle = objNull;

    switch (_method) do {
        case "land": {
            _spawnPos = [_target, _distance, 5000, 5, 0, 0.6, 0] call BIS_fnc_findSafePos;
            if (_spawnPos isEqualTo []) then { _spawnPos = [_target, _distance, random 360] call BIS_fnc_relPos; };
            _vehicle = createVehicle ["C_Offroad_01_F", _spawnPos, [], 0, "NONE"];
            _vehicle setDir (_spawnPos getDir _target);
        };
        case "air": {
            _vehicle = createVehicle ["B_Heli_Light_01_F", _spawnPos, [], 0, "FLY"];
            _vehicle setPosASL [(_spawnPos select 0), (_spawnPos select 1), 150];
            _vehicle setDir (_spawnPos getDir _target);
            _vehicle flyInHeight 100;
        };
        case "sea": {
            _spawnPos = [_target, _distance, 5000, 0, 2, 20, 0] call BIS_fnc_findSafePos;
            if (_spawnPos isEqualTo []) then { _spawnPos = [_target, _distance, random 360] call BIS_fnc_relPos; };
            _vehicle = createVehicle ["I_C_Boat_Transport_02_F", _spawnPos, [], 0, "NONE"];
            _vehicle setDir (_spawnPos getDir _target);
        };
    };

    private _units = [];
    {
        private _unit = _group createUnit [_x, _spawnPos, [], 0, "FORM"];
        _units pushBack _unit;
    } forEach _classes;

    [_group, _squadId] call HL2_fnc_finalizeRebelGroup;

    private _leader = leader _group;

    switch (_method) do {
        case "land": {
            if (!isNull _vehicle) then {
                _leader assignAsDriver _vehicle;
                _leader moveInDriver _vehicle;
                {
                    if (_x != _leader) then {
                        _x assignAsCargo _vehicle;
                        _x moveInCargo _vehicle;
                    };
                } forEach _units;
                [_group, _vehicle, _requester] spawn {
                    params ["_grp", "_veh", "_req"];
                    private _lastKnown = getPosATL _req;
                    while { alive _veh && { !isNull _req } && { alive _req } } do {
                        _lastKnown = getPosATL _req;
                        _veh doMove _lastKnown;
                        if ((_veh distance2D _lastKnown) < 120) exitWith {};
                        sleep 5;
                    };
                    if (!alive _veh) then {
                        [_grp, _req] call HL2_fnc_rebelJoinOnFoot;
                    } else {
                        {
                            unassignVehicle _x;
                            doGetOut _x;
                        } forEach units _grp;
                        [_grp, _req] call HL2_fnc_rebelJoinOnFoot;
                    };
                };
            };
        };
        case "air": {
            if (!isNull _vehicle) then {
                {
                    _x assignAsCargo _vehicle;
                    _x moveInCargo _vehicle;
                } forEach _units;
                private _pilotGrp = createGroup east;
                private _pilot = _pilotGrp createUnit ["O_Helipilot_F", _spawnPos, [], 0, "FORM"];
                _pilot assignAsDriver _vehicle;
                _pilot moveInDriver _vehicle;
                [_pilotGrp, _vehicle, _group, _requester] spawn {
                    params ["_pilotGrp", "_heli", "_sq", "_req"];
                    private _targetPos = getPosATL _req;
                    while { alive _heli && { !isNull _req } && { alive _req } } do {
                        _targetPos = getPosATL _req;
                        _pilotGrp move _targetPos;
                        _heli move _targetPos;
                        if ((_heli distance2D _targetPos) < 120) exitWith {};
                        sleep 2;
                    };
                    if (!alive _heli) exitWith {
                        [_sq, _req] call HL2_fnc_rebelJoinOnFoot;
                        if (!isNull _pilotGrp) then { deleteGroup _pilotGrp; };
                    };
                    _heli land "GET OUT";
                    sleep 5;
                    {
                        unassignVehicle _x;
                        doGetOut _x;
                    } forEach units _sq;
                    [_sq, _req] call HL2_fnc_rebelJoinOnFoot;
                    sleep 5;
                    private _escape = [_targetPos, 5000, random 360] call BIS_fnc_relPos;
                    _pilotGrp move _escape;
                    _heli move _escape;
                    sleep 30;
                    { deleteVehicle _x; } forEach crew _heli;
                    deleteVehicle _heli;
                    deleteGroup _pilotGrp;
                };
            };
        };
        case "sea": {
            if (!isNull _vehicle) then {
                _leader assignAsDriver _vehicle;
                _leader moveInDriver _vehicle;
                {
                    if (_x != _leader) then {
                        _x assignAsCargo _vehicle;
                        _x moveInCargo _vehicle;
                    };
                } forEach _units;
                [_group, _vehicle, _requester] spawn {
                    params ["_grp", "_boat", "_req"];
                    private _lastKnown = getPosATL _req;
                    private _water = [_lastKnown, 0, 500, 0, 2, 20, 0] call BIS_fnc_findSafePos;
                    if (_water isEqualTo []) then { _water = _lastKnown; };
                    while { alive _boat && { !isNull _req } && { alive _req } } do {
                        _lastKnown = getPosATL _req;
                        _water = [_lastKnown, 0, 500, 0, 2, 20, 0] call BIS_fnc_findSafePos;
                        if (_water isEqualTo []) then { _water = _lastKnown; };
                        _boat move _water;
                        if ((_boat distance2D _water) < 80) exitWith {};
                        sleep 4;
                    };
                    if (!alive _boat) then {
                        [_grp, _req] call HL2_fnc_rebelJoinOnFoot;
                    } else {
                        {
                            unassignVehicle _x;
                            doGetOut _x;
                        } forEach units _grp;
                        [_grp, _req] call HL2_fnc_rebelJoinOnFoot;
                    };
                };
            };
        };
    };
};

HL2_fnc_rebelJoinOnFoot = {
    params ["_group", "_requester"];
    private _targetGroup = if (!isNull _requester) then { group _requester } else { createGroup east };
    if (isNull _targetGroup) then { _targetGroup = createGroup east; };
    if (!isNull _requester && { isNull group _requester }) then {
        [_requester] joinSilent _targetGroup;
    };
    private _dest = if (!isNull _requester) then { getPosATL _requester } else { [0,0,0] };
    {
        if (alive _x) then {
            [_x] joinSilent _targetGroup;
            if (!(_dest isEqualTo [0,0,0])) then { _x doMove _dest; };
        };
    } forEach units _group;
    deleteGroup _group;
};

HL2_fnc_dispatchReinforcements = {
    params ["_requester", "_side", "_squadId", "_method"];
    if (!isServer) exitWith {};
    if (isNull _requester) exitWith {};
    if (!alive _requester) exitWith {};

    switch (_side) do {
        case west: { [_requester, _squadId, _method] call HL2_fnc_spawnCombineSupport; };
        case east: { [_requester, _squadId, _method] call HL2_fnc_spawnRebelSupport; };
    };
};
publicVariable "HL2_fnc_dispatchReinforcements";