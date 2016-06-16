local osx = {}

local function sleep()
  os.execute("sleep 0.5")
end

function osx.screensaver()
  hs.alert.show("Starting screensaver...")
  sleep()
  os.execute("open /System/Library/Frameworks/ScreenSaver.framework/Versions/A/Resources/ScreenSaverEngine.app")
end

function osx.lock()
  hs.alert.show("Locking...")
  sleep()
  os.execute("/System/Library/CoreServices/Menu\\ Extras/User.menu/Contents/Resources/CGSession -suspend")
end

function osx.sleep()
  hs.alert.show("Sleeping...")
  sleep()
  os.execute("pmset sleepnow")
end

return osx
