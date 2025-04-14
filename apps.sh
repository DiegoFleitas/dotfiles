#!/bin/bash
# This script will be executed by chezmoi prior to initiating the dotfiles installation. 
# This ensures that any required setup or prerequisites are addressed before the installation starts.

# set -x  # This will bash print each command before executing it.

# Function to display messages with separators
output_message() {
    echo "======================================="
    echo "$1"
    echo "======================================="
}

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
      sudo apt install -y $source
      ;;
    deb)
      wget -q "$source" -O /tmp/package.deb
      sudo apt install -y /tmp/package.deb
      rm /tmp/package.deb
      ;;
    snap)
      sudo snap install $source
      ;;
    repo)
      # For Docker and similar applications that need repos
      case $source in
        docker-ce)
          sudo apt update
          sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
          curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
          echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
          sudo apt update
          sudo apt install -y docker-ce
          sudo usermod -aG docker $USER
          ;;
      esac
      ;;
    ppa)
      # For apps that need PPAs
      IFS=' ' read -r ppa_path package_name <<< "$source"
      sudo add-apt-repository -y $ppa_path
      sudo apt update
      sudo apt install -y $package_name
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
while IFS=: read -r name type detection source || [[ -n "$name" ]]; do
  # Skip comments and empty lines
  [[ "$name" =~ ^#.*$ || -z "$name" ]] && continue
  
  install_app "$name" "$type" "$detection" "$source"
done < "/home/diego/environment/dotfiles/apps.conf"
