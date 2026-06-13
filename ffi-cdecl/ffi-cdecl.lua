#!/usr/bin/env luajit

local VERSION = "1.0.0"

local buffer = require("string.buffer")
local ffi = require("ffi")

ffi.log = function() end

require "ffi/loadlib"
require "ffi/posix_h"
require "ffi/tree_sitter_h"

local ts = ffi.loadlib("tree-sitter", "0.26")
local ts_c = ffi.loadlib("tree-sitter-c", "15.0")

-- Helpers. {{{

local function shell_escape(s)
    if s:match("[][*?%s|&;<>()$`\\\"'#˜%%!{}:]") then
        s = "'" .. s:gsub("'", "'\\''") .. "'"
    end
    return s
end

local function split_flags(s)
    local flags = {}
    for a in s:gmatch("([^,]+)") do
        table.insert(flags, shell_escape(a))
    end
    return table.concat(flags, " ")
end

local function popen(cmd, input, lines)
    local stdout = os.tmpname()
    local stdin
    cmd = cmd.." 1>"..shell_escape(stdout)
    if input then
        stdin = os.tmpname()
        local f = io.open(stdin, "w+")
        f:write(input)
        f:close()
        cmd = cmd.." <"..shell_escape(stdin)
    end
    -- print("executing: ", cmd)
    local ret = os.execute(cmd)
    if stdin then
        os.remove(stdin)
    end
    if ret ~= 0 then
        os.remove(stdout)
        error(string.format("command failed [%u]: %s\n", ret, cmd))
    end
    local f = io.open(stdout)
    os.remove(stdout)
    if lines then
        return function()
            local l = f:read("*l")
            if not l then
                f:close()
            end
            return l
        end
    end
    local out = f:read("*a")
    f:close()
    return out
end

local function iter_node(node)
    local c = ts.ts_node_child_count(node)
    local i = -1
    return function()
        i = i + 1
        if i == c then
            return
        end
        return ts.ts_node_child(node, i)
    end
end

-- }}}

