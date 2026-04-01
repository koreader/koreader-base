local test_command = ([[./luajit -e '
ffi = require("ffi")
require "ffi/posix_h"
ffi.cdef "static const int POCKETBOOK_VERSION = %u;"
require "ffi/inkview_h"
local mtp = ffi.new("iv_mtinfo *")
mtp = mtp + 1
']]):gsub("\n", " ")

describe("ffi/inkview_h module", function()
    it("should not support version 502", function()
        local ret = os.execute(string.format(test_command, 502))
        assert.are_not.equal(0, ret)
    end)
    for supported_version in string.gmatch("505 507 508 509 510 511 512 514 515 517 519 523 605 608 610 611 612", "%d+") do
        it("should support version "..supported_version, function()
            local ret = os.execute(string.format(test_command, supported_version))
            assert.are.equal(0, ret)
        end)
    end
end)
