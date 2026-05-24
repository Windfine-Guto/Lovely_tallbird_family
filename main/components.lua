local PICKUP_TARGET_EXCLUDE_TAGS = { "catchable", "mineactive", "intense" }
local modid = 'lovely_tallbird_family'

AddComponentPostInit("playercontroller", function(self)
    local fn_name = self.TryAOECharging and "TryAOECharging" or "TryAOETargeting"
    local old_fn = self[fn_name]
    self[fn_name] = function(self, ...)
        if old_fn(self, ...) then
            return true
        end

        if  TUNING.TALLBIRD_SELECT_MODE==2 then
            return
        end
        
        local player = self.inst
        if not player or not player.HUD then
            return
        end

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

    local old_GetActionButtonAction = self.GetActionButtonAction
    self.GetActionButtonAction = function(self, force_target)
        local nearest_dist = math.huge
        local nearest_action = nil

        local default_action = old_GetActionButtonAction(self, force_target)
        if default_action and default_action.action ~= ACTIONS.WALKTO and default_action.action ~= ACTIONS.ATTACK then
            local target = default_action.target
            if target and target:IsValid() then
                local dist = self.inst:GetDistanceSqToInst(target)
                nearest_dist = dist
                nearest_action = default_action
            end
        end

        if self.inst.replica.rider and self.inst.replica.rider:IsRiding() then
            local mount = self.inst.replica.rider:GetMount()
            if mount:HasTag("tallbird") then
                local pickup_tags = { "CHOP_workable", "MINE_workable" }
                local x, y, z = self.inst.Transform:GetWorldPosition()
                local ents = TheSim:FindEntities(x, y, z, self.directwalking and 3 or 6, nil, PICKUP_TARGET_EXCLUDE_TAGS, pickup_tags)

                for i, v in ipairs(ents) do
                    if v ~= self.inst and v.entity:IsVisible() and CanEntitySeeTarget(self.inst, v) then
                        local action = nil
                        if v:HasTag("CHOP_workable") then
                            action = ACTIONS.BIRD_CHOP
                        elseif v:HasTag("MINE_workable") then
                            action = ACTIONS.BIRD_MINE
                        end

                        if action then
                            local dist = self.inst:GetDistanceSqToInst(v)
                            if dist < nearest_dist then
                                nearest_dist = dist
                                nearest_action = BufferedAction(self.inst, v, action)
                            end
                        end
                    end
                end
            end
        end

        return nearest_action or default_action
    end
end)

local NOTAGS = {'INLIMBO','notarget','noattack','player','companion','abigail','glommer','friendlyfruitfly'
,"chester","hutch", "playerghost","DECOR", "FX" ,"structure","wall"}
local function playerdamage(inst,data)
	local target=data.target
	if not target:IsValid() or not target.components or not target.components.combat then
        return
    end

    if inst._tallbird_mount_aoe_leg==true then
        if inst.components.combat then
            inst.components.combat:DoAreaAttack(target, 4, nil, nil,
nil, NOTAGS)
        end
    else
        if inst.components.inventory ~= nil then
            local weapon = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if inst.components.combat then
                if weapon==nil or weapon.components.weapon == nil then

                else
                    inst.components.combat:DoAttack(target,weapon, nil, nil, 1)
                end
            end
        end
    end
