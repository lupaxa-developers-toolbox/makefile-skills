#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=/dev/null
source "$(dirname "$0")/harness.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

BARE="$TMP/makefiles.git"
makefiles_bare_repo "$BARE"

CONSUMER="$TMP/consumer"
make_consumer "$CONSUMER"
make -C "$CONSUMER" init MAKEFILES_REPO="$BARE"

out="$(make -C "$CONSUMER" help SKILLS=c)"
assert_contains "$out" "c-lint"
assert_contains "$out" "c-syntax"
assert_contains "$out" "c-analyze"
assert_contains "$out" "c-check"
assert_contains "$out" "bump-dev"
assert_not_contains "$out" "javascript-lint"
assert_not_contains "$out" "perl-lint"

out="$(make -C "$CONSUMER" help)"
assert_not_contains "$out" "c-lint"

make -C "$CONSUMER" -n c-lint SKILLS=c >/dev/null
make -C "$CONSUMER" -n c-syntax SKILLS=c >/dev/null
make -C "$CONSUMER" -n c-analyze SKILLS=c >/dev/null
make -C "$CONSUMER" -n c-check SKILLS=c >/dev/null

cat > "$CONSUMER/.bumpversion.toml" <<'EOF'
[tool.bumpversion]
current_version = "0.1.0"
EOF

out="$(make -C "$CONSUMER" status SKILLS=c)"
assert_contains "$out" "C:"

out="$(make -C "$CONSUMER" status)"
assert_not_contains "$out" "C:"

echo "PASS: test_c_skill.sh"
