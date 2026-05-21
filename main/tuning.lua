local modid = 'lovely_tallbird_family'

TUNING.TEENBIRD_DAMAGE=37.5*GetModConfigData(modid..'_teenbirddamage')
TUNING.TALLBIRD_DAMAGE=50*GetModConfigData(modid..'_tallbirddamage')
TUNING.SMALLBIRD_HATCH_TIME=TUNING.SMALLBIRD_HATCH_TIME*GetModConfigData(modid..'_egghatch')
TUNING.SMALLBIRD_HUNGER=TUNING.SMALLBIRD_HUNGER*GetModConfigData(modid..'_smallbirdhunger')
TUNING.TEENBIRD_HUNGER=TUNING.TEENBIRD_HUNGER*GetModConfigData(modid..'_teenbirdhunger')
TUNING.SMALLBIRD_GROW_TIME=TUNING.SMALLBIRD_GROW_TIME/GetModConfigData(modid..'_smallbirdgrowtime')
TUNING.TEENBIRD_GROW_TIME=TUNING.TEENBIRD_GROW_TIME/GetModConfigData(modid..'_teenbirdgrowtime')
TUNING.TALLBIRD_SELECT_MODE=GetModConfigData(modid..'_selecttallbird') or 1
TUNING.TALLBIRD_SELECT_KEY=GetModConfigData(modid..'select_op') or 122
TUNING.TALLBIRD_PLANAR_DAMAGE = GetModConfigData(modid..'_planar_damage')
TUNING.TALLBIRD_PLANAR_ABSOR = GetModConfigData(modid..'_planar_absor')
TUNING.TALLBIRD_PLANAR_DEFENSE = GetModConfigData(modid..'_planar_defense')
TUNING.TALLBIRD_PLAYER_DAMAGE = GetModConfigData(modid..'_add_damage')
TUNING.TALLBIRD_PLAYER_ABSOR = GetModConfigData(modid..'_add_absor')
TUNING.TALLBIRD_PLAYER_SPEED = GetModConfigData(modid..'_add_speed')
TUNING.TALLBIRD_PLAYER_LIMIT = GetModConfigData(modid..'_add_limit')
TUNING.TALLBIRD_PLANAR_TIME = GetModConfigData(modid..'buff_time')
TUNING.TALLBIRD_LASER_DAMAGE = GetModConfigData(modid..'laser_damage')
TUNING.TALLBIRD_TENTACLE_NUM = GetModConfigData(modid..'tentacle_num')


TUNING.LOVELY_BIRD = {
    TAG = GetModConfigData(modid..'_tallbird_follow') and {"tallbird"} or { "lovely_bird","smallbird","teenbird","tallbird" }
}