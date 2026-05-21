local modid = 'lovely_tallbird_family'

local smallbird_health=TUNING.SMALLBIRD_HEALTH*GetModConfigData(modid..'_smallbirdhealth')
local smallbird_damage=TUNING.SMALLBIRD_DAMAGE*GetModConfigData(modid..'_smallbirddamage')
local smallbird_hunger_speed = GetModConfigData(modid..'_smallbirdhunger_speed')
local teenbird_hunger_speed = GetModConfigData(modid..'_teenbirdhunger_speed')
local teenbird_health=TUNING.TEENBIRD_HEALTH*GetModConfigData(modid..'_teenbirdhealth')
local tallbird_health=TUNING.TALLBIRD_HEALTH*GetModConfigData(modid..'_tallbirdhealth')

local function is_bird_follower(inst)
    GLOBAL.assert(inst ~= nil);
    return inst:HasAnyTag(TUNING.LOVELY_BIRD.TAG)
end
---玩家
AddPlayerPostInit(function(inst)
if GetModConfigData(modid..'_birdfollow') then
local old_on_despawn = inst.OnDespawn
inst.all_followers = {}
inst.OnDespawn = function(inst, migrationdata, ...)
    for follower, _ in pairs(inst.components.leader.followers) do
        if is_bird_follower(follower) then
            local savedata = follower:GetSaveRecord()
            table.insert(inst.all_followers, savedata)
            follower:AddTag("notarget")
            follower:AddTag("NOCLICK")
            follower.persists = false
            if follower.components.health then
                follower.components.health:SetInvincible(true)
            end
            follower:DoTaskInTime(math.random() * 0.2, function(follower)
            local fx = GLOBAL.SpawnPrefab("spawn_fx_small")
                fx.Transform:SetPosition(follower.Transform:GetWorldPosition())
                if not follower.components.colourtweener then
                    follower:AddComponent("colourtweener")
                end
                follower.components.colourtweener:StartTween(
                    {0, 0, 0, 1}, 
                    13 * GLOBAL.FRAMES, 
                    follower.Remove)
            end)
        end
    end
return old_on_despawn(inst, migrationdata, ...)
end
local old_on_save = inst.OnSave
inst.OnSave = function(inst, data, ...)
    data.all_followers = inst.all_followers
    if old_on_save ~= nil then
        return old_on_save(inst, data, ...)
    end
end

local old_on_load = inst.OnLoad
inst.OnLoad = function(inst, data, ...)
    if data and data.all_followers then
        for _, savedata in pairs(data.all_followers) do
            inst:DoTaskInTime(0.2 * math.random(), function(inst)
            local bird = GLOBAL.SpawnSaveRecord(savedata)
                inst.components.leader:AddFollower(bird)
                bird:DoTaskInTime(0, function(bird)
                    if inst:IsValid() and not bird:IsNear(inst, 8) then
                        bird.Transform:SetPosition(inst.Transform:GetWorldPosition())
                        bird.sg:GoToState("idle")
                    end
                end)
            local fx = GLOBAL.SpawnPrefab("spawn_fx_small")
                fx.Transform:SetPosition(bird.Transform:GetWorldPosition())
            end)
        end
    end
if old_on_load ~= nil then
    return old_on_load(inst, data, ...) 
end
end
end
inst._tallbird_mount_aoe_leg = true
inst:AddComponent("bird_family")

local old_doubleclickactionsfn
local function GetDoubleClickActions(inst, pos, dir, target)
	local rider = inst.replica.rider
	local mount = rider and rider:GetMount() or nil
    if old_doubleclickactionsfn~=nil and mount and mount:HasTag("woby") then
        return old_doubleclickactionsfn(inst, pos, dir, target)
    elseif inst:HasTag("shadow_tallbird_dash") then
        local pos2
		if dir then
			pos2 = inst:GetPosition()
			pos2.x = pos2.x + dir.x * 10
			pos2.y = 0
			pos2.z = pos2.z + dir.z * 10
		elseif target then
			pos2 = target:GetPosition()
			pos2.y = 0
		end
		return { ACTIONS.SHADOW_TALLBIRD_DASH }, pos2
    end
    return old_doubleclickactionsfn~=nil and old_doubleclickactionsfn(inst, pos, dir, target) or {}
end
local function OnSetOwner(inst)
	if inst.components.playeractionpicker then
        old_doubleclickactionsfn = inst.components.playeractionpicker.doubleclickactionsfn
		inst.components.playeractionpicker.doubleclickactionsfn = GetDoubleClickActions
	end
end
inst:ListenForEvent("setowner", OnSetOwner)
inst:ListenForEvent("temperaturedelta",function (inst,data)
    local is_summer = not TheWorld:HasTag("cave") and TheWorld.state.season=="summer"
    local is_winter = TheWorld.state.season=="winter"
    if data.new<5 and is_winter or data.new>65 and is_summer then
        if inst.components.timer then
            inst.components.timer:StartTimer("tallbird_temp_protect", 20)
        end
    end
end)
end)

