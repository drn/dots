local screen = {}

local watcher = nil
local lastCount = nil

local function screenCount() return #hs.screen:allScreens() end

local function handleCountChange(count)
  if count == 1 then
    -- TODO
  elseif count == 2 then
    -- TODO
      -- if open, move Mailplane to next screen, bottom
      -- if open, move iTerm vertical window to next screen, full screen
      -- if open, move Messages to next screen, bottom
  end
end

function screen.watch()
  if watcher ~= nil then return end
  lastCount = screenCount()
  watcher = hs.screen.watcher.new(function()
    local updatedCount = screenCount()
    if lastCount ~= updatedCount then
      hs.alert.show('Screen count changed from '..lastCount..' -> '..updatedCount)
      lastCount = updatedCount
    end
  end)
  watcher:start()
end

return screen
