unused_args = false
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
    "thirdparty/*",
}

-- don't balk on busted stuff in spec
files["spec/unit/*"].std = "+busted"

-- TODO: clean up and enforce max line width (631)
-- https://luacheck.readthedocs.io/en/stable/warnings.html
ignore = {
    "211/__*", -- Unused local variable
    "231/__",  -- Local variable is set but never accessed
    "631",     -- Line is too long
    "dummy",
}
