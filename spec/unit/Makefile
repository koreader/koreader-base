all: mo

KOREADER_MISC_TOOL=../../../misc
XGETTEXT_BIN=$(KOREADER_MISC_TOOL)/gettext/lua_xgettext.py
L10N_DIR=l10n
MO_DIR=i18n

pot:
	$(XGETTEXT_BIN) gettext_spec.lua \
		> data/l10n/templates/koreader.pot

po:
	test -d data/$(L10N_DIR)/zh_CN || mkdir -p data/l10n/zh_CN
	for lang in `ls data/$(L10N_DIR) | grep -v templates`; do \
		cd data/$(L10N_DIR)/$$lang && \
			echo data/$(L10N_DIR)/$$lang && \
			mv koreader.po koreader.old.po; \
			if msgmerge -N -o koreader.po koreader.old.po \
					../templates/koreader.pot; then \
				rm koreader.old.po; \
			else \
				rm -f koreader.po; \
				mv koreader.old.po koreader.po; \
			fi && \
		cd - ; \
	done

mo:
	cd data && \
		for po in `find l10n -iname '*.po'`; do \
			resource=`basename $$po .po` ; \
			lingua=`dirname $$po | xargs basename` ; \
			mkdir -p $(MO_DIR)/$$lingua/LC_MESSAGES/ ; \
			msgfmt -o $(MO_DIR)/$$lingua/LC_MESSAGES/$$resource.mo $$po ; \
		done


.PHONY: all clean

