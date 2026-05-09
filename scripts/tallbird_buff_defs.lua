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
    inst.shadow_tallbird_eyefx1.AnimState:SetFinalOffset(0)

    local fx3 = SpawnPrefab("shadow_tallbird_eyefx")
    inst.shadow_tallbird_eyefx2 = fx3
    inst.shadow_tallbird_eyefx2.entity:SetParent(inst.entity)
    inst.shadow_tallbird_eyefx2.entity:AddFollower()

    inst.shadow_tallbird_eyefx2.Follower:FollowSymbol(inst.GUID, layer, x2, y, 0)
    inst.shadow_tallbird_eyefx2.Transform:SetScale(scale, scale, scale)
    inst.shadow_tallbird_eyefx2.AnimState:SetFinalOffset(0)

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
local buffs = {
    shadow_tallbird = {
        duration = TUNING.TOTAL_DAY_TIME/2,
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
            RemoveShadowFx(target)
            target:RemoveEventCallback("onattackother",shadow_buff)
        end
    },
    lunar_tallbird = {
        duration = TUNING.TOTAL_DAY_TIME/2,
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

            end

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
            end

        end
    }
}

return buffs