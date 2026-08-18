# Getting started

## Requirements

- GNU Make
- Git
- Network access to clone this library (SSH or HTTPS)
- Skill-specific tools as needed (`bump-my-version`, Python toolchain, MkDocs,
  ShellCheck, …) — use `make doctor` after init to verify

## Adopt the wrapper

1. Copy [`templates/Makefile`](https://github.com/lupaxa-developers-toolbox/makefile-skills/blob/master/templates/Makefile)
   to your project root as `Makefile`.
2. Add `.makefiles/` to the project's `.gitignore`. Commit the wrapper and
   `.gitignore`, not the cloned skills library.
3. Initialise:

   ```bash
   make init
   ```

   This sparse-clones `skills/` and `templates/` into `.makefiles/` (docs,
   tests, and examples stay out of the clone) and creates `makefiles.config`
   from the starter template when the file is missing.
4. Edit `makefiles.config` for your project:

   ```ini
   skills = python mkdocs
   transport = https
   ref = head
   ```

   Versioning is always available. Optional skills are `python`, `mkdocs`, and
   `bash`.

5. Inspect:

   ```bash
   make help
   make doctor
   ```

## First commands

```bash
make status
make version
make show-version-flow
```

## Pin the library version

`ref = head` tracks the tip of `master`. To pin a release tag in
`makefiles.config`:

```ini
ref = v1.0.0
```

Then run `make update` (or `make init` on a fresh clone).

## Refresh skills and wrapper

```bash
make update
```

This fetches and checks out `ref` again inside `.makefiles/`. By default it
also overwrites `./Makefile` from the upstream template at that ref.
`makefiles.config` is never modified. Set `update_wrapper = no` in config to
update skills only.

`make init` and `make update` print quiet cyan `==>` status lines only (git
clone/fetch progress is suppressed). Use `NO_COLOR=1` for plain text, or
`FORCE_COLOR=1` when piping.

## Migrating from an older wrapper

If your Makefile still sets knobs such as `SKILLS ?=` inline:

1. Move those values into `makefiles.config` (or run `make init` to create a
   starter, then edit).
2. Run `make update` to refresh the wrapper (default), or set
   `update_wrapper = no` until you are ready.
3. Remove the old knob lines from the Makefile.

## Custom skills in `.makefiles-custom/`

Project-specific Make fragments live under `.makefiles-custom/` (override with
`custom_dir` in `makefiles.config`). The wrapper includes
`$(MAKEFILES_CUSTOM_DIR)/*.mk` after the library skills — commit this
directory; only `.makefiles/` is gitignored.

```text
.makefiles-custom/
  deploy.mk          # make deploy, make deploy-staging, …
  local-tools.mk
```

Use this for targets that belong in the repo but are not part of the shared
library.
