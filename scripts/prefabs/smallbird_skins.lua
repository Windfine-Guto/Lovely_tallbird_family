local function init_fn(inst)
    GlassicAPI.BasicInitFn(inst)
    if inst and inst.AnimState then
        inst.AnimState:AddOverrideBuild("smallbird_basic_water_fx")
    end
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
    CreatePrefabSkin("smallbird_pink", {
        base_prefab = "smallbird",
        type = "item",
        rarity = "Elegant",
        assets = {
            Asset("ANIM", "anim/tallbirdskin_pink.zip"),
        },
        init_fn = init_fn,
        clear_fn = clear_fn,
        skin_tags = { "SMALLBIRD", "PINK" },
        build_name_override = "tallbirdskin_pink",
    }),
    CreatePrefabSkin("smallbird_red", {
        base_prefab = "smallbird",
        type = "item",
        rarity = "Elegant",
        assets = {
            Asset("ANIM", "anim/tallbirdskin_red.zip"),
        },
        init_fn = init_fn,
        clear_fn = clear_fn,
        skin_tags = { "SMALLBIRD", "RED" },
        build_name_override = "tallbirdskin_red",
    }),
    CreatePrefabSkin("smallbird_blue", {
        base_prefab = "smallbird",
        type = "item",
        rarity = "Elegant",
        assets = {
            Asset("ANIM", "anim/tallbirdskin_blue.zip"),
        },
        init_fn = init_fn,
        clear_fn = clear_fn,
        skin_tags = { "SMALLBIRD", "BLUE" },
        build_name_override = "tallbirdskin_blue",
    }),
    CreatePrefabSkin("smallbird_green", {
        base_prefab = "smallbird",
        type = "item",
        rarity = "Elegant",
        assets = {
            Asset("ANIM", "anim/tallbirdskin_green.zip"),
        },
        init_fn = init_fn,
        clear_fn = clear_fn,
        skin_tags = { "SMALLBIRD", "GREEN" },
        build_name_override = "tallbirdskin_green",
    }),
    CreatePrefabSkin("smallbird_purple", {
        base_prefab = "smallbird",
        type = "item",
        rarity = "Elegant",
        assets = {
            Asset("ANIM", "anim/tallbirdskin_purple.zip"),
        },
        init_fn = init_fn,
        clear_fn = clear_fn,
        skin_tags = { "SMALLBIRD", "PURPLE" },
        build_name_override = "tallbirdskin_purple",
    }),
    CreatePrefabSkin("smallbird_brown", {
        base_prefab = "smallbird",
        type = "item",
        rarity = "Elegant",
        assets = {
            Asset("ANIM", "anim/tallbirdskin_brown.zip"),
        },
        init_fn = init_fn,
        clear_fn = clear_fn,
        skin_tags = { "SMALLBIRD", "BROWN" },
        build_name_override = "tallbirdskin_brown",
    }),
    CreatePrefabSkin("smallbird_snowman", {
        base_prefab = "smallbird",
        type = "item",
        rarity = "Elegant",
        assets = {
            Asset("ANIM", "anim/tallbirdskin_snowman.zip"),
        },
        init_fn = init_fn,
        clear_fn = clear_fn,
        skin_tags = { "SMALLBIRD", "SNOWMAN" },
        build_name_override = "tallbirdskin_snowman",
    }),
}

return unpack(skins)