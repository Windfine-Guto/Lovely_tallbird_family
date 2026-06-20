local FARM_PLANT_TAGS = {"tendable_farmplant"}
local NOTAGS = {'INLIMBO','notarget','noattack','player','companion','abigail','glommer','friendlyfruitfly','wall'}
local function song_update(inst)
    local ix, iy, iz = inst.Transform:GetWorldPosition()
    local nearby_tendable_plants = TheSim:FindEntities(ix, iy, iz, TUNING.PHONOGRAPH_TEND_RANGE, FARM_PLANT_TAGS)
    for _, tendable_plant in pairs(nearby_tendable_plants) do
        tendable_plant.components.farmplanttendable:TendTo()
    end
end

AddStategraphEvent("smallbird", EventHandler("dance", function(inst)
    if not (inst.sg:HasStateTag("busy") or
            inst.components.health:IsDead()) then
        inst.sg:GoToState("idle_peep")
    end
end))

AddStategraphEvent("smallbird", EventHandler("warm", function(inst)
    if not (inst.sg:HasStateTag("sit") or inst.sg:HasStateTag("busy") or
            inst.components.health:IsDead()) then
        inst.sg:GoToState("sit_warm")
    end
end))

AddStategraphEvent("smallbird", EventHandler("wave", function(inst)
    if not (inst.sg:HasStateTag("waving") or inst.sg:HasStateTag("busy") or
            inst.components.health:IsDead()) then
        inst.sg:GoToState("wave")
    end
end))

AddStategraphEvent("smallbird", EventHandler("flyaway", function(inst)
    if not inst.components.health:IsDead() then
		inst.sg:GoToState("flyaway")
	end
end))

AddStategraphActionHandler("smallbird", ActionHandler(ACTIONS.DIG, "till_or_dig"))
AddStategraphActionHandler("smallbird", ActionHandler(ACTIONS.TILL, "till_or_dig"))
AddStategraphActionHandler("smallbird", ActionHandler(ACTIONS.CHOP, "chop"))
AddStategraphActionHandler("smallbird", ActionHandler(ACTIONS.MINE, "mine"))
AddStategraphActionHandler("smallbird", ActionHandler(ACTIONS.INTERACT_WITH, "plant_peep"))

AddStategraphState("smallbird",State{
		name = "flyaway",
		tags = { "flight", "busy", "noelectrocute" },
		onenter = function(inst)
			inst.Physics:Stop()
			inst.DynamicShadow:Enable(false)
			inst.AnimState:PlayAnimation("boat_jump_pre")
            inst.AnimState:PushAnimation("boat_jump", true)
			inst.sg.statemem.flapSound = 9*FRAMES
		end,

		onupdate = function(inst, dt)
			inst.sg.statemem.flapSound = inst.sg.statemem.flapSound - dt
			if inst.sg.statemem.flapSound <= 0 then
				inst.sg.statemem.flapSound = 3*FRAMES
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/mossling/flap")
			end
		end,

		timeline =
		{
			TimeEvent(20*FRAMES, function(inst)
				inst.Physics:SetMotorVel(-2 + math.random()*4,2*(6+math.random()*2),-2 + math.random()*4)
			end),
            TimeEvent(30*FRAMES, function(inst)
				inst.Physics:SetMotorVel(-2 + math.random()*4,2*(6+math.random()*2),-2 + math.random()*4)
			end),
            TimeEvent(40*FRAMES, function(inst)
				inst.Physics:SetMotorVel(-2 + math.random()*4,2*(6+math.random()*2),-2 + math.random()*4)
			end),
            TimeEvent(50*FRAMES, function(inst)
				inst.Physics:SetMotorVel(-2 + math.random()*4,2*(6+math.random()*2),-2 + math.random()*4)
			end),
			TimeEvent(78*FRAMES, function(inst) inst:Remove() end)
		}
	})

