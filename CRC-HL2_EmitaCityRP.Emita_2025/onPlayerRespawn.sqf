private _old = player getVariable ["CID_Number", nil];
if (!isNil "_old") then {
    CID_Loyalty deleteAt _old;
    CID_Malcompliance deleteAt _old;
    if !(isNil "Global_CID_Registry") then {
        Global_CID_Registry = Global_CID_Registry - [_old];
        publicVariable "Global_CID_Registry";
    };
};

player setVariable ["HasCID", false, false];
player setVariable ["CID_Number", nil, true];
player setVariable ["isLoyalist", false, true];
player setVariable ["Favor", 0, true];

[player] joinSilent createGroup civilian;
[player] remoteExec ["MRC_fnc_assignCID", 2];
player setVariable ["WBK_CombineType","  rebel_",true];
player setVariable ["WBK_HL_CustomArmour",0,true];
player setVariable ["WBK_HL_CustomArmour_MAX",50,true];