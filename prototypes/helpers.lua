local whocares_icon = "__core__/graphics/questionmark.png"
local invisible_flags = {
  "placeable-player", "player-creation",
  "not-rotatable", "not-on-map", "hide-alt-info",
}

data:extend{
  util.merge({
    data.raw["linked-belt"]["linked-belt"],
    {
      name = "pkspd-linked-belt",
      flags = invisible_flags,
      hidden = true,
      selectable_in_game = false,
      icon = whocares_icon,
    }
  }),
  -- Entity that the player uses to command two docks to connect
  -- https://github.com/robot256/factorio_shortwave_fix/blob/main/control.lua
  -- https://mods.factorio.com/mod/circuit-wire-poles
  -- The bridged signals are just carried thru the real dock entity.
  -- TODO actually impl this
  util.merge({
    data.raw["constant-combinator"]["constant-combinator"],
    {
      name = "pkspd-dock-circuit-controller",
      flags = invisible_flags,
      hidden = true,
      selectable_in_game = false,
      icon = whocares_icon,
      maximum_wire_distance = default_circuit_wire_max_distance,
      draw_copper_wires = false,
      draw_circuit_wires = true,
    }
  }),
}
