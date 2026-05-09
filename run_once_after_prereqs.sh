#!/usr/bin/env bash
set -euo pipefail

: "${DOTFILES_INSTALL_APT:=1}"
: "${DOTFILES_INSTALL_BREW:=1}"
: "${DOTFILES_INSTALL_BUN:=1}"
: "${DOTFILES_INSTALL_MISE:=1}"
: "${DOTFILES_INSTALL_OHMYZSH:=1}"
: "${DOTFILES_INSTALL_FLYCTL:=0}"

export DOTFILES_INSTALL_APT
export DOTFILES_INSTALL_BREW
export DOTFILES_INSTALL_BUN
export DOTFILES_INSTALL_MISE
export DOTFILES_INSTALL_OHMYZSH
export DOTFILES_INSTALL_FLYCTL

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec /bin/bash -e "${SCRIPT_DIR}/install/after_prereqs.sh" "$@"
