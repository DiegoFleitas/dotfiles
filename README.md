# dotfiles

[![Test](https://github.com/DiegoFleitas/dotfiles/actions/workflows/test.yml/badge.svg)](https://github.com/DiegoFleitas/dotfiles/actions/workflows/test.yml)
[![Version Drift](https://github.com/DiegoFleitas/dotfiles/actions/workflows/version-drift.yml/badge.svg)](https://github.com/DiegoFleitas/dotfiles/actions/workflows/version-drift.yml)

Personal Linux/macOS environment setup with [chezmoi](https://www.chezmoi.io/), shell scripts, and versioned configs.

[![chezmoi](https://img.shields.io/badge/chezmoi-dotfiles-1B5E8A?logo=chezmoi&logoColor=white&style=flat-square)](https://www.chezmoi.io/)
[![Zsh](https://img.shields.io/badge/Zsh-shell-4EAA25?logo=zsh&logoColor=white&style=flat-square)](https://www.zsh.org/)
[![mise](https://img.shields.io/badge/mise-tool%20versions-000000?logo=mise&logoColor=white&style=flat-square)](https://mise.jdx.dev/)
[![Node.js](https://img.shields.io/badge/Node.js-24-339933?logo=nodedotjs&logoColor=white&style=flat-square)](https://nodejs.org/)
[![Python](https://img.shields.io/badge/Python-3.12-3776AB?logo=python&logoColor=white&style=flat-square)](https://www.python.org/)
[![PHP](https://img.shields.io/badge/PHP-8.5-777BB4?logo=php&logoColor=white&style=flat-square)](https://www.php.net/)
[![Bun](https://img.shields.io/badge/Bun-runtime-000000?logo=bun&logoColor=white&style=flat-square)](https://bun.com/)
[![Homebrew](https://img.shields.io/badge/Homebrew-packages-FBB040?logo=homebrew&logoColor=black&style=flat-square)](https://brew.sh/)

Quick links: [new machine](#tldr-new-machine) | [update current machine](#tldr-update-current-machine)

## Quick start

From your home directory:

```bash
cd ~
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply DiegoFleitas
```

After install, run `source ~/.profile` (or open a new shell).

## What you get

- `zsh` with [oh-my-zsh](https://ohmyz.sh/)
- Dotfiles like `.bashrc`, `.zshrc`, `.profile`, `.gitconfig` (template)
- Dev tooling via:
  - [nvm](https://github.com/nvm-sh/nvm) (Node 24) + [Corepack](https://nodejs.org/api/corepack.html)
  - Python 3.12 via [mise](https://mise.jdx.dev/) ([`dot_mise.toml`](dot_mise.toml)); optional [pyenv](https://github.com/pyenv/pyenv) if you set `DOTFILES_INSTALL_PYENV=1`
  - PHP 8.5 via mise ([`ubi:adwinying/php`](https://github.com/adwinying/php) in [`dot_mise.toml`](dot_mise.toml))
  - [Bun](https://bun.com) — official install script in `install/after_prereqs.sh` (not Homebrew)
  - [Homebrew](https://brew.sh/) + Brewfile (mise, Composer, yarn, pnpm, [biome](https://biomejs.dev/), awscli, [ruff](https://docs.astral.sh/ruff/), [uv](https://docs.astral.sh/uv/), and more); PHP runtime via [mise](https://mise.jdx.dev/) + [`dot_mise.toml`](dot_mise.toml)
- Shell behavior:
  - Auto-use project `.nvmrc`
  - Auto-activate local `.venv` when present
- Setup scripts run in order; optional `apps.sh` stays manual

## What happens during install

Chezmoi applies this repo in a fixed order. **`run_once_before_*`** scripts run *before* any files are written; **`run_once_after_*`** scripts run *after* all managed files are on disk. This repo uses only **`after_`** hooks, with numeric prefixes so **prereqs always runs before finalize** (both need Homebrew and other tools installed in the first step).

### Apply flow

```mermaid
flowchart TD
  A["chezmoi init --apply DiegoFleitas"] --> B["Dotfiles source in ~/.local/share/chezmoi"]
  B --> C["run_once_before_* — before any files change\n(this repo: none)"]
  C --> D["Apply managed files into ~\n.bashrc, .zshrc, .gitconfig, …"]
  D --> E["run_once_after_010_prereqs → install/after_prereqs.sh\napt, Homebrew, nvm, Bun, omz, mise, Brewfile, …"]
  E --> F["run_once_after_090_finalize → install/before_finalize.sh\nshell default, brew update, nvm/Corepack, omz, optional pyenv, …"]
  F --> G["New shell or: source ~/.profile"]
```

Chezmoi only runs **`run_once_*`** scripts when the script is new or its **rendered content** changed (see [use scripts](https://www.chezmoi.io/user-guide/use-scripts-to-perform-actions/)). To re-run everything from scratch you can clear script state: `chezmoi state delete-bucket --bucket=scriptState` (then `chezmoi apply`).

### GitHub Codespaces path

Account **Dotfiles** clones this repo under **`/workspaces/.codespaces/.persistedshare/dotfiles`**. **`install.sh`** runs first (so Codespaces does not treat the **`install/`** directory as the `install` hook). It calls **`bootstrap.sh`**, which runs the same **`chezmoi init --apply`** as local setup.

```mermaid
flowchart LR
  A["Codespaces: dotfiles repo clone"] --> B["install.sh"]
  B --> C["bootstrap.sh"]
  C --> D["chezmoi init --apply DiegoFleitas"]
  D --> E["Apply flow diagram above"]
```

## Try it in Codespaces

Quick test: open the [Codespaces blank template](https://github.com/github/codespaces-blank), then use **Code -> Open on Codespaces**.

To apply these dotfiles to all new Codespaces:

1. Open [GitHub Codespaces settings](https://github.com/settings/codespaces)
2. Under **Dotfiles**, select this repo (for example `DiegoFleitas/dotfiles`) or your fork
3. Turn on **Automatically install dotfiles**
4. Create a new Codespace from any repo

Codespaces clones this repo and runs the first matching installer (`install.sh`, then `install`, then `bootstrap.sh`, …). This repo ships **`install.sh`** so Codespaces does not treat the **`install/`** directory as the `install` hook (that produced `Permission denied`). `install.sh` delegates to `bootstrap.sh` (chezmoi install + apply).

Changes in this repo only affect **new** Codespaces.

### Codespaces minimal profile (default)

When **`CODESPACE_NAME`** is set (GitHub Codespaces), chezmoi defaults to **`DOTFILES_CODESPACES_PROFILE=minimal`** unless you override it. That skips heavy bootstrap the [devcontainers universal image](https://github.com/devcontainers/images/tree/main/src/universal) already provides (git, zsh, nvm, Node, Python, PHP, Docker, Oh My Zsh, etc.): no **`apt upgrade`**, no **Homebrew + Brewfile**, no **mise** toolchains, no **Bun** installer, no **oh-my-zsh** re-install, and **`before_finalize`** skips **brew update**, **nvm install/Corepack**, **oh-my-zsh update**, and **pyenv** maintenance.

Your **dotfiles still apply** (shell configs, `mise activate` guards, etc.). For **local-like** toolchain parity in the cloud, set **`DOTFILES_CODESPACES_PROFILE=full`** (for example in a Codespace **secret**, **devcontainer** `containerEnv`, or your dotfiles repo’s [`.devcontainer/devcontainer.json`](.devcontainer/devcontainer.json)).

The image often installs nvm at **`~/.nvm`** or **`/usr/local/share/nvm`**; `install/before_finalize.sh` resolves those when running the full profile.

## Ubuntu WSL2 quick setup

Install Ubuntu, then run the quick-start install command:

```powershell
wsl --install -d ubuntu
# To remove later: wsl --unregister ubuntu
```

WSL behavior notes:
- `install/before_finalize.sh` (via the `run_once_after_090_finalize` hook) skips `chsh` on WSL and in GitHub Codespaces to avoid interactive prompts during `chezmoi apply`/`chezmoi update`.
- To start in zsh automatically on WSL terminals, keep `exec zsh` in your `~/.bashrc`.

## Git identity prompt

> [!IMPORTANT]
> On first `chezmoi apply` in an interactive shell, you will be prompted for git `user.name` and `user.email`, plus optional install steps (apt, Homebrew, Bun, mise, oh-my-zsh, Fly.io CLI). Those values are cached in `~/.config/chezmoi/chezmoi.toml` and are not re-prompted on later applies. To change them later, edit that file or re-run `chezmoi init` as needed.
>
> In non-interactive environments without Codespaces (for example CI), prompts are skipped and chezmoi uses safe defaults: `apt`, `brew`, `bun`, `mise`, and `ohmyzsh` are enabled; `flyctl` is disabled; and git `user.name`/`user.email` are left empty so chezmoi will not write a `[user]` block to `~/.gitconfig`. On **GitHub Codespaces** (`CODESPACE_NAME` set), the default **`DOTFILES_CODESPACES_PROFILE=minimal`** turns **off** `apt`/`brew`/`bun`/`mise`/`oh-my-zsh` installs in generated config so bootstrap matches the universal image; set **`DOTFILES_CODESPACES_PROFILE=full`** if you want the same heavy install as WSL/local. To change values later, re-run `chezmoi init DiegoFleitas` interactively or edit `~/.config/chezmoi/chezmoi.toml`.

## Optional apps install

Run `apps.sh` after setup to install extra applications (Docker, etc.) from `apps.conf`.

`apps.sh` is run manually and installs applications from `apps.conf` using system-level installers common on Debian/Ubuntu: apt, `.deb` packages, snap, apt repositories, and PPAs. Homebrew-managed developer tools are provisioned from the `Brewfile` (applied during `install/after_prereqs.sh` with `brew bundle` when Homebrew install is enabled). `Bun` is installed earlier in `install/after_prereqs.sh` using the official curl installer; other developer tooling comes from the `Brewfile`.

**Fly.io CLI** is optional. Answer the chezmoi prompt for Fly.io on first apply, or set `DOTFILES_INSTALL_FLYCTL=1` for a run (for example `DOTFILES_INSTALL_FLYCTL=1 chezmoi apply`), or run `brew install flyctl` after setup.

Usage:

```bash
./apps.sh
```

Interactive picker controls (multi-select; default is none selected):
- Toggle selection by number(s): `1 3 5`
- Select all: `all`
- Clear all: `none`
- Start install: `done`
- Exit without installing: `q`

Non-interactive (install everything):

```bash
./apps.sh -y
```

Dry-run (prints what would be installed; does not run installs):

```bash
./apps.sh --dry-run
```

## Compatibility

Tested on **Ubuntu 22.04.5 LTS** and newer.

## Version management

Version values live in `versions.env`:

- `NODE_VERSION` (Node major line; matches `dot_nvmrc` / `~/.nvmrc`)
- `PYTHON_VERSION` (Python line)
- `PHP_VERSION` (PHP line; should match the pin in `dot_mise.toml`)
- `NVM_INSTALL_VERSION` (nvm installer tag)

Node version precedence note:
- `nvm` follows the nearest `.nvmrc` from the current directory upward.
- A home-level `~/.nvmrc` can override your default alias in home-shell sessions.
- Recommended if you want global consistency with this repo: set `~/.nvmrc` to `24`.

Python behavior note:
- `install/before_finalize.sh` checks for any installed `PYTHON_VERSION.x` (for example `3.12.x`) and skips rebuilds on routine updates.
- To force a Python refresh intentionally, run with `DOTFILES_PYTHON_REFRESH=1 chezmoi apply`.

### Bump versions

1. Update `versions.env` (`NODE_VERSION`, `PYTHON_VERSION`, `PHP_VERSION`, `NVM_INSTALL_VERSION` as needed)
2. Keep `dot_nvmrc` aligned with `NODE_VERSION` (published as `~/.nvmrc`)
3. Run:

```bash
bash scripts/check-version-drift.sh
```

4. If it passes, commit the version bump

### Drift protection

- `scripts/check-version-drift.sh` ensures scripts/docs use centralized values
- `.github/workflows/version-drift.yml` runs checks on push, PR, and monthly
- `.github/renovate.json` updates:
  - GitHub Actions versions
  - `NVM_INSTALL_VERSION` in `versions.env` (regex manager)

## Testing

Shell tests use [bats-core](https://github.com/bats-core/bats-core).

Run locally:

```bash
./scripts/test.sh
```

Direct command (if `bats` is already installed):

```bash
bats test/
```

CI:
- `.github/workflows/test.yml` installs Bats and runs `bats test/` on push and pull request events

Current test coverage:
- `scripts/check-version-drift.sh` passes with valid repo state
- `scripts/check-version-drift.sh` fails when `dot_nvmrc` and `versions.env` diverge
- `install/after_prereqs.sh` and `install/before_finalize.sh` keep using centralized version variables

## Troubleshooting

- Warning: `config file template has changed, run chezmoi init to regenerate config file`
  - Run:
    ```bash
    cd ~
    chezmoi init DiegoFleitas
    chezmoi apply
    ```
- Stale/legacy test hook symptoms (for example `test/finalize.bats` or `/tmp/helpers/common.bash` errors)
  - Regenerate config as above, then re-run:
    ```bash
    chezmoi update
    ```
  - Canonical test runner is `./scripts/test.sh` (or `bats test/` in repo root).

## TL;DR (update current machine)

From your home directory:

```bash
cd ~
chezmoi update
```

Then open a new shell (or run `source ~/.profile`), and confirm tools:
- `zsh --version`
- `node -v`
- `python --version`

## TL;DR (new machine)

1. Run:
   ```bash
   cd ~
   sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply DiegoFleitas
   ```
2. Open a new shell (or run `source ~/.profile`)
3. Confirm tools:
   - `zsh --version`
   - `node -v`
   - `python --version`
   - `php --version`
4. Optional: run `apps.sh` for extra apps (Docker, etc.)
