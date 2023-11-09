#!/bin/sh

# Switch to zsh if it's not already the current shell
if [ "$SHELL" != "$(which zsh)" ]; then
  chsh -s "$(which zsh)"
fi

# Any other final setup steps can be added here
