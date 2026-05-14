#!/usr/bin/env bash
# Shared helpers for GitHub Codespaces profiles (sourced by install/*.sh).
# Universal image layout: https://github.com/devcontainers/images

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

# First readable nvmrc wins: chezmoi source dot_nvmrc, then ~/.nvmrc after apply.
# Skips empty and # comment-only lines; strips inline comments after #. Fallback 24.
dotfiles_default_node_version_from_nvmrc() {
  local repo_root="${1:?}"
  local f line stripped
  for f in "${repo_root}/dot_nvmrc" "${HOME}/.nvmrc"; do
    [ -r "$f" ] || continue
    while IFS= read -r line || [ -n "$line" ]; do
      [[ "${line}" =~ ^[[:space:]]*# ]] && continue
      [[ "${line}" =~ ^[[:space:]]*$ ]] && continue
      stripped="${line%%#*}"
      stripped="${stripped#"${stripped%%[![:space:]]*}"}"
      stripped="${stripped%"${stripped##*[![:space:]]}"}"
      [ -n "${stripped}" ] || continue
      printf '%s\n' "$(printf '%s\n' "${stripped}" | tr -d '[:space:]')"
      return 0
    done <"${f}"
  done
  printf '%s\n' "24"
}

# Skip brew/nvm/Corepack/omz maintenance in before_finalize for minimal profile.
dotfiles_skip_finalize_tooling_maintenance() {
  dotfiles_is_minimal_codespace
}
