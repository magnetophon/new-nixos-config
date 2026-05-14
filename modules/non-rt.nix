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
      # "kvm-amd"
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

      # Bluetooth audio config for the Klark Teknik DW 20BR BT→XLR receiver.
      #
      # The "99-" prefix in the attribute name controls drop-in sort order — wireplumber
      # loads conf.d files alphabetically, later files override earlier ones for the same
      # keys. We want ours to win.
      wireplumber.extraConfig."99-bluez" = {

        # Monitor-level properties for bluez devices.
        "monitor.bluez.properties" = {
          # SBC-XQ: higher-bitrate variant of the mandatory SBC codec. Off by default in
          # PipeWire; turning it on means noticeably better quality when SBC is the
          # negotiated codec (i.e., when AAC/aptX/LDAC aren't available). No downside.
          "bluez5.enable-sbc-xq" = true;

          # The next two are PipeWire defaults already; setting them is redundant but
          # makes intent explicit and future-proofs against the defaults changing.
          "bluez5.enable-msbc" = true; # mSBC codec for HSP/HFP (call quality)
          "bluez5.enable-hw-volume" = true; # use device-side hardware volume control
        };

        # Per-device rules. Matched against properties of each discovered bluez device;
        # `update-props` adjusts the matched device's properties before policy runs.
        "monitor.bluez.rules" = [
          {
            # The Klark Teknik DW 20BR advertises BOTH A2DP Source AND A2DP Sink roles.
            # When bluez auto-connects on link-up, it tries to set up both profiles in
            # parallel; one wins the L2CAP socket, the other returns EBUSY from
            # btd_service_connect, and neither completes cleanly — you end up with the
            # device "connected" but no audio transport.
            #
            # Pin this device to a2dp_sink only (PC as A2DP Source, speaker as A2DP Sink).
            # That's the direction we want anyway (PC → speaker), and skipping the other
            # avoids the race entirely.
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
