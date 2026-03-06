---table of abilitylevelfields
ChannelRealFields = {
	["normaldur"] = ABILITY_RLF_DURATION_NORMAL,
	["adur"] = ABILITY_RLF_DURATION_NORMAL,
	["herodur"] = ABILITY_RLF_DURATION_HERO,
	["ahdu"] = ABILITY_RLF_DURATION_HERO,
	["cooldown"] = ABILITY_RLF_COOLDOWN,
	["cool"] = ABILITY_RLF_COOLDOWN,
	["area"] = ABILITY_RLF_AREA_OF_EFFECT,
	["aoe"] = ABILITY_RLF_AREA_OF_EFFECT,
	["aare"] = ABILITY_RLF_AREA_OF_EFFECT,
	["range"] = ABILITY_RLF_CAST_RANGE,
	["rng"] = ABILITY_RLF_CAST_RANGE,
	["casttime"] = ABILITY_RLF_CASTING_TIME,
	["castingtime"] = ABILITY_RLF_CASTING_TIME,
	["artdur"] = ABILITY_RLF_ART_DURATION,
	["ncl4"] = ABILITY_RLF_ART_DURATION,
	["followthrough"] = ABILITY_RLF_FOLLOW_THROUGH_TIME,
	["followthroughtime"] = ABILITY_RLF_FOLLOW_THROUGH_TIME,
	["ncl1"] = ABILITY_RLF_FOLLOW_THROUGH_TIME
}
ChannelIntegerFields = {
	["cost"] = ABILITY_ILF_MANA_COST,
	["manacost"] = ABILITY_ILF_MANA_COST,
	["amcs"] = ABILITY_ILF_MANA_COST,
	["lvls"] = ABILITY_IF_LEVELS,
	["levels"] = ABILITY_IF_LEVELS,
	["alev"] = ABILITY_IF_LEVELS,
	["requiredlevel"] = ABILITY_IF_REQUIRED_LEVEL,
	["reqlevel"] = ABILITY_IF_REQUIRED_LEVEL,
	["reqlvl"] = ABILITY_IF_REQUIRED_LEVEL,
	["arlv"] = ABILITY_IF_REQUIRED_LEVEL,
	["targettype"] = ABILITY_ILF_TARGET_TYPE,
	["targeting"] = ABILITY_ILF_TARGET_TYPE,
	["ncl2"] = ABILITY_ILF_TARGET_TYPE,
	["options"] = ABILITY_ILF_OPTIONS,
	["opts"] = ABILITY_ILF_OPTIONS,
	["ncl3"] = ABILITY_ILF_OPTIONS
}

---@param which_ability ability | integer | string
---@param which_field string
---@param which_level integer
---@return number
function GetAbilityField(which_ability, which_field, which_level)
	--[[
    If which_ability is a string, it turns it into an integer using FourCC.
    If which_ability is not a string (probably already a numeric id), it just uses the value directly.
	]]
	
	local id = type(which_ability) == "string" and FourCC(which_ability) or which_ability
	which_field = type(which_field) == "string" and which_field:lower() or tostring(which_field):lower()
	if (which_level < 0) then
		which_level = 1
	end

	-- create a dummy unit with the ability, for retrieving an Ability Class instance via BlzGetUnitAbility()
	local dummy = CreateUnit(Player(0), FourCC('e000'), 0, 0, 0)
	UnitAddAbility(dummy, id)
	
	-- return appropiate field value
	if ChannelRealFields[which_field] then
		return BlzGetAbilityRealLevelField((BlzGetUnitAbility(dummy, id)), ChannelRealFields[which_field], which_level)
	elseif ChannelIntegerFields[which_field] then
		return BlzGetAbilityIntegerLevelField((BlzGetUnitAbility(dummy, id)), ChannelIntegerFields[which_field], which_level)
	else
		print("Error in retrieving ability field")
		return nil
	end
	RemoveUnit(dummy)
end