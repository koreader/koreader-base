--[[--
Module for interfacing with the RTC (real time clock).

This module provides the ability to schedule wakeups through RTC.

See <http://man7.org/linux/man-pages/man4/rtc.4.html> for technical details.

@module ffi.rtc
]]

local ffi = require("ffi")
local bor = bit.bor
local C = ffi.C

-- Load header definitions for functions and constants to the ffi.C namespace.
local dummy = require("ffi/posix_h")
local dummy = require("ffi/rtc_h")

-----------------------------------------------------------------

local RTC = {
    _wakeup_scheduled = false,   -- Flipped in @{setWakeupAlarm} and @{unsetWakeupAlarm}.
    _wakeup_scheduled_ptm = nil, -- Stores a reference to the time of the last scheduled wakeup alarm.
}

--[[--
Adds seconds to epoch.

@int seconds_from_now Number of seconds.
@treturn int (cdata) Epoch.
--]]
function RTC:secondsFromNowToEpoch(seconds_from_now)
    local t = ffi.new("time_t[1]")
    t[0] = C.time(nil)
    t[0] = t[0] + seconds_from_now
    local epoch = C.mktime(C.localtime(t))
    return epoch
end

--[[--
Set wakeup alarm.

If you want to set the alarm to a certain amount of time from now,
you can process your value with @{secondsFromNowToEpoch}.

@int Epoch.
@enabled bool Whether the call enables or disables the alarm. Defaults to true.

@treturn bool Success.
@treturn re Error code (if any).
@treturn err Error string (if any).
--]]
function RTC:setWakeupAlarm(epoch, enabled)
    enabled = (enabled ~= nil) and enabled or true

    local ptm = C.gmtime(ffi.new("int[1]", epoch))
    self._wakeup_scheduled_ptm = ptm

    local wake = ffi.new("struct rtc_wkalrm")
    wake.time.tm_sec = ptm.tm_sec
    wake.time.tm_min = ptm.tm_min
    wake.time.tm_hour = ptm.tm_hour
    wake.time.tm_mday = ptm.tm_mday
    wake.time.tm_mon = ptm.tm_mon
    wake.time.tm_year = ptm.tm_year
    -- wday, yday, and isdst fields are unused by Linux
    wake.time.tm_wday = -1
    wake.time.tm_yday = -1
    wake.time.tm_isdst = -1

    wake.enabled = enabled and 1 or 0

    local err
    local rtc0 = C.open("/dev/rtc0", bor(C.O_RDONLY, C.O_NONBLOCK))
    if rtc0 == -1 then
        err = ffi.string(C.strerror(ffi.errno()))
        print("setWakeupAlarm open /dev/rtc0", rtc0, err)
        return nil, rtc0, err
    end
    local re = C.ioctl(rtc0, C.RTC_WKALM_SET, wake)
    if re == -1 then
        err = ffi.string(C.strerror(ffi.errno()))
        print("setWakeupAlarm ioctl RTC_WKALM_SET", re, err)
        return nil, re, err
    end
    re = C.close(rtc0)
    if re == -1 then
        err = ffi.string(C.strerror(ffi.errno()))
        print("setWakeupAlarm close /dev/rtc0", re, err)
        return nil, re, err
    end

    if enabled then
        self._wakeup_scheduled = true
    else
        self._wakeup_scheduled = false
        self._wakeup_scheduled_ptm = nil
    end
    return true
end

--[[--
Unset wakeup alarm.
--]]
function RTC:unsetWakeupAlarm()
    self:setWakeupAlarm(-1, false)
    self._wakeup_scheduled = false
    self._wakeup_scheduled_ptm = nil
end

--[[--
Get a copy of the wakealarm we set (if any).

This value is compared with @{getWakeupAlarmSys} in @{validateWakeupAlarmByProximity}.

@treturn tm (time struct)
--]]
function RTC:getWakeupAlarm()
    return self._wakeup_scheduled_ptm
end

--[[--
Get RTC wakealarm from system.

@treturn tm (time struct)
--]]
function RTC:getWakeupAlarmSys()
    local wake = ffi.new("struct rtc_wkalrm")

    local err, re
    local rtc0 = C.open("/dev/rtc0", C.O_RDONLY)
    if rtc0 == -1 then
        err = ffi.string(C.strerror(ffi.errno()))
        print("getWakeupAlarm open /dev/rtc0", rtc0, err)
        return nil, rtc0, err
    end
    re = C.ioctl(rtc0, C.RTC_WKALM_RD, wake)
    if re == -1 then
        err = ffi.string(C.strerror(ffi.errno()))
        print("getWakeupAlarm ioctl RTC_WKALM_RD", re, err)
        return nil, re, err
    end
    re = C.close(rtc0)
    if re == -1 then
        err = ffi.string(C.strerror(ffi.errno()))
        print("getWakeupAlarm close /dev/rtc0", re, err)
        return nil, re, err
    end

    if wake ~= -1 then
        local t = ffi.new("time_t[1]")
        t[0] = C.time(nil)
        local tm = ffi.new("struct tm") -- luacheck: ignore
        tm = C.gmtime(t)
        tm.tm_sec = wake.time.tm_sec
        tm.tm_min = wake.time.tm_min
        tm.tm_hour = wake.time.tm_hour
        tm.tm_mday = wake.time.tm_mday
        tm.tm_mon = wake.time.tm_mon
        tm.tm_year = wake.time.tm_year
        return tm
    end
end

--[[--
Checks if the alarm we set matches the system alarm as well as the current time.
--]]
function RTC:validateWakeupAlarmByProximity(task_alarm_epoch, proximity)
    -- In principle alarm time and current time should match within a second,
    -- but let's be absurdly generous and assume anything within 30 is a match.
    proximity = proximity or 30

    local alarm = self:getWakeupAlarm()
    local alarm_epoch
    local alarm_sys = self:getWakeupAlarmSys()
    local alarm_sys_epoch

    -- this seems a bit roundabout
    local current_time = ffi.new("time_t[1]")
    current_time[0] = C.time(nil)
    local current_time_epoch = C.mktime(C.gmtime(current_time))

    if not (alarm and alarm_sys) then return end

    alarm_epoch = C.mktime(alarm)
    alarm_sys_epoch = C.mktime(alarm_sys)

    print("validateWakeupAlarmByProximity", task_alarm_epoch, alarm_epoch, alarm_sys_epoch, current_time_epoch)

    -- If our stored alarm and the system alarm don't match, we didn't set it.
    if not (alarm_epoch == alarm_sys_epoch) then return end

    -- If our stored alarm and the provided task alarm don't match,
    -- we're not talking about the same task. This should never happen.
    if task_alarm_epoch and not (alarm_epoch == task_alarm_epoch) then return end

    local diff = current_time_epoch - alarm_epoch
    if diff >= 0 and diff < proximity then return true end
end

--[[--
Checks if we scheduled a wakeup alarm.

@treturn bool
--]]
function RTC:isWakeupAlarmScheduled()
    return self._wakeup_scheduled
end

return RTC
