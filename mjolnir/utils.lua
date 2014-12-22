local utils = {}

function utils.osascript(command)
  return utils.capture("osascript -e '"..command.."'")
end

function utils.capture(command)
  local handle = io.popen(command)
  local result = handle:read("*a")
  handle:close()
  return string.gsub(result, "\n", "")
end

return utils
