# dotfiles

My attempt at dotfiles.

## Before installation

Clone this repo (lol). You'll need git up & running on the new setup

`sudo apt install git`

## Installation

`sh install.sh`

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
