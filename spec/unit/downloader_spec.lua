local http = require("socket.http")
local Downloader = require("ffi/downloader")

describe("Downloader", function()
    local downloader, request, last_request

    before_each(function()
        downloader = Downloader:new()
        request = stub(http, "request")
        last_request = nil
    end)

    after_each(function()
        request:revert()
    end)

    local function respond(ok, code, headers, status)
        request.invokes(function(req)
            last_request = req
            if headers then
                req.response_headers(code, headers, status)
            end
            return ok, code, headers, status
        end)
    end

    it("should preserve connection errors without response headers", function()
        for _, err in ipairs({"timeout", "connection refused", "host not found"}) do
            respond(nil, err)
            assert.is_falsy(downloader:fetch("http://example.com/manifest"))
            assert.is_equal(err, downloader.err)
            assert.is_equal(err, downloader.status_code)
            assert.is_nil(downloader.headers)
            assert.is_nil(downloader.etag)
        end
    end)

    it("should reject LuaSocket's headerless success return", function()
        respond(1, 200)
        assert.is_false(downloader:fetch("http://example.com/manifest"))
        assert.is_equal("no HTTP response headers", downloader.err)
        assert.is_equal(200, downloader.status_code)
        assert.is_nil(downloader.headers)
        assert.is_nil(downloader.etag)
    end)

    it("should reject range responses without response headers", function()
        respond(1, 200)
        assert.is_false(downloader:fetch("http://example.com/update", nil, {{0, 9}}))
        assert.is_equal("no HTTP response headers", downloader.err)
    end)

    it("should preserve HTTP errors returned without response headers", function()
        respond(1, 408)
        assert.is_false(downloader:fetch("http://example.com/manifest"))
        assert.is_equal("HTTP 408", downloader.err)
        assert.is_equal(408, downloader.status_code)
    end)

    it("should stop at the first range response without headers", function()
        local requests = 0
        request.invokes(function(req)
            requests = requests + 1
            if requests == 1 then
                return 1, 200
            end
            req.response_headers(206, {}, "HTTP/1.1 206 Partial Content")
            return 1, 206, {}, "HTTP/1.1 206 Partial Content"
        end)
        assert.is_false(downloader:fetch("http://example.com/update", nil, {{0, 9}, {20, 29}}))
        assert.is_equal("no HTTP response headers", downloader.err)
        assert.is_equal(1, requests)
    end)

    it("should preserve a connection error after a successful range request", function()
        local requests = 0
        request.invokes(function(req)
            requests = requests + 1
            if requests == 1 then
                req.response_headers(206, {}, "HTTP/1.1 206 Partial Content")
                return 1, 206, {}, "HTTP/1.1 206 Partial Content"
            end
            return nil, "timeout"
        end)
        assert.is_falsy(downloader:fetch("http://example.com/update", nil, {{0, 9}, {20, 29}, {40, 49}}))
        assert.is_equal("timeout", downloader.err)
        assert.is_equal(2, requests)
        assert.is_nil(downloader.headers)
        assert.is_nil(downloader.etag)
    end)

    it("should provide an error when the request returns no diagnostic", function()
        respond(nil)
        assert.is_falsy(downloader:fetch("http://example.com/manifest"))
        assert.is_equal("no HTTP response", downloader.err)
    end)

    it("should retain successful response headers and ETag", function()
        local headers = {etag = '"manifest-v1"'}
        respond(1, 200, headers, "HTTP/1.1 200 OK")
        assert.is_true(downloader:fetch("http://example.com/manifest"))
        assert.is_equal(headers, downloader.headers)
        assert.is_equal(headers.etag, downloader.etag)
        assert.is_equal(200, downloader.status_code)
        assert.is_nil(downloader.err)
    end)

    it("should accept an unchanged response without an ETag", function()
        respond(1, 304, {}, "HTTP/1.1 304 Not Modified")
        assert.is_true(downloader:fetch("http://example.com/manifest", nil, nil, '"manifest-v1"'))
        assert.is_equal('"manifest-v1"', last_request.headers["If-None-Match"])
        assert.is_equal(304, downloader.status_code)
        assert.is_nil(downloader.etag)
        assert.is_nil(downloader.err)
    end)

    it("should preserve HTTP error status lines", function()
        respond(1, 503, {}, "HTTP/1.1 503 Service Unavailable")
        assert.is_false(downloader:fetch("http://example.com/manifest"))
        assert.is_equal("HTTP/1.1 503 Service Unavailable", downloader.err)
        assert.is_equal(503, downloader.status_code)
    end)

    it("should accept partial responses to range requests", function()
        respond(1, 206, {}, "HTTP/1.1 206 Partial Content")
        assert.is_true(downloader:fetch("http://example.com/update", nil, {{0, 9}}))
        assert.is_equal("bytes=0-9", last_request.headers.Range)
        assert.is_equal(206, downloader.status_code)
        assert.is_nil(downloader.err)
    end)

    it("should preserve connection errors for range requests", function()
        respond(nil, "timeout")
        assert.is_falsy(downloader:fetch("http://example.com/update", nil, {{0, 9}}))
        assert.is_equal("timeout", downloader.err)
        assert.is_nil(downloader.headers)
    end)

    it("should preserve the error for unsupported range requests", function()
        respond(1, 200, {}, "HTTP/1.1 200 OK")
        assert.is_false(downloader:fetch("http://example.com/update", nil, {{0, 9}}))
        assert.is_equal("server does not support range requests!", downloader.err)
    end)

    it("should clear stale response metadata and errors between fetches", function()
        respond(1, 200, {etag = '"manifest-v1"'}, "HTTP/1.1 200 OK")
        assert.is_true(downloader:fetch("http://example.com/manifest"))

        respond(nil, "timeout")
        assert.is_falsy(downloader:fetch("http://example.com/manifest"))
        assert.is_equal("timeout", downloader.err)
        assert.is_nil(downloader.headers)
        assert.is_nil(downloader.etag)

        respond(1, 200, {}, "HTTP/1.1 200 OK")
        assert.is_true(downloader:fetch("http://example.com/manifest"))
        assert.is_nil(downloader.etag)
        assert.is_nil(downloader.err)
    end)
end)
