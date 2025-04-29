-- TODO: put the part that's "glued to the ground"
-- in an integration layer.
-- Kind of jank for now but it works
local graphics = {
  north = {
    filename = "__space-platform-docks__/graphics/entity/dock-up.png",
    scale = 0.5,
    shift = {0, 0},
    width = 64 * 10,
    height = 64 * 6,
  },
  south = {
    filename = "__space-platform-docks__/graphics/entity/dock-down.png",
    scale = 0.5,
    shift = {0, 0},
    width = 64 * 10,
    height = 64 * 6,
  },
  west = {
    filename = "__space-platform-docks__/graphics/entity/dock-left.png",
    scale = 0.5,
    shift = {0, 0.5},
    width = 64 * 6,
    height = 64 * 13,
  },
  east = {
    filename = "__space-platform-docks__/graphics/entity/dock-right.png",
    scale = 0.5,
    shift = {0, 0.5},
    width = 64 * 6,
    height = 64 * 13,
  },
}

local make_cc_entry = function(x, y)
  return {
    variation=4,
    main_offset={x,y}, shadow_offset={x,y},
    show_shadow = false
  }
end
local circuit_connectors = circuit_connector_definitions.create_vector(
  universal_connector_template,
  -- NESW
  {
    make_cc_entry(2.5, 0),
    make_cc_entry(0, -2.5),
    make_cc_entry(-2.5, 0),
    make_cc_entry(0, 2.5),
  }
)
return {
  graphics = graphics,
  circuit_connectors = circuit_connectors,
}
