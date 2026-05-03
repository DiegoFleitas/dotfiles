#!/usr/bin/env bash
set -euo pipefail

# chezmoi run_once slot: after_prereqs (content must differ from before_finalize for run_once hashing)
# The wrapper may run from a temp path; it execs the real install/lib helper on disk.

_here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
for _r in "${CHEZMOI_SOURCE_DIR:-}" "${CHEZMOI_WORKING_TREE:-}" "${_here}"; do
  [[ -z "${_r}" ]] && continue
  if [[ -f "${_r}/install/lib/run_once_dispatch.sh" ]]; then
    exec /bin/bash "${_r}/install/lib/run_once_dispatch.sh" after_prereqs "$@"
  fi
done
exec /bin/bash "${_here}/install/lib/run_once_dispatch.sh" after_prereqs "$@"
