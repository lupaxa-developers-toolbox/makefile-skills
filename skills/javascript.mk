NODE ?= node
ESLINT ?= eslint
SRC_DIR ?= .
ESLINT_FLAGS ?=
JAVASCRIPT_FILES ?= $(shell \
	find "$(SRC_DIR)" \
		\( -path '*/.makefiles/*' -o -path '*/.git/*' \) -prune -o \
		\( -name '*.js' -o -name '*.mjs' -o -name '*.cjs' \) -type f -print 2>/dev/null | sort \
)

STATUS_FRAGMENTS += status-javascript

.PHONY: help-javascript status-javascript javascript-doctor javascript-syntax javascript-analyze javascript-lint javascript-check

help-javascript:
	$(call mf_help_header,JavaScript:)
	$(call mf_help_line,javascript-doctor,Check JavaScript tools and source discovery)
	$(call mf_help_line,javascript-syntax,Validate JavaScript syntax using node --check)
	$(call mf_help_line,javascript-analyze,Analyse JavaScript files using ESLint)
	$(call mf_help_line,javascript-lint,Run JavaScript syntax validation and ESLint)
	$(call mf_help_line,javascript-check,Alias of javascript-lint)
	@echo

status-javascript:
	@$(mf_color_prelude) \
	mf_color_init; \
	mf_heading "JavaScript:"; \
	mf_plain "Source directory:" "$(SRC_DIR)"; \
	set -- $(JAVASCRIPT_FILES); \
	mf_plain "Files discovered:" "$$#"; \
	if command -v "$(NODE)" >/dev/null 2>&1; then \
		mf_tagged "node:" green "[OK]" "$$(command -v "$(NODE)")"; \
	else \
		mf_tagged "node:" red "[MISSING]" "$(NODE)"; \
	fi; \
	if command -v "$(ESLINT)" >/dev/null 2>&1; then \
		mf_tagged "ESLint:" green "[OK]" "$$(command -v "$(ESLINT)")"; \
	else \
		mf_tagged "ESLint:" red "[MISSING]" "$(ESLINT)"; \
	fi

javascript-doctor:
	@$(mf_color_prelude) \
	mf_color_init; \
	failures=0; \
	mf_heading "JavaScript doctor:"; \
	if [ -d "$(SRC_DIR)" ]; then \
		mf_tagged "Source directory:" green "[OK]" "$(SRC_DIR)"; \
	else \
		mf_tagged "Source directory:" red "[MISSING]" "$(SRC_DIR)"; \
		failures=$$((failures + 1)); \
	fi; \
	if command -v "$(NODE)" >/dev/null 2>&1; then \
		mf_tagged "node:" green "[OK]" "$$(command -v "$(NODE)")"; \
	else \
		mf_tagged "node:" red "[MISSING]" "$(NODE)"; \
		failures=$$((failures + 1)); \
	fi; \
	if command -v "$(ESLINT)" >/dev/null 2>&1; then \
		mf_tagged "ESLint:" green "[OK]" "$$(command -v "$(ESLINT)")"; \
	else \
		mf_tagged "ESLint:" red "[MISSING]" "$(ESLINT)"; \
		failures=$$((failures + 1)); \
	fi; \
	set -- $(JAVASCRIPT_FILES); \
	if [ "$$#" -gt 0 ]; then \
		mf_tagged "Files discovered:" green "[OK]" "$$#"; \
	else \
		mf_tagged "Files discovered:" yellow "[WARN]" "0 — set SRC_DIR or JAVASCRIPT_FILES"; \
	fi; \
	if [ "$$failures" -ne 0 ]; then \
		mf_msg_err "JavaScript doctor found $$failures issue(s)."; \
		exit 1; \
	fi; \
	mf_msg_ok "JavaScript doctor: OK"

define require_javascript_files
	@test -n "$(strip $(JAVASCRIPT_FILES))" || { \
		echo "ERROR: no JavaScript files were discovered." >&2; \
		echo "Search directory: $(SRC_DIR)" >&2; \
		echo "Set SRC_DIR or provide JAVASCRIPT_FILES explicitly." >&2; \
		exit 2; \
	}
endef

define require_node
	@command -v "$(NODE)" >/dev/null 2>&1 || { \
		echo "ERROR: Node.js command not found: $(NODE)" >&2; \
		exit 2; \
	}
endef

define require_eslint
	@command -v "$(ESLINT)" >/dev/null 2>&1 || { \
		echo "ERROR: ESLint command not found: $(ESLINT)" >&2; \
		exit 2; \
	}
endef

javascript-syntax:
	@$(require_javascript_files)
	@$(require_node)
	@failed=0; \
	for file in $(JAVASCRIPT_FILES); do \
		if "$(NODE)" --check "$$file"; then \
			printf '  PASS  %s\n' "$$file"; \
		else \
			printf '  FAIL  %s\n' "$$file"; \
			failed=$$((failed + 1)); \
		fi; \
	done; \
	if [ "$$failed" -ne 0 ]; then \
		echo "JavaScript syntax validation failed." >&2; \
		exit 1; \
	fi; \
	echo "JavaScript syntax validation passed."

javascript-analyze:
	@$(require_javascript_files)
	@$(require_eslint)
	@"$(ESLINT)" $(ESLINT_FLAGS) $(JAVASCRIPT_FILES)
	@echo "JavaScript analysis passed."

javascript-lint: javascript-syntax javascript-analyze

javascript-check: javascript-lint
