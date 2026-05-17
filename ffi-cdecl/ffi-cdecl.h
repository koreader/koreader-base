#define cdecl_const(Id)   _Static_assert((Id) < 0 ? (Id) >= (-0x7fffffffll - 1ll) : (Id) <= 0xffffffffull, "const value is outside LuaJIT representable range"); const int cdecl_const_##Id[2] = { (Id) < 0 ? 1 : 0, (Id) };
#define _cdecl(Id, Kind)  const int cdecl_##Kind##_##Id = 0;
#define cdecl_enum(Id)    _cdecl(Id, enum)
#define cdecl_func(Id)    _cdecl(Id, func)
#define cdecl_struct(Id)  _cdecl(Id, struct)
#define cdecl_type(Id)    _cdecl(Id, type)
#define cdecl_union(Id)   _cdecl(Id, union)
#define cdecl_var(Id)     _cdecl(Id, var)
