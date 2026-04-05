local Widget = require "widgets/widget"
local UIAnim = require "widgets/uianim"
local easing = require "easing"


local CastSelect = {
    atk_mode = {
        pos = { 0, 150 },
        animbank = "spell_icons_tallbird",
        animbuild = "spell_icons_tallbird",
        animdis = "switch",
        animfoc = "switch_focus"
    },
}
-- 高亮（聚焦）动画
local function OnSelect(anim)
    if anim.currentAnim == anim.animfoc then return end
    anim:SetScale(1, 1)
    anim:GetAnimState():PlayAnimation(anim.animfoc, true)
    anim.currentAnim = anim.animfoc
end

-- 取消高亮（禁用）动画
local function OnUnSelect(anim)
    if anim.currentAnim == anim.animdis then return end
    anim:SetScale(1, 1)
    anim:GetAnimState():PlayAnimation(anim.animdis, true)
    anim.currentAnim = anim.animdis
end

local TallbirdAtkSelect = Class(Widget, function(self, owner)
    Widget._ctor(self, "TallbirdAtkSelect")
    self.owner = owner

    self:SetClickable(true)
    self.casts = {}
    for name, data in pairs(CastSelect) do
        local anim = self:AddChild(UIAnim())
        anim:GetAnimState():SetBank(data.animbank)
        anim:GetAnimState():SetBuild(data.animbuild)
        anim.animdis = data.animdis
        anim.animfoc = data.animfoc
        OnUnSelect(anim)
        self.casts[name] = anim
    end

    self.updating = false
    self.open = false
    self.current_select = nil
    self.start_time = nil
end)

-- 是否可以选择，动画期间禁止选择
function TallbirdAtkSelect:CanSelect()
    return not self.updating
end

-- 选择，填入就选择name，不填就清空选择
function TallbirdAtkSelect:Select(name)
    if self.current_select then
        OnUnSelect(self.casts[self.current_select])
        self.current_select = nil
    end

    if name then
        self.current_select = name
        OnSelect(self.casts[name])
    end
end

-- 显示的时候自动播放动画
function TallbirdAtkSelect:OnShow()
    local mouse = TheInput:GetScreenPosition()
    self:SetPosition(mouse.x, mouse.y)
    self.start_time = GetTime()
    self.updating = true
    self.open = true
    self:StartUpdating()
end

-- 隐藏时停止更新并重置图标位置
function TallbirdAtkSelect:OnHide()
    self:StopUpdating()
    self.updating = false
    self.open = false
    for _, anim in pairs(self.casts) do
        anim:SetPosition(0, 0)
        OnUnSelect(anim)
    end
    self.hovered_spell = nil
end

local duration = 0.5 --动画总持续事件
function TallbirdAtkSelect:OnUpdate(dt)
    local elapsedTime = GetTime() - self.start_time
    if elapsedTime < duration then
        for name, anim in pairs(self.casts) do
            local target_pos = CastSelect[name].pos
            local x = easing.outQuad(elapsedTime, 0, target_pos[1], duration)
            local y = easing.outQuad(elapsedTime, 0, target_pos[2], duration)
            anim:GetAnimState():SetMultColour(1, 1, 1, elapsedTime / duration)
            anim:SetPosition(x, y)
        end
    else
        -- self:StopUpdating()
        self.updating = false
    end
    if self.updating then return end  -- 动画未完成时不允许选择

    local mouse = TheInput:GetScreenPosition()
    local hovered = nil

    for name, anim in pairs(self.casts) do
        local animPos = anim:GetWorldPosition()
        local halfSize = 51   -- 图标半宽，高亮但检测仍用原始大小，避免抖动
        if mouse.x >= animPos.x - halfSize and mouse.x <= animPos.x + halfSize and
           mouse.y >= animPos.y - halfSize and mouse.y <= animPos.y + halfSize then
            hovered = name
            break
        end
    end

    -- 更新高亮状态
    for name, anim in pairs(self.casts) do
        if name == hovered then
            OnSelect(anim)
        else
            OnUnSelect(anim)
        end
    end

    self.hovered_spell = hovered
    if not self.owner:HasTag("tallbird_mount") then
        self:Hide()
    end
end
function TallbirdAtkSelect:OnMouseButton(button, down, x, y)
    -- 只处理左键松开（click）
    if button == MOUSEBUTTON_LEFT and not down then
        if self.hovered_spell then
            local attack_mode = "tallbird"
            if self.owner._tallbird_mount_aoe_leg == true then
                self.owner._tallbird_mount_aoe_leg = false
            else
                self.owner._tallbird_mount_aoe_leg = true
            end
        	SendModRPCToServer(MOD_RPC[attack_mode..'attack'][attack_mode..'attack'],self.owner._tallbird_mount_aoe_leg)
            self:Hide()
        end
        return true  -- 表示已处理
    end
    -- 不处理其他按键，让父控件继续
    return false
end

return TallbirdAtkSelect