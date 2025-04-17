require "__core__/lualib/util"
local linklib = require "control/linklib"

local handler = require "__core__/lualib/event_handler"
handler.add_libraries({
  require "control/spawn-helpers",
  require("control/ui-lib").handler_lib,
  require("control/ui").handler_lib,
})
