GO ?= go
SRC_DIR ?= .
GO_MODULE_DIRS ?= $(MAKEFILES_DIR)/skills/go/module-dirs
GO_VET_FLAGS ?= ./...
GO_TEST_FLAGS ?= ./...
GO_BUILD_FLAGS ?= ./...
GO_CLEAN_FLAGS ?= ./...

STATUS_FRAGMENTS += status-go

.PHONY: help-go status-go go-doctor go-lint go-test go-check go-build go-clean

help-go:
	$(call mf_help_header,Go:)
	$(call mf_help_line,go-doctor,Check the Go tool and module discovery)
	$(call mf_help_line,go-lint,Run go vet in each module)
	$(call mf_help_line,go-test,Run go test in each module)
	$(call mf_help_line,go-check,Run Go lint and tests)
	$(call mf_help_line,go-build,Run go build in each module)
	$(call mf_help_line,go-clean,Run go clean in each module)
	@echo

status-go:
	@$(mf_color_prelude) \
	mf_color_init; \
	mf_heading "Go:"; \
	mf_plain "Source directory:" "$(SRC_DIR)"; \
	if [ -x "$(GO_MODULE_DIRS)" ]; then \
		set -- $$("$(GO_MODULE_DIRS)" "$(SRC_DIR)" 2>/dev/null); \
		mf_plain "Modules discovered:" "$$#"; \
	else \
		mf_tagged "Module finder:" red "[MISSING]" "$(GO_MODULE_DIRS)"; \
	fi; \
	if command -v "$(GO)" >/dev/null 2>&1; then \
		mf_tagged "Go:" green "[OK]" "$$(command -v "$(GO)")"; \
	else \
		mf_tagged "Go:" red "[MISSING]" "$(GO)"; \
	fi

define require_go
	@command -v "$(GO)" >/dev/null 2>&1 || { \
		echo "ERROR: Go command not found: $(GO)" >&2; \
		exit 2; \
	}
endef

define go_each
	set -eu; \
	if [ ! -x "$(GO_MODULE_DIRS)" ]; then \
		echo "ERROR: Go module finder not found: $(GO_MODULE_DIRS)" >&2; \
		exit 2; \
	fi; \
	mods="$$( "$(GO_MODULE_DIRS)" "$(SRC_DIR)" )"; \
	if [ -z "$$mods" ]; then \
		echo "ERROR: no Go module was discovered." >&2; \
		echo "Search directory: $(SRC_DIR)" >&2; \
		exit 2; \
	fi; \
	list="$$(mktemp)"; \
	trap 'rm -f "$$list"' EXIT; \
	printf '%s\n' "$$mods" >"$$list"; \
	while IFS= read -r dir; do \
		[ -n "$$dir" ] || continue; \
		printf '==> %s\n' "$$dir"; \
		( cd "$$dir" && "$(GO)" $(1) ) || exit 1; \
	done <"$$list"
endef

go-doctor:
	@$(mf_color_prelude) \
	mf_color_init; \
	failures=0; \
	mf_heading "Go doctor:"; \
	if [ -d "$(SRC_DIR)" ]; then \
		mf_tagged "Source directory:" green "[OK]" "$(SRC_DIR)"; \
	else \
		mf_tagged "Source directory:" red "[MISSING]" "$(SRC_DIR)"; \
		failures=$$((failures + 1)); \
	fi; \
	if [ -x "$(GO_MODULE_DIRS)" ]; then \
		mf_tagged "Module finder:" green "[OK]" "$(GO_MODULE_DIRS)"; \
		set -- $$("$(GO_MODULE_DIRS)" "$(SRC_DIR)" 2>/dev/null || true); \
		if [ "$$#" -gt 0 ]; then \
			mf_tagged "Modules discovered:" green "[OK]" "$$#"; \
		else \
			mf_tagged "Modules discovered:" yellow "[WARN]" "0 — set SRC_DIR"; \
		fi; \
	else \
		mf_tagged "Module finder:" red "[MISSING]" "$(GO_MODULE_DIRS)"; \
		failures=$$((failures + 1)); \
	fi; \
	if command -v "$(GO)" >/dev/null 2>&1; then \
		mf_tagged "Go:" green "[OK]" "$$(command -v "$(GO)")"; \
	else \
		mf_tagged "Go:" red "[MISSING]" "$(GO)"; \
		failures=$$((failures + 1)); \
	fi; \
	if [ "$$failures" -ne 0 ]; then \
		mf_msg_err "Go doctor found $$failures issue(s)."; \
		exit 1; \
	fi; \
	mf_msg_ok "Go doctor: OK"

go-lint:
	@$(require_go)
	@$(call go_each,vet $(GO_VET_FLAGS))
	@echo "Go lint passed."

go-test:
	@$(require_go)
	@$(call go_each,test $(GO_TEST_FLAGS))
	@echo "Go tests passed."

go-build:
	@$(require_go)
	@$(call go_each,build $(GO_BUILD_FLAGS))
	@echo "Go build passed."

go-clean:
	@$(require_go)
	@$(call go_each,clean $(GO_CLEAN_FLAGS))
	@echo "Go clean passed."

go-check: go-lint go-test
