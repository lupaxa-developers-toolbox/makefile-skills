PROJECT_NAME ?= $(notdir $(CURDIR))
BUMP ?= bump-my-version
VERSION_FILE ?= .bumpversion.toml
PROJECT_VERSION := $(shell sed -n 's/^[[:space:]]*current_version[[:space:]]*=[[:space:]]*"\([^"]*\)"[[:space:]]*$$/\1/p' "$(VERSION_FILE)" 2>/dev/null | head -n 1)

# Defaults so top-level doctor works even with an older consumer wrapper.
MAKEFILES_DIR ?= .makefiles
MAKEFILES_MODE ?= consumer
MAKEFILES_REF ?= head
MAKEFILES_TRANSPORT ?= https
MAKEFILES_CUSTOM_DIR ?= .makefiles-custom
SKILLS ?=

# Colour helpers live here (not a separate skills/*.mk) so makefile conventions
# stay happy: skill files must not include other .mk files, and common.mk is
# not a real skill. Older wrappers that only include versioning.mk still get colour.

# Expand at the start of a recipe that needs colour helpers:
#   @$(mf_color_prelude) \
#   mf_color_init; \
#   ...

define mf_color_prelude
mf_color_init() { \
	if [ -n "$${NO_COLOR:-}" ]; then \
		MF_C=0; \
	else \
		case "$${FORCE_COLOR:-}" in \
			""|0|[Ff][Aa][Ll][Ss][Ee]|[Nn][Oo]) \
				if [ -t 1 ]; then MF_C=1; else MF_C=0; fi ;; \
			*) MF_C=1 ;; \
		esac; \
	fi; \
	if [ "$$MF_C" -eq 1 ]; then \
		MF_GREEN=$$(printf '\033[32m'); \
		MF_YELLOW=$$(printf '\033[33m'); \
		MF_RED=$$(printf '\033[31m'); \
		MF_CYAN=$$(printf '\033[96m'); \
		MF_RESET=$$(printf '\033[0m'); \
	else \
		MF_GREEN=; MF_YELLOW=; MF_RED=; MF_CYAN=; MF_RESET=; \
	fi; \
}; \
mf_title() { printf '%s%s%s\n' "$$MF_CYAN" "$$1" "$$MF_RESET"; }; \
mf_heading() { printf '\n%s%s%s\n' "$$MF_CYAN" "$$1" "$$MF_RESET"; }; \
mf_plain() { printf '  %-22s %s\n' "$$1" "$$2"; }; \
mf_tagged() { \
	_mf_lbl="$$1"; _mf_col="$$2"; _mf_tag="$$3"; _mf_rest="$${4-}"; \
	case "$$_mf_col" in \
		green) _mf_c="$$MF_GREEN" ;; \
		yellow) _mf_c="$$MF_YELLOW" ;; \
		red) _mf_c="$$MF_RED" ;; \
		*) _mf_c= ;; \
	esac; \
	if [ -n "$$_mf_rest" ]; then \
		printf '  %-22s %s%s%s %s\n' "$$_mf_lbl" "$$_mf_c" "$$_mf_tag" "$$MF_RESET" "$$_mf_rest"; \
	else \
		printf '  %-22s %s%s%s\n' "$$_mf_lbl" "$$_mf_c" "$$_mf_tag" "$$MF_RESET"; \
	fi; \
}; \
mf_msg_ok() { printf '%s%s%s\n' "$$MF_GREEN" "$$1" "$$MF_RESET"; }; \
mf_msg_err() { printf '%s%s%s\n' "$$MF_RED" "$$1" "$$MF_RESET" >&2; }; \
mf_label() { printf '%s%s%s %s\n' "$$MF_CYAN" "$$1" "$$MF_RESET" "$$2"; };
endef

# One-line Make recipe: cyan help section header (respects NO_COLOR / FORCE_COLOR / TTY).
# Usage: $(call mf_help_header,Lifecycle:)
define mf_help_header
@$(mf_color_prelude) \
mf_color_init; \
mf_title "$(1)"
endef

