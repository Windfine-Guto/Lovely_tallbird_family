local locale = GLOBAL.LOC.GetLocaleCode()
if locale == "zh" or locale == "zht" or locale=="zhr" then
    modimport("main/string_zh")
else
    modimport("main/string_en")
end