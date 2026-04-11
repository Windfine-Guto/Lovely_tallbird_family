local Bird_Named = Class(function(self, inst)
    self.inst = inst
end,
nil,
{
    
})

function Bird_Named:Named(inst,target,doer)
    if target.components.writeable and target.components.named then
        target.components.writeable:BeginWriting(doer)
        if inst.components.stackable then
            inst.components.stackable:Get():Remove()
        else
            inst:Remove()
        end
    end
    return true
end

return Bird_Named