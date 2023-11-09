#!/bin/sh

# Set default shell to zsh
sudo chsh "$(id -un)" --shell "/usr/bin/zsh"

# Switch to zsh for the current session
if [ -n "$ZSH_VERSION" ]; then
    exec zsh
fi

# Any other final setup steps can be added here
