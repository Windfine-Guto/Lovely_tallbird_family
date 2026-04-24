local Widget = require "widgets/widget"
local Badge = require "widgets/badge"
local UIAnim = require "widgets/uianim"

local HealthBadge = Class(Badge, function(self, config)
    Badge._ctor(self, "tallbird_health", nil, {1, 1, 1, 1}, nil, nil, false)

    self:SetScale(0.9)
    self.num:SetScale(0.9)

    -- self.anim:GetAnimState():Hide("heart")
    -- self.anim:GetAnimState():Hide("bg")
    -- self.anim:GetAnimState():Hide("bg_texture")
    -- self.anim:GetAnimState():Hide("health_meter")
    self.anim:SetScale(0.5)

end)

function HealthBadge:SetPercent(val, max)
    HealthBadge._base.SetPercent(self, val, max)
end

-- 主控件
local Tallbird_Mount_Health = Class(Widget, function(self, owner)
    Widget._ctor(self, "Tallbird_Mount_Health")
    self.owner = owner

    self.isHidden = true
    self.maxHealth = 800
    self.mounted = false

    self.CONFIG = {
        THEME = "Default",
        BG_BRIGHTNESS = 0.6,
        BG_OPACITY = 1.0,
        SCALE = 1.0,
        BASE_X = 0,
        BASE_Y = 95,
        ROOT_Y = 18,
        ROOT_Y_HIDDEN = -130,
    }

    self.root = self:AddChild(Widget("root"))

    local badgeConfig = {
        theme = self.CONFIG.THEME,
        brightness = self.CONFIG.BG_BRIGHTNESS,
        opacity = self.CONFIG.BG_OPACITY,
    }

    self.healthBadge = self.root:AddChild(HealthBadge(badgeConfig))
    self.healthBadge:SetPosition(0, 0)

    if self.healthBadge.bg ~= nil then
        self.CONFIG.ROOT_Y = 18
    elseif self.CONFIG.THEME == "TheForge" then
        self.CONFIG.BASE_Y = self.CONFIG.BASE_Y + 4
    end

    self:Hide()
    self:SetScale(self.CONFIG.SCALE)
    self:SetPosition(self.CONFIG.BASE_X, self.CONFIG.BASE_Y)
    self.root:SetPosition(0, self.CONFIG.ROOT_Y_HIDDEN)

    self.owner:DoTaskInTime(0.1, function()
        if not self.owner.player_classified then return end
        self.owner.player_classified:ListenForEvent("tallbirdDataDirty", function(classified)
            local data = classified.tallbirdData:value()
            if data ~= "dismount" then
                local decoded = json.decode(data)
                self.maxHealth = decoded.maxHealth
                self:UpdateHealth(decoded.health)
                self.mounted = true
                if self.isHidden then self:SlideIn() end
            else
                self.mounted = false
                if not self.isHidden then self:SlideOut() end
            end
        end)
        self.owner.player_classified:ListenForEvent("tallbirdHealthDirty", function(classified)
            self:UpdateHealth(classified.tallbirdHealth:value())
        end)
    end)

    self.owner:ListenForEvent("RepositionStatusBar_Tallbird", function()
        local offset = 0
        if Profile:GetIntegratedBackpack() or TheInput:ControllerAttached() then
            local backpack = self.owner.replica.inventory:GetOverflowContainer()
            if backpack and backpack:IsOpenedBy(self.owner) then
                offset = 45
            end
        end
        if not self.isHidden then
            self:MoveTo(self:GetPosition(), {x = self.CONFIG.BASE_X, y = self.CONFIG.BASE_Y + offset, z = 0}, 0.15)
        else
            self:SetPosition(self.CONFIG.BASE_X, self.CONFIG.BASE_Y + offset)
        end
    end)
end)

function Tallbird_Mount_Health:UpdateHealth(health)
    self.healthBadge:SetPercent(health / self.maxHealth, self.maxHealth)
end

function Tallbird_Mount_Health:SlideIn()
    self.isHidden = false
    self:Show()
    self.root:CancelMoveTo()
    self.root:MoveTo(self.root:GetPosition(), {x = 0, y = self.CONFIG.ROOT_Y, z = 0}, 0.5)
end

function Tallbird_Mount_Health:SlideOut()
    self.isHidden = true
    self.root:CancelMoveTo()
    self.root:MoveTo(self.root:GetPosition(), {x = 0, y = self.CONFIG.ROOT_Y_HIDDEN, z = 0}, 0.5, function()
        self:Hide()
    end)
end

return Tallbird_Mount_Health