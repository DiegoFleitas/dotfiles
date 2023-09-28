#!/bin/bash
# set -x  # This will bash print each command before executing it.

# Function to display messages with separators
output_message() {
    echo "======================================="
    echo "$1"
    echo "======================================="
}

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

export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

# Install brew packages
output_message "Installing brew packages..."
brew bundle # This installs chezmoi among other things (check Brewfile for details)

# Symlink dotfiles using chezmoi
output_message "Applying dotfiles with chezmoi..."
chezmoi apply --verbose

# Install oh-my-zsh if not already installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    output_message "Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

source ~/.zshrc

output_message "Dotfiles have been applied (chezmoi)."
output_message "Installation completed."