end

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
            self.inst:ListenForEvent("tallbird_attack",playerdamage)
            if GetModConfigData(modid..'_tallbirdwaterwalk') then
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
            if target:HasTag("bird_planared") and not target:HasTag("toughworker") then
                inst:AddTag("toughworker")
            end
        end
    end
    function self:ActualDismount(...)
        original_ActualDismount(self,...)
        if self.inst:HasTag("tallbird_mount") then
            self.inst:RemoveEventCallback("tallbird_attack",playerdamage)
            self.inst.components.locomotor:RemoveExternalSpeedMultiplier(self.inst,"tallbird_speed")
            if GetModConfigData(modid..'_tallbirdwaterwalk') then
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
---遮阴效果
AddComponentPostInit("sheltered", function(self)
    local old_setsheltered = self.SetSheltered
    local SHELTERED_MUST_TAGS = { "tallbird" }
    local SHELTERED_CANT_TAGS = { "FX", "NOCLICK", "DECOR", "INLIMBO", "stump", "burnt" }
    function self:SetSheltered(issheltered, level)
        local x, y, z = self.inst.Transform:GetWorldPosition()
        local num_sheltered = TheSim:CountEntities(x, y, z, 3, SHELTERED_MUST_TAGS, SHELTERED_CANT_TAGS) or 0
        if num_sheltered<=0 then
            return old_setsheltered(self,issheltered,level)
        end
        level = level or 1
        level = level<2 and num_sheltered>1 and 2 or level
        if self.mounted and level < 2 then
            issheltered = false
        end
        self.sheltered_level = level
        if not issheltered then
            if self.presheltered then
                self.presheltered = false
                self.inst.replica.sheltered:StopSheltered()
            end
            if self.sheltered then
                self.sheltered = false
                self.inst:PushEvent("sheltered", { sheltered=false, level=self.sheltered_level })
            end
        elseif not self.presheltered then
            self.presheltered = true
            self.inst.replica.sheltered:StartSheltered()
        elseif not self.sheltered and self.inst.replica.sheltered:IsSheltered() then
            self.sheltered = true
            self.inst:PushEvent("sheltered", { sheltered=true, level=self.sheltered_level })
            if self.inst.components.talker ~= nil
                and self.announcecooldown <= 0 and (TheWorld.state.israining and self.inst.components.rainimmunity == nil or GetLocalTemperature(self.inst) >= TUNING.OVERHEAT_TEMP - 5) then
                self.inst.components.talker:Say(GetString(self.inst, "ANNOUNCE_TALLBIRD_SHELETERED"))
                self.announcecooldown = TUNING.TOTAL_DAY_TIME
            end
        end
    end
end)

AddComponentPostInit("sleeper", function(self)
    local old_gotosleep = self.GoToSleep
    self.GoToSleep = function(sleeptime)
        if self.inst:HasTag("planar_buff_nosleep") then
            return self:WakeUp()
        end
        return old_gotosleep(sleeptime)
    end
end)

local DAMAGE_ONEOF_TAGS = { "_combat", "pickable", "NPC_workable", "CHOP_workable", "HAMMER_workable", "MINE_workable", "DIG_workable" }
local function Tallbird_Trample(inst,targets)
    if inst:HasTag("tallbird_mount") then
        local x,y,z = inst.Transform:GetWorldPosition()
        for _, v in pairs(TheSim:FindEntities(x, y or 0, z, 2.5, nil, NOTAGS, DAMAGE_ONEOF_TAGS)) do
            if not targets[v] and v:IsValid() and
                not (v.components.health ~= nil and v.components.health:IsDead()) then
                local isworkable = false
                if v.components.workable ~= nil then
                    local work_action = v.components.workable:GetWorkAction()
                    isworkable =
                        (   work_action == nil and v:HasTag("NPC_workable") ) or
                        (   v.components.workable:CanBeWorked() and
                            (   work_action == ACTIONS.CHOP or
                                work_action == ACTIONS.HAMMER or
                                work_action == ACTIONS.MINE or
                                (   work_action == ACTIONS.DIG and
                                    v.components.spawner == nil and
                                    v.components.childspawner == nil and v:HasTag("stump")
                                )
                            )
                        )
                end
                if isworkable then
                    local x1, y1, z1 = v.Transform:GetWorldPosition()
                    SpawnPrefab("collapse_small").Transform:SetPosition(x1, y1, z1)
                    targets[v] = true
                    v.components.workable:Destroy(inst)

                    if v:HasTag("stump") then
                        v.components.workable:WorkedBy_Internal(inst, 1)
                    end
                elseif v.components.pickable ~= nil
                        and v.components.pickable:CanBePicked()
                        and not v:HasTag("intense") and v.prefab~="tallbirdnest" and v.prefab~="new_tallbirdnest" then
                    targets[v] = true
                    local success, loots = v.components.pickable:Pick(inst)
                    if loots then
                        for i, v in ipairs(loots) do
                            targets[v] = true
                            Launch(v, inst, 0.2)
                        end
                    end
                elseif v.components.combat == nil and v.components.health ~= nil then
                    targets[v] = true
                elseif inst.components.combat:CanTarget(v) then
                    targets[v] = true
                    inst.components.combat:DoAttack(v)
                end
            end
        end
    end
