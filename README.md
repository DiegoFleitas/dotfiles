# dotfiles

[![Test](https://github.com/DiegoFleitas/dotfiles/actions/workflows/test.yml/badge.svg)](https://github.com/DiegoFleitas/dotfiles/actions/workflows/test.yml)
[![Version drift](https://github.com/DiegoFleitas/dotfiles/actions/workflows/version-drift.yml/badge.svg)](https://github.com/DiegoFleitas/dotfiles/actions/workflows/version-drift.yml)

[![chezmoi](https://img.shields.io/badge/chezmoi-dotfiles-1B5E8A?logo=chezmoi&logoColor=white&style=flat-square)](https://www.chezmoi.io/)
[![Zsh](https://img.shields.io/badge/Zsh-shell-4EAA25?logo=zsh&logoColor=white&style=flat-square)](https://www.zsh.org/)
[![mise](https://img.shields.io/badge/mise-tool%20versions-000000?logo=mise&logoColor=white&style=flat-square)](https://mise.jdx.dev/)
[![Node.js](https://img.shields.io/badge/Node.js-22-339933?logo=nodedotjs&logoColor=white&style=flat-square)](https://nodejs.org/)
[![Python](https://img.shields.io/badge/Python-3.12-3776AB?logo=python&logoColor=white&style=flat-square)](https://www.python.org/)
[![PHP](https://img.shields.io/badge/PHP-8.4-777BB4?logo=php&logoColor=white&style=flat-square)](https://www.php.net/)
[![Bun](https://img.shields.io/badge/Bun-runtime-000000?logo=bun&logoColor=white&style=flat-square)](https://bun.com/)
[![Homebrew](https://img.shields.io/badge/Homebrew-packages-FBB040?logo=homebrew&logoColor=black&style=flat-square)](https://brew.sh/)

Personal Linux/macOS setup with [chezmoi](https://www.chezmoi.io/), shell hooks, and versioned configs.

## Install (new machine)

```bash
cd ~
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply DiegoFleitas
```

Then `source ~/.profile` or open a new shell. Confirm: `zsh --version`, `node -v`, `python --version`, `php --version`.

## Update

```bash
cd ~
chezmoi update
```

New shell or `source ~/.profile`.

## What’s in the box

- **Shell:** `zsh` + [oh-my-zsh](https://ohmyz.sh/); dotfiles (`.bashrc`, `.zshrc`, `.profile`, templated `.gitconfig`).
- **Tooling:** [mise](https://mise.jdx.dev/) pins **Node 22**, **Python 3.12**, **PHP 8.4** in [`dot_mise.toml`](dot_mise.toml) → `~/.mise.toml`; [Bun](https://bun.com) via curl in `run_once_after_prereqs.sh`; [Homebrew](https://brew.sh/) + Brewfile (mise, Composer, yarn, pnpm, biome, awscli, ruff, uv, …). [Corepack](https://nodejs.org/api/corepack.html) in `run_once_before_finalize.sh`.
- **Behavior:** mise after `brew shellenv`; repo [`dot_nvmrc`](dot_nvmrc) → `~/.nvmrc`; walk-up `.venv` activation.

## Install order

`chezmoi init --apply` runs:

1. **`run_once_after_prereqs.sh`** — apt prep (Linux), Homebrew, Bun, `brew bundle`, `mise install`, optional Fly (`DOTFILES_INSTALL_FLYCTL=1`), oh-my-zsh (no-op as root).
2. **Dotfiles** — templates and `~/.mise.toml`.
3. **`run_once_before_finalize.sh`** — default shell `zsh`, mise refresh, Corepack, `brew update`, oh-my-zsh update.

## Codespaces

[Codespaces settings](https://github.com/settings/codespaces) → **Dotfiles** → this repo → **Automatically install dotfiles**. New codespaces run `bootstrap.sh` (same chezmoi flow). Changes apply to **new** codespaces only. Quick try: [blank template](https://github.com/github/codespaces-blank) → **Code → Open on Codespaces**.

## WSL2 (Ubuntu)

```powershell
wsl --install -d ubuntu
# Remove: wsl --unregister ubuntu
```

`run_once_before_finalize.sh` skips `chsh` on WSL (non-interactive apply). Keep `exec zsh` in `~/.bashrc` if you want zsh by default.

## Git

> [!IMPORTANT]
> First `chezmoi apply` prompts for `user.name` / `user.email` (cached). Change later with `chezmoi apply` or `~/.config/chezmoi/chezmoi.toml`.

Signed commits: set `signingKey` under `[data.git]` → see `dot_gitconfig.tmpl`.

## Secrets

No keys or tokens in this repo. Use `ssh-keygen` + host keys, `gh auth login`, [chezmoi encryption](https://chezmoi.io/user-guide/frequently-asked-questions/encryption/) (age), or a password manager—never cleartext secrets in public templates.

## Optional `apps.sh`

Not run by chezmoi. **Linux:** installs from `apps.conf` via apt, `.deb`, snap, apt repositories, and PPAs. **macOS:** not invoked here—use Brew/App Store/vendors for the same apps. Dev packages are provisioned from the `Brewfile` during `run_once_after_prereqs.sh` (`brew bundle`). `Bun` is installed earlier in `run_once_after_prereqs.sh` using the official curl installer; other dev tools come from the Brewfile.

**Fly.io CLI:** `DOTFILES_INSTALL_FLYCTL=1 chezmoi apply` or `brew install flyctl` later.

```bash
./apps.sh              # interactive picker (default: none selected)
./apps.sh -y           # install all
./apps.sh --dry-run    # print only
```

Picker: numbers toggle, `all` / `none`, `done` to run, `q` to quit.

## Compatibility

- **Linux:** Ubuntu 22.04+ (apt/snap); `apps.sh` matches that stack.
- **macOS:** Apple Silicon / Intel; Homebrew + shell configs; no `apps.sh`.

## Versions & bumps

Single source: **`dot_mise.toml`** (pins **Node 22**, **Python 3.12**, **PHP 8.4**). Keep **`dot_nvmrc`** in sync with the `node = "…"` line. Force Python reinstall: `DOTFILES_PYTHON_REFRESH=1 chezmoi apply`.

**Bump:** edit `dot_mise.toml` → `dot_nvmrc` if Node changed → README + Shields labels → `./scripts/test.sh` → commit.

**Drift:** `test/mise_config_contract.bats`, `test/version_drift.bats`, workflow `version-drift.yml`, Renovate on Actions.

**PHP (Linux/WSL):** mise builds PHP from source; `install/mise_install_env.sh` sets conservative `MAKEFLAGS` / `ASDF_CONCURRENCY`. If linking fails, raise VM/WSL RAM, try `MISE_VERBOSE=1 mise install -y`, or point `TMPDIR` at a roomy disk.

## Testing

[bats-core](https://github.com/bats-core/bats-core) + **pytest** (`test_python/`). `pip install -r requirements-dev.txt` then `./scripts/test.sh` (same as CI: `.github/workflows/test.yml`). More suites live under [`test/`](test/); stub footguns: [`test/helpers/common.bash`](test/helpers/common.bash).

## Troubleshooting

- **“config file template has changed…”** — `cd ~ && chezmoi init DiegoFleitas && chezmoi apply`
- **Legacy test paths** (`finalize.bats`, `/tmp/helpers/…`) — regenerate config as above, `chezmoi update`, use `./scripts/test.sh`
