local containers=require("containers")
local params=containers.params

local container_prefabs = {
    "carrot",
    "lightbulb",
    "wormlight",
    "wormlight_lesser",
}

params.carrotfishingrod =
{
    widget =
    {
        slotpos = {
            Vector3(0, 15, 0),
        },
        -- slotbg =
        -- {
        --     { image = "spore_slot.tex", atlas = "images/hud2.xml" },
        -- },
        animbank = "ui_alterguardianhat_1x1",
        animbuild = "ui_alterguardianhat_1x1",
        pos = Vector3(0, 60, 0),
    },
    acceptsstacks = true,
    usespecificslotsforitems = true,
    type = "hand_inv",
    excludefromcrafting = true,
}

function params.carrotfishingrod.itemtestfn(container, item, slot)
    return item:HasTag("dryable") or item.prefab=="carrot" or item.prefab=="lightbulb"
    or item.prefab=="wormlight" or item.prefab=="wormlight_lesser"
end

local assets = {
    Asset("ANIM", "anim/beak_carrot_bird_rod.zip"),
    Asset("ANIM", "anim/swap_chum.zip"),
    Asset("IMAGE","images/inventoryimages/beak_carrot_bird_rod.tex"),
	Asset("ATLAS", "images/inventoryimages/beak_carrot_bird_rod.xml"),
}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "beak_carrot_bird_rod", "swap_object")
    for i = 0, 24 do
        owner.AnimState:OverrideSymbol("fishline-"..i, "beak_carrot_bird_rod", "fishline-"..i)
    end
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    local item = nil
    local build = nil
    if inst.components.container then
        inst.components.container:Open(owner)
        item = inst.components.container:GetItemInSlot(1)
    end

    if item then
        build = item.components.dryable and item.components.dryable:GetBuildFile() or "meat_rack_food"
        if item.components.dryable then
            owner.AnimState:OverrideSymbol("carrot", build, item.prefab)
        else
            owner.AnimState:OverrideSymbol("carrot", "swap_chum", item.prefab)
            if item.prefab~="carrot" then
                local Light_fx = SpawnPrefab("lunar_tallbird_light_fx")
                Light_fx.entity:SetParent(owner.entity)
                Light_fx.entity:AddFollower()
                Light_fx.Follower:FollowSymbol(owner.GUID, "swap_object", 0, 0, 0)
                owner.rod_tallbird_light_fx = Light_fx
            end
        end
    else
        owner.AnimState:ClearOverrideSymbol("carrot")
    end
    if not owner:HasTag("beak_carrot_bird_rod_user") then
        owner:AddTag("beak_carrot_bird_rod_user")
    end
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")

    owner.AnimState:ClearOverrideSymbol("carrot")
    for i = 0, 24 do
        owner.AnimState:ClearOverrideSymbol("fishline-"..i)
    end

    if inst.components.container then
        inst.components.container:Close(owner)
    end

    owner:RemoveTag("beak_carrot_bird_rod_user")
    owner:RemoveTag("beak_carrot_bird_rod_joust")

    if owner.rod_tallbird_light_fx then
        owner.rod_tallbird_light_fx:Remove()
    end
end

local function on_uses_finished(inst)
    local owner = inst.components.inventoryitem:GetGrandOwner()
    if owner then
        owner:PushEvent("toolbroke", { tool = inst })
    end

    inst:Remove()
end

local function OnHitOther(inst, owner, target)
    local fx = SpawnPrefab((target:HasTag("largecreature") or target:HasTag("epic")) and "round_puff_fx_lg" or "round_puff_fx_sm")
    fx.Transform:SetPosition(target.Transform:GetWorldPosition())
end

local function UseModifier(uses, action, doer, target, item)
    if (action == ACTIONS.ROW or action == ACTIONS.ROW_FAIL or action == ACTIONS.ROW_CONTROLLER)
            and doer:HasTag("master_crewman") then
        uses = uses * TUNING.MASTER_CREWMAN_MULT.OAR_CONSUMPTION
    end
    return uses
