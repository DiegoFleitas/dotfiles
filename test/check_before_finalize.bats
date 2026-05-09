#!/usr/bin/env bats

load 'helpers/common.bash'

setup() {
  REPO_ROOT="$(repo_root)"
  TARGET_FILE="${REPO_ROOT}/install/before_finalize.sh"
}

@test "before_finalize sources versions.env and defaults version variables" {
  run grep -F '[ -f "${REPO_ROOT}/versions.env" ] && . "${REPO_ROOT}/versions.env"' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F ': "${NODE_VERSION:=22}"' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F ': "${PYTHON_VERSION:=3.12}"' "${TARGET_FILE}"
  [ "$status" -eq 0 ]
}

@test "before_finalize uses centralized Node and Python values" {
  run grep -F 'nvm install "${NODE_VERSION}" && nvm alias default "${NODE_VERSION}"' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F 'pyenv versions --bare | grep -Eq "^${PYTHON_VERSION}(\\.|$)"' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F 'pyenv install "${PYTHON_VERSION}"' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F 'DOTFILES_PYTHON_REFRESH' "${TARGET_FILE}"
  [ "$status" -eq 0 ]
}

@test "before_finalize runs in strict mode and has WSL guard for chsh" {
  run grep -F 'set -euo pipefail' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F 'is_wsl() {' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F 'WSL detected. Skipping chsh to avoid interactive prompts.' "${TARGET_FILE}"
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

@test "before_finalize gates toolchain blocks on DOTFILES_INSTALL_MISE with default 1" {
  run grep -F '[ "${DOTFILES_INSTALL_MISE:-1}" = "1" ]' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F 'Skipping toolchain update (DOTFILES_INSTALL_MISE=0).' "${TARGET_FILE}"
  [ "$status" -eq 0 ]
}
