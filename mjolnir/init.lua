local hotkey = require "mjolnir.hotkey"
local window = require "mjolnir.window"
local screen = require "mjolnir.screen"
local application = require "mjolnir.application"

-- Window Management

function resize(coordinates)
  local win = window.focusedwindow()
  if win ~= nil then
    win:movetounit(coordinates)
  end
end

local bindings = {
  -- Quadrants
  p          = { x=0,   y=0,   w=0.5, h=0.5 },
  ["\\"]     = { x=0.5, y=0,   w=0.5, h=0.5 },
  ["["]      = { x=0,   y=0.5, w=0.5, h=0.5 },
  ["]"]      = { x=0.5, y=0.5, w=0.5, h=0.5 },
  -- Halves
  right      = { x=0.5, y=0,   w=0.5, h=1   },
  left       = { x=0,   y=0,   w=0.5, h=1   },
  up         = { x=0,   y=0,   w=1,   h=0.5 },
  down       = { x=0,   y=0.5, w=1,   h=0.5 },
  -- Fullscreen
  ["return"] = { x=0,   y=0,   w=1,   h=1   }
}
for key,coordinates in pairs(bindings) do
  hotkey.bind({"ctrl", "alt", "cmd"}, key, function()
    resize(coordinates)
  end)
end

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
      application.launchorfocus(name)
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
