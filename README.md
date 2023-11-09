# dotfiles

My attempt at dotfiles.

## Installation

`sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply DiegoFleitas`

## Trying them out

You can simply set up GitHub CodeSpaces to pick up dotfiles [here](https://github.com/settings/codespaces)
or create a new Ubuntu WSL2, install & clean up after
ex:

```powershell
wsl --install -d ubuntu
# delete
# wsl --unregister ubuntu
```
