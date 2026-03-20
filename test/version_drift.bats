#!/usr/bin/env bats

load 'helpers/common.bash'

setup() {
  REPO_ROOT="$(repo_root)"
  DOT_NVMRC_BACKUP=""
  VERSIONS_ENV_BACKUP=""
}

teardown() {
  if [ -n "${DOT_NVMRC_BACKUP}" ] && [ -f "${DOT_NVMRC_BACKUP}" ]; then
    restore_file "${DOT_NVMRC_BACKUP}" "${REPO_ROOT}/dot_nvmrc"
  fi
  if [ -n "${VERSIONS_ENV_BACKUP}" ] && [ -f "${VERSIONS_ENV_BACKUP}" ]; then
    restore_file "${VERSIONS_ENV_BACKUP}" "${REPO_ROOT}/versions.env"
  fi
}

@test "version drift check passes with current repository state" {
  run bash "${REPO_ROOT}/scripts/check-version-drift.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Version drift check passed."* ]]
}

@test "version drift check fails when dot_nvmrc mismatches versions.env" {
  local dot_nvmrc="${REPO_ROOT}/dot_nvmrc"
  DOT_NVMRC_BACKUP="$(mktemp)"

  backup_file "${dot_nvmrc}" "${DOT_NVMRC_BACKUP}"
  printf '%s\n' "999" > "${dot_nvmrc}"

  run bash "${REPO_ROOT}/scripts/check-version-drift.sh"
  [ "$status" -ne 0 ]
  [[ "$output" == *"dot_nvmrc (999) != NODE_VERSION"* ]]

  restore_file "${DOT_NVMRC_BACKUP}" "${dot_nvmrc}"
  DOT_NVMRC_BACKUP=""
}

@test "version drift check fails when versions.env is missing" {
  local versions_env="${REPO_ROOT}/versions.env"
  VERSIONS_ENV_BACKUP="$(mktemp)"

  backup_file "${versions_env}" "${VERSIONS_ENV_BACKUP}"
  rm -f "${versions_env}"

  run bash "${REPO_ROOT}/scripts/check-version-drift.sh"
  [ "$status" -ne 0 ]
  [[ "$output" == *"missing versions.env"* ]]

  restore_file "${VERSIONS_ENV_BACKUP}" "${versions_env}"
  VERSIONS_ENV_BACKUP=""
}
