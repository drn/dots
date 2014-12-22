local itunes = {}

local utils = require "utils"

function itunes.playpause() run("playpause") end
function itunes.back() run("back track") end
function itunes.next() run("next track") end
function itunes.position(seconds) setposition(getposition() + seconds) end
function itunes.volume(percent) setvolume(getvolume() + percent) end
function itunes.notification()
  local info = getinfo()
  local title = info["name"]
  local message = info["artist"]
  if info["album"] ~= nil then message = message.." - "..info["album"] end
  print(os.execute(
    "/usr/local/bin/terminal-notifier"..
    " -title '"..title.."'"..
    " -message '"..message.."'"..
    " -appIcon $HOME/.mjolnir/itunes-cover"..
    " -sender com.apple.iTunes"..
    " -activate com.apple.iTunes"
  ))
end

function getvolume() return tonumber(tostring(run("sound volume"))) end
function setvolume(volume) run("set sound volume to "..volume) end
function getposition() return tonumber(tostring(run("player position"))) end
function setposition(position) run("set player position to "..position) end

function getinfo()
  local raw = run(
    '(get name of current track)'..' & "|" & '..
    '(get artist of current track)'..' & "|" & '..
    '(get album of current track)'
  )
  local info = {}
  for word in string.gmatch(raw, '([^|]+)') do table.insert(info, word) end
  return { name = info[1], artist = info[2], album = info[3] }
end

function artwork()
  os.execute("rm ~/.mjolnir/itunes-cover")
  os.execute(
    'osascript'..
    ' -e "tell application \"iTunes\" to set d to raw data of artwork 1 of current track"'..
    ' -e "set b to open for access file \"Users:darrencheng:.mjolnir:itunes-cover\" with write permission"'..
    ' -e "set eof b to 0"'..
    ' -e "write d to b"'..
    ' -e "close access b"'
  )
end

function run(command)
  return utils.osascript('tell app "iTunes" to '..command)
end

return itunes
