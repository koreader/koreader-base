local test_command = ([[./luajit -e '
require "ffi/loadlib"
require "ffi/posix_h"
TURBO_SSL = true
__TURBO_USE_LUASOCKET__ = true
require "turbo"
']]):gsub("\n", " ")

describe("turbo module", function()
    it("should not conflict with ffi/posix_h", function()
        local ret = os.execute(test_command)
        assert.are.equal(0, ret)
    end)
end)

