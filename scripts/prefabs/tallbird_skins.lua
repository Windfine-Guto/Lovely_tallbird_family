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