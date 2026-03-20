#!/usr/bin/env bats

load 'helpers/common.bash'

setup() {
  REPO_ROOT="$(repo_root)"
  TARGET_FILE="${REPO_ROOT}/run_once_before_finalize.sh"
}

@test "before_finalize sources versions.env and defaults version variables" {
  run grep -F '[ -f "${SCRIPT_DIR}/versions.env" ] && . "${SCRIPT_DIR}/versions.env"' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F ': "${NODE_VERSION:=22}"' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F ': "${PYTHON_VERSION:=3.12}"' "${TARGET_FILE}"
  [ "$status" -eq 0 ]
}

@test "before_finalize uses centralized Node and Python values" {
  run grep -F 'nvm install "${NODE_VERSION}" && nvm alias default "${NODE_VERSION}"' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F 'pyenv install --skip-existing "${PYTHON_VERSION}"' "${TARGET_FILE}"
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
