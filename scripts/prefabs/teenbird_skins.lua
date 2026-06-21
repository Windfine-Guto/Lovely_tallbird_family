local function init_fn(inst)
    GlassicAPI.BasicInitFn(inst)
    if inst and inst.AnimState then
        inst.AnimState:AddOverrideBuild("ds_tallbird_basic_water_fx")
    end
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
    CreatePrefabSkin("teenbird_pink", {
        base_prefab = "teenbird",
        type = "item",
        rarity = "Elegant",
        assets = {
            Asset("ANIM", "anim/tallbirdskin_pink.zip"),
        },
        init_fn = init_fn,
        clear_fn = clear_fn,
        skin_tags = { "TEENBIRD", "PINK" },
        build_name_override = "tallbirdskin_pink",
    }),
    CreatePrefabSkin("teenbird_red", {
        base_prefab = "teenbird",
        type = "item",
        rarity = "Elegant",
        assets = {
            Asset("ANIM", "anim/tallbirdskin_red.zip"),
        },
        init_fn = init_fn,
        clear_fn = clear_fn,
        skin_tags = { "TEENBIRD", "RED" },
        build_name_override = "tallbirdskin_red",
    }),
    CreatePrefabSkin("teenbird_blue", {
        base_prefab = "teenbird",
        type = "item",
        rarity = "Elegant",
        assets = {
            Asset("ANIM", "anim/tallbirdskin_blue.zip"),
        },
        init_fn = init_fn,
        clear_fn = clear_fn,
        skin_tags = { "TEENBIRD", "BLUE" },
        build_name_override = "tallbirdskin_blue",
    }),
    CreatePrefabSkin("teenbird_green", {
        base_prefab = "teenbird",
        type = "item",
        rarity = "Elegant",
        assets = {
            Asset("ANIM", "anim/tallbirdskin_green.zip"),
        },
        init_fn = init_fn,
        clear_fn = clear_fn,
        skin_tags = { "TEENBIRD", "GREEN" },
        build_name_override = "tallbirdskin_green",
    }),
    CreatePrefabSkin("teenbird_purple", {
        base_prefab = "teenbird",
        type = "item",
        rarity = "Elegant",
        assets = {
            Asset("ANIM", "anim/tallbirdskin_purple.zip"),
        },
        init_fn = init_fn,
        clear_fn = clear_fn,
        skin_tags = { "TEENBIRD", "PURPLE" },
        build_name_override = "tallbirdskin_purple",
    }),
    CreatePrefabSkin("teenbird_brown", {
        base_prefab = "teenbird",
        type = "item",
        rarity = "Elegant",
        assets = {
            Asset("ANIM", "anim/tallbirdskin_brown.zip"),
        },
        init_fn = init_fn,
        clear_fn = clear_fn,
        skin_tags = { "TEENBIRD", "BROWN" },
        build_name_override = "tallbirdskin_brown",
    }),
    CreatePrefabSkin("teenbird_snowman", {
        base_prefab = "teenbird",
        type = "item",
        rarity = "Elegant",
        assets = {
            Asset("ANIM", "anim/tallbirdskin_snowman.zip"),
        },
        init_fn = init_fn,
        clear_fn = clear_fn,
        skin_tags = { "TEENBIRD", "SNOWMAN" },
        build_name_override = "tallbirdskin_snowman",
    }),
}

return unpack(skins)