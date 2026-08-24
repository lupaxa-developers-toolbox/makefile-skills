PERL ?= perl
PERLCRITIC ?= perlcritic
SRC_DIR ?= .
PERLCRITIC_FLAGS ?=
PERL_FILES ?= $(shell \
	find "$(SRC_DIR)" \
		\( -path '*/.makefiles/*' -o -path '*/.git/*' \) -prune -o \
		\( -name '*.pl' -o -name '*.pm' \) -type f -print 2>/dev/null | sort \
)

STATUS_FRAGMENTS += status-perl

.PHONY: help-perl status-perl perl-doctor perl-syntax perl-critic perl-lint perl-check

help-perl:
	$(call mf_help_header,Perl:)
	$(call mf_help_line,perl-doctor,Check Perl tools and source discovery)
	$(call mf_help_line,perl-syntax,Validate Perl syntax using perl -c)
	$(call mf_help_line,perl-critic,Analyse Perl sources using Perl::Critic)
	$(call mf_help_line,perl-lint,Run Perl syntax validation and Perl::Critic)
	$(call mf_help_line,perl-check,Alias of perl-lint)
	@echo

status-perl:
	@$(mf_color_prelude) \
	mf_color_init; \
	mf_heading "Perl:"; \
	mf_plain "Source directory:" "$(SRC_DIR)"; \
	set -- $(PERL_FILES); \
	mf_plain "Files discovered:" "$$#"; \
	if command -v "$(PERL)" >/dev/null 2>&1; then \
		mf_tagged "Perl:" green "[OK]" "$$(command -v "$(PERL)")"; \
	else \
		mf_tagged "Perl:" red "[MISSING]" "$(PERL)"; \
	fi; \
	if command -v "$(PERLCRITIC)" >/dev/null 2>&1; then \
		mf_tagged "Perl::Critic:" green "[OK]" "$$(command -v "$(PERLCRITIC)")"; \
	else \
		mf_tagged "Perl::Critic:" red "[MISSING]" "$(PERLCRITIC)"; \
	fi

perl-doctor:
	@$(mf_color_prelude) \
	mf_color_init; \
	failures=0; \
	mf_heading "Perl doctor:"; \
	if [ -d "$(SRC_DIR)" ]; then \
		mf_tagged "Source directory:" green "[OK]" "$(SRC_DIR)"; \
	else \
		mf_tagged "Source directory:" red "[MISSING]" "$(SRC_DIR)"; \
		failures=$$((failures + 1)); \
	fi; \
	if command -v "$(PERL)" >/dev/null 2>&1; then \
		mf_tagged "Perl:" green "[OK]" "$$(command -v "$(PERL)")"; \
	else \
		mf_tagged "Perl:" red "[MISSING]" "$(PERL)"; \
		failures=$$((failures + 1)); \
	fi; \
	if command -v "$(PERLCRITIC)" >/dev/null 2>&1; then \
		mf_tagged "Perl::Critic:" green "[OK]" "$$(command -v "$(PERLCRITIC)")"; \
	else \
		mf_tagged "Perl::Critic:" red "[MISSING]" "$(PERLCRITIC)"; \
		failures=$$((failures + 1)); \
	fi; \
	set -- $(PERL_FILES); \
	if [ "$$#" -gt 0 ]; then \
		mf_tagged "Files discovered:" green "[OK]" "$$#"; \
	else \
		mf_tagged "Files discovered:" yellow "[WARN]" "0 — set SRC_DIR or PERL_FILES"; \
	fi; \
	if [ "$$failures" -ne 0 ]; then \
		mf_msg_err "Perl doctor found $$failures issue(s)."; \
		exit 1; \
	fi; \
	mf_msg_ok "Perl doctor: OK"

define require_perl_files
	@test -n "$(strip $(PERL_FILES))" || { \
		echo "ERROR: no Perl files were discovered." >&2; \
		echo "Search directory: $(SRC_DIR)" >&2; \
		echo "Set SRC_DIR or provide PERL_FILES explicitly." >&2; \
		exit 2; \
	}
endef

perl-syntax:
	@$(require_perl_files)
	@command -v "$(PERL)" >/dev/null 2>&1 || { \
		echo "ERROR: Perl command not found: $(PERL)" >&2; \
		exit 2; \
	}
	@failed=0; \
	for file in $(PERL_FILES); do \
		if "$(PERL)" -c "$$file"; then \
			printf '  PASS  %s\n' "$$file"; \
		else \
			printf '  FAIL  %s\n' "$$file"; \
			failed=$$((failed + 1)); \
		fi; \
	done; \
	if [ "$$failed" -ne 0 ]; then \
		echo "Perl syntax validation failed." >&2; \
		exit 1; \
	fi; \
	echo "Perl syntax validation passed."

perl-critic:
	@command -v "$(PERLCRITIC)" >/dev/null 2>&1 || { \
		echo "ERROR: Perl::Critic command not found: $(PERLCRITIC)" >&2; \
		exit 2; \
	}
	@"$(PERLCRITIC)" $(PERLCRITIC_FLAGS) "$(SRC_DIR)"

perl-lint: perl-syntax perl-critic

perl-check: perl-lint
