local function NoHoles(pt)
    return not TheWorld.Map:IsPointNearHole(pt)
end
local function shadow_buff(inst,data)
    local target = data.target
    if target ~= nil and target.components.combat ~= nil then
        local pt
        if target ~= nil and target:IsValid() then
            pt = target:GetPosition()
        else
            pt = inst:GetPosition()
            target = nil
        end
        for i = 1, TUNING.TALLBIRD_TENTACLE_NUM do
            local offset = FindWalkableOffset(pt, math.random() * TWOPI, 2, 3, false, true, NoHoles, false, true)
            if offset ~= nil then
                inst.SoundEmitter:PlaySound("dontstarve/common/shadowTentacleAttack_1")
                inst.SoundEmitter:PlaySound("dontstarve/common/shadowTentacleAttack_2")
                local tentacle = SpawnPrefab("shadowtentacle")
                if tentacle ~= nil then
                    tentacle.owner = inst
                    tentacle.Transform:SetPosition(pt.x + offset.x, 0, pt.z + offset.z)
                    tentacle.components.combat:SetTarget(target)
                end
            end
        end
    end
end
local function CreateShadowFx(inst)
    local fx = SpawnPrefab("wurt_shadow_merm_planar_fx")
    fx.SoundEmitter:PlaySound("meta4/shadow_merm/buff_idle", "loop")
    inst.shadow_tallbird_bufffx = fx
    fx.AnimState:PlayAnimation("buff_pre")
    fx.AnimState:PushAnimation("buff_idle")
    fx.entity:SetParent(inst.entity)

if inst:HasTag("tallbird")  then
    local layer = "tallbird_eyewhite"
    local x1 = 0
    local x2 = 0
    local y = 0
    local scale = 1
    local fx2 = SpawnPrefab("shadow_tallbird_eyefx")
    inst.shadow_tallbird_eyefx1 = fx2
    inst.shadow_tallbird_eyefx1.entity:SetParent(inst.entity)
    inst.shadow_tallbird_eyefx1.entity:AddFollower()

    inst.shadow_tallbird_eyefx1.Follower:FollowSymbol(inst.GUID, layer, x1, y, 0)
    inst.shadow_tallbird_eyefx1.Transform:SetScale(scale, scale, scale)

    local fx3 = SpawnPrefab("shadow_tallbird_eyefx")
    inst.shadow_tallbird_eyefx2 = fx3
    inst.shadow_tallbird_eyefx2.entity:SetParent(inst.entity)
    inst.shadow_tallbird_eyefx2.entity:AddFollower()

    inst.shadow_tallbird_eyefx2.Follower:FollowSymbol(inst.GUID, layer, x2, y, 0)
    inst.shadow_tallbird_eyefx2.Transform:SetScale(scale, scale, scale)

    inst.AnimState:SetMultColour(0, 0, 0, 0.5)
 end
end
local function RemoveShadowFx(inst)
    if inst.shadow_tallbird_bufffx and inst.shadow_tallbird_bufffx:IsValid() then
        local fx = inst.shadow_tallbird_bufffx
        fx.SoundEmitter:KillSound("loop")
        fx.AnimState:PlayAnimation("buff_pst")
        fx.SoundEmitter:PlaySound("meta4/shadow_merm/buff_pst")
        fx:ListenForEvent("animover", function() fx:Remove() end)
    end
if inst:HasTag("tallbird")  then
    if inst.shadow_tallbird_eyefx1 and inst.shadow_tallbird_eyefx1:IsValid() then
        inst.shadow_tallbird_eyefx1:Remove()
    end
    if inst.shadow_tallbird_eyefx2 and inst.shadow_tallbird_eyefx2:IsValid() then
        inst.shadow_tallbird_eyefx2:Remove()
    end

    inst.AnimState:SetMultColour(1, 1, 1, 1)
