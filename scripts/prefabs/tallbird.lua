local brain = require "brains/tallbirdbrain"

local assets =
{
    Asset("ANIM", "anim/ds_tallbird_basic.zip"),
    Asset("ANIM", "anim/wilsontallbird.zip"),
    Asset("SOUND", "sound/tallbird.fsb"),
}

local prefabs =
{
    "meat",
    "tallbirdcorpse",
}

local sounds =
{
    walk = "dontstarve/beefalo/walk",
    grunt = "dontstarve/creatures/tallbird/chirp",
    yell = "dontstarve/creatures/tallbird/attack",
    swish = "dontstarve/creatures/tallbird/scratch_ground",
    curious = "dontstarve/creatures/teenbird/chirp",
    angry = "dontstarve/creatures/tallbird/chirp",
    sleep = "dontstarve/creatures/tallbird/sleep",
}

local loot = { "meat", "meat" }
local MAX_CHASEAWAY_DIST = 32
local MAX_CHASE_DIST = 256

local RETARGET_MUST_TAGS = { "_combat", "_health" }
local RETARGET_CANT_TAGS_HOME={"tallbird","teenbird","smallbird","bird_friend"}
local RETARGET_CANT_TAGS = { "tallbird","teenbird","smallbird","player",
"glommer","chester","companion","beefalo","hutch","abigail" }
local RETARGET_ONEOF_TAGS = { "animal","monster","pig" }
local RETARGET_ANIMAL_ONEOF_TAGS = { "animal", "monster","character" }
local function Retarget(inst)
    local function IsValidTarget(guy)
        return not guy.components.health:IsDead()
            and inst.components.combat:CanTarget(guy)
            and (not inst:HasTag("smallbird") or inst:HasTag("companion"))
    end
    return --Threat to nest
        inst.components.homeseeker ~= nil and
        inst.components.homeseeker:HasHome() and
        FindEntity(
            inst.components.homeseeker.home,
            SpringCombatMod(TUNING.TALLBIRD_DEFEND_DIST/2),
            IsValidTarget,
            RETARGET_MUST_TAGS,
            RETARGET_CANT_TAGS_HOME,
            RETARGET_ANIMAL_ONEOF_TAGS)
        or
        FindEntity(
            inst,
            SpringCombatMod(TUNING.TALLBIRD_TARGET_DIST*2),
            IsValidTarget,
            RETARGET_MUST_TAGS,
            RETARGET_CANT_TAGS,
            RETARGET_ONEOF_TAGS)
end

local function ShouldAcceptItem(inst, item)
    if item.components.edible and inst.components.eater and not item:HasTag("tallbirdegg") then
        if inst.components.health then
            inst.components.health:DoDelta(inst.components.health.maxhealth*.2,nil,item)
        end
        inst.sg:GoToState("eat")
        return inst.components.eater:CanEat(item)
    end
end
local function OnGetItemFromPlayer(inst, giver, item)
    if inst.components.sleeper then
        inst.components.sleeper:WakeUp()
    end
    if item.components.edible then
        if inst.components.combat.target and inst.components.combat.target == giver then
            inst.components.combat:SetTarget(nil)
        end
        if giver.components.leader and giver:HasTag("bird_family") then
            if inst.components.bird_cultivate and inst.components.follower and not inst.components.follower.leader then
                giver:PushEvent("makefriend")
                giver.components.leader:AddFollower(inst)
                inst.components.bird_cultivate.follow=true
                inst.components.bird_cultivate.wild=false
                inst.components.bird_cultivate:Updata()
            end
        end
    end
end

local function KeepTarget(inst, target)
    local home = inst.components.homeseeker ~= nil and inst.components.homeseeker.home or nil
    --In case of no home, just say keep the target
    --If there is an egg thief, then chase up to MAX_CHASE_DIST from home
    --Otherwise, only chase up to MAX_CHASEAWAY_DIST from home
    return home == nil or
        inst:IsNear(home,
            target == home.thief and
            home.components.pickable ~= nil and
            not home.components.pickable:CanBePicked() and
            SpringCombatMod(MAX_CHASE_DIST) or
            SpringCombatMod(MAX_CHASEAWAY_DIST))
end

local function ShouldSleep(inst)
    return DefaultSleepTest(inst) and inst.components.follower:IsNearLeader(7)
end

local function ShouldWake(inst)
    return DefaultWakeTest(inst) or not inst.components.follower:IsNearLeader(10)
end

local function CanShareTargetWith(dude)
    return dude:HasTag("tallbird") and not dude.components.health:IsDead()
