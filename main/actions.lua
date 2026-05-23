local modid = 'lovely_tallbird_family'

local DrownCheckClientSafe = function(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    if inst:GetCurrentPlatform() then
        return false
    else
        local platform = TheWorld.Map:GetPlatformAtPoint(x, z)
        if platform then
            return false
    	end
    end

    if TheWorld.Map:IsOceanTileAtPoint(x, y, z) or TheWorld.Map:IsInvalidTileAtPoint(x, y, z) then
        return true
    end
end
if GetModConfigData(modid..'_tallbirdwaterwalk') then
local DISMOUNT_fn = ACTIONS.DISMOUNT.fn
ACTIONS.DISMOUNT.fn = function(act)
    local rider = act.doer.components.rider
    local mount = rider and rider:GetMount()
    if mount and mount:HasTag("tallbird") and DrownCheckClientSafe(act.doer) then
        return false
    end
    return DISMOUNT_fn(act)
end
end

local SADDLE_fn = ACTIONS.SADDLE.fn
ACTIONS.SADDLE.fn = function(act)
    local target = act.target
    local saddle = act.invobject
    local doer = act.doer
    local talker = doer.components.talker

    if target and target.components.bird_cultivate
    and target.components.bird_cultivate.wild == true then
        if talker then
            doer:DoTaskInTime(0,function ()
            talker:Say(GetString(doer,"ANNOUNCE_TALLBIRD_ISWILD"))
            end)
        end
        return false
    end

    local is_target_tallbird = target and target:HasTag("tallbird")
    local is_saddle_tallbird_saddle = saddle and saddle:HasTag("tallbird_saddle")

    if is_target_tallbird and not is_saddle_tallbird_saddle then
        if talker then
            doer:DoTaskInTime(0,function ()
            talker:Say(GetString(doer,"ANNOUNCE_ISTALLBIRD_NOTSADDLE"))
            end)
        end
        return false
    end
    if is_saddle_tallbird_saddle and not is_target_tallbird then
        if talker then
            doer:DoTaskInTime(0,function ()
            talker:Say(GetString(doer,"ANNOUNCE_NOTTALLBIRD_ISSADDLE"))
            end)
        end
        return false
    end

    if is_saddle_tallbird_saddle and is_target_tallbird then
        local current = target.components.inventory and target.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
        if current ~= nil then
            if current.prefab=="featherhat"  then
                if target.components.bird_cultivate.playerid~=nil
                and target.components.bird_cultivate.playerid~=doer.userid then
                    if talker then
                        doer:DoTaskInTime(0,function ()
                        talker:Say(GetString(doer,"ANNOUNCE_TALLBIRD_TRUSTEENSHIP"))
                        end)
                    end
                    return false
                elseif doer.userid==target.components.bird_cultivate.playerid then
                    target.components.bird_cultivate:Get_Back(doer)
                end
            end
            target.components.inventory:DropItem(current)
        end
    end

    return SADDLE_fn(act)
end

local WAX_fn = ACTIONS.WAX.fn
ACTIONS.WAX.fn = function(act)
    local target = act.target
    local waxitem = act.invobject
    if target and (target:HasTag("smallbird") or target:HasTag("teenbird")) then
        if target.components.bird_cultivate then
            target.components.bird_cultivate.nogrow = true
            target.components.bird_cultivate:Updata()
            local fx = SpawnPrefab("beeswax_spray_fx")
            fx.Transform:SetPosition(target.Transform:GetWorldPosition())
            if target.prefab=="smallbird" then
                target.AnimState:PlayAnimation("fear")
            else
                target.sg:GoToState("idle_blink")
            end
        end
    if waxitem then
        if waxitem.components.finiteuses ~= nil then
            waxitem.components.finiteuses:Use()
        elseif waxitem.components.stackable ~= nil then
            waxitem.components.stackable:Get():Remove()
        else
            waxitem:Remove()
        end
    end
        return true
    end
    return WAX_fn(act)
end

AddComponentAction("EQUIPPED", "wax", function(inst, doer, target, actions, right)
    if (target:HasTag("smallbird") or target:HasTag("teenbird"))
    and inst:HasTag("waxspray") and not target:HasTag("nogrow") then
        table.insert(actions, ACTIONS.WAX)
    end
end)

local function tallbird_buff(inst,obj,number)
    local name1 = number==1 and "lunar_tallbird" or "shadow_tallbird"
    local name2 = number==1 and "shadow_tallbird" or "lunar_tallbird"
    local followers = inst.components.leader and inst.components.leader.followers
    if inst.components.debuffable then
        if inst.components.debuffable:HasDebuff(name2) then
            inst.components.debuffable:RemoveDebuff(name2)
        end
        inst.components.debuffable:AddDebuff(name1,"buff_"..name1)
    end
    for follower, _ in pairs(followers) do
        if follower:HasTag("tallbird") and follower.components.debuffable then
            if follower.components.bird_cultivate and follower.components.bird_cultivate.planar~=true then
                follower.components.bird_cultivate.planar=true
                follower.components.bird_cultivate:Updata()
            end
            if follower.components.debuffable:HasDebuff(name2) then
                follower.components.debuffable:RemoveDebuff(name2)
            end
            follower.components.debuffable:AddDebuff(name1,"buff_"..name1)
        end
    end
    if obj and obj.components.stackable then
        if inst:HasTag("wurt_lunar_spelluser") and number==2 then
            obj.components.stackable:Get():Remove()
        elseif inst:HasTag("wurt_shadow_spelluser") and number==1 then
            obj.components.stackable:Get():Remove()
        end
        if not inst:HasTag("merm_builder") then
            obj.components.stackable:Get():Remove()
        end
    elseif obj then
        if inst:HasTag("wurt_lunar_spelluser") and number==2 then
            obj:Remove()
        elseif inst:HasTag("wurt_shadow_spelluser") and number==1 then
            obj:Remove()
        end
        if not inst:HasTag("merm_builder") then
            obj:Remove()
        end
    end
end
local CASTSPELL_fn = ACTIONS.CASTSPELL.fn
ACTIONS.CASTSPELL.fn = function (act)
    local doer = act.doer
    local obj = act.invobject
    if doer:HasTag("bird_family") then
        if obj and obj.prefab=="purebrilliance" then
            tallbird_buff(doer,obj,1)
            if not doer:HasTag("merm_builder") then
                return true
            end
        elseif obj and obj.prefab=="horrorfuel" then
            tallbird_buff(doer,obj,2)
            if not doer:HasTag("merm_builder") then
                return true
            end
        end
    end
    return CASTSPELL_fn(act)
end
AddComponentAction("INVENTORY", "bird_planaritem", function(inst, doer, actions, right)
    if doer:HasTag("bird_family") then
        table.insert(actions, ACTIONS.CASTSPELL)
    end
end)

local BIRD_JOUST = Action()
BIRD_JOUST.id = "BIRD_JOUST"
BIRD_JOUST.strfn = function (act)
    return "BIRD_JOUST"
end
-- BIRD_JOUST.priority = 10
BIRD_JOUST.rmb = true
BIRD_JOUST.distance = math.huge
BIRD_JOUST.mount_valid = true
BIRD_JOUST.invalid_hold_action = true
BIRD_JOUST.silent_generic_fail = true
BIRD_JOUST.fn = function(act)
	if act.doer and act.invobject then
        local joustuser = act.doer.components.joustuser
        if not joustuser then
            return
        end
        if not act.invobject.components.joustsource then
            return
        end
        if ShouldItemMimicBeRevealedFor(act.invobject, act.doer) then
            return false, "ITEMMIMIC"
        end
        return joustuser:CanJoust()
    end
end
AddAction(BIRD_JOUST)
STRINGS.ACTIONS.BIRD_JOUST = {
    BIRD_JOUST = STRINGS.TALLBIRD_ACTIONS_NAMED.JOUST
}

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.BIRD_JOUST, "joust_pre"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.BIRD_JOUST, "joust_pre"))

