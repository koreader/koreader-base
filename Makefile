include Makefile.defs

# As we do not want to run parallel ninja invocations into the
# same directory (e.g. when invoked with `make mupdf k2pdfopt`),
# we disable parallelisation for this top-level Makefile.
.NOTPARALLEL:

DO_STRIP := $(if $(or $(EMULATE_READER),$(KODEBUG)),,1)
DO_STRIP := $(if $(or $(DO_STRIP),$(APPIMAGE),$(LINUX)),1,)

$(info ************ Building for MACHINE: "$(MACHINE)" **********)
$(info ************ PATH: "$(PATH)" **********)
$(info ************ CHOST: "$(CHOST)" **********)
$(info ************ NINJA: $(strip $(NINJA) $(PARALLEL_JOBS:%=-j%) $(PARALLEL_LOAD:%=-l%)) **********)
$(info ************ MAKE: $(strip $(MAKE) $(PARALLEL_JOBS:%=-j%) $(PARALLEL_LOAD:%=-l%)) **********)

PHONY = all bindeps clean distclean fetchthirdparty libcheck %-re re setup skeleton test test-data

.PHONY: $(PHONY)

# Main rules. {{{

all: $(BUILD_ENTRYPOINT)

clean:
	rm -rf $(OUTPUT_DIR)

