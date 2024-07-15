include_guard(GLOBAL)

include(koreader_thirdparty_common)
include(koreader_thirdparty_libs)

function(declare_koreader_target NAME)
    cmake_parse_arguments("" "EXCLUDE_FROM_ALL" "SUFFIX;TYPE;VISIBILITY" "DEPENDS;SOURCES" ${ARGN})
    set(${NAME}_TYPE ${_TYPE} PARENT_SCOPE)
    set(${NAME}_DEPENDS ${_DEPENDS} PARENT_SCOPE)
    set(${NAME}_EXCLUDE_FROM_ALL ${_EXCLUDE_FROM_ALL} PARENT_SCOPE)
    set(${NAME}_SUFFIX ${_SUFFIX} PARENT_SCOPE)
    set(${NAME}_SOURCES ${_SOURCES} PARENT_SCOPE)
    set(${NAME}_VISIBILITY ${_VISIBILITY} PARENT_SCOPE)
    set(KOREADER_TARGETS ${KOREADER_TARGETS} ${NAME} PARENT_SCOPE)
endfunction()

function(setup_target NAME)
    if(${NAME}_TYPE STREQUAL executable)
        add_executable(${NAME})
        set(_DESTINATION ${OUTPUT_DIR})
    elseif(${NAME}_TYPE STREQUAL library)
        add_library(${NAME} SHARED)
        set(_DESTINATION ${OUTPUT_DIR}/libs)
    else()
        message(FATAL_ERROR "unsupported target '${NAME}' type: ${${NAME}_TYPE}")
    endif()
    if(${NAME}_DEPENDS)
        target_link_libraries(${NAME} PRIVATE ${${NAME}_DEPENDS})
    endif()
    if(${NAME}_SUFFIX)
        set_target_properties(${NAME} PROPERTIES SUFFIX ${${NAME}_SUFFIX})
    endif()
    if(${NAME}_VISIBILITY)
        if(${NAME}_VISIBILITY STREQUAL "hidden")
            set_target_properties(${NAME} PROPERTIES VISIBILITY_INLINES_HIDDEN TRUE)
        endif()
        set_target_properties(${NAME} PROPERTIES
            C_VISIBILITY_PRESET ${${NAME}_VISIBILITY}
            CXX_VISIBILITY_PRESET ${${NAME}_VISIBILITY}
        )
    endif()
    if(CMAKE_BUILD_TYPE STREQUAL "Debug")
        target_compile_definitions(${NAME} PRIVATE DEBUG)
    endif()
    set_target_properties(${NAME} PROPERTIES EXCLUDE_FROM_ALL ${${NAME}_EXCLUDE_FROM_ALL})
    target_sources(${NAME} PRIVATE ${${NAME}_SOURCES})
    # Post-build install command.
    set(INSTALL_CMD)
    append_binary_install_command(INSTALL_CMD $<TARGET_FILE_NAME:${NAME}> DESTINATION ${_DESTINATION})
    add_custom_command(TARGET ${NAME} POST_BUILD VERBATIM ${INSTALL_CMD})
    # Custom finalization.
    string(REPLACE "-" "_" SETUP setup_${NAME})
    if(COMMAND ${SETUP})
        # Work around lack of `cmake_language(CALL …)` until version 3.18.
        set(FNAME ${CMAKE_CURRENT_BINARY_DIR}/${SETUP}.cmake)
        file(WRITE ${FNAME} "${SETUP}()\n")
        include(${FNAME})
    endif()
endfunction()

# KOREADER LIBRARIES. {{{

# blitbuffer
if(ANDROID OR CERVANTES OR KINDLE OR KOBO OR POCKETBOOK OR REMARKABLE OR SONY_PRSTUX OR USE_SDL)
    set(EXCLUDE_FROM_ALL)
