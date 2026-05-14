#!/usr/bin/env bats

load 'helpers/common.bash'

setup() {
  REPO_ROOT="$(repo_root)"
  TARGET_FILE="${REPO_ROOT}/install/after_prereqs.sh"
}

@test "after_prereqs defaults NODE_VERSION from dot_nvmrc via codespaces helper when not set" {
  run grep -F 'REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F 'dotfiles_default_node_version_from_nvmrc "${REPO_ROOT}"' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F ': "${NVM_INSTALL_VERSION:=v0.40.3}"' "${TARGET_FILE}"
  [ "$status" -eq 0 ]
}

@test "after_prereqs prints install overview before Bye message" {
  local overview_line bye_line
  overview_line="$(grep -n 'dotfiles_print_install_overview' "${TARGET_FILE}" | head -1 | cut -d: -f1)"
  bye_line="$(grep -n 'Bye! (Run source ~/.profile to apply changes)' "${TARGET_FILE}" | head -1 | cut -d: -f1)"
  [ -n "${overview_line}" ]
  [ -n "${bye_line}" ]
  [ "${overview_line}" -lt "${bye_line}" ]
}

@test "after_prereqs installs nvm only when nvm.sh is missing on disk" {
  run grep -F 'NVM_DIR="${NVM_DIR:-$HOME/.nvm}"' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F '[ ! -s "$NVM_DIR/nvm.sh" ]' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F 'nvm-sh/nvm/${NVM_INSTALL_VERSION}/install.sh' "${TARGET_FILE}"
  [ "$status" -eq 0 ]
}

@test "after_prereqs skips nvm bootstrap when DOTFILES_INSTALL_NVM=0" {
  run grep -F 'Skipping nvm bootstrap (DOTFILES_INSTALL_NVM=0).' "${TARGET_FILE}"
  [ "$status" -eq 0 ]
}

@test "after_prereqs installs bun via official curl installer when missing" {
  run grep -F 'curl -fsSL https://bun.com/install | bash' "${TARGET_FILE}"
  [ "$status" -eq 0 ]
}

@test "after_prereqs installs bun only when bun binary is missing" {
  run grep -F '[ ! -x "$BUN_INSTALL/bin/bun" ]' "${TARGET_FILE}"
  [ "$status" -eq 0 ]
}

@test "after_prereqs runs brew bundle (installs Brewfile packages e.g. jq)" {
  run grep -F 'brew bundle --file="${HOME}/.local/share/chezmoi/Brewfile"' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F '|| brew bundle' "${TARGET_FILE}"
  [ "$status" -eq 0 ]
}

@test "after_prereqs can install flyctl when DOTFILES_INSTALL_FLYCTL=1" {
  run grep -F 'DOTFILES_INSTALL_FLYCTL' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F 'brew install flyctl' "${TARGET_FILE}"
  [ "$status" -eq 0 ]
}

@test "after_prereqs flyctl opt-in defaults DOTFILES_INSTALL_FLYCTL to 0" {
  run grep -F '${DOTFILES_INSTALL_FLYCTL:-0}' "${TARGET_FILE}"
  [ "$status" -eq 0 ]
}

@test "after_prereqs uses non-interactive apt-get (avoids dpkg conffile prompts in headless envs)" {
  run grep -F 'apt_noninteractive()' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F 'DEBIAN_FRONTEND=noninteractive apt-get' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F -- '--force-confold' "${TARGET_FILE}"
  [ "$status" -eq 0 ]
}

@test "after_prereqs sources codespaces helpers for profile detection" {
  run grep -F '. "${SCRIPT_DIR}/codespaces.sh"' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F ': "${DOTFILES_INSTALL_APT:=0}"' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F 'Codespaces profile:' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F 'Skipping nvm bootstrap (Codespaces minimal profile).' "${TARGET_FILE}"
  [ "$status" -eq 0 ]
}

@test "after_prereqs gates apt brew bun nvm and oh-my-zsh on DOTFILES_INSTALL_* with default 1" {
  run grep -F '[ "${DOTFILES_INSTALL_APT:-1}" = "1" ] && [ "${HAS_APT}" -eq 1 ]' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F '[ "${DOTFILES_INSTALL_BREW:-1}" = "1" ]' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F '[ "${DOTFILES_INSTALL_BUN:-1}" = "1" ]' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F '[ "${DOTFILES_INSTALL_NVM:-1}" = "1" ]' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F '[ "${DOTFILES_INSTALL_OHMYZSH:-1}" = "1" ]' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F 'CODESPACE_NAME' "${TARGET_FILE}"
  [ "$status" -eq 0 ]
}

@test "after_prereqs runs brew bundle before optional flyctl install" {
  bundle_line="$(grep -n 'brew bundle --file="${HOME}/.local/share/chezmoi/Brewfile"' "${TARGET_FILE}" | head -1 | cut -d: -f1)"
  fly_line="$(grep -n 'brew install flyctl' "${TARGET_FILE}" | head -1 | cut -d: -f1)"
  [ -n "${bundle_line}" ]
  [ -n "${fly_line}" ]
  [ "${bundle_line}" -lt "${fly_line}" ]
}

@test "after_prereqs flyctl block skips install when fly or flyctl exists" {
  run grep -F 'command -v fly' "${TARGET_FILE}"
  [ "$status" -eq 0 ]

  run grep -F 'Fly CLI already installed; skipping flyctl.' "${TARGET_FILE}"
  [ "$status" -eq 0 ]
}

@test "after_prereqs flyctl block skips when brew missing" {
  run grep -F 'DOTFILES_INSTALL_FLYCTL=1 but brew not found; skipping flyctl.' "${TARGET_FILE}"
  [ "$status" -eq 0 ]
}
