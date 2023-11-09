# dotfiles

My attempt at dotfiles.

## Installation

`sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply DiegoFleitas`

## Trying them out

Remember to put your own info at gitconfig file!

You can simply set up GitHub CodeSpaces to pick up dotfiles [here](https://github.com/settings/codespaces)
or create a new Ubuntu WSL2, install & clean up after. 
If you wanna try it out I suggest the first, CodeSpaces will run the installation snippet by itself picking it up from `bootstrap.sh`

ex:

```powershell
wsl --install -d ubuntu
# delete
# wsl --unregister ubuntu
```

