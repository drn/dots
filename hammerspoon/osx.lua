local osx = {}

local alert = require 'alert'

local function sleep()
  os.execute("sleep 0.5")
end

function osx.screensaver()
  alert.show("Starting screensaver...")
  sleep()
  os.execute("open /System/Library/CoreServices/ScreenSaverEngine.app")
end

function osx.lock()
  alert.show("Locking...")
  sleep()
  os.execute("/System/Library/CoreServices/Menu\\ Extras/User.menu/Contents/Resources/CGSession -suspend")
end

function osx.sleep()
  alert.show("Sleeping...")
  sleep()
  os.execute("pmset sleepnow")
end

return osx
