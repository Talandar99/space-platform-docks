-- https://github.com/pettett/ch-concentrated-solar/blob/master/control/ui.lua

local ui_lib = require "control/ui-lib"

local handler_lib = {events={}}

local STATUS_LOOKUP = {}
for stat, number in pairs(defines.entity_status) do
  STATUS_LOOKUP[number] = stat:gsub("_", "-")
end
local DIODE2SPRITE = {
  [defines.entity_status_diode.green] = "status_working",
  [defines.entity_status_diode.yellow] = "status_yellow",
  [defines.entity_status_diode.red] = "status_not_working",
}

local function make_status_with_diode(parent, dock)
  local ui = parent.add{type="flow", direction="horizontal"}

  -- https://forums.factorio.com/viewtopic.php?p=538298
  local diode_color, status_name
  if dock.custom_status then
    status_name = dock.custom_status.label
    diode_color = dock.custom_status.diode
  else
    status_name = {"entity-status." ..  STATUS_LOOKUP[dock.status] }
    -- AUGH todo
    diode_color = defines.entity_status_diode.green
  end

  ui.add{
    type="sprite", style="status_image",
    -- https://lua-api.factorio.com/latest/concepts/SpritePath.html
    sprite="utility/" .. DIODE2SPRITE[diode_color],
    
  }
  ui.add{
    type="label",
    caption=status_name
  }
end

local function make_dock_status(parent, dock)
  -- local top_info = parent.add{
  --   type="frame", direction="vertical",
  --   style="inside_shallow_frame"
  -- }
  -- top_info.style.vertically_stretchable = true

  make_status_with_diode(parent, dock)

  local preview = parent
    .add{
      type="frame", direction="vertical",
      style="deep_frame_in_shallow_frame"
    }
    .add{type="entity-preview"}
  -- false for some reason??
  preview.visible = true
  preview.style.horizontally_stretchable = true
  -- preview.style.vertically_stretchable = true
  preview.style.minimal_width = 384
  preview.style.minimal_height = 192
  preview.entity = dock
end

local function make_auto_circuit_control(parent)
  local elt = parent.add{
    type="flow", direction="horizontal",
    style="player_input_horizontal_flow"
  }

  elt.add{
    type="label", caption={"pkspd-gui.autodock-signal"},
  }
  elt.add{
    type="sprite", sprite="info",
    tooltip={"pkspd-gui.autodock-signal-tt"}
  }
  elt.add{
    type="choose-elem-button", name="pkspd_dock_autodock_signal",
    elem_type="signal"
  }
end

local function make_manual_dock_popdown(dock, parent)
end

handler_lib.events[defines.events.on_gui_opened] = function(evt)
  if evt.gui_type ~= defines.gui_type.entity
      or not evt.entity
      or evt.entity.name ~= "pkspd-platform-dock"
  then
    return
  end

  local dock = evt.entity

  local player = game.get_player(evt.player_index)
  if not player then return end

  local main_frame = ui_lib.new_main_frame(player, dock.prototype.localised_name)
  main_frame.tags = {tid=dock.unit_number}

  local main_content = main_frame.add{
    type="frame", direction="vertical",
    style="entity_frame"
  }

  make_dock_status(main_content, dock)

  local auto_manual_switch = main_content.add{
    type="switch",
    name="pkspd_dock_auto_manual_switch",
    left_label_caption={"pkspd-gui.automatic-mode"},
    right_label_caption={"pkspd-gui.manual-mode"},
  }

  main_content.add{type="line"}

  make_auto_circuit_control(main_content)

  local manual_popdown_button = main_content.add{
    type="button",
    name = "pkspd_dock_manual_popdown_button",
    caption={"pkspd-gui.manual-dock"},
  }
  manual_popdown_button.style.horizontally_stretchable = true
end

handler_lib.events[defines.events.on_gui_click] = function(event)
  -- if event.element and event.element.name == "pkspd_dock_x_button" then
  --   event.element.parent.parent.destroy()
  -- end
end

handler_lib.events[defines.events.on_gui_closed] = function(event)
  -- if event.element and event.element.name == "pkspd_dock_main_frame" then
  --   event.element.destroy()
  -- end
end

return handler_lib
