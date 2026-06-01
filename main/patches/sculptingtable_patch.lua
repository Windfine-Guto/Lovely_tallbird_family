-- 陶轮补丁：接受高脚鸟蛋作为雕刻材料，合成巨型蛋

AddPrefabPostInit("sculptingtable", function(inst)
    if not GLOBAL.TheWorld.ismastersim then
        return
    end

    local old_abletoaccept = inst.components.trader.abletoaccepttest
    inst.components.trader:SetAbleToAcceptTest(function(inst, item)
        if item.prefab == "tallbirdegg" then
            if inst.components.pickable.caninteractwith then
                return false, "SLOTFULL"
            end
            return true
        end
        return old_abletoaccept(inst, item)
    end)

    local old_onaccept = inst.components.trader.onaccept
    inst.components.trader.onaccept = function(inst, giver, item)
        if item.prefab == "tallbirdegg" then
            inst.components.pickable:SetUp("tallbirdegg", 1000000)
            inst.components.pickable:Pause()
            if not inst.components.pickable.caninteractwith then
                inst.components.pickable.caninteractwith = true
                inst.SoundEmitter:PlaySound("dontstarve/common/together/moonbase/moonstaff_place")
            end

            inst.AnimState:ClearOverrideSymbol("cutstone01")
            inst.AnimState:ClearOverrideSymbol("swap_body")
            inst.AnimState:OverrideSymbol("cutstone01", "tallbird_egg", "swap_tallbird_egg")

            inst.components.prototyper.trees.SCULPTING = TECH.SCULPTING_TWO.SCULPTING
        else
            return old_onaccept(inst, giver, item)
        end
    end

    local old_CreateItem = inst.CreateItem
    inst.CreateItem = function(inst, item)
        local base_ingredient = inst.components.pickable.caninteractwith and inst.components.pickable.product or nil
        if base_ingredient == "tallbirdegg" then
            inst.components.pickable:SetUp("tallbird_egg_oversized", 1000000)
            inst.components.pickable:Pause()
            if not inst.components.pickable.caninteractwith then
                inst.components.pickable.caninteractwith = true
                inst.SoundEmitter:PlaySound("dontstarve/common/together/moonbase/moonstaff_place")
            end

            inst.AnimState:ClearOverrideSymbol("cutstone01")
            inst.AnimState:ClearOverrideSymbol("swap_body")
            inst.AnimState:OverrideSymbol("swap_body", "tallbird_egg_oversized", "swap_body")

            inst.components.prototyper.trees.SCULPTING = TECH.SCULPTING_ONE.SCULPTING

            local fx = SpawnPrefab("collapse_small")
            local x, y, z = inst.Transform:GetWorldPosition()
            fx.Transform:SetPosition(x, y + 1.2, z)
            fx:SetMaterial("stone")
            inst.SoundEmitter:PlaySound("dontstarve/common/together/sculpting_table/craft")
        else
            return old_CreateItem(inst, item)
        end
    end

    local old_OnLoad = inst.OnLoad
    inst.OnLoad = function(inst, data)
        if old_OnLoad then
            old_OnLoad(inst, data)
        end
        if inst.components.pickable.caninteractwith then
            local product = inst.components.pickable.product
            if product == "tallbirdegg" then
                inst.AnimState:ClearOverrideSymbol("cutstone01")
                inst.AnimState:ClearOverrideSymbol("swap_body")
                inst.AnimState:OverrideSymbol("cutstone01", "tallbird_egg", "swap_tallbird_egg")
            elseif product == "tallbird_egg_oversized" then
                inst.AnimState:ClearOverrideSymbol("cutstone01")
                inst.AnimState:ClearOverrideSymbol("swap_body")
                inst.AnimState:OverrideSymbol("swap_body", "tallbird_egg_oversized", "swap_body")
            end
        end
    end
end)
