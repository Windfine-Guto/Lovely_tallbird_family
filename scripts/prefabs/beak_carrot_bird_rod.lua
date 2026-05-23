local containers=require("containers")
local params=containers.params

params.carrotfishingrod =
{
    widget =
    {
        slotpos = {
            Vector3(0, 15, 0),
        },
        slotbg =
        {
            { image = "spore_slot.tex", atlas = "images/hud2.xml" },
        },
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
    return item:HasTag("meat")
end

local assets = {
    Asset("ANIM", "anim/beak_carrot_bird_rod.zip"),
    Asset("IMAGE","images/inventoryimages/beak_carrot_bird_rod.tex"),
	Asset("ATLAS", "images/inventoryimages/beak_carrot_bird_rod.xml"),
}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "beak_carrot_bird_rod", "swap_object")
    owner.AnimState:OverrideSymbol("carrot", "beak_carrot_bird_rod", "carrot")
    for i = 0, 24 do
        owner.AnimState:OverrideSymbol("fishline-"..i, "beak_carrot_bird_rod", "fishline-"..i)
    end
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    if inst.components.container then
        inst.components.container:Open(owner)
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

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("idle")
    inst.AnimState:SetBuild("beak_carrot_bird_rod")
    inst.AnimState:PlayAnimation("idle")

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

	inst.components.floater:SetBankSwapOnFloat(true, -37, { sym_build = "yoth_lance", sym_name = "swap_lance" })

    local finiteuses = inst:AddComponent("finiteuses")
    finiteuses:SetMaxUses(TUNING.YOTH_LANCE_USES)
    finiteuses:SetUses(TUNING.YOTH_LANCE_USES)
    finiteuses:SetOnFinished(on_uses_finished)

    local weapon = inst:AddComponent("weapon")
    weapon:SetDamage(TUNING.YOTH_LANCE_ATTACK_DAMAGE)
    weapon:SetRange(TUNING.YOTH_LANCE_LENGTH)

    local joustsource = inst:AddComponent("joustsource")
    joustsource:SetSpeed(TUNING.YOTH_LANCE_JOUST_SPEED)
    joustsource:SetLanceLength(TUNING.YOTH_LANCE_LENGTH)
    joustsource:SetRunAnimLoopCount(TUNING.YOTH_LANCE_RUNANIM_LOOP_COUNT*1000)
    joustsource:SetOnHitOtherFn(OnHitOther)

    local container = inst:AddComponent("container")
	container:WidgetSetup("carrotfishingrod")

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "beak_carrot_bird_rod"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/beak_carrot_bird_rod.xml"

    inst:AddComponent("fencerotator")

    local equippable = inst:AddComponent("equippable")
    equippable:SetOnEquip(onequip)
    equippable:SetOnUnequip(onunequip)

    return inst
end

return Prefab("beak_carrot_bird_rod", fn, assets)