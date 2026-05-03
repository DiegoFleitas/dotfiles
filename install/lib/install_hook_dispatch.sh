#!/usr/bin/env bash
# Invoked only via run_once_*.sh wrappers (CHEZMOI_* paths find this file).
# Filename MUST NOT start with "run_" — chezmoi executes those as hooks with no args.
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
    printf 'install_hook_dispatch: unknown hook %q\n' "${hook}" >&2
    exit 1
    ;;
esac
