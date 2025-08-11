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

if (isNil { missionNamespace getVariable "RationStock" }) then {
    missionNamespace setVariable ["RationStock", 5, true]; // true = publicVariable
};

if (isNil { missionNamespace getVariable "Biomass" }) then {
    missionNamespace setVariable ["Biomass", 5, true];
};

if (isNil { missionNamespace getVariable "Stims" }) then {
    missionNamespace setVariable ["Stims", 5, true];
};

if (isNil { missionNamespace getVariable "Armor" }) then {
    missionNamespace setVariable ["Armor", 5, true];
};

if (isNil { missionNamespace getVariable "PlasmaLevel" }) then {
    missionNamespace setVariable ["PlasmaLevel", 5, true];
};

call compile preprocessFileLineNumbers "portalStorm.sqf";

[] spawn {
    while {true} do {
        private _delay = 3000 + random 6000;
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
        // Wait 55 minutes (3300 seconds)
        sleep 3300;

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
        // Wait between missions (61 minutes, in case a side is idle so their missions don't pile up)
        private _delay = 3660;
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

    if (time - _last < 1800) exitWith {
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

    if (time - _last < 1800) exitWith {
        ["No missions ready. Come back later."] remoteExec ["hintSilent", _caller];
    };

    missionNamespace setVariable ["lastMissionRequestRebels", time, true];

    // run the mission script on the server
    [] execVM "missionsRebels.sqf";

};

TAG_fnc_requestCombineMission = {
    params ["_caller"];

    private _last = missionNamespace getVariable ["lastMissionRequestCombine", -99999];

    if (time - _last < 1800) exitWith {
        ["No missions ready. Come back later."] remoteExec ["hintSilent", _caller];
    };

    missionNamespace setVariable ["lastMissionRequestCombine", time, true];

    // run the mission script on the server
    [] execVM "missionsCombine.sqf";

};




// === Bagging & tracking helpers (vanilla body bag; ACE cargo-friendly) ===
if (isNil "fnc_addCleanupBagActions") then {
  fnc_registerBag = {
    params ["_bag","_tag"];
    if (isNull _bag) exitWith {};
    _bag setVariable ["cleanupTag", _tag, true];
    private _key = format ["CLEANUP_BAGS_%1", _tag];
    private _arr = missionNamespace getVariable [_key, []];
    _arr pushBackUnique _bag;
    missionNamespace setVariable [_key, _arr, true];
  };

  fnc_addCleanupBagActions = {
    params ["_corpse","_tag"];
    if (isNull _corpse || alive _corpse) exitWith {};
    if (_corpse getVariable ["hasCleanupBagActions", false]) exitWith {};
    _corpse setVariable ["hasCleanupBagActions", true, true];

    // Action: Bag body (turn into body bag prop and register it)
    _corpse addAction [
      "<t color='#FFD700'>Bag body</t>",
      {
        params ["_corpse","_caller","_args"]; private _tag = _args;
		_caller lookAt _corpse;
		[_caller, "AinvPknlMstpSnonWnonDnon_medic_1"] remoteExec ["playMoveNow", _caller];
		uiSleep 6;  // duration of the anim
        if (isNull _corpse || alive _corpse) exitWith {};
        private _bag = createVehicle ["CBRN_Bodybag_Closed", getPosATL _corpse, [], 0, "NONE"];
        _bag setDir (getDir _corpse);

        // Make ACE-cargoable & small
        if !(isNil "ACE_cargo_fnc_setSize") then { [_bag, 1] call ACE_cargo_fnc_setSize; };
		[_bag, true, [0, 2, 0], 180] call ace_dragging_fnc_setDraggable;

        // Hide/delete corpse to avoid dupes
        hideBody _corpse; deleteVehicle _corpse;

        // Track this bag for the mission
        [_bag, _tag] call fnc_registerBag;

        // Convenience action: load into nearest vehicle (optional)
        _bag addAction [
          "<t color='#90EE90'>Use ACE to load into a vehicle.</t>",
          {
            params ["_bag","_caller"];
            private _veh = objNull;
            private _cands = nearestObjects [_bag, ["Car","Truck","Tank","Ship_F","Air"], 15];
            if !(_cands isEqualTo []) then { _veh = _cands select 0; };
            if (isNull _veh) exitWith { _caller sideChat "No vehicle nearby."; };
            if !(isNil "ACE_cargo_fnc_loadItem") then {
              [_veh, _bag] call ACE_cargo_fnc_loadItem;
            } else {
              // Fallback: attach (not ideal, but works without ACE Cargo)
              _bag attachTo [_veh, [0, -1.2, -0.5]];
            };
          },
          nil, 1.5, true, true, "", "true"
        ];
      },
      nil, 1.5, true, true, "", "!(alive _target)", 3
    ];
  };
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
                    ["Attention Citizens: Ration Production is below quota. Report to the Ration Factory in Sector 3 and begin assembling rations. Restock Biomass as needed. Scavenge, if needed. Take the assembled rations and deliver them to the Ration Distribution Center in Sector 1, to the warehouse terminal on the left.",
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

