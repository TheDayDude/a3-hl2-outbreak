publicVariable "Global_CID_Registry";
publicVariable "CID_Loyalty";
publicVariable "CID_Malcompliance";
publicVariable "AntiCitizen";
publicVariable "WasCitizen";
CID_Loyalty = createHashMap;
CID_Malcompliance = createHashMap;
[] execVM "xenAggroLoop.sqf";
[] execVM "outlandsThreatSpawner.sqf";
[] execVM "rebelIncursion.sqf";
[] execVM "spawnLootSystem.sqf";
[] execVM "malcompliant.sqf";
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
    ["Sociostability", 50]
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
        private _infestation = missionNamespace getVariable ["Infestation", 50];
        private _hours = (4 - (_infestation / 25)) max 0.5;
        private _interval = _hours * 3600;
        private _delay = _interval + random (_interval * 0.25);
        sleep _delay;
        [] spawn portalStorm_fnc_start;
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

//garbagio cleanup
[] spawn {
    while {true} do {
        // Wait 55 minutes (6600 seconds)
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

    if (time - _last < 1200) exitWith {
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

    if (time - _last < 1200) exitWith {
        ["No missions ready. Come back later."] remoteExec ["hintSilent", _caller];
    };

    missionNamespace setVariable ["lastMissionRequestRebels", time, true];

    // run the mission script on the server
    [] execVM "missionsRebels.sqf";

};

TAG_fnc_requestCombineMission = {
    params ["_caller"];

    private _last = missionNamespace getVariable ["lastMissionRequestCombine", -99999];

    if (time - _last < 1200) exitWith {
        ["No missions ready. Come back later."] remoteExec ["hintSilent", _caller];
    };

    missionNamespace setVariable ["lastMissionRequestCombine", time, true];

    // run the mission script on the server
    [] execVM "missionsCombine.sqf";

};




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