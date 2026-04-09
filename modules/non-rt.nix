{ pkgs, lib, config, ... }:

{
  # ── Audio: PipeWire ────────────────────────────────────────────────
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    jack.enable = true;
    pulse.enable = true;
    socketActivation = true;
  };

  # ── Espanso ────────────────────────────────────────────────────────
  services.espanso.enable = true;

  # ── Virtualisation ─────────────────────────────────────────────────
  virtualisation = {
    virtualbox.host.enable = true;
    libvirtd.enable = true;
    docker.enable = true;
  };

  users.extraGroups.vboxusers.members = [ "bart" ];
  users.users.bart.extraGroups = [ "libvirtd" "docker" ];

  programs.virt-manager.enable = true;
  security.polkit.enable = true;

  environment.systemPackages = with pkgs; [
    spice
    spice-gtk
    usbredir
    virt-manager
    coppwr        # pipewire settings
  ];

  # ── ZFS maintenance (scrub, SMART, etc.) ───────────────────────────
  services.smartd = {
    enable = true;
    notifications.test = true;
    notifications.x11.enable = true;
  };

  services.zfs.autoScrub = {
    enable = true;
    interval = "Mon 03:00:00";
  };

  # ── Musnix (non-RT mode) ──────────────────────────────────────────
  musnix = {
    rtcqs.enable = true;
    rtirq.highList = "snd_hrtimer";
    rtirq.resetAll = 1;
    rtirq.prioLow = 0;
    alsaSeq.enable = false;
  };
}
