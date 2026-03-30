#!/usr/bin/env bats

load 'helpers/common.bash'

setup() {
  REPO_ROOT="$(repo_root)"
  TARGET_FILE="${REPO_ROOT}/run_once_after_prereqs.sh"
}

@test "after_prereqs sources versions.env and defaults version variables" {
  run grep -F '[ -f "${SCRIPT_DIR}/versions.env" ] && . "${SCRIPT_DIR}/versions.env"' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F ': "${PYTHON_VERSION:=3.12}"' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F ': "${PHP_VERSION:=8.5}"' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F ': "${NVM_INSTALL_VERSION:=v0.40.3}"' "${TARGET_FILE}"
  [ "$status" -eq 0 ]
}

@test "after_prereqs installs nvm only when nvm.sh is missing on disk" {
  run grep -F 'NVM_DIR="${NVM_DIR:-$HOME/.nvm}"' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F '[ ! -s "$NVM_DIR/nvm.sh" ]' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F 'command -v nvm' "${TARGET_FILE}"
  [ "$status" -ne 0 ]
}

@test "after_prereqs uses centralized installer and python values" {
  run grep -F 'nvm-sh/nvm/${NVM_INSTALL_VERSION}/install.sh' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F 'pyenv install "${PYTHON_VERSION}"' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F 'pyenv global "${PYTHON_VERSION}"' "${TARGET_FILE}"
  [ "$status" -eq 0 ]
}

@test "after_prereqs runs brew bundle (installs Brewfile packages e.g. php, composer)" {
  run grep -F 'brew bundle --file="${HOME}/.local/share/chezmoi/Brewfile"' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F '|| brew bundle' "${TARGET_FILE}"
  [ "$status" -eq 0 ]
}

@test "after_prereqs can install flyctl when DOTFILES_INSTALL_FLYCTL=1" {
  run grep -F 'DOTFILES_INSTALL_FLYCTL' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F 'brew install flyctl' "${TARGET_FILE}"
  [ "$status" -eq 0 ]
}

@test "after_prereqs flyctl opt-in defaults DOTFILES_INSTALL_FLYCTL to 0" {
  run grep -F '${DOTFILES_INSTALL_FLYCTL:-0}' "${TARGET_FILE}"
  [ "$status" -eq 0 ]
}

@test "after_prereqs runs brew bundle before optional flyctl install" {
  bundle_line="$(grep -n 'brew bundle --file="${HOME}/.local/share/chezmoi/Brewfile"' "${TARGET_FILE}" | head -1 | cut -d: -f1)"
  fly_line="$(grep -n 'brew install flyctl' "${TARGET_FILE}" | head -1 | cut -d: -f1)"
  [ -n "${bundle_line}" ]
  [ -n "${fly_line}" ]
  [ "${bundle_line}" -lt "${fly_line}" ]
}

@test "after_prereqs flyctl block skips install when fly or flyctl exists" {
  run grep -F 'command -v fly' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F 'Fly CLI already installed; skipping flyctl.' "${TARGET_FILE}"
  [ "$status" -eq 0 ]
}

@test "after_prereqs flyctl block skips when brew missing" {
  run grep -F 'DOTFILES_INSTALL_FLYCTL=1 but brew not found; skipping flyctl.' "${TARGET_FILE}"
  [ "$status" -eq 0 ]
}