end
end
local TRIBEAM_ANGLEOFF = PI / 5
local TRIBEAM_COS = math.cos(TRIBEAM_ANGLEOFF)
local TRIBEAM_SIN = math.sin(TRIBEAM_ANGLEOFF)
local TRIBEAM_COSNEG = math.cos(-TRIBEAM_ANGLEOFF)
local TRIBEAM_SINNEG = math.sin(-TRIBEAM_ANGLEOFF)
local NUM_STEPS = 10
local STEP = 1.0
local OFFSET = 2 - STEP
local SECOND_BLAST_TIME = 22 * FRAMES

local function SpawnPlayerBeam(inst, target_pos)
    if target_pos == nil then
        return
    end

    local ix, iy, iz = inst.Transform:GetWorldPosition()

    local target_step_num = RoundBiasedUp(NUM_STEPS * 2 / 5)

    local gx, gy, gz = nil, 0, nil
    local x_step = STEP
    local angle = math.atan2(iz - target_pos.z, ix - target_pos.x)

    if inst:GetDistanceSqToPoint(target_pos:Get()) < 4 then
        gx, gy, gz = inst.Transform:GetWorldPosition()
        gx = gx + (2 * math.cos(angle))
        gz = gz + (2 * math.sin(angle))
    else
        gx, gy, gz = target_pos:Get()
        gx = gx + (target_step_num * STEP * math.cos(angle))
        gz = gz + (target_step_num * STEP * math.sin(angle))
    end

    gx = gx - math.cos(angle)
    gz = gz - math.sin(angle)

    local targets, skiptoss = {}, {}
    local sbtargets, sbskiptoss = {}, {}
    local x, z = nil, nil
    local trigger_time = nil

    local i = -1
    while i < NUM_STEPS do
        i = i + 1
        x = gx - i * x_step * math.cos(angle)
        z = gz - i * STEP * math.sin(angle)

        local first = (i == 0)
        local prefab = (i > 0 and "lunar_tallbird_laser") or "lunar_tallbird_laserempty"
        local x1, z1 = x, z

        trigger_time = math.max(0, i - 1) * FRAMES

        inst:DoTaskInTime(trigger_time, function(inst2)
            local fx = SpawnPrefab(prefab)
            fx.caster = inst2
            fx.Transform:SetPosition(x1, 0, z1)
            fx:Trigger(0, targets, skiptoss)
            if first then
                ShakeAllCameras(CAMERASHAKE.FULL, .7, .02, .2, target_pos or fx, 30)
            end
        end)

    end

end
local function lunar_buff(inst,data)
    local target = data.target
    if not target or not target:IsValid() then return end

    local ipos = inst:GetPosition()
    local target_pos = target:GetPosition()

    -- 中央光束
    SpawnPlayerBeam(inst, target_pos)

    -- 左右偏移光束
    local i_to_target = target_pos - ipos
    local offpos1 = Vector3(
        (i_to_target.x * TRIBEAM_COS - i_to_target.z * TRIBEAM_SIN) + ipos.x,
        0,
        (i_to_target.x * TRIBEAM_SIN + i_to_target.z * TRIBEAM_COS) + ipos.z
    )
    SpawnPlayerBeam(inst, offpos1)

    local offpos2 = Vector3(
        (i_to_target.x * TRIBEAM_COSNEG - i_to_target.z * TRIBEAM_SINNEG) + ipos.x,
        0,
        (i_to_target.x * TRIBEAM_SINNEG + i_to_target.z * TRIBEAM_COSNEG) + ipos.z
    )
    SpawnPlayerBeam(inst, offpos2)
end
local function CreateLunarFx(inst)
    local Light_fx = SpawnPrefab("lunar_tallbird_light_fx")
    inst.lunar_tallbird_light_fx = Light_fx
    inst.lunar_tallbird_light_fx.entity:SetParent(inst.entity)
    if inst.components.bloomer ~= nil then
        inst.components.bloomer:PushBloom(inst, "shaders/anim.ksh", -1)
    else
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    end

    local layer2 = inst:HasTag("tallbird") and "tallbird_head" or "hair"
    local y2 = inst:HasTag("tallbird") and -50 or 0
    local scale2 = inst:HasTag("tallbird") and 1.3 or 1
    local fx4 = SpawnPrefab("lunar_tallbird_fx")
    inst.lunar_tallbird_bufffx2 = fx4
    inst.lunar_tallbird_bufffx2.entity:SetParent(inst.entity)
    inst.lunar_tallbird_bufffx2.entity:AddFollower()

    inst.lunar_tallbird_bufffx2.Follower:FollowSymbol(inst.GUID, layer2, 0, y2, 0)
    inst.lunar_tallbird_bufffx2.Transform:SetScale(scale2, scale2, scale2)

