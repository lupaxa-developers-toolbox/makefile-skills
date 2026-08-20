# Reference

## Lifecycle (wrapper)

<div class="lupaxa-table lupaxa-table--commands" markdown="1">

| Command | Description |
| --- | --- |
| `make init` / `make install` | Sparse-clone `skills/` and `templates/` into `MAKEFILES_DIR` (default `.makefiles`); create `makefiles.config` when missing; quiet `==>` status only |
| `make update` | Fetch and check out `ref`; by default also refresh `./Makefile` from upstream template; quiet `==>` status only |
| `make help` | List lifecycle commands and enabled skill help |
| `make status` | Project / version / Git / skill status (Status help section) |
| `make doctor` | Top-level: lifecycle + `doctor-versioning` + each enabled `*-doctor` |
| `make completion` | Print bash completion snippet for `make` targets |

</div>

## `makefiles.config`

Consumer-editable knobs at the repository root. Syntax: `key = value` with `#`
comments. Created by `make init` when missing; never overwritten by `make update`.
Unknown keys are a hard error.

<div class="lupaxa-table lupaxa-table--config" markdown="1">

| Config key | Make variable | Default | Description |
| --- | --- | --- | --- |
| `skills` | `SKILLS` | _(empty)_ | Optional skills: `python`, `mkdocs`, `bash`, `ruby` (space-separated) |
| `ref` | `MAKEFILES_REF` | `head` | `head` → tip of `master`, or a tag such as `v1.0.0` |
| `transport` | `MAKEFILES_TRANSPORT` | `https` | `ssh`, `https`, or `http` (https default so public consumers need no org SSH) |
| `repo_ssh` | `MAKEFILES_REPO_SSH` | `git@github.com:lupaxa-developers-toolbox/makefile-skills.git` | SSH clone URL |
| `repo_http` | `MAKEFILES_REPO_HTTP` | `https://github.com/lupaxa-developers-toolbox/makefile-skills.git` | HTTPS clone URL |
| `custom_dir` | `MAKEFILES_CUSTOM_DIR` | `.makefiles-custom` | Directory of project `.mk` fragments `-include`d after library skills |
| `update_wrapper` | `MAKEFILES_UPDATE_WRAPPER` | `yes` | When truthy, `make update` overwrites `./Makefile` from upstream template |

</div>

### Precedence

1. Command-line / environment Make overrides (highest)
2. Values from `makefiles.config`
3. Wrapper / built-in defaults

### `update_wrapper`

Default is `yes`: `make update` refreshes skills **and** overwrites `./Makefile`
from `.makefiles/templates/Makefile`. Set to `no` (or `false`, `0`) to update
skills only and keep a hand-edited Makefile.

Accepted truthy values: `yes`, `true`, `1`. Accepted falsey values: `no`,
`false`, `0`.

### Wrapper-only variables

These are not in `makefiles.config`:

<div class="lupaxa-table lupaxa-table--vars-desc" markdown="1">

| Variable | Default | Description |
| --- | --- | --- |
| `MAKEFILES_DIR` | `.makefiles` | Clone location (gitignored in consumers) |
| `MAKEFILES_CONFIG` | `makefiles.config` | Path to the consumer config file |
| `MAKEFILES_REPO` | _(derived)_ | Selected URL from transport + repo URLs; override for one-offs |
| `MAKEFILES_MODE` | `consumer` | Set to `library` for makefile-skills development |

</div>

## Versioning (always on)

<div class="lupaxa-table lupaxa-table--commands" markdown="1">

