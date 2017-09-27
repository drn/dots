local brightness = {}

local function display(text)
  hs.alert.closeAll(0)
  local icon = '🔅'
  if hs.brightness.get() > 50 then icon = '🔆' end
  hs.alert.show(text..(math.floor(hs.brightness.get() / 5) * 5)..'% '..icon, 0.5)
end

function brightness.increase(delta)
  delta = delta or 15
  hs.brightness.set(hs.brightness.get() + delta)
  display(' ↑ ')
end

function brightness.decrease(delta)
  delta = delta or 15
  hs.brightness.set(hs.brightness.get() - delta)
  display(' ↓ ')
end

return brightness