end

local function OnAttacked(inst, data)
    if data.attacker == nil then
        return
    end
    if data.attacker ~= nil and inst.components.combat then
        inst.components.combat:ShareTarget(data.attacker, 30, CanShareTargetWith,3)
    end
    local current_target = inst.components.combat.target

    if current_target == data.attacker then
        --Already targeting our attacker, just update the time
        inst._last_attacker = current_target
        inst._last_attacked_time = GetTime()
        return
    end

    if current_target ~= nil then
        local home = inst.components.homeseeker ~= nil and inst.components.homeseeker.home or nil
        if home ~= nil and
            current_target == home.thief and
            home.components.pickable ~= nil and
            home.components.pickable:CanBePicked() then
            --Don't change target from our egg thief!
            return
        end

        local time = GetTime()
        if inst._last_attacker == current_target and
            inst._last_attacked_time + TUNING.TALLBIRD_ATTACK_AGGRO_TIMEOUT >= time then
            --Our target attacked us recently, stay on it!
            return
        end

        --Switch to new target
        inst.components.combat:SetTarget(data.attacker)
        inst._last_attacker = data.attacker
        inst._last_attacked_time = time

    elseif inst.components.combat:SuggestTarget(data.attacker) then
        inst._last_attacker = data.attacker
        inst._last_attacked_time = GetTime()
    end
end

local MAKE_NEXT_EXCLUDE_TAGS = {"tallbird"}

local function CanMakeNewHome(inst)
	if inst.components.homeseeker == nil and not inst.components.combat:HasTarget() then
		local x, y, z = inst.Transform:GetWorldPosition()
		local tile = TheWorld.Map:GetTileAtPoint(x, y, z)
		return (tile == WORLD_TILES.ROCKY or tile == WORLD_TILES.DIRT) and TheSim:CountEntities(x, y, z, TUNING.TALLBIRD_MAKE_NEST_RADIUS, nil, MAKE_NEXT_EXCLUDE_TAGS) == 0
	end
end

local function MakeNewHome(inst)
	if inst:CanMakeNewHome() then
		local nest = SpawnPrefab("tallbirdnest")
		nest.Transform:SetPosition(inst.Transform:GetWorldPosition())
		nest.components.pickable:MakeEmpty()
		nest.components.childspawner:TakeOwnership(inst)
		nest.components.childspawner:SetMaxChildren(1)
		nest:StartNesting()
		return true
	end
end

local function OnEntitySleep(inst, data)
    inst.entitysleeping = true
    if inst.pending_spawn_smallbird then
        local smallbird = SpawnPrefab("smallbird")
        smallbird:PushEvent("SetUpSpringSmallBird", {smallbird=smallbird, tallbird=inst})
        inst.pending_spawn_smallbird = false
    end
end

local function OnEntityWake(inst, data)
    inst.entitysleeping = false
end

local function ApplyBuildOverrides(inst, animstate)
    local override_build = inst.AnimState:GetBuild()
    if animstate ~= nil and animstate ~= inst.AnimState then
        animstate:SetBank("wilsontallbird")
        animstate:AddOverrideBuild(override_build)
        animstate:Hide("tallbird_beakfull")
        animstate:Hide("beakfull")
    end
end
local function ClearBuildOverrides(inst, animstate)
    local override_build = inst.AnimState:GetBuild()

    if animstate ~= nil and animstate ~= inst.AnimState then
        animstate:ClearOverrideBuild(override_build)
    end
end

local function OnDeath(inst, data)
    inst:AddTag("NOCLICK")
    inst.persists = false
    if inst.components.rideable:IsBeingRidden() then
        inst.components.rideable:Buck(true)
    end
end

local function OnRefuseRider(inst, data)
      if inst.components.sleeper:IsAsleep() and not inst.components.health:IsDead() then
        inst.components.sleeper:WakeUp()
      end
end
local function OnRefuseGiver(inst, giver, item)
    local talker = giver.components.talker
    if item and item.prefab=="twigs" then
        if talker then
            if inst.components.follower and inst.components.follower.leader==giver then
                return
            end
            giver.components.talker:Say(GetString(giver,"ANNOUNCE_TALLBIRD_NOTWIGS"))
        end
    elseif item and item.prefab=="cutgrass"  then
        if inst.components.follower and inst.components.follower.leader~=giver then
            return
        end
        if talker then
            giver.components.talker:Say(GetString(giver,"ANNOUNCE_TALLBIRD_NOCUTGRASS"))
        end
    end
end