end

AddComponentPostInit("joustsource", function(self)
    local old_CheckCollision = self.CheckCollision
    function self:CheckCollision (inst, targets)
        old_CheckCollision(self,inst,targets)
        local new_targets = inst.sg.statemem.joustdata and inst.sg.statemem.joustdata.tallbird_targets
        Tallbird_Trample(inst, new_targets)
    end
end)

---兼容行为学队列
AddComponentPostInit("actionqueuer", function(self)
    if AddActionQueuerActionList then
		AddActionQueuerActionList("noworkdelay", "BIRD_CHOP", "BIRD_MINE", "BIRD_DIG","BIRD_HAMMER")
    end
    if AddActionQueuerAction then
        AddActionQueuerAction("rightclick","BIRD_DIG",function (target)
            return target:HasTag("stump") or target.prefab=="red_mushroom"
            or target.prefab=="blue_mushroom" or target.prefab=="green_mushroom"
        end)
        AddActionQueuerAction("allclick","BIRD_CHOP",function (target)
            local attack_mode = "tallbird"
            if self.inst._tallbird_mount_aoe_leg == true then
                self.inst._tallbird_mount_aoe_leg = false
                SendModRPCToServer(MOD_RPC[attack_mode..'attack'][attack_mode..'attack'],self.inst._tallbird_mount_aoe_leg)
            end
            return true
        end)
        AddActionQueuerAction("allclick","BIRD_MINE",function (target)
            local attack_mode = "tallbird"
            if self.inst._tallbird_mount_aoe_leg == true then
                self.inst._tallbird_mount_aoe_leg = false
                SendModRPCToServer(MOD_RPC[attack_mode..'attack'][attack_mode..'attack'],self.inst._tallbird_mount_aoe_leg)
            end
            return true
        end)
        AddActionQueuerAction("rightclick","BIRD_HAMMER",function (target)
            local attack_mode = "tallbird"
            if self.inst._tallbird_mount_aoe_leg == true then
                self.inst._tallbird_mount_aoe_leg = false
                SendModRPCToServer(MOD_RPC[attack_mode..'attack'][attack_mode..'attack'],self.inst._tallbird_mount_aoe_leg)
            end
            return true
        end)
        AddActionQueuerAction("rightclick","BIRD_SCYTHE",function (target)
            local attack_mode = "tallbird"
            if self.inst._tallbird_mount_aoe_leg == false then
                self.inst._tallbird_mount_aoe_leg = true
                SendModRPCToServer(MOD_RPC[attack_mode..'attack'][attack_mode..'attack'],self.inst._tallbird_mount_aoe_leg)
            end
            return true
        end)
        AddActionQueuerAction("rightclick","BIRD_COLLECT",function (target)
            local attack_mode = "tallbird"
            if self.inst._tallbird_mount_aoe_leg == false then
                self.inst._tallbird_mount_aoe_leg = true
                SendModRPCToServer(MOD_RPC[attack_mode..'attack'][attack_mode..'attack'],self.inst._tallbird_mount_aoe_leg)
            end
            return true
        end)
    end
end)