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

out="$(make -C "$CONSUMER" help SKILLS=powershell)"
assert_contains "$out" "powershell-lint"
assert_contains "$out" "powershell-syntax"
assert_contains "$out" "powershell-analyze"
assert_contains "$out" "powershell-check"
assert_contains "$out" "bump-dev"
assert_not_contains "$out" "perl-lint"
assert_not_contains "$out" "php-lint"

out="$(make -C "$CONSUMER" help)"
assert_not_contains "$out" "powershell-lint"

make -C "$CONSUMER" -n powershell-lint SKILLS=powershell >/dev/null
make -C "$CONSUMER" -n powershell-syntax SKILLS=powershell >/dev/null
make -C "$CONSUMER" -n powershell-analyze SKILLS=powershell >/dev/null
make -C "$CONSUMER" -n powershell-check SKILLS=powershell >/dev/null

cat > "$CONSUMER/.bumpversion.toml" <<'EOF'
[tool.bumpversion]
current_version = "0.1.0"
EOF

out="$(make -C "$CONSUMER" status SKILLS=powershell)"
assert_contains "$out" "PowerShell:"

out="$(make -C "$CONSUMER" status)"
assert_not_contains "$out" "PowerShell:"

echo "PASS: test_powershell_skill.sh"
