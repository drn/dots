local itunes = {}

local as = require 'hs.applescript'

local function tell(cmd)
  local _cmd = 'tell application "iTunes" to ' .. cmd
  local _ok, result = as.applescript(_cmd)
  return result
end

local function isRunning()
  local _cmd = 'tell application "System Events" to (name of processes)'..
               ' contains "iTunes"'
  local _ok, result = as.applescript(_cmd)
  return result:match('true') ~= nil
end

local function position() return tonumber(tell('player position')) end

function itunes.next()
  if not isRunning() then return end
  hs.itunes.next()
end

function itunes.previous()
  if not isRunning() then return end
  hs.itunes.previous()
end

function itunes.forward()
  if not isRunning() then return end
  local updated = math.floor(position() + 10)
  tell('set player position to '..updated)
  message = (position() < updated) and ' ⇥' or ' → '..updated..'s'
  hs.alert.show(message, 0.5)
end

function itunes.backward()
  if not isRunning() then return end
  local updated = math.floor(position() - 10)
  tell('set player position to '..updated)
  local message = (updated < 0) and ' ⇤' or ' ← '..updated..'s'
  hs.alert.show(message, 0.5)
end

function itunes.increaseVolume()
  if not isRunning() then return end
  tell('set sound volume to '..tonumber(tell('sound volume')) + 10)
  hs.alert.show(' ↑ '..tell('sound volume')..'%', 0.5)
end

function itunes.decreaseVolume()
  if not isRunning() then return end
  tell('set sound volume to '..tonumber(tell('sound volume')) - 10)
  hs.alert.show(' ↓ '..tell('sound volume')..'%', 0.5)
end

function itunes.maxVolume()
  if not isRunning() then return end
  tell('set sound volume to 100')
  hs.alert.show(' ↑ 100%', 0.5)
end

function itunes.minVolume()
  if not isRunning() then return end
  tell('set sound volume to 0')
  hs.alert.show(' ↓ 0%', 0.5)
end

function itunes.playpause()
  tell('playpause')
  icon = (tell('player state as string') == 'playing') and ' ▶' or ' ◼'
  hs.alert.show(icon, 0.5)
end

function itunes.display()
  if not isRunning() then return end
  hs.itunes.displayCurrentTrack()
end

return itunes
