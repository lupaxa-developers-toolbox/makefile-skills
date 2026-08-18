MKDOCS        ?= mkdocs
MKDOCS_CONFIG ?= mkdocs.yml
MKDOCS_HOST   ?= 127.0.0.1
MKDOCS_PORT   ?= 8000

STATUS_FRAGMENTS += status-mkdocs

.PHONY: help-mkdocs status-mkdocs mkdocs-doctor mkdocs-build mkdocs-serve mkdocs-clean

help-mkdocs:
	$(call mf_help_header,Documentation (MkDocs):)
	@echo "  mkdocs-doctor       Check MkDocs config and tools"
	@echo "  mkdocs-build        Build the static MkDocs site"
	@echo "  mkdocs-serve        Serve MkDocs with live reload"
	@echo "  mkdocs-clean        Remove the generated site/ directory"
	@echo
	@echo "  mkdocs-serve uses $(MKDOCS_HOST):$(MKDOCS_PORT) by default."
	@echo "  Override with MKDOCS_PORT / MKDOCS_HOST, e.g.:"
	@echo "    make mkdocs-serve MKDOCS_PORT=8001"
	@echo

status-mkdocs:
	@$(mf_color_prelude) \
	mf_color_init; \
	mf_heading "Documentation:"; \
	if [ -f "$(MKDOCS_CONFIG)" ]; then \
		mf_tagged "Configuration:" green "[OK]" "$(MKDOCS_CONFIG)"; \
	else \
		mf_tagged "Configuration:" red "[MISSING]" "$(MKDOCS_CONFIG)"; \
	fi; \
	mf_plain "Serve address:" "$(MKDOCS_HOST):$(MKDOCS_PORT)"; \
	if command -v "$(MKDOCS)" >/dev/null 2>&1; then \
		mf_tagged "MkDocs:" green "[OK]" "$$(command -v "$(MKDOCS)")"; \
	else \
		mf_tagged "MkDocs:" red "[MISSING]" "$(MKDOCS)"; \
	fi

mkdocs-doctor:
	@$(mf_color_prelude) \
	mf_color_init; \
	failures=0; \
	mf_heading "MkDocs doctor:"; \
	if [ -f "$(MKDOCS_CONFIG)" ]; then \
		mf_tagged "Configuration:" green "[OK]" "$(MKDOCS_CONFIG)"; \
	else \
		mf_tagged "Configuration:" red "[MISSING]" "$(MKDOCS_CONFIG)"; \
		failures=$$((failures + 1)); \
	fi; \
	mf_plain "Serve address:" "$(MKDOCS_HOST):$(MKDOCS_PORT)"; \
	if command -v "$(MKDOCS)" >/dev/null 2>&1; then \
		mf_tagged "MkDocs:" green "[OK]" "$$(command -v "$(MKDOCS)")"; \
	else \
		mf_tagged "MkDocs:" red "[MISSING]" "$(MKDOCS)"; \
		failures=$$((failures + 1)); \
	fi; \
	if [ "$$failures" -ne 0 ]; then \
		mf_msg_err "MkDocs doctor found $$failures issue(s)."; \
		exit 1; \
	fi; \
	mf_msg_ok "MkDocs doctor: OK"

mkdocs-build:
	$(MKDOCS) build --config-file "$(MKDOCS_CONFIG)"

mkdocs-serve:
	$(MKDOCS) serve \
		--config-file "$(MKDOCS_CONFIG)" \
		--dev-addr "$(MKDOCS_HOST):$(MKDOCS_PORT)"

mkdocs-clean:
	rm -rf site
