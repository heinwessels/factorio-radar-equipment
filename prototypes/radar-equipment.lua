local item_sounds = require("__base__.prototypes.item_sounds")

---@type data.TechnologyPrototype
local tech_to_mimic
for _, technology in pairs(data.raw.technology) do
    if technology.effects then
        for _, effect in pairs(technology.effects) do
            if effect.type == "unlock-recipe" then
                if effect.recipe == "tank" then
                  tech_to_mimic = technology
                  break
                end
            end
        end
        if tech_to_mimic then break end
    end
end

data:extend{
  {
    type = "item",
    name = "radar-equipment",
    icon = "__radar-equipment__/graphics/icon.png",
    place_as_equipment_result = "radar-equipment",
    subgroup = "utility-equipment",
    order = "f[radar]-a[radar-equipment]",
    inventory_move_sound = item_sounds.electric_small_inventory_move,
    pick_sound = item_sounds.electric_small_inventory_pickup,
    drop_sound = item_sounds.electric_small_inventory_move,
    stack_size = 20
  },
  {
    type = "recipe",
    name = "radar-equipment",
    ingredients =
    {
      {type = "item", name = "electronic-circuit", amount = 5},
      {type = "item", name = "iron-gear-wheel", amount = 5},
      {type = "item", name = "iron-plate", amount = 10}
    },
    results = {{type="item", name="radar-equipment", amount=1}},
    enabled = not tech_to_mimic, -- Just in case the tank doesn't exist. Meh
  },
  {
    type = "night-vision-equipment",
    name = "radar-equipment",
    localised_description = {"",
      {"equipment-description.radar-equipment"},
      "\n[color=#fae8be][font=default-semibold]", -- This is annoying
      {"description.continuous-radar-coverage-distance"},
      "[/font][/color]",
      " 3", -- Won't be true if other mod changes it. Just ask me!
    },
    sprite = {
      filename = "__radar-equipment__/graphics/equipment.png",
      width = 128,
      height = 166,
      priority = "medium",
      scale = 0.43,
    },
    shape = {
      width = 2,
      height = 2,
      type = "full"
    },
    energy_source =
    {
      type = "electric",
      buffer_capacity = "180kJ",
      input_flow_limit = "240kW",
      usage_priority = "secondary-input",
    },
    energy_input = "30kW",
    categories = {"armor"},
    darkness_to_turn_on = 0, -- Always on (except at daytime exactly at 0)
    color_lookup = {{1, "identity"}},
  },
}

if tech_to_mimic then
  data:extend {
    {
      type = "technology",
      name = "radar-equipment",
      effects = {{
        type = "unlock-recipe",
        recipe = "radar-equipment"
      }},
      icon = "__radar-equipment__/graphics/technology.png",
      icon_size = 256,
      order = table.deepcopy(tech_to_mimic.order),
      prerequisites = table.deepcopy(tech_to_mimic.prerequisites),
      unit = table.deepcopy(tech_to_mimic.unit),
    }
  }
end