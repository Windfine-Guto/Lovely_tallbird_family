GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})

Assets = {
	Asset("ANIM", "anim/spell_icons_tallbird.zip"),
    Asset("ANIM", "anim/status_meter_tallbird.zip"),
}

PrefabFiles = {
    "tallbird",
    "tallbird_saddle"
}

local modid = 'lovely_tallbird_family'


local config_name10 = modid..'_egghatch'
local config_name = modid..'_smallbirdhealth'
local config_name2 = modid..'_smallbirddamage'
local config_name3 = modid..'_smallbirdgrow'
local config_name4 = modid..'_smallbirdprotect'
local config_name5 = modid..'_smallbirdgifts'
local config_name11 = modid..'_smallbirdwaterwalk'
local config_name14 = modid..'_smallbirdhunger'
local smallbird_health=TUNING.SMALLBIRD_HEALTH*GetModConfigData(config_name)
local smallbird_damage=TUNING.SMALLBIRD_DAMAGE*GetModConfigData(config_name2)
local config_name6 = modid..'_teenbirdhealth'
local config_name7 = modid..'_teenbirddamage'
local config_name8 = modid..'_teenbirdprotect'
local config_name9 = modid..'_teenbirdgifts'
local config_name12 = modid..'_teenbirdwaterwalk'
local config_name13 = modid..'_birdfollow'
local config_name15 =modid..'_teenbirdhunger'
-- local config_name16 =modid..'_teenbirdgrow'
local config_name17 =modid..'_tallbirdhealth'
local config_name18 =modid..'_tallbirddamage'
local config_name19 =modid..'_tallbirdprotect'
local config_name20 =modid..'_tallbirdgifts'
local config_name21=modid..'_tallbirdwaterwalk'
local config_name22 =modid..'sanityaura'
local config_name23 =modid..'_smallbirdgrowtime'
local config_name24 =modid..'_teenbirdgrowtime'
local config_name25 =modid..'_smallbirdhunger_speed'
local config_name26 =modid..'_teenbirdhunger_speed'

local smallbird_hunger_speed = GetModConfigData(config_name25)
local teenbird_hunger_speed = GetModConfigData(config_name26)
local teenbird_health=TUNING.TEENBIRD_HEALTH*GetModConfigData(config_name6)
local tallbird_health=TUNING.TALLBIRD_HEALTH*GetModConfigData(config_name17)

TUNING.TEENBIRD_DAMAGE=37.5*GetModConfigData(config_name7)
TUNING.TALLBIRD_DAMAGE=50*GetModConfigData(config_name18)
TUNING.SMALLBIRD_HATCH_TIME=TUNING.SMALLBIRD_HATCH_TIME*GetModConfigData(config_name10)
TUNING.SMALLBIRD_HUNGER=TUNING.SMALLBIRD_HUNGER*GetModConfigData(config_name14)
TUNING.TEENBIRD_HUNGER=TUNING.TEENBIRD_HUNGER*GetModConfigData(config_name15)
TUNING.SMALLBIRD_GROW_TIME=TUNING.SMALLBIRD_GROW_TIME/GetModConfigData(config_name23)
TUNING.TEENBIRD_GROW_TIME=TUNING.TEENBIRD_GROW_TIME/GetModConfigData(config_name24)

local locale = GLOBAL.LOC.GetLocaleCode()
if locale == "zh" or locale == "zht" or locale=="zhr" then
    modimport("string_zh")
else
    modimport("string_en")
end

AddRecipe2("tallbird_saddle",{Ingredient("rope", 3),Ingredient("beardhair", 10),Ingredient("driftwood_log", 3)},
TECH.SCIENCE_TWO,
{atlas = "images/inventoryimages/tallbird_saddle.xml",
image = "tallbird_saddle.tex"},
{"RIDING"})

local originalGetString = GetString

_G.GetString = function(inst, stringtype, modifier, ...)
    if stringtype == "ANNOUNCE_MOUNT_LOWHEALTH"
    and inst and inst:HasTag("tallbird_mount") then
        return originalGetString(inst, "ANNOUNCE_TALLBIRD_MOUNT_LOWHEALTH", modifier, ...)
    end
    return originalGetString(inst, stringtype, modifier, ...)
end

local NativePlayAnimation = AnimState.PlayAnimation
local NativePushAnimation = AnimState.PushAnimation

local AnimStateToEntity = setmetatable({}, {__mode = "k"})

local OldAddAnimState = Entity.AddAnimState
function Entity:AddAnimState(...)
    local animstate = OldAddAnimState(self, ...)
    if animstate then
        local entity = Ents[self:GetGUID()]
        if entity then
            AnimStateToEntity[animstate] = entity
            entity:ListenForEvent("onremove", function()
                AnimStateToEntity[animstate] = nil
            end)
        end
    end
    return animstate
end

local function GetEntityFromAnimState(animstate)
    return AnimStateToEntity[animstate]
end

local function ReplaceAttackAnim(inst, anim)
    if inst and inst:HasTag("tallbird_mount") and inst._tallbird_mount_aoe_leg == true then
        if anim == "atk_pre" then
            return "atkleg_pre"
        elseif anim == "atk" then
            return "atkleg"
        end
    end
    return anim
end

function AnimState:PlayAnimation(anim, loop)
    local inst = GetEntityFromAnimState(self)
    local new_anim = ReplaceAttackAnim(inst, anim)
    return NativePlayAnimation(self, new_anim, loop)
end

function AnimState:PushAnimation(anim, loop)
    local inst = GetEntityFromAnimState(self)
    local new_anim = ReplaceAttackAnim(inst, anim)
    return NativePushAnimation(self, new_anim, loop)
end

TUNING.LOVELY_BIRD = {
    TAG = { "lovely_bird","smallbird","teenbird","tallbird" }
}
local function is_bird_follower(inst)
    GLOBAL.assert(inst ~= nil);
    return inst:HasAnyTag(TUNING.LOVELY_BIRD.TAG)
end

AddPlayerPostInit(function(inst)
if GetModConfigData(config_name13) then
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
end)