# Fixed-width command column so descriptions line up across all help sections.
# Longest current target: python-check-diff-all (21). Override with MF_HELP_CMD_WIDTH if needed.
MF_HELP_CMD_WIDTH ?= 22
mf_comma := ,

# Usage: $(call mf_help_line,target-name,Description text)
# Commas in descriptions must be written as $$(mf_comma) (Make splits call args on ,).
# Command column is green when colour is enabled (pad plain text, then wrap ANSI).
define mf_help_line
@$(mf_color_prelude) \
mf_color_init; \
printf '  %s%-*s%s %s\n' "$$MF_GREEN" $(MF_HELP_CMD_WIDTH) "$(1)" "$$MF_RESET" "$(2)"
endef

# Description continuation (blank command column, same width).
define mf_help_cont
@printf '  %-*s %s\n' $(MF_HELP_CMD_WIDTH) "" "$(1)"
endef

.PHONY: bump-patch bump-minor bump-major bump-patch-dev bump-minor-dev bump-major-dev bump-dev \
	bump-patch-rc bump-minor-rc bump-major-rc bump-rc release bump-final draft-tag \
	doctor doctor-versioning help-versioning show-version-flow status version

# Status is always-on (printed before Versioning) so it appears even when the
# consumer wrapper's help text is outdated.
help-versioning:
	$(call mf_help_header,Status:)
	$(call mf_help_line,status,Show project$(mf_comma) version$(mf_comma) Git$(mf_comma) and enabled-skill status)
	$(call mf_help_line,doctor,Run all doctors (lifecycle + versioning + enabled skills))
	@echo
	$(call mf_help_header,Versioning:)
	$(call mf_help_line,version,Show the current project version)
	$(call mf_help_line,show-version-flow,Show the version stage and valid next steps)
	$(call mf_help_line,bump-patch,Bump to the next stable patch (X.Y.Z+1))
	$(call mf_help_line,bump-minor,Bump to the next stable minor (X.Y+1.0))
	$(call mf_help_line,bump-major,Bump to the next stable major (X+1.0.0))
	$(call mf_help_line,bump-dev,Alias of bump-patch-dev)
	$(call mf_help_line,bump-patch-dev,Start/continue patch -devN)
	$(call mf_help_line,bump-minor-dev,Start/continue minor -devN)
	$(call mf_help_line,bump-major-dev,Start/continue major -devN)
	$(call mf_help_line,bump-rc,Alias of bump-patch-rc)
	$(call mf_help_line,bump-patch-rc,Start patch -rc1 from stable/dev$(mf_comma) or bump -rcN)
	$(call mf_help_line,bump-minor-rc,Start minor -rc1 from stable/dev$(mf_comma) or bump -rcN)
	$(call mf_help_line,bump-major-rc,Start major -rc1 from stable/dev$(mf_comma) or bump -rcN)
	$(call mf_help_line,release,Publish -rcN as stable)
	$(call mf_help_line,bump-final,Alias of release)
	$(call mf_help_line,doctor-versioning,Check versioning config and tools)
	@echo
	$(call mf_help_header,GitHub packaging (does not change current_version):)
	$(call mf_help_line,draft-tag,Create next vX.Y.Z-draftN tag at HEAD for draft releases)
	@echo

