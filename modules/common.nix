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
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      keep-outputs = true;
      keep-derivations = true;
      stalled-download-timeout = 600;
    };
    optimise = {
      automatic = true;
      dates = [ "05:45" ];
    };
    package = pkgs.nixVersions.stable;
  };

  # Default: disallow unfree. Allowlist the specific packages actually used.
  # Names are matched against `lib.getName pkg` (pname or derivation name).
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      # microcode (cpu.intel.updateMicrocode)
      "intel-microcode"

      # graphics driver stack (hardware.graphics)
      "intel-ocl"

      # claude-sandbox (modules/claude-sandbox.nix)
      "claude-code"

      # steam-run (extras.nix)
      "steam-unwrapped"

      # dictionaries (extras.nix)
      "aspell-dict-en-science"

      # fonts (laptop.nix)
      "corefonts"

      # DAWs / audio (music.nix)
      "bitwig-studio6"
      "reaper"
      "x32-edit"
      "vst2-sdk" # pulled in by some plugin builds
    ];

  # ── Boot ────────────────────────────────────────────────────────────
  boot = {
    loader.timeout = 1;
    tmp.cleanOnBoot = true;
    blacklistedKernelModules = [
      "snd_pcsp"
      "pcspkr"
    ];
    supportedFilesystems.zfs = true;
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
      isNormalUser = true;
      uid = 1001; # for audio-off.service
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
    direnv.enable = true;
    ssh.askPassword = "";
    neovim = {
      enable = true;
    };
    gnupg.agent.enable = true;
    television = {
      enable = true;
      enableZshIntegration = true;
    };
    command-not-found.enable = true;
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

  # ── Time sync (rt.nix force-disables chrony: NTP can spike CPU) ─────
  services.chrony.enable = true;
  services.acpid.enable = true;

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
      (lib.lowPrio vim) # extras.nix ships a customized vim-full; let it win the shared paths
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
      (ripgrep.override { withPCRE2 = true; })
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
      nix-check-deps
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
      (lib.hiPrio rust-analyzer) # win over rustup's rust-analyzer proxy shim
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

      # search / files (from laptop)
      ripgrep-all
      silver-searcher
      trash-cli
      inotify-tools
      httm
      w3m
      tiv

      # sysadmin (from laptop)
      parted
      lm_sensors
      acpi
      powertop
      s-tui
      sysz
      systemctl-tui

      # backup (from laptop)
      borgbackup
      restic

      # dev (from laptop)
      deno
      bacon
      just
      cookiecutter
      kondo
      gh

      # nix dev (from laptop)
      nox
      treefmt
      nixpkgs-fmt
      nixpkgs-lint
      devenv
      nix-direnv
      nix-init
      nix-serve

      # media CLI (from laptop)
      yt-dlp
      ffmpeg-full

      # calculators (from laptop)
      bc
      libqalculate

      # misc CLI (from laptop)
      gopass
      weechat
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
    # enableRedistributableFirmware (default true) covers linux-firmware,
    # which has Intel WiFi/GPU blobs and ethernet NIC firmware. Add anything
    # else explicitly per host.
    enableAllFirmware = false;
    cpu = {
      amd.updateMicrocode = true;
      intel.updateMicrocode = true;
    };
  };

  environment.sessionVariables = {
    EDITOR = "hx";
    NIXPKGS = "/home/bart/source/nixpkgs/";
    NIXPKGS_ALL = "/home/bart/source/nixpkgs/pkgs/top-level/all-packages.nix";
    PAGER = "less";
    LESS = "-isMR";
    NIX_PAGER = "bat";
    XDG_DATA_HOME = "$HOME/.local/share";
    TERMINFO_DIRS = "/run/current-system/sw/share/terminfo";
    RANGER_LOAD_DEFAULT_RC = "FALSE";
    FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git";
    FZF_ALT_C_COMMAND = "bfs -color -type d";
    FZF_ALT_C_OPTS = "--preview 'tree -L 4 -d -C --noreport -C {} | head -200'";
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