local function OnTallbirdMount(rider, data)
    local mount = data.target
    if mount and mount.prefab == "tallbird" then
        local mountData = {
            health = mount.replica.health:GetCurrent(),
            maxHealth = mount.replica.health:Max(),
        }
        rider.player_classified.tallbirdData:set(GLOBAL.json.encode(mountData))
        rider.player_classified.tallbirdHealth:set_local(mountData.health)
        rider:ListenForEvent("healthdelta", rider.player_classified.OnTallbirdHealthDelta, mount)
    end
end

local function OnTallbirdDismount(rider, data)
    local mount = data.target
    if mount and mount.prefab == "tallbird" then
        rider.player_classified.tallbirdData:set("dismount")
        rider:RemoveEventCallback("healthdelta", rider.player_classified.OnTallbirdHealthDelta, mount)
    end
end

-- 在 player_classified 上注册网络变量
AddPrefabPostInit("player_classified", function(inst)
    inst.tallbirdData = GLOBAL.net_string(inst.GUID, "tallbirdData", "tallbirdDataDirty")
    inst.tallbirdHealth = GLOBAL.net_ushortint(inst.GUID, "tallbirdHealth", "tallbirdHealthDirty")
    inst.birdFameNumber = GLOBAL.net_ushortint(inst.GUID, "birdFameNumber", "birdFameNumberDirty")
    if GLOBAL.TheWorld.ismastersim then
        inst.OnTallbirdHealthDelta = function(mount, data)
            inst.tallbirdHealth:set(mount.replica.health:GetCurrent())
        end

        inst:DoTaskInTime(0.1, function()
            local parent = inst.entity:GetParent()
            inst:ListenForEvent("mounted", OnTallbirdMount, parent)
            inst:ListenForEvent("dismounted", OnTallbirdDismount, parent)
        end)
        inst:DoTaskInTime(0.1, function()
        local parent = inst.entity:GetParent()
        if parent and parent.components.bird_family then
            inst.birdFameNumber:set(parent.components.bird_family.number)
            parent:ListenForEvent("bird_fame_changed", function()
                inst.birdFameNumber:set(parent.components.bird_family.number)
            end)
        end
        end)
    end
end)

--鸟
local function CalcSanityAura(inst, observer)
    return (GetModConfigData(modid..'sanityaura') and inst.components.follower ~= nil and inst.components.follower.leader == observer and TUNING.SANITYAURA_SMALL) or 0
