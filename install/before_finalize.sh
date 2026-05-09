#!/usr/bin/env bash

set -euo pipefail

# Define output_message function
output_message() {
  echo "===================================="
  echo "$1"
  echo "===================================="
}

SCRIPT_DIR="$(cd -- "${BASH_SOURCE[0]%/*}" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
# shellcheck disable=SC1091
[ -f "${REPO_ROOT}/versions.env" ] && . "${REPO_ROOT}/versions.env"
: "${NODE_VERSION:=22}"
: "${PYTHON_VERSION:=3.12}"
: "${DOTFILES_PYTHON_REFRESH:=0}"

is_wsl() {
  grep -qi microsoft /proc/version 2>/dev/null
}

# Ensure Zsh is installed before proceeding
if ! command -v zsh &> /dev/null; then
  echo "Zsh is not installed."
  # echo "Installing Zsh..."
  # sudo apt-get update && sudo apt-get install -y zsh
  output_message "Skipping Zsh installation."
else
  output_message "Zsh is already installed."
fi

# Add zsh to /etc/shells if it's not already there
# This is necessary because chsh only accepts shells listed in /etc/shells.
ZSH_BIN="$(command -v zsh)"
if ! grep -q "${ZSH_BIN}" /etc/shells; then
  echo "${ZSH_BIN}" | sudo tee -a /etc/shells
  output_message "Added zsh to /etc/shells."
else
  output_message "Zsh is already in /etc/shells."
fi

# Attempt to set default shell to zsh if not already set
if [ "${SHELL:-}" != "${ZSH_BIN}" ]; then
  if is_wsl; then
    output_message "WSL detected. Skipping chsh to avoid interactive prompts."
  else
    chsh -s "${ZSH_BIN}"
    output_message "Default shell changed to Zsh. Please log out and log back in for changes to take effect."
  fi
fi

# Instead of exec zsh, run the remaining commands in the current shell
output_message "Continuing setup process..."

# Check if nvm is available before updating
if [ "${DOTFILES_INSTALL_MISE:-1}" = "1" ]; then
  if [ -f "$HOME/.nvm/nvm.sh" ]; then
    output_message "Loading and updating nvm..."
    export NVM_DIR="$HOME/.nvm"
    # shellcheck disable=SC1091
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    # shellcheck disable=SC1091
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
    nvm install "${NODE_VERSION}" && nvm alias default "${NODE_VERSION}"
    if command -v corepack &>/dev/null; then
      output_message "Enabling Corepack (pnpm/yarn with Node)..."
      corepack enable
    fi
  else
    output_message "nvm not found. Skipping nvm update."
  fi
else
  output_message "Skipping toolchain update (DOTFILES_INSTALL_MISE=0)."
fi

# Check if brew is available before updating
if [ "${DOTFILES_INSTALL_BREW:-1}" = "1" ]; then
  if command -v brew &> /dev/null; then
    output_message "Updating Homebrew..."
    brew update
    if [ "${DOTFILES_BREW_UPGRADE:-0}" = "1" ]; then
      output_message "DOTFILES_BREW_UPGRADE=1, upgrading Homebrew packages..."
      brew upgrade
    else
      output_message "Skipping brew upgrade by default (set DOTFILES_BREW_UPGRADE=1 to enable)."
    fi
  else
    output_message "Homebrew not found. Skipping Homebrew update."
  fi
else
  output_message "Skipping Homebrew update (DOTFILES_INSTALL_BREW=0)."
fi

# Update oh-my-zsh
if [ "${DOTFILES_INSTALL_OHMYZSH:-1}" = "1" ]; then
  if [ -d "$HOME/.oh-my-zsh" ]; then
    output_message "Updating oh-my-zsh..."
    ZDOTDIR="${HOME}" ZSH_DISABLE_COMPFIX=true zsh -f -c '
      export ZSH="$HOME/.oh-my-zsh"
      [ -f "$ZSH/oh-my-zsh.sh" ] && . "$ZSH/oh-my-zsh.sh"
      command -v omz >/dev/null 2>&1 && omz update
    '
  else
    output_message "oh-my-zsh not found. Skipping oh-my-zsh update."
  fi
else
  output_message "Skipping oh-my-zsh update (DOTFILES_INSTALL_OHMYZSH=0)."
fi

# Check if pyenv is available before updating
if [ "${DOTFILES_INSTALL_MISE:-1}" = "1" ]; then
  if [ "${DOTFILES_INSTALL_BREW:-1}" = "1" ]; then
    if command -v pyenv &> /dev/null; then
      output_message "Updating pyenv and Python versions..."
      brew upgrade pyenv
      if pyenv versions --bare | grep -Eq "^${PYTHON_VERSION}(\\.|$)"; then
        output_message "Python ${PYTHON_VERSION}.x already present; skipping rebuild. Set DOTFILES_PYTHON_REFRESH=1 to force refresh."
        if [ "${DOTFILES_PYTHON_REFRESH}" = "1" ]; then
          output_message "DOTFILES_PYTHON_REFRESH=1, refreshing Python ${PYTHON_VERSION}..."
          pyenv install "${PYTHON_VERSION}"
        fi
      else
        output_message "No Python ${PYTHON_VERSION}.x found. Installing..."
        pyenv install "${PYTHON_VERSION}"
      fi
    else
      output_message "pyenv not found. Skipping pyenv update."
    fi
  else
    output_message "Skipping pyenv update (DOTFILES_INSTALL_BREW=0)."
  fi
else
  output_message "Skipping toolchain update (DOTFILES_INSTALL_MISE=0)."
fi

output_message "Setup completed successfully! (You can run apps.sh now; tests: ./scripts/test.sh)"
