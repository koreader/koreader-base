local ffi = require("ffi")

local android = require("android")
local dummy = require("ffi/linux_input_h")

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

function input.waitForEvent(timeout)
	local countdown = usecs
	while true do
		-- check for queued events
		if #inputQueue > 0 then
			-- return oldest FIFO element
			return table.remove(inputQueue, 1)
		end
		local events = ffi.new("int[1]")
		local source = ffi.new("struct android_poll_source*[1]")
		if ffi.C.ALooper_pollAll(timeout, nil, events, ffi.cast("void**", source)) >= 0 then
			if source[0] ~= nil then
				--source[0].process(android.app, source[0])
				if source[0].id == ffi.C.LOOPER_ID_MAIN then
					local cmd = ffi.C.android_app_read_cmd(android.app)
					ffi.C.android_app_pre_exec_cmd(android.app, cmd)
					A.LOGI("got command: " .. tonumber(cmd))
					if cmd == ffi.C.APP_CMD_INIT_WINDOW then
						draw_frame()
					elseif cmd == ffi.C.APP_CMD_TERM_WINDOW then
						-- do nothing for now
					elseif cmd == ffi.C.APP_CMD_LOST_FOCUS then
						draw_frame()
					end
					ffi.C.android_app_post_exec_cmd(android.app, cmd)
				elseif source[0].id == ffi.C.LOOPER_ID_INPUT then
					local event = ffi.new("AInputEvent*[1]")
					while ffi.C.AInputQueue_getEvent(android.app.inputQueue, event) >= 0 do
						if ffi.C.AInputQueue_preDispatchEvent(android.app.inputQueue, event[0]) == 0 then
							ffi.C.AInputQueue_finishEvent(android.app.inputQueue, event[0],
								android.handle_input(android.app, event[0]))
						end
					end
				end
			end
			if android.app.destroyRequested ~= 0 then
				error("application forced to quit")
				android.LOGI("Engine thread destroy requested!")
				return
			end
		end
	end
end

function input.fakeTapInput() end
function input.closeAll end

return input
