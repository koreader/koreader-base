unused_args = false
std = "luajit"
-- ignore implicit self
self = false

globals = {
    "G_reader_settings",
}

read_globals = {
    "DLANDSCAPE_CLOCKWISE_ROTATION",
    "lfs",
}

exclude_files = {
    "build/*",
    "thirdparty/*",
}

files["spec/unit/*"].std = "+busted"

-- TODO: clean up and enforce max line width (631)
ignore = {
    "631",
    "dummy",
}
