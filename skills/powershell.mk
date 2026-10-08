PWSH ?= pwsh
SRC_DIR ?= .
SCRIPTANALYZER_FLAGS ?=
POWERSHELL_FILES ?= $(shell \
	find "$(SRC_DIR)" \
		\( -path '*/.makefiles/*' -o -path '*/.git/*' \) -prune -o \
		\( -name '*.ps1' -o -name '*.psm1' -o -name '*.psd1' \) -type f -print 2>/dev/null | sort \
)

STATUS_FRAGMENTS += status-powershell

.PHONY: help-powershell status-powershell powershell-doctor powershell-syntax powershell-analyze powershell-lint powershell-check

help-powershell:
	$(call mf_help_header,PowerShell:)
	$(call mf_help_line,powershell-doctor,Check PowerShell tools and source discovery)
	$(call mf_help_line,powershell-syntax,Parse PowerShell files with pwsh)
	$(call mf_help_line,powershell-analyze,Analyse PowerShell files with PSScriptAnalyzer)
	$(call mf_help_line,powershell-lint,Run PowerShell syntax validation and PSScriptAnalyzer)
	$(call mf_help_line,powershell-check,Alias of powershell-lint)
	@echo

status-powershell:
	@$(mf_color_prelude) \
	mf_color_init; \
	mf_heading "PowerShell:"; \
	mf_plain "Source directory:" "$(SRC_DIR)"; \
	set -- $(POWERSHELL_FILES); \
	mf_plain "Files discovered:" "$$#"; \
	if command -v "$(PWSH)" >/dev/null 2>&1; then \
		mf_tagged "pwsh:" green "[OK]" "$$(command -v "$(PWSH)")"; \
		if "$(PWSH)" -NoProfile -NonInteractive -Command 'if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) { exit 1 }'; then \
			mf_tagged "PSScriptAnalyzer:" green "[OK]" "module"; \
		else \
			mf_tagged "PSScriptAnalyzer:" red "[MISSING]" "PSScriptAnalyzer"; \
		fi; \
	else \
		mf_tagged "pwsh:" red "[MISSING]" "$(PWSH)"; \
		mf_tagged "PSScriptAnalyzer:" red "[MISSING]" "PSScriptAnalyzer"; \
	fi

powershell-doctor:
	@$(mf_color_prelude) \
	mf_color_init; \
	failures=0; \
	mf_heading "PowerShell doctor:"; \
	if [ -d "$(SRC_DIR)" ]; then \
		mf_tagged "Source directory:" green "[OK]" "$(SRC_DIR)"; \
	else \
		mf_tagged "Source directory:" red "[MISSING]" "$(SRC_DIR)"; \
		failures=$$((failures + 1)); \
	fi; \
	if command -v "$(PWSH)" >/dev/null 2>&1; then \
		mf_tagged "pwsh:" green "[OK]" "$$(command -v "$(PWSH)")"; \
		if "$(PWSH)" -NoProfile -NonInteractive -Command 'if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) { exit 1 }'; then \
			mf_tagged "PSScriptAnalyzer:" green "[OK]" "module"; \
		else \
			mf_tagged "PSScriptAnalyzer:" red "[MISSING]" "PSScriptAnalyzer"; \
			failures=$$((failures + 1)); \
		fi; \
	else \
		mf_tagged "pwsh:" red "[MISSING]" "$(PWSH)"; \
		mf_tagged "PSScriptAnalyzer:" red "[MISSING]" "PSScriptAnalyzer"; \
		failures=$$((failures + 1)); \
	fi; \
	set -- $(POWERSHELL_FILES); \
	if [ "$$#" -gt 0 ]; then \
		mf_tagged "Files discovered:" green "[OK]" "$$#"; \
	else \
		mf_tagged "Files discovered:" yellow "[WARN]" "0 — set SRC_DIR or POWERSHELL_FILES"; \
	fi; \
	if [ "$$failures" -ne 0 ]; then \
		mf_msg_err "PowerShell doctor found $$failures issue(s)."; \
		exit 1; \
	fi; \
	mf_msg_ok "PowerShell doctor: OK"

define require_powershell_files
	@test -n "$(strip $(POWERSHELL_FILES))" || { \
		echo "ERROR: no PowerShell files were discovered." >&2; \
		echo "Search directory: $(SRC_DIR)" >&2; \
		echo "Set SRC_DIR or provide POWERSHELL_FILES explicitly." >&2; \
		exit 2; \
	}
endef

define require_pwsh
	@command -v "$(PWSH)" >/dev/null 2>&1 || { \
		echo "ERROR: PowerShell command not found: $(PWSH)" >&2; \
		exit 2; \
	}
endef

powershell-syntax:
	@$(require_powershell_files)
	@$(require_pwsh)
	@failed=0; \
	for file in $(POWERSHELL_FILES); do \
		if PWSH_FILE="$$file" "$(PWSH)" -NoProfile -NonInteractive -Command '\
			$$errs = $$null; \
			$$null = [System.Management.Automation.Language.Parser]::ParseFile($$env:PWSH_FILE, [ref]$$null, [ref]$$errs); \
			if ($$errs -and $$errs.Count -gt 0) { $$errs | ForEach-Object { $$_.ToString() }; exit 1 }'; then \
			printf '  PASS  %s\n' "$$file"; \
		else \
			printf '  FAIL  %s\n' "$$file"; \
			failed=$$((failed + 1)); \
		fi; \
	done; \
	if [ "$$failed" -ne 0 ]; then \
		echo "PowerShell syntax validation failed." >&2; \
		exit 1; \
	fi; \
	echo "PowerShell syntax validation passed."

powershell-analyze:
	@$(require_powershell_files)
	@$(require_pwsh)
	@ps_files=""; \
	sep=""; \
	for file in $(POWERSHELL_FILES); do \
		escaped=$$(printf '%s' "$$file" | sed "s/'/''/g"); \
		ps_files="$$ps_files$$sep'$$escaped'"; \
		sep=","; \
	done; \
	settings=""; \
	if [ -f PSScriptAnalyzerSettings.psd1 ]; then \
		settings="PSScriptAnalyzerSettings.psd1"; \
	fi; \
	"$(PWSH)" -NoProfile -NonInteractive -Command "\
		if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) { \
			Write-Error 'ERROR: PSScriptAnalyzer module not found.'; \
			exit 2 \
		}; \
		\$$ErrorActionPreference = 'Stop'; \
		try { \
			Import-Module PSScriptAnalyzer; \
			\$$failed = 0; \
			foreach (\$$file in @($$ps_files)) { \
				\$$splat = @{ Path = \$$file }; \
				if ('$$settings' -ne '') { \$$splat.Settings = '$$settings' }; \
				\$$results = Invoke-ScriptAnalyzer @splat $(SCRIPTANALYZER_FLAGS); \
				if (\$$results) { \
					\$$results | Format-Table -AutoSize | Out-String | Write-Host; \
					\$$failed++ \
				} \
			} \
		} catch { \
			Write-Error \$$_; \
			exit 1 \
		}; \
		if (\$$failed -gt 0) { exit 1 }; \
		Write-Host 'PowerShell analysis passed.'"

powershell-lint: powershell-syntax powershell-analyze

powershell-check: powershell-lint
