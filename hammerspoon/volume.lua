local volume = {}

local device = hs.audiodevice.defaultOutputDevice()

local function display()
  hs.alert.show(device:volume()..'% Volume')
end

function volume.increase()
  device:setVolume(device:volume() + 6)
  display()
end

function volume.decrease()
  device:setVolume(device:volume() - 6)
  display()
end

return volume
