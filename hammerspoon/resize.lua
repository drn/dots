local resize = {}

local units = {
  -- Quadrants
  topleft     = { x=0,   y=0,   w=0.5, h=0.5 },
  topright    = { x=0.5, y=0,   w=0.5, h=0.5 },
  bottomleft  = { x=0,   y=0.5, w=0.5, h=0.5 },
  bottomright = { x=0.5, y=0.5, w=0.5, h=0.5 },
  -- Halves
  right       = { x=0.5, y=0,   w=0.5, h=1   },
  left        = { x=0,   y=0,   w=0.5, h=1   },
  top         = { x=0,   y=0,   w=1,   h=0.5 },
  bottom      = { x=0,   y=0.5, w=1,   h=0.5 },
  -- Fullscreen
  full        = { x=0,   y=0,   w=1,   h=1   }
}

for name,unit in pairs(units) do
  resize[name] = function() setUnit(unit) end
end

function resize.center()
  local win = hs.window.focusedWindow()
  if win == nil then return end
  local baseframe = win:screen():fullFrame()
  local f = win:frame()
  f.x = baseframe.x + ((baseframe.w / 2) - (f.w / 2))
  f.y = baseframe.y + ((baseframe.h / 2) - (f.h / 2))
  win:setFrame(f, 0)
end

function resize.changescreen()
  local win = hs.window.focusedWindow()
  if win == nil then return end
  current = win:screen()
  next = current:next()
  if current:id() == next:id() then return end
  win:setFrame(next:fullFrame(), 0)
end

function setUnit(unit)
  local win = hs.window.focusedWindow()
  if win == nil then return end
  if win:application():title() == 'iTerm' then return end

  local screenframe = win:screen():frame()
  local expected = frameForUnit(screenframe, unit)
  win:setFrame(expected, 0)
  local updated = win:frame()

  local justified = win:frame()

  if expected.w ~= updated.w then
    justified.x = expected.x + (expected.w - updated.w) / 2
  end
  if expected.h ~= updated.h then
    justified.y = expected.y + (expected.h - updated.h) / 2
    if justified.y + justified.h > screenframe.h then
      justified.y = screenframe.h + screenframe.y - justified.h
    end
  end

  if justified.x ~= updated.x or justified.h ~= updated.h then
    win:setFrame(justified, 0)
  end
end

function frameForUnit(baseframe, unit)
  return {
    x = baseframe.x + (unit.x * baseframe.w),
    y = baseframe.y + (unit.y * baseframe.h),
    w = unit.w * baseframe.w,
    h = unit.h * baseframe.h,
  }
end

return resize

