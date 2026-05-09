#!/bin/sh
# GitHub Codespaces tries install.sh before `install` and bootstrap.sh.
# This repo has a directory `install/` for chezmoi hook scripts; without this file,
# Codespaces runs ./install, hits the directory, and fails with "Permission denied".
exec "$(CDPATH= cd -- "$(dirname "$0")" && pwd)/bootstrap.sh" "$@"
