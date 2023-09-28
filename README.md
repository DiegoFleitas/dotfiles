# dotfiles

My attempt at dotfiles.

## Before installation

Clone this repo (lol). You'll need git up & running on the new setup

`sudo apt install git`

## Installation

`sh install.sh`

## Testing (manual)

Proceed at your own risk.

```powershell
wsl --install -d ubuntu
```

```bash
mkdir environment && cd environment
git clone https://github.com/DiegoFleitas/dotfiles.git
code dotfiles
sh install.sh
```

```powershell
wsl --unregister ubuntu
```
