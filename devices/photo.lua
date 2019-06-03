local Photo = {}
local dev, publish
local period = 0
local timer = tmr.create()

local function get_data()
    publish('photo', 'light', adc.read(0))
end 

local function register(p)
    if (p > 0) then
      if (p < 5000) then
        p = 5000
      end
      if (period > 0) then
        timer:interval(p)
      else
        timer:register(p, tmr.ALARM_AUTO, get_data)
        timer:start()
      end
      period = p
    else
      if (period > 0) then
        timer:unregister();
      end
      period = 0
    end
end

Photo.init = function(d, p)
    log.info('Photo Init')
    dev = d
    publish = p

    register(10000)
end

Photo.set_period = function(t)
    p = tonumber(t)
    if (p ~= nil) then
        register(p)
    end
end

return Photo