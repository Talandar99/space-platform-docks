-- https://github.com/pettett/ch-concentrated-solar/blob/master/control/ui.lua

local ui_lib = {events={}}

local function make_dock_view(ui, dock)
  local frame = ui.add{
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
    caption={"pkspd-gui.on-platform", dock.surface.localised_name}
  }
  
  return frame
end

local function make_manual_tab(evt, tab_holder)
  local manual_tab = tab_holder.add{type="tab", caption={"pkspd-gui.manual-mode"}}

  local manual_contents = tab_holder.add{type="flow", direction="vertical"}
  manual_contents.add{
    type="label",
    caption={"pkspd-gui.pick-a-dock"},
    style="frame_title"
  }

  local dock_view_holder = manual_contents
    .add{type="frame"}
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
    label={"pkspd-gui.initiate-dock"}
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

  local left_info = main_content.add{type="frame"}
  left_info.add{type="label", caption="Docked to a platform or something"}

  local tab_holder = main_content.add{
    type = "tabbed-pane",
    name = "pkspd_dock_tabbed_pane"
  }
  make_manual_tab(evt, tab_holder)
  make_auto_tab(evt, tab_holder)
end

ui_lib.events[defines.events.on_gui_click] = function(event)
  if event.element and event.element.name == "pkspd_dock_x_button" then
    event.element.parent.parent.destroy()
  end
end

return ui_lib
