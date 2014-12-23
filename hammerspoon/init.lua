local resize = require "resize"

-- Window Management

local resizemod = {"ctrl", "alt", "cmd"}
local resizebindings = {
  topleft     = 'p',
  topright    = '\\',
  bottomleft  = '[',
  bottomright = ']',
  right       = 'right',
  left        = 'left',
  top         = 'up',
  bottom      = 'down',
  full        = 'return'
}
for name,key in pairs(resizebindings) do
  hs.hotkey.bind(resizemod, key, function()
    resize[name]()
  end)
end
hs.hotkey.bind(resizemod, "'", function() resize.center() end)
table.insert(resizemod, "shift")
hs.hotkey.bind(resizemod, "return", function() resize.changescreen() end)

-- Open Hammerspoon Console

hs.hotkey.bind({"ctrl", "alt", "cmd"}, "o", function() hs.openConsole() end)

-- Auto-reload configuration

function reloadConfig(files) hs.reload() end
hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()
hs.alert.show("Hammerspoon Reloaded", 0.8)
