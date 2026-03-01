-- If backgrounds start changing inconsistently (forward & background does not
-- result in the same picture showing up, this is likely due to the Desktop &
-- Screen Saver System Preferences being set to Apple > Desktop Pictures instead
-- of Folders > horizontal.

local background = {
  primary   = {},
  secondary = {}
}

local alert = require 'alert'
local as    = require 'hs.applescript'
local fs    = require 'hs.fs'

local function tell(cmd)
  local _cmd = 'tell application "System Events" to ' .. cmd
  local _ok, result = as.applescript(_cmd)
  return result
end

-- returns the filename of the current background image
local function backgroundPath(target)
  local path = tell('get picture of '..target..' desktop')
  if not path then return '' end
  return path:match("^.+/(.+)$")
end

local function backgroundFolder(target)
  local folder = 'horizontal'
  if target == 'second' then folder = 'vertical' end
  return '~/Pictures/'..folder..'/'
end

-- returns a table of filenames and the index of the current background
local function backgroundInfo(target)
  -- build files table
  local files = {}
  for file in fs.dir(backgroundFolder(target)) do
    if file ~= '.' and file ~= '..' and file ~= '.DS_Store' then
      files[#files + 1] = file
    end
  end
  -- sort files table
  table.sort(files, function(a,b) return a < b end)

  -- find index of current background
  local index = 1
  local path = backgroundPath(target)
  for idx, file in pairs(files) do
    if path == file then
      index = idx
    end
  end
  -- return files and index
  return files, index
end

local function setBackground(filename, target)
  tell(
    'set picture of '..target..' desktop to "' ..
    backgroundFolder(target) ..
    filename ..
    '"'
  )
end

local function forward(target)
  local files, index = backgroundInfo(target)
  -- iterate forward
  index = index + 1
  if index > #files then index = 1 end
  -- set background and alert
  setBackground(files[index], target)
  alert.showOnly(index)
end

local function backward(target)
  local files, index = backgroundInfo(target)
  -- iterate backward
  index = index - 1
  if index < 1 then index = #files end
  -- set background and alert
  setBackground(files[index], target)
  alert.showOnly(index)
end

function background.primary.forward()
  forward('current')
end

function background.primary.backward()
  backward('current')
end

function background.secondary.forward()
  forward('second')
end

function background.secondary.backward()
  backward('second')
end

return background
