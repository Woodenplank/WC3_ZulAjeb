-- requires QuickHeal.lua
-- requires SpellTemplate.lua
do
    local ChainHealSpellObject = Spell:Create("A01B", "unit") -- main ability object
    local function ChainHealCast()
        -- Exit early if this is the wrong ability
        local abilId = GetSpellAbilityId()
        if abilId ~= ChainHealSpellObject.id then
            return
        end

        -- stats
        local this = ChainHealSpellObject:NewInstance()
        local heal = this.herodur                       -- use CHANNEL - Duration (Hero) in object editor to set healing value
        local bounce_reduc = 0.15                       -- loss of healing per bounce
        --[[ ADDITIONAL IDEA: 
            Here we could also add in a special effect like:
            UnitHasItem(Waterdancer's Amulet) then
                bounce_reduc = 0
            If you want an item that removes the loss of healing per bounce mechanic.
        ]]
        local bounce_dist = this.aoe
        local bounce_num = math.floor(this.normaldur)   -- use CHANNEL - Duration (Normal) in object editor for number of healing bounces

        -- Editor objects
        local t_delay = CreateTimer()
        local ug = CreateGroup()
        local ug_filter = CreateGroup()
        local cond = Condition(function()
            local fu = GetFilterUnit()
            return (
                not IsUnitEnemy(fu, this.castplayer)
                and not IsUnitType(fu, UNIT_TYPE_DEAD)
                and not IsUnitType(fu, UNIT_TYPE_STRUCTURE)
                and not IsUnitInGroup(fu, ug_filter))
        end)
        --[[ ADDITIONAL IDEA: 
            The default ability can't heal the same unit twice (no-repeat-bounces).
            You could do a special item that increased number of bounces (bounce_num = bounce_num + X)
            and also let bounces hit the same unti twice (alternate condition function).
        ]]

        -- ChainHeal on first target
        local last_x, last_y = this.cast_x, this.cast_y
        local next_x, next_y = this.targ_x, this.targ_y
        local l = AddLightningEx("HWPB", false, last_x, last_y, 50, next_x, next_y, 50) -- z-offset by 50, so it's not along the ground
        DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Orc\\HealingWave\\HealingWaveTarget.mdl", next_x, next_y))
        QuickHealUnit(this.target, heal)
        GroupAddUnit(ug_filter, this.target)
        local last_u = this.target
        
        -- -- Chaining
        local next_u
        local bounces = 1
        TimerStart(t_delay, 0.53, true, function()
            -- remove lightning from previous bounce
            DestroyLightning(l)

            -- Pick a new units within range and heal it
            GroupEnumUnitsInRange(ug, next_x, next_y, bounce_dist, cond)
            next_u = GroupPickRandomUnit(ug)
            QuickHealUnit(next_u, heal*bounce_reduc*bounces)
            GroupAddUnit(ug_filter, next_u)

            -- create new lightning between new (next) target and the former
            last_x, last_y = GetUnitX(last_u), GetUnitY(last_u)
            next_x, next_y = GetUnitX(next_u), GetUnitY(next_u)
            l = AddLightningEx("HWSB", false, last_x, last_y, 50, next_x, next_y, 50) -- z-offset by 50, so it's not along the ground
            DestroyEffect(AddSpecialEffect("Abilities\\Spells\\Orc\\HealingWave\\HealingWaveTarget.mdl", next_x, next_y))
            last_u = next_u

            -- Check for finish
            bounces = bounces + 1
            if (bounces >= bounce_num) or IsUnitGroupEmptyBJ(ug) then
                DestroyLightning(l)
                PauseTimer(t_delay)
                DestroyTimer(t_delay)
                DestroyGroup(ug)
                DestroyGroup(ug_filter)
                DestroyCondition(cond)
            end
        end)
        -- END --
    end

    -- Build trigger --
    ChainHealSpellObject:MakeTrigger(ChainHealCast)
end