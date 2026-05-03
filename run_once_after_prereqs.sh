#!/bin/bash
set -euo pipefail
# This script runs at the start of chezmoi apply (run_after_): system deps, brew, mise, oh-my-zsh.

# set -x  # This will bash print each command before executing it.

# Function to display messages with separators
output_message() {
    echo "======================================="
    echo "$1"
    echo "======================================="
}

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC2034
export MISE_CONFIG_FILE="${SCRIPT_DIR}/dot_mise.toml"

if [ "${DOTFILES_DISABLE_APT:-0}" = "1" ]; then
    HAS_APT=0
elif [ "$(uname -s)" = "Linux" ] && command -v apt >/dev/null 2>&1; then
    HAS_APT=1
else
    HAS_APT=0
fi

# Early return if root user (brew install errors out on root)
if [ "$(id -u)" -eq 0 ]; then
   output_message "Rerun as non root."
   exit 1
fi

### Essentials
if [ "${HAS_APT}" -eq 1 ]; then
    # Update packages
    output_message "Updating apt packages..."
    sudo apt update && sudo apt upgrade -y

    # Install build essentials and required dependencies
    output_message "Installing apt build dependencies..."
    sudo apt install -y \
      build-essential \
      libssl-dev \
      libffi-dev \
      python3-dev \
      zlib1g-dev \
      libbz2-dev \
      libreadline-dev \
      libsqlite3-dev \
      curl \
      git \
      wget \
      zsh
else
    output_message "apt not available. Skipping apt dependency setup."
fi

# Install git if not already installed
# (I usually install git manually, but this is here just in case)
if ! command -v git &> /dev/null; then
    output_message "Installing git..."
    if [ "${HAS_APT}" -eq 1 ]; then
        sudo apt install git -y
    else
        output_message "Package manager for git not detected. Install git manually."
    fi
fi

# Install curl if not already installed
if ! command -v curl &> /dev/null; then
    output_message "Installing curl..."
    if [ "${HAS_APT}" -eq 1 ]; then
        sudo apt install curl -y
    else
        output_message "Package manager for curl not detected. Install curl manually."
    fi
fi

# Install Homebrew if not already installed
if ! command -v brew &> /dev/null; then
    output_message "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Add brew to user's path (skip fixed-path eval when stubbing `brew` on PATH; see Bats tests).
if [ "${DOTFILES_BREW_USE_PATH_ONLY:-0}" != "1" ]; then
  if [ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
      eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  elif [ -x "/opt/homebrew/bin/brew" ]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x "/usr/local/bin/brew" ]; then
      eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

### Development tools
# Bun (official installer; separate from mise-managed Node)
BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
export BUN_INSTALL
if [ ! -x "$BUN_INSTALL/bin/bun" ]; then
    output_message "Installing bun..."
    curl -fsSL https://bun.com/install | bash
fi

# Install brew packages
output_message "Installing brew packages..."
# Use Brewfile from chezmoi directory or fall back to this one
brew bundle --file="${HOME}/.local/share/chezmoi/Brewfile" 2>/dev/null || brew bundle

# mise: polyglot tool versions (see dot_mise.toml)
if ! command -v mise &> /dev/null; then
    output_message "Installing mise..."
    brew install mise
fi

output_message "Installing toolchains via mise (see dot_mise.toml)..."
mise install -y
# Expose shims in this non-interactive script (same effect as `mise activate` in a shell).
# shellcheck disable=SC1090
eval "$(mise env -s bash 2>/dev/null)" || true

if command -v node &> /dev/null && command -v python3 &> /dev/null && command -v php &> /dev/null; then
    output_message "mise toolchains are available (node, python3, php)."
else
    output_message "Warning: expected mise shims not all on PATH yet; open a new shell after apply."
fi

# Optional Fly.io CLI (left out of default Brewfile)
if [ "${DOTFILES_INSTALL_FLYCTL:-0}" = "1" ]; then
  if command -v brew &>/dev/null; then
    if command -v fly &>/dev/null || command -v flyctl &>/dev/null; then
      output_message "Fly CLI already installed; skipping flyctl."
    else
      output_message "DOTFILES_INSTALL_FLYCTL=1, installing flyctl..."
      brew install flyctl
    fi
  else
    output_message "DOTFILES_INSTALL_FLYCTL=1 but brew not found; skipping flyctl."
  fi
fi

# Install oh-my-zsh if not already installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    output_message "Installing oh-my-zsh..."
    # RUNZSH flag for unattended installation
    RUNZSH=no /bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    # set zsh as default shell
    if [ -r /proc/version ] && grep -qi microsoft /proc/version; then
        # WSL detected - add to shell profile instead of chsh
        if [ -f "$HOME/.bashrc" ] && ! grep -qxF "exec zsh" "$HOME/.bashrc"; then
            echo "exec zsh" >> "$HOME/.bashrc"
        fi
    else
        chsh -s "$(command -v zsh)"
    fi
fi

output_message "Bye! (Run source ~/.profile to apply changes)"
