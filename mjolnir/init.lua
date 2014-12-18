local application = require "mjolnir.application"
local hotkey = require "mjolnir.hotkey"
local window = require "mjolnir.window"

-- Window Management

hotkey.bind({"ctrl", "alt", "cmd"}, "p", function()
  local win = window.focusedwindow()
  if not win:isfullscreen() then
    win:movetounit({x=0, y=0, w=0.5, h=0.5})
  end
end)
hotkey.bind({"ctrl", "alt", "cmd"}, "\\", function()
  local win = window.focusedwindow()
  if not win:isfullscreen() then
    win:movetounit({x=0.5, y=0, w=0.5, h=0.5})
  end
end)
hotkey.bind({"ctrl", "alt", "cmd"}, "[", function()
  local win = window.focusedwindow()
  if not win:isfullscreen() then
    win:movetounit({x=0, y=0.5, w=0.5, h=0.5})
  end
end)
hotkey.bind({"ctrl", "alt", "cmd"}, "]", function()
  local win = window.focusedwindow()
  if not win:isfullscreen() then
    win:movetounit({x=0.5, y=0.5, w=0.5, h=0.5})
  end
end)

hotkey.bind({"ctrl", "alt", "cmd"}, "right", function()
  local win = window.focusedwindow()
  if not win:isfullscreen() then
    win:movetounit({x=0.5, y=0, w=0.5, h=1})
  end
end)
hotkey.bind({"ctrl", "alt", "cmd"}, "left", function()
  local win = window.focusedwindow()
  if not win:isfullscreen() then
    win:movetounit({x=0, y=0, w=0.5, h=1})
  end
end)
hotkey.bind({"ctrl", "alt", "cmd"}, "up", function()
  local win = window.focusedwindow()
  if not win:isfullscreen() then
    win:movetounit({x=0, y=0, w=1, h=0.5})
  end
end)
hotkey.bind({"ctrl", "alt", "cmd"}, "down", function()
  local win = window.focusedwindow()
  if not win:isfullscreen() then
    win:movetounit({x=0, y=0.5, w=1, h=0.5})
  end
end)
hotkey.bind({"ctrl", "alt", "cmd"}, "return", function()
  local win = window.focusedwindow()
  if win:isfullscreen() ~= nil then
    win:maximize()
  end
end)

-- Mjolnir

hotkey.bind({"ctrl", "alt", "cmd"}, "r", function()
  mjolnir.reload()
end)

hotkey.bind({"ctrl", "alt", "cmd"}, "o", function()
  mjolnir.openconsole()
end)