end

local function ShowRackItem(inst,data)
    if inst.components.equippable and inst.components.equippable:IsEquipped() then
        local owner = inst.components.inventoryitem and inst.components.inventoryitem.owner
        onequip(inst,owner)
        inst:AddTag("beak_rod_fishing")
        owner:AddTag("beak_carrot_bird_rod_joust")
    end
end

local function HideRackItem(inst,data)
    local owner = inst.components.inventoryitem and inst.components.inventoryitem.owner
    if inst.components.equippable and inst.components.equippable:IsEquipped() then
        onequip(inst,owner)
        inst:RemoveTag("beak_rod_fishing")
        owner:RemoveTag("beak_carrot_bird_rod_joust")
    end
    if owner.rod_tallbird_light_fx then
        owner.rod_tallbird_light_fx:Remove()
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("beak_carrot_bird_rod")
    inst.AnimState:SetBuild("beak_carrot_bird_rod")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("allow_action_on_impassable")
    inst:AddTag("nopunch")
    inst:AddTag("carrotfishingrod")

	MakeInventoryFloatable(inst, "med", 0.05, {1.8, 0.5, 1}, true, -37)

    inst:AddTag("pointy")
    inst:AddTag("lancejab")

    --weapon (from weapon component) added to pristine state for optimization

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst.OnEntityReplicated=function (inst)
            if inst.replica.container then
                inst.replica.container:WidgetSetup("carrotfishingrod")
            end
        end
        return inst
    end

	inst.components.floater:SetBankSwapOnFloat(true, -37, { sym_build = "beak_carrot_bird_rod", sym_name = "swap_object" })

    local finiteuses = inst:AddComponent("finiteuses")
    finiteuses:SetMaxUses(TUNING.BOAT.OARS.MALBATROSS.USES)
    finiteuses:SetUses(TUNING.BOAT.OARS.MALBATROSS.USES)
    finiteuses:SetConsumption(ACTIONS.ROW, 1)
    finiteuses:SetConsumption(ACTIONS.ROW_CONTROLLER, 1)
    finiteuses:SetConsumption(ACTIONS.ROW_FAIL, TUNING.BOAT.OARS.MALBATROSS.ROW_FAIL_WEAR)
    finiteuses:SetOnFinished(on_uses_finished)
    finiteuses:SetModifyUseConsumption(UseModifier)

    local weapon = inst:AddComponent("weapon")
    weapon:SetDamage(TUNING.BOAT.OARS.MALBATROSS.DAMAGE)
    weapon:SetRange(TUNING.YOTH_LANCE_LENGTH)

    local joustsource = inst:AddComponent("joustsource")
    joustsource:SetSpeed(TUNING.YOTH_LANCE_JOUST_SPEED)
    joustsource:SetLanceLength(TUNING.YOTH_LANCE_LENGTH)
    joustsource:SetRunAnimLoopCount(TUNING.YOTH_LANCE_RUNANIM_LOOP_COUNT)
    joustsource:SetOnHitOtherFn(OnHitOther)

    local container = inst:AddComponent("container")
	container:WidgetSetup("carrotfishingrod")

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "beak_carrot_bird_rod"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/beak_carrot_bird_rod.xml"

    inst:AddComponent("fencerotator")

    inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(0)

    local oar = inst:AddComponent("oar")
    oar.force = TUNING.BOAT.OARS.MALBATROSS.FORCE
    oar.max_velocity = TUNING.BOAT.OARS.MALBATROSS.MAX_VELOCITY

    local equippable = inst:AddComponent("equippable")
    equippable:SetOnEquip(onequip)
    equippable:SetOnUnequip(onunequip)

    inst:ListenForEvent("itemget", ShowRackItem)
    inst:ListenForEvent("itemlose", HideRackItem)

    return inst
end

return Prefab("beak_carrot_bird_rod", fn, assets)