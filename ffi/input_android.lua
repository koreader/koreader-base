local ffi = require("ffi")
local bit = require("bit")

local android = require("android")
local dummy = require("ffi/linux_input_h")

-- to trigger refreshes for certain Android framework events:
local fb = require("ffi/framebuffer_android").open()

local input = {}

function input.open()
end

local inputQueue = {}

local ev_time = ffi.new("struct timeval")
local function genEmuEvent(evtype, code, value)
	ffi.C.gettimeofday(ev_time, nil)
	local ev = {
		type = tonumber(evtype),
		code = tonumber(code),
		value = tonumber(value),
		time = { sec = tonumber(ev_time.tv_sec), usec = tonumber(ev_time.tv_usec) }
	}
	table.insert(inputQueue, ev)
end

local is_in_touch = false

local function motionEventHandler(motion_event)
	local action = ffi.C.AMotionEvent_getAction(motion_event)
	local flags = bit.band(action, ffi.C.AMOTION_EVENT_ACTION_MASK)
	if flags == ffi.C.AMOTION_EVENT_ACTION_DOWN then
		is_in_touch = true
		local id = ffi.C.AMotionEvent_getPointerId(motion_event, 0)
		local x = ffi.C.AMotionEvent_getX(motion_event, id)
		local y = ffi.C.AMotionEvent_getY(motion_event, id)
		genEmuEvent(ffi.C.EV_ABS, ffi.C.ABS_MT_TRACKING_ID, id)
		genEmuEvent(ffi.C.EV_ABS, ffi.C.ABS_MT_POSITION_X, x)
		genEmuEvent(ffi.C.EV_ABS, ffi.C.ABS_MT_POSITION_Y, y)
		genEmuEvent(ffi.C.EV_SYN, ffi.C.SYN_REPORT, 0)
	elseif flags == ffi.C.AMOTION_EVENT_ACTION_UP then
		is_in_touch = false
		genEmuEvent(ffi.C.EV_ABS, ffi.C.ABS_MT_TRACKING_ID, -1)
		genEmuEvent(ffi.C.EV_SYN, ffi.C.SYN_REPORT, 0)
	elseif flags == ffi.C.AMOTION_EVENT_ACTION_MOVE then
		if is_in_touch then
			local id = ffi.C.AMotionEvent_getPointerId(motion_event, 0)
			local x = ffi.C.AMotionEvent_getX(motion_event, id)
			local y = ffi.C.AMotionEvent_getY(motion_event, id)
			genEmuEvent(ffi.C.EV_ABS, ffi.C.ABS_MT_POSITION_X, x)
			genEmuEvent(ffi.C.EV_ABS, ffi.C.ABS_MT_POSITION_Y, y)
			genEmuEvent(ffi.C.EV_SYN, ffi.C.SYN_REPORT, 0)
		end
	end
end

function input.waitForEvent(usecs)
	local timeout = math.ceil(usecs and usecs/1000 or -1)
	while true do
		-- check for queued events
		if #inputQueue > 0 then
			-- return oldest FIFO element
			return table.remove(inputQueue, 1)
		end
		local events = ffi.new("int[1]")
		local source = ffi.new("struct android_poll_source*[1]")
		local poll_state = ffi.C.ALooper_pollAll(timeout, nil, events, ffi.cast("void**", source))
		if poll_state >= 0 then
			if source[0] ~= nil then
				--source[0].process(android.app, source[0])
				if source[0].id == ffi.C.LOOPER_ID_MAIN then
					local cmd = ffi.C.android_app_read_cmd(android.app)
					ffi.C.android_app_pre_exec_cmd(android.app, cmd)
					android.LOGI("got command: " .. tonumber(cmd))
					if cmd == ffi.C.APP_CMD_INIT_WINDOW then
						fb:refresh()
					elseif cmd == ffi.C.APP_CMD_TERM_WINDOW then
						-- do nothing for now
					elseif cmd == ffi.C.APP_CMD_LOST_FOCUS then
						-- do we need this here?
						fb:refresh()
					end
					ffi.C.android_app_post_exec_cmd(android.app, cmd)
				elseif source[0].id == ffi.C.LOOPER_ID_INPUT then
					local event = ffi.new("AInputEvent*[1]")
					while ffi.C.AInputQueue_getEvent(android.app.inputQueue, event) >= 0 do
						if ffi.C.AInputQueue_preDispatchEvent(android.app.inputQueue, event[0]) == 0 then
							if ffi.C.AInputEvent_getType(event[0]) == ffi.C.AINPUT_EVENT_TYPE_MOTION then
								motionEventHandler(event[0])
							end
							ffi.C.AInputQueue_finishEvent(android.app.inputQueue, event[0], 1)
						end
					end
				end
			end
			if android.app.destroyRequested ~= 0 then
				android.LOGI("Engine thread destroy requested!")
				error("application forced to quit")
				return
			end
		elseif poll_state == ffi.C.ALOOPER_POLL_TIMEOUT then
			error("Waiting for input failed: timeout\n")
		end
	end
end

function input.fakeTapInput() end
function input.closeAll() end

return input
