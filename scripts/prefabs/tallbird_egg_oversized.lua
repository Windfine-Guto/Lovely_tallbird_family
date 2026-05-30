local assets =
{
    Asset("ANIM", "anim/tallbird_egg_oversized.zip"),
    Asset("IMAGE", "images/inventoryimages/tallbird_egg_oversized.tex"),
    Asset("ATLAS", "images/inventoryimages/tallbird_egg_oversized.xml"),
    Asset("INV_IMAGE", "tallbird_egg_oversized"),
}
local prefabs = {}
local loots = {"hat_eggshell","armor_halfshell"}
for i = 1, 7 do
    table.insert(loots,"tallbird_yolk")
end
local PHYSICS_RADIUS = 0.45

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_body", "tallbird_egg_oversized", "swap_body")
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
end

local function onhammered(inst, worker)
    inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst:Remove()
end

local function onhit(inst, worker)
    inst.components.inventoryitem.canbepickedup = not inst.components.inventoryitem.canbepickedup
    inst:PushEvent("doroll",worker)
end

local function KeepTargetFn()
    return false
end

local function Sound(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	return TheWorld.Map:IsOceanAtPoint(x, 0, z) and "turnoftides/common/together/water/swim/walk_water_med" or "tallbird_egg_oversized/tallbird_egg_oversized/eggroll-"..math.random(1,5)
end

local function OnStartPushing(inst, doer)
	inst.Transform:SetRotation(doer:GetAngleToPoint(inst.Transform:GetWorldPosition()))
	inst.AnimState:PlayAnimation("egg_roll_loop", true)

    inst.push_sound = inst:DoPeriodicTask(0.3,function()
        inst.SoundEmitter:PlaySound(Sound(inst))
    end)
end

local function OnStopPushing(inst)
	inst.Physics:Stop()
	inst.AnimState:PlayAnimation("egg_roll_pst")
    inst.push_sound:Cancel()
    inst.push_sound = nil
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeHeavyObstaclePhysics(inst, PHYSICS_RADIUS)
    inst:SetPhysicsRadiusOverride(PHYSICS_RADIUS)

    MakeInventoryFloatable(inst, "med", 0.5)

    inst:AddTag("heavy")
    inst:AddTag("heavylift_lmb")
	inst:AddTag("pushing_roll")
    inst:AddTag("tallbird_egg_oversized")
    inst.gymweight = 2
    inst.Transform:SetEightFaced()

    inst.AnimState:SetBank("tallbird_egg_oversized")
    inst.AnimState:SetBuild("tallbird_egg_oversized")
    inst.AnimState:PlayAnimation("idle")
    inst.scrapbook_anim = "idle"

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("heavyobstaclephysics")
    inst.components.heavyobstaclephysics:SetRadius(PHYSICS_RADIUS)
    inst.components.heavyobstaclephysics:AddPushingStates()

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.cangoincontainer = false
    inst.components.inventoryitem.imagename = "tallbird_egg_oversized"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/tallbird_egg_oversized.xml"

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = 9
    inst.components.locomotor.runspeed = 9

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(20)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)

    inst:AddComponent("symbolswapdata")
    inst.components.symbolswapdata:SetData("tallbird_egg_oversized", "swap_body")

    inst:AddComponent("pushable")
    inst.components.pushable:SetOnStartPushingFn(OnStartPushing)
    inst.components.pushable:SetOnStopPushingFn(OnStopPushing)
    inst.components.pushable:SetPushingSpeed(2)
    inst.components.pushable:SetTargetDist(1.15)
	inst.components.pushable:SetMinDist(0.75)
	inst.components.pushable:SetMaxDist(1.95)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.walkspeedmult = TUNING.HEAVY_SPEED_MULT

    inst:AddComponent("lootdropper")
    inst.components.lootdropper.droprecipeloot = false
    inst.components.lootdropper:SetLoot(loots)

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(7)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)

    inst:SetStateGraph("SGtallbird_egg_oversized")

    return inst
end

return Prefab("tallbird_egg_oversized", fn, assets, prefabs)