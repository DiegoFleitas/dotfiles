# shellcheck shell=bash
# Source before `mise install` when building PHP from source (asdf-php).
# Linux/WSL: cap make parallelism to reduce OOM or flaky final links.

if [ "$(uname -s)" = "Linux" ]; then
  export MAKEFLAGS="${MAKEFLAGS:--j2}"
  export ASDF_CONCURRENCY="${ASDF_CONCURRENCY:-1}"
fi
