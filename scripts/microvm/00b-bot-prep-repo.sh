#!/usr/bin/env bash
# Step 2 of 3 — run on pronix as BOT (typically invoked by bart over ssh
# after 00a has seeded bart's pubkey into bot's authorized_keys). Sets up
# bot's clone to be the canonical source: clones it from origin if it
# isn't there yet, and enables push-into-checked-out-branch so bart can
# push back.
# No sudo. Everything stays inside /home/bot.
set -euo pipefail

usage() {
  cat >&2 <<EOF
Usage: $0 [origin-url]

  origin-url  used only if ~/new-nixos-config does not exist;
              default: https://github.com/magnetophon/new-nixos-config
EOF
  exit 2
}

[ $# -le 1 ] || usage
origin_url="${1:-https://github.com/magnetophon/new-nixos-config}"

if [ "$(id -un)" != "bot" ]; then
  echo "error: must run as user 'bot' (got $(id -un))" >&2
  exit 1
fi

repo=$HOME/new-nixos-config

if [ ! -d "$repo/.git" ]; then
  echo "==> cloning $origin_url into $repo"
  git clone "$origin_url" "$repo"
else
  echo "==> $repo already a git working tree, skipping clone"
fi

cur="$(git -C "$repo" config receive.denyCurrentBranch 2>/dev/null || true)"
if [ "$cur" = "updateInstead" ]; then
  echo "==> receive.denyCurrentBranch already updateInstead, skipping"
else
  git -C "$repo" config receive.denyCurrentBranch updateInstead
  echo "==> set receive.denyCurrentBranch = updateInstead"
fi

echo
echo "==> done. bart can now:"
echo "  git clone bot@pronix:new-nixos-config /home/bart/source/new-nixos-config"
echo "or, if bart already has a clone, run 00c-bart-add-remote.sh."
