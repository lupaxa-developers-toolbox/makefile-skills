#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=/dev/null
source "$(dirname "$0")/harness.sh"

unset NO_COLOR FORCE_COLOR

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

make_consumer "$TMP/consumer"
cat > "$TMP/consumer/.bumpversion.toml" <<'EOF'
[tool.bumpversion]
current_version = "0.1.0"
EOF

BARE="$TMP/bare.git"
makefiles_bare_repo "$BARE"
make -C "$TMP/consumer" init MAKEFILES_REPO="$BARE" MAKEFILES_TRANSPORT=https

# With NO_COLOR, status must not contain ESC
out="$(NO_COLOR=1 make -C "$TMP/consumer" status 2>&1)"
assert_contains "$out" "Project:"
assert_contains "$out" "[OK]"
if printf '%s' "$out" | grep -q $'\033'; then
  echo "ASSERT: NO_COLOR=1 status must not contain ESC" >&2
  exit 1
fi

# With FORCE_COLOR, status must contain ESC even when not a TTY
out="$(FORCE_COLOR=1 make -C "$TMP/consumer" status 2>&1)"
assert_contains "$out" "[OK]"
if ! printf '%s' "$out" | grep -q $'\033'; then
  echo "ASSERT: FORCE_COLOR=1 status must contain ESC" >&2
  exit 1
fi
assert_contains "$out" $'\033[96m'   # bright cyan heading
assert_contains "$out" $'\033[32m'   # green OK

# False-like FORCE_COLOR must not enable colour
out="$(FORCE_COLOR=0 make -C "$TMP/consumer" status 2>&1)"
if printf '%s' "$out" | grep -q $'\033'; then
  echo "ASSERT: FORCE_COLOR=0 status must not contain ESC" >&2
  exit 1
fi

# NO_COLOR wins over FORCE_COLOR
out="$(NO_COLOR=1 FORCE_COLOR=1 make -C "$TMP/consumer" status 2>&1)"
if printf '%s' "$out" | grep -q $'\033'; then
  echo "ASSERT: NO_COLOR must win over FORCE_COLOR" >&2
  exit 1
fi

# Doctor failure summary is red when FORCE_COLOR (break versioning by removing bump tool from PATH)
out="$(FORCE_COLOR=1 env PATH="/usr/bin:/bin" make -C "$TMP/consumer" doctor-versioning 2>&1)" || true
assert_contains "$out" "[MISSING]"
assert_contains "$out" $'\033[31m'

# An older consumer wrapper may include only versioning.mk (colour lives there).
mkdir -p "$TMP/legacy-consumer/.makefiles/skills"
cp "$REPO_ROOT/skills/versioning.mk" "$TMP/legacy-consumer/.makefiles/skills/versioning.mk"
cat > "$TMP/legacy-consumer/Makefile" <<'EOF'
-include .makefiles/skills/versioning.mk
EOF
cat > "$TMP/legacy-consumer/.bumpversion.toml" <<'EOF'
[tool.bumpversion]
current_version = "0.1.0"
EOF
out="$(FORCE_COLOR=1 make -C "$TMP/legacy-consumer" status 2>&1)"
assert_not_contains "$out" "mf_color_init: command not found"
assert_contains "$out" $'\033[96m'

# make help: cyan section headers; NO_COLOR stays plain
out="$(FORCE_COLOR=1 make -C "$TMP/consumer" help 2>&1)"
assert_contains "$out" "Lifecycle:"
assert_contains "$out" "Status:"
assert_contains "$out" "Versioning:"
assert_contains "$out" $'\033[96m'
out="$(NO_COLOR=1 make -C "$TMP/consumer" help 2>&1)"
assert_contains "$out" "Lifecycle:"
if printf '%s' "$out" | grep -q $'\033'; then
  echo "ASSERT: NO_COLOR=1 help must not contain ESC" >&2
  exit 1
fi

# version / show-version-flow: cyan labels
out="$(FORCE_COLOR=1 make -C "$TMP/consumer" version 2>&1)"
assert_contains "$out" "version:"
assert_contains "$out" $'\033[96m'
out="$(FORCE_COLOR=1 make -C "$TMP/consumer" show-version-flow 2>&1)"
assert_contains "$out" "Current version:"
assert_contains "$out" "Suggested next steps:"
assert_contains "$out" $'\033[96m'

# bump ERROR is red; bump success is green
bindir="$TMP/bin"
install_bump_stub "$bindir"
out="$(FORCE_COLOR=1 env PATH="$bindir:$PATH" make -C "$TMP/consumer" bump-patch 2>&1)"
assert_contains "$out" "Bump stable (patch):"
assert_contains "$out" $'\033[32m'
# Force an error: bump-patch while on -dev (after bump-dev)
FORCE_COLOR=1 env PATH="$bindir:$PATH" make -C "$TMP/consumer" bump-dev >/dev/null
err="$(FORCE_COLOR=1 env PATH="$bindir:$PATH" make -C "$TMP/consumer" bump-patch 2>&1)" || true
assert_contains "$err" "ERROR:"
assert_contains "$err" $'\033[31m'

echo "PASS: test_status_colour.sh"
