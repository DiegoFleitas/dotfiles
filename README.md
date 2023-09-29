# dotfiles

My attempt at dotfiles.

## Installation

`sh -c "$(curl -fsLS git.io/chezmoi)" -- init --apply DiegoFleitas`

## Testing (manual)

Proceed at your own risk.

Create a new Ubuntu WSL2

```powershell
wsl --install -d ubuntu
```

Clone repo & run dotfiles

```bash
git clone https://github.com/DiegoFleitas/dotfiles.git environment/dotfiles
cd environment/dotfiles
code .
sh install.sh
```

Clean up

```powershell
wsl --unregister ubuntu
```
