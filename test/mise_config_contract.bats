#!/usr/bin/env bats

load 'helpers/common.bash'

setup() {
  REPO_ROOT="$(repo_root)"
}

@test "dot_mise.toml exists and declares node python php tools" {
  local f="${REPO_ROOT}/dot_mise.toml"
  [ -f "${f}" ]
  run grep -E '^\[tools\]' "${f}"
  [ "$status" -eq 0 ]
  run grep -E '^node\s*=' "${f}"
  [ "$status" -eq 0 ]
  run grep -E '^python\s*=' "${f}"
  [ "$status" -eq 0 ]
  run grep -E '^php\s*=' "${f}"
  [ "$status" -eq 0 ]
}

@test "dot_mise.toml tool pins are non-empty quoted strings" {
  local f="${REPO_ROOT}/dot_mise.toml"
  run grep -E '^node\s*=\s*"[^"]+"' "${f}"
  [ "$status" -eq 0 ]
  run grep -E '^python\s*=\s*"[0-9.]+"' "${f}"
  [ "$status" -eq 0 ]
  run grep -E '^php\s*=\s*"[0-9.]+"' "${f}"
  [ "$status" -eq 0 ]
}
