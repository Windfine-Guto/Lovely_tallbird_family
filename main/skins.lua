if GetModConfigData('lovely_tallbird_family'..'skins') then
modimport("main/glassic_api_loader")
local modname = KnownModIndex:GetModActualName(folder_name) or folder_name or "tallbird"

local skin_prefabs = LoadPrefabFile("scripts/prefabs/tallbird_skins", nil, MODS_ROOT..modname.."/")
local tallbird_skins = {}
for _, prefab in ipairs(skin_prefabs) do
    table.insert(tallbird_skins, prefab.name)
end

local skin_prefabs_teen = LoadPrefabFile("scripts/prefabs/teenbird_skins", nil, MODS_ROOT..modname.."/")
local teenbird_skins = {}
for _, prefab in ipairs(skin_prefabs_teen) do
    table.insert(teenbird_skins, prefab.name)
end

local skin_prefabs_small = LoadPrefabFile("scripts/prefabs/smallbird_skins", nil, MODS_ROOT..modname.."/")
local smallbird_skins = {}
for _, prefab in ipairs(skin_prefabs_small) do
    table.insert(smallbird_skins, prefab.name)
end


GlassicAPI.SkinHandler.AddModSkins({
    tallbird = tallbird_skins,
    teenbird = teenbird_skins,
    smallbird = smallbird_skins,
})
end