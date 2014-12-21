local hotkey = require "mjolnir.hotkey"
local window = require "mjolnir.window"
local screen = require "mjolnir.screen"
local application = require "mjolnir.application"

-- Window Management

function resize(coordinates)
  local win = window.focusedwindow()
  if win ~= nil then
    win:movetounit(coordinates)
  end
end

local bindings = {
  -- Quadrants
  p          = { x=0,   y=0,   w=0.5, h=0.5 },
  ["\\"]     = { x=0.5, y=0,   w=0.5, h=0.5 },
  ["["]      = { x=0,   y=0.5, w=0.5, h=0.5 },
  ["]"]      = { x=0.5, y=0.5, w=0.5, h=0.5 },
  -- Halves
  right      = { x=0.5, y=0,   w=0.5, h=1   },
  left       = { x=0,   y=0,   w=0.5, h=1   },
  up         = { x=0,   y=0,   w=1,   h=0.5 },
  down       = { x=0,   y=0.5, w=1,   h=0.5 },
  -- Fullscreen
  ["return"] = { x=0,   y=0,   w=1,   h=1   }
}
for key,coordinates in pairs(bindings) do
  hotkey.bind({"ctrl", "alt", "cmd"}, key, function()
    resize(coordinates)
  end)
end

---- Center

hotkey.bind({"ctrl", "alt", "cmd"}, "'", function()
  local win = window.focusedwindow()
  if win == nil then return end
  local screenrect = win:screen():fullframe()
  local f = win:frame()
  f.x = screenrect.x + ((screenrect.w / 2) - (f.w / 2))
  f.y = screenrect.y + ((screenrect.h / 2) - (f.h / 2))
  win:setframe(f)
end)

---- Screen

hotkey.bind({"ctrl", "alt", "cmd", "shift"}, "return", function()
  local win = window.focusedwindow()
  if win == nil then return end
  current = win:screen()
  next = current:next()
  if current:id() ~= next:id() then
    win:setframe(next:fullframe())
  end
end)

-- Application
local bindings = {
  [{ "cmd", "alt", "shift"}] = {
    iTerm      = "i",
    Safari     = "return",
    Messages   = "n",
    HipChat    = "m",
    Wunderlist = "'",
    MacVim     = "."
  },
  [{ "cmd", "shift"}] = {
    [ "Mailplane 3" ] = "/",
  },
  [{ "cmd", "alt"}] = {
    [ "Google Chrome" ] = "return"
  }
}
for modifiers,apps in pairs(bindings) do
  for name, key in pairs(apps) do
    hotkey.bind(modifiers, key, function()
      application.launchorfocus(name)
    end)
  end
end

-- Mjolnir

hotkey.bind({"ctrl", "alt", "cmd"}, "r", function()
  mjolnir.reload()
end)
hotkey.bind({"ctrl", "alt", "cmd"}, "o", function()
  mjolnir.openconsole()
end)

-- iTunes

hotkey.bind({ "cmd", "alt", "shift"}, "a", function()
  itunesdisplay()
end)
hotkey.bind({ "ctrl" }, "space", function()
  itunes("playpause")
end)
hotkey.bind({ "cmd", "alt" }, "left", function()
  itunes("back track")
end)
hotkey.bind({ "cmd", "alt" }, "right", function()
  itunes("next track")
end)
hotkey.bind({ "ctrl", "cmd" }, "right", function()
  local position = itunes("player position")
  itunes("set player position to "..(tonumber(position) + 10))
end)
hotkey.bind({ "ctrl", "cmd" }, "left", function()
  local position = itunes("player position")
  itunes("set player position to "..(tonumber(position) - 10))
end)
hotkey.bind({ "ctrl", "cmd" }, "up", function()
  local volume = itunes("sound volume")
  itunes("set sound volume to "..(tonumber(volume) + 5))
end)
hotkey.bind({ "ctrl", "cmd" }, "down", function()
  local volume = itunes("sound volume")
  itunes("set sound volume to "..(tonumber(volume) - 5))
end)

function itunesdisplay()
  local info = itunesinfo()
  local title = info["name"]
  local message = info["artist"]
  if info["album"] ~= nil then message = message.." - "..info["album"] end
  os.execute(
    "/usr/local/bin/terminal-notifier"..
    " -title '"..title.."'"..
    " -message '"..message.."'"..
    " -appIcon $HOME/.mjolnir/itunes-cover"..
    " -sender com.apple.iTunes"..
    " -activate com.apple.iTunes"
  )
end

function itunesinfo()
  local rawinfo = itunes(
    '(get name of current track)'..' & "|" & '..
    '(get artist of current track)'..' & "|" & '..
    '(get album of current track)'
  )
  info = {}
  for word in string.gmatch(rawinfo, '([^|]+)') do table.insert(info, word) end
  return { name = info[1], artist = info[2], album = info[3] }
end

function itunesartwork()
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

function itunes(command)
  return osascript("tell app \"iTunes\" to "..command)
end

function osascript(command)
  local handle = io.popen("osascript -e '"..command.."'")
  local result = handle:read("*a")
  handle:close()
  return string.gsub(result, "\n", "")
end
