/*
    OTA promotion system.
    Call once from initServer.sqf: [] execVM "ota_functions.sqf";
*/
OTA_fnc_cinematic = {
    params ["_unit"];

    // visuals/audio for the player only
    _unit playMoveNow "AinjPpneMstpSnonWnonDnon";
    cutText ["", "BLACK OUT", 1];
	sleep 2;
    [_unit, "cp_die_08"] remoteExecCall ["say3D", 0];
	titleText ["<t color='#2795F5' size='5'>Memory Wipe In Progress...</t>", "PLAIN", 0.3, true, true];
	sleep 10;
	[_unit, "WBK_radio_off_3"] remoteExecCall ["say3D", 0];
	titleText ["<t color='#2795F5' size='5'>Replacing Memories...</t>", "PLAIN", 0.3, true, true];
    sleep 6;
    titleText ["<t color='#2795F5' size='5'>Programming Loyalty...</t>", "PLAIN", 0.3, true, true];
	[_unit, "COMBINE_die_07"] remoteExecCall ["say3D", 0];
    sleep 8;
    cutText ["", "BLACK IN", 1];
	["Vital Alert: Autonomous unit subsumed. Mandatory compliance with tenets of advisorial assistance act. Threat level adjustment. Probe. Expunge."] remoteExec ["systemChat", 0];
	["Overbarn"] remoteExec ["playSound", 0];
	_unit switchMove "";
	titleText ["<t color='#2795F5' size='5'>Unit Online. Access to OTA Armory: Granted.</t>", "PLAIN", 0.6, true, true];
};

OTA_fnc_join = {
    params ["_target","_caller"];
    if (!isServer) exitWith {};

    private _next = missionNamespace getVariable ["OTA_next",0];
    if (time < _next) exitWith {
        [format ["OTA slot locked for %1",
            [_next-time] call BIS_fnc_timeToString]]
            remoteExec ["hintsilent", _caller];
    };

    private _current = missionNamespace getVariable ["OTA_current", objNull];
    if (!isNull _current && {alive _current}) exitWith {
        ["Another officer already serves as OTA."]
            remoteExec ["hintsilent", _caller];
    };

    missionNamespace setVariable ["OTA_current", _caller, true];

    // cinematic sequence on the caller
    [_caller] remoteExec ["OTA_fnc_cinematic", _caller];

    // gameplay effects
    _caller setVariable ["isOTA", true, true];
    _caller setVariable ["WBK_CombineType"," COMBINE_",true];
    _caller setVariable ["WBK_HL_CustomArmour",250,true];
    _caller setVariable ["WBK_HL_CustomArmour_MAX",250,true];
    _caller setVariable ["CanBuyFakeID",false,true];   // Smuggler check
	_caller forceAddUniform "HL_CMB_U_OW";
	removeHeadgear _caller;
	_caller addHeadgear "CombainSolder";
	_caller removeWeapon (primaryWeapon _caller);
	_caller addWeapon "HL2_CMB_AR2Proto";
	_caller addMagazines ["HL2_CMB_90Rnd_AR2Proto_Mag", 3];		

    // reset on death and start cooldown
    _caller addEventHandler ["Killed", {
        params ["_unit"];
        _unit setVariable ["isOTA",false,true];
        _unit setVariable ["WBK_CombineType"," cp_",true];
        _unit setVariable ["WBK_HL_CustomArmour",75,true];
        _unit setVariable ["WBK_HL_CustomArmour_MAX",75,true];
        _unit setVariable ["CanBuyFakeID",true,true];

        missionNamespace setVariable ["OTA_current", objNull, true];
        missionNamespace setVariable ["OTA_next", time + 1800, true];   // 30 min cooldown
    }];
};
publicVariable "OTA_fnc_join";
publicVariable "OTA_fnc_cinematic";

// monitor OTA armory for unauthorized players
[] spawn {
    waitUntil {!isNil "ota_armory"};
    while {true} do {
        private _current = missionNamespace getVariable ["OTA_current", objNull];
        {
            if (_x != _current && {isPlayer _x}) then {
                _x setPos (getMarkerPos "OTA_Reject");
            };
        } forEach (list ota_armory);
        sleep 1;
    };
};