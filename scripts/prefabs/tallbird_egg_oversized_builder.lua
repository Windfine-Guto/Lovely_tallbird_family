local function builderonbuilt(inst, builder)
    local prototyper = builder.components.builder.current_prototyper
    if prototyper ~= nil and prototyper.CreateItem ~= nil then
        prototyper:CreateItem("tallbird_egg_oversized")
    else
        local egg = SpawnPrefab("tallbird_egg_oversized")
        egg.Transform:SetPosition(builder.Transform:GetWorldPosition())
    end
    inst:Remove()
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()

    inst:AddTag("CLASSIFIED")

    inst.persists = false

    inst:DoTaskInTime(0, inst.Remove)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.OnBuiltFn = builderonbuilt

    return inst
end

return Prefab("tallbird_egg_oversized_builder", fn, nil, { "tallbird_egg_oversized" })