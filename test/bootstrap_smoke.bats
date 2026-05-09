#!/usr/bin/env bats

load 'helpers/common.bash'

setup() {
  REPO_ROOT="$(repo_root)"
  TARGET_FILE="${REPO_ROOT}/bootstrap.sh"
  FINALIZE_FILE="${REPO_ROOT}/install/before_finalize.sh"
  TEST_RUNNER_FILE="${REPO_ROOT}/scripts/test.sh"
  BREWFILE="${REPO_ROOT}/Brewfile"
  CHEZMOI_TMPL="${REPO_ROOT}/.chezmoi.toml.tmpl"
  DOT_PROFILE="${REPO_ROOT}/dot_profile"
  DOT_ZSHRC="${REPO_ROOT}/dot_zshrc"
  DOT_BASHRC="${REPO_ROOT}/dot_bashrc"
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

@test "install.sh exists for Codespaces dotfiles order and delegates to bootstrap.sh" {
  INSTALL_SH="${REPO_ROOT}/install.sh"
  [ -f "${INSTALL_SH}" ]
  [ -x "${INSTALL_SH}" ]

  run grep -F 'bootstrap.sh' "${INSTALL_SH}"
  [ "$status" -eq 0 ]

  run grep -F 'exec ' "${INSTALL_SH}"
  [ "$status" -eq 0 ]
}

@test "finalize script keeps WSL path non-interactive" {
  run grep -F 'if is_wsl; then' "${FINALIZE_FILE}"
  [ "$status" -eq 0 ]

  run grep -F 'WSL detected. Skipping chsh to avoid interactive prompts.' "${FINALIZE_FILE}"
  [ "$status" -eq 0 ]
}

@test "repo has no legacy finalize.bats or /tmp helper paths" {
  run grep -nE 'finalize\.bats|/tmp/helpers/common\.bash' \
    "${REPO_ROOT}/.chezmoi.toml.tmpl" \
    "${REPO_ROOT}/run_once_after_010_prereqs.sh.tmpl" \
    "${REPO_ROOT}/run_once_after_090_finalize.sh.tmpl" \
    "${REPO_ROOT}/scripts/test.sh"
  [ "$status" -ne 0 ]

  run grep -RnF '/tmp/helpers/common.bash' "${REPO_ROOT}/test"  --exclude=bootstrap_smoke.bats
  [ "$status" -ne 0 ]
}

@test "canonical test runner remains scripts/test.sh (bats + pytest)" {
  run grep -F 'bats --jobs 1 test/' "${TEST_RUNNER_FILE}"
  [ "$status" -eq 0 ]
  run grep -F 'pytest test_python/' "${TEST_RUNNER_FILE}"
  [ "$status" -eq 0 ]
}

@test "Brewfile installs mise and composer via Homebrew but not bun" {
  [ -f "${BREWFILE}" ]

  run grep -F 'brew "mise"' "${BREWFILE}"
  [ "$status" -eq 0 ]

  run grep -F 'brew "composer"' "${BREWFILE}"
  [ "$status" -eq 0 ]

  run grep -F 'brew "bun"' "${BREWFILE}"
  [ "$status" -ne 0 ]
}

@test "chezmoi template separates brew bundle from bun curl installer" {
  [ -f "${CHEZMOI_TMPL}" ]

  run grep -F 'brew bundle (mise, composer' "${CHEZMOI_TMPL}"
  [ "$status" -eq 0 ]

  run grep -F 'bun (curl installer)' "${CHEZMOI_TMPL}"
  [ "$status" -eq 0 ]
}

@test "chezmoi template gates prompts on .chezmoi.interactive for Codespaces compatibility" {
  [ -f "${CHEZMOI_TMPL}" ]

  run grep -F 'hasKey .chezmoi "interactive"' "${CHEZMOI_TMPL}"
  [ "$status" -eq 0 ]

  run grep -F '.chezmoi.interactive' "${CHEZMOI_TMPL}"
  [ "$status" -eq 0 ]

  run grep -F 'promptStringOnce . "git.name"' "${CHEZMOI_TMPL}"
  [ "$status" -eq 0 ]

  run grep -F 'promptStringOnce . "git.email"' "${CHEZMOI_TMPL}"
  [ "$status" -eq 0 ]

  run grep -F 'promptBoolOnce . "install.flyctl"' "${CHEZMOI_TMPL}"
  [ "$status" -eq 0 ]
}

@test "chezmoi template seeds non-interactive defaults matching install/* gates" {
  [ -f "${CHEZMOI_TMPL}" ]

  run grep -F '{{ $gitName := "" }}' "${CHEZMOI_TMPL}"
  [ "$status" -eq 0 ]

  run grep -F '{{ $gitEmail := "" }}' "${CHEZMOI_TMPL}"
  [ "$status" -eq 0 ]

  for var in instApt instBrew instBun instMise instOmzsh; do
    run grep -F "{{ \$${var} := true }}" "${CHEZMOI_TMPL}"
    [ "$status" -eq 0 ]
  done

  run grep -F '{{ $instFlyctl := false }}' "${CHEZMOI_TMPL}"
  [ "$status" -eq 0 ]
}

@test "chezmoi template applies Codespaces minimal install overrides when CODESPACE_NAME set" {
  [ -f "${CHEZMOI_TMPL}" ]

  run grep -F 'DOTFILES_CODESPACES_PROFILE' "${CHEZMOI_TMPL}"
  [ "$status" -eq 0 ]

  run grep -F 'codespaces_profile' "${CHEZMOI_TMPL}"
  [ "$status" -eq 0 ]

  run grep -F '{{   $instApt = false }}' "${CHEZMOI_TMPL}"
  [ "$status" -eq 0 ]

  run grep -F '{{   $instMise = false }}' "${CHEZMOI_TMPL}"
  [ "$status" -eq 0 ]
}

@test "dot_profile dot_zshrc and dot_bashrc wire bun PATH and BUN_INSTALL" {
  for f in "${DOT_PROFILE}" "${DOT_ZSHRC}" "${DOT_BASHRC}"; do
    [ -f "${f}" ]

    run grep -F 'BUN_INSTALL' "${f}"
    [ "$status" -eq 0 ]

    run grep -F '# bun (https://bun.com)' "${f}"
    [ "$status" -eq 0 ]
  done
}
