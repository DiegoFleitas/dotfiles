#!/usr/bin/env bash
# System deps, brew bundle, nvm, bun, oh-my-zsh, mise, optional pyenv (chezmoi run_once_after_010_prereqs or direct).

# Function to display messages with separators
output_message() {
    echo "======================================="
    echo "$1"
    echo "======================================="
}

SCRIPT_DIR="$(cd -- "${BASH_SOURCE[0]%/*}" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/codespaces.sh"
# shellcheck disable=SC1091
[ -f "${REPO_ROOT}/versions.env" ] && . "${REPO_ROOT}/versions.env"
: "${NODE_VERSION:=24}"
: "${PYTHON_VERSION:=3.12}"
: "${PHP_VERSION:=8.5}"
: "${NVM_INSTALL_VERSION:=v0.40.3}"

if dotfiles_is_minimal_codespace; then
    output_message "Codespaces profile: $(dotfiles_codespace_profile) (set DOTFILES_CODESPACES_PROFILE=full for local-like installs)."
    # Defaults only when unset so DOTFILES_CODESPACES_PROFILE=full or explicit exports still win.
    : "${DOTFILES_INSTALL_APT:=0}"
    : "${DOTFILES_INSTALL_BREW:=0}"
    : "${DOTFILES_INSTALL_BUN:=0}"
    : "${DOTFILES_INSTALL_MISE:=0}"
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
# nvm is a shell function loaded from nvm.sh, not a PATH binary; in non-interactive
# scripts (e.g. chezmoi) the usual executable lookup does not see it, so we test nvm.sh on disk.
NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
export NVM_DIR
if dotfiles_is_minimal_codespace; then
    output_message "Skipping nvm bootstrap (Codespaces minimal profile)."
elif [ ! -s "$NVM_DIR/nvm.sh" ] && ! dotfiles_nvm_sh_usable; then
    output_message "Installing nvm..."
    sh -c "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_INSTALL_VERSION}/install.sh | bash"
fi

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

# mise: polyglot tool versions (see dot_mise.toml)
if [ "${DOTFILES_INSTALL_MISE:-1}" = "1" ] && [ "${DOTFILES_INSTALL_BREW:-1}" = "1" ]; then
    # shellcheck disable=SC2034
    export MISE_CONFIG_FILE="${REPO_ROOT}/dot_mise.toml"
    if ! command -v mise &> /dev/null; then
        output_message "Installing mise..."
        brew install mise
    fi

    output_message "Installing toolchains via mise (see dot_mise.toml)..."
    # shellcheck source=mise_install_env.sh
    source "${SCRIPT_DIR}/mise_install_env.sh"
    mise install -y
    # Expose shims in this non-interactive script (same effect as `mise activate` in a shell).
    # shellcheck disable=SC1090
    eval "$(mise env -s bash 2>/dev/null)" || true

    if command -v node &> /dev/null && command -v python3 &> /dev/null && command -v php &> /dev/null; then
        output_message "mise toolchains are available (node, python3, php)."
    else
        output_message "Warning: expected mise shims not all on PATH yet; open a new shell after apply."
    fi
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

if [ "${DOTFILES_INSTALL_BREW:-1}" = "1" ]; then
    # Python: dot_mise.toml + mise activate own the default toolchain; pyenv would duplicate
    # work (slow source compile on Linux). Opt back in with DOTFILES_INSTALL_PYENV=1.
    _install_pyenv=0
    if [ "${DOTFILES_INSTALL_PYENV:-}" = "1" ]; then
        _install_pyenv=1
    elif [ "${DOTFILES_INSTALL_PYENV:-}" = "0" ]; then
        _install_pyenv=0
    elif [ "${DOTFILES_INSTALL_MISE:-1}" != "1" ]; then
        _install_pyenv=1
    fi

    if [ "${_install_pyenv}" -eq 1 ]; then
        if ! command -v pyenv &> /dev/null; then
            output_message "Installing pyenv..."
            brew install pyenv
        fi

        if command -v pyenv &> /dev/null; then
            if ! pyenv versions | grep -q "${PYTHON_VERSION}"; then
                output_message "Installing Python ${PYTHON_VERSION}..."
                pyenv install "${PYTHON_VERSION}"
                output_message "Setting global Python version to ${PYTHON_VERSION}..."
                pyenv global "${PYTHON_VERSION}"
            fi
        else
            output_message "pyenv not found after install attempt. Skipping Python setup."
        fi
    else
        output_message "Skipping pyenv (Python is managed by mise; set DOTFILES_INSTALL_PYENV=1 to use pyenv)."
    fi

    if command -v python3 &> /dev/null; then
        output_message "Python ${PYTHON_VERSION} is available on PATH."
    fi
fi

output_message "Bye! (Run source ~/.profile to apply changes)"
