include Makefile.defs

DO_STRIP := $(if $(or $(EMULATE_READER),$(KODEBUG)),,1)
DO_STRIP := $(if $(or $(DO_STRIP),$(APPIMAGE),$(DEBIAN)),1,)

ifeq (,$(MAKE_RESTARTS))
$(info ************ Building for MACHINE: "$(MACHINE)" **********)
$(info ************ PATH: "$(PATH)" **********)
$(info ************ CHOST: "$(CHOST)" **********)
endif

PHONY = all clean distclean fetch-cmake fetchthirdparty %-re re skeleton test test-data 

.PHONY: $(PHONY)

# Main rules. {{{

all: skeleton $(BUILD_NINJA)

clean:
	rm -rf $(CMAKE_DIR) $(STAGING_DIR) $(OUTPUT_DIR) $(wildcard $(THIRDPARTY_DIR)/*/build/$(MACHINE))

distclean:
	rm -rf build $(wildcard $(THIRDPARTY_DIR)/*/build)

re: clean
	$(MAKE) all

%-re:
	$(MAKE) $*-clean
	$(MAKE) $*

# }}}

# CMake build interface.

include Makefile.third

$(BUILD_NINJA): $(CMAKE_KO) $(CMAKE_TCF)
	$(CMAKE) $(CMAKE_FLAGS) -S . -B $(CMAKE_DIR)

# Forward unknown targets to the CMake build system.
LEFTOVERS = $(filter-out $(PHONY) build/% serial%,$(MAKECMDGOALS))
.PHONY: $(LEFTOVERS)
all $(LEFTOVERS): $(BUILD_NINJA)
	$(and $(DRY_RUN),$(wildcard $(BUILD_NINJA)),+)$(strip \
		$(CMAKE_MAKE_PROGRAM) $(CMAKE_MAKE_PROGRAM_FLAGS) \
		-C $(CMAKE_DIR) \
		$(if $(KEEP_GOING),-k$(if $(USE_NINJA),0)) \
		$(if $(DRY_RUN),-nv) \
		$@)

# }}}

# Support for installing cmake from official release.

CMAKE_DIST = cmake-3.27.8-linux-x86_64.tar.gz
CMAKE_DIST_URL = https://github.com/Kitware/CMake/releases/download/v3.27.8/$(CMAKE_DIST)
CMAKE_DIST_SHA1 = 7b2d35e868011294cd852d272d18bbc2af9ed5b2

fetch-cmake: cmake/bin/cmake

cmake/bin/cmake: $(CMAKE_DIST)
	mkdir -p cmake
	tar xzf $(CMAKE_DIST) --strip-components=1 -C cmake
	rm -f $(CMAKE_DIST)

.SECONDARY: $(CMAKE_DIST)

$(CMAKE_DIST):
	$(call wget_and_validate,$(CMAKE_DIST),$(CMAKE_DIST_URL),$(CMAKE_DIST_SHA1))

# }}}

# Output skeleton. {{{

define SKELETON
$(CMAKE_DIR)/
$(OUTPUT_DIR)/.busted
$(OUTPUT_DIR)/cache/
$(OUTPUT_DIR)/clipboard/
$(OUTPUT_DIR)/data/cr3.css
$(OUTPUT_DIR)/ffi
$(OUTPUT_DIR)/fonts/
$(OUTPUT_DIR)/plugins/
$(OUTPUT_DIR)/spec/base
$(STAGING_DIR)/
endef

skeleton: $(strip $(SKELETON))

$(OUTPUT_DIR)/.busted: | $(OUTPUT_DIR)/
	ln -snf ../../.busted $@

$(OUTPUT_DIR)/data: | $(OUTPUT_DIR)/
	ln -snf $(abspath $(THIRDPARTY_DIR)/kpvcrlib/crengine/cr3gui/data) $@

$(OUTPUT_DIR)/data/cr3.css: | $(OUTPUT_DIR)/data
	ln -snf $(abspath $(THIRDPARTY_DIR)/kpvcrlib/cr3.css) $@

$(OUTPUT_DIR)/ffi: | $(OUTPUT_DIR)/
	ln -snf ../../ffi $@

$(OUTPUT_DIR)/spec/base: | $(OUTPUT_DIR)/spec/
	ln -snf ../../../spec $@

build/%/:
	mkdir -p $@

# }}}

# Testsuite support. {{{

test: all test-data
	eval "$$($(LUAROCKS_BINARY) path)" && cd $(OUTPUT_DIR) && \
		env TESSDATA_DIR=$(OUTPUT_DIR)/data \
		./luajit "$$(which busted)" \
		--exclude-tags=notest \
		-o gtest ./spec/base/unit

test-data: $(OUTPUT_DIR)/.busted $(OUTPUT_DIR)/data/tessdata/eng.traineddata $(OUTPUT_DIR)/spec/base $(OUTPUT_DIR)/fonts/droid/DroidSansMono.ttf

TESSDATA_DIST = tesseract-ocr-3.02.eng.tar.gz
TESSDATA_DIST_URL = https://src.fedoraproject.org/repo/pkgs/tesseract/$(TESSDATA_DIST)/3562250fe6f4e76229a329166b8ae853/$(TESSDATA_DIST)
TESSDATA_DIST_SHA1 = 989ed4c3a5b246d7353893e466c353099d8b73a1

$(OUTPUT_DIR)/data/tessdata/eng.traineddata: $(TESSDATA_DIST) | $(OUTPUT_DIR)/data
	tar xzf $(TESSDATA_DIST) --strip-components=1 -C $(OUTPUT_DIR)/data
	rm -f $(TESSDATA_DIST)

.SECONDARY: $(TESSDATA_DIST)

$(TESSDATA_DIST):
	$(call wget_and_validate,$(TESSDATA_DIST),$(TESSDATA_DIST_URL),$(TESSDATA_DIST_SHA1))

DROID_FONT = DroidSansMono.ttf
DROID_FONT_URL = https://github.com/koreader/koreader-fonts/raw/master/droid/$(DROID_FONT)
DROID_FONT_SHA1 = 0b75601f8ef8e111babb6ed11de6573f7178ce44

$(OUTPUT_DIR)/fonts/droid/DroidSansMono.ttf: $(DROID_FONT) | $(OUTPUT_DIR)/fonts/droid/
	cp $^ $@
	rm -f $^

.SECONDARY: $(DROID_FONT)

$(DROID_FONT):
	$(call wget_and_validate,$(DROID_FONT),$(DROID_FONT_URL),$(DROID_FONT_SHA1))

# }}}

# Hack to seriallize goals. {{{

ifneq (,$(filter serial,$(MAKECMDGOALS)))
.PHONY: serial%
serial%:
	for goal in $(filter-out serial,$@); do $(MAKE) "$$goal" || exit $$?; done
endif

# }}}