local NOTAGS = {'INLIMBO','notarget','noattack','player','companion','abigail','glommer','friendlyfruitfly'}
local function playerdamage(inst,data)
	local target=data.target
	if not target:IsValid() or not target.components or not target.components.combat then
        return
    end
	if inst.target_spdamage_processed==true then
		return
	end
    inst.target_spdamage_processed=true
    if inst._tallbird_mount_aoe_leg==true then
        if inst.components.combat then
            inst.components.combat:DoAreaAttack(target, 4, nil, nil,
nil, NOTAGS)
        end
    else
        if inst.components.inventory ~= nil then
            local weapon = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if inst.components.combat then
                if weapon==nil then
                    -- inst.components.combat:DoAttack(target,nil, nil, nil, 0.2*1)
                    inst.target_spdamage_processed = nil
                    return
                elseif weapon.components.projectile or weapon:HasTag("rangedweapon") then
                    inst.target_spdamage_processed = nil
                    return
                else
                    inst.components.combat:DoAttack(target,weapon, nil, nil, 1)
                end
            end
        end
    end
	inst.target_spdamage_processed = nil
end

local DrownCheckClientSafe = function(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    if inst:GetCurrentPlatform() then
        return false
    else
        local platform = TheWorld.Map:GetPlatformAtPoint(x, z)
        if platform then
            return false
    	end
    end

    if TheWorld.Map:IsOceanTileAtPoint(x, y, z) or TheWorld.Map:IsInvalidTileAtPoint(x, y, z) then
        return true
    end
end
if GetModConfigData(config_name21) then
local DISMOUNT_fn = ACTIONS.DISMOUNT.fn
ACTIONS.DISMOUNT.fn = function(act)
    local rider = act.doer.components.rider
    local mount = rider and rider:GetMount()
    if mount and mount:HasTag("tallbird") and DrownCheckClientSafe(act.doer) then
        return false
    end
    return DISMOUNT_fn(act)
end
end

local SADDLE_fn = ACTIONS.SADDLE.fn
ACTIONS.SADDLE.fn = function(act)
    local target = act.target
    local saddle = act.invobject
    local doer = act.doer
    local talker = doer.components.talker

    if target and target.components.bird_cultivate
    and target.components.bird_cultivate.wild == true then
        if talker then
            doer:DoTaskInTime(0,function ()
            talker:Say(GetString(doer,"ANNOUNCE_TALLBIRD_ISWILD"))
            end)
        end
        return false
    end

    local is_target_tallbird = target and target:HasTag("tallbird")
    local is_saddle_tallbird_saddle = saddle and saddle:HasTag("tallbird_saddle")

    if is_target_tallbird and not is_saddle_tallbird_saddle then
        if talker then
            doer:DoTaskInTime(0,function ()
            talker:Say(GetString(doer,"ANNOUNCE_ISTALLBIRD_NOTSADDLE"))
            end)
        end
        return false
    end
    if is_saddle_tallbird_saddle and not is_target_tallbird then
        if talker then
            doer:DoTaskInTime(0,function ()
            talker:Say(GetString(doer,"ANNOUNCE_NOTTALLBIRD_ISSADDLE"))
            end)
        end
        return false
    end

    return SADDLE_fn(act)
end

local CastSelect = require("widgets/castselect")
AddClassPostConstruct("widgets/controls", function(self)
    if not self.owner then
        return
    end
    self.tallbird_atk_select = self:AddChild(CastSelect(self.owner))
    self.tallbird_atk_select:Hide()
end)

AddComponentPostInit("playercontroller", function(self)
    local fn_name = self.TryAOECharging and "TryAOECharging" or "TryAOETargeting"
    local old_fn = self[fn_name]
    self[fn_name] = function(self, ...)
        if old_fn(self, ...) then
            return true
        end

        local player = self.inst
        if not player or not player.HUD then
            return
        end

        -- 检查是否骑乘高脚鸟（有 tallbird 标签）
        local rider = player.replica.rider
        local mount = rider and rider:GetMount()
        if not mount or not mount:HasTag("tallbird") then
            return
        end
        if player.HUD.controls.tallbird_atk_select and player.HUD.controls.tallbird_atk_select.open == false then
            player.HUD.controls.tallbird_atk_select:Show()
        elseif player.HUD.controls.tallbird_atk_select and player.HUD.controls.tallbird_atk_select.open == true then
            player.HUD.controls.tallbird_atk_select:Hide()
        end
        return true
    end
end)

AddComponentPostInit("rider", function(self)
    local original_Mount = self.Mount
    local original_ActualDismount = self.ActualDismount
    function self:Mount(target, instant)
        original_Mount(self, target, instant)
        if target:HasTag("tallbird") then
            self.inst:AddTag("tallbird_mount")
            if self.riding and self.inst and self.inst.DynamicShadow then
                self.inst.DynamicShadow:SetSize(2.75, 1)
            end
            self.inst:ListenForEvent("onhitother",playerdamage)
            if GetModConfigData(config_name21) then
                self.inst.Physics:SetCollisionMask(
                    COLLISION.GROUND,
                    COLLISION.OBSTACLES,
                    COLLISION.CHARACTERS)
                self.inst.Physics:Teleport(self.inst.Transform:GetWorldPosition())
                if self.inst.components.drownable then
                    self.inst.components.drownable.enabled = false
                end
            end
        end
    end
    function self:ActualDismount(...)
        original_ActualDismount(self,...)
        if self.inst:HasTag("tallbird_mount") then
            self.inst:RemoveEventCallback("onhitother",playerdamage)
            if GetModConfigData(config_name21) then
            self.inst.Physics:SetCollisionMask(
					COLLISION.WORLD,
					COLLISION.OBSTACLES,
					COLLISION.SMALLOBSTACLES,
					COLLISION.CHARACTERS,
					COLLISION.GIANTS
				)
                self.inst.Physics:Teleport(self.inst.Transform:GetWorldPosition())
                if self.inst.components.drownable then
                    self.inst.components.drownable.enabled = true
                end
            end
            self.inst:RemoveTag("tallbird_mount")
        end
    end
end)
AddComponentPostInit("locomotor", function(self)
    local original_ScanForPlatform = self.ScanForPlatform
    function self:ScanForPlatform(...)
        local can_hop, hop_x, hop_z, target_platform, blocked = original_ScanForPlatform(self, ...)

        local rider = self.inst.replica and self.inst.replica.rider
        local mount = rider and rider:GetMount()
        if mount and mount:HasTag("tallbird") then
            can_hop = false
            blocked = true
        end

        return can_hop, hop_x, hop_z, target_platform, blocked
    end
end)
AddComponentPostInit("rideable", function(self)
    function self:OnSave()
        if self.inst:HasTag("tallbird") then
            return {
            rideable = self.inst.components.rideable ~= nil 
            and self.inst.components.rideable:OnSaveDomesticatable() or nil
        }
        end
    end
    function self:OnLoad(data, newents)
        if self.inst:HasTag("tallbird") then
            if data ~= nil then
                if self.inst.components.rideable ~= nil then
                    self.inst.components.rideable:OnLoadDomesticatable(data.rideable, newents)
                end
            end
        end
    end
end)

local function CalcSanityAura(inst, observer)
    return (GetModConfigData(config_name22) and inst.components.follower ~= nil and inst.components.follower.leader == observer and TUNING.SANITYAURA_SMALL) or 0
end
AddPrefabPostInit("smallbird", function(inst)
    inst:AddComponent("drownable")
    inst:AddComponent("sanityaura")
    inst:AddComponent("bird_cultivate")
    inst.components.sanityaura.aurafn = CalcSanityAura
    if inst.components.eater then
        local old_eatfn = inst.components.eater.oneatfn
        inst.components.eater:SetOnEatFn(function (inst,food,feeder)
            if old_eatfn then
                old_eatfn(inst,food,feeder)
            end
            inst.AnimState:PlayAnimation("eat")
        end)
    end
local function ShouldAcceptItem(inst, item)
    if item.components.edible and inst.components.hunger and inst.components.eater and not item:HasTag("tallbirdegg") then
        return inst.components.eater:CanEat(item)
    end
end
    if inst.components.trader then
        inst.components.trader:SetAcceptTest(ShouldAcceptItem)
    end

if GetModConfigData(config_name4) then
    inst.components.bird_cultivate.nodeath = true
else
    inst.components.bird_cultivate.nodeath = false
end
if GetModConfigData(config_name3) then
    inst.components.bird_cultivate.nogrow = true
else
    inst.components.bird_cultivate.nogrow = false
end
if GetModConfigData(config_name11) then
    inst.Physics:SetCollisionMask(
		COLLISION.GROUND,
		COLLISION.OBSTACLES,
		COLLISION.CHARACTERS)
    inst.Physics:Teleport(inst.Transform:GetWorldPosition())
end
if inst.components.hunger then
    inst.components.hunger:SetRate(smallbird_hunger_speed/TUNING.TEENBIRD_STARVE_TIME)
end
if GetModConfigData(config_name5) then
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

inst:ListenForEvent("leaderchanged", function(inst, data)
if inst.components.follower
and inst.components.follower.leader
and inst.components.follower.leader:HasTag("player") then
    inst.components.bird_cultivate.wild = false
    if inst.components.bird_cultivate then
        inst.components.bird_cultivate:Updata()
    end
end
end)

end)

AddPrefabPostInit("teenbird", function(inst)
    if inst.AnimState then
        inst.AnimState:Hide("beakfull")
        inst.AnimState:Hide("tallbird_beakfull")
    end
    inst:AddComponent("bird_cultivate")
    inst:AddComponent("drownable")
    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aurafn = CalcSanityAura
local function ShouldAcceptItem(inst, item)
    if item.components.edible and inst.components.hunger and inst.components.eater and not item:HasTag("tallbirdegg") then
        return inst.components.eater:CanEat(item)
    end
end
    if inst.components.trader then
        inst.components.trader:SetAcceptTest(ShouldAcceptItem)
    end
local function SpawnAdult(inst)
    local tallbird = SpawnPrefab("tallbird")
    tallbird.Transform:SetPosition(inst.Transform:GetWorldPosition())
    tallbird.sg:GoToState("idle")
  
    if inst.components.follower and inst.components.follower.leader then
        local leader = inst.components.follower.leader
        tallbird.components.follower:SetLeader(leader)
        if leader.components.bird_family then
            leader.components.bird_family.number = leader.components.bird_family.number+1
            leader.components.bird_family:Updata()
        end
    end

    inst:Remove()
end
if inst.userfunctions then
    inst.userfunctions.SpawnAdult=SpawnAdult
end

if GetModConfigData(config_name8) then
    inst.components.bird_cultivate.nodeath = true
else
    inst.components.bird_cultivate.nodeath = false
end

if GetModConfigData(config_name12) then
        inst.Physics:SetCollisionMask(
		COLLISION.GROUND,
		COLLISION.OBSTACLES,
		COLLISION.CHARACTERS)
        inst.Physics:Teleport(inst.Transform:GetWorldPosition())
end
if inst.components.hunger then
    inst.components.hunger:SetRate(teenbird_hunger_speed/TUNING.TEENBIRD_STARVE_TIME)
end
if GetModConfigData(config_name9) then
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
inst:ListenForEvent("leaderchanged", function(inst, data)
if inst.components.follower
and inst.components.follower.leader
and inst.components.follower.leader:HasTag("player") then
    inst.components.bird_cultivate.wild = false
    if inst.components.bird_cultivate then
        inst.components.bird_cultivate:Updata()
    end
end
end)

end)

local FARM_DEBRIS_TAGS = {"farm_debris"}
local DIG_TAGS = { "DIG_workable", "tree" }
local DIG_CANT_TAGS = { "carnivalgame_part", "event_trigger", "waxedplant" }
local SOILMUST = {"soil"}
local SOILMUSTNOT = {"merm_soil_blocker","farm_debris","NOBLOCK"}
local BrainCommon = require("brains/braincommon")
local function collectdigsites(inst, digsites, tile)
    local cent = Vector3(TheWorld.Map:GetTileCenterPoint(tile[1], 0, tile[2]))
    local soils = TheSim:FindEntities(cent.x, 0, cent.z, 2, SOILMUST, SOILMUSTNOT)
    
    if #soils < 9 then
        local dist = 4/3
        for dx=-dist,dist,dist do
            local dobreak = false
            for dz=-dist,dist,dist do
                local localsoils = TheSim:FindEntities(cent.x+dx,0, cent.z+dz, 0.21, SOILMUST, SOILMUSTNOT)
                if #localsoils < 1 and TheWorld.Map:CanTillSoilAtPoint(cent.x+dx,0,cent.z+dz) then
                    table.insert(digsites,{pos = Vector3(cent.x+dx,0,cent.z+dz), tile = tile })
                end
            end
        end
    end 
    return digsites
end
local function findtillpos(inst)
    local tiles = {}
    
    if not inst.digtile then

        -- collect garden tiles in a 9x9 grid
        local RANGE = 4
        local pos = Vector3(inst.Transform:GetWorldPosition())

        for x=-RANGE,RANGE,1 do
            for z=-RANGE,RANGE,1 do
                local tx = pos.x + (x*4)
                local tz = pos.z + (z*4)
                local tile = TheWorld.Map:GetTileAtPoint(tx, 0, tz)
                if tile == WORLD_TILES.FARMING_SOIL then
                    table.insert(tiles,{tx,tz})
                end
            end
        end
    else
        table.insert(tiles,inst.digtile)
    end

    -- find diggable places in those tiles.
    local digsites = {}
    for i,tile in ipairs(tiles)do
        digsites = collectdigsites(inst,digsites, tile)
    end

    if #digsites > 0 then
        local pos = digsites[math.random(1,#digsites)].pos
        inst.digtile = digsites[math.random(1,#digsites)].tile
        return pos
    end

    inst.digtile = nil
end
local function findTillTarget(inst,finddist)
    return findtillpos(inst)
end
local function findDigTarget(inst,finddist)
    return FindEntity(inst, finddist, nil, FARM_DEBRIS_TAGS)
end
local function TillAction(inst, leaderdist, finddist)
    local pos = findtillpos(inst)
    if pos then

        pos = Vector3(pos.x -0.02 + math.random()*0.04,0,pos.z -0.02 + math.random()*0.04)
        local marker = SpawnPrefab("merm_soil_marker")
        marker.Transform:SetPosition(pos.x,pos.y,pos.z)
        
        return BufferedAction(inst, nil, ACTIONS.TILL, nil, pos )
    end
end

local function DigAction(inst, leaderdist, finddist)
    local target = FindEntity(inst, finddist, nil, FARM_DEBRIS_TAGS)
    if target == nil and inst.components.follower.leader ~= nil then
        target = FindEntity(inst.components.follower.leader, finddist, nil, FARM_DEBRIS_TAGS)
    end

    if target ~= nil then
        if inst.stump_target ~= nil then
            target = inst.stump_target
            inst.stump_target = nil
        end

        return BufferedAction(inst, target, ACTIONS.DIG)
    end
end
local dig_clump_starter = function(inst,finddist)
    local target = findDigTarget(inst,finddist)

    if not target then
        target = findTillTarget(inst,finddist)
    end

    local leaderisdigging = inst.components.follower.leader ~= nil and
                    inst.components.follower.leader.sg ~= nil and
                    inst.components.follower.leader.sg:HasStateTag("digging")

    local leaderistilling = inst.components.follower.leader ~= nil and
                    inst.components.follower.leader.sg ~= nil and
                    inst.components.follower.leader.sg:HasStateTag("tilling")

    return (leaderisdigging or leaderistilling) and (inst.stump_target or target) or nil
end
local dig_clump_keepgoing = function(inst, leaderdist, finddist)
    return inst.stump_target ~= nil
        or (inst.components.follower.leader ~= nil and
            inst:IsNear(inst.components.follower.leader, leaderdist))
end
local dig_clump_finder = function(inst, leaderdist, finddist)
    local action = DigAction(inst, leaderdist, finddist)
    if not action then
        action = TillAction(inst, leaderdist, finddist)
    end
    return action
end

   ----

local function dig_stump_starter(inst,finddist)
    local target = FindEntity(inst, finddist, nil, DIG_TAGS, DIG_CANT_TAGS)
    return inst.stump_target or target or nil
end

local function dig_stump_keepgoing(inst, leaderdist, finddist)
    return inst.stump_target ~= nil
        or (inst.components.follower.leader ~= nil and
            inst:IsNear(inst.components.follower.leader, leaderdist))
end

local function dig_stump_finder(inst, leaderdist, finddist)
    local target = FindEntity(inst, finddist, nil, DIG_TAGS, DIG_CANT_TAGS)
    if target == nil and inst.components.follower.leader ~= nil then
        target = FindEntity(inst.components.follower.leader, finddist, nil, DIG_TAGS, DIG_CANT_TAGS)
    end
    if target ~= nil then
        if inst.stump_target ~= nil then
            target = inst.stump_target
            inst.stump_target = nil
        end

        return BufferedAction(inst, target, ACTIONS.DIG)
    end
end
AddBrainPostInit("smallbirdbrain",function(self)
local FIND_FOOD_HUNGER_PERCENT = 0.75
local SEE_FOOD_DIST = 15
local EATFOOD_CANT_TAGS = { "INLIMBO", "outofreach" }
local function IsStarving(inst)
    return inst.components.hunger and inst.components.hunger:IsStarving()
end
local function IsHungry(inst)
    return inst.components.hunger and inst.components.hunger:GetPercent() < FIND_FOOD_HUNGER_PERCENT
end
local function CanSeeFood(inst)
	local target = FindEntity(inst, SEE_FOOD_DIST,
		function(item)
			return inst.components.eater:CanEat(item) and item:IsOnValidGround() and not item:HasTag("tallbirdegg")
		end,
		nil,
		EATFOOD_CANT_TAGS)
    return target
end
local function FindFoodAction(inst)
    local target = CanSeeFood(inst)
    if target then
        return BufferedAction(inst, target, ACTIONS.EAT)
    end
end
    table.remove(self.bt.root.children[4].children,1)
    table.insert(self.bt.root.children[4].children,1,ConditionNode(function() 
        return IsStarving(self.inst) and CanSeeFood(self.inst) end, "SeesFoodToEat"))
    table.remove(self.bt.root.children[4].children,3)
    table.insert(self.bt.root.children[4].children,3,DoAction(self.inst, function() 
        return FindFoodAction(self.inst) end))
    table.remove(self.bt.root.children[7].children,1)
    table.insert(self.bt.root.children[7].children,1,ConditionNode(function()
        return IsHungry(self.inst) and CanSeeFood(self.inst) end, "SeesFoodToEat"))
    table.remove(self.bt.root.children[7].children,3)
    table.insert(self.bt.root.children[7].children,3,DoAction(self.inst, function() 
        return FindFoodAction(self.inst) end))
    table.insert(self.bt.root.children,8,BrainCommon.NodeAssistLeaderDoAction(self, {
                action = "DIG", 
                starter = dig_clump_starter,
                keepgoing = dig_clump_keepgoing,
                finder = dig_clump_finder,
        }))
    table.insert(self.bt.root.children,9,BrainCommon.NodeAssistLeaderDoAction(self, {
                action = "CHOP",
                starter = dig_stump_starter,
                keepgoing = dig_stump_keepgoing,
                finder = dig_stump_finder,
            }))
    table.insert(self.bt.root.children,10,BrainCommon.NodeAssistLeaderDoAction(self, {
            action = "CHOP", 
        }))
    table.insert(self.bt.root.children,11,BrainCommon.NodeAssistLeaderDoAction(self, {
            action = "MINE", 
        }))
end)
AddBrainPostInit("tallbirdbrain", function(self)
local THREAT_CANT_TAGS = {'tallbird', 'notarget','teenbird','smallbird','bird_friend'}
local THREAT_ONEOF_TAGS = {'character', 'animal','monster'}
local START_FACE_DIST = 6
local MIN_FOLLOW_DIST = 2
local MAX_FOLLOW_DIST = 10
local TARGET_FOLLOW_DIST = (MAX_FOLLOW_DIST+MIN_FOLLOW_DIST)/2
local MAX_CHASE_TIME      = 20
local MAX_CHASE_DIST      = 30
local RUN_AWAY_DIST       = 8
local STOP_RUN_AWAY_DIST  = 10
local function GetNearbyThreatFn(inst)
    return FindEntity(inst, START_FACE_DIST, nil, nil, THREAT_CANT_TAGS, THREAT_ONEOF_TAGS)
end
local function DefendHomeAction(inst)
    if inst.components.homeseeker and
       inst.components.homeseeker:HasHome() then
        return BufferedAction(inst, inst.components.homeseeker.home, ACTIONS.WALKTO, nil, nil, nil, 0.2)
    end
end
local function GetLeader(inst)
    return inst.components.follower and inst.components.follower.leader
end
local function GetTraderFn(inst)
    return inst.components.follower.leader ~= nil
        and inst.components.trader:IsTryingToTradeWithMe(inst.components.follower.leader)
        and inst:HasTag("companion")
        and inst.components.follower.leader
        or nil
end
local function KeepTraderFn(inst, target)
    return inst.components.trader:IsTryingToTradeWithMe(target)
end
local function GoHomeAction(inst)
    if inst.components.homeseeker and
       inst.components.homeseeker:HasHome() and not inst.components.follower.leader then
        return BufferedAction(inst, inst.components.homeseeker.home, ACTIONS.GOHOME, nil, nil, nil, 0.2)
    end
end
local function ShouldAttack(self)
    local target = self.inst.components.combat.target
    return target ~= nil and target:IsValid()
    and self.inst.components.combat:CanTarget(target)
    and not self.inst.components.combat:InCooldown()
end

    table.remove(self.bt.root.children,4)
    table.insert(self.bt.root.children,4,WhileNode(function() return self.inst.components.homeseeker and self.inst.components.homeseeker:HasHome() and GetNearbyThreatFn(self.inst.components.homeseeker.home) end, "ThreatNearNest",
				DoAction(self.inst, function() return DefendHomeAction(self.inst) end, "GoHome", true)
			))
    table.remove(self.bt.root.children,5)
    table.insert(self.bt.root.children,5,WhileNode(function() return not TheWorld.state.isday and not self.inst.components.follower.leader end, "IsNight",
				DoAction(self.inst, function() return GoHomeAction(self.inst) end, "GoHome", true)
			))
    table.remove(self.bt.root.children,3)
    table.insert(self.bt.root.children,3,WhileNode(function() return ShouldAttack(self) end, "Attack",
            ChaseAndAttack(self.inst, SpringCombatMod(MAX_CHASE_TIME), SpringCombatMod(MAX_CHASE_DIST))))
    table.insert(self.bt.root.children,4,WhileNode(function() return self.inst.components.combat.target ~= nil and self.inst.components.combat:InCooldown() end, "Dodge",
            RunAway(self.inst, function() return self.inst.components.combat.target end, RUN_AWAY_DIST, STOP_RUN_AWAY_DIST)))
    table.insert(self.bt.root.children,9,Wander(self.inst, function() if not self.inst.components.follower.leader then return self.inst.components.knownlocations:GetLocation("home") end end, 16))
    table.insert(self.bt.root.children,9,Wander(self.inst, function() if self.inst.components.follower.leader then return Vector3(self.inst.components.follower.leader.Transform:GetWorldPosition()) end end, MAX_FOLLOW_DIST- 1, {minwalktime=.5, randwalktime=.5, minwaittime=6, randwaittime=3}))
    table.remove(self.bt.root.children,11)
    table.insert(self.bt.root.children,3,FaceEntity(self.inst, GetTraderFn, KeepTraderFn))
    table.insert(self.bt.root.children,7,SequenceNode{
            ParallelNodeAny {
                WaitNode(math.random()*.5),
                    Follow(self.inst, GetLeader, 
    MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST),
            }
        })
    table.insert(self.bt.root.children,8,SequenceNode{
            ParallelNodeAny {
                WaitNode(math.random()*.9),
                    Follow(self.inst, GetLeader, 
    MIN_FOLLOW_DIST, TARGET_FOLLOW_DIST, MAX_FOLLOW_DIST),
            }
        })
    table.insert(self.bt.root.children,11,BrainCommon.NodeAssistLeaderDoAction(self, {
                action = "DIG", 
                starter = dig_clump_starter,
                keepgoing = dig_clump_keepgoing,
                finder = dig_clump_finder,
        }))
    table.insert(self.bt.root.children,12,BrainCommon.NodeAssistLeaderDoAction(self, {
                action = "CHOP",
                starter = dig_stump_starter,
                keepgoing = dig_stump_keepgoing,
                finder = dig_stump_finder,
            }))
    table.insert(self.bt.root.children,13,BrainCommon.NodeAssistLeaderDoAction(self, {
            action = "CHOP", 
        }))
    table.insert(self.bt.root.children,14,BrainCommon.NodeAssistLeaderDoAction(self, {
            action = "MINE", 
        }))
end)

AddPrefabPostInit("tallbird", function(inst)
--     inst.userfunctions={}
--     inst.userfunctions.GetPeepChance=function ()
--         return 0.9
--     end
--     if inst.components.locomotor then
--         inst.components.locomotor.walkspeed=10
--     end
-- local RETARGET_MUST_TAGS = { "_combat", "_health" }
-- local RETARGET_CANT_TAGS_HOME={"tallbird","teenbird","smallbird","bird_friend"}
-- local RETARGET_CANT_TAGS = { "tallbird","teenbird","smallbird","player",
-- "glommer","chester","companion","beefalo","hutch","abigail" }
-- local RETARGET_ONEOF_TAGS = { "animal","monster","pig" }
-- local RETARGET_ANIMAL_ONEOF_TAGS = { "animal", "monster","character" }
-- local function Retarget(inst)
--     local function IsValidTarget(guy)
--         return not guy.components.health:IsDead()
--             and inst.components.combat:CanTarget(guy)
--             and (not inst:HasTag("smallbird") or inst:HasTag("companion"))
--     end
--     return --Threat to nest
--         inst.components.homeseeker ~= nil and
--         inst.components.homeseeker:HasHome() and
--         FindEntity(
--             inst.components.homeseeker.home,
--             SpringCombatMod(TUNING.TALLBIRD_DEFEND_DIST/2),
--             IsValidTarget,
--             RETARGET_MUST_TAGS,
--             RETARGET_CANT_TAGS_HOME,
--             RETARGET_ANIMAL_ONEOF_TAGS)
--         or
--         FindEntity(
--             inst,
--             SpringCombatMod(TUNING.TALLBIRD_TARGET_DIST*2),
--             IsValidTarget,
--             RETARGET_MUST_TAGS,
--             RETARGET_CANT_TAGS,
--             RETARGET_ONEOF_TAGS)
-- end
-- local function ShouldAcceptItem(inst, item)
--     if item.components.edible and inst.components.eater and not item:HasTag("tallbirdegg") then
--         if inst.components.health then
--             inst.components.health:DoDelta(inst.components.health.maxhealth*.2,nil,item)
--         end
--         return inst.components.eater:CanEat(item)
--     end
-- end
-- local function OnGetItemFromPlayer(inst, giver, item)
--     if inst.components.sleeper then
--         inst.components.sleeper:WakeUp()
--     end
--     if item.components.edible then
--         if inst.components.combat.target and inst.components.combat.target == giver then
--             inst.components.combat:SetTarget(nil)
--         end
--         if giver.components.leader and giver:HasTag("bird_family") then
--             if inst.components.bird_cultivate then
--                 giver.components.leader:AddFollower(inst)
--                 inst.components.bird_cultivate.follow=true
--                 inst.components.bird_cultivate.wild=false
--                 inst.components.bird_cultivate:Updata()
--             end
--         end
--     end
-- end

    -- inst:AddTag("companion")
    -- inst:AddTag("character")
    -- inst:AddTag("notraptrigger")
    -- inst:AddTag("trader")

    -- if inst.components.combat then
    --     inst.components.combat:SetRetargetFunction(3, Retarget)
    -- end
    -- if inst.components.health then
    --     inst.components.health:StartRegen(10, 10)
    -- end

    -- inst:AddComponent("trader")
    -- inst.components.trader:SetAcceptTest(ShouldAcceptItem)
    -- inst.components.trader.onaccept = OnGetItemFromPlayer
    -- if inst.components.leader then
    --     inst:AddComponent("follower")
    -- end
    -- inst:AddComponent("bird_cultivate")
    -- inst:AddComponent("drownable")
    inst:AddComponent("sanityaura")
    -- inst:AddComponent("planardamage")
    inst.components.sanityaura.aurafn = CalcSanityAura

if GetModConfigData(config_name19) then
    if inst.components.bird_cultivate then
        inst.components.bird_cultivate.nodeath = true
    end
else
    if inst.components.bird_cultivate then
        inst.components.bird_cultivate.nodeath = false
    end
end


if GetModConfigData(config_name21) then
    inst.Physics:SetCollisionMask(
		COLLISION.GROUND,
		COLLISION.OBSTACLES,
		COLLISION.CHARACTERS)
    inst.Physics:Teleport(inst.Transform:GetWorldPosition())
end
local bird_health
if inst.components.health then
    bird_health=inst.components.health.currenthealth/inst.components.health.maxhealth
    inst.components.health:SetMaxHealth(tallbird_health)
    inst.components.health:SetCurrentHealth(bird_health*tallbird_health)
end
if GetModConfigData(config_name20) then
    if inst.components.bird_cultivate then
        inst.components.bird_cultivate.gift = true
    end
else
    if inst.components.bird_cultivate then
        inst.components.bird_cultivate.gift = false
    end
end
-- if inst.components.combat then
--     inst.components.combat:SetNoAggroTags({"bird_family", "smallbird","teenbird","tallbird"})
-- end
    -- inst:ListenForEvent("leaderchanged", function(inst, data)
    -- if inst.components.follower then
    -- if inst.components.follower.leader
    -- and inst.components.follower.leader:HasTag("player") then
    --     inst.components.bird_cultivate.wild = false
    --     if inst.components.bird_cultivate then
    --         inst.components.bird_cultivate:Updata()
    --     end
    -- end
    -- end
    -- end)
end)

AddStategraphActionHandler("smallbird", ActionHandler(ACTIONS.DIG, "till_or_dig"))
AddStategraphActionHandler("smallbird", ActionHandler(ACTIONS.TILL, "till_or_dig"))
AddStategraphActionHandler("smallbird", ActionHandler(ACTIONS.CHOP, "chop"))
AddStategraphActionHandler("smallbird", ActionHandler(ACTIONS.MINE, "mine"))
AddStategraphState("smallbird",State{
    name = "till_or_dig",
        tags = { "digging" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("atk")
        end,

        timeline =
        {
            TimeEvent(14 * FRAMES, function(inst)
                local act = inst:GetBufferedAction()
                local target = act.target

                if target ~= nil and target:IsValid() and target.components.workable ~= nil and target.components.workable:CanBeWorked() then
                    target.components.workable:WorkedBy(inst,10)
                end

                if target ~= nil and act.action == ACTIONS.MINE then
                    PlayMiningFX(inst, target)
                end

                if target ~= nil and  target:HasTag("farm_debris") and act.action == ACTIONS.DIG then
                    inst.SoundEmitter:PlaySound("dontstarve/wilson/dig")
                end

                if act.action == ACTIONS.TILL then
                    local pos = act:GetActionPoint()
                    if pos then
                    local tile = TheWorld.Map:GetTileAtPoint(pos.x, 0, pos.z)
                    
                        if tile == GROUND.FARMING_SOIL then
                       
                            TheWorld.Map:CollapseSoilAtPoint(pos.x,0,pos.z)
                            SpawnPrefab("farm_soil").Transform:SetPosition(pos.x,0,pos.z)
                            inst.SoundEmitter:PlaySound("dontstarve/wilson/dig")
                            
                            local markers = TheSim:FindEntities(pos.x, 0, pos.z, 0.5, {"merm_soil_marker"})
                            for _, marker in ipairs(markers) do
                                marker:Remove()
                            end
                        end
                    end
                    -- inst.SoundEmitter:PlaySound("dontstarve/wilson/dig")
                end

                if target ~= nil and target:HasTag("stump") and act.action == ACTIONS.DIG then
                    inst.SoundEmitter:PlaySound("dontstarve/wilson/use_axe_tree")
                end

                inst:PerformBufferedAction()
            end),
        },

        events =
        {
            EventHandler("animover", function (inst)
                inst.sg:GoToState("idle")
            end),
        },
})
AddStategraphState("smallbird",State{
    name = "chop",
        tags = { "chopping" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("atk")
        end,

        timeline =
        {
            TimeEvent(13 * FRAMES, function(inst)
                inst:PerformBufferedAction()
            end),
        },

        events =
        {
            EventHandler("animover", function (inst)
                inst.sg:GoToState("idle")
            end),
        },
})
AddStategraphState("smallbird",State{
    name = "mine",
        tags = { "mining" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("atk")
        end,

        timeline =
        {
            TimeEvent(13 * FRAMES, function(inst)
                if inst.bufferedaction ~= nil then
                    PlayMiningFX(inst, inst.bufferedaction.target)
                end
                inst:PerformBufferedAction()
            end),
        },

        events =
        {
            EventHandler("animover", function (inst)
                inst.sg:GoToState("idle")
            end),
        },
})
AddStategraphActionHandler("tallbird", ActionHandler(ACTIONS.DIG, "till_or_dig"))
AddStategraphActionHandler("tallbird", ActionHandler(ACTIONS.TILL, "till_or_dig"))
AddStategraphActionHandler("tallbird", ActionHandler(ACTIONS.CHOP, "chop"))
AddStategraphActionHandler("tallbird", ActionHandler(ACTIONS.MINE, "mine"))
AddStategraphState("tallbird",State{
    name = "till_or_dig",
        tags = { "busy","digging" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")
        end,

        timeline =
        {
            TimeEvent(14 * FRAMES, function(inst)
                local act = inst:GetBufferedAction()
                local target = act.target

                if target ~= nil and target:IsValid() and target.components.workable ~= nil and target.components.workable:CanBeWorked() then
                    target.components.workable:WorkedBy(inst,10)
                end

                if target ~= nil and act.action == ACTIONS.MINE then
                    PlayMiningFX(inst, target)
                end

                if target ~= nil and  target:HasTag("farm_debris") and act.action == ACTIONS.DIG then
                    inst.SoundEmitter:PlaySound("dontstarve/wilson/dig")
                end

                if act.action == ACTIONS.TILL then
                    local pos = act:GetActionPoint()
                    if pos then
                    local tile = TheWorld.Map:GetTileAtPoint(pos.x, 0, pos.z)
                    
                        if tile == GROUND.FARMING_SOIL then
                       
                            TheWorld.Map:CollapseSoilAtPoint(pos.x,0,pos.z)
                            SpawnPrefab("farm_soil").Transform:SetPosition(pos.x,0,pos.z)
                       
                            inst.SoundEmitter:PlaySound("dontstarve/wilson/dig")
                            
                            local markers = TheSim:FindEntities(pos.x, 0, pos.z, 0.5, {"merm_soil_marker"})
                            for _, marker in ipairs(markers) do
                                marker:Remove()
                            end
                        end
                    end
                    -- inst.SoundEmitter:PlaySound("dontstarve/wilson/dig")
                end

                if target ~= nil and target:HasTag("stump") and act.action == ACTIONS.DIG then
                    inst.SoundEmitter:PlaySound("dontstarve/wilson/use_axe_tree")
                end

                inst:PerformBufferedAction()
            end),
        },

        events =
        {
            EventHandler("animover", function (inst)
                inst.sg:GoToState("idle")
            end),
        },
})
AddStategraphState("tallbird",State{
    name = "chop",
        tags = { "chopping" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("atk")
        end,

        timeline =
        {
            TimeEvent(13 * FRAMES, function(inst)
                inst:PerformBufferedAction()
            end),
        },

        events =
        {
            EventHandler("animover", function (inst)
                inst.sg:GoToState("idle")
            end),
        },
})
AddStategraphState("tallbird",State{
    name = "mine",
        tags = { "mining" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("atk")
        end,

        timeline =
        {
            TimeEvent(13 * FRAMES, function(inst)
                if inst.bufferedaction ~= nil then
                    PlayMiningFX(inst, inst.bufferedaction.target)
                end
                inst:PerformBufferedAction()
            end),
        },

        events =
        {
            EventHandler("animover", function (inst)
                inst.sg:GoToState("idle")
            end),
        },
})

AddStategraphPostInit("tallbird", function(sg)
    local death_fn = sg.events.death.fn
    sg.events.death.fn = function(inst, ...)
        if not inst:HasTag("tallbird") or inst.components.rideable == nil or not inst.components.rideable:IsBeingRidden() then
            return death_fn(inst, ...)
        end
    end
end)

AddStategraphPostInit("wilson", function(sg)
    local state = sg.states["mount"]
    if state then
      local old_timeline = state.timeline
      local original_fn = nil
      local pos = nil
      for i = #old_timeline, 1, -1 do
        local v = old_timeline[i]
        if v and v.time and v.time == 14 * FRAMES then
            original_fn = v.fn
            pos = i
            table.remove(old_timeline, i)
            break
        end
      end
      table.insert(old_timeline,pos,
        TimeEvent(14 * FRAMES, function(inst)
            if inst:HasTag("tallbird_mount") then
              inst.SoundEmitter:PlaySound("dontstarve/creatures/tallbird/chirp")
            else
              if original_fn then
                    original_fn(inst)
                end
            end
        end)
      )
    end
    -- local attack_timeline = sg.states.attack.timeline
    -- table.insert(attack_timeline, TimeEvent(7 * FRAMES, function(inst)
    --     local rider = inst.replica.rider
    --     local mount = rider and rider:GetMount()
    --     if not mount or not mount:HasTag("tallbird") then
    --         return
    --     end
    --     inst.SoundEmitter:PlaySound("dontstarve/creatures/tallbird/attack")
    -- end))
    
end)

AddPrefabPostInit("purebrilliance", function(inst)
    inst:AddTag("bird_plannaritem")
    inst:AddComponent("bird_plannaritem")
end)

AddPrefabPostInit("horrorfuel", function(inst)
    inst:AddTag("bird_plannaritem")
    inst:AddComponent("bird_plannaritem")
end)

local BIRD_PLANNARITEM = Action()
BIRD_PLANNARITEM.id = "BIRD_PLANNARITEM"
BIRD_PLANNARITEM.strfn = function (act)
    return "PLANNAR"
end
BIRD_PLANNARITEM.priority = 20
BIRD_PLANNARITEM.fn = function (act)
    local obj = act.invobject
    local target = act.target
    if obj.components.bird_plannaritem and target.components.bird_cultivate and target.components.bird_cultivate.plannar==false
    then
        return obj.components.bird_plannaritem:Do(obj,target)
    end
    return false
end
AddAction(BIRD_PLANNARITEM)
STRINGS.ACTIONS.BIRD_PLANNARITEM = {
    PLANNAR = "位面化"
}

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.BIRD_PLANNARITEM, "give"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.BIRD_PLANNARITEM, "give"))

AddComponentAction("USEITEM", "bird_plannaritem", function(inst, doer, target, actions, right)
    if inst:HasTag("bird_plannaritem") and target:HasTag("tallbird") and doer:HasTag("bird_family") and not target:HasTag("bird_plannared") then
        table.insert(actions, ACTIONS.BIRD_PLANNARITEM)
    end
end)

AddPrefabPostInit("twigs", function(inst)
    inst:AddTag("bird_follow")
    inst:AddComponent("bird_follow")
end)

AddPrefabPostInit("cutgrass", function(inst)
    inst:AddTag("bird_leave")
    inst:AddComponent("bird_leave")
end)

local BIRD_LEAVE = Action()
BIRD_LEAVE.id = "BIRD_LEAVE"
BIRD_LEAVE.strfn = function (act)
    return "LEAVE"
end
BIRD_LEAVE.priority = 20
BIRD_LEAVE.fn = function (act)
    local obj = act.invobject
    local target = act.target
    local doer = act.doer
    if obj.components.bird_leave and target.components.bird_cultivate and target.components.bird_cultivate.wild==false then
        return obj.components.bird_leave:Leave(obj,target,doer)
    end
    return false
end
AddAction(BIRD_LEAVE)
STRINGS.ACTIONS.BIRD_LEAVE = {
    LEAVE = "取消跟随"
}

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.BIRD_LEAVE, "give"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.BIRD_LEAVE, "give"))

AddComponentAction("USEITEM", "bird_leave", function(inst, doer, target, actions, right)
    if inst:HasTag("bird_leave") and target:HasTag("lovely_bird") and doer:HasTag("bird_family") and not target:HasTag("bird_leaver") and target:HasTag("tallbird") then
        table.insert(actions, ACTIONS.BIRD_LEAVE)
    end
end)

local BIRD_FOLLOW = Action()
BIRD_FOLLOW.id = "BIRD_FOLLOW"
BIRD_FOLLOW.strfn = function (act)
    return "FOLLOW"
end
BIRD_FOLLOW.priority = 20
BIRD_FOLLOW.fn = function (act)
    local obj = act.invobject
    local target = act.target
    local doer = act.doer
    if obj.components.bird_follow and target.components.bird_cultivate then
        return obj.components.bird_follow:Follow(obj,target,doer)
    end
    return false
end
AddAction(BIRD_FOLLOW)
STRINGS.ACTIONS.BIRD_FOLLOW = {
    FOLLOW = "跟随"
}

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.BIRD_FOLLOW, "give"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.BIRD_FOLLOW, "give"))

AddComponentAction("USEITEM", "bird_follow", function(inst, doer, target, actions, right)
    if inst:HasTag("bird_follow") and doer:HasTag("bird_family") and not target:HasTag("bird_follower") and target:HasTag("tallbird") then
        table.insert(actions, ACTIONS.BIRD_FOLLOW)
    end
end)

local attack_mode_key = 114
local attack_mode = "tallbird"

AddModRPCHandler(attack_mode..'attack', attack_mode..'attack', function(inst,mode)
    if inst and inst:IsValid() and not inst:HasTag("playerghost") and inst:HasTag("tallbird_mount") then
        if mode==true then
            if inst and inst.components.talker then
                inst.components.talker:Say(GetString(inst,"ANNOUNCE_TALLBIRD_ATKLEG"))
            end
            inst._tallbird_mount_aoe_leg = mode
        else
            if inst and inst.components.talker then
                inst.components.talker:Say(GetString(inst,"ANNOUNCE_TALLBIRD_NOTATKLEG"))
            end
            inst._tallbird_mount_aoe_leg = mode
        end
    end
end)

local function IsHUDScreen()
	local screen = TheFrontEnd:GetActiveScreen()
    return screen and screen.name == "HUD"
end
local function AddKeyListener(self)
    if self.owner and self.owner:HasTag("player") then
        self[attack_mode..'handle'] = {}
        self.inst:ListenForEvent("onremove", function()
            for _, handler in pairs(self[attack_mode..'handle']) do
                handler:Remove()
            end
        end)
        self[attack_mode.."handle"].keydown = TheInput:AddKeyDownHandler(attack_mode_key, function()
    	if IsHUDScreen() and self.owner:HasTag("tallbird_mount") then
            if self.owner._tallbird_mount_aoe_leg == true then
                self.owner._tallbird_mount_aoe_leg = false
            else
                self.owner._tallbird_mount_aoe_leg = true
            end
        	SendModRPCToServer(MOD_RPC[attack_mode..'attack'][attack_mode..'attack'],self.owner._tallbird_mount_aoe_leg)
    	end
        end)
    end
end

AddClassPostConstruct("widgets/controls", AddKeyListener)