local assets =
{
    Asset("ANIM", "anim/tallbird_egg.zip"),
    Asset("IMAGE","images/inventoryimages/new_tallbirdnest.tex"),
	Asset("ATLAS", "images/inventoryimages/new_tallbirdnest.xml"),
}

local assets_item =
{
    Asset("ANIM", "anim/tallbird_egg.zip"),
}

local prefabs =
{
    "smallbird",
    "tallbird",
    "tallbirdegg",
    "new_tallbirdnest_item",
}

local prefabs_item =
{
    "new_tallbirdnest",
}

local TALLBIRD_LAY_DIST = 16

local function StopNesting(inst)
    if inst.nesttask then
        inst.nesttask:Cancel()
        inst.nesttask = nil
    end
    inst.nesttime = nil
end

local function ForceLay(inst)
    if inst.components.childspawner and inst.components.pickable then
        for k,v in pairs(inst.components.childspawner.childrenoutside) do
            if distsq(Vector3(v.Transform:GetWorldPosition()), Vector3(inst.Transform:GetWorldPosition()) ) < TALLBIRD_LAY_DIST*TALLBIRD_LAY_DIST then
                inst.components.pickable:Regen()
                break
            end
        end
    end
end

local function DoNesting(inst)
    StopNesting(inst)
    if inst.components.pickable and not inst.components.pickable:CanBePicked() then
        inst.readytolay = true
        if inst:IsAsleep() then
            ForceLay(inst)
        end
    end
end

local function StartNesting(inst, time)
    StopNesting(inst)
    time = time or (TUNING.TALLBIRD_LAY_EGG_TIME_MIN + math.random() * TUNING.TALLBIRD_LAY_EGG_TIME_VAR )
    inst.nesttime = GetTime() + time
    inst.nesttask = inst:DoTaskInTime(time, DoNesting)
end

local function onpicked(inst, picker,loot)
    inst.thief = picker
    if inst.AnimState:IsCurrentAnimation("eggnest_signed1") then
        inst.AnimState:PlayAnimation("nest_signed1")
    elseif inst.AnimState:IsCurrentAnimation("eggnest") then
        inst.AnimState:PlayAnimation("nest")
    end
    if inst.components.childspawner then
        inst.components.childspawner.noregen = true
    end
    if inst.components.childspawner and picker then
        for k,v in pairs(inst.components.childspawner.childrenoutside) do
            if v.components.combat and not (picker:HasTag("bird_friend") or picker:HasTag("bird_family")) then
                v.components.combat:SuggestTarget(picker)
            end
        end
    end
    inst:DoTaskInTime(0, StartNesting)
end

local function onmakeempty(inst)
    if inst.AnimState:IsCurrentAnimation("eggnest_signed1") then
        inst.AnimState:PlayAnimation("nest_signed1")
    elseif inst.AnimState:IsCurrentAnimation("eggnest") then
        inst.AnimState:PlayAnimation("nest")
    end
    if inst.components.childspawner then
        inst.components.childspawner.noregen = true
    end
end

local function onregrow(inst)
    if inst.AnimState:IsCurrentAnimation("nest_signed1") then
        inst.AnimState:PlayAnimation("eggnest_signed1")
    elseif inst.AnimState:IsCurrentAnimation("nest") then
        inst.AnimState:PlayAnimation("eggnest")
    end
    if inst.components.childspawner then
        inst.components.childspawner.noregen = false
    end
    StopNesting(inst)
    inst.thief = nil
    inst.readytolay = nil
end

local function onvacate(inst)
    if inst.components.pickable then
        inst.components.pickable:MakeEmpty()
        StartNesting(inst)
    end
end

local function onsleep(inst)
    if inst.components.pickable and not inst.components.pickable:CanBePicked() and inst.readytolay then
        ForceLay(inst)
    end
end

local function OnSave(inst, data)
    data.readytolay = inst.readytolay
    --data.canspawn = inst.canspawnsmallbird
    data.havespawned = inst.spawnedsmallbirdthisseason
    if inst.nesttime and inst.nesttime > GetTime() then
        data.timetonest = inst.nesttime - GetTime()
    end
end

local function OnLoad(inst, data)
    if data then
        inst.readytolay = data.readytolay
        if data.timetonest or not inst.readytolay then
            StartNesting(inst, data.timetonest)
        end
        --inst.canspawnsmallbird = data.canspawn or true
        inst.spawnedsmallbirdthisseason = data.havespawned or false
    end
end

