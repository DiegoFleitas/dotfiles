#!/bin/sh
# GitHub Codespaces tries install.sh before `install` and bootstrap.sh.
# This repo has a directory `install/` for chezmoi hook scripts; without this file,
# Codespaces runs ./install, hits the directory, and fails with "Permission denied".
ROOT="$(dirname "$0")"
ROOT="$(cd "$ROOT" && pwd)"
exec "$ROOT/bootstrap.sh" "$@"
