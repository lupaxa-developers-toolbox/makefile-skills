CARGO ?= cargo
SRC_DIR ?= .
RUST_WORKSPACE_ROOTS ?= $(MAKEFILES_DIR)/skills/rust/workspace-roots
CARGO_CLIPPY_FLAGS ?= --workspace --all-targets -- -D warnings
CARGO_TEST_FLAGS ?= --workspace
CARGO_BUILD_FLAGS ?= --workspace
CARGO_CLEAN_FLAGS ?=

STATUS_FRAGMENTS += status-rust

.PHONY: help-rust status-rust rust-doctor rust-lint rust-test rust-check rust-build rust-clean

help-rust:
	$(call mf_help_header,Rust:)
	$(call mf_help_line,rust-doctor,Check cargo, clippy, and workspace discovery)
	$(call mf_help_line,rust-lint,Run cargo clippy in each workspace)
	$(call mf_help_line,rust-test,Run cargo test in each workspace)
	$(call mf_help_line,rust-check,Run Rust lint and tests)
	$(call mf_help_line,rust-build,Run cargo build in each workspace)
	$(call mf_help_line,rust-clean,Run cargo clean in each workspace)
	@echo

status-rust:
	@$(mf_color_prelude) \
	mf_color_init; \
	mf_heading "Rust:"; \
	mf_plain "Source directory:" "$(SRC_DIR)"; \
	if [ -x "$(RUST_WORKSPACE_ROOTS)" ]; then \
		set -- $$("$(RUST_WORKSPACE_ROOTS)" "$(SRC_DIR)" 2>/dev/null || true); \
		mf_plain "Workspaces discovered:" "$$#"; \
	else \
		mf_tagged "Workspace finder:" red "[MISSING]" "$(RUST_WORKSPACE_ROOTS)"; \
	fi; \
	if command -v "$(CARGO)" >/dev/null 2>&1; then \
		mf_tagged "cargo:" green "[OK]" "$$(command -v "$(CARGO)")"; \
		if "$(CARGO)" clippy -V >/dev/null 2>&1; then \
			mf_tagged "clippy:" green "[OK]" "cargo clippy"; \
		else \
			mf_tagged "clippy:" red "[MISSING]" "cargo clippy"; \
		fi; \
	else \
		mf_tagged "cargo:" red "[MISSING]" "$(CARGO)"; \
	fi

define require_cargo
	@command -v "$(CARGO)" >/dev/null 2>&1 || { \
		echo "ERROR: cargo command not found: $(CARGO)" >&2; \
		exit 2; \
	}
endef

define require_clippy
	@"$(CARGO)" clippy -V >/dev/null 2>&1 || { \
		echo "ERROR: cargo clippy is not available. Install the clippy component." >&2; \
		exit 2; \
	}
endef

define rust_each
	set -eu; \
	if [ ! -x "$(RUST_WORKSPACE_ROOTS)" ]; then \
		echo "ERROR: Rust workspace finder not found: $(RUST_WORKSPACE_ROOTS)" >&2; \
		exit 2; \
	fi; \
	roots="$$( CARGO="$(CARGO)" "$(RUST_WORKSPACE_ROOTS)" "$(SRC_DIR)" )"; \
	if [ -z "$$roots" ]; then \
		echo "ERROR: no Rust workspace was discovered." >&2; \
		echo "Search directory: $(SRC_DIR)" >&2; \
		exit 2; \
	fi; \
	list="$$(mktemp)"; \
	trap 'rm -f "$$list"' EXIT; \
	printf '%s\n' "$$roots" >"$$list"; \
	while IFS= read -r root; do \
		[ -n "$$root" ] || continue; \
		printf '==> %s\n' "$$root"; \
		( cd "$$root" && "$(CARGO)" $(1) ) || exit 1; \
	done <"$$list"
endef

rust-doctor:
	@$(mf_color_prelude) \
	mf_color_init; \
	failures=0; \
	mf_heading "Rust doctor:"; \
	if [ -d "$(SRC_DIR)" ]; then \
		mf_tagged "Source directory:" green "[OK]" "$(SRC_DIR)"; \
	else \
		mf_tagged "Source directory:" red "[MISSING]" "$(SRC_DIR)"; \
		failures=$$((failures + 1)); \
	fi; \
	if [ -x "$(RUST_WORKSPACE_ROOTS)" ]; then \
		mf_tagged "Workspace finder:" green "[OK]" "$(RUST_WORKSPACE_ROOTS)"; \
	else \
		mf_tagged "Workspace finder:" red "[MISSING]" "$(RUST_WORKSPACE_ROOTS)"; \
		failures=$$((failures + 1)); \
	fi; \
	if command -v "$(CARGO)" >/dev/null 2>&1; then \
		mf_tagged "cargo:" green "[OK]" "$$(command -v "$(CARGO)")"; \
		if "$(CARGO)" clippy -V >/dev/null 2>&1; then \
			mf_tagged "clippy:" green "[OK]" "cargo clippy"; \
		else \
			mf_tagged "clippy:" red "[MISSING]" "cargo clippy"; \
			failures=$$((failures + 1)); \
		fi; \
		if [ -x "$(RUST_WORKSPACE_ROOTS)" ]; then \
			set -- $$( CARGO="$(CARGO)" "$(RUST_WORKSPACE_ROOTS)" "$(SRC_DIR)" 2>/dev/null || true ); \
			if [ "$$#" -gt 0 ]; then \
				mf_tagged "Workspaces discovered:" green "[OK]" "$$#"; \
			else \
				mf_tagged "Workspaces discovered:" yellow "[WARN]" "0 — set SRC_DIR"; \
			fi; \
		fi; \
	else \
		mf_tagged "cargo:" red "[MISSING]" "$(CARGO)"; \
		failures=$$((failures + 1)); \
	fi; \
	if [ "$$failures" -ne 0 ]; then \
		mf_msg_err "Rust doctor found $$failures issue(s)."; \
		exit 1; \
	fi; \
	mf_msg_ok "Rust doctor: OK"

rust-lint:
	@$(require_cargo)
	@$(require_clippy)
	@$(call rust_each,clippy $(CARGO_CLIPPY_FLAGS))
	@echo "Rust lint passed."

rust-test:
	@$(require_cargo)
	@$(call rust_each,test $(CARGO_TEST_FLAGS))
	@echo "Rust tests passed."

rust-build:
	@$(require_cargo)
	@$(call rust_each,build $(CARGO_BUILD_FLAGS))
	@echo "Rust build passed."

rust-clean:
	@$(require_cargo)
	@$(call rust_each,clean $(CARGO_CLEAN_FLAGS))
	@echo "Rust clean passed."

rust-check: rust-lint rust-test