end
AddPrefabPostInit("smallbird", function(inst)
local function OnGetItemFromPlayer(inst, giver, item)
    --print("smallbird - OnGetItemFromPlayer")

    if inst.components.sleeper then
        inst.components.sleeper:WakeUp()
    end

    --I eat food
    if item.components.edible then
        if inst.components.combat.target and inst.components.combat.target == giver then
            inst.components.combat:SetTarget(nil)
        end
        if inst.components.eater:Eat(item, giver) then
            --print("   yummy!")
            -- yay!?
        end
        if inst.components.follower and inst.components.follower.leader==nil then
            giver:PushEvent("makefriend")
            inst.components.follower:SetLeader(giver)
        end
    end
     if item.components.equippable ~= nil and item.components.equippable.equipslot == EQUIPSLOTS.HEAD then
        local current = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
        if current ~= nil then
            inst.components.inventory:DropItem(current)
        end
        inst.components.inventory:Equip(item)
        inst.AnimState:Show("hat")
    end
end
    if inst.components.locomotor then
        inst.components.locomotor.runspeed = 6
        inst.components.locomotor.pathcaps = {
            ignorecreep = true,
            allowocean = true,
        }
        inst.components.locomotor:SetAllowPlatformHopping(true)
        inst:AddComponent("embarker")
        inst.components.embarker.embark_speed = 6

        inst:AddComponent("drownable")

        inst:AddComponent("amphibiouscreature")
        inst.components.amphibiouscreature:SetBanks("smallbird", "smallbird_water")
        inst.components.amphibiouscreature:SetEnterWaterFn(function(inst)
            inst.AnimState:SetBuild("smallbird_basic_water")
        end)
        inst.components.amphibiouscreature:SetExitWaterFn(function(inst)
            inst.AnimState:SetBuild("smallbird_basic")
        end)
    end

    inst:AddComponent("sanityaura")
    inst:AddComponent("bird_cultivate")
    inst.components.sanityaura.aurafn = CalcSanityAura
    if inst.components.eater then
        local old_eatfn = inst.components.eater.oneatfn
        inst.components.eater:SetOnEatFn(function (inst,food,feeder)
            if old_eatfn then
                old_eatfn(inst,food,feeder)
            end
            inst.sg:GoToState("eat")
        end)
        inst:AddComponent("named")
        inst:AddComponent("writeable")
        inst.components.writeable:SetDefaultWriteable(false)
        inst.components.writeable:SetAutomaticDescriptionEnabled(false)
        inst.components.writeable:SetWriteableDistance(TUNING.BEEFALO_NAMING_DIST)
        inst.components.writeable:SetOnWrittenFn(function(inst, new_name, writer)
            if inst.components.named ~= nil then
                inst.components.named:SetName(new_name, writer ~= nil and writer.userid or nil)
            end
        end)
        inst:AddComponent("timer")
    end
local function ShouldAcceptItem(inst, item)
    if item.components.equippable ~= nil and item.components.equippable.equipslot == EQUIPSLOTS.HEAD then
        return true
    elseif item.components.edible and inst.components.hunger and inst.components.eater and not item:HasTag("tallbirdegg") then
        return inst.components.eater:CanEat(item)
    end
end
    if inst.components.trader then
        inst.components.trader:SetAcceptTest(ShouldAcceptItem)
        inst.components.trader.onaccept = OnGetItemFromPlayer
        inst.components.trader.deleteitemonaccept = false
        inst:AddComponent("inventory")
    end

if GetModConfigData(modid..'_smallbirdprotect') then
    inst.components.bird_cultivate.nodeath = true
else
    inst.components.bird_cultivate.nodeath = false
end

if inst.components.hunger then
    inst.components.hunger:SetRate(smallbird_hunger_speed/TUNING.TEENBIRD_STARVE_TIME)
end
if GetModConfigData(modid..'_smallbirdgifts') then
    inst.components.bird_cultivate.gift = true
else
    inst.components.bird_cultivate.gift = false
end
local bird_health
if inst.components.health then
    bird_health=inst.components.health.currenthealth/inst.components.health.maxhealth
    inst.components.health:SetMaxHealth(smallbird_health)
    inst.components.health:SetCurrentHealth(bird_health*smallbird_health)
end
if inst.components.combat then
    inst.components.combat:SetDefaultDamage(smallbird_damage)
    inst.components.combat:SetNoAggroTags({"bird_family", "smallbird","teenbird","tallbird"})
end
if inst.components.follower then
    inst.components.follower.keepdeadleader = true
    inst.components.follower:KeepLeaderOnAttacked()
end
if inst.userfunctions then
    -- local old_teenfn = inst.userfunctions.SpawnTeen
    inst.userfunctions.SpawnTeen = function (inst)
        local current = inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
        if current ~= nil then
            inst.components.inventory:DropItem(current)
        end
        local teenbird = SpawnPrefab("teenbird")
        teenbird.Transform:SetPosition(inst.Transform:GetWorldPosition())
        teenbird.sg:GoToState("idle")
        local name = inst.name~="小鸟" and inst.name~="Smallbird" and inst.name or nil
        if inst.components.follower:GetLeader() then
            teenbird.components.follower:SetLeader(inst.components.follower:GetLeader())
            local leader = inst.components.follower:GetLeader()
            if name and teenbird.components.named then
                teenbird.components.named:SetName(name,leader.name)
            end
        end
        local build_name = inst.AnimState:GetSkinBuild()
        if build_name=="smallbirdskin_manrabbit" then
            teenbird.AnimState:SetSkin("tallbird_teenskin_manrabbit")
        end
        inst:Remove()
    end
end

inst:ListenForEvent("leaderchanged", function(inst, data)
if inst.components.follower then
    local leader = inst.components.follower.leader
    if leader then
        local nowild = leader.components.bird_cultivate and leader.components.bird_cultivate.wild == false
        if inst.components.bird_cultivate then
            if leader:HasTag("player") or nowild then
                inst.components.bird_cultivate.wild = false
            end
            inst.components.bird_cultivate:Updata()
        end
    end
end
end)

end)

