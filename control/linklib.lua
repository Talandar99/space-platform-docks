require "__core__/lualib/util"

local function find_helpers(dock)
  if dock.name ~= "pkspd-platform-dock" then
    error("Only call find_helpers on platform docks, instead got " .. tostring(dock))
  end

  local out = {}
  local helpers = dock.surface.find_entities_filtered{
    area = dock.bounding_box,
    name = {"pkspd-linked-belt", }
  }
  for _,helper in ipairs(helpers) do
    if helper.name == "pkspd-linked-belt" then
      if helper.linked_belt_type == "input" then
        out.input_belt = helper
      else
        out.output_belt = helper
      end
    end
  end

  return out
end

-- Returns either `nil` or an error localised string
local function link_docks(dock_a, dock_b)
  local surface_a = dock_a.surface
  local surface_b = dock_b.surface
  -- jackass
  if surface_a == surface_b then return "Docks were on the same surface" end
  if not surface_a.platform then return "Dock A was not on a platform" end
  if not surface_b.platform then return "Dock B was not on a platform" end

  if dock_a.direction ~= util.oppositedirection(dock_b.direction) then
    return "Docks A and B were not pointing in the right directions (should be opposite)"
  end

  -- Link belts
  local helpers_a = find_helpers(dock_a)
  local helpers_b = find_helpers(dock_b)
  helpers_a.input_belt.connect_linked_belts(helpers_b.output_belt)
  helpers_b.input_belt.connect_linked_belts(helpers_a.output_belt)

  -- Link wires
  local wires_a = dock_a.get_wire_connectors()
  local wires_b = dock_b.get_wire_connectors()
  for _,wirecolor in ipairs{defines.wire_connector_id.circuit_red, defines.wire_connector_id.circuit_green} do
    wires_a[wirecolor].connect_to(
      wires_b[wirecolor], false, defines.wire_origin.script
    )
  end

  return nil
end

return {
  find_helpers = find_helpers,
  link_docks = link_docks,  
}
