#!/usr/bin/env bats

load 'helpers/common.bash'

setup() {
  REPO_ROOT="$(repo_root)"
}

@test "dotfiles_default_node_version_from_nvmrc matches trimmed dot_nvmrc" {
  run env REPO_ROOT="${REPO_ROOT}" /bin/bash -c '
    set -euo pipefail
    SCRIPT_DIR="${REPO_ROOT}/install"
    # shellcheck disable=SC1091
    . "${SCRIPT_DIR}/codespaces.sh"
    dotfiles_default_node_version_from_nvmrc "${REPO_ROOT}"'
  [ "$status" -eq 0 ]
  expected="$(tr -d "[:space:]" < "${REPO_ROOT}/dot_nvmrc")"
  [ "$output" = "${expected}" ]
}
