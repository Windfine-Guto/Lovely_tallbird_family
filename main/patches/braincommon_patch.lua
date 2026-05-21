-- 扩展 CHOP 的 Starter
local BrainCommon = require("brains/braincommon")

local oldChopStarter = BrainCommon.AssistLeaderDefaults.CHOP.Starter
BrainCommon.AssistLeaderDefaults.CHOP.Starter = function(inst, leaderdist, finddist)
    if oldChopStarter(inst, leaderdist, finddist) then
        return true
    end
    local leader = inst.components.follower and inst.components.follower:GetLeader()
    if leader and leader:GetBufferedAction() then
        local action = leader:GetBufferedAction().action
        return action == ACTIONS.BIRD_CHOP or action == ACTIONS.CHOP
    end
    return false
end

local oldMineStarter = BrainCommon.AssistLeaderDefaults.MINE.Starter
BrainCommon.AssistLeaderDefaults.MINE.Starter = function(inst, leaderdist, finddist)
    if oldMineStarter(inst, leaderdist, finddist) then
        return true
    end
    local leader = inst.components.follower and inst.components.follower:GetLeader()
    if leader and leader:GetBufferedAction() then
        local action = leader:GetBufferedAction().action
        return action == ACTIONS.BIRD_MINE or action == ACTIONS.MINE
    end
    return false
end