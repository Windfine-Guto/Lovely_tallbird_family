local Bird_follow = Class(function(self, inst)
    self.inst = inst
end,
nil,
{
    
})

function Bird_follow:Follow(inst,target,doer)
    if target.components.bird_cultivate then
        doer:PushEvent("makefriend")
        target.components.bird_cultivate:SetLeader(doer)
        if doer:HasTag("bird_family") and target.components.bird_cultivate.wild==true then
            target.components.bird_cultivate.wild=false
            target.components.bird_cultivate:Updata()
        end
        if inst.components.stackable then
            inst.components.stackable:Get():Remove()
        else
            inst:Remove()
        end
    end
    return true
end

return Bird_follow