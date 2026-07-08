local ffi = require("ffi")
local C = ffi.C
local util = require("ffi/util")

require("ffi/posix_h")
require("ffi/linux_input_h")

-- Load the client/protocol library
local libblight = ffi.loadlib("blight_protocol", "3", "blight_protocol")

local input = {
    is_ffi = true,
    devices = {},
}

local function get_device_num(path)
    if not path then
        return nil
    end
    local real_path = path
    local buf = ffi.new("char[4096]")
    local res = C.realpath(path, buf)
    if res ~= nil then
        real_path = ffi.string(buf)
    end
    local num = real_path:match("event(%d+)")
    return num and tonumber(num)
end

function input.open(path)
    local framebuffer = require("ffi/framebuffer_blight")
    local bus = framebuffer.bus
    if not bus then
        return false
    end

    local dev_num = get_device_num(path)
    if not dev_num then
        return false
    end

    -- Close if already open
    if input.devices[path] then
        input.close(path)
    end

    local buf = libblight.blight_service_input_open(bus, dev_num)
    if buf == nil then
        return false
    end

    input.devices[path] = buf
    return true
end

function input.close(path)
    local buf = input.devices[path]
    if buf then
        libblight.blight_input_buffer_deref(buf)
        input.devices[path] = nil
    end
    return true
end

function input.closeAll()
    for path, _ in pairs(input.devices) do
        input.close(path)
    end
    return true
end

local last_time_sec, last_time_usec = util.gettime()

function input.waitForEvent(sec, usec)
    local active_devices = {}
    local active_paths = {}
    for path, buf in pairs(input.devices) do
        table.insert(active_devices, buf)
        table.insert(active_paths, path)
    end

    local n_devices = #active_devices
    if n_devices == 0 then
        return false, C.ETIME
    end

    -- Check if we were suspended/resumed since the last waitForEvent call
    local now_sec, now_usec = util.gettime()
    if last_time_sec then
        local elapsed = (now_sec - last_time_sec) + (now_usec - last_time_usec) / 1000000
        if elapsed > 5 then
            local framebuffer = require("ffi/framebuffer_blight")
            if framebuffer.fd and framebuffer.fd >= 0 and framebuffer.surface_id > 0 then
                libblight.blight_focus(framebuffer.fd)
                libblight.blight_raise(framebuffer.fd, framebuffer.surface_id)
            end
        end
    end
    last_time_sec, last_time_usec = now_sec, now_usec

    local deadline_sec, deadline_usec
    if sec then
        deadline_usec = now_usec + usec
        deadline_sec = now_sec + sec + math.floor(deadline_usec / 1000000)
        deadline_usec = deadline_usec % 1000000
    end

    local event_ptr = ffi.new("struct input_event*[1]")

    while true do
        local evs = {}
        for i = 1, n_devices do
            local buf = active_devices[i]
            while true do
                local r = libblight.blight_event_from_buffer(buf, event_ptr, false)
                if r == 0 then
                    local ev = event_ptr[0]
                    table.insert(evs, {
                        type = ev.type,
                        code = ev.code,
                        value = ev.value,
                        time = { sec = tonumber(ev.time.tv_sec), usec = tonumber(ev.time.tv_usec) },
                    })
                    libblight.blight_event_free(ev)
                else
                    break
                end
            end
        end

        if #evs > 0 then
            return true, evs
        end

        if deadline_sec then
            now_sec, now_usec = util.gettime()
            if now_sec > deadline_sec or (now_sec == deadline_sec and now_usec >= deadline_usec) then
                last_time_sec, last_time_usec = now_sec, now_usec
                return false, C.ETIME
            end
        end

        C.usleep(2000)

        -- Check if we were suspended/resumed during usleep
        now_sec, now_usec = util.gettime()
        local elapsed = (now_sec - last_time_sec) + (now_usec - last_time_usec) / 1000000
        if elapsed > 5 then
            local framebuffer = require("ffi/framebuffer_blight")
            if framebuffer.fd and framebuffer.fd >= 0 and framebuffer.surface_id > 0 then
                libblight.blight_focus(framebuffer.fd)
                libblight.blight_raise(framebuffer.fd, framebuffer.surface_id)
            end
        end
        last_time_sec, last_time_usec = now_sec, now_usec
    end
end

return input
