---食材
AddIngredientValues({"tallbird_yolk"}, {egg=4}, true)

---料理
local cooking = require("cooking")
local tallbirdeggs = cooking.recipes["cookpot"]["talleggs"]
if tallbirdeggs then
    tallbirdeggs.test = function(cooker, names, tags)
        return (names.tallbirdegg or names.tallbird_yolk) and tags.veggie and tags.veggie >= 1
    end
end

AddRecipeFilter({
    name = "LOVELY_TALLBIRD_FAMILY",
    atlas = "images/tallbird_researchlab_filter.xml",
    image = "tallbird_researchlab_filter.tex",
    -- image_size = 256,
    -- custom_pos = false
},#CRAFTING_FILTER_DEFS+1)

---配方
AddRecipe2("tallbird_saddle",{Ingredient("rope", 3),Ingredient("beardhair", 10),Ingredient("driftwood_log", 3)},
TECH.SCIENCE_TWO,
{atlas = "images/inventoryimages/tallbird_saddle.xml",
image = "tallbird_saddle.tex"},
{"RIDING"})
AddRecipe2("tallbird_comb_follow",{Ingredient("boneshard", 5)},
TECH.SCIENCE_TWO,
{atlas = "images/inventoryimages/comb2.xml",
image = "comb2.tex"},
{"TOOLS"})
AddRecipe2("new_tallbirdnest_item",{Ingredient("cutgrass", 3),Ingredient("tallbirdegg", 1)},
TECH.SCIENCE_ONE,
{atlas = "images/inventoryimages/new_tallbirdnest.xml",
image = "new_tallbirdnest.tex"},
{"TOOLS"})
AddRecipe2("beak_carrot_bird_rod",{Ingredient("oceanfishingrod", 1),Ingredient("malbatross_beak", 1)},
TECH.MAGIC_THREE,
{atlas = "images/inventoryimages/beak_carrot_bird_rod.xml",
image = "beak_carrot_bird_rod.tex"},
{"MAGIC"})
AddRecipe2("armor_eggshell",{Ingredient("tallbird_eggshell1", 5,"images/inventoryimages/tallbird_eggshell1.xml", "tallbird_eggshell1.tex"),
Ingredient("tallbird_eggshell2", 5,"images/inventoryimages/tallbird_eggshell2.xml", "tallbird_eggshell2.tex")},
TECH.SCIENCE_TWO,
{atlas = "images/inventoryimages/armor_eggshell.xml",
image = "armor_eggshell.tex"},
{"ARMOUR"})
AddRecipe2("tallbird_egg_oversized_builder",{Ingredient(TECH_INGREDIENT.SCULPTING, 2),Ingredient("tallbirdegg", 6),Ingredient("nightmarefuel", 7)},
TECH.SCULPTING_ONE,
{nounlock = true, actionstr="SCULPTING",
atlas = "images/inventoryimages/tallbird_egg_oversized.xml",
image = "tallbird_egg_oversized.tex"},
{"CRAFTING_STATION"})
AddRecipe2("tallbird_flute",{Ingredient("opalpreciousgem", 1),Ingredient("panflute", 1),Ingredient("cutreeds",1)},
TECH.MAGIC_THREE,
{atlas = "images/inventoryimages/tallbird_flute_work.xml",
image = "tallbird_flute_work.tex"},
{"MAGIC"})
AddRecipe2("egg_box",{Ingredient("papyrus", 3),Ingredient("beeswax", 1)},
TECH.SCIENCE_TWO,
{atlas = "images/inventoryimages/egg_box.xml",
image = "egg_box.tex"},
{"CONTAINERS"})
AddDeconstructRecipe("armor_halfshell", {Ingredient("tallbird_eggshell1", 6,"images/inventoryimages/tallbird_eggshell1.xml", "tallbird_eggshell1.tex")})
AddDeconstructRecipe("hat_eggshell", {Ingredient("tallbird_eggshell1", 8,"images/inventoryimages/tallbird_eggshell1.xml", "tallbird_eggshell1.tex")})

AddRecipeToFilter("tallbird_saddle","LOVELY_TALLBIRD_FAMILY")
AddRecipeToFilter("tallbird_comb_follow","LOVELY_TALLBIRD_FAMILY")
AddRecipeToFilter("new_tallbirdnest_item","LOVELY_TALLBIRD_FAMILY")
AddRecipeToFilter("beak_carrot_bird_rod","LOVELY_TALLBIRD_FAMILY")
AddRecipeToFilter("armor_eggshell","LOVELY_TALLBIRD_FAMILY")
AddRecipeToFilter("tallbird_egg_oversized_builder","LOVELY_TALLBIRD_FAMILY")
AddRecipeToFilter("tallbird_flute","LOVELY_TALLBIRD_FAMILY")
AddRecipeToFilter("egg_box","LOVELY_TALLBIRD_FAMILY")