-- Parser. {{{

local Parser = {}

function Parser:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.buf = nil
    o.lang = ffi.gc(ts_c.tree_sitter_c(), ts.ts_language_delete)
    o.parser = ffi.gc(ts.ts_parser_new(), ts.ts_parser_delete)
    if not ts.ts_parser_set_language(o.parser, o.lang) then
        error("ts_parser_set_language")
    end
    o.tree = nil
    return o
end

function Parser:free()
    if self.tree then
        ts.ts_tree_delete(ffi.gc(self.tree, nil))
    end
    if self.parser then
        ts.ts_parser_delete(ffi.gc(self.parser, nil))
    end
    ts.ts_language_delete(ffi.gc(self.lang, nil))
    self.buf = nil
    self.lang = nil
    self.parser = nil
    self.tree = nil
end

function Parser:parse_buffer(buf)
    self.source = nil
    if self.tree then
        ts.ts_tree_delete(ffi.gc(self.tree, nil))
        self.tree = nil
    end
    ts.ts_parser_reset(self.parser)
    self.buf = buf
    local ptr, len = self.buf:ref()
    self.tree = ffi.gc(ts.ts_parser_parse_string(self.parser, nil, ptr, len), ts.ts_tree_delete)
    return self.tree
end

function Parser:parse_string(source)
    return self:parse_buffer(buffer:new():set(source))
end

function Parser:language_field_id_for_name(name, named)
    local id = ts.ts_language_field_id_for_name(self.lang, name, #name)
    assert(id ~= 0, name)
    return id
end

function Parser:language_symbol_name(sym)
    local s = ts.ts_language_symbol_name(self.lang, sym)
    assert(s ~= nil, sym)
    return ffi.string(s)
end

function Parser:language_symbol_for_name(name, named)
    local id = ts.ts_language_symbol_for_name(self.lang, name, #name, named or false)
    assert(id ~= 0, name)
    return id
end

function Parser:node_text(node)
    local s = ts.ts_node_start_byte(node)
    local e = ts.ts_node_end_byte(node)
    local ptr, len = self.buf:ref()
    assert(e <= len)
    return ffi.string(ptr + s, e - s)
end

function Parser:node_sexp(node)
    local sexp = ts.ts_node_string(node)
    if sexp == nil then
        return
    end
    local s = ffi.string(sexp)
    ffi.C.free(sexp)
    return s
end

function Parser:query(sexp)
    local error_offset = ffi.new("uint32_t[1]")
    local error_type = ffi.new("TSQueryError[1]")
    local query = ts.ts_query_new(self.lang, sexp, #sexp, error_offset, error_type)
    if query == nil then
        error(string.format("query error %u at byte %u", tonumber(error_type[0]), tonumber(error_offset[0])))
    end
    return ffi.gc(query, ts.ts_query_delete)
end

function Parser:run_query(query_or_sexp, node, max_depth)
    local query_owned = type(query_or_sexp) == "string"
    local query = query_owned and self:query(query_or_sexp) or query_or_sexp
    local c = ffi.gc(ts.ts_query_cursor_new(), ts.ts_query_cursor_delete)
    local match = ffi.new("TSQueryMatch")
    if max_depth then
        ts.ts_query_cursor_set_max_start_depth(c, max_depth)
    end
    ts.ts_query_cursor_exec(c, query, node or ts.ts_tree_root_node(self.tree))
    return function ()
        if not ts.ts_query_cursor_next_match(c, match) then
            if query_owned then
                ts.ts_query_delete(ffi.gc(query, nil))
            end
            return
        end
        return match
    end
end

-- }}}

-- Formatter. {{{

local Formatter = {}

function Formatter:new(parser)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.parser = parser
    o.format_by_id = {}
    o.output = {}
    for k, v in pairs(o.format_named) do
        local sym = parser:language_symbol_for_name(k, true)
        o.format_by_id[sym] = v
        o["c_"..k] = sym
    end
    for k, v in pairs(o.format_unnamed) do
        local sym = parser:language_symbol_for_name(k, false)
        o.format_by_id[sym] = v
        o["c_"..k] = sym
    end
    for name, is_named in pairs{
        call_expression = true,
        identifier = true,
    } do
        o["c_"..name] = parser:language_symbol_for_name(name, is_named)
    end
    for field in ([[
        body
        declarator
        function
        left
        name
        operator
        right
        type
        underlying_type
        value
    ]]):gmatch("[^%s]+") do
        o["f_"..field] = parser:language_field_id_for_name(field)
    end
    for name, text in pairs{
        comma = ",",
        right_brace = "}",
    } do
        o["c_"..name] = parser:language_symbol_for_name(text)
    end
    self.supported_attributes = {}
    for a in ([[
        aligned
        cdecl
        fastcall
        mode
        packed __packed__
        stdcall
        thiscall
        vector_size
    ]]):gmatch("[^%s]+") do
       self.supported_attributes[a] = true
    end
    return o
end

Formatter.format_named = {}
Formatter.format_unnamed = {}

function Formatter.format_named:abstract_pointer_declarator(node)
    if self.output[#self.output]:match("[%w_]$") then
        table.insert(self.output, " ")
    end
    self:children(node)
end

function Formatter.format_named:assignment_expression(node)
    self:format(ts.ts_node_child_by_field_id(node, self.f_left))
    table.insert(self.output, " ")
    self:format(ts.ts_node_child_by_field_id(node, self.f_operator))
    table.insert(self.output, " ")
    self:format(ts.ts_node_child_by_field_id(node, self.f_right))
end

function Formatter.format_named:attribute_specifier(node)
    local start = #self.output
    local attrs = ts.ts_node_named_child(node, 0)
    for n in iter_node(attrs) do
        local id
        local sym = ts.ts_node_symbol(n)
        if sym == self.c_call_expression then
            id = self.parser:node_text(ts.ts_node_child_by_field_id(n, self.f_function))
        elseif sym == self.c_identifier then
            id = self.parser:node_text(n)
        end
        if id and self.supported_attributes[id] then
            if #self.output == start then
                table.insert(self.output, " __attribute__((")
            else
                table.insert(self.output, ", ")
            end
            self:format(n)
        end
    end
    if #self.output ~= start then
        table.insert(self.output, ")) ")
    end
end

Formatter.format_named.binary_expression = Formatter.format_named.assignment_expression

function Formatter.format_named:enumerator(node)
    self:format(ts.ts_node_child_by_field_id(node, self.f_name))
    local value = ts.ts_node_child_by_field_id(node, self.f_value)
    if not ts.ts_node_is_null(value) then
        table.insert(self.output, " = ")
        self:format(value)
    end
end

function Formatter.format_named:enumerator_list(node)
    for n in iter_node(node) do
        local sym = ts.ts_node_symbol(n)
        if sym == self.c_right_brace and self.output[#self.output] ~= "\n" then
            table.insert(self.output, ",\n")
        end
        self:format(n)
        if sym == self.c_comma then
            table.insert(self.output, "\n")
        end
    end
end

function Formatter.format_named:init_declarator(node)
    self:format(ts.ts_node_child_by_field_id(node, self.f_declarator))
    table.insert(self.output, " = ")
    self:format(ts.ts_node_child_by_field_id(node, self.f_value))
end

function Formatter.format_named:parenthesized_declarator(node)
    if self.output[#self.output]:match("[%w_]$") then
        table.insert(self.output, " ")
    end
    self:children(node)
end

Formatter.format_named.pointer_declarator = Formatter.format_named.abstract_pointer_declarator

local TYPE_ALIASES = {
    -- bool
    ["_Bool"] = "bool",
    -- short
    ["short int"] = "short",
    ["signed short"] = "short",
    ["signed short int"] = "short",
    -- unsigned short
    ["unsigned short int"] = "unsigned short",
    -- int
    ["signed int"] = "int",
    -- unsigned
    ["unsigned int"] = "unsigned",
    -- long
    ["long int"] = "long",
    ["signed long"] = "long",
    ["signed long int"] = "long",
    -- unsigned long
    ["unsigned long int"] = "unsigned long",
    -- long long
    ["long long int"] = "long long",
    ["signed long long"] = "long long",
    ["signed long long int"] = "long long",
    -- unsigned long long
    ["unsigned long long int"] = "unsigned long long",
}

function Formatter.format_named:primitive_type(node)
    local text = self.parser:node_text(node)
    text = TYPE_ALIASES[text] or text
    table.insert(self.output, text)
end

Formatter.format_named.sized_type_specifier = Formatter.format_named.primitive_type
Formatter.format_named.type_identifier = Formatter.format_named.primitive_type

function Formatter.format_unnamed:extern(node)
end

function Formatter:format(node)
    local sym = ts.ts_node_symbol(node)
    local func = self.format_by_id[sym]
    if func then
        func(self, node)
        return
    end
    if ts.ts_node_child_count(node) == 0 then
        table.insert(self.output, self.parser:node_text(node))
        return
    end
    self:children(node)
end

function Formatter:children(node)
    for n in iter_node(node) do
        self:format(n)
    end
end

function Formatter:__call()
    self:format(ts.ts_tree_root_node(self.parser.tree))
    local buf = buffer:new(#self.parser.buf)
    local prev_token = ""
    local indent = ""
    for __, token in ipairs(self.output) do
        if token == "}" then
            indent = indent:sub(3)
            if not prev_token:match("\n$") then
                token = indent.."\n}"
            end
        end
        if prev_token:match("\n$") then
            buf:put(indent)
        end
        if token == "{" then
            token = " {\n"
            indent = indent .. "  "
        elseif token == "," then
            token = ", "
        elseif token == ";" then
            token = ";\n"
        elseif token:match("^[%w_}]") and prev_token:match("[]}%w_]$") then
            buf:put(" ")
        end
        buf:put(token)
        prev_token = token
    end
    return (buf:get():gsub("%s+\n", "\n"))
end

-- }}}

local help = [[
USAGE: ffi-cdecl [OPTIONS] CDECL_FILE

general options:

  -h, --help   show this help message and exit
  -v           show version
  -W           warn instead of erroring out on missing / redefined cdecl

compiler options:

  -c COMPILER  select compiler (default: gcc)
  -D MACRO     macro definition (forwarded to compiler)
  -I DIR       include directory (forwarded to compiler)
  -f FLAGS     compiler flags (comma separated, e.g. `-f -std=c99,-Wall`)

output options:

  -o FILE      output file (optional, fallback to stdout)
  -r MODULE    extra require to add to the generated output (e.g. `-r ffi/posix_h`)

pkg-config options:

  -d MODULE    extend compiler flags with the results of `pkg-config --cflags MODULE`
  -p FLAGS     pkg-config flags (comma separated, e.g. `-p --env-only,--with-path=…`
]]

local function _main(parser, ffi_cdecl_dir)

    local compiler = "gcc"
    local output_file = "-"
    local input_file
    local cflags = {}
    local cppflags = {}
    local pkgflags = {}
    local requires = {}
    local warn_only = false

    while #arg > 0 do
        local a = table.remove(arg, 1)
        if a == "-D" or a == "-I" then
            -- Compiler pre-processor flag.
            table.insert(cppflags, a..shell_escape(table.remove(arg, 1)))
        elseif a == "-c" then
            compiler = shell_escape(table.remove(arg, 1))
        elseif a == "-d" then
            -- Dependency, call pkg-config to get the necessary flags.
            local pkg_config_cmd = table.concat({
                "pkg-config", table.concat(pkgflags, " "),
                "--cflags", shell_escape(table.remove(arg, 1)),
            }, " ")
            local flags = popen(pkg_config_cmd):gsub("%s*$", "")
            table.insert(cppflags, flags)
        elseif a == "-f" then
            -- Compiler flag.
            table.insert(cflags, split_flags(table.remove(arg, 1)))
        elseif a == "-h" then
            io.stdout:write(help)
            return 0
        elseif a == "-o" then
            -- Output file.
            output_file = table.remove(arg, 1)
        elseif a == "-p" then
            -- Pkg-config flags.
            table.insert(pkgflags, split_flags(table.remove(arg, 1)))
        elseif a == "-r" then
            table.insert(requires, table.remove(arg, 1))
        elseif a == "-v" then
            print("ffi-cdecl version "..VERSION)
            return 0
        elseif a == "-W" then
            warn_only = true
        elseif not input_file then
            input_file = a
        else
            io.stderr:write(string.format("ERROR: invalid argument “%s”\n", a))
            return 1
        end
    end

    if not input_file then
        io.stderr:write(help)
        return 1
    end

    local source = popen(table.concat({
        compiler,
        table.concat(cflags, " "),
        "-E -P -include", shell_escape(ffi_cdecl_dir.."/ffi-cdecl.h"),
        table.concat(cppflags, " "),
        shell_escape(input_file)
    }, " "))

    -- if true then return end

    parser:parse_string(source)

    -- for node in iter_node(ts.ts_tree_root_node(parser.tree)) do
    --     print()
    --     print("node text:", parser:node_text(node))
    --     print("node sexp:", parser:node_sexp(node))
    -- end

    -- if true then return end

    local cdecl_list = {}
    local cdecl_by_kind = {}
    for t in ("const enum func struct type union var"):gmatch("%S+") do
        cdecl_by_kind[t] = {}
    end

    for m in parser:run_query([[
        (declaration
            (type_qualifier) @qualifier (#eq? @qualifier "const")
            type: (_) @type
            declarator: (init_declarator
                declarator: [
                    (identifier) @name
                    (array_declarator declarator: (identifier) @name)
                ]
                value: (_)
            )
        ) @match
    ]]) do
        local kind, id = parser:node_text(m.captures[3].node):match("^cdecl_([^_]+)_(.+)$")
        if kind then
            table.insert(cdecl_list, {kind, id})
            cdecl_by_kind[kind][id] = true
        end
    end

    -- for kind, list in pairs(cdecl_by_kind) do
    --     if next(list) then
    --         print("\ncdecl_"..kind)
    --         for id, v in pairs(list) do
    --             print("", id)
    --         end
    --     end
    -- end

    -- if true then return end

    local set_cdecl = function (kind, id, cdef)
        local old = cdecl_by_kind[kind][id]
        if old ~= true and old ~= cdef then
            local msg = string.format("redefining %s (%s), from:\n%s\nto:\n%s\n", id, kind, old, cdef)
            if warn_only then
                io.stderr:write(msg)
                cdef = old.."\n"..cdef
            else
                error(msg)
            end
        end
        cdecl_by_kind[kind][id] = cdef
    end

    local c_declaration = parser:language_symbol_for_name("declaration",  true)
    local c_primitive_type = parser:language_symbol_for_name("primitive_type", true)
    local c_type_identifier = parser:language_symbol_for_name("type_identifier", true)
    local c_enum_or_struct_or_union = {
        [parser:language_symbol_for_name("enum_specifier", true)] = "enum",
        [parser:language_symbol_for_name("struct_specifier", true)] = "struct",
        [parser:language_symbol_for_name("union_specifier", true)] = "union",
    }

    -- cdecl_const
    if next(cdecl_by_kind.const) then
        local cmd = table.concat({
            compiler,
            table.concat(cflags, " "),
            "-S",
            "-o", "-",
            "-x", "cpp-output", "-",
        }, " ")
        local id, negative, value
        for line in popen(cmd, source, true) do
            local label = line:match("^([%w_]+):$")
            if label then
                negative, value = nil, nil
                id = label:match("^_?cdecl_const_([%w_]+)$")
                if id and not cdecl_by_kind.const[id] then
                    id = nil
                end
            elseif id then
                for _, pattern in ipairs{
                    "^%s*.long%s+(-?%d+)",
                    "^%s*.word%s+(-?%d+)",
                    "^%s*.(space)%s+8$",
                    "^%s*.(zero)%s+8$",
                } do
                    local v = line:match(pattern)
                    if v then
                        if v == "space" or v == "zero" then
                            negative, value = 0, 0
                        elseif not negative then
                            negative = tonumber(v)
                        elseif not value then
                            value = tonumber(v)
                        else
                            error("failed to parse assembler output!")
                        end
                        break
                    end
                end
                if negative and value then
                    local int_type = negative ~= 0 and "int" or "unsigned"
                    value = tonumber(ffi.new(int_type, tonumber(value)))
                    set_cdecl("const", id, string.format("static const %s %s = %s;", int_type, id, value))
                    id, negative, value = nil, nil, nil
                end
            end
        end
    end

    -- cdecl_enum
    if next(cdecl_by_kind.enum) then
        for m in parser:run_query([[
            (enum_specifier
                name: (type_identifier) @id
                body: (_)
            ) @match
        ]], nil, 2) do
            local id = parser:node_text(m.captures[1].node)
            if cdecl_by_kind.enum[id] then
                local cdef = parser:node_text(m.captures[0].node) .. ";"
                set_cdecl('enum', id, cdef)
            end
        end
    end

    -- cdecl_func
    if next(cdecl_by_kind.func) then
        for m in parser:run_query([[
            (function_declarator
                declarator: (identifier) @id
            ) @match
        ]], nil, 4) do
            local id = parser:node_text(m.captures[1].node)
            if cdecl_by_kind.func[id] then
                local node = m.captures[0].node
                -- Walk up to the parent declaration.
                repeat node = ts.ts_node_parent(node)
                until ts.ts_node_symbol(node) == c_declaration
                local cdef = parser:node_text(node)
                set_cdecl('func', id, cdef)
            end
        end
    end

    -- cdecl_struct
    if next(cdecl_by_kind.struct) then
        for m in parser:run_query([[
            (struct_specifier
                name: (type_identifier) @id
                body: (_)
            ) @match
        ]], nil, 2) do
            local id = parser:node_text(m.captures[1].node)
            if cdecl_by_kind.struct[id] then
                local cdef = parser:node_text(m.captures[0].node) .. ";"
                set_cdecl('struct', id, cdef)
            end
        end
    end

    -- cdecl_type
    if next(cdecl_by_kind.type) then
        local type_id_query = parser:query([[ (type_identifier) @id ]])
        for m in parser:run_query([[
            (type_definition (type_qualifier)* @qualifiers
                type: (_) @type
                declarator: (_) @decl
            ) @match
        ]], nil, 1) do
            local qualifiers = m.capture_count == 4 and m.captures[1].node or nil
            local target = m.captures[m.capture_count - 2].node
            local decl = m.captures[m.capture_count - 1].node
            local decl_sym = ts.ts_node_symbol(decl)
            local id
            if decl_sym == c_type_identifier then
                id = parser:node_text(decl)
            elseif decl_sym == c_primitive_type then
                -- Typedefing a primitive type (e.g.: `typedef int int_t;`), ignore those definitions.
                id = nil
            else
                local sm = parser:run_query(type_id_query, decl, 3)()
                if sm then
                    id = parser:node_text(sm.captures[0].node)
                end
            end
            if cdecl_by_kind.type[id] then
                local base_type
                local complex_type = c_enum_or_struct_or_union[ts.ts_node_symbol(target)]
                if complex_type then
                    base_type = complex_type.." "..parser:node_text(ts.ts_node_child(target, 1))
                else
                    base_type = parser:node_text(target)
                end
                local cdef = { "typedef", base_type, parser:node_text(decl), ";" }
                if qualifiers then
                    table.insert(cdef, 2, parser:node_text(qualifiers))
                end
                set_cdecl('type', id, table.concat(cdef, " "))
            end
        end
    end

    -- cdecl_union
    if next(cdecl_by_kind.union) then
        for m in parser:run_query([[
            (union_specifier
                name: (type_identifier) @id
                body: (_)
            ) @match
        ]]) do
            local id = parser:node_text(m.captures[1].node)
            if cdecl_by_kind.union[id] then
                local cdef = parser:node_text(m.captures[0].node) .. ";"
                set_cdecl('union', id, cdef)
            end
        end
    end

    -- cdecl_var
    if next(cdecl_by_kind.var) then
        for m in parser:run_query([[
            (declaration
                declarator: (identifier) @id
            ) @match
        ]]) do
            local id = parser:node_text(m.captures[1].node)
            if cdecl_by_kind.var[id] then
                local node = m.captures[0].node
                local cdef = parser:node_text(node)
                set_cdecl('var', id, cdef)
            end
        end
    end

    local cdef_block = buffer:new()

    for __, v in pairs(cdecl_list) do
        local kind, id = unpack(v)
        local cdef = cdecl_by_kind[kind][id]
        if cdef == true then
            local msg = "missing cdef for "..id.." ("..kind..")\n"
            if warn_only then
                io.stderr:write(msg)
            else
                error(msg)
            end
        end
        if cdef ~= true then
            cdef_block:put(cdef)
            cdef_block:put("\n")
        end
    end

    -- Output.

    parser:parse_buffer(cdef_block)

    -- for node in iter_node(ts.ts_tree_root_node(parser.tree)) do
    --     print()
    --     print("node text:", parser:node_text(node))
    --     print("node sexp:", parser:node_sexp(node))
    -- end

    if output_file == "-" then
        output_file = io.stdout
    else
        output_file = io.open(output_file, "w+")
    end
    output_file:write("-- Automatically generated with ffi-cdecl.\n\n")
    if #requires > 0 then
        for __, r in ipairs(requires) do
            output_file:write(string.format("require \"%s\"\n", r))
        end
        output_file:write("\n")
    end
    output_file:write("require(\"ffi\").cdef[[\n")
    output_file:write(Formatter:new(parser)())
    output_file:write("]]\n")
    if output_file ~= io.stdout then
        output_file:close()
    end

    return 0

end

local function main()
    local ffi_cdecl_path = debug.getinfo(2, "S").source:match("^@(.*)/[^/]*.lua$") or "."
    local parser = Parser:new()
    local ok, ret = xpcall(_main, debug.traceback, parser, ffi_cdecl_path)
    if not ok then
        io.stderr:write(ret)
        io.stderr:write("\n")
    end
    parser:free()
    os.exit(ok and ret or 1)
end

main()

-- vim: foldmethod=marker foldlevel=0
