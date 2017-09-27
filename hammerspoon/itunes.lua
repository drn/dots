local itunes = {}

local as = require 'hs.applescript'

local function tell(cmd)
  local _cmd = 'tell application "iTunes" to ' .. cmd
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
  return currentPosition ~= nil and currentPosition or 0
end

local function display(message)
  hs.alert.closeAll(0)
  hs.alert.show(message, 0.5)
end

function itunes.next()
  if not hs.itunes.isRunning() then return end
  hs.itunes.next()
  display(' ⇥')
end

function itunes.previous()
  if not hs.itunes.isRunning() then return end
  tell('back track')
  display(' ⇤')
end

function itunes.forward(delta)
  if not hs.itunes.isRunning() then return end
  delta = delta or 10
  local updated = hs.itunes.getPosition() + delta
  hs.itunes.setPosition(updated)
  message = (hs.itunes.getPosition() < math.floor(updated)) and ' ⇥' or ' → '..formatSeconds(updated)
  display(message)
end

function itunes.backward(delta)
  if not hs.itunes.isRunning() then return end
  local position = hs.itunes.getPosition()
  if position < 0.5 then
    itunes.previous()
    return
  end
  delta = delta or 10
  local updated = position - delta
  if updated < 0 then updated = 0 end
  hs.itunes.setPosition(updated)
  display(' ← '..formatSeconds(updated))
end

function itunes.increaseVolume()
  if not hs.itunes.isRunning() then return end
  hs.itunes.volumeUp()
  display(' ↑ '..hs.itunes.getVolume()..'% ♬')
end

function itunes.decreaseVolume()
  if not hs.itunes.isRunning() then return end
  hs.itunes.volumeDown()
  display(' ↓ '..hs.itunes.getVolume()..'% ♬')
end

function itunes.maxVolume()
  if not hs.itunes.isRunning() then return end
  hs.itunes.setVolume(100)
  display(' ↑ 100%')
end

function itunes.minVolume()
  if not hs.itunes.isRunning() then return end
  hs.itunes.setVolume(0)
  display(' ↓ 0%')
end

function itunes.playpause()
  hs.itunes.playpause()
  icon = hs.itunes.isPlaying() and ' ▶' or ' ◼'
  display(icon)
end

function itunes.display()
  if not hs.itunes.isRunning() then return end
  artist = hs.itunes.getCurrentArtist() or ''
  album  = hs.itunes.getCurrentAlbum() or ''
  track  = hs.itunes.getCurrentTrack() or ''
  current = hs.itunes.getPosition()
  total   = duration()
  percent = math.floor(current / total * 100 + 0.5)
  time   = formatSeconds(current)..'  ('..percent..'%)'..'\n'..formatSeconds(total)
  info   = track..'\n'..album..'\n'..artist..'\n'..time
  hs.alert.closeAll(0)
  hs.alert.show(info, 1.75)
end

function itunes.open()
  hs.application.launchOrFocus('iTunes')
end

function itunes.addToPlaylist(playlist)
  if not hs.itunes.isRunning() then return end
  script = [[
    tell application "iTunes"
      set trackId to (persistent ID of current track)
      set result to (tracks of playlist "]]..playlist..[[" whose persistent ID is trackId)
      if result is {} then
        duplicate current track to playlist "]]..playlist..'"\n'..[[
        "true"
      else
        "false"
      end if
    end tell
  ]]
  local _ok, result = as.applescript(script)
  if result == 'true' then
    track = tell('name of the current track as string') or ''
    hs.alert.show(track..' → '..playlist)
  else
    hs.alert.show('✓', 0.3)
  end
end

return itunes
