#!/usr/bin/env bats

load 'helpers/common.bash'

setup() {
  dotfiles_clear_stub_path_conflicts
  REPO_ROOT="$(repo_root)"
  TARGET_FILE="${REPO_ROOT}/install/after_prereqs.sh"

  TEST_TMPDIR="$(mktemp -d)"
  BIN_DIR="${TEST_TMPDIR}/bin"
  mkdir -p "${BIN_DIR}"
  export BIN_DIR

  CALL_LOG="${TEST_TMPDIR}/calls.log"
  : > "${CALL_LOG}"

  export CALL_LOG
  export DOTFILES_BREW_USE_PATH_ONLY=1
  export DOTFILES_DISABLE_APT=1
  unset DOTFILES_INSTALL_FLYCTL 2>/dev/null || true
  export PATH="${BIN_DIR}:/bin:/usr/bin"

  # Isolate HOME so the script can't touch the real dotfiles.
  export HOME="${TEST_TMPDIR}/home"
  mkdir -p "${HOME}"

  # mise installs toolchains from dot_mise.toml (SCRIPT_DIR); no HOME stubs needed.

  # Provide a bashrc file in case the script tries to read/append.
  : > "${HOME}/.bashrc"
}

teardown() {
  rm -rf "${TEST_TMPDIR}"
}

write_stub() {
  local name="$1"
  local content="$2"
  printf '%s\n' "${content}" > "${BIN_DIR}/${name}"
  chmod +x "${BIN_DIR}/${name}"
}

# Pipe/install steps invoke `bash` by name; PATH may not include /usr/bin.
stub_bash_forwarder() {
  write_stub "bash" '#!/bin/bash
exec /bin/bash "$@"
'
}

@test "after_prereqs exits early when run as root (no side-effect commands invoked)" {
  write_stub "uname" '#!/bin/bash
echo "uname $*" >>"$CALL_LOG"
echo "Linux"
'

  # Make id -u report root.
  write_stub "id" '#!/bin/bash
echo "id $*" >>"$CALL_LOG"
if [ "${1:-}" = "-u" ]; then
  echo 0
  exit 0
fi
echo 0
'

  # Side-effect commands should never run past the guard.
  write_stub "sudo" '#!/bin/bash
echo "sudo $*" >>"$CALL_LOG"
exit 99
'
  write_stub "apt" '#!/bin/bash
echo "apt $*" >>"$CALL_LOG"
exit 99
'
  write_stub "brew" '#!/bin/bash
echo "brew $*" >>"$CALL_LOG"
exit 99
'
  write_stub "curl" '#!/bin/bash
echo "curl $*" >>"$CALL_LOG"
exit 99
'

  dotfiles_run_script_clean "${TARGET_FILE}"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Rerun as non root."* ]]

  run grep -F "sudo " "${CALL_LOG}"
  [ "$status" -ne 0 ]
  run grep -F "apt " "${CALL_LOG}"
  [ "$status" -ne 0 ]
  run grep -F "brew " "${CALL_LOG}"
  [ "$status" -ne 0 ]
  run grep -F "curl " "${CALL_LOG}"
  [ "$status" -ne 0 ]
}

@test "after_prereqs when apt is unavailable does not call sudo apt" {
  # Make sure the real system `apt` isn't discoverable via PATH.
  # We only restrict PATH for the script invocation (not for Bats itself).

  write_stub "uname" '#!/bin/bash
echo "uname $*" >>"$CALL_LOG"
echo "Linux"
'

  write_stub "dirname" '#!/bin/bash
echo "dirname $*" >>"$CALL_LOG"
path="${1:-}"
path="${path%/}"
if [[ "${path}" != *"/"* ]]; then
  echo "."
else
  echo "${path%/*}"
fi
'

  # Non-root execution.
  write_stub "id" '#!/bin/bash
echo "id $*" >>"$CALL_LOG"
if [ "${1:-}" = "-u" ]; then
  echo 1000
  exit 0
fi
echo 1000
'

  # Ensure git/curl are considered installed (avoid apt installs).
  write_stub "git" '#!/bin/bash
echo "git $*" >>"$CALL_LOG"
exit 0
'
  write_stub "curl" '#!/bin/bash
echo "curl $*" >>"$CALL_LOG"
exit 0
'

  # Provide brew and all commands used later in the script.
  write_stub "brew" '#!/bin/bash
echo "brew $*" >>"$CALL_LOG"
case "${1:-}" in
  shellenv) exit 0 ;;
  bundle) exit 0 ;;
  install) exit 0 ;;
