#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=/dev/null
source "$(dirname "$0")/harness.sh"

# Custom skills under MAKEFILES_CUSTOM_DIR (no auto-sync).
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

BARE="$TMP/bare.git"
makefiles_bare_repo "$BARE"
make_consumer "$TMP/c1"
cat > "$TMP/c1/.bumpversion.toml" <<'TOML'
[tool.bumpversion]
current_version = "0.1.0"
TOML
make -C "$TMP/c1" init MAKEFILES_REPO="$BARE" MAKEFILES_TRANSPORT=https

mkdir -p "$TMP/c1/.makefiles-custom"
cat > "$TMP/c1/.makefiles-custom/hello.mk" <<'MK'
.PHONY: custom-hello
custom-hello:
	@echo CUSTOM_HELLO_OK
MK
out="$(make -C "$TMP/c1" custom-hello)"
assert_contains "$out" "CUSTOM_HELLO_OK"

echo "PASS: test_auto_sync.sh (custom include only)"
