local brightness = {}

local function display(text)
  hs.alert.closeAll(0)
  local icon = '🔅'
  if hs.brightness.get() > 50 then icon = '🔆' end
  hs.alert.show(text..math.floor(hs.brightness.get() + 0.5)..'% '..icon, 0.5)
end

function brightness.increase()
  hs.brightness.set(hs.brightness.get() + 15)
  display(' ↑ ')
end

function brightness.decrease()
  hs.brightness.set(hs.brightness.get() - 15)
  display(' ↓ ')
end

return brightness
