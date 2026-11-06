#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=/dev/null
source "$(dirname "$0")/harness.sh"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

TREE="$TMP/src"
mkdir -p "$TREE/nested" "$TREE/vendor/github.com/x" "$TREE/.git" "$TREE/.makefiles"
printf 'module example.com\n' >"$TREE/go.mod"
printf 'module example.com/nested\n' >"$TREE/nested/go.mod"
printf 'module example.com/vendor\n' >"$TREE/vendor/go.mod"
printf 'module hidden\n' >"$TREE/.git/go.mod"
printf 'module hidden\n' >"$TREE/.makefiles/go.mod"

found="$("$ROOT/skills/go/module-dirs" "$TREE")"
printf '%s\n' "$found" | grep -qx "$TREE"
printf '%s\n' "$found" | grep -qx "$TREE/nested"
if printf '%s\n' "$found" | grep -q '/vendor/'; then
    echo "FAIL: vendor module was discovered" >&2
    exit 1
fi
if printf '%s\n' "$found" | grep -q '/.git'; then
    echo "FAIL: .git module was discovered" >&2
    exit 1
fi

BARE="$TMP/makefiles.git"
makefiles_bare_repo "$BARE"

CONSUMER="$TMP/consumer"
make_consumer "$CONSUMER"
make -C "$CONSUMER" init MAKEFILES_REPO="$BARE"

out="$(make -C "$CONSUMER" help SKILLS=go)"
assert_contains "$out" "go-doctor"
assert_contains "$out" "go-lint"
assert_contains "$out" "go-test"
assert_contains "$out" "go-check"
assert_contains "$out" "go-build"
assert_contains "$out" "go-clean"
assert_contains "$out" "bump-dev"
assert_not_contains "$out" "rust-lint"
assert_not_contains "$out" "c-lint"

out="$(make -C "$CONSUMER" help)"
assert_not_contains "$out" "go-lint"

for target in go-doctor go-lint go-test go-check go-build go-clean; do
    dry="$(make -C "$CONSUMER" -n "$target" SKILLS=go)"
    case "$target" in
        go-doctor) ;;
        *)
            assert_contains "$dry" "go"
            assert_contains "$dry" "./..."
            ;;
    esac
done

cat >"$CONSUMER/.bumpversion.toml" <<'EOF'
[tool.bumpversion]
current_version = "0.1.0"
EOF

out="$(make -C "$CONSUMER" status SKILLS=go)"
assert_contains "$out" "Go:"

out="$(make -C "$CONSUMER" status)"
assert_not_contains "$out" "Go:"

echo "PASS: test_go_skill.sh"
