local spotify = {}
local alert = require 'alert'
local as    = require 'hs.applescript'

local function tell(cmd)
  local _cmd = 'tell application "Spotify" to ' .. cmd
  local _ok, result = as.applescript(_cmd)
  return result
end

local function formatSeconds(seconds)
  local minutes = math.floor(seconds / 60)
  local hours = math.floor(minutes / 60)
  local formatted = math.floor(seconds % 60)..'s'
  if minutes > 0 then formatted = (minutes % 60)..'m '..formatted end
  if hours > 0 then formatted = hours..'h '..formatted end
  return formatted
end

local function duration()
  local currentPosition = tonumber(tell('duration of current track'))
  return currentPosition ~= nil and currentPosition / 1000 or 0
end

local function spotifyExec(command)
  command = command or ''
  local output = hs.execute(
    'source ~/.dots/sys/env; ~/go/bin/spotify '..command
  )
  alert.showOnly(output:gsub('%s*$', ''), 1, 20)
end

function spotify.next()
  if not hs.spotify.isRunning() then return end
  hs.spotify.next()
  alert.showOnly('⇥')
end

function spotify.previous()
  if not hs.spotify.isRunning() then return end
  hs.spotify.previous()
  alert.showOnly('⇤')
end

function spotify.forward(delta)
  if not hs.spotify.isRunning() then return end
  delta = delta or 10
  local updated = hs.spotify.getPosition() + delta
  hs.spotify.setPosition(updated)
  local isZeroPosition = math.floor(hs.spotify.getPosition()) == 0
  local message = isZeroPosition and '⇥' or '→ '..formatSeconds(updated)
  alert.showOnly(message)
end

function spotify.backward(delta)
  if not hs.spotify.isRunning() then return end
  local position = hs.spotify.getPosition()
  if position < 0.5 then
    spotify.previous()
    return
  end
  delta = delta or 10
  local updated = position - delta
  if updated < 0 then updated = 0 end
  hs.spotify.setPosition(updated)
  alert.showOnly('← '..formatSeconds(updated))
end

function spotify.increaseVolume()
  if not hs.spotify.isRunning() then return end
  hs.spotify.volumeUp()
  alert.showOnly('↑ '..hs.spotify.getVolume()..'% ♬')
end

function spotify.decreaseVolume()
  if not hs.spotify.isRunning() then return end
  hs.spotify.volumeDown()
  alert.showOnly('↓ '..hs.spotify.getVolume()..'% ♬')
end

function spotify.maxVolume()
  if not hs.spotify.isRunning() then return end
  hs.spotify.setVolume(100)
  alert.showOnly('↑ 100%')
end

function spotify.minVolume()
  if not hs.spotify.isRunning() then return end
  hs.spotify.setVolume(0)
  alert.showOnly('↓ 0%')
end

function spotify.playpause()
  if not hs.spotify.isRunning() then
    hs.application.launchOrFocus('Spotify')
    alert.showOnly('▶')
  else
    hs.spotify.playpause()
    local icon = hs.spotify.isPlaying() and '▶' or '◼'
    alert.showOnly(icon)
  end
end

function spotify.display()
  if not hs.spotify.isRunning() then return end
  local artist = hs.spotify.getCurrentArtist() or ''
  local album  = hs.spotify.getCurrentAlbum() or ''
  local track  = hs.spotify.getCurrentTrack() or ''
  local current = hs.spotify.getPosition()
  local total   = duration()
  local percent = math.floor(current / total * 100 + 0.5)
  local time   = (
    formatSeconds(current)..
    '  ('..percent..'%)'..
    '\n'..
    formatSeconds(total)
  )
  local info   = track..'\n'..album..'\n'..artist..'\n'..time
  alert.showOnly(info, 1.75, 20)
end

function spotify.open()
  hs.application.launchOrFocus('Spotify')
end

function spotify.toggle()
  spotifyExec()
end

function spotify.save()
  spotifyExec("save")
end

function spotify.remove()
  spotifyExec("remove")
end

return spotify
