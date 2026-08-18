# makefile-skills

Reusable **Makefile skills** for project versioning, Python quality tooling,
MkDocs documentation, and Bash validation.

Each consumer project keeps a thin wrapper `Makefile` and a `makefiles.config`
file. The wrapper clones this library into a gitignored `.makefiles/` directory,
always enables **versioning**, and optionally enables standalone skills via
`skills` in config. Refresh the clone (and, by default, the wrapper itself)
with `make update` when you want a newer `ref`. `init` / `update` status is
quiet (`==>` lines only). Default clone transport is **https**.

## Why it exists

Copy-pasted Makefiles drift. This library keeps shared targets in one place and
lets you refresh them with `make update`, while each project commits its wrapper,
`makefiles.config`, and `.gitignore`.

## Skills at a glance

<div class="lupaxa-table lupaxa-table--skills" markdown="1">

| Skill | Always on? | Purpose |
| --- | --- | --- |
| Versioning | Yes | Direct stable bumps plus optional `-dev` / `-rc` cycles (`bump-my-version`) |
| Python | Optional | Lint, type-check, test, audit, build, publish (prefixed targets) |
| MkDocs | Optional | Build and serve docs (`mkdocs-serve` supports custom ports) |
| Bash | Optional | Discover scripts, `bash -n`, ShellCheck |

</div>

## Next steps

- [Getting started](getting-started.md) — copy the wrapper, `make init`, edit config
- [Usage](usage.md) — day-to-day workflows (`doctor`, bumps, Python, docs, Bash)
- [Reference](reference.md) — commands, config keys, and variables
- [Examples](examples.md) — ready-made wrapper and config profiles
