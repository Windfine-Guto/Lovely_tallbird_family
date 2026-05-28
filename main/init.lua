GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})

Assets = {
	Asset("ANIM", "anim/spell_icons_tallbird.zip"),
    Asset("ANIM","anim/tallbird_health.zip"),
    Asset("ANIM","anim/smallbird_basic_water.zip"),
}

PrefabFiles = GetModConfigData('lovely_tallbird_family'..'skins') and {
    "tallbird",
    "tallbird_saddle",
    "tallbird_eggshell",
    "tallbird_skins",
    "teenbird_skins",
    "smallbird_skins",
    "tallbird_comb",
    "tallbird_buffs",
    "tallbird_eyefx",
    "lunar_tallbird_laser",
    "new_tallbirdnest",
    "beak_carrot_bird_rod",
    "tallbird_yolk",
    "armor_eggshell",
    "eggshellfx_armor"
}
or {
    "tallbird",
    "tallbird_saddle",
    "tallbird_eggshell",
    "tallbird_comb",
    "tallbird_buffs",
    "tallbird_eyefx",
    "lunar_tallbird_laser",
    "new_tallbirdnest",
    "beak_carrot_bird_rod",
    "tallbird_yolk",
    "armor_eggshell",
    "eggshellfx_armor"
}