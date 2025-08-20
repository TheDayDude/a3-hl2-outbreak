/*
    timeSkip.sqf
    Handles the "Request Time Skip" logic.

    To use, place this in an object's init field in the editor:
        this addAction ["Request Time Skip", { [player] remoteExec ["TAG_fnc_requestTimeSkip", 2]; }];
*/

if (!isServer) exitWith {};

TAG_fnc_requestTimeSkip = {
    params ["_player"];

    // Cooldown check (1 hour game time)
    private _last = missionNamespace getVariable ["TimeSkipLast", -3600];
    if (time - _last < 3600) exitWith {
        ["Time skip is on cooldown."] remoteExec ["hint", _player];
    };

    // Mark player as ready for 1 minute
    _player setVariable ["TimeSkipReady", true, true];
    [_player] spawn {
        params ["_p"];
        sleep 60;
        _p setVariable ["TimeSkipReady", false, true];
    };

    // Start check loop if not already running
    if !(missionNamespace getVariable ["TimeSkipCheckRunning", false]) then {
        missionNamespace setVariable ["TimeSkipCheckRunning", true];
        [] spawn {
            private _success = false;
            for "_i" from 1 to 60 do {
                if ({ _x getVariable ["TimeSkipReady", false] } count allPlayers == count allPlayers && {count allPlayers > 0}) exitWith { _success = true; };
                sleep 1;
            };

            if (_success) then {
                skipTime 8;
                missionNamespace setVariable ["TimeSkipLast", time, true];
                ["Time advanced by 8 hours."] remoteExec ["hint", 0];
            } else {
                ["Not all players are ready for sleep."] remoteExec ["hint", 0];
            };

            {
                _x setVariable ["TimeSkipReady", false, true];
            } forEach allPlayers;

            missionNamespace setVariable ["TimeSkipCheckRunning", false];
        };
    };
};
