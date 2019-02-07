local brightness = {}

local alert = require 'alert'

local function display(text, value)
  local icon = '🔅'
  if value > 100 then value = 100 end
  if value < 0 then value = 0 end
  if value > 50 then icon = '🔆' end
  alert.showOnly(text..(math.floor(value / 5) * 5)..'% '..icon, 0.5)
end

function brightness.increase(delta)
  delta = delta or 15
  local value = hs.brightness.get() + delta
  hs.brightness.set(value)
  display(' ↑ ', value)
end

function brightness.decrease(delta)
  delta = delta or 15
  local value = hs.brightness.get() - delta
  hs.brightness.set(value)
  display(' ↓ ', value)
end

return brightness
