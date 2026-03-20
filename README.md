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
  - [nvm](https://github.com/nvm-sh/nvm) (Node 22) + [Corepack](https://nodejs.org/api/corepack.html)
  - [pyenv](https://github.com/pyenv/pyenv) (Python 3.12)
  - [Homebrew](https://brew.sh/) + Brewfile (yarn, pnpm, [biome](https://biomejs.dev/), awscli, [ruff](https://docs.astral.sh/ruff/), [uv](https://docs.astral.sh/uv/), and more)
- Shell behavior:
  - Auto-use project `.nvmrc`
  - Auto-activate local `.venv` when present
- Setup scripts run in order; optional `apps.sh` stays manual

## What happens during install

`chezmoi init --apply` clones this repo and runs:

1. `run_once_after_prereqs.sh`
   - apt update/upgrade, build deps, Homebrew, nvm, oh-my-zsh, pyenv, Python 3.12
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

## Optional apps install

Run `apps.sh` after setup to install extra applications (Docker, etc.) from `apps.conf`.

`apps.sh` is not run automatically by chezmoi.

## Compatibility

Tested on **Ubuntu 22.04.5 LTS** and newer.

## Version management

Version values live in `versions.env`:

- `NODE_VERSION` (Node major line)
- `PYTHON_VERSION` (Python line)
- `NVM_INSTALL_VERSION` (nvm installer tag)

Node version precedence note:
- `nvm` follows the nearest `.nvmrc` from the current directory upward.
- A home-level `~/.nvmrc` can override your default alias in home-shell sessions.
- Recommended if you want global consistency with this repo: set `~/.nvmrc` to `22`.

Python behavior note:
- `run_once_before_finalize.sh` checks for any installed `PYTHON_VERSION.x` (for example `3.12.x`) and skips rebuilds on routine updates.
- To force a Python refresh intentionally, run with `DOTFILES_PYTHON_REFRESH=1 chezmoi apply`.

### Bump versions

1. Update `versions.env`
2. Keep `.nvmrc` aligned with `NODE_VERSION`
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
- `scripts/check-version-drift.sh` fails when `.nvmrc` and `versions.env` diverge
- `run_once_after_prereqs.sh` and `run_once_before_finalize.sh` keep using centralized version variables

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
