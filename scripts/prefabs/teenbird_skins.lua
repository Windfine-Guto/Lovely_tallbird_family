local function init_fn(inst)
    GlassicAPI.BasicInitFn(inst)
end
---清理皮肤
local function clear_fn(inst)
    if inst.AnimState then
        inst.AnimState:SetBuild("tallbird_teen_build")
    end
end

teenbird_clear_fn = clear_fn
---皮肤列表
local skins = {
    CreatePrefabSkin("teenbird_manrabbit", {
        base_prefab = "teenbird",
        type = "item",
        rarity = "Elegant",
        assets = {
            Asset("ANIM", "anim/tallbird_teenskin_manrabbit.zip"),
        },
        init_fn = init_fn,
        clear_fn = clear_fn,
        skin_tags = { "TEENBIRD", "MANRABBIT" },
        build_name_override = "tallbird_teenskin_manrabbit",
    }),
}

return unpack(skins)