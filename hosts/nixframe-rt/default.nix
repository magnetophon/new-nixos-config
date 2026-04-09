{
  pkgs,
  lib,
  config,
  ...
}:

{
  imports = [ ../nixframe/common.nix ];

  networking.hostName = "nixframe-rt";

  # ── JACK device config ─────────────────────────────────────────────
  musnix.rtirq.nameList = "rtc0 usb";

  services.jack.jackd.extraOptions = [
    "-P71"
    "-p2048"
    "-dalsa"
    "-dhw:USB"
    "-r48000"
    "-n3"
  ];
}
