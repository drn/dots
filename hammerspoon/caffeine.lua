local caffeine = {}

local sleepType = 'system'
local function alert(message) hs.alert.show(message, 1) end
local function isOn() return hs.caffeinate.get(sleepType) end

function caffeine.toggle()
  hs.caffeinate.set(sleepType, not isOn(), true)
  alert(isOn() and 'Caffeinating!' or 'Getting sleepy...')
end

function caffeine.display()
  alert(isOn() and 'Caffeinated' or 'Sleepy')
end

return caffeine