AddComponentAction("EQUIPPED", "joustsource", function(inst, doer, target, actions, right)
    if right and doer:HasTag("tallbird_mount") then
        table.insert(actions, ACTIONS.BIRD_JOUST)
    end
    if right and inst:HasTag("carrotfishingrod") and (doer.replica.rider == nil or not doer.replica.rider:IsRiding()) then
        for i, action in ipairs(actions) do
            if action == ACTIONS.JOUST then
                table.remove(actions, i)
                break
            end
        end
    end
end)
AddComponentAction("POINT", "joustsource", function(inst, doer, pos, actions, right, target)
    if right and doer:HasTag("tallbird_mount") then
        table.insert(actions, ACTIONS.BIRD_JOUST)
    end
    if right and inst:HasTag("carrotfishingrod") and (doer.replica.rider == nil or not doer.replica.rider:IsRiding()) and TheWorld.Map:IsAboveGroundAtPoint(pos:Get()) then
        for i, action in ipairs(actions) do
            if action == ACTIONS.JOUST then
                table.remove(actions, i)
                break
            end
        end
    end
end)

local SHADOW_TALLBIRD_DASH = Action()
SHADOW_TALLBIRD_DASH.id = "SHADOW_TALLBIRD_DASH"
SHADOW_TALLBIRD_DASH.strfn = function (act)
    return "SHADOW_TALLBIRD_DASH"
