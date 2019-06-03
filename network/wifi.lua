log.info("WiFi Init")
isWiFi = false
wifi.setmode(wifi.STATION)
wifi.sta.config{ssid=config.WIFI_SSID, pwd=config.WIFI_PWD}
wifi.sta.connect()

local wifi_timer = tmr.create()
wifi_timer:register(1000, tmr.ALARM_AUTO, start_wifi)

local function start_wifi()
  if wifi.sta.getip() == nil then
    log.info("IP unavaiable, Waiting...")
    isWiFi = false
  else
    wifi_timer:unregister()
    log.info("ESP8266 mode is: " .. wifi.getmode())
    log.info("The module MAC address is: " .. wifi.ap.getmac())
    log.info("Config done, IP is " .. wifi.sta.getip())
    isWiFi = true
  end
end

wifi_timer:start()