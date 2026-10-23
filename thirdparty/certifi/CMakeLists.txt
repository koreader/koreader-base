# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} -E copy_if_different certifi/cacert.pem ${OUTPUT_DIR}/data/ca-bundle.crt)

external_project(
    DOWNLOAD URL f8e2ea95de0d04faf08b80e3535fa148
    https://files.pythonhosted.org/packages/32/d1/a3652fe2c19134d0d15922177821d863cbd7e842d53a21bbe7e8e3a1b5ac/certifi-2026.10.23-py3-none-any.whl
    INSTALL_COMMAND ${INSTALL_CMD}
)
