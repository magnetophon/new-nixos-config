{
  pkgs,
  lib,
  config,
  ...
}:

{
  imports = [ ./hardware-configuration.nix ];

  networking = {
    hostName = "pronix";
    hostId = "392d5564";
    useDHCP = false;
    interfaces.eno1.useDHCP = true;
    interfaces.eno2.useDHCP = true;
    interfaces.eno3.useDHCP = true;
    interfaces.eno4.useDHCP = true;
  };

  system.stateVersion = "20.09";

  # ── Boot ────────────────────────────────────────────────────────────
  boot = {
    loader.grub = {
      enable = true;
      copyKernels = true;
      mirroredBoots = [
        {
          path = "/boot";
          devices = [ "/dev/disk/by-id/wwn-0x5000c500681b26fb" ];
        } # DISK17 (live /boot)
        {
          path = "/boot1";
          devices = [ "/dev/disk/by-id/wwn-0x5000c500684c2f73" ];
        } # DISK15
        {
          path = "/boot2";
          devices = [ "/dev/disk/by-id/wwn-0x5000c500763332ff" ];
        } # DISK18
      ];
    };
    tmp.useTmpfs = true;
    kernelParams = [ "elevator=none" ];
    zfs = {
      extraPools = [ "bu_pool" ];
      forceImportRoot = true;
    };
  };

  fileSystems = {
    "/" = {
      device = "sys_pool_2/root/nixos";
      fsType = "zfs";
    };
    "/boot" = {
      device = "/dev/disk/by-id/wwn-0x5000c500681b26fb-part2"; # sdf2 = the ESP
      fsType = "vfat";
      options = [
        "nofail"
        "umask=0077"
      ];
    };
    "/boot1" = {
      device = "/dev/disk/by-id/wwn-0x5000c500684c2f73-part2";
      fsType = "vfat";
      options = [
        "nofail"
        "umask=0077"
      ];
    };
    "/boot2" = {
      device = "/dev/disk/by-id/wwn-0x5000c500763332ff-part2";
      fsType = "vfat";
      options = [
        "nofail"
        "umask=0077"
      ];
    };
    "/home" = {
      device = "sys_pool_2/home";
      fsType = "zfs";
    };
    "/home/bot" = {
      device = "sys_pool_2/bot";
      fsType = "zfs";
    };
  };

  swapDevices = [ { device = "/dev/disk/by-id/wwn-0x5000c5005f5cb3b3-part1"; } ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
}
