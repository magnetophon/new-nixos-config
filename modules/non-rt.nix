{
  pkgs,
  lib,
  config,
  ...
}:

{
  # ── Boot extras for VMs (not wanted in RT mode) ────────────────────
  boot = {
    kernel.sysctl."net.ipv4.ip_forward" = 1; # for VM networking
    kernelModules = [
      "kvm-intel"
      "kvm-amd"
      "tun"
      "virtio"
    ];
  };

  # ── Hardware ────────────────────────────────────────────────────────
  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };

  # ── Services ───────────────────────────────────────────────────────
  services = {
    # Audio: PipeWire
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      jack.enable = true;
      pulse.enable = true;
      socketActivation = true;
    };

    espanso.enable = true;
    fstrim.enable = true;
    fwupd.enable = true;

    # ZFS maintenance
    smartd = {
      enable = true;
      notifications.test = true;
      notifications.x11.enable = true;
    };

    zfs.autoScrub = {
      enable = true;
      interval = "Mon 03:00:00";
    };
  };

  # ── Virtualisation ─────────────────────────────────────────────────
  virtualisation = {
    virtualbox.host.enable = true;
    libvirtd.enable = true;
    docker.enable = true;
  };

  users.extraGroups.vboxusers.members = [ "bart" ];
  users.users.bart.extraGroups = [
    "libvirtd"
    "docker"
  ];

  programs = {
    virt-manager.enable = true;
    direnv.enable = true;
  };
  security.polkit.enable = true;

  # ── Packages ───────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    spice
    spice-gtk
    usbredir
    virt-manager
    coppwr # pipewire settings
  ];
}
