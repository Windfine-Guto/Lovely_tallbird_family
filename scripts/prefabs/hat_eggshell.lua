local assets = {
    Asset("ANIM", "anim/hat_eggshell.zip"),
    Asset("IMAGE", "images/inventoryimages/hat_eggshell.tex"),
    Asset("ATLAS", "images/inventoryimages/hat_eggshell.xml")
}

local function OnBlocked(owner)
    owner.SoundEmitter:PlaySound("dontstarve/wilson/hit_armour")
end

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
    if equippedArmor ~= nil and equippedArmor:HasTag("armor_halfshell") then
        if inst.sg:HasStateTag("gaint_shell") then
            equippedArmor.components.armor:SetAbsorption(TUNING.FULL_ABSORPTION)
        else
            equippedArmor.components.armor:SetAbsorption(TUNING.ARMORSNURTLESHELL_ABSORPTION)
        end
    end
end

local TARGET_MUST_TAGS = { "_combat" }
local TARGET_CANT_TAGS = { "INLIMBO" }
local function droptargets(inst)
    inst.task = nil

    local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner or nil
    if owner ~= nil and owner.sg:HasStateTag("gaint_shell") then
        local x, y, z = owner.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, 20, TARGET_MUST_TAGS, TARGET_CANT_TAGS)
        for i, v in ipairs(ents) do
            if v.components.combat ~= nil and v.components.combat.target == owner then
                v.components.combat:SetTarget(nil)
            end
        end
    end
end

local function onuse(inst)
    local owner = inst.components.inventoryitem.owner
    if owner ~= nil then
        owner.sg:GoToState("gaint_shell_enter")
        if inst.task ~= nil then
            inst.task:Cancel()
        end
        inst.task = inst:DoTaskInTime(5, droptargets)
    end
end

local function onstopuse(inst)
    if inst.task ~= nil then
        inst.task:Cancel()
        inst.task = nil
    end
end

local function onequip(inst, owner)

    owner.AnimState:OverrideSymbol("swap_hat", "hat_eggshell", "swap_hat")

    owner.AnimState:Show("HAT")
    owner.AnimState:Hide("HAIR_HAT")
    owner.AnimState:Show("HAIR_NOHAT")
    owner.AnimState:Show("HAIR")

    owner.AnimState:Show("HEAD")
    owner.AnimState:Hide("HEAD_HAT")

    if owner:HasTag("player") then
        owner.AnimState:OverrideSymbol("fx_spin_line", "hat_eggshell", "fx_spin_line")
        owner.AnimState:OverrideSymbol("gaint_egg", "hat_eggshell", "gaint_egg")
        owner.AnimState:OverrideSymbol("gap", "hat_eggshell", "gap")
        owner.AnimState:OverrideSymbol("shadow", "hat_eggshell", "shadow")
        owner.AnimState:OverrideSymbol("spot_frame", "hat_eggshell", "spot_frame")
        inst:ListenForEvent("blocked", OnBlocked, owner)
        inst:ListenForEvent("newstate", ProtectionLevels, owner)
    end
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_hat")
    owner.AnimState:Hide("HAT")
    owner.AnimState:Hide("HAIR_HAT")
    owner.AnimState:Show("HAIR_NOHAT")
    owner.AnimState:Show("HAIR")

    if owner:HasTag("player") then
        owner.AnimState:Show("HEAD")
        owner.AnimState:Hide("HEAD_HAT")
        owner.AnimState:ClearOverrideSymbol("fx_spin_line")
        owner.AnimState:ClearOverrideSymbol("gaint_egg")
        owner.AnimState:ClearOverrideSymbol("gap")
        owner.AnimState:ClearOverrideSymbol("shadow")
        owner.AnimState:ClearOverrideSymbol("spot_frame")
        inst:RemoveEventCallback("blocked", OnBlocked, owner)
        inst:RemoveEventCallback("newstate", ProtectionLevels, owner)
        onstopuse(inst)
    end

end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    inst.AnimState:SetBank("hat_eggshell")
    inst.AnimState:SetBuild("hat_eggshell")
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("hat")
    inst:AddTag("hat_eggshell")
    inst:AddTag("hardarmor")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "hat_eggshell"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/hat_eggshell.xml"

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(TUNING.WATERPROOFNESS_SMALLMED)

    inst:AddComponent("insulator")
    inst.components.insulator:SetSummer()
    inst.components.insulator:SetInsulation(TUNING.INSULATION_SMALL)

    inst:AddComponent("armor")
    inst.components.armor:InitCondition(475, TUNING.ARMORSNURTLESHELL_ABSORPTION)

    inst:AddComponent("tradable")

    inst:AddComponent("useableitem")
    inst.components.useableitem:SetOnUseFn(onuse)
    inst.components.useableitem:SetOnStopUseFn(onstopuse)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("hat_eggshell", fn, assets)