# Top-level doctor lives in skills so `make doctor` works after init/update
# even if the project wrapper predates the doctor target.
# Always runs every section (versioning + each enabled skill); exits non-zero
# only after all sections have reported.
doctor:
	@set +e; \
	$(mf_color_prelude) \
	mf_color_init; \
	failures=0; \
	mf_title "$(or $(PROJECT_NAME),$(notdir $(CURDIR))) Doctor"; \
	mf_heading "Lifecycle:"; \
	mf_plain "Mode:" "$(MAKEFILES_MODE)"; \
	mf_plain "Transport:" "$(MAKEFILES_TRANSPORT)"; \
	mf_plain "Repository URL:" "$(MAKEFILES_REPO)"; \
	mf_plain "Ref:" "$(MAKEFILES_REF)"; \
	if command -v git >/dev/null 2>&1; then \
		mf_tagged "git:" green "[OK]" "$$(command -v git)"; \
	else \
		mf_tagged "git:" red "[MISSING]" "git"; \
		failures=$$((failures + 1)); \
	fi; \
	if [ "$(MAKEFILES_MODE)" = "library" ]; then \
		if [ -f "$(MAKEFILES_DIR)/skills/versioning.mk" ]; then \
			mf_tagged "Skills tree:" green "[OK]" "$(MAKEFILES_DIR)/skills"; \
		else \
			mf_tagged "Skills tree:" red "[MISSING]" "$(MAKEFILES_DIR)/skills/versioning.mk"; \
			failures=$$((failures + 1)); \
		fi; \
	elif [ -d "$(MAKEFILES_DIR)/.git" ]; then \
		mf_tagged "Skills clone:" green "[OK]" "$(MAKEFILES_DIR)"; \
	elif [ -e "$(MAKEFILES_DIR)" ]; then \
		mf_tagged "Skills clone:" red "[INVALID]" "$(MAKEFILES_DIR) exists but is not a git clone"; \
		failures=$$((failures + 1)); \
	else \
		mf_tagged "Skills clone:" red "[MISSING]" "$(MAKEFILES_DIR) — run: make init"; \
		failures=$$((failures + 1)); \
	fi; \
	if [ -f "$(MAKEFILES_DIR)/skills/versioning.mk" ]; then \
		mf_tagged "versioning.mk:" green "[OK]"; \
	else \
		mf_tagged "versioning.mk:" red "[MISSING]"; \
		failures=$$((failures + 1)); \
	fi; \
	for s in $(SKILLS); do \
		if [ -f "$(MAKEFILES_DIR)/skills/$$s.mk" ]; then \
			mf_tagged "skill $$s:" green "[OK]"; \
		else \
			mf_tagged "skill $$s:" red "[MISSING]" "$(MAKEFILES_DIR)/skills/$$s.mk"; \
			failures=$$((failures + 1)); \
		fi; \
	done; \
	if [ ! -f "$(MAKEFILES_DIR)/skills/versioning.mk" ]; then \
		echo; \
		mf_msg_err "Doctor found $$failures issue(s). Run: make init"; \
		exit 2; \
	fi; \
	$(MAKE) --no-print-directory doctor-versioning; \
	ver_rc=$$?; \
	if [ $$ver_rc -ne 0 ]; then failures=$$((failures + 1)); fi; \
	for s in $(SKILLS); do \
		$(MAKE) --no-print-directory $$s-doctor; \
		skill_rc=$$?; \
		if [ $$skill_rc -ne 0 ]; then failures=$$((failures + 1)); fi; \
	done; \
	echo; \
	if [ "$$failures" -ne 0 ]; then \
		mf_msg_err "Doctor found $$failures failing section(s)."; \
		exit 1; \
	fi; \
	mf_msg_ok "Doctor: all checks passed."

define require_version
	@$(mf_color_prelude) \
	mf_color_init; \
	if [ ! -f "$(VERSION_FILE)" ]; then \
		mf_msg_err "ERROR: version file not found: $(VERSION_FILE)"; \
		exit 2; \
	fi; \
	if [ -z "$(PROJECT_VERSION)" ]; then \
		mf_msg_err "ERROR: current_version was not found in $(VERSION_FILE)"; \
		exit 2; \
	fi
endef

