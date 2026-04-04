
local function OnDiscarded(inst)
    inst.components.finiteuses:Use()
end
------------------------------------------------------------------------------------------------------------------
local assets = {
        Asset("ANIM", "anim/tallbird_saddle.zip"),
        Asset("IMAGE","images/inventoryimages/tallbird_saddle.tex"),
	    Asset("ATLAS", "images/inventoryimages/tallbird_saddle.xml"),
    }

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("tallbird_saddle")
    inst.AnimState:SetBuild("tallbird_saddle")
    inst.AnimState:PlayAnimation("idle")

    inst.mounted_foleysound = "dontstarve/beefalo/saddle/".."wigfrid_foley"

    MakeInventoryFloatable(inst, "med", 0.1, 1.2)

    inst:AddTag("combatmount")
    inst:AddTag("tallbird_saddle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end


    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.atlasname = "images/inventoryimages/tallbird_saddle.xml"

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.SADDLE_WATHGRITHR_USES)
    inst.components.finiteuses:SetUses(TUNING.SADDLE_WATHGRITHR_USES)

    local build = inst.AnimState:GetBuild()

    inst:AddComponent("saddler")
    inst.components.saddler:SetSwaps(build, "swap_saddle")
    inst.components.saddler:SetDiscardedCallback(OnDiscarded)
    inst.components.saddler:SetAbsorption(0.5)

    MakeHauntableLaunch(inst)

    inst.scrapbook_scale = 0.7
    inst.scrapbook_animoffsety = -50
    inst.scrapbook_animoffsetbgy = 55
    return inst
end


return Prefab("tallbird_saddle", fn, assets)