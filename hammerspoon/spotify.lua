local spotify = {}

local as = require 'hs.applescript'

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

local function display(message)
  hs.alert.closeAll(0)
  hs.alert.show(message, 0.5)
end

function spotify.next()
  if not hs.spotify.isRunning() then return end
  hs.spotify.next()
  display(' ⇥')
end

function spotify.previous()
  if not hs.spotify.isRunning() then return end
  hs.spotify.previous()
  display(' ⇤')
end

function spotify.forward()
  if not hs.spotify.isRunning() then return end
  local updated = hs.spotify.getPosition() + 10
  hs.spotify.setPosition(updated)
  message = (math.floor(hs.spotify.getPosition()) == 0) and ' ⇥' or ' → '..formatSeconds(updated)
  display(message)
end

function spotify.backward()
  if not hs.spotify.isRunning() then return end
  local position = hs.spotify.getPosition()
  if position < 0.5 then
    spotify.previous()
    return
  end
  local updated = position - 10
  if updated < 0 then updated = 0 end
  hs.spotify.setPosition(updated)
  display(' ← '..formatSeconds(updated))
end

function spotify.increaseVolume()
  if not hs.spotify.isRunning() then return end
  hs.spotify.volumeUp()
  display(' ↑ '..hs.spotify.getVolume()..'% ♬')
end

function spotify.decreaseVolume()
  if not hs.spotify.isRunning() then return end
  hs.spotify.volumeDown()
  display(' ↓ '..hs.spotify.getVolume()..'% ♬')
end

function spotify.maxVolume()
  if not hs.spotify.isRunning() then return end
  hs.spotify.setVolume(100)
  display(' ↑ 100%')
end

function spotify.minVolume()
  if not hs.spotify.isRunning() then return end
  hs.spotify.setVolume(0)
  display(' ↓ 0%')
end

function spotify.playpause()
  if not hs.spotify.isRunning() then
    hs.application.launchOrFocus('Spotify')
    display(' ▶')
  else
    hs.spotify.playpause()
    icon = hs.spotify.isPlaying() and ' ▶' or ' ◼'
    display(icon)
  end
end

function spotify.display()
  if not hs.spotify.isRunning() then return end
  artist = hs.spotify.getCurrentArtist() or ''
  album  = hs.spotify.getCurrentAlbum() or ''
  track  = hs.spotify.getCurrentTrack() or ''
  current = hs.spotify.getPosition()
  total   = duration()
  percent = math.floor(current / total * 100 + 0.5)
  time   = formatSeconds(current)..'  ('..percent..'%)'..'\n'..formatSeconds(total)
  info   = track..'\n'..album..'\n'..artist..'\n'..time
  hs.alert.closeAll(0)
  hs.alert.show(info, 1.75)
end

return spotify
