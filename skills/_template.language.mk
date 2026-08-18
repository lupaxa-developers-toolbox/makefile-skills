# =============================================================================
# Language skill template
# =============================================================================
#
# Create a new language skill (Ruby, Go, Rust, …):
#
#   1. Copy this file:
#        cp skills/_template.language.mk skills/go.mk
#   2. Replace placeholders in the new file (including target names):
#        lang  → go          (skill id / target prefix; lowercase)
#        Lang  → Go          (help / status section titles)
#   3. Enable in a consumer wrapper:
#        SKILLS ?= go
#      or add to an examples/Makefile.* profile.
#   4. Fill in tool variables and replace stub recipes.
#   5. Checklist before merging:
#        [ ] skills/<id>.mk (this file, renamed)
#        [ ] tests/test_<id>_skill.sh (help / doctor / one real target)
#        [ ] examples/Makefile.<id> (or extend an existing example)
#        [ ] mkdocs/reference.md + README optional-skills list
#        [ ] make doctor SKILLS=<id> runs end-to-end
#
# Conventions (match python / bash / mkdocs):
#   - Standalone skill: do not include versioning.mk or other skills.
#   - All public targets are prefixed: lang-lint, not lint.
#   - Register help via help-lang (wrapper loops help-$(SKILL)).
#   - Register status via STATUS_FRAGMENTS += status-lang.
#   - Provide lang-doctor for top-level `make doctor`.
#   - Do not enable this file via SKILLS (leading underscore = template only).
#
# =============================================================================

# --- Tool / layout overrides (replace with real defaults) --------------------

LANG_TOOL ?= lang-tool
SRC_DIR ?= .
TEST_DIR ?= tests
# CONFIG_FILE ?=

# --- Required skill hooks ----------------------------------------------------

STATUS_FRAGMENTS += status-lang

.PHONY: help-lang status-lang lang-doctor lang-lint lang-test lang-check lang-build lang-clean

help-lang:
	$(call mf_help_header,Lang:)
	@echo "  lang-doctor         Check Lang tools and project layout"
	@echo "  lang-lint           Lint Lang sources (stub — implement me)"
	@echo "  lang-test           Run Lang tests (stub — implement me)"
	@echo "  lang-check          lint + test"
	@echo "  lang-build          Build Lang artefacts (stub — implement me)"
	@echo "  lang-clean          Remove Lang build artefacts (stub — implement me)"
	@echo
	@echo "  This is a skill template. Replace lang/Lang and stub recipes."
	@echo

status-lang:
	@$(mf_color_prelude) \
	mf_color_init; \
	mf_heading "Lang:"; \
	mf_plain "Source directory:" "$(SRC_DIR)"; \
	mf_plain "Test directory:" "$(TEST_DIR)"; \
	if command -v "$(LANG_TOOL)" >/dev/null 2>&1; then \
		mf_tagged "LANG_TOOL:" green "[OK]" "$$(command -v "$(LANG_TOOL)")"; \
	else \
		mf_tagged "LANG_TOOL:" red "[MISSING]" "$(LANG_TOOL)"; \
	fi; \
	mf_tagged "Skill:" yellow "[STUB]" "replace recipes in skills/lang.mk"

lang-doctor:
	@$(mf_color_prelude) \
	mf_color_init; \
	failures=0; \
	mf_heading "Lang doctor:"; \
	mf_plain "Source directory:" "$(SRC_DIR)"; \
	if [ -d "$(SRC_DIR)" ]; then \
		mf_tagged "Source exists:" green "[OK]" "$(SRC_DIR)"; \
	else \
		mf_tagged "Source exists:" red "[MISSING]" "$(SRC_DIR)"; \
		failures=$$((failures + 1)); \
	fi; \
	if command -v "$(LANG_TOOL)" >/dev/null 2>&1; then \
		mf_tagged "LANG_TOOL:" green "[OK]" "$$(command -v "$(LANG_TOOL)")"; \
	else \
		mf_tagged "LANG_TOOL:" red "[MISSING]" "$(LANG_TOOL) (expected until you set real tools)"; \
	fi; \
	mf_tagged "Skill template:" yellow "[STUB]" "implement lint/test/build"; \
	if [ "$$failures" -ne 0 ]; then \
		mf_msg_err "Lang doctor found $$failures issue(s)."; \
		exit 1; \
	fi; \
	mf_msg_ok "Lang doctor: OK (stub — replace LANG_TOOL and recipes)"

# --- Suggested workflow targets (stubs) --------------------------------------

lang-lint:
	@echo "TODO(lang-lint): implement Lang linting" >&2; \
	exit 2

lang-test:
	@echo "TODO(lang-test): implement Lang tests" >&2; \
	exit 2

lang-check: lang-lint lang-test

lang-build:
	@echo "TODO(lang-build): implement Lang build" >&2; \
	exit 2

lang-clean:
	@echo "TODO(lang-clean): implement Lang clean (no-op stub)"
