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
Enable/Disable the alarm interrupt.
The use of RTC_WKALM_SET allows us to bypass the need for RTC_AIE_* calls,
thanks to the enabled field in the rtc_wkalrm struct.
Busybox rtcwake still does an RTC_AIE_OFF when resuming from an alarm wakeup,
as does Nickel when powering off.
In this scenario, the modern util-linux rtcwake, which never uses legacy RTC_ALM_SET calls,
instead uses RTC_WKALM_SET filled from RTC_WKALM_RD but with enabled set to 0.

@enabled bool Whether the call enables or disables the alarm interrupt. Defaults to true.

@treturn bool Success.
@treturn re Error code (if any).
@treturn err Error string (if any).
--]]
function RTC:toggleAlarmInterrupt(enabled)
    enabled = (enabled ~= nil) and enabled or true

    local err
    local rtc0 = C.open("/dev/rtc0", bor(C.O_RDONLY, C.O_NONBLOCK, C.O_CLOEXEC))
    if rtc0 == -1 then
        err = ffi.string(C.strerror(ffi.errno()))
        print("toggleAlarmInterrupt open /dev/rtc0", rtc0, err)
        return nil, rtc0, err
    end
    local re = C.ioctl(rtc0, enabled and C.RTC_AIE_ON or C.RTC_AIE_OFF, 0)
    if re == -1 then
        err = ffi.string(C.strerror(ffi.errno()))
        if enabled then
            print("toggleAlarmInterrupt ioctl RTC_AIE_ON", re, err)
        else
            print("toggleAlarmInterrupt ioctl RTC_AIE_OFF", re, err)
        end
        return nil, re, err
    end
    re = C.close(rtc0)
    if re == -1 then
        err = ffi.string(C.strerror(ffi.errno()))
        print("toggleAlarmInterrupt close /dev/rtc0", re, err)
        return nil, re, err
    end

    return true
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

    local ptm = C.gmtime(ffi.new("time_t[1]", epoch))
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
    local rtc0 = C.open("/dev/rtc0", bor(C.O_RDONLY, C.O_NONBLOCK, C.O_CLOEXEC))
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
    -- NOTE: Both util-linux & busybox rtcwake leave the current alarm as-is, and just disable the alarm interrupt.
    --       c.f., toggleAlarmInterrupt for details.
    self:toggleAlarmInterrupt(false)
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
    local rtc0 = C.open("/dev/rtc0", bor(C.O_RDONLY, C.O_NONBLOCK, C.O_CLOEXEC))
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

    -- Convert from UTC to local because these time-related functions are @#$@#$ stupid.
    local task_alarm_epoch_local = task_alarm_epoch and C.mktime(C.gmtime(ffi.new("time_t[1]", task_alarm_epoch))) or nil
    alarm_epoch = C.mktime(alarm)
    alarm_sys_epoch = C.mktime(alarm_sys)

    print("validateWakeupAlarmByProximity", task_alarm_epoch_local, alarm_epoch, alarm_sys_epoch, current_time_epoch)

    -- If our stored alarm and the system alarm don't match, we didn't set it.
    if not (alarm_epoch == alarm_sys_epoch) then return end

    -- If our stored alarm and the provided task alarm don't match,
    -- we're not talking about the same task. This should never happen.
    if task_alarm_epoch_local and not (alarm_epoch == task_alarm_epoch_local) then return end

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

-- Helpers for HCToSys
local function set_kernel_tz(tz)
    local re = C.settimeofday(nil, tz)
    if re == -1 then
        local err = ffi.string(C.strerror(ffi.errno()))
        print("set_kernel_tz settimeofday", re, err)
        return nil, re, err
    end

    return true
end

--[[--
Sets the system clock based on the hardware clock.

(e.g., hwclock --hctosys).
Heavily inspired by busybox's hwclock applet.
--]]
function RTC:HCToSys()
    local ok, err, re
    local rtc0 = C.open("/dev/rtc0", bor(C.O_RDONLY, C.O_NONBLOCK, C.O_CLOEXEC))
    if rtc0 == -1 then
        err = ffi.string(C.strerror(ffi.errno()))
        print("HCToSys open /dev/rtc0", rtc0, err)
        return nil, rtc0, err
    end

    -- Read the hardware clock
    local tm = ffi.new("struct tm")
    re = C.ioctl(rtc0, C.RTC_RD_TIME, tm)
    if re == -1 then
        err = ffi.string(C.strerror(ffi.errno()))
        print("HCToSys ioctl RTC_RD_TIME", re, err)
        return nil, re, err
    end
    re = C.close(rtc0)
    if re == -1 then
        err = ffi.string(C.strerror(ffi.errno()))
        print("HCToSys close /dev/rtc0", re, err)
        return nil, re, err
    end

    -- Deal with some TZ nonsense to convert that broken down representation to an UTC time_t...
    local oldtz = os.getenv("TZ")
    C.setenv("TZ", "UTC0", 1)
    local t = C.mktime(tm)
    C.unsetenv("TZ")
    if oldtz then
        C.setenv("TZ", oldtz, 1)
    end

    -- We want a timeval for settimeofday
    local tv = ffi.new("struct timeval")
    tv.tv_sec = t

    -- Deal with some more kernel & TZ nonsense...
    local tz = ffi.new("struct timezone")
    ok, re, err = set_kernel_tz(tz)
    if not ok then
        return nil, re, err
    end
    local cur = ffi.new("time_t[1]")
    cur[0] = C.time(nil)
    local broken = C.localtime(cur)
    tz.tz_minuteswest = -broken.tm_gmtoff / 60
    ok, re, err = set_kernel_tz(tz)
    if not ok then
        return nil, re, err
    end

    -- Finally set the system clock
    re = C.settimeofday(tv, nil)
    if re == -1 then
        err = ffi.string(C.strerror(ffi.errno()))
        print("HCToSys settimeofday", re, err)
        return nil, re, err
    end

    return true
end

return RTC
