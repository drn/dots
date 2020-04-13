local resize     = require 'resize'
local music      = require 'music'
local screen     = require 'screen'
local chrome     = require 'chrome'
local osx        = require 'osx'
local volume     = require 'volume'
local brightness = require 'brightness'
local alert      = require 'alert'
local background = require 'background'

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
hs.hotkey.bind(resizemod, '/', function() resize.center() end)
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
    iTerm                 = 'i',
    Safari                = 'return',
    Messages              = 'n',
    Slack                 = 'm',
    Discord               = 'j',
    [ "Microsoft To Do" ] = "'",
    MacVim                = '.'
  },
  [{ 'cmd', 'shift'}] = {
    [ 'Superhuman' ] = '/'
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

-- Chrome

hs.hotkey.bind({'ctrl', 'alt', 'cmd'}, 'l', function()
  chrome.refocus()
end)
hs.hotkey.bind({'ctrl', 'alt', 'cmd'}, 'n', function()
  chrome.openProfileMenu()
end)
hs.hotkey.bind({'ctrl', 'alt', 'cmd', 'shift'}, 'm', function()
  chrome.closeOtherTabs()
end)

-- Date & Time

hs.hotkey.bind({'ctrl', 'cmd'}, '/', function()
  local date = os.date('%A, %h %e')
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
  volume.increase(2)
end)
hs.hotkey.bind({'ctrl', 'cmd'}, 'down', function()
  volume.decrease()
end, nil, function()
  volume.decrease(2)
end)

-- Brightness Bindings

hs.hotkey.bind({'ctrl', 'alt'}, 'up', function()
  brightness.increase()
end, nil, function()
  brightness.increase()
end)
hs.hotkey.bind({'ctrl', 'alt'}, 'down', function()
  brightness.decrease()
end, nil, function()
  brightness.decrease()
end)

-- Background Bindings

hs.hotkey.bind({'ctrl', 'alt', 'cmd'}, '-', function()
  background.backward()
end)

hs.hotkey.bind({'ctrl', 'alt', 'cmd'}, '=', function()
  background.forward()
end)

-- Test Binding

hs.hotkey.bind({'ctrl', 'alt', 'cmd'}, 'j', function()
end)

-- Reload configuration

hs.hotkey.bind({'ctrl', 'cmd'}, 'delete', function() hs.reload() end)
function reloadConfig(files) hs.reload() end
hs.pathwatcher.new(os.getenv('HOME') .. '/.hammerspoon/', reloadConfig):start()

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
  alpha = 1
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
