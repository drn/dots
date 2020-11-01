local bluetooth = {}

local alert = require 'alert'

function bluetooth.hd1Toggle()
  local output = hs.execute("~/bin/hd1 toggle")
  alert.showOnly(output:gsub('%s*$', ''), 1, 20)
end

function bluetooth.hd1Status()
  local output = hs.execute("~/bin/hd1 status")
  alert.showOnly(output:gsub('%s*$', ''), 1, 20)
end

return bluetooth
