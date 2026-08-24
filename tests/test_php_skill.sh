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

out="$(make -C "$CONSUMER" help SKILLS=php)"
assert_contains "$out" "php-lint"
assert_contains "$out" "php-syntax"
assert_contains "$out" "php-cs"
assert_contains "$out" "php-stan"
assert_contains "$out" "php-check"
assert_contains "$out" "bump-dev"
assert_not_contains "$out" "perl-lint"
assert_not_contains "$out" "python-lint"

out="$(make -C "$CONSUMER" help)"
assert_not_contains "$out" "php-lint"

make -C "$CONSUMER" -n php-lint SKILLS=php >/dev/null
make -C "$CONSUMER" -n php-syntax SKILLS=php >/dev/null
make -C "$CONSUMER" -n php-cs SKILLS=php >/dev/null
make -C "$CONSUMER" -n php-stan SKILLS=php >/dev/null

cat > "$CONSUMER/.bumpversion.toml" <<'EOF'
[tool.bumpversion]
current_version = "0.1.0"
EOF

out="$(make -C "$CONSUMER" status SKILLS=php)"
assert_contains "$out" "PHP:"

out="$(make -C "$CONSUMER" status)"
assert_not_contains "$out" "PHP:"

echo "PASS: test_php_skill.sh"
