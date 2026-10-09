# makefile-skills — library development Makefile
# Uses the local skills/ tree (no .makefiles clone).

MAKEFILES_MODE := library
MAKEFILES_DIR  := .
# Versioning is always included. Optional skills are listed alphabetically.
SKILLS         ?= bash javascript mkdocs perl php powershell python ruby

include templates/Makefile

.PHONY: validate-makefiles validate-shell
validate-makefiles:
	@bash "$(CURDIR)/scripts/validate-makefiles.sh"

validate-shell:
	@bash "$(CURDIR)/scripts/validate-shell.sh"
