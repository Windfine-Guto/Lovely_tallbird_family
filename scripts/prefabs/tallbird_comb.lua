local assets =
{
    Asset("ANIM", "anim/comb.zip"),
    Asset("IMAGE","images/inventoryimages/comb.tex"),
	Asset("ATLAS", "images/inventoryimages/comb.xml"),
    Asset("IMAGE","images/inventoryimages/comb2.tex"),
	Asset("ATLAS", "images/inventoryimages/comb2.xml"),
}


local function fn1()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("comb")
    inst.AnimState:SetBuild("comb")
    inst.AnimState:PlayAnimation("idle2")

    inst:AddTag("tallbird_comb_follow")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "comb2"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/comb2.xml"

    inst:AddComponent("bird_follow")

    MakeHauntableLaunch(inst)


    return inst
end
local function fn2()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("comb")
    inst.AnimState:SetBuild("comb")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("tallbird_comb_leave")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "comb"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/comb.xml"

    inst:AddComponent("bird_leave")

    MakeHauntableLaunch(inst)


    return inst
end


return Prefab("tallbird_comb_follow", fn1, assets),
       Prefab("tallbird_comb_leave", fn2, assets)