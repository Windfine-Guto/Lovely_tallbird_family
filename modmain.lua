GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})

Assets = {
	Asset("ANIM", "anim/spell_icons_tallbird.zip"),
    Asset("ANIM","anim/tallbird_health.zip"),
}

PrefabFiles = {
    "tallbird",
    "tallbird_saddle",
    "tallbird_eggshell",
    "tallbird_skins"
}

local writeables = require("writeables")

-- 公共基础配置
local base_layout = {
    prompt = "给你的鸟起个名字",
    animbank = "ui_board_5x3",
    animbuild = "ui_board_5x3",
    menuoffset = Vector3(6, -70, 0),
    maxcharacters = TUNING.BEEFALO_NAMING_MAX_LENGTH or 80,
    defaulttext = function(inst, doer)
        local name = (doer and doer.name) or "无名氏"
        return name.."的鸟" end,
    cancelbtn = { text = "取消", control = CONTROL_CANCEL },
    acceptbtn = { text = "确定", control = CONTROL_ACCEPT },
}

if not TheNet:IsDedicated() then
    local BIRD_NAMES = {
        "小短腿", "飞毛腿", "尖嘴巴", "长睫毛",
        "跳跳","大眼睛","黑汤圆","乒乓球","炸弹","哈基鸟","小鸡","坤坤","大长腿","活珠子",
        "蛋蛋","咕咕鸡","花生","小丸子","肉丸","球球","大鸡腿","小鸟","皮球","瓜子","蹦蹦",
        "飞飞","小西瓜","笨蛋","臭鸟","月亮","皮蛋","鸡蛋","鸟蛋","鸟士比亚","鸟加索",
    }
    base_layout.middlebtn = {
        text = "随机",
        cb = function(inst, doer, widget)
            local name = BIRD_NAMES[math.random(#BIRD_NAMES)]
            widget:OverrideText(name)
        end,
        control = CONTROL_MENU_MISC_2,
    }
end

writeables.AddLayout("tallbird", base_layout)
writeables.AddLayout("teenbird", base_layout)
writeables.AddLayout("smallbird", base_layout)

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
    modimport("scripts/string_zh")
else
    modimport("scripts/string_en")
end

local modname = KnownModIndex:GetModActualName(folder_name) or folder_name or "tallbird"

local skin_prefabs = LoadPrefabFile("scripts/prefabs/tallbird_skins", nil, MODS_ROOT..modname.."/")
local tallbird_skins = {}
for _, prefab in ipairs(skin_prefabs) do
    table.insert(tallbird_skins, prefab.name)
end

GlassicAPI.SkinHandler.AddModSkins({
    tallbird = tallbird_skins,
})

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

    if GLOBAL.TheWorld.ismastersim then
        inst.OnTallbirdHealthDelta = function(mount, data)
            inst.tallbirdHealth:set(mount.replica.health:GetCurrent())
        end

        inst:DoTaskInTime(0.1, function()
            local parent = inst.entity:GetParent()
            inst:ListenForEvent("mounted", OnTallbirdMount, parent)
            inst:ListenForEvent("dismounted", OnTallbirdDismount, parent)
        end)
    end
end)

local CastSelect = require("widgets/castselect")
local TallbirdMountHealth = require "widgets/tallbird_mount_health"
AddClassPostConstruct("widgets/controls", function(self)
    if not self.owner then
        return
    end
    self.tallbird_atk_select = self:AddChild(CastSelect(self.owner))
    self.tallbird_atk_select:Hide()

    self.TallbirdMountHealth = self.bottom_root:AddChild(TallbirdMountHealth(self.owner))
    self.TallbirdMountHealth:MoveToBack()
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
            self.inst.components.locomotor:SetExternalSpeedMultiplier(self.inst,"tallbird_speed",1.25)
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
            local inst = self.inst
            if inst.components.worker == nil then
                inst:AddComponent("worker")
                inst.components.worker:SetAction(ACTIONS.CHOP,  1 )
                inst.components.worker:SetAction(ACTIONS.MINE,  1 )
                inst.components.worker:SetAction(ACTIONS.DIG,    1)
                inst.components.worker:SetAction(ACTIONS.HAMMER, 1)
            end
            if target:HasTag("bird_plannared") and not target:HasTag("toughworker") then
                inst:AddTag("toughworker")
            end
        end
    end
    function self:ActualDismount(...)
        original_ActualDismount(self,...)
        if self.inst:HasTag("tallbird_mount") then
            self.inst:RemoveEventCallback("onhitother",playerdamage)
            self.inst.components.locomotor:RemoveExternalSpeedMultiplier(self.inst,"tallbird_speed")
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
            if self.inst.components.worker ~= nil then
                self.inst:RemoveComponent("worker")
            end
            self.inst:RemoveTag("toughworker")
            self.inst:RemoveTag("tallbird_mount")
        end
    end
end)
-- AddComponentPostInit("locomotor", function(self)
--     local original_ScanForPlatform = self.ScanForPlatform
--     function self:ScanForPlatform(...)
--         local can_hop, hop_x, hop_z, target_platform, blocked = original_ScanForPlatform(self, ...)

--         local rider = self.inst.replica and self.inst.replica.rider
--         local mount = rider and rider:GetMount()
--         if mount and mount:HasTag("tallbird") then
--             can_hop = false
--             blocked = true
--         end

--         return can_hop, hop_x, hop_z, target_platform, blocked
--     end
-- end)
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
    if inst.components.locomotor then
        inst.components.locomotor.runspeed = 6
        inst.components.locomotor:SetAllowPlatformHopping(true)
    end
    inst:AddComponent("embarker")
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

if inst.userfunctions then
    -- local old_teenfn = inst.userfunctions.SpawnTeen
    inst.userfunctions.SpawnTeen = function (inst)
        local teenbird = SpawnPrefab("teenbird")
        teenbird.Transform:SetPosition(inst.Transform:GetWorldPosition())
        teenbird.sg:GoToState("idle")
        local name = inst.name
        if inst.components.follower:GetLeader() then
            teenbird.components.follower:SetLeader(inst.components.follower:GetLeader())
            local leader = inst.components.follower:GetLeader()
            if name and teenbird.components.named then
                teenbird.components.named:SetName(name,leader.name)
            end
        end

        inst:Remove()
    end
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
    if inst.components.locomotor then
        inst.components.locomotor.walkspeed = 8
        inst.components.locomotor.runspeed = 8
        inst.components.locomotor:SetAllowPlatformHopping(true)
    end
    inst:AddComponent("embarker")
    inst:AddComponent("bird_cultivate")
    inst:AddComponent("drownable")
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
    end
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
        local name = inst.name
        tallbird.components.follower:SetLeader(leader)
        if name and tallbird.components.named then
            tallbird.components.named:SetName(name,leader.name)
        end
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

local oldMineStarter = BrainCommon.AssistLeaderDefaults.MINE.Starter
BrainCommon.AssistLeaderDefaults.MINE.Starter = function(inst, leaderdist, finddist)
    if oldMineStarter(inst, leaderdist, finddist) then
        return true
    end
    local leader = inst.components.follower and inst.components.follower:GetLeader()
    if leader and leader:GetBufferedAction() then
        local action = leader:GetBufferedAction().action
        return action == ACTIONS.BIRD_MINE or action == ACTIONS.MINE
    end
    return false
end

-- 扩展 CHOP 的 Starter
local oldChopStarter = BrainCommon.AssistLeaderDefaults.CHOP.Starter
BrainCommon.AssistLeaderDefaults.CHOP.Starter = function(inst, leaderdist, finddist)
    if oldChopStarter(inst, leaderdist, finddist) then
        return true
    end
    local leader = inst.components.follower and inst.components.follower:GetLeader()
    if leader and leader:GetBufferedAction() then
        local action = leader:GetBufferedAction().action
        return action == ACTIONS.BIRD_CHOP or action == ACTIONS.CHOP
    end
    return false
end

AddBrainPostInit("smallbirdbrain",function(self)
local FIND_FOOD_HUNGER_PERCENT = 0.75
local SEE_FOOD_DIST = 15
local MIN_FOLLOW_TARGET_DIST     = 5
local DEFAULT_FOLLOW_TARGET_DIST = 8
local MAX_FOLLOW_TARGET_DIST     = 15
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

local function ShouldWaitForHelp(inst)
    if inst.components.combat.target == nil then
        return false
    end
    local leader = inst.components.follower:GetLeader()
    return leader ~= nil and inst.components.health:GetPercent() <= 0.3
end
local function TargetFollowTargetDistFn(inst)
    local target = inst.components.combat.target

    if target == nil or target.components.combat == nil then
        return DEFAULT_FOLLOW_TARGET_DIST
    end

    return math.max(math.sqrt(target.components.combat:CalcAttackRangeSq(inst)) + MIN_FOLLOW_TARGET_DIST, DEFAULT_FOLLOW_TARGET_DIST)
end

    table.insert(self.bt.root.children,4,WhileNode(function() return ShouldWaitForHelp(self.inst) end, "WaitingForHelp",
            PriorityNode({
                Follow(self.inst, function() return self.inst.components.combat.target end, MIN_FOLLOW_TARGET_DIST, TargetFollowTargetDistFn, MAX_FOLLOW_TARGET_DIST),
                StandStill(self.inst)
            }, .25)
        )
        )
    table.remove(self.bt.root.children[5].children,1)
    table.insert(self.bt.root.children[5].children,1,ConditionNode(function() 
        return IsStarving(self.inst) and CanSeeFood(self.inst) end, "SeesFoodToEat"))
    table.remove(self.bt.root.children[5].children,3)
    table.insert(self.bt.root.children[5].children,3,DoAction(self.inst, function() 
        return FindFoodAction(self.inst) end))
    table.remove(self.bt.root.children[8].children,1)
    table.insert(self.bt.root.children[8].children,1,ConditionNode(function()
        return IsHungry(self.inst) and CanSeeFood(self.inst) end, "SeesFoodToEat"))
    table.remove(self.bt.root.children[8].children,3)
    table.insert(self.bt.root.children[8].children,3,DoAction(self.inst, function() 
        return FindFoodAction(self.inst) end))
    table.insert(self.bt.root.children,9,BrainCommon.NodeAssistLeaderDoAction(self, {
                action = "DIG", 
                starter = dig_clump_starter,
                keepgoing = dig_clump_keepgoing,
                finder = dig_clump_finder,
        }))
    table.insert(self.bt.root.children,10,BrainCommon.NodeAssistLeaderDoAction(self, {
                action = "CHOP",
                starter = dig_stump_starter,
                keepgoing = dig_stump_keepgoing,
                finder = dig_stump_finder,
            }))
    table.insert(self.bt.root.children,11,BrainCommon.NodeAssistLeaderDoAction(self, {
            action = "CHOP", 
        }))
    table.insert(self.bt.root.children,12,BrainCommon.NodeAssistLeaderDoAction(self, {
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

AddStategraphEvent("smallbird", EventHandler("onhop",
        function(inst)
            if (inst.components.health == nil or not inst.components.health:IsDead()) and inst.sg:HasAnyStateTag("moving", "idle") then
                if not inst.sg:HasStateTag("jumping") then
                    if inst.components.embarker and inst.components.embarker.antic and inst:HasTag("swimming") then
                        inst.sg:GoToState("hop_antic")
                    else
                        inst.sg:GoToState("hop_pre")
                    end
                end
            elseif inst.components.embarker then
                inst.components.embarker:Cancel()
            end
        end))

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
local wait_for_pre = true
local anims = { pre = "boat_jump_pre", loop = "boat_jump", pst = "boat_jump_pst"}
local timelines = {}
local data = {}
local land_sound = nil
local landed_in_falling_state = nil
local fns = nil

AddStategraphState("smallbird",State{
        name = "hop_pre",
        tags = { "doing", "nointerrupt", "busy", "boathopping", "jumping", "autopredict", "nomorph", "nosleep" },

        onenter = function(inst)
			if fns and fns.pre_onenter then
				fns.pre_onenter(inst)
			end
            local embark_x, embark_z = inst.components.embarker:GetEmbarkPosition()
            inst:ForceFacePoint(embark_x, 0, embark_z)
            if not wait_for_pre then
				inst.sg.statemem.not_interrupted = true
                inst.sg:GoToState("hop_loop", inst.sg.statemem.queued_post_land_state)
			else
	            inst.AnimState:PlayAnimation(FunctionOrValue(anims.pre, inst) or "jump_pre", false)
				if data.start_embarking_pre_frame ~= nil then
					inst.sg:SetTimeout(data.start_embarking_pre_frame)
				end
            end
        end,

        timeline = timelines.hop_pre or nil,

		ontimeout = function(inst)
			inst.sg.statemem.collisionmask = inst.Physics:GetCollisionMask()
	        inst.Physics:SetCollisionMask(COLLISION.GROUND)
			if not TheWorld.ismastersim then
	            inst.Physics:SetLocalCollisionMask(COLLISION.GROUND)
			end
			inst.components.embarker:StartMoving()
            if fns and fns.pre_ontimeout then
                fns.pre_ontimeout(inst)
            end
		end,

        events =
        {
            EventHandler("animover",
                function(inst)
                    if wait_for_pre then
						inst.sg.statemem.not_interrupted = true
                        inst.sg:GoToState("hop_loop", {queued_post_land_state = inst.sg.statemem.queued_post_land_state, collisionmask = inst.sg.statemem.collisionmask})
                    end
                end),
            EventHandler("cancelhop", function(inst)
                inst.sg:GoToState("hop_cancelhop")
            end),
        },

		onexit = function(inst)
			if fns and fns.pre_onexit then
				fns.pre_onexit(inst)
			end
			if not inst.sg.statemem.not_interrupted then
				if data.start_embarking_pre_frame ~= nil then
					inst.Physics:ClearLocalCollisionMask()
					if inst.sg.statemem.collisionmask ~= nil then
						inst.Physics:SetCollisionMask(inst.sg.statemem.collisionmask)
					end
				end
	            inst.components.embarker:Cancel()
			end
		end,
})
AddStategraphState("smallbird",State{
        name = "hop_loop",
        tags = { "doing", "nointerrupt", "busy", "boathopping", "jumping", "autopredict", "nomorph", "nosleep" },

        onenter = function(inst, data)
			if fns and fns.loop_onenter then
				fns.loop_onenter(inst)
			end
			inst.sg.statemem.queued_post_land_state = data ~= nil and data.queued_post_land_state or nil
            inst.AnimState:PlayAnimation(FunctionOrValue(anims.loop, inst) or "jump_loop", true)
			inst.sg.statemem.collisionmask = data ~= nil and data.collisionmask or inst.Physics:GetCollisionMask()
	        inst.Physics:SetCollisionMask(COLLISION.GROUND)
			if not TheWorld.ismastersim then
	            inst.Physics:SetLocalCollisionMask(COLLISION.GROUND)
			end
            inst.components.embarker:StartMoving()
            inst:AddTag("ignorewalkableplatforms")
        end,

        timeline = timelines.hop_loop or nil,

        events =
        {
            EventHandler("done_embark_movement", function(inst)
                local px, _, pz = inst.Transform:GetWorldPosition()
				inst.sg.statemem.not_interrupted = true
                inst.sg:GoToState("hop_pst", {landed_in_water = not TheWorld.Map:IsPassableAtPoint(px, 0, pz), queued_post_land_state = inst.sg.statemem.queued_post_land_state} )
            end),
            EventHandler("cancelhop", function(inst)
                inst.sg:GoToState("hop_cancelhop")
            end),
        },

		onexit = function(inst)
			if fns and fns.loop_onexit then
				fns.loop_onexit(inst)
			end
            inst.Physics:ClearLocalCollisionMask()
			if inst.sg.statemem.collisionmask ~= nil then
                inst.Physics:SetCollisionMask(inst.sg.statemem.collisionmask)
			end
            inst:RemoveTag("ignorewalkableplatforms")
			if not inst.sg.statemem.not_interrupted then
	            inst.components.embarker:Cancel()
			end

			if inst.components.locomotor.isrunning then
                inst:PushEvent("locomote")
			end
		end,
})
AddStategraphState("smallbird",State{
        name = "hop_pst",
        tags = { "doing", "nointerrupt", "boathopping", "jumping", "autopredict", "nomorph", "nosleep" },

        onenter = function(inst, data)
			if fns and fns.pst_onenter then
				fns.pst_onenter(inst)
			end
            inst.AnimState:PlayAnimation(FunctionOrValue(anims.pst, inst) or "jump_pst", false)

            inst.components.embarker:Embark()

            local nextstate = "hop_pst_complete"
			if data ~= nil then
				nextstate = (
                                data.landed_in_water and landed_in_falling_state ~= nil and
                                (
                                    type(landed_in_falling_state) ~= "function" and landed_in_falling_state or landed_in_falling_state(inst)
                                )
                            )
							 or data.queued_post_land_state
							 or nextstate
			end
            if wait_for_pre then
                inst.sg.statemem.nextstate = nextstate
            else
                inst.sg:GoToState(nextstate)
            end
        end,

        timeline = timelines.hop_pst or nil,

        events =
        {
            EventHandler("animover", function(inst)
                if wait_for_pre then
                    inst.sg:GoToState(inst.sg.statemem.nextstate)
                end
            end),
        },

		onexit = function(inst)
			if fns and fns.pst_onexit then
				fns.pst_onexit(inst)
			end
			-- here for now, should be moved into timeline
			land_sound = FunctionOrValue(land_sound, inst)
			if land_sound ~= nil then
				--For now we just have the land on boat sound
				--Delay since inst:GetCurrentPlatform() may not be updated yet
				inst:DoTaskInTime(0, DoHopLandSound, land_sound)
            end
		end
})
AddStategraphState("smallbird",State{
        name = "hop_pst_complete",
        tags = {"autopredict", "nomorph", "nosleep" },

        onenter = function(inst)
			if fns and fns.pst_complete_onenter then
				fns.pst_complete_onenter(inst)
			end
			if inst.components.locomotor.isrunning then
                inst:DoTaskInTime(0,
                    function()
                        if inst.sg.currentstate.name == "hop_pst_complete" then
                            inst.sg:GoToState("idle")
                        end
                    end)
            else
                inst.sg:GoToState("idle")
            end
        end,

		onexit = fns and fns.pst_complete_onexit,
})
AddStategraphState("smallbird",State{
        name = "hop_cancelhop",
        tags = {"nopredict", "nomorph", "nosleep", "busy"},

        onenter = function(inst)
			if fns and fns.cancelhop_onenter then
				fns.cancelhop_onenter(inst)
			end
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation(FunctionOrValue(anims.pst, inst) or "jump_pst", false)
        end,

        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },

		onexit = fns and fns.cancelhop_onexit,
})

AddStategraphActionHandler("tallbird", ActionHandler(ACTIONS.DIG, "till_or_dig"))
AddStategraphActionHandler("tallbird", ActionHandler(ACTIONS.TILL, "till_or_dig"))
AddStategraphActionHandler("tallbird", ActionHandler(ACTIONS.CHOP, "chop"))
AddStategraphActionHandler("tallbird", ActionHandler(ACTIONS.MINE, "mine"))

AddStategraphState("tallbird",State{
        name = "hop_pre",
        tags = { "doing", "nointerrupt", "busy", "boathopping", "jumping", "autopredict", "nomorph", "nosleep" },

        onenter = function(inst)
			if fns and fns.pre_onenter then
				fns.pre_onenter(inst)
			end
            local embark_x, embark_z = inst.components.embarker:GetEmbarkPosition()
            inst:ForceFacePoint(embark_x, 0, embark_z)
            if not wait_for_pre then
				inst.sg.statemem.not_interrupted = true
                inst.sg:GoToState("hop_loop", inst.sg.statemem.queued_post_land_state)
			else
	            inst.AnimState:PlayAnimation(FunctionOrValue(anims.pre, inst) or "jump_pre", false)
				if data.start_embarking_pre_frame ~= nil then
					inst.sg:SetTimeout(data.start_embarking_pre_frame)
				end
            end
        end,

        timeline = timelines.hop_pre or nil,

		ontimeout = function(inst)
			inst.sg.statemem.collisionmask = inst.Physics:GetCollisionMask()
	        inst.Physics:SetCollisionMask(COLLISION.GROUND)
			if not TheWorld.ismastersim then
	            inst.Physics:SetLocalCollisionMask(COLLISION.GROUND)
			end
			inst.components.embarker:StartMoving()
            if fns and fns.pre_ontimeout then
                fns.pre_ontimeout(inst)
            end
		end,

        events =
        {
            EventHandler("animover",
                function(inst)
                    if wait_for_pre then
						inst.sg.statemem.not_interrupted = true
                        inst.sg:GoToState("hop_loop", {queued_post_land_state = inst.sg.statemem.queued_post_land_state, collisionmask = inst.sg.statemem.collisionmask})
                    end
                end),
            EventHandler("cancelhop", function(inst)
                inst.sg:GoToState("hop_cancelhop")
            end),
        },

		onexit = function(inst)
			if fns and fns.pre_onexit then
				fns.pre_onexit(inst)
			end
			if not inst.sg.statemem.not_interrupted then
				if data.start_embarking_pre_frame ~= nil then
					inst.Physics:ClearLocalCollisionMask()
					if inst.sg.statemem.collisionmask ~= nil then
						inst.Physics:SetCollisionMask(inst.sg.statemem.collisionmask)
					end
				end
	            inst.components.embarker:Cancel()
			end
		end,
})
AddStategraphState("tallbird",State{
        name = "hop_loop",
        tags = { "doing", "nointerrupt", "busy", "boathopping", "jumping", "autopredict", "nomorph", "nosleep" },

        onenter = function(inst, data)
			if fns and fns.loop_onenter then
				fns.loop_onenter(inst)
			end
			inst.sg.statemem.queued_post_land_state = data ~= nil and data.queued_post_land_state or nil
            inst.AnimState:PlayAnimation(FunctionOrValue(anims.loop, inst) or "jump_loop", true)
			inst.sg.statemem.collisionmask = data ~= nil and data.collisionmask or inst.Physics:GetCollisionMask()
	        inst.Physics:SetCollisionMask(COLLISION.GROUND)
			if not TheWorld.ismastersim then
	            inst.Physics:SetLocalCollisionMask(COLLISION.GROUND)
			end
            inst.components.embarker:StartMoving()
            inst:AddTag("ignorewalkableplatforms")
        end,

        timeline = timelines.hop_loop or nil,

        events =
        {
            EventHandler("done_embark_movement", function(inst)
                local px, _, pz = inst.Transform:GetWorldPosition()
				inst.sg.statemem.not_interrupted = true
                inst.sg:GoToState("hop_pst", {landed_in_water = not TheWorld.Map:IsPassableAtPoint(px, 0, pz), queued_post_land_state = inst.sg.statemem.queued_post_land_state} )
            end),
            EventHandler("cancelhop", function(inst)
                inst.sg:GoToState("hop_cancelhop")
            end),
        },

		onexit = function(inst)
			if fns and fns.loop_onexit then
				fns.loop_onexit(inst)
			end
            inst.Physics:ClearLocalCollisionMask()
			if inst.sg.statemem.collisionmask ~= nil then
                inst.Physics:SetCollisionMask(inst.sg.statemem.collisionmask)
			end
            inst:RemoveTag("ignorewalkableplatforms")
			if not inst.sg.statemem.not_interrupted then
	            inst.components.embarker:Cancel()
			end

			if inst.components.locomotor.isrunning then
                inst:PushEvent("locomote")
			end
		end,
})
AddStategraphState("tallbird",State{
        name = "hop_pst",
        tags = { "doing", "nointerrupt", "boathopping", "jumping", "autopredict", "nomorph", "nosleep" },

        onenter = function(inst, data)
			if fns and fns.pst_onenter then
				fns.pst_onenter(inst)
			end
            inst.AnimState:PlayAnimation(FunctionOrValue(anims.pst, inst) or "jump_pst", false)

            inst.components.embarker:Embark()

            local nextstate = "hop_pst_complete"
			if data ~= nil then
				nextstate = (
                                data.landed_in_water and landed_in_falling_state ~= nil and
                                (
                                    type(landed_in_falling_state) ~= "function" and landed_in_falling_state or landed_in_falling_state(inst)
                                )
                            )
							 or data.queued_post_land_state
							 or nextstate
			end
            if wait_for_pre then
                inst.sg.statemem.nextstate = nextstate
            else
                inst.sg:GoToState(nextstate)
            end
        end,

        timeline = timelines.hop_pst or nil,

        events =
        {
            EventHandler("animover", function(inst)
                if wait_for_pre then
                    inst.sg:GoToState(inst.sg.statemem.nextstate)
                end
            end),
        },

		onexit = function(inst)
			if fns and fns.pst_onexit then
				fns.pst_onexit(inst)
			end
			-- here for now, should be moved into timeline
			land_sound = FunctionOrValue(land_sound, inst)
			if land_sound ~= nil then
				--For now we just have the land on boat sound
				--Delay since inst:GetCurrentPlatform() may not be updated yet
				inst:DoTaskInTime(0, DoHopLandSound, land_sound)
            end
		end
})
AddStategraphState("tallbird",State{
        name = "hop_pst_complete",
        tags = {"autopredict", "nomorph", "nosleep" },

        onenter = function(inst)
			if fns and fns.pst_complete_onenter then
				fns.pst_complete_onenter(inst)
			end
			if inst.components.locomotor.isrunning then
                inst:DoTaskInTime(0,
                    function()
                        if inst.sg.currentstate.name == "hop_pst_complete" then
                            inst.sg:GoToState("idle")
                        end
                    end)
            else
                inst.sg:GoToState("idle")
            end
        end,

		onexit = fns and fns.pst_complete_onexit,
})
AddStategraphState("tallbird",State{
        name = "hop_cancelhop",
        tags = {"nopredict", "nomorph", "nosleep", "busy"},

        onenter = function(inst)
			if fns and fns.cancelhop_onenter then
				fns.cancelhop_onenter(inst)
			end
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation(FunctionOrValue(anims.pst, inst) or "jump_pst", false)
        end,

        events = {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },

		onexit = fns and fns.cancelhop_onexit,
})
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

-- require("stategraphs/commonstates")
AddStategraphEvent("tallbird", EventHandler("onhop",
        function(inst)
            if (inst.components.health == nil or not inst.components.health:IsDead()) and inst.sg:HasAnyStateTag("moving", "idle") then
                if not inst.sg:HasStateTag("jumping") then
                    if inst.components.embarker and inst.components.embarker.antic and inst:HasTag("swimming") then
                        inst.sg:GoToState("hop_antic")
                    else
                        inst.sg:GoToState("hop_pre")
                    end
                end
            elseif inst.components.embarker then
                inst.components.embarker:Cancel()
            end
        end))

AddStategraphPostInit("smallbird", function(sg)
    local hatch_fn = sg.states["hatch"].onenter
    sg.states["hatch"].onenter = function (inst)
        if hatch_fn then hatch_fn(inst) end
        local shell1 = SpawnPrefab("tallbird_eggshell1")
        local shell2 = SpawnPrefab("tallbird_eggshell2")
        if inst.components.lootdropper then
            inst.components.lootdropper:FlingItem(shell1)
            inst.components.lootdropper:FlingItem(shell2)
        end
    end
end)

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

local BIRD_NAMED = Action()
BIRD_NAMED.id = "BIRD_NAMED"
BIRD_NAMED.strfn = function (act)
    return "NAMED"
end
-- BIRD_NAMED.priority = 20
BIRD_NAMED.fn = function (act)
    local obj = act.invobject
    local target = act.target
    local doer = act.doer
    if obj.components.bird_named then
        return obj.components.bird_named:Named(obj,target,doer)
    end
    return false
end
AddAction(BIRD_NAMED)
STRINGS.ACTIONS.BIRD_NAMED = {
    NAMED = "命名"
}

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.BIRD_NAMED, "give"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.BIRD_NAMED, "give"))

AddComponentAction("USEITEM", "bird_named", function(inst, doer, target, actions, right)
    if target:HasTag("lovely_bird") and doer and inst:HasTag("tallbird_eggshell") then
        table.insert(actions, ACTIONS.BIRD_NAMED)
    end
end)

local function PlayMiningFX(inst, target, nosound)
    if target ~= nil and target:IsValid() then
        local frozen = target:HasTag("frozen")
        local moonglass = target:HasAnyTag("moonglass", "LunarBuildup")
        local crystal = target:HasTag("crystal")
        if target.Transform ~= nil then
            SpawnPrefab(
                (frozen and "mining_ice_fx") or
                (moonglass and "mining_moonglass_fx") or
                (crystal and "mining_crystal_fx") or
                "mining_fx"
            ).Transform:SetPosition(target.Transform:GetWorldPosition())
        end
        if not nosound and inst.SoundEmitter ~= nil then
            inst.SoundEmitter:PlaySound(
                (frozen and "dontstarve_DLC001/common/iceboulder_hit") or
                ((moonglass or crystal) and "turnoftides/common/together/moon_glass/mine") or
                "dontstarve/wilson/use_pick_rock"
            )
        end
    end
end

local function HarvestPickable( ent, doer)
        if ent.components.pickable.picksound ~= nil then
            doer.SoundEmitter:PlaySound(ent.components.pickable.picksound)
        end

        local success, loot = ent.components.pickable:Pick(TheWorld)

        if loot ~= nil then
            for i, item in ipairs(loot) do
                Launch(item, doer, 1.5)
            end
        end
    end

local function IsEntityInFront( entity, doer_rotation, doer_pos)
        local facing = Vector3(math.cos(-doer_rotation / RADIANS), 0 , math.sin(-doer_rotation / RADIANS))
        return IsWithinAngle(doer_pos, facing, TUNING.VOIDCLOTH_SCYTHE_HARVEST_ANGLE_WIDTH, entity:GetPosition())
    end

    local HARVEST_MUSTTAGS  = {"pickable"}
    local HARVEST_CANTTAGS  = {"INLIMBO", "FX"}
    local HARVEST_ONEOFTAGS = {"plant", "lichen", "oceanvine", "kelp"}

    local function DoScythe( target, doer)
        if target.components.pickable ~= nil and target.components.pickable:CanBePicked() and not doer._tallbird_mount_aoe_leg then
            HarvestPickable(target, doer)
            return
        end
        if target.components.pickable ~= nil then
            local doer_pos = doer:GetPosition()
            local x, y, z = doer_pos:Get()

            local doer_rotation = doer.Transform:GetRotation()

            local ents = TheSim:FindEntities(x, y, z, TUNING.VOIDCLOTH_SCYTHE_HARVEST_RADIUS, HARVEST_MUSTTAGS, HARVEST_CANTTAGS, HARVEST_ONEOFTAGS)
            for _, ent in pairs(ents) do
                if ent:IsValid() and ent.components.pickable ~= nil then
                    if IsEntityInFront(ent, doer_rotation, doer_pos) then
                        HarvestPickable(ent, doer)
                    end
                end
            end
        end
    end

local function DoMountedToolWork(act, workaction)
    local target = act.target
    local doer = act.doer
    if target == nil or doer == nil then return false end

    if target.components.workable == nil or
       not target.components.workable:CanBeWorked() or
       target.components.workable:GetWorkAction() ~= workaction then
        return false
    end

    local rider = doer.replica.rider
    local mount = rider and rider:GetMount()
    if mount == nil or not mount:HasTag("tallbird") then
        return false
    end

    local numworks_bird =
        (doer.components.worker ~= nil and doer.components.worker:GetEffectiveness(workaction))
        or 1
    local numworks = 0
    local tool = doer.components.inventory and doer.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) or nil
    if tool and tool.components.tool then
        numworks = tool.components.tool:CanDoAction(workaction) and
        tool.components.tool:GetEffectiveness(workaction)
    end
    if tool and not tool.components.tool then
        numworks = 0.5
        if tool.components.finiteuses and not doer._tallbird_mount_aoe_leg then
            tool.components.finiteuses:Use(1)
        end
        tool = nil
    elseif tool and tool.components.finiteuses and not doer._tallbird_mount_aoe_leg and tool.components.tool:CanDoAction(workaction) then
        tool.components.finiteuses:OnUsedAsItem(workaction, doer, target)
    elseif tool and not tool.components.tool:CanDoAction(workaction) then
        numworks = 0.5
        if tool.components.finiteuses and not doer._tallbird_mount_aoe_leg then
            tool.components.finiteuses:Use(1)
        end
        tool = nil
    end

    if doer.components.workmultiplier ~= nil then
        numworks = numworks * doer.components.workmultiplier:GetMultiplier(workaction)
    end

    local recoil
    if not doer._tallbird_mount_aoe_leg then
        recoil, numworks = target.components.workable:ShouldRecoil(doer, tool, numworks)
    end

    if doer.components.workmultiplier ~= nil then
        numworks = doer.components.workmultiplier:ResolveSpecialWorkAmount(workaction, target, nil, numworks, recoil)
    end

    -- 触发反冲相关事件
    -- if recoil and doer.sg ~= nil and doer.sg.statemem.recoilstate ~= nil then
    --     doer:PushEventImmediate("recoil_off", { target = target })
    --     if numworks == 0 then
    --         doer:PushEvent("tooltooweak", { workaction = workaction })
    --     end
    -- end
    
    if target.components.workable.action == ACTIONS.MINE then
        PlayMiningFX(doer,target)
    end
    if target.components.workable.action == ACTIONS.DIG then
        doer.SoundEmitter:PlaySound("dontstarve/wilson/dig")
    end
    if target.components.workable.action == ACTIONS.HAMMER then
       doer.SoundEmitter:PlaySound(doer.sg.statemem.action ~= nil and doer.sg.statemem.action.invobject ~= nil and doer.sg.statemem.action.invobject.hit_skin_sound or "dontstarve/wilson/hit") 
    end
    if not doer._tallbird_mount_aoe_leg then
        numworks_bird = numworks + numworks_bird
    end
    
    target.components.workable:WorkedBy_Internal(doer, numworks_bird)
    return true
end

local BIRD_CHOP = Action()
BIRD_CHOP.id = "BIRD_CHOP"
BIRD_CHOP.strfn = function (act)
    return "BIRD_CHOP"
end
-- BIRD_CHOP.priority = 20
BIRD_CHOP.mount_valid =true
BIRD_CHOP.fn = function (act)
    return DoMountedToolWork(act, ACTIONS.CHOP)
end
AddAction(BIRD_CHOP)
STRINGS.ACTIONS.BIRD_CHOP = {
    BIRD_CHOP = "砍"
}

local BIRD_MINE = Action()
BIRD_MINE.id = "BIRD_MINE"
BIRD_MINE.strfn = function (act)
    return "BIRD_MINE"
end
-- BIRD_MINE.priority = 20
BIRD_MINE.mount_valid =true
BIRD_MINE.fn = function (act)
    return DoMountedToolWork(act, ACTIONS.MINE)
end
AddAction(BIRD_MINE)
STRINGS.ACTIONS.BIRD_MINE = {
    BIRD_MINE = "开采"
}

local BIRD_DIG = Action()
BIRD_DIG.id = "BIRD_DIG"
BIRD_DIG.strfn = function (act)
    return "BIRD_DIG"
end
-- BIRD_DIG.priority = 20
BIRD_DIG.mount_valid =true
BIRD_DIG.fn = function (act)
    return DoMountedToolWork(act, ACTIONS.DIG)
end
AddAction(BIRD_DIG)
STRINGS.ACTIONS.BIRD_DIG = {
    BIRD_DIG = "挖"
}

local BIRD_HAMMER = Action()
BIRD_HAMMER.id = "BIRD_HAMMER"
BIRD_HAMMER.strfn = function (act)
    return "BIRD_HAMMER"
end
-- BIRD_HAMMER.priority = 20
BIRD_HAMMER.mount_valid =true
BIRD_HAMMER.fn = function (act)
    return DoMountedToolWork(act, ACTIONS.HAMMER)
end
AddAction(BIRD_HAMMER)
STRINGS.ACTIONS.BIRD_HAMMER = {
    BIRD_HAMMER = "敲"
}

local BIRD_SCYTHE = Action()
BIRD_SCYTHE.id = "BIRD_SCYTHE"
BIRD_SCYTHE.strfn = function (act)
    return "BIRD_SCYTHE"
end
BIRD_SCYTHE.priority = 20
BIRD_SCYTHE.mount_valid =true
BIRD_SCYTHE.fn = function (act)
    local target = act.target
    local doer = act.doer
    if target == nil or doer == nil then return false end

    local rider = doer.replica.rider
    local mount = rider and rider:GetMount()
    if mount == nil or not mount:HasTag("tallbird") then
        return false
    end

    if target.components.pickable == nil or not target.components.pickable:CanBePicked() then
        return false
    end

    DoScythe(target, doer)
    return true
end
AddAction(BIRD_SCYTHE)
STRINGS.ACTIONS.BIRD_SCYTHE = {
    BIRD_SCYTHE = "收割"
}

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.BIRD_CHOP, "attack"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.BIRD_CHOP, "attack"))
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.BIRD_MINE, "attack"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.BIRD_MINE, "attack"))
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.BIRD_DIG, "attack"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.BIRD_DIG, "attack"))
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.BIRD_HAMMER, "attack"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.BIRD_HAMMER, "attack"))
AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.BIRD_SCYTHE, "attack"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.BIRD_SCYTHE, "attack"))

