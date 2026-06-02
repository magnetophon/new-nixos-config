#!/usr/bin/env bash
# Step 3 of 3 — run on nixframe as BART. Wires bart's clone to pull/push
# from bot@pronix:new-nixos-config using the dedicated key from
# 00a/00b. If bart doesn't have a clone yet, clones it from pronix.
# Otherwise adds `pronix` as a second remote. Either way, pins
# `core.sshCommand` so subsequent git ops use the dedicated key without
# touching bart's global ~/.ssh/config.
# No sudo. Everything stays inside bart's home.
#
# Generate the key first (one-liner):
#   ssh-keygen -t ed25519 -N '' -C "bart -> bot@pronix" -f ~/.ssh/id_ed25519_pronix_bot
set -euo pipefail

usage() {
  cat >&2 <<EOF
Usage: $0 [identity-file [bart-clone-dir]]

  identity-file   SSH private key for bart -> bot@pronix
                  default: \$HOME/.ssh/id_ed25519_pronix_bot
  bart-clone-dir  default: /home/bart/source/new-nixos-config
EOF
  exit 2
}

[ $# -le 2 ] || usage
key="${1:-$HOME/.ssh/id_ed25519_pronix_bot}"
clone="${2:-/home/bart/source/new-nixos-config}"

if [ "$(id -un)" != "bart" ]; then
  echo "error: must run as user 'bart' (got $(id -un))" >&2
  exit 1
fi

if [ ! -f "$key" ]; then
  cat >&2 <<EOF
error: $key not found. Generate it first:
  ssh-keygen -t ed25519 -N '' -C "bart -> bot@pronix" -f $key
then seed the matching pubkey via 00a-root-seed-bot-ssh.sh on pronix.
EOF
  exit 1
fi

ssh_cmd="ssh -i $key -o IdentitiesOnly=yes"

if [ ! -d "$clone/.git" ]; then
  echo "==> $clone not present; cloning bot@pronix:new-nixos-config with $key"
  mkdir -p "$(dirname "$clone")"
  GIT_SSH_COMMAND="$ssh_cmd" git clone bot@pronix:new-nixos-config "$clone"
  git -C "$clone" config core.sshCommand "$ssh_cmd"
  echo "==> pinned core.sshCommand to use $key"
else
  echo "==> $clone already a git working tree"
  if git -C "$clone" remote get-url pronix >/dev/null 2>&1; then
    echo "==> 'pronix' remote already configured: $(git -C "$clone" remote get-url pronix)"
  else
    git -C "$clone" remote add pronix bot@pronix:new-nixos-config
    echo "==> added 'pronix' remote -> bot@pronix:new-nixos-config"
  fi
  git -C "$clone" config core.sshCommand "$ssh_cmd"
  echo "==> pinned core.sshCommand to use $key"
  git -C "$clone" fetch pronix
fi

cat <<EOF

==> done. Workflow:
  git pull pronix main          # fetch claude's commits for review
  git log -p pronix/main..HEAD  # diff before applying
  git push pronix main          # optional — push back to pronix/bot
EOF
