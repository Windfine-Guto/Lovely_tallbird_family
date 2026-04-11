local assets =
{
    Asset("ANIM", "anim/tallbird_eggshell.zip"),
    Asset("IMAGE","images/inventoryimages/tallbird_eggshell1.tex"),
	Asset("ATLAS", "images/inventoryimages/tallbird_eggshell1.xml"),
    Asset("IMAGE","images/inventoryimages/tallbird_eggshell2.tex"),
	Asset("ATLAS", "images/inventoryimages/tallbird_eggshell2.xml"),
}


local function fn(data)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("tallbird_eggshell")
    inst.AnimState:SetBuild("tallbird_eggshell")
    inst.AnimState:PlayAnimation("tallbird_eggshell"..data.number)

    inst:AddTag("tallbird_eggshell")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "tallbird_eggshell"..data.number
    inst.components.inventoryitem.atlasname = "images/inventoryimages/tallbird_eggshell"..data.number..".xml"

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

    inst:AddComponent("bird_named")

    MakeHauntableLaunch(inst)


    return inst
end

local function RegularFn1()
    return fn({
        number = "1",
    })
end

local function RegularFn2()
    return fn({
        number = "2",
    })
end

return Prefab("tallbird_eggshell1", RegularFn1, assets),
        Prefab("tallbird_eggshell2", RegularFn2, assets)