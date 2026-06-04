local clockwork_common = require("prefabs/clockwork_common")
require("stategraphs/commonstates")

local events=
{
	EventHandler("doroll", function(inst, attacker)
		inst.Physics:SetMass(1)
		inst.Physics:SetDamping(0)
		inst.Physics:SetCollisionGroup(COLLISION.ITEMS)
		inst.Physics:SetCollisionMask(
			COLLISION.WORLD,
			COLLISION.OBSTACLES,
			COLLISION.SMALLOBSTACLES)

		inst.sg:GoToState("roll_pre", attacker)
	end),
}

local function Sound(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	return TheWorld.Map:IsOceanAtPoint(x, 0, z) and "turnoftides/common/together/water/swim/walk_water_med" or "tallbird_egg_oversized/tallbird_egg_oversized/eggroll-"..math.random(1,5)
end

local function AreDifferentPlatforms(inst, target)
    if inst.components.locomotor.allow_platform_hopping then
        return inst:GetCurrentPlatform() ~= target:GetCurrentPlatform()
    end
    return false
end

local LANCE_PADDING = 0.6
local JOUSTING_TAGS = { "jousting" }

local function should_collide(guy, inst)
	return DiffAngle(inst.Transform:GetRotation(), guy.Transform:GetRotation()) > 44
end

local function Collided(inst, target)
	inst.components.lootdropper:DropLoot()
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst:Remove()

	local victim = SpawnPrefab("smallbird")
	target:PushEvent("killed",{victim = victim,stackmult = 7/6 })
	victim:Remove()
end

local NOTAGS3 = {'INLIMBO','notarget','noattack'
, "playerghost","DECOR", "FX" ,"structure","wall","waxedplant","ancienttree","tallbird_egg_oversized"}
local DAMAGE_ONEOF_TAGS = { "pickable", "NPC_workable", "CHOP_workable", "HAMMER_workable", "MINE_workable", "DIG_workable" }
local function Roll_Trample(inst, target)
    local x,y,z = inst.Transform:GetWorldPosition()
    for _, v in pairs(TheSim:FindEntities(x, y or 0, z, 2.5, nil, NOTAGS3, DAMAGE_ONEOF_TAGS)) do
        if v:IsValid() and
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
                v.components.workable:Destroy(inst)

                if v:HasTag("stump") then
                    if v.components.workable then
                        v.components.workable:WorkedBy_Internal(inst, 1)
                    else
                        v:Remove()
                    end
                end
				Collided(inst,target)
            elseif v.components.pickable ~= nil
                    and v.components.pickable:CanBePicked()
                    and not v:HasTag("intense") and v.prefab~="tallbirdnest" and v.prefab~="new_tallbirdnest" then
                local success, loots = v.components.pickable:Pick(TheWorld)
                if loots then
                    for i, v in ipairs(loots) do
                        Launch(v, inst, 0.2)
                    end
                end
            end
        end
    end
end
local function DoJoustAoe(inst, targets)
	local x, y, z = inst.Transform:GetWorldPosition()

	--lance start and end points (NOTE: 2d vector using x,y,0)
	local p1 = Vector3(0.05, -0.43, 0) --base of lance
	local p2 = Vector3(2.6 - LANCE_PADDING, -0.06, 0) --tip of lance

	--rotate to match our facing
	local theta = -inst.Transform:GetRotation() * DEGREES
	local cos_theta = math.cos(theta)
	local sin_theta = math.sin(theta)
	local tempx = p1.x
	p1.x = x + tempx * cos_theta - p1.y * sin_theta
	p1.y = z + p1.y * cos_theta + tempx * sin_theta
	tempx = p2.x
	p2.x = x + tempx * cos_theta - p2.y * sin_theta
	p2.y = z + p2.y * cos_theta + tempx * sin_theta

	local cx = (p1.x + p2.x) * 0.5
	local cz = (p1.y + p2.y) * 0.5
	local radius = math.sqrt(distsq(p1.x, p1.y, cx, cz))
	local lsq = Dist2dSq(p1, p2)
	local t = GetTime()

	local function should_hit(guy, inst)
		local last_t = targets[guy]
		if last_t == nil or last_t + 0.75 < t then
			local p3 = guy:GetPosition()
			p3.y, p3.z = p3.z, 0 --convert x,0,z -> x,y,0
			local range = LANCE_PADDING + guy:GetPhysicsRadius(0)
			--if DistPointToSegmentXYSq(p3, p1, p2) < range * range then
			--V2C: modified becasue we don't want to hit anything behind the back point
			local dot = (p3.x - p1.x) * (p2.x - p1.x) + (p3.y - p1.y) * (p2.y - p1.y)
			if dot >= 0 then
				dot = dot / lsq
				local dsq =
					dot >= 1 and
					Dist2dSq(p3, p2) or
					Dist2dSq(p3, Vector3(p1.x + dot * (p2.x - p1.x), p1.y + dot * (p2.y - p1.y), 0))
				if dsq < range * range then
					targets[guy] = t
					return true
				end
			end
		end
		return false
	end

	inst.components.combat.ignorehitrange = true
	clockwork_common.FindAOETargetsAtXZ(inst, cx, cz, radius + LANCE_PADDING + 3,
		function(guy, inst)
			if should_hit(guy, inst) then
				if guy:HasTag("jousting") and should_collide(guy, inst) then
					guy:PushEventImmediate("roll_collide")
					inst.components.workable:WorkedBy_Internal(guy, 1)
				else
					inst.components.combat:DoAttack(guy)
					inst.components.workable:WorkedBy_Internal(guy, 1)
					guy:PushEvent("knockback", { knocker = inst, radius = 6.5, forcelanded = true })
				end
			end
		end)
	inst.components.combat.ignorehitrange = false

	local knight_rad = inst:GetPhysicsRadius(0)
	for i, v in ipairs(TheSim:FindEntities(cx, 0, cz, radius + LANCE_PADDING + knight_rad, JOUSTING_TAGS)) do
		if v ~= inst and should_hit(v, inst) and should_collide(v, inst) then
			v:PushEventImmediate("roll_collide")
			inst.components.workable:WorkedBy_Internal(v, 1)
		end
	end

end

local states=
{
	State{
        name = "idle",
        tags = {"idle", "canrotate"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("idle")
        end,

    },
	State{
		name = "roll_pre",
		tags = { "attack", "busy" },

		onenter = function(inst, attacker)
			inst.components.locomotor:StopMoving()
			inst.AnimState:PlayAnimation("egg_roll_pre")
			
			if attacker and attacker:IsValid() then
				inst.sg.statemem.target = attacker
				inst.sg.statemem.maxdelta = 20

				inst.sg.statemem.dir = inst:GetAngleToPoint(attacker.Transform:GetWorldPosition())
			else
				inst.sg.statemem.dir = inst.Transform:GetRotation()
			end

			inst.Transform:SetRotation(math.floor(inst.sg.statemem.dir / 45 + 0.5) * 45)
		end,

		onupdate = function(inst, dt)
			if dt > 0 then
				if inst.sg:HasStateTag("jumping") then
					inst.Physics:SetMotorVelOverride(-9 * inst.components.locomotor:GetSpeedMultiplier(), 0, 0)
				else
					local target = inst.sg.statemem.target
					if target then
						if target:IsValid() then
							local rot = inst.sg.statemem.dir
							local rot1 = inst:GetAngleToPoint(target.Transform:GetWorldPosition())
							local delta = math.clamp(ReduceAngle(rot1 - rot), -inst.sg.statemem.maxdelta, inst.sg.statemem.maxdelta) * math.min(1, dt / FRAMES)
							inst.sg.statemem.maxdelta = math.max(1, inst.sg.statemem.maxdelta - dt / FRAMES)

							--true dir (for movement)
							inst.sg.statemem.dir = rot + delta

							--facing dir snapped to 45s (for hitbox)
							inst.Transform:SetRotation(math.floor(inst.sg.statemem.dir / 45 + 0.5) * 45)
						else
							inst.sg.statemem.target = nil
						end
					end
				end
			end
		end,

		timeline =
		{
			FrameEvent(7, function(inst)
				inst.sg:AddStateTag("jumping")

				local theta = ReduceAngle(inst.sg.statemem.dir - inst.Transform:GetRotation()) * DEGREES
				local speed = 9 * inst.components.locomotor:GetSpeedMultiplier()
				inst.Physics:SetMotorVelOverride(-speed * math.cos(theta), 0, speed * math.sin(theta))
			end),
			FrameEvent(10, function(inst) inst.SoundEmitter:PlaySound(Sound(inst)) end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg.statemem.jousting = true
					inst.sg:GoToState("roll_loop", {
						target = inst.sg.statemem.target,
						dir = inst.sg.statemem.dir,
					})
				end
			end),
		},

		onexit = function(inst)
			if not inst.sg.statemem.jousting then
				inst.Physics:ClearMotorVelOverride()
				inst.Physics:Stop()
			end
		end,
	},

	State{
		name = "roll_loop",
		tags = { "attack", "busy", "jumping" },

		onenter = function(inst, data)
			if not inst.AnimState:IsCurrentAnimation("egg_roll_loop") then
				inst.AnimState:PlayAnimation("egg_roll_loop", true)
			end
			inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
			if data then
				inst.sg.statemem.target = data.target
				inst.sg.statemem.dir = data.dir --true dir (for movement)
				inst.sg.statemem.loops = data.loops or 1
				inst.sg.statemem.targets = data.targets or {}
			else
				inst.sg.statemem.loops = 1
				inst.sg.statemem.targets = {}
			end
			inst:AddTag("jousting")
		end,

		onupdate = function(inst, dt)
			if dt > 0 then
				local rot = inst.sg.statemem.dir
				if rot then
					local target = inst.sg.statemem.target
					if target then
						if target:IsValid() then
							local rot1 = inst:GetAngleToPoint(target.Transform:GetWorldPosition())
							if math.floor(rot / 45 + 0.5) * 45 == math.floor(rot1 / 45 + 0.5) * 45 then
								local delta = math.clamp(ReduceAngle(rot1 - rot), -1, 1) * math.min(1, dt / FRAMES)
								rot = rot + delta
								inst.sg.statemem.dir = rot
							end
						else
							inst.sg.statemem.target = nil
						end
					end

					local theta = ReduceAngle(rot - inst.Transform:GetRotation()) * DEGREES
					local speed = 9 * inst.components.locomotor:GetSpeedMultiplier()
					inst.Physics:SetMotorVelOverride(-speed * math.cos(theta), 0, speed * math.sin(theta))
				end
				DoJoustAoe(inst, inst.sg.statemem.targets)
				Roll_Trample(inst,inst.sg.statemem.target )
			end
		end,

		timeline =
		{
			FrameEvent(0, function(inst)
				if not (inst.sg.laststate and inst.sg.laststate.name == "roll_pre") then
					inst.SoundEmitter:PlaySound(Sound(inst))
				end
			end),
			FrameEvent(15, function(inst) inst.SoundEmitter:PlaySound(Sound(inst)) end),
		},

		ontimeout = function(inst)
			local maxloops = 3
			local loops = inst.sg.statemem.loops
			if loops >= maxloops then
				inst.sg.statemem.stopping = true
				inst.sg:GoToState("roll_pst")
				return
			elseif loops < maxloops - 1 then
				local target = inst.sg.statemem.target
				if target and target:IsValid() and DiffAngle(inst.Transform:GetRotation(), inst:GetAngleToPoint(target.Transform:GetWorldPosition())) < 90 and not AreDifferentPlatforms(inst, target) then
					--target still in front, keep going
					inst.sg.statemem.jousting = true
					inst.sg:GoToState("roll_loop", {
						target = target,
						dir = inst.sg.statemem.dir,
						loops = loops + 1,
						targets = inst.sg.statemem.targets,
					})
					return
				end
			end
			--force end after 1 more loop
			inst.sg.statemem.jousting = true
			inst.sg:GoToState("roll_loop", {
				dir = inst.sg.statemem.dir,
				loops = maxloops,
				targets = inst.sg.statemem.targets,
			})
		end,

		events =
		{
			EventHandler("roll_collide", function(inst)
				inst.sg:GoToState("roll_collide")
			end),
		},

		onexit = function(inst)
			if not (inst.sg.statemem.jousting or inst.sg.statemem.stopping) then
				inst.Physics:ClearMotorVelOverride()
				inst.Physics:Stop()
			end
			if not inst.sg.statemem.jousting then
				inst:RemoveTag("jousting")
			end
		end,
	},

	State{
		name = "roll_pst",
		tags = { "busy", "jumping" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("egg_roll_pst")
			inst.SoundEmitter:PlaySound(Sound(inst))
			local _
			inst.sg.statemem.vx, _, inst.sg.statemem.vz = inst.Physics:GetMotorVel()
			inst.Physics:SetMotorVelOverride(inst.sg.statemem.vx * 0.64, 0, inst.sg.statemem.vz * 0.64)
		end,

		timeline =
		{
			FrameEvent(2, function(inst) inst.Physics:SetMotorVelOverride(inst.sg.statemem.vx * 0.32, 0, inst.sg.statemem.vz * 0.32) end),
			FrameEvent(4, function(inst) inst.Physics:SetMotorVelOverride(inst.sg.statemem.vx * 0.16, 0, inst.sg.statemem.vz * 0.16) end),
			FrameEvent(6, function(inst) inst.Physics:SetMotorVelOverride(inst.sg.statemem.vx * 0.08, 0, inst.sg.statemem.vz * 0.08) end),
			FrameEvent(8, function(inst) inst.Physics:SetMotorVelOverride(inst.sg.statemem.vx * 0.04, 0, inst.sg.statemem.vz * 0.04) end),
			FrameEvent(10, function(inst)
				inst.Physics:ClearMotorVelOverride()
				inst.Physics:Stop()
				inst.sg:RemoveStateTag("jumping")
			end),
			FrameEvent(11, function(inst)
				inst.sg:AddStateTag("caninterrupt")
			end),
			FrameEvent(12, function(inst)
				inst.sg:RemoveStateTag("busy")
			end),
			FrameEvent(14, function(inst)
				inst.Physics:SetMass(0)
				inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
				inst.Physics:SetCollisionMask(
					COLLISION.ITEMS,
					COLLISION.GIANTS)
			end),
		},

		events =
		{
			-- EventHandler("animover", function(inst)
			-- 	if inst.AnimState:AnimDone() then
			-- 		-- inst.sg:GoToState("idle")
			-- 	end
			-- end),
		},

		onexit = function(inst)
			if inst.sg:HasStateTag("jumping") then
				inst.Physics:ClearMotorVelOverride()
				inst.Physics:Stop()
			end
		end,
	},

	State{
		name = "roll_collide",
		tags = { "busy", "jumping", "nosleep" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("egg_roll_pst")
			local _
			inst.sg.statemem.vx, _, inst.sg.statemem.vz = inst.Physics:GetMotorVel()
			inst.Physics:SetMotorVelOverride(inst.sg.statemem.vx * -0.6, 0, inst.sg.statemem.vz * -0.5)
		end,

		timeline =
		{
			FrameEvent(6, function(inst) inst.Physics:SetMotorVelOverride(inst.sg.statemem.vx * -0.24, 0, inst.sg.statemem.vz * -0.2) end),
			FrameEvent(9, function(inst)
				inst.Physics:ClearMotorVelOverride()
				inst.Physics:Stop()
				inst.sg:RemoveStateTag("jumping")
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.Physics:SetMass(0)
					inst.Physics:SetCollisionGroup(COLLISION.OBSTACLES)
					inst.Physics:SetCollisionMask(
						COLLISION.ITEMS,
						COLLISION.GIANTS)
					-- inst.sg:GoToState("idle")
				end
			end),
		},

		onexit = function(inst)
			if inst.sg:HasStateTag("jumping") then
				inst.Physics:ClearMotorVelOverride()
				inst.Physics:Stop()
			end
		end,
	}
}

return StateGraph("tallbird_egg_oversized", states, events, "idle")