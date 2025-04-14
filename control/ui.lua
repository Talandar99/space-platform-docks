-- https://github.com/pettett/ch-concentrated-solar/blob/master/control/ui.lua

local ui_lib = {events={}}

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
  local ui = parent.add{type="flow"}
  ui.style.padding = 8

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
    type="sprite",
    -- https://lua-api.factorio.com/latest/concepts/SpritePath.html
    sprite="utility/" .. DIODE2SPRITE[diode_color],
  }
  ui.add{
    type="label",
    caption=status_name
  }
end

local function make_dock_status(parent, dock)
  local left_info = parent.add{
    type="frame", direction="vertical",
    style="inside_shallow_frame"
  }
  left_info.style.vertically_stretchable = true

  make_status_with_diode(left_info, dock)

  local preview_frame_frame = left_info.add{type="flow"}
  preview_frame_frame.style.left_padding = 16
  preview_frame_frame.style.right_padding = 16
  local preview_frame = preview_frame_frame.add{type="frame", style="entity_frame"}
  preview_frame.style.padding = 0
  local preview = preview_frame.add{type="entity-preview"}
  -- false for some reason??
  preview.visible = true
  -- preview.style.horizontally_stretchable = true
  -- preview.style.vertically_stretchable = true
  preview.style.minimal_width = 384
  preview.style.minimal_height = 192
  preview.entity = dock
end

local function make_dock_view(parent, dock)
  local frame = parent.add{
    type="frame", direction="vertical",
    tags = {pkspd_dock_picker=true, viewing=dock.unit_number}
  }

  local camera = frame.add{
    type="camera", name="camera",
    position = dock.position,
    surface = dock.surface
  }
  camera.style.width = 256
  camera.style.height = 192
  camera.zoom = 0.5
  camera.entity = dock

  local label = frame.add{
    type="label",
    caption={"pkspd-gui.on-platform", dock.surface.platform.name}
  }
  label.style.horizontal_align = "center"
  
  return frame
end

local function make_manual_tab(evt, tab_holder)
  local manual_tab = tab_holder.add{type="tab", caption={"pkspd-gui.manual-mode"}}

  local manual_contents = tab_holder.add{
    type="flow", direction="vertical"
  }

  local dock_view_holder = manual_contents
    .add{
      type="scroll-pane",
      horizontal_scroll_policy="never",
      vertical_scroll_policy="always",
    }
    .add{type="table", column_count=3}

  for i = 1,10 do
    make_dock_view(dock_view_holder, evt.entity)
  end

  manual_contents.add{
    type="button",
    name="pkspd_dock_initiate_dock",
    caption={"pkspd-gui.initiate-dock"}
  }

  tab_holder.add_tab(manual_tab, manual_contents)
end

local function make_auto_tab(evt, tab_holder)
  local auto_tab = tab_holder.add{type="tab", caption={"pkspd-gui.automatic-mode"}}

  local auto_contents = tab_holder.add{type="flow", direction="vertical"}
  auto_contents.add{type="label", caption="Hello world!!"}

  tab_holder.add_tab(auto_tab, auto_contents)
end

ui_lib.events[defines.events.on_gui_opened] = function(evt)
  if evt.gui_type ~= defines.gui_type.entity
      or not evt.entity
      or evt.entity.name ~= "pkspd-platform-dock"
  then
    return
  end

  local dock = evt.entity

  local player = game.get_player(evt.player_index)
  if not player then return end

  local main_frame = player.gui.screen.add{
    type = "frame",
    name = "pkspd_dock_main_frame",
    direction = "vertical",
    tags = {tid = dock.unit_number}
  }
  player.opened = main_frame
  main_frame.style.vertically_stretchable = true
  main_frame.style.horizontally_stretchable = true
  main_frame.auto_center = true

  local titlebar = main_frame.add{type = "flow"}
  titlebar.drag_target = main_frame
  titlebar.add{
    type = "label",
    style = "frame_title",
    caption = dock.prototype.localised_name,
    ignored_by_interaction = true
  }
  local filler = titlebar.add {
    type = "empty-widget",
    style = "draggable_space",
    ignored_by_interaction = true,
  }
  filler.style.height = 24
  filler.style.horizontally_stretchable = true
  titlebar.add {
    type = "sprite-button",
    name = "pkspd_dock_x_button",
    style = "frame_action_button",
    sprite = "utility/close",
    tooltip = { "gui.close-instruction" },
  }

  local main_content = main_frame.add{
    type="table", column_count = 2
  }

  make_dock_status(main_content, dock)

  -- TODO: check out style frame_tabbed_pane
  local right_controls = main_content.add{
    type="frame",
    style="inside_shallow_frame",
    -- caption={"pkspd-gui.dock-controls"}
  }
  local tab_holder = right_controls.add{type="tabbed-pane"}
  make_manual_tab(evt, tab_holder)
  make_auto_tab(evt, tab_holder)
end

ui_lib.events[defines.events.on_gui_click] = function(event)
  if event.element and event.element.name == "pkspd_dock_x_button" then
    event.element.parent.parent.destroy()
  end
end

return ui_lib
