set(LJSQLITE3_MOD ${OUTPUT_DIR}/common/lua-ljsqlite3/init.lua)

add_custom_command(
    OUTPUT ${LJSQLITE3_MOD}
    MAIN_DEPENDENCY init.lua
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/init.lua ${LJSQLITE3_MOD}
)

add_custom_target(lua-ljsqlite3 ALL DEPENDS ${LJSQLITE3_MOD})
