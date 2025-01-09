local lfs = require("lfs")

local testsuites = {}
local roots = {}
local lpaths = {}
for entry in lfs.dir("spec") do
    local attr = lfs.attributes("spec/" .. entry .. "/unit")
    if attr and attr.mode == "directory" then
        local testroot = "spec/" .. entry .. "/unit"
        local testpath = testroot .. "/?.lua"
        testsuites[entry] = {}
        testsuites[entry].ROOT = {testroot}
        testsuites[entry].lpath = testpath
        table.insert(roots, testroot)
        table.insert(lpaths, testpath)
    end
end

testsuites.all = {
    ROOT = roots,
    lpath = table.concat(lpaths, ";"),
}

return testsuites
