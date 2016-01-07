local util = require("ffi/util")
local lfs = require("libs/libkoreader-lfs")

describe("util module", function()
    describe("util.gettime", function()

        it("should return sec and usec", function()
            local sec, usec = util.gettime()
            assert.are_not.equal(sec, nil)
            assert.are_not.equal(usec, nil)
        end)

    end)

    describe("util.template", function()

        it("should not affect string without arguments", function()
            local str_regular = ("just a string")
            local str_template = util.template(
                ("just a string")
            )
            assert.are.equal(str_regular, str_template)

            local str_regular_marker = ("just a string %1")
            local str_template_marker = util.template(
                ("just a string %1")
            )
            assert.are.equal(str_regular_marker, str_template_marker)
        end)

        it("should not replace %0", function()
            local str_regular = ("The argument goes %0.")
            local str_template = util.template(
                ("The argument goes %0."),
                "argument"
            )
            assert.are.equal(str_regular, str_template)
        end)

        it("should replace place markers with arguments", function()
            local str_regular = ("The arguments go here and there.")
            local str_template = util.template(
                ("The arguments go %1 and %2."),
                "here",
                "there"
            )
            assert.are.equal(str_regular, str_template)
        end)

        it("should allow dynamic positioning of place markers", function()
            local str_regular = ("The arguments go there and here.")
            local str_template = util.template(
                ("The arguments go %2 and %1."),
                "here",
                "there"
            )
            assert.are.equal(str_regular, str_template)
        end)

        it("should replace place markers no matter how many times they appear", function()
            local str_regular = ("bark bark bark bark")
            local str_template = util.template(
                ("%1 %1 %1 %1"),
                "bark"
            )
            assert.are.equal(str_regular, str_template)
        end)

        it("should treat %10 as %10, not %1", function()
            local str_regular = ("First: success1; tenth: success10.")
            local str_template = util.template(
                ("First: %1; tenth: %10."),
                "success1",
                "success2",
                "success3",
                "success4",
                "success5",
                "success6",
                "success7",
                "success8",
                "success9",
                "success10"
            )
            assert.are.equal(str_regular, str_template)
        end)

        it("should treat %100 as %10", function()
            local str_regular = ("First: success1-; tenth: success10-; hundredth: success10-0.")
            local template_args = {}
            for i=1,100,1 do
                template_args[i] = "success" .. i .. "-"
            end
            local str_template = util.template(
                ("First: %1; tenth: %10; hundredth: %100."),
                unpack(template_args)
            )
            assert.are.equal(str_regular, str_template)
        end)

        it("should not allow escaping", function()
            local str_regular = ("This %argument tried to escape.")
            local str_template = util.template(
                ("This %%1 tried to escape."),
                "argument"
            )
            assert.are.equal(str_regular, str_template)
        end)

    end)

    describe("util.copyFile", function()
        local sample_pdf = "spec/base/unit/data/simple.pdf"
        local output_pdf = "spec/base/unit/data/test_util_copy.pdf"

        it("should copy properly", function()
            local from_f = io.open(sample_pdf, "r")
            local from_data = from_f:read("*a")
            util.copyFile(sample_pdf, output_pdf)
            local to_f = io.open(output_pdf, "r")
            local to_data = to_f:read("*a")
            assert.equals(from_data, to_data)
            from_f:close()
            to_f:close()
            os.remove(output_pdf)
        end)

        it("fail at non-exists files", function()
            local err = util.copyFile("/tmp/abc/123/foo/bar/baz/777.pkg", output_pdf)
            assert.is_not_nil(err)
        end)
    end)

    describe("util.joinPath", function()
        it("should join path properly", function()
            assert.equals(util.joinPath("/abc/123", "foo"), "/abc/123/foo")
            assert.equals(util.joinPath("/abc/123/", "bar"), "/abc/123/bar")
            assert.equals(util.joinPath("/123/", "/bar"), "/bar")
            assert.equals(util.joinPath("/tmp", "bar.pdf"), "/tmp/bar.pdf")
        end)
    end)

    describe("util.purgeDir", function()
        it("should error out on non-exists directory", function()
            ok, err = util.purgeDir('/tmp/123/abc/567/foobar')
            assert.is_nil(ok)
            assert.is_not_nil(err)
        end)

        it("should delete non-empty directory", function()
            local tmp_dir = "spec/base/unit/data/test_purge_dir"
            local tmp_subdir = util.joinPath(tmp_dir, "morestuff")
            lfs.mkdir(tmp_dir)
            lfs.mkdir(tmp_subdir)
            assert.equals(lfs.attributes(tmp_dir).mode, "directory")
            assert.equals(lfs.attributes(tmp_subdir).mode, "directory")
            util.purgeDir(tmp_dir)
            local w, err = lfs.attributes(tmp_dir)
            assert.is_not_nil(err)
            _, err = lfs.attributes(tmp_subdir)
            assert.is_not_nil(err)
        end)
    end)
end)
