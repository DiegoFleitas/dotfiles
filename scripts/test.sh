#!/usr/bin/env bash

set -euo pipefail

if ! command -v bats >/dev/null 2>&1; then
  echo "bats is not installed."
  echo "Install it, then rerun this script:"
  echo "  sudo apt-get update && sudo apt-get install -y bats"
  exit 127
fi

exec bats test/
