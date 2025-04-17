require "__core__/lualib/util"
local linklib = require "control/linklib"

local autodock = {}

local function get_circuit_value(dock, freq)
  return dock.get_signal(
    freq,
    defines.wire_connector_id.circuit_red,
    defines.wire_connector_id.circuit_green
  )
end

autodock.try_autodock = function(dock)
  local info = linklib.dock_info(dock)
  if info["mode"] == "automatic" then
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
            return other
          end
        end
      end
    end
  end
 
  -- Failure
  linklib.unlink_dock(dock)
end

local function on_tick(evt)
  for dock_id,info in pairs(storage.dock_info) do
    if info["mode"] == "automatic" then
      local dock = game.get_entity_by_unit_number(dock_id)
      autodock.try_autodock(dock, info)
    end
  end
end

autodock.handler_lib = {
  on_nth_tick = {
    [5] = on_tick
  }
}
return autodock
