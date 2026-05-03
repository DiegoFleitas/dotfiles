#!/usr/bin/env bash
# Invoked only from the real filesystem (run_once wrappers locate this via CHEZMOI_* paths).
set -euo pipefail

hook="${1:?}"
shift

# Strip install/lib/<thisfile> from BASH_SOURCE (no external dirname: tests stub dirname in PATH).
_script_path="${BASH_SOURCE[0]}"
_lib_dir="${_script_path%/*}"
_install_dir="${_lib_dir%/*}"
ROOT="${_install_dir%/*}"
ROOT="$(cd -- "${ROOT}" && pwd)"

case "${hook}" in
  before_finalize) exec /bin/bash "${ROOT}/install/before_finalize.sh" "$@" ;;
  after_prereqs) exec /bin/bash "${ROOT}/install/after_prereqs.sh" "$@" ;;
  *)
    printf 'run_once_dispatch: unknown hook %q\n' "${hook}" >&2
    exit 1
    ;;
esac
