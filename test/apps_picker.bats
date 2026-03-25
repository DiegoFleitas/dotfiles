#!/usr/bin/env bats

load 'helpers/common.bash'

setup() {
  REPO_ROOT="$(repo_root)"
  APPS_SCRIPT="${REPO_ROOT}/apps.sh"
}

@test "apps.sh supports dry-run (safe for CI)" {
  run bash "${APPS_SCRIPT}" --dry-run <<< $'done\n'
  [ "$status" -eq 0 ]
  [[ "$output" == *"DRY RUN"* || "$output" == *"No applications selected. Exiting."* ]]
}

@test "picker toggles multiple selections and installs only selected (dry-run)" {
  # apps.conf order (non-comment lines):
  # 1 firefox
  # 2 google-chrome
  # 3 slack
  # ...
  run env APPS_DRY_RUN=1 bash "${APPS_SCRIPT}" <<< $'1 3\ndone\n'
  [ "$status" -eq 0 ]

  [[ "$output" == *"DRY RUN: would install firefox"* ]]
  [[ "$output" == *"DRY RUN: would install slack"* ]]
  [[ "$output" != *"DRY RUN: would install google-chrome"* ]]
}

@test "picker default is none selected (done exits without installing)" {
  run env APPS_DRY_RUN=1 bash "${APPS_SCRIPT}" <<< $'done\n'
  [ "$status" -eq 0 ]
  [[ "$output" == *"No applications selected. Exiting."* ]]
}

