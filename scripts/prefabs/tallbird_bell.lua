local assets =
{
    Asset("ANIM", "anim/cowbell_shadow.zip"),
    Asset("IMAGE","images/inventoryimages/tallbird_bell.tex"),
	Asset("ATLAS", "images/inventoryimages/tallbird_bell.xml"),
    Asset("IMAGE","images/inventoryimages/tallbird_bell_linked.tex"),
	Asset("ATLAS", "images/inventoryimages/tallbird_bell_linked.xml"),
}

local prefabs = {
    "tallbird",
    "teenbird",
    "smallbird"
}
-----------------------------------------------------------------------------------------------------------------------------------------

local function OnDropped(inst)
    if inst:HasTag("bird_store") then
        inst.AnimState:PlayAnimation("idle1", false)
    else
        inst.AnimState:PlayAnimation("idle2", true)
    end
end

local function Fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("cowbell_shadow")
    inst.AnimState:SetBuild("cowbell_shadow")
    inst.AnimState:PlayAnimation("idle1", false)

    MakeInventoryFloatable(inst)

    inst:AddTag("bell")
    inst:AddTag("donotautopick")
    inst:AddTag("bird_store")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "tallbird_bell"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/tallbird_bell.xml"
    inst.components.inventoryitem:SetOnDroppedFn(OnDropped)

    inst:AddComponent("bird_store")

    inst._sound = "rifts4/beefalo_revive/bell_ring"

    return inst
end

-----------------------------------------------------------------------------------------------------------------------------------------

return Prefab("tallbird_bell",Fn, assets,prefabs)
