# For some reason we need to include this again…
include(${CMAKE_KOVARS})

list(APPEND CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
    -DBUILD_SHARED_LIBS=FALSE
    # Project options.
    # Disable all auto features…
    -DAUTO=FALSE
    # …and force enable needed only.
    -DANTIWORD=TRUE
    -DCHMLIB=TRUE
    -DFREETYPE=TRUE
    -DFRIBIDI=TRUE
    -DGIF=TRUE
    -DHARFBUZZ=TRUE
    -DLIBJPEG=TRUE
    -DLIBPNG=TRUE
    -DLIBUNIBREAK=TRUE
    -DLIBWEBP=TRUE
    -DLUNASVG=TRUE
    -DMATHML=TRUE
    -DMD4C=TRUE
    -DSRELL=TRUE
    -DUTF8PROC=TRUE
    -DZLIB=TRUE
    -DZSTD=TRUE
    # Enable custom memory manager.
    -DOWN_MEM_MAN=TRUE
    # Disable some stuff on legacy platforms.
    -DDISABLE_CLOEXEC=$<BOOL:${LEGACY}>
    -DDISABLE_LFS=$<BOOL:${LEGACY}>
)

list(APPEND BUILD_CMD COMMAND ninja)

external_project(
    BUILD_ALWAYS
    CMAKE_ARGS ${CMAKE_ARGS}
    BUILD_COMMAND ${BUILD_CMD}
)
