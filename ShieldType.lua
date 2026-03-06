do
-- template for shields with charges, e.g. Water Shield with 10 charges
    ChargeShield = {}
    local meta = {}
    setmetatable(ChargeShield, meta)
    setmetatable(ChargeShield, {__index = meta})

    function meta:decrement()
        self.charges = self.charges - 1
        if self.charges == 0 then
            self:destroy()
        end
    end

    function meta:increment()
        self.charges = self.charges + 1
    end

    -- Start counting down the duration of the shield
    function meta:start()
        if self.t then
            TimerStart(self.t, self.dur, false, function()
                self:destroy()
            end)
        end
    end

    -- destructor method
    function meta:destroy()
        DestroyEffect(self.handle)
        -- remove ability from target unit
        -- ... or remove the buff from a dummy-buffer cast
        --
        --
        self.blockamount = 0
        self.handle = nil
        self.target = nil
        self = nil
    end

    -- main creator method
    function meta:new(params)
        local this = {}
        setmetatable(this, {__index = self})

        this.target = params.target or params.target_u or nil
        if this.target == nil then
            print("Critical error: Missing parameter: \"target\" for generating ChargeShield")
            print("Returning empty table")
            return {}
        end
        this.id = GetHandleId(this.target)
        this.alv = params.alv or params.lvl or 1
        this.blockamount = params.blockamount or params.shieldvalue or 0
        this.charges = params.charges or params.n or 1
        this.buffid = fourCC(params.buffid) or nil
        this.dur = params.dur or params.duration or 60
        this.chargefunction = params.func or params.chargefunction or nil
        this.model = params.model or ""
        
        
        -- build new instance
        if this.model ~= "" then
            this.handle = AddSpecialEffectTarget(this.model, target_u, "chest")
        else
            this.handle = nil
        end
        -- add ability to target unit... or use a dummy-buffer? Dunno which is preferred.
        --UnitAddAbility(this.target, this.buffid)
        --SetUnitAbilityLevel(this.target, this.buffid, this.alv+1)
        --BlzUnitHideAbility(this.target, this.buffid, true)
        --
        --
        this.t = CreateTimer()
        return this
    end
    ----------------------------------------------------------------------
end