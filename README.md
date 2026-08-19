<p align="center">
    <a href="https://github.com/lupaxa-developers-toolbox">
        <img src="https://raw.githubusercontent.com/the-lupaxa-project/brand-assets/master/logos/organisations/developers-toolbox/readme-logo.png" alt="Organisation Logo" />
    </a>
</p>

<h1 align="center">Makefile Skills</h1>

Reusable Makefile skills for project versioning, Python, MkDocs, Bash, and Ruby
workflows.

## Adopt the wrapper

1. Copy [`templates/Makefile`](templates/Makefile) to your project root as
   `Makefile`.
2. Add `.makefiles/` to the project's `.gitignore`. Commit the wrapper and
   `.gitignore`, but not the cloned skills library.
3. Run `make init`. This sparse-clones the library into `.makefiles/` (only
   `skills/` and `templates/` — not this repo's MkDocs site, tests, or
   examples) and creates `makefiles.config` from the starter template when the
   file is missing.
4. Edit `makefiles.config` for your project — for example:

   ```ini
   skills = python mkdocs
   transport = https
   ref = head
   ```

   Versioning is always available. Optional skills are `python`, `mkdocs`,
   `bash`, and `ruby`. To add another language, copy
   [`skills/_template.language.mk`](skills/_template.language.mk) to
   `skills/<id>.mk` and follow the checklist in that file.

   **Important:** if `make init` still materialises `mkdocs/`, `examples/`, etc.,
   replace your `Makefile` from [`templates/Makefile`](templates/Makefile),
   then `rm -rf .makefiles && make init`.

5. Run `make help` and `make doctor`.

Use `make doctor` to verify tools, the skills clone, and skill-specific
configuration before you start day-to-day work. `status` and `doctor` appear
under the **Status** section in `make help`.

Enable bash completion for make targets:

```bash
eval "$(make -s completion)"
```

Use `make update` to fetch the selected revision again. By default it also
refreshes `./Makefile` from the upstream template (see `update_wrapper` in
`makefiles.config`). Lifecycle status for `init` / `update` is quiet: only
cyan `==>` lines (git clone/fetch chatter is suppressed; set `NO_COLOR=1` for
plain text).

## Configuration

Consumer-editable knobs live in `makefiles.config` at the repository root
(`key = value` syntax, `#` comments). `make update` never overwrites this file.

| Config key | Make variable | Default |
| --- | --- | --- |
| `skills` | `SKILLS` | _(empty)_ |
| `ref` | `MAKEFILES_REF` | `head` |
| `transport` | `MAKEFILES_TRANSPORT` | `https` (works without org SSH) |
| `repo_ssh` | `MAKEFILES_REPO_SSH` | Lupaxa developers-toolbox SSH URL |
| `repo_http` | `MAKEFILES_REPO_HTTP` | Lupaxa developers-toolbox HTTPS URL |
| `custom_dir` | `MAKEFILES_CUSTOM_DIR` | `.makefiles-custom` |
| `update_wrapper` | `MAKEFILES_UPDATE_WRAPPER` | `yes` |

Precedence (highest wins): command-line / environment Make overrides →
`makefiles.config` → wrapper defaults.

Set `update_wrapper = no` to skip refreshing `./Makefile` on `make update`
(skills still update). Accepted truthy/falsey values include `yes`/`no`,
`true`/`false`, and `1`/`0`.

## Pin the library version

`ref = head` checks out the library's `master` branch. To pin consumers after
a library release is tagged, set `ref` to that tag in `makefiles.config`:

```ini
ref = v1.0.0
```

Create tags such as `v1.0.0` in the library when you are ready to publish a
stable pin; consumers can continue using the default `head` until then.

## Migrating from an older wrapper

If your Makefile still sets `SKILLS ?=`, transport URLs, or other knobs
inline:

1. Copy those values into `makefiles.config` (or run `make init` to create a
   starter file, then edit it).
2. Run `make update` to refresh `./Makefile` from the upstream template
   (default), or set `update_wrapper = no` until you are ready.
3. Remove the old knob lines from your Makefile so `makefiles.config` is the
   single durable source.

An old wrapper without config continues to work until refreshed; Make/CLI
overrides still win.

## Skills and commands

`versioning` is always enabled and provides direct stable bumps
(`make bump-patch`, `make bump-minor`, `make bump-major`) plus optional
`-dev` / `-rc` pre-releases (`make bump-dev`, `make bump-rc`, `make release`,
and channel-specific `bump-*-dev` / `bump-*-rc`). You can jump straight to
`-rc1` from stable; `-dev` is not required. `-devN` does not create a GitHub
release; `-rcN` tags feed the test/prerelease workflow. For GitHub **draft**
releases (attach assets before publish), use `make draft-tag` — it only
creates a `vX.Y.Z-draftN` git tag and does not change `current_version`.
See `make help` or `make show-version-flow` for version next steps.

Enable `python` for prefixed commands such as `make python-lint`,
`make python-type`, `make python-test`, `make python-check`, and
`make python-build`.

Enable `mkdocs` for `make mkdocs-build`, `make mkdocs-serve`, and
`make mkdocs-clean`. Serve defaults to `127.0.0.1:8000`; override per run:

```bash
make mkdocs-serve MKDOCS_PORT=8001
make mkdocs-serve MKDOCS_PORT=8002
```

Enable `bash` for `make bash-list-scripts`, `make bash-syntax`,
`make bash-shellcheck`, and `make bash-check`.

Enable `ruby` for `make ruby-bundle`, `make ruby-lint`, `make ruby-format`,
`make ruby-test`, `make ruby-check`, and `make ruby-build`. When a `Gemfile`
is present, lint, format, check-diff, test, and check run via `bundle exec`
(`RUBY_RUN`); `ruby-format` uses RuboCop `-A` (unsafe autocorrect). `gem
build` / `gem push` are not bundled.

Run `make help` in a consumer project to see only the versioning commands and
the optional skills selected in `makefiles.config`.

## Documentation site

Project docs use MkDocs Material (Lupaxa technical documentation template):

```bash
python -m pip install -r requirements.txt
make mkdocs-serve   # requires skills including mkdocs, or: python -m mkdocs serve
```

Source lives in `mkdocs/`; config is `mkdocs.yml` at the repository root.

## Developing this library

Contributors working in **this** repository (not consumer projects) can run
the same Makefile lint CI uses:

```bash
make validate-makefiles
make validate-shell
# or: bash scripts/validate-makefiles.sh / scripts/validate-shell.sh
```

Also run the integration suite before release:

```bash
bash tests/run_all.sh
```

<a href="https://github.com/the-lupaxa-project">
    <img src="https://raw.githubusercontent.com/the-lupaxa-project/brand-assets/master/logos/components/footer-for-child-orgs.svg" alt="The Lupaxa Project Footer" width="100%" />
</a>
