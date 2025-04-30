require "__core__/lualib/util"

local linklib = {
  stats_lookup = {},
  diode2sprite = {},
}

for stat, number in pairs(defines.entity_status) do
  linklib.stats_lookup[number] = stat:gsub("_", "-")
end
linklib.diode2sprite = {
  [defines.entity_status_diode.green] = "status_working",
  [defines.entity_status_diode.yellow] = "status_yellow",
  [defines.entity_status_diode.red] = "status_not_working",
}

linklib.can_platform_link = function(platform)
  local ok =
    platform
    and platform.valid
    and platform.space_location
    and (platform.state == defines.space_platform_state.waiting_at_station or platform.state == defines.space_platform_state.paused)

  -- squish to boolean
  return not not ok
end

linklib.is_furnace_status_ok = function(entity)
  local s = entity.status
  return
    s == defines.entity_status.normal
    or s == defines.entity_status.working
    or s == defines.entity_status.no_ingredients
end

-- Return a CustomEntityStatus or nil
linklib.vanity_status = function(dock)
  if not linklib.is_furnace_status_ok(dock) then
    return nil
  end

  local green, yellow, red = defines.entity_status_diode.green, 
    defines.entity_status_diode.yellow,
    defines.entity_status_diode.red
  local info = linklib.dock_info(dock)
  if not info then
    -- huh?
    return {diode = green, label = {"pkspd-text.status-ready"}}
  end

  if info.other_dock then
    return {diode = green, label = {"pkspd-text.status-docked"}}
  end

  if not linklib.can_platform_link(dock.surface.platform) then
    return {diode = yellow, label = {"pkspd-text.status-platform-moving"}}
  end

  -- All good i guess
  if info.mode == "manual" then
    return {diode = green, label = {"pkspd-text.status-ready"}}
  else
    return {diode = green, label = {"pkspd-text.status-circuit-listening"}}
  end
end

-- Returns either nil if it's ok, or a localised string error
-- TODO localise these things
linklib.could_link_problem = function(dock_a, dock_b)
  if not dock_a.valid then return "Dock A was invalid?!" end
  if not dock_b.valid then return "Dock B was invalid?!" end

  if dock_a == dock_b then
    return "Cannot link " .. tostring(dock_a) .. " to itself"
  end
  
  local a_info = linklib.dock_info(dock_a)
  local b_info = linklib.dock_info(dock_b)
  local a_other = a_info["other_dock"]
  local b_other = b_info["other_dock"]
  if a_other then 
    return tostring(dock_a) .. " was already linked to " .. tostring(a_other)
  end
  if b_other then 
    return tostring(dock_b) .. " was already linked to " .. tostring(b_other)
  end

  if dock_a.direction ~= util.oppositedirection(dock_b.direction) then
    return tostring(dock_a) .. " and " .. tostring(dock_b) ..
      " were not pointing in compatible directions (should be opposite)"
  end

  local surface_a, surface_b = dock_a.surface, dock_b.surface
  if surface_a == surface_b then 
    return "Docks were on the same surface " .. tostring(surface_a)
  end
  if not surface_a.platform then 
    return tostring(dock_a) .. " was not on a platform(!?)"
  end
  if not surface_b.platform then 
    return tostring(dock_b) .. " was not on a platform(!?)"
  end
  if not linklib.can_platform_link(surface_a.platform) then
    return tostring(dock_a) .. " was not on a platform that can link"
  end
  if not linklib.can_platform_link(surface_b.platform) then
    return tostring(dock_b) .. " was not on a platform that can link"
  end
  if surface_a.platform.space_location ~= surface_b.platform.space_location then
    return tostring(dock_a) .. " and " .. tostring(dock_b) ..
      " were not in the same body's orbit"
  end

  -- Nerd emoji!

  if surface_a.platform.space_location ~= surface_b.platform.space_location then
    return tostring(dock_a) .. " and " .. tostring(dock_b) ..
      " were not in the same body's orbit"
  end

  if a_info["mode"] ~= b_info["mode"] then
    local loc_a = "pkspd-text.mode-" .. a_info["mode"]
    local loc_b = "pkspd-text.mode-" .. b_info["mode"]
    return {"pkspd-text.linkerr-bad-modes", dock_a, loc_a, dock_b, loc_b}
  end

  if not linklib.is_furnace_status_ok(dock_a) then
    return tostring(dock_a) .. " had a mechanical problem"
  end
  if not linklib.is_furnace_status_ok(dock_b) then
    return tostring(dock_b) .. " had a mechanical problem"
  end

  -- yay!
  return nil
end

