local background = {}

local alert = require 'alert'
local as    = require 'hs.applescript'
local fs    = require 'hs.fs'

local function tell(cmd)
  local _cmd = 'tell application "Finder" to ' .. cmd
  local _ok, result = as.applescript(_cmd)
  return result
end

-- returns the filename of the current background image
local function currentBackground()
  local path = tell('get posix path of (get desktop picture as alias)')
  if not path then return '' end
  return path:match("^.+/(.+)$")
end

-- returns a table of filenames and the index of the current background
local function backgroundInfo()
  -- build files table
  local files = {}
  for file in fs.dir("~/Pictures/backgrounds") do
    if file ~= '.' and file ~= '..' and file ~= '.DS_Store' then
      files[#files + 1] = file
    end
  end
  -- sort files table
  table.sort(files, function(a,b) return a < b end)
  -- find index of current background
  local index = 1
  local current = currentBackground()
  for idx, file in pairs(files) do
    if current == file then
      index = idx
    end
  end
  -- return files and index
  return files, index
end

local function setBackground(filename)
  tell(
    'set desktop picture to posix file "' ..
    os.getenv('HOME') ..
    '/Pictures/backgrounds/' ..
    filename ..
    '"'
  )
end

function background.forward()
  local files, index = backgroundInfo()
  -- iterate forward
  index = index + 1
  if index > #files then index = 1 end
  -- set background and alert
  setBackground(files[index])
  alert.showOnly(index)
end

function background.backward()
  local files, index = backgroundInfo()
  -- iterate backward
  index = index - 1
  if index < 1 then index = #files end
  -- set background and alert
  setBackground(files[index])
  alert.showOnly(index)
end

return background
