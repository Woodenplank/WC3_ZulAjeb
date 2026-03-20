--[[
    Application (ideas)

    WAVE ATTACK, with warning before each segment blows up (deals damage)
    ------------------------------------------------------------------------------------------------------------------------------------
    [...]
        local abilId = GetSpellAbilityId()
        if abilId ~= warnwave_test_id then
            return
        end
        local caster = GetTriggerUnit()

        local mine_dmg = 90
        local mine_aoe = 70
        local mine_armtime = 2.0
        paramset = {
            x=nil,
            y=nil,
            z=5,
            source = caster,
            dur = mine_armtime,
            aoe = mine_aoe,
            dmg = mine_dmg,
            scale1 = 0.8,
            modelwarn = "Abilities\\Spells\\Orc\\LightningBolt\\LightningBoltMissile.mdl",
            modelblow = "Abilities\\Spells\\Other\\Monsoon\\MonsoonBoltTarget.mdl"
        }

        local cast_x, cast_y = GetUnitX(caster), GetUnitY(caster)
        local targ_x, targ_y = GetSpellTargetX(), GetSpellTargetY()
        local ang = AngleBetweenCoords(cast_x, targ_x, cast_y, targ_y)
        local slicewidth = 100 * math.pi/180    -- 'degrees to radians'
        local ang_l = ang - slicewidth/2
        local ang_r = ang + slicewidth/2

        -- build "triangular" cone
        local spawncount = 1
        local diststep = 60
        local dist_current = diststep
        local range = 700
        local waves = math.floor(range/diststep)

        local t = CreateTimer()
        local delay = 0.3
        TimerStart(t, delay, true, function()
            if dist_current <= range then
                local angstep = (slicewidth/spawncount)
                local ang_current = ang_l-angstep/2
                for i=1, spawncount do
                    local x,y = PolarStep(cast_x, cast_y, dist_current, ang_current + angstep)
                    paramset.x = x
                    paramset.y = y
                    local bomb = Mine:create(paramset)
                    bomb:arm()
                    ang_current = ang_current + angstep
                end

                -- increment for next
                dist_current = dist_current + diststep
                spawncount = spawncount +1
            else
                PauseTimer(t)
                DestroyTimer(t)
            end
        end)
    [...]
    ------------------------------------------------------------------------------------------------------------------------------------
    
    A trap on the ground - arms when someone gets close
    Note that this requires continuous tracking, checking if there are units within range of the i'th trap.
    As such, unless they're very prevalent, this should probably just be a brief segment of the map.
    And then it can get turned off later
    ------------------------------------------------------------------------------------------------------------------------------------
    [...]
    local function deploymines()
        local mine_dmg = 100
        local mine_aoe = 150
        local mine_armtime = 2.0
        baseparams = {
            x=nil,
            y=nil,
            z=0,
            source = Player(28), --I think this is neutral hostile? Adjust as needed...
            dur = mine_armtime,
            aoe = mine_aoe,
            dmg = mine_dmg,
            scale1 = 0.3,
            modelwarn = "Mushroom01.mdx",
            modelblow = "Abilities\\Weapons\\GreenDragonMissile\\GreenDragonMissile.mdl"
        }
        local range = 500
        local number=11

        for i=1,number do
            local dist = math.random()*range
            local ang = math.random()*2*math.pi
            local new_x = 0 + dist * math.cos(ang)      -- this exists in Geometry.lua
            local new_y = 0 + dist * math.sin(ang)      -- this exists in Geometry.lua
            baseparams.x = new_x
            baseparams.y = new_y
            local bomb = Mine:create(baseparams)
        end
    end

    -- Build trigger --
    local function CreateTrig()
        local tr = CreateTrigger()
        TriggerRegisterTimerEventSingle(tr, 5)
        TriggerAddAction(tr, deploymines)
    end
    OnInit.trig(CreateTrig)
    

    -- And now we need to track if someone walks close to them
    [...]
]]


-- ================================================================================================================== --
-- ============================================== Metatable definition ============================================== --
-- ================================================================================================================== --

