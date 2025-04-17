-- https://github.com/pettett/ch-concentrated-solar/blob/master/control/ui.lua

local ui_lib = require "control/ui-lib"
local linklib = require "control/linklib"

local dock_ui = {handler_lib = {events={}}}

-- i would rather store things here as little as possible
-- tags are only good for read-only data and plain lua primitives tho
local function extra_data(player)
  local player_id = player
  if type(player) ~= "number" then
    player_id = player.index
  end
  if not storage.dock_gui_infos then
    storage.dock_gui_infos = {}
  end
  if not storage.dock_gui_infos[player_id] then
    storage.dock_gui_infos[player_id] = {}
  end
  return storage.dock_gui_infos[player_id]
end

local function dock_info_extra(element)
  local dock = game.get_entity_by_unit_number(
    ui_lib.find_parent_main_frame(element).tags["tid"]
  )
  local dock_info = linklib.dock_info(dock)
  local extra = extra_data(element.player_index)
  return dock, dock_info, extra
end

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
  make_status_with_diode(parent, dock)
  local dock_info = linklib.dock_info(dock)

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

  local other_dock_row = parent.add{
    type="flow", layout="horizontal"
  }
  other_dock_row.style.vertical_align = "center"
  
  local other_dock = linklib.find_linked_dock(dock)
  local caption
  if other_dock then
    caption = {"pkspd-gui.yes-docked", other_dock.surface.platform.name}
  else
    caption = {"pkspd-gui.not-docked"}
  end
  other_dock_row.add{type="label", caption=caption}
  local spacer = other_dock_row.add{type="empty-widget"}
  spacer.style.horizontally_stretchable = true

  local undock_button = other_dock_row.add{
    type="button", name="pkspd_undock",
    caption={"pkspd-gui.undock"}
  }
  undock_button.enabled = (dock_info["mode"] == "manual" and other_dock ~= nil)
end

local function make_auto_circuit_control(parent)
  local _, info, _ = dock_info_extra(parent)
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
  local signal_picker = elt.add{
    type="choose-elem-button", name="pkspd_dock_autodock_signal",
    elem_type="signal",
  }
  signal_picker.elem_value = info["autodock_frequency"]
  -- you CAN NOT put a little number in the bottom-right-hand corner
  -- due to W O K E
end

local function make_manual_dock_popdown(button)
  local dock = game.get_entity_by_unit_number(
    ui_lib.find_parent_main_frame(button).tags.tid
  )
  local popdown_holder = button.parent

  local oh_no_already_there = popdown_holder["pkspd_manual_dock_popdown"]
  if oh_no_already_there then
    oh_no_already_there.destroy()
    return
  end
  
  -- Put dock names on the left, preview on the right
  local new_frame = popdown_holder.add{
    type="frame", direction="horizontal",
    name="pkspd_manual_dock_popdown",
    style="inset_frame_container_frame"
  }
  extra_data(button.player_index)["manual_dock_popdown"] = new_frame
  new_frame.style.horizontally_stretchable = true

  local docks_list_frame = new_frame
    .add{type="frame", direction="vertical", style="inside_deep_frame"}
  docks_list_frame.style.horizontally_stretchable = true
  docks_list_frame.style.minimal_width = 120
  local docks_list_scroll = docks_list_frame.add{
    type="scroll-pane", horizontal_scroll_policy="never",
    -- vertical_scroll_policy="always",
    style="list_box_scroll_pane",
  }
  docks_list_scroll.style.vertically_stretchable = true
  -- Required to set vertical_spacing due to WOKE
  local docks_list_scroll_fr = docks_list_scroll.add{
    type="flow", direction="vertical"
  }
  docks_list_scroll_fr.style.vertical_spacing=0

  local all_other_docks = linklib.find_linkable_docks(dock)
  for _,other_dock in ipairs(all_other_docks) do
    local dock_line = docks_list_scroll_fr.add{
      type="button", style="list_box_item",
      tags={pkspd_dock_line=true, for_dock=other_dock.unit_number},
      caption={"pkspd-gui.dock-line", other_dock.surface.platform.name},
    }
    dock_line.style.horizontally_stretchable = true
  end

  local rhs = new_frame.add{
    type="flow", direction="vertical"
  }
  local dock_preview_holder = rhs.add{
    type="frame", style="inside_deep_frame", direction="vertical"
  }
  -- ugh
  extra_data(button.player_index)["dock_preview_holder"] = dock_preview_holder
  dock_preview_holder.style.horizontally_stretchable = true
  dock_preview_holder.style.vertically_stretchable = true
  dock_preview_holder.style.minimal_width = 256
  dock_preview_holder.style.minimal_height = 256
  dock_preview_holder.style.horizontal_align = "center"
  dock_preview_holder.style.vertical_align = "center"
  -- so there's something there

  local do_the_dock_button = rhs.add{
    type="button", name = "pkspd_do_the_dock_button",
    caption={"pkspd-gui.initiate-dock"},
    enabled = false
  }
  do_the_dock_button.style.horizontally_stretchable = true
  extra_data(button.player_index)["do_the_dock_button"] = do_the_dock_button
