#!/usr/bin/env bash
# Pre-flight for claude-microvm rollout, Commit 4.
# Formats the claude-vm-disk zvol as ext4 exactly once. Bails if any
# filesystem signature is already present (so re-running is safe).
set -euo pipefail

usage() {
  cat >&2 <<EOF
Usage: sudo $0 <nixframe|pronix>
EOF
  exit 2
}

[ $# -eq 1 ] || usage
host="$1"

if [ "$(id -u)" -ne 0 ]; then
  echo "error: must run as root (sudo)" >&2
  exit 1
fi

case "$host" in
  nixframe) zvol=/dev/zvol/rpool/nixos/microvms/claude-vm-disk ;;
  pronix)   zvol=/dev/zvol/sys_pool_2/microvms/claude-vm-disk ;;
  *) usage ;;
esac

if [ ! -e "$zvol" ]; then
  echo "error: $zvol does not exist — run 01-zfs.sh first" >&2
  exit 1
fi

existing_fs="$(blkid -s TYPE -o value "$zvol" 2>/dev/null || true)"
if [ -n "$existing_fs" ]; then
  echo "==> $zvol already has filesystem ($existing_fs), skipping"
  blkid "$zvol"
  exit 0
fi

echo "==> mkfs.ext4 on $zvol"
mkfs.ext4 -L claude-vm-disk "$zvol"
echo
echo "==> done:"
blkid "$zvol"
