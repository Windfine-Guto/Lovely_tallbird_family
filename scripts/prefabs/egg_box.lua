local assets =
{
    Asset("ANIM", "anim/egg_box_ui.zip"),
    Asset("ANIM", "anim/egg_box.zip"),
    Asset("ANIM", "anim/egg_box_item.zip"),
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

local egg_box_item = require("egg_box_item").item
local dynamic_item = require("egg_box_item").dynamic_item

local SOUNDS =
{
    open  = "meta5/wendy/basket_open",
    close = "meta5/wendy/basket_close",
}

function params.egg_box.itemtestfn(container, item, slot)
    return egg_box_item[item.prefab] or dynamic_item[item.prefab]
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
                        if dynamic_item[item.prefab] then
                            local fx = SpawnPrefab("egg_box_dynamic_fx")
                            local scale = dynamic_item[item.prefab].scale
                            fx.AnimState:SetBank(dynamic_item[item.prefab].bank)
                            fx.AnimState:SetBuild(dynamic_item[item.prefab].build)
                            fx.AnimState:PlayAnimation(dynamic_item[item.prefab].anim,true)
                            if dynamic_item[item.prefab].multcolor then
                                fx.AnimState:SetMultColour(1, 1, 1, 0.5)
                            end
                            fx.entity:SetParent(grand_owner.entity)
                            fx.entity:AddFollower()
                            fx.Follower:FollowSymbol(grand_owner.GUID, "egg"..i, 0, 40, 0,true, true)
                            fx.Transform:SetScale(scale, scale, scale)
                            grand_owner._tallbird_egg_box_dynamic_item[i] = fx
                        else
                            animstate:OverrideSymbol("egg"..i,"egg_box_item",item.prefab)
                        end
                    else
                        if grand_owner._tallbird_egg_box_dynamic_item[i] then
                            grand_owner._tallbird_egg_box_dynamic_item[i]:Remove()
                            grand_owner._tallbird_egg_box_dynamic_item[i] = nil
                        else
                            animstate:ClearOverrideSymbol("egg"..i)
                        end
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
            local dynamicitem = grand_owner._tallbird_egg_box_dynamic_item
            local animstate = grand_owner.AnimState
            if animstate then
                animstate:ClearOverrideBuild(inst.AnimState:GetBuild())
            end
            if dynamicitem then
                for k, v in pairs(dynamicitem) do
                    if v and v:IsValid() then
                        v:Remove()
                        dynamicitem[k] = nil
                    end
                end
            end
        end)
    end
end

local function ShowRackItem(inst,data)
    local slot = data.slot
    local item = data.item
    if slot and item then
        if dynamic_item[item.prefab] then
            local fx = SpawnPrefab("egg_box_dynamic_fx")
            local scale = dynamic_item[item.prefab].scale
            fx.AnimState:SetBank(dynamic_item[item.prefab].bank)
            fx.AnimState:SetBuild(dynamic_item[item.prefab].build)
            fx.AnimState:PlayAnimation(dynamic_item[item.prefab].anim,true)
            if dynamic_item[item.prefab].multcolor then
                fx.AnimState:SetMultColour(1, 1, 1, 0.5)
            end
            fx.entity:SetParent(inst.entity)
            fx.entity:AddFollower()
            fx.Follower:FollowSymbol(inst.GUID, "egg"..slot, 0, 40, 0,true, true)
            fx.Transform:SetScale(scale, scale, scale)
            inst._dynamic_item[slot] = fx
        else
            inst.AnimState:OverrideSymbol("egg"..slot, "egg_box_item",item.prefab)
        end
        local grand_owner = inst.components.inventoryitem:GetGrandOwner()
        if grand_owner then
            grand_owner:PushEvent("itemgetorlose")
            local animstate = grand_owner.AnimState
            if animstate then
                grand_owner:DoTaskInTime(0.2,function ()
                    if dynamic_item[item.prefab] then
                        local fx = SpawnPrefab("egg_box_dynamic_fx")
                        local scale = dynamic_item[item.prefab].scale
                        fx.AnimState:SetBank(dynamic_item[item.prefab].bank)
                        fx.AnimState:SetBuild(dynamic_item[item.prefab].build)
                        fx.AnimState:PlayAnimation(dynamic_item[item.prefab].anim,true)
                        if dynamic_item[item.prefab].multcolor then
                            fx.AnimState:SetMultColour(1, 1, 1, 0.5)
                        end
                        fx.entity:SetParent(grand_owner.entity)
                        fx.entity:AddFollower()
                        fx.Follower:FollowSymbol(grand_owner.GUID, "egg"..slot, 0, 40, 0,true, true)
                        fx.Transform:SetScale(scale, scale, scale)
                        grand_owner._tallbird_egg_box_dynamic_item[slot] = fx
                    else
                        animstate:OverrideSymbol("egg"..slot, "egg_box_item",item.prefab)
                    end
                end)
            end
        end
    end
end

local function HideRackItem(inst,data)
    local slot = data.slot
    local item = data.prev_item
    local prefab = item and item.prefab or nil
    local total_slots = inst.components.container:GetNumSlots() or 12
    local empty_slots = 0
    for i = 1, total_slots do
        if inst.components.container:GetItemInSlot(i) == nil then
            empty_slots = empty_slots + 1
        end
    end
    if empty_slots~=1 then
        prefab = nil
    end
    if slot then
        if inst._dynamic_item[slot] then
            inst._dynamic_item[slot]:Remove()
            inst._dynamic_item[slot] = nil
        else
            inst.AnimState:ClearOverrideSymbol("egg"..slot)
        end
        local grand_owner = inst.components.inventoryitem:GetGrandOwner()
        if grand_owner then
            grand_owner:PushEvent("itemgetorlose",{itemprefab = prefab})
            local animstate = grand_owner.AnimState
            if animstate then
                grand_owner:DoTaskInTime(0.2,function ()
                    if dynamic_item[item.prefab] then
                        local dynamicitem = grand_owner._tallbird_egg_box_dynamic_item[slot]
                        if dynamicitem and dynamicitem:IsValid() then
                            dynamicitem:Remove()
                            dynamicitem = nil
                        end
                    else
                        animstate:ClearOverrideSymbol("egg"..slot)
                    end
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
                local stack_size = item.components.stackable
                and item.components.stackable:StackSize() or 1
                local cooked = item.components.cookable:Cook()
                if cooked then
                    if cooked.components.stackable and stack_size > 1 then
                        cooked.components.stackable:SetStackSize(stack_size)
                    end
                    item:Remove()
                    container:GiveItem(cooked, i)
                    container:DropItemBySlot(i)
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

    inst._dynamic_item = {}
    inst._owner_dynamic_item = {}

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    MakeHauntableLaunchAndDropFirstItem(inst)

    inst:ListenForEvent("itemget", ShowRackItem)
    inst:ListenForEvent("itemlose", HideRackItem)

    return inst
end

return Prefab( "egg_box",   fn,   assets )