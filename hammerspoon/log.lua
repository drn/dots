local log = {}

local logger = hs.logger.new('log', 'debug')

function log.debug(info)
  logger.d(hs.inspect(info))
end

return log
