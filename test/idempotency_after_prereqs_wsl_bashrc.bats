#!/usr/bin/env bats

load 'helpers/common.bash'

setup() {
  REPO_ROOT="$(repo_root)"
  TARGET_FILE="${REPO_ROOT}/run_once_after_prereqs.sh"
}

@test "after_prereqs WSL bashrc append is idempotent" {
  # Static checks against the script implementation itself.
  # The guard should look for the exact line before appending.
  run grep -F 'grep -qxF "exec zsh" "$HOME/.bashrc"' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F 'echo "exec zsh" >> "$HOME/.bashrc"' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  # Ensure the legacy unconditional append doesn't exist anymore.
  run grep -F 'echo "exec zsh" >> ~/.bashrc' "${TARGET_FILE}"
  [ "$status" -ne 0 ]
}