# flavour: patch|minor|major
# mode: stable|dev|rc
define run_version_bump
	@$(require_version)
	@$(mf_color_prelude) \
	mf_color_init; \
	flavour="$(1)"; mode="$(2)"; current="$(PROJECT_VERSION)"; \
	base="$${current%%-*}"; \
	maj="$${base%%.*}"; rest="$${base#*.}"; min="$${rest%%.*}"; pat="$${rest#*.}"; \
	stage=stable; n=0; \
	case "$$current" in \
	  *-dev[0-9]*) stage=dev; n="$${current##*-dev}" ;; \
	  *-rc[0-9]*) stage=rc; n="$${current##*-rc}" ;; \
	esac; \
	channel_ok() { \
	  case "$$1" in \
	    patch) [ "$$pat" -ge 1 ] ;; \
	    minor) [ "$$pat" -eq 0 ] && [ "$$min" -ge 1 ] ;; \
	    major) [ "$$pat" -eq 0 ] && [ "$$min" -eq 0 ] && [ "$$maj" -ge 1 ] ;; \
	    *) return 1 ;; \
	  esac; \
	}; \
	open_channel() { \
	  if [ "$$pat" -ge 1 ]; then echo patch; \
	  elif [ "$$min" -ge 1 ]; then echo minor; \
	  elif [ "$$maj" -ge 1 ]; then echo major; \
	  else echo ""; fi; \
	}; \
	hint_target() { \
	  case "$$1-$$2" in \
	    dev-patch) echo "bump-dev (alias: bump-patch-dev)" ;; \
	    dev-minor) echo "bump-minor-dev" ;; \
	    dev-major) echo "bump-major-dev" ;; \
	    rc-patch) echo "bump-rc (alias: bump-patch-rc)" ;; \
	    rc-minor) echo "bump-minor-rc" ;; \
	    rc-major) echo "bump-major-rc" ;; \
	    *) echo "" ;; \
	  esac; \
	}; \
	next_base() { \
	  case "$$1" in \
	    patch) echo "$$maj.$$min.$$((pat + 1))" ;; \
	    minor) echo "$$maj.$$((min + 1)).0" ;; \
	    major) echo "$$((maj + 1)).0.0" ;; \
	  esac; \
	}; \
	new_version=""; \
	case "$$mode" in \
	  stable) \
	    if [ "$$stage" != stable ]; then \
	      ofl="$$(open_channel)"; \
	      if [ "$$stage" = dev ]; then hint="$$(hint_target dev "$$ofl")"; \
	      else hint="$$(hint_target rc "$$ofl")"; fi; \
	      if [ -n "$$hint" ]; then \
	        mf_msg_err "ERROR: bump-$$flavour requires a stable version (current: $$current). Hint: make $$hint"; \
	      else \
	        mf_msg_err "ERROR: bump-$$flavour requires a stable version (current: $$current)."; \
	      fi; \
	      exit 2; \
	    fi; \
	    new_version="$$(next_base "$$flavour")" ;; \
	  dev) \
	    if [ "$$stage" = rc ]; then \
	      ofl="$$(open_channel)"; hint="$$(hint_target rc "$$ofl")"; \
	      if [ -n "$$hint" ]; then \
	        mf_msg_err "ERROR: bump-$$flavour-dev cannot run on a release candidate ($$current). Hint: make $$hint or make release"; \
	      else \
	        mf_msg_err "ERROR: bump-$$flavour-dev cannot run on a release candidate ($$current). Hint: make release"; \
	      fi; \
	      exit 2; \
	    fi; \
	    if [ "$$stage" = stable ]; then \
	      nb="$$(next_base "$$flavour")"; new_version="$$nb-dev1"; \
	    else \
	      if ! channel_ok "$$flavour"; then \
	        ofl="$$(open_channel)"; hint="$$(hint_target dev "$$ofl")"; \
	        if [ -n "$$hint" ]; then \
	          mf_msg_err "ERROR: bump-$$flavour-dev does not match open channel for $$current. Hint: make $$hint"; \
	        else \
	          mf_msg_err "ERROR: bump-$$flavour-dev does not match open channel for $$current."; \
	        fi; \
	        exit 2; \
	      fi; \
	      new_version="$$base-dev$$((n + 1))"; \
	    fi ;; \
	  rc) \
	    if [ "$$stage" = stable ]; then \
	      nb="$$(next_base "$$flavour")"; new_version="$$nb-rc1"; \
	    else \
	      if ! channel_ok "$$flavour"; then \
	        ofl="$$(open_channel)"; hint="$$(hint_target rc "$$ofl")"; \
	        if [ -n "$$hint" ]; then \
	          mf_msg_err "ERROR: bump-$$flavour-rc does not match open channel for $$current. Hint: make $$hint"; \
	        else \
	          mf_msg_err "ERROR: bump-$$flavour-rc does not match open channel for $$current."; \
	        fi; \
	        exit 2; \
	      fi; \
	      if [ "$$stage" = dev ]; then new_version="$$base-rc1"; \
	      else new_version="$$base-rc$$((n + 1))"; fi; \
	    fi ;; \
	esac; \
	if [ "$$stage" = stable ]; then \
	  last_stable=""; \
	  if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then \
	    last_stable="$$(git tag -l 'v*' | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$$' | sort -V | tail -n 1)"; \
	    last_stable="$${last_stable#v}"; \
	  fi; \
	  if [ -n "$$last_stable" ] && [ "$$last_stable" != "$$current" ]; then \
	    mf_msg_err "ERROR: current_version ($$current) does not match last stable tag ($$last_stable). Do not tag by hand. Set current_version to $$last_stable, or delete the extra tag, then retry."; \
	    exit 2; \
	  fi; \
	fi; \
	mf_msg_ok "Bump $$mode ($$flavour): $$current -> $$new_version"; \
	$(BUMP) bump version --new-version "$$new_version"
