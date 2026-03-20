#!/usr/bin/env bats

load 'helpers/common.bash'

setup() {
  REPO_ROOT="$(repo_root)"
  TARGET_FILE="${REPO_ROOT}/bootstrap.sh"
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