| Command | Description |
| --- | --- |
| `make version` | Print current version from `.bumpversion.toml` |
| `make show-version-flow` | Valid next bump/release commands for this stage |
| `make bump-patch` | Bump to next stable patch (`X.Y.Z+1`) |
| `make bump-minor` | Bump to next stable minor (`X.Y+1.0`) |
| `make bump-major` | Bump to next stable major (`X+1.0.0`) |
| `make bump-dev` | Alias of `bump-patch-dev` |
| `make bump-patch-dev` | Start or continue patch `-devN` |
| `make bump-minor-dev` | Start or continue minor `-devN` |
| `make bump-major-dev` | Start or continue major `-devN` |
| `make bump-rc` | Alias of `bump-patch-rc` |
| `make bump-patch-rc` | Start patch `-rc1` from stable or `-devN`, or bump `-rcN` |
| `make bump-minor-rc` | Start minor `-rc1` from stable or `-devN`, or bump `-rcN` |
| `make bump-major-rc` | Start major `-rc1` from stable or `-devN`, or bump `-rcN` |
| `make release` | Promote `-rcN` → stable |
| `make bump-final` | Alias of `release` |
| `make draft-tag` | Create next `vX.Y.Z-draftN` git tag at HEAD (does not change `current_version`) |
| `make doctor-versioning` | Check version file, bump tool, git work tree |

</div>

### Versioning variables

<div class="lupaxa-table lupaxa-table--vars" markdown="1">

| Variable | Default |
| --- | --- |
| `VERSION_FILE` | `.bumpversion.toml` |
| `BUMP` | `bump-my-version` |
| `PROJECT_NAME` | directory name |
| `DRAFT_BASE` | _(optional)_ — `X.Y.Z` override for `draft-tag` |

</div>

## Python skill

Enable with `skills = python` in `makefiles.config`.

<div class="lupaxa-table lupaxa-table--commands" markdown="1">

| Command | Description |
| --- | --- |
| `make python-doctor` | Check layout and tools |
| `make python-install-dev` | Editable install with `[dev]` |
| `make python-install-test` | Editable install with `[test]` |
| `make python-lint` | Ruff lint + format check |
| `make python-check-style` | Lint + mypy |
| `make python-format` | Ruff format |
| `make python-type` | mypy |
| `make python-test` | pytest |
| `make python-test-cov` | pytest with coverage |
| `make python-check` | lint + type + test |
| `make python-check-all` | lint + type + coverage + audit |
| `make python-audit` | pip-audit in an isolated venv |
| `make python-build` | Hatch build |
| `make python-publish` | Hatch publish |
| `make python-clean` | Remove Python artefacts |

</div>

### Python variables

<div class="lupaxa-table lupaxa-table--vars" markdown="1">

| Variable | Default |
| --- | --- |
| `SRC_DIR` | `src` |
| `TEST_DIR` | `tests` |
| `PYPROJECT_FILE` | `pyproject.toml` |
| `PIP_INSTALL_DEV` | `-e ".[dev]"` |
| `PIP_INSTALL_TEST` | `-e ".[test]"` |
| `PYTHON_RUFF_PATHS` | `$(SRC_DIR) $(TEST_DIR)` |
| `MYPY_ARGS` | `$(SRC_DIR)` (set empty to use `[tool.mypy] files`) |
| `PYTHON_PACKAGE_DIRS` | empty (`hatch build` at root; set for multi-package) |
| `PYTHON` / `RUFF` / `MYPY` / `PYTEST` / `HATCH` | tool names on `PATH` |

</div>

## MkDocs skill

Enable with `skills = mkdocs` (or include `mkdocs` in `skills`).

<div class="lupaxa-table lupaxa-table--commands" markdown="1">

| Command | Description |
| --- | --- |
| `make mkdocs-doctor` | Check config and `mkdocs` binary |
| `make mkdocs-build` | Build static site |
| `make mkdocs-serve` | Live-reload server |
| `make mkdocs-clean` | Remove `site/` |

</div>

### MkDocs variables

<div class="lupaxa-table lupaxa-table--vars" markdown="1">

| Variable | Default |
| --- | --- |
| `MKDOCS_CONFIG` | `mkdocs.yml` |
| `MKDOCS_HOST` | `127.0.0.1` |
| `MKDOCS_PORT` | `8000` |
| `MKDOCS` | `mkdocs` |

</div>

## Bash skill

Enable with `skills = bash` in `makefiles.config`.

<div class="lupaxa-table lupaxa-table--commands" markdown="1">

| Command | Description |
| --- | --- |
| `make bash-doctor` | Check discovery helper and tools |
| `make bash-list-scripts` | List discovered scripts |
| `make bash-syntax` | `bash -n` on each script |
| `make bash-shellcheck` | ShellCheck analysis |
| `make bash-lint` | Alias of `bash-shellcheck` |
| `make bash-test` / `make bash-check` | syntax + ShellCheck |

