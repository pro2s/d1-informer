-- Configuration
log.info("Info init")
local settings = {calibration = 0, ['update-wifi'] = 1.5, ['updarte-gsm'] = 60}

local api_url = config.API_URL
local headers_table = {'X-AIO-Key: ' .. config.API_KEY, 'Content-Type: application/json'}
local headers = table.concat(headers_table, '\r\n') .. '\r\n'

local sht30 = require("devices/sht30")
local photo = require("devices/photo")

local info_timer = tmr.create()

local function http_log(code, data)
  if (code < 0) then
    log.error("HTTP request failed")
  else
    log.info(code, data)
  end
end

local function calibrate(text)
  value = tonumber(text)
  value = value + settings.calibration
  return string.format("%.1f", value)
end

local function publish(dev, sensor_type, text)
  if sensor_type == 'temperature' then
    text = calibrate(text)
  end
  node.task.post(function()
    url = api_url .. '.' .. sensor_type .. '/data'
    http.post(url, headers, '{"value":"' .. text .. '"}', http_log)
  end)
end

local function log_message(text, success)
  if isWiFi then
    wifi_log_message(text, success)
  end
end

local function wifi_log_message(text, success)
  http.post(api_url .. '/data', headers,
  '{"value":"' .. text .. '"}',
  function(code, data)
    node.task.post(function() http_log(code, data) end)
    if (code == 200 and success ~= nil) then
      success()
    end
  end)
end

local function get_message(feed, success, always)
  http.get(api_url .. '.' .. feed .. '/data/last', headers,
  function(code, data)
    node.task.post(function() http_log(code, data) end)
    if (code == 200 and success ~= nil) then
      ok, result = pcall(sjson.decode, data)
      log.info('get', ok, result.value)
      if (ok and result.value ~= nil) then
        success(result.value)
      end
    end
    if (always ~= nil) then
      always()
    end
  end)
end

local function get_calibration(callback)
  get_message('calibration',
    function(value)
      settings.calibration = tonumber(value)
    end,
    callback
  )
end

local function get_update_channel(channel, callback)
  get_message('update-' .. channel,
    function(value)
      new_value = tonumber(value)
      if new_value ~= settings['update-' .. channel] then
        settings['update-' .. channel] = new_value
      end
    end,
    callback
  )
end

local function chain(callback, ...)
  if callback ~= nil then
    callback(function() chain(unpack(arg)); end)
  end
end

local function get_period(name)
  return settings['update-wifi'] * 60000
end

local function update_settings()
  chain(
    get_calibration,
    function(nxt) get_update_channel('gsm', nxt); end,
    function(nxt) get_update_channel('wifi', nxt); end,
    function() sht30.set_period(get_period('update-wifi')); end,
    function() photo.set_period(get_period('update-wifi')); end
  )
end

local function get_status(flag)
  if flag then
    return "on"
  else
    return "off"
  end
end

local function log_network()
  status = "wifi:" .. get_status(isWiFi) .. ":gsm:" .. get_status(isGSM)
  log_message(status, update_settings)
end

log_message("Start", log_network)

info_timer:register(60 * 60000, tmr.ALARM_AUTO, update_settings)
info_timer:start()

sht30.init('sht30', publish)
sht30.set_period(get_period('update-wifi'))

photo.init('light', publish)
photo.set_period(get_period('update-wifi'))
