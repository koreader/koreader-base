
describe("MD5 module", function()
    local md5

    setup(function()
        md5 = require("ffi/MD5")
    end)

    it("should calculate correct MD5 hashes", function()
        assert.is_equal(md5.sum(""), "d41d8cd98f00b204e9800998ecf8427e")
        assert.is_equal(md5.new():sum("\0"), "93b885adfe0da089cdf634904fd59f71")
        assert.is_equal(md5.new():sum("0123456789abcdefX"), "1b05aba914a8b12315c7ee52b42f3d35")
    end)

    it("should calculate MD5 sum by updating", function()
        local m = md5.new()
        m:update("0123456789")
        m:update("abcdefghij")
        assert.is_equal(m:sum(), md5.sum("0123456789abcdefghij"))
    end)

    it("should calculate MD5 sum of a file", function()
        assert.is_equal(
            md5.sumFile("spec/base/unit/data/2col.jbig2.pdf"),
            "ee53c8f032c3d047cb3d1999c8ff5e09")
    end)

    it("should error out on non-exist file", function()
        local ok, err = md5.sumFile("foo/bar/abc/123/baz.pdf")
        assert.is.falsy(ok)
        assert.is_not_nil(err)
    end)
end)

