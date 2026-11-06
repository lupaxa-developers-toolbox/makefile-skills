#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=/dev/null
source "$(dirname "$0")/harness.sh"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

TREE="$TMP/src"
mkdir -p "$TREE/crates/a" "$TREE/tools/b" "$TREE/vendor/crate" "$TREE/target/debug"
printf '[workspace]\nmembers = ["crates/a"]\n' >"$TREE/Cargo.toml"
printf '[package]\nname = "a"\n' >"$TREE/crates/a/Cargo.toml"
printf '[package]\nname = "b"\n' >"$TREE/tools/b/Cargo.toml"
printf '[package]\nname = "vendored"\n' >"$TREE/vendor/crate/Cargo.toml"
printf '[package]\nname = "built"\n' >"$TREE/target/debug/Cargo.toml"

BIN="$TMP/bin"
mkdir -p "$BIN"
cat >"$BIN/cargo" <<EOF
#!/usr/bin/env bash
set -eu
manifest=""
prev=""
for arg in "\$@"; do
    if [ "\$prev" = "--manifest-path" ]; then
        manifest="\$arg"
    fi
    prev="\$arg"
done
case "\$manifest" in
    "$TREE/tools/b/Cargo.toml") ws="$TREE/tools/b" ;;
    *) ws="$TREE" ;;
esac
printf '%s\n' "{\"workspace_root\":\"\$ws\"}"
EOF
chmod +x "$BIN/cargo"

found="$(CARGO="$BIN/cargo" "$ROOT/skills/rust/workspace-roots" "$TREE")"
printf '%s\n' "$found" | grep -qx "$TREE"
printf '%s\n' "$found" | grep -qx "$TREE/tools/b"
if printf '%s\n' "$found" | grep -q '/crates/a'; then
    echo "FAIL: workspace member was listed as its own root" >&2
    exit 1
fi
if printf '%s\n' "$found" | grep -q '/vendor/'; then
    echo "FAIL: vendor crate was discovered" >&2
    exit 1
fi
count="$(printf '%s\n' "$found" | grep -c .)"
if [ "$count" -ne 2 ]; then
    echo "FAIL: expected 2 workspace roots, got $count" >&2
    printf '%s\n' "$found" >&2
    exit 1
fi

BARE="$TMP/makefiles.git"
makefiles_bare_repo "$BARE"

CONSUMER="$TMP/consumer"
make_consumer "$CONSUMER"
make -C "$CONSUMER" init MAKEFILES_REPO="$BARE"

out="$(make -C "$CONSUMER" help SKILLS=rust)"
assert_contains "$out" "rust-doctor"
assert_contains "$out" "rust-lint"
assert_contains "$out" "rust-test"
assert_contains "$out" "rust-check"
assert_contains "$out" "rust-build"
assert_contains "$out" "rust-clean"
assert_contains "$out" "bump-dev"
assert_not_contains "$out" "go-lint"
assert_not_contains "$out" "c-lint"

out="$(make -C "$CONSUMER" help)"
assert_not_contains "$out" "rust-lint"

dry="$(make -C "$CONSUMER" -n rust-lint SKILLS=rust)"
assert_contains "$dry" "clippy"
assert_contains "$dry" "--workspace"
assert_contains "$dry" "-D warnings"
assert_contains "$dry" "workspace-roots"

dry="$(make -C "$CONSUMER" -n rust-test SKILLS=rust)"
assert_contains "$dry" "test"
assert_contains "$dry" "--workspace"

dry="$(make -C "$CONSUMER" -n rust-build SKILLS=rust)"
assert_contains "$dry" "build"
assert_contains "$dry" "--workspace"

dry="$(make -C "$CONSUMER" -n rust-clean SKILLS=rust)"
assert_contains "$dry" "clean"

make -C "$CONSUMER" -n rust-check SKILLS=rust >/dev/null
make -C "$CONSUMER" -n rust-doctor SKILLS=rust >/dev/null

cat >"$CONSUMER/.bumpversion.toml" <<'EOF'
[tool.bumpversion]
current_version = "0.1.0"
EOF

out="$(make -C "$CONSUMER" status SKILLS=rust)"
assert_contains "$out" "Rust:"

out="$(make -C "$CONSUMER" status)"
assert_not_contains "$out" "Rust:"

echo "PASS: test_rust_skill.sh"