end
SHADOW_TALLBIRD_DASH.distance = math.huge
SHADOW_TALLBIRD_DASH.mount_valid = true
SHADOW_TALLBIRD_DASH.invalid_hold_action = true
SHADOW_TALLBIRD_DASH.fn = function(act)
	local pt = act:GetActionPoint()
	if pt then
		act.doer:ForceFacePoint(pt)
		return true
	end
	return false
end
AddAction(SHADOW_TALLBIRD_DASH)
STRINGS.ACTIONS.SHADOW_TALLBIRD_DASH = {
    SHADOW_TALLBIRD_DASH = STRINGS.TALLBIRD_ACTIONS_NAMED.DASH
}

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.SHADOW_TALLBIRD_DASH, "dash_woby_pre"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.SHADOW_TALLBIRD_DASH, "dash_woby_pre"))

local BIRD_PLANARITEM = Action()
BIRD_PLANARITEM.id = "BIRD_PLANARITEM"
BIRD_PLANARITEM.strfn = function (act)
    return "PLANAR"
end
BIRD_PLANARITEM.priority = 20
BIRD_PLANARITEM.fn = function (act)
    local obj = act.invobject
    local target = act.target
    if obj.components.bird_planaritem and target.components.bird_cultivate and target.components.bird_cultivate.planar~=true
    then
        return obj.components.bird_planaritem:Do(obj,target)
    end
    return false
end
AddAction(BIRD_PLANARITEM)
STRINGS.ACTIONS.BIRD_PLANARITEM = {
    PLANAR = STRINGS.TALLBIRD_ACTIONS_NAMED.PLANAR
}

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.BIRD_PLANARITEM, "give"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.BIRD_PLANARITEM, "give"))

AddComponentAction("USEITEM", "bird_planaritem", function(inst, doer, target, actions, right)
    if inst:HasTag("bird_planaritem") and target:HasTag("tallbird") and not target:HasTag("bird_planared") then
        table.insert(actions, ACTIONS.BIRD_PLANARITEM)
    end
end)

local BIRD_LEAVE = Action()
BIRD_LEAVE.id = "BIRD_LEAVE"
BIRD_LEAVE.strfn = function (act)
    return "LEAVE"
end
BIRD_LEAVE.priority = 20
BIRD_LEAVE.fn = function (act)
    local obj = act.invobject
    local target = act.target
    local doer = act.doer
    if obj.components.bird_leave and target.components.bird_cultivate and target.components.bird_cultivate.wild==false then
        return obj.components.bird_leave:Leave(obj,target,doer)
    end
    return false
end
AddAction(BIRD_LEAVE)
STRINGS.ACTIONS.BIRD_LEAVE = {
    LEAVE = STRINGS.TALLBIRD_ACTIONS_NAMED.LEAVE
}

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.BIRD_LEAVE, "give"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.BIRD_LEAVE, "give"))

