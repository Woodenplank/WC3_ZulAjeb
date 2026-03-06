-- work in progress. Do not import.
do
    Spell = setmetatable({},{})
    local mt = getmetatable(Spell)
    mt.__index = mt
    mt.__newindex = mt

---------------------------------- _________________ ----------------------------------

    function mt:Create(abilID, target_type)
        local this = setmetatable({}, {__index = self})
        this.id = FourCC(abilID)
        this.target_type = target_type

        -- [[ The below causes a CTD when booting up a WC3 map. ]]
        -- [[ TODO: Investigate! ]]

        -- if (type(abilID) == "string") then
        --     print("got string")
        --     this.id = FourCC(abilID)
        -- elseif (type(abilID) == "number") then
        --     print("got number")
        --     this.id = abilID
        -- else
        --     print("Invalid abilID supplied. Expected 4-letter string or number but got "..tostring(abilID))
        --     return nil
        -- end
        -- print("Set abilID = "..tostring(abilID))
        -- if type(target_type) ~= "string" then
        --     print("Attempted to assign non-string as target type... Aborting spell id"..tostring(this.id))
        --     return nil
        -- end
        -- target_type=tolower(target_type)
        -- if (target_type == "point" or target_type == "unit" or target_type == "instant" or target_type == "unit_or_point") then
        --     this.target_type = target_type
        -- else
        --     print("Could not recognize target_type for abilID"..tostring(abilID)..". Expected point/unit/instant, but got "..tostring(target_type))
        --     return nil
        -- end
        -- print("Targeting type = "..tostring(target_type))

        return this
    end


    function mt:MakeTrigger(func)
        local function t()
            local trg = CreateTrigger()
            TriggerRegisterAnyUnitEventBJ(trg, EVENT_PLAYER_UNIT_SPELL_EFFECT)
            TriggerAddAction(trg, func)
        end
        OnInit.trig(t)
    end


    -- for spell instances
    function mt:NewInstance()
        local new = {}
        new.caster = GetTriggerUnit()
        new.castplayer = GetOwningPlayer(new.caster)
        new.alv = GetUnitAbilityLevel(new.caster, self.id) - 1
        new.normaldur = GetAbilityField(self.id, "normaldur", new.alv)
        new.herodur = GetAbilityField(self.id, "herodur", new.alv)
        new.aoe = GetAbilityField(self.id, "aoe", new.alv)
        new.range= GetAbilityField(self.id, "range", new.alv)
        new.cast_x = GetUnitX(new.caster)
        new.cast_y = GetUnitY(new.caster)
        -- 'Targetting'-specific getters
        if self.target_type == "unit" or self.target_type == "unit target" then
            new.target = GetSpellTargetUnit()
            new.targ_x = GetUnitX(new.target)
            new.targ_y = GetUnitY(new.target)
        elseif self.target_type == "point" or self.target_type == "point target" then
            new.targ_x = GetSpellTargetX()
            new.targ_y = GetSpellTargetY()
        elseif self.target_type == "instant" or self.target_type == "instant (no target)" then
            new.targ_x = new.cast_x
            new.targ_y = new.cast_y
        else -- safety
            new.targ_x = nil
            new.targ_y = nil
            new.target = nil
        end
    
        return setmetatable(new, { __index = self })
    end
-- END DO --
end