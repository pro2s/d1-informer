local Device = {}
local dev, publish, get_data
local period = 0
local timer = tmr.create()

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

Device.init = function(d, p)
    log.info(Device.name .. ' Init')
    dev = d
    publish = p

    register(10000)
end

Device.set_period = function(t)
    p = tonumber(t)
    if (p ~= nil) then
        register(p)
    end
end

return Device