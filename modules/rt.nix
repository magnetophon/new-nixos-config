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
    kernel.packages = pkgs.linuxPackages;
    # kernel.packages = pkgs.linuxPackages_6_12;
    # kernel.packages = pkgs.linuxPackages_latest;
    rtirq.enable = true;
    das_watchdog.enable = true;
    rtcqs.enable = true;
    # rtirq.highList = "snd_hrtimer";
    rtirq.resetAll = 1;
    rtirq.prioLow = 0;
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
  # ── Disable DPMS and screensaver blanking ──────────────────────────
  # Disable DPMS and screensaver blanking
  services.xserver.serverFlagsSection = ''
    Option "BlankTime" "0"
    Option "StandbyTime" "0"
    Option "SuspendTime" "0"
    Option "OffTime" "0"
  '';

  # ── no turbo: keep quiet ───────────────────────────────────────────
  systemd.services.disable-turbo = {
    description = "Disable CPU turbo boost";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-modules-load.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.bash}/bin/bash -c 'echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo'";
      ExecStop = "${pkgs.bash}/bin/bash -c 'echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo'";
    };
  };

  boot.kernelParams = [
    # to get graphics drivers on old kernel: 6.12
    # "xe.force_probe=46a6"
    # your existing params...
    # xe.force_probe='46a6'
    # i915.force_probe='!46a6
    "i915.force_probe=!46a6"
    "xe.force_probe=46a6"
  ];
}
