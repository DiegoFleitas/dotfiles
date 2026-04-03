#!/usr/bin/env bats

load 'helpers/common.bash'

setup() {
  REPO_ROOT="$(repo_root)"
  APPS_CONF="${REPO_ROOT}/apps.conf"
  README="${REPO_ROOT}/README.md"
  FINALIZE="${REPO_ROOT}/run_once_before_finalize.sh"
  AFTER_PREREQS="${REPO_ROOT}/run_once_after_prereqs.sh"
  APPS_SH="${REPO_ROOT}/apps.sh"
}

@test "apps.conf has no brew-typed application rows" {
  run bash -c "grep -vE '^[[:space:]]*(#|$)' '${APPS_CONF}' | grep ':brew:'"
  [ "$status" -ne 0 ]
}

@test "apps.conf data lines only use types supported by apps.sh" {
  run bash -c '
    set -euo pipefail
    bad=0
    while IFS= read -r line || [[ -n "${line}" ]]; do
      [[ "${line}" =~ ^[[:space:]]*# ]] && continue
      [[ -z "${line//[:space:]}" ]] && continue
      type=$(printf "%s\n" "${line}" | cut -d: -f2)
      case "${type}" in
        apt|deb|snap|repo|ppa) ;;
        *)
          echo "unsupported type \"${type}\" in: ${line}" >&2
          bad=1
          ;;
      esac
    done < "'"${APPS_CONF}"'"
    exit "${bad}"
  '
  [ "$status" -eq 0 ]
}

@test "apps.conf ends with a newline" {
  run bash -c "n=\$(wc -c <'${APPS_CONF}'); test \"\${n// /}\" -gt 0"
  [ "$status" -eq 0 ]

  run bash -c "c=\$(tail -c1 '${APPS_CONF}' | wc -c); test \"\${c// /}\" -eq 1"
  [ "$status" -eq 0 ]
}

@test "before_finalize has no bun-specific upgrade path" {
  run grep -F 'bun' "${FINALIZE}"
  [ "$status" -ne 0 ]
}

@test "README lists apps.sh installer types and documents Bun outside apps.sh" {
  run grep -F '**apt**, **deb**, **snap**, **repo**, and **ppa**' "${README}"
  [ "$status" -eq 0 ]

  run grep -F '**Brewfile**' "${README}"
  [ "$status" -eq 0 ]

  run grep -F 'not installed by `apps.sh`' "${README}"
  [ "$status" -eq 0 ]

  run grep -F 'curl installer (not the Brewfile)' "${README}"
  [ "$status" -eq 0 ]
}

@test "README documents Fly.io opt-in via DOTFILES_INSTALL_FLYCTL or brew" {
  run grep -F 'DOTFILES_INSTALL_FLYCTL' "${README}"
  [ "$status" -eq 0 ]

  run grep -F 'brew install flyctl' "${README}"
  [ "$status" -eq 0 ]
}

@test "run_once_after_prereqs installs flyctl when DOTFILES_INSTALL_FLYCTL=1" {
  run grep -F 'DOTFILES_INSTALL_FLYCTL' "${AFTER_PREREQS}"
  [ "$status" -eq 0 ]

  run grep -F 'brew install flyctl' "${AFTER_PREREQS}"
  [ "$status" -eq 0 ]
}

@test "apps.sh install_app case has no brew branch" {
  run grep -E '[[:space:]]*brew\)' "${APPS_SH}"
  [ "$status" -ne 0 ]
}
