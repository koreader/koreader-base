# Build in source tree.
set(BINARY_DIR ${SOURCE_DIR})

external_project(
    DOWNLOAD GIT 573e64298c47b1f8e444640d89e80df4b8e2808f
    https://github.com/koreader/pocketbook-inkview.git
)
