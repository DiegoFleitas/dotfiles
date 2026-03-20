#!/usr/bin/env bats

load 'helpers/common.bash'

setup() {
  REPO_ROOT="$(repo_root)"
  TARGET_FILE="${REPO_ROOT}/bootstrap.sh"
  FINALIZE_FILE="${REPO_ROOT}/run_once_before_finalize.sh"
  TEST_RUNNER_FILE="${REPO_ROOT}/scripts/test.sh"
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

@test "finalize script keeps WSL path non-interactive" {
  run grep -F 'if is_wsl; then' "${FINALIZE_FILE}"
  [ "$status" -eq 0 ]

  run grep -F 'WSL detected. Skipping chsh to avoid interactive prompts.' "${FINALIZE_FILE}"
  [ "$status" -eq 0 ]
}

@test "repo has no legacy finalize.bats or /tmp helper paths" {
  run rg -n 'finalize\.bats|/tmp/helpers/common\.bash' \
    "${REPO_ROOT}/.chezmoi.toml.tmpl" \
    "${REPO_ROOT}/run_once_after_prereqs.sh" \
    "${REPO_ROOT}/run_once_before_finalize.sh" \
    "${REPO_ROOT}/scripts/test.sh"
  [ "$status" -ne 0 ]

  run rg -n '/tmp/helpers/common\.bash' "${REPO_ROOT}/test"
  [ "$status" -ne 0 ]
}

@test "canonical test runner remains scripts/test.sh to bats test" {
  run grep -F 'exec bats test/' "${TEST_RUNNER_FILE}"
  [ "$status" -eq 0 ]
}
