local wifi = {}

local command = '/usr/sbin/networksetup '

local function isOff()
  return hs.execute(command..'-getairportpower en0 | grep On') == ''
end

function wifi.off()
  os.execute(command..'-setairportpower en0 off')
  hs.alert.show('Turning WiFi off...', 0.5)
end

function wifi.on()
  os.execute(command..'-setairportpower en0 on')
  hs.alert.show('Turning WiFi on...', 0.5)
end

function wifi.toggle()
  if isOff() then
    wifi.on()
  else
    wifi.off()
  end
end

return wifi
