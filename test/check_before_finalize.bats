#!/usr/bin/env bats

load 'helpers/common.bash'

setup() {
  REPO_ROOT="$(repo_root)"
  TARGET_FILE="${REPO_ROOT}/install/before_finalize.sh"
}

@test "before_finalize defaults NODE_VERSION when not set" {
  run grep -F ': "${NODE_VERSION:=24}"' "${TARGET_FILE}"
  [ "$status" -eq 0 ]
}

@test "before_finalize uses nvm plus Corepack when nvm is enabled" {
  run grep -F 'nvm install "${NODE_VERSION}" && nvm alias default "${NODE_VERSION}"' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F 'corepack enable' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F 'dotfiles_resolve_nvm_dir' "${TARGET_FILE}"
  [ "$status" -eq 0 ]
}

@test "before_finalize runs in strict mode and has WSL guard for chsh" {
  run grep -F 'set -euo pipefail' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F 'is_wsl() {' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F 'WSL detected. Skipping chsh to avoid interactive prompts.' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F 'CODESPACE_NAME' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F 'GitHub Codespaces detected. Skipping chsh' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F 'command -v chsh >/dev/null 2>&1' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F 'chsh not found. Skipping default shell change.' "${TARGET_FILE}"
  [ "$status" -eq 0 ]
}

@test "before_finalize avoids implicit brew upgrades unless explicitly enabled" {
  run grep -F 'if [ "${DOTFILES_BREW_UPGRADE:-0}" = "1" ]; then' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F 'Skipping brew upgrade by default (set DOTFILES_BREW_UPGRADE=1 to enable).' "${TARGET_FILE}"
  [ "$status" -eq 0 ]
}

@test "before_finalize updates oh-my-zsh without user shell rc side effects" {
  run grep -F 'zsh -f -c' "${TARGET_FILE}"
  [ "$status" -eq 0 ]
}

@test "before_finalize includes canonical test runner hint" {
  run grep -F 'tests: ./scripts/test.sh' "${TARGET_FILE}"
  [ "$status" -eq 0 ]
}

@test "before_finalize gates brew and oh-my-zsh updates on DOTFILES_INSTALL_* with default 1" {
  run grep -F '[ "${DOTFILES_INSTALL_BREW:-1}" = "1" ]' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F '[ "${DOTFILES_INSTALL_OHMYZSH:-1}" = "1" ]' "${TARGET_FILE}"
  [ "$status" -eq 0 ]
}

@test "before_finalize gates toolchain blocks on DOTFILES_INSTALL_NVM with default 1" {
  run grep -F '[ "${DOTFILES_INSTALL_NVM:-1}" = "1" ]' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F 'Skipping toolchain update (DOTFILES_INSTALL_NVM=0).' "${TARGET_FILE}"
  [ "$status" -eq 0 ]
}

@test "before_finalize skips brew nvm Corepack omz maintenance on Codespaces minimal profile" {
  run grep -F '. "${SCRIPT_DIR}/codespaces.sh"' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F 'Skipping Homebrew update (Codespaces minimal profile).' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F 'Skipping oh-my-zsh update (Codespaces minimal profile).' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F 'Skipping nvm/Corepack update (Codespaces minimal profile).' "${TARGET_FILE}"
  [ "$status" -eq 0 ]
}
