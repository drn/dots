local notifier = {}

function notifier.notify(options)
  command = { "/usr/local/bin/terminal-notifier" }

  title    = format(options["title"])
  message  = format(options["message"])
  icon     = format(options["icon"])
  bundleid = format(options["bundleid"])

  if title ~= nil then table.insert(command, "-title "..title) end
  if message ~= nil then table.insert(command, "-message "..message) end
  if icon ~= nil then table.insert(command, "-icon "..icon) end
  if bundleid ~= nil then
    table.insert(command, "-sender "..bundleid)
    table.insert(command, "-activate "..bundleid)
  end
  print(table.concat(command, " "))
  os.execute(table.concat(command, " "))
end

function format(input)
  if input == nil then return nil end
  return '"'..string.gsub(input, '"', '\\"')..'"'
end

return notifier
