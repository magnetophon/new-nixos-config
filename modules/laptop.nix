{
  pkgs,
  lib,
  config,
  nixpkgs-glide,
  ...
}:

{
  imports = [
    ./music.nix
    ./extras.nix
  ];

  # ── Boot extras for laptop ─────────────────────────────────────────
  boot = {
    blacklistedKernelModules = [ "uvcvideo" ]; # no webcam
  };

  # ── X11 / i3 ───────────────────────────────────────────────────────
  services.xserver = {
    enable = true;
    displayManager.lightdm.enable = true;

    # config = ''
    # Section "InputClass"
    # Identifier     "Enable libinput for TrackPoint"
    # MatchIsPointer "on"
    # Driver         "libinput"
    # EndSection
    # '';

    desktopManager.xterm.enable = false;
    desktopManager.wallpaper.mode = "fill";
    enableCtrlAltBackspace = true;
    xkb = {
      options = "caps:swapescape,terminate:ctrl_alt_bksp";
      layout = "us";
      variant = "altgr-intl";
    };
  };

  services.libinput = {
    enable = true;
    touchpad = {
      middleEmulation = false;
      accelSpeed = "0.1";
      tappingButtonMap = "lrm";
    };
  };

  services.unclutter-xfixes = {
    enable = true;
    threshold = 2;
    extraOptions = [ "ignore-scrolling" ];
  };

  # ── Laptop services ────────────────────────────────────────────────
  services = {
    upower.enable = true;
    ringboard.x11.enable = true;

    printing = {
      enable = true;
      drivers = [ pkgs.brlaser ];
    };

    physlock = {
      enable = true;
      allowAnyUser = true;
      muteKernelMessages = true;
      lockOn = {
        suspend = true;
        hibernate = true;
      };
    };

    logind.settings.Login = {
      HandleLidSwitch = "suspend-then-hibernate";
      HandleLidSwitchExternalPower = "suspend-then-hibernate";
      HandleLidSwitchDocked = "ignore";
      HandlePowerKey = "suspend-then-hibernate";
      HandlePowerKeyLongPress = "poweroff";
    };

    gnome.gnome-keyring.enable = true;

    udev.extraRules = ''
      ENV{ID_FS_USAGE}=="filesystem|other|crypto", ENV{UDISKS_FILESYSTEM_SHARED}="1"
    '';
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "*";
  };

  # ── Hibernate delay ────────────────────────────────────────────────
  systemd.sleep.settings.Sleep = {
    HibernateDelaySec = "30m";
    SuspendState = "mem";
  };

  # ── Brightness save/restore across suspend ──────────────────────────
  systemd.services.brightness-save = {
    description = "Save brightness before suspend";
    wantedBy = [ "sleep.target" ];
    before = [ "sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.brightnessctl}/bin/brightnessctl --save";
    };
  };

  systemd.services.brightness-restore = {
    description = "Restore brightness after resume";
    wantedBy = [
      "suspend.target"
      "hibernate.target"
    ];
    after = [
      "suspend.target"
      "hibernate.target"
    ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.brightnessctl}/bin/brightnessctl --restore";
    };
  };

  # ── Systemd user services ──────────────────────────────────────────
  systemd.user.services.autocutsel = {
    enable = true;
    description = "AutoCutSel clipboard manager daemon";
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "forking";
      Restart = "always";
      RestartSec = 2;
      ExecStartPre = "${pkgs.autocutsel}/bin/autocutsel -fork";
      ExecStart = "${pkgs.autocutsel}/bin/autocutsel -selection PRIMARY -fork";
    };
  };

  systemd.user.services.dunst = {
    unitConfig = {
      Description = "dunst notification daemon";
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    serviceConfig = {
      ExecStart = "${pkgs.dunst}/bin/dunst";
      Restart = "always";
    };
    wantedBy = [ "graphical-session.target" ];
  };

  systemd.services.audio-off = {
    description = "Mute audio before suspend";
    wantedBy = [ "sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      Environment = "XDG_RUNTIME_DIR=/run/user/1001";
      User = "bart";
      RemainAfterExit = "yes";
      ExecStart = "${pkgs.alsa-utils}/bin/amixer -q -c 0 set Master mute";
    };
  };

  # ── Extra user groups for laptop ───────────────────────────────────
  users.users.bart.extraGroups = [
    "audio"
    "jackaudio"
    "video"
    "usbmux"
    "networkmanager"
    "adbusers"
    "camera"
  ];

  # ── GUI packages ───────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # window manager
    i3
    i3status-rust
    i3-layout-manager
    i3-resurrect
    i3altlayout
    autotiling-rs
    wmfocus
    dmenu
    rofi
    rofi-pass
    rofimoji
    walker

    # terminal emulators
    alacritty-graphics
    kitty
    wezterm

    # browsers
    firefox
    qutebrowser
    ungoogled-chromium
    tor-browser
    # nixpkgs-glide.legacyPackages.${pkgs.stdenv.hostPlatform.system}.glide-browser

    # desktop utilities
    clipster
    picom
    dunst
    libnotify
    autocutsel
    brightnessctl
    arandr
    xrandr-invert-colors
    xclip
    xdotool
    xprop
    xev
    xwininfo
    xkill
    scrot
    flameshot
    feh
    pqiv
    emulsion
    physlock
    networkmanager_dmenu
    connman_dmenu
    impala

    # file manager GUI
    thunar

    # media
    vlc
    (mpv-unwrapped.override {
      jackaudioSupport = true;
      archiveSupport = true;
      vapoursynthSupport = true;
    })

    # communication
    thunderbird
    signal-desktop
    telegram-desktop
    hexchat

    # office / documents
    libreoffice
    zathura
    evince
    xournalpp

    # graphics
    gimp
    inkscape
    blender

    # calculators
    qalculate-gtk

    # password / auth
    authenticator
    gnome-keyring
    libsecret

    # system tools
    gparted
    baobab
    udiskie
    acpid

    # syncing / backup
    nextcloud-client
    syncthing

    # misc
    meld
    transmission_4-gtk
    obs-studio
    simplescreenrecorder
    recoll
    bluetui
    mepo
    alsa-utils
  ];

  # ── Session variables ──────────────────────────────────────────────
  environment.sessionVariables = {
    BROWSER = "qutebrowser";
    TERMCMD = "alacritty";
  };

  # ── Fonts ──────────────────────────────────────────────────────────
  fonts = {
    fontDir.enable = true;
    fontconfig = {
      # accept bitmap (non-scalable) fonts.
      localConf = ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
        <fontconfig>
        <selectfont><acceptfont>
        <pattern><patelt name="scalable"><bool>false</bool></patelt></pattern>
        </acceptfont></selectfont>
        </fontconfig>
      '';
      defaultFonts = {
        emoji = [ "Noto Color Emoji" ];
        monospace = [ "IBM Plex Mono" ];
        sansSerif = [ "IBM Plex Sans" ];
        serif = [ "IBM Plex Serif" ];
      };
      useEmbeddedBitmaps = true;
    };
    packages = with pkgs; [
      terminus_font
      siji
      terminus_font_ttf
      ibm-plex
      font-awesome_4
      nerd-fonts.droid-sans-mono
      nerd-fonts.terminess-ttf
      nerd-fonts.liberation
      nerd-fonts.noto
      nerd-fonts.fira-code
      nerd-fonts.symbols-only
      corefonts
    ];
  };

  # ── Chromium policy ────────────────────────────────────────────────
  programs = {
    seahorse.enable = true;
    chromium = {
      enable = true;
      defaultSearchProviderSearchURL = "https://duckduckgo.com/?q={searchTerms}";
      extensions = [
        "pkehgijcmpdhfbdbbnkijodmdjhbjlgp" # privacy badger
        "cjpalhdlnbpafiamejdnhcphjbkeiagm" # ublock origin
        "ldpochfccmkkmhdbclfhpagapcfdljkj" # Decentraleyes
        "poahndpaaanbpbeafbkploiobpiiieko" # Display anchors
      ];
      extraOpts = {
        DefaultSearchProviderEnabled = true;
        DefaultSearchProviderName = "DuckDuckGo";
        PasswordManagerEnabled = false;
        BrowserSignin = 0;
        AudioCaptureAllowed = false;
        RestoreOnStartup = 5;
        NetworkPredictionOptions = 2;
        SafeBrowsingEnabled = true;
        SafeBrowsingExtendedReportingEnabled = false;
        SearchSuggestEnabled = false;
      };
    };
    dconf.enable = true;
  };

  xdg.sounds.enable = false;

}
