local alert = {}

function alert.showOnly(text, duration, size)
  alert.close()
  alert.show(text, duration, size)
end

function alert.close()
  hs.alert.closeAll(0)
end

function alert.show(text, duration, size)
  duration = duration or 0.5
  size = size or 24
  local radius = size - 4

  hs.alert.show(
    text,
    {
      textSize = size,
      radius   = radius
    },
    hs.screen.mainScreen(),
    duration
  )
end

return alert