AddPrefabPostInit("teenbird", function(inst)
local function OnGetItemFromPlayer(inst, giver, item)
    --print("smallbird - OnGetItemFromPlayer")

    if inst.components.sleeper then
        inst.components.sleeper:WakeUp()
    end

    --I eat food
    if item.components.edible then
        if inst.components.combat.target and inst.components.combat.target == giver then
            inst.components.combat:SetTarget(nil)
        end
        if inst.components.eater:Eat(item, giver) then
            --print("   yummy!")
            -- yay!?
        end
        if inst.components.follower and inst.components.follower.leader==nil then
            giver:PushEvent("makefriend")
            inst.components.follower:SetLeader(giver)
        end
    end
     if item.components.equippable ~= nil and item.components.equippable.equipslot == EQUIPSLOTS.HEAD then
        local current = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
        if current ~= nil then
            inst.components.inventory:DropItem(current)
        end
        inst.components.inventory:Equip(item)
        inst.AnimState:Show("hat")
    end
end
    if inst.AnimState then
        inst.AnimState:Hide("beakfull")
        inst.AnimState:Hide("tallbird_beakfull")
    end
    if inst.components.locomotor then
        inst.components.locomotor.walkspeed = 8
        inst.components.locomotor.runspeed = 8
        inst.components.locomotor:SetAllowPlatformHopping(true)
    end
    inst:AddComponent("embarker")
    inst:AddComponent("bird_cultivate")
    inst:AddComponent("drownable")
    inst.components.drownable.enabled = true
    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aurafn = CalcSanityAura
    if inst.components.eater then
        local old_eatfn = inst.components.eater.oneatfn
        inst.components.eater:SetOnEatFn(function (inst,food,feeder)
            if old_eatfn then
                old_eatfn(inst,food,feeder)
            end
            inst.sg:GoToState("eat")
        end)
        inst:AddComponent("named")
        inst:AddComponent("writeable")
        inst.components.writeable:SetDefaultWriteable(false)
        inst.components.writeable:SetAutomaticDescriptionEnabled(false)
        inst.components.writeable:SetWriteableDistance(TUNING.BEEFALO_NAMING_DIST)
        inst.components.writeable:SetOnWrittenFn(function(inst, new_name, writer)
            if inst.components.named ~= nil then
                inst.components.named:SetName(new_name, writer ~= nil and writer.userid or nil)
            end
        end)
        inst:AddComponent("timer")
        if inst.components.timer and not inst.components.timer:TimerExists("emote_cd") then
            inst.components.timer:StartTimer("emote_cd", 3+10*math.random())
        end
    end
local function ShouldAcceptItem(inst, item)
    if item.components.equippable ~= nil and item.components.equippable.equipslot == EQUIPSLOTS.HEAD then
        return true
    elseif item.components.edible and inst.components.hunger and inst.components.eater and not item:HasTag("tallbirdegg") then
        return inst.components.eater:CanEat(item)
    end
end
    if inst.components.trader then
        inst.components.trader:SetAcceptTest(ShouldAcceptItem)
        inst.components.trader.onaccept = OnGetItemFromPlayer
        inst.components.trader.deleteitemonaccept = false
        inst:AddComponent("inventory")
    end

local function SpawnAdult(inst)
    local current = inst.components.inventory and inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
        if current ~= nil then
            inst.components.inventory:DropItem(current)
        end
    local tallbird = SpawnPrefab("tallbird")
    tallbird.Transform:SetPosition(inst.Transform:GetWorldPosition())
    tallbird.sg:GoToState("idle")
  
    if inst.components.follower and inst.components.follower.leader then
        local leader = inst.components.follower.leader
        local name = inst.name~="小高脚鸟" and inst.name~="Smallish Tallbird" and inst.name or nil
        tallbird.components.follower:SetLeader(leader)
        if name and tallbird.components.named then
            tallbird.components.named:SetName(name,leader.name)
        end
        if leader.components.bird_family then
            leader.components.bird_family.number = leader.components.bird_family.number+1
            leader.components.bird_family:Updata()
        end
    end
    local build_name = inst.AnimState:GetSkinBuild()
    if build_name=="tallbird_teenskin_manrabbit" then
        tallbird.AnimState:SetSkin("tallbirdskin_manrabbit")
    end
    inst:Remove()
end
if inst.userfunctions then
    inst.userfunctions.SpawnAdult=SpawnAdult
end

if GetModConfigData(modid..'_teenbirdprotect') then
    inst.components.bird_cultivate.nodeath = true
else
    inst.components.bird_cultivate.nodeath = false
end

if GetModConfigData(modid..'_teenbirdwaterwalk') then
        inst.Physics:SetCollisionMask(
		COLLISION.GROUND,
		COLLISION.OBSTACLES,
		COLLISION.CHARACTERS)
        inst.Physics:Teleport(inst.Transform:GetWorldPosition())
        if inst.components.drownable then
            inst.components.drownable.enabled = false
        end
end
if inst.components.hunger then
    inst.components.hunger:SetRate(teenbird_hunger_speed/TUNING.TEENBIRD_STARVE_TIME)
end
if GetModConfigData(modid..'_teenbirdgifts') then
    inst.components.bird_cultivate.gift = true
else
    inst.components.bird_cultivate.gift = false
end

local bird_health
if inst.components.health then
    bird_health=inst.components.health.currenthealth/inst.components.health.maxhealth
    inst.components.health:SetMaxHealth(teenbird_health)
    inst.components.health:SetCurrentHealth(bird_health*teenbird_health)
end
if inst.components.combat then
    inst.components.combat:SetNoAggroTags({"bird_family", "smallbird","teenbird","tallbird"})
end
if inst.components.follower then
    inst.components.follower.keepdeadleader = true
    inst.components.follower:KeepLeaderOnAttacked()
end
inst:ListenForEvent("leaderchanged", function(inst, data)
if inst.components.follower then
    local leader = inst.components.follower.leader
    if leader then
        local nowild = leader.components.bird_cultivate and leader.components.bird_cultivate.wild == false
        if inst.components.bird_cultivate then
            if leader:HasTag("player") or nowild then
                inst.components.bird_cultivate.wild = false
            end
            inst.components.bird_cultivate:Updata()
        end
    end
end
end)

end)

