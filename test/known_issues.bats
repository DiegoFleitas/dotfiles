#!/usr/bin/env bats
#
# Documented triage of a bug report received against commit a405f4f
# ("fix(chezmoi): gate prompts on .chezmoi.interactive for Codespaces bootstrap").
#
# Each @test below encodes the *desired* behavior described by the report. They
# are all `skip`ped with a reason so the suite stays green while the analysis
# stays discoverable in test output. Two categories:
#
#   - "Verified … not a bug": confirmed working as designed. Skip reason explains
#     why the report's premise is wrong; the assertion would only flip green if
#     the design changed.
#   - "TODO …": real pre-existing observation worth fixing later. Skip reason
#     points at the file/lines and at the intended fix; the assertion would flip
#     green once the fix lands.
#
# When picking up one of the TODOs: remove the `skip` line and the test should
# describe the contract you need to satisfy.

load 'helpers/common.bash'

setup() {
  REPO_ROOT="$(repo_root)"
  BEFORE_FILE="${REPO_ROOT}/install/before_finalize.sh"
  GITCONFIG_TMPL="${REPO_ROOT}/dot_gitconfig.tmpl"
}

@test "is_wsl explicitly guards on grep availability and /proc/version readability" {
  skip "Verified 2026-05-09: not a bug. 'grep -qi microsoft /proc/version 2>/dev/null' returns non-zero (false) safely when /proc/version is missing or grep is unavailable. is_wsl is only invoked inside 'if is_wsl; then', so set -e is suppressed for the conditional. No additional command -v / [ -r ] guard needed."

  run grep -F 'command -v grep' "${BEFORE_FILE}"
  [ "$status" -eq 0 ]

  run grep -F '[ -r /proc/version ]' "${BEFORE_FILE}"
  [ "$status" -eq 0 ]
}

@test "before_finalize guards chsh invocation on command -v chsh" {
  skip "TODO (pre-existing, not introduced by Codespaces fix): chsh is unconditionally invoked on the non-WSL branch (install/before_finalize.sh:49). chsh is universal on Debian/Ubuntu via the passwd package, but a 'command -v chsh' guard would be safer for minimal/Alpine/container images. Compare with after_prereqs.sh:182 which already uses 'command -v chsh >/dev/null 2>&1'."

  run grep -F 'command -v chsh >/dev/null 2>&1' "${BEFORE_FILE}"
  [ "$status" -eq 0 ]
}

@test "dot_gitconfig.tmpl references the .chezmoi.toml.tmpl variable names \$gitName/\$gitEmail" {
  skip "Verified 2026-05-09 via 'chezmoi execute-template': not a bug. dot_gitconfig.tmpl declares its own locals \$name / \$email (populated from .git.name and .git.email that .chezmoi.toml.tmpl writes into the toml as 'git = { name = ..., email = ... }'). The two templates have separate variable scopes; the [user] block renders correctly when git data is present (rendered output: 'name = \"DiegoFleitas\" / email = \"diego.fleitas68@gmail.com\"')."

  run grep -F '$gitName' "${GITCONFIG_TMPL}"
  [ "$status" -eq 0 ]

  run grep -F '$gitEmail' "${GITCONFIG_TMPL}"
  [ "$status" -eq 0 ]
}
