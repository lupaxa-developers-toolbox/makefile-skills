#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="$REPO_ROOT/templates/Makefile"
CONFIG_TEMPLATE="$REPO_ROOT/templates/makefiles.config"
PYTHON_EXAMPLE="$REPO_ROOT/examples/Makefile.python"
EXAMPLES_DIR="$REPO_ROOT/examples"

# Canonical CI overlay appended to python example Makefiles (see examples/Makefile.python).
PYTHON_CI_OVERLAY="$(awk '/^# CI-friendly aliases/ { found=1 } found { print }' "$PYTHON_EXAMPLE")"

strip_python_overlay() {
  local template_lines
  template_lines=$(wc -l < "$TEMPLATE" | tr -d ' ')
  head -n "$template_lines" "$1"
}

extract_python_overlay() {
  awk '/^# CI-friendly aliases/ { found=1 } found { print }' "$1"
}

assert_identical_to_template() {
  local name="$1"
  local example="$2"

  if ! diff -q "$TEMPLATE" "$example" >/dev/null; then
    echo "ASSERT: $name is expected to be identical to templates/Makefile" >&2
    diff -u "$TEMPLATE" "$example" >&2 || true
    exit 1
  fi
}

assert_python_example_drift() {
  local name="$1"
  local example="$2"

  prefix="$(strip_python_overlay "$example")"
  overlay="$(extract_python_overlay "$example")"

  if [ "$overlay" != "$PYTHON_CI_OVERLAY" ]; then
    echo "ASSERT: $name CI overlay block does not match examples/Makefile.python:" >&2
    diff -u <(printf '%s\n' "$PYTHON_CI_OVERLAY") <(printf '%s\n' "$overlay") >&2 || true
    exit 1
  fi

  tmp="$(mktemp)"
  printf '%s\n' "$prefix" >"$tmp"
  assert_identical_to_template "$name (excluding CI overlay)" "$tmp"
  rm -f "$tmp"
}

assert_config_skills() {
  local name="$1"
  local config="$2"
  local expected_skills="$3"
  local expected_update_wrapper="${4:-yes}"

  if [ ! -f "$config" ]; then
    echo "ASSERT: missing example config $name ($config)" >&2
    exit 1
  fi

  skills_line="$(grep -E '^skills[[:space:]]*=' "$config" || true)"
  if [ -z "$skills_line" ]; then
    echo "ASSERT: $name must contain a skills = line" >&2
    exit 1
  fi
  actual_skills="$(printf '%s' "$skills_line" | sed -E 's/^skills[[:space:]]*=[[:space:]]*//')"
  if [ "$actual_skills" != "$expected_skills" ]; then
    echo "ASSERT: $name skills must be '${expected_skills}' (got '${actual_skills}')" >&2
    exit 1
  fi

  if ! grep -qE "^update_wrapper = ${expected_update_wrapper}$" "$config"; then
    echo "ASSERT: $name must contain 'update_wrapper = ${expected_update_wrapper}'" >&2
    exit 1
  fi
}

for example in "$EXAMPLES_DIR"/Makefile.*; do
  name="$(basename "$example")"

  case "$name" in
    Makefile.python|Makefile.python-docs)
      assert_python_example_drift "$name" "$example"
      ;;
    *)
      assert_identical_to_template "$name" "$example"
      ;;
  esac
done

assert_config_skills "makefiles.config.versioning-only" \
  "$EXAMPLES_DIR/makefiles.config.versioning-only" ""

assert_config_skills "makefiles.config.bash-project" \
  "$EXAMPLES_DIR/makefiles.config.bash-project" "bash"

assert_config_skills "makefiles.config.python" \
  "$EXAMPLES_DIR/makefiles.config.python" "python" "no"

assert_config_skills "makefiles.config.python-docs" \
  "$EXAMPLES_DIR/makefiles.config.python-docs" "python mkdocs" "no"

# Example configs should match the starter template except for allowed drift.
for config in "$EXAMPLES_DIR"/makefiles.config.*; do
  cfg_name="$(basename "$config")"
  diff_out="$(diff "$CONFIG_TEMPLATE" "$config" || true)"
  if [ -n "$diff_out" ]; then
    case "$cfg_name" in
      makefiles.config.python|makefiles.config.python-docs)
        non_allowed_diff="$(
          echo "$diff_out" \
            | grep -v -- '^[<>-]*[<>] skills ' \
            | grep -v -- '^[<>-]*[<>] update_wrapper ' \
            | grep -v -- 'CI overlay in Makefile.python' \
            | grep -E '^[<>]' || true
        )"
        ;;
      *)
        non_allowed_diff="$(echo "$diff_out" | grep -v -- '^[<>-]*[<>] skills ' | grep -E '^[<>]' || true)"
        ;;
    esac
    if [ -n "$non_allowed_diff" ]; then
      echo "ASSERT: $cfg_name has drifted from templates/makefiles.config beyond allowed lines:" >&2
      echo "$diff_out" >&2
      exit 1
    fi
  fi
done

echo "PASS: test_examples_drift.sh"
