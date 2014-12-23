local itunes = {}

local as = require "hs.applescript"

local function tell(cmd)
  local _cmd = 'tell application "iTunes" to ' .. cmd
  local _ok, result = as.applescript(_cmd)
  return result
end

local function position()
  return tonumber(tell('player position'))
end

function itunes.forward()
  local updated = math.floor(position() + 10)
  tell('set player position to '..updated)
  message = (position() < updated) and ' ⇥' or ' → '..updated..'s'
  hs.alert.show(message, 0.5)
end

function itunes.backward()
  local updated = math.floor(position() - 10)
  tell("set player position to "..updated)
  local message = (updated < 0) and ' ⇤' or ' ← '..updated..'s'
  hs.alert.show(message, 0.5)
end

function itunes.increaseVolume()
  tell('set sound volume to '..tonumber(tell('sound volume')) + 10)
  hs.alert.show(' ↑ '..tell('sound volume')..'%', 0.5)
end

function itunes.decreaseVolume()
  tell('set sound volume to '..tonumber(tell('sound volume')) - 10)
  hs.alert.show(' ↓ '..tell('sound volume')..'%', 0.5)
end

function itunes.maxVolume()
  tell('set sound volume to 100')
  hs.alert.show(' ↑ 100%', 0.5)
end

function itunes.minVolume()
  tell('set sound volume to 0')
  hs.alert.show(' ↓ 0%', 0.5)
end

return itunes
