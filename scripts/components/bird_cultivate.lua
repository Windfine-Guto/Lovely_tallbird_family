local Bird_cultivate = Class(function(self, inst)
    self.inst = inst
    self.nodeath = false
    self.wild = true
    self.plannar = false
    self.gift = false
    self.follow = true
    self.nogrow = false
end,
nil,
{
    
})
local seed={"seeds","carrot_seeds","corn_seeds","potato_seeds","tomato_seeds",
            "asparagus_seeds","eggplant_seeds","pumpkin_seeds","watermelon_seeds",
            "dragonfruit_seeds","durian_seeds","garlic_seeds","onion_seeds","pepper_seeds",
            "pomegranate_seeds"}
local function Small_OnTimerDone2(inst)
    if inst.components.lootdropper then
        local random_gifts = math.random(1,10)
        if random_gifts>1 then
            inst.components.worldsettingstimer:StartTimer("ancienttree_seed_spawngifts", 7 * TUNING.TOTAL_DAY_TIME)
            return
        end
    local gift = SpawnPrefab("ancienttree_seed")
    inst.components.lootdropper:FlingItem(gift)
    inst.components.worldsettingstimer:StartTimer("ancienttree_seed_spawngifts", 7 * TUNING.TOTAL_DAY_TIME)
    end
