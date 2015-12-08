local chrome = {}

local as = require 'hs.applescript'

local profiles = { 'Personal', 'Thanx' }

local function next(app)
  for i,profile in pairs(profiles) do
    local menuItem = app:findMenuItem({'People', profile})
    if menuItem['ticked'] then
      return profiles[i+1 > #profiles and 1 or i+1]
    end
  end
end

local function tell(cmd)
  local _cmd = 'tell application "Google Chrome" to ' .. cmd
  local _ok, result = as.applescript(_cmd)
  return result
end

function chrome.openProfileMenu()
  local app = hs.application.applicationsForBundleID('com.google.Chrome')[1]
  if app ~= nil then
    app:activate()
    app:selectMenuItem({'People'})
  end
end

function chrome.nextProfile()
  local app = hs.application.applicationsForBundleID('com.google.Chrome')[1]
  if app ~= nil then
    app:activate()
    app:selectMenuItem({'People', next(app)})
  end
end

function chrome.swapProfile()
  local app = hs.application.applicationsForBundleID('com.google.Chrome')[1]
  if app ~= nil then
    local url = tell('tell window 1 to URL of active tab')
    app:activate()
    app:selectMenuItem({'People', next(app)})
    app:selectMenuItem({'File', 'New Tab'})
    os.execute('sleep 0.5')
    if type(url) == 'string' and not url:match('chrome://') then
      tell('tell window 1 to set URL of active tab to "'..url..'"')
    end
  end
end

return chrome
