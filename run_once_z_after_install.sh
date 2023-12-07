#!/bin/bash

# Attempt to set default shell to zsh if not already set
if [ "$SHELL" != "/usr/bin/zsh" ]; then
  chsh -s "/usr/bin/zsh"
fi

# Exec zsh if in a bash session, which is the default for chezmoi
if [ -z "$ZSH_VERSION" ]; then
    exec zsh
fi

# Any other final setup steps can be added here