AddComponentAction("USEITEM", "bird_leave", function(inst, doer, target, actions, right)
    if inst:HasTag("bird_leave") and target:HasTag("lovely_bird") and target:HasTag("tallbird") then
        table.insert(actions, ACTIONS.BIRD_LEAVE)
    end
end)

local BIRD_NAMED = Action()
BIRD_NAMED.id = "BIRD_NAMED"
BIRD_NAMED.strfn = function (act)
    return "NAMED"
end
-- BIRD_NAMED.priority = 20
BIRD_NAMED.fn = function (act)
    local obj = act.invobject
    local target = act.target
    local doer = act.doer
    if obj.components.bird_named then
        return obj.components.bird_named:Named(obj,target,doer)
    end
    return false
end
AddAction(BIRD_NAMED)
STRINGS.ACTIONS.BIRD_NAMED = {
    NAMED = STRINGS.TALLBIRD_ACTIONS_NAMED.NAMED
}

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.BIRD_NAMED, "give"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.BIRD_NAMED, "give"))

AddComponentAction("USEITEM", "bird_named", function(inst, doer, target, actions, right)
    if target:HasTag("lovely_bird") and doer and inst:HasTag("tallbird_eggshell") then
        table.insert(actions, ACTIONS.BIRD_NAMED)
    end
end)

local function PlayMiningFX(inst, target, nosound)
    if target ~= nil and target:IsValid() then
        local frozen = target:HasTag("frozen")
        local moonglass = target:HasAnyTag("moonglass", "LunarBuildup")
        local crystal = target:HasTag("crystal")
        if target.Transform ~= nil then
            SpawnPrefab(
                (frozen and "mining_ice_fx") or
                (moonglass and "mining_moonglass_fx") or
                (crystal and "mining_crystal_fx") or
                "mining_fx"
            ).Transform:SetPosition(target.Transform:GetWorldPosition())
        end
        if not nosound and inst.SoundEmitter ~= nil then
            inst.SoundEmitter:PlaySound(
                (frozen and "dontstarve_DLC001/common/iceboulder_hit") or
                ((moonglass or crystal) and "turnoftides/common/together/moon_glass/mine") or
                "dontstarve/wilson/use_pick_rock"
            )
        end
    end
end

local function HarvestPickable( ent, doer)
        if ent.components.pickable.picksound ~= nil then
            doer.SoundEmitter:PlaySound(ent.components.pickable.picksound)
        end

        local success, loot = ent.components.pickable:Pick(TheWorld)

        if loot ~= nil then
            for i, item in ipairs(loot) do
                Launch(item, doer, 1.5)
            end
        end
    end

local function IsEntityInFront( entity, doer_rotation, doer_pos)
        local facing = Vector3(math.cos(-doer_rotation / RADIANS), 0 , math.sin(-doer_rotation / RADIANS))
        return IsWithinAngle(doer_pos, facing, TUNING.VOIDCLOTH_SCYTHE_HARVEST_ANGLE_WIDTH, entity:GetPosition())
    end

    local HARVEST_MUSTTAGS  = {"pickable"}
    local HARVEST_CANTTAGS  = {"INLIMBO", "FX"}
    local HARVEST_ONEOFTAGS = {"plant", "lichen", "oceanvine", "kelp"}

    local function DoScythe( target, doer)
        if target.components.pickable ~= nil and target.components.pickable:CanBePicked() and not doer._tallbird_mount_aoe_leg then
            HarvestPickable(target, doer)
            return
        end
        if target.components.pickable ~= nil then
            local doer_pos = doer:GetPosition()
            local x, y, z = doer_pos:Get()

            local doer_rotation = doer.Transform:GetRotation()

            local ents = TheSim:FindEntities(x, y, z, TUNING.VOIDCLOTH_SCYTHE_HARVEST_RADIUS, HARVEST_MUSTTAGS, HARVEST_CANTTAGS, HARVEST_ONEOFTAGS)
            for _, ent in pairs(ents) do
                if ent:IsValid() and ent.components.pickable ~= nil then
                    if IsEntityInFront(ent, doer_rotation, doer_pos) then
                        HarvestPickable(ent, doer)
                    end
                end
            end
        end
    end

