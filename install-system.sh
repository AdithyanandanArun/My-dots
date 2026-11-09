#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
if [[ ${1:-} != --sddm && ${1:-} != --power ]]; then echo 'Usage: sudo ./install-system.sh --sddm|--power' >&2; exit 1; fi
if [[ $EUID -ne 0 ]]; then echo 'Run with sudo.' >&2; exit 1; fi
backup="/var/backups/my-dots-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$backup"
if [[ $1 == --sddm ]]; then
 [[ ! -e /etc/sddm.conf.d ]] || cp -a /etc/sddm.conf.d "$backup/"
 [[ ! -e /usr/share/sddm/themes/pixie ]] || cp -a /usr/share/sddm/themes/pixie "$backup/pixie"
 mkdir -p /usr/share/sddm/themes/pixie /etc/sddm.conf.d
 cp -a "$root/system/sddm/pixie/." /usr/share/sddm/themes/pixie/
 printf '[Theme]\nCurrent=pixie\n' > /etc/sddm.conf.d/99-pixie.conf
else
 [[ ! -e /etc/systemd/logind.conf.d ]] || cp -a /etc/systemd/logind.conf.d "$backup/"
 install -Dm644 "$root/system/logind/90-lock-suspend.conf" /etc/systemd/logind.conf.d/90-lock-suspend.conf
 systemctl kill --kill-whom=main --signal=HUP systemd-logind.service
fi
echo "Backup: $backup"
