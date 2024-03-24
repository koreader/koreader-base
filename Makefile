include Makefile.defs

# As we do not want to run parallel ninja invocations into the
# same directory (e.g. when invoked with `make mupdf k2pdfopt`),
# we disable parallelisation for this top-level Makefile.
.NOTPARALLEL:

DO_STRIP := $(if $(or $(EMULATE_READER),$(KODEBUG)),,1)
DO_STRIP := $(if $(or $(DO_STRIP),$(APPIMAGE),$(DEBIAN)),1,)

$(info ************ Building for MACHINE: "$(MACHINE)" **********)
$(info ************ PATH: "$(PATH)" **********)
$(info ************ CHOST: "$(CHOST)" **********)

PHONY = all clean distclean fetchthirdparty %-re re setup skeleton test test-data

.PHONY: $(PHONY)

# Main rules. {{{

all: skeleton $(BUILD_ENTRYPOINT)

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
	git submodule foreach --recursive git reset --hard
	git submodule update
	@echo "cleaning up crengine checkout..."
	@rm -rf thirdparty/kpvcrlib/crengine/thirdparty
	@test -d thirdparty/kpvcrlib/crengine \
		&& (cd thirdparty/kpvcrlib/crengine; git checkout .) \
		|| echo warn: crengine folder not found

# }}}

# CMake build interface. {{{

$(BUILD_ENTRYPOINT): $(CMAKE_KO) $(CMAKE_TCF)
	$(CMAKE) $(CMAKE_FLAGS) -S . -B $(CMAKE_DIR)

define newline


endef

define escape
'$(subst $(newline),' ',$(subst ','"'"',$(call $1)))'
endef

$(CMAKE_KO): Makefile.defs | $(CMAKE_DIR)/
	@printf '%s\n' $(call escape,cmake_koreader) >'$@'

$(CMAKE_TCF): Makefile.defs | $(CMAKE_DIR)/
	@printf '%s\n' $(call escape,$(if $(EMULATE_READER),cmake_toolchain,cmake_cross_toolchain)) >'$@'

# Forward unknown targets to the CMake build system.
LEFTOVERS = $(filter-out $(PHONY) build/%,$(MAKECMDGOALS))
.PHONY: $(LEFTOVERS)
all $(LEFTOVERS): $(BUILD_ENTRYPOINT)
	$(and $(DRY_RUN),$(wildcard $(BUILD_ENTRYPOINT)),+)$(strip \
		$(CMAKE_MAKE_PROGRAM) $(CMAKE_MAKE_PROGRAM_FLAGS) \
		-C $(CMAKE_DIR) $@)

# }}}

# Output skeleton. {{{

define SKELETON
$(CMAKE_DIR)/
$(OUTPUT_DIR)/cache/
$(OUTPUT_DIR)/clipboard/
$(OUTPUT_DIR)/data/cr3.css
$(OUTPUT_DIR)/ffi
$(OUTPUT_DIR)/fonts/
$(OUTPUT_DIR)/plugins/
$(STAGING_DIR)/
endef

skeleton: $(strip $(SKELETON))

$(OUTPUT_DIR)/data: | $(OUTPUT_DIR)/
	ln -snf $(abspath $(THIRDPARTY_DIR)/kpvcrlib/crengine/cr3gui/data) $@

$(OUTPUT_DIR)/data/cr3.css: | $(OUTPUT_DIR)/data
	ln -snf $(abspath $(THIRDPARTY_DIR)/kpvcrlib/cr3.css) $@

$(OUTPUT_DIR)/ffi: | $(OUTPUT_DIR)/
	ln -snf ../../ffi $@

build/%/:
	mkdir -p $@

# }}}

# Testsuite support. {{{

ifneq (,$(EMULATE_READER))

$(OUTPUT_DIR)/.busted: | $(OUTPUT_DIR)/
	ln -snf ../../.busted $@

$(OUTPUT_DIR)/spec/base: | $(OUTPUT_DIR)/spec/
	ln -snf ../../../spec $@

test: all test-data
	eval "$$($(LUAROCKS_BINARY) path)" && cd $(OUTPUT_DIR) && \
		env TESSDATA_DIR=$(OUTPUT_DIR)/data \
		./luajit "$$(which busted)" \
		--exclude-tags=notest \
		-o gtest ./spec/base/unit

test-data: $(OUTPUT_DIR)/.busted $(OUTPUT_DIR)/data/tessdata/eng.traineddata $(OUTPUT_DIR)/spec/base $(OUTPUT_DIR)/fonts/droid/DroidSansMono.ttf

TESSDATA_DIST = thirdparty/tesseract/build/downloads/tesseract-ocr-3.02.eng.tar.gz
TESSDATA_DIST_URL = https://src.fedoraproject.org/repo/pkgs/tesseract/$(notdir $(TESSDATA_DIST))/3562250fe6f4e76229a329166b8ae853/$(notdir $(TESSDATA_DIST))
TESSDATA_DIST_SHA1 = 989ed4c3a5b246d7353893e466c353099d8b73a1

$(OUTPUT_DIR)/data/tessdata/eng.traineddata: $(TESSDATA_DIST) | $(OUTPUT_DIR)/data
	tar xzf $(TESSDATA_DIST) --strip-components=1 -C $(OUTPUT_DIR)/data
	touch $@

$(TESSDATA_DIST):
	mkdir -p $(dir $(TESSDATA_DIST))
	$(call wget_and_validate,$(TESSDATA_DIST),$(TESSDATA_DIST_URL),$(TESSDATA_DIST_SHA1))

DROID_FONT = thirdparty/fonts/build/downloads/DroidSansMono.ttf
DROID_FONT_URL = https://github.com/koreader/koreader-fonts/raw/master/droid/$(notdir $(DROID_FONT))
DROID_FONT_SHA1 = 0b75601f8ef8e111babb6ed11de6573f7178ce44

$(OUTPUT_DIR)/fonts/droid/DroidSansMono.ttf: $(DROID_FONT) | $(OUTPUT_DIR)/fonts/droid/
	cp $^ $@

$(DROID_FONT):
	mkdir -p $(dir $(DROID_FONT))
	$(call wget_and_validate,$(DROID_FONT),$(DROID_FONT_URL),$(DROID_FONT_SHA1))

endif

# }}}

# vim: foldmethod=marker foldlevel=0
