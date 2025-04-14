#!/bin/bash

# Add zsh to /etc/shells if it's not already there
# This is necessary because chsh only accepts shells listed in /etc/shells.
if ! grep -q "$(which zsh)" /etc/shells; then
  echo "$(which zsh)" | sudo tee -a /etc/shells
fi

# Attempt to set default shell to zsh if not already set
if [ "$SHELL" != "$(which zsh)" ]; then
  chsh -s $(which zsh)
fi

# Exec zsh if in a bash session, which is the default for chezmoi
if [ -z "$ZSH_VERSION" ]; then
  exec zsh
fi

# Update nvm to the latest version
output_message "Updating nvm to the latest version..."
nvm install --lts && nvm alias default lts

# Update Homebrew and its packages
output_message "Updating Homebrew and its packages..."
brew update && brew upgrade

# Update oh-my-zsh
output_message "Updating oh-my-zsh..."
if [ -d "$HOME/.oh-my-zsh" ]; then
    zsh -ic "omz update"
fi

# Update pyenv and Python versions
output_message "Updating pyenv and Python versions..."
brew upgrade pyenv
if pyenv versions | grep -q "3.10.9"; then
    output_message "Updating Python 3.10.9..."
    pyenv install --skip-existing 3.10.9
fi

# Any other final setup steps...