distclean:
	rm -rf build $(wildcard $(THIRDPARTY_DIR)/*/build)

re: clean
	$(MAKE) all

%-re:
	$(MAKE) $*-clean
	$(MAKE) $*

setup: $(BUILD_ENTRYPOINT)

fetchthirdparty:
	git submodule init
	git submodule sync
	git submodule update --jobs 3 $(if $(CI),--depth 1)

# }}}

# CMake build interface. {{{

$(BUILD_ENTRYPOINT): $(CMAKE_KOVARS) $(CMAKE_TCF)
	$(CMAKE) $(CMAKE_FLAGS) -S cmake -B $(CMAKE_DIR)

define newline


endef

define escape
'$(subst $(newline),' ',$(subst ','"'"',$(call $1)))'
endef

$(CMAKE_KOVARS): Makefile.defs | $(CMAKE_DIR)/
	@printf '%s\n' $(call escape,cmake_koreader_vars) >'$@'

$(CMAKE_TCF): Makefile.defs | $(CMAKE_DIR)/
	@printf '%s\n' $(call escape,$(if $(EMULATE_READER),cmake_toolchain,cmake_cross_toolchain)) >'$@'

# Forward unknown targets to the CMake build system.
LEFTOVERS = $(filter-out $(PHONY) cache-key build/%,$(MAKECMDGOALS))
.PHONY: $(LEFTOVERS)
all $(LEFTOVERS): skeleton $(BUILD_ENTRYPOINT)
	$(and $(DRY_RUN),$(wildcard $(BUILD_ENTRYPOINT)),+)$(strip $(CMAKE_MAKE_PROGRAM) -C $(CMAKE_DIR) $@)

# }}}

# Output skeleton. {{{

define SKELETON
$(CMAKE_DIR)/
$(OUTPUT_DIR)/cache/
$(OUTPUT_DIR)/clipboard/
$(OUTPUT_DIR)/data/cr3.css
$(OUTPUT_DIR)/ffi
$(OUTPUT_DIR)/fonts/
$(STAGING_DIR)/
endef
ifneq (,$(EMULATE_READER))
define SKELETON +=
$(OUTPUT_DIR)/spec/base
endef
endif

skeleton: $(strip $(SKELETON))

$(OUTPUT_DIR)/data: | $(OUTPUT_DIR)/
	$(SYMLINK) $(abspath $(THIRDPARTY_DIR)/kpvcrlib/crengine/cr3gui/data) $@

$(OUTPUT_DIR)/data/cr3.css: | $(OUTPUT_DIR)/data
	$(SYMLINK) $(abspath $(THIRDPARTY_DIR)/kpvcrlib/cr3.css) $@

$(OUTPUT_DIR)/ffi: | $(OUTPUT_DIR)/
	$(SYMLINK) $(abspath ffi) $@

build/%/:
	mkdir -p $@

# }}}

# Testsuite support. {{{

ifneq (,$(EMULATE_READER))

$(OUTPUT_DIR)/.busted: | $(OUTPUT_DIR)/
	$(SYMLINK) $(abspath .busted) $@

$(OUTPUT_DIR)/spec/base: | $(OUTPUT_DIR)/spec/
	$(SYMLINK) $(abspath spec) $@

test: all test-data
	cd $(OUTPUT_DIR) && $(BUSTED_LUAJIT) ./spec/base/unit

test-data: $(OUTPUT_DIR)/.busted $(OUTPUT_DIR)/data/tessdata/eng.traineddata $(OUTPUT_DIR)/spec/base $(OUTPUT_DIR)/fonts/droid/DroidSansMono.ttf

TESSDATA_FILE = thirdparty/tesseract/build/downloads/eng.traineddata
TESSDATA_FILE_URL = https://github.com/tesseract-ocr/tessdata/raw/4.1.0/$(notdir $(TESSDATA_FILE))
TESSDATA_FILE_SHA1 = 007b522901a665bc2037428602d4d527f5ead7ed

$(OUTPUT_DIR)/data/tessdata/eng.traineddata: $(TESSDATA_FILE) | $(OUTPUT_DIR)/data/tessdata/
	$(SYMLINK) $(abspath $(TESSDATA_FILE)) $@

$(TESSDATA_FILE):
	mkdir -p $(dir $(TESSDATA_FILE))
	$(call wget_and_validate,$(TESSDATA_FILE),$(TESSDATA_FILE_URL),$(TESSDATA_FILE_SHA1))

DROID_FONT = thirdparty/fonts/build/downloads/DroidSansMono.ttf
DROID_FONT_URL = https://github.com/koreader/koreader-fonts/raw/master/droid/$(notdir $(DROID_FONT))
DROID_FONT_SHA1 = 0b75601f8ef8e111babb6ed11de6573f7178ce44

$(OUTPUT_DIR)/fonts/droid/DroidSansMono.ttf: $(DROID_FONT) | $(OUTPUT_DIR)/fonts/
	$(SYMLINK) $(abspath $(dir $(DROID_FONT))) $(OUTPUT_DIR)/fonts/droid

$(DROID_FONT):
	mkdir -p $(dir $(DROID_FONT))
	$(call wget_and_validate,$(DROID_FONT),$(DROID_FONT_URL),$(DROID_FONT_SHA1))

endif

# }}}

# CI helpers. {{{

define cache_key_ignores
':!*.lua'
':!*/.*'
':!/.*'
':!/COPYING'
':!/README.md'
':!/ffi-cdecl/*'
':!/spec/*'
':!/toolchain/*'
':!/utils/*'
endef

cache-key: Makefile
	git ls-files -z $(strip $(cache_key_ignores)) | xargs -0 git ls-tree @ | tee $@

# }}}

# Dump binaries runtime path and dependencies. {{{

bindeps:
	@./utils/bindeps.sh $(filter-out $(addprefix $(OUTPUT_DIR)/,cmake staging thirdparty),$(wildcard $(OUTPUT_DIR)/*))

# }}}

# Checking libraries for missing dependencies. {{{

# NOTE: the extra `$(filter %/,…)` is to work around some older versions
# of make (e.g. 4.2.1) returning files too when using `$(wildcard …/*/)`.
libcheck:
	@./utils/libcheck.sh $(CC) $(LDFLAGS) -Wl,-rpath-link=$(OUTPUT_DIR)/libs -- '$(if $(USE_LUAJIT_LIB),,1)' $(filter %/,$(filter-out $(OUTPUT_DIR)/thirdparty/,$(wildcard $(OUTPUT_DIR)/*/)))

ifneq (,$(POCKETBOOK))
libcheck: utils/libcheck/libinkview.so
utils/libcheck/libinkview.so: utils/libcheck/libinkview.ld
	$(LD) -shared -o $@ $<
endif

# }}}

# vim: foldmethod=marker foldlevel=0
