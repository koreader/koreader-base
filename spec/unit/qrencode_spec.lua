require("ffi_wrapper")
local qrencode = require("ffi/qrencode")

describe("QRencode module", function()
    it("should match the defined result", function()
        local result = '2;2;2;2;2;2;2;-2;-2;-1;1;1;1;-2;2;2;2;2;2;2;2;2;-2;-2;-2;-2;-2;2;-2;-2;-1;-1;1;1;-2;2;-2;-2;'
          ..'-2;-2;-2;2;2;-2;2;2;2;-2;2;-2;-2;-1;1;-1;-1;-2;2;-2;2;2;2;-2;2;2;-2;2;2;2;-2;2;-2;2;1;1;1;-1;-2;2;-2;2;'
          ..'2;2;-2;2;2;-2;2;2;2;-2;2;-2;-2;1;-1;-1;-1;-2;2;-2;2;2;2;-2;2;2;-2;-2;-2;-2;-2;2;-2;-2;-1;-1;-1;1;-2;2;'
          ..'-2;-2;-2;-2;-2;2;2;2;2;2;2;2;2;-2;2;-2;2;-2;2;-2;2;2;2;2;2;2;2;-2;-2;-2;-2;-2;-2;-2;-2;-2;1;1;-1;-1;-2;'
          ..'-2;-2;-2;-2;-2;-2;-2;2;2;-2;2;2;2;2;-2;-2;1;1;-1;1;2;-2;-2;-2;2;-2;-2;-2;1;1;-1;-1;-1;1;-2;1;1;-1;-1;1;'
          ..'1;-1;1;1;-1;1;-1;1;-1;1;-1;1;-1;-1;-1;2;1;-1;-1;1;-1;1;-1;1;1;-1;-1;-1;-1;1;-1;-1;1;1;1;-1;-2;-1;1;-1;'
          ..'-1;-1;-1;1;1;-1;1;1;-1;1;1;1;-1;-1;1;-1;-1;2;1;-1;1;1;1;-1;1;-1;1;-1;-1;1;-1;-1;-2;-2;-2;-2;-2;-2;-2;-2;'
          ..'-2;-1;-1;-1;-1;1;-1;-1;1;-1;1;-1;1;2;2;2;2;2;2;2;-2;-2;1;1;1;-1;-1;1;1;1;-1;-1;1;-1;2;-2;-2;-2;-2;-2;2;'
          ..'-2;2;1;1;1;1;-1;-1;-1;-1;1;1;1;1;2;-2;2;2;2;-2;2;-2;2;-1;1;1;-1;1;1;-1;-1;-1;-1;-1;-1;2;-2;2;2;2;-2;2;'
          ..'-2;2;-1;1;1;1;1;-1;-1;1;1;-1;1;1;2;-2;2;2;2;-2;2;-2;-2;-1;1;-1;-1;-1;-1;-1;-1;-1;1;-1;1;2;-2;-2;-2;-2;'
          ..'-2;2;-2;2;1;-1;1;1;1;1;1;-1;1;-1;-1;1;2;2;2;2;2;2;2;-2;2;1;1;1;1;1;-1;-1;1;1;1;-1;-1;'
        local ok, matrix, size = qrencode.qrcode('test')
        assert.is_true(ok)
        local ret = {}
        for x = 1, size do
            for y = 1, size do
                table.insert(ret, tostring(matrix[(y - 1) * size + x]))
                table.insert(ret, ';')
            end
        end
        assert.are.same(table.concat(ret, ''), result)
    end)

    -- ISO/IEC 18004:2006(E): https://abcdocz.com/doc/1124990/iso-iec-18004
    -- Annex I.1: "This Annex describes the encoding of the data string '01234567'
    -- into both a QR Code symbol and a Micro QR Code symbol."
    -- Annex I.2: "The data string is to be encoded into a version 1-M symbol,
    -- using the Numeric mode in accordance with 6.4.3."
    describe("encoding pipeline (ISO/IEC 18004:2006 Annex I.2 worked example)", function()
		it("selects numeric mode, version 1, EC level M, per Annex I.2's stated setup", function()
			local result = qrencode._debug_mask_penalties("01234567", 2) -- 2 = EC level M
			assert.are.equal(1, result.version)
			assert.are.equal(2, result.ec)
		end)

		-- Annex I.2 Step 1 gives the final padded bitstream as:
		--   00010000 00100000 00001100 01010110 01100001 10000000
		--   11101100 00010001 11101100 00010001 11101100 00010001
		--   11101100 00010001 11101100 00010001
		-- Step 2 appends the 10 RS parity codewords (version 1-M has a single,
		-- non-interleaved block, so no weaving is needed):
		--   10100101 00100100 11010100 11000001 11101101 00110110
		--   11000111 10000111 00101100 01010101
		it("generates exact data and Reed-Solomon parity codewords (Annex I.2, Steps 1-2)", function()
			local result = qrencode._debug_mask_penalties("01234567", 2)
			local expected_codewords = {
				-- 16 Data codewords (mode, character count, payload, terminator, 0xEC/0x11 pad bytes)
				0x10, 0x20, 0x0C, 0x56, 0x61, 0x80, 0xEC, 0x11,
				0xEC, 0x11, 0xEC, 0x11, 0xEC, 0x11, 0xEC, 0x11,
				-- 10 Reed-Solomon parity codewords from degree-10 polynomial division
				0xA5, 0x24, 0xD4, 0xC1, 0xED, 0x36, 0xC7, 0x87, 0x2C, 0x55,
			}
			assert.are.same(expected_codewords, result.codewords)
		end)

		-- Annex I.2 Step 4: "Apply the data masking patterns defined in 6.8.1 in
		-- turn and evaluate the results in accordance with 6.8.2. The data
		-- masking pattern selected is referenced 010." (= mask 2). Confirmed
		-- independently by the format-information bits given directly after
		-- ("00 010") in Step 5, which agree with the Step 4 caption.
		it("selects mask 2, matching Annex I.2 Step 4 directly", function()
			local result = qrencode._debug_mask_penalties("01234567", 2)
			assert.are.equal(2, result.best_mask)
		end)
	end)

	-- J. Persson, "A note on minor errors in the International QR Barcode standard" (2008):
	-- https://www.coastalmonitoring.org/resources/jpclass/QR/qr-comment.pdf
	-- Persson's target was the 2000 edition's Annex G, which (for this same
	-- "01234567"/version 1-M input) selected mask 3 with a penalty breakdown
	-- that fails the standard's own scoring rules - mask 3 incurs a false
	-- 1:1:3:1:1 finder-like match that mask 7 avoids, so mask 7 scores lower.
	-- Persson's paper only compares masks 3 and 7; it does not claim mask 7
	-- is the global optimum. The 2006 edition's Annex I.2 (tested above)
	-- independently settles that question directly: mask 2 is correct.
	describe("mask penalty scoring vs Persson's published correction to the 2000-edition Annex G", function()
		local result = qrencode._debug_mask_penalties("01234567", 2)

		it("evaluates mask 7 as having a lower total penalty than mask 3, as Persson demonstrated", function()
			local p_mask3 = result.components[3].p1 + result.components[3].p2 + result.components[3].p3 + result.components[3].p4
			local p_mask7 = result.components[7].p1 + result.components[7].p2 + result.components[7].p3 + result.components[7].p4
			assert.is_true(p_mask7 < p_mask3)
		end)

		it("matches Persson's P1 (line-run) scores exactly", function()
			assert.are.equal(187, result.components[3].p1)
			assert.are.equal(176, result.components[7].p1)
		end)

		-- Persson's P2 (2x2 block) figures were computed by hand and are
		-- documented in his paper as depending on a block-search convention
		-- the standard itself leaves unspecified. This implementation instead
		-- follows the convention used by reference libraries such as ZXing/
		-- rxing, which count every overlapping 2x2 window rather than
		-- partitioning into disjoint larger blocks - their own source code
		-- states this is "equivalent to the spec's rule... because this is
		-- the number of 2x2 blocks inside such a [larger] block." Mask 3's
		-- score (105) happens to coincide with Persson's hand-computed value
		-- exactly; mask 7's (150 vs. his 126) diverges, consistent with the
		-- two methods only disagreeing when a mask produces same-colour
		-- regions larger than 2x2.
		it("matches Persson's P2 score for mask 3 exactly; mask 7 differs per the overlapping-window convention", function()
			assert.are.equal(105, result.components[3].p2)
			assert.are.equal(150, result.components[7].p2)
		end)

		-- Persson's P3 figures assume scanning extends into the printed
		-- quiet zone outside the matrix (needed to detect the three real
		-- finder patterns as 1:1:3:1:1 matches, giving every mask a flat
		-- +720 baseline). This implementation models that same quiet zone
		-- explicitly via a 4-module padding border, so it reproduces his
		-- absolute totals, not just the delta between masks.
		it("matches Persson's P3 scores and the 40-point mask 3 vs. mask 7 gap exactly", function()
			assert.are.equal(760, result.components[3].p3)
			assert.are.equal(720, result.components[7].p3)
			assert.are.equal(40, result.components[3].p3 - result.components[7].p3)
		end)

		it("matches Persson's P4 (dark ratio) scores exactly", function()
			assert.are.equal(0, result.components[3].p4)
			assert.are.equal(0, result.components[7].p4)
		end)
	end)

	describe("qrcode() across a range of versions", function()
		local base_text = "The quick brown fox jumps over the lazy dog. "
		local function make_payload(len)
			local s = base_text:rep(math.ceil(len / #base_text))
			return s:sub(1, len)
		end

		local test_lengths = { 10, 50, 100, 200, 350, 500, 800, 1200, 1700, 2200, 2700, 2953 }

		for _, len in ipairs(test_lengths) do
			it(string.format("encodes a %d-byte payload successfully with a well-formed matrix", len), function()
				local payload = make_payload(len)
				local ok, matrix, size = qrencode.qrcode(payload, 1)
				assert.are.equal(true, ok)
				assert.is_true(size >= 21 and size <= 177)
				assert.are.equal(0, (size - 17) % 4)

				local function cell(x, y) return matrix[(y - 1) * size + x] end
				assert.is_true(cell(1, 1) > 0)
				assert.is_true(cell(7, 1) > 0)
				assert.is_true(cell(1, 7) > 0)
				assert.is_true(cell(4, 4) > 0)
				assert.is_true(cell(2, 2) < 0)
			end)
		end
	end)

	-- ISO/IEC 18004:2006(E) §5.1(e)(2): "maximum QR Code symbol size,
	-- Version 40-L: ... Byte data: 2953".
	describe("Cross MAX_TEXT_LENGTH boundary (ISO/IEC 18004:2006 section 5.1(e)(2))", function()
		local base_text = "The quick brown fox jumps over the lazy dog. "

		it("encodes the maximum Version 40-L byte-mode capacity (2953 bytes)", function()
			local payload = base_text:rep(math.ceil(2953 / #base_text)):sub(1, 2953)
			local ok, _, size = qrencode.qrcode(payload, 1)
			assert.are.equal(true, ok)
			assert.are.equal(177, size)
		end)

		it("raises an error when payload exceeds version 40 capacity (2954 bytes)", function()
			local payload = base_text:rep(math.ceil(2954 / #base_text)):sub(1, 2954)
			assert.has_error(function()
				qrencode.qrcode(payload, 1)
			end)
		end)
	end)

    describe("specification reference vectors", function()
		-- ISO/IEC 18004:2006(E) §6.4.4 explicitly provides "AC-42" as the worked evaluation example.
		it("encodes the standard alphanumeric example 'AC-42' at Version 1-H (ISO/IEC 18004:2006 section 6.4.4)", function()
			local res = qrencode._debug_mask_penalties("AC-42", 4) -- 4 = EC level H, per the spec's own example
			assert.are.equal(1, res.version)
			assert.are.equal(4, res.ec)
		end)

		-- Not sourced from the standard - a plain smoke test for an ordinary
		-- alphanumeric string, kept for basic coverage rather than as a
		-- spec-conformance check.
		it("encodes 'HELLO WORLD' at Version 1-M", function()
			local res = qrencode._debug_mask_penalties("HELLO WORLD", 2)
			assert.are.equal(1, res.version)
			assert.are.equal(2, res.ec)
		end)

		-- Table 5 ("Alphanumeric mode character set") lists exactly 45 valid characters.
		-- Table 7 ("Data capacity") specifies Version 1-L holds a maximum of 25 Alphanumeric characters.
		it("encodes the full 45-character alphanumeric set, promoting cleanly to Version 2-L", function()
			local alnum_set = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:"
			local ok, _, size = qrencode.qrcode(alnum_set, 1)
			assert.is_true(ok)
			assert.are.equal(25, size) -- Version 2 is 25x25 modules
		end)
	end)

	-- The triplet/remainder bit-width rules exercised here (10-bit triplets,
	-- 7-bit two-digit remainder, 4-bit one-digit remainder) are the same
	-- rules worked in Annex I.2 Step 1 ("012 -> 0000001100" [10-bit],
	-- "67 -> 1000011" [7-bit]) - these boundary cases follow directly from
	-- that same procedure, not a separately cited example.
	describe("numeric remainder bit-packing boundaries", function()
		local boundary_strings = {
			{ str = "7",    desc = "1 digit (4-bit remainder)" },
			{ str = "84",   desc = "2 digits (7-bit remainder)" },
			{ str = "492",  desc = "3 digits (10-bit triplet)" },
			{ str = "1048", desc = "4 digits (1 triplet + 1 remainder)" },
		}

		for _, tc in ipairs(boundary_strings) do
			it(string.format("encodes %s correctly in Version 1", tc.desc), function()
				local ok, _, size = qrencode.qrcode(tc.str, 1)
				assert.is_true(ok)
				assert.are.equal(21, size)
			end)
		end

		it("saturates Version 1-L numeric capacity at exactly 41 digits", function()
			local payload_41 = string.rep("9", 41)
			local ok, _, size = qrencode.qrcode(payload_41, 1)
			assert.is_true(ok)
			assert.are.equal(21, size)

			local payload_42 = string.rep("9", 42)
			local ok2, _, size2 = qrencode.qrcode(payload_42, 1)
			assert.is_true(ok2)
			assert.are.equal(25, size2)
		end)
	end)

	-- Capacity boundaries below are derived from this module's own capacity
	-- table (get_version_eclevel/capacity), the same constant table used
	-- across every implementation checked in this file's history (ZXing,
	-- rxing, the legacy comparison module) - not directly viewed against a
	-- Table 7 page image.
	describe("Version 1 capacity boundaries across EC levels (8-bit byte mode)", function()
		local levels = {
			{ ec = 1, max_v1 = 17, name = "Level L" },
			{ ec = 2, max_v1 = 14, name = "Level M" },
			{ ec = 3, max_v1 = 11, name = "Level Q" },
			{ ec = 4, max_v1 = 7,  name = "Level H" },
		}

		for _, lvl in ipairs(levels) do
			it(string.format("fits %d bytes in Version 1 for %s", lvl.max_v1, lvl.name), function()
				local payload = string.rep("a", lvl.max_v1)
				local ok, _, size = qrencode.qrcode(payload, lvl.ec)
				assert.is_true(ok)
				assert.are.equal(21, size)
			end)

			it(string.format("promotes %d bytes to Version 2 for %s", lvl.max_v1 + 1, lvl.name), function()
				local payload = string.rep("a", lvl.max_v1 + 1)
				local ok, _, size = qrencode.qrcode(payload, lvl.ec)
				assert.is_true(ok)
				assert.are.equal(25, size)
			end)
		end

        -- Table 7 specifies Version 1-L capacity for Numeric mode is 41 characters.
		it("saturates Version 1-L numeric capacity at exactly 41 digits", function()
			local payload_41 = string.rep("9", 41)
			local ok, _, size = qrencode.qrcode(payload_41, 1)
			assert.is_true(ok)
			assert.are.equal(21, size)

			local payload_42 = string.rep("9", 42)
			local ok2, _, size2 = qrencode.qrcode(payload_42, 1)
			assert.is_true(ok2)
			assert.are.equal(25, size2)
		end)
	end)

	describe("ISO/IEC 18004:2006 Section 6.4.5 8-bit byte mode compliance", function()
		-- Section 6.4.5 mandates encoding of the full 8-bit Latin/Kana character set (0x00 to 0xFF).
		-- These tests verify the implementation's string handling is binary-safe across that range.
		it("encodes payload containing mixed nulls, control chars, and high bytes", function()
			local binary_payload = "PREFIX\0\1\2\255\128SUFFIX"
			local ok, _, size = qrencode.qrcode(binary_payload, 1)
			assert.is_true(ok)
			assert.are.equal(21, size)
		end)

		it("preserves exact Version 1 capacity boundaries when payload consists entirely of null bytes", function()
			-- Validates against the V1-L 17-byte maximum (Table 7) to ensure
			-- internal string length checks do not fail on \0 truncation
			local null_v1 = string.rep("\0", 17)
			local ok, _, size = qrencode.qrcode(null_v1, 1)
			assert.is_true(ok)
			assert.are.equal(21, size)

			local null_v2 = string.rep("\0", 18)
			local ok2, _, size2 = qrencode.qrcode(null_v2, 1)
			assert.is_true(ok2)
			assert.are.equal(25, size2)
		end)
	end)

    describe("structural invariants (ISO/IEC 18004:2006 section 6.7)", function()
        local function cell(matrix, size, x, y) return matrix[(y - 1) * size + x] end

        it("places the dark module at (9, version*4+10) for every version tested", function()
            for _, version in ipairs({ 1, 5, 10, 20, 40 }) do
                local payload = string.rep("a", version == 1 and 5 or version * 15)
                local ok, matrix, size = qrencode.qrcode(payload, 1)
                assert.is_true(ok)
                assert.is_true(cell(matrix, size, 9, size - 7) > 0)
            end
        end)

        it("keeps the horizontal and vertical timing patterns alternating and unoverwritten", function()
            local ok, matrix, size = qrencode.qrcode(string.rep("a", 200), 1)
            assert.is_true(ok)
            for i = 9, size - 8 do
                local expect_dark = (i % 2 == 1)
                assert.are.equal(expect_dark, cell(matrix, size, i, 7) > 0)
                assert.are.equal(expect_dark, cell(matrix, size, 7, i) > 0)
            end
        end)
    end)
end)