linklib.find_linkable_docks = function(dock)
  local space_loc = dock.surface.platform and dock.surface.platform.space_location
  if not space_loc then return {} end

  local out = {}

  -- Irritatingly it doesn't look like there's a good way to get all space
  -- locations and the platforms orbiting above.
  for _,force in pairs(game.forces) do
    for _,platform in pairs(force.platforms) do
      if not linklib.can_platform_link(platform) then goto continue end
      if platform == dock.surface.platform then goto continue end
      -- game.print("Checking " .. tostring(platform))

      -- The more we can get the game engine to filter, rather than do ourself,
      -- the quicker.
      local maybe_okays = platform.surface.find_entities_filtered{
        name="pkspd-platform-dock",
        direction=util.oppositedirection(dock.direction),
        to_be_deconstructed=false,
      }

      for _,mb_ok in ipairs(maybe_okays) do
        local problem = linklib.could_link_problem(dock, mb_ok)
        -- game.print("Checking " .. tostring(mb_ok) .. ", " .. tostring(problem))
        if problem == nil then
          table.insert(out, mb_ok)
        end
      end

      ::continue::
    end
  end

  return out
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
  local err = linklib.could_link_problem(dock_a, dock_b)
  -- golang moment
  if err then return err end

  -- Link belts
  local helpers_a = linklib.find_helpers(dock_a)
  local helpers_b = linklib.find_helpers(dock_b)
  helpers_a.input_belt.connect_linked_belts(helpers_b.output_belt)
  helpers_b.input_belt.connect_linked_belts(helpers_a.output_belt)

  -- Link pipes
  local fbs_a = dock_a.fluidbox
  local fbs_b = dock_b.fluidbox
  fbs_a.add_linked_connection(1, dock_b, 2)
  fbs_b.add_linked_connection(1, dock_a, 2)

  -- Link wires
  local wires_a = helpers_a.circuit_bridge.get_wire_connectors()
  local wires_b = helpers_b.circuit_bridge.get_wire_connectors()
  for _,wirecolor in ipairs{defines.wire_connector_id.circuit_red, defines.wire_connector_id.circuit_green} do
    wires_a[wirecolor].connect_to(
      wires_b[wirecolor], false, defines.wire_origin.script
    )
  end

  -- Cosmetics
  dock_a.custom_status = {
    diode = defines.entity_status_diode.green,
    label = {"pkspd-gui.status-docked"},
  }
  dock_b.custom_status = {
    diode = defines.entity_status_diode.green,
    label = {"pkspd-gui.status-docked"},
  }

  -- Associate in storage dict
  local info_a = linklib.dock_info(dock_a)
  local info_b = linklib.dock_info(dock_b)
  info_a["linked_dock"] = dock_b
  info_b["linked_dock"] = dock_a
  info_b["mode"] = info_a["mode"]

  -- Noise!
  for _,dock in ipairs{dock_a, dock_b} do
    -- TODO
  end
  -- game.print("Linked " .. tostring(dock_a) .. " and " .. tostring(dock_b))
  
  script.raise_event("pkspd-redraw-dock-guis", {})
  return nil
end

-- Returns the dock it was unlinked from, or nil
linklib.unlink_dock = function(dock_a)
  local dock_b = linklib.find_linked_dock(dock_a)
  if not dock_b then return nil end
  
  -- Unlink belts
  local helpers_a = linklib.find_helpers(dock_a)
  local helpers_b = linklib.find_helpers(dock_b)
  helpers_a.input_belt.disconnect_linked_belts()
  helpers_b.input_belt.disconnect_linked_belts()

  -- Unlink wires
  local wires_a = dock_a.get_wire_connectors()
  local wires_b = dock_b.get_wire_connectors()
  for _,wirecolor in ipairs{defines.wire_connector_id.circuit_red, defines.wire_connector_id.circuit_green} do
    local wire_a = wires_a[wirecolor]
    local wire_b = wires_b[wirecolor]
    if wire_a and wire_b then
      wire_a.disconnect_from(wire_b, defines.wire_origin.script)
    end
  end

  dock_a.custom_status = nil
  dock_b.custom_status = nil

  local info_a = linklib.dock_info(dock_a)
  local info_b = linklib.dock_info(dock_b)
  info_a["linked_dock"] = nil
  info_b["linked_dock"] = nil

  script.raise_event("pkspd-redraw-dock-guis", {})
  return dock_b
end

linklib.dock_info = function(dock)
  if type(dock) == "number" then dock = game.get_entity_by_unit_number(dock) end
  if not dock or not dock.valid or dock.name ~= "pkspd-platform-dock" then
    return nil
  end
  -- INDEXED BY DOCK NUMBER
  if not storage.dock_info then storage.dock_info = {} end
  if not storage.dock_info[dock.unit_number] then
    storage.dock_info[dock.unit_number] = {}
  end
  return storage.dock_info[dock.unit_number]
end
linklib.find_linked_dock = function(dock) 
  local info = linklib.dock_info(dock)
  if not info then return nil end
  local other = info["linked_dock"]
  if other and not other.valid then
    info["linked_dock"] = nil
    return nil
  else
    return other
  end
end

local function get_circuit_value(dock, freq)
  return dock.get_signal(
    freq,
    defines.wire_connector_id.circuit_red,
    defines.wire_connector_id.circuit_green
  )
end
linklib.try_autodock = function(dock)
  local info = linklib.dock_info(dock)

  local freq = info["autodock_frequency"]
  if freq then
    local my_freq_value = get_circuit_value(dock, freq)
    if my_freq_value ~= 0 then
      -- game.print("Searching for docks with " 
      --   .. tostring(freq) .. "=" .. my_freq_value)
      local ok_docks = linklib.find_linkable_docks(dock)
      for _,other in ipairs(ok_docks) do
        local other_info = linklib.dock_info(other)
        local other_freq = other_info["autodock_frequency"]
        if other_freq and util.table.compare(other_freq, freq)
            and get_circuit_value(other, freq) == my_freq_value
        then
          local err = linklib.link_docks(dock, other)
          if err then
            game.print({"", "autodock failed? ", err})
          end
          return
        end
      end
    end
  end

  linklib.unlink_dock(dock)
end

return linklib
