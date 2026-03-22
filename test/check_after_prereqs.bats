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
