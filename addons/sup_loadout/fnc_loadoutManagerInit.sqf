/* ----------------------------------------------------------------------------
Function: SpyderAddons_fnc_recruitmentInit

Description:
Creates the server side object to store settings

Parameters:
_this select 0: OBJECT - Reference to module
_this select 1: ARRAY - Synchronized units

Returns:
nil

Author:
SpyderBlack723

Peer Reviewed:
nil
---------------------------------------------------------------------------- */

private ["_logic","_moduleID"];
params ["_logic","_syncedUnits"];

_enable = call compile (_logic getvariable ["Enable","false"]);
if !(_enable) exitWith {["[SpyderAddons - Sup Loadout] Module has been disabled, exiting"] call SpyderAddons_fnc_log};

// Confirm init function available
if (isNil "SpyderAddons_fnc_loadoutManager") exitWith {["[SpyderAddons - Sup Loadout] Main function missing"] call SpyderAddons_fnc_log};

["[SpyderAddons - Sup Loadout] Initialization starting"] call SpyderAddons_fnc_log;

["init", _syncedUnits] call SpyderAddons_fnc_loadoutManager;

["[SpyderAddons - Sup Loadout] Initialization complete"] call SpyderAddons_fnc_log;