# shellcheck shell=bash
# Source before `mise install` when building PHP from source (asdf-php).
# Linux/WSL: avoid OOM during huge final links (php-cgi, etc.). Submakes inherit
# MAKEFLAGS — use -j1 here unless the user already set MAKEFLAGS / ASDF_CONCURRENCY.

if [ "$(uname -s)" = "Linux" ]; then
  export ASDF_CONCURRENCY="${ASDF_CONCURRENCY:-1}"
  # Default single-job; override for faster builds if you have RAM: MAKEFLAGS=-j4 mise install -y
  export MAKEFLAGS="${MAKEFLAGS:--j1}"

  # GNU ld only: lowers peak RSS on very large links (ignored if ld is lld/mold).
  if command -v ld >/dev/null 2>&1 && ld --version 2>&1 | grep -q 'GNU ld'; then
    case "${LDFLAGS:-}" in *reduce-memory-overheads*) ;; *)
      export LDFLAGS="${LDFLAGS-} -Wl,--reduce-memory-overheads"
      ;;
    esac
  fi

  # WSL: tiny tmpfs /tmp can break large builds; use a cache dir under HOME unless TMPDIR is set.
  if [ -z "${TMPDIR:-}" ] && [ -n "${WSL_DISTRO_NAME:-}" ]; then
    export TMPDIR="${HOME}/.cache/mise-build-tmp"
    mkdir -p "${TMPDIR}"
  fi
fi
