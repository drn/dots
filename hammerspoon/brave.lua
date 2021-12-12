local brave = {}

local as = require 'hs.applescript'
local alert = require 'alert'
local bundleID = "com.brave.Browser"
local appName = "Brave Browser"

local function tell(cmd)
  local _cmd = 'tell application "' .. appName .. '" to ' .. cmd
  local _ok, result = as.applescript(_cmd)
  return result
end

function brave.openProfileMenu()
  local app = hs.application.applicationsForBundleID(bundleID)[1]
  if app ~= nil then
    app:activate()
    -- focus on menubar if auto-hidden
    hs.eventtap.keyStroke({'fn', 'ctrl'}, 'f2')
    app:selectMenuItem({'Profiles'})
  end
end

function brave.refocus()
  local app = hs.application.applicationsForBundleID(bundleID)[1]
  if app ~= nil then
    tell('tell window 1 to set URL of active tab to "javascript:"')
  end
end

function brave.closeOtherTabs()
  local app = hs.application.applicationsForBundleID(bundleID)[1]
  if app ~= nil then
    alert.show('Closing Other Tabs')
    local _cmd = ([[
      tell application "]] .. appName .. [["
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

return brave