if inst:HasTag("tallbird")  then

    local fx = SpawnPrefab("wurt_lunar_merm_planar_fx")
    inst.lunar_tallbird_bufffx = fx
    fx.entity:SetParent(inst.entity)
    inst.SoundEmitter:PlaySound("meta4/lunar_merm/buff")

    local layer = "tallbird_eyewhite"
    local x1 = 0
    local x2 = 0
    local y = 0
    local scale = 1.22
    local fx2 = SpawnPrefab("lunar_tallbird_eyefx")
    inst.lunar_tallbird_eyefx1 = fx2
    inst.lunar_tallbird_eyefx1.entity:SetParent(inst.entity)
    inst.lunar_tallbird_eyefx1.entity:AddFollower()

    inst.lunar_tallbird_eyefx1.Follower:FollowSymbol(inst.GUID, layer, x1, y, 0)
    inst.lunar_tallbird_eyefx1.Transform:SetScale(scale, scale, scale)

    local fx3 = SpawnPrefab("lunar_tallbird_eyefx")
    inst.lunar_tallbird_eyefx2 = fx3
    inst.lunar_tallbird_eyefx2.entity:SetParent(inst.entity)
    inst.lunar_tallbird_eyefx2.entity:AddFollower()

    inst.lunar_tallbird_eyefx2.Follower:FollowSymbol(inst.GUID, layer, x2, y, 0)
    inst.lunar_tallbird_eyefx2.Transform:SetScale(scale, scale, scale)

 end
end
local function RemoveLunarFx(inst)
    if inst.lunar_tallbird_light_fx and inst.lunar_tallbird_light_fx:IsValid() then
        inst.lunar_tallbird_light_fx:Remove()
        if inst.components.bloomer ~= nil then
            inst.components.bloomer:PopBloom(inst)
        else
            inst.AnimState:ClearBloomEffectHandle()
        end
    end
    if inst.lunar_tallbird_bufffx2 and inst.lunar_tallbird_bufffx2:IsValid() then
        local fx = inst.lunar_tallbird_bufffx2
        fx:Remove()
    end
if inst:HasTag("tallbird")  then
    if inst.lunar_tallbird_bufffx and inst.lunar_tallbird_bufffx:IsValid() then
        local fx = inst.lunar_tallbird_bufffx
        fx.AnimState:PlayAnimation("pst")
        fx:ListenForEvent("animover", function() fx:Remove() end)
    end
    if inst.lunar_tallbird_eyefx1 and inst.lunar_tallbird_eyefx1:IsValid() then
        inst.lunar_tallbird_eyefx1:Remove()
    end
    if inst.lunar_tallbird_eyefx2 and inst.lunar_tallbird_eyefx2:IsValid() then
        inst.lunar_tallbird_eyefx2:Remove()
    end

