local util = require "__core__/lualib/util"

local ui_lib = {}

ui_lib.new_main_frame = function(player, name, title_caption, tags)
  local main_frame = player.gui.screen.add{
    type = "frame",
    name = name,
    tags = util.merge{{pkspd_main_frame = true}, tags},
    direction = "vertical",
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
    caption = title_caption,
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
    name = "pkspd_x_button",
    style = "frame_action_button",
    sprite = "utility/close",
    tooltip = { "gui.close-instruction" },
  }

  return main_frame
end

ui_lib.find_parent_main_frame = function(element)
  local it = element
  while it do
    if it.tags["pkspd_main_frame"] then return it end
    it = it.parent
  end
  return nil
end

local function on_gui_click(event)
  if event.element and event.element.name == "pkspd_x_button" then
    ui_lib.find_parent_main_frame(event.element).destroy()
  end
end
local function on_gui_closed(event)
  if event.element and event.element.tags["pkspd_main_frame"] then
    event.element.destroy()
  end
end

ui_lib.handler_lib = {
  events = {
    [defines.events.on_gui_click] = on_gui_click,
    [defines.events.on_gui_closed] = on_gui_closed,
  }
}

return ui_lib