local function DoMountedToolWork(act, workaction)
    local target = act.target
    local doer = act.doer
    if target == nil or doer == nil then return false end

    if target.components.workable == nil or
       not target.components.workable:CanBeWorked() or
       target.components.workable:GetWorkAction() ~= workaction then
        return false
    end

    local rider = doer.replica.rider
    local mount = rider and rider:GetMount()
    if mount == nil or not mount:HasTag("tallbird") then
        return false
    end

    local numworks_bird =
        (doer.components.worker ~= nil and doer.components.worker:GetEffectiveness(workaction))
        or 1
    local numworks = 0
    local tool = doer.components.inventory and doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) or nil
    if tool and tool.components.tool then
        numworks = tool.components.tool:CanDoAction(workaction) and
        tool.components.tool:GetEffectiveness(workaction)
    end
    if tool and not tool.components.tool then
        numworks = 0.5
        if tool.components.finiteuses and not doer._tallbird_mount_aoe_leg then
            tool.components.finiteuses:Use(1)
        end
        tool = nil
    elseif tool and tool.components.finiteuses and not doer._tallbird_mount_aoe_leg and tool.components.tool:CanDoAction(workaction) then
        tool.components.finiteuses:OnUsedAsItem(workaction, doer, target)
    elseif tool and not tool.components.tool:CanDoAction(workaction) then
        numworks = 0.5
        if tool.components.finiteuses and not doer._tallbird_mount_aoe_leg then
            tool.components.finiteuses:Use(1)
        end
        tool = nil
    end

    if doer.components.workmultiplier ~= nil then
        numworks = numworks * doer.components.workmultiplier:GetMultiplier(workaction)
    end

    local recoil
    if not doer._tallbird_mount_aoe_leg then
        recoil, numworks = target.components.workable:ShouldRecoil(doer, tool, numworks)
    end

    if doer.components.workmultiplier ~= nil then
        numworks = doer.components.workmultiplier:ResolveSpecialWorkAmount(workaction, target, nil, numworks, recoil)
    end

    -- 触发反冲相关事件
    -- if recoil and doer.sg ~= nil and doer.sg.statemem.recoilstate ~= nil then
    --     doer:PushEventImmediate("recoil_off", { target = target })
    --     if numworks == 0 then
    --         doer:PushEvent("tooltooweak", { workaction = workaction })
    --     end
    -- end
    
    if target.components.workable.action == ACTIONS.MINE then
        PlayMiningFX(doer,target)
    end
    if target.components.workable.action == ACTIONS.DIG then
        doer.SoundEmitter:PlaySound("dontstarve/wilson/dig")
    end
    if target.components.workable.action == ACTIONS.HAMMER then
       doer.SoundEmitter:PlaySound(doer.sg.statemem.action ~= nil and doer.sg.statemem.action.invobject ~= nil and doer.sg.statemem.action.invobject.hit_skin_sound or "dontstarve/wilson/hit") 
    end
    if not doer._tallbird_mount_aoe_leg then
        numworks_bird = numworks + numworks_bird
    end
    
    target.components.workable:WorkedBy_Internal(doer, numworks_bird)
    return true
end

local BIRD_CHOP = Action()
BIRD_CHOP.id = "BIRD_CHOP"
BIRD_CHOP.strfn = function (act)
    return "BIRD_CHOP"
end
-- BIRD_CHOP.priority = 20
BIRD_CHOP.mount_valid =true
BIRD_CHOP.fn = function (act)
    return DoMountedToolWork(act, ACTIONS.CHOP)
end
AddAction(BIRD_CHOP)
STRINGS.ACTIONS.BIRD_CHOP = {
    BIRD_CHOP = STRINGS.TALLBIRD_ACTIONS_NAMED.CHOP
}

local BIRD_MINE = Action()
BIRD_MINE.id = "BIRD_MINE"
BIRD_MINE.strfn = function (act)
    return "BIRD_MINE"
