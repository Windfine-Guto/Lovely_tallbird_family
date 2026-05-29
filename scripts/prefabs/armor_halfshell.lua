local assets =
{
    Asset("ANIM", "anim/armor_halfshell.zip"),
    Asset("IMAGE", "images/inventoryimages/armor_halfshell.tex"),
    Asset("ATLAS", "images/inventoryimages/armor_halfshell.xml")
}

local function ProtectionLevels(inst, data)
    local equippedHat = inst.components.inventory ~= nil and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD) or nil
    local equippedArmor = inst.components.inventory ~= nil and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY) or nil
    if equippedHat ~= nil then
        if inst.sg:HasStateTag("gaint_shell") then
            equippedHat.components.armor:SetAbsorption(TUNING.FULL_ABSORPTION)
        else
            equippedHat.components.armor:SetAbsorption(TUNING.ARMORSNURTLESHELL_ABSORPTION)
            equippedHat.components.useableitem:StopUsingItem()
        end
    end
    if equippedArmor ~= nil then
        if inst.sg:HasStateTag("gaint_shell") then
            equippedArmor.components.armor:SetAbsorption(TUNING.FULL_ABSORPTION)
        else
            equippedArmor.components.armor:SetAbsorption(TUNING.ARMORSNURTLESHELL_ABSORPTION)
        end
    end
end

local function onequip(inst, owner)
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("equipskinneditem", inst:GetSkinName())
        owner.AnimState:OverrideItemSkinSymbol("swap_body", skin_build, "swap_body", inst.GUID, "armor_marble")
    else
		owner.AnimState:OverrideSymbol("swap_body", "armor_halfshell", "swap_body")
    end
    inst:ListenForEvent("newstate", ProtectionLevels, owner)
    if inst.components.container ~= nil then
        inst.components.container:Open(owner)
    end
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")

    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end
    inst:RemoveEventCallback("newstate", ProtectionLevels, owner)
    if inst.components.container ~= nil then
        inst.components.container:Close(owner)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("armor_halfshell")
    inst.AnimState:SetBuild("armor_halfshell")
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("shell")
	inst:AddTag("hardarmor")
    inst:AddTag("armor_halfshell")

    inst.foleysound = "dontstarve/movement/foley/shellarmour"

    MakeInventoryFloatable(inst, "med", 0.2, 0.70)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst.OnEntityReplicated=function (inst)
            if inst.replica.container then
                inst.replica.container:WidgetSetup("piggyback")
            end
        end
        return inst
    end

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("piggyback")

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "armor_halfshell"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/armor_halfshell.xml"

    inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALL)

    inst:AddComponent("insulator")
    inst.components.insulator:SetSummer()
    inst.components.insulator:SetInsulation(TUNING.INSULATION_SMALL)

    inst:AddComponent("armor")
    inst.components.armor:InitCondition(400, TUNING.ARMORSNURTLESHELL_ABSORPTION)

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("armor_halfshell", fn, assets)
