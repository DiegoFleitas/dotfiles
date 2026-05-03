#!/usr/bin/env bash
set -euo pipefail

# chezmoi run_once slot: before_finalize (content must differ from after_prereqs for run_once hashing)
# The wrapper may run from a temp path; it execs the real install/lib helper on disk.

_here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
for _r in "${CHEZMOI_SOURCE_DIR:-}" "${CHEZMOI_WORKING_TREE:-}" "${_here}"; do
  [[ -z "${_r}" ]] && continue
  if [[ -f "${_r}/install/lib/install_hook_dispatch.sh" ]]; then
    exec /bin/bash "${_r}/install/lib/install_hook_dispatch.sh" before_finalize "$@"
  fi
done
exec /bin/bash "${_here}/install/lib/install_hook_dispatch.sh" before_finalize "$@"
