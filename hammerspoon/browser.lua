local browser = {}

local as = require 'hs.applescript'
local alert = require 'alert'

local browsers = { ['Brave Browser'] = true, ['Safari'] = true }

local function app()
  local app = hs.application.frontmostApplication()
  if browsers[app:name()] then
    return app
  end
  return nil
end

function browser.openProfileMenu()
  local app = app()
  if app == nil then return end
  app:activate()
  -- focus on menubar if auto-hidden
  hs.eventtap.keyStroke({'fn', 'ctrl'}, 'f2')
  app:selectMenuItem({'Profiles'})
end

function browser.closeOtherTabs()
  local app = app()
  if app == nil then return end
  alert.show('Closing Other Tabs')
  local name = app:name()
  local _cmd
  if name == 'Safari' then
    _cmd = [[
      tell application "Safari"
        set currentTab to current tab of window 1
        set tabList to every tab of window 1
        repeat with thisTab in tabList
          if thisTab is not currentTab then
            close thisTab
          end if
        end repeat
      end tell
    ]]
  else
    _cmd = ([[
      tell application "]] .. name .. [["
        set tabList to every tab of window 1
        set activeTabIndex to active tab index of window 1
        set counter to 1
        repeat with thisTab in tabList
          if counter is not equal to activeTabIndex then
            close thisTab
          end if
          set counter to counter + 1
        end repeat
      end tell
    ]])
  end
  as.applescript(_cmd)
end

return browser