endef

doctor-versioning:
	@$(mf_color_prelude) \
	mf_color_init; \
	failures=0; \
	mf_heading "Versioning doctor:"; \
	if [ -f "$(VERSION_FILE)" ]; then \
		mf_tagged "Configuration:" green "[OK]" "$(VERSION_FILE)"; \
	else \
		mf_tagged "Configuration:" red "[MISSING]" "$(VERSION_FILE)"; \
		failures=$$((failures + 1)); \
	fi; \
	if [ -n "$(PROJECT_VERSION)" ]; then \
		mf_tagged "current_version:" green "[OK]" "$(PROJECT_VERSION)"; \
	else \
		mf_tagged "current_version:" red "[MISSING]"; \
		failures=$$((failures + 1)); \
	fi; \
	if command -v "$(BUMP)" >/dev/null 2>&1; then \
		mf_tagged "bump-my-version:" green "[OK]" "$$(command -v "$(BUMP)")"; \
	else \
		mf_tagged "bump-my-version:" red "[MISSING]" "$(BUMP)"; \
		failures=$$((failures + 1)); \
	fi; \
	if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then \
		mf_tagged "Git work tree:" green "[OK]"; \
	else \
		mf_tagged "Git work tree:" red "[MISSING]"; \
		failures=$$((failures + 1)); \
	fi; \
	if [ "$$failures" -ne 0 ]; then \
		mf_msg_err "Versioning doctor found $$failures issue(s)."; \
		exit 1; \
	fi; \
	mf_msg_ok "Versioning doctor: OK"

STATUS_FRAGMENTS ?=

