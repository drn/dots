local lib = {}

function lib.formatSeconds(seconds)
  local minutes = math.floor(seconds / 60)
  local hours = math.floor(minutes / 60)
  local formatted = math.floor(seconds % 60)..'s'
  if minutes > 0 then formatted = (minutes % 60)..'m '..formatted end
  if hours > 0 then formatted = hours..'h '..formatted end
  return formatted
end

function lib.frameForUnit(baseframe, unit)
  return {
    x = baseframe.x + (unit.x * baseframe.w),
    y = baseframe.y + (unit.y * baseframe.h),
    w = unit.w * baseframe.w,
    h = unit.h * baseframe.h,
  }
end

return lib
