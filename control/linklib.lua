require "__core__/lualib/util"

local linklib = {}

linklib.find_linked_dock = function(dock)
  if not storage.linked_docks then return nil end
  if not dock.valid or dock.name ~= "pkspd-platform-dock" then return nil end
  local id = storage.linked_docks[dock.unit_number]
  return game.get_entity_by_unit_number(id)
end

linklib.find_helpers = function(dock)
  if not dock.valid then error("Dock was invalid") end
  if dock.name ~= "pkspd-platform-dock" then
    error("Only call find_helpers on platform docks, instead got " .. tostring(dock))
  end

  local out = {}
  local helpers = dock.surface.find_entities_filtered{
    area = dock.bounding_box,
    name = {"pkspd-linked-belt", "pkspd-dock-circuit-bridge"}
  }
  for _,helper in ipairs(helpers) do
    if helper.name == "pkspd-linked-belt" then
      if helper.linked_belt_type == "input" then
        out.input_belt = helper
      else
        out.output_belt = helper
      end
    elseif helper.name == "pkspd-dock-circuit-bridge" then
      out.circuit_bridge = helper
    end
  end

  return out
end

-- Returns either `nil` or an error localised string
linklib.link_docks = function(dock_a, dock_b)
  local a_other = linklib.find_linked_dock(dock_a)
  local b_other = linklib.find_linked_dock(dock_b)
  if a_other then return "Dock A was already linked to " .. tostring(b_other) end
  if b_other then return "Dock A was already linked to " .. tostring(a_other) end
  
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
  local wires_a = helpers_a.circuit_bridge.get_wire_connectors()
  local wires_b = helpers_a.circuit_bridge.get_wire_connectors()
  for _,wirecolor in ipairs{defines.wire_connector_id.circuit_red, defines.wire_connector_id.circuit_green} do
    wires_a[wirecolor].connect_to(
      wires_b[wirecolor], false, defines.wire_origin.script
    )
  end

  -- Associate in storage dict
  if not storage.linked_docks then storage.linked_docks = {} end
  storage.linked_docks[dock_a.unit_number] = dock_b
  storage.linked_docks[dock_b.unit_number] = dock_a

  return nil
end

-- Returns the dock it was unlinked from, or nil
linklib.unlink_dock = function(dock_a)
  local dock_b = linklib.find_linked_dock(dock_a)
  if not dock_b then return nil end
  
  -- Link belts
  local helpers_a = linklib.find_helpers(dock_a)
  local helpers_b = linklib.find_helpers(dock_b)
  helpers_a.input_belt.disconnect_linked_belts()
  helpers_b.input_belt.disconnect_linked_belts()

  -- Link wires
  local wires_a = dock_a.get_wire_connectors()
  local wires_b = dock_b.get_wire_connectors()
  for _,wirecolor in ipairs{defines.wire_connector_id.circuit_red, defines.wire_connector_id.circuit_green} do
    wires_a[wirecolor].disconnect_from(
      wires_b[wirecolor], defines.wire_origin.script
    )
  end

  storage.linked_docks[dock_a.unit_number] = nil
  storage.linked_docks[dock_b.unit_number] = nil

  return dock_b
end

return linklib
