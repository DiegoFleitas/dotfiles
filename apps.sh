#!/bin/bash
# Optional script: run manually after chezmoi apply. Installs extra apps listed in apps.conf.
# By default runs interactively: prompts for each app. Use -y/--yes to install all without prompting.

# set -x  # This will bash print each command before executing it.

# Function to display messages with separators
output_message() {
    echo "======================================="
    echo "$1"
    echo "======================================="
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPS_CONF="${SCRIPT_DIR}/apps.conf"

# Parse args:
# -y/--yes: install all without prompting
# --dry-run: don't install; print what would happen (useful for tests/CI)
INSTALL_ALL=false
DRY_RUN=false
for arg in "$@"; do
  case $arg in
    -y|--yes) INSTALL_ALL=true ;;
    --dry-run) DRY_RUN=true ;;
  esac
done

# Also allow env var (useful when you don't control argv, e.g. bats)
if [[ "${APPS_DRY_RUN:-}" == "1" ]]; then
  DRY_RUN=true
fi

if [[ "$INSTALL_ALL" == true ]]; then
  output_message "Installing all applications from config (non-interactive)..."
else
  output_message "Interactive mode: choose one or more applications to install."
fi

# Read apps.conf into arrays (skip comments/empty lines)
declare -a APP_NAMES APP_TYPES APP_DETECTIONS APP_SOURCES APP_SELECTED
if [[ ! -f "$APPS_CONF" ]]; then
  output_message "Error: config file not found: $APPS_CONF"
  exit 1
fi

while IFS=: read -r name type detection source || [[ -n "$name" ]]; do
  [[ "$name" =~ ^#.*$ || -z "$name" ]] && continue
  APP_NAMES+=("$name")
  APP_TYPES+=("$type")
  APP_DETECTIONS+=("$detection")
  APP_SOURCES+=("$source")
  APP_SELECTED+=(false)
done < "$APPS_CONF"

# Function to install applications from config file
install_app() {
  local name=$1
  local type=$2
  local detection=$3
  local source=$4

  output_message "Checking $name..."

  if [[ "$DRY_RUN" == true ]]; then
    output_message "DRY RUN: would install $name ($type: $source)"
    return 0
  fi

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

toggle_selection() {
  local idx="$1" # 0-based
  if [[ "${APP_SELECTED[idx]}" == true ]]; then
    APP_SELECTED[idx]=false
  else
    APP_SELECTED[idx]=true
  fi
}

run_picker() {
  local line token num idx
  while true; do
    echo ""
    echo "Select apps to install (default: none selected)."
    echo "Type numbers to toggle, or: all, none, done, q"
    echo ""

    for idx in "${!APP_NAMES[@]}"; do
      num=$((idx + 1))
      if [[ "${APP_SELECTED[$idx]}" == true ]]; then
        printf '%2s) [x] %s\n' "$num" "${APP_NAMES[$idx]}"
      else
        printf '%2s) [ ] %s\n' "$num" "${APP_NAMES[$idx]}"
      fi
    done

    echo ""
    read -r -p "Selection> " line
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"

    case "${line,,}" in
      q|quit|exit)
        output_message "No changes made."
        exit 0
        ;;
      done|install|go)
        return 0
        ;;
      all)
        for idx in "${!APP_SELECTED[@]}"; do
          APP_SELECTED[idx]=true
        done
        ;;
      none|clear)
        for idx in "${!APP_SELECTED[@]}"; do
          APP_SELECTED[idx]=false
        done
        ;;
      "")
        # no-op
        ;;
      *)
        for token in $line; do
          if [[ "$token" =~ ^[0-9]+$ ]]; then
            num="$token"
            idx=$((num - 1))
            if [[ $idx -ge 0 && $idx -lt ${#APP_NAMES[@]} ]]; then
              toggle_selection "$idx"
            else
              echo "Ignoring out-of-range selection: $token"
            fi
          else
            echo "Ignoring unknown token: $token"
          fi
        done
        ;;
    esac
  done
}

if [[ "$INSTALL_ALL" == true ]]; then
  for idx in "${!APP_SELECTED[@]}"; do
    APP_SELECTED[idx]=true
  done
else
  run_picker
fi

selected_any=false
for idx in "${!APP_NAMES[@]}"; do
  if [[ "${APP_SELECTED[$idx]}" == true ]]; then
    selected_any=true
    break
  fi
done

if [[ "$selected_any" != true ]]; then
  output_message "No applications selected. Exiting."
  exit 0
fi

for idx in "${!APP_NAMES[@]}"; do
  if [[ "${APP_SELECTED[$idx]}" == true ]]; then
    install_app "${APP_NAMES[$idx]}" "${APP_TYPES[$idx]}" "${APP_DETECTIONS[$idx]}" "${APP_SOURCES[$idx]}"
  fi
done
