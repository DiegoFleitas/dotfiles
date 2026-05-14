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

# Non-fatal summary for end of install scripts (safe under set -e callers).
dotfiles_print_install_overview() {
  local nvm_dir bun_install line

  echo "======================================="
  echo "Install overview (versions)"
  echo "======================================="
  line="$(uname -srm 2>/dev/null)" || line="unknown"
  printf 'OS: %s\n' "${line}"

  if command -v git >/dev/null 2>&1; then
    git --version 2>/dev/null || printf '%s\n' "git: (version failed)"
  else
    printf '%s\n' "git: not found"
  fi

  if command -v zsh >/dev/null 2>&1; then
    zsh --version 2>/dev/null || printf '%s\n' "zsh: (version failed)"
  else
    printf '%s\n' "zsh: not found"
  fi

  if command -v brew >/dev/null 2>&1; then
    line="$(brew --version 2>/dev/null)" || line=""
    if [ -n "${line}" ]; then
      printf '%s\n' "${line%%$'\n'*}"
    else
      printf '%s\n' "brew: (version failed)"
    fi
  else
    printf '%s\n' "brew: not on PATH"
  fi

  bun_install="${BUN_INSTALL:-$HOME/.bun}"
  if [ -x "${bun_install}/bin/bun" ]; then
    printf 'bun: %s\n' "$("${bun_install}/bin/bun" --version 2>/dev/null || echo "(version failed)")"
  elif command -v bun >/dev/null 2>&1; then
    printf 'bun: %s\n' "$(bun --version 2>/dev/null || echo "(version failed)")"
  else
    printf '%s\n' "bun: not found"
  fi

  nvm_dir="$(dotfiles_resolve_nvm_dir)"
  if [ -n "${nvm_dir}" ] && [ -s "${nvm_dir}/nvm.sh" ]; then
    (
      export NVM_DIR="${nvm_dir}"
      # shellcheck disable=SC1091
      . "${NVM_DIR}/nvm.sh" 2>/dev/null || true
      if command -v nvm >/dev/null 2>&1; then
        line="$(nvm --version 2>/dev/null)" || line=""
        if [ -n "${line}" ]; then
          printf 'nvm: %s\n' "${line}"
        else
          printf '%s\n' "nvm: (version failed)"
        fi
      else
        printf '%s\n' "nvm: nvm.sh present (function unavailable in this subshell)"
      fi
      if command -v node >/dev/null 2>&1; then
        printf 'node: %s\n' "$(node -v 2>/dev/null || echo "(version failed)")"
        printf 'npm: %s\n' "$(npm -v 2>/dev/null || echo "(version failed)")"
        if command -v corepack >/dev/null 2>&1; then
          printf 'corepack: %s\n' "$(corepack --version 2>/dev/null || echo "(version failed)")"
        else
          printf '%s\n' "corepack: not on PATH"
        fi
      else
        printf '%s\n' "node: not installed yet (finalize installs default from dot_nvmrc / NODE_VERSION)"
      fi
    ) || true
  else
    printf '%s\n' "nvm: nvm.sh not found"
  fi

  if command -v flyctl >/dev/null 2>&1; then
    line="$(flyctl version 2>/dev/null)" || line=""
    [ -n "${line}" ] && printf 'flyctl: %s\n' "${line%%$'\n'*}"
  elif command -v fly >/dev/null 2>&1; then
    line="$(fly version 2>/dev/null)" || line=""
    [ -n "${line}" ] && printf 'fly: %s\n' "${line%%$'\n'*}"
  fi
  echo "======================================="
}

# Skip brew/nvm/Corepack/omz maintenance in before_finalize for minimal profile.
dotfiles_skip_finalize_tooling_maintenance() {
  dotfiles_is_minimal_codespace
}
