local function MakeFx(data)
    local assets =
    {
        Asset("ANIM", "anim/merm_actions_skills.zip"),
        Asset("ANIM", "anim/brightmare_gestalt_head_evolved.zip")
    }
    local function commonfn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddNetwork()
        inst.entity:AddAnimState()
        inst:AddTag("FX")
        inst.entity:SetPristine()
        if not TheWorld.ismastersim then
            return inst
        end
        inst.persists=false
        return inst
    end
    local function fn()
        local inst = commonfn()
        if data.master_postinit then
            data.master_postinit(inst)
        end
        return inst
    end

    return Prefab(data.name,fn,assets)
end

local FX = {
    {
        name = "lunar_tallbird_eyefx",
        master_postinit = function (inst)
            inst.AnimState:SetBank("pigman")
            inst.AnimState:SetBuild("merm_actions_skills")
            inst.AnimState:PlayAnimation("flame", true)
            inst.AnimState:SetFinalOffset(1)
            inst.AnimState:SetMultColour(1, 1, 1, 0.3)
            inst.Transform:SetNoFaced()

            inst:AddTag("DECOR")

        end
    },
    {
        name = "shadow_tallbird_eyefx",
        master_postinit = function (inst)
            inst.AnimState:SetBank("pigman")
            inst.AnimState:SetBuild("merm_actions_skills")
            inst.AnimState:PlayAnimation("alternateeyes", true)
            inst.AnimState:SetFinalOffset(1)
            inst.Transform:SetNoFaced()

            inst:AddTag("DECOR")
        end
    },
    {
        name = "lunar_tallbird_fx",
        master_postinit = function (inst)
            inst.AnimState:SetBank("brightmare_gestalt_head_evolved")
            inst.AnimState:SetBuild("brightmare_gestalt_head_evolved")
            inst.AnimState:PlayAnimation("idle", true)
            inst.AnimState:SetFinalOffset(-1)
            inst.AnimState:SetMultColour(1, 1, 1, 0.1)

            inst:AddTag("DECOR")

        end
    },
    {
        name = "lunar_tallbird_light_fx",
        master_postinit = function (inst)
            inst.entity:AddLight()
            inst.Light:SetFalloff(0.9)
            inst.Light:SetIntensity(.6)
            inst.Light:SetRadius(2)
            inst.Light:SetColour(255/255, 255/255, 255/255)
        end
    },
    {
        name = "egg_box_dynamic_fx",
        master_postinit = function (inst)
        end
    }
}

local ret = {}
for i, v in ipairs(FX) do
    table.insert(ret, MakeFx(v))
end

return unpack(ret)