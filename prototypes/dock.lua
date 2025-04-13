local nice_fluidbox = {
  -- pipe_picture = assembler2pipepictures(),
  pipe_covers = pipecoverspictures(),
  volume = 1000,
  secondary_draw_orders = { north = -1 },
}

data:extend{
  {
    type = "item",
    stack_size = 1,
    name = "pkspd-platform-dock",
    subgroup = "space-related",
    place_result = "pkspd-platform-dock",
    icon = "__base__/graphics/icons/rocket-silo.png",
  },
  {
    -- Has some good properties:
    -- - Inbuilt fluid boxes (for linking)
    -- - Can be rotated but only before placement
    -- - Animation support
    type = "furnace",
    name = "pkspd-platform-dock",
    icon = "__base__/graphics/icons/rocket-silo.png",
    flags = {"placeable-neutral", "placeable-player", "player-creation"},
    minable = {mining_time = 1.0, result = "pkspd-platform-dock"},
    -- The default direction is north
    selection_box = {{-5, -3}, {5, 3}},
    collision_box = {{-5, -3}, {5, 3}},
    tile_width = 10,
    tile_height = 6,
    build_grid_size = 2,
    -- this is what the collector does
    -- using the thruster's mask makes it unable to be placed???
    -- i genuinely have no idea
    collision_mask = { layers = {
      is_lower_object=true, is_object=true, transport_belt=true
    }},
    tile_buildability_rules = {
      -- Support
      {
        area = {{-4.9, 0.1}, {4.9, 2.9}},
        required_tiles = {layers = {ground_tile = true}},
        colliding_tiles = {layers = {empty_space = true}},
        remove_on_collision = true,
      },
      -- Space for the latch
      {
        area = {{-4.9, -2.9}, {4.9, -0.1}},
        required_tiles = {layers = {empty_space = true}},
        remove_on_collision = true,
      },
      -- Giant exclusion zone to prevent any fun from happening on the side
      -- that it is sticking out on.
      {
        area = {{-50, -50}, {50, -2.9}},
        required_tiles = {layers = {empty_space = true}},
        remove_on_collision = true,
      },
    },

    -- Fluidboxes for teleporting later
    fluid_boxes = {
      util.merge({
        nice_fluidbox,
        {
          production_type = "input",
          pipe_connections = {{
            flow_direction="input",
            direction=defines.direction.south, position={-2.5, 2.5}
          }}
        }
      }),
      util.merge({
        nice_fluidbox,
        {
          production_type = "output",
          pipe_connections = {{
            flow_direction="output",
            direction=defines.direction.south, position={2.5, 2.5}
          }}
        }
      }),
    },

    graphics_set = require("prototypes/dock-graphics"),

    energy_usage = "180kW",
    energy_source = {
      type = "electric",
      usage_priority = "secondary-input",
    },
    -- or whatever
    crafting_categories = {"smelting"},
    crafting_speed = 1,
    source_inventory_size = 1,
    result_inventory_size = 1,
  }
}

