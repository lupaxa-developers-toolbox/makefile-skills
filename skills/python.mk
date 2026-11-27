# Project tools live in .venv. CI runs install and check as separate make
# processes and never activates the virtualenv, so later targets call the
# binaries by path. PYTHON is the interpreter that creates .venv.
PYTHON ?= python3
VENV_DIR ?= .venv
VENV_BIN := $(VENV_DIR)/bin
PIP ?= $(VENV_BIN)/python -m pip
HATCH ?= $(VENV_BIN)/hatch
MYPY ?= $(VENV_BIN)/mypy
PYTEST ?= $(VENV_BIN)/pytest
RUFF ?= $(VENV_BIN)/ruff

SRC_DIR ?= src
TEST_DIR ?= tests
COVERAGE_TARGET ?= $(SRC_DIR)
AUDIT_VENV_DIR ?= .audit-env
AUDIT_PYTHON := $(AUDIT_VENV_DIR)/bin/python
PYPROJECT_FILE ?= pyproject.toml

# Overridable install / path knobs. Defaults preserve the single-package layout.
# Multi-package workspaces set these in .makefiles-custom (no recipe overrides).
PIP_INSTALL_DEV ?= -e ".[dev]"
PIP_INSTALL_TEST ?= -e ".[test]"
PYTHON_RUFF_PATHS ?= $(SRC_DIR) $(TEST_DIR)
# Default: type-check SRC_DIR. Set empty to rely on [tool.mypy] files in pyproject.
MYPY_ARGS ?= $(SRC_DIR)
# Space-separated package dirs (each with its own pyproject). Empty = hatch at root.
PYTHON_PACKAGE_DIRS ?=

STATUS_FRAGMENTS += status-python

.PHONY: help-python status-python python-doctor python-venv python-install-dev python-install-test python-lint python-check-style python-check-diff python-check-diff-all python-format python-format-diff python-type python-test python-test-cov python-check python-check-all python-audit python-build python-publish python-clean

help-python:
	$(call mf_help_header,Python:)
	$(call mf_help_line,python-doctor,Check Python tools and project layout)
	$(call mf_help_line,python-venv,Create the project venv)
	$(call mf_help_line,python-install-dev,Install editable with dev extras)
	$(call mf_help_line,python-install-test,Install editable with test extras)
	$(call mf_help_line,python-lint,Ruff lint + format check)
	$(call mf_help_line,python-check-style,Lint + type)
	$(call mf_help_line,python-check-diff,Show Ruff lint corrections)
	$(call mf_help_line,python-check-diff-all,Show lint and format changes)
	$(call mf_help_line,python-format,Ruff format)
	$(call mf_help_line,python-format-diff,Show Ruff formatting changes)
	$(call mf_help_line,python-type,mypy)
	$(call mf_help_line,python-test,pytest)
	$(call mf_help_line,python-test-cov,pytest with coverage)
	$(call mf_help_line,python-check,lint + type + test)
	$(call mf_help_line,python-check-all,lint + type + test-cov + audit)
	$(call mf_help_line,python-audit,pip-audit in isolated venv)
	$(call mf_help_line,python-build,Hatch build)
	$(call mf_help_line,python-publish,Hatch publish)
	$(call mf_help_line,python-clean,Remove Python artefacts)
	@echo

status-python:
	@$(mf_color_prelude) \
	mf_color_init; \
	mf_heading "Python:"; \
	if [ -f "$(PYPROJECT_FILE)" ]; then \
		mf_tagged "Configuration:" green "[OK]" "$(PYPROJECT_FILE)"; \
	else \
		mf_tagged "Configuration:" red "[MISSING]" "$(PYPROJECT_FILE)"; \
	fi; \
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
	if command -v "$(PYTHON)" >/dev/null 2>&1; then \
		python_version="$$("$(PYTHON)" --version 2>&1)"; \
		mf_tagged "Python:" green "[OK]" "$$python_version"; \
		mf_plain "Python executable:" "$$(command -v "$(PYTHON)")"; \
	else \
		mf_tagged "Python:" red "[MISSING]" "$(PYTHON)"; \
		mf_tagged "Python executable:" red "[UNAVAILABLE]"; \
	fi; \
	if [ -x "$(VENV_BIN)/python" ]; then \
		mf_tagged "Virtualenv:" green "[OK]" "$(VENV_DIR)"; \
	else \
		mf_tagged "Virtualenv:" red "[MISSING]" "$(VENV_DIR)"; \
	fi; \
	for tool_pair in "Hatch:$(HATCH)" "Ruff:$(RUFF)" "mypy:$(MYPY)" "pytest:$(PYTEST)"; do \
		label="$${tool_pair%%:*}"; \
		cmd="$${tool_pair#*:}"; \
		if [ -x "$$cmd" ]; then \
			mf_tagged "$$label:" green "[OK]" "$$cmd"; \
		else \
			mf_tagged "$$label:" red "[MISSING]" "$$cmd"; \
		fi; \
	done

