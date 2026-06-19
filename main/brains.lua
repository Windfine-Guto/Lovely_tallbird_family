local FARM_DEBRIS_TAGS = {"farm_debris"}
local DIG_TAGS = { "DIG_workable", "tree" }
local DIG_CANT_TAGS = { "carnivalgame_part", "event_trigger", "waxedplant" }
local SOILMUST = {"soil"}
local SOILMUSTNOT = {"merm_soil_blocker","farm_debris","NOBLOCK"}
local BrainCommon = require("brains/braincommon")
local function collectdigsites(inst, digsites, tile)
    local cent = Vector3(TheWorld.Map:GetTileCenterPoint(tile[1], 0, tile[2]))
    local soils = TheSim:FindEntities(cent.x, 0, cent.z, 2, SOILMUST, SOILMUSTNOT)
    
    if #soils < 9 then
        local dist = 4/3
        for dx=-dist,dist,dist do
            local dobreak = false
            for dz=-dist,dist,dist do
                local localsoils = TheSim:FindEntities(cent.x+dx,0, cent.z+dz, 0.21, SOILMUST, SOILMUSTNOT)
                if #localsoils < 1 and TheWorld.Map:CanTillSoilAtPoint(cent.x+dx,0,cent.z+dz) then
                    table.insert(digsites,{pos = Vector3(cent.x+dx,0,cent.z+dz), tile = tile })
                end
            end
        end
    end 
    return digsites
