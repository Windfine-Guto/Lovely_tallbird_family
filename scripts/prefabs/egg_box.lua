local assets =
{
    Asset("ANIM", "anim/egg_box_ui.zip"),
    Asset("ANIM", "anim/egg_box.zip"),
    Asset("IMAGE","images/inventoryimages/egg_box.tex"),
	Asset("ATLAS", "images/inventoryimages/egg_box.xml"),
}

local containers=require("containers")
local params=containers.params

params.egg_box =
{
    widget =
    {
        slotpos = {},
        animbank = "egg_box_ui",
        animbuild = "egg_box_ui",
        pos = Vector3(0, 220, 0),
        side_align_tip = 160,
    },
    type = "chest",
}

for y = 2.5, -0.5, -1 do
    for x = 0, 2 do
        table.insert(params.egg_box.widget.slotpos, Vector3(75 * x - 75 * 2 + 75, 75 * y - 75 * 2 + 75, 0))
    end
end

local food_item = {
    ["tallbirdegg"] = true,
    ["bird_egg"] = true,
}

local SOUNDS =
{
    open  = "meta5/wendy/basket_open",
    close = "meta5/wendy/basket_close",
}

function params.egg_box.itemtestfn(container, item, slot)
    return food_item[item.prefab]
end
-----------------------------------------------------------------------------------------------

local function OnOpen(inst)
    if inst:HasTag("burnt") then
        return
    end
    inst.AnimState:PlayAnimation("open")
    inst.AnimState:PushAnimation("opend", false)
    inst.SoundEmitter:PlaySound(inst._sounds.open)
    local grand_owner = inst.components.inventoryitem:GetGrandOwner()
    if grand_owner then
        local animstate = grand_owner.AnimState
        if animstate then
            animstate:AddOverrideBuild(inst.AnimState:GetBuild())
            local container = inst.components.container
            local num_slot = 0
            if container then
                num_slot = container:GetNumSlots()
                for i = 1, num_slot do
                    local item = container:GetItemInSlot(i)
                    if item then
                        animstate:OverrideSymbol("egg"..i,"egg_box",item.prefab)
                    else
                        animstate:Hide("egg"..i)
                    end
                end
            end
        end
    end
end

local function OnClose(inst)
    if inst:HasTag("burnt") then
        return
    end
    inst.AnimState:PlayAnimation("close")
    inst.AnimState:PushAnimation("closed", false)
    inst.SoundEmitter:PlaySound(inst._sounds.close)
    local grand_owner = inst.components.inventoryitem:GetGrandOwner()
    if grand_owner then
        grand_owner:DoTaskInTime(0.2,function()
            local animstate = grand_owner.AnimState
            if animstate then
                animstate:ClearOverrideBuild(inst.AnimState:GetBuild())
            end
        end)
    end
end

local function ShowRackItem(inst,data)
    local slot = data.slot
    local item = data.item
    if slot and item then
        inst.AnimState:OverrideSymbol("egg"..slot, "egg_box",item.prefab)
        inst.AnimState:Show("egg"..slot)
        local grand_owner = inst.components.inventoryitem:GetGrandOwner()
        if grand_owner then
            grand_owner:PushEvent("itemgetorlose")
            local animstate = grand_owner.AnimState
            if animstate then
                grand_owner:DoTaskInTime(0.2,function ()
                    animstate:OverrideSymbol("egg"..slot, "egg_box",item.prefab)
                    animstate:Show("egg"..slot)
                end)
            end
        end
    end
end

local function HideRackItem(inst,data)
    local slot = data.slot
    if slot then
        inst.AnimState:Hide("egg"..slot)
        inst.AnimState:ClearOverrideSymbol("egg"..slot)
        local grand_owner = inst.components.inventoryitem:GetGrandOwner()
        if grand_owner then
            grand_owner:PushEvent("itemgetorlose")
            local animstate = grand_owner.AnimState
            if animstate then
                grand_owner:DoTaskInTime(0.2,function ()
                    animstate:ClearOverrideSymbol("egg"..slot)
                    animstate:Hide("egg"..slot)
                end)
            end
        end
    end
end

local function OnPutInInventory(inst)
    inst.components.container:Close()
    inst.AnimState:PlayAnimation("closed", false)
end

-----------------------------------------------------------------------------------------------

local function OnBurnt(inst)
    local container = inst.components.container
    local num_slot = 0
    if container then
        num_slot = container:GetNumSlots()
        for i = 1, num_slot do
            local item = container:GetItemInSlot(i)
            if item and item.components.cookable then
                local cooked = item.components.cookable:Cook()
                item:Remove()
                if cooked then
                    container:GiveItem(cooked, i)
                end
            else
                container:DropItemBySlot(i)
            end
        end
    end
    DefaultBurntFn(inst)
end

-----------------------------------------------------------------------------------------------

local function OnSave(inst, data)
    if (inst.components.burnable ~= nil and inst.components.burnable:IsBurning()) or inst:HasTag("burnt") then
        data.burnt = true
    end
end

local function OnLoad(inst, data)
    if data ~= nil and data.burnt and inst.components.burnable ~= nil then
        inst.components.burnable.onburnt(inst)
    end
end

-----------------------------------------------------------------------------------------------

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    -- inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    -- inst.MiniMapEntity:SetIcon("beargerfur_sack.png")

    inst.AnimState:SetBank("egg_box")
    inst.AnimState:SetBuild("egg_box")
    inst.AnimState:PlayAnimation("closed")
    for i = 1, 12 do
        inst.AnimState:Hide("egg"..i)
    end

    MakeInventoryPhysics(inst)

    MakeInventoryFloatable(inst, "small", 0.35)

    inst:AddTag("portablestorage")
    inst:AddTag("egg_box")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst.OnEntityReplicated=function (inst)
            if inst.replica.container then
                inst.replica.container:WidgetSetup("egg_box")
            end
        end
        return inst
    end

    inst._sounds = SOUNDS

    inst:AddComponent("inspectable")
    inst:AddComponent("lootdropper")

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("egg_box")
    inst.components.container.onopenfn = OnOpen
    inst.components.container.onclosefn = OnClose
    inst.components.container.skipclosesnd = true
    inst.components.container.skipopensnd = true
    inst.components.container.droponopen = true

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetOnPutInInventoryFn(OnPutInInventory)
    inst.components.inventoryitem.imagename = "egg_box"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/egg_box.xml"

    MakeSmallBurnable(inst)

    inst.components.burnable:SetOnBurntFn(OnBurnt)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    MakeHauntableLaunchAndDropFirstItem(inst)

    inst:ListenForEvent("itemget", ShowRackItem)
    inst:ListenForEvent("itemlose", HideRackItem)

    return inst
end

return Prefab( "egg_box",   fn,   assets )