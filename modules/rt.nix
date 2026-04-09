{
  pkgs,
  lib,
  config,
  ...
}:

{
  # ── Disable non-essential services ─────────────────────────────────
  services = {
    tlp.enable = false;
    espanso.enable = lib.mkForce false;
    fstrim.enable = lib.mkForce false;
    pipewire.enable = false;
    zfs.autoScrub.enable = lib.mkForce false;
    zfs.autoSnapshot.enable = lib.mkForce false;
    zfs.trim.enable = lib.mkForce false;
    smartd.enable = lib.mkForce false;
  };

  # ── Disable virtualisation ─────────────────────────────────────────
  # (these are set in non-rt.nix, force them off here)
  virtualisation.virtualbox.host.enable = lib.mkForce false;
  virtualisation.libvirtd.enable = lib.mkForce false;
  virtualisation.docker.enable = lib.mkForce false;

  # ── Audio: JACK only ───────────────────────────────────────────────
  services.pulseaudio.enable = false;

  # boot.kernelPackages = pkgs.linuxPackages_6_12;
  musnix = {
    enable = true;
    kernel.realtime = true;
    # kernel.packages = pkgs.linuxPackages;
    kernel.packages = pkgs.linuxPackages_6_12;
    # kernel.packages = pkgs.linuxPackages_latest;
    rtirq.enable = true;
    das_watchdog.enable = true;
    rtcqs.enable = true;
    rtirq.highList = "snd_hrtimer";
    rtirq.resetAll = 1;
    rtirq.prioLow = 0;
    alsaSeq.enable = false;
  };

  services.jack = {
    jackd.session = "a2jmidid -e";
    alsa.enable = true;
  };

  # ── Packages: bare minimum for recording ───────────────────────────
  environment.systemPackages = with pkgs; [
    ardour
    jack2
    a2jmidid
    qjackctl
    alsa-utils
    carla
    jalv
    lilv
  ];
  boot.kernelParams = [
    "xe.force_probe=46a6"
    # your existing params...
  ];
}
