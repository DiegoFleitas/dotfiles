#!/bin/bash

# Define output_message function
output_message() {
  echo "===================================="
  echo "$1"
  echo "===================================="
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
if ! grep -q "$(which zsh)" /etc/shells; then
  echo "$(which zsh)" | sudo tee -a /etc/shells
  output_message "Added zsh to /etc/shells."
else
  output_message "Zsh is already in /etc/shells."
fi

# Attempt to set default shell to zsh if not already set
if [ "$SHELL" != "$(which zsh)" ]; then
  chsh -s $(which zsh)
  output_message "Default shell changed to Zsh. Please log out and log back in for changes to take effect."
fi

# Instead of exec zsh, run the remaining commands in the current shell
output_message "Continuing setup process..."

# Check if nvm is available before updating
if [ -f "$HOME/.nvm/nvm.sh" ]; then
  output_message "Loading and updating nvm..."
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
  nvm install 18 && nvm alias default 18
else
  output_message "nvm not found. Skipping nvm update."
fi

# Check if brew is available before updating
if command -v brew &> /dev/null; then
  output_message "Updating Homebrew and its packages..."
  brew update && brew upgrade
else
  output_message "Homebrew not found. Skipping Homebrew update."
fi

# Update oh-my-zsh
if [ -d "$HOME/.oh-my-zsh" ]; then
  output_message "Updating oh-my-zsh..."
  zsh -ic "omz update"
else
  output_message "oh-my-zsh not found. Skipping oh-my-zsh update."
fi

# Check if pyenv is available before updating
if command -v pyenv &> /dev/null; then
  output_message "Updating pyenv and Python versions..."
  brew upgrade pyenv
  if pyenv versions | grep -q "3.10.9"; then
    output_message "Updating Python 3.10.9..."
    pyenv install --skip-existing 3.10.9
  fi
else
  output_message "pyenv not found. Skipping pyenv update."
fi

output_message "Setup completed successfully!"