-- local function PotentialRiderTest(inst, potential_rider)
--     local talker = potential_rider.components.talker

    -- if not inst.components.rideable:IsSaddled() then
    --     if talker then
    --         talker:Say("鞍")
    --     end
    --     return false
    -- end

    -- if not potential_rider:HasTag("bird_friend") then
    --     if talker then
    --         talker:Say("NO")
    --     end
    --     return false
    -- end
--     return true
-- end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 10, .5)

    inst.DynamicShadow:SetSize(2.75, 1)
    --inst.Transform:SetScale(1.5, 1.5, 1.5)
    inst.Transform:SetFourFaced()

    ----------
    inst:AddTag("tallbird")
    inst:AddTag("animal")
    inst:AddTag("largecreature")
    inst:AddTag("companion")
    inst:AddTag("character")
    inst:AddTag("notraptrigger")
    inst:AddTag("trader")
    inst:AddTag("saddleable")

    inst.AnimState:SetBank("tallbird")
    inst.AnimState:SetBuild("ds_tallbird_basic")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:Hide("beakfull")
    inst.AnimState:Hide("tallbird_beakfull")
    inst.scrapbook_hide = {"beakfull","tallbird_beakfull"}

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst.override_combat_fx_height = "high"
    inst._last_attacker = nil
    inst._last_attacked_time = nil

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = 10
    inst.components.locomotor.runspeed = 10

    inst:SetStateGraph("SGtallbird")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot(loot)

    ------------------
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.TALLBIRD_HEALTH)
    inst.components.health:StartRegen(10, 10)
    ------------------

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "head"
    inst.components.combat:SetDefaultDamage(TUNING.TALLBIRD_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.TALLBIRD_ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(3, Retarget)
    inst.components.combat:SetKeepTargetFunction(KeepTarget)
    inst.components.combat:SetRange(TUNING.TALLBIRD_ATTACK_RANGE)
    inst.components.combat:SetNoAggroTags({"bird_family", "smallbird","teenbird","tallbird"})

    inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(ShouldAcceptItem)
    inst.components.trader.onaccept = OnGetItemFromPlayer
    inst.components.trader:SetOnRefuse(OnRefuseGiver)

    MakeLargeBurnableCharacter(inst, "head")
    MakeLargeFreezableCharacter(inst, "head")
    MakeHauntablePanic(inst)
    ------------------

    inst:AddComponent("knownlocations")

    inst:AddComponent("bird_cultivate")
    inst:AddComponent("drownable")
    inst:AddComponent("planardamage")

    inst:AddComponent("leader")

    ------------------

    inst:AddComponent("eater")
    inst.components.eater:SetDiet({ FOODGROUP.OMNI }, { FOODGROUP.OMNI })

    ------------------
    inst:AddComponent("sleeper")
    inst.components.sleeper.watchlight = true
    inst.components.sleeper:SetResistance(3)
    inst.components.sleeper.testperiod = GetRandomWithVariance(6, 2)
    inst.components.sleeper:SetSleepTest(ShouldSleep)
    inst.components.sleeper:SetWakeTest(ShouldWake)
    ------------------

    inst:AddComponent("inspectable")

    inst:AddComponent("follower")

    inst:AddComponent("rideable")
    inst.components.rideable:SetShouldSave(true)
    inst.components.rideable:SetSaddleable(true)
    -- inst.components.rideable:SetCustomRiderTest(PotentialRiderTest)
    inst:ListenForEvent("refusedrider", OnRefuseRider)

    inst:ListenForEvent("leaderchanged", function(inst, data)
    if inst.components.follower then
    if inst.components.follower.leader
    and inst.components.follower.leader:HasTag("player") then
        inst.components.bird_cultivate.wild = false
        if inst.components.bird_cultivate then
            inst.components.bird_cultivate:Updata()
        end
    end
    end
    end)
    inst:ListenForEvent("death", OnDeath)
    ------------------
    inst.userfunctions={}
    inst.userfunctions.GetPeepChance=function ()
        return 0.9
    end
    inst.sounds = sounds
	inst.CanMakeNewHome = CanMakeNewHome
	inst.MakeNewHome = MakeNewHome
    inst.ApplyBuildOverrides = ApplyBuildOverrides
    inst.ClearBuildOverrides = ClearBuildOverrides

    inst:SetBrain(brain)

    inst:ListenForEvent("attacked", OnAttacked)

    inst:ListenForEvent("entitysleep", OnEntitySleep)
    inst:ListenForEvent("entitywake", OnEntityWake)

    return inst
end

return Prefab("tallbird", fn, assets, prefabs)