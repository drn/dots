local hotkey = require "mjolnir.hotkey"
local window = require "mjolnir.window"
local screen = require "mjolnir.screen"
local app = require "mjolnir.application"

-- Window Management

function resize(coordinates)
  local win = window.focusedwindow()
  if win ~= nil then
    win:movetounit(coordinates)
  end
end

---- Quadrants

hotkey.bind({"ctrl", "alt", "cmd"}, "p", function()
  resize({x=0, y=0, w=0.5, h=0.5})
end)
hotkey.bind({"ctrl", "alt", "cmd"}, "\\", function()
  resize({x=0.5, y=0, w=0.5, h=0.5})
end)
hotkey.bind({"ctrl", "alt", "cmd"}, "[", function()
  resize({x=0, y=0.5, w=0.5, h=0.5})
end)
hotkey.bind({"ctrl", "alt", "cmd"}, "]", function()
  resize({x=0.5, y=0.5, w=0.5, h=0.5})
end)

---- Halves

hotkey.bind({"ctrl", "alt", "cmd"}, "right", function()
  resize({x=0.5, y=0, w=0.5, h=1})
end)
hotkey.bind({"ctrl", "alt", "cmd"}, "left", function()
  resize({x=0, y=0, w=0.5, h=1})
end)
hotkey.bind({"ctrl", "alt", "cmd"}, "up", function()
  resize({x=0, y=0, w=1, h=0.5})
end)
hotkey.bind({"ctrl", "alt", "cmd"}, "down", function()
  resize({x=0, y=0.5, w=1, h=0.5})
end)

---- Fullscreen

hotkey.bind({"ctrl", "alt", "cmd"}, "return", function()
  resize({x=0, y=0, w=1, h=1})
end)

---- Center

hotkey.bind({"ctrl", "alt", "cmd"}, "'", function()
  local win = window.focusedwindow()
  if win == nil then return end
  local screenrect = win:screen():fullframe()
  local f = win:frame()
  f.x = screenrect.x + ((screenrect.w / 2) - (f.w / 2))
  f.y = screenrect.y + ((screenrect.h / 2) - (f.h / 2))
  win:setframe(f)
end)

---- Screen

hotkey.bind({"ctrl", "alt", "cmd", "shift"}, "return", function()
  local win = window.focusedwindow()
  if win == nil then return end
  current = win:screen()
  next = current:next()
  if current:id() ~= next:id() then
    win:setframe(next:fullframe())
  end
end)

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
    hotkey.bind(modifiers, key, function()
      app.launchorfocus(name)
    end)
  end
end

-- Mjolnir

hotkey.bind({"ctrl", "alt", "cmd"}, "r", function()
  mjolnir.reload()
end)
hotkey.bind({"ctrl", "alt", "cmd"}, "o", function()
  mjolnir.openconsole()
end)
