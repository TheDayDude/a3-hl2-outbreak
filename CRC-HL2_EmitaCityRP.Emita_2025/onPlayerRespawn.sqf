params ["_unit", "_corpse"];
if (!local _unit) exitWith {};

private _old = _unit getVariable ["CID_Number", nil];
if (!isNil "_old") then {
    CID_Loyalty deleteAt _old;
    CID_Malcompliance deleteAt _old;
    if !(isNil "Global_CID_Registry") then {
        Global_CID_Registry = Global_CID_Registry - [_old];
        publicVariable "Global_CID_Registry";
    };
};

_unit setVariable ["HasCID", false, false];
_unit setVariable ["CID_Number", nil, true];
_unit setVariable ["isLoyalist", false, true];
_unit setVariable ["Favor", 0, true];

[_unit] joinSilent createGroup civilian;
[_unit] remoteExec ["MRC_fnc_assignCID", 2];
_unit setVariable ["WBK_CombineType","  rebel_",true];
_unit setVariable ["WBK_HL_CustomArmour",0,true];
_unit setVariable ["WBK_HL_CustomArmour_MAX",50,true];