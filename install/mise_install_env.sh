# shellcheck shell=bash
# Source before `mise install` when building PHP from source (asdf-php).
# Linux/WSL: avoid OOM during huge final links (php-cgi, etc.). Submakes inherit
# MAKEFLAGS — use -j1 here unless the user already set MAKEFLAGS / ASDF_CONCURRENCY.

if [ "$(uname -s)" = "Linux" ]; then
  export ASDF_CONCURRENCY="${ASDF_CONCURRENCY:-1}"
  # Default single-job; override for faster builds if you have RAM: MAKEFLAGS=-j4 mise install -y
  export MAKEFLAGS="${MAKEFLAGS:--j1}"
fi
