# dotfiles

Personal configuration files for Linux and macOS environments. Reproducible setup using [chezmoi](https://www.chezmoi.io/), shell scripts, and versioned configs.

## What's included

- **Shell:** zsh with [oh-my-zsh](https://ohmyz.sh/)
- **Dot configs:** `.bashrc`, `.zshrc`, `.profile`, `.gitconfig` (template)
- **Dev stack:** [nvm](https://github.com/nvm-sh/nvm) (Node), [pyenv](https://github.com/pyenv/pyenv) (Python 3.10.9), [Homebrew](https://brew.sh/) + Brewfile (yarn, pnpm, awscli, etc.)
- **Run scripts:** system deps and tool installs run automatically in order; optional `apps.sh` for extra apps (run manually after apply)

## Installation

From your home directory:

```bash
cd ~
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply DiegoFleitas
```

Chezmoi will clone this repo and run, in order:

1. **run_once_after_prereqs.sh** — apt update/upgrade, build deps, Homebrew, nvm, oh-my-zsh, pyenv, Python 3.10.9
2. **Dotfiles apply** — symlinks/copies for config files
3. **run_once_before_finalize.sh** — default shell (zsh), brew/nvm/omz/pyenv updates

Then run `source ~/.profile` (or open a new shell) to pick up changes.

## Trying them out

### GitHub Codespaces

You can use this repo (or your fork) so every new Codespace gets these configs automatically:

1. Open [GitHub Codespaces settings](https://github.com/settings/codespaces).
2. Under **Dotfiles**, use the dropdown to select this repository (e.g. `DiegoFleitas/dotfiles` or your fork).
3. Turn on **Automatically install dotfiles**.
4. Create a new Codespace from any repo. Codespaces will clone this dotfiles repo and run `bootstrap.sh`, which runs the same chezmoi install as the snippet above.

Changes to this repo only apply to **new** Codespaces; existing ones are unchanged.

### New Ubuntu WSL2

Install a distro, then run the install snippet above. Example:

  ```powershell
  wsl --install -d ubuntu
  # To remove later: wsl --unregister ubuntu
  ```

## Git config

> [!IMPORTANT]
> On first `chezmoi apply` you will be prompted for your git `user.name` and `user.email`; those values are cached. To change them later, run `chezmoi apply` again or edit `~/.config/chezmoi/chezmoi.toml`.

Remember to set your own name and email in the gitconfig when prompted.

## Optional: apps.sh

After installation, you can run `apps.sh` to install extra applications (Docker, etc.) according to `apps.conf`. This is not run automatically by chezmoi.

## Compatibility

Tested on **Ubuntu 22.04.5 LTS** and later. Best results on that version or newer.
