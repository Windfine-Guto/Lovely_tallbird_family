local function init_fn(inst)
    GlassicAPI.BasicInitFn(inst)
end
---清理皮肤
local function clear_fn(inst)
    if inst.AnimState then
        inst.AnimState:SetBuild("smallbird_basic")
    end
end

smallbird_clear_fn = clear_fn
---皮肤列表
local skins = {
    CreatePrefabSkin("smallbird_manrabbit", {
        base_prefab = "smallbird",
        type = "item",
        rarity = "Elegant",
        assets = {
            Asset("ANIM", "anim/smallbirdskin_manrabbit.zip"),
        },
        init_fn = init_fn,
        clear_fn = clear_fn,
        skin_tags = { "SMALLBIRD", "MANRABBIIT" },
        build_name_override = "smallbirdskin_manrabbit",
    }),
}

return unpack(skins)