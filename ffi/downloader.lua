local http = require("socket.http")
local ffi = require("ffi")

local Downloader = {}

function Downloader:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Downloader:free()
    self.ce:free()
    self.ce = nil
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

function Downloader:fetch(url, callback, ranges, etag, stats)
    assert(not (ranges and etag))
    self.status_code = nil
    self.etag = nil
    local ok
    local sink = function(s)
        return s and callback(ffi.cast("uint8_t *", s), #s)
    end
    local body, status_code, resp_headers, status_line
    if ranges then
        ranges = merge_ranges(ranges)
        local range_support_checked = false
        local ranges_index = 1
        repeat
            body, status_code, resp_headers, status_line = http.request{
                url = url,
                headers = { ["Range"] = string.format("bytes=%u-%u", ranges[ranges_index][1], ranges[ranges_index][2]) },
                sink = sink,
            }
            if not body then
                self.err = status_code
                return false
            end
            if not range_support_checked then
                if resp_headers["accept-ranges"] ~= "bytes" then
                    self.err = "server does not support range requests!"
                    return false
                end
                range_support_checked = true
            end
            ok = status_code == 206
            if not ok then
                self.err = status_line
                return false
            end
            ranges_index = ranges_index + 1
        until ranges_index > #ranges
    else
        body, status_code, resp_headers, status_line = http.request{
            url = url,
            headers = etag and { ["If-None-Match"] = etag },
            sink = sink,
        }
        if not body then
            self.err = status_code
            return false
        end
        self.etag = resp_headers['etag']
        ok = status_code == 200 or status_code == 304
        if not ok then
            self.err = status_line
        end
    end
    self.status_code = status_code
    return ok
end

return Downloader