end
-- BIRD_MINE.priority = 20
BIRD_MINE.mount_valid =true
BIRD_MINE.fn = function (act)
    return DoMountedToolWork(act, ACTIONS.MINE)
end
AddAction(BIRD_MINE)
STRINGS.ACTIONS.BIRD_MINE = {
    BIRD_MINE = STRINGS.TALLBIRD_ACTIONS_NAMED.MINE
}

local BIRD_DIG = Action()
BIRD_DIG.id = "BIRD_DIG"
BIRD_DIG.strfn = function (act)
    return "BIRD_DIG"
end
-- BIRD_DIG.priority = 20
BIRD_DIG.mount_valid =true
BIRD_DIG.fn = function (act)
    return DoMountedToolWork(act, ACTIONS.DIG)
end
AddAction(BIRD_DIG)
STRINGS.ACTIONS.BIRD_DIG = {
    BIRD_DIG = STRINGS.TALLBIRD_ACTIONS_NAMED.DIG
}

local BIRD_HAMMER = Action()
BIRD_HAMMER.id = "BIRD_HAMMER"
BIRD_HAMMER.strfn = function (act)
    return "BIRD_HAMMER"
end
-- BIRD_HAMMER.priority = 20
BIRD_HAMMER.mount_valid =true
BIRD_HAMMER.fn = function (act)
    return DoMountedToolWork(act, ACTIONS.HAMMER)
end
AddAction(BIRD_HAMMER)
STRINGS.ACTIONS.BIRD_HAMMER = {
    BIRD_HAMMER = STRINGS.TALLBIRD_ACTIONS_NAMED.HAMMER
}

local BIRD_SCYTHE = Action()
BIRD_SCYTHE.id = "BIRD_SCYTHE"
BIRD_SCYTHE.strfn = function (act)
    return "BIRD_SCYTHE"
end
BIRD_SCYTHE.priority = 20
BIRD_SCYTHE.mount_valid =true
BIRD_SCYTHE.fn = function (act)
    local target = act.target
    local doer = act.doer
    if target == nil or doer == nil then return false end

    local rider = doer.replica.rider
    local mount = rider and rider:GetMount()
    if mount == nil or not mount:HasTag("tallbird") then
        return false
    end

    if target.components.pickable == nil or not target.components.pickable:CanBePicked() then
        return false
    end

    DoScythe(target, doer)
    return true
end
AddAction(BIRD_SCYTHE)
STRINGS.ACTIONS.BIRD_SCYTHE = {
    BIRD_SCYTHE = STRINGS.TALLBIRD_ACTIONS_NAMED.SCYTHE
}

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.BIRD_CHOP, "attack"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.BIRD_CHOP, "attack"))
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.BIRD_MINE, "attack"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.BIRD_MINE, "attack"))
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.BIRD_DIG, "attack"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.BIRD_DIG, "attack"))
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.BIRD_HAMMER, "attack"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.BIRD_HAMMER, "attack"))
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.BIRD_SCYTHE, "attack"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.BIRD_SCYTHE, "attack"))

AddComponentAction("SCENE", "workable", function(inst, doer, actions, right)
    local tallbird = doer.replica.rider:IsRiding() and doer.replica.rider:GetMount()
    if inst:HasTag("CHOP_workable") and doer:HasTag("player") and tallbird and tallbird:HasTag("tallbird") then
        table.insert(actions, ACTIONS.BIRD_CHOP)
    end
	if inst:HasTag("MINE_workable") and doer:HasTag("player") and tallbird and tallbird:HasTag("tallbird") then
        table.insert(actions, ACTIONS.BIRD_MINE)
    end
    if right and inst:HasTag("DIG_workable") and doer:HasTag("player") and tallbird and tallbird:HasTag("tallbird") then
        table.insert(actions, ACTIONS.BIRD_DIG)
    end
    if right and inst:HasTag("HAMMER_workable") and doer:HasTag("player") and tallbird and tallbird:HasTag("tallbird") then
        table.insert(actions, ACTIONS.BIRD_HAMMER)
    end
end)

