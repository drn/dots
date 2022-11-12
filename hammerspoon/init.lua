local alert      = require 'alert'
local background = require 'background'
local bluetooth  = require 'bluetooth'
local brightness = require 'brightness'
local browser    = require 'browser'
local log        = require 'log'
local music      = require 'music'
local osx        = require 'osx'
local resize     = require 'resize'
local screen     = require 'screen'
local volume     = require 'volume'

-- Window Management

local resizemod = {'ctrl', 'alt', 'cmd'}
local resizebindings = {
  topleft       = 'p',
  topright      = '\\',
  bottomleft    = '[',
  bottomright   = ']',
  right         = 'right',
  left          = 'left',
  top           = 'up',
  bottom        = 'down',
  full          = 'return',
  fitVertical   = "'",
  fitHorizontal = ";"
}
for name,key in pairs(resizebindings) do
  hs.hotkey.bind(resizemod, key, function()
    resize[name]()
  end)
end
hs.hotkey.bind(resizemod, '/', function() resize.center(false) end)
hs.hotkey.bind(resizemod, '.', function() resize.center(true) end)
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
    Alacritty             = 'i',
    Messages              = 'n',
    Notion                = ';',
    Slack                 = 'm',
    Spotify               = 'space',
    Things3               = "'",
    [ 'Google Calendar' ] = '/'
  },
  [{ 'cmd', 'shift'}] = {
    [ 'Superhuman' ] = '/'
  },
  [{ 'cmd', 'alt'}] = {
    [ 'Brave Browser' ] = 'return'
  }
}
for modifiers,apps in pairs(bindings) do
  for name, key in pairs(apps) do
    hs.hotkey.bind(modifiers, key, function()
      hs.application.launchOrFocus(name)
    end)
  end
end

-- Music

hs.hotkey.bind({ 'cmd', 'alt', 'shift'}, 'a', function() music.display() end)
hs.hotkey.bind({ 'cmd', 'alt', 'shift'}, 'k', function() music.open() end)
hs.hotkey.bind({ 'ctrl' }, 'space', function() music.playpause() end)
hs.hotkey.bind({ 'cmd', 'alt' }, 'left', function() music.previous() end)
hs.hotkey.bind({ 'cmd', 'alt' }, 'right', function() music.next() end)
hs.hotkey.bind({ 'ctrl', 'cmd' }, 'right', function()
  music.forward()
end, nil, function()
  music.forward(1)
end)
hs.hotkey.bind({ 'ctrl', 'cmd' }, 'left', function()
  music.backward()
end, nil, function()
  music.backward(1)
end)
hs.hotkey.bind({ 'cmd', 'alt' }, 'up', function()
  music.increaseVolume()
end, nil, function()
  music.increaseVolume()
end)
hs.hotkey.bind({ 'cmd', 'alt' }, 'down', function()
  music.decreaseVolume()
end, nil, function()
  music.decreaseVolume()
end)
hs.hotkey.bind({ 'ctrl', 'cmd' }, '-', function()
  music.remove()
end)
hs.hotkey.bind({ 'ctrl', 'cmd' }, '=', function()
  music.save()
end)

-- Browser

hs.hotkey.bind({'ctrl', 'alt', 'cmd'}, 'n', function()
  browser.openProfileMenu()
end)
hs.hotkey.bind({'ctrl', 'alt', 'cmd', 'shift'}, 'm', function()
  browser.closeOtherTabs()
end)

-- Date & Time

hs.hotkey.bind({'ctrl', 'cmd'}, '/', function()
  local date = os.date('%A, %B %d'):gsub(' 0', ' ')
  local time = os.date('%I:%M%p'):gsub('^0',''):lower()
  alert.close()
  alert.show(time..' - '..date, 2.5)
end)

-- Open Hammerspoon Console

hs.hotkey.bind({'ctrl', 'alt', 'cmd'}, 'o', function() hs.openConsole() end)

-- OS Bindings

hs.hotkey.bind({'ctrl', 'alt', 'cmd', 'shift'}, 'l', function()
  osx.screensaver()
end)

-- Volume Bindings

hs.hotkey.bind({'ctrl', 'cmd'}, 'up', function()
  volume.increase()
end, nil, function()
  volume.increase()
end)
hs.hotkey.bind({'ctrl', 'cmd'}, 'down', function()
  volume.decrease()
end, nil, function()
  volume.decrease()
end)

-- Brightness Bindings

hs.hotkey.bind({'ctrl', 'alt'}, 'up', function()
  brightness.primary.increase()
end, nil, function()
  brightness.primary.increase()
end)
hs.hotkey.bind({'ctrl', 'alt'}, 'down', function()
  brightness.primary.decrease()
end, nil, function()
  brightness.primary.decrease()
end)
hs.hotkey.bind({'ctrl', 'alt', 'shift'}, 'up', function()
  brightness.secondary.increase()
end, nil, function()
  brightness.secondary.increase()
end)
hs.hotkey.bind({'ctrl', 'alt', 'shift'}, 'down', function()
  brightness.secondary.decrease()
end, nil, function()
  brightness.secondary.decrease()
end)

-- Background Bindings

hs.hotkey.bind({'ctrl', 'alt', 'cmd'}, '-', function()
  background.primary.backward()
end, nil, function()
  background.primary.backward()
end)

hs.hotkey.bind({'ctrl', 'alt', 'cmd'}, '=', function()
  background.primary.forward()
end, nil, function()
  background.primary.forward()
end)

hs.hotkey.bind({'ctrl', 'alt', 'cmd', 'shift'}, '-', function()
  background.secondary.backward()
end, nil, function()
  background.secondary.backward()
end)

hs.hotkey.bind({'ctrl', 'alt', 'cmd', 'shift'}, '=', function()
  background.secondary.forward()
end, nil, function()
  background.secondary.forward()
end)

-- Bluetooth Bindings

hs.hotkey.bind({'ctrl', 'alt', 'cmd'}, '0', function()
  bluetooth.hd1Status()
end)

hs.hotkey.bind({'ctrl', 'alt', 'cmd', 'shift'}, '0', function()
  bluetooth.hd1Toggle()
end)

-- Test Binding

hs.hotkey.bind({'ctrl', 'alt', 'cmd'}, 'j', function()
end)

-- Open hammerspoon console

hs.hotkey.bind({'ctrl', 'alt', 'cmd'}, 'delete', function()
  hs.toggleConsole()
end)

-- Reload configuration

hs.hotkey.bind({'ctrl', 'cmd'}, 'delete', function() hs.reload() end)
hs.pathwatcher.new(os.getenv('HOME') .. '/.hammerspoon/', hs.reload):start()

-- Watch for Screen changes

-- screen.watch()

-- Set default alert styles

hs.alert.defaultStyle['textSize'] = 24
hs.alert.defaultStyle['radius'] = 20
hs.alert.defaultStyle['strokeColor'] = {
  white = 1,
  alpha = 0
}
hs.alert.defaultStyle['fillColor'] = {
  red   = 9/255,
  green = 8/255,
  blue  = 32/255,
  alpha = 0.9
}
hs.alert.defaultStyle['textColor'] = {
  red   = 209/255,
  green = 236/255,
  blue  = 240/255,
  alpha = 1
}
hs.alert.defaultStyle['textFont'] = 'Helvetica Light'

hs.allowAppleScript(true)
alert.show('Hammerspoon Reloaded')
