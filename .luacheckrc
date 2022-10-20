unused_args = false
unused_secondaries = false
std = "luajit"
-- ignore implicit self
self = false

globals = {
    "G_defaults",
    "table.pack",
    "table.unpack",
}

exclude_files = {
    "build/*",
    "ffi/sha2.lua",
    "luafilesystem/*",
    "thirdparty/*",
}

files["spec/unit/*"].std = "+busted"

-- TODO: clean up and enforce max line width (631)
ignore = {
    "631",
    "dummy",
}
