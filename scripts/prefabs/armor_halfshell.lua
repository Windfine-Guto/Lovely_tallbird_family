local containers=require("containers")

local assets =
{
    Asset("ANIM", "anim/armor_halfshell.zip"),
    Asset("IMAGE", "images/inventoryimages/armor_halfshell.tex"),
    Asset("ATLAS", "images/inventoryimages/armor_halfshell.xml")
}

local params=containers.params

params.halfshell_back =
{
    widget =
    {
        slotpos = {},
        animbank = "ui_piggyback_2x6",
        animbuild = "ui_piggyback_2x6",
--        pos = Vector3(-5, -50, 0),
        pos = Vector3(-5, -90, 0),
    },
    issidewidget = true,
    type = "pack",
    openlimit = 1,
}

for y = 0, 5 do
    table.insert(params.halfshell_back.widget.slotpos, Vector3(-162, -75 * y + 170, 0))
    table.insert(params.halfshell_back.widget.slotpos, Vector3(-162 + 75, -75 * y + 170, 0))
end

function params.halfshell_back.itemtestfn(container, item, slot)
    return not item:HasTag("armor_halfshell")
end

local function ProtectionLevels(inst, data)
    local equippedHat = inst.components.inventory ~= nil and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD) or nil
    local equippedArmor = inst.components.inventory ~= nil and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY) or nil
    if equippedHat ~= nil and equippedHat:HasTag("hat_eggshell") then
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

local function OnArmorBroken(inst)
    if inst.components.container then
        inst.components.container:DropEverything()
    end
end

local function CanNotGoinContainer(inst,data)
    if inst.components.inventoryitem then
        inst.components.inventoryitem.cangoincontainer = false
    end
    local owner = inst.components.inventoryitem:GetGrandOwner()
    if owner and owner.components.inventory then
        owner.components.inventory:DropItem(inst)
    end
end

local function CanGoinContainer(inst,data)
    local container = inst.components.container
    local num_slot = 0
    if container then
        num_slot = container:GetNumSlots()
        for i = 1, num_slot do
            local item = container:GetItemInSlot(i)
            if item then
                return
            end
        end
        if inst.components.inventoryitem then
            inst.components.inventoryitem.cangoincontainer = true
        end
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
    inst:AddTag("tallbirdeggshell_repair")

    inst.foleysound = "dontstarve/movement/foley/shellarmour"

    MakeInventoryFloatable(inst, "med", 0.2, 0.70)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst.OnEntityReplicated=function (inst)
            if inst.replica.container then
                inst.replica.container:WidgetSetup("halfshell_back")
            end
        end
        return inst
    end

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("halfshell_back")

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
    inst.components.armor:SetOnFinished(OnArmorBroken)

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    MakeHauntableLaunch(inst)

    inst:ListenForEvent("itemget", CanNotGoinContainer)
    inst:ListenForEvent("itemlose", CanGoinContainer)

    return inst
end

return Prefab("armor_halfshell", fn, assets)
