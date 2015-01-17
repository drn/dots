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

local function formatSeconds(seconds)
  local minutes = math.floor(seconds / 60)
  local hours = math.floor(minutes / 60)
  local formatted = math.floor(seconds % 60)..'s'
  if minutes > 0 then formatted = (minutes % 60)..'m '..formatted end
  if hours > 0 then formatted = hours..'h '..formatted end
  return formatted
end

local function position()
  local currentPosition = tonumber(tell('player position'))
  return currentPosition ~= nil and currentPosition or 0
end

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
  local updated = position() + 10
  tell('set player position to '..updated)
  message = (position() < updated) and ' ⇥' or ' → '..formatSeconds(updated)
  hs.alert(message, 0.5)
end

function itunes.backward()
  if not isRunning() then return end
  local updated = position() - 10
  tell('set player position to '..updated)
  local message = (updated < 0) and ' ⇤' or ' ← '..formatSeconds(updated)
  hs.alert(message, 0.5)
end

function itunes.increaseVolume()
  if not isRunning() then return end
  tell('set sound volume to '..tonumber(tell('sound volume')) + 10)
  hs.alert(' ↑ '..tell('sound volume')..'%', 0.5)
end

function itunes.decreaseVolume()
  if not isRunning() then return end
  tell('set sound volume to '..tonumber(tell('sound volume')) - 10)
  hs.alert(' ↓ '..tell('sound volume')..'%', 0.5)
end

function itunes.maxVolume()
  if not isRunning() then return end
  tell('set sound volume to 100')
  hs.alert(' ↑ 100%', 0.5)
end

function itunes.minVolume()
  if not isRunning() then return end
  tell('set sound volume to 0')
  hs.alert(' ↓ 0%', 0.5)
end

function itunes.playpause()
  tell('playpause')
  icon = (tell('player state as string') == 'playing') and ' ▶' or ' ◼'
  hs.alert(icon, 0.5)
end

function itunes.display()
  if not isRunning() then return end
  hs.itunes.displayCurrentTrack()
end

return itunes
