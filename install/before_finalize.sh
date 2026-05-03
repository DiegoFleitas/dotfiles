#!/bin/bash

set -euo pipefail

# Implementation for chezmoi run_once (invoked via repo-root run_once_before_finalize.sh).

# Define output_message function
output_message() {
  echo "===================================="
  echo "$1"
  echo "===================================="
}

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC2034
export MISE_CONFIG_FILE="${REPO_ROOT}/dot_mise.toml"
: "${DOTFILES_PYTHON_REFRESH:=0}"

is_wsl() {
  command -v grep >/dev/null 2>&1 && [ -r /proc/version ] && grep -qi microsoft /proc/version 2>/dev/null
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
    if command -v chsh >/dev/null 2>&1; then
      chsh -s "${ZSH_BIN}"
      output_message "Default shell changed to Zsh. Please log out and log back in for changes to take effect."
    else
      output_message "chsh not found. Skipping default shell change."
    fi
  fi
fi

# Instead of exec zsh, run the remaining commands in the current shell
output_message "Continuing setup process..."

# mise: install/refresh toolchains from dot_mise.toml
if command -v mise &> /dev/null; then
  if [ "${DOTFILES_PYTHON_REFRESH}" = "1" ]; then
    output_message "DOTFILES_PYTHON_REFRESH=1, forcing Python reinstall via mise..."
    mise install -f python
  fi
  output_message "Ensuring mise toolchains are installed..."
  mise install -y
  # shellcheck disable=SC1090
  eval "$(mise env -s bash 2>/dev/null)" || true
  if command -v corepack &>/dev/null; then
    output_message "Enabling Corepack (pnpm/yarn with Node)..."
    corepack enable
  else
    output_message "corepack not found on PATH; skip (run after opening a new shell with mise activate)."
  fi
else
  output_message "mise not found. Skipping toolchain update (run run_once_after_prereqs or brew install mise)."
fi

# Check if brew is available before updating
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

# Update oh-my-zsh
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

output_message "Setup completed successfully! (You can run apps.sh now; tests: ./scripts/test.sh)"
