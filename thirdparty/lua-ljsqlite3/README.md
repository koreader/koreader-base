LJSQLite3: SQlite3 Interface
============================

Pure LuaJIT binding for [SQLite3](http://sqlite.org) databases.

## Features

- all SQLite3 types are supported and mapped to LuaJIT types
- efficient implementation via value-binding methods and prepared statements
- ability to extend SQLite3 via scalar and aggregate (Lua) callback functions
- command-line shell feature
- results by row or by whole table

```lua
local sql = require "ljsqlite3"
local conn = sql.open("") -- Open a temporary in-memory database.
  
-- Execute SQL commands separated by the ';' character:
conn:exec[[
CREATE TABLE t(id TEXT, num REAL);
INSERT INTO t VALUES('myid1', 200);
]]
  
-- Prepared statements are supported:
local stmt = conn:prepare("INSERT INTO t VALUES(?, ?)")
for i=2,4 do
  stmt:reset():bind('myid'..i, 200*i):step()
end
  
-- Command-line shell feature which here prints all records:
conn "SELECT * FROM t"
--> id    num
--> myid1 200
--> myid2 400
--> myid3 600
--> myid4 800
  
local t = conn:exec("SELECT * FROM t") -- Records are by column.
-- Access to columns via column numbers or names:
assert(t[1] == t.id)
-- Nested indexing corresponds to the record number:
assert(t[1][3] == 'myid3')
  
-- Convenience function returns multiple values for one record:
local id, num = conn:rowexec("SELECT * FROM t WHERE id=='myid3'")
print(id, num) --> myid3 600
 
-- Custom scalar function definition, aggregates supported as well.
conn:setscalar("MYFUN", function(x) return x/100 end)
conn "SELECT MYFUN(num) FROM t"
--> MYFUN(num)
--> 2
--> 4
--> 6
--> 8
 
conn:close() -- Close stmt as well.
```

## Install

This module is included in the [ULua](http://ulua.io) distribution, to install it use:
```
upkg add ljsqlite3
```

Alternatively, manually install this module making sure that all dependencies listed in the `require` section of [`__meta.lua`](__meta.lua) are installed as well (dependencies starting with `clib_` are standard C dynamic libraries).

## Documentation

Refer to the [official documentation](http://scilua.org/ljsqlite3.html).
