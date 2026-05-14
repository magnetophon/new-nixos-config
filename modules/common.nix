{
  pkgs,
  lib,
  config,
  self,
  ...
}:

{
  # ── Nix settings ────────────────────────────────────────────────────
  nix = {
    settings = {
      sandbox = true;
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
    package = pkgs.nixVersions.stable;
  };

  nixpkgs.config.allowUnfree = true;

  # ── Boot ────────────────────────────────────────────────────────────
  boot = {
    loader.timeout = 1;
    tmp.cleanOnBoot = true;
    blacklistedKernelModules = [
      "snd_pcsp"
      "pcspkr"
    ];
    supportedFilesystems = [ "zfs" ];
  };

  # ── Locale / timezone ──────────────────────────────────────────────
  time.timeZone = "Europe/Amsterdam";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_CTYPE = "nl_NL.UTF-8";
      LC_MONETARY = "nl_NL.UTF-8";
      LC_PAPER = "nl_NL.UTF-8";
      LC_NAME = "nl_NL.UTF-8";
      LC_ADDRESS = "nl_NL.UTF-8";
      LC_TELEPHONE = "nl_NL.UTF-8";
      LC_MEASUREMENT = "nl_NL.UTF-8";
      LC_IDENTIFICATION = "nl_NL.UTF-8";
    };
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "nl_NL.UTF-8/UTF-8"
    ];
  };

  # ── Users ───────────────────────────────────────────────────────────
  users = {
    defaultUserShell = pkgs.fish;
    users.bart = {
      name = "bart";
      group = "users";
      createHome = false;
      home = "/home/bart";
      extraGroups = [ "wheel" ];
      shell = pkgs.fish;
      isNormalUser = true;
    };
    mutableUsers = true;
  };

  # ── Programs ────────────────────────────────────────────────────────
  programs = {
    fish = {
      enable = true;
      promptInit = ''
        nix-your-shell fish | source
      '';
    };
    zsh.enable = true;
    zoxide.enable = true;
    neovim = {
      enable = true;
    };
    gnupg.agent.enable = true;
  };

  # ── Services ────────────────────────────────────────────────────────
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false; # add
      X11Forwarding = false; # add
      PermitRootLogin = "no"; # add (currently only in server.nix)
    };
  };
  services.smartd.enable = true;

  # ── Packages (CLI tools common to all hosts) ───────────────────────
  environment = {
    systemPackages = with pkgs; [
      # shells & terminal
      fish
      tmux
      zellij

      # editors
      emacs
      gnutls # for doom emacs irc
      nodejs # for doom lsp mode
      editorconfig-core-c
      pinentry-emacs
      zstd # for undo-tree compression
      vim
      evil-helix

      # git
      gitFull
      delta
      lazygit
      tig

      # file managers
      yazi-unwrapped
      ranger
      lf

      # file management / search
      ripgrep
      fd
      fzf
      skim
      eza
      tree
      bat
      bat-extras.batman

      # disk usage
      dust
      ncdu
      gdu

      # nix tooling
      nix-your-shell
      nixfmt
      nix-tree
      nix-du
      nix-diff
      nixpkgs-review
      nix-output-monitor
      nvd
      nix-index
      nix-prefetch-git
      nix-prefetch-scripts
      nixos-option
      comma
      manix
      deploy-rs

      # system monitoring
      htop
      bottom
      btop
      gotop

      # utilities
      wget
      curl
      coreutils
      gnumake
      cmake
      gcc
      unzip
      zip
      p7zip
      unar
      jq
      stow
      tealdeer
      gnupg
      pass

      # development
      rustup
      rust-analyzer
      cargo
      rustc
      lldb
      shfmt
      haskellPackages.ShellCheck
      python3

      # spell checking
      aspell
      aspellDicts.en
      aspellDicts.nl
      aspellDicts.de

      # misc
      sqlite
      pandoc
      mu
      isync
      imagemagickBig
      ollama
      fclones
      ethtool
    ];

    shells = with pkgs; [
      bashInteractive
      fish
      zsh
    ];

    variables = {
      DO_NOT_TRACK = "1";
    };
  };

  # ── Console ─────────────────────────────────────────────────────────
  console = {
    font = null;
    useXkbConfig = true;
    earlySetup = true;
    colors = [
      "eee8d5"
      "dc322f"
      "859900"
      "b58900"
      "268bd2"
      "d33682"
      "2aa198"
      "073642"
      "002b36"
      "cb4b16"
      "586e75"
      "839496"
      "657b83"
      "6c71c4"
      "586e75"
      "002b36"
    ];
  };

  # ── Security ────────────────────────────────────────────────────────
  security.rtkit.enable = true;

  security.pam.loginLimits = [
    {
      domain = "@audio";
      item = "memlock";
      type = "-";
      value = "unlimited";
    }
    {
      domain = "@audio";
      item = "rtprio";
      type = "-";
      value = "99";
    }
    {
      domain = "@audio";
      item = "nofile";
      type = "soft";
      value = "99999";
    }
    {
      domain = "@audio";
      item = "nofile";
      type = "hard";
      value = "99999";
    }
  ];
  hardware = {
    enableAllFirmware = true;
    cpu = {
      amd.updateMicrocode = true;
      intel.updateMicrocode = true;
    };
  };

  environment.sessionVariables = {
    NIXPKGS = "/home/bart/source/nixpkgs/";
    NIXPKGS_ALL = "/home/bart/source/nixpkgs/pkgs/top-level/all-packages.nix";
    EDITOR = "hx";
  };

  # ── Link full config into current profile ──────────────────────────
  system.systemBuilderCommands = ''
    ln -s ${self} $out/full-config
  '';

  # ── Telemetry opt-outs ─────────────────────────────────────────────
  environment.variables = {
    GATSBY_TELEMETRY_DISABLED = "1";
    HOMEBREW_NO_ANALYTICS = "1";
    STNOUPGRADE = "1";
    DOTNET_CLI_TELEMETRY_OPTOUT = "1";
    SAM_CLI_TELEMETRY = "0";
    AZURE_CORE_COLLECT_TELEMETRY = "0";
  };
}
