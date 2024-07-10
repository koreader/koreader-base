target_sources(lunasvg PRIVATE
    "${CMAKE_CURRENT_LIST_DIR}/ximageelement.cpp"
    "${CMAKE_CURRENT_LIST_DIR}/xtextelement.cpp"
    "${CMAKE_CURRENT_LIST_DIR}/xtspanelement.cpp"
)

target_include_directories(lunasvg PRIVATE "${CMAKE_CURRENT_LIST_DIR}")

install(FILES xlunasvg.h DESTINATION ${LUNASVG_INCDIR})
