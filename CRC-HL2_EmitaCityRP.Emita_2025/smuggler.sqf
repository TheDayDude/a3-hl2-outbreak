// smuggler.sqf — spawns a roaming smuggler merchant in the Slums
if (!isServer) exitWith {};

[] spawn {
    private _smugglerClass = "RDS_PL_Profiteer_Random";
    private _packClass     = "B_Carryall_blk";
    private _activeTime    = 1800;  // 30 minutes active
    private _respawnMin    = 1800;  // 30 minutes
    private _respawnMax    = 3600;  // 45 minutes
    private _fakeCIDPrice  = 30;    // tokens for fake CID

	private _stock_smuggler = [
		["Cytech_Makeshift_Argument_Short","Makeshift Argument (Short)",15],
		["Cytech_Makeshift_PM","Makeshift PM",5],
		["Cytech_Makeshift_Argument","Makeshift Argument",7],
		["Cytech_Makeshift_APS","Makeshift APS",10],
		["Cytech_flashlight_Normal","Normal Flashlight",1],
		["Cytech_APS_Compensator","APS Compensator",2],
		["Cytech_PM_Amplifier","PM Amplifier",2],
		["Cytech_14Rnd_9x18_Mag","14Rnd 9x18mm Mag",2],
		["Cytech_35Rnd_9x18_Mag","35Rnd 9x18mm Mag",3],
		["Cytech_6Rnd_45ACP","6Rnd .45 ACP Cylinder",3],
		["hlc_rifle_aks74u","AKS-74U",25],
		["hlc_30Rnd_545x39_B_AK","30Rnd 5.45mm AK Mag",3],
		["H_bms_helmet_1","BMS Helmet",10],
		["V_resistance_vest_bms","Resistance Vest",12],
		["V_BandollierB_blk","Black Bandolier",2],
		["B_hecu_survival_m81_2","HECU Survival Pack",5],
		["G_Bandanna_blk","Black Bandanna",1],
		["G_Balaclava_cloth_blk_F","Black Cloth Balaclava",1],
		["M40_Gas_mask_nbc_f4_d","M40 Gas Mask (NBC)",4],
		["BMS_X800","NVG X800 Goggles",4],
		["O_NVGoggles_urb_F","Compact NVGs",20],
		["GrenadeMolotovPSRUS","Molotov Cocktail",3],
		["IEDLandBig_Remote_Mag","Large Land IED (Remote)",18],
		["IEDUrbanBig_Remote_Mag","Large Urban IED (Remote)",18],
		["IEDLandSmall_Remote_Mag","Small Land IED (Remote)",10],
		["IEDUrbanSmall_Remote_Mag","Small Urban IED (Remote)",10],
		["ACE_Clacker","M57 Firing Device",5],
		["VRP_AntlionMeat","Antlion Meat",2],
		["WBK_Health_ArmourPlate","Armor Plate",3],
		["WBK_Health_Bandage","Bandage",1],
		["ACE_Banana","Banana",2],
		["plp_bo_w_BottleLiqCream","Bottle of Cream Liqueur",4],
		["plp_bo_w_BottleGin","Bottle of Gin",4],
		["plp_bo_w_BottleTequila","Bottle of Tequila",4],
		["ACE_CableTie","Cable Tie",1],
		["ACE_Can_Spirit","Can of Spirit",2],
		["ACE_Can_RedGull","Can of RedGull",2],
		["ACE_Can_Franta","Can of Franta",2],
		["ACE_Canteen","Canteen",3],
		["ACE_DeadManSwitch","Dead Man's Switch",5],
		["ACE_DefusalKit","Defusal Kit",5],
		["VRP_Bread","Bread",5],
		["VRP_HeadcrabMeat","Headcrab Meat",2],
		["VRP_HoundMeat","Houndeye Meat",2],
		["VRP_Watermelon","Watermelon",4],
		["ACE_MRE_BeefStew","MRE: Beef Stew",5],
		["ACE_MRE_LambCurry","MRE: Lamb Curry",5],
		["HLC_Optic_1p29","1P29 Scope",8],
		["HLC_Optic_PSO1","PSO-1 Scope",8],
		["WBK_BearRebel_Rifle_Scope","Bear Rebel Rifle Scope",10],
		["WBK_BearRebel_Rifle","Bear Rebel Rifle",15],
		["HL_CivHuntingRifle_Mag","Civ. Hunting Rifle Mag",3]
	];


    private _rollInventory = {
        params ["_stock","_count"];
        private _pool = +_stock call BIS_fnc_arrayShuffle;
        private _pick = _pool select [0, _count min (count _pool)];
        private _out  = [];
        {
            _out pushBack [_x select 0, _x select 1, _x select 2];
        } forEach _pick;
        _out
    };

    private _giveTask = {
        params ["_players", "_pos", "_smug"];
        if (_players isEqualTo []) exitWith {};
        sleep 30;
		private _ply = selectRandom _players;
        private _taskId = format ["task_smuggler_%1_%2", side _ply, diag_tickTime];
        [_ply, _taskId,
            ["Find the smuggler rumored to be in the Slums. He will not stay for very long.", "Rumors of a Smuggler", ""],
            _pos, true
        ] remoteExec ["BIS_fnc_taskCreate", _ply];

        [_taskId, _smug, _ply] spawn {
            params ["_taskId","_smug","_ply"];
            waitUntil {
                sleep 3;
                isNull _smug || isNull _ply || !alive _ply || ((_ply distance2D _smug) < 3)
            };
            private _state = if (!isNull _smug && !isNull _ply && alive _ply && ((_ply distance2D _smug) < 3)) then { "SUCCEEDED" } else { "FAILED" };
            [_taskId, _state, true] remoteExec ["BIS_fnc_taskSetState", _ply];
            sleep 10;
            [_taskId] remoteExec ["BIS_fnc_deleteTask", _ply];
        };
    };

    if (isNil "MRC_fnc_addFakeCIDAction") then {
        MRC_fnc_addFakeCIDAction = {
            params ["_m", "_price"];
            if (isNull _m) exitWith {};
            _m addAction [
                format ["Buy Fake CID (Join Civilians) <t color='#FFD700'>(%1 tokens)</t>", _price],
                {
                    params ["_target","_caller","","_args"];
                    _args params ["_price"];
                    [_caller, _target, _price] remoteExecCall ["MRC_fnc_buyFakeCID", 2];
                },
                [_price], 1.5, true, true, "",
                "_this distance _target < 4"
            ];
        };
        publicVariable "MRC_fnc_addFakeCIDAction";
    };

    if (isNil "MRC_fnc_buyFakeCID") then {
        MRC_fnc_buyFakeCID = {
            params ["_plr", "_smug", "_price"];
            if (isNull _plr || { !alive _plr }) exitWith {};
            if (_plr getVariable ["isOTA", false]) exitWith {
                ["Your loyalty programming forbids this."] remoteExec ["hintSilent", owner _plr];
            };			
            private _tokens = { _x == "VRP_HL_Token_Item" } count (items _plr);
            if (_tokens < _price) exitWith {
                ["Not enough tokens."] remoteExec ["hintSilent", owner _plr];
            };

            private _wasCPF = side _plr == west;

            for "_i" from 1 to _price do { _plr removeItem "VRP_HL_Token_Item"; };
            _plr addMagazine "Civilain_IDCard_1";

            private _grp = createGroup [civilian, true];
            [_plr] joinSilent _grp;

            if (_wasCPF && {!isNull _smug}) then {
                _smug addItemToBackpack "U_C18_Uniform_8";
            };

            private _cid = [_plr] call MRC_fnc_assignCID;
            private _prefix = switch (side _plr) do {
                case civilian: {"CIT-"};
                case west: {"UNIT-"};
                case independent: {"???-"};
                case east: {"MAL-"};
                default {"???"};
            };

            private _msg = format ["Fake CID purchased. New CID: %1", _cid];
            if (_wasCPF) then {
                _msg = _msg + "\n You dirty cop... the merchant has a free uniform for you in his pack.";
				["Autonomous Unit: Accept mandatory sector assimilation. Coordinated constriction underway. Debride and cauterize. Entering phase nine, enhanced compliance. Deploy advisory control and oversight. Submit and be subsumed."] remoteExec ["systemChat", 0];
				["Overvista"] remoteExec ["playSound", 0];
				_plr setVariable ["WBK_CombineType"," g_hecu_",true];				
            };
            [_msg] remoteExec ["hintSilent", owner _plr];
        };
        publicVariable "MRC_fnc_buyFakeCID";
    };

    // Wait for merchant helpers from merchants.sqf to be present
    waitUntil { !isNil "MRC_fnc_addMerchantActions" && !isNil "MRC_fnc_merchantServer" };

    while { true } do {
        private _markers = allMapMarkers select { toLower _x find "slums_" == 0 && { toLower _x != "slums_guard" } };
        if (_markers isEqualTo []) exitWith { diag_log "[SMUGGLER] No slums_ markers found."; };
        private _chosen = selectRandom _markers;
        private _pos    = getMarkerPos _chosen;

        private _grp = createGroup civilian;
        private _u = _grp createUnit [_smugglerClass, _pos, [], 0, "NONE"];
        _u setDir (random 360);
        _u setPosATL (_pos vectorAdd [0,0,1]);
        _u switchMove "";
        _u disableAI "MOVE";
        _u disableAI "PATH";
        _u disableAI "TARGET";
        _u disableAI "AUTOTARGET";
        _u allowFleeing 0;
        _u setUnitPos "UP";
        _u setBehaviour "SAFE";
        _u setCaptive true;
        removeAllWeapons _u;
        removeBackpack _u;
        _u addBackpack _packClass;

        private _ammo  = _stock_smuggler select { isClass (configFile >> "CfgMagazines" >> (_x select 0)) };
        private _other = _stock_smuggler select { !isClass (configFile >> "CfgMagazines" >> (_x select 0)) };
        private _entries = ([_other, 6] call _rollInventory);
        _entries append ([_ammo, count _ammo] call _rollInventory);
        [_u, _entries] remoteExec ["MRC_fnc_addMerchantActions", 0, true];
        [_u, _fakeCIDPrice] remoteExec ["MRC_fnc_addFakeCIDAction", 0, true];

        [(allPlayers select { side _x == civilian }), _pos, _u] call _giveTask;
        [(allPlayers select { side _x == east }),      _pos, _u] call _giveTask;

        private _end = time + _activeTime;
        waitUntil { sleep 5; time >= _end };
        if (!isNull _u) then { deleteVehicle _u; };
        if (!isNull _grp) then { deleteGroup _grp; };

        sleep (_respawnMin + random (_respawnMax - _respawnMin));
    };
};