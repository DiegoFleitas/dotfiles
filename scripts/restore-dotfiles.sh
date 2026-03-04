#!/usr/bin/env bash
# Restores dotfiles from a backup (e.g. after reinstall you want to go back).
# Usage: ./scripts/restore-dotfiles.sh [backup_dir]
#   backup_dir: path to a backup folder (e.g. .backups/2025-03-03T22-30-00). Default: latest in .backups

set -e
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUPS_DIR="$REPO_ROOT/.backups"

if [[ -n "$1" ]]; then
  BACKUP_DIR="$1"
else
  latest=""
  for d in "$BACKUPS_DIR"/*/; do
    [[ -d "$d" ]] || continue
    if [[ -z "$latest" || "$d" -nt "$latest" ]]; then
      latest="$d"
    fi
  done
  if [[ -z "$latest" ]]; then
    echo "No backups found in $BACKUPS_DIR"
    exit 1
  fi
  BACKUP_DIR="${latest%/}"
fi

if [[ ! -d "$BACKUP_DIR" ]]; then
  echo "Backup dir not found: $BACKUP_DIR"
  exit 1
fi

echo "Restoring from $BACKUP_DIR"

for f in .bashrc .zshrc .profile .gitconfig .nvmrc; do
  if [[ -f "$BACKUP_DIR/$f" ]]; then
    cp "$BACKUP_DIR/$f" "$HOME/$f"
    echo "  $f"
  fi
done

if [[ -d "$BACKUP_DIR/.config/chezmoi" ]]; then
  mkdir -p "$HOME/.config"
  rm -rf "$HOME/.config/chezmoi"
  cp -R "$BACKUP_DIR/.config/chezmoi" "$HOME/.config/chezmoi"
  echo "  .config/chezmoi/"
fi

echo "Done. Run: source ~/.profile (or open a new shell)"
