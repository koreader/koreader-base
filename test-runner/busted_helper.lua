-- Create `$KO_HOME` directory.
local lfs = require("lfs")
lfs.mkdir(os.getenv("KO_HOME"))
-- Preload necessary busted modules and their dependencies (which
-- are normally dynamically loaded during the testsuite execution).
require("pl.dir")
require("pl.List")
require("busted.execute")
require("busted.modules.files.lua")
require("busted.modules.test_file_loader")
-- Patch `package.path / package.cpath`: filter-out paths
-- specific to the test framework (e.g. `spec/rocks/…`).
local function filter_rocks(path)
    local filtered = {}
    for spec in string.gmatch(path, "([^;]+)") do
        if not spec:match("spec/rocks/") then
            table.insert(filtered, spec)
        end
    end
    return table.concat(filtered, ';')
end
package.path = filter_rocks(package.path)
package.cpath = filter_rocks(package.cpath)
-- Setup `ffi.loadlib` support.
require("ffi/loadlib")
