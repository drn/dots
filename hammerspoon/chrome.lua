local chrome = {}

local as = require 'hs.applescript'

local function tell(cmd)
  local _cmd = 'tell application "Google Chrome" to ' .. cmd
  local _ok, result = as.applescript(_cmd)
  return result
end

function chrome.copyUrl()
  local app = hs.application.applicationsForBundleID('com.google.Chrome')[1]
  if app ~= nil then
    local url = tell('tell window 1 to URL of active tab')
    if url ~= 'chrome://newtab/' then
      hs.pasteboard.setContents(url)
    end
  end
end

function chrome.openProfileMenu()
  local app = hs.application.applicationsForBundleID('com.google.Chrome')[1]
  if app ~= nil then
    app:activate()
    app:selectMenuItem({'People'})
  end
end

return chrome
