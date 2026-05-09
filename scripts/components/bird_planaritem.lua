local Bird_planaritem = Class(function(self, inst)
    self.inst = inst
end,
nil,
{
    
})

function Bird_planaritem:Do(inst,target)
    if target.components.bird_cultivate and target.components.bird_cultivate.planar~=true then
        target.components.bird_cultivate.planar=true
        target.components.bird_cultivate:Updata()
        if inst.components.stackable then
            inst.components.stackable:Get():Remove()
        else
            inst:Remove()
        end
        
    end
    return true
end

return Bird_planaritem