end

local function make_whole_gui(evt)
  if evt.gui_type ~= defines.gui_type.entity
      or not evt.entity
      or evt.entity.name ~= "pkspd-platform-dock"
  then
    return
  end
  local player = game.get_player(evt.player_index)
  if not player then return end

  local dock = evt.entity
  local dock_info = linklib.dock_info(dock)

  local main_frame = ui_lib.new_main_frame(
    player, "pkspd_dock", dock.prototype.localised_name, {tid = dock.unit_number}
  )

  local main_content = main_frame.add{
    type="frame", direction="vertical",
    style="entity_frame"
  }
  local extra = extra_data(player)

  local status_wrap = main_content.add{
    type="flow", name="pkspd_status_wrapper", direction="vertical",
    style="two_module_spacing_vertical_flow"
  }
  extra["status_wrapper"] = status_wrap
  make_dock_status(status_wrap, dock)

  main_content.add{type="line"}

  local side = (dock_info["mode"] == "manual") and "left" or "right"
  local auto_manual_switch = main_content.add{
    type="switch",
    name="pkspd_dock_auto_manual_switch",
    left_label_caption={"pkspd-gui.manual-mode"},
    right_label_caption={"pkspd-gui.automatic-mode"},
    switch_state=side
  }
  extra["auto_manual_switch"] = auto_manual_switch

  make_auto_circuit_control(main_content)

  main_content.add{type="line"}

  -- local popdown_holder = main_content.add{
  --   type="flow", direction="vertical"
  -- }
  local manual_popdown_button = main_content.add{
    type="button",
    name="pkspd_dock_manual_popdown_button",
    caption={"pkspd-gui.manual-dock"},
  }
  extra["manual_popdown_button"] = manual_popdown_button
  manual_popdown_button.style.horizontally_stretchable = true
  manual_popdown_button.enabled = (dock_info["mode"] == "manual")

  dock_ui.update_ui(main_frame)
end

-- Handlers

local function handle_undock(button)
  local main_frame = ui_lib.find_parent_main_frame(button)
  local dock = game.get_entity_by_unit_number(main_frame.tags["tid"])
  linklib.unlink_dock(dock)
  dock_ui.update_ui(main_frame)
end

local function handle_auto_manual_switch(switch)
  local mode = (switch.switch_state == "left") and "manual" or "automatic"
  local dock = game.get_entity_by_unit_number(
    ui_lib.find_parent_main_frame(switch).tags["tid"]
  )
  local dock_info = linklib.dock_info(dock)
  dock_info.mode = mode
end

local function handle_autodock_picker(picker)
  local _, dock_info, _ = dock_info_extra(picker)
  dock_info["autodock_frequency"] = picker.elem_value
end

