fnc_spawnLoot = {
    params ["_pos"];
    private _box = "Box_FIA_Support_F" createVehicle _pos;
    clearWeaponCargoGlobal _box;
    _box addItemCargoGlobal ["FirstAidKit", 3];
    _box addItemCargoGlobal ["VRP_AntlionMeat", 1];
	_box addItemCargoGlobal ["ACE_Canteen", 1];
	_box addItemCargoGlobal ["WBK_Health_Bangages", 5];
	_box addItemCargoGlobal ["VRP_Health_ArmourPlate", 5];
	_box addItemCargoGlobal ["Crowbar", 1];
	_box addItemCargoGlobal ["B_HECU_Survival_m81", 1];
};
