player setVariable ["HasCID", false, false];
player setVariable ["CID_Number", nil, true];
player setVariable ["isLoyalist", false, true];


private _cid = player getVariable ["CID_Number", "Unknown"];

if (!isNil "_cid" && {_cid != "Unknown"}) then {
    CID_Loyalty set [_cid, 0];
    CID_Malcompliance set [_cid, 0];
};

if (side player == east) then {    
	[player] joinSilent createGroup civilian;
}