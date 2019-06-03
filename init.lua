log = require("tools/log")
log.usecolor = true
log.logger = function(str) print(str); end
log.info(uart.getconfig(0))

config = require("config")

dofile("network/wifi.lc")
dofile("network/gsm.lc")
dofile("info.lc")
