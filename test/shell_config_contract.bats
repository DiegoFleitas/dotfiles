#!/usr/bin/env bats

load 'helpers/common.bash'

setup() {
  REPO_ROOT="$(repo_root)"
}

@test "shell configs try command -v brew before linuxbrew fallback" {
  local line_cmd line_linux
  for f in dot_zshrc dot_bashrc dot_profile; do
    line_cmd="$(grep -n 'command -v brew' "${REPO_ROOT}/${f}" | head -1 | cut -d: -f1)"
    line_linux="$(grep -n 'home/linuxbrew/.linuxbrew/bin/brew' "${REPO_ROOT}/${f}" | head -1 | cut -d: -f1)"
    [ -n "${line_cmd}" ]
    [ -n "${line_linux}" ]
    [ "${line_cmd}" -lt "${line_linux}" ]
  done
}

@test "shell configs use portable Homebrew resolution (command -v brew or known paths)" {
  for f in dot_zshrc dot_bashrc dot_profile; do
    run grep -F 'command -v brew' "${REPO_ROOT}/${f}"
    [ "$status" -eq 0 ]
    run grep -F '/opt/homebrew/bin/brew' "${REPO_ROOT}/${f}"
    [ "$status" -eq 0 ]
  done
}

@test "dot_zshrc and dot_bashrc use mise activate without nvm or pyenv init" {
  run grep -F 'mise activate' "${REPO_ROOT}/dot_zshrc"
  [ "$status" -eq 0 ]
  run grep -F 'mise activate' "${REPO_ROOT}/dot_bashrc"
  [ "$status" -eq 0 ]
  run grep -F 'NVM_DIR' "${REPO_ROOT}/dot_zshrc"
  [ "$status" -ne 0 ]
  run grep -F 'pyenv init' "${REPO_ROOT}/dot_zshrc"
  [ "$status" -ne 0 ]
  run grep -F 'NVM_DIR' "${REPO_ROOT}/dot_bashrc"
  [ "$status" -ne 0 ]
  run grep -F 'pyenv init' "${REPO_ROOT}/dot_bashrc"
  [ "$status" -ne 0 ]
}
