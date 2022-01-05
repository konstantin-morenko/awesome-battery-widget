-- Battery widget and notifications

local battery = {}

local wibox = require("wibox")
local awful = require("awful")
local gears = require("gears")
local naughty = require("naughty")

battery.widget = wibox.widget.textbox()
battery.widget:set_text("BATTERY")

function battery.set_battery(bat)
   battery.path = bat
end

function battery.set_ac(ac)
   battery.ac_path = ac
end

function battery.read_state()
   battery.perc = read_line(battery.path .. "/capacity")
   battery.status = read_line(battery.path .. "/status")
end

function read_line(filename)
   f = io.input(filename, "r")
   local t = f:read("*line")
   f:close()
   return t
end

local previous_state = ""

function battery.update()

   local batstat = ""

   if battery.path then
      battery.read_state()

      if previous_state ~= battery.status then
	 naughty.notify({ title = "Battery ",
			  text = battery.perc .. "% " .. battery.status,
			  timeout = timeout })
	 previous_state = battery.status
      end

      local status_short = "?"
      if battery.status == "Full" then
	 status_short = "F"
      elseif battery.status == "Discharging" then
	 status_short = "D"
      elseif battery.status == "Charging" then
	 status_short = "C"
      elseif battery.status == "Unknown" then
	 status_short = "U"
      else
	 status_short = " " .. battery.status
      end
      batstat = battery.perc .. status_short
   end

   battery.ac_online = read_line(battery.ac_path .. "/online")
   local ac_status_short = "?"
   if battery.ac_online == "1" then
      ac_status_short = "A/C"
   elseif battery.ac_online == "0" then
      ac_status_short = "BAT"
   else
      ac_status_short = "UNK"
   end
   
   battery.widget:set_text(ac_status_short .. " " .. batstat)
   battery.notify()
   return true
end

function battery.notify_n(timeout)
   -- naughty.notify({ title = "Battery " .. battery.perc .. "%",
   -- 		    timeout = timeout })
end   

function battery.notify()
   levels = {{90, "info"},
      {80, "info"},
      {70, "info"},
      {60, "info"},
      {50, "info"},
      {40, "info"},
      {30, "warning"},
      {20, "warning"},
      {10, "warning"}}
   for i in ipairs(levels) do
      local perc = levels[i][1]
      local lvl = levels[i][2]
      if tonumber(battery.perc) == perc then
	 if battery.last_notify == perc then
	 else
	    battery.last_notify = tonumber(battery.perc)
	    local timeout
	    if lvl == "warning" then
	       timeout = 0
	    else
	       timeout = 5
	    end
	    battery.notify_n(timeout)
	 end
      end
   end
end

function battery.start()
   battery.last_notify = 100

   battery.update()
   battery.notify_n(5)

   battery.timer = gears.timer {
      timeout   = 10,
      autostart = true,
      callback  = function()
	 battery.update()
      end
   }
end
   

return battery
