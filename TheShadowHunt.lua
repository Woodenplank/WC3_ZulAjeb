do

    -- bemærk at de her ikke behøves være lokale.
    -- Faktisk ville det være smart, at have dummy_utype erklæret et sted som en global variabel, siden den skal gebruges mange steder.
    local ShadHunt_id = FourCC('o000')
    local dummytype_id = FourCC('o001')
    local ShadHunt_spell_id = FourCC('A000')

    -- the basic part of the tooltip
    local ShadHunt_tooltip = "Increases physical damage dealt by 5%. Every time the Hero deals spell damage, there is a 10% to increase the damage bonus by 2% for 10 seconds. Stacks up to a 25% damage increase.|n|n|cffffcc00Bonus:|r "

    -- table for storing ShadowHunt values
    ShadHunt_values = {}

    --[[
        Nu til de egentlige triggers...
        De fire lokale variable ovenfor, er bare for at gøre nedenstående nemmere at forstå.
        Og så skal man heller ikke copy-paste alle mulige steder, hvis noget skal ændres.

        Den vigtige er 
            Shadhunt_values = {}
        Det er en tabel i lua. Ligesom "create hashtable; set ShadowHunt_hash = LastCreatedHashtable" i GUI.
        Her erklærer vi den bare ude i det fri - så ved lua den er global.
        Du kan se senere, hvorfor det er smartere <3
    ]]


    -- ================================================================================================================ --
    local function ShadowHuntPreDamage()
        -- exit early if it's spell damage
		if udg_IsDamageSpell == true then
			return
		end
        
        udg_DamageFilterSource = ShadHunt_id -- ved ikke hvordan Bribe har lavet det; jeg antager det ville ligne JASS-modsvaret
        local u = udg_DamageEventSource
        local id = GetHandleId(u)

        -- sets the damage modifier by fetching table value for unit's handle id
        -- If no table value exists for that id (field == nil), then defaults to 0.05
        -- This means we don't even need an initialization trigger to set the default values.
        local dmg_mod = 1 + (ShadHunt_values[id] or 0.05)
        
        -- update the GUI variable
        udg_DamageEventAmount = udg_DamageEventAmount * dmg_mod
        -- END --
    end

    -- ================================================================================================================ --
    local function ShadowHuntOnDamage()
        -- exit early if not spell damage
		if udg_IsDamageSpell == false then
			return
		end

        local u = udg_DamageEventSource -- just a local reference copy, for easier writing
        local id = GetHandleId(u)
        if (math.random(1,10) == 1) then
            local x,y = GetUnitX(u), GetUnitY(u)
            local dummy = CreateUnit(GetOwningPlayer(u), dummytype_id, x, y, 0)
            UnitApplyTimedLifeBJ(3.0, FourCC('BTLF'), dummy)
            UnitAddAbilityBJ(FourCC('A001'), dummy)
            IssueTargetOrderBJ(dummy, "innerfire", u)

            -- buff timer
            local t = CreateTimer()
            TimerStart(t, 10, false, function()
                -- Once timer expires, purge buff...
                UnitRemoveBuffBJ( FourCC('B000'), u)

                -- Update table and tooltip
                ShadHunt_values[GetHandleId(u)] = 0.05
                BlzSetAbilityExtendedTooltip(ShadHunt_spell_id, ((ShadHunt_tooltip + tostring(5) + "%." )), 0)

                -- Cleanup
                PauseTimer(t)
                DestroyTimer(t)
            end)
        end

        -- If no table value exists for that id (field == nil), then defaults to 0.05
        local huntvalue = ShadHunt_values[id] or 0.05
        if (huntvalue < 0.25) then
            // save new value to hash
            huntvalue = huntvalue + 0.02

            -- Save new value to table and update tooltip
            ShadHunt_values[id] = huntvalue
            BlzSetAbilityExtendedTooltip(ShadHunt_spell_id, ((ShadHunt_tooltip + tostring(huntvalue*100) + "%." )), 0)
        end
        -- END --
    end

    
    --[[
            Nedenstående måde at bygge Triggers på kræver Bribe's "Global Initialization"
            Den er alligevel indkluderet i Lua versionen af Damage Engine, så burde ikke være noget problem.
    ]]
    
    ------ Create PreDamage trigger ------
    local function CreatePreDamTrigger()
        local trg = CreateTrigger()
        TriggerRegisterVariableEvent(trg, "udg_PreDamageEvent", EQUAL, 0.00)
        TriggerAddAction(trg, ShadowHuntPreDamage)
    end
    OnInit.trig(CreatePreDamTrigger)

    ------ Create OnDamage trigger ------
    local function CreateOnDamTrigger()
        local trg = CreateTrigger()
        TriggerRegisterVariableEvent(trg, "udg_OnDamageEvent", EQUAL, 0.00)
        TriggerAddAction(trg, ShadowHuntOnDamage)
    end

    OnInit.trig(CreateOnDamTrigger)
end