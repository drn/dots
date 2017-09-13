local resize = require 'resize'
local music  = require 'music'
local screen = require 'screen'
local chrome = require 'chrome'
local osx    = require 'osx'
local finder = require 'finder'
local volume = require 'volume'
local wifi   = require 'wifi'

-- Window Management

local resizemod = {'ctrl', 'alt', 'cmd'}
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
table.insert(resizemod, 'shift')
hs.hotkey.bind(resizemod, 'return', function() resize.changeScreen() end)

-- Fine Grained Window Adjustment

local resizeTouchMod = {'ctrl', 'alt', 'cmd', 'shift'}
local directions = {'left', 'right', 'up', 'down'}
for _,direction in pairs(directions) do
  hs.hotkey.bind(resizeTouchMod, direction, function() resize.touch(direction) end)
end

-- Application

local bindings = {
  [{ 'cmd', 'alt', 'shift'}] = {
    iTerm      = 'i',
    Safari     = 'return',
    Messages   = 'n',
    Slack      = 'm',
    Discord    = 'j',
    Wunderlist = "'",
    MacVim     = '.'
  },
  [{ 'cmd', 'shift'}] = {
    [ 'Mailplane 3' ] = '/'
  },
  [{ 'cmd', 'alt'}] = {
    [ 'Google Chrome' ] = 'return'
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

hs.hotkey.bind({ 'cmd', 'alt', 'shift'}, 'a', function() music.display() end)
hs.hotkey.bind({ 'cmd', 'alt', 'shift'}, 'k', function() music.open() end)
hs.hotkey.bind({ 'ctrl' }, 'space', function() music.playpause() end)
hs.hotkey.bind({ 'cmd', 'alt' }, 'left', function() music.previous() end)
hs.hotkey.bind({ 'cmd', 'alt' }, 'right', function() music.next() end)
hs.hotkey.bind({ 'ctrl', 'cmd' }, 'right', function() music.forward() end)
hs.hotkey.bind({ 'ctrl', 'cmd' }, 'left', function() music.backward() end)
hs.hotkey.bind({ 'cmd', 'alt' }, 'up', function() music.increaseVolume() end)
hs.hotkey.bind({ 'cmd', 'alt' }, 'down', function() music.decreaseVolume() end)
hs.hotkey.bind({ 'ctrl', 'cmd' }, 'space', function() hs.alert('space') end)

-- Chrome

hs.hotkey.bind({'cmd', 'shift'}, 'l', function()
  chrome.refocus()
end)
hs.hotkey.bind({'ctrl', 'alt', 'cmd'}, 'n', function()
  chrome.openProfileMenu()
end)
hs.hotkey.bind({'ctrl', 'alt', 'cmd', 'shift'}, 'n', function()
  chrome.copyUrl()
end)

-- Date & Time

hs.hotkey.bind({'ctrl', 'cmd'}, '/', function()
  local date = os.date('%A, %h %e')
  local time = os.date('%I:%M%p'):gsub('^0',''):lower()
  hs.alert.closeAll(0)
  hs.alert(time..' - '..date, 2.5)
end)

-- Open Hammerspoon Console

hs.hotkey.bind({'ctrl', 'alt', 'cmd'}, 'o', function() hs.openConsole() end)

-- OS Bindings

hs.hotkey.bind({'ctrl', 'alt', 'cmd', 'shift'}, 'l', function()
  osx.screensaver()
end)
hs.hotkey.bind({'ctrl', 'alt', 'cmd'}, 'r', function()
  finder.refresh()
end)
hs.hotkey.bind({'ctrl', 'alt', 'cmd'}, 'i', function()
  wifi.toggle()
end)

-- Volume Bindings

hs.hotkey.bind({'ctrl', 'cmd'}, 'up', function()
  volume.increase()
end)
hs.hotkey.bind({'ctrl', 'cmd'}, 'down', function()
  volume.decrease()
end)

-- Test Binding

hs.hotkey.bind({'ctrl', 'alt', 'cmd'}, 'j', function()
end)

-- Reload configuration

hs.hotkey.bind({'ctrl', 'cmd'}, 'delete', function() hs.reload() end)
function reloadConfig(files) hs.reload() end
hs.pathwatcher.new(os.getenv('HOME') .. '/.hammerspoon/', reloadConfig):start()

-- Watch for Screen changes

screen.watch()

hs.alert('Hammerspoon Reloaded', 0.5)
