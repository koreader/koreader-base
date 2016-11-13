--------------------------------------------------------------------------------
-- Taken from xsys repo at commit: 87df92c
--
-- A general purpose library that extends Lua standard libraries.
--
-- Copyright (C) 2011-2016 Stefano Peluchetti. All rights reserved.
--
-- Features, documentation and more: http://www.scilua.org .
--
-- This file is part of the Xsys library, which is released under the MIT
-- license: full text in file LICENSE.TXT in the library's root folder.
--------------------------------------------------------------------------------

-- TODO: Design exec API logging so that files are generated (useful for
-- TODO: debugging and profiling).

local insert = table.insert

-- String ----------------------------------------------------------------------
-- CREDIT: Steve Dovan snippet.
-- TODO: Clarify corner cases, make more robust.
local function split(s, re)
  local i1, ls = 1, { }
  if not re then re = '%s+' end
  if re == '' then return { s } end
  while true do
    local i2, i3 = s:find(re, i1)
    if not i2 then
      local last = s:sub(i1)
      if last ~= '' then insert(ls, last) end
      if #ls == 1 and ls[1] == '' then
        return  { }
      else
        return ls
      end
    end
    insert(ls, s:sub(i1, i2 - 1))
    i1 = i3 + 1
  end
end

-- TODO: what = "lr"
local function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- Export ----------------------------------------------------------------------

return {
  string   = {split = split, trim = trim},
}
