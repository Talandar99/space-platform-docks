data:extend{
  util.merge({
    data.raw["item"]["linked-belt"],
    {
      name = "pkspd-linked-belt",
      place_result = "pkspd-linked-belt",
    }
  }),
  util.merge({
    data.raw["linked-belt"]["linked-belt"],
    {
      name = "pkspd-linked-belt",
      flags = {
        "placeable-player", "player-creation",
        "not-rotatable", "not-on-map", "hide-alt-info",
      },
      selectable_in_game = false,
    }
  })
}
