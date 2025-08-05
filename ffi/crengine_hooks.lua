local ffi = require("ffi")

ffi.cdef[[
    void crengine_enable_capture(bool enabled);
    void crengine_get_page_buffer(int page, uint8_t** buf, size_t* size);
    void crengine_clear_buffers();
]]

local C = ffi.C

local _M = {}

function _M.enableCapture(enable)
    C.crengine_enable_capture(enable)
end

function _M.getPageBuffer(page)
    local buf_ptr = ffi.new("uint8_t*[1]")
    local size_ptr = ffi.new("size_t[1]")
    C.crengine_get_page_buffer(page, buf_ptr, size_ptr)
    
    local size = tonumber(size_ptr[0])
    if size == 0 then return nil end
    
    return ffi.string(buf_ptr[0], size)
end

function _M.clearBuffers()
    C.crengine_clear_buffers()
end

return _M
