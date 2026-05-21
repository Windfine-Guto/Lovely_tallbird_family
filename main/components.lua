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
                elseif weapon.components.weapon == nil then
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
            self.inst:RemoveEventCallback("onhitother",playerdamage)
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
