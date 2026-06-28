local function AddCreator(savedata)
    if savedata then
        savedata.creator = { sessionid = TheWorld.meta.session_identifier }

        -- print("[ADDCREATOR]", savedata.prefab, "skin:", savedata.skinname)

        if savedata.data and savedata.data.inventory then
            local inv = savedata.data.inventory
            -- print("[ADDCREATOR]", "has inventory, equip:", tostring(inv.equip ~= nil), "items:", tostring(inv.items ~= nil))
            if inv.items then
                for _, item in pairs(inv.items) do
                    if type(item) == "table" and item.prefab then
                        AddCreator(item)
                    end
                end
            end
            if inv.equip then
                for _, item in pairs(inv.equip) do
                    if type(item) == "table" and item.prefab then
                        AddCreator(item)
                    end
                end
            end
            if inv.activeitem and type(inv.activeitem) == "table" and inv.activeitem.prefab then
                AddCreator(inv.activeitem)
            end
        end
    end
end

local function SpawnSaveCreator(saved, newents)
    local inst = SpawnPrefab(saved.prefab, saved.skinname, saved.skin_id, saved.creator)

    if inst then
        inst.Transform:SetPosition(saved.x or 0, saved.y or 0, saved.z or 0)

        if not inst.entity:IsValid() then
            return nil
        end

        -- 临时替换全局 SpawnSaveRecord，让嵌套物品也走这个逻辑
        local _SetPersistData = inst.SetPersistData
        inst.SetPersistData = function(self, data, newents, ...)
            local old_SpawnSaveRecord = SpawnSaveRecord
            SpawnSaveRecord = SpawnSaveCreator

            local success, err = pcall(_SetPersistData, self, data, newents, ...)

            SpawnSaveRecord = old_SpawnSaveRecord
            if not success then
                print(string.format("[SpawnSavePets] SetPersistData failed for %s: %s", self.prefab, err))
            end
        end

        inst:SetPersistData(saved.data, newents)

        -- 还原
        inst.SetPersistData = _SetPersistData
    else
        print(string.format("[SpawnSavePets] %s FAILED", tostring(saved.prefab)))
    end

    return inst
end

return {
    AddCreator = AddCreator,
    SpawnSaveCreator = SpawnSaveCreator,
}