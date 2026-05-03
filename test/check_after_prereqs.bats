#!/usr/bin/env bats
# Behavioral contracts for run_once_after_prereqs.sh (stub-isolated; see after_prereqs_behavior.bats).

load 'helpers/common.bash'

setup() {
  dotfiles_clear_stub_path_conflicts
  REPO_ROOT="$(repo_root)"
  TARGET_FILE="${REPO_ROOT}/run_once_after_prereqs.sh"
  TEST_TMPDIR="$(mktemp -d)"
  BIN_DIR="${TEST_TMPDIR}/bin"
  mkdir -p "${BIN_DIR}"
  export BIN_DIR
  CALL_LOG="${TEST_TMPDIR}/calls.log"
  : > "${CALL_LOG}"
  export CALL_LOG
  # Omit /usr/bin so system `apt` is not picked up (HAS_APT=0); stubs supply dirname, etc.
  export PATH="${BIN_DIR}:/bin:/usr/bin"
  export DOTFILES_BREW_USE_PATH_ONLY=1
  export DOTFILES_DISABLE_APT=1
  unset DOTFILES_INSTALL_FLYCTL 2>/dev/null || true
  export HOME="${TEST_TMPDIR}/home"
  mkdir -p "${HOME}"
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

# brew bundle strict-mode: test_python/test_run_once_behavior.py::test_after_prereqs_brew_bundle_failure_aborts


@test "after_prereqs: bun installer curl runs when bun binary is missing" {
  mkdir -p "${HOME}/.oh-my-zsh"

  write_stub "uname" '#!/bin/bash
echo "Linux"
'
  write_stub "dirname" '#!/bin/bash
path="${1:-}"
path="${path%/}"
if [[ "${path}" != *"/"* ]]; then echo "."; else echo "${path%/*}"; fi
'
  write_stub "id" '#!/bin/bash
if [ "${1:-}" = "-u" ]; then echo 1000; exit 0; fi
echo 1000
'
  write_stub "git" '#!/bin/bash
exit 0
'
  write_stub "curl" '#!/bin/bash
echo "curl $*" >>"$CALL_LOG"
exit 0
'
  write_stub "brew" '#!/bin/bash
echo "brew $*" >>"$CALL_LOG"
case "${1:-}" in shellenv|bundle|install) exit 0 ;; esac
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
exit 1
'
  write_stub "python3" '#!/bin/bash
exit 0
'
  write_stub "wget" '#!/bin/bash
exit 0
'
  write_stub "zsh" '#!/bin/bash
exit 0
'
  write_stub "chsh" '#!/bin/bash
exit 0
'
  write_stub "sudo" '#!/bin/bash
exit 98
'
  stub_bash_forwarder

  rm -rf "${HOME}/.bun"

  dotfiles_run_script_clean "${TARGET_FILE}"
  [ "$status" -eq 0 ]
  dotfiles_call_log_must_contain "curl -fsSL https://bun.com/install"
}

@test "after_prereqs: brew bundle runs before flyctl when DOTFILES_INSTALL_FLYCTL=1" {
  mkdir -p "${HOME}/.oh-my-zsh"
  mkdir -p "${HOME}/.bun/bin"
  printf '%s\n' '#!/bin/bash' >"${HOME}/.bun/bin/bun"
  chmod +x "${HOME}/.bun/bin/bun"

  write_stub "uname" '#!/bin/bash
echo "Linux"
'
  write_stub "dirname" '#!/bin/bash
path="${1:-}"
path="${path%/}"
if [[ "${path}" != *"/"* ]]; then echo "."; else echo "${path%/*}"; fi
'
  write_stub "id" '#!/bin/bash
if [ "${1:-}" = "-u" ]; then echo 1000; exit 0; fi
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
case "${1:-}" in shellenv|bundle|install) exit 0 ;; esac
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
if [ "${1:-}" = "-q" ] && [ -n "${2:-}" ]; then
  pattern="${2:-}"
  input="$(cat)"
  case "${input}" in *"${pattern}"*) exit 0 ;; *) exit 1 ;; esac
fi
exit 2
'
  write_stub "python3" '#!/bin/bash
exit 0
'
  write_stub "wget" '#!/bin/bash
exit 0
'
  write_stub "zsh" '#!/bin/bash
exit 0
'
  write_stub "chsh" '#!/bin/bash
exit 0
'
  write_stub "sudo" '#!/bin/bash
exit 98
'
  stub_bash_forwarder

  export DOTFILES_INSTALL_FLYCTL=1
  dotfiles_run_script_clean "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  bundle_line="$(/usr/bin/grep -n "brew bundle" "${CALL_LOG}" | head -1 | cut -d: -f1)"
  fly_line="$(/usr/bin/grep -n "brew install flyctl" "${CALL_LOG}" | head -1 | cut -d: -f1)"
  [ -n "${bundle_line}" ]
  [ -n "${fly_line}" ]
  [ "${bundle_line}" -lt "${fly_line}" ]
}

@test "after_prereqs: output references mise toolchain install" {
  mkdir -p "${HOME}/.oh-my-zsh"
  mkdir -p "${HOME}/.bun/bin"
  printf '%s\n' '#!/bin/bash' >"${HOME}/.bun/bin/bun"
  chmod +x "${HOME}/.bun/bin/bun"

  write_stub "uname" '#!/bin/bash
echo "Linux"
'
  write_stub "dirname" '#!/bin/bash
path="${1:-}"
path="${path%/}"
if [[ "${path}" != *"/"* ]]; then echo "."; else echo "${path%/*}"; fi
'
  write_stub "id" '#!/bin/bash
if [ "${1:-}" = "-u" ]; then echo 1000; exit 0; fi
echo 1000
'
  write_stub "git" '#!/bin/bash
exit 0
'
  write_stub "curl" '#!/bin/bash
exit 0
'
  write_stub "brew" '#!/bin/bash
case "${1:-}" in shellenv|bundle|install) exit 0 ;; esac
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
if [ "${1:-}" = "-q" ] && [ -n "${2:-}" ]; then
  pattern="${2:-}"
  input="$(cat)"
  case "${input}" in *"${pattern}"*) exit 0 ;; *) exit 1 ;; esac
fi
exit 2
'
  write_stub "python3" '#!/bin/bash
exit 0
'
  write_stub "wget" '#!/bin/bash
exit 0
'
  write_stub "zsh" '#!/bin/bash
exit 0
'
  write_stub "chsh" '#!/bin/bash
exit 0
'
  write_stub "sudo" '#!/bin/bash
exit 98
'
  stub_bash_forwarder

  dotfiles_run_script_clean "${TARGET_FILE}"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Installing toolchains via mise"* ]]
}
