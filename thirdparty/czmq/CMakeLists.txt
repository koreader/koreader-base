list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake_tweaks.patch)
if(NOT DARWIN)
    # patch: ignore limited broadcast address
    list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/zbeacon.patch)
    # patch: add _DEFAULT_SOURCE define for glibc starting at version 2.20
    list(APPEND PATCH_CMD COMMAND ${KO_PATCH} ${CMAKE_CURRENT_SOURCE_DIR}/czmq_default_source_define.patch)
endif()

# Make sure the daisy-chain once again picks up our toolchain file...
list(APPEND CMAKE_ARGS "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TCF}")

list(APPEND BUILD_CMD COMMAND ${KO_MAKE_PROGRAM} czmq)

set(LIB_SPEC czmq VERSION 1)
set_libname(LIB ${LIB_SPEC})

# Install shared lib.
append_shared_lib_install_command(INSTALL_CMD BYPRODUCTS ${LIB} ${LIB_SPEC})

# Install headers.
append_headers_install_command(
    INSTALL_CMD BYPRODUCTS
    FROM "${SOURCE_DIR}/include"
    czmq.h czmq_prelude.h zactor.h zauth.h zbeacon.h zcert.h zcertstore.h
    zchunk.h zclock.h zconfig.h zctx.h zdigest.h zdir.h zdir_patch.h zfile.h
    zframe.h zgossip.h zhash.h zlist.h zloop.h zmonitor.h zmsg.h zmutex.h
    zpoller.h zproxy.h zrex.h zsocket.h zsock.h zsock_monitor.h zsockopt.h
    zsock_option.h zstr.h zsys.h zthread.h zuuid.h
)

ko_write_gitclone_script(
    GIT_CLONE_SCRIPT_FILENAME
    https://github.com/zeromq/czmq.git
    2a0ddbc4b2dde623220d7f4980ddd60e910cfa78
    ${SOURCE_DIR}
)

thirdparty_project(
    DOWNLOAD_COMMAND ${CMAKE_COMMAND} -P ${GIT_CLONE_SCRIPT_FILENAME}
    PATCH_COMMAND ${PATCH_CMD}
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
    INSTALL_COMMAND ${INSTALL_CMD}
    BYPRODUCTS ${BYPRODUCTS}
)
