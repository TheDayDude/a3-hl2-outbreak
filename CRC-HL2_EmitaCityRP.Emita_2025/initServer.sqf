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

        // Run the mission selectors
        [] execVM "missionsCombine.sqf";
		[] execVM "missionsRebels.sqf";
		[] execVM "missionsCivilians.sqf";
    };
};

// Server-side mission request handler
TAG_fnc_requestCivMission = {
    params ["_caller"];

    private _last = missionNamespace getVariable ["lastMissionRequestCivilian", -99999];

    if (time - _last < 900) exitWith {
        ["No missions ready. Come back later."] remoteExec ["hintSilent", _caller];
    };

    missionNamespace setVariable ["lastMissionRequestCivilian", time, true];

    // run the mission script on the server
    [] execVM "missionsCivilians.sqf";

};

// Server-side mission request handler
TAG_fnc_requestRebelsMission = {
    params ["_caller"];

    private _last = missionNamespace getVariable ["lastMissionRequestRebels", -99999];

    if (time - _last < 900) exitWith {
        ["No missions ready. Come back later."] remoteExec ["hintSilent", _caller];
    };

    missionNamespace setVariable ["lastMissionRequestRebels", time, true];

    // run the mission script on the server
    [] execVM "missionsRebels.sqf";

};

TAG_fnc_requestCombineMission = {
    params ["_caller"];

    private _last = missionNamespace getVariable ["lastMissionRequestCombine", -99999];

    if (time - _last < 900) exitWith {
        ["No missions ready. Come back later."] remoteExec ["hintSilent", _caller];
    };

    missionNamespace setVariable ["lastMissionRequestCombine", time, true];

    // run the mission script on the server
    [] execVM "missionsCombine.sqf";

};

HL2_fnc_spawnReinforcements = {
    params ["_requester", "_initialPos"];

    if (!isServer) exitWith {};
    if (isNull _requester) exitWith {};

    private _side = side _requester;
    if !(_side in [west, east]) exitWith {};

    private _spawnPos = [_initialPos, 2000, 5000, 5, 0, 20, 0] call BIS_fnc_findSafePos;
    if (_spawnPos isEqualTo []) then {
        _spawnPos = [_initialPos, 2000 + random 2000, random 360] call BIS_fnc_relPos;
    };

    private _vehicleClass = if (_side isEqualTo west) then { "B_MRAP_01_F" } else { "O_G_Offroad_01_F" };
    private _driverClass = if (_side isEqualTo west) then { "B_Soldier_F" } else { "O_G_Soldier_F" };
    private _passengerClasses = if (_side isEqualTo west) then {
        ["B_Soldier_GL_F", "B_Soldier_AR_F", "B_medic_F"]
    } else {
        ["O_G_Soldier_GL_F", "O_G_Soldier_AR_F", "O_G_medic_F"]
    };

    private _group = createGroup _side;
    private _vehicle = createVehicle [_vehicleClass, _spawnPos, [], 0, "NONE"];
    _vehicle setDir random 360;
    _vehicle setVehicleLock "UNLOCKED";

    private _driver = _group createUnit [_driverClass, _spawnPos, [], 0, "FORM"];
    _driver assignAsDriver _vehicle;
    _driver moveInDriver _vehicle;

    {
        private _unit = _group createUnit [_x, _spawnPos, [], 0, "FORM"];
        _unit assignAsCargo _vehicle;
        _unit moveInCargo _vehicle;
    } forEach _passengerClasses;

    _group setBehaviour "AWARE";
    _group setCombatMode "YELLOW";
    _group setSpeedMode "NORMAL";

    [_group, _vehicle, _requester] spawn {
        params ["_grp", "_veh", "_req"];

        private _reached = false;
        while { alive _veh && {!isNull _req} && { alive _req } } do {
            private _dest = getPosATL _req;
            { _x doMove _dest; } forEach units _grp;
            _veh doMove _dest;

            if ((_veh distance2D _dest) < 120) exitWith { _reached = true; };
            sleep 5;
        };

        if (!alive _veh) exitWith {
            ["Reinforcements were lost before reaching you."] remoteExec ["systemChat", _req];
        };

        if (isNull _req || { !alive _req }) exitWith {};
        if (!_reached) exitWith {};

        {
            unassignVehicle _x;
            doGetOut _x;
        } forEach units _grp;

        waitUntil {
            sleep 1;
            ({ vehicle _x == _x } count units _grp) == { alive _x } count units _grp
        };

        {
            if (alive _x) then {
                [_x] joinSilent (group _req);
            };
        } forEach units _grp;

        deleteVehicle _veh;
        deleteGroup _grp;
        ["Reinforcements have joined your squad."] remoteExec ["systemChat", _req];
    };
};
publicVariable "HL2_fnc_spawnReinforcements";


HL2_fnc_launchRecon = {
    params ["_requester", "_initialPos"];

    if (!isServer) exitWith {};
    if (isNull _requester) exitWith {};

    private _side = side _requester;
    if !(_side in [west, east]) exitWith {};

    private _spawnPos = [_initialPos, 2000, 5000, 0, 0, 50, 0] call BIS_fnc_findSafePos;
    if (_spawnPos isEqualTo []) then {
        _spawnPos = [_initialPos, 2000 + random 2000, random 360] call BIS_fnc_relPos;
    };

    private _heliClass = if (_side isEqualTo west) then { "B_Heli_Light_01_F" } else { "O_Heli_Light_02_unarmed_F" };
    private _pilotClass = if (_side isEqualTo west) then { "B_Helipilot_F" } else { "O_Helipilot_F" };

    private _grp = createGroup _side;
    private _heli = createVehicle [_heliClass, _spawnPos, [], 0, "FLY"];
    _heli setPosASL [(_spawnPos select 0), (_spawnPos select 1), 120];
    _heli setDir random 360;
    _heli flyInHeight 120;

    private _pilot = _grp createUnit [_pilotClass, _spawnPos, [], 0, "FORM"];
    _pilot assignAsDriver _heli;
    _pilot moveInDriver _heli;

    _grp setBehaviour "CARELESS";
    _grp setSpeedMode "LIMITED";

    [_grp, _heli, _requester] spawn {
        params ["_grp", "_heli", "_req"];

        private _cleanup = {
            params ["_grpC", "_heliC"];
            if (!isNull _heliC) then {
                { deleteVehicle _x; } forEach crew _heliC;
                deleteVehicle _heliC;
            };
            if (!isNull _grpC) then {
                deleteGroup _grpC;
            };
        };

        private _timeout = time + 300;
        private _reached = false;
        while { time < _timeout && { alive _heli } && { !isNull _req } && { alive _req } } do {
            private _dest = getPosATL _req;
            _grp move _dest;
            _heli move _dest;

            if ((_heli distance2D _dest) < 200) exitWith { _reached = true; };
            sleep 3;
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