else()
    set(EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
endif()
declare_koreader_target(
    blitbuffer TYPE library
    ${EXCLUDE_FROM_ALL}
    SOURCES blitbuffer.c
    VISIBILITY hidden
)
function(setup_blitbuffer)
    target_compile_options(blitbuffer PRIVATE SHELL:${VECTO_CFLAGS})
endfunction()

# koreade-cre
declare_koreader_target(
    koreader-cre TYPE library
    DEPENDS crengine::crengine luajit::luajit
    SOURCES cre.cpp
    SUFFIX .so
    VISIBILITY hidden
)

# koreader-djvu
declare_koreader_target(
    koreader-djvu TYPE library
    DEPENDS djvulibre::djvulibre libk2pdfopt::k2pdfopt luajit::luajit pthread
    SOURCES djvu.c
    SUFFIX .so
    VISIBILITY hidden
)

# kodeader-input
set(DEPENDS luajit::luajit)
if(KINDLE OR REMARKABLE)
    list(APPEND DEPENDS popen-noshell::popen-noshell)
elseif(POCKETBOOK)
    list(APPEND DEPENDS dl inkview pthread)
endif()
if(ANDROID OR USE_SDL)
    set(EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
else()
    set(EXCLUDE_FROM_ALL)
endif()
declare_koreader_target(
    koreader-input TYPE library
    DEPENDS ${DEPENDS}
    ${EXCLUDE_FROM_ALL}
    SOURCES input/input.c
    VISIBILITY hidden
)
function(setup_koreader_input)
    foreach(PLATFORM CERVANTES KOBO KINDLE LEGACY POCKETBOOK REMARKABLE SONY_PRSTUX)
        if(${PLATFORM})
            if(PLATFORM STREQUAL "LEGACY")
                set(PLATFORM KINDLE_LEGACY)
            endif()
            target_compile_definitions(koreader-input PRIVATE -D${PLATFORM})
        endif()
    endforeach()
endfunction()

# koreader-lfs
declare_koreader_target(
    koreader-lfs TYPE library
    DEPENDS luajit::luajit
    SOURCES lfs.c lfs.h
    VISIBILITY hidden
)
function(setup_koreader_lfs)
    # Ensure only the right symbols are exported.
    add_custom_command(
        COMMAND
        patch -p1
        --directory=${CMAKE_SOURCE_DIR}/luafilesystem
        --input=${CMAKE_SOURCE_DIR}/patches/lfs-visibility.patch
        --output=${CMAKE_BINARY_DIR}/lfs.h
        OUTPUT lfs.h
        DEPENDS ${CMAKE_SOURCE_DIR}/patches/lfs-visibility.patch
        MAIN_DEPENDENCY ${CMAKE_SOURCE_DIR}/luafilesystem/src/lfs.h
    )
    # Avoid precision loss on 32-bit arches (LFS is always built w/ LARGEFILE
    # support, but lua_Integer is always a ptrdiff_t, which is not wide enough).
    add_custom_command(
        COMMAND
        patch -p1
        --directory=${CMAKE_SOURCE_DIR}/luafilesystem
        --input=${CMAKE_SOURCE_DIR}/patches/lfs-pushnumber-for-wide-types.patch
        --output=${CMAKE_BINARY_DIR}/lfs.c
        OUTPUT lfs.c
        DEPENDS ${CMAKE_SOURCE_DIR}/patches/lfs-pushnumber-for-wide-types.patch
        MAIN_DEPENDENCY ${CMAKE_SOURCE_DIR}/luafilesystem/src/lfs.c
    )
    set_target_properties(koreader-lfs PROPERTIES SUFFIX .so)
endfunction()

# koreader-nnsvg
declare_koreader_target(
    koreader-nnsvg TYPE library
    DEPENDS luajit::luajit nanosvg::nanosvg
    SOURCES nnsvg.c
    SUFFIX .so
    VISIBILITY hidden
)

# koreader-xtext
declare_koreader_target(
    koreader-xtext TYPE library
    DEPENDS freetype2::freetype fribidi::fribidi harfbuzz::harfbuzz luajit::luajit libunibreak::unibreak
    SOURCES xtext.cpp
    SUFFIX .so
    VISIBILITY hidden
)

# wrap-mupdf
declare_koreader_target(
    wrap-mupdf TYPE library
    DEPENDS mupdf::mupdf
    SOURCES wrap-mupdf.c
    SUFFIX .so
    VISIBILITY hidden
)
function(setup_wrap_mupdf)
    target_exports(wrap-mupdf CDECLS mupdf_decl)
endfunction()

# }}}

# MISCELLANY. {{{

# extr
declare_koreader_target(
    extr TYPE executable
    DEPENDS mupdf::mupdf
    EXCLUDE_FROM_ALL
    SOURCES extr.c
)

# libXss
if(APPIMAGE)
    set(EXCLUDE_FROM_ALL)
else()
    set(EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
endif()
declare_koreader_target(
    Xss TYPE library
    ${EXCLUDE_FROM_ALL}
    SOURCES libxss-dummy.c
)
function(setup_Xss)
    set_target_properties(Xss PROPERTIES SOVERSION 1)
endfunction()

# koreader
if(DARWIN)
    set(EXCLUDE_FROM_ALL)
else()
    set(EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
endif()
declare_koreader_target(
    osx_loader TYPE executable
    DEPENDS luajit::luajit
    ${EXCLUDE_FROM_ALL}
    SOURCES osx_loader.c
)
function(setup_osx_loader)
    set_target_properties(osx_loader PROPERTIES OUTPUT_NAME koreader)
endfunction()

# inkview-compat
if(POCKETBOOK)
    set(EXCLUDE_FROM_ALL)
else()
    set(EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
endif()
declare_koreader_target(
    inkview-compat TYPE library
    DEPENDS inkview pthread
    ${EXCLUDE_FROM_ALL}
    SOURCES input/inkview-compat.c
)

# button-listen
if(REMARKABLE)
    set(EXCLUDE_FROM_ALL)
else()
    set(EXCLUDE_FROM_ALL EXCLUDE_FROM_ALL)
endif()
declare_koreader_target(
    button-listen TYPE executable
    ${EXCLUDE_FROM_ALL}
    SOURCES button-listen.c
)

# }}}

# vim: foldmethod=marker foldlevel=0