AddComponentAction("SCENE", "workable", function(inst, doer, actions, right)
    local tallbird = doer.replica.rider:IsRiding() and doer.replica.rider:GetMount()
    if inst:HasTag("CHOP_workable") and doer:HasTag("player") and tallbird and tallbird:HasTag("tallbird") then
        table.insert(actions, ACTIONS.BIRD_CHOP)
    end
	if inst:HasTag("MINE_workable") and doer:HasTag("player") and tallbird and tallbird:HasTag("tallbird") then
        table.insert(actions, ACTIONS.BIRD_MINE)
    end
    if right and inst:HasTag("DIG_workable") and doer:HasTag("player") and tallbird and tallbird:HasTag("tallbird") then
        table.insert(actions, ACTIONS.BIRD_DIG)
    end
    if right and inst:HasTag("HAMMER_workable") and doer:HasTag("player") and tallbird and tallbird:HasTag("tallbird") then
        table.insert(actions, ACTIONS.BIRD_HAMMER)
    end
end)

local SCYTHE_ONEOFTAGS = {"plant", "lichen", "oceanvine", "kelp"}

local function IsValidScytheTarget(target)
    return target:HasOneOfTags(SCYTHE_ONEOFTAGS)
end

AddComponentAction("SCENE", "pickable", function(inst, doer, actions, right)
    local tallbird = doer.replica.rider:IsRiding() and doer.replica.rider:GetMount()
    if right and IsValidScytheTarget(inst) and tallbird and tallbird:HasTag("tallbird") and inst:HasTag("pickable") then
        table.insert(actions, ACTIONS.BIRD_SCYTHE)
    end
end)