local SCYTHE_ONEOFTAGS = {"plant", "lichen", "oceanvine", "kelp"}

local function IsValidScytheTarget(target)
    return target:HasOneOfTags(SCYTHE_ONEOFTAGS)
end

AddComponentAction("SCENE", "pickable", function(inst, doer, actions, right)
    local tallbird = doer.replica.rider:IsRiding() and doer.replica.rider:GetMount()
    if right and IsValidScytheTarget(inst) and tallbird and tallbird:HasTag("tallbird") and inst:HasTag("pickable") then
        table.insert(actions, ACTIONS.BIRD_SCYTHE)
    end
end)

local NABBAG_MUSTTAGS = {"_inventoryitem"}
local NABBAG_CANTTAGS = {"INLIMBO", "FX", "_container", "heavy", "fire"}
local BIRD_COLLECT = Action()
BIRD_COLLECT.id = "BIRD_COLLECT"
BIRD_COLLECT.strfn = function (act)
    return "COLLECT"
end
BIRD_COLLECT.priority = 20
BIRD_COLLECT.mount_valid =true
BIRD_COLLECT.fn = function (act)
    local doer = act.doer
    local target = act.target

    local success = false
    if target and not target:HasAnyTag(NABBAG_CANTTAGS) then
        success = ACTIONS.PICKUP.fn(act)
        if not success then
            return false
        end
    end

    if not doer._tallbird_mount_aoe_leg then
        return success
    end

    local x, y, z = doer.Transform:GetWorldPosition()
    local max_dist = TUNING.SKILLS.WORTOX.NABBAG_MAX_RADIUS
    local ents = TheSim:FindEntities(x, y, z, max_dist, NABBAG_MUSTTAGS, NABBAG_CANTTAGS)
    
    local picked_count = 0
    local max_items = TUNING.SKILLS.WORTOX.NABBAG_MAX_ITEMS_PER_NAB

    for _, ent in ipairs(ents) do
        if ent ~= target and ent.replica.inventoryitem and ent.replica.inventoryitem:CanBePickedUp(doer) then
            act.target = ent
            if ACTIONS.PICKUP.fn(act) then
                picked_count = picked_count + 1
                if picked_count >= max_items then break end
            end
        end
    end

    act.target = target
    return success or picked_count > 0
end
AddAction(BIRD_COLLECT)
STRINGS.ACTIONS.BIRD_COLLECT = {
    COLLECT = STRINGS.TALLBIRD_ACTIONS_NAMED.COLLECT
}

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.BIRD_COLLECT, "attack"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.BIRD_COLLECT, "attack"))

AddComponentAction("SCENE", "inventoryitem", function(inst, doer, actions, right)
    if right and inst.replica.inventoryitem
    and inst.replica.inventoryitem:CanBePickedUp(doer)
    and not inst:HasAnyTag("_container", "heavy", "fire")
    and doer:HasTag("tallbird_mount")
    then
        table.insert(actions, ACTIONS.BIRD_COLLECT)
    end
end)

local BIRDS_FOLLOW = Action()
BIRDS_FOLLOW.id = "BIRDS_FOLLOW"
BIRDS_FOLLOW.strfn = function (act)
    return "GATHER"
end
BIRDS_FOLLOW.priority = 20
BIRDS_FOLLOW.mount_valid =true
BIRDS_FOLLOW.fn = function (act)
    local obj = act.invobject
    local doer = act.doer
    local x,y,z = doer.Transform:GetWorldPosition()
    local targets = doer:HasTag("bird_family") and TheSim:FindEntities(x, y or 0, z, 20 , {"tallbird"},nil , nil)
                    or TheSim:FindEntities(x, y or 0, z, 20 , {"lovely_bird"},nil , nil)
    for _,v in pairs(targets) do
        if v.components.follower and v.components.follower.leader==nil then
            v.components.follower:SetLeader(doer)
            v.sg:GoToState("idle_blink")
        end
    end
    local item = SpawnPrefab("tallbird_comb_leave")
    if item then
        local container = obj.components.inventoryitem:GetContainer()
        if container ~= nil then
            local slot = obj.components.inventoryitem:GetSlotNum()
            obj:Remove()
            container:GiveItem(item, slot)
        else
            obj:Remove()
            item.Transform:SetPosition(x, y, z)
        end
    end
    return true
