#!/usr/bin/env bash
# Run the same makefile-lint pipeline as .github/workflows/validate-makefiles.yml.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

PIPELINE=""
for candidate in \
  "${LUPAXA_CICD_TOOLBOX:-$HOME/Desktop/GitMaster/Lupaxa/CICDToolbox}/makefile-lint/src/pipeline.sh" \
  "$HOME/Desktop/GitMaster/Lupaxa/CICDToolbox/makefile-lint/src/pipeline.sh"
do
  if [[ -f "$candidate" ]]; then
    PIPELINE="$candidate"
    break
  fi
done

# Workflow exclude_files plus local scanner excludes.
EXCLUDE_FILES="${EXCLUDE_FILES:-^site/|^mkdocs/|^\\.makefiles/|^\\.venv/|^venv/|^cursor-docs/|\\.egg-info/|^\\.superpowers/|^\\.cursor/}"
export EXCLUDE_FILES
export NO_COLOR="${NO_COLOR:-1}"

if [[ -n "$PIPELINE" ]]; then
  exec bash "$PIPELINE"
fi

exec bash <(curl -fsSL https://raw.githubusercontent.com/lupaxa-cicd-toolbox/makefile-lint/master/src/pipeline.sh)
