#include <\x\spyderaddons\addons\sup_recruit\script_component.hpp>
SCRIPT(recruitment);

/* ----------------------------------------------------------------------------
Function: SpyderAddons_fnc_recruitment

Description:
Main handler for recruitment

Parameters:
String - Operation
Array - Arguments

Returns:
Any - Result of the operation

Examples:
(begin example)
(end)

See Also:
- nil

Author: SpyderBlack723

Peer Reviewed:
nil
---------------------------------------------------------------------------- */

params [
	["_operation", ""],
	["_arguments", []]
];
private ["_result"];

//-- Define Class
#define MAINCLASS SpyderAddons_fnc_recruitment

//-- Define control ID's
#define RECRUITMENT_UNITLIST 574
#define RECRUITMENT_GEARLIST 576

switch (_operation) do {

	case "init": {
		_arguments params ["_logic","_syncedUnits"];

		_factions = [_logic getVariable "RecruitableFactions"] call SpyderAddons_fnc_getModuleArray;
		_whitelist = [_logic getVariable "RecruitableUnits"] call SpyderAddons_fnc_getModuleArray;
		_blacklist = [_logic getVariable "BlacklistedUnits"] call SpyderAddons_fnc_getModuleArray;
		_maxUnits = call compile (_logic getVariable "MaximumUnits");
		_spawnCode = compile (_logic getVariable "SpawnCode");

		{
			if (typeName _x == "OBJECT") then {
				_x setVariable ["Recruitment_Settings", [_factions,_whitelist,_blacklist,_maxUnits,_spawnCode]];
				_x addAction ["Recruit", {["open",_this] call SpyderAddons_fnc_recruitment}];
			};
		} forEach _syncedUnits;
	};
	
	case "open": {
		CreateDialog "Recruitment_Menu";
		["onLoad", _arguments] call SpyderAddons_fnc_recruitment;

		MOD(recruitmentHandler) = [] call CBA_fnc_hashCreate;
		[MOD(recruitmentHandler),"Data", _arguments] call CBA_fnc_hashSet;
	};

	case "onLoad": {
		private ["_factions"];
		_arguments params ["_object","_caller"];

		player setVariable ["Recruitment_CurrentObject", _object];

		//-- Get settings
		_settings = _object getVariable "Recruitment_Settings";
		_settings params [
			"_factions",
			"_whitelist",
			"_blacklist"
		];

		//-- Get faction units
		_units = "(
			((getText (_x >> 'faction')) in _factions) and
			{(configName _x) isKindOf 'Man' and
			{!((getText (_x >> '_generalMacro') == 'B_Soldier_base_F')) and
			{count (getArray (_x >> 'weapons')) > 2 and
			{!((configName _x) in _blacklist)
		}}}})" configClasses (configFile >> "CfgVehicles");

		//-- Add whitelisted units
		{
			if ((typeName _x == "STRING") and !(_x in _units)) then {
				_units pushBack (configFile >> "CfgVehicles" >> _x);
			};
		} forEach _whitelist;

		//-- Build list with retrieved units
		{
			_name = getText (_x >> "displayName");

			lbAdd [RECRUITMENT_UNITLIST, _name];
			lbSetData [RECRUITMENT_UNITLIST, _forEachIndex, configName _x];
		} forEach _units;

		//-- Track group list selection
		(findDisplay 570 displayCtrl RECRUITMENT_UNITLIST)  ctrlAddEventHandler ["LBSelChanged","
			['updateGear'] call SpyderAddons_fnc_recruitment;
		"];
	};

	case "onUnload": {
		MOD(recruitmentHandler) = nil;
	};

	case "updateGear": {
		//-- Clear any existing data
		lbClear RECRUITMENT_GEARLIST;

		//-- Get currently selected unit
		_index = lbCurSel RECRUITMENT_UNITLIST;
		_class = lbData [RECRUITMENT_UNITLIST, _index];

		//-- Get config entry
		_configClass = configfile >> "CfgVehicles" >> _class;
		_weapons = getArray (_configClass >> "weapons");
		_magazines = getArray (_configClass >> "magazines");
		_items = getArray (_configClass >> "Items");

		private ["_index"];
		_index = 0;

		//-- Weapons
		{
			if !((_x == "Throw") or (_x == "Put")) then {
				_configPath = configfile >> "CfgWeapons" >> _x;
				if (isClass _configPath) then {
					_displayName = getText (_configPath >> "displayName");
					_picture = getText (_configPath >> "picture");

					lbAdd [RECRUITMENT_GEARLIST, _displayName];
					lbSetPicture [RECRUITMENT_GEARLIST, _index, _picture];
					_index = _index + 1;
				};
			};
		} forEach _weapons;

		_itemArray = _magazines + _items;
		{
			private ["_item","_count","_configPath"];
			_item = _x;
			_count = {_x == _item} count _itemArray;

			if !(_count == 0) then {
				for "_i" from 0 to _count step 1 do {_itemArray = _itemArray - [_item]};

				_configPath = configfile >> "CfgWeapons" >> _item;
				if !(isClass _configPath) then {_configPath = configfile >> "CfgMagazines" >> _item};
				if !(isClass _configPath) then {_configPath = configfile >> "CfgVehicles" >> _item};

				if !(isClass _configPath) then {
					_displayName = getText (_configPath >> "displayName");
					_picture = getText (_configPath >> "picture");
					_itemInfo = format ["%1: %2", _displayName, _count];

					lbAdd [RECRUITMENT_GEARLIST, _itemInfo];
					lbSetPicture [RECRUITMENT_GEARLIST, _index, _picture];
					_index = _index + 1;
				};
			};
		} forEach _itemArray;
	};

	case "getSelectedUnit": {
		_data = [MOD(recruitmentHandler),"Data"] call CBA_fnc_hashGet;
		_currentObject = _data select 0;

		//-- Exit if too many units in player group
		_settings = _currentObject getVariable "Recruitment_Settings";
		_maxUnits = _settings select 3;

		if (count units group player >= _maxUnits) exitWith {
			hint format ["You have too many units in your group. You may not recruit more until you have less than %1 units in your group.", _maxUnits];
		};

		_index = lbCurSel RECRUITMENT_UNITLIST;
		_classname = lbData [RECRUITMENT_UNITLIST, _index];

		["spawnUnit", [_data, _classname]] remoteExecCall [QUOTE(MAINCLASS), 2];
	};

	case "spawnUnit": {
		_arguments params ["_data","_classname"];
		_data params ["_object","_player"];
		_settings = _object getVariable "Recruitment_Settings";
		_spawnCode = _settings select 4;

		_unit = (group _player) createUnit [_classname, (getPos _player), [], 15, "FORM"];
		addSwitchableUnit _unit;

		_unit call _spawnCode;
	};

};

//-- Return result if any exists
if (!isNil "_result") then {_result} else {nil};