end
AddAction(BIRDS_FOLLOW)
STRINGS.ACTIONS.BIRDS_FOLLOW = {
    GATHER = STRINGS.TALLBIRD_ACTIONS_NAMED.GATHER
}

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.BIRDS_FOLLOW,  "play_whistle"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.BIRDS_FOLLOW,  "play_whistle"))

AddComponentAction("INVENTORY", "bird_follow", function(inst, doer, actions, right)
    if doer and inst:HasTag("tallbird_comb_follow") then
        table.insert(actions, ACTIONS.BIRDS_FOLLOW)
    end
end)

local BIRDS_LEAVE = Action()
BIRDS_LEAVE.id = "BIRDS_LEAVE"
BIRDS_LEAVE.strfn = function (act)
    return "DISSOLVE"
end
BIRDS_LEAVE.priority = 20
BIRDS_LEAVE.mount_valid =true
BIRDS_LEAVE.fn = function (act)
    local obj = act.invobject
    local doer = act.doer
    local x,y,z = doer.Transform:GetWorldPosition()
    local targets = doer.components.leader and doer.components.leader.followers or {}
    for follower,_ in pairs(targets) do
        if follower:IsValid() and follower:HasTag("tallbird") and follower.components.follower and follower.components.follower.leader==doer then
            follower.components.follower:SetLeader(nil)
            follower.sg:GoToState("idle_blink")
        end
    end
    local item = SpawnPrefab("tallbird_comb_follow")
    if item then
        local container = obj.components.inventoryitem:GetContainer()
        if container ~= nil then
            local slot = obj.components.inventoryitem:GetSlotNum()
            obj:Remove()
            container:GiveItem(item, slot)
        else
            obj:Remove()
            item.Transform:SetPosition(x, y, z)
        end
    end
    return true
end
AddAction(BIRDS_LEAVE)
STRINGS.ACTIONS.BIRDS_LEAVE = {
    DISSOLVE = STRINGS.TALLBIRD_ACTIONS_NAMED.DISSOLVE
}

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.BIRDS_LEAVE,  "play_whistle"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.BIRDS_LEAVE,  "play_whistle"))

AddComponentAction("INVENTORY", "bird_leave", function(inst, doer, actions, right)
    if doer and inst:HasTag("tallbird_comb_leave") then
        table.insert(actions, ACTIONS.BIRDS_LEAVE)
    end
end)

local BIRDS_SPAWNER = Action()
BIRDS_SPAWNER.id = "BIRDS_SPAWNER"
BIRDS_SPAWNER.strfn = function (act)
    return "SPAWN"
end
-- BIRDS_SPAWNER.priority = 20
BIRDS_SPAWNER.fn = function (act)
    local target = act.target
    local doer = act.doer
    local talker = doer.components.talker
    local nest_spawner = target.components.tallbird_spawner
    if nest_spawner then
        if nest_spawner.spawner==false then
            nest_spawner.spawner=true
            if talker then talker:Say(GetString(doer,"ANNOUNCE_TALLBIRD_SPAWNER")) end
        else
            nest_spawner.spawner=false
            if talker then talker:Say(GetString(doer,"ANNOUNCE_TALLBIRD_NO_SPAWNER")) end
        end
        nest_spawner:Updata(target)
    end
    return true
end
AddAction(BIRDS_SPAWNER)
STRINGS.ACTIONS.BIRDS_SPAWNER = {
    SPAWN = STRINGS.TALLBIRD_ACTIONS_NAMED.SPAWN
}

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.BIRDS_SPAWNER,  "doshortaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.BIRDS_SPAWNER,  "doshortaction"))

AddComponentAction("SCENE", "tallbird_spawner", function(inst, doer, actions, right)
    if right and doer and inst:HasTag("new_tallbirdnest") then
        table.insert(actions, ACTIONS.BIRDS_SPAWNER)
    end
end)