esac
exit 0
'
  write_stub "mise" "#!/bin/bash
echo \"mise \$*\" >>\"\$CALL_LOG\"
if [ \"\${1:-}\" = \"env\" ] && [ \"\${2:-}\" = \"-s\" ]; then
  echo \"export PATH=\\\"${BIN_DIR}:\\\$PATH\\\"\"
fi
exit 0
"
  write_stub "node" '#!/bin/bash
exit 0
'
  write_stub "php" '#!/bin/bash
exit 0
'
  write_stub "grep" '#!/bin/bash
echo "grep $*" >>"$CALL_LOG"
if [ "${1:-}" = "-q" ]; then
  pattern="${2:-}"
  input="$(cat)"
  case "${input}" in
    *"${pattern}"*) exit 0 ;;
    *) exit 1 ;;
  esac
fi
exit 2
'
  write_stub "python3" '#!/bin/bash
echo "python3 $*" >>"$CALL_LOG"
exit 0
'
  write_stub "chsh" '#!/bin/bash
echo "chsh $*" >>"$CALL_LOG"
exit 0
'
  write_stub "wget" '#!/bin/bash
echo "wget $*" >>"$CALL_LOG"
exit 0
'
  write_stub "zsh" '#!/bin/bash
echo "zsh $*" >>"$CALL_LOG"
exit 0
'

  # If sudo is invoked, we want the test to fail fast.
  write_stub "sudo" '#!/bin/bash
echo "sudo $*" >>"$CALL_LOG"
exit 98
'

  # Run the script with a minimal PATH (stubs only). Oh-my-zsh install uses
  # `/bin/bash -c "$(curl …)"` (absolute bash). `apt` must not resolve from stubs
  # (e.g. do not prefix /bin: this system has /bin/apt which would set HAS_APT=1).
  dotfiles_run_script_clean "${TARGET_FILE}"
  [ "$status" -eq 0 ]
  [[ "$output" == *"apt not available. Skipping apt dependency setup."* ]]

  run /usr/bin/grep -F "sudo apt" "${CALL_LOG}"
  [ "$status" -ne 0 ]
}

