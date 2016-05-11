local resize   = require 'resize'
local itunes   = require 'itunes'
local screen   = require 'screen'
local chrome   = require 'chrome'
local osx      = require 'osx'
local finder   = require 'finder'
local volume   = require 'volume'

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
    Wunderlist = "'",
    MacVim     = '.'
  },
  [{ 'cmd', 'shift'}] = {
    [ 'Nylas N1' ] = '/'
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

hs.hotkey.bind({ 'cmd', 'alt', 'shift'}, 'a', function() itunes.display() end)
hs.hotkey.bind({ 'ctrl' }, 'space', function() itunes.playpause() end)
hs.hotkey.bind({ 'cmd', 'alt' }, 'left', function() itunes.previous() end)
hs.hotkey.bind({ 'cmd', 'alt' }, 'right', function() itunes.next() end)
hs.hotkey.bind({ 'ctrl', 'cmd' }, 'right', function() itunes.forward() end)
hs.hotkey.bind({ 'ctrl', 'cmd' }, 'left', function() itunes.backward() end)
hs.hotkey.bind({ 'cmd', 'alt' }, 'up', function() itunes.increaseVolume() end)
hs.hotkey.bind({ 'cmd', 'alt' }, 'down', function() itunes.decreaseVolume() end)
hs.hotkey.bind({ 'ctrl', 'shift' }, 'space', function()
  itunes.addToPlaylist('Dunno')
end)
hs.hotkey.bind({ 'ctrl', 'shift' }, ',', function()
  itunes.addToPlaylist('Erg')
end)

-- Chrome

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
  if hs.execute('networksetup -getairportpower en0 | grep On') == '' then
    hs.alert.show('Turning WiFi on...', 0.5)
    os.execute('networksetup -setairportpower en0 on')
  else
    hs.alert.show('Turning WiFi off...', 0.5)
    os.execute('networksetup -setairportpower en0 off')
  end
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

-- Auto-reload configuration

function reloadConfig(files) hs.reload() end
hs.pathwatcher.new(os.getenv('HOME') .. '/.hammerspoon/', reloadConfig):start()

-- Watch for Screen changes

screen.watch()

hs.alert('Hammerspoon Reloaded', 0.5)