status:
	@$(mf_color_prelude) \
	mf_color_init; \
	current="$(PROJECT_VERSION)"; \
	mf_title "$(PROJECT_NAME) Repository Status"; \
	mf_heading "Project:"; \
	mf_plain "Name:" "$(PROJECT_NAME)"; \
	mf_plain "Directory:" "$(CURDIR)"; \
	mf_heading "Versioning:"; \
	if [ -f "$(VERSION_FILE)" ]; then \
		mf_tagged "Configuration:" green "[OK]" "$(VERSION_FILE)"; \
	else \
		mf_tagged "Configuration:" red "[MISSING]" "$(VERSION_FILE)"; \
	fi; \
	if [ -n "$$current" ]; then \
		base="$${current%%-*}"; \
		major="$${base%%.*}"; \
		minor_patch="$${base#*.}"; \
		minor="$${minor_patch%%.*}"; \
		patch="$${minor_patch##*.}"; \
		if [ "$$patch" -ge 1 ]; then flavour=patch; \
		elif [ "$$minor" -ge 1 ]; then flavour=minor; \
		elif [ "$$major" -ge 1 ]; then flavour=major; \
		else flavour=""; fi; \
		case "$$current" in \
			*-dev[0-9]*) \
				stage="Development pre-release"; \
				dev_number="$${current##*-dev}"; \
				next_dev="$$base-dev$$((dev_number + 1))"; \
				next_rc="$$base-rc1"; \
				mf_plain "Current version:" "$$current"; \
				mf_plain "Stage:" "$$stage"; \
				if [ -n "$$flavour" ]; then \
					if [ "$$flavour" = patch ]; then dev_target="bump-dev"; rc_target="bump-rc"; \
					else dev_target="bump-$$flavour-dev"; rc_target="bump-$$flavour-rc"; fi; \
					mf_plain "Next development:" "make $$dev_target ($$next_dev)"; \
					mf_plain "Next release candidate:" "make $$rc_target ($$next_rc)"; \
					mf_plain "Next stable release:" "$$base"; \
				else \
					mf_plain "Next step:" "No matching channel continues this pre-release ($$base)"; \
				fi ;; \
			*-rc[0-9]*) \
				stage="Release candidate"; \
				rc_number="$${current##*-rc}"; \
				next_rc="$$base-rc$$((rc_number + 1))"; \
				mf_plain "Current version:" "$$current"; \
				mf_plain "Stage:" "$$stage"; \
				if [ -n "$$flavour" ]; then \
					if [ "$$flavour" = patch ]; then rc_target="bump-rc"; else rc_target="bump-$$flavour-rc"; fi; \
					mf_plain "Next release candidate:" "make $$rc_target ($$next_rc)"; \
				else \
					mf_plain "Next release candidate:" "No matching channel continues this pre-release ($$base)"; \
				fi; \
				mf_plain "Next stable release:" "make release ($$base)" ;; \
			*) \
				stage="Final / stable release"; \
				next_patch="$$major.$$minor.$$((patch + 1))"; \
				next_minor="$$major.$$((minor + 1)).0"; \
				next_major="$$((major + 1)).0.0"; \
				next_patch_dev="$$next_patch-dev1"; \
				next_minor_dev="$$next_minor-dev1"; \
				next_major_dev="$$next_major-dev1"; \
				next_patch_rc="$$next_patch-rc1"; \
				next_minor_rc="$$next_minor-rc1"; \
				next_major_rc="$$next_major-rc1"; \
				mf_plain "Current version:" "$$current"; \
				mf_plain "Stage:" "$$stage"; \
				mf_plain "Next patch (stable):" "$$next_patch"; \
				mf_plain "Next minor (stable):" "$$next_minor"; \
				mf_plain "Next major (stable):" "$$next_major"; \
				mf_plain "Next patch (dev):" "$$next_patch_dev"; \
				mf_plain "Next minor (dev):" "$$next_minor_dev"; \
				mf_plain "Next major (dev):" "$$next_major_dev"; \
				mf_plain "Next patch (rc):" "$$next_patch_rc"; \
				mf_plain "Next minor (rc):" "$$next_minor_rc"; \
				mf_plain "Next major (rc):" "$$next_major_rc" ;; \
		esac; \
	else \
		mf_tagged "Current version:" red "[UNAVAILABLE]"; \
		mf_tagged "Stage:" red "[UNAVAILABLE]"; \
	fi; \
	if command -v "$(BUMP)" >/dev/null 2>&1; then \
		bump_path="$$(command -v "$(BUMP)")"; \
		mf_tagged "bump-my-version:" green "[OK]" "$$bump_path"; \
	else \
		mf_tagged "bump-my-version:" red "[MISSING]" "$(BUMP)"; \
	fi; \
	mf_heading "Git:"; \
	if command -v git >/dev/null 2>&1; then \
		mf_tagged "Git command:" green "[OK]" "$$(command -v git)"; \
		if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then \
			branch="$$(git branch --show-current 2>/dev/null)"; \
			if [ -z "$$branch" ]; then branch="Detached HEAD"; fi; \
			if [ -z "$$(git status --porcelain 2>/dev/null)" ]; then working_tree="Clean"; else working_tree="Changes present"; fi; \
			mf_tagged "Repository:" green "[OK]" "Git work tree"; \
			mf_plain "Branch:" "$$branch"; \
			mf_plain "Working tree:" "$$working_tree"; \
		else \
			mf_tagged "Repository:" red "[UNAVAILABLE]" "Not a Git work tree"; \
			mf_tagged "Branch:" red "[UNAVAILABLE]"; \
			mf_tagged "Working tree:" red "[UNAVAILABLE]"; \
		fi; \
	else \
		mf_tagged "Git command:" red "[MISSING]" "git"; \
		mf_tagged "Repository:" red "[UNAVAILABLE]"; \
		mf_tagged "Branch:" red "[UNAVAILABLE]"; \
		mf_tagged "Working tree:" red "[UNAVAILABLE]"; \
	fi
	@for t in $(STATUS_FRAGMENTS); do \
		$(MAKE) --no-print-directory $$t; \
	done

