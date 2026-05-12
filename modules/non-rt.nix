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
      # Klark Teknik DW 20BR advertises both A2DP Source and Sink roles, causing
      # bluez to auto-connect both in parallel and one gets EBUSY. Pin to sink only.
      wireplumber.extraConfig."99-bluez" = {
        "monitor.bluez.properties" = {
          "bluez5.enable-sbc-xq" = true;
          "bluez5.enable-msbc" = true;
          "bluez5.enable-hw-volume" = true;
        };
        "monitor.bluez.rules" = [
          {
            matches = [ { "device.name" = "bluez_card.20_64_DE_FF_EB_70"; } ];
            actions = {
              update-props = {
                "bluez5.auto-connect" = [ "a2dp_sink" ];
              };
            };
          }
        ];
      };
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
