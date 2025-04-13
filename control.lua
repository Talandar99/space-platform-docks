-- https://github.com/raiguard/EditorExtensions/blob/master/scripts/infinity-loader.lua
local function spawn_helper_entities(evt)
  local entity = evt.entity or evt.destination
  if not entity.valid then
    return
  end

  if entity.name ~= "pkspd-platform-dock" then
    return
  end

  -- do something
end

