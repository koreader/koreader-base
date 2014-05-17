
local gettext = require("ffi/gettext")
local _ = gettext.translate

describe("Gettext module", function()
	it("should init without error", function()
		assert.are.same(
			true,
			gettext.init("spec/base/unit/data/i18n", "koreader"))
	end)
	it("should set language without error", function()
		gettext.change_lang("")
	end)
	it("should translate string", function()
		assert.are.same("freedom", _("freedom"))
		gettext.change_lang("zh_CN")
		assert.are.same("自由", _("freedom"))
	end)
end)
