local select_mode = "tallbird_select"
local attack_mode = "tallbird"

local retarget1 = "retarget1"
local retarget2 = "retarget2"

local function Retarget1(inst)
    return FindEntity(inst, 16, function(ent)
local t = ent.components.combat.target
return inst.components.combat:CanTarget(ent) and t and (t == inst or t:HasTag("player")
 or (t:HasTag("companion") and (not t.components.combat or t.components.combat.target ~= inst)))
 end, { "_combat" }, { "player" })
end

local RETARGET_MUST_TAGS = { "_combat", "_health" }
local RETARGET_CANT_TAGS_HOME={"tallbird","teenbird","smallbird","bird_friend"}
local RETARGET_CANT_TAGS = { "tallbird","teenbird","smallbird","player",
"glommer","chester","companion","beefalo","hutch","abigail" }
local RETARGET_ONEOF_TAGS = { "monster","prey","insect","hostile","character","animal" }
local RETARGET_ANIMAL_ONEOF_TAGS = { "monster","prey","insect","hostile","character","animal" }
local function Retarget2(inst)
    local function IsValidTarget(guy)
        return not guy.components.health:IsDead()
            and inst.components.combat:CanTarget(guy)
            and (not inst:HasTag("smallbird") or inst:HasTag("companion"))
    end
    return
        inst.components.homeseeker ~= nil and
        inst.components.homeseeker:HasHome() and
        FindEntity(
            inst.components.homeseeker.home,
            SpringCombatMod(TUNING.TALLBIRD_DEFEND_DIST/2),
            IsValidTarget,
            RETARGET_MUST_TAGS,
            RETARGET_CANT_TAGS_HOME,
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

AddModRPCHandler(retarget1..'attack', retarget1..'attack', function(inst)
    if inst and inst:IsValid() and not inst:HasTag("playerghost") and inst:HasTag("tallbird_mount") then
        local targets = inst.components.leader and inst.components.leader.followers or {}
        local talker = inst.components.talker
        if talker then
            talker:Say(GetString(inst,"ANNOUNCE_TALLBIRD_RETARGET1"))
        end
        for follower,_ in pairs(targets) do
            if follower:IsValid() and follower:HasTag("tallbird") and follower.components.follower and follower.components.follower.leader==inst then
                if follower.components.combat then
                    follower.components.combat:DropTarget()
                    follower.components.combat:SetRetargetFunction(1.5, Retarget1)
                end
            end
        end
    end
end)

AddModRPCHandler(retarget2..'attack', retarget2..'attack', function(inst)
    if inst and inst:IsValid() and not inst:HasTag("playerghost") and inst:HasTag("tallbird_mount") then
        local targets = inst.components.leader and inst.components.leader.followers or {}
        local talker = inst.components.talker
        if talker then
            talker:Say(GetString(inst,"ANNOUNCE_TALLBIRD_RETARGET2"))
        end
        for follower,_ in pairs(targets) do
            if follower:IsValid() and follower:HasTag("tallbird") and follower.components.follower and follower.components.follower.leader==inst then
                if follower.components.combat then
                    follower.components.combat:SetRetargetFunction(1.5, Retarget2)
                end
            end
        end
    end
end)

local function IsHUDScreen()
	local screen = TheFrontEnd:GetActiveScreen()
    return screen and screen.name == "HUD"
end
local function AddKeyListener(self)
    if self.owner and self.owner:HasTag("player") then
        self[select_mode..'handle'] = {}
        self.inst:ListenForEvent("onremove", function()
            for _, handler in pairs(self[select_mode..'handle']) do
                handler:Remove()
            end
        end)
        self[select_mode.."handle"].keydown = TheInput:AddKeyDownHandler(TUNING.TALLBIRD_SELECT_KEY, function()
    	if IsHUDScreen() and self.owner:HasTag("tallbird_mount") then
            local player = self.owner
            if not player or not player.HUD or TUNING.TALLBIRD_SELECT_MODE==1 then
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
    	end
        end)
    end
end

AddClassPostConstruct("widgets/controls", AddKeyListener)