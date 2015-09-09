local util = require("ffi/util")

describe("util module", function()
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
end)
