# dotfiles

Personal configuration files for Linux and macOS environments.  
Reproducible setup using `chezmoi`, shell scripts, and versioned configs.

## Installation

`cd ~`
`sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply DiegoFleitas`

## Trying them out

Remember to put your own info at gitconfig file!

You can simply set up GitHub CodeSpaces to pick up dotfiles [here](https://github.com/settings/codespaces), CodeSpaces will run the installation snippet by itself picking it up from `bootstrap.sh`

Or create a new Ubuntu WSL2, install & clean up after. 
ex:

```powershell
wsl --install -d ubuntu
# delete
# wsl --unregister ubuntu
```

## Git config

> [!IMPORTANT]
> On first `chezmoi apply` you will be prompted for your git `user.name` and `user.email`; those values are cached. To change them later, run `chezmoi apply` again or edit `~/.config/chezmoi/chezmoi.toml`.

## Compatibility

This repository is now updated and tested for compatibility with Ubuntu 22.04.5 LTS. Ensure you are using this version or later for best results.

