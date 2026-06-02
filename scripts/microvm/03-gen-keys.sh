#!/usr/bin/env bash
# Pre-flight for claude-microvm rollout, Commit 4.
# Generates the two ed25519 keypairs claude-vm needs:
#   claude-ctl-key    -- claude-vm -> host claude-ctl   (restart claude-test-vm)
#   claude-build-key  -- claude-vm -> pronix claudeBuilder (build offload)
# Stores them under <repo>/secrets/. Skips any keypair that already exists.
# Prints the pubkeys so they can be pasted into the module placeholders
# (<<INLINE_PUBKEY_FROM_CLAUDE_VM>>, <<PUBKEY_OF_CLAUDE_VM_BUILD_KEY>>).
# Does NOT require root.
set -euo pipefail

script_dir="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
repo_root="$(git -C "$script_dir" rev-parse --show-toplevel 2>/dev/null)" \
  || { echo "error: $0 must live inside a git repo" >&2; exit 1; }

secrets="$repo_root/secrets"
mkdir -p "$secrets"
chmod 0700 "$secrets"

generate_one() {
  local name="$1" comment="$2"
  local priv="$secrets/$name"
  local pub="$priv.pub"
  if [ -e "$priv" ] || [ -e "$pub" ]; then
    echo "==> $name already exists, skipping" >&2
    return 0
  fi
  ssh-keygen -t ed25519 -N '' -C "$comment" -f "$priv" >/dev/null
  chmod 0600 "$priv"
  chmod 0644 "$pub"
  echo "==> generated $name" >&2
}

generate_one claude-ctl-key   "claude-vm -> host claude-ctl"
generate_one claude-build-key "claude-vm -> pronix claudeBuilder"

cat <<EOF

=== pubkey for <<INLINE_PUBKEY_FROM_CLAUDE_VM>> (claude-ctl) ===
$(cat "$secrets/claude-ctl-key.pub")

=== pubkey for <<PUBKEY_OF_CLAUDE_VM_BUILD_KEY>> (claudeBuilder) ===
$(cat "$secrets/claude-build-key.pub")
EOF
