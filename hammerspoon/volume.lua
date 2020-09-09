local volume = {}

local alert = require 'alert'

local function display(text)
  alert.close()
  local device = hs.audiodevice.defaultOutputDevice()
  local icon = '🔈'
  if device:volume() > 30 then
    icon = '🔉'
  end
  if device:volume() > 60 then
    icon = '🔊'
  end
  if device:muted() then
    icon = '🔇'
  end
  alert.show(text..' '..math.floor(device:volume() + 0.5)..'% '..icon)
  local name = device:name()
  if name ~= "Built-in Output" then
    alert.show(name, 0.5, 12)
  end
end

local function normalizeBalance()
  local device = hs.audiodevice.defaultOutputDevice()
  device:setBalance(0.5)
end

function volume.increase(delta)
  normalizeBalance()
  delta = delta or 6
  local device = hs.audiodevice.defaultOutputDevice()
  device:setVolume(device:volume() + delta)
  if device:muted() then
    device:setMuted(false)
  end
  display('↑')
end

function volume.decrease(delta)
  normalizeBalance()
  delta = delta or 6
  local device = hs.audiodevice.defaultOutputDevice()
  device:setVolume(device:volume() - delta)
  if device:volume() == 0 then
    device:setMuted(true)
  end
  display('↓')
end

return volume
