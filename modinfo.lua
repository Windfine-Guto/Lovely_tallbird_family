local modid = 'lovely_tallbird_family'
local cur = (locale == 'zh' or locale == 'zhr') and 'zh' or 'en'

version = '1.5.0'
author = 'over_dragon、Guto'

forumthread = ''
api_version = 10
priority = -987 -- 加载优先级，越低加载越晚，默认为0

dst_compatible = true -- 联机版适配性
dont_starve_compatible = false -- 单机版适配性
reign_of_giants_compatible = false -- 单机版：巨人国适配性
all_clients_require_mod = true -- 服务端/所有端模组
-- server_only_mod = true -- 仅服务端模组
-- client_only_mod = true -- 仅客户端模组
server_filter_tags = {} -- 创意工坊模组分类标签
icon_atlas = 'modicon.xml' -- 图集
icon = 'modicon.tex' -- 图标



local LANGS = {
    ['zh'] = {
        name = '可爱鸟家族',
        description = '放心的养鸟，遛鸟，鸟绝不会让你失望的',
        config = {
            {modid..'language','语言','',true,{
                {'中文',true},
                {'英文',false}
            }},
            {'高脚鸟蛋'},
            {modid..'_egghatch','高脚鸟蛋孵化时间','原版是3天',1,{
                {'1分钟',1/24},
                {'1天',1/3},
                {'2天',2/3},
                {'3天',1}
            }},
            {'小鸟'},
            {modid..'_smallbirdhealth','小鸟生命上限倍率','调整生命上限倍率',1,{
                {'1.0',1},
                {'2.0',2},
                {'3.0',3},
                {'4.0',4},
                {'5.0',5},
                {'6.0',6},
                {'7.0',7},
                {'8.0',8},
                {'9.0',9},
                {'10.0',10}
            }},
            {modid..'_smallbirddamage','小鸟伤害倍率','调整伤害倍率',1,{
                {'1.0',1},
                {'2.0',2},
                {'3.0',3},
                {'4.0',4},
                {'5.0',5},
                {'6.0',6},
                {'7.0',7},
                {'8.0',8},
                {'9.0',9},
                {'10.0',10}
            }},
            {modid..'_smallbirdhunger','小鸟饥饿值倍率','饥饿速度不变',1,{
                {'1.0',1},
                {'2.0',2},
                {'3.0',3},
                {'4.0',4},
                {'5.0',5},
                {'6.0',6},
                {'7.0',7},
                {'8.0',8},
                {'9.0',9},
                {'10.0',10}
            }},
            {modid..'_smallbirdhunger_speed','小鸟饥饿速度','',20,{
                {'20饥饿值/天',20},
                {'15饥饿值/天',15},
                {'10饥饿值/天',10},
                {'5饥饿值/天',5},
                {'2饥饿值/天',2},
                {'1饥饿值/天',1}
            }},
            {modid..'_smallbirdgrowtime','小鸟成长时间调整','',1,{
                {'10天',1},
                {'5天',2},
                {'2天',5},
                {'1天',10},
                {'半天',20},
                {'1分钟',80},
                {'10秒',480},
            }},
            {modid..'_smallbirdgrow','小鸟不长大','玩家养的小鸟永远保持幼年，合适当宠物',false,{
                {'开启',true},
                {'关闭',false}
            }},
            {modid..'_smallbirdprotect','小鸟血线保护','血量不会低于10%，且低于20%不参与战斗，血量恢复100%时恢复正常',true,{
                {'开启',true},
                {'关闭',false}
            }},
            {modid..'_smallbirdgifts','小鸟的礼物','每1.5天随机带点种子给你，每7天有10%概率带个特殊种子',true,{
                {'开启',true},
                {'关闭',false}
            }},
            {modid..'_smallbirdwaterwalk','小鸟水上行走','出海也能跟着你',true,{
                {'开启',true},
                {'关闭',false}
            }},
            {'小高脚鸟'},
            {modid..'_teenbirdhealth','青年高脚鸟生命上限倍率','调整生命上限倍率',1,{
                {'1.0',1},
                {'2.0',2},
                {'3.0',3},
                {'4.0',4},
                {'5.0',5},
                {'6.0',6},
                {'7.0',7},
                {'8.0',8},
                {'9.0',9},
                {'10.0',10}
            }},
            {modid..'_teenbirddamage','青年高脚鸟伤害倍率','调整伤害倍率',1,{
                {'1.0',1},
                {'2.0',2},
                {'3.0',3},
                {'4.0',4},
                {'5.0',5},
                {'6.0',6},
                {'7.0',7},
                {'8.0',8},
                {'9.0',9},
                {'10.0',10}
            }},
            {modid..'_teenbirdhunger','青年高脚鸟饥饿值倍率','饥饿速度不变',1,{
                {'1.0',1},
                {'2.0',2},
                {'3.0',3},
                {'4.0',4},
                {'5.0',5},
                {'6.0',6},
                {'7.0',7},
                {'8.0',8},
                {'9.0',9},
                {'10.0',10}
            }},
            {modid..'_teenbirdhunger_speed','小高脚鸟饥饿速度','注意，会对所有青年高脚鸟生效，饥饿速度过低野生青年高脚鸟饿不死',60,{
                {'60饥饿值/天',60},
                {'40饥饿值/天',40},
                {'20饥饿值/天',20},
                {'10饥饿值/天',10},
                {'5饥饿值/天',5},
                {'1饥饿值/天',1}
            }},
            {modid..'_teenbirdgrowtime','青年高脚鸟成长时间调整','',1,{
                {'18天',1},
                {'9天',2},
                {'6天',3},
                {'3天',6},
                {'1天',18},
                {'半天',36},
                {'18秒',480},
            }},
            {modid..'_teenbirdprotect','青年高脚鸟血线保护','血量不会低于10%，且低于20%不参与战斗，血量恢复50%以上时恢复正常',true,{
                {'开启',true},
                {'关闭',false}
            }},
            {modid..'_teenbirdgifts','青年高脚鸟的礼物','每3天带个高脚鸟蛋给你，每5天有10%概率带个特殊种子',true,{
                {'开启',true},
                {'关闭',false}
            }},
            {modid..'_teenbirdwaterwalk','青年高脚鸟水上行走','出海也能跟着你',true,{
                {'开启',true},
                {'关闭',false}
            }},
            {'高脚鸟'},
            {modid..'_tallbirdhealth','高脚鸟生命上限倍率','调整生命上限倍率',1,{
                {'1.0',1},
                {'2.0',2},
                {'3.0',3},
                {'4.0',4},
                {'5.0',5},
                {'6.0',6},
                {'7.0',7},
                {'8.0',8},
                {'9.0',9},
                {'10.0',10}
            }},
            {modid..'_tallbirddamage','高脚鸟伤害倍率','调整伤害倍率',1,{
                {'1.0',1},
                {'2.0',2},
                {'3.0',3},
                {'4.0',4},
                {'5.0',5},
                {'6.0',6},
                {'7.0',7},
                {'8.0',8},
                {'9.0',9},
                {'10.0',10}
            }},
            {modid..'_tallbirdprotect','高脚鸟血线保护','血量不会低于10%，且低于20%不参与战斗，血量恢复50%以上时恢复正常',true,{
                {'开启',true},
                {'关闭',false}
            }},
            {modid..'_tallbirdgifts','高脚鸟的礼物','每2天带个高脚鸟蛋给你，每3天有20%概率带个特殊种子',true,{
                {'开启',true},
                {'关闭',false}
            }},
            {modid..'_tallbirdwaterwalk','高脚鸟水上行走','出海也能跟着你',true,{
                {'开启',true},
                {'关闭',false}
            }},
            {'全部鸟'},
            {modid..'_birdfollow','鸟跟随上下洞穴','但是换角色时鸟会消失',true,{
                {'开启',true},
                {'关闭',false}
            }},
            {modid..'sanityaura','鸟正向理智光环','最高25理智/分钟',true,{
                {'开启',true},
                {'关闭',false}
            }}
        }
    },
    ['en'] = {
        name = 'Lovely Tallbird Family',
        description = 'Raise and walk your birds with peace of mind — they\'ll never let you down!',
        config = {
            {'Language'},
            {modid..'language','Language','',false,{
                {'Chinese', true},
                {'English', false}
            }},
            {'Tallbird Egg'},
            {modid..'_egghatch','Morsel Egg Incubation Time','Vanilla: 3 days',1,{
                {'1 minute',1/24},
                {'1 Day',1/3},
                {'2 Days',2/3},
                {'3 Days',1}
            }},
            {'Smallbird'},
            {modid..'_smallbirdhealth','Smallbird Max Health Multiplier','Adjust max health multiplier',1,{
                {'1.0',1},
                {'2.0',2},
                {'3.0',3},
                {'4.0',4},
                {'5.0',5},
                {'6.0',6},
                {'7.0',7},
                {'8.0',8},
                {'9.0',9},
                {'10.0',10}
            }},
            {modid..'_smallbirddamage','Smallbird Damage Multiplier','Adjust damage multiplier',1,{
                {'1.0',1},
                {'2.0',2},
                {'3.0',3},
                {'4.0',4},
                {'5.0',5},
                {'6.0',6},
                {'7.0',7},
                {'8.0',8},
                {'9.0',9},
                {'10.0',10}
            }},
            {modid..'_smallbirdhunger','Smallbird Hunger Rate Multiplier','Hunger drain speed remains unchanged',1,{
                {'1.0',1},
                {'2.0',2},
                {'3.0',3},
                {'4.0',4},
                {'5.0',5},
                {'6.0',6},
                {'7.0',7},
                {'8.0',8},
                {'9.0',9},
                {'10.0',10}
            }},
            {modid..'_smallbirdhunger_speed','Smallbird Hunger Drain Rate','',20,{
                {'20 Hunger/Day',20},
                {'15 Hunger/Day',15},
                {'10 Hunger/Day',10},
                {'5 Hunger/Day',5},
                {'2 Hunger/Day',2},
                {'1 Hunger/Day',1}
            }},
            {modid..'_smallbirdgrowtime','Small Bird Growth Time Adjustment','',1,{
                {'10 Days',1},
                {'5 Days',2},
                {'2 Days',5},
                {'1 Day',10},
                {'Half Day',20},
                {'1 Minute',80},
                {'10 Seconds',480},
            }},
            {modid..'_smallbirdgrow','Smallbird Never Grows Up','Player-raised smallbirds will remain babies forever, suitable as pets.',false,{
                {'Enable',true},
                {'Disable',false}
            }},
            {modid..'_smallbirdprotect','Smallbird Health Threshold Protection','Health never drops below 10%; stops fighting below 20% and resumes when fully healed',true,{
                {'Enable',true},
                {'Disable',false}
            }},
            {modid..'_smallbirdgifts','Smallbird Gift Giving','Randomly brings seeds every 1.5 days; 10% chance for a special seed every 7 days',true,{
                {'Enable',true},
                {'Disable',false}
            }},
            {modid..'_smallbirdwaterwalk','Smallbird Water Walking','Follows you even across the ocean',true,{
                {'Enable',true},
                {'Disable',false}
            }},
            {'Teenbird'},
            {modid..'_teenbirdhealth','Teenbird Max Health Multiplier','Adjust max health multiplier',1,{
                {'1.0',1},
                {'2.0',2},
                {'3.0',3},
                {'4.0',4},
                {'5.0',5},
                {'6.0',6},
                {'7.0',7},
                {'8.0',8},
                {'9.0',9},
                {'10.0',10}
            }},
            {modid..'_teenbirddamage','Teenbird Damage Multiplier','Adjust damage multiplier',1,{
                {'1.0',1},
                {'2.0',2},
                {'3.0',3},
                {'4.0',4},
                {'5.0',5},
                {'6.0',6},
                {'7.0',7},
                {'8.0',8},
                {'9.0',9},
                {'10.0',10}
            }},
            {modid..'_teenbirdhunger','Teenbird Hunger Rate Multiplier','Hunger drain speed remains unchanged',1,{
                {'1.0',1},
                {'2.0',2},
                {'3.0',3},
                {'4.0',4},
                {'5.0',5},
                {'6.0',6},
                {'7.0',7},
                {'8.0',8},
                {'9.0',9},
                {'10.0',10}
            }},
            {modid..'_teenbirdhunger_speed','Teenbird Hunger Drain Rate','Note: Affects all teenbirds. If the hunger drain rate is too low, wild teenbirds may not starve.',60,{
                {'60 Hunger/Day',60},
                {'40 Hunger/Day',40},
                {'20 Hunger/Day',20},
                {'10 Hunger/Day',10},
                {'5 Hunger/Day',5},
                {'1 Hunger/Day',1}
            }},
            {modid..'_teenbirdgrowtime','Juvenile Tallbird Growth Time','',1,{
                {'18 Days',1},
                {'9 Days',2},
                {'6 Days',3},
                {'3 Days',6},
                {'1 Day',18},
                {'Half Day',36},
                {'18 Seconds',480},
            }},
            {modid..'_teenbirdprotect','Teenbird Health Threshold Protection','Health never drops below 10%; stops fighting below 20% and resumes when above 50% health',true,{
                {'Enable',true},
                {'Disable',false}
            }},
            {modid..'_teenbirdgifts','Teenbird Gift Giving','Brings a Morsel Egg every 3 days; 10% chance for a special seed every 5 days',true,{
                {'Enable',true},
                {'Disable',false}
            }},
            {modid..'_teenbirdwaterwalk','Teenbird Water Walking','Follows you even across the ocean',true,{
                {'Enable',true},
                {'Disable',false}
            }},
            {'Tallbird'},
            {modid..'_tallbirdhealth','Tallbird Health Multiplier','Adjust health multiplier',1,{
                {'1.0',1},
                {'2.0',2},
                {'3.0',3},
                {'4.0',4},
                {'5.0',5},
                {'6.0',6},
                {'7.0',7},
                {'8.0',8},
                {'9.0',9},
                {'10.0',10}
            }},
            {modid..'_tallbirddamage','Tallbird Damage Multiplier','Adjust damage multiplier',1,{
                {'1.0',1},
                {'2.0',2},
                {'3.0',3},
                {'4.0',4},
                {'5.0',5},
                {'6.0',6},
                {'7.0',7},
                {'8.0',8},
                {'9.0',9},
                {'10.0',10}
            }},
            {modid..'_tallbirdprotect','Tallbird Health Protection','Health will not drop below 10%, and will not engage in combat when below 20%. Returns to normal when health recovers above 50%',true,{
                {'Enable',true},
                {'Disable',false}
            }},
            {modid..'_tallbirdgifts','Tallbird Gifts','Brings a tallbird egg every 2 days, and has a 20% chance to bring a special seed every 3 days',true,{
                {'Enable',true},
                {'Disable',false}
            }},
            {modid..'_tallbirdwaterwalk','Tallbird Water Walking','Can follow you on water',true,{
                {'Enable',true},
                {'Disable',false}
            }},
            {'All Bird'},
            {modid..'_birdfollow','Bird Cave Transition Follow','Disappears when switching characters',true,{
                {'Enable',true},
                {'Disable',false}
            }},
            {modid..'sanityaura', 'Avian Positive Sanity Aura', 'Max 25 Sanity/Min', true, {
                {'Enable', true},
                {'Disable', false}
            }}
        }
    }
}

name = LANGS[cur].name
description = version..'\n'..LANGS[cur].description
local config = LANGS[cur].config or {}
local _configuration_options = {}
for i = 1, #config do
    local options = {}
    if config[i][5] then
        for k = 1, #config[i][5] do
            options[k] = {description = config[i][5][k][1], data = config[i][5][k][2]}
        end
    end
    _configuration_options[i] = {
        name = config[i][1],
        label = config[i][2],
        hover = config[i][3] or '',
        default = config[i][4] or false,
        options = #options>0 and options or {{description = "", data = false}},
    }
end

configuration_options = _configuration_options