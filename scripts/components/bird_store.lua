local Bird_Store = Class(function(self, inst)
    self.inst = inst
    self.store = false
    self.all_followers = {}
    self.playerid = nil
end,
nil,
{
    
})

function Bird_Store:Store(owner)
    self.playerid = owner.userid or nil
    self.all_followers = {}
    self.inst:RemoveTag("bird_store")
    self.inst:AddTag("bird_summon")
    self.store = true
    local followers = owner.components.leader and owner.components.leader.followers or {}
    for follower, _ in pairs(followers) do
        if follower:HasTag("lovely_bird") then
            local savedata = follower:GetSaveRecord()
            table.insert(self.all_followers, savedata)
            follower:AddTag("notarget")
            follower:AddTag("NOCLICK")
            follower.persists = false
            if follower.components.health then
                follower.components.health:SetInvincible(true)
            end
            follower:DoTaskInTime(math.random() * 0.2, function(follower)
            local fx = SpawnPrefab("spawn_fx_small")
                fx.Transform:SetPosition(follower.Transform:GetWorldPosition())
                if not follower.components.colourtweener then
                    follower:AddComponent("colourtweener")
                end
                follower.components.colourtweener:StartTween(
                    {0, 0, 0, 1},
                    13 * FRAMES,
                    follower.Remove)
            end)
        end
    end
    if self.inst.components.inventoryitem then
        self.inst.components.inventoryitem.atlasname = "images/inventoryimages/tallbird_bell_linked.xml"
        self.inst.components.inventoryitem:ChangeImageName("tallbird_bell_linked")
    end
    return true
end

function Bird_Store:Summon(owner)
    if self.playerid and self.playerid~=owner.userid then
        local talker = owner.components.talker
        if talker then
            talker:Say(GetString(owner,"ANNOUNCE_NOT_MY_BIRDS"))
        end
        return false
    end
    self.inst:RemoveTag("bird_summon")
    self.inst:AddTag("bird_store")
    self.store = false
    for _, savedata in pairs(self.all_followers) do
        owner:DoTaskInTime(0.2 * math.random(), function(owner)
        local bird = SpawnSaveRecord(savedata)
            owner.components.leader:AddFollower(bird)
            bird:DoTaskInTime(0, function(bird)
                if owner:IsValid() and not bird:IsNear(owner, 8) then
                    bird.Transform:SetPosition(owner.Transform:GetWorldPosition())
                    bird.sg:GoToState("idle")
                end
                
            end)
        local fx = SpawnPrefab("spawn_fx_small")
        fx.Transform:SetPosition(bird.Transform:GetWorldPosition())
        end)
    end
    if self.inst.components.inventoryitem then
        self.inst.components.inventoryitem.atlasname = "images/inventoryimages/tallbird_bell.xml"
        self.inst.components.inventoryitem:ChangeImageName("tallbird_bell")
    end
    self.playerid = nil
    return true
end

function Bird_Store:OnSave()
    return {
        all_followers = self.all_followers,
        store = self.store,
        playerid = self.playerid,
    }
end
function Bird_Store:OnLoad(data)
    if data then
        self.all_followers = data.all_followers
        self.store = data.store
        self.playerid = data.playerid
    end
    if self.store==false then
        self.inst:RemoveTag("bird_summon")
        self.inst:AddTag("bird_store")
        if self.inst.components.inventoryitem then
            self.inst.components.inventoryitem.atlasname = "images/inventoryimages/tallbird_bell.xml"
            self.inst.components.inventoryitem:ChangeImageName("tallbird_bell")
        end
    else
        self.inst:RemoveTag("bird_store")
        self.inst:AddTag("bird_summon")
        if self.inst.components.inventoryitem then
            self.inst.components.inventoryitem.atlasname = "images/inventoryimages/tallbird_bell_linked.xml"
            self.inst.components.inventoryitem:ChangeImageName("tallbird_bell_linked")
        end
    end
end

return Bird_Store