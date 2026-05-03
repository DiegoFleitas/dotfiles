#!/usr/bin/env bash
#
# Stub / isolation footguns (worth reading when a test hangs or misbehaves):
#
# - Stub scripts must NOT use `#!/usr/bin/env bash` when PATH starts with BIN_DIR:
#   `/usr/bin/env` resolves `bash` via PATH and can recurse into BIN_DIR/bash forever.
#   Use `#!/bin/bash` (or another fixed path) for stub interpreters.
# - Assertions on CALL_LOG must use `/usr/bin/grep` (or helpers below): a stub named
#   `grep` on PATH shadows the real binary.
# - Do not forward arbitrary developer exports into `dotfiles_run_script_clean`
#   unless explicitly opt-in (see BUN_INSTALL handling inside that function).

repo_root() {
  cd "$(dirname "${BATS_TEST_FILENAME}")/.." >/dev/null 2>&1 && pwd
}

# Bash prefers shell functions over PATH for `command -v`. Dev shells often wrap
# brew/curl; unset those so stub binaries in BIN_DIR are the ones run.
dotfiles_clear_stub_path_conflicts() {
  unset -f brew bundle curl git pyenv mise grep bash 2>/dev/null || true
}

# Run a script under test with a clean environment (no BASH_ENV, no inherited
# functions) and non-interactive bash. Call from Bats @tests after setup() has
# exported HOME, PATH (e.g. BIN_DIR:/bin:/usr/bin), CALL_LOG, and
# DOTFILES_BREW_USE_PATH_ONLY / DOTFILES_DISABLE_APT.
# Optional: export SHELL, DOTFILES_INSTALL_FLYCTL, DOTFILES_BREW_UPGRADE,
# DOTFILES_PYTHON_REFRESH, NVM_DIR before calling when a test needs them.
#
# BUN_INSTALL is not forwarded from the Bats process environment: a normal dev shell
# often exports it and would make run_once skip the bun installer. To force a value
# for a test, set DOTFILES_TEST_BUN_INSTALL and it will be passed as BUN_INSTALL.
dotfiles_run_script_clean() {
  local script_path="${1:?script path required}"
  shift
  local path_for_child="${PATH:?}"
  # Prefer stub bin first — never trust PATH alone if BIN_DIR is set (parent shells
  # may prepend Linuxbrew/Homebrew and leak real `brew` before env -i is applied).
  if [[ -n "${BIN_DIR:-}" ]]; then
    path_for_child="${BIN_DIR}:/bin:/usr/bin"
  fi
  # Build env -i without a bash array: some Bats versions mishandle `run "${cmd[@]}"`
  # when the payload is large or interacts oddly with `run`, causing hangs.
  local env_cmd=(/usr/bin/env -i
    "HOME=${HOME:?}"
    "PATH=${path_for_child}"
    "DOTFILES_BREW_USE_PATH_ONLY=${DOTFILES_BREW_USE_PATH_ONLY:-1}"
    "DOTFILES_DISABLE_APT=${DOTFILES_DISABLE_APT:-1}"
    "LANG=C"
    "LC_ALL=C")
  [[ -n "${CALL_LOG+x}" ]] && env_cmd+=("CALL_LOG=${CALL_LOG}")
  [[ -n "${SHELL+x}" ]] && env_cmd+=("SHELL=${SHELL}")
  [[ -n "${DOTFILES_INSTALL_FLYCTL+x}" ]] && env_cmd+=("DOTFILES_INSTALL_FLYCTL=${DOTFILES_INSTALL_FLYCTL}")
  [[ -n "${DOTFILES_BREW_UPGRADE+x}" ]] && env_cmd+=("DOTFILES_BREW_UPGRADE=${DOTFILES_BREW_UPGRADE}")
  [[ -n "${DOTFILES_PYTHON_REFRESH+x}" ]] && env_cmd+=("DOTFILES_PYTHON_REFRESH=${DOTFILES_PYTHON_REFRESH}")
  [[ -n "${NVM_DIR+x}" ]] && env_cmd+=("NVM_DIR=${NVM_DIR}")
  [[ -n "${DOTFILES_TEST_BUN_INSTALL+x}" ]] && env_cmd+=("BUN_INSTALL=${DOTFILES_TEST_BUN_INSTALL}")

  # Use /bin/bash so macOS CI runners can execute tests (/usr/bin/bash is often absent).
  # shellcheck disable=SC2068
  run "${env_cmd[@]}" /bin/bash --noprofile --norc "${script_path}" "$@"
}

# Assert "${CALL_LOG}" contains a line matching a fixed string. Uses /usr/bin/grep so
# a stub `grep` on PATH cannot break the check. On failure, dumps CALL_LOG to stderr.
dotfiles_call_log_must_contain() {
  local needle="${1:?needle required}"
  if [[ -z "${CALL_LOG:-}" ]]; then
    printf '%s\n' "dotfiles_call_log_must_contain: CALL_LOG is unset" >&2
    return 1
  fi
  if ! /usr/bin/grep -qF "$needle" "${CALL_LOG}"; then
    printf '%s\n' "Expected CALL_LOG to contain: ${needle}" >&2
    printf '%s\n' "--- ${CALL_LOG} (full contents) ---" >&2
    /usr/bin/cat "${CALL_LOG}" >&2 || true
    return 1
  fi
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
