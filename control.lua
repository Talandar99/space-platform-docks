require "__core__/lualib/util"
local linklib = require "control/linklib"

local handler = require "__core__/lualib/event_handler"
handler.add_libraries({
  require "control/spawn-helpers",
  require "control/ui",
})

commands.add_command("pkspd-link-platforms", nil, function(cmd)
  local splitted = util.split_whitespace(cmd.parameter)
  local surface_a = game.get_surface(splitted[1])
  local surface_b = game.get_surface(splitted[2])
  -- Find just any old docks for the time being, before I make a gui
  local dock_a = surface_a.find_entities_filtered{name="pkspd-platform-dock"}[1]
  local dock_b = surface_b.find_entities_filtered{name="pkspd-platform-dock"}[1]
  local result = linklib.link_docks(dock_a, dock_b)
  if result then
    game.print(result)
  end
end)
