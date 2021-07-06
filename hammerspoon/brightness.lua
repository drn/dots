local brightness = {
  primary = {},
  secondary = {}
}

local alert = require 'alert'

local function display(text, value)
  local icon = '🔅'
  if value > 100 then value = 100 end
  if value < 0 then value = 0 end
  if value > 50 then icon = '🔆' end
  alert.showOnly(text..(math.floor(value / 5) * 5)..'% '..icon, 0.5)
end

local function increase(screen, delta)
  current = screen:getBrightness()
  if not current then return end
  delta = (delta or 5) / 100.0
  local value = current + delta
  screen:setBrightness(value)
  display('↑ ', value * 100)
end

local function decrease(screen, delta)
  current = screen:getBrightness()
  if not current then return end
  delta = (delta or 5) / 100.0
  local value = current - delta
  screen:setBrightness(value)
  display('↓ ', value * 100)
end

function brightness.primary.increase(delta)
  local screen = hs.screen.primaryScreen()
  increase(screen, delta)
end

function brightness.primary.decrease(delta)
  local screen = hs.screen.primaryScreen()
  decrease(screen, delta)
end

function brightness.secondary.increase(delta)
  local screen = hs.screen.allScreens()[2]
  if not screen then return end
  increase(screen, delta)
end

function brightness.secondary.decrease(delta)
  local screen = hs.screen.allScreens()[2]
  if not screen then return end
  decrease(screen, delta)
end

return brightness
