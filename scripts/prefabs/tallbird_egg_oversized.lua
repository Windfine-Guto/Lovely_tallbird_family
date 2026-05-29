local assets = 
{
    Asset("ANIM", "anim/gaint_egg_roll.zip"),
    Asset("IMAGE", "images/inventoryimages/gaint_egg_roll.tex"),
    Asset("ATLAS", "images/inventoryimages/gaint_egg_roll.xml"),
    Asset("INV_IMAGE", "gaint_egg_roll"),
}
local prefabs = {}
local PHYSICS_RADIUS = 0.45

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_body", "gaint_egg_roll", "swap_body")
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
end

local function onhammered(inst, worker)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end

    inst.components.lootdropper:DropLoot()

    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("rock")
    inst:Remove()
end

local function onhit(inst, worker)
    inst.AnimState:PlayAnimation("hit")
    inst.AnimState:PushAnimation("idle_full")
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeHeavyObstaclePhysics(inst, PHYSICS_RADIUS)
    inst:SetPhysicsRadiusOverride(PHYSICS_RADIUS)

    inst:AddTag("heavy")
    inst.gymweight = 1

    inst.AnimState:SetBank("gaint_egg_roll")
    inst.AnimState:SetBuild("gaint_egg_roll")
    inst.AnimState:PlayAnimation("hide_idle")
    inst.scrapbook_anim = "hide_idle"

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("heavyobstaclephysics")
    inst.components.heavyobstaclephysics:SetRadius(PHYSICS_RADIUS)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.cangoincontainer = false
    
    inst.components.inventoryitem:ChangeImageName("gaint_egg_roll")

    inst:AddComponent("symbolswapdata")
    inst.components.symbolswapdata:SetData("gaint_egg_roll", "swap_body")

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.walkspeedmult = TUNING.HEAVY_SPEED_MULT

    inst:AddComponent("submersible")

    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(2)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    MakeMediumBurnable(inst)
    MakeMediumPropagator(inst)

    return inst
end

return Prefab("gaint_egg_roll", fn, assets, prefabs)