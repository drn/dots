local bluetooth = {}

local alert = require 'alert'

function bluetooth.hd1()
  local output = hs.execute("~/bin/hd1")
  alert.showOnly(output:gsub('%s*$', ''), 1, 20)
end

return bluetooth
