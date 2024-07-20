include Makefile.defs

# As we do not want to run parallel ninja invocations into the
# same directory (e.g. when invoked with `make mupdf k2pdfopt`),
# we disable parallelisation for this top-level Makefile.
.NOTPARALLEL:

DO_STRIP := $(if $(or $(EMULATE_READER),$(KODEBUG)),,1)
DO_STRIP := $(if $(or $(DO_STRIP),$(APPIMAGE),$(LINUX)),1,)

define build_info
$(info ************ Building for MACHINE: "$(MACHINE)" **********)
$(info ************ PATH: "$(PATH)" **********)
$(info ************ CHOST: "$(CHOST)" **********)
$(info ************ NINJA: $(strip $(NINJA) $(PARALLEL_JOBS:%=-j%) $(PARALLEL_LOAD:%=-l%)) **********)
$(info ************ MAKE: $(strip $(MAKE) $(PARALLEL_JOBS:%=-j%) $(PARALLEL_LOAD:%=-l%)) **********)
endef

PHONY = all bindeps buildstats clean distclean fetchthirdparty info libcheck %-re re reinstall setup skeleton test test-data uninstall

.PHONY: $(PHONY)

# Main rules. {{{

all: $(BUILD_ENTRYPOINT)

clean:
	rm -rf $(OUTPUT_DIR)

