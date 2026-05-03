# dotfiles

[![Test](https://github.com/DiegoFleitas/dotfiles/actions/workflows/test.yml/badge.svg)](https://github.com/DiegoFleitas/dotfiles/actions/workflows/test.yml)
[![Version drift](https://github.com/DiegoFleitas/dotfiles/actions/workflows/version-drift.yml/badge.svg)](https://github.com/DiegoFleitas/dotfiles/actions/workflows/version-drift.yml)

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
  - [mise](https://mise.jdx.dev/) — Node 22, Python 3.12, and PHP 8.4 from a single [`dot_mise.toml`](dot_mise.toml) (installed as `~/.mise.toml` via chezmoi); [Corepack](https://nodejs.org/api/corepack.html) is enabled in `run_once_before_finalize.sh`
  - [Bun](https://bun.com) — official install script in `run_once_after_prereqs.sh` (not Homebrew)
  - [Homebrew](https://brew.sh/) + Brewfile ([mise](https://formulae.brew.sh/formula/mise), Composer, yarn, pnpm, [biome](https://biomejs.dev/), awscli, [ruff](https://docs.astral.sh/ruff/), [uv](https://docs.astral.sh/uv/), and more)
- Shell behavior:
  - **mise** activates after Homebrew `shellenv` (see `.zshrc` / `.bashrc`)
  - Project-local versions: mise respects `mise.toml` / tool files when you walk directories; a repo-published `dot_nvmrc` still maps to `~/.nvmrc` for tools that read it
  - Auto-activate the nearest `.venv` (walks up from the current directory)
- Setup scripts run in order; optional `apps.sh` stays manual

## What happens during install

`chezmoi init --apply` clones this repo and runs:

1. `run_once_after_prereqs.sh`
   - apt update/upgrade and build deps (Linux with apt), Homebrew (install if needed), Bun (curl installer), `brew bundle`, then `mise install` from `dot_mise.toml`, optional Fly.io CLI (`DOTFILES_INSTALL_FLYCTL=1`), then oh-my-zsh. Exits early if run as root.
2. Dotfiles apply
   - symlinks/copies for config files (including `~/.mise.toml`)
3. `run_once_before_finalize.sh`
   - default shell (`zsh`), mise toolchain refresh, Corepack, brew update, oh-my-zsh update

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

Tool versions live in **`dot_mise.toml`** (single source of truth; chezmoi installs it as `~/.mise.toml`). Current pins: Node **22**, Python **3.12**, PHP **8.4**.

Node note: keep **`dot_nvmrc`** aligned with the `node = "…"` entry so `~/.nvmrc` stays consistent for anything that reads it without mise.

Python refresh: run `DOTFILES_PYTHON_REFRESH=1 chezmoi apply` to force a reinstall of the Python version via mise (`run_once_before_finalize.sh`).

### Bump versions

1. Edit `dot_mise.toml` (`node`, `python`, `php`)
2. Update `dot_nvmrc` if you changed the Node line
3. Update this README if you change major/minor lines so the documented numbers stay accurate
4. Run `./scripts/test.sh` (includes contract tests for README / `dot_nvmrc` alignment)
5. Commit the bump

### Drift protection

- Bats tests in `test/mise_config_contract.bats` and `test/version_drift.bats` assert config shape and alignment between `dot_mise.toml`, `dot_nvmrc`, and README
- `.github/workflows/version-drift.yml` runs those contract tests on push, PR, and monthly
- `.github/renovate.json` tracks GitHub Actions dependency updates

## Testing

Shell tests use [bats-core](https://github.com/bats-core/bats-core). Behavioral checks for `run_once_*.sh` also run under **pytest** (`test_python/`) with explicit subprocess env/timeouts.

Install dev deps once:

```bash
pip install -r requirements-dev.txt
```

Run locally:

```bash
./scripts/test.sh
```

Direct commands (if tools are already installed):

```bash
bats --jobs 1 test/
python3 -m pytest test_python/
```

CI runs `./scripts/test.sh` on Ubuntu and macOS (see `.github/workflows/test.yml`).

All `*.bats` files under [`test/`](test/) drive validation. They cover, among other themes: mise config and version alignment, stub-based provisioning script behavior, `apps.sh` / picker flows, Brewfile and `apps.conf` contracts, idempotency guards, and template/shell-config sanity. Browse `test/` for the current suites rather than duplicating an inventory here.

If a Bats test **hangs** or a stub test **fails in odd ways** (e.g. missing `CALL_LOG` lines), read the short “footguns” note at the top of [`test/helpers/common.bash`](test/helpers/common.bash) (stub shebangs, `grep` on `PATH`, env forwarding—run a single file with `timeout 60 bats test/some.bats` while debugging).

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
  - Canonical test runner is `./scripts/test.sh` (or `bats --jobs 1 test/` in repo root).

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
- `php --version`

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