local function SpawnSmallBird(inst)
    local tallbird = nil
    for k,v in pairs(inst.components.childspawner.childrenoutside) do
        if v.prefab == "tallbird" then tallbird = v break end
    end
    --print("spawning smallbird for tallbird", tallbird)
    if tallbird and tallbird:IsValid() then
        --inst.canspawnsmallbird = false
        inst.spawnedsmallbirdthisseason = true
        if tallbird.entitysleeping then
            local smallbird = SpawnPrefab("smallbird")
            smallbird:PushEvent("SetUpSpringSmallBird", {smallbird=smallbird, tallbird=tallbird})
        else
            tallbird.pending_spawn_smallbird = true
        end
    end
end

local function SeasonalSpawnChanges(inst)
    if TheWorld.state.isspring then
        if (inst.spawnedsmallbirdthisseason == nil or inst.spawnedsmallbirdthisseason == false) then
            inst:DoTaskInTime(math.random(TUNING.MIN_SPRING_SMALL_BIRD_SPAWN_TIME, TUNING.MAX_SPRING_SMALL_BIRD_SPAWN_TIME), SpawnSmallBird)
        end
    else
        inst.spawnedsmallbirdthisseason = false
    end
end

local function ondeploy(inst, pt)--, deployer)
    local ent = SpawnPrefab("new_tallbirdnest", inst.linked_skinname, inst.skin_id )
    inst:Remove()
    ent.Transform:SetPosition(pt:Get())
    ent.SoundEmitter:PlaySound("dontstarve/wilson/pickup_reeds")
end

local function dig_up(inst,worker)
    if inst.components.childspawner and worker then
        for k,v in pairs(inst.components.childspawner.childrenoutside) do
            if v.components.combat and not (worker:HasTag("bird_friend") or worker:HasTag("bird_family")) then
                v.components.combat:SuggestTarget(worker)
            end
        end
    end
    if inst.components.pickable and inst.components.pickable:CanBePicked() then
        inst.components.lootdropper:SpawnLootPrefab("tallbirdegg")
    end
    inst.components.lootdropper:SpawnLootPrefab("new_tallbirdnest_item", nil, inst.linked_skinname, inst.skin_id )
    inst:Remove()
end

local function IsLowPriorityAction(act, force_inspect)
    return act == nil
        or act.action == ACTIONS.WALKTO
        or (act.action == ACTIONS.LOOKAT and not force_inspect)
end

--Runs on clients
local function CanMouseThrough(inst)
    if not inst:HasTag("fire") and ThePlayer ~= nil and ThePlayer.components.playeractionpicker ~= nil then
        local force_inspect = ThePlayer.components.playercontroller ~= nil and ThePlayer.components.playercontroller:IsControlPressed(CONTROL_FORCE_INSPECT)
        local lmb, rmb = ThePlayer.components.playeractionpicker:DoGetMouseActions(inst:GetPosition(), inst)
        return IsLowPriorityAction(rmb, force_inspect)
            and IsLowPriorityAction(lmb, force_inspect)
    end
end

local function FindChild(inst)
    local spawner = inst.components.childspawner
    if spawner:NumChildren() > 0 then
        if inst.findchild then
            inst.findchild:Cancel()
            inst.findchild = nil
        end
        return
    end
    local x, y, z = inst.Transform:GetWorldPosition()
    local tallbirds = TheSim:FindEntities(x, y or 0, z, 10, {"tallbird"})
    for _, bird in ipairs(tallbirds) do
        if not bird.components.homeseeker or bird.components.homeseeker:GetHome() == nil then
            spawner:TakeOwnership(bird)
            spawner:StopSpawning()
            spawner:SetMaxChildren(1)
            if inst.findchild then
                inst.findchild:Cancel()
                inst.findchild = nil
            end
            break
        end
    end
end

