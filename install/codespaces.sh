#!/usr/bin/env bash
# Shared helpers for GitHub Codespaces profiles (sourced by install/*.sh).
# Universal image layout: https://github.com/devcontainers/images (setup-user links
# Node tooling under /home/codespace; nvm script often at /usr/local/share/nvm/nvm.sh).

dotfiles_is_codespace() {
  [ -n "${CODESPACE_NAME:-}" ]
}

# Prints minimal or full. Default on Codespaces when DOTFILES_CODESPACES_PROFILE is unset: minimal.
dotfiles_codespace_profile() {
  case "${DOTFILES_CODESPACES_PROFILE:-}" in
    minimal | full) printf '%s\n' "${DOTFILES_CODESPACES_PROFILE}" ;;
    *) dotfiles_is_codespace && printf '%s\n' minimal || printf '%s\n' full ;;
  esac
}

dotfiles_is_minimal_codespace() {
  dotfiles_is_codespace && [ "$(dotfiles_codespace_profile)" = "minimal" ]
}

# devcontainers universal: nvm at ~/.nvm or /usr/local/share/nvm.
dotfiles_nvm_sh_usable() {
  local d="${NVM_DIR:-$HOME/.nvm}"
  [ -s "${d}/nvm.sh" ] || [ -s /usr/local/share/nvm/nvm.sh ]
}

dotfiles_resolve_nvm_dir() {
  if [ -s "${HOME}/.nvm/nvm.sh" ]; then
    printf '%s\n' "${HOME}/.nvm"
  elif [ -s /usr/local/share/nvm/nvm.sh ]; then
    printf '%s\n' "/usr/local/share/nvm"
  else
    printf '%s\n' ""
  fi
}

# Skip brew/nvm/omz/pyenv maintenance in before_finalize for minimal profile.
dotfiles_skip_finalize_tooling_maintenance() {
  dotfiles_is_minimal_codespace
}
