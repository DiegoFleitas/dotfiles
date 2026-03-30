#!/usr/bin/env bats

load 'helpers/common.bash'

setup() {
  REPO_ROOT="$(repo_root)"
  TARGET_FILE="${REPO_ROOT}/run_once_after_prereqs.sh"

  TEST_TMPDIR="$(mktemp -d)"
  BIN_DIR="${TEST_TMPDIR}/bin"
  mkdir -p "${BIN_DIR}"

  CALL_LOG="${TEST_TMPDIR}/calls.log"
  : > "${CALL_LOG}"

  export CALL_LOG
  export PATH="${BIN_DIR}:${PATH}"

  # Isolate HOME so the script can't touch the real dotfiles.
  export HOME="${TEST_TMPDIR}/home"
  mkdir -p "${HOME}"

  # Prevent nvm install path.
  mkdir -p "${HOME}/.nvm"
  printf '%s\n' "# stub nvm.sh" > "${HOME}/.nvm/nvm.sh"

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

@test "after_prereqs exits early when run as root (no side-effect commands invoked)" {
  write_stub "uname" '#!/usr/bin/env bash
echo "uname $*" >>"$CALL_LOG"
echo "Linux"
'

  # Make id -u report root.
  write_stub "id" '#!/usr/bin/env bash
echo "id $*" >>"$CALL_LOG"
if [ "${1:-}" = "-u" ]; then
  echo 0
  exit 0
fi
echo 0
'

  # Side-effect commands should never run past the guard.
  write_stub "sudo" '#!/usr/bin/env bash
echo "sudo $*" >>"$CALL_LOG"
exit 99
'
  write_stub "apt" '#!/usr/bin/env bash
echo "apt $*" >>"$CALL_LOG"
exit 99
'
  write_stub "brew" '#!/usr/bin/env bash
echo "brew $*" >>"$CALL_LOG"
exit 99
'
  write_stub "curl" '#!/usr/bin/env bash
echo "curl $*" >>"$CALL_LOG"
exit 99
'

  run bash "${TARGET_FILE}"
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

  write_stub "uname" '#!/usr/bin/bash
echo "uname $*" >>"$CALL_LOG"
echo "Linux"
'

  write_stub "dirname" '#!/usr/bin/bash
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
  write_stub "id" '#!/usr/bin/bash
echo "id $*" >>"$CALL_LOG"
if [ "${1:-}" = "-u" ]; then
  echo 1000
  exit 0
fi
echo 1000
'

  # Ensure git/curl are considered installed (avoid apt installs).
  write_stub "git" '#!/usr/bin/bash
echo "git $*" >>"$CALL_LOG"
exit 0
'
  write_stub "curl" '#!/usr/bin/bash
echo "curl $*" >>"$CALL_LOG"
exit 0
'

  # Provide brew and all commands used later in the script.
  write_stub "brew" '#!/usr/bin/bash
echo "brew $*" >>"$CALL_LOG"
case "${1:-}" in
  shellenv) exit 0 ;;
  bundle) exit 0 ;;
  install) exit 0 ;;
esac
exit 0
'
  write_stub "pyenv" '#!/usr/bin/bash
echo "pyenv $*" >>"$CALL_LOG"
if [ "${1:-}" = "versions" ]; then
  printf "%s\n" "* 3.12.0 (set by stub)"
  exit 0
fi
exit 0
'
  write_stub "grep" '#!/usr/bin/bash
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
  write_stub "python3" '#!/usr/bin/bash
echo "python3 $*" >>"$CALL_LOG"
exit 0
'
  write_stub "chsh" '#!/usr/bin/bash
echo "chsh $*" >>"$CALL_LOG"
exit 0
'
  write_stub "wget" '#!/usr/bin/bash
echo "wget $*" >>"$CALL_LOG"
exit 0
'
  write_stub "zsh" '#!/usr/bin/bash
echo "zsh $*" >>"$CALL_LOG"
exit 0
'

  # If sudo is invoked, we want the test to fail fast.
  write_stub "sudo" '#!/usr/bin/bash
