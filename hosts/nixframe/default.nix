{
  pkgs,
  lib,
  config,
  ...
}:

{
  imports = [ ./common.nix ];

  networking = {
    hostName = "nixframe";
    extraHosts = ''
      192.168.6.2 stratus.local
    '';
  };

  boot.loader.systemd-boot.memtest86.enable = true;

  # ── TLP ────────────────────────────────────────────────────────────
  services.tlp = {
    enable = true;
    settings = {
      START_CHARGE_THRESH_BAT0 = "70";
      STOP_CHARGE_THRESH_BAT0 = "90";
      CPU_SCALING_GOVERNOR_ON_AC = "powersave";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_BOOST_ON_AC = "1";
      CPU_BOOST_ON_BAT = "0";
      CPU_HWP_DYN_BOOST_ON_AC = "1";
      CPU_HWP_DYN_BOOST_ON_BAT = "0";
      CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      PCIE_ASPM_ON_BAT = "powersupersave";
      INTEL_GPU_MIN_FREQ_ON_BAT = "100";
      INTEL_GPU_MAX_FREQ_ON_BAT = "300";
      INTEL_GPU_BOOST_FREQ_ON_BAT = "300";
      SOUND_POWER_SAVE_ON_AC = "0";
      SOUND_POWER_SAVE_ON_BAT = "1";
      DEVICES_TO_DISABLE_ON_LAN_CONNECT = "wifi";
      DEVICES_TO_ENABLE_ON_LAN_DISCONNECT = "wifi";
    };
  };
  services.thermald.enable = true;

  services.fwupd.extraRemotes = [ "lvfs-testing" ];
  services.fwupd.uefiCapsuleSettings.DisableCapsuleUpdateOnDisk = true;

  services.smartd.devices = [ { device = "/dev/nvme0n1"; } ];

  services.udev.extraRules = ''
    ACTION=="add|change", SUBSYSTEM=="leds", KERNEL=="chromeos:multicolor:power", RUN+="${pkgs.coreutils}/bin/chmod 0666 /sys/class/leds/%k/multi_intensity"
  '';

  boot.binfmt.emulatedSystems = [ "armv7l-linux" ];

}
