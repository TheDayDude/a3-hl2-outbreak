// File: fnc_spawnRebels.sqf

params ["_pos"];

private _rebelTypes = [
    "WBK_Rebel_SL_1",
    "WBK_Rebel_Rifleman_3",
    "WBK_Rebel_Medic_1",
    "WBK_Rebel_SMG_1",
    "WBK_Rebel_SMG_2",
    "WBK_Rebel_Sniper",
    "WBK_Rebel_Shotgunner",
    "WBK_Rebel_HL2_RPG"
];

private _grp = createGroup east;
private _count = 4 + floor random 4; // Spawns between 4 to 7 units

for "_i" from 1 to _count do {
    private _unit = _grp createUnit [selectRandom _rebelTypes, _pos, [], 0, "FORM"];
    _unit setSkill (0.5 + random 0.4);
};

_grp setBehaviour "AWARE";
_grp setCombatMode "RED";
_grp addWaypoint [_pos vectorAdd [random 20 - 10, random 20 - 10, 0], 0];