@test "after_prereqs installs oh-my-zsh and appends exec zsh on WSL (idempotent guard path)" {
  # Scripts gate WSL on [ -r /proc/version ]; macOS runners have no /proc.
  if [[ ! -r /proc/version ]]; then
    skip "WSL contract requires Linux /proc/version (skipped on macOS)"
  fi

  # Force oh-my-zsh install path.
  rm -rf "${HOME}/.oh-my-zsh"

  write_stub "uname" '#!/bin/bash
echo "uname $*" >>"$CALL_LOG"
echo "Linux"
'

  write_stub "dirname" '#!/bin/bash
path="${1:-}"
path="${path%/}"
if [[ "${path}" != *"/"* ]]; then
  echo "."
else
  echo "${path%/*}"
fi
'

  write_stub "id" '#!/bin/bash
if [ "${1:-}" = "-u" ]; then
  echo 1000
  exit 0
fi
echo 1000
'

  # Simulate WSL detection: `grep -qi microsoft /proc/version` should succeed.
  # Also support the idempotency guard: `grep -qxF "exec zsh" "$HOME/.bashrc"`.
  write_stub "grep" '#!/bin/bash
if [ "${1:-}" = "-qi" ] && [ "${2:-}" = "microsoft" ] && [ "${3:-}" = "/proc/version" ]; then
  exit 0
fi
if [ "${1:-}" = "-qxF" ] && [ "${2:-}" = "exec zsh" ]; then
  file="${3:-}"
  [ -f "${file}" ] || exit 1
  while IFS= read -r line; do
    [ "${line}" = "exec zsh" ] && exit 0
  done < "${file}"
  exit 1
fi
exit 1
'

  # Ensure git/curl are considered installed so we don't hit apt installs.
  write_stub "git" '#!/bin/bash
exit 0
'

  # This curl is used by the oh-my-zsh installer invocation.
  # The script does: `/bin/bash -c "$(curl -fsSL https://.../install.sh)"`.
  # We output a harmless shell snippet to prove that path ran.
  write_stub "curl" '#!/bin/bash
echo "curl $*" >>"$CALL_LOG"
printf "%s\n" "echo OMZ_INSTALLER_RAN"
exit 0
'

  write_stub "brew" '#!/bin/bash
echo "brew $*" >>"$CALL_LOG"
exit 0
'
  write_stub "mise" "#!/bin/bash
echo \"mise \$*\" >>\"\$CALL_LOG\"
if [ \"\${1:-}\" = \"env\" ] && [ \"\${2:-}\" = \"-s\" ]; then
  echo \"export PATH=\\\"${BIN_DIR}:\\\$PATH\\\"\"
fi
exit 0
"
  write_stub "node" '#!/bin/bash
exit 0
'
  write_stub "php" '#!/bin/bash
exit 0
'
  write_stub "python3" '#!/bin/bash
exit 0
'
  write_stub "zsh" '#!/bin/bash
exit 0
'
  write_stub "wget" '#!/bin/bash
exit 0
'
  write_stub "chsh" '#!/bin/bash
echo "chsh $*" >>"$CALL_LOG"
exit 0
'

  stub_bash_forwarder

  # Fail fast if sudo is invoked (it shouldn't be, since HAS_APT should be 0).
  write_stub "sudo" '#!/bin/bash
echo "sudo $*" >>"$CALL_LOG"
exit 98
'

  dotfiles_run_script_clean "${TARGET_FILE}"
  if [ "$status" -ne 0 ]; then
    echo "SCRIPT_EXIT_STATUS=$status"
    echo "SCRIPT_OUTPUT_START"
    echo "$output"
    echo "SCRIPT_OUTPUT_END"
    echo "CALL_LOG_START"
    cat "${CALL_LOG}" || true
    echo "CALL_LOG_END"
  fi
  [ "$status" -eq 0 ]
  [[ "$output" == *"Installing oh-my-zsh..."* ]]
  [[ "$output" == *"OMZ_INSTALLER_RAN"* ]]

  # WSL path should append exec zsh exactly once.
  # Use /usr/bin/grep (not PATH-resolved grep) because this test stubs `grep`
  # for WSL detection + idempotency guard behavior.
  run /usr/bin/grep -nFx "exec zsh" "${HOME}/.bashrc"
  [ "$status" -eq 0 ]

  # WSL branch should not chsh.
  # Use /usr/bin/grep to keep assertions independent of our stubs.
  run /usr/bin/grep -F "chsh " "${CALL_LOG}"
  [ "$status" -ne 0 ]
}

@test "after_prereqs installs oh-my-zsh and calls chsh on non-WSL" {
  rm -rf "${HOME}/.oh-my-zsh"

  write_stub "uname" '#!/bin/bash
echo "Linux"
'

  write_stub "dirname" '#!/bin/bash
path="${1:-}"
path="${path%/}"
if [[ "${path}" != *"/"* ]]; then
  echo "."
else
  echo "${path%/*}"
fi
'

  write_stub "id" '#!/bin/bash
if [ "${1:-}" = "-u" ]; then
  echo 1000
  exit 0
fi
echo 1000
'

  # Non-WSL detection: make the microsoft grep check fail.
  write_stub "grep" '#!/bin/bash
if [ "${1:-}" = "-qi" ] && [ "${2:-}" = "microsoft" ] && [ "${3:-}" = "/proc/version" ]; then
  exit 1
fi
if [ "${1:-}" = "-qxF" ] && [ "${2:-}" = "exec zsh" ]; then
  file="${3:-}"
  [ -f "${file}" ] || exit 1
  while IFS= read -r line; do
    [ "${line}" = "exec zsh" ] && exit 0
  done < "${file}"
  exit 1
fi
exit 1
'

  write_stub "git" '#!/bin/bash
exit 0
'
  write_stub "curl" '#!/bin/bash
printf "%s\n" "echo OMZ_INSTALLER_RAN"
exit 0
'

  stub_bash_forwarder

  # `which zsh` is used in the non-WSL branch.
  write_stub "which" '#!/bin/bash
if [ "${1:-}" = "zsh" ]; then
  echo "${BIN_DIR}/zsh"
  exit 0
fi
exit 1
'
  write_stub "zsh" '#!/bin/bash
exit 0
'
  write_stub "chsh" '#!/bin/bash
echo "chsh $*" >>"$CALL_LOG"
exit 0
'

  # Keep the rest harmless.
  write_stub "brew" '#!/bin/bash
exit 0
'
  write_stub "mise" "#!/bin/bash
echo \"mise \$*\" >>\"\$CALL_LOG\"
if [ \"\${1:-}\" = \"env\" ] && [ \"\${2:-}\" = \"-s\" ]; then
  echo \"export PATH=\\\"${BIN_DIR}:\\\$PATH\\\"\"
fi
exit 0
"
  write_stub "node" '#!/bin/bash
exit 0
'
  write_stub "php" '#!/bin/bash
exit 0
'
  write_stub "python3" '#!/bin/bash
exit 0
'
  write_stub "wget" '#!/bin/bash
exit 0
'
  write_stub "sudo" '#!/bin/bash
exit 98
'

  dotfiles_run_script_clean "${TARGET_FILE}"
  if [ "$status" -ne 0 ]; then
    echo "SCRIPT_EXIT_STATUS=$status"
    echo "SCRIPT_OUTPUT_START"
    echo "$output"
    echo "SCRIPT_OUTPUT_END"
    echo "CALL_LOG_START"
    cat "${CALL_LOG}" || true
    echo "CALL_LOG_END"
  fi
  [ "$status" -eq 0 ]
  [[ "$output" == *"Installing oh-my-zsh..."* ]]
  [[ "$output" == *"OMZ_INSTALLER_RAN"* ]]

  # Use /usr/bin/grep (not PATH-resolved grep) because this test stubs `grep`
  # to force non-WSL behavior.
  run /usr/bin/grep -F "chsh -s" "${CALL_LOG}"
  [ "$status" -eq 0 ]
}

@test "after_prereqs installs oh-my-zsh and skips chsh on GitHub Codespaces" {
  rm -rf "${HOME}/.oh-my-zsh"
  : >"${HOME}/.bashrc"

  export CODESPACE_NAME="test-codespace"

  write_stub "uname" '#!/bin/bash
echo "Linux"
'

  write_stub "dirname" '#!/bin/bash
path="${1:-}"
path="${path%/}"
if [[ "${path}" != *"/"* ]]; then
  echo "."
else
  echo "${path%/*}"
fi
'

  write_stub "id" '#!/bin/bash
if [ "${1:-}" = "-u" ]; then
  echo 1000
  exit 0
fi
echo 1000
'

  # Non-WSL: microsoft grep fails; Codespaces branch uses CODESPACE_NAME.
  write_stub "grep" '#!/bin/bash
if [ "${1:-}" = "-qi" ] && [ "${2:-}" = "microsoft" ] && [ "${3:-}" = "/proc/version" ]; then
  exit 1
fi
if [ "${1:-}" = "-qxF" ] && [ "${2:-}" = "exec zsh" ]; then
  file="${3:-}"
  [ -f "${file}" ] || exit 1
  while IFS= read -r line; do
    [ "${line}" = "exec zsh" ] && exit 0
  done < "${file}"
  exit 1
fi
exit 1
'

  write_stub "git" '#!/bin/bash
exit 0
'
  write_stub "curl" '#!/bin/bash
printf "%s\n" "echo OMZ_INSTALLER_RAN"
exit 0
'

  stub_bash_forwarder

  write_stub "which" '#!/bin/bash
if [ "${1:-}" = "zsh" ]; then
  echo "${BIN_DIR}/zsh"
  exit 0
fi
exit 1
'
  write_stub "zsh" '#!/bin/bash
exit 0
'
  write_stub "chsh" '#!/bin/bash
echo "chsh $*" >>"$CALL_LOG"
exit 0
'

  write_stub "brew" '#!/bin/bash
exit 0
'
  write_stub "mise" "#!/bin/bash
echo \"mise \$*\" >>\"\$CALL_LOG\"
if [ \"\${1:-}\" = \"env\" ] && [ \"\${2:-}\" = \"-s\" ]; then
  echo \"export PATH=\\\"${BIN_DIR}:\\\$PATH\\\"\"
fi
exit 0
"
  write_stub "node" '#!/bin/bash
exit 0
'
  write_stub "php" '#!/bin/bash
exit 0
'
  write_stub "python3" '#!/bin/bash
exit 0
'
  write_stub "wget" '#!/bin/bash
exit 0
'
  write_stub "sudo" '#!/bin/bash
exit 98
'

  dotfiles_run_script_clean "${TARGET_FILE}"
  unset CODESPACE_NAME
  [ "$status" -eq 0 ]
  [[ "$output" == *"Installing oh-my-zsh..."* ]]

  run /usr/bin/grep -F "chsh " "${CALL_LOG}"
  [ "$status" -ne 0 ]

  run /usr/bin/grep -nFx "exec zsh" "${HOME}/.bashrc"
  [ "$status" -eq 0 ]
}

@test "after_prereqs installs flyctl when DOTFILES_INSTALL_FLYCTL=1 and CLI absent" {
  mkdir -p "${HOME}/.oh-my-zsh"

  write_stub "uname" '#!/bin/bash
echo "Linux"
'

  write_stub "dirname" '#!/bin/bash
path="${1:-}"
path="${path%/}"
if [[ "${path}" != *"/"* ]]; then
  echo "."
else
  echo "${path%/*}"
fi
'

  write_stub "id" '#!/bin/bash
if [ "${1:-}" = "-u" ]; then
  echo 1000
  exit 0
fi
echo 1000
'

  write_stub "git" '#!/bin/bash
exit 0
'
  write_stub "curl" '#!/bin/bash
exit 0
'

  write_stub "brew" '#!/bin/bash
echo "brew $*" >>"$CALL_LOG"
case "${1:-}" in
  shellenv) exit 0 ;;
  bundle) exit 0 ;;
  install) exit 0 ;;
esac
exit 0
'
  write_stub "mise" "#!/bin/bash
echo \"mise \$*\" >>\"\$CALL_LOG\"
if [ \"\${1:-}\" = \"env\" ] && [ \"\${2:-}\" = \"-s\" ]; then
  echo \"export PATH=\\\"${BIN_DIR}:\\\$PATH\\\"\"
fi
exit 0
"
  write_stub "node" '#!/bin/bash
exit 0
'
  write_stub "php" '#!/bin/bash
exit 0
'
  write_stub "python3" '#!/bin/bash
exit 0
'
  write_stub "grep" '#!/bin/bash
exit 1
'
  write_stub "chsh" '#!/bin/bash
exit 0
'
  write_stub "wget" '#!/bin/bash
exit 0
'
  write_stub "zsh" '#!/bin/bash
exit 0
'
  write_stub "sudo" '#!/bin/bash
exit 98
'

  export DOTFILES_INSTALL_FLYCTL=1
  dotfiles_run_script_clean "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run /usr/bin/grep -F "brew install flyctl" "${CALL_LOG}"
  [ "$status" -eq 0 ]
}
