--- The qrcode library is licensed under the 3-clause BSD license (aka "new BSD")
--- To get in contact with the author, mail to <gundlach@speedata.de>.
---
--- Please report bugs on the [github project page](http://speedata.github.io/luaqrcode/).
-- Copyright (c) 2012-2020, Patrick Gundlach and contributors, see https://github.com/speedata/luaqrcode
-- All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met:
--	 * Redistributions of source code must retain the above copyright
--	   notice, this list of conditions and the following disclaimer.
--	 * Redistributions in binary form must reproduce the above copyright
--	   notice, this list of conditions and the following disclaimer in the
--	   documentation and/or other materials provided with the distribution.
--	 * Neither the name of SPEEDATA nor the
--	   names of its contributors may be used to endorse or promote products
--	   derived from this software without specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
-- ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
-- WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- DISCLAIMED. IN NO EVENT SHALL SPEEDATA GMBH BE LIABLE FOR ANY
-- DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
-- (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
-- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
-- ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
-- (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
-- SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

local max, min = math.max, math.min
local floor, abs = math.floor, math.abs
local byte, sub = string.byte, string.sub
local match = string.match

local bit = require("bit")
local band, bor, bxor, lshift, rshift, bnot = bit.band, bit.bor, bit.bxor, bit.lshift, bit.rshift, bit.bnot
local ffi = require("ffi")

--- Helper functions & Persistent Module Caches
--- =========================================

-- FFI-backed persistent caches for maximum L1 cache density.
local MAX_QR_LEN = 31329
local MAX_PADDING = 4
local MAX_PADDED_SIZE = 177 + 2 * MAX_PADDING
local MAX_STRIDE = floor((MAX_PADDED_SIZE + 31) / 32)
local MAX_BB_LEN = MAX_PADDED_SIZE * MAX_STRIDE

-- Standard int8_t UI arrays
local base_matrix = ffi.new("int8_t[?]", MAX_QR_LEN + 1)
local best_matrix = ffi.new("int8_t[?]", MAX_QR_LEN + 1)
local raw_bit     = ffi.new("int8_t[?]", MAX_QR_LEN + 1)

-- uint32_t Bitboards for the Penalty Pipeline
local bb_base    = ffi.new("uint32_t[?]", MAX_BB_LEN)
local bb_scratch = ffi.new("uint32_t[?]", MAX_BB_LEN)

-- Encoding and EC block caches
local bw_buf             = ffi.new("uint8_t[?]", 4001)
local arranged_data      = ffi.new("uint8_t[?]", 4001)
local ec_blocks_cache    = ffi.new("uint8_t[?]", 4001)
local mp_int             = ffi.new("int32_t[?]", 256)
local block_data_offsets = ffi.new("int32_t[?]", 201)
local block_data_lens    = ffi.new("int32_t[?]", 201)
local block_ec_offsets   = ffi.new("int32_t[?]", 201)
local block_ec_lens      = ffi.new("int32_t[?]", 201)

local function set_cell(matrix, size, x, y, val)
	matrix[(y - 1) * size + x] = val
end

local function set_bb_bit(bb, stride, x, y, val)
	x, y = x - 1, y - 1
	local w = y * stride + floor(x / 32)
	if val == 1 then
		bb[w] = bor(bb[w], lshift(1, x % 32))
	else
		bb[w] = band(bb[w], bnot(lshift(1, x % 32)))
	end
end

-- Persistent BitWriter
local bw = { buf = bw_buf, len = 0, acc = 0, bits = 0 }
function bw:reset()
	self.len, self.acc, self.bits = 0, 0, 0
end

function bw:write(val, len)
	self.acc = bor(lshift(self.acc, len), val)
	self.bits = self.bits + len
	while self.bits >= 8 do
		self.bits = self.bits - 8
		self.len = self.len + 1
		self.buf[self.len] = band(rshift(self.acc, self.bits), 0xFF)
	end
end

function bw:flush()
	if self.bits > 0 then
		self.len = self.len + 1
		self.buf[self.len] = band(lshift(self.acc, 8 - self.bits), 0xFF)
		self.bits = 0
	end
end


--- Step 1: Determine version, ec level and mode for codeword
--- =========================================================

local function get_mode(str)
	if match(str,"^[0-9]+$") then
		return 1
	elseif match(str,"^[0-9A-Z $%%*./:+-]+$") then
		return 2
	else
		return 4
	end
end

local capacity = {
	{  19,   16,   13,    9},{  34,   28,   22,   16},{  55,   44,   34,   26},{  80,   64,   48,   36},
	{ 108,   86,   62,   46},{ 136,  108,   76,   60},{ 156,  124,   88,   66},{ 194,  154,  110,   86},
	{ 232,  182,  132,  100},{ 274,  216,  154,  122},{ 324,  254,  180,  140},{ 370,  290,  206,  158},
	{ 428,  334,  244,  180},{ 461,  365,  261,  197},{ 523,  415,  295,  223},{ 589,  453,  325,  253},
	{ 647,  507,  367,  283},{ 721,  563,  397,  313},{ 795,  627,  445,  341},{ 861,  669,  485,  385},
	{ 932,  714,  512,  406},{1006,  782,  568,  442},{1094,  860,  614,  464},{1174,  914,  664,  514},
	{1276, 1000,  718,  538},{1370, 1062,  754,  596},{1468, 1128,  808,  628},{1531, 1193,  871,  661},
	{1631, 1267,  911,  701},{1735, 1373,  985,  745},{1843, 1455, 1033,  793},{1955, 1541, 1115,  845},
	{2071, 1631, 1171,  901},{2191, 1725, 1231,  961},{2306, 1812, 1286,  986},{2434, 1914, 1354, 1054},
	{2566, 1992, 1426, 1096},{2702, 2102, 1502, 1142},{2812, 2216, 1582, 1222},{2956, 2334, 1666, 1276},
}

local function get_version_eclevel(len,mode,requested_ec_level)
	local local_mode = mode
	if mode == 4 then local_mode = 3 elseif mode == 8 then local_mode = 4 end
	assert(local_mode <= 4)

	local bits, digits, modebits, c
	local tab = { {10,9,8,8},{12,11,16,10},{14,13,16,12} }
	local minversion = 99
	local maxec_level = requested_ec_level or 1
	local minlv, maxlv = 1, 4
	if requested_ec_level and requested_ec_level >= 1 and requested_ec_level <= 4 then
		minlv = requested_ec_level
		maxlv = requested_ec_level
	end
	for ec_level = minlv, maxlv do
		for version = 1, #capacity do
			bits = capacity[version][ec_level] * 8 - 4
			if version < 10 then
				digits = tab[1][local_mode]
			elseif version < 27 then
				digits = tab[2][local_mode]
			elseif version <= 40 then
				digits = tab[3][local_mode]
			end
			modebits = bits - digits
			if local_mode == 1 then -- numeric
				c = floor(modebits * 3 / 10)
			elseif local_mode == 2 then -- alphanumeric
				c = floor(modebits * 2 / 11)
			elseif local_mode == 3 then -- binary
				c = floor(modebits * 1 / 8)
			else
				c = floor(modebits * 1 / 13)
			end

			if c >= len then
				if version <= minversion then
					minversion = version
					maxec_level = ec_level
				end
				break
			end
		end
	end
	assert(minversion<=40, "Data too long to encode in QR code")
	return minversion, maxec_level
end

local function write_length(str_len, version, mode)
	local i = mode
	if mode == 4 then
		i = 3
	elseif mode == 8 then
		i = 4
	end
	local tab = { {10,9,8,8},{12,11,16,10},{14,13,16,12} }
	local digits
	if version < 10 then
		digits = tab[1][i]
	elseif version < 27 then
		digits = tab[2][i]
	elseif version <= 40 then
		digits = tab[3][i]
	end
	bw:write(str_len, digits)
end


--- Step 2: Encode data
--- ===================

local asciitbl = {
	    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
	-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
	36, -1, -1, -1, 37, 38, -1, -1, -1, -1, 39, 40, -1, 41, 42, 43,
	 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 44, -1, -1, -1, -1, -1,
	-1, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24,
	25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, -1, -1, -1, -1, -1,
}

local function encode_data(str, mode)
	local str_len = #str
	if mode == 1 then
		local i = 1
		while i <= str_len do
			local rem = str_len - i + 1
			if rem >= 3 then
				local v = (byte(str, i) - 48) * 100 + (byte(str, i+1) - 48) * 10 + (byte(str, i+2) - 48)
				bw:write(v, 10)
				i = i + 3
			elseif rem == 2 then
				local v = (byte(str, i) - 48) * 10 + (byte(str, i+1) - 48)
				bw:write(v, 7)
				i = i + 2
			else
				local v = byte(str, i) - 48
				bw:write(v, 4)
				i = i + 1
			end
		end
	elseif mode == 2 then
		local i = 1
		while i <= str_len do
			local rem = str_len - i + 1
			if rem >= 2 then
				local v = asciitbl[byte(str, i)] * 45 + asciitbl[byte(str, i+1)]
				bw:write(v, 11)
				i = i + 2
			else
				bw:write(asciitbl[byte(str, i)], 6)
				i = i + 1
			end
		end
	elseif mode == 4 then
		for i = 1, str_len do
			bw:write(byte(str, i), 8)
		end
	end
end

local function add_pad_data(version, ec_level)
	local cpty = capacity[version][ec_level] * 8
	local current_bits = bw.len * 8 + bw.bits
	local count_to_pad = min(4, cpty - current_bits)
	if count_to_pad > 0 then
		bw:write(0, count_to_pad)
	end
	bw:flush()
	local remaining_bytes = floor(cpty / 8) - bw.len
	for i = 1, remaining_bytes do
		bw.len = bw.len + 1
		bw.buf[bw.len] = i % 2 == 1 and 236 or 17
	end
end


--- Step 3: Organize data and calculate error correction code
--- =========================================================

local alpha_int = {
	[0] = 1,
	  2,   4,   8,  16,  32,  64, 128,  29,  58, 116, 232, 205, 135,  19,  38,  76,
	152,  45,  90, 180, 117, 234, 201, 143,   3,   6,  12,  24,  48,  96, 192, 157,
	 39,  78, 156,  37,  74, 148,  53, 106, 212, 181, 119, 238, 193, 159,  35,  70,
	140,   5,  10,  20,  40,  80, 160,  93, 186, 105, 210, 185, 111, 222, 161,  95,
	190,  97, 194, 153,  47,  94, 188, 101, 202, 137,  15,  30,  60, 120, 240, 253,
	231, 211, 187, 107, 214, 177, 127, 254, 225, 223, 163,  91, 182, 113, 226, 217,
	175,  67, 134,  17,  34,  68, 136,  13,  26,  52, 104, 208, 189, 103, 206, 129,
	 31,  62, 124, 248, 237, 199, 147,  59, 118, 236, 197, 151,  51, 102, 204, 133,
	 23,  46,  92, 184, 109, 218, 169,  79, 158,  33,  66, 132,  21,  42,  84, 168,
	 77, 154,  41,  82, 164,  85, 170,  73, 146,  57, 114, 228, 213, 183, 115, 230,
	209, 191,  99, 198, 145,  63, 126, 252, 229, 215, 179, 123, 246, 241, 255, 227,
	219, 171,  75, 150,  49,  98, 196, 149,  55, 110, 220, 165,  87, 174,  65, 130,
	 25,  50, 100, 200, 141,   7,  14,  28,  56, 112, 224, 221, 167,  83, 166,  81,
	162,  89, 178, 121, 242, 249, 239, 195, 155,  43,  86, 172,  69, 138,   9,  18,
	 36,  72, 144,  61, 122, 244, 245, 247, 243, 251, 235, 203, 139,  11,  22,  44,
	 88, 176, 125, 250, 233, 207, 131,  27,  54, 108, 216, 173,  71, 142,   0,   0
}

local int_alpha = {
	[0] = 256, -- special value
	0,   1,  25,   2,  50,  26, 198,   3, 223,  51, 238,  27, 104, 199,  75,   4,
	100, 224,  14,  52, 141, 239, 129,  28, 193, 105, 248, 200,   8,  76, 113,   5,
	138, 101,  47, 225,  36,  15,  33,  53, 147, 142, 218, 240,  18, 130,  69,  29,
	181, 194, 125, 106,  39, 249, 185, 201, 154,   9, 120,  77, 228, 114, 166,   6,
	191, 139,  98, 102, 221,  48, 253, 226, 152,  37, 179,  16, 145,  34, 136,  54,
	208, 148, 206, 143, 150, 219, 189, 241, 210,  19,  92, 131,  56,  70,  64,  30,
	 66, 182, 163, 195,  72, 126, 110, 107,  58,  40,  84, 250, 133, 186,  61, 202,
	 94, 155, 159,  10,  21, 121,  43,  78, 212, 229, 172, 115, 243, 167,  87,   7,
	112, 192, 247, 140, 128,  99,  13, 103,  74, 222, 237,  49, 197, 254,  24, 227,
	165, 153, 119,  38, 184, 180, 124,  17,  68, 146, 217,  35,  32, 137,  46,  55,
	 63, 209,  91, 149, 188, 207, 205, 144, 135, 151, 178, 220, 252, 190,  97, 242,
	 86, 211, 171,  20,  42,  93, 158, 132,  60,  57,  83,  71, 109,  65, 162,  31,
	 45,  67, 216, 183, 123, 164, 118, 196,  23,  73, 236, 127,  12, 111, 246, 108,
	161,  59,  82,  41, 157,  85, 170, 251,  96, 134, 177, 187, 204,  62,  90, 203,
	 89,  95, 176, 156, 169, 160,  81,  11, 245,  22, 235, 122, 117,  44, 215,  79,
	174, 213, 233, 230, 231, 173, 232, 116, 214, 244, 234, 168,  80,  88, 175
}

local generator_polynomial = {
	 [7] = { 21, 102, 238, 149, 146, 229,  87,   0},
	[10] = { 45,  32,  94,  64,  70, 118,  61,  46,  67, 251,   0 },
	[13] = { 78, 140, 206, 218, 130, 104, 106, 100,  86, 100, 176, 152,  74,   0 },
	[15] = {105,  99,   5, 124, 140, 237,  58,  58,  51,  37, 202,  91,  61, 183,   8,   0},
	[16] = {120, 225, 194, 182, 169, 147, 191,  91,   3,  76, 161, 102, 109, 107, 104, 120,   0},
	[17] = {136, 163, 243,  39, 150,  99,  24, 147, 214, 206, 123, 239,  43,  78, 206, 139,  43,   0},
	[18] = {153,  96,  98,   5, 179, 252, 148, 152, 187,  79, 170, 118,  97, 184,  94, 158, 234, 215,   0},
	[20] = {190, 188, 212, 212, 164, 156, 239,  83, 225, 221, 180, 202, 187,  26, 163,  61,  50,  79,  60,  17,   0},
	[22] = {231, 165, 105, 160, 134, 219,  80,  98, 172,   8,  74, 200,  53, 221, 109,  14, 230,  93, 242, 247, 171, 210,   0},
	[24] = { 21, 227,  96,  87, 232, 117,   0, 111, 218, 228, 226, 192, 152, 169, 180, 159, 126, 251, 117, 211,  48, 135, 121, 229,   0},
	[26] = { 70, 218, 145, 153, 227,  48, 102,  13, 142, 245,  21, 161,  53, 165,  28, 111, 201, 145,  17, 118, 182, 103,   2, 158, 125, 173,   0},
	[28] = {123,   9,  37, 242, 119, 212, 195,  42,  87, 245,  43,  21, 201, 232,  27, 205, 147, 195, 190, 110, 180, 108, 234, 224, 104, 200, 223, 168,   0},
	[30] = {180, 192,  40, 238, 216, 251,  37, 156, 130, 224, 193, 226, 173,  42, 125, 222,  96, 239,  86, 110,  48,  50, 182, 179,  31, 216, 152, 145, 173, 41, 0}
}

--[=[
local function calculate_error_correction(data, data_offset, len_message, num_ec_codewords, out_array, out_offset)
	local highest_exponent = len_message + num_ec_codewords - 1
	for i = 1, len_message do
		mp_int[highest_exponent - i + 1] = data[data_offset + i - 1]
	end
	for i = 1, highest_exponent - len_message do
		mp_int[i] = 0
	end
	mp_int[0] = 0

	local gp = generator_polynomial[num_ec_codewords]

	while highest_exponent >= num_ec_codewords do
		local exp = int_alpha[mp_int[highest_exponent]]
		if exp ~= 256 then
            -- Reverted to induction-variable arithmetic to prevent LuaJIT trace desync on large EC blocks
            for j = highest_exponent, highest_exponent - num_ec_codewords, -1 do
                local gp_val = gp[j - highest_exponent + num_ec_codewords + 1]
                local combined = (gp_val + exp) % 255
                mp_int[j] = bxor(alpha_int[combined], mp_int[j])
			end
		end
		for i = highest_exponent, num_ec_codewords, -1 do
			if mp_int[i] == 0 then
				highest_exponent = i - 1
            else
                break
			end
		end
		if highest_exponent < num_ec_codewords then break end
	end

	for i = 1, num_ec_codewords do
		out_array[out_offset + i - 1] = mp_int[num_ec_codewords - i]
	end
end
]=]
-- This is mathematically the same function as above, but LuaJIT fares better here,
-- it uses more computations but it is more predictable thus, faster performance
local function calculate_error_correction(data, data_offset, len_message, num_ec_codewords, out_array, out_offset)
    -- Clear the shift register (mp_int[0] is x^0, mp_int[num_ec_codewords - 1] is x^(n-1))
    for i = 0, num_ec_codewords - 1 do
        mp_int[i] = 0
    end

    local gp = generator_polynomial[num_ec_codewords]
    -- Process every single data byte (strict shift register, no skipping zeros)
    for i = 0, len_message - 1 do
        local data_byte = data[data_offset + i]
        -- The MSB of the remainder is at the top of the register
        local msb = mp_int[num_ec_codewords - 1]
        local feedback = bxor(msb, data_byte)

        -- Shift the register left (multiply by x)
        for j = num_ec_codewords - 1, 1, -1 do
            mp_int[j] = mp_int[j - 1]
        end
        mp_int[0] = 0

        -- Subtract (XOR) the generator polynomial if feedback is non-zero
        if feedback ~= 0 then
            local exp = int_alpha[feedback]
            for j = 0, num_ec_codewords - 1 do
                -- gp[j+1] holds the exponent for x^j
                local gp_val = gp[j + 1]
                local combined = gp_val + exp

                -- Explicit Galois wrap to match C bounds
                if combined >= 255 then
                    combined = combined - 255
                end

                mp_int[j] = bxor(mp_int[j], alpha_int[combined])
            end
        end
    end
    -- Flush the final remainder to the output buffer
    -- out_array[0] gets the MSB (x^(n-1)), out_array[n-1] gets the LSB (x^0)
    for i = 0, num_ec_codewords - 1 do
        out_array[out_offset + i] = mp_int[num_ec_codewords - 1 - i]
    end
end

local ecblocks = {
	{{  1,{ 26, 19, 2}                 },   {  1,{26,16, 4}},                  {  1,{26,13, 6}},                  {  1, {26, 9, 8}               }},
	{{  1,{ 44, 34, 4}                 },   {  1,{44,28, 8}},                  {  1,{44,22,11}},                  {  1, {44,16,14}               }},
	{{  1,{ 70, 55, 7}                 },   {  1,{70,44,13}},                  {  2,{35,17, 9}},                  {  2, {35,13,11}               }},
	{{  1,{100, 80,10}                 },   {  2,{50,32, 9}},                  {  2,{50,24,13}},                  {  4, {25, 9, 8}               }},
	{{  1,{134,108,13}                 },   {  2,{67,43,12}},                  {  2,{33,15, 9},  2,{34,16, 9}},   {  2, {33,11,11},  2,{34,12,11}}},
	{{  2,{ 86, 68, 9}                 },   {  4,{43,27, 8}},                  {  4,{43,19,12}},                  {  4, {43,15,14}               }},
	{{  2,{ 98, 78,10}                 },   {  4,{49,31, 9}},                  {  2,{32,14, 9},  4,{33,15, 9}},   {  4, {39,13,13},  1,{40,14,13}}},
	{{  2,{121, 97,12}                 },   {  2,{60,38,11},  2,{61,39,11}},   {  4,{40,18,11},  2,{41,19,11}},   {  4, {40,14,13},  2,{41,15,13}}},
	{{  2,{146,116,15}                 },   {  3,{58,36,11},  2,{59,37,11}},   {  4,{36,16,10},  4,{37,17,10}},   {  4, {36,12,12},  4,{37,13,12}}},
	{{  2,{ 86, 68, 9},  2,{ 87, 69, 9}},   {  4,{69,43,13},  1,{70,44,13}},   {  6,{43,19,12},  2,{44,20,12}},   {  6, {43,15,14},  2,{44,16,14}}},
	{{  4,{101, 81,10}                 },   {  1,{80,50,15},  4,{81,51,15}},   {  4,{50,22,14},  4,{51,23,14}},   {  3, {36,12,12},  8,{37,13,12}}},
	{{  2,{116, 92,12},  2,{117, 93,12}},   {  6,{58,36,11},  2,{59,37,11}},   {  4,{46,20,13},  6,{47,21,13}},   {  7, {42,14,14},  4,{43,15,14}}},
	{{  4,{133,107,13}                 },   {  8,{59,37,11},  1,{60,38,11}},   {  8,{44,20,12},  4,{45,21,12}},   { 12, {33,11,11},  4,{34,12,11}}},
	{{  3,{145,115,15},  1,{146,116,15}},   {  4,{64,40,12},  5,{65,41,12}},   { 11,{36,16,10},  5,{37,17,10}},   { 11, {36,12,12},  5,{37,13,12}}},
	{{  5,{109, 87,11},  1,{110, 88,11}},   {  5,{65,41,12},  5,{66,42,12}},   {  5,{54,24,15},  7,{55,25,15}},   { 11, {36,12,12},  7,{37,13,12}}},
	{{  5,{122, 98,12},  1,{123, 99,12}},   {  7,{73,45,14},  3,{74,46,14}},   { 15,{43,19,12},  2,{44,20,12}},   {  3, {45,15,15}, 13,{46,16,15}}},
	{{  1,{135,107,14},  5,{136,108,14}},   { 10,{74,46,14},  1,{75,47,14}},   {  1,{50,22,14}, 15,{51,23,14}},   {  2, {42,14,14}, 17,{43,15,14}}},
	{{  5,{150,120,15},  1,{151,121,15}},   {  9,{69,43,13},  4,{70,44,13}},   { 17,{50,22,14},  1,{51,23,14}},   {  2, {42,14,14}, 19,{43,15,14}}},
	{{  3,{141,113,14},  4,{142,114,14}},   {  3,{70,44,13}, 11,{71,45,13}},   { 17,{47,21,13},  4,{48,22,13}},   {  9, {39,13,13}, 16,{40,14,13}}},
	{{  3,{135,107,14},  5,{136,108,14}},   {  3,{67,41,13}, 13,{68,42,13}},   { 15,{54,24,15},  5,{55,25,15}},   { 15, {43,15,14}, 10,{44,16,14}}},
	{{  4,{144,116,14},  4,{145,117,14}},   { 17,{68,42,13}},                  { 17,{50,22,14},  6,{51,23,14}},   { 19, {46,16,15},  6,{47,17,15}}},
	{{  2,{139,111,14},  7,{140,112,14}},   { 17,{74,46,14}},                  {  7,{54,24,15}, 16,{55,25,15}},   { 34, {37,13,12}               }},
	{{  4,{151,121,15},  5,{152,122,15}},   {  4,{75,47,14}, 14,{76,48,14}},   { 11,{54,24,15}, 14,{55,25,15}},   { 16, {45,15,15}, 14,{46,16,15}}},
	{{  6,{147,117,15},  4,{148,118,15}},   {  6,{73,45,14}, 14,{74,46,14}},   { 11,{54,24,15}, 16,{55,25,15}},   { 30, {46,16,15},  2,{47,17,15}}},
	{{  8,{132,106,13},  4,{133,107,13}},   {  8,{75,47,14}, 13,{76,48,14}},   {  7,{54,24,15}, 22,{55,25,15}},   { 22, {45,15,15}, 13,{46,16,15}}},
	{{ 10,{142,114,14},  2,{143,115,14}},   { 19,{74,46,14},  4,{75,47,14}},   { 28,{50,22,14},  6,{51,23,14}},   { 33, {46,16,15},  4,{47,17,15}}},
	{{  8,{152,122,15},  4,{153,123,15}},   { 22,{73,45,14},  3,{74,46,14}},   {  8,{53,23,15}, 26,{54,24,15}},   { 12, {45,15,15}, 28,{46,16,15}}},
	{{  3,{147,117,15}, 10,{148,118,15}},   {  3,{73,45,14}, 23,{74,46,14}},   {  4,{54,24,15}, 31,{55,25,15}},   { 11, {45,15,15}, 31,{46,16,15}}},
	{{  7,{146,116,15},  7,{147,117,15}},   { 21,{73,45,14},  7,{74,46,14}},   {  1,{53,23,15}, 37,{54,24,15}},   { 19, {45,15,15}, 26,{46,16,15}}},
	{{  5,{145,115,15}, 10,{146,116,15}},   { 19,{75,47,14}, 10,{76,48,14}},   { 15,{54,24,15}, 25,{55,25,15}},   { 23, {45,15,15}, 25,{46,16,15}}},
	{{ 13,{145,115,15},  3,{146,116,15}},   {  2,{74,46,14}, 29,{75,47,14}},   { 42,{54,24,15},  1,{55,25,15}},   { 23, {45,15,15}, 28,{46,16,15}}},
	{{ 17,{145,115,15}            	 },   { 10,{74,46,14}, 23,{75,47,14}},   { 10,{54,24,15}, 35,{55,25,15}},   { 19, {45,15,15}, 35,{46,16,15}}},
	{{ 17,{145,115,15},  1,{146,116,15}},   { 14,{74,46,14}, 21,{75,47,14}},   { 29,{54,24,15}, 19,{55,25,15}},   { 11, {45,15,15}, 46,{46,16,15}}},
	{{ 13,{145,115,15},  6,{146,116,15}},   { 14,{74,46,14}, 23,{75,47,14}},   { 44,{54,24,15},  7,{55,25,15}},   { 59, {46,16,15},  1,{47,17,15}}},
	{{ 12,{151,121,15},  7,{152,122,15}},   { 12,{75,47,14}, 26,{76,48,14}},   { 39,{54,24,15}, 14,{55,25,15}},   { 22, {45,15,15}, 41,{46,16,15}}},
	{{  6,{151,121,15}, 14,{152,122,15}},   {  6,{75,47,14}, 34,{76,48,14}},   { 46,{54,24,15}, 10,{55,25,15}},   {  2, {45,15,15}, 64,{46,16,15}}},
	{{ 17,{152,122,15},  4,{153,123,15}},   { 29,{74,46,14}, 14,{75,47,14}},   { 49,{54,24,15}, 10,{55,25,15}},   { 24, {45,15,15}, 46,{46,16,15}}},
	{{  4,{152,122,15}, 18,{153,123,15}},   { 13,{74,46,14}, 32,{75,47,14}},   { 48,{54,24,15}, 14,{55,25,15}},   { 42, {45,15,15}, 32,{46,16,15}}},
	{{ 20,{147,117,15},  4,{148,118,15}},   { 40,{75,47,14},  7,{76,48,14}},   { 43,{54,24,15}, 22,{55,25,15}},   { 10, {45,15,15}, 67,{46,16,15}}},
	{{ 19,{148,118,15},  6,{149,119,15}},   { 18,{75,47,14}, 31,{76,48,14}},   { 34,{54,24,15}, 34,{55,25,15}},   { 20, {45,15,15}, 61,{46,16,15}}}
}

local function arrange_codewords_and_calculate_ec(version, ec_level, data)
	local blocks = ecblocks[version][ec_level]
	local num_blocks
	local data_pos = 1
	local ec_pos = 1
	local max_data_len = 0
	local max_ec_len = 0

	local block_idx = 1
	for i = 1, #blocks / 2 do
		local count = blocks[2*i - 1]
		local size_datablock = blocks[2*i][2]
		local size_ecblock = blocks[2*i][1] - size_datablock

		max_data_len = max(max_data_len, size_datablock)
		max_ec_len = max(max_ec_len, size_ecblock)

		for _ = 1, count do
			block_data_offsets[block_idx] = data_pos
			block_data_lens[block_idx] = size_datablock

			block_ec_offsets[block_idx] = ec_pos
			block_ec_lens[block_idx] = size_ecblock

			calculate_error_correction(data, data_pos, size_datablock, size_ecblock, ec_blocks_cache, ec_pos)

			data_pos = data_pos + size_datablock
			ec_pos = ec_pos + size_ecblock
			block_idx = block_idx + 1
		end
	end
	num_blocks = block_idx - 1

	local out_len = 0
	for p = 1, max_data_len do
		for b = 1, num_blocks do
			if p <= block_data_lens[b] then
				out_len = out_len + 1
				arranged_data[out_len] = data[block_data_offsets[b] + p - 1]
			end
		end
	end

	for p = 1, max_ec_len do
		for b = 1, num_blocks do
			if p <= block_ec_lens[b] then
				out_len = out_len + 1
				arranged_data[out_len] = ec_blocks_cache[block_ec_offsets[b] + p - 1]
			end
		end
	end

	return out_len
end


--- Step 4: Generate matrices via scratchpad and calculate penalty
--- ===============================================================

local alignment_pattern = {
	{},{6,18},{6,22},{6,26},{6,30},{6,34},
	{6,22,38},{6,24,42},{6,26,46},{6,28,50},{6,30,54},{6,32,58},{6,34,62},
	{6,26,46,66},{6,26,48,70},{6,26,50,74},{6,30,54,78},{6,30,56,82},{6,30,58,86},{6,34,62,90},
	{6,28,50,72,94},{6,26,50,74,98},{6,30,54,78,102},{6,28,54,80,106},{6,32,58,84,110},{6,30,58,86,114},{6,34,62,90,118},
	{6,26,50,74,98 ,122},{6,30,54,78,102,126},{6,26,52,78,104,130},{6,30,56,82,108,134},{6,34,60,86,112,138},{6,30,58,86,114,142},{6,34,62,90,118,146},
	{6,30,54,78,102,126,150}, {6,24,50,76,102,128,154},{6,28,54,80,106,132,158},{6,32,58,84,110,136,162},{6,26,54,82,110,138,166},{6,30,58,86,114,142,170}
}

local typeinfo = {
	{ [0] = "111011111000100", "111001011110011", "111110110101010", "111100010011101", "110011000101111", "110001100011000", "110110001000001", "110100101110110" },
	{ [0] = "101010000010010", "101000100100101", "101111001111100", "101101101001011", "100010111111001", "100000011001110", "100111110010111", "100101010100000" },
	{ [0] = "011010101011111", "011000001101000", "011111100110001", "011101000000110", "010010010110100", "010000110000011", "010111011011010", "010101111101101" },
	{ [0] = "001011010001001", "001001110111110", "001110011100111", "001100111010000", "000011101100010", "000001001010101", "000110100001100", "000100000111011" }
}

local function add_typeinfo_to_matrix(matrix, size, ec_level, mask)
	local ec_mask_type = typeinfo[ec_level][mask]
	local bit_val
	for i = 1, 7 do
		bit_val = sub(ec_mask_type, i, i) == "1" and 2 or -2
		set_cell(matrix, size, 9, size - i + 1, bit_val)
	end
	for i = 8, 9 do
		bit_val = sub(ec_mask_type, i, i) == "1" and 2 or -2
		set_cell(matrix, size, 9, 17 - i, bit_val)
	end
	for i = 10, 15 do
		bit_val = sub(ec_mask_type, i, i) == "1" and 2 or -2
		set_cell(matrix, size, 9, 16 - i, bit_val)
	end
	for i = 1, 6 do
		bit_val = sub(ec_mask_type, i, i) == "1" and 2 or -2
		set_cell(matrix, size, i, 9, bit_val)
	end
	bit_val = sub(ec_mask_type, 7, 7) == "1" and 2 or -2
	set_cell(matrix, size, 8, 9, bit_val)
	for i = 8, 15 do
		bit_val = sub(ec_mask_type, i, i) == "1" and 2 or -2
		set_cell(matrix, size, size - 15 + i, 9, bit_val)
	end
end

local version_information = {
	"001010010011111000", "001111011010000100", "100110010101100100", "110010110010010100",
	"011011111101110100", "010001101110001100", "111000100001101100", "101100000110011100", "000101001001111100",
	"000111101101000010", "101110100010100010", "111010000101010010", "010011001010110010", "011001011001001010",
	"110000010110101010", "100100110001011010", "001101111110111010", "001000110111000110", "100001111000100110",
	"110101011111010110", "011100010000110110", "010110000011001110", "111111001100101110", "101011101011011110",
	"000010100100111110", "101010111001000001", "000011110110100001", "010111010001010001", "111110011110110001",
	"110100001101001001", "011101000010101001", "001001100101011001", "100000101010111001", "100101100011000101",
}

local function add_version_information(matrix, version, size)
	if version < 7 then return end
	local bitstring = version_information[version - 6]
	local x, y, bit_val
	local start_x = size - 10
	local start_y = 1
	for i = 1, #bitstring do
		bit_val = sub(bitstring, i, i) == "1" and 2 or -2
		x = start_x + (i - 1) % 3
		y = start_y + floor((i - 1) / 3)
		set_cell(matrix, size, x, y, bit_val)
	end
	start_x = 1
	start_y = size - 10
	for i = 1, #bitstring do
		bit_val = sub(bitstring, i, i) == "1" and 2 or -2
		x = start_x + floor((i - 1) / 3)
		y = start_y + (i - 1) % 3
		set_cell(matrix, size, x, y, bit_val)
	end
end

local function generate_base_matrix(version)
	local size = version * 4 + 17
	local len = size * size

	ffi.fill(base_matrix, len + 1, 0)

	for i = 1, 8 do
		for j = 1, 8 do
			set_cell(base_matrix, size, i, j, -2)
			set_cell(base_matrix, size, size - 8 + i, j, -2)
			set_cell(base_matrix, size, i, size - 8 + j, -2)
		end
	end

	for i = 1, 7 do
		set_cell(base_matrix, size, 1, i, 2); set_cell(base_matrix, size, 7, i, 2)
		set_cell(base_matrix, size, i, 1, 2); set_cell(base_matrix, size, i, 7, 2)
		set_cell(base_matrix, size, size, i, 2); set_cell(base_matrix, size, size - 6, i, 2)
		set_cell(base_matrix, size, size - i + 1, 1, 2); set_cell(base_matrix, size, size - i + 1, 7, 2)
		set_cell(base_matrix, size, 1, size - i + 1, 2); set_cell(base_matrix, size, 7, size - i + 1, 2)
		set_cell(base_matrix, size, i, size - 6, 2); set_cell(base_matrix, size, i, size, 2)
	end

	for i = 1, 3 do
		for j = 1, 3 do
			set_cell(base_matrix, size, 2 + j, i + 2, 2)
			set_cell(base_matrix, size, size - j - 1, i + 2, 2)
			set_cell(base_matrix, size, 2 + j, size - i - 1, 2)
		end
	end

	for i = 9, size - 8 do
		set_cell(base_matrix, size, i, 7, i % 2 == 0 and -2 or 2)
		set_cell(base_matrix, size, 7, i, i % 2 == 0 and -2 or 2)
	end

	add_version_information(base_matrix, version, size)
	set_cell(base_matrix, size, 9, size - 7, 2)

	local ap = alignment_pattern[version]
	for x = 1, #ap do
		for y = 1, #ap do
			if not (x == 1 and y == 1 or x == #ap and y == 1 or x == 1 and y == #ap) then
				local pos_x, pos_y = ap[x] + 1, ap[y] + 1
				for dy = -2, 2 do
					for dx = -2, 2 do
						set_cell(base_matrix, size, pos_x + dx, pos_y + dy, max(abs(dx), abs(dy)) % 2 == 0 and 2 or -2)
					end
				end
			end
		end
	end

	return size
end

local maskFunc = {
	[0]=function(x,y) return (y+x)%2==0 end,
	function(_,y) return y%2==0 end,
	function(x,_) return x%3==0 end,
	function(x,y) return (y+x)%3==0 end,
	function(x,y) return (y%4-1.5)*(x%6-2.5)>0 end, -- optimized for not using math.floor (too slow) or // operation (new Lua only)
	function(x,y) return (y*x)%2+(y*x)%3==0 end,
	function(x,y) return ((y*x)%3+y*x)%2==0 end,
	function(x,y) return ((y*x)%3+y+x)%2==0 end,
}

local function popcount32(x)
	x = x - band(rshift(x, 1), 0x55555555)
	x = band(x, 0x33333333) + band(rshift(x, 2), 0x33333333)
	x = band(x + rshift(x, 4), 0x0F0F0F0F)

    -- Cascade the byte sums:
    -- Byte 0 gets Byte 0 + Byte 1, Byte 2 gets Byte 2 + Byte 3
    x = x + rshift(x, 8)
    -- Byte 0 gets (Byte 0 + Byte 1) + (Byte 2 + Byte 3)
    x = x + rshift(x, 16)

    -- The maximum possible popcount is 32, which fits in 6 bits.
    -- A single mask strips away the junk data in the upper bytes.
    return band(x, 0x3F)
end

-- SWAR penalty scratch: c_bb holds per-word "differs from left" bits,
-- T_base/T_scratch are transposed boards for the vertical pass.
local c_bb      = ffi.new("uint32_t[?]", MAX_BB_LEN)
local T_base    = ffi.new("uint32_t[?]", MAX_BB_LEN)
local T_scratch = ffi.new("uint32_t[?]", MAX_BB_LEN)
local tr_buf    = ffi.new("uint32_t[?]", 32)

local sz_cache = {}

local function make_mask(min_b, max_b)
	local mask = 0
	if min_b <= max_b then
		min_b = max(0, min_b)
		max_b = min(31, max_b)
		for i = min_b, max_b do
			mask = bor(mask, lshift(1, i))
		end
	end
	return mask
end

local function get_size_masks(size, stride, padding)
	local key = size * 100 + padding
	local e = sz_cache[key]
	if e then return e end
	e = { v5 = {}, m3A = {}, m3B = {} }
	local end_idx = padding + size - 1
	for w = 0, stride - 1 do
		local w_off = w * 32
		-- v5 (P1): Run of 5 must be entirely inside the symbol
		e.v5[w] = make_mask(padding - w_off, end_idx - 4 - w_off)

		-- m3A (P3 TA): 11-bit pattern 00001011101. 1s are at offsets +4 to +10.
		-- The 1s must be inside, meaning start bit 'b' can overhang into the left padding by up to 4.
		e.m3A[w] = make_mask(padding - 4 - w_off, end_idx - 10 - w_off)

		-- m3B (P3 TB): 11-bit pattern 10111010000. 1s are at offsets +0 to +6.
		e.m3B[w] = make_mask(padding - w_off, end_idx - 6 - w_off)
	end
	sz_cache[key] = e
	return e
end

local p2_mask_cache = {}
local function get_p2_masks(size, stride, padding)
	local e = p2_mask_cache[size]
	if e then return e end
	e = {}
	for w = 0, stride - 1 do
		local start_bit = padding - w * 32
		local end_bit = padding + size - 2 - w * 32
		e[w] = make_mask(start_bit, end_bit)
	end
	p2_mask_cache[size] = e
	return e
end

local function transpose32()
	local a, b, t
	for k = 0, 15 do
		a, b = tr_buf[k], tr_buf[k + 16]
		t = band(bxor(rshift(a, 16), b), 0x0000FFFF)
		tr_buf[k + 16] = bxor(b, t)
		tr_buf[k] = bxor(a, lshift(t, 16))
	end
	for base = 0, 16, 16 do
		for r = 0, 7 do
			local k = base + r
			a, b = tr_buf[k], tr_buf[k + 8]
			t = band(bxor(rshift(a, 8), b), 0x00FF00FF)
			tr_buf[k + 8] = bxor(b, t)
			tr_buf[k] = bxor(a, lshift(t, 8))
		end
	end
	for base = 0, 24, 8 do
		for r = 0, 3 do
			local k = base + r
			a, b = tr_buf[k], tr_buf[k + 4]
			t = band(bxor(rshift(a, 4), b), 0x0F0F0F0F)
			tr_buf[k + 4] = bxor(b, t)
			tr_buf[k] = bxor(a, lshift(t, 4))
		end
	end
	for base = 0, 28, 4 do
		for r = 0, 1 do
			local k = base + r
			a, b = tr_buf[k], tr_buf[k + 2]
			t = band(bxor(rshift(a, 2), b), 0x33333333)
			tr_buf[k + 2] = bxor(b, t)
			tr_buf[k] = bxor(a, lshift(t, 2))
		end
	end
	for base = 0, 30, 2 do
		a, b = tr_buf[base], tr_buf[base + 1]
		t = band(bxor(rshift(a, 1), b), 0x55555555)
		tr_buf[base + 1] = bxor(b, t)
		tr_buf[base] = bxor(a, lshift(t, 1))
	end
end

local function transpose_bb(src, dst, size, stride)
	for bx = 0, stride - 1 do
		for by = 0, stride - 1 do
			local navail = size - by * 32
			if navail > 32 then navail = 32 end
			for r = 0, 31 do
				tr_buf[r] = r < navail and src[(by * 32 + r) * stride + bx] or 0
			end
			transpose32()
			for c = 0, 31 do
				local row = bx * 32 + c
				if row < size then dst[row * stride + by] = tr_buf[c] end
			end
		end
	end
end

local function scan_p1p3(bb, size, stride, padding, sm)
	local v5, m3A, m3B = sm.v5, sm.m3A, sm.m3B
	local w_end = stride - 1
	local p1, p3 = 0, 0

	for y = padding, padding + size - 1 do
		local off = y * stride
		local prev31 = 0
		for w = 0, w_end do
			local b = bb[off + w]
			if w == 0 then
				c_bb[off + w] = bor(bxor(b, lshift(b, 1)), 1)
			else
				c_bb[off + w] = bxor(b, bor(lshift(b, 1), prev31))
			end
			prev31 = rshift(b, 31)
		end

		c_bb[off] = bor(c_bb[off], lshift(1, padding))

		for w = 0, w_end do
			local c = c_bb[off + w]
			local z1 = bor(bor(rshift(c, 1), rshift(c, 2)), bor(rshift(c, 3), rshift(c, 4)))
			if w < w_end then
				local cx = c_bb[off + w + 1]
				z1 = bor(z1, lshift(cx, 28), lshift(cx, 29), lshift(cx, 30), lshift(cx, 31))
			end
			local A = band(v5[w], bxor(z1, -1))
			p1 = p1 + popcount32(A) + 2 * popcount32(band(A, c))

			local b = bb[off + w]
			local bnext = w < w_end and bb[off + w + 1] or 0
			local s0 = b
			local s1 = bor(rshift(b, 1), lshift(bnext, 31))
			local s2 = bor(rshift(b, 2), lshift(bnext, 30))
			local s3 = bor(rshift(b, 3), lshift(bnext, 29))
			local s4 = bor(rshift(b, 4), lshift(bnext, 28))
			local s5 = bor(rshift(b, 5), lshift(bnext, 27))
			local s6 = bor(rshift(b, 6), lshift(bnext, 26))
			local s7 = bor(rshift(b, 7), lshift(bnext, 25))
			local s8 = bor(rshift(b, 8), lshift(bnext, 24))
			local s9 = bor(rshift(b, 9), lshift(bnext, 23))
			local s10 = bor(rshift(b, 10), lshift(bnext, 22))

			local TA = band(band(band(s4, s6), band(s7, s8)), s10)
			local NA = bor(bor(bor(s0, s1), bor(s2, s3)), bor(s5, s9))

			local TB = band(band(band(s0, s2), band(s3, s4)), s6)
			local NB = bor(bor(bor(s1, s5), bor(s7, s8)), bor(s9, s10))

			p3 = p3 + 40 * popcount32(band(band(TA, bxor(NA, -1)), m3A[w]))
			p3 = p3 + 40 * popcount32(band(band(TB, bxor(NB, -1)), m3B[w]))

			local s11 = bor(rshift(b, 11), lshift(bnext, 21))
			local s12 = bor(rshift(b, 12), lshift(bnext, 20))
			local s13 = bor(rshift(b, 13), lshift(bnext, 19))
			local s14 = bor(rshift(b, 14), lshift(bnext, 18))
			local ND = bor(bor(NA, s11), bor(bor(s12, s13), s14))

			p3 = p3 - 40 * popcount32(band(band(TA, bxor(ND, -1)), m3A[w]))
		end
	end
	return p1, p3
end

local function compute_penalty_components(bb, tbb, padded_size, size, stride, padding)
	local sm = get_size_masks(size, stride, padding)
	local p1, p3 = scan_p1p3(bb, size, stride, padding, sm)
	local p1v, p3v = scan_p1p3(tbb, size, stride, padding, sm)
	p1 = p1 + p1v
	p3 = p3 + p3v

	local p2, dark = 0, 0
	local w_end = stride - 1
	local p2m = get_p2_masks(size, stride, padding)

	for y = padding, padding + size - 1 do
		local offA = y * stride
		for w = 0, w_end do
			dark = dark + popcount32(bb[offA + w])
		end

		if y < padding + size - 1 then
			local offB = offA + stride
			for w = 0, w_end do
				local a = bb[offA + w]
				local b2 = bb[offB + w]
				local d = bor(bor(bxor(a, rshift(a, 1)), bxor(a, b2)), bxor(b2, rshift(b2, 1)))

				p2 = p2 + popcount32(band(bnot(d), p2m[w])) * 3

				local cross_bit = w * 32 + 31
				if cross_bit >= padding and cross_bit <= padding + size - 2 then
					local a31 = band(rshift(a, 31), 1)
					local b31 = band(rshift(b2, 31), 1)
					if a31 == b31 and a31 == band(bb[offA + w + 1], 1) and b31 == band(bb[offB + w + 1], 1) then
						p2 = p2 + 3
					end
				end
			end
		end
	end

	local percent = dark / (size * size) * 100
	local p4 = floor(abs(50 - percent) / 5) * 10
	return p1, p2, p3, p4
end

local function add_typeinfo_both(bb, tbb, size, stride, ec_level, mask, padding)
	local ec_mask_type = typeinfo[ec_level][mask]
	local bit_val
	for i = 1, 7 do
		bit_val = sub(ec_mask_type, i, i) == "1" and 1 or 0
		set_bb_bit(bb, stride, padding + 9, padding + size - i + 1, bit_val)
		set_bb_bit(tbb, stride, padding + size - i + 1, padding + 9, bit_val)
	end
	for i = 8, 9 do
		bit_val = sub(ec_mask_type, i, i) == "1" and 1 or 0
		set_bb_bit(bb, stride, padding + 9, padding + 17 - i, bit_val)
		set_bb_bit(tbb, stride, padding + 17 - i, padding + 9, bit_val)
	end
	for i = 10, 15 do
		bit_val = sub(ec_mask_type, i, i) == "1" and 1 or 0
		set_bb_bit(bb, stride, padding + 9, padding + 16 - i, bit_val)
		set_bb_bit(tbb, stride, padding + 16 - i, padding + 9, bit_val)
	end
	for i = 1, 6 do
		bit_val = sub(ec_mask_type, i, i) == "1" and 1 or 0
		set_bb_bit(bb, stride, padding + i, padding + 9, bit_val)
		set_bb_bit(tbb, stride, padding + 9, padding + i, bit_val)
	end
	bit_val = sub(ec_mask_type, 7, 7) == "1" and 1 or 0
	set_bb_bit(bb, stride, padding + 8, padding + 9, bit_val)
	set_bb_bit(tbb, stride, padding + 9, padding + 8, bit_val)
	for i = 8, 15 do
		bit_val = sub(ec_mask_type, i, i) == "1" and 1 or 0
		set_bb_bit(bb, stride, padding + size - 15 + i, padding + 9, bit_val)
		set_bb_bit(tbb, stride, padding + 9, padding + size - 15 + i, bit_val)
	end
end

local static_cache = {}

local function build_static(version, size, stride, padding, total_words)
	local n_cells = size * size
	local entry = {
		count = 0,
		free = ffi.new("int32_t[?]", n_cells + 1),
		x = ffi.new("int16_t[?]", n_cells + 1),
		y = ffi.new("int16_t[?]", n_cells + 1),
		masks = {},
		t_masks = {},
		fixed = {},
	}
	for m = 0, 7 do entry.masks[m] = ffi.new("uint32_t[?]", total_words) end
	local count = 0
	local x, y = size, size
	local x_dir, y_dir = -1, -1
	while x >= 1 do
		local idx = (y - 1) * size + x
		if base_matrix[idx] == 0 then
			count = count + 1
			entry.free[count] = idx
			entry.x[count] = x - 1
			entry.y[count] = y - 1
		end
		x = x + x_dir
		if x_dir == 1 then
			y = y + y_dir
			if y < 1 or y > size then
				x = x - 2
				if x == 7 then x = 6 end -- jump over timing pattern
				y = y_dir == -1 and 1 or size
				y_dir = -y_dir
			end
		end
		x_dir = -x_dir
	end
	entry.count = count
	for m = 0, 7 do
		local func = maskFunc[m]
		local mb = entry.masks[m]
		for k = 1, count do
			if func(entry.x[k], entry.y[k]) then
				set_bb_bit(mb, stride, entry.x[k] + 1 + padding, entry.y[k] + 1 + padding, 1)
			end
		end
	end
	local padded_size = size + 2 * padding
	for m = 0, 7 do
		transpose_bb(entry.masks[m], T_base, padded_size, stride)
		local tb = ffi.new("uint32_t[?]", total_words)
		ffi.copy(tb, T_base, total_words * 4)
		entry.t_masks[m] = tb
	end
	static_cache[version] = entry
	return entry
end

-- Shared setup: encodes `str`, builds the base (unmasked) bitboards, and
-- returns everything the mask search needs.
local function prepare_boards(str, ec_level, mode_enc)
	local mode_num = mode_enc or get_mode(str)
	local version, ec = get_version_eclevel(#str, mode_num, ec_level)

	bw:reset()
	bw:write(mode_num, 4)
	write_length(#str, version, mode_num)
	encode_data(str, mode_num)
	add_pad_data(version, ec)

	local total_arranged_bytes = arrange_codewords_and_calculate_ec(version, ec, bw.buf)
	local size = generate_base_matrix(version)

	add_typeinfo_to_matrix(base_matrix, size, ec, 0)

	local padding = 4
	local padded_size = size + 2 * padding
	local stride = floor((padded_size + 31) / 32)
	local total_words = padded_size * stride

	local entry = static_cache[version] or build_static(version, size, stride, padding, total_words)
	local count = entry.count

	local fixed_dark = entry.fixed[ec]
	if not fixed_dark then
		fixed_dark = ffi.new("uint32_t[?]", total_words)
		for yi = 1, size do
			local rowbase = (yi - 1) * size
			for xi = 1, size do
				if base_matrix[rowbase + xi] == 2 then
					set_bb_bit(fixed_dark, stride, xi + padding, yi + padding, 1)
				end
			end
		end
		entry.fixed[ec] = fixed_dark
	end

	ffi.copy(bb_base, fixed_dark, total_words * 4)

	local total_bits = total_arranged_bytes * 8
	for k = 1, count do
		local data_bit = 0
		if k <= total_bits then
			local bi = k - 1
			data_bit = band(rshift(arranged_data[floor(bi / 8) + 1], 7 - bi % 8), 1)
		end
		raw_bit[k] = data_bit
		if data_bit == 1 then
			local xx, yy = entry.x[k] + padding, entry.y[k] + padding
			local wi = yy * stride + floor(xx / 32)
			bb_base[wi] = bor(bb_base[wi], lshift(1, xx % 32))
		end
	end

	transpose_bb(bb_base, T_base, padded_size, stride)

	return version, ec, size, padded_size, stride, total_words, entry, padding, total_arranged_bytes
end

local function search_masks(size, padded_size, stride, total_words, ec, entry, padding, is_debug)
	local components = is_debug and {} or nil
	local min_penalty, best_mask = nil, 0
	for mask = 0, 7 do
		local mb = entry.masks[mask]
		local tb = entry.t_masks[mask]
		for i = 0, total_words - 1 do
			bb_scratch[i] = bxor(bb_base[i], mb[i])
			T_scratch[i] = bxor(T_base[i], tb[i])
		end
		add_typeinfo_both(bb_scratch, T_scratch, size, stride, ec, mask, padding)

		local p1, p2, p3, p4 = compute_penalty_components(bb_scratch, T_scratch, padded_size, size, stride, padding)

		if is_debug then
			components[mask] = { p1 = p1, p2 = p2, p3 = p3, p4 = p4 }
		end

		local penalty = p1 + p2 + p3 + p4
		if not min_penalty or penalty < min_penalty then
			min_penalty = penalty
			best_mask = mask
		end
	end
	return best_mask, components
end

local function qrcode(str, ec_level, mode_enc)
	local _, ec, size, padded_size, stride, total_words, entry, padding = prepare_boards(str, ec_level, mode_enc)

	local best_mask = search_masks(size, padded_size, stride, total_words, ec, entry, padding, false)

	local len = size * size
	ffi.copy(best_matrix, base_matrix, len + 1)
	add_typeinfo_to_matrix(best_matrix, size, ec, best_mask)

	local func = maskFunc[best_mask]
	for k = 1, entry.count do
		local data_bit = raw_bit[k]
		if func(entry.x[k], entry.y[k]) then
			data_bit = bxor(data_bit, 1)
		end
		best_matrix[entry.free[k]] = data_bit == 1 and 1 or -1
	end

	return true, best_matrix, size
end

-- Test-facing only: exposes the per-mask components qrcode() computes
-- internally but normally discards, by calling the exact same two
-- functions qrcode() calls.
local function debug_mask_penalties(str, ec_level, mode_enc)
	local version, ec, size, padded_size, stride, total_words, entry, padding, total_arranged_bytes = prepare_boards(str, ec_level, mode_enc)
	local best_mask, components = search_masks(size, padded_size, stride, total_words, ec, entry, padding, true)

	local codewords = {}
	for i = 1, total_arranged_bytes do
		codewords[i] = arranged_data[i]
	end

	return {
		version = version,
		ec = ec,
		components = components,
		best_mask = best_mask,
		codewords = codewords,
	}
end

return {
	qrcode = qrcode,
	_debug_mask_penalties = debug_mask_penalties,
}
