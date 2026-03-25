#!/bin/bash
# This script runs at the start of chezmoi apply (run_after_): system deps, brew, nvm, oh-my-zsh, pyenv.

# set -x  # This will bash print each command before executing it.

# Function to display messages with separators
output_message() {
    echo "======================================="
    echo "$1"
    echo "======================================="
}

# Load centralized tool versions
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
[ -f "${SCRIPT_DIR}/versions.env" ] && . "${SCRIPT_DIR}/versions.env"
: "${NODE_VERSION:=22}"
: "${PYTHON_VERSION:=3.12}"
: "${PHP_VERSION:=8.5}"
: "${NVM_INSTALL_VERSION:=v0.40.3}"

if [ "$(uname -s)" = "Linux" ] && command -v apt >/dev/null 2>&1; then
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

# Add brew to user's path.
if [ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [ -x "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x "/usr/local/bin/brew" ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

### Development tools
# nvm is a shell function loaded from nvm.sh, not a PATH binary; in non-interactive
# scripts (e.g. chezmoi) the usual executable lookup does not see it, so we test nvm.sh on disk.
NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
export NVM_DIR
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
    output_message "Installing nvm..."
    sh -c "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_INSTALL_VERSION}/install.sh | bash"
fi

# Install brew packages
output_message "Installing brew packages..."
# Use Brewfile from chezmoi directory or fall back to this one
brew bundle --file="${HOME}/.local/share/chezmoi/Brewfile" 2>/dev/null || brew bundle

# Install oh-my-zsh if not already installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    output_message "Installing oh-my-zsh..."
    # RUNZSH flag for unattended installation
    RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    # set zsh as default shell
    if grep -qi microsoft /proc/version; then
        # WSL detected - add to shell profile instead of chsh
        if [ -f "$HOME/.bashrc" ] && ! grep -qxF "exec zsh" "$HOME/.bashrc"; then
            echo "exec zsh" >> "$HOME/.bashrc"
        fi
    else
        chsh -s "$(which zsh)"
    fi
fi

# Install pyenv if not already installed
if ! command -v pyenv &> /dev/null; then
    output_message "Installing pyenv..."
    brew install pyenv
fi

# Setup python environment
if ! pyenv versions | grep -q "${PYTHON_VERSION}"; then
    output_message "Installing Python ${PYTHON_VERSION}..."
    pyenv install "${PYTHON_VERSION}"
    output_message "Setting global Python version to ${PYTHON_VERSION}..."
    pyenv global "${PYTHON_VERSION}"
fi

if command -v python3 &> /dev/null; then
    output_message "Python ${PYTHON_VERSION} installed successfully."
else
    output_message "Python installation failed."
fi

output_message "Bye! (Run source ~/.profile to apply changes)"