version:
	@$(require_version)
	@$(mf_color_prelude) \
	mf_color_init; \
	mf_label "$(PROJECT_NAME) version:" "$(PROJECT_VERSION)"

bump-patch:
	$(call run_version_bump,patch,stable)

bump-minor:
	$(call run_version_bump,minor,stable)

bump-major:
	$(call run_version_bump,major,stable)

bump-patch-dev bump-dev:
	$(call run_version_bump,patch,dev)

bump-minor-dev:
	$(call run_version_bump,minor,dev)

bump-major-dev:
	$(call run_version_bump,major,dev)

bump-patch-rc bump-rc:
	$(call run_version_bump,patch,rc)

bump-minor-rc:
	$(call run_version_bump,minor,rc)

bump-major-rc:
	$(call run_version_bump,major,rc)

release bump-final:
	@$(require_version)
	@$(mf_color_prelude) \
	mf_color_init; \
	current="$(PROJECT_VERSION)"; \
	case "$$current" in \
	  *-rc[0-9]*) new_version="$${current%%-*}" ;; \
	  *) mf_msg_err "ERROR: release expects a -rcN version (current: $$current)."; exit 2 ;; \
	esac; \
	mf_msg_ok "Release version: $$current -> $$new_version"; \
	$(BUMP) bump version --new-version "$$new_version"

# Create vX.Y.Z-draftN at HEAD for generate-draft-release.yml. Does not modify
# .bumpversion.toml. Base is stripped of -devN/-rcN; override with DRAFT_BASE=X.Y.Z.
draft-tag:
	@$(require_version)
	@$(mf_color_prelude) \
	mf_color_init; \
	command -v git >/dev/null 2>&1 || { mf_msg_err "ERROR: git is required for draft-tag"; exit 2; }; \
	git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { \
		mf_msg_err "ERROR: draft-tag must run inside a Git work tree"; exit 2; \
	}; \
	current="$(PROJECT_VERSION)"; \
	if [ -n "$(DRAFT_BASE)" ]; then base="$(DRAFT_BASE)"; else base="$${current%%-*}"; fi; \
	echo "$$base" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$$' || { \
		mf_msg_err "ERROR: draft base must be X.Y.Z (got: $$base)"; exit 2; \
	}; \
	n=1; \
	while git rev-parse -q --verify "refs/tags/v$$base-draft$$n" >/dev/null 2>&1; do \
		n=$$((n + 1)); \
	done; \
	tag="v$$base-draft$$n"; \
	git tag -a "$$tag" -m "Draft release $$base-draft$$n"; \
	mf_msg_ok "Created annotated tag $$tag at $$(git rev-parse --short HEAD)"; \
	echo "Push with: git push origin $$tag"; \
	echo "(.bumpversion.toml unchanged: $$current)"

