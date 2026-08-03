# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} -E copy_if_different certifi/cacert.pem ${OUTPUT_DIR}/data/ca-bundle.crt)

external_project(
    DOWNLOAD URL edeeb8218c0de1993d874d818064553c
    https://files.pythonhosted.org/packages/0b/a7/71ac2cff56fec219ed242bb11b8efb69fcc4bec75db06fb7bfe35de520e6/certifi-2026.7.22-py3-none-any.whl
    INSTALL_COMMAND ${INSTALL_CMD}
)
