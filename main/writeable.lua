local writeables = require("writeables")

-- 公共基础配置
local base_layout = {
    prompt = STRINGS.TALLBIRD_NAMED_WRITEABLE.prompt,
    animbank = "ui_board_5x3",
    animbuild = "ui_board_5x3",
    menuoffset = Vector3(6, -70, 0),
    maxcharacters = TUNING.BEEFALO_NAMING_MAX_LENGTH or 80,
    defaulttext = function(inst, doer)
        local name = (doer and doer.name) or STRINGS.TALLBIRD_NAMED_WRITEABLE.noname
        return name..STRINGS.TALLBIRD_NAMED_WRITEABLE.text0 end,
    cancelbtn = { text = STRINGS.TALLBIRD_NAMED_WRITEABLE.text1, control = CONTROL_CANCEL },
    acceptbtn = { text = STRINGS.TALLBIRD_NAMED_WRITEABLE.text3, control = CONTROL_ACCEPT },
}

if not TheNet:IsDedicated() then
    local BIRD_NAMES = {
        "小短腿", "飞毛腿", "尖嘴巴", "长睫毛",
        "跳跳","大眼睛","黑汤圆","乒乓球","炸弹","哈基鸟","小鸡","坤坤","大长腿","活珠子",
        "蛋蛋","咕咕鸡","花生","小丸子","肉丸","球球","大鸡腿","皮球","瓜子","蹦蹦",
        "飞飞","小西瓜","笨蛋","臭鸟","月亮","皮蛋","鸡蛋","鸟蛋","鸟士比亚","鸟加索",
    }
    base_layout.middlebtn = {
        text = STRINGS.TALLBIRD_NAMED_WRITEABLE.text2,
        cb = function(inst, doer, widget)
            local name = BIRD_NAMES[math.random(#BIRD_NAMES)]
            widget:OverrideText(name)
        end,
        control = CONTROL_MENU_MISC_2,
    }
end

writeables.AddLayout("tallbird", base_layout)
writeables.AddLayout("teenbird", base_layout)
writeables.AddLayout("smallbird", base_layout)