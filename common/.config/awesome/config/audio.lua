local awful = require("awful")
local gears = require("gears")

local M = {}

local audio_script = gears.filesystem.get_configuration_dir() .. "scripts/audio.sh"

function M.auto()
  awful.spawn.with_shell(audio_script .. " auto >/dev/null 2>&1")
end

function M.start()
  gears.timer.start_new(3, function()
    M.auto()
    return false
  end)

  gears.timer({
    timeout = 3,
    autostart = true,
    call_now = false,
    callback = function()
      M.auto()
    end,
  })
end

return M
