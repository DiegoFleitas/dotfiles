#!/usr/bin/env bats

load 'helpers/common.bash'

setup() {
  REPO_ROOT="$(repo_root)"
  AFTER_TMPL="${REPO_ROOT}/run_once_after_prereqs.sh.tmpl"
  BEFORE_TMPL="${REPO_ROOT}/run_once_before_finalize.sh.tmpl"
}

@test "run_once_after_prereqs template exports install flags and delegates to install/after_prereqs.sh" {
  run grep -F 'export DOTFILES_INSTALL_APT="{{ .install.apt | ternary "1" "0" }}"' "${AFTER_TMPL}"
  [ "$status" -eq 0 ]

  run grep -F 'export DOTFILES_INSTALL_FLYCTL="{{ .install.flyctl | ternary "1" "0" }}"' "${AFTER_TMPL}"
  [ "$status" -eq 0 ]

  run grep -F 'exec /bin/bash "{{ .chezmoi.sourceDir }}/install/after_prereqs.sh"' "${AFTER_TMPL}"
  [ "$status" -eq 0 ]
}

@test "run_once_before_finalize template exports install flags and delegates to install/before_finalize.sh" {
  run grep -F 'export DOTFILES_INSTALL_BREW="{{ .install.brew | ternary "1" "0" }}"' "${BEFORE_TMPL}"
  [ "$status" -eq 0 ]

  run grep -F 'export DOTFILES_INSTALL_OHMYZSH="{{ .install.ohmyzsh | ternary "1" "0" }}"' "${BEFORE_TMPL}"
  [ "$status" -eq 0 ]

  run grep -F 'exec /bin/bash "{{ .chezmoi.sourceDir }}/install/before_finalize.sh"' "${BEFORE_TMPL}"
  [ "$status" -eq 0 ]
}