AddPrefabPostInit("tallbird", function(inst)
    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aurafn = CalcSanityAura

if GetModConfigData(modid..'_tallbirdprotect') then
    if inst.components.bird_cultivate then
        inst.components.bird_cultivate.nodeath = true
    end
else
    if inst.components.bird_cultivate then
        inst.components.bird_cultivate.nodeath = false
    end
end

if GetModConfigData(modid..'_tallbirdwaterwalk') then
    inst.Physics:SetCollisionMask(
		COLLISION.GROUND,
		COLLISION.OBSTACLES,
		COLLISION.CHARACTERS)
    inst.Physics:Teleport(inst.Transform:GetWorldPosition())
    if inst.components.drownable then
        inst.components.drownable.enabled = false
    end
end
local bird_health
if inst.components.health then
    bird_health=inst.components.health.currenthealth/inst.components.health.maxhealth
    inst.components.health:SetMaxHealth(tallbird_health)
    inst.components.health:SetCurrentHealth(bird_health*tallbird_health)
end
if GetModConfigData(modid..'_tallbirdgifts') then
    if inst.components.bird_cultivate then
        inst.components.bird_cultivate.gift = true
    end
else
    if inst.components.bird_cultivate then
        inst.components.bird_cultivate.gift = false
    end
end
end)

