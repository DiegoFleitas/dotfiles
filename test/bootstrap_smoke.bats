#!/usr/bin/env bats

load 'helpers/common.bash'

setup() {
  REPO_ROOT="$(repo_root)"
  TARGET_FILE="${REPO_ROOT}/bootstrap.sh"
  FINALIZE_FILE="${REPO_ROOT}/run_once_before_finalize.sh"
}

@test "bootstrap script exists and uses chezmoi init apply" {
  [ -f "${TARGET_FILE}" ]

  run grep -F '#!/bin/sh' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F 'get.chezmoi.io' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F 'init --apply DiegoFleitas' "${TARGET_FILE}"
  [ "$status" -eq 0 ]
}

@test "finalize script keeps WSL path non-interactive" {
  run grep -F 'if is_wsl; then' "${FINALIZE_FILE}"
  [ "$status" -eq 0 ]

  run grep -F 'WSL detected. Skipping chsh to avoid interactive prompts.' "${FINALIZE_FILE}"
  [ "$status" -eq 0 ]
}
