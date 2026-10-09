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

out="$(make -C "$CONSUMER" help SKILLS=javascript)"
assert_contains "$out" "javascript-lint"
assert_contains "$out" "javascript-syntax"
assert_contains "$out" "javascript-analyze"
assert_contains "$out" "javascript-check"
assert_contains "$out" "bump-dev"
assert_not_contains "$out" "powershell-lint"
assert_not_contains "$out" "perl-lint"

out="$(make -C "$CONSUMER" help)"
assert_not_contains "$out" "javascript-lint"

make -C "$CONSUMER" -n javascript-lint SKILLS=javascript >/dev/null
make -C "$CONSUMER" -n javascript-syntax SKILLS=javascript >/dev/null
make -C "$CONSUMER" -n javascript-analyze SKILLS=javascript >/dev/null
make -C "$CONSUMER" -n javascript-check SKILLS=javascript >/dev/null

cat > "$CONSUMER/.bumpversion.toml" <<'EOF'
[tool.bumpversion]
current_version = "0.1.0"
EOF

out="$(make -C "$CONSUMER" status SKILLS=javascript)"
assert_contains "$out" "JavaScript:"

out="$(make -C "$CONSUMER" status)"
assert_not_contains "$out" "JavaScript:"

echo "PASS: test_javascript_skill.sh"
