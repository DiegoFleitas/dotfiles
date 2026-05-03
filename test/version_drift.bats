#!/usr/bin/env bats

load 'helpers/common.bash'

setup() {
  REPO_ROOT="$(repo_root)"
  DOT_NVMRC_BACKUP=""
  DOT_MISE_BACKUP=""
}

teardown() {
  if [ -n "${DOT_NVMRC_BACKUP}" ] && [ -f "${DOT_NVMRC_BACKUP}" ]; then
    restore_file "${DOT_NVMRC_BACKUP}" "${REPO_ROOT}/dot_nvmrc"
  fi
  if [ -n "${DOT_MISE_BACKUP}" ] && [ -f "${DOT_MISE_BACKUP}" ]; then
    restore_file "${DOT_MISE_BACKUP}" "${REPO_ROOT}/dot_mise.toml"
  fi
}

@test "dot_nvmrc major matches node pin in dot_mise.toml" {
  local node_pin
  node_pin="$(grep -E '^node[[:space:]]*=' "${REPO_ROOT}/dot_mise.toml" | sed -E 's/^node[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/')"
  local nvmrc
  nvmrc="$(tr -d '[:space:]' < "${REPO_ROOT}/dot_nvmrc")"
  [ -n "${node_pin}" ]
  [ "${nvmrc}" = "${node_pin}" ]
}

@test "README mentions Node Python PHP versions from dot_mise.toml" {
  local dot_mise="${REPO_ROOT}/dot_mise.toml"
  local node_pin python_pin php_pin
  node_pin="$(grep -E '^node[[:space:]]*=' "${dot_mise}" | sed -E 's/^node[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/')"
  python_pin="$(grep -E '^python[[:space:]]*=' "${dot_mise}" | sed -E 's/^python[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/')"
  php_pin="$(grep -E '^("ubi:adwinying/php"|php)[[:space:]]*=' "${dot_mise}" | sed -E 's/^[^=]*=[[:space:]]*"([^"]+)".*/\1/')"
  run grep -Fq "Node ${node_pin}" "${REPO_ROOT}/README.md"
  [ "$status" -eq 0 ]
  run grep -Fq "Python ${python_pin}" "${REPO_ROOT}/README.md"
  [ "$status" -eq 0 ]
  run grep -Fq "PHP ${php_pin}" "${REPO_ROOT}/README.md"
  [ "$status" -eq 0 ]
}

@test "alignment fails when dot_nvmrc mismatches node in dot_mise.toml" {
  local dot_nvmrc="${REPO_ROOT}/dot_nvmrc"
  DOT_NVMRC_BACKUP="$(mktemp)"
  backup_file "${dot_nvmrc}" "${DOT_NVMRC_BACKUP}"
  printf '%s\n' "999" > "${dot_nvmrc}"

  local node_pin
  node_pin="$(grep -E '^node[[:space:]]*=' "${REPO_ROOT}/dot_mise.toml" | sed -E 's/^node[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/')"
  local nvmrc
  nvmrc="$(tr -d '[:space:]' < "${dot_nvmrc}")"
  [ "${nvmrc}" != "${node_pin}" ]

  restore_file "${DOT_NVMRC_BACKUP}" "${dot_nvmrc}"
  DOT_NVMRC_BACKUP=""
}

@test "dot_mise.toml missing required tool line is detectable" {
  local dot_mise="${REPO_ROOT}/dot_mise.toml"
  DOT_MISE_BACKUP="$(mktemp)"
  backup_file "${dot_mise}" "${DOT_MISE_BACKUP}"

  grep -vE '^("ubi:adwinying/php"|php)[[:space:]]*=' "${DOT_MISE_BACKUP}" > "${dot_mise}"
  run grep -E '^("ubi:adwinying/php"|php)[[:space:]]*=' "${dot_mise}"
  [ "$status" -ne 0 ]

  restore_file "${DOT_MISE_BACKUP}" "${dot_mise}"
  DOT_MISE_BACKUP=""
}
