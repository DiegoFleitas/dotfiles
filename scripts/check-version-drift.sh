#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
. "${ROOT_DIR}/versions.env"

fail() {
  echo "Version drift: $1" >&2
  exit 1
}

trimmed_nvmrc="$(tr -d '[:space:]' < "${ROOT_DIR}/dot_nvmrc")"
[ "${trimmed_nvmrc}" = "${NODE_VERSION}" ] || fail "dot_nvmrc (${trimmed_nvmrc}) != NODE_VERSION (${NODE_VERSION})"

rg -q "nvm alias default \"\\$\\{NODE_VERSION\\}\"" "${ROOT_DIR}/run_once_before_finalize.sh" \
  || fail "run_once_before_finalize.sh is not using NODE_VERSION for default alias"
rg -q "nvm install \"\\$\\{NODE_VERSION\\}\"" "${ROOT_DIR}/run_once_before_finalize.sh" \
  || fail "run_once_before_finalize.sh is not using NODE_VERSION for install"
rg -q "NVM_INSTALL_VERSION" "${ROOT_DIR}/run_once_after_prereqs.sh" \
  || fail "run_once_after_prereqs.sh is not using NVM_INSTALL_VERSION"
rg -q "PYTHON_VERSION" "${ROOT_DIR}/run_once_after_prereqs.sh" \
  || fail "run_once_after_prereqs.sh is not using PYTHON_VERSION"
rg -q "PYTHON_VERSION" "${ROOT_DIR}/run_once_before_finalize.sh" \
  || fail "run_once_before_finalize.sh is not using PYTHON_VERSION"

rg -q "Node ${NODE_VERSION}" "${ROOT_DIR}/README.md" \
  || fail "README.md does not mention Node ${NODE_VERSION}"
rg -q "Python ${PYTHON_VERSION}" "${ROOT_DIR}/README.md" \
  || fail "README.md does not mention Python ${PYTHON_VERSION}"

echo "Version drift check passed."
