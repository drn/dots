local screen = {}

local watcher = nil

function screen.watch()
  if watcher ~= nil then return end
  watcher = hs.screen.watcher.new(function()
    hs.alert.show('window changed!')
  end)
  watcher:start()
end

return screen
