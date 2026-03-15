local ffi = require "ffi"
local inkview = ffi.load("inkview")

ffi.cdefs[[
char *GetSoftwareVersion();
]]

-- format is $model.$major.$minor.$build, like "U743g.6.8.4143"
local software_version = ffi.string(inkview.GetSoftwareVersion())
local version_major, version_minor = software_version:match("([1-9][0-9]*)[.]([1-9][0-9]*)[.][1-9][0-9]*$")
if not version_major or not version_minor then
    error("could not parse PocketBook software version: "..software_version)
end
local pocketbook_version = version_major * 100 + version_minor

ffi.cdefs('static const int POCKETBOOK_VERSION = ' .. pocketbook_version .. ';')

require("ffi/posix_h")
require("ffi/inkview_h")

return inkview
