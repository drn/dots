local resize   = require 'resize'
local itunes   = require 'itunes'
local screen   = require 'screen'
local torrent  = require 'torrent'
local chrome   = require 'chrome'

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

-- Application

local bindings = {
  [{ 'cmd', 'alt', 'shift'}] = {
    iTerm      = 'i',
    Safari     = 'return',
    Messages   = 'n',
    HipChat    = 'm',
    Wunderlist = "'",
    MacVim     = '.'
  },
  [{ 'cmd', 'shift'}] = {
    [ 'Mailplane 3' ] = '/',
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

-- Chrome

hs.hotkey.bind({'ctrl', 'alt', 'cmd'}, 'n', function() chrome.nextProfile() end)
hs.hotkey.bind({'ctrl', 'alt', 'cmd', 'shift'}, 'n', function()
  chrome.swapProfile()
end)

-- Date & Time

hs.hotkey.bind({'ctrl', 'cmd'}, '/', function()
  local date = os.date('%A, %h %e')
  local time = os.date('%H:%M%p'):gsub('^0',''):lower()
  hs.alert(time..' - '..date, 2.5)
end)

-- Open Hammerspoon Console

hs.hotkey.bind({'ctrl', 'alt', 'cmd'}, 'o', function() hs.openConsole() end)

-- Test Binding

hs.hotkey.bind({'ctrl', 'alt', 'cmd'}, 'j', function()
  -- TODO
end)

-- Auto-reload configuration

function reloadConfig(files) hs.reload() end
hs.pathwatcher.new(os.getenv('HOME') .. '/.hammerspoon/', reloadConfig):start()

-- Watch for Screen changes

screen.watch()

-- Watch for Torrent changes

torrent.watch()

hs.alert('Hammerspoon Reloaded', 0.5)
