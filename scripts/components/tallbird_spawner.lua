local Tallbird_Spawner = Class(function(self, inst)
    self.inst = inst
    self.spawner = false
end,
nil,
{

})

function Tallbird_Spawner:Updata(inst)
    if self.spawner==true then
        if not inst:HasTag("nest_spawner") then
            inst:AddTag("nest_spawner")
        end
        inst:PushEvent("spawner_start")
    else
        if inst:HasTag("nest_spawner") then
            inst:RemoveTag("nest_spawner")
        end
        inst:PushEvent("spawner_stop")
    end
end

function Tallbird_Spawner:OnSave()
    return {
        spawner = self.spawner
    }
end

function Tallbird_Spawner:OnLoad(data)
    if data~=nil then
        self.spawner = data.spawner
    end
    self:Updata(self.inst)
end

return Tallbird_Spawner