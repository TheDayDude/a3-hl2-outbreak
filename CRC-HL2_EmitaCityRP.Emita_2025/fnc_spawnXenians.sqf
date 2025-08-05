// File: fnc_spawnXenians.sqf

params ["_pos"];

private _xenTypes = [
    "WBK_Bullsquid_1",
    "WBK_Houndeye_1",
    "WBK_Antlion_1",
    "WBK_ClassicZombie_HLA_4",
	"WBK_ClassicZombie_HLA_3",
    "WBK_Zombine_HLA_1",
    "WBK_Headcrab_Normal"
];

private _grp = createGroup resistance;
private _count = 3 + floor random 4; // Spawns between 3 to 6 units

for "_i" from 1 to _count do {
    private _unit = _grp createUnit [selectRandom _xenTypes, _pos, [], 0, "FORM"];
    _unit setSkill (0.4 + random 0.3);

    _unit addEventHandler ["Killed", {
        params ["_dead", "_killer"];
        private _meatCount = selectRandom [0,0,1,1];
        for "_i" from 1 to _meatCount do {
            private _item = createVehicle ["GroundWeaponHolder", getPosATL _dead, [], 0, "NONE"];
            _item addItemCargoGlobal ["VRP_StrangeMeat", 1];
        };
    }];
};

_grp setBehaviour "AWARE";
_grp setCombatMode "RED";
_grp addWaypoint [_pos vectorAdd [random 20 - 10, random 20 - 10, 0], 0];