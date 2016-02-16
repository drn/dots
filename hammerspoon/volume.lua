local volume = {}

local device = hs.audiodevice.defaultOutputDevice()

local function display()
  hs.alert.closeAll(0)
  hs.alert.show(device:volume()..'% ♬', 0.5)
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
