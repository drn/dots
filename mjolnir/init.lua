local application = require "mjolnir.application"
local hotkey = require "mjolnir.hotkey"
local window = require "mjolnir.window"

-- Window Management

hotkey.bind({"ctrl", "alt", "cmd"}, "p", function()
  local win = window.focusedwindow()
  if not win:isfullscreen() then
    local f = win:screen():frame()
    f.w = f.w / 2
    f.h = f.h / 2
    win:setframe(f)
  end
end)
hotkey.bind({"ctrl", "alt", "cmd"}, "[", function()
  local win = window.focusedwindow()
  if not win:isfullscreen() then
    local f = win:screen():frame()
    f.w = f.w / 2
    f.h = f.h / 2
    f.x = f.w
    win:setframe(f)
  end
end)
hotkey.bind({"ctrl", "alt", "cmd"}, "]", function()
  local win = window.focusedwindow()
  if not win:isfullscreen() then
    local f = win:screen():frame()
    f.w = f.w / 2
    f.h = f.h / 2
    f.y = f.y + f.h
    win:setframe(f)
  end
end)
hotkey.bind({"ctrl", "alt", "cmd"}, "\\", function()
  local win = window.focusedwindow()
  if not win:isfullscreen() then
    local f = win:screen():frame()
    f.w = f.w / 2
    f.h = f.h / 2
    f.x = f.w
    f.y = f.y + f.h
    win:setframe(f)
  end
end)
hotkey.bind({"ctrl", "alt", "cmd"}, "right", function()
  local win = window.focusedwindow()
  if not win:isfullscreen() then
    local f = win:screen():frame()
    f.w = f.w / 2
    f.x = f.w
    win:setframe(f)
  end
end)
hotkey.bind({"ctrl", "alt", "cmd"}, "left", function()
  local win = window.focusedwindow()
  if not win:isfullscreen() then
    local f = win:screen():frame()
    f.w = f.w / 2
    win:setframe(f)
  end
end)
hotkey.bind({"ctrl", "alt", "cmd"}, "up", function()
  local win = window.focusedwindow()
  if win:isfullscreen() ~= nil then
    local f = win:screen():frame()
    f.h = f.h / 2
    win:setframe(f)
  end
end)
hotkey.bind({"ctrl", "alt", "cmd"}, "down", function()
  local win = window.focusedwindow()
  if not win:isfullscreen() then
    local f = win:screen():frame()
    f.h = f.h / 2
    f.y = f.y + f.h
    win:setframe(f)
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