do
    Mine = {}
    local meta = {}
    setmetatable(Mine,meta)
    setmetatable(Mine, {__index = meta})

    -- ============================================== creator and destructor methods ============================================== --

    function meta:create(params)
        local this = {}
        setmetatable(this, {__index = self})

        -- timing
        this.armed = false
        this.t = nil
        this.dynamic = false
        this.td = nil

        -- origin
        this.source = params.source or params.u or nil
        this.x = params.x or 0
        this.y = params.y or 0
        this.z = params.z or params.height or 0

        -- stats
        this.dur = params.dur or params.duration or 1
        this.lifetime = 0
        this.dmg = params.dmg or params.damage or 0
        this.aoe = params.aoe or params.area or 90

        -- aesthetics        
        this.modelwarn = params.model1 or params.modelwarn or ""
        this.modelblow = params.model2 or params.modelblow or ""
        this.scale1 = params.scalestart or params.scale1 or 1
        this.alpha1 = params.alphastart or params.alpha1 or 255
        this.scale2 = params.scaleend or params.scale2 or 1
        this.alpha2 = params.alphaend or params.alpha2 or 255

        -- values for storing current scale and alpha
        -- (There is no native to GetSpecialEffectAlpha(), so we must track it)
        this.s = this.scale1
        this.a = this.alpha1

        -- Special Effect
        if this.modelwarn ~= "" then
            this.handle = AddSpecialEffect(this.modelwarn, this.x, this.y)
            BlzSetSpecialEffectHeight(this.handle, this.z)
            BlzSetSpecialEffectScale(this.handle, this.scale1)
            BlzSetSpecialEffectAlpha(this.handle, this.alpha1)
        else
            this.handle = nil
        end

        return this
    end

    function meta:destroy()
        -- This method destroys the mine WITHOUT explosion or SFX
        -- Strictly a memory cleanup
        if self.handle then 
            DestroyEffect(self.handle)
            self.handle = nil
        end
        if self.armed then
            PauseTimer(self.t)
            DestroyTimer(self.t)
            self.armed = nil
        end
        if self.dynamic then
            PauseTimer(self.td)
            DestroyTimer(self.td)
            self.dynamic = nil
        end
    end

    -- ============================================== Explosive methods ============================================== --

    function meta:arm()
        -- early return if already armed
        if self.armed then 
            return
        end

        -- start a timer for self-detonation
        self.t = CreateTimer()
        TimerStart(self.t, self.dur, false, function()
            self:detonate()
        end)
        self.armed = true
    end

    function meta:detonate()
        -- Make a new "modelblow" model for blowing up, if one is given
        -- delete (previous) mine model
        if self.handle and self.modelblow~="" then
            DestroyEffect(self.handle)
            DestroyEffect(AddSpecialEffect(self.modelblow, self.x, self.y))
        end

        -- Area damage
        local ug = CreateGroup()
        local p = GetOwningPlayer(self.source)
        local cond = Condition(function() 
            local fu= GetFilterUnit()
            return IsUnitEnemy(fu, p)
                and not IsUnitType(fu, UNIT_TYPE_DEAD)
                and not IsUnitInGroup(fu, self.hit)
        end)
        GroupEnumUnitsInRange(ug, self.x, self.y, self.aoe, cond)
        ForGroup(ug, function()
            local pu = GetEnumUnit()
            UnitDamageTarget(self.source, pu, self.dmg, true, false, ATTACK_TYPE_NORMAL, DAMAGE_TYPE_NORMAL, nil)
        end)

        -- clean temp memory
        DestroyGroup(ug)
        DestroyCondition(cond)

        -- misc cleanup
        if self.armed then
            PauseTimer(self.t)
            DestroyTimer(self.t)
        end
        if self.dynamic then
            PauseTimer(self.td)
            DestroyTimer(self.td)
        end
    end

    -- ============================================== Visual settings ============================================== --
    
    function meta:flagdynamic()
        -- if dynamic==true already, undo it
        if self.dynamic then
            self.dynamic = false
            PauseTimer(self.td)
            DestroyTimer(self.td)
            return false
        end

        -- Start dynamic mode
        self.dynamic = true
        -- dynamic step values
        local t_interval = 0.1
        local alphastep = ((self.alpha2 - self.alpha1) / self.dur) * t_interval
        local scalestep = ((self.scale2 - self.scale1) / self.dur) * t_interval

        -- Periodic update
        self.td = CreateTimer()
        TimerStart(self.td, t_interval, true, function()
            self.a = self.a + alphastep
            self.s = self.s + scalestep
            BlzSetSpecialEffectAlpha(self.handle, self.a)
            BlzSetSpecialEffectScale(self.handle, self.s)
            
            -- check if lifetime ended
            self.lifetime = self.lifetime + t_interval
            if self.lifetime >= self.dur then
                PauseTimer(self.td)
                DestroyTimer(self.td)
                self.dynamic = false                
            end
        end)
    end

    -- END --
end