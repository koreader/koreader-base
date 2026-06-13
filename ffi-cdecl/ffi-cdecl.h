#define cdecl_const(Id)   _Static_assert((Id) < 0 ? (Id) >= (-0x7fffffffll - 1ll) : (Id) <= 0xffffffffull, "const value is outside LuaJIT representable range"); const int cdecl_const_##Id[2] = { (Id) < 0 ? 1 : 0, (Id) };
#define _cdecl(Id, Kind)  const int cdecl_##Kind##_##Id = 0;
#define cdecl_enum(Id)    _cdecl(Id, enum)
#define cdecl_func(Id)    _cdecl(Id, func)
#define cdecl_struct(Id)  _cdecl(Id, struct)
#define cdecl_type(Id)    _cdecl(Id, type)
#define cdecl_union(Id)   _cdecl(Id, union)
#define cdecl_var(Id)     _cdecl(Id, var)

#define _cdecl_token_concat1(A, B)  A ## B
#define _cdecl_token_concat2(A, B)  _cdecl_token_concat1(A, B)

#define cdecl_out(...)  const char *_cdecl_token_concat2(cdecl_out_, __COUNTER__) = # __VA_ARGS__;

// Miscellaneous helpers.
#define cdecl_offsetof(I, T, M)  enum { OFFSETOF_##I = offsetof(T, M) }; cdecl_const(OFFSETOF_##I);
#define cdecl_sizeof(I, T)       enum { SIZEOF_##I = sizeof (T) }; cdecl_const(SIZEOF_##I);
