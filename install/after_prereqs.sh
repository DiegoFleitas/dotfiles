#!/usr/bin/env bash
# System deps, brew bundle, nvm, bun, oh-my-zsh (chezmoi run_once_after_010_prereqs or direct).

# Function to display messages with separators
output_message() {
    echo "======================================="
    echo "$1"
    echo "======================================="
}

SCRIPT_DIR="$(cd -- "${BASH_SOURCE[0]%/*}" && pwd)"
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/codespaces.sh"
: "${NODE_VERSION:=24}"
: "${NVM_INSTALL_VERSION:=v0.40.3}"

if dotfiles_is_minimal_codespace; then
    output_message "Codespaces profile: $(dotfiles_codespace_profile) (set DOTFILES_CODESPACES_PROFILE=full for local-like installs)."
    # Defaults only when unset so DOTFILES_CODESPACES_PROFILE=full or explicit exports still win.
    : "${DOTFILES_INSTALL_APT:=0}"
    : "${DOTFILES_INSTALL_BREW:=0}"
    : "${DOTFILES_INSTALL_BUN:=0}"
    : "${DOTFILES_INSTALL_NVM:=0}"
    : "${DOTFILES_INSTALL_OHMYZSH:=0}"
fi

if [ "${DOTFILES_DISABLE_APT:-0}" = "1" ]; then
    HAS_APT=0
elif [ "$(uname -s)" = "Linux" ] && command -v apt >/dev/null 2>&1; then
    HAS_APT=1
else
    HAS_APT=0
fi

# Early return if root user (brew install errors out on root)
if [ "$(id -u)" -eq 0 ]; then
   output_message "Rerun as non root."
   exit 1
fi

# Non-interactive apt for headless/Codespaces/chezmoi: avoid dpkg conffile prompts (e.g. sshd_config).
apt_noninteractive() {
    sudo DEBIAN_FRONTEND=noninteractive apt-get \
        -y -q \
        -o Dpkg::Options::="--force-confdef" \
        -o Dpkg::Options::="--force-confold" \
        "$@"
}

### Essentials
if [ "${DOTFILES_INSTALL_APT:-1}" = "1" ] && [ "${HAS_APT}" -eq 1 ]; then
    # Update packages
    output_message "Updating apt packages..."
    apt_noninteractive update && apt_noninteractive upgrade

    # Install build essentials and required dependencies
    output_message "Installing apt build dependencies..."
    apt_noninteractive install \
      build-essential \
      libssl-dev \
      libffi-dev \
      python3-dev \
      zlib1g-dev \
      libbz2-dev \
      libreadline-dev \
      libsqlite3-dev \
      curl \
      git \
      wget \
      zsh
else
    if [ "${DOTFILES_INSTALL_APT:-1}" != "1" ]; then
        output_message "Skipping apt dependency setup (DOTFILES_INSTALL_APT=0)."
    else
        output_message "apt not available. Skipping apt dependency setup."
    fi
fi

# Install git if not already installed
if ! command -v git &> /dev/null; then
    output_message "Installing git..."
    if [ "${DOTFILES_INSTALL_APT:-1}" = "1" ] && [ "${HAS_APT}" -eq 1 ]; then
        apt_noninteractive install git
    else
        output_message "Package manager for git not detected. Install git manually."
    fi
fi

# Install curl if not already installed
if ! command -v curl &> /dev/null; then
    output_message "Installing curl..."
    if [ "${DOTFILES_INSTALL_APT:-1}" = "1" ] && [ "${HAS_APT}" -eq 1 ]; then
        apt_noninteractive install curl
    else
        output_message "Package manager for curl not detected. Install curl manually."
    fi
fi

# Install Homebrew if not already installed
if [ "${DOTFILES_INSTALL_BREW:-1}" = "1" ]; then
    if ! command -v brew &> /dev/null; then
        output_message "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    # Add brew to PATH unless tests request stub-only command resolution.
    if [ "${DOTFILES_BREW_USE_PATH_ONLY:-0}" != "1" ]; then
        if [ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
            eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        elif [ -x "/opt/homebrew/bin/brew" ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [ -x "/usr/local/bin/brew" ]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi
fi

### Development tools
# Bun (official installer; separate from nvm-managed Node)
if [ "${DOTFILES_INSTALL_BUN:-1}" = "1" ]; then
    BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
    export BUN_INSTALL
    if [ ! -x "$BUN_INSTALL/bin/bun" ]; then
        output_message "Installing bun..."
        curl -fsSL https://bun.com/install | bash
    fi
fi

# Install brew packages
if [ "${DOTFILES_INSTALL_BREW:-1}" = "1" ]; then
    output_message "Installing brew packages..."
    # Use Brewfile from chezmoi directory or fall back to this one
    brew bundle --file="${HOME}/.local/share/chezmoi/Brewfile" 2>/dev/null || brew bundle
fi

# nvm is a shell function loaded from nvm.sh, not a PATH binary; in non-interactive
# scripts (e.g. chezmoi) the usual executable lookup does not see it, so we test nvm.sh on disk.
NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
export NVM_DIR
if dotfiles_is_minimal_codespace; then
    output_message "Skipping nvm bootstrap (Codespaces minimal profile)."
elif [ "${DOTFILES_INSTALL_NVM:-1}" = "1" ]; then
    if [ ! -s "$NVM_DIR/nvm.sh" ] && ! dotfiles_nvm_sh_usable; then
        output_message "Installing nvm..."
        sh -c "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_INSTALL_VERSION}/install.sh | bash"
    fi
else
    output_message "Skipping nvm bootstrap (DOTFILES_INSTALL_NVM=0)."
fi

# Optional Fly.io CLI (left out of default Brewfile)
if [ "${DOTFILES_INSTALL_FLYCTL:-0}" = "1" ]; then
  if command -v brew &>/dev/null; then
    if command -v fly &>/dev/null || command -v flyctl &>/dev/null; then
      output_message "Fly CLI already installed; skipping flyctl."
    else
      output_message "DOTFILES_INSTALL_FLYCTL=1, installing flyctl..."
      brew install flyctl
    fi
  else
    output_message "DOTFILES_INSTALL_FLYCTL=1 but brew not found; skipping flyctl."
  fi
fi

# Install oh-my-zsh if not already installed
if [ "${DOTFILES_INSTALL_OHMYZSH:-1}" = "1" ]; then
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        output_message "Installing oh-my-zsh..."
        # RUNZSH flag for unattended installation (/bin/bash is portable in CI and tests)
        RUNZSH=no /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        # Stubbed installer output in tests does not create the install directory.
        mkdir -p "$HOME/.oh-my-zsh"
        # set zsh as default shell
        if [ -r /proc/version ] && grep -qi microsoft /proc/version; then
            # WSL detected - add to shell profile instead of chsh
            if [ -f "$HOME/.bashrc" ] && ! grep -qxF "exec zsh" "$HOME/.bashrc"; then
                echo "exec zsh" >> "$HOME/.bashrc"
            fi
        elif [ -n "${CODESPACE_NAME:-}" ]; then
            # GitHub Codespaces: chsh prompts for a password and blocks non-interactive bootstrap
            if [ -f "$HOME/.bashrc" ] && ! grep -qxF "exec zsh" "$HOME/.bashrc"; then
                echo "exec zsh" >> "$HOME/.bashrc"
            fi
        else
            if command -v chsh >/dev/null 2>&1; then
                chsh -s "$(command -v zsh)"
            fi
        fi
    fi
fi

output_message "Bye! (Run source ~/.profile to apply changes)"
