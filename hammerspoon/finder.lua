local finder = {}

local as = require 'hs.applescript'

local function tell(cmd)
  local _cmd = 'tell application "Finder" to ' .. cmd
  local _ok, result = as.applescript(_cmd)
  return result
end

function finder.refresh()
  if hs.window.focusedWindow():application():title() == 'Finder' then
    tell('tell front window to update every item')
    hs.alert('Refreshing Finder items...')
  end
end

return finder
