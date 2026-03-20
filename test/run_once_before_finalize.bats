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