echo "sudo $*" >>"$CALL_LOG"
exit 98
'

  # Run the script with a minimal PATH consisting only of our stubs.
  # This guarantees `command -v apt` fails (so HAS_APT=0) and prevents any
  # real system commands/network/package managers from running.
  run /usr/bin/env PATH="${BIN_DIR}" /usr/bin/bash "${TARGET_FILE}"
  [ "$status" -eq 0 ]
  [[ "$output" == *"apt not available. Skipping apt dependency setup."* ]]

  run grep -F "sudo apt" "${CALL_LOG}"
  [ "$status" -ne 0 ]
}

@test "after_prereqs installs oh-my-zsh and appends exec zsh on WSL (idempotent guard path)" {
  # Force oh-my-zsh install path.
  rm -rf "${HOME}/.oh-my-zsh"

  write_stub "uname" '#!/usr/bin/bash
echo "uname $*" >>"$CALL_LOG"
echo "Linux"
'

  write_stub "dirname" '#!/usr/bin/bash
path="${1:-}"
path="${path%/}"
if [[ "${path}" != *"/"* ]]; then
  echo "."
else
  echo "${path%/*}"
fi
'

  write_stub "id" '#!/usr/bin/bash
if [ "${1:-}" = "-u" ]; then
  echo 1000
  exit 0
fi
echo 1000
'

  # Simulate WSL detection: `grep -qi microsoft /proc/version` should succeed.
  # Also support the idempotency guard: `grep -qxF "exec zsh" "$HOME/.bashrc"`.
  write_stub "grep" '#!/usr/bin/bash
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
  write_stub "git" '#!/usr/bin/bash
exit 0
'

  # This curl is used by the oh-my-zsh installer invocation.
  # The script does: `sh -c "$(curl -fsSL https://.../install.sh)"`.
  # We output a harmless shell snippet to prove that path ran.
  write_stub "curl" '#!/usr/bin/bash
echo "curl $*" >>"$CALL_LOG"
printf "%s\n" "echo OMZ_INSTALLER_RAN"
exit 0
'

  write_stub "sh" '#!/usr/bin/bash
echo "sh $*" >>"$CALL_LOG"
if [ "${1:-}" = "-c" ]; then
  /usr/bin/bash -c "${2:-}"
  exit $?
fi
exit 0
'

  write_stub "brew" '#!/usr/bin/bash
echo "brew $*" >>"$CALL_LOG"
exit 0
'
  write_stub "pyenv" '#!/usr/bin/bash
echo "pyenv $*" >>"$CALL_LOG"
if [ "${1:-}" = "versions" ]; then
  printf "%s\n" "* 3.12.0 (set by stub)"
  exit 0
fi
exit 0
'
  write_stub "python3" '#!/usr/bin/bash
exit 0
'
  write_stub "zsh" '#!/usr/bin/bash
exit 0
'
  write_stub "wget" '#!/usr/bin/bash
exit 0
'
  write_stub "chsh" '#!/usr/bin/bash
echo "chsh $*" >>"$CALL_LOG"
exit 0
'

  # Fail fast if sudo is invoked (it shouldn't be, since HAS_APT should be 0).
  write_stub "sudo" '#!/usr/bin/bash
echo "sudo $*" >>"$CALL_LOG"
exit 98
'

  run /usr/bin/env PATH="${BIN_DIR}" /usr/bin/bash "${TARGET_FILE}"
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
  # Use /bin/grep (not PATH-resolved grep) because this test stubs `grep`
  # for WSL detection + idempotency guard behavior.
  run /bin/grep -nFx "exec zsh" "${HOME}/.bashrc"
  [ "$status" -eq 0 ]

  # WSL branch should not chsh.
  # Use /bin/grep to keep assertions independent of our stubs.
  run /bin/grep -F "chsh " "${CALL_LOG}"
  [ "$status" -ne 0 ]
}

