local Bird_family = Class(function(self, inst)
    self.inst = inst
    self.number = 0
end,
nil,
{
    
})

local function CanShareTargetWith(dude)
    return dude:HasTag("tallbird") and not dude.components.health:IsDead()
end

local function OnAttacked(inst, data)
    if data.attacker ~= nil then
        inst.components.combat:SetTarget(data.attacker)
        inst.components.combat:ShareTarget(data.attacker, 30, CanShareTargetWith,8)
    end
end

function Bird_family:Updata()
    if self.number>=1 then
        if not self.inst:HasTag("bird_friend") then
            self.inst:AddTag("bird_friend")
        end
    end
    if self.number>=3 then
        if not self.inst:HasTag("bird_friend2") then
            self.inst:AddTag("bird_friend2")
        end
        self.inst:ListenForEvent("attacked",OnAttacked)
    end
    if self.number>=8 then
        if not self.inst:HasTag("bird_family") then
            self.inst:AddTag("bird_family")
        end
    end
end

function Bird_family:OnSave()
    return {
        number = self.number
    }
end
function Bird_family:OnLoad(data)
    if data~=nil then
        self.number = data.number
    end
    self:Updata()
end

return Bird_family