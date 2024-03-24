include(${CMAKE_CURRENT_LIST_DIR}/FindPackageHelper.cmake)
find_package_helper(Leptonica
    FIND_LIB_ARGS lept
    FIND_HDR_ARGS allheaders.h PATH_SUFFIXES leptonica
)