AddStategraphState("smallbird",State{
        name = "flyback",
		tags = { "flight", "busy", "noelectrocute" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("boat_jump",true)
            inst.Physics:SetMotorVelOverride(0, -5.5, 0)
        end,

        onupdate = function(inst)
            inst.Physics:SetMotorVelOverride(0, -7.5, 0)
        end,

        timeline =
		{
            TimeEvent(74*FRAMES, function(inst)
                inst.AnimState:PlayAnimation("boat_jump_pst")
            end),
			TimeEvent(78*FRAMES, function(inst)
                local x, y, z = inst.Transform:GetWorldPosition()
                inst.Physics:ClearMotorVelOverride()
                inst.Physics:Stop()
                inst.Physics:Teleport(x, 0, z)
                inst.sg:GoToState("idle")
            end)
		},

        onexit = function(inst)
            local x, y, z = inst.Transform:GetWorldPosition()
            if y > 0 then
                inst.Transform:SetPosition(x, 0, z)
            end
            inst.Physics:ClearMotorVelOverride()
        end,
    })

AddStategraphState("smallbird",State{
        name = "wave",
        tags = {"idle","waving"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst:ClearBufferedAction()
            inst.AnimState:PlayAnimation("idle_blink")
        end,

        timeline =
        {
            TimeEvent(5*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/creatures/smallbird/chirp")
                if inst.components.timer then
                    inst.components.timer:StartTimer("wave_cd", 30)
                end
                end),
            TimeEvent(17*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/smallbird/blink") end)
        },

        events=
        {
            EventHandler("animover",
                function(inst,data)
                    inst.sg:GoToState("idle")
                end
            ),
        },
    })

AddStategraphState("smallbird",State{
        name = "sit_warm",
        tags = {"idle","sit"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst:ClearBufferedAction()
            inst.AnimState:PlayAnimation("idle",true)
            local leader = inst.components.follower and inst.components.follower.leader
            if leader~=nil then
                if leader.components.temperature then
                    leader.components.temperature:SetModifier("smallbird_warm", 25)
                end
                local talker = leader and leader.components.talker
                if talker then
                    talker:Say(GetString(inst,"ANNOUNCE_SMALLBIRD_WARM"))
                end
            end
        end,

        timeline =
        {
            TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/smallbird/chirp") end),
        },

        onexit = function(inst)
            local leader = inst.components.follower and inst.components.follower.leader
            if leader~=nil and leader.components.temperature then
                leader.components.temperature:RemoveModifier("smallbird_warm")
            end
		end,
    })

AddStategraphState("smallbird",State{
        name = "plant_peep",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("meep")
        end,

        onexit = function(inst)
			inst:ClearBufferedAction()
		end,

        timeline =
        {
            TimeEvent(3*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/creatures/smallbird/chirp") 
                inst:PerformBufferedAction()
                song_update(inst)
                end),
            TimeEvent(10*FRAMES, function(inst)
                song_update(inst)
                end),
        },

        events=
        {
            EventHandler("animover",
                function(inst,data)
                    inst.sg:GoToState("idle")
                end
            ),
        },
    })

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

local config = {swimming_clear_collision_frame = 5*FRAMES,}
local anims = {pre="boat_jump_pre", loop="boat_jump", pst="boat_jump_pst",antic="boat_jump_pre"}
local timelines = {
        hop_pre = {
            TimeEvent(0, function(inst)
                if inst:HasTag("swimming") then
                    SpawnPrefab("splash_green").Transform:SetPosition(inst.Transform:GetWorldPosition())
                end
            end),
        },
        hop_pst = {
            TimeEvent(4 * FRAMES, function(inst)
                if inst:HasTag("swimming") then
                    inst.components.locomotor:Stop()
                    SpawnPrefab("splash_green").Transform:SetPosition(inst.Transform:GetWorldPosition())
                end
            end),
            TimeEvent(6 * FRAMES, function(inst)
                if not inst:HasTag("swimming") then
                    inst.components.locomotor:StopMoving()
                end
            end),
        }
    }
local onenters = (config ~= nil and config.onenters ~= nil) and config.onenters or nil
local onexits = (config ~= nil and config.onexits ~= nil) and config.onexits or nil

local base_hop_pre_timeline = {
    TimeEvent(config.swimming_clear_collision_frame or 0, function(inst)
		if inst.sg.statemem.swimming then
			inst.Physics:ClearCollidesWith(COLLISION.LIMITS)
		end
	end),
}
timelines.hop_pre = timelines.hop_pre == nil and base_hop_pre_timeline or JoinArrays(timelines.hop_pre, base_hop_pre_timeline)

AddStategraphState("smallbird",State{
        name = "hop_pre",
        tags = { "doing", "busy", "jumping", "canrotate" },

        onenter = function(inst)
			inst.sg.statemem.swimming = inst:HasTag("swimming")
            inst.AnimState:PlayAnimation(anims.pre or "jump")
			if not inst.sg.statemem.swimming then
				inst.Physics:ClearCollidesWith(COLLISION.LIMITS)
			end
			if inst.components.embarker:HasDestination() then
	            inst.sg:SetTimeout(18 * FRAMES)
                inst.components.embarker:StartMoving()
			else
	            inst.sg:SetTimeout(18 * FRAMES)
                if inst.landspeed then
                    inst.components.locomotor.runspeed = inst.landspeed
                end
                inst.components.locomotor:RunForward()
			end

			if onenters ~= nil and onenters.hop_pre ~= nil then
				onenters.hop_pre(inst)
			end
        end,

	    onupdate = function(inst,dt)
			if inst.components.embarker:HasDestination() then
				if inst.sg.statemem.embarked then
					inst.components.embarker:Embark()
					inst.sg:GoToState("hop_pst", false)
				elseif inst.sg.statemem.timeout then
					inst.components.embarker:Cancel()

					local x, y, z = inst.Transform:GetWorldPosition()
					inst.sg:GoToState("hop_pst", not TheWorld.Map:IsVisualGroundAtPoint(x, y, z) and inst:GetCurrentPlatform() == nil)
				end
            elseif inst.sg.statemem.timeout or
                   (inst.sg.statemem.tryexit and inst.sg.statemem.swimming == TheWorld.Map:IsVisualGroundAtPoint(inst.Transform:GetWorldPosition())) or
                   (not inst.components.locomotor.dest and not inst.components.locomotor.wantstomoveforward) then
				inst.components.embarker:Cancel()
				local x, y, z = inst.Transform:GetWorldPosition()
				inst.sg:GoToState("hop_pst", not TheWorld.Map:IsVisualGroundAtPoint(x, y, z) and inst:GetCurrentPlatform() == nil)
			end
		end,

        timeline = timelines.hop_pre,

		ontimeout = function(inst)
			inst.sg.statemem.timeout = true
		end,

        events =
        {
            EventHandler("done_embark_movement", function(inst)
				if not inst.AnimState:IsCurrentAnimation("jump_loop") then
					inst.AnimState:PlayAnimation(anims.loop or "jump_loop", false)
					inst.components.amphibiouscreature:OnExitOcean()
				end
				inst.sg.statemem.embarked = true
            end),
            EventHandler("animover", function(inst)
				if not inst.AnimState:IsCurrentAnimation("jump_loop") then
					if inst.AnimState:AnimDone() then
						if not inst.components.embarker:HasDestination() then
							inst.sg.statemem.tryexit = true
						end
					end
					inst.AnimState:PlayAnimation(anims.loop or "jump_loop", false)

					inst.components.amphibiouscreature:OnExitOcean()
				end
            end),
        },

		onexit = function(inst)
            inst.Physics:CollidesWith(COLLISION.LIMITS)
			if inst.components.embarker:HasDestination() then
				inst.components.embarker:Cancel()
			end

			if onexits ~= nil and onexits.hop_pre ~= nil then
				onexits.hop_pre(inst)
			end
		end,
    })
AddStategraphState("smallbird",State{
        name = "hop_pst",
        tags = { "busy", "jumping" },

        onenter = function(inst, land_in_water)
			if land_in_water then
				inst.components.amphibiouscreature:OnEnterOcean()
			else
				inst.components.amphibiouscreature:OnExitOcean()
			end

			if onenters ~= nil and onenters.hop_pst ~= nil then
				onenters.hop_pst(inst)
			end

            inst.AnimState:PlayAnimation(anims.pst or "jump_pst")
        end,

        timeline = timelines.hop_pst,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
			if onexits ~= nil and onexits.hop_pst ~= nil then
				onexits.hop_pst(inst)
			end
		end,
    })
AddStategraphState("smallbird",State{
        name = "hop_antic",
        tags = { "doing", "busy", "jumping", "canrotate" },

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.sg.statemem.swimming = inst:HasTag("swimming")

            inst.AnimState:PlayAnimation(anims.antic or "jump_antic")

            inst.sg:SetTimeout(30 * FRAMES)

			if onenters ~= nil and onenters.hop_antic ~= nil then
				onenters.hop_antic(inst)
			end
        end,

        timeline = timelines.hop_antic,

        ontimeout = function(inst)
            inst.sg:GoToState("hop_pre")
        end,
        onexit = function(inst)
			if onexits ~= nil and onexits.hop_antic ~= nil then
				onexits.hop_antic(inst)
			end
        end,
    })

AddStategraphEvent("tallbird", EventHandler("dance", function(inst)
    if not (inst.sg:HasStateTag("dancing") or inst.sg:HasStateTag("busy") or
            inst.components.health:IsDead()) then
        inst.sg:GoToState("dance")
    end
end))
AddStategraphEvent("tallbird", EventHandler("warm", function(inst)
    if not (inst.sg:HasStateTag("sit") or inst.sg:HasStateTag("busy") or
            inst.components.health:IsDead()) then
        inst.sg:GoToState("sit_warm")
    end
end))
AddStategraphEvent("tallbird", EventHandler("wave", function(inst)
    if not (inst.sg:HasStateTag("waving") or inst.sg:HasStateTag("busy") or
            inst.components.health:IsDead()) then
        inst.sg:GoToState("wave")
    end
end))

AddStategraphEvent("tallbird", EventHandler("emote", function(inst,data)
    if not (inst.sg:HasStateTag("emote") or inst.sg:HasStateTag("busy") or
            inst.components.health:IsDead()) then
        inst.sg:GoToState("idle_emote",data)
    end
end))

AddStategraphEvent("tallbird", EventHandler("dojoust", function(inst, target)
	if not (inst.components.health:IsDead() or inst.sg:HasStateTag("busy")) and
		target and target:IsValid()
	then
		inst.sg:GoToState("joust_pre", target)
	end
end))

AddStategraphEvent("tallbird", EventHandler("flyaway", function(inst)
    if not inst.components.health:IsDead() then
		inst.sg:GoToState("flyaway")
	end
end))

AddStategraphEvent("tallbird", EventHandler("otherfeed", function(inst)
    if not (inst.sg:HasStateTag("eat") or inst.sg:HasStateTag("busy") or
            inst.components.health:IsDead()) then
        inst.sg:GoToState("otherfeed")
    end
end))

AddStategraphActionHandler("tallbird", ActionHandler(ACTIONS.DIG, "till_or_dig"))
AddStategraphActionHandler("tallbird", ActionHandler(ACTIONS.TILL, "till_or_dig"))
AddStategraphActionHandler("tallbird", ActionHandler(ACTIONS.CHOP, "chop"))
AddStategraphActionHandler("tallbird", ActionHandler(ACTIONS.MINE, "mine"))
AddStategraphActionHandler("tallbird", ActionHandler(ACTIONS.INTERACT_WITH, "plant_peep"))

AddStategraphState("tallbird",State{
		name = "flyaway",
		tags = { "flight", "busy", "noelectrocute" },
		onenter = function(inst)
			inst.Physics:Stop()
			inst.DynamicShadow:Enable(false)
			inst.AnimState:PlayAnimation("takeoff_pre")
            inst.AnimState:PushAnimation("takeoff_loop", true)
			inst.sg.statemem.flapSound = 9*FRAMES
		end,

		onupdate = function(inst, dt)
			inst.sg.statemem.flapSound = inst.sg.statemem.flapSound - dt
			if inst.sg.statemem.flapSound <= 0 then
				inst.sg.statemem.flapSound = 3*FRAMES
				inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/mossling/flap")
			end
		end,

		timeline =
		{
			TimeEvent(20*FRAMES, function(inst)
				inst.Physics:SetMotorVel(-2 + math.random()*4,2*(6+math.random()*2),-2 + math.random()*4)
			end),
            TimeEvent(30*FRAMES, function(inst)
				inst.Physics:SetMotorVel(-2 + math.random()*4,2*(6+math.random()*2),-2 + math.random()*4)
			end),
            TimeEvent(40*FRAMES, function(inst)
				inst.Physics:SetMotorVel(-2 + math.random()*4,2*(6+math.random()*2),-2 + math.random()*4)
			end),
            TimeEvent(50*FRAMES, function(inst)
				inst.Physics:SetMotorVel(-2 + math.random()*4,2*(6+math.random()*2),-2 + math.random()*4)
			end),
			TimeEvent(78*FRAMES, function(inst) inst:Remove() end)
		}
	})

AddStategraphState("tallbird",State{
        name = "flyback",
		tags = { "flight", "busy", "noelectrocute" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("takeoff_loop")
            inst.Physics:SetMotorVelOverride(0, -5.5, 0)
        end,

        onupdate = function(inst)
            inst.Physics:SetMotorVelOverride(0, -7.5, 0)
        end,

        timeline =
		{
            TimeEvent(60*FRAMES, function(inst)
                inst.AnimState:PlayAnimation("takeoff_pst")
            end),
			TimeEvent(78*FRAMES, function(inst)
                local x, y, z = inst.Transform:GetWorldPosition()
                inst.Physics:ClearMotorVelOverride()
                inst.Physics:Stop()
                inst.Physics:Teleport(x, 0, z)
                inst.sg:GoToState("idle")
            end),
		},

        onexit = function(inst)
            local x, y, z = inst.Transform:GetWorldPosition()
            if y > 0 then
                inst.Transform:SetPosition(x, 0, z)
            end
            inst.Physics:ClearMotorVelOverride()
        end,
    })

local NOTAGS3 = {'INLIMBO','notarget','noattack','player','companion','abigail','glommer','friendlyfruitfly'
,"chester","hutch", "playerghost","DECOR", "FX" ,"structure","wall","waxedplant","ancienttree","tallbird_egg_oversized"}
local DAMAGE_ONEOF_TAGS = { "pickable", "NPC_workable", "CHOP_workable", "HAMMER_workable", "MINE_workable", "DIG_workable" }
local function Tallbird_Trample(inst)
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
            elseif v.components.pickable ~= nil
                    and v.components.pickable:CanBePicked()
                    and not v:HasTag("intense") and v.prefab~="tallbirdnest" and v.prefab~="new_tallbirdnest" and not v:HasTag("flower") then
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
local function AreDifferentPlatforms(inst, target)
    if inst.components.locomotor.allow_platform_hopping then
        return inst:GetCurrentPlatform() ~= target:GetCurrentPlatform()
    end
    return false
end
local clockwork_common = require("prefabs/clockwork_common")
local LANCE_PADDING = 0.4
local JOUSTING_TAGS = { "jousting" }


local function should_collide(guy, inst)
	return DiffAngle(inst.Transform:GetRotation(), guy.Transform:GetRotation()) > 44
end
local function DoJoustAoe(inst, targets)
    local NOTAGS2= {"companion","smallbird","teenbird","tallbird","bird_family"}
    local MUSTTAGS = {"monster","hostile"}

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
	clockwork_common.FindAOETargetsAtXZ(inst, x, z, LANCE_PADDING + 3,
		function(guy, inst)
			if should_hit(guy, inst) then
                if not guy:HasAnyTag(NOTAGS2) then
                    if guy:HasAnyTag(MUSTTAGS) or guy.components.combat and guy.components.combat.target==inst
                    or inst.components.combat.target==guy then
                        if guy:HasTag("jousting") and should_collide(guy, inst) then
                            guy:PushEventImmediate("joust_collide")
                            inst.components.combat:DoAttack(guy)
                        else
                            inst.components.combat:DoAttack(guy)
                            guy:PushEvent("knockback", { knocker = inst, radius = 6.5, forcelanded = true })
                        end
                    end
				end
			end
		end)
	inst.components.combat.ignorehitrange = false

	-- local knight_rad = inst:GetPhysicsRadius(0)
	-- for i, v in ipairs(TheSim:FindEntities(x, 0, z, 3, JOUSTING_TAGS)) do
	-- 	if v ~= inst and should_hit(v, inst) and should_collide(v, inst) then
    --         if not v:HasAnyTag(NOTAGS2) then
    --             if v:HasAnyTag(MUSTTAGS) or v.components.combat and v.components.combat.target==inst
    --             or inst.components.combat.target==v then
    --                 inst.components.combat:DoAttack(v)
    --                 v:PushEventImmediate("joust_collide")
    --             end
    --         end
	-- 	end
	-- end

end



AddStategraphState("tallbird",State{
        name = "otherfeed",
        tags = {"idle","eat"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("steal")
            inst.SoundEmitter:PlaySound("dontstarve/creatures/smallbird/scratch_ground")
        end,

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },
    })

AddStategraphState("tallbird",State{
		name = "joust_pre",
		tags = { "attack", "busy" },

		onenter = function(inst, target)
			inst.components.locomotor:StopMoving()
			inst.Transform:SetEightFaced()
			inst.AnimState:PlayAnimation("joust_pre")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/tallbird/scratch_ground")
			if target and target:IsValid() then
				inst.sg.statemem.target = target
				inst.sg.statemem.maxdelta = 20

				--true dir (for movement)
				inst.sg.statemem.dir = inst:GetAngleToPoint(target.Transform:GetWorldPosition())
			else
				--true dir (for movement)
				inst.sg.statemem.dir = inst.Transform:GetRotation()
			end

			--facing dir snapped to 45s (for hitbox)
			inst.Transform:SetRotation(math.floor(inst.sg.statemem.dir / 45 + 0.5) * 45)
		end,

		onupdate = function(inst, dt)
			if inst:IsAsleep() then
				inst.sg:GoToState("idle")
			elseif dt > 0 then
				if inst.sg:HasStateTag("jumping") then
					inst.Physics:SetMotorVelOverride(TUNING.YOTH_KNIGHT_JOUST_SPEED * inst.components.locomotor:GetSpeedMultiplier(), 0, 0)
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
			FrameEvent(18, function(inst)
				inst.sg:AddStateTag("jumping")

				local theta = ReduceAngle(inst.sg.statemem.dir - inst.Transform:GetRotation()) * DEGREES
				local speed = TUNING.YOTH_KNIGHT_JOUST_SPEED * inst.components.locomotor:GetSpeedMultiplier()
				inst.Physics:SetMotorVelOverride(speed * math.cos(theta), 0, -speed * math.sin(theta))
			end),
			FrameEvent(21, function(inst) inst.SoundEmitter:PlaySound("dontstarve/movement/run_horseshoes") end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg.statemem.jousting = true
					inst.sg:GoToState("joust_loop", {
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
				inst.Transform:SetFourFaced()
			end
		end,
	})

AddStategraphState("tallbird",State{
		name = "joust_loop",
		tags = { "attack", "busy", "jumping" },

		onenter = function(inst, data)
			inst.Physics:ClearCollidesWith(COLLISION.CHARACTERS)
            inst.Physics:ClearCollidesWith(COLLISION.GIANTS)
			inst.Transform:SetEightFaced()
			if not inst.AnimState:IsCurrentAnimation("joust_loop") then
				inst.AnimState:PlayAnimation("joust_loop", true)
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
			if inst:IsAsleep() then
				inst.sg:GoToState("idle")
			elseif dt > 0 then
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
					local speed = 20 * inst.components.locomotor:GetSpeedMultiplier()
					inst.Physics:SetMotorVelOverride(speed * math.cos(theta), 0, -speed * math.sin(theta))
				end
				DoJoustAoe(inst, inst.sg.statemem.targets)
                Tallbird_Trample(inst)
			end
		end,

		timeline =
		{
			FrameEvent(0, function(inst)
				if not (inst.sg.laststate and inst.sg.laststate.name == "joust_pre") then
					inst.SoundEmitter:PlaySound("dontstarve/movement/run_horseshoes")
				end
			end),
			FrameEvent(15, function(inst) inst.SoundEmitter:PlaySound("dontstarve/movement/run_horseshoes") end),
		},

		ontimeout = function(inst)
			local maxloops = 3
			local loops = inst.sg.statemem.loops
			if loops >= maxloops then
				inst.sg.statemem.stopping = true
				inst.sg:GoToState("joust_pst")
				return
			elseif loops < maxloops - 1 then
				local target = inst.sg.statemem.target
				if target and target:IsValid() and DiffAngle(inst.Transform:GetRotation(), inst:GetAngleToPoint(target.Transform:GetWorldPosition())) < 90 and not AreDifferentPlatforms(inst, target) then
					--target still in front, keep going
					inst.sg.statemem.jousting = true
					inst.sg:GoToState("joust_loop", {
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
			inst.sg:GoToState("joust_loop", {
				dir = inst.sg.statemem.dir,
				loops = maxloops,
				targets = inst.sg.statemem.targets,
			})
		end,

		onexit = function(inst)
			if not (inst.sg.statemem.jousting or inst.sg.statemem.stopping) then
				inst.Physics:ClearMotorVelOverride()
				inst.Physics:Stop()
				inst.Transform:SetFourFaced()
			end
			if not inst.sg.statemem.jousting then
				inst.Physics:CollidesWith(COLLISION.CHARACTERS)
                inst.Physics:CollidesWith(COLLISION.GIANTS)
				inst:RemoveTag("jousting")
			end
		end,
	})

AddStategraphState("tallbird",State{
		name = "joust_pst",
		tags = { "busy", "jumping" },

		onenter = function(inst)
			inst.Transform:SetEightFaced()
			inst.AnimState:PlayAnimation("joust_pst")
			inst.SoundEmitter:PlaySound("dontstarve/creatures/tallbird/scratch_ground")
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
			FrameEvent(22, function(inst)
				inst.sg:AddStateTag("caninterrupt")
			end),
			FrameEvent(28, function(inst)
				inst.sg:RemoveStateTag("busy")
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg:GoToState("idle")
				end
			end),
		},

		onexit = function(inst)
			if inst.sg:HasStateTag("jumping") then
				inst.Physics:ClearMotorVelOverride()
				inst.Physics:Stop()
			end
			inst.Transform:SetFourFaced()
		end,
	})

AddStategraphState("tallbird",State{
        name = "idle_emote",
        tags = {"idle","emote"},

        onenter = function(inst,data)
            local num = math.random(1, 4)
            inst.components.locomotor:Stop()
            inst:ClearBufferedAction()
            if data and data.emote=="pose" then
                inst.AnimState:PlayAnimation("emote4")
                return
            end
            if not TheWorld.state.isday and inst.components.timer
            and not inst.components.timer:TimerExists("yawn_cd") and math.random() < 0.7 then
                inst.AnimState:PlayAnimation("emote_yawn")
                inst.components.timer:StartTimer("yawn_cd", 60+8*math.random())
            elseif inst.components.hunger and inst.components.hunger:GetPercent()>0.9
            and inst.components.timer and not inst.components.timer:TimerExists("happy_cd") then
                inst.AnimState:PlayAnimation("emote_jumpcheer")
                inst.components.timer:StartTimer("happy_cd", 60+5*math.random())
            else
                inst.AnimState:PlayAnimation("emote"..num)
            end
        end,

        timeline =
        {
            TimeEvent(14*FRAMES, function(inst)
                if inst:HasTag("tallbird") and math.random()<0.5 then
                    inst.SoundEmitter:PlaySound("dontstarve/creatures/tallbird/chirp")
                elseif math.random()<0.5 then
                    inst.SoundEmitter:PlaySound("dontstarve/creatures/teenbird/chirp")
                end
                if inst.components.timer then
                    inst.components.timer:StartTimer("emote_cd", 15+7*math.random())
                end
                end),
        },

        events=
        {
            EventHandler("animover",
                function(inst,data)
                    inst.sg:GoToState("idle")
                end
            ),
        },
    })

AddStategraphState("tallbird",State{
        name = "wave",
        tags = {"idle","waving"},

        onenter = function(inst)
            local num = math.random(1, 3)
            inst.components.locomotor:Stop()
            inst:ClearBufferedAction()
            inst.AnimState:PlayAnimation("waving"..num)
        end,

        timeline =
        {
            TimeEvent(14*FRAMES, function(inst)
                if inst:HasTag("tallbird") then
                    inst.SoundEmitter:PlaySound("dontstarve/creatures/tallbird/chirp")
                else
                    inst.SoundEmitter:PlaySound("dontstarve/creatures/teenbird/chirp")
                end
                if inst.components.timer then
                    inst.components.timer:StartTimer("wave_cd", 30)
                end
                end),
        },

        events=
        {
            EventHandler("animover",
                function(inst,data)
                    inst.sg:GoToState("idle")
                end
            ),
        },
    })

AddStategraphState("tallbird",State{
        name = "sit_warm",
        tags = {"idle","sit"},

        onenter = function(inst)
            inst.sitselect = math.random(1, 4)
            local num = inst.sitselect
            inst.components.locomotor:Stop()
            inst:ClearBufferedAction()
            inst.AnimState:PlayAnimation("pre_sit"..num)
            inst.AnimState:PushAnimation("loop_sit"..num, true)
            local leader = inst.components.follower and inst.components.follower.leader
            if leader~=nil then
                if leader.components.temperature then
                    leader.components.temperature:SetModifier("tallbird_warm", 50)
                end
                local talker = leader and leader.components.talker
                if talker then
                    talker:Say(GetString(inst,"ANNOUNCE_TALLBIRD_WARM"))
                end
            end
        end,

        timeline =
        {
            TimeEvent(8*FRAMES, function(inst)
                if inst:HasTag("tallbird") then
                    inst.SoundEmitter:PlaySound("dontstarve/creatures/tallbird/chirp")
                else
                    inst.SoundEmitter:PlaySound("dontstarve/creatures/teenbird/chirp")
                end
                end),
        },

        onexit = function(inst)
            local num = inst.sitselect
			inst.AnimState:PlayAnimation("pst_sit"..num)
            local leader = inst.components.follower and inst.components.follower.leader
            if leader~=nil and leader.components.temperature then
                leader.components.temperature:RemoveModifier("tallbird_warm")
            end
		end,
    })

AddStategraphState("tallbird",State{
        name = "plant_peep",
        tags = {"busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("hungry", true)
        end,

        onexit = function(inst)
			inst:ClearBufferedAction()
		end,

        timeline =
        {
            TimeEvent(8*FRAMES, function(inst)
                if inst:HasTag("tallbird") then
                    inst.SoundEmitter:PlaySound("dontstarve/creatures/tallbird/chirp")
                else
                    inst.SoundEmitter:PlaySound("dontstarve/creatures/teenbird/chirp")
                end
                inst:PerformBufferedAction()
                end),
            TimeEvent(25*FRAMES, function(inst)
                if inst:HasTag("tallbird") then
                    inst.SoundEmitter:PlaySound("dontstarve/creatures/tallbird/chirp")
                else
                    inst.SoundEmitter:PlaySound("dontstarve/creatures/teenbird/chirp")
                end
                song_update(inst)
                end),
        },

        events=
        {
            EventHandler("animover",
                function(inst,data)
                    inst.sg:GoToState("idle")
                end
            ),
        },
    })

AddStategraphState("tallbird",State{
        name = "attack_leg",
        tags = {"attack", "busy", "aoe"},

        onenter = function(inst, cb)
            inst.Physics:Stop()
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("atkleg_pre")
            inst.AnimState:PushAnimation("atkleg", false)
        end,

        timeline=
        {
            TimeEvent(10*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/tallbird/chirp") end),
            TimeEvent(12*FRAMES, function(inst) inst.components.combat:DoAttack()
            local target = nil
            if inst.components.combat.target then
                target = inst.components.combat.target
                inst.components.combat:DoAreaAttack(target, 4, nil, nil,
                nil, NOTAGS)
            end
            if inst.components.timer then
                inst.components.timer:StartTimer("attackleg_cd", 6)
            end
             end),
            TimeEvent(14*FRAMES, function(inst)
				inst.sg:RemoveStateTag("attack")
				inst.sg:RemoveStateTag("busy")
				inst.sg:RemoveStateTag("aoe")
			end),
        },

        events=
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end),
        },
    })

AddStategraphState("tallbird",State{
        name = "dance",
        tags = {"idle", "dancing"},

        onenter = function(inst)
            inst.danceselect = math.random(0, 4)
            local num = inst.danceselect
            inst.components.locomotor:Stop()
            inst:ClearBufferedAction()
            inst.AnimState:PlayAnimation("pre_dance"..num)
            inst.AnimState:PushAnimation("loop_dance"..num, true)
        end,

        onexit = function(inst)
            local num = inst.danceselect
			inst.AnimState:PlayAnimation("pst_dance"..num)
		end,
    })

local config = {swimming_clear_collision_frame = 5*FRAMES,}
local anims = {}
-- {pre="jump_pre", loop="jump_loop", pst="jump_pst",antic="jump_antic"}
local timelines = {
        hop_pre = {
            TimeEvent(0, function(inst)
                if inst:HasTag("swimming") then
                    SpawnPrefab("splash_green").Transform:SetPosition(inst.Transform:GetWorldPosition())
                end
            end),
        },
        hop_pst = {
            TimeEvent(4 * FRAMES, function(inst)
                if inst:HasTag("swimming") then
                    inst.components.locomotor:Stop()
                    SpawnPrefab("splash_green").Transform:SetPosition(inst.Transform:GetWorldPosition())
                end
            end),
            TimeEvent(6 * FRAMES, function(inst)
                if not inst:HasTag("swimming") then
                    inst.components.locomotor:StopMoving()
                end
            end),
        }
    }
local onenters = (config ~= nil and config.onenters ~= nil) and config.onenters or nil
local onexits = (config ~= nil and config.onexits ~= nil) and config.onexits or nil

local base_hop_pre_timeline = {
    TimeEvent(config.swimming_clear_collision_frame or 0, function(inst)
		if inst.sg.statemem.swimming then
			inst.Physics:ClearCollidesWith(COLLISION.LIMITS)
		end
	end),
}
timelines.hop_pre = timelines.hop_pre == nil and base_hop_pre_timeline or JoinArrays(timelines.hop_pre, base_hop_pre_timeline)

AddStategraphState("tallbird",State{
        name = "hop_pre",
        tags = { "doing", "busy", "jumping", "canrotate" },

        onenter = function(inst)
			inst.sg.statemem.swimming = inst:HasTag("swimming")
            inst.AnimState:PlayAnimation(anims.pre or "jump")
			if not inst.sg.statemem.swimming then
				inst.Physics:ClearCollidesWith(COLLISION.LIMITS)
			end
			if inst.components.embarker:HasDestination() then
	            inst.sg:SetTimeout(18 * FRAMES)
                inst.components.embarker:StartMoving()
			else
	            inst.sg:SetTimeout(18 * FRAMES)
                if inst.landspeed then
                    inst.components.locomotor.runspeed = inst.landspeed
                end
                inst.components.locomotor:RunForward()
			end

			if onenters ~= nil and onenters.hop_pre ~= nil then
				onenters.hop_pre(inst)
			end
        end,

	    onupdate = function(inst,dt)
			if inst.components.embarker:HasDestination() then
				if inst.sg.statemem.embarked then
					inst.components.embarker:Embark()
					inst.sg:GoToState("hop_pst", false)
				elseif inst.sg.statemem.timeout then
					inst.components.embarker:Cancel()

					local x, y, z = inst.Transform:GetWorldPosition()
					inst.sg:GoToState("hop_pst", not TheWorld.Map:IsVisualGroundAtPoint(x, y, z) and inst:GetCurrentPlatform() == nil)
				end
            elseif inst.sg.statemem.timeout or
                   (inst.sg.statemem.tryexit and inst.sg.statemem.swimming == TheWorld.Map:IsVisualGroundAtPoint(inst.Transform:GetWorldPosition())) or
                   (not inst.components.locomotor.dest and not inst.components.locomotor.wantstomoveforward) then
				inst.components.embarker:Cancel()
				local x, y, z = inst.Transform:GetWorldPosition()
				inst.sg:GoToState("hop_pst", not TheWorld.Map:IsVisualGroundAtPoint(x, y, z) and inst:GetCurrentPlatform() == nil)
			end
		end,

        timeline = timelines.hop_pre,

		ontimeout = function(inst)
			inst.sg.statemem.timeout = true
		end,

        events =
        {
            EventHandler("done_embark_movement", function(inst)
				if not inst.AnimState:IsCurrentAnimation("jump_loop") then
					inst.AnimState:PlayAnimation(anims.loop or "jump_loop", false)
					inst.components.amphibiouscreature:OnExitOcean()
				end
				inst.sg.statemem.embarked = true
            end),
            EventHandler("animover", function(inst)
				if not inst.AnimState:IsCurrentAnimation("jump_loop") then
					if inst.AnimState:AnimDone() then
						if not inst.components.embarker:HasDestination() then
							inst.sg.statemem.tryexit = true
						end
					end
					inst.AnimState:PlayAnimation(anims.loop or "jump_loop", false)

					inst.components.amphibiouscreature:OnExitOcean()
				end
            end),
        },

		onexit = function(inst)
            inst.Physics:CollidesWith(COLLISION.LIMITS)
			if inst.components.embarker:HasDestination() then
				inst.components.embarker:Cancel()
			end

			if onexits ~= nil and onexits.hop_pre ~= nil then
				onexits.hop_pre(inst)
			end
		end,
    })
AddStategraphState("tallbird",State{
        name = "hop_pst",
        tags = { "busy", "jumping" },

        onenter = function(inst, land_in_water)
			if land_in_water then
				inst.components.amphibiouscreature:OnEnterOcean()
			else
				inst.components.amphibiouscreature:OnExitOcean()
			end

			if onenters ~= nil and onenters.hop_pst ~= nil then
				onenters.hop_pst(inst)
			end

            inst.AnimState:PlayAnimation(anims.pst or "jump_pst")
        end,

        timeline = timelines.hop_pst,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
			if onexits ~= nil and onexits.hop_pst ~= nil then
				onexits.hop_pst(inst)
			end
		end,
    })
AddStategraphState("tallbird",State{
        name = "hop_antic",
        tags = { "doing", "busy", "jumping", "canrotate" },

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.sg.statemem.swimming = inst:HasTag("swimming")

            inst.AnimState:PlayAnimation(anims.antic or "jump_antic")

            inst.sg:SetTimeout(30 * FRAMES)

			if onenters ~= nil and onenters.hop_antic ~= nil then
				onenters.hop_antic(inst)
			end
        end,

        timeline = timelines.hop_antic,

        ontimeout = function(inst)
            inst.sg:GoToState("hop_pre")
        end,
        onexit = function(inst)
			if onexits ~= nil and onexits.hop_antic ~= nil then
				onexits.hop_antic(inst)
			end
        end,
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

local function DoTalkSound(inst)
    if inst.talksoundoverride ~= nil then
        inst.SoundEmitter:PlaySound(inst.talksoundoverride, "talk")
        return true
    elseif not inst:HasTag("mime") then
        inst.SoundEmitter:PlaySound((inst.talker_path_override or "dontstarve/characters/")..(inst.soundsname or inst.prefab).."/talk_LP", "talk")
        return true
    end
end

local function StopTalkSound(inst, instant)
    if not instant and inst.endtalksound ~= nil and inst.SoundEmitter:PlayingSound("talk") then
        inst.SoundEmitter:PlaySound(inst.endtalksound)
    end
    inst.SoundEmitter:KillSound("talk")
end

local function CancelTalk_Override(inst, instant)
	if inst.sg.statemem.talktask ~= nil then
		inst.sg.statemem.talktask:Cancel()
		inst.sg.statemem.talktask = nil
		StopTalkSound(inst, instant)
	end
end

local function OnTalk_Override(inst)
	CancelTalk_Override(inst, true)
	if DoTalkSound(inst) then
		inst.sg.statemem.talktask = inst:DoTaskInTime(1.5 + math.random() * .5, CancelTalk_Override)
	end
	return true
end

local function OnDoneTalking_Override(inst)
	CancelTalk_Override(inst)
	return true
end

local function HandleInstrumentAssets(inst, build, symbol)
    local inv_obj = inst.bufferedaction ~= nil and inst.bufferedaction.invobject or nil
    local override_build, override_symbol, override_sound
    if inv_obj and inv_obj.components.instrument then
        override_build, override_symbol, override_sound = inv_obj.components.instrument:GetAssetOverrides()
        inst.sg.statemem.sound = override_sound
    end
    local skin_build = inv_obj and inv_obj:GetSkinBuild() or nil
    if skin_build ~= nil then
        inst.AnimState:OverrideItemSkinSymbol(symbol, skin_build, override_symbol or symbol, inv_obj.GUID, override_build or build)
    else
        inst.AnimState:OverrideSymbol(symbol, override_build or build, override_symbol or symbol)
    end
    return inv_obj
end

local function OwnsPocketRummageContainer(inst, item)
	local owner = item.components.inventoryitem and item.components.inventoryitem:GetGrandOwner() or nil
	if owner == inst then
		return true
	end
	local mount = inst.components.rider and inst.components.rider:GetMount() or nil
	if owner == mount or item == mount then
		return true
	end
end

local function ClosePocketRummageMem(inst, item)
	if item == nil then
		item = inst.sg.mem.pocket_rummage_item
	elseif item ~= inst.sg.mem.pocket_rummage_item then
		return
	end
	if item then
		inst.sg.mem.pocket_rummage_item = nil

		if OwnsPocketRummageContainer(inst, item) and item.components.container then
			item.components.container:Close(inst)
		end
	end
end

local function SetPocketRummageMem(inst, item)
	inst.sg.mem.pocket_rummage_item = item
end

local function IsHoldingPocketRummageActionItem(holder, item)
	local owner = item.components.inventoryitem and item.components.inventoryitem.owner or nil
    if owner then
        return owner == holder
		or (	--Allow linked containers like woby's rack	
				owner.components.inventoryitem == nil and
				owner.entity:GetParent() == holder
			)
    end
end

local function CheckPocketRummageMem(inst)
	local item = inst.sg.mem.pocket_rummage_item
	if item then
		if not (item.components.container and
				item.components.container:IsOpenedBy(inst) and
				OwnsPocketRummageContainer(inst, item))
		then
			SetPocketRummageMem(inst, nil)
		else
			local stayopen = inst.sg.statemem.keep_pocket_rummage_mem_onexit
			if not stayopen and inst.sg.statemem.is_going_to_action_state then
				local buffaction = inst:GetBufferedAction()
				if buffaction and
					(	buffaction.action == ACTIONS.BUILD or
						(buffaction.action == ACTIONS.DROP and buffaction.invobject ~= item) or
						(buffaction.invobject and IsHoldingPocketRummageActionItem(item, buffaction.invobject))
					)
				then
					stayopen = true
				end
			end
			if not stayopen then
				ClosePocketRummageMem(inst)
			end
		end
	end
end

AddStategraphState("wilson",State{
		name = "start_pocket_rummage_eggbox",
		tags = { "doing", "busy", "nodangle", "keep_pocket_rummage" },

		onenter = function(inst, resume_item)
			inst.components.locomotor:Stop()
			-- inst.SoundEmitter:PlaySound("dontstarve/wilson/make_trap", "make")
			inst.AnimState:PlayAnimation("handout_eggbox_pre")
			inst.AnimState:PushAnimation("handout_eggbox_loop")

			if resume_item then
				if resume_item ~= inst.sg.mem.pocket_rummage_item then
					ClosePocketRummageMem(inst)
				end
				inst.sg.statemem.item = resume_item
				inst.sg:RemoveStateTag("busy")
			else
				ClosePocketRummageMem(inst)
				inst.sg.statemem.action = inst:GetBufferedAction()
				if inst.sg.statemem.action then
					if inst.sg.statemem.action.invobject then
						inst.sg.statemem.item = inst.sg.statemem.action.invobject
					elseif inst.sg.statemem.action.target == inst then
						inst.sg.statemem.item = inst.components.rider:GetMount()
					end
					inst.components.inventory:ReturnActiveActionItem(inst.sg.statemem.item)
				end
			end
		end,

		onupdate = function(inst)
			local item = inst.sg.mem.pocket_rummage_item
			if item and
				not (item.components.container and
					item.components.container:IsOpenedBy(inst) and
					OwnsPocketRummageContainer(inst, item))
			then
				SetPocketRummageMem(inst, nil)
				inst.sg:GoToState("stop_pocket_rummage_eggbox", true)
			end
		end,

		timeline =
		{
			FrameEvent(7, function(inst)
				inst.sg:RemoveStateTag("busy")
				inst:PerformBufferedAction()

				local item = inst.sg.statemem.item
				if item and
					item.components.container and
					item.components.container:IsOpenedBy(inst) and
					OwnsPocketRummageContainer(inst, item)
				then
					SetPocketRummageMem(inst, item)
				else
					SetPocketRummageMem(inst, nil)
					inst.sg:GoToState("stop_pocket_rummage_eggbox", true)
				end
			end),
		},

		events =
		{
			EventHandler("ontalk", OnTalk_Override),
			EventHandler("donetalking", OnDoneTalking_Override),
			EventHandler("equip", function(inst) inst.sg:GoToState("idle") end),
			EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
            EventHandler("itemgetorlose", function (inst)
                inst.AnimState:PlayAnimation("handout_eggbox_pickup")
			    inst.AnimState:PushAnimation("handout_eggbox_loop")
            end)
		},

		onexit = function(inst)
			-- inst.SoundEmitter:KillSound("make")
			CancelTalk_Override(inst)

			CheckPocketRummageMem(inst)

			if inst.bufferedaction == inst.sg.statemem.action and
				not (inst.components.playercontroller and inst.components.playercontroller.lastheldaction == inst.bufferedaction)
			then
				inst:ClearBufferedAction()
			end
		end,
	})

AddStategraphState("wilson",State{
		name = "stop_pocket_rummage_eggbox",
		tags = { "doing", "nodangle" },

		onenter = function(inst, ignoreaction)
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("handout_eggbox_pst")

			ClosePocketRummageMem(inst)

			if not ignoreaction then
				--V2C: Clear, don't perform. Make sure we only do closing here.
				--     The RUMMAGE action might reopen if it was closed already.
				inst:ClearBufferedAction()
			end
		end,

		events =
		{
			EventHandler("ontalk", OnTalk_Override),
			EventHandler("donetalking", OnDoneTalking_Override),
			EventHandler("equip", function(inst) inst.sg:GoToState("idle") end),
			EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg:GoToState("idle")
				end
			end),
		},

		onexit = CancelTalk_Override,
	})

AddStategraphState("wilson",State{
        name = "play_flute_long",
		tags = {"busy", "doing", "playing","nointerrupt" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("action_uniqueitem_pre")
            inst.AnimState:PushAnimation("flute", false)
            local inv_obj = HandleInstrumentAssets(inst, "tallbird_flute", "pan_flute01")
            inst.components.inventory:ReturnActiveActionItem(inv_obj)
            inst:PerformBufferedAction()
        end,

        timeline =
        {
            TimeEvent(30 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound(inst.sg.statemem.sound or "dontstarve/wilson/flute_LP", "flute")
            end),
			TimeEvent(80 * FRAMES, function(inst)
				if inst.sg.statemem.action_failed then
					inst.sg:RemoveStateTag("busy")
				end
			end),
			TimeEvent(82 * FRAMES, function(inst) -- NOTES(JBK): Keep FRAMES in sync with panflute. [PFSSTS]
				if not inst.sg.statemem.action_failed then
					inst.sg:RemoveStateTag("busy")
				end
			end),
            TimeEvent(85 * FRAMES, function(inst)
				if not inst.sg.statemem.action_failed then
					inst.SoundEmitter:KillSound("flute")
				end
            end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },

        onexit = function(inst)
            inst.SoundEmitter:KillSound("flute")
			inst.AnimState:ClearOverrideSymbol("pan_flute01")
        end,
    })

AddStategraphState("wilson",State{
        name = "gaint_shell_enter",
        tags = { "hiding", "notalking", "gaint_shell", "nomorph", "busy", "nopredict" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("hide")
            inst:AddTag("gaint_shell")
            inst.sg:SetTimeout(15 * FRAMES)
        end,

        timeline =
        {
            TimeEvent(6 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/movement/foley/hideshell")
            end),
        },

        events =
        {
			EventHandler("ontalk", OnTalk_Override),
			EventHandler("donetalking", OnDoneTalking_Override),
            EventHandler("unequip", function(inst, data)
				local slot = data and data.eslot
				if slot and (slot == EQUIPSLOTS.HEAD or slot == EQUIPSLOTS.BODY) then
                    inst:RemoveTag("gaint_shell")
					inst.sg:GoToState("idle")
				end
			end),
            -- EventHandler("equip", function(inst, data)
			-- 	local slot = data and data.eslot
			-- 	if slot and (slot == EQUIPSLOTS.HEAD or slot == EQUIPSLOTS.BODY) then
			-- 		inst.sg:GoToState("idle")
			-- 	end
			-- end),
        },

        ontimeout = function(inst)
            --Transfer talk task to shell_idle state
            local talktask = inst.sg.statemem.talktask
            inst.sg.statemem.talktask = nil
            inst.sg:GoToState("gaint_shell_idle", talktask)
        end,

		onexit = CancelTalk_Override,
    })

AddStategraphState("wilson",State{
        name = "gaint_shell_idle",
        tags = { "hiding", "notalking", "gaint_shell", "nomorph", "idle" },

        onenter = function(inst, talktask)
            inst.components.locomotor:Stop()
            inst.AnimState:PushAnimation("hide_idle", false)
            inst:AddTag("gaint_shell")
            --Transferred over from shell_idle so it doesn't cut off abrubtly
            inst.sg.statemem.talktask = talktask
        end,

        events =
        {
            -- EventHandler("equip", function(inst, data)
			-- 	local slot = data and data.eslot
			-- 	if slot and (slot == EQUIPSLOTS.HEAD or slot == EQUIPSLOTS.BODY) then
			-- 		inst.sg:GoToState("idle")
			-- 	end
			-- end),
            EventHandler("unequip", function(inst, data)
				local slot = data and data.eslot
				if slot and (slot == EQUIPSLOTS.HEAD or slot == EQUIPSLOTS.BODY) then
					inst.sg:GoToState("idle")
				end
			end),
            EventHandler("ontalk", function(inst)
                inst.AnimState:PushAnimation("hide_idle", false)
				return OnTalk_Override(inst)
            end),
			EventHandler("donetalking", OnDoneTalking_Override),
        },

		onexit = function (inst,instant)
            inst:RemoveTag("gaint_shell")
            CancelTalk_Override(inst,instant)
        end,
    })

AddStategraphState("wilson",State{
        name = "gaint_shell_hit",
        tags = { "hiding", "gaint_shell", "nomorph", "busy", "pausepredict" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst:ClearBufferedAction()
            inst:AddTag("gaint_shell")
            inst.AnimState:PlayAnimation("gaint_shell_hit")

            inst.SoundEmitter:PlaySound("dontstarve/wilson/hit")

            local stun_frames = 3
            if inst.components.playercontroller ~= nil then
                --Specify min frames of pause since "busy" tag may be
                --removed too fast for our network update interval.
                inst.components.playercontroller:RemotePausePrediction(stun_frames)
            end
            inst.sg:SetTimeout(stun_frames * FRAMES)
        end,

        events =
        {
            -- EventHandler("equip", function(inst, data)
			-- 	local slot = data and data.eslot
			-- 	if slot and (slot == EQUIPSLOTS.HEAD or slot == EQUIPSLOTS.BODY) then
			-- 		inst.sg:GoToState("idle")
			-- 	end
			-- end),
            EventHandler("unequip", function(inst, data)
				local slot = data and data.eslot
				if slot and (slot == EQUIPSLOTS.HEAD or slot == EQUIPSLOTS.BODY) then
					inst.sg.statemem.unequipped = true
				end
			end),
        },

        ontimeout = function(inst)
            inst.sg:GoToState(inst.sg.statemem.unequipped and "idle" or "gaint_shell_idle")
        end,

        onexit = function (inst)
            inst:RemoveTag("gaint_shell")
        end,
    })

AddStategraphState("wilson",State{
        name = "shell_roll_start",
        tags = { "moving", "running", "canrotate", "autopredict","gaint_shell" },

        onenter = function(inst)
            inst.Transform:SetEightFaced()
            inst.components.locomotor:RunForward()
			inst.AnimState:PlayAnimation("egg_roll_pre")
            inst._shell_roll_speed = 0
            inst:AddTag("gaint_shell")
        end,

        onupdate = function(inst)
            inst.components.locomotor:RunForward()
        end,

        timeline =
        {
            TimeEvent(7 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("tallbird_egg_oversized/tallbird_egg_oversized/eggroll-3")
            end)
        },

        events =
        {
            -- EventHandler("equip", function(inst, data)
			-- 	local slot = data and data.eslot
			-- 	if slot and (slot == EQUIPSLOTS.HEAD or slot == EQUIPSLOTS.BODY) then
			-- 		inst.sg:GoToState("idle")
			-- 	end
			-- end),
            EventHandler("unequip", function(inst, data)
				local slot = data and data.eslot
				if slot and (slot == EQUIPSLOTS.HEAD or slot == EQUIPSLOTS.BODY) then
					inst.sg:GoToState("idle")
				end
			end),
			EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("shell_roll")
                end
            end),
        },

        onexit = function (inst)
            inst:RemoveTag("gaint_shell")
            inst.Transform:SetFourFaced()
        end
    })

AddStategraphState("wilson",State{
        name = "shell_roll",
        tags = { "moving", "running", "canrotate", "autopredict","gaint_shell" },

        onenter = function(inst)
            inst.Transform:SetEightFaced()
            inst.components.locomotor:RunForward()

            if not inst.AnimState:IsCurrentAnimation("egg_roll_loop") then
                inst.AnimState:PlayAnimation("egg_roll_loop", true)
            end

            inst._shell_roll_speed = inst._shell_roll_speed + 1
            inst._shell_roll_speed = inst._shell_roll_speed<=5
            and inst._shell_roll_speed or 5
            local speed = inst._shell_roll_speed
            if inst.components.locomotor then
                inst.components.locomotor:SetExternalSpeedMultiplier(inst,"shell_roll_speed",1+speed*0.1)
            end

            inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
            inst:AddTag("gaint_shell")
        end,

        onupdate = function(inst)
            inst.components.locomotor:RunForward()
        end,

        timeline =
        {
            --unmounted
            TimeEvent(7 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("tallbird_egg_oversized/tallbird_egg_oversized/eggroll-1")
            end),
            TimeEvent(15 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("tallbird_egg_oversized/tallbird_egg_oversized/eggroll-2")
            end),
        },

        events =
        {
            -- EventHandler("equip", function(inst, data)
			-- 	local slot = data and data.eslot
			-- 	if slot and (slot == EQUIPSLOTS.HEAD or slot == EQUIPSLOTS.BODY) then
			-- 		inst.sg:GoToState("idle")
			-- 	end
			-- end),
            EventHandler("unequip", function(inst, data)
				local slot = data and data.eslot
				if slot and (slot == EQUIPSLOTS.HEAD or slot == EQUIPSLOTS.BODY) then
					inst.sg:GoToState("idle")
				end
			end),
        },

        ontimeout = function(inst)
            inst.sg:GoToState("shell_roll")
        end,

        onexit = function (inst)
            inst:RemoveTag("gaint_shell")
            inst.Transform:SetFourFaced()
            if inst.components.locomotor then
                inst.components.locomotor:RemoveExternalSpeedMultiplier(inst,"shell_roll_speed")
            end
        end
    })

AddStategraphState("wilson",State{
        name = "shell_roll_stop",
        tags = { "canrotate", "idle", "autopredict","gaint_shell" },

        onenter = function(inst)
            inst.Transform:SetEightFaced()
            inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("egg_roll_pst")
            inst:AddTag("gaint_shell")
        end,

        timeline =
        {
            TimeEvent(7 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("tallbird_egg_oversized/tallbird_egg_oversized/eggroll-4")
            end)
        },

        events =
        {
            -- EventHandler("equip", function(inst, data)
			-- 	local slot = data and data.eslot
			-- 	if slot and (slot == EQUIPSLOTS.HEAD or slot == EQUIPSLOTS.BODY) then
			-- 		inst.sg:GoToState("idle")
			-- 	end
			-- end),
            EventHandler("unequip", function(inst, data)
				local slot = data and data.eslot
				if slot and (slot == EQUIPSLOTS.HEAD or slot == EQUIPSLOTS.BODY) then
					inst.sg:GoToState("idle")
				end
			end),
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("gaint_shell_idle")
                end
            end),
        },

        onexit = function(inst)
            inst:RemoveTag("gaint_shell")
            inst.Transform:SetFourFaced()
        end,
    })

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

    local function SoundPath(event)
        return "waterlogged1/creatures/spider_water/" .. event
    end
    local old_walk_onenter = sg.states["walk"].onenter
    sg.states["walk"].onenter = function(inst, ...)
        old_walk_onenter(inst, ...)
        if inst.components.amphibiouscreature and inst.components.amphibiouscreature.in_water then
            inst.SoundEmitter:PlaySound(SoundPath("walk_water"))
        end
    end

    local old_timeline = sg.states["walk"].timeline
      local original_fn = nil
      local pos = nil
      for i = #old_timeline, 1, -1 do
        local v = old_timeline[i]
        if v and v.time and v.time == 1 * FRAMES then
            original_fn = v.fn
            pos = i
            table.remove(old_timeline, i)
            break
        end
      end
      table.insert(old_timeline,pos,
        TimeEvent(1 * FRAMES, function(inst)
            if inst.components.amphibiouscreature and inst.components.amphibiouscreature.in_water then
                inst.SoundEmitter:PlaySound(SoundPath("walk_water"))
            else
              if original_fn then
                    original_fn(inst)
                end
            end
        end)
      )
      table.insert(old_timeline,
        TimeEvent(5 * FRAMES, function(inst)
            if inst.components.amphibiouscreature and inst.components.amphibiouscreature.in_water then
                inst.SoundEmitter:PlaySound("turnoftides/common/together/water/swim/walk_water_med")
                local wake = SpawnPrefab("boat_water_fx")
                local rotation = inst.Transform:GetRotation() - 180
                local reverse_rot = rotation - math.floor(rotation/360)*360
                local theta = reverse_rot * DEGREES
                local pos = inst:GetPosition() + (Vector3(math.cos(theta), 0, -math.sin(theta)) * 0.5)
                wake.Transform:SetPosition(pos:Get())
                wake.Transform:SetRotation(reverse_rot - 90)
                wake.AnimState:SetScale(0.7, 0.7)
            end
        end)
      )
end)

AddStategraphPostInit("tallbird", function(sg)
    local death_fn = sg.events.death.fn
    sg.events.death.fn = function(inst, ...)
        if not inst:HasTag("tallbird") or inst.components.rideable == nil or not inst.components.rideable:IsBeingRidden() then
            return death_fn(inst, ...)
        end
    end
    local doattack_fn = sg.events.doattack.fn
    sg.events.doattack.fn = function (inst)
        if inst.components.timer and not inst.components.timer:TimerExists("attackleg_cd") then
            inst.sg:GoToState("attack_leg")
        else
            doattack_fn(inst)
        end
    end
    local onsleep_fn = sg.events.gotosleep.fn
    sg.events.gotosleep.fn = function (inst)
        if not inst:HasTag("planar_buff_nosleep") then
            onsleep_fn(inst)
        else
            return
        end
    end
    local old_gohome = sg.states["gohome"].onenter
    sg.states["gohome"].tags = {"idle","gohome"}
    -- sg.states["gohome"].onenter = function (inst)
    --     if not inst:HasTag("planar_buff_nosleep") then
    --         return old_gohome(inst)
    --     else
    --         inst.sg:GoToState("idle")
    --     end
    -- end
end)

AddStategraphPostInit("wilson", function(sg)
---actionhandlers
---RUMMAGE
    local old_RUMMAGE_deststate = sg.actionhandlers[ACTIONS.RUMMAGE].deststate
    sg.actionhandlers[ACTIONS.RUMMAGE].deststate = function (inst,action)
        if action.invobject and action.invobject:HasTag("egg_box")
        and action.invobject.components.container and inst.replica.rider and not inst.replica.rider:IsRiding() then
            return action.invobject.components.container:IsOpenedBy(inst) and "stop_pocket_rummage_eggbox" or "start_pocket_rummage_eggbox"
        else
            return old_RUMMAGE_deststate(inst,action)
        end
    end
---events

---locomote
    local old_locomote_fn = sg.events.locomote.fn
    sg.events.locomote.fn = function(inst, data)
        if inst.sg:HasAnyStateTag("busy", "overridelocomote") and not inst:HasTag("gaint_shell") then
            return
        end
        local is_moving = inst.sg:HasStateTag("moving")
        local should_move = inst.components.locomotor:WantsToMoveForward()

        if is_moving and not should_move and inst:HasTag("gaint_shell") then
            inst.sg:GoToState("shell_roll_stop")
        elseif not is_moving and should_move and inst:HasTag("gaint_shell") then
			if data and data.dir then
				inst.components.locomotor:SetMoveDir(data.dir)
			end
            inst.sg:GoToState("shell_roll_start")
        else
            return old_locomote_fn(inst,data)
        end
    end

---blocked
    local old_blocked_fn = sg.events.blocked.fn
    sg.events.blocked.fn = function(inst, data)
        if not inst.components.health:IsDead() and inst.sg:HasStateTag("gaint_shell") then
            inst.sg:GoToState("gaint_shell_hit")
        else
            return old_blocked_fn(inst, data)
        end
    end

---attacked
    local old_attacked_fn = sg.events.attacked.fn
    sg.events.attacked.fn = function(inst, data)
        if inst.components.health and not inst.components.health:IsDead() and
        not inst.sg:HasAnyStateTag("drowning", "falling")
        and inst.sg:HasStateTag("gaint_shell") then
            inst.sg:GoToState("gaint_shell_hit")
        else
            return old_attacked_fn(inst, data)
        end
    end

---unequip
    local old_unequip_fn = sg.events.unequip.fn
    sg.events.unequip.fn = function (inst,data)
        local slot = data and data.eslot
        if inst:HasTag("gaint_shell") then
            if slot and (slot == EQUIPSLOTS.HEAD or slot == EQUIPSLOTS.BODY) then
                inst.sg:GoToState("idle")
            else
                return
            end
        else
            return old_unequip_fn(inst,data)
        end
    end

---equip
    local old_equip_fn = sg.events.equip.fn
    sg.events.equip.fn = function (inst,data)
        local slot = data and data.eslot
        if inst:HasTag("gaint_shell") then
           if slot and (slot == EQUIPSLOTS.HEAD or slot == EQUIPSLOTS.BODY) then
                inst:RemoveTag("gaint_shell")
                inst.sg:GoToState("idle")
            else
                return
            end
        else
            return old_equip_fn(inst,data)
        end
    end

---state

---attack
    local attack_state = sg.states["attack"]

    for i, ev in ipairs(attack_state.timeline) do
        if ev.time == 8 * FRAMES then
            local old_fn = ev.fn
            ev.fn = function(inst)
                if inst:HasTag("tallbird_mount") then
                    local action = inst:GetBufferedAction()
                    if action and action.target then
                        inst:PushEvent("tallbird_attack", { target = action.target })
                    end
                end
                return old_fn(inst)
            end
            break
        end
    end
---mount
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
---play_whistle
    local whistle_onenter = sg.states["play_whistle"].onenter
    sg.states["play_whistle"].onenter = function(inst)
        local buffered_action = inst:GetBufferedAction()
        if inst:HasTag("tallbird_mount") then
            if buffered_action and buffered_action.action == ACTIONS.BIRDS_LEAVE then
                inst.components.locomotor:Stop()
                inst.AnimState:PlayAnimation("action_uniqueitem_pre")
                inst.AnimState:PushAnimation("emote_slowclap",false)
            else
                inst.components.locomotor:Stop()
                inst.AnimState:PlayAnimation("action_uniqueitem_pre")
                inst.AnimState:PushAnimation("emoteXL_waving1",false)
            end
            
        elseif buffered_action and (buffered_action.action == ACTIONS.BIRDS_LEAVE 
            or buffered_action.action == ACTIONS.BIRDS_FOLLOW) then
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("action_uniqueitem_pre")
            inst.AnimState:PushAnimation("whistle", false)
        else
            whistle_onenter(inst)
        end
    end
    local whistle_timeline = sg.states["play_whistle"].timeline
    local original_fn_whistle = nil
    local pos_whistle = nil
    for i = #whistle_timeline, 1, -1 do
        local v = whistle_timeline[i]
        if v and v.time and v.time == 20 * FRAMES then
            original_fn_whistle = v.fn
            pos_whistle = i
            table.remove(whistle_timeline, i)
            break
        end
      end
      table.insert(whistle_timeline,pos_whistle,
        TimeEvent(20 * FRAMES, function(inst)
            if inst:HasTag("tallbird_mount") then
                if inst:PerformBufferedAction() then
					inst.SoundEmitter:PlaySound("dontstarve/creatures/tallbird/chirp")
                else
					inst.sg.statemem.action_failed = true
					inst.AnimState:SetFrame(35)
                end
            else
                if original_fn_whistle then
                    original_fn_whistle(inst)
                end
            end
        end)
      )
    -- local attack_timeline = sg.states.attack.timeline
    -- table.insert(attack_timeline, TimeEvent(7 * FRAMES, function(inst)
    --     local rider = inst.replica.rider
    --     local mount = rider and rider:GetMount()
    --     if not mount or not mount:HasTag("tallbird") then
    --         return
    --     end
    --     inst.SoundEmitter:PlaySound("dontstarve/creatures/tallbird/attack")
    -- end))
---dash_woby_pre
    local dash_pre_state = sg.states["dash_woby_pre"]
    local old_onenter = dash_pre_state.onenter
    dash_pre_state.onenter = function (inst)
        local mount = inst.components.rider:GetMount()
	    if mount and mount:HasTag("woby") then
            old_onenter(inst)
        elseif inst:HasTag("shadow_tallbird_dash") then
            inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("run_pre")
			inst.AnimState:PushAnimation("run_pst", false)
        end
    end
    for i, ev in ipairs(dash_pre_state.timeline) do
        if ev.frame == 3 then
            local old_fn = ev.fn
            ev.fn = function(inst)
                local mount = inst.components.rider:GetMount()
                if mount and mount:HasTag("woby") then
                    old_fn(inst)
                elseif inst:HasTag("shadow_tallbird_dash") then
                    if not inst:PerformBufferedAction() then
                        inst.AnimState:PlayAnimation("run_pst")
                        inst.sg:GoToState("idle", true)
                        
                        return
				    end
                    inst.Physics:SetMotorVel(30, 0, 0)
                    inst.AnimState:SetMultColour(0.25, 0.25, 0.25, 1)
                end
            end
            break
        end
    end

---dash_woby
    local function ToggleOffPhysicsExceptWorld(inst)
        inst.sg.statemem.isphysicstoggle = true
        inst.Physics:SetCollisionMask(COLLISION.WORLD)
    end
    local dash_state = sg.states["dash_woby"]
    local old_onenter = dash_state.onenter
    dash_state.onenter = function (inst)
        local mount = inst.components.rider:GetMount()
	    if mount and mount:HasTag("woby") then
            old_onenter(inst)
        elseif inst:HasTag("shadow_tallbird_dash") then
            inst.sg.statemem.shadow_tallbird_dash = true

            inst.Physics:SetMotorVel(30, 0, 0)

			inst.components.health:SetInvincible(true)
			if inst.components.playercontroller then
				inst.components.playercontroller:Enable(false)
			end
			inst.AnimState:SetMultColour(0, 0, 0, 0)
			ToggleOffPhysicsExceptWorld(inst)

			--player hidden via 0 alpha instead of Hide(), so that we can still see silhoutte child
			inst.sg.statemem.silhoutte = SpawnPrefab("woby_dash_silhouette_fx")
			inst.sg.statemem.silhoutte.entity:SetParent(inst.entity)

			local fx = SpawnPrefab("woby_dash_shadow_fx")
			fx.AnimState:SetFrame(3)
			fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
			--fx:SetFxOwner(inst) --don't track owner, keep fx stationary
			fx.SoundEmitter:PlaySound("meta5/woby/shadow_dash_out")

        end
    end
    for i, ev in ipairs(dash_state.timeline) do
        if ev.frame == 4 then
            local old_fn = ev.fn
            ev.fn = function(inst)
                local mount = inst.components.rider:GetMount()
                if mount and mount:HasTag("woby") then
                    old_fn(inst)
                elseif inst.sg.statemem.shadow_tallbird_dash then
                    inst.Physics:SetMotorVel(16, 0, 0)
                end
            end
            break
        end
    end
    table.insert(dash_state.timeline,1,FrameEvent(2, function(inst)
        local mount = inst.components.rider:GetMount()
	    if not (mount and mount:HasTag("woby")) and inst.sg.statemem.shadow_tallbird_dash then
				local x, y, z = inst.Transform:GetWorldPosition()
				local fx = SpawnPrefab("woby_dash_shadow_fx")
				fx.AnimState:PlayAnimation("woby_teleport_fx_small"..tostring(math.random(2)))
				fx.Transform:SetPosition(x, y, z)
				fx:SetFxOwner(inst)

				local theta = inst.Transform:GetRotation() * DEGREES
				local cos_theta = math.cos(theta)
				local sin_theta = math.sin(theta)
				local map = TheWorld.Map
				local pt = Vector3(0, 0, 0)
				local success = false
				local _ispassableatpoint = GetActionPassableTestFnAt(x, y, z)
				for i = 7, 12.5, 0.5 do
					pt.x = x + cos_theta * (i - 0.5)
					pt.z = z - sin_theta * (i - 0.5)
					if _ispassableatpoint(pt:Get()) then
						pt.x = x + cos_theta * (i + 0.5)
						pt.z = z - sin_theta * (i + 0.5)
						if _ispassableatpoint(pt:Get()) then
							pt.x = x + cos_theta * i
							pt.z = z - sin_theta * i
							if not map:IsPointNearHole(pt) then
								success = true
								break
							end
						end
					end
				end
				if not success then
					for i = 6.5, 0.5, -0.5 do
						pt.x = x + cos_theta * (i - 0.5)
						pt.z = z - sin_theta * (i - 0.5)
						if _ispassableatpoint(pt:Get()) then
							pt.x = x + cos_theta * (i + 0.5)
							pt.z = z - sin_theta * (i + 0.5)
							if _ispassableatpoint(pt:Get()) then
								pt.x = x + cos_theta * i
								pt.z = z - sin_theta * i
								if not map:IsPointNearHole(pt) then
									success = true
									break
								end
							end
						end
					end
				end
				inst.Physics:Stop()
				if success then
					x, y, z = pt:Get()
					inst.Physics:Teleport(x, y, z)
				end

				fx = SpawnPrefab("woby_dash_shadow_fx")
				fx.Transform:SetPosition(x, y, z)
				--fx:SetFxOwner(inst) --don't track owner, keep fx stationary
				fx.SoundEmitter:PlaySound("meta5/woby/shadow_dash_in")
        end
			end))
    table.insert(dash_state.timeline,FrameEvent(5, function(inst)
            if not (mount and mount:HasTag("woby")) and inst.sg.statemem.shadow_tallbird_dash then
                PlayFootstep(inst)
                inst.SoundEmitter:PlaySound("dontstarve/beefalo/walk", nil, 0.5)
            end
			end))
    table.insert(dash_state.timeline,FrameEvent(6, function(inst)
            if not (mount and mount:HasTag("woby")) and inst.sg.statemem.shadow_tallbird_dash then
                inst.sg.statemem.dashing = true
				inst.sg:GoToState("dash_woby_pst", true)
				inst.sg.statemem.isphysicstoggle = true
            end
			end))
    local function ToggleOnPhysics(inst)
        inst.sg.statemem.isphysicstoggle = nil
        inst.Physics:SetCollisionMask(
            COLLISION.WORLD,
            COLLISION.OBSTACLES,
            COLLISION.SMALLOBSTACLES,
            COLLISION.CHARACTERS,
            COLLISION.GIANTS
        )
    end
    local old_onexit = dash_state.onexit
    dash_state.onexit = function (inst)
        old_onexit(inst)
        local mount = inst.components.rider:GetMount()
	    if not (mount and mount:HasTag("woby")) and inst.sg.statemem.shadow_tallbird_dash then
           inst.components.health:SetInvincible(false)
			if inst.components.playercontroller then
				inst.components.playercontroller:Enable(true)
			end
			ToggleOnPhysics(inst)
			inst.AnimState:SetMultColour(1, 1, 1, 1)
			inst.Physics:Stop()
            inst.sg.statemem.silhoutte:Remove()

            inst.sg.statemem.shadow_tallbird_dash = false
        end
    end

---dash_woby_pst
    local dash_pst_state = sg.states["dash_woby_pst"]
   
    local old_onexit = dash_pst_state.onexit
    dash_pst_state.onexit = function(inst)
        local mount = inst.components.rider:GetMount()
	    if mount and mount:HasTag("woby") then
            old_onexit(inst)
        end
    end

    for i, ev in ipairs(dash_pst_state.timeline) do
        if ev.frame == 12 then
            local old_fn = ev.fn
            ev.fn = function(inst)
                local mount = inst.components.rider:GetMount()
                if mount and mount:HasTag("woby") then
                    old_fn(inst)
                end
            end
            break
        end
    end

---joust_pre
    local function SetRideFaced(inst)
        if inst:HasTag("tallbird_mount") then
            inst.Transform:SetSixFaced()
        end
    end

    local function Joust_nocollide(inst)
        local joustdata = inst.sg.statemem.joustdata
        local joustsource = joustdata.source and joustdata.source:IsValid() and joustdata.source.components.joustsource or nil
        if not joustsource then
            inst.sg.statemem.stopping = true
            inst.sg:GoToState("joust_stop")
            return
        end
        local joustuser = inst.components.joustuser
        if joustuser then
            joustsource:CheckCollision(inst, joustdata.targets)
            if not inst.components.joustuser:CheckEdge() then
                joustdata.edgecount = 0
            elseif joustdata.edgecount < 3 then
                joustdata.edgecount = joustdata.edgecount + 1
            else
                inst.sg.statemem.stopping = true
                inst.sg:GoToState("joust_stop")
            end
        end
    end

    local function SpeedBuff(inst)
        if inst:HasTag("tallbird_mount") then
            local mount = inst.components.rider and inst.components.rider:GetMount()
            if inst.components.locomotor then
                inst.components.locomotor:SetExternalSpeedMultiplier(mount,"tallbird_joust_speed",2)
            end
        end
    end

    local function RemoveBuff(inst)
        if inst:HasTag("tallbird_mount") then
            local mount = inst.components.rider and inst.components.rider:GetMount()
            if inst.components.locomotor then
                inst.components.locomotor:RemoveExternalSpeedMultiplier(mount,"tallbird_joust_speed")
                inst.components.locomotor:RemoveExternalSpeedMultiplier(mount,"tallbird_joust_speed2")
            end
        end
    end

    local joust_pre_state = sg.states["joust_pre"]
    local old_joust_pre_onexit = joust_pre_state.onexit
    joust_pre_state.onexit = function(inst)
        old_joust_pre_onexit(inst)
        if not inst.sg.statemem.keepeightfaced then
			SetRideFaced(inst)
		end
    end
---joust_start
    local joust_start_state = sg.states["joust_start"]

    local old_joust_start_onenter = joust_start_state.onenter
    joust_start_state.onenter = function (inst, joustdata)
        joustdata.tallbird_targets = {}
        joustdata.tallbird_speed = -1
        if inst.rod_tallbird_light_fx then
            inst.rod_tallbird_light_fx.Follower:FollowSymbol(inst.GUID, "carrot", 0, 0, 0)
        end
        return old_joust_start_onenter(inst,joustdata)
    end

    local old_joust_start_onexit = joust_start_state.onexit
    joust_start_state.onexit = function(inst)
        old_joust_start_onexit(inst)
        if not inst.sg.statemem.jousting and not inst.sg.statemem.stopping then
			SetRideFaced(inst)
        end
        if inst.rod_tallbird_light_fx then
            inst.rod_tallbird_light_fx.Follower:FollowSymbol(inst.GUID, "swap_object", 0, 0, 0)
        end
    end

    local old_joust_start_onupdate = joust_start_state.onupdate
    joust_start_state.onupdate = function(inst)
		if not inst:HasTag("tallbird_mount") then
            return old_joust_start_onupdate(inst)
        else
            return Joust_nocollide(inst)
        end
    end
---joust
    local joust_state = sg.states["joust"]
    local old_joust_state_onenter = joust_state.onenter
    joust_state.onenter = function (inst, joustdata)
        SpeedBuff(inst)
        if inst:HasTag("beak_carrot_bird_rod_joust") then
            joustdata.tallbird_speed = joustdata.tallbird_speed>=0 and joustdata.tallbird_speed + 1 or 0
            joustdata.tallbird_speed = joustdata.tallbird_speed<=TUNING.TALLBIRD_ROD_SPEED_LIMIT and joustdata.tallbird_speed or TUNING.TALLBIRD_ROD_SPEED_LIMIT
            local mount = inst.components.rider and inst.components.rider:GetMount()
            if mount and mount:HasTag("tallbird") and inst.components.locomotor then
                inst.components.locomotor:SetExternalSpeedMultiplier(mount,"tallbird_joust_speed2",1+joustdata.tallbird_speed*0.1)
            end
            joustdata.loop = TUNING.YOTH_LANCE_RUNANIM_LOOP_COUNT
        end
        if inst.rod_tallbird_light_fx then
            inst.rod_tallbird_light_fx.Follower:FollowSymbol(inst.GUID, "carrot", 0, 0, 0)
        end
        return old_joust_state_onenter(inst,joustdata)
    end

    local old_joust_onexit = joust_state.onexit
    joust_state.onexit = function(inst)
        RemoveBuff(inst)
        old_joust_onexit(inst)
        if not inst.sg.statemem.jousting and not inst.sg.statemem.stopping then
			SetRideFaced(inst)
        end
        if inst.rod_tallbird_light_fx then
            inst.rod_tallbird_light_fx.Follower:FollowSymbol(inst.GUID, "swap_object", 0, 0, 0)
        end
    end

    local old_joust_onupdate = joust_state.onupdate
    joust_state.onupdate = function(inst)
		if not inst:HasTag("tallbird_mount") then
            return old_joust_onupdate(inst)
        else
            return Joust_nocollide(inst)
        end
    end

    local old_joust_events_joust_collide = joust_state.events.joust_collide.fn
    joust_state.events.joust_collide.fn = function(inst)
		if not inst:HasTag("tallbird_mount") then
            return old_joust_events_joust_collide(inst)
        end
    end
---joust_stop
    local joust_stop_state = sg.states["joust_stop"]

    local old_joust_stop_onenter = joust_stop_state.onenter
    joust_stop_state.onenter = function (inst)
        old_joust_stop_onenter(inst)

        if inst:HasTag("tallbird_mount") then
            local theta = ReduceAngle(0) * DEGREES
            local speed = 10
            inst.Physics:SetMotorVel(speed * math.cos(theta), 0, -speed * math.sin(theta))
        end
        if inst.rod_tallbird_light_fx then
            inst.rod_tallbird_light_fx.Follower:FollowSymbol(inst.GUID, "carrot", 0, 0, 0)
        end
    end

    local joust_stop_state_timeline_pos = 1
    for i, ev in ipairs(joust_stop_state.timeline) do
        if ev.frame == 22 then
            joust_stop_state_timeline_pos = i
            local old_fn = ev.fn
            ev.fn = function(inst)
                old_fn(inst)
                SetRideFaced(inst)
            end
        end
    end
    table.insert(joust_stop_state.timeline,joust_stop_state_timeline_pos,FrameEvent(15, function(inst)
		if inst:HasTag("tallbird_mount") then
            inst.Physics:Stop()
        end
    end))


    local old_joust_stop_onexit = joust_stop_state.onexit
    joust_stop_state.onexit = function(inst)
        if inst.rod_tallbird_light_fx then
            inst.rod_tallbird_light_fx.Follower:FollowSymbol(inst.GUID, "swap_object", 0, 0, 0)
        end
        old_joust_stop_onexit(inst)
		SetRideFaced(inst)
    end

---fishing_pre
    local fishing_pre_state = sg.states["fishing_pre"]

    local old_fishing_pre_events_animqueueover = fishing_pre_state.events.animqueueover.fn
    fishing_pre_state.events.animqueueover.fn = function(inst)
		if not inst:HasTag("beak_carrot_bird_rod_user") then
            return old_fishing_pre_events_animqueueover(inst)
        else
            if inst.AnimState:AnimDone() then
                inst.SoundEmitter:PlaySound("dontstarve/common/fishingpole_baitsplash")
                inst.sg:GoToState("idle")
            end
        end
    end

---mounted_idle
    local mounted_idle_state = sg.states["mounted_idle"]

    local old_mounted_idle_onenter = mounted_idle_state.onenter
    mounted_idle_state.onenter = function(inst, pushanim)
        if inst:HasTag("tallbird_mount") and inst.rod_tallbird_light_fx then
            inst.rod_tallbird_light_fx.Follower:FollowSymbol(inst.GUID, "carrot", 0, 0, 5)
        end
        return old_mounted_idle_onenter(inst, pushanim)
    end

    local old_mounted_idle_onexit = mounted_idle_state.onexit
    mounted_idle_state.onexit = function(inst,...)
        if inst:HasTag("tallbird_mount") and inst.rod_tallbird_light_fx then
            inst.rod_tallbird_light_fx.Follower:FollowSymbol(inst.GUID, "swap_object", 0, 0, 0)
        end
        if old_mounted_idle_onexit then
            return old_mounted_idle_onexit(inst,...)
        end
    end

---run_start
    local run_start_state = sg.states["run_start"]

    local old_run_start_onenter = run_start_state.onenter
    run_start_state.onenter = function(inst)
        if inst:HasTag("tallbird_mount") and inst.rod_tallbird_light_fx then
            inst.rod_tallbird_light_fx.Follower:FollowSymbol(inst.GUID, "carrot", 0, 0, 5)
        end
        return old_run_start_onenter(inst)
    end

    local old_run_start_onexit = run_start_state.onexit
    run_start_state.onexit = function(inst,...)
        if inst:HasTag("tallbird_mount") and inst.rod_tallbird_light_fx then
            inst.rod_tallbird_light_fx.Follower:FollowSymbol(inst.GUID, "swap_object", 0, 0, 0)
        end
        if old_run_start_onexit then
            return old_run_start_onexit(inst,...)
        end
    end

---run
    local run_state = sg.states["run"]

    local old_run_onenter = run_state.onenter
    run_state.onenter = function(inst)
        if inst:HasTag("tallbird_mount") and inst.rod_tallbird_light_fx then
            inst.rod_tallbird_light_fx.Follower:FollowSymbol(inst.GUID, "carrot", 0, 0, 5)
        end
        return old_run_onenter(inst)
    end

    local old_run_onexit = run_state.onexit
    run_state.onexit = function(inst,...)
        if inst:HasTag("tallbird_mount") and inst.rod_tallbird_light_fx then
            inst.rod_tallbird_light_fx.Follower:FollowSymbol(inst.GUID, "swap_object", 0, 0, 0)
        end
        if old_run_onexit then
            return old_run_onexit(inst,...)
        end
    end

---run_stop
    local run_stop_state = sg.states["run_stop"]

    local old_run_stop_onenter = run_stop_state.onenter
    run_stop_state.onenter = function(inst)
        if inst:HasTag("tallbird_mount") and inst.rod_tallbird_light_fx then
            inst.rod_tallbird_light_fx.Follower:FollowSymbol(inst.GUID, "carrot", 0, 0, 5)
        end
        return old_run_stop_onenter(inst)
    end

    local old_run_stop_onexit = run_stop_state.onexit
    run_stop_state.onexit = function(inst)
        if inst:HasTag("tallbird_mount") and inst.rod_tallbird_light_fx then
            inst.rod_tallbird_light_fx.Follower:FollowSymbol(inst.GUID, "swap_object", 0, 0, 0)
        end
        if old_run_stop_onexit then
            return old_run_stop_onexit(inst)
        end
    end
end)

---延迟补偿

AddStategraphState("wilson_client",State{
		name = "play_flute_long",
		server_states = { "play_flute_long" },
		forward_server_states = true,
		onenter = function(inst) inst.sg:GoToState("action_uniqueitem_busy") end,
	})

AddStategraphState("wilson_client",State{
        name = "gaint_shell_idle",
        tags = { "hiding", "notalking", "gaint_shell", "idle" },

        onenter = function(inst, talktask)
            inst.components.locomotor:Stop()
            inst.AnimState:PushAnimation("hide_idle", false)
            inst.sg.statemem.talktask = talktask
        end,

        events =
        {
            -- EventHandler("equip", function(inst, data)
			-- 	local slot = data and data.eslot
			-- 	if slot and (slot == EQUIPSLOTS.HEAD or slot == EQUIPSLOTS.BODY) then
			-- 		inst.sg:GoToState("idle")
			-- 	end
			-- end),
            EventHandler("unequip", function(inst, data)
				local slot = data and data.eslot
				if slot and (slot == EQUIPSLOTS.HEAD or slot == EQUIPSLOTS.BODY) then
					inst.sg:GoToState("idle")
				end
			end),
            EventHandler("ontalk", function(inst)
                inst.AnimState:PushAnimation("hide_idle", false)
				return OnTalk_Override(inst)
            end),
			EventHandler("donetalking", OnDoneTalking_Override),
        },

		onexit = function (inst,instant)
            CancelTalk_Override(inst,instant)
        end,
    })

AddStategraphState("wilson_client",State{
        name = "shell_roll_start",
        tags = { "moving", "running", "canrotate", "autopredict","gaint_shell" },

        onenter = function(inst)
            inst.Transform:SetEightFaced()
            inst.components.locomotor:RunForward()
			inst.AnimState:PlayAnimation("egg_roll_pre")
            inst._shell_roll_speed = 0
        end,

        onupdate = function(inst)
            inst.components.locomotor:RunForward()
        end,

        timeline =
        {
            TimeEvent(7 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("tallbird_egg_oversized/tallbird_egg_oversized/eggroll-3")
            end)
        },

        events =
        {
            EventHandler("equip", function(inst, data)
				local slot = data and data.eslot
				if slot and (slot == EQUIPSLOTS.HEAD or slot == EQUIPSLOTS.BODY) then
					inst.sg:GoToState("idle")
				end
			end),
            EventHandler("unequip", function(inst, data)
				local slot = data and data.eslot
				if slot and (slot == EQUIPSLOTS.HEAD or slot == EQUIPSLOTS.BODY) then
					inst.sg:GoToState("idle")
				end
			end),
			EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("shell_roll")
                end
            end),
        },

        onexit = function (inst)
            inst.Transform:SetFourFaced()
        end
    })

AddStategraphState("wilson_client",State{
        name = "shell_roll",
        tags = { "moving", "running", "canrotate", "autopredict","gaint_shell" },

        onenter = function(inst)
            inst.Transform:SetEightFaced()
            inst.components.locomotor:RunForward()

            if not inst.AnimState:IsCurrentAnimation("egg_roll_loop") then
                inst.AnimState:PlayAnimation("egg_roll_loop", true)
            end

            inst._shell_roll_speed = inst._shell_roll_speed + 1
            inst._shell_roll_speed = inst._shell_roll_speed<=5
            and inst._shell_roll_speed or 5

            inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
        end,

        onupdate = function(inst)
            inst.components.locomotor:RunForward()
        end,

        timeline =
        {
            TimeEvent(7 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("tallbird_egg_oversized/tallbird_egg_oversized/eggroll-1")
            end),
            TimeEvent(15 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("tallbird_egg_oversized/tallbird_egg_oversized/eggroll-2")
            end),
        },

        events =
        {
            EventHandler("equip", function(inst, data)
				local slot = data and data.eslot
				if slot and (slot == EQUIPSLOTS.HEAD or slot == EQUIPSLOTS.BODY) then
					inst.sg:GoToState("idle")
				end
			end),
            EventHandler("unequip", function(inst, data)
				local slot = data and data.eslot
				if slot and (slot == EQUIPSLOTS.HEAD or slot == EQUIPSLOTS.BODY) then
					inst.sg:GoToState("idle")
				end
			end),
        },

        ontimeout = function(inst)
            inst.sg:GoToState("shell_roll")
        end,

        onexit = function (inst)
            inst.Transform:SetFourFaced()
        end
    })

AddStategraphState("wilson_client",State{
        name = "shell_roll_stop",
        tags = { "canrotate", "idle", "autopredict","gaint_shell" },

        onenter = function(inst)
            inst.Transform:SetEightFaced()
            inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("egg_roll_pst")
        end,

        timeline =
        {
            TimeEvent(7 * FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("tallbird_egg_oversized/tallbird_egg_oversized/eggroll-4")
            end)
        },

        events =
        {
            EventHandler("equip", function(inst, data)
				local slot = data and data.eslot
				if slot and (slot == EQUIPSLOTS.HEAD or slot == EQUIPSLOTS.BODY) then
					inst.sg:GoToState("idle")
				end
			end),
            EventHandler("unequip", function(inst, data)
                local slot = data and data.eslot
				if slot and (slot == EQUIPSLOTS.HEAD or slot == EQUIPSLOTS.BODY) then
					inst.sg:GoToState("idle")
				end
			end),
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("gaint_shell_idle")
                end
            end),
        },

        onexit = function(inst)
            inst.Transform:SetFourFaced()
        end,
    })

AddStategraphState("wilson_client",State{
		name = "start_pocket_rummage_eggbox",
		server_states = { "start_pocket_rummage_eggbox" },
		forward_server_states = true,
		onenter = function(inst)
			inst.components.locomotor:Stop()
			-- inst.SoundEmitter:PlaySound("dontstarve/wilson/make_trap", "make_preview")
			inst.AnimState:PlayAnimation("handout_eggbox_pre")
			inst.AnimState:PushAnimation("handout_eggbox_loop")

			inst:PerformPreviewBufferedAction()
			inst.sg:SetTimeout(2)
		end,

		timeline =
		{
			FrameEvent(7, function(inst)
				inst.sg:RemoveStateTag("busy")
			end),
		},

		onupdate = function(inst)
			if inst.sg:ServerStateMatches() then
				if inst.entity:FlattenMovementPrediction() then
					inst.sg:GoToState("idle", "noanim")
				end
			elseif inst.bufferedaction == nil then
				inst.AnimState:PlayAnimation("handout_eggbox_pst")
				inst.sg:GoToState("idle", true)
			end
		end,

		ontimeout = function(inst)
			inst:ClearBufferedAction()
			inst.AnimState:PlayAnimation("handout_eggbox_pst")
			inst.sg:GoToState("idle", true)
		end,

		onexit = function(inst)
			-- inst.SoundEmitter:KillSound("make_preview")
		end,
	})

AddStategraphState("wilson_client",State{
		name = "stop_pocket_rummage_eggbox",
		tags = { "doing" },
		server_states = { "stop_pocket_rummage_eggbox" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("handout_eggbox_pst")
			inst.AnimState:PushAnimation("idle_loop")
			inst:PerformPreviewBufferedAction()
			inst.sg:SetTimeout(2)
		end,

		onupdate = function(inst)
			if inst.sg:ServerStateMatches() then
				if inst.entity:FlattenMovementPrediction() then
					inst.sg:GoToState("idle", "noanim")
				end
			elseif inst.bufferedaction == nil then
				inst.AnimState:PlayAnimation("handout_eggbox_pre")
				inst.AnimState:PushAnimation("handout_eggbox_loop")
				inst.sg:GoToState("idle", "noanim")
			end
		end,

		ontimeout = function(inst)
			inst:ClearBufferedAction()
			inst.AnimState:PlayAnimation("handout_eggbox_pre")
			inst.AnimState:PushAnimation("handout_eggbox_loop")
			inst.sg:GoToState("idle", "noanim")
		end,
	})

AddStategraphPostInit("wilson_client", function(sg)

    local old_RUMMAGE_deststate = sg.actionhandlers[ACTIONS.RUMMAGE].deststate
    sg.actionhandlers[ACTIONS.RUMMAGE].deststate = function (inst,action)
        if action.invobject and action.invobject:HasTag("egg_box")
        and action.invobject.replica.container and inst.replica.rider and not inst.replica.rider:IsRiding() then
            return action.invobject.replica.container:IsOpenedBy(inst) and "stop_pocket_rummage_eggbox" or "start_pocket_rummage_eggbox"
        else
            return old_RUMMAGE_deststate(inst,action)
        end
    end
---events

---locomote
    local old_locomote_fn = sg.events.locomote.fn
    sg.events.locomote.fn = function(inst, data)
        if (inst.sg:HasStateTag("busy") or inst:HasTag("busy")) and
			not (inst.sg:HasStateTag("boathopping") or inst:HasTag("boathopping")) and not inst:HasTag("gaint_shell") then
			return
		elseif inst.sg:HasStateTag("overridelocomote") and not inst:HasTag("gaint_shell") then
			return
		end

        local is_moving = inst.sg:HasStateTag("moving")
        local should_move = inst.components.locomotor:WantsToMoveForward()

        if is_moving and not should_move and inst:HasTag("gaint_shell") then
            inst.sg:GoToState("shell_roll_stop")
        elseif not is_moving and should_move and inst:HasTag("gaint_shell") then
			if data and data.dir then
				if inst.components.locomotor then
					inst.components.locomotor:SetMoveDir(data.dir)
				else
					inst.Transform:SetRotation(data.dir)
				end
			end
            inst.sg:GoToState("shell_roll_start")
        else
            return old_locomote_fn(inst,data)
        end
    end
end)