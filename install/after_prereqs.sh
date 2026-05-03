#!/bin/bash
set -euo pipefail
# Implementation for chezmoi run_once (invoked via repo-root run_once_after_prereqs.sh).

# Function to display messages with separators
output_message() {
    echo "======================================="
    echo "$1"
    echo "======================================="
}

# Early return if root user (brew install errors out on root). Must run before
# REPO_ROOT/HAS_APT so stub-isolated tests (minimal PATH) never hit 127 first.
if [ "$(id -u)" -eq 0 ]; then
    echo "Rerun as non root."
    exit 1
fi

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC2034
export MISE_CONFIG_FILE="${REPO_ROOT}/dot_mise.toml"

HAS_APT=0
if [ "${DOTFILES_DISABLE_APT:-0}" != "1" ] && command -v apt >/dev/null 2>&1; then
    HAS_APT=1
fi

### Essentials
if [ "${HAS_APT}" -eq 1 ]; then
    # Update packages
    output_message "Updating apt packages..."
    sudo apt update && sudo apt upgrade -y

    output_message "Installing apt dependencies (shell & general dev)..."
    sudo apt install -y \
      build-essential \
      libffi-dev \
      libssl-dev \
      python3-dev \
      zlib1g-dev \
      libbz2-dev \
      libreadline-dev \
      libsqlite3-dev \
      curl \
      git \
      wget \
      zsh

    # mise / asdf-php: compiles PHP (e.g. 8.4.x) from source. Global flags use libxml, gd, intl,
    # pdo_pgsql, zip, onig, etc. Linux branch also passes --with-gettext; buildconf wants autotools;
    # plocate fixes `locate` (used to find libjpeg/libpng paths). ext/sodium needs libsodium-dev.
    # https://github.com/asdf-community/asdf-php/issues/202
    output_message "Installing apt dependencies for PHP source builds (mise / asdf-php)..."
    sudo apt install -y \
      autoconf \
      automake \
      libtool \
      pkg-config \
      bison \
      re2c \
      gettext \
      plocate \
      libxml2-dev \
      libcurl4-openssl-dev \
      libgd-dev \
      libicu-dev \
      libonig-dev \
      libpq-dev \
      libsodium-dev \
      libzip-dev
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
    if command -v bash >/dev/null 2>&1; then
        curl -fsSL https://bun.com/install | bash
    else
        echo "bash not found; cannot install bun." >&2
        exit 1
    fi
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
# shellcheck source=mise_install_env.sh
_script_dir="${BASH_SOURCE[0]%/*}"
source "${_script_dir}/mise_install_env.sh"
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
    # RUNZSH flag for unattended installation (/bin/bash portable on Linux + macOS CI)
    RUNZSH=no /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

    # Ensure install dir exists (stubbed curl output does not create ~/.oh-my-zsh)
    mkdir -p "$HOME/.oh-my-zsh"

    # set zsh as default shell
    if [ -r /proc/version ] && command -v grep >/dev/null 2>&1 && grep -qi microsoft /proc/version; then
        # WSL detected - add to shell profile instead of chsh
        if [ -f "$HOME/.bashrc" ] && ! grep -qxF "exec zsh" "$HOME/.bashrc"; then
            echo "exec zsh" >> "$HOME/.bashrc"
        fi
    else
        if command -v chsh >/dev/null 2>&1; then
            chsh -s "$(command -v zsh)"
        fi
    fi
fi

output_message "Bye! (Run source ~/.profile to apply changes)"
