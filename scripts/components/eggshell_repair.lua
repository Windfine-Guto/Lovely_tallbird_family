local Eggshell_Repair = Class(function(self, inst)
    self.inst = inst
end,
nil,
{

})

function Eggshell_Repair:Repair(inst,target)
    local con = target.components.armor and target.components.armor.maxcondition * 0.1
    if con then
        target.components.armor:Repair(con)
        if inst.components.stackable then
            inst.components.stackable:Get():Remove()
        else
            inst:Remove()
        end
    end
    return true
end

return Eggshell_Repair