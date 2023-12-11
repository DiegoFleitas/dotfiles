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

# Any other final setup steps...
