{
  pkgs,
  lib,
  config,
  ...
}:

{
  # ── Boot ────────────────────────────────────────────────────────────
  boot = {
    tmp.useTmpfs = true;
    kernelParams = [ "elevator=none" ];
  };

  # ── Networking ─────────────────────────────────────────────────────
  networking.useDHCP = false;

  # ── Users ──────────────────────────────────────────────────────────
  users = {
    groups.nixBuild = { };
    users.nixBuild = {
      name = "nixBuild";
      isSystemUser = true;
      useDefaultShell = true;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID1kJ2pCgAaixNICnm2WB6ILvE7+BTvNTaWPYBOvaXsv nixBuild"
      ];
      group = "nixBuild";
    };
  };

  nix.settings = {
    allowed-users = [
      "nixBuild"
      "@wheel"
    ];
    trusted-users = [ "nixBuild" ];
    download-buffer-size = 1073741824; # 1GB
  };

  # ── SSH hardening ──────────────────────────────────────────────────
  services.openssh = {
    ports = [ 511 ];
    settings.PermitRootLogin = "no";
    extraConfig = ''
      Match User nixBuild
        AllowAgentForwarding no
        AllowTcpForwarding no
        PermitTTY no
        PermitTunnel no
        X11Forwarding no
      Match All
        ClientAliveInterval 300
        ClientAliveCountMax 3
        TCPKeepAlive yes
    '';
  };

  # ── Firewall ────────────────────────────────────────────────────────
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 511 ]; # your SSH port
    allowedUDPPortRanges = [
      {
        from = 60000;
        to = 61000;
      }
    ]; # for mosh
    # add others as needed
  };

  # ── Services ────────────────────────────────────────────────────────
  services = {
    fail2ban = {
      enable = true;
      jails.sshd = lib.mkForce ''
        enabled = true
        filter = sshd
        maxretry = 3
        bantime = 3600
        ignoreip = 127.0.0.1/8,192.168.178.1/24
      '';
    };

    smartd.enable = true;

    zfs = {
      autoSnapshot.enable = true;
      autoScrub = {
        enable = true;
        interval = "weekly";
      };
      trim.enable = true;
    };
  };

  # ── Wake on LAN ────────────────────────────────────────────────────
  networking.interfaces.eno1.wakeOnLan.enable = true;

  systemd.services.wol-eth0 = {
    description = "Wake-on-LAN for eno1";
    requires = [ "network.target" ];
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.ethtool}/bin/ethtool -s eno1 wol g";
    };
  };

  # ── Mail (ZED notifications) ───────────────────────────────────────
  programs = {
    mosh.enable = true;
    msmtp = {
      enable = true;
      setSendmail = true;
      defaults = {
        aliases = "/etc/aliases";
        port = 465;
        tls_trust_file = "/etc/ssl/certs/ca-certificates.crt";
        tls = "on";
        auth = "login";
        tls_starttls = "off";
      };
      accounts.default = {
        host = "sub5.mail.dreamhost.com";
        passwordeval = "pass mail";
        user = "bart@magnetophon.nl";
        from = "bart@magnetophon.nl";
      };
    };
    gnupg.agent.enableSSHSupport = true;
  };

  # ── Server packages (beyond common) ───────────────────────────────
  environment.systemPackages = with pkgs; [
    smartmontools
    mkpasswd
    pinentry-curses
    thumbs # tmux-thumbs
    clang
    faust
    rmlint
    lm_sensors
    xclip
    haskellPackages.markdown
  ];

}
