require "__core__/lualib/util"
local linklib = require "control/linklib"
local ui = require "control/ui"

local function tick5(evt)
  if storage.dock_info then
    for dock_id,info in pairs(storage.dock_info) do
      local dock = game.get_entity_by_unit_number(dock_id)
      if dock then
        if info["mode"] == "automatic" then
          linklib.try_autodock(dock)
        end

        -- there is no event for when a platform departs
        if not linklib.can_platform_link(dock.surface.platform) then
          linklib.unlink_dock(dock)
        end

        dock.custom_status = linklib.vanity_status(dock)
      end
    end
  end

  -- script.raise_event("pkspd-redraw-dock-guis", {})
end

local function tick60(evt)
  if storage.dock_info then
    -- Garbage collect unneeded 
    local remove_idxes = {}
    local unlink_docks = {}
    for dock_id,info in pairs(storage.dock_info) do
      if not game.get_entity_by_unit_number(dock_id) then
        if info.linked_dock and info.linked_dock.valid then
          table.insert(unlink_docks, info.linked_dock)
        end
        table.insert(remove_idxes, dock_id)
      end
    end
    for _,remove_idx in ipairs(remove_idxes) do
      storage.dock_info[remove_idx] = nil
    end
    for _,unlink_me in ipairs(unlink_docks) do
      linklib.unlink_dock(unlink_me)
    end
  end
end

return {
  on_nth_tick = {
    [5] = tick5,
    [60] = tick60,
  }
}