</div>

### Bash variables

<div class="lupaxa-table lupaxa-table--vars" markdown="1">

| Variable | Default |
| --- | --- |
| `SHELL_SOURCE_DIR` | `.` |
| `SHELL_FILE_FINDER` | `$(MAKEFILES_DIR)/skills/bash/find-shell-files` |
| `SHELL_FILES` | auto-discovered |
| `SHELLCHECK_SHELL` | `bash` |
| `BASH` / `SHELLCHECK` | tool names on `PATH` |

</div>

## Ruby skill

Enable with `skills = ruby` in `makefiles.config`.

<div class="lupaxa-table lupaxa-table--commands" markdown="1">

| Command | Description |
| --- | --- |
| `make ruby-doctor` | Check Ruby tools and project layout |
| `make ruby-bundle` | Install dependencies from `Gemfile` |
| `make ruby-lint` | Run RuboCop |
| `make ruby-format` | RuboCop unsafe autocorrect (`-A`; all correctable offences) |
| `make ruby-check-diff` | Show correctable RuboCop offences |
| `make ruby-test` | Run `rake test` |
| `make ruby-check` | Run lint and tests |
| `make ruby-check-all` | Alias of `ruby-check` |
| `make ruby-build` | Build the project gem |
| `make ruby-publish` | Build and publish the project gem |
| `make ruby-clean` | Remove Ruby build and test artefacts |

</div>

When a `Gemfile` is present, lint, format, check-diff, test, and check
targets run via `bundle exec` (`RUBY_RUN`). `ruby-format` invokes RuboCop
with `-A` (unsafe autocorrect — the full correctable set, not safe-only `-a`).
`ruby-build` and `ruby-publish` call `gem build` and `gem push` directly —
they are not wrapped in Bundler.

### Ruby variables

<div class="lupaxa-table lupaxa-table--vars" markdown="1">

| Variable | Default |
| --- | --- |
| `RUBY` | `ruby` |
| `BUNDLE` | `bundle` |
| `RUBOCOP` | `rubocop` |
| `RAKE` | `rake` |
| `GEM` | `gem` |
| `GEMFILE` | `Gemfile` |
| `GEMSPEC` | _(empty — auto-detect single `*.gemspec`)_ |
| `SRC_DIR` | `lib` |
| `TEST_DIR` | `test` |
| `RUBY_RUN` | `bundle exec` when `Gemfile` exists; otherwise empty |
| `RUBOCOP_ARGS` | _(empty)_ |

</div>

## Repository layout (this library)

```text
templates/Makefile              Canonical consumer wrapper (refreshable)
templates/makefiles.config      Starter consumer config (copied on init)
examples/                       Example wrappers and matching configs
skills/                         Skill fragments (.mk) and bash helper
skills/_template.language.mk    Starter for a new language skill (copy → rename)
scripts/validate-makefiles.sh   Local checkmake run (same as CI validate-makefiles)
scripts/validate-shell.sh       Local shellcheck run (same as CI shell-script-linter)
mkdocs/                         Documentation source (this site)
mkdocs.yml                      MkDocs configuration
docs/                           Community standards (conduct, contributing, …)
LICENCE                         MIT licence
tests/                          Shell integration tests
overrides/                      Material theme overrides
```

Library maintainers: `make validate-makefiles` and `make validate-shell` run
the CI linters; `bash tests/run_all.sh` runs the integration suite.

## Adding a language skill

Copy [`skills/_template.language.mk`](https://github.com/lupaxa-developers-toolbox/makefile-skills/blob/master/skills/_template.language.mk)
to `skills/<id>.mk` (for example `go.mk`), replace `lang` / `Lang`, implement the stub
targets, then enable with `skills = go` in `makefiles.config`. See the checklist in the template header.

## Migration from an older wrapper

1. Copy knob values from the Makefile into `makefiles.config`.
2. Run `make update` to refresh the wrapper (default), or set
   `update_wrapper = no` until ready.
3. Remove knob lines from the Makefile so config is the single durable source.

An old wrapper without config continues to work until refreshed.
