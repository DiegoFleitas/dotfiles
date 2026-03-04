#!/usr/bin/env bash
# Backs up dotfiles that chezmoi manages so you can restore after a reinstall.
# Usage: ./scripts/backup-dotfiles.sh [backups_dir]
# Default backups_dir: .backups (relative to repo root)

set -e
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUPS_DIR="${1:-$REPO_ROOT/.backups}"
TIMESTAMP="$(date +%Y-%m-%dT%H-%M-%S)"
BACKUP_DIR="$BACKUPS_DIR/$TIMESTAMP"

mkdir -p "$BACKUP_DIR"

echo "Backing up dotfiles to $BACKUP_DIR"

for f in .bashrc .zshrc .profile .gitconfig .nvmrc; do
  if [[ -e "$HOME/$f" ]]; then
    cp "$HOME/$f" "$BACKUP_DIR/$f"
    echo "  $f"
  fi
done

if [[ -d "$HOME/.config/chezmoi" ]]; then
  mkdir -p "$BACKUP_DIR/.config"
  cp -R "$HOME/.config/chezmoi" "$BACKUP_DIR/.config/chezmoi"
  echo "  .config/chezmoi/"
fi

echo "Done. Backup at: $BACKUP_DIR"
