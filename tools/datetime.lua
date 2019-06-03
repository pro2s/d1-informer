local datetime = { _version = "0.1.0" }

datetime.every = nil
local s = 0
local m = 0
local h = 0
local time = nil -- Unix timestamp or somthing else

datetime.toString = function()
    return string.format("%02d:%02d:%02d", h, m, s)
end

function get_time() -- Sync with internet
    time = nil
    return(time)
end 

function wait_for_time()
    tmr.stop(2)
    if time == nil then 
       print("Waiting for time...")
    else
      tmr.stop(2)
      print("Time Set! "..time)
      h = tonumber(string.sub(time,1,2))
      m = tonumber(string.sub(time,4,5))
      s = tonumber(string.sub(time,7,8))
    end
end

tmr.alarm(0, 1000, 1, function() -- Every second increment clock and display
    s = s+1
    if s == 60 then
      s = 0
      m = m + 1
    end
    if m == 60 then
      m = 0
      h = h + 1
      time = get_time() -- sync time every hour
      tmr.alarm(2, 1000, 1, wait_for_time)
    end
    if h == 13 then
      h = 1
    end
    if datetime.every then
      datetime.every()
    end
 end)

 return datetime