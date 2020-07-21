require("ffi_wrapper")

describe("MD5 module", function()
    local md5, sha2

    setup(function()
        md5 = require("ffi/MD5")
        sha2 = require("ffi/sha2")
    end)

    it("should calculate correct MD5 hashes", function()
        assert.is_equal("d41d8cd98f00b204e9800998ecf8427e", sha2.md5(""))
        assert.is_equal("93b885adfe0da089cdf634904fd59f71", sha2.md5("\0"))
        assert.is_equal("1b05aba914a8b12315c7ee52b42f3d35", sha2.md5("0123456789abcdefX"))
    end)

    it("should calculate MD5 sum by updating", function()
        local update = sha2.md5()
        update("0123456789")
        update("abcdefghij")
        assert.is_equal(sha2.md5("0123456789abcdefghij"), update())
    end)

    it("should calculate MD5 sum of a file", function()
        assert.is_equal(
            "ee53c8f032c3d047cb3d1999c8ff5e09",
            md5.sumFile("spec/base/unit/data/2col.jbig2.pdf"))
    end)

    it("should error out on non-exist file", function()
        local ok, err = md5.sumFile("foo/bar/abc/123/baz.pdf")
        assert.is.falsy(ok)
        assert.is_not_nil(err)
    end)
end)

