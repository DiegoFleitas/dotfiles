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

PYTHON_FOR_PYTEST="python3"
if [[ -x "${REPO_ROOT}/.venv/bin/python" ]]; then
  PYTHON_FOR_PYTEST="${REPO_ROOT}/.venv/bin/python"
fi

if ! "${PYTHON_FOR_PYTEST}" -c "import pytest" 2>/dev/null; then
  echo "pytest is not installed (needed for test_python/). Install dev deps:" >&2
  echo "  python3 -m venv .venv && . .venv/bin/activate && pip install -r requirements-dev.txt" >&2
  echo "  # or: python3 -m pip install --user -r requirements-dev.txt" >&2
  exit 127
fi

(
  cd "${REPO_ROOT}"
  bats --jobs 1 test/
)
(
  cd "${REPO_ROOT}"
  "${PYTHON_FOR_PYTEST}" -m pytest test_python/
)
