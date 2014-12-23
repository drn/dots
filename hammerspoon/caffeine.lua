local caffeine = {}

local sleepType = 'system'
local menuItem = nil

local function alert(message) hs.alert.show(message, 1) end
local function isOn() return hs.caffeinate.get(sleepType) end
local function createMenuItem()
  if menuItem ~= nil then return end
  menuItem = hs.menubar.new()
  menuItem:setIcon(os.getenv('HOME')..'/.hammerspoon/caffeine.png')
  menuItem:setClickCallback(function() caffeine.toggle() end)
end
local function deleteMenuItem()
  if menuItem == nil then return end
  menuItem:delete()
  menuItem = nil
end
local function toggleMenu()
  if isOn() then createMenuItem() else deleteMenuItem() end
end

function caffeine.toggle()
  hs.caffeinate.set(sleepType, not isOn(), true)
  alert(isOn() and 'Caffeinating!' or 'Getting sleepy...')
  toggleMenu()
end

function caffeine.display()
  alert(isOn() and 'Caffeinated' or 'Sleepy')
end

return caffeine