distclean:
	rm -rf build $(wildcard $(THIRDPARTY_DIR)/*/build)

info:
	$(strip $(build_info))

re: clean
	$(MAKE) all

%-re:
	$(MAKE) $*-clean
	$(MAKE) $*

fetchthirdparty:
	git submodule init
	git submodule sync
	git submodule update --jobs 3 $(if $(CI),--depth 1)

reinstall: uninstall
	$(MAKE)

uninstall:
	rm -vrf $(filter-out $(CMAKE_DIR) $(OUTPUT_DIR)/thirdparty,$(wildcard $(OUTPUT_DIR)/*))
	$(MAKE) rm-install-stamps

# }}}

# CMake build interface. {{{

setup $(BUILD_ENTRYPOINT): $(CMAKE_KOVARS) $(CMAKE_TCF)
	$(strip $(build_info))
	$(CMAKE) $(CMAKE_FLAGS) -S cmake -B $(CMAKE_DIR)

define write_file
$(if $(DRY_RUN),: write $1,$(file >$1,$2))
endef

$(CMAKE_KOVARS): Makefile.defs | $(CMAKE_DIR)/
	$(call write_file,$@,$(cmake_koreader_vars))

$(CMAKE_TCF): Makefile.defs | $(CMAKE_DIR)/
	$(call write_file,$@,$(if $(EMULATE_READER),$(cmake_toolchain),$(cmake_cross_toolchain)))

# Forward unknown targets to the CMake build system.
LEFTOVERS = $(filter-out $(PHONY) cache-key build/%,$(MAKECMDGOALS))
.PHONY: $(LEFTOVERS)
all $(LEFTOVERS): skeleton $(BUILD_ENTRYPOINT)
	$(and $(DRY_RUN),$(wildcard $(BUILD_ENTRYPOINT)),+)cd $(CMAKE_DIR) && $(strip $(NINJA) $(NINJAFLAGS) $@)

# }}}

# Output skeleton. {{{

CR3GUI_DATADIR = $(THIRDPARTY_DIR)/kpvcrlib/crengine/cr3gui/data

define CR3GUI_DATADIR_EXCLUDES
%/KoboUSBMS.tar.gz
%/cr3.ini
%/cr3skin-format.txt
%/desktop
%/devices
%/manual
endef

define SKELETON
$(CMAKE_DIR)/
$(OUTPUT_DIR)/cache/
$(OUTPUT_DIR)/clipboard/
$(OUTPUT_DIR)/data/
$(OUTPUT_DIR)/data/cr3.css
$(OUTPUT_DIR)/data/dict
$(OUTPUT_DIR)/data/tessdata
$(OUTPUT_DIR)/ffi
$(OUTPUT_DIR)/fonts/
$(STAGING_DIR)/
endef
ifneq (,$(EMULATE_READER))
define SKELETON +=
$(OUTPUT_DIR)/spec/base
endef
endif
SKELETON += $(addprefix $(OUTPUT_DIR)/data/,$(notdir $(filter-out $(CR3GUI_DATADIR_EXCLUDES),$(wildcard $(CR3GUI_DATADIR)/*))))

skeleton: $(strip $(SKELETON))

$(OUTPUT_DIR)/data/cr3.css: | $(OUTPUT_DIR)/data/
	$(SYMLINK) $(THIRDPARTY_DIR)/kpvcrlib/cr3.css $@

$(OUTPUT_DIR)/data/%: $(CR3GUI_DATADIR)/% | $(OUTPUT_DIR)/data/
	$(SYMLINK) $(CR3GUI_DATADIR)/$* $@

$(CR3GUI_DATADIR)/%:
	mkdir $@

$(OUTPUT_DIR)/ffi: | $(OUTPUT_DIR)/
	$(SYMLINK) ffi $@

build/%/:
	mkdir -p $@

# }}}

# Testsuite support. {{{

ifneq (,$(EMULATE_READER))

$(OUTPUT_DIR)/.busted: | $(OUTPUT_DIR)/
	$(SYMLINK) .busted $@

$(OUTPUT_DIR)/spec/base: | $(OUTPUT_DIR)/spec/
	$(SYMLINK) spec $@

test: all test-data
	cd $(OUTPUT_DIR) && $(BUSTED_LUAJIT) ./spec/base/unit

test-data: $(OUTPUT_DIR)/.busted $(OUTPUT_DIR)/data/tessdata/eng.traineddata $(OUTPUT_DIR)/spec/base $(OUTPUT_DIR)/fonts/droid/DroidSansMono.ttf

TESSDATA_FILE = thirdparty/tesseract/build/downloads/eng.traineddata
TESSDATA_FILE_URL = https://github.com/tesseract-ocr/tessdata/raw/4.1.0/$(notdir $(TESSDATA_FILE))
TESSDATA_FILE_SHA1 = 007b522901a665bc2037428602d4d527f5ead7ed

$(OUTPUT_DIR)/data/tessdata/eng.traineddata: $(TESSDATA_FILE) | $(OUTPUT_DIR)/data/tessdata
	$(SYMLINK) $(TESSDATA_FILE) $@

$(TESSDATA_FILE):
	mkdir -p $(dir $(TESSDATA_FILE))
	$(call wget_and_validate,$(TESSDATA_FILE),$(TESSDATA_FILE_URL),$(TESSDATA_FILE_SHA1))

DROID_FONT = thirdparty/fonts/build/downloads/DroidSansMono.ttf
DROID_FONT_URL = https://github.com/koreader/koreader-fonts/raw/master/droid/$(notdir $(DROID_FONT))
DROID_FONT_SHA1 = 0b75601f8ef8e111babb6ed11de6573f7178ce44

$(OUTPUT_DIR)/fonts/droid/DroidSansMono.ttf: $(DROID_FONT) | $(OUTPUT_DIR)/fonts/
	$(SYMLINK) $(dir $(DROID_FONT)) $(OUTPUT_DIR)/fonts/droid

$(DROID_FONT):
	mkdir -p $(dir $(DROID_FONT))
	$(call wget_and_validate,$(DROID_FONT),$(DROID_FONT_URL),$(DROID_FONT_SHA1))

endif

# }}}

# CI helpers. {{{

define cache_key_cmd
git ls-files -z
--cached --ignored --exclude-from=$(abspath $1)
| xargs -0 git ls-tree @
endef

cache-key: Makefile cache-key.base
	$(strip $(call cache_key_cmd,cache-key.base)) | tee $@

# }}}

# Dump binaries runtime path and dependencies. {{{

bindeps:
	@./utils/bindeps.sh $(filter-out $(addprefix $(OUTPUT_DIR)/,cmake staging thirdparty),$(wildcard $(OUTPUT_DIR)/*))

# }}}

# Dump build timings for last ninja invocation. {{{

# Show external project tasks with a duration of 1s or more (descending order).
define buildstats_jq_script
  sort_by(-.dur) | .[] | select(.dur >= 1e6) | (.dur*1e-5 | round | ./10), "\n",
  (.name | sub("(.*[/ ])?(?<p>[^/]*)/stamp/(?<t>[^/]*)$$"; "\(.p) \(.t)")), "\n"
endef

buildstats: $(CMAKE_DIR)/.ninja_log
	ninjatracing $< | jq -j '$(strip $(buildstats_jq_script))' | \
	    xargs -n3 printf '%6.2fs %s %s\n' | \
	    git column --mode=row

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

ifneq (,$(KINDLE))
libcheck: utils/libcheck/liblipc.so
utils/libcheck/liblipc.so: utils/libcheck/liblipc.ld
	$(LD) -shared -o $@ $<
endif

# }}}

# vim: foldmethod=marker foldlevel=0
