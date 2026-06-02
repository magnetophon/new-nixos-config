#!/usr/bin/env bash
# Pre-flight for claude-microvm rollout, Commit 4.
# Seeds bart's pubkey into /home/bot/.config/claude-vm/authorized_keys so
# claude-vm can virtiofs-mount it RO at /run/host-ssh/authorized_keys
# for its sshd.
set -euo pipefail

usage() {
  cat >&2 <<EOF
Usage: sudo $0 <path-to-bart-pubkey>
EOF
  exit 2
}

[ $# -eq 1 ] || usage
pubkey="$1"

if [ "$(id -u)" -ne 0 ]; then
  echo "error: must run as root (sudo)" >&2
  exit 1
fi

[ -f "$pubkey" ] || { echo "error: $pubkey not found" >&2; exit 1; }

if ! grep -qE '^(ssh-(ed25519|rsa|dss)|ecdsa-)' "$pubkey"; then
  echo "error: $pubkey does not look like an OpenSSH public key" >&2
  exit 1
fi

dir=/home/bot/.config/claude-vm
dest=$dir/authorized_keys

install -d -m 0750 -o bot -g bot "$dir"
install -m 0644 -o bot -g bot "$pubkey" "$dest"

echo "==> seeded $dest:"
cat "$dest"
