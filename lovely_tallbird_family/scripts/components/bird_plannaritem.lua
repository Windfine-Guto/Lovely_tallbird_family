local Bird_plannaritem = Class(function(self, inst)
    self.inst = inst
end,
nil,
{
    
})

function Bird_plannaritem:Do(inst,target)
    if target.components.bird_cultivate and target.components.bird_cultivate.plannar==false then
        target.components.bird_cultivate.plannar=true
        target.components.bird_cultivate:Updata()
        if inst.components.stackable then
            inst.components.stackable:Get():Remove()
        else
            inst:Remove()
        end
        
    end
    return true
end

return Bird_plannaritem