---物品
AddPrefabPostInit("featherhat", function(inst)
    local old_onequip
    if inst.components.equippable then
        old_onequip = inst.components.equippable.onequipfn
        inst.components.equippable:SetOnEquip(function(inst, owner, from_ground)
            if old_onequip then
                old_onequip(inst, owner, from_ground)
            end
            if owner:HasTag("tallbird") and inst.components.fueled then
                inst.components.fueled:StopConsuming()
            end
        end)
    end
end)

AddPrefabPostInit("alterguardianhat", function(inst)
    local old_onequip, old_onunequip
    if inst.components.equippable then
        old_onequip = inst.components.equippable.onequipfn
        old_onunequip = inst.components.equippable.onunequipfn
        inst.components.equippable:SetOnEquip(function(inst, owner, from_ground)
            if old_onequip then
                old_onequip(inst, owner, from_ground)
            end
            if owner:HasTag("tallbird") or owner:HasTag("smallbird") then
               if not inst._is_active then
                    owner.AnimState:ClearOverrideSymbol("swap_hat")
                    owner.AnimState:Hide("HAT")
                    owner.AnimState:Hide("HAIR_HAT")
                    owner.AnimState:Show("HAIR_NOHAT")
                    owner.AnimState:Show("HAIR")
                  
                    if inst._light == nil then
                        inst._light = SpawnPrefab("alterguardianhatlight")
                        inst._light.entity:SetParent(owner.entity)
                    end

                   local layer = owner.prefab == "smallbird" and "head" or "tallbird_head"
                   local y = owner.prefab == "smallbird" and 0 or -50
                   local scale = owner.prefab == "smallbird" and 1 
                   or owner.prefab == "teenbird" and 1.3 or 1.5
                    if inst._front == nil then
                        inst._front = SpawnPrefab("alterguardian_hat_equipped")
                        inst._front.entity:SetParent(owner.entity)
                        inst._front.entity:AddFollower()
                        
                        inst._front.Follower:FollowSymbol(owner.GUID, layer, 0, y, 0)
                        inst._front.Transform:SetScale(scale, scale, scale)
                        inst._front.AnimState:Hide("back")
                        inst._front.AnimState:SetFinalOffset(1)
                        inst._front.AnimState:PlayAnimation("activate_pre")
                        inst._front.AnimState:PushAnimation("activate_loop", true)
                    end

                   
                    if inst._back == nil then
                        inst._back = SpawnPrefab("alterguardian_hat_equipped")
                        inst._back.entity:SetParent(owner.entity)
                        inst._back.entity:AddFollower()
                        inst._back.Follower:FollowSymbol(owner.GUID, layer, 0, y, 0)
                        inst._back.Transform:SetScale(scale, scale, scale)
                        inst._back.AnimState:Hide("front")
                        inst._back.AnimState:SetFinalOffset(-1)
                        inst._back.AnimState:PlayAnimation("activate_pre")
                        inst._back.AnimState:PushAnimation("activate_loop", true)
                    end

                    
                    local skin_build = inst:GetSkinBuild()
                    if skin_build then
                        inst._front:SetSkin(skin_build, inst.GUID)
                        inst._back:SetSkin(skin_build, inst.GUID)
                    end

                    inst:PushEvent("itemget", {})
                end
                inst._is_active = true
            end
        end)
        inst.components.equippable:SetOnUnequip(function(inst, owner)
            if old_onunequip then
                old_onunequip(inst, owner)
            end
            if owner:HasTag("tallbird") or owner:HasTag("smallbird") then
                if inst._is_active then
                    inst._is_active = false
                end
            end
        end)
    end
end)

AddPrefabPostInit("purebrilliance", function(inst)
    inst:AddTag("bird_planaritem")
    inst:AddComponent("bird_planaritem")
end)

AddPrefabPostInit("horrorfuel", function(inst)
    inst:AddTag("bird_planaritem")
    inst:AddComponent("bird_planaritem")
end)

AddPrefabPostInit("cutgrass", function(inst)
    inst:AddTag("bird_leave")
    inst:AddComponent("bird_leave")
end)