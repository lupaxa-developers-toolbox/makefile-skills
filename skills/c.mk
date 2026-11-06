ifeq ($(origin CC),default)
CC := gcc
endif
CPPCHECK ?= cppcheck
SRC_DIR ?= .
CFLAGS ?=
CPPCHECK_FLAGS ?=
C_FILES ?= $(shell \
	find "$(SRC_DIR)" \
		\( -path '*/.makefiles/*' -o -path '*/.git/*' \) -prune -o \
		\( -name '*.c' -o -name '*.h' \) -type f -print 2>/dev/null | sort \
)

STATUS_FRAGMENTS += status-c

.PHONY: help-c status-c c-doctor c-syntax c-analyze c-lint c-check

help-c:
	$(call mf_help_header,C:)
	$(call mf_help_line,c-doctor,Check C tools and source discovery)
	$(call mf_help_line,c-syntax,Validate C syntax using gcc -fsyntax-only)
	$(call mf_help_line,c-analyze,Analyse C files using cppcheck)
	$(call mf_help_line,c-lint,Run C syntax validation and cppcheck)
	$(call mf_help_line,c-check,Alias of c-lint)
	@echo

status-c:
	@$(mf_color_prelude) \
	mf_color_init; \
	mf_heading "C:"; \
	mf_plain "Source directory:" "$(SRC_DIR)"; \
	set -- $(C_FILES); \
	mf_plain "Files discovered:" "$$#"; \
	if command -v "$(CC)" >/dev/null 2>&1; then \
		mf_tagged "CC:" green "[OK]" "$$(command -v "$(CC)")"; \
	else \
		mf_tagged "CC:" red "[MISSING]" "$(CC)"; \
	fi; \
	if command -v "$(CPPCHECK)" >/dev/null 2>&1; then \
		mf_tagged "cppcheck:" green "[OK]" "$$(command -v "$(CPPCHECK)")"; \
	else \
		mf_tagged "cppcheck:" red "[MISSING]" "$(CPPCHECK)"; \
	fi

c-doctor:
	@$(mf_color_prelude) \
	mf_color_init; \
	failures=0; \
	mf_heading "C doctor:"; \
	if [ -d "$(SRC_DIR)" ]; then \
		mf_tagged "Source directory:" green "[OK]" "$(SRC_DIR)"; \
	else \
		mf_tagged "Source directory:" red "[MISSING]" "$(SRC_DIR)"; \
		failures=$$((failures + 1)); \
	fi; \
	if command -v "$(CC)" >/dev/null 2>&1; then \
		mf_tagged "CC:" green "[OK]" "$$(command -v "$(CC)")"; \
	else \
		mf_tagged "CC:" red "[MISSING]" "$(CC)"; \
		failures=$$((failures + 1)); \
	fi; \
	if command -v "$(CPPCHECK)" >/dev/null 2>&1; then \
		mf_tagged "cppcheck:" green "[OK]" "$$(command -v "$(CPPCHECK)")"; \
	else \
		mf_tagged "cppcheck:" red "[MISSING]" "$(CPPCHECK)"; \
		failures=$$((failures + 1)); \
	fi; \
	set -- $(C_FILES); \
	if [ "$$#" -gt 0 ]; then \
		mf_tagged "Files discovered:" green "[OK]" "$$#"; \
	else \
		mf_tagged "Files discovered:" yellow "[WARN]" "0 — set SRC_DIR or C_FILES"; \
	fi; \
	if [ "$$failures" -ne 0 ]; then \
		mf_msg_err "C doctor found $$failures issue(s)."; \
		exit 1; \
	fi; \
	mf_msg_ok "C doctor: OK"

define require_c_files
	@test -n "$(strip $(C_FILES))" || { \
		echo "ERROR: no C files were discovered." >&2; \
		echo "Search directory: $(SRC_DIR)" >&2; \
		echo "Set SRC_DIR or provide C_FILES explicitly." >&2; \
		exit 2; \
	}
endef

define require_cc
	@command -v "$(CC)" >/dev/null 2>&1 || { \
		echo "ERROR: C compiler not found: $(CC)" >&2; \
		exit 2; \
	}
endef

define require_cppcheck
	@command -v "$(CPPCHECK)" >/dev/null 2>&1 || { \
		echo "ERROR: cppcheck command not found: $(CPPCHECK)" >&2; \
		exit 2; \
	}
endef

c-syntax:
	@$(require_c_files)
	@$(require_cc)
	@failed=0; \
	for file in $(C_FILES); do \
		case "$$file" in \
			*.h) set -- "$(CC)" $(CFLAGS) -fsyntax-only -x c-header "$$file" ;; \
			*) set -- "$(CC)" $(CFLAGS) -fsyntax-only "$$file" ;; \
		esac; \
		if "$$@"; then \
			printf '  PASS  %s\n' "$$file"; \
		else \
			printf '  FAIL  %s\n' "$$file"; \
			failed=$$((failed + 1)); \
		fi; \
	done; \
	if [ "$$failed" -ne 0 ]; then \
		echo "C syntax validation failed." >&2; \
		exit 1; \
	fi; \
	echo "C syntax validation passed."

c-analyze:
	@$(require_c_files)
	@$(require_cppcheck)
	@"$(CPPCHECK)" --error-exitcode=1 $(CPPCHECK_FLAGS) $(C_FILES)
	@echo "C analysis passed."

c-lint: c-syntax c-analyze

c-check: c-lint
