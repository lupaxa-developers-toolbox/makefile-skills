# makefile-skills — library development Makefile
# Uses the local skills/ tree (no .makefiles clone).

MAKEFILES_MODE := library
MAKEFILES_DIR  := .
SKILLS         ?= bash mkdocs python ruby

include templates/Makefile

.PHONY: validate-makefiles validate-shell
validate-makefiles:
	@bash "$(CURDIR)/scripts/validate-makefiles.sh"

validate-shell:
	@bash "$(CURDIR)/scripts/validate-shell.sh"
