# Makefile Skills

Reusable **Makefile skills** for project versioning, Python quality tooling,
MkDocs documentation, Bash validation, Ruby gem workflows, and Perl, PHP,
PowerShell, JavaScript, and C validation, plus Go modules and Rust workspaces.

Each consumer project keeps a thin wrapper `Makefile` and a `makefiles.config`
file. The wrapper clones this library into a gitignored `.makefiles/` directory,
always enables **versioning**, and optionally enables standalone skills via
`skills` in config. Refresh the clone (and, by default, the wrapper itself)
with `make update` when you want a newer `ref`. `init` / `update` status is
quiet (`==>` lines only). Default clone transport is **https**.

## Why it Exists

Copy-pasted Makefiles drift. This library keeps shared targets in one place and
lets you refresh them with `make update`, while each project commits its wrapper,
`makefiles.config`, and `.gitignore`.

## Skills at a Glance

<div class="lupaxa-table lupaxa-table--skills" markdown="1">

| Skill      | Always on? | Purpose                                                                     |
| ---------- | ---------- | --------------------------------------------------------------------------- |
| Versioning | Yes        | Direct stable bumps plus optional `-dev` / `-rc` cycles (`bump-my-version`) |
| Bash       | Optional   | Discover scripts, `bash -n`, ShellCheck                                     |
| C          | Optional   | `gcc -fsyntax-only` and cppcheck                                            |
| Go         | Optional   | `go vet`, `go test`, and `go build` in each module                          |
| JavaScript | Optional   | `node --check` and ESLint                                                   |
| MkDocs     | Optional   | Build and serve docs (`mkdocs-serve` supports custom ports)                 |
| Perl       | Optional   | `perl -c` syntax checks and Perl::Critic                                    |
| PHP        | Optional   | `php -l`, PHP_CodeSniffer, and PHPStan                                      |
| PowerShell | Optional   | `pwsh` parse and PSScriptAnalyzer                                           |
| Python     | Optional   | Lint, type-check, test, audit, build, publish (prefixed targets)            |
| Ruby       | Optional   | Bundler install, RuboCop, `rake test`, gem build/publish                    |
| Rust       | Optional   | `cargo clippy`, `cargo test`, and `cargo build` in each workspace           |

</div>
