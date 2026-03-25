#!/usr/bin/env bats

load 'helpers/common.bash'

setup() {
  REPO_ROOT="$(repo_root)"
  TARGET_FILE="${REPO_ROOT}/dot_gitconfig.tmpl"
}

@test "dot_gitconfig template has quoted email and name fields" {
  [ -f "${TARGET_FILE}" ]

  run grep -F "[user]" "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F 'email = {{ $email | quote }}' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F 'name = {{ $name | quote }}' "${TARGET_FILE}"
  [ "$status" -eq 0 ]
}
