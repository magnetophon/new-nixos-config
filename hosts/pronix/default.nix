{ pkgs, lib, config, ... }:

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
      devices = [
        "/dev/disk/by-id/wwn-0x5000c500684c2f73"  # DISK15
        "/dev/disk/by-id/wwn-0x5000c500681b26fb"  # DISK17
        "/dev/disk/by-id/wwn-0x5000c500763332ff"  # DISK18
      ];
    };
    tmp.useTmpfs = true;
    kernelParams = [ "elevator=none" ];
  };

  fileSystems = {
    "/" = { device = "sys_pool_2/root/nixos"; fsType = "zfs"; };
    "/home" = { device = "sys_pool_2/home"; fsType = "zfs"; };
  };
  boot.zfs.extraPools = [ "bu_pool" ];

  swapDevices = [{ device = "/dev/disk/by-id/wwn-0x5000c5005f5cb3b3-part1"; }];

  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
}
