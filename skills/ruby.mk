RUBY ?= ruby
BUNDLE ?= bundle
RUBOCOP ?= rubocop
RAKE ?= rake
GEM ?= gem
GEMFILE ?= Gemfile
GEMSPEC ?=
SRC_DIR ?= lib
TEST_DIR ?= test
RUBOCOP_ARGS ?=

ifneq ($(wildcard $(GEMFILE)),)
RUBY_RUN ?= bundle exec
else
RUBY_RUN ?=
endif

STATUS_FRAGMENTS += status-ruby

.PHONY: help-ruby status-ruby ruby-doctor ruby-bundle ruby-lint ruby-format ruby-check-diff ruby-test ruby-check ruby-check-all ruby-build ruby-publish ruby-clean

help-ruby:
	$(call mf_help_header,Ruby:)
	$(call mf_help_line,ruby-doctor,Check Ruby tools and project layout)
	$(call mf_help_line,ruby-bundle,Install dependencies from Gemfile)
	$(call mf_help_line,ruby-lint,Run RuboCop)
	$(call mf_help_line,ruby-format,RuboCop unsafe autocorrect (-A))
	$(call mf_help_line,ruby-check-diff,Show correctable RuboCop offences)
	$(call mf_help_line,ruby-test,Run rake test)
	$(call mf_help_line,ruby-check,Run lint and tests)
	$(call mf_help_line,ruby-check-all,Alias of ruby-check)
	$(call mf_help_line,ruby-build,Build the project gem)
	$(call mf_help_line,ruby-publish,Build and publish the project gem)
	$(call mf_help_line,ruby-clean,Remove Ruby build and test artefacts)
	@echo

status-ruby:
	@$(mf_color_prelude) \
	mf_color_init; \
	mf_heading "Ruby:"; \
	mf_plain "Source directory:" "$(SRC_DIR)"; \
	mf_plain "Test directory:" "$(TEST_DIR)"; \
	mf_plain "Gemfile:" "$(GEMFILE)"; \
	if [ -d "$(SRC_DIR)" ]; then \
		mf_tagged "Source directory:" green "[OK]" "$(SRC_DIR)"; \
	else \
		mf_tagged "Source directory:" red "[MISSING]" "$(SRC_DIR)"; \
	fi; \
	if [ -d "$(TEST_DIR)" ]; then \
		mf_tagged "Test directory:" green "[OK]" "$(TEST_DIR)"; \
	else \
		mf_tagged "Test directory:" red "[MISSING]" "$(TEST_DIR)"; \
	fi; \
	if [ -f "$(GEMFILE)" ]; then \
		mf_tagged "Gemfile:" green "[OK]" "$(GEMFILE)"; \
	else \
		mf_tagged "Gemfile:" red "[MISSING]" "$(GEMFILE)"; \
	fi; \
	gemspec="$(GEMSPEC)"; \
	if [ -z "$$gemspec" ]; then \
		set -- *.gemspec; \
		if [ "$$1" != '*.gemspec' ]; then gemspec="$$1"; fi; \
	fi; \
	if [ -n "$$gemspec" ] && [ -f "$$gemspec" ]; then \
		mf_tagged "Gemspec:" green "[OK]" "$$gemspec"; \
	else \
		mf_tagged "Gemspec:" red "[MISSING]" "$${gemspec:-*.gemspec}"; \
	fi; \
	for tool_pair in "Ruby:$(RUBY)" "RuboCop:$(RUBOCOP)" "rake:$(RAKE)" "gem:$(GEM)"; do \
		label="$${tool_pair%%:*}"; \
		cmd="$${tool_pair#*:}"; \
		if command -v "$$cmd" >/dev/null 2>&1; then \
			mf_tagged "$$label:" green "[OK]" "$$(command -v "$$cmd")"; \
		else \
			mf_tagged "$$label:" red "[MISSING]" "$$cmd"; \
		fi; \
	done; \
	if [ -f "$(GEMFILE)" ]; then \
		if command -v "$(BUNDLE)" >/dev/null 2>&1; then \
			mf_tagged "Bundler:" green "[OK]" "$$(command -v "$(BUNDLE)")"; \
		else \
			mf_tagged "Bundler:" red "[MISSING]" "$(BUNDLE)"; \
		fi; \
	fi

