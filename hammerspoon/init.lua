local resize = require "resize"
local itunes = require "itunes"

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

-- Application

local bindings = {
  [{ "cmd", "alt", "shift"}] = {
    iTerm      = "i",
    Safari     = "return",
    Messages   = "n",
    HipChat    = "m",
    Wunderlist = "'",
    MacVim     = "."
  },
  [{ "cmd", "shift"}] = {
    [ "Mailplane 3" ] = "/",
  },
  [{ "cmd", "alt"}] = {
    [ "Google Chrome" ] = "return"
  }
}
for modifiers,apps in pairs(bindings) do
  for name, key in pairs(apps) do
    hs.hotkey.bind(modifiers, key, function()
      hs.application.launchOrFocus(name)
    end)
  end
end

-- iTunes

hs.hotkey.bind({ "cmd", "alt", "shift"}, "a", function()
  hs.itunes.displayCurrentTrack()
end)
hs.hotkey.bind({ "ctrl" }, "space", function() itunes.playpause() end)
hs.hotkey.bind({ "cmd", "alt" }, "left", function() hs.itunes.previous() end)
hs.hotkey.bind({ "cmd", "alt" }, "right", function() hs.itunes.next() end)
hs.hotkey.bind({ "ctrl", "cmd" }, "right", function() itunes.forward() end)
hs.hotkey.bind({ "ctrl", "cmd" }, "left", function() itunes.backward() end)
hs.hotkey.bind({ "ctrl", "cmd" }, "up", function() itunes.increaseVolume() end)
hs.hotkey.bind({ "ctrl", "cmd" }, "down", function() itunes.decreaseVolume() end)
hs.hotkey.bind({ "alt", "cmd" }, "up", function() itunes.maxVolume() end)
hs.hotkey.bind({ "alt", "cmd" }, "down", function() itunes.minVolume() end)

-- Open Hammerspoon Console

hs.hotkey.bind({"ctrl", "alt", "cmd"}, "o", function() hs.openConsole() end)

-- Auto-reload configuration

function reloadConfig(files) hs.reload() end
hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()
hs.alert.show("Hammerspoon Reloaded", 0.5)
