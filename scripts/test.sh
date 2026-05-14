#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v bats >/dev/null 2>&1; then
  echo "bats is not installed."
  echo "Install it, then rerun this script:"
  case "$(uname -s)" in
    Darwin)
      echo "  macOS:  brew install bats-core"
      ;;
    Linux)
      echo "  Linux:  sudo apt-get update && sudo apt-get install -y bats"
      ;;
    *)
      echo "  See: https://github.com/bats-core/bats-core#installation"
      ;;
  esac
  exit 127
fi

(
  cd "${REPO_ROOT}"
  bats --jobs 1 test/
)
