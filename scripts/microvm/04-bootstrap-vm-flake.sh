#!/usr/bin/env bash
# Pre-flight for claude-microvm rollout, Commit 4.
# Mounts the claude-vm-disk zvol, seeds /persist/new-nixos-config from
# the host's flake clone (only if not already present, so commits made
# inside claude-vm aren't clobbered), sets bot ownership, and enables
# `git push` into the in-VM clone (the "VM repo accepts pushes from bart"
# mitigation).
set -euo pipefail

usage() {
  cat >&2 <<EOF
Usage: sudo $0 <nixframe|pronix> [flake-source-dir]

  flake-source-dir defaults to the current directory; it must contain a
  flake.nix and be a git working tree.
EOF
  exit 2
}

[ $# -ge 1 ] && [ $# -le 2 ] || usage
host="$1"
src="${2:-$PWD}"

if [ "$(id -u)" -ne 0 ]; then
  echo "error: must run as root (sudo)" >&2
  exit 1
fi

case "$host" in
  nixframe) zvol=/dev/zvol/rpool/nixos/microvms/claude-vm-disk ;;
  pronix)   zvol=/dev/zvol/sys_pool_2/microvms/claude-vm-disk ;;
  *) usage ;;
esac

[ -e "$zvol"       ] || { echo "error: $zvol missing — run 01-zfs.sh first" >&2; exit 1; }
[ -f "$src/flake.nix" ] || { echo "error: $src/flake.nix not found"            >&2; exit 1; }
[ -d "$src/.git"     ] || { echo "error: $src is not a git working tree"      >&2; exit 1; }

# Sanity-check the zvol is formatted.
fs="$(blkid -s TYPE -o value "$zvol" 2>/dev/null || true)"
[ "$fs" = "ext4" ] || { echo "error: $zvol is not ext4 (got '$fs') — run 02-mkfs-zvol.sh first" >&2; exit 1; }

mnt=/mnt/claude-vm-persist
mkdir -p "$mnt"

cleanup() { mountpoint -q "$mnt" && umount "$mnt" || true; }
trap cleanup EXIT

if ! mountpoint -q "$mnt"; then
  echo "==> mounting $zvol at $mnt"
  mount "$zvol" "$mnt"
fi

if [ ! -d "$mnt/new-nixos-config/.git" ]; then
  echo "==> bootstrapping $mnt/new-nixos-config from $src"
  mkdir -p "$mnt/new-nixos-config"
  rsync -aHAX \
    --exclude '/.direnv/' \
    --exclude '/result' \
    --exclude '/result-*' \
    --exclude '/secrets/' \
    "$src/" "$mnt/new-nixos-config/"
else
  echo "==> $mnt/new-nixos-config/.git already exists, leaving in-VM commits intact"
fi

# bot inside the VM is uid/gid 1002.
chown -R 1002:1002 "$mnt/new-nixos-config"

# Idempotent: re-setting the same value is a no-op.
git -C "$mnt/new-nixos-config" config receive.denyCurrentBranch updateInstead

echo
echo "==> done. Persistent flake clone at $mnt/new-nixos-config:"
( cd "$mnt/new-nixos-config" && git rev-parse --short HEAD && git status -s | head -20 )
