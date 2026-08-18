#!/usr/bin/env bash
# Run the same shellcheck pipeline as .github/workflows/shell-script-linter.yml.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

PIPELINE=""
for candidate in \
  "${LUPAXA_CICD_TOOLBOX:-$HOME/Desktop/GitMaster/Lupaxa/CICDToolbox}/shellcheck/src/pipeline.sh" \
  "$HOME/Desktop/GitMaster/Lupaxa/CICDToolbox/shellcheck/src/pipeline.sh"
do
  if [[ -f "$candidate" ]]; then
    PIPELINE="$candidate"
    break
  fi
done

EXCLUDE_FILES="${EXCLUDE_FILES:-^site/|^mkdocs/|^\\.makefiles/|^\\.venv/|^venv/|^cursor-docs/|\\.egg-info/|^\\.superpowers/|^\\.cursor/}"
export EXCLUDE_FILES
export NO_COLOR="${NO_COLOR:-1}"

if [[ -n "$PIPELINE" ]]; then
  exec bash "$PIPELINE"
fi

exec bash <(curl -fsSL https://raw.githubusercontent.com/lupaxa-cicd-toolbox/shellcheck/master/src/pipeline.sh)
