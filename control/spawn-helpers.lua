require "__core__/lualib/util"
local math2d = require "__core__/lualib/math2d"

local linklib = require "control/linklib"

-- https://github.com/raiguard/EditorExtensions/blob/master/scripts/infinity-loader.lua
local function spawn_helper_entities(evt)
  local entity = evt.entity or evt.destination
  if not entity.valid or entity.name ~= "pkspd-platform-dock" then
    return
  end

  -- in, out
  -- resources travel clockwise
  local belt_poses_table = {
    [defines.direction.north] = {{-1.5, 2.5}, {1.5, 2.5}},
    [defines.direction.south] = {{1.5, -2.5}, {-1.5, -2.5}},
    [defines.direction.west] = {{2.5, 1.5}, {2.5, -1.5}},
    [defines.direction.east] = {{-2.5, -1.5}, {-2.5, 1.5}},
  }
  local belt_poses = belt_poses_table[entity.direction]
  local nice_place_params = {
    name = "pkspd-linked-belt",
    force = entity.force,
    raise_built = true,
    create_built_effect_smoke = true,
  }
  local belt_in = entity.surface.create_entity(util.merge({
    nice_place_params,
    {
      position = math2d.position.add(belt_poses[1], entity.position),
      direction = entity.direction,
      -- not documented that this works on linked belts
      type = "input",
    },
  }))
  local belt_out = entity.surface.create_entity(util.merge({
    nice_place_params,
    {
      position = math2d.position.add(belt_poses[2], entity.position),
      direction = util.oppositedirection(entity.direction),
      type = "output",
    },
  }))
  game.print("Input " .. tostring(belt_in) .. "; output " .. tostring(belt_out))
end

local function kill_helper_entities(evt)
  local entity = evt.entity
  if not entity.valid or entity.name ~= "pkspd-platform-dock" then
    return
  end

  -- do something
  local helpers = linklib.find_helpers(entity)
  for _ty,helper in pairs(helpers) do
    game.print("Killing " .. tostring(helper))

    if helper.name == "pkspd-linked-belt" then
      if evt.buffer then
        for i = 1,helper.get_max_transport_line_index() do
          local tl = helper.get_transport_line(i)
          for _,stack in ipairs(tl.get_detailed_contents()) do
            evt.buffer.insert(stack.stack)
          end
        end
      end
    end

    helper.destroy{raise_destroy=true}
  end
end

local handler_lib = {
  events = {}
}

for _,defn in ipairs{
  defines.events.on_built_entity,
  defines.events.on_entity_cloned,
  defines.events.on_robot_built_entity,
  defines.events.on_script_raised_built,
  defines.events.on_script_raised_revive,
  defines.events.on_space_platform_built_entity,
} do
  handler_lib.events[defn] = spawn_helper_entities
end
for _,defn in ipairs{
  defines.events.on_entity_died,
  defines.events.on_player_mined_entity,
  defines.events.on_robot_mined_entity,
  defines.events.on_script_raised_destroy,
  defines.events.on_space_platform_mined_entity,
} do
  handler_lib.events[defn] = kill_helper_entities
end

return handler_lib

