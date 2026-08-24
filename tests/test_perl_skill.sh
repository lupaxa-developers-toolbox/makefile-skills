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

out="$(make -C "$CONSUMER" help SKILLS=perl)"
assert_contains "$out" "perl-lint"
assert_contains "$out" "perl-syntax"
assert_contains "$out" "perl-critic"
assert_contains "$out" "perl-check"
assert_contains "$out" "bump-dev"
assert_not_contains "$out" "php-lint"
assert_not_contains "$out" "python-lint"

out="$(make -C "$CONSUMER" help)"
assert_not_contains "$out" "perl-lint"

make -C "$CONSUMER" -n perl-lint SKILLS=perl >/dev/null
make -C "$CONSUMER" -n perl-syntax SKILLS=perl >/dev/null
make -C "$CONSUMER" -n perl-critic SKILLS=perl >/dev/null

cat > "$CONSUMER/.bumpversion.toml" <<'EOF'
[tool.bumpversion]
current_version = "0.1.0"
EOF

out="$(make -C "$CONSUMER" status SKILLS=perl)"
assert_contains "$out" "Perl:"

out="$(make -C "$CONSUMER" status)"
assert_not_contains "$out" "Perl:"

echo "PASS: test_perl_skill.sh"
