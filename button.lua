local success_timer = tmr.create()
local button_pin = 3
local count = 0

local function accept_request()
    gpio.write(7, gpio.HIGH)
    success_timer:register(1000, tmr.ALARM_SINGLE, function (t) gpio.write(7, gpio.LOW); t:unregister() end)
    success_timer:start()
end
  
local function pin1cb(level)
    if (level == gpio.HIGH) then
      count = count + 1
      log.info("Pressed ".. count)
      log_message('Press Button on D6', function () node.task.post(accept_request) end)
    end
    gpio.trig(pin, level == gpio.HIGH and "down" or "up")
end
  
local function debounce(func)
    local last = 0
    -- 50ms * 1000 as tmr.now() has μs resolution
    local delay = 50000 
  
    return function (...)
        local now = tmr.now()
        local delta = now - last
        -- proposed because of delta rolling over, https://github.com/hackhitchin/esp8266-co-uk/issues/2
        if delta < 0 then delta = delta + 2147483647 end; 
        if delta < delay then return end;
  
        last = now
        return func(...)
    end
end

local pin = 6
local led = 6

gpio.mode(led, gpio.OUTPUT)
gpio.write(led, gpio.LOW)

gpio.mode(pin, gpio.INT, gpio.PULLUP)
gpio.trig(pin, "down", debounce(pin1cb))

