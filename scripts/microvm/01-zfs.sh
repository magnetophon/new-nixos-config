#!/usr/bin/env bash
# Pre-flight for claude-microvm rollout, Commit 2.
# Creates the bot dataset, projects dataset, microvms dataset, and
# claude-vm zvol on the chosen host. Idempotent: skips datasets that
# already exist.
set -euo pipefail

usage() {
  cat >&2 <<EOF
Usage: sudo $0 <nixframe|pronix>

Pool layouts:
  nixframe -> rpool/nixos/{home/bot, home/bot/projects, microvms, microvms/claude-vm-disk}
  pronix   -> sys_pool_2/{bot (shrink), bot-projects, microvms, microvms/claude-vm-disk}
EOF
  exit 2
}

[ $# -eq 1 ] || usage
host="$1"

if [ "$(id -u)" -ne 0 ]; then
  echo "error: must run as root (sudo)" >&2
  exit 1
fi

zfs_exists() { zfs list -H -o name "$1" >/dev/null 2>&1; }

case "$host" in
  nixframe)
    pool=rpool/nixos

    if ! zfs_exists "$pool/home/bot"; then
      echo "==> creating $pool/home/bot"
      systemctl stop user@1002.service 2>/dev/null || true
      # /home/bot is currently a plain directory inside the parent
      # rpool/nixos/home dataset; must be empty to be replaced.
      if [ -e /home/bot ]; then
        if [ -n "$(ls -A /home/bot 2>/dev/null)" ]; then
          echo "error: /home/bot is not empty; bailing to avoid data loss" >&2
          ls -la /home/bot >&2
          exit 1
        fi
        rmdir /home/bot
      fi
      zfs create -o mountpoint=legacy -o quota=5G "$pool/home/bot"
      mkdir /home/bot
      mount -t zfs "$pool/home/bot" /home/bot
      chown bot:bot /home/bot
      # 0750, not 2775: sshd's StrictModes refuses authorized_keys for a
      # group-writable home dir. The shared dir is /home/bot/projects below.
      chmod 0750 /home/bot
    else
      echo "==> $pool/home/bot already exists, skipping"
    fi

    if ! zfs_exists "$pool/home/bot/projects"; then
      echo "==> creating $pool/home/bot/projects"
      zfs create -o mountpoint=legacy -o quota=30G "$pool/home/bot/projects"
      mkdir -p /home/bot/projects
      mount -t zfs "$pool/home/bot/projects" /home/bot/projects
      chown bot:bot /home/bot/projects
      chmod 2775 /home/bot/projects
    else
      echo "==> $pool/home/bot/projects already exists, skipping"
    fi

    if ! zfs_exists "$pool/microvms"; then
      echo "==> creating $pool/microvms"
      zfs create -o mountpoint=/var/lib/microvms -o compression=lz4 \
        -o atime=off -o quota=30G "$pool/microvms"
    else
      echo "==> $pool/microvms already exists, skipping"
    fi

    if ! zfs_exists "$pool/microvms/claude-vm-disk"; then
      echo "==> creating $pool/microvms/claude-vm-disk (20G sparse zvol)"
      zfs create -V 20G -s -o compression=lz4 -o volblocksize=16k \
        "$pool/microvms/claude-vm-disk"
    else
      echo "==> $pool/microvms/claude-vm-disk already exists, skipping"
    fi
    ;;

  pronix)
    pool=sys_pool_2

    cur_quota="$(zfs get -H -o value quota "$pool/bot" 2>/dev/null || echo MISSING)"
    if [ "$cur_quota" = "MISSING" ]; then
      echo "error: $pool/bot does not exist on this host — wrong host?" >&2
      exit 1
    fi
    if [ "$cur_quota" != "5G" ]; then
      echo "==> shrinking $pool/bot quota: $cur_quota -> 5G"
      zfs set quota=5G "$pool/bot"
    else
      echo "==> $pool/bot already has quota=5G, skipping"
    fi

    if ! zfs_exists "$pool/bot-projects"; then
      echo "==> creating $pool/bot-projects"
      zfs create -o mountpoint=legacy -o quota=30G "$pool/bot-projects"
      mkdir -p /home/bot/projects
      mount -t zfs "$pool/bot-projects" /home/bot/projects
      chown bot:bot /home/bot/projects
      chmod 2775 /home/bot/projects
    else
      echo "==> $pool/bot-projects already exists, skipping"
    fi

    if ! zfs_exists "$pool/microvms"; then
      echo "==> creating $pool/microvms"
      zfs create -o mountpoint=/var/lib/microvms -o compression=lz4 \
        -o atime=off -o quota=30G "$pool/microvms"
    else
      echo "==> $pool/microvms already exists, skipping"
    fi

    if ! zfs_exists "$pool/microvms/claude-vm-disk"; then
      echo "==> creating $pool/microvms/claude-vm-disk (20G sparse zvol)"
      zfs create -V 20G -s -o compression=lz4 -o volblocksize=16k \
        "$pool/microvms/claude-vm-disk"
    else
      echo "==> $pool/microvms/claude-vm-disk already exists, skipping"
    fi
    ;;

  *)
    usage
    ;;
esac

echo
echo "==> done. Relevant datasets/zvols:"
zfs list -t all -o name,used,quota,mountpoint | grep -E 'bot|projects|microvm' || true
