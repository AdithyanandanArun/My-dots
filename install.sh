#!/usr/bin/env bash
set -euo pipefail
if [[ $EUID -eq 0 ]]; then echo 'Run as your normal user, not root.' >&2; exit 1; fi
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
backup="$HOME/.local/state/my-dots-backups/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$backup" "$HOME/.config" "$HOME/.local/bin" "$HOME/.local/share/icons" "$HOME/Pictures/noctalia-wallpapers" "$HOME/Pictures/Screenshots"
for cmd in niri noctalia kitty python3 systemctl; do command -v "$cmd" >/dev/null || { echo "Missing required command: $cmd" >&2; exit 1; }; done
if [[ "$HOME" == *$'\n'* || "$HOME" == *'"'* || "$HOME" == *'\\'* ]]; then echo 'Home paths containing quotes, backslashes or newlines are unsupported.' >&2; exit 1; fi
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
cp -a "$root/config/." "$stage/"
cp -a "$root/bin" "$stage/bin"
export MY_DOTS_HOME="$HOME" MY_DOTS_STAGE="$stage"
python3 - <<'PY'
import os
from pathlib import Path
root=Path(os.environ['MY_DOTS_STAGE'])
for p in root.rglob('*'):
    if p.is_file() and not p.is_symlink():
        try: text=p.read_text()
        except UnicodeDecodeError: continue
        p.write_text(text.replace('@HOME@', os.environ['MY_DOTS_HOME']))
PY
niri validate -c "$stage/niri/config.kdl"
noctalia config validate "$stage/noctalia/config.toml"
for item in niri noctalia kitty fastfetch fish environment.d; do
  if [[ -e "$HOME/.config/$item" ]]; then cp -a "$HOME/.config/$item" "$backup/$item"; fi
  mkdir -p "$HOME/.config/$item"
  cp -a "$stage/$item/." "$HOME/.config/$item/"
done
mkdir -p "$HOME/.config/systemd/user" "$backup/user-services" "$backup/bin" "$backup/icons"
for unit in awake-mode.service lock-before-sleep.service laptop-refresh-rate.service desktop-backup.service desktop-backup.timer; do
  [[ ! -e "$HOME/.config/systemd/user/$unit" ]] || cp -a "$HOME/.config/systemd/user/$unit" "$backup/user-services/"
  cp -a "$stage/systemd/user/$unit" "$HOME/.config/systemd/user/"
done
for script in awake-mode-monitor toggle-awake-mode lock-before-sleep laptop-refresh-rate backup-desktop-setup; do
  [[ ! -e "$HOME/.local/bin/$script" ]] || cp -a "$HOME/.local/bin/$script" "$backup/bin/"
  install -m 755 "$stage/bin/$script" "$HOME/.local/bin/$script"
done
if [[ -e "$HOME/.local/share/icons/W11-Concept-Dark-Smooth" ]]; then cp -a "$HOME/.local/share/icons/W11-Concept-Dark-Smooth" "$backup/icons/"; fi
cp -a "$root/icons/W11-Concept-Dark-Smooth" "$HOME/.local/share/icons/"
if command -v gsettings >/dev/null; then
  gsettings set org.gnome.desktop.interface cursor-theme 'W11-Concept-Dark-Smooth' || true
  gsettings set org.gnome.desktop.interface cursor-size 48 || true
fi
systemctl --user daemon-reload
systemctl --user enable --now desktop-backup.timer || true
systemctl --user set-environment XCURSOR_THEME=W11-Concept-Dark-Smooth XCURSOR_SIZE=48 || true
if command -v swayidle >/dev/null; then systemctl --user enable --now lock-before-sleep.service || true; fi
[[ ! -e "$HOME/.config/xdg-terminals.list" ]] || cp -a "$HOME/.config/xdg-terminals.list" "$backup/"
printf 'kitty.desktop\n' > "$HOME/.config/xdg-terminals.list"
echo "Installed. Existing files backed up to: $backup"
echo 'Add wallpapers to ~/Pictures/noctalia-wallpapers, then open Mod+Shift+W.'
echo 'Review README.md for optional SDDM, power-button and laptop refresh settings.'
