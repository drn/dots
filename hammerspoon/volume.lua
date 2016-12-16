local volume = {}

local device = hs.audiodevice.defaultOutputDevice()

local function display(text)
  hs.alert.closeAll(0)
  hs.alert.show(text..math.floor(device:volume() + 0.5)..'% 🔊', 0.5)
end

function volume.increase()
  device:setVolume(device:volume() + 6)
  if device:muted() then
    device:setMuted(false)
  end
  display(' ↑ ')
end

function volume.decrease()
  device:setVolume(device:volume() - 6)
  if device:volume() == 0 then
    device:setMuted(true)
  end
  display(' ↓ ')
end

return volume
