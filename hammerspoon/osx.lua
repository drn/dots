local osx = {}

function osx.lock()
  hs.alert.show("Locking System...")
  os.execute("sleep 0.5")
  os.execute("/System/Library/CoreServices/Menu\\ Extras/User.menu/Contents/Resources/CGSession -suspend")
end

return osx
