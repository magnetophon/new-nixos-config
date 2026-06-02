#!/usr/bin/env bash
# Step 1 of 3 — run on pronix as ROOT, ONCE.
# The only piece of the cross-host setup that needs root: seeding bart's
# pubkey into /home/bot/.ssh/authorized_keys so bart can `ssh bot@pronix`.
# Everything after this is done by bot (in their own home) and bart (in his
# own clone) without further privilege.
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

ssh_dir=/home/bot/.ssh
auth=$ssh_dir/authorized_keys

install -d -m 0700 -o bot -g bot "$ssh_dir"
[ -e "$auth" ] || install -m 0600 -o bot -g bot /dev/null "$auth"

bart_key="$(awk 'NF' "$pubkey")"
if grep -Fqx "$bart_key" "$auth"; then
  echo "==> bart's pubkey already in $auth, skipping"
else
  echo "$bart_key" >> "$auth"
  chown bot:bot "$auth"
  chmod 0600 "$auth"
  echo "==> appended bart's pubkey to $auth"
fi

cat <<EOF

==> done. Next, on nixframe as bart (using the dedicated key whose
    pubkey you just seeded):

  ssh -i ~/.ssh/id_ed25519_pronix_bot bot@pronix \\
      /home/bot/new-nixos-config/scripts/microvm/00b-bot-prep-repo.sh

  /home/bart/source/new-nixos-config/scripts/microvm/00c-bart-add-remote.sh
EOF
