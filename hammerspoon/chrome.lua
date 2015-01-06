local chrome = {}

local profiles = { 'Personal', 'Thanx' }

local function inspect(app)
  for _,profile in pairs(profiles) do
    print(profile, hs.inspect.inspect(app:findMenuItem({'People', profile})))
  end
end

local function next(app)
  for i,profile in pairs(profiles) do
    local menuItem = app:findMenuItem({'People', profile})
    if menuItem['ticked'] then
      return profiles[i+1 > #profiles and 1 or i+1]
    end
  end
end

function chrome.nextProfile()
  local app = hs.application.applicationsForBundleID('com.google.Chrome')[1]
  if app ~= nil then
    app:activate()
    app:selectMenuItem({'People', next(app)})
  end
end

return chrome
