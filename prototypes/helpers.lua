local whocares_icon = "__core__/graphics/questionmark.png"

local nice_fluidbox = {
  -- pipe_picture = assembler2pipepictures(),
  pipe_covers = pipecoverspictures(),
  volume = 0,
  secondary_draw_orders = { north=-1, south=1 },
}
local fluid_throughput = 10

data:extend{
  util.merge({
    data.raw["linked-belt"]["linked-belt"],
    {
      name = "pkspd-linked-belt",
      flags = {
        "placeable-player", "player-creation",
        "not-rotatable", "not-on-map", "hide-alt-info",
      },
      hidden = true,
      selectable_in_game = false,
      icon = whocares_icon,
    }
  }),
  -- Disable unless there's a linked dock
  -- to avoid fluid getting caught in the pump.
  -- {
  --   type = "pump",
  --   name = "pkspd-linked-pipe-input",
  --   flags = {
  --     "placeable-player", "player-creation",
  --     "not-rotatable", "not-on-map", "hide-alt-info",
  --     "placeable-off-grid"
  --   },
  --   hidden = true,
  --   selectable_in_game = false,
  --   icon = whocares_icon,
  -- },
  -- Carries bridged signals across the dock.
  -- https://github.com/robot256/factorio_shortwave_fix/blob/main/control.lua
  -- https://mods.factorio.com/mod/circuit-wire-poles
  util.merge({
    data.raw["constant-combinator"]["constant-combinator"],
    {
      name = "pkspd-dock-circuit-bridge",
      flags = {
        "placeable-player", "player-creation",
        "not-rotatable", "not-on-map", "hide-alt-info",
        "placeable-off-grid"
      },
      hidden = true,
      selectable_in_game = true,
      icon = whocares_icon,
      maximum_wire_distance = default_circuit_wire_max_distance,
      draw_copper_wires = false,
      draw_circuit_wires = true,
    }
  }),
  -- Used to avoid circular dependency errors
  -- Fired when we need to re-draw all the guis
  {
    type = "custom-event",
    name = "pkspd-redraw-dock-guis"
  }
}
