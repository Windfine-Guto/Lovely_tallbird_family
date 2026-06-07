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
AddRecipe2("tallbird_bell",{Ingredient("opalpreciousgem", 1),Ingredient("beef_bell", 1)},
TECH.MAGIC_THREE,
{atlas = "images/inventoryimages/tallbird_bell_linked.xml",
image = "tallbird_bell_linked.tex"},
{"MAGIC"})