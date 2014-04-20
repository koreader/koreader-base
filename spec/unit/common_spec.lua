
package.path = "common/?.lua;" .. package.path
package.cpath = "common/?.so;" .. package.cpath

local socket = require("socket")
local url = require("socket.url")
local http = require("socket.http")
local https = require("ssl.https")

describe("Common modules", function()
    it("should get response from HTTP request", function()
        local urls = {
            "http://www.google.com",
            "https://www.google.com",
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
end)
