-- requires SpellTemplate.lua
-- requires Chopinski missile system
do
    local ThrowRockSpellObject = Spell:Create("A01D", "unit") -- main ability object
    local function throwrock()
        -- Exit early if this is the wrong ability
        local abilId = GetSpellAbilityId()
        if abilId ~= ThrowRockSpellObject.id then
            return
        end

        local this = ThrowRockSpellObject:NewInstance()
        local dmg = this.herodur -- use CHANNEL - Duration (Hero) in object editor to set damage value

        -- Make a (chopinski) missile to deal damage and launch it
        local rock = Missiles:create(this.cast_x, this.cast_y, 50, this.targ_x, this.targ_y, GetUnitFlyHeight(this.target) + 50)
        rock:model("Abilities\\Weapons\\RockBoltMissile\\RockBoltMissile.mdl")
        rock:speed(800)
        rock:arc(25)
        rock:scale(1.5)
        rock.target = this.target
        rock.onFinish = function()
            UnitDamageTarget(this.caster, rock.target, dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_NORMAL, nil)
            return true
        end
        rock:launch()
    end

    -- Build the trigger --
    ThrowRockSpellObject:MakeTrigger(throwrock)
end