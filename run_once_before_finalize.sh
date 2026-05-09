#!/usr/bin/env bash
set -euo pipefail

: "${DOTFILES_INSTALL_MISE:=1}"
: "${DOTFILES_INSTALL_BREW:=1}"
: "${DOTFILES_INSTALL_OHMYZSH:=1}"

export DOTFILES_INSTALL_MISE
export DOTFILES_INSTALL_BREW
export DOTFILES_INSTALL_OHMYZSH

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec /bin/bash -e "${SCRIPT_DIR}/install/before_finalize.sh" "$@"
