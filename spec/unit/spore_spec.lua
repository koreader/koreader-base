package.path = "common/?.lua;" .. package.path
package.cpath = "common/?.so;" .. package.cpath

local service = [[
{
    "base_url" : "http://services.org:9999/restapi/",
    "name" : "api",
    "methods" : {
        "get_info" : {
            "path" : "/show",
            "method" : "GET",
            "optional_params" : [
                "user",
                "border"
            ],
        },
        "get_user_info" : {
            "path" : "/show",
            "method" : "GET",
            "required_params" : [
                "user"
            ],
            "optional_params" : [
                "border"
            ],
            "required_payload" : true,
            "expected_status" : [ 100, 200 ]
        },
        "action1" : {
            "path" : "/doit?action=action1",
            "method" : "GET",
            "unattended_params" : true
        }
    }
}
]]

describe("Lua Spore modules", function()
    local headers = {}
    package.loaded['socket.http'] = {
        request = function (req) return req, 200, headers, {} end -- mock
    }
    local Spore = require("Spore")
    local client = Spore.new_from_string(service)
    it("should complete http request", function()
        local res = client:get_user_info({payload = 'opaque data', user = 'john'})
        assert.are.same(res.headers, headers)
        client:enable('Format.JSON')
        res = client:get_user_info({payload = 'opaque data', user = 'john'})
        assert.are.same(res.headers, headers)

        package.loaded['Spore.Middleware.Dummy'] = {}
        local dummy_resp = { status = 200 }
        require('Spore.Middleware.Dummy').call = function (self, req)
            return dummy_resp
        end
        client:reset_middlewares()
        client:enable('Dummy')
        res = client:get_info()
        assert.are.same(res, dummy_resp)
        package.loaded['socket.http'] = nil
    end)
end)
