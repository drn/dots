local volume = {}

local function display(text)
  hs.alert.closeAll(0)
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
  hs.alert.show(text..math.floor(device:volume() + 0.5)..'% '..icon, 0.5)
end

function volume.increase(delta)
  delta = delta or 6
  local device = hs.audiodevice.defaultOutputDevice()
  device:setVolume(device:volume() + delta)
  if device:muted() then
    device:setMuted(false)
  end
  display(' ↑ ')
end

function volume.decrease(delta)
  delta = delta or 6
  local device = hs.audiodevice.defaultOutputDevice()
  device:setVolume(device:volume() - delta)
  if device:volume() == 0 then
    device:setMuted(true)
  end
  display(' ↓ ')
end

return volume
