# Examples

Ready-made profiles live in [`examples/`](https://github.com/lupaxa-developers-toolbox/makefile-skills/tree/master/examples).
Each profile pairs a wrapper `Makefile` with a matching `makefiles.config`.
The wrapper is a copy of [`templates/Makefile`](https://github.com/lupaxa-developers-toolbox/makefile-skills/blob/master/templates/Makefile)
except where noted below.

<div class="lupaxa-table lupaxa-table--examples" markdown="1">

| Wrapper                    | Config                             | skills          | update_wrapper | Use when                       |
| -------------------------- | ---------------------------------- | --------------- | -------------- | ------------------------------ |
| `Makefile.versioning-only` | `makefiles.config.versioning-only` | *(empty)*       | `yes`          | Version bumps only             |
| `Makefile.bash-project`    | `makefiles.config.bash-project`    | `bash`          | `yes`          | Shell-script repositories      |
| `Makefile.javascript`      | `makefiles.config.javascript`      | `javascript`    | `yes`          | JavaScript scripts and modules |
| `Makefile.perl`            | `makefiles.config.perl`            | `perl`          | `yes`          | Perl scripts and modules       |
| `Makefile.php`             | `makefiles.config.php`             | `php`           | `yes`          | PHP applications and libraries |
| `Makefile.powershell`      | `makefiles.config.powershell`      | `powershell`    | `yes`          | PowerShell scripts and modules |
| `Makefile.python`          | `makefiles.config.python`          | `python`        | `no`           | Python package / app           |
| `Makefile.python-docs`     | `makefiles.config.python-docs`     | `python mkdocs` | `no`           | Python project with MkDocs     |
| `Makefile.ruby`            | `makefiles.config.ruby`            | `ruby`          | `yes`          | Ruby gem / library projects    |

</div>

Copy the wrapper to `./Makefile` and the matching config to `./makefiles.config`,
or copy only `templates/Makefile` and edit `makefiles.config` after `make init`.

!!! note "Python examples and wrapper refresh"
    `Makefile.python` and `Makefile.python-docs` append a CI alias overlay
    (`lint`, `check`, `test`, …) for
    [`reusable-python-makefile-ci`](https://github.com/the-lupaxa-project/workflows).
    That overlay would be wiped if `make update` refreshed the wrapper, so
    their configs set `update_wrapper = no`. Skills still update normally.

## Versioning Only

`makefiles.config.versioning-only`:

```ini
skills =
update_wrapper = yes
```

```bash
cp examples/Makefile.versioning-only ./Makefile
cp examples/makefiles.config.versioning-only ./makefiles.config
# add .makefiles/ to .gitignore
make init
make doctor
make bump-patch
# or, to start a -devN pre-release cycle instead: make bump-dev
```

## Bash

`makefiles.config.bash-project`:

```ini
skills = bash
update_wrapper = yes
```

```bash
cp examples/Makefile.bash-project ./Makefile
cp examples/makefiles.config.bash-project ./makefiles.config
make init
make bash-list-scripts
make bash-check
```

## JavaScript

`makefiles.config.javascript`:

```ini
skills = javascript
update_wrapper = yes
```

```bash
cp examples/Makefile.javascript ./Makefile
cp examples/makefiles.config.javascript ./makefiles.config
make init
make javascript-doctor
make javascript-check
```

## Perl

`makefiles.config.perl`:

```ini
skills = perl
update_wrapper = yes
```

```bash
cp examples/Makefile.perl ./Makefile
cp examples/makefiles.config.perl ./makefiles.config
make init
make perl-doctor
make perl-check
```

## PHP

`makefiles.config.php`:

```ini
skills = php
update_wrapper = yes
```

```bash
cp examples/Makefile.php ./Makefile
cp examples/makefiles.config.php ./makefiles.config
make init
make php-doctor
make php-check
```

## PowerShell

`makefiles.config.powershell`:

```ini
skills = powershell
update_wrapper = yes
```

```bash
cp examples/Makefile.powershell ./Makefile
cp examples/makefiles.config.powershell ./makefiles.config
make init
make powershell-doctor
make powershell-check
```

## Python

`makefiles.config.python`:

```ini
skills = python
update_wrapper = no
```

```bash
cp examples/Makefile.python ./Makefile
cp examples/makefiles.config.python ./makefiles.config
make init
make python-install-dev
make python-check
```

## Python + MkDocs

`makefiles.config.python-docs`:

```ini
skills = python mkdocs
update_wrapper = no
```

```bash
cp examples/Makefile.python-docs ./Makefile
cp examples/makefiles.config.python-docs ./makefiles.config
make init
make python-check
make mkdocs-serve MKDOCS_PORT=8000
```

## Ruby

`makefiles.config.ruby`:

```ini
skills = ruby
update_wrapper = yes
```

```bash
cp examples/Makefile.ruby ./Makefile
cp examples/makefiles.config.ruby ./makefiles.config
make init
make ruby-bundle
make ruby-check
```

!!! tip "Ignore the clone"
    Consumer projects should ignore `.makefiles/` (see `examples/.gitignore`).
    Commit the wrapper Makefile and `makefiles.config`; do not commit the clone.
