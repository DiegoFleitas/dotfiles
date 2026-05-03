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

@test "dot_gitconfig template sets core init pull push defaults" {
  run grep -F "[core]" "${TARGET_FILE}"
  [ "$status" -eq 0 ]
  run grep -F 'editor = vim' "${TARGET_FILE}"
  [ "$status" -eq 0 ]
  run grep -F "[init]" "${TARGET_FILE}"
  [ "$status" -eq 0 ]
  run grep -F 'defaultBranch = main' "${TARGET_FILE}"
  [ "$status" -eq 0 ]
  run grep -F "[pull]" "${TARGET_FILE}"
  [ "$status" -eq 0 ]
  run grep -F "[push]" "${TARGET_FILE}"
  [ "$status" -eq 0 ]
  run grep -F 'autoSetupRemote = true' "${TARGET_FILE}"
  [ "$status" -eq 0 ]
}

@test "dot_gitconfig optional signing blocks reference signingKey" {
  run grep -F 'signingKey' "${TARGET_FILE}"
  [ "$status" -eq 0 ]
  run grep -F 'gpgsign = true' "${TARGET_FILE}"
  [ "$status" -eq 0 ]
}