end
end
local buffs = {
    shadow_tallbird = {
        duration = TUNING.TOTAL_DAY_TIME*TUNING.TALLBIRD_PLANAR_TIME,
        priority = 1,
        nospeech = nil,
        onattachedfn = function (inst,target)
            local i = 0
            if target:HasTag("player") then
                local followers = target.components.leader and target.components.leader.followers
                for follower, _ in pairs(followers) do
                    if follower:HasTag("tallbird") then
                        i=i+1
                    end
                end
                if i>TUNING.TALLBIRD_PLAYER_LIMIT then
                    i=TUNING.TALLBIRD_PLAYER_LIMIT
                end
                if target.components.locomotor then
                    target.components.locomotor:SetExternalSpeedMultiplier(inst,"shadow_tallbird_speed",1+i*TUNING.TALLBIRD_PLAYER_SPEED)
                end
                if target.components.combat then
                    target.components.combat.externaldamagemultipliers:SetModifier(inst,1+i*TUNING.TALLBIRD_PLAYER_DAMAGE,"shadow_tallbird_damage" )
                end
                if target.components.health then
                    target.components.health.externalabsorbmodifiers:SetModifier(inst, i*TUNING.TALLBIRD_PLAYER_ABSOR, "shadow_tallbird_absor")
                end
                target:AddTag("shadow_tallbird_dash")
            end
            if target:HasTag("tallbird") then
                target:PushEvent("sleep_immunity")
                RemovePhysicsColliders(target)
                target.Physics:SetCollisionGroup(COLLISION.SANITY)
                target.Physics:CollidesWith(COLLISION.SANITY)
                target.Physics:Teleport(target.Transform:GetWorldPosition())
            end
            CreateShadowFx(target)
            target:ListenForEvent("onattackother",shadow_buff)
        end,
        onextendedfn = function (inst,target)
            if target:HasTag("player") then
                if target.components.locomotor then
                    target.components.locomotor:RemoveExternalSpeedMultiplier(inst,"shadow_tallbird_speed")
                end
                if target.components.combat then
                    target.components.combat.externaldamagemultipliers:RemoveModifier(inst,"shadow_tallbird_damage" )
                end
                if target.components.health then
                    target.components.health.externalabsorbmodifiers:RemoveModifier(inst, "shadow_tallbird_absor")
                end

                local i = 0
                local followers = target.components.leader and target.components.leader.followers
                for follower, _ in pairs(followers) do
                    if follower:HasTag("tallbird") then
                        i=i+1
                    end
                end
                if i>TUNING.TALLBIRD_PLAYER_LIMIT then
                    i=TUNING.TALLBIRD_PLAYER_LIMIT
                end
                if target.components.locomotor then
                    target.components.locomotor:SetExternalSpeedMultiplier(inst,"shadow_tallbird_speed",1+i*TUNING.TALLBIRD_PLAYER_SPEED)
                end
                if target.components.combat then
                    target.components.combat.externaldamagemultipliers:SetModifier(inst,1+i*TUNING.TALLBIRD_PLAYER_DAMAGE,"shadow_tallbird_damage" )
                end
                if target.components.health then
                    target.components.health.externalabsorbmodifiers:SetModifier(inst, i*TUNING.TALLBIRD_PLAYER_ABSOR, "shadow_tallbird_absor")
                end
            end
            if target.components.health then
                target.components.health:DoDelta(target.components.health.maxhealth*.2,nil,inst)
            end
            RemoveShadowFx(target)
            CreateShadowFx(target)
            target:RemoveEventCallback("onattackother",shadow_buff)
            target:ListenForEvent("onattackother",shadow_buff)
        end,
        ondetachedfn = function (inst,target)
            if target:HasTag("player") then
                if target.components.locomotor then
                    target.components.locomotor:RemoveExternalSpeedMultiplier(inst,"shadow_tallbird_speed")
                end
                if target.components.combat then
                    target.components.combat.externaldamagemultipliers:RemoveModifier(inst,"shadow_tallbird_damage" )
                end
                if target.components.health then
                    target.components.health.externalabsorbmodifiers:RemoveModifier(inst, "shadow_tallbird_absor")
                end
                target:RemoveTag("shadow_tallbird_dash")
            end
            if target:HasTag("tallbird") then
                target:PushEvent("remove_sleep_immunity")
                MakeCharacterPhysics(target, 10, .5)
                -- target.Physics:Teleport(target.Transform:GetWorldPosition())
            end
            RemoveShadowFx(target)
            target:RemoveEventCallback("onattackother",shadow_buff)
        end
    },
    lunar_tallbird = {
        duration = TUNING.TOTAL_DAY_TIME*TUNING.TALLBIRD_PLANAR_TIME,
        priority = 1,
        nospeech = nil,
        onattachedfn = function (inst,target)
            local i = 0
            if target:HasTag("player") then
                local followers = target.components.leader and target.components.leader.followers
                for follower, _ in pairs(followers) do
                    if follower:HasTag("tallbird") then
                        i=i+1
                    end
                end
                if i>TUNING.TALLBIRD_PLAYER_LIMIT then
                    i=TUNING.TALLBIRD_PLAYER_LIMIT
                end
                if target.components.locomotor then
                    target.components.locomotor:SetExternalSpeedMultiplier(inst,"lunar_tallbird_speed",1+i*TUNING.TALLBIRD_PLAYER_SPEED)
                end
                if target.components.combat then
                    target.components.combat.externaldamagemultipliers:SetModifier(inst,1+i*TUNING.TALLBIRD_PLAYER_DAMAGE,"lunar_tallbird_damage" )
                end
                if target.components.health then
                    target.components.health.externalabsorbmodifiers:SetModifier(inst, i*TUNING.TALLBIRD_PLAYER_ABSOR, "lunar_tallbird_absor")
                end
                if target.components.grogginess ~= nil then
                    target.components.grogginess:AddImmunitySource(inst)
                end
            end
            if target:HasTag("tallbird") then
                target:PushEvent("sleep_immunity")
            end
            CreateLunarFx(target)
            target:ListenForEvent("onattackother",lunar_buff)
        end,
        onextendedfn = function (inst,target)
            if target:HasTag("player") then
                if target.components.locomotor then
                    target.components.locomotor:RemoveExternalSpeedMultiplier(inst,"lunar_tallbird_speed")
                end
                if target.components.combat then
                    target.components.combat.externaldamagemultipliers:RemoveModifier(inst,"lunar_tallbird_damage" )
                end
                if target.components.health then
                    target.components.health.externalabsorbmodifiers:RemoveModifier(inst, "lunar_tallbird_absor")
                end

                local i = 0
                local followers = target.components.leader and target.components.leader.followers
                for follower, _ in pairs(followers) do
                    if follower:HasTag("tallbird") then
                        i=i+1
                    end
                end
                if i>TUNING.TALLBIRD_PLAYER_LIMIT then
                    i=TUNING.TALLBIRD_PLAYER_LIMIT
                end
                if target.components.locomotor then
                    target.components.locomotor:SetExternalSpeedMultiplier(inst,"lunar_tallbird_speed",1+i*TUNING.TALLBIRD_PLAYER_SPEED)
                end
                if target.components.combat then
                    target.components.combat.externaldamagemultipliers:SetModifier(inst,1+i*TUNING.TALLBIRD_PLAYER_DAMAGE,"lunar_tallbird_damage" )
                end
                if target.components.health then
                    target.components.health.externalabsorbmodifiers:SetModifier(inst, i*TUNING.TALLBIRD_PLAYER_ABSOR, "lunar_tallbird_absor")
                end
            end
            if target.components.health then
                target.components.health:DoDelta(target.components.health.maxhealth*.2,nil,inst)
            end
            RemoveLunarFx(target)
            CreateLunarFx(target)
            target:RemoveEventCallback("onattackother",lunar_buff)
            target:ListenForEvent("onattackother",lunar_buff)
        end,
        ondetachedfn = function (inst,target)
            if target:HasTag("player") then
                if target.components.locomotor then
                    target.components.locomotor:RemoveExternalSpeedMultiplier(inst,"lunar_tallbird_speed")
                end
                if target.components.combat then
                    target.components.combat.externaldamagemultipliers:RemoveModifier(inst,"lunar_tallbird_damage" )
                end
                if target.components.health then
                    target.components.health.externalabsorbmodifiers:RemoveModifier(inst, "lunar_tallbird_absor")
                end
                if target.components.grogginess ~= nil then
                    target.components.grogginess:RemoveImmunitySource(inst)
                end
            end
            if target:HasTag("tallbird") then
                target:PushEvent("remove_sleep_immunity")
            end
            RemoveLunarFx(target)
            target:RemoveEventCallback("onattackother",lunar_buff)
        end
    }
}

return buffs