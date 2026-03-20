#!/usr/bin/env bats

load 'helpers/common.bash'

setup() {
  REPO_ROOT="$(repo_root)"
  DOT_NVMRC_BACKUP=""
}

teardown() {
  if [ -n "${DOT_NVMRC_BACKUP}" ] && [ -f "${DOT_NVMRC_BACKUP}" ]; then
    restore_file "${DOT_NVMRC_BACKUP}" "${REPO_ROOT}/dot_nvmrc"
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
