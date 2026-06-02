#!/usr/bin/env bash
# Wrapper for nixos-rebuild that refuses to proceed unless HEAD of the
# flake repo is signed by a key trusted by the invoking user (i.e., a
# key listed in their ~/.config/git/allowed_signers).
#
# Commits authored inside claude-vm are unsigned and will be rejected
# here; bart signs HEAD after reviewing the diff:
#   git commit -S --amend --no-edit
#
# Bart's fish function (per-machine path, not committed to the repo):
#   function nixos-rebuild
#     command sudo /home/bart/source/new-nixos-config/scripts/microvm/nixos-rebuild-verified.sh $argv
#   end
set -euo pipefail

flake_root="$(cd "$(dirname "$(readlink -f "$0")")/../.." && pwd)"

# git verify-commit must read the invoker's allowed_signers, not root's.
# SUDO_USER is set when this script is launched via sudo.
invoker="${SUDO_USER:-$USER}"

cd "$flake_root"

if ! sudo -u "$invoker" git verify-commit HEAD; then
  short="$(git rev-parse --short HEAD)"
  cat >&2 <<EOF
error: HEAD ($short) is not signed by a key in $invoker's
       ~/.config/git/allowed_signers. Refusing to rebuild.
       Review the diff, then sign with:
         git commit -S --amend --no-edit
EOF
  exit 1
fi

exec nixos-rebuild "$@"
