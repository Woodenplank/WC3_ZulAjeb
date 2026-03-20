-- requires Mine.lua
do
    --[[
    A trap on the ground - arms when someone gets close, then explodes shortly after.
    Note that this requires continuous tracking, checking if there are units within range of the i'th trap.
    As such, unless they're very prevalent, this should probably just be a brief segment of the map.
    And then it can get turned off later


    Alternatively, if the map has multiple segments with poison traps like this, you can easily modify
    setupmines() to take a table of regions as its input, and then run different instances of this function
    as different parts of the map are entered (by Players exploring a dungeon?)
    ]]

    -- regions on the map, at center of which mushrooms are placed
    mushroom_coords = {
        {x=GetRectCenterX(____), y=GetRectCenterY(____)},
        {x=GetRectCenterX(____), y=GetRectCenterY(____)},
        {x=GetRectCenterX(____), y=GetRectCenterY(____)},
        {x=GetRectCenterX(____), y=GetRectCenterY(____)},
    }
    mushroom_bombs = {}

    local function setupmines()
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
        
        -- Spawn a list of mushrooms, from the set of coordinate regions
        local mushroom_count=0
        for idx,coords in mushroom_coords do
            baseparams.x = mushroom_coords[x]
            baseparams.y = mushroom_coords[y]
            local bomb = Mine:create(baseparams)
            mushroom_count = mushroom_count+1

            -- adds a "hitscanner" functionality to the spawned mushroom
            -- this allows us to quickly check later, if a unit is in range
            function bomb:hitscan()
                -- create a Unit Group Object and Filter Condition
                local ug = CreateGroup()
                local cond = Condition(function() local fu= GetFilterUnit()
                    return IsUnitEnemy(fu, self.owner)
                    and not IsUnitType(fu, UNIT_TYPE_DEAD)
                    and not IsUnitInGroup(fu, self.hit)
                end)
                -- group units within range of the mushroom's (x,y)-coordinates
                GroupEnumUnitsInRange(ug, self.coords.x, self.coords.y, self.collision, cond)
                local did_collide = (CountUnitsInGroup(ug)>0)
                -- cleanup memory
                DestroyGroup(ug)
                DestroyCondition(cond)
                -- true if unit group was non-empty. Otherwise false.
                return did_collide
            end

            -- Insert the newly created mushroom into a table
            table.insert(mushroom_bombs,bomb)
        end


        -- And now we need to track if someone walks close to them
        local t = CreateTimer()
        TimerStart(t, 0.5, function()
            for idx, mine for pairs(mushroom_bombs) do
                if mine:hitscan() then
                    -- if a mushroom 'finds' an enemy within range, it is activated
                    mine:arm()
                    mine:flagdynamic()

                    -- remove the mushroom from the table, to prevent multiple activations
                    table.remove(mushroom_bombs, idx)
                    mushroom_count = mushroom_count-1
                end
            end

            -- check if all mushrooms have been detonated.
            if (mushroom_count<=0) then
                PauseTimer(t)
                DestroyTimer(t)
                mushroom_bombs = nil
                mushroom_coords= nil
            end
        end)
        -- END --
    end

    -- Build trigger --
    local function CreateTrig()
        local tr = CreateTrigger()
        TriggerRegisterTimerEventSingle(tr, 5)
        TriggerAddAction(tr, setupmines)
    end
    OnInit.trig(CreateTrig)
end