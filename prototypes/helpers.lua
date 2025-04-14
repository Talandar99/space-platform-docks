local whocares_icon = "__core__/graphics/questionmark.png"

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
}
