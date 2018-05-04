local wifi = {}

local alert = require 'alert'

local command = '/usr/sbin/networksetup '

local function isOff()
  return hs.execute(command..'-getairportpower en0 | grep On') == ''
end

function wifi.off()
  os.execute(command..'-setairportpower en0 off')
  alert.show('Turning WiFi off...')
end

function wifi.on()
  os.execute(command..'-setairportpower en0 on')
  alert.show('Turning WiFi on...')
end

function wifi.toggle()
  if isOff() then
    wifi.on()
  else
    wifi.off()
  end
end

return wifi
