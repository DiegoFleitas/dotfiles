#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  echo "Version drift: $1" >&2
  exit 1
}

VERSIONS_FILE="${ROOT_DIR}/versions.env"
DOT_NVMRC_FILE="${ROOT_DIR}/dot_nvmrc"

[ -f "${VERSIONS_FILE}" ] || fail "missing versions.env at ${VERSIONS_FILE}"
# shellcheck disable=SC1090
. "${VERSIONS_FILE}"
[ -n "${NODE_VERSION:-}" ] || fail "NODE_VERSION is missing in versions.env"
[ -n "${PYTHON_VERSION:-}" ] || fail "PYTHON_VERSION is missing in versions.env"
[ -n "${PHP_VERSION:-}" ] || fail "PHP_VERSION is missing in versions.env"
[ -n "${NVM_INSTALL_VERSION:-}" ] || fail "NVM_INSTALL_VERSION is missing in versions.env"

[ -f "${DOT_NVMRC_FILE}" ] || fail "missing dot_nvmrc at ${DOT_NVMRC_FILE}"
trimmed_nvmrc="$(tr -d '[:space:]' < "${ROOT_DIR}/dot_nvmrc")"
[ -n "${trimmed_nvmrc}" ] || fail "dot_nvmrc is empty"
[ "${trimmed_nvmrc}" = "${NODE_VERSION}" ] || fail "dot_nvmrc (${trimmed_nvmrc}) != NODE_VERSION (${NODE_VERSION})"

grep -q "nvm alias default \"\\\${NODE_VERSION}\"" "${ROOT_DIR}/run_once_before_finalize.sh" \
  || fail "run_once_before_finalize.sh is not using NODE_VERSION for default alias"
grep -q "nvm install \"\\\${NODE_VERSION}\"" "${ROOT_DIR}/run_once_before_finalize.sh" \
  || fail "run_once_before_finalize.sh is not using NODE_VERSION for install"
grep -q "NVM_INSTALL_VERSION" "${ROOT_DIR}/run_once_after_prereqs.sh" \
  || fail "run_once_after_prereqs.sh is not using NVM_INSTALL_VERSION"
grep -Fq 'NVM_DIR="${NVM_DIR:-$HOME/.nvm}"' "${ROOT_DIR}/run_once_after_prereqs.sh" \
  || fail "run_once_after_prereqs.sh should set NVM_DIR before checking nvm.sh"
grep -Fq '[ ! -s "$NVM_DIR/nvm.sh" ]' "${ROOT_DIR}/run_once_after_prereqs.sh" \
  || fail "run_once_after_prereqs.sh should install nvm when nvm.sh is missing (not command -v nvm)"
grep -q "PYTHON_VERSION" "${ROOT_DIR}/run_once_after_prereqs.sh" \
  || fail "run_once_after_prereqs.sh is not using PYTHON_VERSION"
grep -q "PHP_VERSION" "${ROOT_DIR}/run_once_after_prereqs.sh" \
  || fail "run_once_after_prereqs.sh is not using PHP_VERSION"
grep -q "PYTHON_VERSION" "${ROOT_DIR}/run_once_before_finalize.sh" \
  || fail "run_once_before_finalize.sh is not using PYTHON_VERSION"

grep -q "Node ${NODE_VERSION}" "${ROOT_DIR}/README.md" \
  || fail "README.md does not mention Node ${NODE_VERSION}"
grep -q "Python ${PYTHON_VERSION}" "${ROOT_DIR}/README.md" \
  || fail "README.md does not mention Python ${PYTHON_VERSION}"
grep -q "PHP ${PHP_VERSION}" "${ROOT_DIR}/README.md" \
  || fail "README.md does not mention PHP ${PHP_VERSION}"

echo "Version drift check passed."
