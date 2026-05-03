#!/usr/bin/env bats
# Behavioral contracts for run_once_before_finalize.sh (stub-isolated HOME + PATH).

load 'helpers/common.bash'

setup() {
  dotfiles_clear_stub_path_conflicts
  REPO_ROOT="$(repo_root)"
  TARGET_FILE="${REPO_ROOT}/run_once_before_finalize.sh"
  TEST_TMPDIR="$(mktemp -d)"
  BIN_DIR="${TEST_TMPDIR}/bin"
  mkdir -p "${BIN_DIR}"
  export BIN_DIR
  CALL_LOG="${TEST_TMPDIR}/calls.log"
  : > "${CALL_LOG}"
  export CALL_LOG
  export PATH="${BIN_DIR}:/bin:/usr/bin"
  export HOME="${TEST_TMPDIR}/home"
  mkdir -p "${HOME}/.oh-my-zsh"
  cat >"${HOME}/.oh-my-zsh/oh-my-zsh.sh" <<'EOF'
omz() {
  return 0
}
EOF
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

stub_dirname() {
  write_stub "dirname" '#!/bin/bash
path="${1:-}"
path="${path%/}"
if [[ "${path}" != *"/"* ]]; then echo "."; else echo "${path%/*}"; fi
'
}

@test "before_finalize: skips chsh when WSL is detected" {
  stub_dirname
  write_stub "zsh" '#!/bin/bash
echo "zsh $*" >>"$CALL_LOG"
if [[ "${1:-}" == "-f" ]] && [[ "${2:-}" == "-c" ]]; then
  export ZSH="$HOME/.oh-my-zsh"
  # shellcheck disable=SC1091
  [ -f "$ZSH/oh-my-zsh.sh" ] && . "$ZSH/oh-my-zsh.sh"
  command -v omz >/dev/null 2>&1 && omz update
fi
exit 0
'
  write_stub "grep" '#!/bin/bash
echo "grep $*" >>"$CALL_LOG"
if [[ "$*" == *microsoft* ]] && [[ "$*" == *proc/version* ]]; then exit 0; fi
if [[ "$*" == */etc/shells ]]; then exit 1; fi
if [[ "${1:-}" == "-Eq" ]]; then exit 0; fi
exit 0
'
  write_stub "sudo" '#!/bin/bash
cat >/dev/null 2>&1 || true
echo "sudo $*" >>"$CALL_LOG"
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
  write_stub "corepack" '#!/bin/bash
exit 0
'

  export SHELL=/bin/bash
  dotfiles_run_script_clean "${TARGET_FILE}"
  [ "$status" -eq 0 ]
  [[ "$output" == *"WSL detected. Skipping chsh"* ]]
  run /usr/bin/grep -F "chsh -s" "${CALL_LOG}"
  [ "$status" -ne 0 ]
}

@test "before_finalize: invokes chsh when not WSL" {
  stub_dirname
  write_stub "zsh" '#!/bin/bash
echo "zsh $*" >>"$CALL_LOG"
if [[ "${1:-}" == "-f" ]] && [[ "${2:-}" == "-c" ]]; then
  export ZSH="$HOME/.oh-my-zsh"
  # shellcheck disable=SC1091
  [ -f "$ZSH/oh-my-zsh.sh" ] && . "$ZSH/oh-my-zsh.sh"
  command -v omz >/dev/null 2>&1 && omz update
fi
exit 0
'
  write_stub "grep" '#!/bin/bash
echo "grep $*" >>"$CALL_LOG"
if [[ "$*" == *microsoft* ]] && [[ "$*" == *proc/version* ]]; then exit 1; fi
if [[ "$*" == */etc/shells ]]; then exit 1; fi
if [[ "${1:-}" == "-Eq" ]]; then exit 0; fi
exit 0
'
  write_stub "sudo" '#!/bin/bash
cat >/dev/null 2>&1 || true
echo "sudo $*" >>"$CALL_LOG"
exit 0
'
  write_stub "chsh" '#!/bin/bash
echo "chsh $*" >>"$CALL_LOG"
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
  write_stub "corepack" '#!/bin/bash
exit 0
'

  export SHELL=/bin/bash
  dotfiles_run_script_clean "${TARGET_FILE}"
  [ "$status" -eq 0 ]
  run /usr/bin/grep -F "chsh -s" "${CALL_LOG}"
  [ "$status" -eq 0 ]
}

@test "before_finalize: skips optional full brew upgrade by default (DOTFILES_BREW_UPGRADE)" {
  stub_dirname
  write_stub "zsh" '#!/bin/bash
if [[ "${1:-}" == "-f" ]] && [[ "${2:-}" == "-c" ]]; then
  export ZSH="$HOME/.oh-my-zsh"
  # shellcheck disable=SC1091
  [ -f "$ZSH/oh-my-zsh.sh" ] && . "$ZSH/oh-my-zsh.sh"
  command -v omz >/dev/null 2>&1 && omz update
fi
exit 0
'
  write_stub "grep" '#!/bin/bash
if [[ "$*" == *microsoft* ]] && [[ "$*" == *proc/version* ]]; then exit 1; fi
if [[ "$*" == */etc/shells ]]; then exit 1; fi
if [[ "${1:-}" == "-Eq" ]]; then exit 0; fi
exit 0
'
  write_stub "sudo" '#!/bin/bash
exit 0
'
  write_stub "chsh" '#!/bin/bash
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
  write_stub "corepack" '#!/bin/bash
exit 0
'

  export SHELL=/bin/bash
  dotfiles_run_script_clean "${TARGET_FILE}"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Skipping brew upgrade by default"* ]]
}
