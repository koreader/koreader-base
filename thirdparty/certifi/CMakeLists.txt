# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

list(APPEND INSTALL_CMD COMMAND ${CMAKE_COMMAND} -E copy_if_different certifi/cacert.pem ${OUTPUT_DIR}/data/ca-bundle.crt)

external_project(
    DOWNLOAD URL 3b14da8e2efaade7cd0ff168139c7868
    https://files.pythonhosted.org/packages/ef/2f/c5464532e965badff2f4c4c1a3a83f5697f0d7c407ed0cda44aaa99bb451/certifi-2026.6.17-py3-none-any.whl
    INSTALL_COMMAND ${INSTALL_CMD}
)