end
local function findtillpos(inst)
    local tiles = {}
    
    if not inst.digtile then

        -- collect garden tiles in a 9x9 grid
        local RANGE = 4
        local pos = Vector3(inst.Transform:GetWorldPosition())

        for x=-RANGE,RANGE,1 do
            for z=-RANGE,RANGE,1 do
                local tx = pos.x + (x*4)
                local tz = pos.z + (z*4)
                local tile = TheWorld.Map:GetTileAtPoint(tx, 0, tz)
                if tile == WORLD_TILES.FARMING_SOIL then
                    table.insert(tiles,{tx,tz})
                end
            end
        end
    else
        table.insert(tiles,inst.digtile)
    end

    -- find diggable places in those tiles.
    local digsites = {}
    for i,tile in ipairs(tiles)do
        digsites = collectdigsites(inst,digsites, tile)
    end

    if #digsites > 0 then
        local pos = digsites[math.random(1,#digsites)].pos
        inst.digtile = digsites[math.random(1,#digsites)].tile
        return pos
    end

    inst.digtile = nil
end
local function findTillTarget(inst,finddist)
    return findtillpos(inst)
end
local function findDigTarget(inst,finddist)
    return FindEntity(inst, finddist, nil, FARM_DEBRIS_TAGS)
end
local function TillAction(inst, leaderdist, finddist)
    local pos = findtillpos(inst)
    if pos then

        pos = Vector3(pos.x -0.02 + math.random()*0.04,0,pos.z -0.02 + math.random()*0.04)
        local marker = SpawnPrefab("merm_soil_marker")
        marker.Transform:SetPosition(pos.x,pos.y,pos.z)
        
        return BufferedAction(inst, nil, ACTIONS.TILL, nil, pos )
    end
end

local function DigAction(inst, leaderdist, finddist)
    local target = FindEntity(inst, finddist, nil, FARM_DEBRIS_TAGS)
    if target == nil and inst.components.follower.leader ~= nil then
        target = FindEntity(inst.components.follower.leader, finddist, nil, FARM_DEBRIS_TAGS)
    end

    if target ~= nil then
        if inst.stump_target ~= nil then
            target = inst.stump_target
            inst.stump_target = nil
        end

        return BufferedAction(inst, target, ACTIONS.DIG)
    end
end
local dig_clump_starter = function(inst,finddist)
    local target = findDigTarget(inst,finddist)

    if not target then
        target = findTillTarget(inst,finddist)
    end

    local leaderisdigging = inst.components.follower.leader ~= nil and
                    inst.components.follower.leader.sg ~= nil and
                    inst.components.follower.leader.sg:HasStateTag("digging")

    local leaderistilling = inst.components.follower.leader ~= nil and
                    inst.components.follower.leader.sg ~= nil and
                    inst.components.follower.leader.sg:HasStateTag("tilling")

    return (leaderisdigging or leaderistilling) and (inst.stump_target or target) or nil
end
local dig_clump_keepgoing = function(inst, leaderdist, finddist)
    return inst.stump_target ~= nil
        or (inst.components.follower.leader ~= nil and
            inst:IsNear(inst.components.follower.leader, leaderdist))
end
local dig_clump_finder = function(inst, leaderdist, finddist)
    local action = DigAction(inst, leaderdist, finddist)
    if not action then
        action = TillAction(inst, leaderdist, finddist)
    end
    return action
end

   ----

local function dig_stump_starter(inst,finddist)
    local target = FindEntity(inst, finddist, nil, DIG_TAGS, DIG_CANT_TAGS)
    return inst.stump_target or target or nil
end

local function dig_stump_keepgoing(inst, leaderdist, finddist)
    return inst.stump_target ~= nil
        or (inst.components.follower.leader ~= nil and
            inst:IsNear(inst.components.follower.leader, leaderdist))
end

local function dig_stump_finder(inst, leaderdist, finddist)
    local target = FindEntity(inst, finddist, nil, DIG_TAGS, DIG_CANT_TAGS)
    if target == nil and inst.components.follower.leader ~= nil then
        target = FindEntity(inst.components.follower.leader, finddist, nil, DIG_TAGS, DIG_CANT_TAGS)
    end
    if target ~= nil then
        if inst.stump_target ~= nil then
            target = inst.stump_target
            inst.stump_target = nil
        end

        return BufferedAction(inst, target, ACTIONS.DIG)
    end
end

local function AreDifferentPlatforms(inst, target)
    if inst.components.locomotor.allow_platform_hopping then
        return inst:GetCurrentPlatform() ~= target:GetCurrentPlatform()
    end
    return false
end
local function TryJoust(inst)
    local cd = inst.components.timer and not inst.components.timer:TimerExists("joust_cd")
	if inst.canjoust and cd then
		local target = inst.components.combat.target
		if target then
			local dsq = inst:GetDistanceSqToPoint(target.Transform:GetWorldPosition())
			local range = {min = 8, max = 28}
			if dsq >= range.min * range.min and dsq < range.max * range.max and not AreDifferentPlatforms(inst, target) then
				inst:PushEvent("dojoust", target)
                inst.components.timer:StartTimer("joust_cd",15)
                return true
			end
		end
	end
    return false
end
AddBrainPostInit("smallbirdbrain",function(self)
local FIND_FOOD_HUNGER_PERCENT = 0.75
local SEE_FOOD_DIST = 15
local MIN_FOLLOW_TARGET_DIST     = 5
local DEFAULT_FOLLOW_TARGET_DIST = 8
local MAX_FOLLOW_TARGET_DIST     = 15
local MAX_CHASE_TIME = 10
local EATFOOD_CANT_TAGS = { "INLIMBO", "outofreach" ,"tallbirdegg","deerclops_eyeball",}
local function IsStarving(inst)
    return inst.components.hunger and inst.components.hunger:IsStarving()
end
local function IsHungry(inst)
    return inst.components.hunger and inst.components.hunger:GetPercent() < FIND_FOOD_HUNGER_PERCENT
end
local function CanSeeFood(inst)
	local target = FindEntity(inst, SEE_FOOD_DIST,
		function(item)
			return inst.components.eater:CanEat(item) and item.prefab~="minotaurhorn" and not item.prefab:find("spoiled")
		end,
		nil,
		EATFOOD_CANT_TAGS)
    return target
end
local function FindFoodAction(inst)
    local target = CanSeeFood(inst)
    if target then
        return BufferedAction(inst, target, ACTIONS.EAT)
    end
end

local function GetWaitTarget(inst)
    local target = FindEntity(inst, 16, function(ent)
        local t = ent.components.combat.target
        return inst.components.combat:CanTarget(ent)
           and t
           and (t == inst
                or t:HasTag("player")
                or (t:HasTag("companion") and (not t.components.combat or t.components.combat.target ~= inst)))
    end, {"_combat"})
    inst._wait_target = target
    return target
end
local function ShouldWaitForHelp(inst)
    local leader = inst.components.follower:GetLeader()
    return leader ~= nil and inst.components.health:GetPercent() <= 0.3 and GetWaitTarget(inst)
end

local function WaitTargetDist(inst)
    local target = inst._wait_target
    if target == nil or target.components.combat == nil then
        return DEFAULT_FOLLOW_TARGET_DIST
    end
    return math.max(
        math.sqrt(target.components.combat:CalcAttackRangeSq(inst)) + MIN_FOLLOW_TARGET_DIST,
        DEFAULT_FOLLOW_TARGET_DIST
    )
end

local function GetLeader(inst)
    return inst.components.follower and inst.components.follower:GetLeader()
end

local function GetLeaderPos(inst)
    local leader = GetLeader(inst)
    if not leader then
        return nil
    end

    return leader:GetPosition()
end

local function DanceParty(inst)
    inst:PushEvent("dance")
end

local function ShouldDanceParty(inst)
    local leader = GetLeader(inst)
    return leader ~= nil and leader.sg:HasStateTag("dancing")
end
local function ShouldAttack(self)
    local target = self.inst.components.combat.target
    return target ~= nil and target:IsValid()
    and not self.inst.components.combat:InCooldown()
end
local function GetFollowPos(inst)
    return inst.components.follower.leader and inst.components.follower.leader:GetPosition() or
        inst:GetPosition()
end
local function ShouldNear(inst)
    local is_winter = TheWorld.state.season=="winter"
    local leader = GetLeader(inst)
    local temp = leader and leader.components.timer and leader.components.timer:TimerExists("tallbird_temp_protect")
    return leader~=nil and leader:HasTag("player") and not leader.sg:HasStateTag("moving") and temp and is_winter
end
local function Warm(inst)
    inst:PushEvent("warm")
end
local function ShouldHello(inst)
    local target = inst.components.combat.target
    local leader = GetLeader(inst)
    local friend = FindEntity(inst,10,nil,{"bird_friend"})
    inst._wave_hello_target = friend
    local cooldown = inst.components.timer and inst.components.timer:TimerExists("wave_cd")
    return target==nil and (leader==nil or leader and not leader:HasTag("player")) and friend~=nil and not cooldown
end
local function GetFriendPost(inst)
    if inst._wave_hello_target then
        return inst._wave_hello_target:GetPosition()
    else
        return nil
    end
end
local function Hello(inst)
    inst:PushEvent("wave")
end
local function ShouldEmote(inst)
    local target = inst.components.combat.target
    return inst:HasTag("teenbird") and target==nil and inst.components.timer and not inst.components.timer:TimerExists("emote_cd")
end
local function Emote(inst)
    inst:PushEvent("emote")
end

    table.insert(self.bt.root.children,4,WhileNode(function() return ShouldWaitForHelp(self.inst) end, "WaitingForHelp",
            PriorityNode({
                Follow(self.inst, function() return GetWaitTarget(self.inst) end, MIN_FOLLOW_TARGET_DIST, WaitTargetDist, MAX_FOLLOW_TARGET_DIST),
                StandStill(self.inst)
            })
        )
        )
    table.remove(self.bt.root.children[5].children,1)
    table.insert(self.bt.root.children[5].children,1,ConditionNode(function() 
        return IsStarving(self.inst) and CanSeeFood(self.inst) end, "SeesFoodToEat"))
    table.remove(self.bt.root.children[5].children,3)
    table.insert(self.bt.root.children[5].children,3,DoAction(self.inst, function() 
        return FindFoodAction(self.inst) end))
    table.remove(self.bt.root.children,6)
    table.insert(self.bt.root.children,6,WhileNode(function() return ShouldAttack(self) end, "AttackMomentarily",
			ParallelNodeAny{
			ChaseAndAttack(self.inst, SpringCombatMod(MAX_CHASE_TIME)),
			ConditionWaitNode(function()
				return TryJoust(self.inst)
			end, "Joust"),
		}))
    table.remove(self.bt.root.children[8].children,1)
    table.insert(self.bt.root.children[8].children,1,ConditionNode(function()
        return IsHungry(self.inst) and CanSeeFood(self.inst) end, "SeesFoodToEat"))
    table.remove(self.bt.root.children[8].children,3)
    table.insert(self.bt.root.children[8].children,3,DoAction(self.inst, function() 
        return FindFoodAction(self.inst) end))
    table.insert(self.bt.root.children,9,BrainCommon.NodeAssistLeaderDoAction(self, {
                action = "DIG", 
                starter = dig_clump_starter,
                keepgoing = dig_clump_keepgoing,
                finder = dig_clump_finder,
        }))
    table.insert(self.bt.root.children,10,BrainCommon.NodeAssistLeaderDoAction(self, {
                action = "CHOP",
                starter = dig_stump_starter,
                keepgoing = dig_stump_keepgoing,
                finder = dig_stump_finder,
            }))
    table.insert(self.bt.root.children,11,BrainCommon.NodeAssistLeaderDoAction(self, {
            action = "CHOP", 
        }))
    table.insert(self.bt.root.children,12,BrainCommon.NodeAssistLeaderDoAction(self, {
            action = "MINE", 
        }))
    table.insert(self.bt.root.children,3,WhileNode(function() return ShouldDanceParty(self.inst) end, "Dance Party",
        PriorityNode({
            Leash(self.inst, GetLeaderPos, TUNING.ABIGAIL_DEFENSIVE_MED_FOLLOW, TUNING.ABIGAIL_DEFENSIVE_MED_FOLLOW),
            ActionNode(function() DanceParty(self.inst) end),
    })))
    table.insert(self.bt.root.children,8,WhileNode(function() return self.inst:HasTag("teenbird") and self.inst.components.combat.target ~= nil and self.inst.components.combat:InCooldown() end, "Dodge",
            RunAway(self.inst, function() return self.inst.components.combat.target end, 5, 8)))
    table.remove(self.bt.root.children[7].children,3)
    table.insert(self.bt.root.children,11,
    FindFarmPlant(self.inst, ACTIONS.INTERACT_WITH, true, GetFollowPos))
    table.insert(self.bt.root.children,9,WhileNode(function() return ShouldNear(self.inst) end, "Near Leader",
        PriorityNode({
            Leash(self.inst, GetLeaderPos, 4, 1.5),
            ActionNode(function() Warm(self.inst) end),
    })))
    table.insert(self.bt.root.children,12,WhileNode(function() return ShouldHello(self.inst) end, "Hello",
        PriorityNode({
            Leash(self.inst, GetFriendPost, 5, 5),
            ActionNode(function() Hello(self.inst) end),
    })))
    table.insert(self.bt.root.children,18,WhileNode(function() return ShouldEmote(self.inst) end, "Emote",
        ActionNode(function() Emote(self.inst) end)
    ))
end)
AddBrainPostInit("tallbirdbrain", function(self)
local THREAT_CANT_TAGS = {'tallbird', 'notarget','teenbird','smallbird','bird_friend'}
local THREAT_ONEOF_TAGS = {'character', 'animal','monster'}
local START_FACE_DIST = 6
local MIN_FOLLOW_DIST = 2
local MAX_FOLLOW_DIST = 10
local TARGET_FOLLOW_DIST = (MAX_FOLLOW_DIST+MIN_FOLLOW_DIST)/2
local MAX_CHASE_TIME      = 20
local MAX_CHASE_DIST      = 40
local RUN_AWAY_DIST       = 8
local STOP_RUN_AWAY_DIST  = 10
local function GetNearbyThreatFn(inst)
    return FindEntity(inst, START_FACE_DIST, nil, nil, THREAT_CANT_TAGS, THREAT_ONEOF_TAGS)
end
local function DefendHomeAction(inst)
    if inst.components.homeseeker and
       inst.components.homeseeker:HasHome() then
        return BufferedAction(inst, inst.components.homeseeker.home, ACTIONS.WALKTO, nil, nil, nil, 0.2)
    end
end
local function GetLeader(inst)
    return inst.components.follower and inst.components.follower:GetLeader()
end
local function GetTraderFn(inst)
    return inst.components.follower.leader ~= nil
        and inst.components.trader:IsTryingToTradeWithMe(inst.components.follower.leader)
        and inst:HasTag("companion")
        and inst.components.follower.leader
        or nil
end
local function KeepTraderFn(inst, target)
    return inst.components.trader:IsTryingToTradeWithMe(target)
end
local function GoHomeAction(inst)
    if inst.components.homeseeker and
       inst.components.homeseeker:HasHome() and not inst.components.follower.leader and not inst:IsNear(inst.components.homeseeker.home, 2) then
        return BufferedAction(inst, inst.components.homeseeker.home, ACTIONS.GOHOME, nil, nil, nil, 0.2)
    end
end
local function ShouldAttack(self)
    local target = self.inst.components.combat.target
    return target ~= nil and target:IsValid()
    and not self.inst.components.combat:InCooldown()
end

local function GetLeaderPos(inst)
    local leader = GetLeader(inst)
    if not leader then
        return nil
    end

    return leader:GetPosition()
end

local function DanceParty(inst)
    inst:PushEvent("dance")
end

local function ShouldDanceParty(inst)
    local leader = GetLeader(inst)
    return leader ~= nil and leader.sg:HasStateTag("dancing")
end
local function GetFollowPos(inst)
    return inst.components.follower.leader and inst.components.follower.leader:GetPosition() or
        inst:GetPosition()
end
local function ShouldNear(inst)
    local is_summer = not TheWorld:HasTag("cave") and TheWorld.state.season=="summer"
    local is_winter = TheWorld.state.season=="winter"
    local leader = GetLeader(inst)
    local temp = leader and leader.components.timer and leader.components.timer:TimerExists("tallbird_temp_protect")
    return leader and leader:HasTag("player") and not leader.sg:HasStateTag("moving") and temp and (is_summer or is_winter)
end
local function Warm(inst)
    inst:PushEvent("warm")
end
local function ShouldHello(inst)
    local target = inst.components.combat.target
    local leader = GetLeader(inst)
    local friend = FindEntity(inst,10,nil,{"bird_friend"})
    inst._wave_hello_target = friend
    local cooldown = inst.components.timer and inst.components.timer:TimerExists("wave_cd")
    return target==nil and (leader==nil or leader and not leader:HasTag("player")) and friend~=nil and not cooldown
end
local function GetFriendPost(inst)
    if inst._wave_hello_target then
        return inst._wave_hello_target:GetPosition()
    else
        return nil
    end
end
local function Hello(inst)
    inst:PushEvent("wave")
end
local function ShouldEmote(inst)
    local target = inst.components.combat.target
    return target==nil and inst.components.timer and not inst.components.timer:TimerExists("emote_cd") and math.random() < 0.5
end
local function Emote(inst)
    inst:PushEvent("emote")
end

    table.remove(self.bt.root.children,4)
    table.insert(self.bt.root.children,4,WhileNode(function() return self.inst.components.homeseeker and self.inst.components.homeseeker:HasHome() and GetNearbyThreatFn(self.inst.components.homeseeker.home) end, "ThreatNearNest",
				DoAction(self.inst, function() return DefendHomeAction(self.inst) end, "GoHome", true)
			))
    table.remove(self.bt.root.children,5)
    table.insert(self.bt.root.children,5,WhileNode(function() return not TheWorld.state.isday and not self.inst.components.follower.leader end, "IsNight",
				DoAction(self.inst, function() return GoHomeAction(self.inst) end, "GoHome", true)
			))
    table.remove(self.bt.root.children,3)
    table.insert(self.bt.root.children,3,WhileNode(function() return ShouldAttack(self) end, "AttackMomentarily",
			ParallelNodeAny{
				ChaseAndAttack(self.inst, SpringCombatMod(MAX_CHASE_TIME), SpringCombatMod(MAX_CHASE_DIST)),
				ConditionWaitNode(function()
					return TryJoust(self.inst)
				end, "Joust"),
		}))
    table.insert(self.bt.root.children,4,WhileNode(function() return self.inst.components.combat.target ~= nil and self.inst.components.combat:InCooldown() end, "Dodge",
            RunAway(self.inst, function() return self.inst.components.combat.target end, RUN_AWAY_DIST, STOP_RUN_AWAY_DIST)))
    table.insert(self.bt.root.children,9,Wander(self.inst, function() if not self.inst.components.follower.leader then return self.inst.components.knownlocations:GetLocation("home") end end, 16))
    table.insert(self.bt.root.children,9,Wander(self.inst, function() if self.inst.components.follower.leader then return Vector3(self.inst.components.follower.leader.Transform:GetWorldPosition()) end end, MAX_FOLLOW_DIST- 1, {minwalktime=.5, randwalktime=.5, minwaittime=6, randwaittime=3}))
    table.remove(self.bt.root.children,11)
    table.insert(self.bt.root.children,3,FaceEntity(self.inst, GetTraderFn, KeepTraderFn))
    table.insert(self.bt.root.children,7,SequenceNode{
            ParallelNodeAny {
                WaitNode(math.random()*.5),
                    Follow(self.inst, GetLeader, 
    MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST),
            }
        })
    table.insert(self.bt.root.children,10,BrainCommon.NodeAssistLeaderDoAction(self, {
                action = "DIG", 
                starter = dig_clump_starter,
                keepgoing = dig_clump_keepgoing,
                finder = dig_clump_finder,
        }))
    table.insert(self.bt.root.children,11,BrainCommon.NodeAssistLeaderDoAction(self, {
                action = "CHOP",
                starter = dig_stump_starter,
                keepgoing = dig_stump_keepgoing,
                finder = dig_stump_finder,
            }))
    table.insert(self.bt.root.children,12,BrainCommon.NodeAssistLeaderDoAction(self, {
            action = "CHOP",
        }))
    table.insert(self.bt.root.children,13,BrainCommon.NodeAssistLeaderDoAction(self, {
            action = "MINE",
        }))
    table.insert(self.bt.root.children,3,WhileNode(function() return ShouldDanceParty(self.inst) end, "Dance Party",
        PriorityNode({
            Leash(self.inst, GetLeaderPos, TUNING.ABIGAIL_DEFENSIVE_MED_FOLLOW, TUNING.ABIGAIL_DEFENSIVE_MED_FOLLOW),
            ActionNode(function() DanceParty(self.inst) end),
    })))
    table.insert(self.bt.root.children,11,
    FindFarmPlant(self.inst, ACTIONS.INTERACT_WITH, true, GetFollowPos))
    table.insert(self.bt.root.children,7,WhileNode(function() return ShouldNear(self.inst) end, "Near Leader",
        PriorityNode({
            Leash(self.inst, GetLeaderPos, 4, 1.5),
            SequenceNode({ConditionNode(function() return TheWorld.state.season=="winter" end,"Winter"),
            ActionNode(function() Warm(self.inst) end),
        }),
            SequenceNode({ConditionNode(function() return not TheWorld:HasTag("cave") and TheWorld.state.season=="summer" end,"Summer"),
            StandStill(self.inst),
        }),
    })))
    table.insert(self.bt.root.children,13,WhileNode(function() return ShouldHello(self.inst) end, "Hello",
        PriorityNode({
            Leash(self.inst, GetFriendPost, 5, 5),
            ActionNode(function() Hello(self.inst) end),
    })))
    table.insert(self.bt.root.children,19,WhileNode(function() return ShouldEmote(self.inst) end, "Emote",
        ActionNode(function() Emote(self.inst) end)
    ))
end)