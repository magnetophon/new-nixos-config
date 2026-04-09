{ pkgs, lib, config, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  networking = {
    hostId = "f2119c72";
    wireless.iwd.enable = true;
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
    };
  };

  system.stateVersion = "23.05";

  # ── Boot / ZFS ─────────────────────────────────────────────────────
  boot = {
    loader = {
      efi.efiSysMountPoint = "/boot/efi";
      efi.canTouchEfiVariables = false;
      generationsDir.copyKernels = true;
      grub = {
        enable = true;
        efiInstallAsRemovable = true;
        copyKernels = true;
        efiSupport = true;
        zfsSupport = true;
        devices = [ "/dev/disk/by-id/nvme-WD_BLACK_SN850X_1000GB_223761800744" ];
        extraInstallCommands = ''
          ESP_MIRROR=$(${pkgs.coreutils}/bin/mktemp -d)
          ${pkgs.coreutils}/bin/cp -r /boot/efi/EFI $ESP_MIRROR
          for i in /boot/efis/*; do
           ${pkgs.coreutils}/bin/cp -r $ESP_MIRROR/EFI $i
          done
          ${pkgs.coreutils}/bin/rm -rf $ESP_MIRROR
        '';
      };
    };
    kernelParams = [
      "zfs.zfs_arc_max=12884901888"
      "mem_sleep_default=deep"
    ];
    zfs.allowHibernation = true;
    zfs.forceImportRoot = false;
    zfs.forceImportAll = false;
    initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" ];
    kernelModules = [ "kvm-intel" ];
  };

  boot.resumeDevice = lib.mkIf (config.swapDevices != [ ])
    (lib.mkDefault (builtins.head config.swapDevices).device);

  fileSystems = {
    "/" = { device = "rpool/nixos/root"; fsType = "zfs"; options = [ "zfsutil" "X-mount.mkdir" ]; };
    "/home" = { device = "rpool/nixos/home"; fsType = "zfs"; options = [ "zfsutil" "X-mount.mkdir" ]; };
    "/home/bart/.cache" = { device = "rpool/nixos/home/bart_cache"; fsType = "zfs"; options = [ "zfsutil" "X-mount.mkdir" ]; };
    "/var/lib" = { device = "rpool/nixos/var/lib"; fsType = "zfs"; options = [ "zfsutil" "X-mount.mkdir" ]; };
    "/var/log" = { device = "rpool/nixos/var/log"; fsType = "zfs"; options = [ "zfsutil" "X-mount.mkdir" ]; };
    "/boot" = { device = "bpool/nixos/root"; fsType = "zfs"; options = [ "zfsutil" "X-mount.mkdir" ]; };
    "/boot/efis/nvme-WD_BLACK_SN850X_1000GB_223761800744-part1" = { device = "/dev/disk/by-uuid/A366-D51A"; fsType = "vfat"; };
    "/boot/efi" = { device = "/boot/efis/nvme-WD_BLACK_SN850X_1000GB_223761800744-part1"; fsType = "none"; options = [ "bind" ]; };
  };
  swapDevices = [{ device = "/dev/disk/by-label/swap"; }];

  # ── i3 ─────────────────────────────────────────────────────────────
  services.xserver = {
    dpi = 120;
    windowManager.i3.enable = true;
  };
  services.displayManager = {
    defaultSession = "none+i3";
    autoLogin = { enable = true; user = "bart"; };
  };

  # ── Framework specific ─────────────────────────────────────────────
  hardware.fw-fanctrl.enable = true;

  # Plugin paths (DSSI, LV2, etc.) are set automatically by musnix/NixOS.

  # ── Distributed builds ─────────────────────────────────────────────
  nix = {
    settings = {
      max-jobs = 0;
      trusted-users = [ "root" "nixBuild" "bart" ];
      builders-use-substitutes = true;
    };
    distributedBuilds = true;
    buildMachines = [{
      hostName = "builder";
      maxJobs = 16;
      sshKey = "/root/.ssh/id_nixBuild";
      sshUser = "nixBuild";
      system = "x86_64-linux";
      speedFactor = 4;
      supportedFeatures = [ "benchmark" "big-parallel" "kvm" "nixos-test" ];
      mandatoryFeatures = [ ];
    }];
  };
}
