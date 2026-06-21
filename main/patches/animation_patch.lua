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
    if inst and inst:HasTag("tallbird") then
        print(anim)
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