package.path = os.getenv("HOME").."/.mjolnir/?.lua;"..package.path
local hotkey      = require "mjolnir.hotkey"
local itunes      = require "itunes"

-- Mjolnir

hotkey.bind({"ctrl", "alt", "cmd"}, "r", function() mjolnir.reload() end)
hotkey.bind({"ctrl", "alt", "cmd"}, "o", function() mjolnir.openconsole() end)

-- iTunes

hotkey.bind({ "cmd", "alt", "shift"}, "a", function() itunes.notification() end)
hotkey.bind({ "ctrl" }, "space", function() itunes.playpause() end)
hotkey.bind({ "cmd", "alt" }, "left", function() itunes.back() end)
hotkey.bind({ "cmd", "alt" }, "right", function() itunes.next() end)
hotkey.bind({ "ctrl", "cmd" }, "right", function() itunes.position(10) end)
hotkey.bind({ "ctrl", "cmd" }, "left", function() itunes.position(-10) end)
hotkey.bind({ "ctrl", "cmd" }, "up", function() itunes.volume(5) end)
hotkey.bind({ "ctrl", "cmd" }, "down", function() itunes.volume(-5) end)
