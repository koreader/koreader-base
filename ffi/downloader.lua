local http = require("socket.http")
local ffi = require("ffi")

local Downloader = {}

function Downloader:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

local function merge_ranges(ranges)
    local new_ranges = {}
    for i, r in ipairs(ranges) do
        if #new_ranges > 0 and new_ranges[#new_ranges][2] == r[1] - 1 then
            new_ranges[#new_ranges][2] = r[2]
        else
            table.insert(new_ranges, r)
        end
    end
    return new_ranges
end

function Downloader:fetch(url, callback, ranges, etag)
    assert(not (ranges and etag))
    local sink = function(s)
        return s and callback(ffi.cast("uint8_t *", s), #s)
    end
    local abort
    local response_headers = function(status_code, resp_headers, status_line)
        if ranges then
            abort = status_code ~= 206
        else
            abort = status_code ~= 200 and status_code ~= 304
        end
        return abort
    end
    local ok, status_code, resp_headers, status_line
    if ranges then
        ranges = merge_ranges(ranges)
        local ranges_index = 1
        repeat
            ok, status_code, resp_headers, status_line = http.request{
                url = url,
                headers = { ["Range"] = string.format("bytes=%u-%u", ranges[ranges_index][1], ranges[ranges_index][2]) },
                response_headers = response_headers,
                sink = sink,
            }
            ok = ok and not abort
            ranges_index = ranges_index + 1
        until abort or not ok or ranges_index > #ranges
        if not ok and status_code == 200 then
            status_line = "server does not support range requests!"
        end
    else
        ok, status_code, resp_headers, status_line = http.request{
            url = url,
            headers = etag and { ["If-None-Match"] = etag },
            response_headers = response_headers,
            sink = sink,
        }
        ok = ok and not abort
    end
    self.headers = resp_headers
    self.etag = resp_headers['etag']
    self.status_code = status_code
    self.err = not ok and (status_line or status_code) or nil
    return ok
end

return Downloader