ruby-doctor:
	@$(mf_color_prelude) \
	mf_color_init; \
	failures=0; \
	mf_heading "Ruby doctor:"; \
	if [ -d "$(SRC_DIR)" ]; then \
		mf_tagged "Source directory:" green "[OK]" "$(SRC_DIR)"; \
	else \
		mf_tagged "Source directory:" red "[MISSING]" "$(SRC_DIR)"; \
		failures=$$((failures + 1)); \
	fi; \
	if [ -d "$(TEST_DIR)" ]; then \
		mf_tagged "Test directory:" green "[OK]" "$(TEST_DIR)"; \
	else \
		mf_tagged "Test directory:" red "[MISSING]" "$(TEST_DIR)"; \
		failures=$$((failures + 1)); \
	fi; \
	for tool_pair in "Ruby:$(RUBY)" "RuboCop:$(RUBOCOP)" "rake:$(RAKE)" "gem:$(GEM)"; do \
		label="$${tool_pair%%:*}"; \
		cmd="$${tool_pair#*:}"; \
		if command -v "$$cmd" >/dev/null 2>&1; then \
			mf_tagged "$$label:" green "[OK]" "$$(command -v "$$cmd")"; \
		else \
			mf_tagged "$$label:" red "[MISSING]" "$$cmd"; \
			failures=$$((failures + 1)); \
		fi; \
	done; \
	if [ -f "$(GEMFILE)" ]; then \
		if command -v "$(BUNDLE)" >/dev/null 2>&1; then \
			mf_tagged "Bundler:" green "[OK]" "$$(command -v "$(BUNDLE)")"; \
		else \
			mf_tagged "Bundler:" red "[MISSING]" "$(BUNDLE)"; \
			failures=$$((failures + 1)); \
		fi; \
	fi; \
	gemspec="$(GEMSPEC)"; \
	if [ -z "$$gemspec" ]; then \
		set -- *.gemspec; \
		if [ "$$1" != '*.gemspec' ]; then gemspec="$$1"; fi; \
	fi; \
	if [ -n "$$gemspec" ] && [ -f "$$gemspec" ]; then \
		mf_tagged "Gemspec:" green "[OK]" "$$gemspec"; \
	else \
		mf_tagged "Gemspec:" yellow "[WARN]" "No gemspec found"; \
	fi; \
	if [ "$$failures" -ne 0 ]; then \
		mf_msg_err "Ruby doctor found $$failures issue(s)."; \
		exit 1; \
	fi; \
	mf_msg_ok "Ruby doctor: OK"

ruby-bundle:
	@if [ ! -f "$(GEMFILE)" ]; then \
		echo "Skipping bundle install: $(GEMFILE) not found."; \
	else \
		"$(BUNDLE)" install; \
	fi

ruby-lint:
	$(RUBY_RUN) $(RUBOCOP) $(RUBOCOP_ARGS)

ruby-format:
	$(RUBY_RUN) $(RUBOCOP) -A $(RUBOCOP_ARGS)

ruby-check-diff:
	$(RUBY_RUN) $(RUBOCOP) --display-only-correctable $(RUBOCOP_ARGS)

ruby-test:
	$(RUBY_RUN) $(RAKE) test

ruby-check: ruby-lint ruby-test

ruby-check-all: ruby-check

ruby-build:
	@set -e; \
	gemspec="$(GEMSPEC)"; \
	if [ -z "$$gemspec" ]; then \
		set -- *.gemspec; \
		if [ "$$#" -eq 0 ] || [ "$$1" = '*.gemspec' ]; then \
			echo "ERROR: no *.gemspec found; set GEMSPEC=path/to/file.gemspec" >&2; \
			exit 2; \
		fi; \
		if [ "$$#" -gt 1 ]; then \
			echo "ERROR: multiple gemspecs ($$*); set GEMSPEC=..." >&2; \
			exit 2; \
		fi; \
		gemspec="$$1"; \
	fi; \
	"$(GEM)" build "$$gemspec"

ruby-publish: ruby-build
	@set -e; \
	gem_file="$$(ls -t -- *.gem 2>/dev/null | head -1)"; \
	if [ -z "$$gem_file" ]; then \
		echo "ERROR: no *.gem found to publish" >&2; \
		exit 2; \
	fi; \
	"$(GEM)" push "$$gem_file"

ruby-clean:
	rm -rf pkg .bundle coverage .resultset.json .rspec_status
	rm -f -- *.gem
