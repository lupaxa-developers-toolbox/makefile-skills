PHP ?= php
PHPCS ?= phpcs
PHPSTAN ?= phpstan
SRC_DIR ?= .
PHPCS_FLAGS ?=
PHPSTAN_FLAGS ?=
PHP_FILES ?= $(shell \
	find "$(SRC_DIR)" \
		\( -path '*/.makefiles/*' -o -path '*/.git/*' \) -prune -o \
		-name '*.php' -type f -print 2>/dev/null | sort \
)

STATUS_FRAGMENTS += status-php

.PHONY: help-php status-php php-doctor php-syntax php-cs php-stan php-lint php-check

help-php:
	$(call mf_help_header,PHP:)
	$(call mf_help_line,php-doctor,Check PHP tools and source discovery)
	$(call mf_help_line,php-syntax,Validate PHP syntax using php -l)
	$(call mf_help_line,php-cs,Analyse PHP sources using PHP_CodeSniffer)
	$(call mf_help_line,php-stan,Analyse PHP sources using PHPStan)
	$(call mf_help_line,php-lint,Run all PHP validation tools)
	$(call mf_help_line,php-check,Alias of php-lint)
	@echo

status-php:
	@$(mf_color_prelude) \
	mf_color_init; \
	mf_heading "PHP:"; \
	mf_plain "Source directory:" "$(SRC_DIR)"; \
	set -- $(PHP_FILES); \
	mf_plain "Files discovered:" "$$#"; \
	if command -v "$(PHP)" >/dev/null 2>&1; then \
		mf_tagged "PHP:" green "[OK]" "$$(command -v "$(PHP)")"; \
	else \
		mf_tagged "PHP:" red "[MISSING]" "$(PHP)"; \
	fi; \
	if command -v "$(PHPCS)" >/dev/null 2>&1; then \
		mf_tagged "PHP_CodeSniffer:" green "[OK]" "$$(command -v "$(PHPCS)")"; \
	else \
		mf_tagged "PHP_CodeSniffer:" red "[MISSING]" "$(PHPCS)"; \
	fi; \
	if command -v "$(PHPSTAN)" >/dev/null 2>&1; then \
		mf_tagged "PHPStan:" green "[OK]" "$$(command -v "$(PHPSTAN)")"; \
	else \
		mf_tagged "PHPStan:" red "[MISSING]" "$(PHPSTAN)"; \
	fi

php-doctor:
	@$(mf_color_prelude) \
	mf_color_init; \
	failures=0; \
	mf_heading "PHP doctor:"; \
	if [ -d "$(SRC_DIR)" ]; then \
		mf_tagged "Source directory:" green "[OK]" "$(SRC_DIR)"; \
	else \
		mf_tagged "Source directory:" red "[MISSING]" "$(SRC_DIR)"; \
		failures=$$((failures + 1)); \
	fi; \
	if command -v "$(PHP)" >/dev/null 2>&1; then \
		mf_tagged "PHP:" green "[OK]" "$$(command -v "$(PHP)")"; \
	else \
		mf_tagged "PHP:" red "[MISSING]" "$(PHP)"; \
		failures=$$((failures + 1)); \
	fi; \
	if command -v "$(PHPCS)" >/dev/null 2>&1; then \
		mf_tagged "PHP_CodeSniffer:" green "[OK]" "$$(command -v "$(PHPCS)")"; \
	else \
		mf_tagged "PHP_CodeSniffer:" red "[MISSING]" "$(PHPCS)"; \
		failures=$$((failures + 1)); \
	fi; \
	if command -v "$(PHPSTAN)" >/dev/null 2>&1; then \
		mf_tagged "PHPStan:" green "[OK]" "$$(command -v "$(PHPSTAN)")"; \
	else \
		mf_tagged "PHPStan:" red "[MISSING]" "$(PHPSTAN)"; \
		failures=$$((failures + 1)); \
	fi; \
	set -- $(PHP_FILES); \
	if [ "$$#" -gt 0 ]; then \
		mf_tagged "Files discovered:" green "[OK]" "$$#"; \
	else \
		mf_tagged "Files discovered:" yellow "[WARN]" "0 — set SRC_DIR or PHP_FILES"; \
	fi; \
	if [ "$$failures" -ne 0 ]; then \
		mf_msg_err "PHP doctor found $$failures issue(s)."; \
		exit 1; \
	fi; \
	mf_msg_ok "PHP doctor: OK"

define require_php_files
	@test -n "$(strip $(PHP_FILES))" || { \
		echo "ERROR: no PHP files were discovered." >&2; \
		echo "Search directory: $(SRC_DIR)" >&2; \
		echo "Set SRC_DIR or provide PHP_FILES explicitly." >&2; \
		exit 2; \
	}
endef

php-syntax:
	@$(require_php_files)
	@command -v "$(PHP)" >/dev/null 2>&1 || { \
		echo "ERROR: PHP command not found: $(PHP)" >&2; \
		exit 2; \
	}
	@failed=0; \
	for file in $(PHP_FILES); do \
		if "$(PHP)" -l "$$file"; then \
			printf '  PASS  %s\n' "$$file"; \
		else \
			printf '  FAIL  %s\n' "$$file"; \
			failed=$$((failed + 1)); \
		fi; \
	done; \
	if [ "$$failed" -ne 0 ]; then \
		echo "PHP syntax validation failed." >&2; \
		exit 1; \
	fi; \
	echo "PHP syntax validation passed."

php-cs:
	@command -v "$(PHPCS)" >/dev/null 2>&1 || { \
		echo "ERROR: PHP_CodeSniffer command not found: $(PHPCS)" >&2; \
		exit 2; \
	}
	@"$(PHPCS)" $(PHPCS_FLAGS) "$(SRC_DIR)"

php-stan:
	@command -v "$(PHPSTAN)" >/dev/null 2>&1 || { \
		echo "ERROR: PHPStan command not found: $(PHPSTAN)" >&2; \
		exit 2; \
	}
	@"$(PHPSTAN)" analyse $(PHPSTAN_FLAGS) "$(SRC_DIR)"

php-lint: php-syntax php-cs php-stan

php-check: php-lint
