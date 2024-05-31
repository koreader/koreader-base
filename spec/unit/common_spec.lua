package.path = "common/?.lua;" .. package.path
package.cpath = "common/?.so;" .. package.cpath
require("ffi_wrapper")

local url = require("socket.url")
local http = require("socket.http")
local https = require("ssl.https")
local buffer = require("string.buffer")
local Blitbuffer = require("ffi/blitbuffer")

describe("Common modules", function()
    it("should get response from HTTP request #internet", function()
        local urls = {
            "http://www.example.com",
            "https://www.example.com",
        }
        for i=1, #urls do
            local http_scheme = url.parse(urls[i]).scheme == "http"
            local request = http_scheme and http.request or https.request
            local body, code, headers, status = request(urls[i])
            assert.truthy(body)
            assert.are.same(code, 200)
            assert.truthy(headers)
            assert.truthy(status)
        end
    end)
    it("should serialize blitbuffer", function()
        local w, h = 75, 100
        local bb = Blitbuffer.new(w, h)
        local random = math.random
        for i = 0, h -1 do
            for j = 0, w - 1 do
                local color = Blitbuffer.Color4(random(16))
                bb:setPixel(j, i, color)
            end
        end

        local t = {
            w = bb.w,
            h = bb.h,
            stride = tonumber(bb.stride),
            fmt = bb:getType(),
            data = Blitbuffer.tostring(bb),
        }
        local ser = buffer.encode(t)
        local deser = buffer.decode(ser)
        assert.are.same(t, deser)

        local ss = Blitbuffer.fromstring(deser.w, deser.h, deser.fmt, deser.data, deser.stride)
        assert.are.same(bb.w, ss.w)
        assert.are.same(bb.h, ss.h)
        assert.are.same(bb.stride, ss.stride)
        assert.are.same(bb:getType(), ss:getType())
        for i = 0, h - 1 do
            for j = 0, w - 1 do
                local bb_color = bb:getPixel(j, i):getColor4L().a
                local ss_color = ss:getPixel(j, i):getColor4L().a
                assert.are.same(bb_color, ss_color)
            end
        end
    end)
end)
