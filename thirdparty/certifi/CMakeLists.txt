# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} -E copy_if_different certifi/cacert.pem ${OUTPUT_DIR}/data/ca-bundle.crt)

external_project(
    DOWNLOAD URL 09ac8b5eddc520f3f2d5e6f7ee949553
    https://files.pythonhosted.org/packages/59/8c/57e832b7af6d7c5abe66eb3fbe3a3a32f4d11ea23a1aa7131371035be991/certifi-2026.5.20-py3-none-any.whl
    INSTALL_COMMAND ${INSTALL_CMD}
)
