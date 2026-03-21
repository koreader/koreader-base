# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

external_project(
    DOWNLOAD GIT 4a3e32c39ed14ac7f2e3ca4f8c66a7d5fbe5e0fe
    https://github.com/koreader/pocketbook-inkview.git
)
