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

out="$(make -C "$CONSUMER" help SKILLS=ruby)"
assert_contains "$out" "ruby-lint"
assert_contains "$out" "ruby-test"
assert_contains "$out" "ruby-check"
assert_contains "$out" "bump-dev"
assert_not_contains "$out" "python-lint"
assert_not_contains "$out" "bash-shellcheck"

out="$(make -C "$CONSUMER" help)"
assert_not_contains "$out" "ruby-lint"

make -C "$CONSUMER" -n ruby-lint SKILLS=ruby >/dev/null
make -C "$CONSUMER" -n ruby-test SKILLS=ruby >/dev/null

cat > "$CONSUMER/.bumpversion.toml" <<'EOF'
[tool.bumpversion]
current_version = "0.1.0"
EOF

out="$(make -C "$CONSUMER" status SKILLS=ruby)"
assert_contains "$out" "Ruby:"

out="$(make -C "$CONSUMER" status)"
assert_not_contains "$out" "Ruby:"

# Hybrid: no Gemfile → dry-run must not mention bundle exec
rm -f "$CONSUMER/Gemfile"
out="$(make -C "$CONSUMER" -n ruby-lint SKILLS=ruby)"
assert_not_contains "$out" "bundle exec"

# Hybrid: Gemfile present → dry-run includes bundle exec
touch "$CONSUMER/Gemfile"
out="$(make -C "$CONSUMER" -n ruby-lint SKILLS=ruby)"
assert_contains "$out" "bundle exec"

out="$(make -C "$CONSUMER" -n ruby-test SKILLS=ruby)"
assert_contains "$out" "bundle exec"
assert_contains "$out" "rake test"

echo "PASS: test_ruby_skill.sh"
