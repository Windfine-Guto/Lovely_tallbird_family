local assets =
{
    Asset("ANIM", "anim/tallbird_egg.zip"),
    Asset("IMAGE","images/inventoryimages/tallbird_yolk.tex"),
	Asset("ATLAS", "images/inventoryimages/tallbird_yolk.xml"),
}

local function commonfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()

    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBuild("tallbird_egg")
    inst.AnimState:SetBank("egg")
    inst.AnimState:PlayAnimation("raw_eggs")
    inst.scrapbook_anim = "raw_eggs"

    inst:AddTag("cattoy")
    inst:AddTag("tallbirdegg")
	inst:AddTag("tallbird_yolk")

    inst:AddTag("cookable")

    inst:AddTag("show_spoilage") --保鲜度动画
    inst:AddTag("icebox_valid")		--放进冰箱
    inst:AddTag("saltbox_valid")		--放进盐盒

    MakeInventoryFloatable(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_SUPERFAST)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "tallbird_yolk"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/tallbird_yolk.xml"

    inst:AddComponent("edible")
    inst.components.edible.foodtype = FOODTYPE.MEAT
    inst.components.edible.healthvalue = TUNING.HEALING_SMALL
    inst.components.edible.hungervalue = TUNING.CALORIES_MED

    inst:AddComponent("cookable")
    inst.components.cookable.product = "tallbirdegg_cooked"

    MakeHauntableLaunch(inst)

    return inst
end


return Prefab("tallbird_yolk", commonfn, assets)
