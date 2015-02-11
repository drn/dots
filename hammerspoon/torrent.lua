local torrent = {}

local watcher = nil
local menuItem = nil
local downloadsPath = os.getenv('HOME')..'/Downloads/'
local autoEnqueuePath = os.getenv('HOME')..'/Downloads/torrents/movies/'
local handleType = 'off'

local function detectTorrents(files)
  local torrents = {}
  for _, file in pairs(files) do
    if file:match('%.torrent$') ~= nil then
      local filename = file:gsub(downloadsPath, '')
      if filename:match('/') == nil then
        if hs.fs.attributes(downloadsPath..filename) ~= nil then
          table.insert(torrents,filename)
        end
      end
    end
  end
  return torrents
end

local function formattedName(name)
  return string.sub(name,0,10)..'...'
end

local function tellFinder(command)
  hs.applescript.applescript('tell application "Finder" to '..command)
end

local function handleTorrent(tor)
  if handleType == 'open' then
    os.execute('open '..downloadsPath)
    tellFinder('reveal ("'..downloadsPath..tor..'" as POSIX file)')
    print('reveal ("'..downloadsPath..tor..'" as POSIX file)')
    hs.alert(formattedName(tor)..' detected')
  elseif handleType == 'auto' then
    os.execute('mv "'..downloadsPath..tor..'" "'..autoEnqueuePath..tor..'"')
    hs.alert(formattedName(tor)..' enqueued for download')
  end
end

local function iconPath()
  return os.getenv('HOME')..'/.hammerspoon/torrent-'..handleType..'.png'
end

local function isOpen() return handleType == 'open' end
local function isAuto() return handleType == 'auto' end
local function isOff() return handleType == 'off' end

local function setType(type)
  handleType = type
  menuItem:setIcon(iconPath())
  if isOpen() or isAuto() then
    watcher:start()
  elseif isOff() then
    watcher:stop()
  end
end

local cycle = hs.fnutils.cycle({
  function() setType('auto') end,
  function() setType('off') end
})

function torrent.watch()
  if watcher ~= nil then return end

  -- patch watcher
  watcher = hs.pathwatcher.new(downloadsPath, function(files)
    local torrents = detectTorrents(files)
    for _, tor in pairs(torrents) do
      handleTorrent(tor)
    end
  end)

  -- menubar icon
  menuItem = hs.menubar.new()
  menuItem:setIcon(os.getenv('HOME')..'/.hammerspoon/torrent-off.png')
  menuItem:setClickCallback(function() cycle()() end)
end

return torrent
