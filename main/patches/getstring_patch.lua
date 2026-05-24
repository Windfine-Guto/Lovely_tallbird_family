local originalGetString = _G.GetString

_G.GetString = function(inst, stringtype, modifier, ...)
    if stringtype == "ANNOUNCE_MOUNT_LOWHEALTH"
    and inst and inst:HasTag("tallbird_mount") then
        return originalGetString(inst, "ANNOUNCE_TALLBIRD_MOUNT_LOWHEALTH", modifier, ...)
    end
    return originalGetString(inst, stringtype, modifier, ...)
end