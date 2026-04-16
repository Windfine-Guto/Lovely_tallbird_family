local function init_fn(inst)
    GlassicAPI.BasicInitFn(inst)
end
---清理皮肤
local function clear_fn(inst)
    if inst.AnimState then
        inst.AnimState:SetBuild("ds_tallbird_basic")
    end
end

tallbird_clear_fn = clear_fn
---皮肤列表
local skins = {
    CreatePrefabSkin("tallbird_teen", {   ---皮肤名字
        base_prefab = "tallbird",      ---高脚鸟
        type = "item",
        rarity = "Elegant",
        assets = {
            Asset("ANIM", "anim/tallbird_teen_build.zip"),  ---build资源位置
        },
        init_fn = init_fn,
        clear_fn = clear_fn,
        skin_tags = { "TALLBIRD", "TEEN" },      ---皮肤标签
        build_name_override = "tallbird_teen_build",   ---皮肤build名字
    }),
    CreatePrefabSkin("tallbird_pink", {   ---皮肤名字
        base_prefab = "tallbird",      ---高脚鸟
        type = "item",
        rarity = "Elegant",
        assets = {
            Asset("ANIM", "anim/tallbirdskin_pink.zip"),  ---build资源位置
        },
        init_fn = init_fn,
        clear_fn = clear_fn,
        skin_tags = { "TALLBIRD", "PINK" },      ---皮肤标签
        build_name_override = "tallbirdskin_pink",   ---皮肤build名字
    }),
    CreatePrefabSkin("tallbird_red", {   ---皮肤名字
        base_prefab = "tallbird",      ---高脚鸟
        type = "item",
        rarity = "Elegant",
        assets = {
            Asset("ANIM", "anim/tallbirdskin_red.zip"),  ---build资源位置
        },
        init_fn = init_fn,
        clear_fn = clear_fn,
        skin_tags = { "TALLBIRD", "RED" },      ---皮肤标签
        build_name_override = "tallbirdskin_red",   ---皮肤build名字
    }),
    CreatePrefabSkin("tallbird_blue", {   ---皮肤名字
        base_prefab = "tallbird",      ---高脚鸟
        type = "item",
        rarity = "Elegant",
        assets = {
            Asset("ANIM", "anim/tallbirdskin_blue.zip"),  ---build资源位置
        },
        init_fn = init_fn,
        clear_fn = clear_fn,
        skin_tags = { "TALLBIRD", "BLUE" },      ---皮肤标签
        build_name_override = "tallbirdskin_blue",   ---皮肤build名字
    }),
    CreatePrefabSkin("tallbird_green", {   ---皮肤名字
        base_prefab = "tallbird",      ---高脚鸟
        type = "item",
        rarity = "Elegant",
        assets = {
            Asset("ANIM", "anim/tallbirdskin_green.zip"),  ---build资源位置
        },
        init_fn = init_fn,
        clear_fn = clear_fn,
        skin_tags = { "TALLBIRD", "GREEN" },      ---皮肤标签
        build_name_override = "tallbirdskin_green",   ---皮肤build名字
    }),
    CreatePrefabSkin("tallbird_manrabbit", {   ---皮肤名字
        base_prefab = "tallbird",      ---高脚鸟
        type = "item",
        rarity = "Elegant",
        assets = {
            Asset("ANIM", "anim/tallbirdskin_manrabbit.zip"),  ---build资源位置
        },
        init_fn = init_fn,
        clear_fn = clear_fn,
        skin_tags = { "TALLBIRD", "MANRABBIIT" },      ---皮肤标签
        build_name_override = "tallbirdskin_manrabbit",   ---皮肤build名字
    }),
    CreatePrefabSkin("tallbird_purple", {   ---皮肤名字
        base_prefab = "tallbird",      ---高脚鸟
        type = "item",
        rarity = "Elegant",
        assets = {
            Asset("ANIM", "anim/tallbirdskin_purple.zip"),  ---build资源位置
        },
        init_fn = init_fn,
        clear_fn = clear_fn,
        skin_tags = { "TALLBIRD", "PURPLE" },      ---皮肤标签
        build_name_override = "tallbirdskin_purple",   ---皮肤build名字
    }),
    CreatePrefabSkin("tallbird_brown", {   ---皮肤名字
        base_prefab = "tallbird",      ---高脚鸟
        type = "item",
        rarity = "Elegant",
        assets = {
            Asset("ANIM", "anim/tallbirdskin_brown.zip"),  ---build资源位置
        },
        init_fn = init_fn,
        clear_fn = clear_fn,
        skin_tags = { "TALLBIRD", "BROWN" },      ---皮肤标签
        build_name_override = "tallbirdskin_brown",   ---皮肤build名字
    }),
    CreatePrefabSkin("tallbird_snowman", {   ---皮肤名字
        base_prefab = "tallbird",      ---高脚鸟
        type = "item",
        rarity = "Elegant",
        assets = {
            Asset("ANIM", "anim/tallbirdskin_snowman.zip"),  ---build资源位置
        },
        init_fn = init_fn,
        clear_fn = clear_fn,
        skin_tags = { "TALLBIRD", "SNOWMAN" },      ---皮肤标签
        build_name_override = "tallbirdskin_snowman",   ---皮肤build名字
    }),
    -- CreatePrefabSkin("tallbird_", {
    --     base_prefab = "tallbird",
    --     type = "item",
    --     rarity = "Elegant",
    --     assets = {
    --         Asset("ANIM", "anim/test_tallbird_build.zip"),
    --     },
    --     init_fn = init_fn,
    --     clear_fn = clear_fn,
    --     skin_tags = { "TALLBIRD", "TEST" },
    --     build_name_override = "test_tallbird_build",
    -- }),
}

return unpack(skins)