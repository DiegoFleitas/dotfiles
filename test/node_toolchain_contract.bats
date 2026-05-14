#!/usr/bin/env bats

load 'helpers/common.bash'

setup() {
  REPO_ROOT="$(repo_root)"
}

@test "dot_nvmrc pin matches Node line in README" {
  local pin
  pin="$(tr -d '[:space:]' < "${REPO_ROOT}/dot_nvmrc")"
  [ -n "${pin}" ]

  run grep -Fq "Node ${pin}" "${REPO_ROOT}/README.md"
  [ "$status" -eq 0 ]

  run grep -Fq "Node.js-${pin}" "${REPO_ROOT}/README.md"
  [ "$status" -eq 0 ]
}
