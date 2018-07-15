local music = {}

local app = require "hs.application"

local itunes = require 'itunes'
local spotify = require 'spotify'

local function provider()
  if app.get('Spotify') ~= nil then
    return spotify
  end
  if app.get('iTunes') ~= nil then
    return itunes
  end
  return nil
end

local function call(method, option)
  local provider = provider()
  if provider ~= nil then provider[method](option) end
end

local bindings = {
  'next',
  'previous',
  'forward',
  'backward',
  'increaseVolume',
  'decreaseVolume',
  'maxVolume',
  'minVolume',
  'display',
  'open'
}
for i=1, #bindings do
  music[bindings[i]] = function(option)
    call(bindings[i], option)
  end
end

function music.playpause()
  local provider = provider()
  if provider == nil then provider = spotify end
  provider.playpause()
end

return music
