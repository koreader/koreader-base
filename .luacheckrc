unused_args = false
unused_secondaries = false
std = "luajit"
-- ignore implicit self
self = false

read_globals = {
    "DLANDSCAPE_CLOCKWISE_ROTATION",
    "lfs",
}

exclude_files = {
    "build/*",
    "luafilesystem/*",
    "thirdparty/*",
}

files["spec/unit/*"].std = "+busted"

-- TODO: clean up and enforce max line width (631)
ignore = {
    "631",
    "dummy",
}
