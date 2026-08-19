# Usage

## Diagnose the environment

```bash
make doctor
```

`make doctor` is the top-level check: lifecycle (clone/transport), then
`doctor-versioning`, then each enabled skill doctor (`python-doctor`,
`mkdocs-doctor`, `bash-doctor`, `ruby-doctor`, …). Every section runs even if an earlier one
fails; the command exits non-zero only after the full report if any section
had issues. You can still run any skill doctor on its own (those fail fast).

```bash
make status
```

`make status` and `make doctor` appear under the **Status** help section
(always listed, above Versioning). Status is informational (project, version
stage, Git, enabled skills) and does not fail on missing tools.

`make help` (and the default `make` target) colours section headers in cyan
on interactive terminals. Status and doctor also use colour: green `[OK]`,
yellow `[WARN]`, red missing/error tags, and cyan section headings.
`make version` / `make show-version-flow` use cyan labels; bump/release/
draft-tag success lines are green and `ERROR:` messages are red. Colour is
skipped when output is not a TTY. Set `NO_COLOR=1` to force plain text, or
set `FORCE_COLOR` to a truthy value such as `1` to force colour (for example
when piping); `0`, `false`, and `no` do not force it. `NO_COLOR` wins if both
are set.

## Shell completion

After `make init`, enable bash target completion:

```bash
eval "$(make -s completion)"
# or permanently in ~/.bashrc:
# source /path/to/project/.makefiles/skills/completion/bash
```

## Configuration (`makefiles.config`)

Consumer-editable knobs live in `makefiles.config` at the repository root.
Syntax is `key = value` with `#` comments. `make init` creates the starter
file when missing; `make update` never overwrites it.

Precedence (highest wins):

1. Command-line / environment Make overrides (e.g. `make status SKILLS=bash`)
2. Values from `makefiles.config`
3. Wrapper / built-in defaults

Example:

```ini
skills = python mkdocs
transport = https
ref = head
update_wrapper = yes
```

Set `update_wrapper = no` to skip refreshing `./Makefile` on `make update`
while still updating skills. Accepted values include `yes`/`no`, `true`/`false`,
and `1`/`0`.

## Versioning

Versioning is always on. Versions live in `.bumpversion.toml` and are applied
with `bump-my-version`.

### Direct stable bumps

```make
make bump-patch    # 1.2.3 → 1.2.4
make bump-minor    # 1.2.3 → 1.3.0
make bump-major    # 1.2.3 → 2.0.0
```

When `current_version` is stable, the last stable git tag (`vX.Y.Z` only;
`-dev`, `-rc`, and `-draft` tags are ignored) must match it. Hand-made tags
ahead of the file abort the bump. Set `current_version` to that tag, or
delete the extra tag, then retry. Repos with no stable tag yet are fine.

### Optional pre-release cycles

Start `-dev` and/or `-rc` when you want them — neither is required for a
stable bump, and `-rc` does not require `-dev` first:

```make
make bump-dev      # 1.2.3 → 1.2.4-dev1  (alias: bump-patch-dev)
make bump-rc       # 1.2.3 → 1.2.4-rc1   (alias: bump-patch-rc; also from -devN)
make release       # 1.2.4-rc1 → 1.2.4
```

Minor/major flavours: `bump-minor-dev` / `bump-major-dev` and
`bump-minor-rc` / `bump-major-rc`. While a `-devN` or `-rcN` cycle is open,
only the matching channel may continue (strict channel).

`-devN` versions are for local / in-repo WIP. They do **not** trigger a GitHub
release workflow (unlike `-rcN` → test/prerelease release).

### Draft GitHub tags (outside the version flow)

`make draft-tag` creates the next `vX.Y.Z-draftN` annotated tag at `HEAD`
without changing `.bumpversion.toml`. That tag triggers
`generate-draft-release.yml`. Override the base with `DRAFT_BASE=1.2.4` if
needed. Push the tag yourself (`git push origin vX.Y.Z-draftN`).

See valid next **version** steps for the current stage:

```bash
make show-version-flow
```

## Python skill

Enable with `skills = python` in `makefiles.config`.

Common loop:

```bash
make python-install-dev
make python-lint
make python-type
make python-test
make python-check          # lint + type + test
make python-build
```

Language targets are prefixed (`python-lint`, not `lint`) so they do not clash
with other skills.

## MkDocs skill

Enable with `skills = python mkdocs` (or `skills = mkdocs` alone).

```bash
make mkdocs-build
make mkdocs-serve
make mkdocs-serve MKDOCS_PORT=8001
make mkdocs-clean
```

Serve defaults to `127.0.0.1:8000`. Override `MKDOCS_PORT` / `MKDOCS_HOST` when
running several sites at once.

This repository’s own docs live under `mkdocs/` with `mkdocs.yml` at the repo
root (Material theme from the Lupaxa technical documentation template).

## Bash skill

Enable with `skills = bash` in `makefiles.config`.

```bash
make bash-list-scripts
make bash-syntax
make bash-shellcheck
make bash-check
```

Discovery finds `.sh` / `.bash` files, shebang lines, and scripts identified by
`file(1)` (including extensionless commands). The skills clone (`.makefiles/`)
is excluded.

If nothing is found:

```bash
make bash-list-scripts SHELL_SOURCE_DIR=bin
# or
make bash-list-scripts SHELL_FILES="bin/tool scripts/install.sh"
```

## Ruby skill

Enable with `skills = ruby` in `makefiles.config`.

Common loop:

```bash
make ruby-bundle
make ruby-lint
make ruby-format
make ruby-test
make ruby-check          # lint + test
make ruby-build
```

When a `Gemfile` is present, RuboCop and `rake test` run through
`bundle exec`. `ruby-build` and `ruby-publish` use `gem` directly (not
bundled). Set `GEMSPEC=` when the repo has multiple `*.gemspec` files.

## Switching SSH and HTTPS

Default `transport` is **`https`**, so consumers outside the organisation can
clone without GitHub SSH access. Org members with deploy keys can switch to
SSH in `makefiles.config`:

```ini
transport = https   # default — or ssh | http
```

`repo_ssh` and `repo_http` hold the two URLs. `transport` selects which one
`make init` / `make update` use. Override `MAKEFILES_REPO` on the command line
only for one-offs (for example a local path).

## Skills sync and wrapper refresh

`make init` clones skills into `.makefiles/` and creates `makefiles.config`
when missing. `make update` fetches and checks out `ref` again (hard fail on
network/ref errors) and, by default, refreshes `./Makefile` from the upstream
template. Set `update_wrapper = no` to update skills only. Ordinary targets
such as `make`, `make help`, and `make status` do **not** contact the remote.

Lifecycle output for `init` / `update` is intentionally quiet: only `==>`
status lines (cyan when colour is enabled). Git pack/progress chatter is
suppressed; failures still surface git's error text.

## Custom skill fragments

Drop `.mk` files into `.makefiles-custom/` (or set `custom_dir` in config).
They are `-include`d after library skills, so you can add prefixed targets or
override behaviour for this repo only. Commit `.makefiles-custom/`; do not add
it to `.gitignore`.
