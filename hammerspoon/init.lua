-- Open Hammerspoon Console

hs.hotkey.bind({"ctrl", "alt", "cmd"}, "o", function() hs.openConsole() end)

-- Auto-reload configuration

function reloadConfig(files) hs.reload() end
hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()
hs.alert.show("Hammerspoon Reloaded", 0.8)
