-- requires ShieldType.lua
-- requires SpellTemplate.lua
do
    SHA_tab_watershield = {}                        -- table for storing shield instances

    -- ============================================================================================================== --
    -- Damage shielding actions
    local function WaterShieldBlock()
        local u = udg_DamageEventTarget
        local lvl = GetUnitAbilityLevel(u, SHA_id_watershieldbuff)

        -- early return if the damaged unit does not have the dummy buff
        if lvl<=0 then
            return
        end

        local id = GetHandleId(u)
        local dmg = udg_DamageEventAmount
        local shield = SHA_tab_watershield[id] -- it's a table, so copied by reference

        if shield.charges > 0 and dmg>0 then    -- I don't know if there are negative sources of dmg, but just in case...
            dmg = dmg * (0.7)                   --[[shield_dmg_resistance_modifier? Right now it's just flat 30%]]
            shield:decrement()
            print(shield.charges)
            shield.func(shield.target)
        else
            shield:destroy() -- this should be necessary, as the decrement operator already handles destruction
                             -- but on the other hand, it shouldn't hurt either.
        end
        
        
        -- -- Below section is for shield(s) based on BLOCKED-AMOUNT, rather than charges
            -- local shield_val = SHA_tab_watershield[id].blockamount
            -- if dmg >= shield then
            --     dmg = dmg - shield_val
            --     SHA_tab_watershield[id]:destroy()
            -- else
            --     SHA_tab_watershield[id].blockamount = shield_val - dmg
            --     dmg = 0
            -- end


        -- Update remaining damage
        udg_DamageEventAmount = dmg
    end


    -- ============================================================================================================== --
    -- Main spellcast actions
    local WaterShieldSpellObject = Spell:Create("A000", "unit") -- main ability object
    local function WaterShieldCast()
        -- Exit early if this is the wrong ability
        local abilId = GetSpellAbilityId()
        if abilId ~= WaterShieldSpellObject.id then
            return
        end

        -- stats
        local this = WaterShieldSpellObject:NewInstance()
        local c = this.herodur                  -- use CHANNEL - Duration (Hero) in object editor to set shield charge count
        local manarestore = this.aoe            -- use CHANNEL - Area of Effect in object editor to set mana restore per charge
        local targ_id = GetHandleId(this.target)
        local cast_id = GetHandleId(this.caster)

        -- Update shield value in global table
        params = {
            target = this.target,
            charges = c,
            buffid = '0000', -- TODO: fix this later
            dur = this.duration,
            chargefunction = function ()
                local fp = GetUnitState(this.target, UNIT_STATE_MANA)
                SetUnitState(this.target, UNIT_STATE_MANA, fp+manarestore)
            end,
            model = "Abilities\\Spells\\Human\\ManaShield\\ManaShieldCaster.mdl"
        }
        local shield_instance = ChargeShield:new(params)
        shield_instance:start()

        -- Add this new instance to the global table for tracking
        SHA_tab_watershield.insert(shield_instance)
    end

    
    -- Build triggers --
    local function CreateWaterShieldCastTrig()
        local tr = CreateTrigger()
        TriggerRegisterAnyUnitEventBJ(tr, EVENT_PLAYER_UNIT_SPELL_EFFECT)
        TriggerAddAction(tr, WaterShieldCast)
    end
    OnInit.trig(CreateWaterShieldCastTrig)

    local function CreateWaterShieldBlockTrig()
        local tr = CreateTrigger()
        TriggerRegisterVariableEvent( tr, "udg_DamageModifierEvent", EQUAL, 1.00 )
        --TriggerRegisterAnyUnitEventBJ(tr, EVENT_PLAYER_UNIT_DAMAGED)
        TriggerAddAction(tr, WaterShieldBlock)
    end
    OnInit.trig(CreateWaterShieldBlockTrig)
end