local function handle_dock_selection(button)
  button.toggled = true
  local for_dock = button.tags["for_dock"]
  local dock_object = game.get_entity_by_unit_number(for_dock)

  local main_frame = ui_lib.find_parent_main_frame(button)
  extra_data(button.player_index)["picked_manual_dock"] = 
    game.get_entity_by_unit_number(for_dock)

  for _,other_button in ipairs(button.parent.children) do
    if other_button ~= button then
      other_button.toggled = false
    end
  end

  local preview_holder = extra_data(button.player_index).dock_preview_holder
  preview_holder.clear()
  -- it needs a position but we're about to override it
  local cam = preview_holder.add{type="camera", position={0,0}}
  cam.style.horizontally_stretchable = true
  cam.style.vertically_stretchable = true
  cam.entity = dock_object
  cam.zoom = 0.5
  cam.visible = true

  local dewit_button = extra_data(button.player_index)["do_the_dock_button"]
  dewit_button.enabled = true
end

local function handle_do_dock(elt)
  local main_frame = ui_lib.find_parent_main_frame(elt)
  local player = game.get_player(elt.player_index)

  local this_dock = game.get_entity_by_unit_number(
    main_frame.tags["tid"]
  )
  -- Force manual control so it doesn't instantly try to undock
  linklib.dock_info(this_dock)["mode"] = "manual"

  local extras = extra_data(player)
  local that_dock = extras["picked_manual_dock"]
  if not that_dock then
    player.print("Somehow pressed the button without picking a dock?!")
    main_frame.destroy()
    return
  end
  linklib.dock_info(that_dock)["mode"] = "manual"

  local err = linklib.link_docks(this_dock, that_dock)
  if err then
    player.print(err)
  end
  -- eyy we did it!
  -- for _,dock in ipairs{this_dock, that_dock} do
  --   dock.surface.play_sound{
  --     path="__base__/sound/silo-raise-rocket.ogg",
  --     position=dock.position
  --   }
  -- end
  extras["manual_dock_popdown"].destroy()
  dock_ui.update_ui(main_frame)
end

dock_ui.update_uis = function()
  for _,player in pairs(game.connected_players) do
    local gui = player.gui.screen["pkspd_dock"]
    if gui then dock_ui.update_ui(gui) end
  end
end
dock_ui.update_ui = function(gui)
  local dock = game.get_entity_by_unit_number(gui.tags["tid"])
  if not dock then
    gui.destroy()
    return
  end
  local dock_info = linklib.dock_info(dock)
  local other_dock = linklib.find_linked_dock(dock)

  local extra = extra_data(gui.player_index)
  local status_wrap = extra["status_wrapper"]
  status_wrap.clear()
  make_dock_status(status_wrap, dock)

  local mode = dock_info["mode"]
  local side = (mode == "manual") and "left" or "right"
  extra["auto_manual_switch"].switch_state = side
  extra["manual_popdown_button"].enabled =
    (mode == "manual" and other_dock == nil)

  -- TODO: updating dock list in real time
end

dock_ui.handler_lib.events[defines.events.on_gui_opened] = make_whole_gui
dock_ui.handler_lib.events[defines.events.on_gui_click] = function(event)
  local elt = event.element
  if not elt or not elt.valid then return end

  if elt.name == "pkspd_dock_auto_manual_switch" then
    handle_auto_manual_switch(elt)
  elseif elt.name == "pkspd_undock" then
    handle_undock(elt)
  elseif elt.name == "pkspd_dock_manual_popdown_button" then
    make_manual_dock_popdown(elt)
  elseif elt.tags["pkspd_dock_line"] then
    handle_dock_selection(elt)
  elseif elt.name == "pkspd_do_the_dock_button" then
    handle_do_dock(elt)
  end
end
dock_ui.handler_lib.events[defines.events.on_gui_elem_changed] = function(event)
  local elt = event.element
  if not elt or not elt.valid then return end
  if elt.name == "pkspd_dock_autodock_signal" then
    handle_autodock_picker(elt)
  end
end

return dock_ui