@test "after_prereqs installs oh-my-zsh and calls chsh on non-WSL" {
  rm -rf "${HOME}/.oh-my-zsh"

  write_stub "uname" '#!/usr/bin/bash
echo "Linux"
'

  write_stub "dirname" '#!/usr/bin/bash
path="${1:-}"
path="${path%/}"
if [[ "${path}" != *"/"* ]]; then
  echo "."
else
  echo "${path%/*}"
fi
'

  write_stub "id" '#!/usr/bin/bash
if [ "${1:-}" = "-u" ]; then
  echo 1000
  exit 0
fi
echo 1000
'

  # Non-WSL detection: make the microsoft grep check fail.
  write_stub "grep" '#!/usr/bin/bash
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

  write_stub "git" '#!/usr/bin/bash
exit 0
'
  write_stub "curl" '#!/usr/bin/bash
printf "%s\n" "echo OMZ_INSTALLER_RAN"
exit 0
'
  write_stub "sh" '#!/usr/bin/bash
if [ "${1:-}" = "-c" ]; then
  /usr/bin/bash -c "${2:-}"
  exit $?
fi
exit 0
'

  # `which zsh` is used in the non-WSL branch.
  write_stub "which" '#!/usr/bin/bash
if [ "${1:-}" = "zsh" ]; then
  echo "${BIN_DIR}/zsh"
  exit 0
fi
exit 1
'
  write_stub "zsh" '#!/usr/bin/bash
exit 0
'
  write_stub "chsh" '#!/usr/bin/bash
echo "chsh $*" >>"$CALL_LOG"
exit 0
'

  # Keep the rest harmless.
  write_stub "brew" '#!/usr/bin/bash
exit 0
'
  write_stub "pyenv" '#!/usr/bin/bash
if [ "${1:-}" = "versions" ]; then
  printf "%s\n" "* 3.12.0 (set by stub)"
  exit 0
fi
exit 0
'
  write_stub "python3" '#!/usr/bin/bash
exit 0
'
  write_stub "wget" '#!/usr/bin/bash
exit 0
'
  write_stub "sudo" '#!/usr/bin/bash
exit 98
'

  run /usr/bin/env PATH="${BIN_DIR}" /usr/bin/bash "${TARGET_FILE}"
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

  # Use /bin/grep (not PATH-resolved grep) because this test stubs `grep`
  # to force non-WSL behavior.
  run /bin/grep -F "chsh -s" "${CALL_LOG}"
  [ "$status" -eq 0 ]
}

@test "after_prereqs installs flyctl when DOTFILES_INSTALL_FLYCTL=1 and CLI absent" {
  mkdir -p "${HOME}/.oh-my-zsh"

  write_stub "uname" '#!/usr/bin/bash
echo "Linux"
'

  write_stub "dirname" '#!/usr/bin/bash
path="${1:-}"
path="${path%/}"
if [[ "${path}" != *"/"* ]]; then
  echo "."
else
  echo "${path%/*}"
fi
'

  write_stub "id" '#!/usr/bin/bash
if [ "${1:-}" = "-u" ]; then
  echo 1000
  exit 0
fi
echo 1000
'

  write_stub "git" '#!/usr/bin/bash
exit 0
'
  write_stub "curl" '#!/usr/bin/bash
exit 0
'

  write_stub "brew" '#!/usr/bin/bash
echo "brew $*" >>"$CALL_LOG"
case "${1:-}" in
  shellenv) exit 0 ;;
  bundle) exit 0 ;;
  install) exit 0 ;;
esac
exit 0
'
  write_stub "pyenv" '#!/usr/bin/bash
echo "pyenv $*" >>"$CALL_LOG"
if [ "${1:-}" = "versions" ]; then
  printf "%s\n" "* 3.12.0 (set by stub)"
  exit 0
fi
exit 0
'
  write_stub "python3" '#!/usr/bin/bash
exit 0
'
  write_stub "grep" '#!/usr/bin/bash
if [ "${1:-}" = "-q" ] && [ -n "${2:-}" ]; then
  if [ "${2:-}" = "3.12" ]; then
    exit 0
  fi
fi
exit 1
'
  write_stub "chsh" '#!/usr/bin/bash
exit 0
'
  write_stub "wget" '#!/usr/bin/bash
exit 0
'
  write_stub "zsh" '#!/usr/bin/bash
exit 0
'
  write_stub "sudo" '#!/usr/bin/bash
exit 98
'

  run /usr/bin/env PATH="${BIN_DIR}" DOTFILES_INSTALL_FLYCTL=1 /usr/bin/bash "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run /bin/grep -F "brew install flyctl" "${CALL_LOG}"
  [ "$status" -eq 0 ]
}