show-version-flow:
	@$(require_version)
	@$(mf_color_prelude) \
	mf_color_init; \
	current="$(PROJECT_VERSION)"; \
	base="$${current%%-*}"; major="$${base%%.*}"; minor_patch="$${base#*.}"; minor="$${minor_patch%%.*}"; patch="$${minor_patch##*.}"; \
	next_patch="$$major.$$minor.$$((patch + 1))"; next_minor="$$major.$$((minor + 1)).0"; next_major="$$((major + 1)).0.0"; \
	if [ "$$patch" -ge 1 ]; then flavour=patch; \
	elif [ "$$minor" -ge 1 ]; then flavour=minor; \
	elif [ "$$major" -ge 1 ]; then flavour=major; \
	else flavour=""; fi; \
	if [ "$$flavour" = patch ]; then dev_target="bump-dev"; rc_target="bump-rc"; \
	elif [ -n "$$flavour" ]; then dev_target="bump-$$flavour-dev"; rc_target="bump-$$flavour-rc"; \
	else dev_target=""; rc_target=""; fi; \
	mf_label "Current version:" "$$current"; echo; \
	if echo "$$current" | grep -Eq -- '-dev[0-9]+$$'; then \
		dev_number="$${current##*-dev}"; next_dev="$$base-dev$$((dev_number + 1))"; next_rc="$$base-rc1"; \
		mf_label "Stage:" "development pre-release"; echo; \
		if [ -n "$$flavour" ]; then \
			mf_title "Suggested next steps:"; echo; \
			printf "  %-20s %-44s (%s)\n" "make $$dev_target" "Continue the development cycle" "$$next_dev"; \
			printf "  %-20s %-44s (%s)\n" "make $$rc_target" "Promote to the first release candidate" "$$next_rc"; \
		else \
			echo "No matching channel continues this pre-release ($$base): patch/minor/major bumps require the corresponding X.Y.Z part to be >=1."; \
		fi; \
	elif echo "$$current" | grep -Eq -- '-rc[0-9]+$$'; then \
		rc_number="$${current##*-rc}"; next_rc="$$base-rc$$((rc_number + 1))"; \
		mf_label "Stage:" "release candidate"; echo; \
		mf_title "Suggested next steps:"; echo; \
		if [ -n "$$flavour" ]; then \
			printf "  %-20s %-44s (%s)\n" "make $$rc_target" "Continue the release candidate cycle" "$$next_rc"; \
		else \
			echo "  (No matching channel continues this pre-release ($$base); further -rc bumps are unavailable.)"; \
		fi; \
		printf "  %-20s %-44s (%s)\n" "make release" "Publish the stable release" "$$base"; \
	else \
		next_patch_dev="$$next_patch-dev1"; next_minor_dev="$$next_minor-dev1"; next_major_dev="$$next_major-dev1"; \
		next_patch_rc="$$next_patch-rc1"; next_minor_rc="$$next_minor-rc1"; next_major_rc="$$next_major-rc1"; \
		mf_label "Stage:" "final / stable release"; echo; \
		mf_title "Suggested next steps:"; echo; \
		printf "  %-20s %-44s (%s)\n" "make bump-patch" "Bump to the next stable patch" "$$next_patch"; \
		printf "  %-20s %-44s (%s)\n" "make bump-minor" "Bump to the next stable minor" "$$next_minor"; \
		printf "  %-20s %-44s (%s)\n" "make bump-major" "Bump to the next stable major" "$$next_major"; \
		printf "  %-20s %-44s (%s)\n" "make bump-dev" "Start the next patch development cycle" "$$next_patch_dev"; \
		printf "  %-20s %-44s (%s)\n" "make bump-minor-dev" "Start the next minor development cycle" "$$next_minor_dev"; \
		printf "  %-20s %-44s (%s)\n" "make bump-major-dev" "Start the next major development cycle" "$$next_major_dev"; \
		printf "  %-20s %-44s (%s)\n" "make bump-rc" "Start the next patch release candidate" "$$next_patch_rc"; \
		printf "  %-20s %-44s (%s)\n" "make bump-minor-rc" "Start the next minor release candidate" "$$next_minor_rc"; \
		printf "  %-20s %-44s (%s)\n" "make bump-major-rc" "Start the next major release candidate" "$$next_major_rc"; \
	fi

