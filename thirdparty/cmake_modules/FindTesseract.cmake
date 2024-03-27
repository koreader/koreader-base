include(${CMAKE_CURRENT_LIST_DIR}/FindPackageHelper.cmake)
find_package_helper(Tesseract
    FIND_LIB_ARGS tesseract
    FIND_HDR_ARGS tesscallback.h PATH_SUFFIXES tesseract
)
