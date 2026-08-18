#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=/dev/null
source "$(dirname "$0")/harness.sh"

LOADER="$REPO_ROOT/skills/load-makefiles-config"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# missing file → empty success
out="$("$LOADER" "$TMP/missing.config")"
test -z "$out"

# maps keys
cat > "$TMP/makefiles.config" <<'EOF'
# comment
skills = python mkdocs
ref = v1.2.3
transport = https
update_wrapper = no
EOF
out="$("$LOADER" "$TMP/makefiles.config")"
assert_contains "$out" "SKILLS ?= python mkdocs"
assert_contains "$out" "MAKEFILES_REF ?= v1.2.3"
assert_contains "$out" "MAKEFILES_TRANSPORT ?= https"
assert_contains "$out" "MAKEFILES_UPDATE_WRAPPER ?= no"

# remaining key mappings
cat > "$TMP/repo.config" <<'EOF'
repo_ssh = git@github.com:org/repo.git
repo_http = https://github.com/org/repo.git
custom_dir = .makefiles/custom
EOF
out="$("$LOADER" "$TMP/repo.config")"
assert_contains "$out" "MAKEFILES_REPO_SSH ?= git@github.com:org/repo.git"
assert_contains "$out" "MAKEFILES_REPO_HTTP ?= https://github.com/org/repo.git"
assert_contains "$out" "MAKEFILES_CUSTOM_DIR ?= .makefiles/custom"

# unknown key fails with exit 2
cat > "$TMP/bad.config" <<'EOF'
skills = bash
nope = 1
EOF
set +e
err="$("$LOADER" "$TMP/bad.config" 2>&1)"
rc=$?
set -e
test "$rc" -eq 2
assert_contains "$err" "unknown key 'nope'"

# malformed line (no =) fails with exit 2
cat > "$TMP/malformed.config" <<'EOF'
skills = bash
not a key value line
EOF
set +e
err="$("$LOADER" "$TMP/malformed.config" 2>&1)"
rc=$?
set -e
test "$rc" -eq 2
assert_contains "$err" "expected key = value"
assert_contains "$err" "not a key value line"

# embedded fallback in templates/Makefile lists same keys as loader
loader_keys="$(sed -n '/make_var_for_key/,/^}/p' "$LOADER" | grep -E '^\s+[a-z_]+\)' | sed 's/).*//' | tr -d ' \t' | sort)"
fallback_line="$(awk '/^define mf_config_fallback_sh$/{getline; print}' "$REPO_ROOT/templates/Makefile")"
# Intentional single-quoted sed: match Make $$key literally, do not expand.
# shellcheck disable=SC2016
fallback_keys="$(printf '%s\n' "$fallback_line" | sed 's/.*case "\$\$key" in //' | tr ';' '\n' | grep ' mv=' | sed -E 's/^[[:space:]]*([a-z_]+)\) mv=.*/\1/' | grep -v '^\*' | sort -u)"
test "$loader_keys" = "$fallback_keys"

echo "PASS: test_makefiles_config.sh (loader)"

# -----------------------------------------------------------------------------
# Integration: wrapper + starter config + sparse templates + update_wrapper
# -----------------------------------------------------------------------------

BARE="$TMP/makefiles.git"
makefiles_bare_repo "$BARE"
CONSUMER="$TMP/consumer"
make_consumer "$CONSUMER"

# Pre-init: hand-written config loads via embedded fallback (transport=https)
cat > "$CONSUMER/makefiles.config" <<'EOF'
transport = https
update_wrapper = yes
EOF
out="$(make -C "$CONSUMER" help)"
assert_contains "$out" "https://github.com/lupaxa-developers-toolbox/makefile-skills.git"

# init creates makefiles.config once (never overwrite)
rm -f "$CONSUMER/makefiles.config"
out="$(NO_COLOR=1 make -C "$CONSUMER" init MAKEFILES_REPO="$BARE" 2>&1)"
test -f "$CONSUMER/makefiles.config"
assert_contains "$(cat "$CONSUMER/makefiles.config")" "skills"
assert_contains "$out" "Creating makefiles.config"
test -d "$CONSUMER/.makefiles/templates"
test -f "$CONSUMER/.makefiles/templates/Makefile"
test -f "$CONSUMER/.makefiles/templates/makefiles.config"
assert_contains "$out" "templates"

# mutate config and ensure update does not clobber it
echo "skills = bash" > "$CONSUMER/makefiles.config"
make -C "$CONSUMER" update MAKEFILES_REPO="$BARE"
assert_contains "$(cat "$CONSUMER/makefiles.config")" "skills = bash"

# default update refreshes Makefile from template
echo "# local divergence" >> "$CONSUMER/Makefile"
make -C "$CONSUMER" update MAKEFILES_REPO="$BARE"
diff -q "$CONSUMER/Makefile" "$CONSUMER/.makefiles/templates/Makefile"

# opt-out leaves diverged Makefile
{
  echo "skills = bash"
  echo "update_wrapper = no"
} > "$CONSUMER/makefiles.config"
echo "# keep me" >> "$CONSUMER/Makefile"
make -C "$CONSUMER" update MAKEFILES_REPO="$BARE"
assert_contains "$(cat "$CONSUMER/Makefile")" "# keep me"

# CLI beats config; config alone sets SKILLS
# Intentional: write a Make recipe that expands $(SKILLS) at make-time.
# shellcheck disable=SC2016
printf '\n__print_skills:\n\t@printf "%%s\\n" "$(SKILLS)"\n' >> "$CONSUMER/Makefile"
{
  echo "skills = python"
  echo "update_wrapper = no"
} > "$CONSUMER/makefiles.config"
out="$(make -C "$CONSUMER" __print_skills SKILLS=bash)"
test "$out" = "bash"
out="$(make -C "$CONSUMER" __print_skills)"
test "$out" = "python"

# unknown key in config fails Make clearly
echo "nope = 1" > "$CONSUMER/makefiles.config"
set +e
err="$(make -C "$CONSUMER" help 2>&1)"
rc=$?
set -e
test "$rc" -ne 0
assert_contains "$err" "makefiles.config"

echo "PASS: test_makefiles_config.sh"
