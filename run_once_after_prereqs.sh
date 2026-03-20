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
: "${NVM_INSTALL_VERSION:=v0.40.3}"

# Early return if root user (brew install errors out on root)
if [ "$(id -u)" -eq 0 ]; then
   output_message "Rerun as non root."
   exit 1
fi

### Essentials
# Update packages
output_message "Updating packages..."
sudo apt update && sudo apt upgrade -y

# Install build essentials and required dependencies
output_message "Installing build essentials and dependencies..."
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

# Install git if not already installed
# (I usually install git manually, but this is here just in case)
if ! command -v git &> /dev/null; then
    output_message "Installing git..."
    sudo apt install git -y
fi

# Install curl if not already installed
if ! command -v curl &> /dev/null; then
    output_message "Installing curl..."
    sudo apt install curl -y
fi

# Install Homebrew if not already installed
if ! command -v brew &> /dev/null; then
    output_message "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Add brew to user's path if it's not already added.
BREW_PATH="/home/linuxbrew/.linuxbrew/bin"
eval "$($BREW_PATH/brew shellenv)"

### Development tools
# Install nvm if not already installed
if ! command -v nvm &> /dev/null; then
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
        echo "exec zsh" >> ~/.bashrc
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
