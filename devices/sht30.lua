-- LGPL v3 License (Free Software Foundation)
-- Copyright (C) 2017 - 2018 ScalAgent Distributed Technologies

-- Get temperature and humidity from SHT30 field

local SHT = {}

local dev, publish

-- SHT shield and I2C parameters
local id  = 0
local sda = 2 -- pin D2
local scl = 1 -- pin D1
local dev_addr = 0x45 -- SHT30

local delay=14 -- 13500us

local function get_data2()
  local data, temp, humi, msg
  
  -- get data
  i2c.start(id)
  i2c.address(id, dev_addr, i2c.RECEIVER)
  data = i2c.read(id, 6) -- read 6 bytes
  i2c.stop(id)
  
  is_integer = 10
  if tonumber('1.1') ~= nil then
    is_integer = 1
  end
  
  -- calculate temperature and humidity (2 data bytes + 1 checksum byte)
  temp = ((((data:byte(1) * 256) + data:byte(2)) * 175 * is_integer) / 65535) - (45 * is_integer)
  humi = ((((data:byte(4) * 256) + data:byte(5)) * 100 * is_integer) / 65535)
  
  
  if is_integer == 10 then 
    temp=""..(temp/10).."."..(temp%10)
    humi=""..(humi/10).."."..(humi%10)
  else 
    temp = string.format("%.1f", temp)
    humi = string.format("%.1f", humi)
  end

  log.info("temperature=" .. temp .. ", humidity=" .. humi)
  
  -- send message
  publish(dev, "temperature", temp)
  publish(dev, "humidity", humi)
end

local function get_data()
  -- send command
  i2c.start(id)
  ack = i2c.address(id, dev_addr, i2c.TRANSMITTER)
  i2c.write(id, 0x2C, 0x06) -- HIGH Repeatability, Clock stretching ENABLED
  i2c.stop(id)

  tmr.create():alarm(delay, tmr.ALARM_SINGLE, get_data2)
end

-- If period set to 0 data shall be get explicitly, otherwise the device
-- send data automatically. Set by default to 10s in init_sht.
local period=0
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

local function set_period(m)
  p = tonumber(m)
  if (p ~= nil) then
    register(p)
  end
end

-- Initialization function
local function init_sht(d, p)
  log.info('Sht30 Init')
  dev = d
  publish = p
  -- Add the initialization of the SHT shield
  i2c.setup(id, sda, scl, i2c.SLOW)
  register(10000)
end

local actions = {
  ["get_data"] = get_data,
  ["set_period"] = set_period
}

SHT.init = init_sht
SHT.actions = actions
-- These methods are only needed for external use of the SHT module
SHT.get_data = get_data
SHT.set_period = set_period

return SHT
