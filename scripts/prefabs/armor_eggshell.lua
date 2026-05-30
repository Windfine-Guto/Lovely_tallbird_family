local assets =
{
    Asset("ANIM", "anim/armor_eggshell.zip"),
    Asset("IMAGE","images/inventoryimages/armor_eggshell.tex"),
	Asset("ATLAS", "images/inventoryimages/armor_eggshell.xml"),
}

local prefabs =
{
    "eggshellfx_armor",
}

local function OnCooldown(inst)
    inst._cdtask = nil
end

local function DoThorns(inst, owner)
    --V2C: tiny CD to limit chain reactions
    inst._cdtask = inst:DoTaskInTime(.3, OnCooldown)

    SpawnPrefab("eggshellfx_armor"):SetFXOwner(owner)

    if owner.SoundEmitter ~= nil then
        owner.SoundEmitter:PlaySound("dontstarve/creatures/egg/egg_hatch_crack")
    end
end

local function OnBlocked(owner, data, inst)
    if inst._cdtask == nil and data ~= nil and not data.redirected then
        DoThorns(inst, owner)
    end
end

local function OnAttackOther(owner, inst)
    if inst.components.cooldown and inst.components.cooldown:IsCharged() then
        DoThorns(inst, owner)
        if inst.components.armor then
            inst.components.armor:TakeDamage(inst._attack_condition)
        end
    end
end

local function onequip(inst, owner)
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("equipskinneditem", inst:GetSkinName())
        owner.AnimState:OverrideItemSkinSymbol("swap_body", skin_build, "swap_body", inst.GUID, "armor_bramble")
    else
		owner.AnimState:OverrideSymbol("swap_body", "armor_eggshell", "swap_body")
    end

    if inst.components.cooldown then
        inst.components.cooldown:FinishCharging()
    end

    inst:ListenForEvent("blocked", inst._onblocked, owner)
    inst:ListenForEvent("attacked", inst._onblocked, owner)
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")

    inst:RemoveEventCallback("blocked", inst._onblocked, owner)
    inst:RemoveEventCallback("attacked", inst._onblocked, owner)

    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst:AddTag("bramble_resistant")
    inst:AddTag("armor_eggshell")
    inst:AddTag("tallbirdeggshell_repair")

    inst.AnimState:SetBank("armor_eggshell")
    inst.AnimState:SetBuild("armor_eggshell")
    inst.AnimState:PlayAnimation("anim")

    inst.scrapbook_specialinfo = "ARMORBRAMBLE"
    inst.scrapbook_damage = TUNING.ARMORBRAMBLE_DMG

    inst.foleysound = "dontstarve/movement/foley/cactus_armor"

    MakeInventoryFloatable(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end


    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "armor_eggshell"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/armor_eggshell.xml"

    MakeSmallBurnable(inst, TUNING.SMALL_BURNTIME)
    MakeSmallPropagator(inst)

    inst:AddComponent("armor")
    inst.components.armor:InitCondition(100+TUNING.ARMORBRAMBLE, TUNING.ARMORBRAMBLE_ABSORPTION)
    inst._attack_condition=inst.components.armor.maxcondition * 0.05

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY

    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("cooldown")
    inst.components.cooldown.cooldown_duration = 2

    MakeHauntableLaunch(inst)

    inst._onblocked      = function(owner, data)     OnBlocked(owner, data, inst) end
    inst._onattackother  =  OnAttackOther

    return inst
end

return Prefab("armor_eggshell", fn, assets, prefabs)
