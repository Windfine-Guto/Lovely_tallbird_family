local Bird_leave = Class(function(self, inst)
    self.inst = inst
end,
nil,
{
    
})

function Bird_leave:Leave(inst,target,doer)
    if target.components.bird_cultivate and target.components.bird_cultivate.wild==false then
        target.components.bird_cultivate:NoLeader(doer)
        if not target:HasTag("bird_leaver") then
            target:AddTag("bird_leaver")
        end
        target:RemoveTag("bird_follower")
        if target.sg then
            target.sg:GoToState("idle_peep")
            if target.components.sleeper and target.components.sleeper:IsAsleep() then
                target.components.sleeper:WakeUp()
            end
        end
        if inst.components.stackable then
            inst.components.stackable:Get():Remove()
        else
            inst:Remove()
        end
    end
    return true
end


return Bird_leave