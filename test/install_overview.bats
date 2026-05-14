#!/usr/bin/env bats

load 'helpers/common.bash'

setup() {
  REPO_ROOT="$(repo_root)"
}

@test "dotfiles_print_install_overview exits 0 and prints banner (set -e safe)" {
  run env HOME="${HOME:-/tmp}" PATH="/usr/bin:/bin" /bin/bash -c '
    set -euo pipefail
    SCRIPT_DIR="'"${REPO_ROOT}"'/install"
    # shellcheck disable=SC1091
    . "${SCRIPT_DIR}/codespaces.sh"
    dotfiles_print_install_overview'
  [ "$status" -eq 0 ]
  [[ "$output" == *"Install overview (versions)"* ]]
  [[ "$output" == *"OS:"* ]]
}
