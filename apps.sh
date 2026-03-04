#!/bin/bash
# Optional script: run manually after chezmoi apply. Installs extra apps listed in apps.conf.

# set -x  # This will bash print each command before executing it.

# Function to display messages with separators
output_message() {
    echo "======================================="
    echo "$1"
    echo "======================================="
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPS_CONF="${SCRIPT_DIR}/apps.conf"

# Install essential applications
output_message "Installing essential applications..."

# Function to install applications from config file
install_app() {
  local name=$1
  local type=$2
  local detection=$3
  local source=$4

  output_message "Checking $name..."
  
  # Check if already installed
  if eval "$detection" &>/dev/null; then
    output_message "$name is already installed."
    return 0
  fi

  output_message "Installing $name..."
  
  case $type in
    apt)
      sudo apt update
      sudo apt install -y "$source"
      ;;
    deb)
      wget -q "$source" -O /tmp/package.deb
      sudo apt install -y /tmp/package.deb
      rm /tmp/package.deb
      ;;
    snap)
      sudo snap install "$source"
      ;;
    repo)
      # For Docker and similar applications that need repos
      case $source in
        docker-ce)
          sudo apt update
          sudo apt install -y ca-certificates curl
          sudo install -m 0755 -d /etc/apt/keyrings
          sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
          sudo chmod a+r /etc/apt/keyrings/docker.asc
          echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
          sudo apt update
          sudo apt install -y docker-ce
          sudo usermod -aG docker "$USER"
          ;;
        *)
          output_message "Unknown repo: $source"
          return 1
          ;;
      esac
      ;;
    ppa)
      # For apps that need PPAs
      IFS=' ' read -r ppa_path package_name <<< "$source"
      sudo add-apt-repository -y "$ppa_path"
      sudo apt update
      sudo apt install -y "$package_name"
      ;;
  esac
  
  if eval "$detection" &>/dev/null; then
    output_message "$name installed successfully."
    return 0
  else
    output_message "WARNING: $name installation may have failed."
    return 1
  fi
}

# Read the app configuration file and install each app
if [[ ! -f "$APPS_CONF" ]]; then
  output_message "Error: config file not found: $APPS_CONF"
  exit 1
fi
while IFS=: read -r name type detection source || [[ -n "$name" ]]; do
  # Skip comments and empty lines
  [[ "$name" =~ ^#.*$ || -z "$name" ]] && continue
  
  install_app "$name" "$type" "$detection" "$source"
done < "$APPS_CONF"
