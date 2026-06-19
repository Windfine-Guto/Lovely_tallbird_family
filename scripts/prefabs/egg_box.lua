local assets =
{
    Asset("ANIM", "anim/egg_box_ui.zip"),
    Asset("ANIM", "anim/egg_box.zip"),
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

-- function params.egg_box.itemtestfn(container, item, slot)
--     return
-- end
-----------------------------------------------------------------------------------------------

local function OnOpen(inst)
    inst.AnimState:PlayAnimation("open")
    inst.AnimState:PushAnimation("opend", false)
    -- inst.components.inventoryitem:ChangeImageName( "_open")

end

local function OnClose(inst)
    inst.AnimState:PlayAnimation("close")
    inst.AnimState:PushAnimation("closed", false)
end

local function ShowRackItem(inst,data)
    local slot = data.slot
    local item = data.item
    inst.AnimState:OverrideSymbol("egg"..slot, "egg_box",item.prefab)
    inst.AnimState:Show("egg"..slot)
end

local function HideRackItem(inst,data)
    local slot = data.slot
    inst.AnimState:Hide("egg"..slot)
    inst.AnimState:ClearOverrideSymbol("egg"..slot)
end

local function OnPutInInventory(inst)

    inst.components.container:Close()
    inst.AnimState:PlayAnimation("closed", false)
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

    inst:AddComponent("inspectable")

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("egg_box")
    inst.components.container.onopenfn = OnOpen
    inst.components.container.onclosefn = OnClose
    inst.components.container.skipclosesnd = true
    inst.components.container.skipopensnd = true
    inst.components.container.droponopen = true

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "hat_eggshell"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/hat_eggshell.xml"

    MakeHauntableLaunchAndDropFirstItem(inst)

    inst:ListenForEvent("itemget", ShowRackItem)
    inst:ListenForEvent("itemlose", HideRackItem)

    return inst
end

return Prefab( "egg_box",   fn,   assets )