local function OnChildKilled(inst,child)
    local spawner = inst.components.childspawner
    if spawner and not inst:HasTag("nest_spawner") then
        if inst.findchild then
            inst.findchild:Cancel()
            inst.findchild = nil
        end
        inst.findchild = inst:DoPeriodicTask(3,function()
            FindChild(inst)
        end)
        spawner:StopSpawning()
        spawner:SetMaxChildren(0)

    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.MiniMapEntity:SetIcon("tallbirdnest.png")

    inst.AnimState:SetBank("egg")
    inst.AnimState:SetBuild("tallbird_egg")
    inst.AnimState:PlayAnimation("nest_signed1")
    inst.AnimState:SetFinalOffset(-1)

	inst:SetDeploySmartRadius(1) --item has special NONE spacing

    inst.CanMouseThrough = CanMouseThrough

    inst:AddTag("antlion_sinkhole_blocker")
    inst:AddTag("structure")
    inst:AddTag("new_tallbirdnest")

    inst.entity:SetPristine()

    inst.scrapbook_anim = "nest_signed1"

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("lootdropper")

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetOnFinishCallback(dig_up)
    inst.components.workable:SetWorkLeft(1)

    inst:AddComponent("pickable")
    inst.components.pickable:SetUp("tallbirdegg", nil)
    inst.components.pickable.onpickedfn = onpicked
    inst.components.pickable.onregenfn = onregrow
    inst.components.pickable.makefullfn = onregrow
    inst.components.pickable.makeemptyfn = onmakeempty
    inst.components.pickable:MakeEmpty()

    MakeMediumBurnable(inst)
    MakeSmallPropagator(inst)

    inst:AddComponent("childspawner")
    inst.components.childspawner.childname = "tallbird"
    inst.components.childspawner.spawnoffscreen = true
    inst.components.childspawner:SetRegenPeriod(4*16*TUNING.SEG_TIME)
    inst.components.childspawner:SetSpawnPeriod(4*16*TUNING.SEG_TIME)
    inst.components.childspawner:SetSpawnedFn(onvacate)
    inst.components.childspawner:SetMaxChildren(0)
    inst.components.childspawner:SetOnChildKilledFn(OnChildKilled)

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    inst:AddComponent("tallbird_spawner")

    inst:ListenForEvent("entitysleep", onsleep)
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    if TUNING.TALLBIRD_BREED==1 then
        SeasonalSpawnChanges(inst)
        inst:WatchWorldState("isspring", SeasonalSpawnChanges)
    end

	inst.StartNesting = StartNesting

    inst.findchild = inst:DoPeriodicTask(3,function()
        FindChild(inst)
    end)

    inst:ListenForEvent("spawner_start",function ()
        if inst.findchild then
            inst.findchild:Cancel()
            inst.findchild = nil
        end
        local spawner = inst.components.childspawner
        if spawner then
            spawner:SetMaxChildren(1)
            spawner.childreninside = 0
            spawner:StartSpawning()
        end
        if inst.AnimState:IsCurrentAnimation("nest_signed1") then
            inst.AnimState:PlayAnimation("nest")
        elseif inst.AnimState:IsCurrentAnimation("eggnest_signed1") then
            inst.AnimState:PlayAnimation("eggnest")
        end
    end)

    inst:ListenForEvent("spawner_stop",function ()
        if inst.findchild then
            inst.findchild:Cancel()
            inst.findchild = nil
        end
        local spawner = inst.components.childspawner
        if spawner then
            spawner:StopSpawning()
            if spawner:NumChildren() == 0 then
                spawner:SetMaxChildren(0)
            end
        end
        inst.findchild = inst:DoPeriodicTask(3,function()
            FindChild(inst)
        end)
        if inst.AnimState:IsCurrentAnimation("nest") then
            inst.AnimState:PlayAnimation("nest_signed1")
        elseif inst.AnimState:IsCurrentAnimation("eggnest") then
            inst.AnimState:PlayAnimation("eggnest_signed1")
        end
    end)

    return inst
end

local function MakeItem(name)
    local function item_fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank("egg")
        inst.AnimState:SetBuild("tallbird_egg")
        inst.AnimState:PlayAnimation("nest_item")


        MakeInventoryFloatable(inst)

        inst.scrapbook_anim = "nest_item"

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end


        inst:AddComponent("inspectable")
        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.imagename = "new_tallbirdnest"
        inst.components.inventoryitem.atlasname = "images/inventoryimages/new_tallbirdnest.xml"

        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM

        inst:AddComponent("deployable")
        inst.components.deployable.ondeploy = ondeploy
        inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.LESS)

        MakeSmallBurnable(inst)
        MakeSmallPropagator(inst)

        inst:AddComponent("fuel")
        inst.components.fuel.fuelvalue = TUNING.MED_FUEL

        MakeHauntableLaunchAndIgnite(inst)

        return inst
    end

    return Prefab(name, item_fn, assets_item, prefabs_item)
end

return Prefab("new_tallbirdnest", fn, assets, prefabs),
    MakeItem("new_tallbirdnest_item"),
    MakePlacer("new_tallbirdnest_item_placer", "egg", "tallbird_egg", "nest_signed1")
