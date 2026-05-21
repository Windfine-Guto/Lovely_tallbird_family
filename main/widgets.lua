---轮盘UI 血量UI
local CastSelect = require("widgets/castselect")
local TallbirdMountHealth = require "widgets/tallbird_mount_health"
AddClassPostConstruct("widgets/controls", function(self)
    if not self.owner then
        return
    end
    self.tallbird_atk_select = self:AddChild(CastSelect(self.owner))
    self.tallbird_atk_select:Hide()

    self.TallbirdMountHealth = self.bottom_root:AddChild(TallbirdMountHealth(self.owner))
    self.TallbirdMountHealth:MoveToBack()
end)

local InventoryBar = require "widgets/inventorybar"
local OldRebuild = InventoryBar.Rebuild
function InventoryBar:Rebuild(...)
    OldRebuild(self, ...)
    if self.owner then
        self.owner:PushEvent("RepositionStatusBar_Tallbird")
    end
end