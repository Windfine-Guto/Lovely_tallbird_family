local assets =
{
    Asset("ANIM", "anim/merm_actions_skills.zip"),
    Asset("ANIM", "anim/brightmare_gestalt_head_evolved.zip")
}

local function commonfn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddNetwork()
	inst.entity:AddLight()
    inst:AddTag("FX")
    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end
   inst.persists=false
      return inst
end
local function lunar()
    local inst = commonfn()
    inst.Light:SetFalloff(0.9)
	inst.Light:SetIntensity(.6)
	inst.Light:SetRadius(2)
	inst.Light:SetColour(255/255, 255/255, 255/255)
    if not TheWorld.ismastersim then
        return inst
    end
    return inst
end
local function fn1()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("pigman")
    inst.AnimState:SetBuild("merm_actions_skills")
    inst.AnimState:PlayAnimation("alternateeyes", true)
	inst.AnimState:SetFinalOffset(1)

	inst.Transform:SetNoFaced()

    inst:AddTag("FX")
    inst:AddTag("DECOR")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end
local function fn2()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("pigman")
    inst.AnimState:SetBuild("merm_actions_skills")
    inst.AnimState:PlayAnimation("flame", true)
	inst.AnimState:SetFinalOffset(1)
    inst.AnimState:SetMultColour(1, 1, 1, 0.3)

	inst.Transform:SetNoFaced()

    inst:AddTag("FX")
    inst:AddTag("DECOR")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end
local function fn3()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("brightmare_gestalt_head_evolved")
    inst.AnimState:SetBuild("brightmare_gestalt_head_evolved")
    inst.AnimState:PlayAnimation("idle", true)
	inst.AnimState:SetFinalOffset(-1)
    inst.AnimState:SetMultColour(1, 1, 1, 0.1)

	inst.Transform:SetNoFaced()

    inst:AddTag("FX")
    inst:AddTag("DECOR")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

return Prefab("shadow_tallbird_eyefx", fn1, assets),
        Prefab("lunar_tallbird_eyefx", fn2, assets),
        Prefab("lunar_tallbird_fx", fn3, assets),
        Prefab("lunar_tallbird_light_fx",lunar)