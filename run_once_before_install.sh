#!/bin/bash
# This script, run_once_before_install.sh, is intended to be executed by chezmoi
# before the actual dotfiles installation process begins. Chezmoi will manage the
# execution of this script to ensure necessary setup or pre-requisites are handled.

# set -x  # This will bash print each command before executing it.

# Function to display messages with separators
output_message() {
    echo "======================================="
    echo "$1"
    echo "======================================="
}

# Early return if root user (brew install errors out on root)
if [ $(id -u) -eq 0 ]; then
   output_message "Rerun as non root."
   exit 1
fi

### Essentials
# Update packages
output_message "Updating packages..."
sudo apt update && sudo apt upgrade -y

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

# Install zsh via Homebrew if not already installed
if ! command -v zsh &> /dev/null; then
    output_message "Installing zsh via Homebrew..."
    brew install zsh
fi

### Development tools
# Install nvm if not already installed
if ! command -v nvm &> /dev/null; then
    output_message "Installing nvm..."
    sh -c "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash"
fi

# Install brew packages
output_message "Installing brew packages..."
brew bundle --file=~/.local/share/chezmoi/Brewfile

# Install oh-my-zsh if not already installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    output_message "Installing oh-my-zsh..."
    # RUNZSH flag for unattended installation
    RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    # set zsh as default shell
    chsh -s $(which zsh)
fi

output_message "Bye!" (Run source ~/.profile to apply changes)
