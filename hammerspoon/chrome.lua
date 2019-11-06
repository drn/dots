local chrome = {}

local as = require 'hs.applescript'
local alert = require 'alert'

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
      alert.show('Copied: '..url)
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

function chrome.refocus()
  local app = hs.application.applicationsForBundleID('com.google.Chrome')[1]
  if app ~= nil then
    tell('tell window 1 to set URL of active tab to "javascript:"')
  end
end

function chrome.closeOtherTabs()
  local app = hs.application.applicationsForBundleID('com.google.Chrome')[1]
  if app ~= nil then
    alert.show('Closing Other Tabs')
    local _cmd = ([[
      tell application "Google Chrome"
        set tabList to every tab of window 1
        set activeTabIndex to active tab index of window 1
        set counter to 1
        repeat with thisTab in tabList
          if not counter = activeTabIndex then
            close thisTab
          end if
          set counter to counter + 1
        end repeat
      end tell
    ]])
    as.applescript(_cmd)
  end
end

return chrome