local PICKUP_TARGET_EXCLUDE_TAGS = { "catchable", "mineactive", "intense" }
AddComponentPostInit("playercontroller",function(self)
    local action = nil
    local old_GetActionButtonAction = self.GetActionButtonAction
    self.GetActionButtonAction = function(self, force_target)
		if self.inst.replica.rider ~= nil and self.inst.replica.rider:IsRiding() then
			local mount = self.inst.replica.rider:GetMount()
			if mount:HasTag("tallbird") then
		        local pickup_tags =
		        {
				"CHOP_workable",
				"MINE_workable",
		        }
		        local x, y, z = self.inst.Transform:GetWorldPosition()
		        local ents = TheSim:FindEntities(x, y, z, self.directwalking and 3 or 6, nil, PICKUP_TARGET_EXCLUDE_TAGS, pickup_tags)
		        for i, v in ipairs(ents) do
		            if v ~= self.inst and v.entity:IsVisible() and CanEntitySeeTarget(self.inst, v) then
		            	if v:HasTag("CHOP_workable") then
							action=ACTIONS.BIRD_CHOP
						end
						if v:HasTag("MINE_workable") then
							action=ACTIONS.BIRD_MINE
						end
		                if action ~= nil then
		                    return BufferedAction(self.inst, v, action)
		                end
		            end
		        end
		    end
		end
		return old_GetActionButtonAction(self,force_target)
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