end
local function Small_OnTimerDone(inst)
    if inst.components.lootdropper then
        local random_seed = seed[math.random(#seed)]
        local random_seednumber = math.random(2,5)
        for i = 1,random_seednumber  do
            local dropped_seed = SpawnPrefab(random_seed)
            inst.components.lootdropper:FlingItem(dropped_seed)
        end
    end
    inst.components.worldsettingstimer:StartTimer("seed_spawngifts", 1.5 * TUNING.TOTAL_DAY_TIME)
end
local function Tall_OnTimerDone2(inst)
    if inst.components.lootdropper then
        local random_gifts = math.random(1,10)
        if random_gifts>2 then
            inst.components.worldsettingstimer:StartTimer("tall_ancienttree_seed_spawngift", 3 * TUNING.TOTAL_DAY_TIME)
            return
        end
    local gift = SpawnPrefab("ancienttree_seed")
    inst.components.lootdropper:FlingItem(gift)
    inst.components.worldsettingstimer:StartTimer("tall_ancienttree_seed_spawngift", 3 * TUNING.TOTAL_DAY_TIME)
    end
end
local function Tall_OnTimerDone(inst)
    if inst.components.lootdropper then
        local dropped_gifts = SpawnPrefab("tallbirdegg")
        inst.components.lootdropper:FlingItem(dropped_gifts)
    end
    inst.components.worldsettingstimer:StartTimer("tall_tallbirdegg_spawngifts", 2 * TUNING.TOTAL_DAY_TIME)
end
local function OnHealthDelta(inst, oldpercent, newpercent)
    if newpercent < 0.2 then
        if inst.components.combat then
            inst:AddTag("noattack")
            inst:AddTag("notarget")
            inst.components.combat.canattack=false
            local x, y, z = inst.Transform:GetWorldPosition()
            local ents = TheSim:FindEntities(x, y, z, 5, {"_combat"})
            for _, ent in ipairs(ents) do
                if ent.components.combat and ent.components.combat.target == inst then
                    ent.components.combat:DropTarget()
                end
            end
        end
        if newpercent < 0.1 then
            inst.components.health:SetPercent(0.1)
        end
    elseif newpercent==1 then
        inst.components.combat.canattack=true
        inst:RemoveTag("noattack")
        inst:RemoveTag("notarget")
    end
end

local RETARGET_MUST_TAGS = { "_combat", "_health" }
local RETARGET_CANT_TAGS_HOME={"tallbird","teenbird","smallbird","bird_friend"}
local RETARGET_CANT_TAGS = { "tallbird","teenbird","smallbird","player",
"glommer","chester","companion","beefalo","hutch","abigail" }
local RETARGET_ONEOF_TAGS = { "monster","hostile" }
local RETARGET_ANIMAL_ONEOF_TAGS = {  "monster","hostile" }
local function Retarget(inst)
    local function IsValidTarget(guy)
        return not guy.components.health:IsDead()
            and inst.components.combat:CanTarget(guy)
            and (not inst:HasTag("smallbird") or inst:HasTag("companion"))
    end
    return --Threat to nest
        inst.components.homeseeker ~= nil and
        inst.components.homeseeker:HasHome() and
        FindEntity(
            inst.components.homeseeker.home,
            SpringCombatMod(TUNING.TALLBIRD_DEFEND_DIST/2),
            IsValidTarget,
            RETARGET_MUST_TAGS,
            RETARGET_CANT_TAGS,
            RETARGET_ANIMAL_ONEOF_TAGS)
        or
        FindEntity(
            inst,
            SpringCombatMod(TUNING.TALLBIRD_TARGET_DIST*2),
            IsValidTarget,
            RETARGET_MUST_TAGS,
            RETARGET_CANT_TAGS,
            RETARGET_ONEOF_TAGS)
end

function Bird_cultivate:Updata()
    if self.plannar==true then
        if self.inst.components.planarentity==nil then
            self.inst:AddComponent("planarentity")
        end
        if self.inst.components.planardamage == nil then
            self.inst:AddComponent("planardamage")
        end
        self.inst.components.planardamage:SetBaseDamage(20)
        if not self.inst:HasTag("bird_plannared") then
            self.inst:AddTag("bird_plannared")
        end
    end
    if self.nogrow==true and self.inst.components.growable then
        self.inst:RemoveComponent("growable")
        if not self.inst:HasTag("nogrow") then
            self.inst:AddTag("nogrow")
        end
    end
    if self.wild==true then
        return
    end
    if self.inst:HasTag("tallbird") and self.inst.components.combat then
        self.inst.components.combat:SetRetargetFunction(1.5, Retarget)
    end
    if self.follow==true then
        if not self.inst:HasTag("bird_follower") then
            self.inst:AddTag("bird_follower")
        end
        self.inst:RemoveTag("bird_leaver")
    else
        if not self.inst:HasTag("bird_leaver") then
            self.inst:AddTag("bird_leaver")
        end
        self.inst:RemoveTag("bird_follower")
    end
    if not self.inst:HasTag("lovely_bird") then
        self.inst:AddTag("lovely_bird")
    end
    
    if self.inst.components.combat then
        self.inst.components.combat:SetNoAggroTags({"bird_friend","bird_family", "smallbird","teenbird","tallbird"})
    end
    if self.inst.components.follower then
        self.inst.components.follower.keepdeadleader = true
        self.inst.components.follower:KeepLeaderOnAttacked()
    end
    if self.nodeath==true and self.inst.components.health then
        self.inst.components.health:SetMinHealth(5)
        self.inst.components.health.ondelta = OnHealthDelta
    end
    if self.gift==true and self.inst:HasTag("smallbird") then
        if not self.inst.components.worldsettingstimer then
            self.inst:AddComponent("worldsettingstimer")
        end
        if not self.inst.components.worldsettingstimer:TimerExists("seed_spawngifts") then
            self.inst.components.worldsettingstimer:AddTimer(
            "seed_spawngifts",
            1.5 * TUNING.TOTAL_DAY_TIME,
            true,
            Small_OnTimerDone
            )
        end
        if not self.inst.components.worldsettingstimer:TimerExists("ancienttree_seed_spawngifts") then
            self.inst.components.worldsettingstimer:AddTimer(
            "ancienttree_seed_spawngifts",
            7 * TUNING.TOTAL_DAY_TIME,
            true,
            Small_OnTimerDone2
            )
        end
        if not self.inst.components.worldsettingstimer:ActiveTimerExists("seed_spawngifts") then
            self.inst.components.worldsettingstimer:StartTimer("seed_spawngifts", 1.5 * TUNING.TOTAL_DAY_TIME)
        end
        if not self.inst.components.worldsettingstimer:ActiveTimerExists("ancienttree_seed_spawngifts") then
            self.inst.components.worldsettingstimer:StartTimer("ancienttree_seed_spawngifts", 7 * TUNING.TOTAL_DAY_TIME)
        end
    elseif self.gift==true and self.inst:HasTag("tallbird") then
        if not self.inst.components.worldsettingstimer then
            self.inst:AddComponent("worldsettingstimer")
        end
        if not self.inst.components.worldsettingstimer:TimerExists("tall_tallbirdegg_spawngifts") then
            self.inst.components.worldsettingstimer:AddTimer(
            "tall_tallbirdegg_spawngifts",
            2 * TUNING.TOTAL_DAY_TIME,
            true,
            Tall_OnTimerDone
            )
        end
        if not self.inst.components.worldsettingstimer:TimerExists("tall_ancienttree_seed_spawngift") then
            self.inst.components.worldsettingstimer:AddTimer(
            "tall_ancienttree_seed_spawngift",
            3 * TUNING.TOTAL_DAY_TIME,
            true,
            Tall_OnTimerDone2
            )
        end
        if not self.inst.components.worldsettingstimer:ActiveTimerExists("tall_tallbirdegg_spawngifts") then
            self.inst.components.worldsettingstimer:StartTimer("tall_tallbirdegg_spawngifts", 2 * TUNING.TOTAL_DAY_TIME)
        end
        if not self.inst.components.worldsettingstimer:ActiveTimerExists("tall_ancienttree_seed_spawngift") then
            self.inst.components.worldsettingstimer:StartTimer("tall_ancienttree_seed_spawngift", 3 * TUNING.TOTAL_DAY_TIME)
        end
    end
end

function Bird_cultivate:SetLeader(leader)
    if self.inst.components.follower and not self.inst.components.follower.leader then
        self.inst.components.follower:SetLeader(leader)
        self.follow=true
    end
end

function Bird_cultivate:NoLeader(doer)
    if self.inst.components.follower and self.inst.components.follower.leader==doer then
        self.inst.components.follower:SetLeader(nil)
        self.follow=false
    end
end

function Bird_cultivate:OnSave()
    return {
        wild = self.wild,
        plannar = self.plannar,
        follow = self.follow,
        nogrow = self.nogrow,
    }
end
function Bird_cultivate:OnLoad(data)
    if data~=nil then
        self.wild = data.wild
        self.plannar = data.plannar
        self.follow = data.follow
        self.nogrow = data.nogrow
    end
    self:Updata()
end

return Bird_cultivate