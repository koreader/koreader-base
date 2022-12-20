local ffi = require("ffi")

-- Custom values we use for ev.type, ev.code & ev.value in Input and Device HAL implementations
-- NOTE: EV_SDL == 'S', EV_GYRO == 'G'

-- In particular, orientation constants, usable by Device implementations for platform-specific gyro translations.
-- (matches framebuffer constants, which matches Linux <input/fb.h> FB_ROTATE_* constants).
-- (i.e., this is how the device is *physically* oriented).
ffi.cdef[[
static const int EV_GYRO = 71;
static const int EV_SDL = 83;

static const int GYRO_HANDLED = 0;

static const int DEVICE_ORIENTATION_UPRIGHT = 0;
static const int DEVICE_ORIENTATION_CLOCKWISE = 1;
static const int DEVICE_ORIENTATION_UPSIDE_DOWN = 2;
static const int DEVICE_ORIENTATION_COUNTER_CLOCKWISE = 3;
]]
