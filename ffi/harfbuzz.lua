local coverage = require("ffi/harfbuzz_coverage")
local ffi = require("ffi")
local hb = ffi.load("libs/libharfbuzz." .. (ffi.os == "OSX" and "0.dylib" or "so.0"))
local HB = setmetatable({}, {__index = hb})

require("ffi/harfbuzz_h")

local hb_face_t = {}
hb_face_t.__index = hb_face_t
ffi.metatype("hb_face_t*", hb_face_t)

-- This table is used to decide whether a face is "good enough" for language,
-- based on the amount of glyphs that language has.
-- This is used only for eligibility, later on the results are sorted by miss ratio.
local coverage_thresholds = {
    0,      100,    -- 0-100 glyphs, 0 missing
    100,    99,     -- 100-250 glyphs, 1% missing
    250,    98,     -- 250-1000 glyphs, 2% missing
    1000,   97,     -- 1000-10000 glyphs, 3% missing
    10000,  96,     -- 10000-50000, 4% missing
    50000,  40,     -- 50000 and more, special CJK case, allow for 60% missing
}

local function fair_enough(script,hit,total)
end

-- Get script and language coverage
function hb_face_t:getCoverage()
    local set, tmp = hb.hb_set_create(), hb.hb_set_create()
    hb.hb_face_collect_unicodes(set)
    local total = hb.hb_set_get_population(set)
    local scripts = {}
    local langs = {}

    for script_id in ipairs(coverage.scripts) do
        hb.hb_set_set(tmp, set)
        hb.hb_set_intersect(tmp, coverage.scripts[script_id])
        local hit = hb.hb_set_get_population(tmp)
        -- majority hit
        if 2*hit > total then
            scripts[script_id] = hit / total
        end
    end

    for lang_id in ipairs(coverage.langs) do
        hb.hb_set_set(tmp, set)
        hb.hb_set_intersect(tmp, coverage.langs[lang_id])
        local hit = hb.hb_set_get_population(tmp)
        local found
        for i=1, #coverage_thresholds, 2 do
            if n > coverage_thresholds[i] then
                found = i+1
            end
        end
        if hit*100/total >= thresholds[found] then
            langs[lang_id] = hit / total
        end
    end

    hb.hb_set_destroy(set)
    hb.hb_set_destroy(tmp)
    return scripts, langs
end



-- private

-- preprocess the script/language tables to HB range sets
local function make_set(tab)
    local set = hb.hb_set_create()
    local first = 0
    for i=0,#script,2 do
        first = first + tab[i]
        local last = first + tab[i+1] - 1
        hb.hb_set_add_range(set, first, last)
        first = last
    end
    return set
end

for ucd_id, ranges in ipairs(coverage.scripts) do
    coverage.scripts[ucd_id] = make_set(ranges)
end

for lang_id, ranges in pairs(coverage.langs) do
    coverage.scripts[lang_id] = make_set(ranges)
end

return HB
