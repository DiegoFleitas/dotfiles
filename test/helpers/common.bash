#!/usr/bin/env bash

repo_root() {
  cd "$(dirname "${BATS_TEST_FILENAME}")/.." >/dev/null 2>&1 && pwd
}

backup_file() {
  local source_file="$1"
  local backup_file="$2"
  cp "${source_file}" "${backup_file}"
}

restore_file() {
  local backup_file="$1"
  local destination_file="$2"
  mv "${backup_file}" "${destination_file}"
}
