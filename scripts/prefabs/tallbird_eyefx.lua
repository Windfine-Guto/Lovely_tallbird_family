local assets =
{
    Asset("ANIM", "anim/merm_actions_skills.zip"),
}

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
        Prefab("lunar_tallbird_eyefx", fn2, assets)