python-doctor:
	@$(mf_color_prelude) \
	mf_color_init; \
	failures=0; \
	mf_heading "Python doctor:"; \
	if [ -f "$(PYPROJECT_FILE)" ]; then \
		mf_tagged "Configuration:" green "[OK]" "$(PYPROJECT_FILE)"; \
	else \
		mf_tagged "Configuration:" red "[MISSING]" "$(PYPROJECT_FILE)"; \
		failures=$$((failures + 1)); \
	fi; \
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
	if command -v "$(PYTHON)" >/dev/null 2>&1; then \
		mf_tagged "Python:" green "[OK]" "$$(command -v "$(PYTHON)")"; \
	else \
		mf_tagged "Python:" red "[MISSING]" "$(PYTHON)"; \
		failures=$$((failures + 1)); \
	fi; \
	if [ -x "$(VENV_BIN)/python" ]; then \
		mf_tagged "Virtualenv:" green "[OK]" "$(VENV_DIR)"; \
	else \
		mf_tagged "Virtualenv:" red "[MISSING]" "$(VENV_DIR)"; \
		failures=$$((failures + 1)); \
	fi; \
	for tool_pair in "Ruff:$(RUFF)" "mypy:$(MYPY)" "pytest:$(PYTEST)" "Hatch:$(HATCH)"; do \
		label="$${tool_pair%%:*}"; \
		cmd="$${tool_pair#*:}"; \
		if [ -x "$$cmd" ]; then \
			mf_tagged "$$label:" green "[OK]" "$$cmd"; \
		else \
			mf_tagged "$$label:" red "[MISSING]" "$$cmd"; \
			failures=$$((failures + 1)); \
		fi; \
	done; \
	if [ "$$failures" -ne 0 ]; then \
		mf_msg_err "Python doctor found $$failures issue(s)."; \
		exit 1; \
	fi; \
	mf_msg_ok "Python doctor: OK"

python-venv:
	@set -e; \
	base="$$("$(PYTHON)" -c 'import sys; print(sys.prefix)')"; \
	if [ -x "$(VENV_BIN)/python" ]; then \
		current="$$("$(VENV_BIN)/python" -c 'import sys; print(sys.base_prefix)' 2>/dev/null || true)"; \
		if [ "$$current" = "$$base" ] && "$(VENV_BIN)/python" -c 'import pip' >/dev/null 2>&1; then \
			exit 0; \
		fi; \
		echo "==> Recreating $(VENV_DIR) for $$base"; \
		rm -rf "$(VENV_DIR)"; \
	else \
		echo "==> Creating $(VENV_DIR) with $$base"; \
	fi; \
	"$(PYTHON)" -m venv "$(VENV_DIR)"

python-install-dev: python-venv
	$(PIP) install $(PIP_INSTALL_DEV)

python-install-test: python-venv
	$(PIP) install $(PIP_INSTALL_TEST)

python-lint:
	$(RUFF) check $(PYTHON_RUFF_PATHS)
	$(RUFF) format --check $(PYTHON_RUFF_PATHS)

python-check-style: python-lint python-type

python-check-diff:
	$(RUFF) check --diff $(PYTHON_RUFF_PATHS)

python-check-diff-all: python-check-diff python-format-diff

python-format:
	$(RUFF) format $(PYTHON_RUFF_PATHS)

python-format-diff:
	$(RUFF) format --diff $(PYTHON_RUFF_PATHS)

python-type:
	$(MYPY) $(MYPY_ARGS)

python-test:
	$(PYTEST) -v

python-test-cov:
	$(PYTEST) \
		--cov="$(COVERAGE_TARGET)" \
		--cov-report=term-missing \
		-v

python-check: python-lint python-type python-test

python-check-all: python-lint python-type python-test-cov python-audit

python-audit:
	@set -e; \
	echo "==> Creating temporary audit environment: $(AUDIT_VENV_DIR)"; \
	rm -rf "$(AUDIT_VENV_DIR)"; \
	trap 'rm -rf "$(AUDIT_VENV_DIR)"' EXIT HUP INT TERM; \
	"$(PYTHON)" -m venv "$(AUDIT_VENV_DIR)"; \
	"$(AUDIT_PYTHON)" -m pip install --upgrade pip; \
	"$(AUDIT_PYTHON)" -m pip install $(PIP_INSTALL_DEV); \
	"$(AUDIT_PYTHON)" -m pip install pip-audit; \
	echo "==> Running dependency audit"; \
	"$(AUDIT_PYTHON)" -m pip_audit; \
	echo "==> Dependency audit complete"

python-build:
	@set -e; \
	if [ -z "$(strip $(PYTHON_PACKAGE_DIRS))" ]; then \
		$(HATCH) build; \
	else \
		for pkg in $(PYTHON_PACKAGE_DIRS); do \
			echo "==> Building $$pkg"; \
			( cd "$$pkg" && $(HATCH) build ); \
		done; \
	fi

python-publish: python-build
	$(HATCH) publish

python-clean:
	rm -rf \
		"$(VENV_DIR)" \
		"$(AUDIT_VENV_DIR)" \
		build \
		dist \
		.pytest_cache \
		.mypy_cache \
		.ruff_cache \
		.coverage \
		coverage.xml \
		htmlcov
	find . \
		-type d \
		\( \
			-name "*.egg-info" \
			-o -name "__pycache__" \
		\) \
		-prune \
		-exec rm -rf {} +
