# dotfiles

[![Test](https://github.com/DiegoFleitas/dotfiles/actions/workflows/test.yml/badge.svg)](https://github.com/DiegoFleitas/dotfiles/actions/workflows/test.yml)
[![Version Drift](https://github.com/DiegoFleitas/dotfiles/actions/workflows/version-drift.yml/badge.svg)](https://github.com/DiegoFleitas/dotfiles/actions/workflows/version-drift.yml)

Personal Linux/macOS environment setup with [chezmoi](https://www.chezmoi.io/), shell scripts, and versioned configs.

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
  - [nvm](https://github.com/nvm-sh/nvm) (Node 22) + [Corepack](https://nodejs.org/api/corepack.html) — `npm` comes from the nvm-managed Node install, not a separate Homebrew `npm` package
  - [pyenv](https://github.com/pyenv/pyenv) (Python 3.12)
  - [Bun](https://bun.com) — official install script in `run_once_after_prereqs.sh` (not Homebrew)
  - [Homebrew](https://brew.sh/) + Brewfile (PHP 8.5, Composer, yarn, pnpm, [biome](https://biomejs.dev/), awscli, [ruff](https://docs.astral.sh/ruff/), [uv](https://docs.astral.sh/uv/), and more)
- Shell behavior:
  - **nvm** and **pyenv** are lazy-loaded on first use (faster shell startup)
  - Auto-use project `.nvmrc` (walks up directories)
  - Auto-activate the nearest `.venv` (walks up from the current directory, like `.nvmrc` discovery)
- Setup scripts run in order; optional `apps.sh` stays manual

## What happens during install

`chezmoi init --apply` clones this repo and runs:

1. `run_once_after_prereqs.sh`
   - apt update/upgrade, build deps, Homebrew, nvm, Bun (curl installer), oh-my-zsh, pyenv, Python 3.12, PHP 8.5 (via Brewfile)
2. Dotfiles apply
   - symlinks/copies for config files
3. `run_once_before_finalize.sh`
   - default shell (`zsh`), plus brew/nvm/omz/pyenv updates

## Try it in Codespaces

Quick test: open the [Codespaces blank template](https://github.com/github/codespaces-blank), then use **Code -> Open on Codespaces**.

To apply these dotfiles to all new Codespaces:

1. Open [GitHub Codespaces settings](https://github.com/settings/codespaces)
2. Under **Dotfiles**, select this repo (for example `DiegoFleitas/dotfiles`) or your fork
3. Turn on **Automatically install dotfiles**
4. Create a new Codespace from any repo

Codespaces clones this repo and runs `bootstrap.sh` (which triggers the same chezmoi install above).

Changes in this repo only affect **new** Codespaces.

## Ubuntu WSL2 quick setup

Install Ubuntu, then run the quick-start install command:

```powershell
wsl --install -d ubuntu
# To remove later: wsl --unregister ubuntu
```

WSL behavior notes:
- `run_once_before_finalize.sh` skips `chsh` on WSL to avoid interactive prompts during `chezmoi apply`/`chezmoi update`.
- To start in zsh automatically on WSL terminals, keep `exec zsh` in your `~/.bashrc`.

## Git identity prompt

> [!IMPORTANT]
> On first `chezmoi apply`, you will be prompted for git `user.name` and `user.email`. Those values are cached. To change them later, run `chezmoi apply` again or edit `~/.config/chezmoi/chezmoi.toml`.

Optional **signed commits**: add a `signingKey` (GPG or SSH) under `[data.git]` in `~/.config/chezmoi/chezmoi.toml`; the generated `.gitconfig` enables `commit.gpgsign` when that key is set (see `dot_gitconfig.tmpl` in this repo).

## SSH keys, API tokens, and secrets

This repo does **not** store private keys or API tokens. Suggested approach:

1. **SSH for Git**: generate a key with `ssh-keygen`, add the public key to your host, and use `ssh-agent` as usual.
2. **GitHub CLI**: `gh auth login` for HTTPS and API tasks when useful.
3. **Sensitive config**: use [chezmoi encryption](https://chezmoi.io/user-guide/frequently-asked-questions/encryption/) (age), a password manager, or keep secrets out of the repo and symlink them.

Do not commit cleartext tokens in templates that push to a public remote.

## Optional apps install

Run `apps.sh` after setup to install extra applications (Docker, etc.) from `apps.conf`.

`apps.sh` is **not** run automatically by chezmoi. Run it manually to install applications from `apps.conf` using system-level installers common on Debian/Ubuntu: apt, `.deb` packages, snap, apt repositories, and PPAs. On **macOS**, use Homebrew, the Mac App Store, or vendor installers for the same apps; this repo does not run `apps.sh` targets there. Homebrew-managed developer tools are provisioned from the `Brewfile` (applied during `run_once_after_prereqs.sh` with `brew bundle`). `Bun` is installed earlier in `run_once_after_prereqs.sh` using the official curl installer; other developer tooling comes from the `Brewfile`. Bun’s install directory is added to `PATH` from `.profile`, `.zshrc`, and `.bashrc`.

**Fly.io CLI** is optional. Install during `chezmoi apply` with `DOTFILES_INSTALL_FLYCTL=1` (for example `DOTFILES_INSTALL_FLYCTL=1 chezmoi apply`), or run `brew install flyctl` after setup.

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

- **Linux**: Tested on **Ubuntu 22.04.5 LTS** and newer. `run_once_*.sh` and `apps.sh` target apt/snap-based environments.
- **macOS**: Shell configs and Homebrew work on Apple Silicon and Intel; `apps.sh` is not used there (see [Optional apps install](#optional-apps-install)).

## Version management

Version values live in `versions.env`:

- `NODE_VERSION` (Node major line)
- `PYTHON_VERSION` (Python line)
- `PHP_VERSION` (PHP major.minor line; Homebrew `php`)
- `NVM_INSTALL_VERSION` (nvm installer tag)

Node version precedence note:
- `nvm` follows the nearest `.nvmrc` from the current directory upward.
- A home-level `~/.nvmrc` can override your default alias in home-shell sessions.
- Recommended if you want global consistency with this repo: set `~/.nvmrc` to `22`.

Python behavior note:
- `run_once_before_finalize.sh` checks for any installed `PYTHON_VERSION.x` (for example `3.12.x`) and skips rebuilds on routine updates.
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

Current test coverage (see `bats test/`):
- `scripts/check-version-drift.sh` passes with valid repo state; fails on `dot_nvmrc` / `versions.env` drift
- Grep-based contracts for `run_once_*.sh` (strict mode, version variables, brew bundle, optional flyctl)
- `test/after_prereqs_behavior.bats` exercises stubbed `run_once_after_prereqs.sh` paths
- `apps.sh` / `apps.conf` invariants and dry-run safety
- `dot_gitconfig.tmpl` and shell config expectations (portable Homebrew, no hardcoded Linuxbrew-only `shellenv`)

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
4. Optional: run `apps.sh` for extra apps (Docker, etc.)
