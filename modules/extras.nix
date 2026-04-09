{
  pkgs,
  lib,
  config,
  ...
}:

# Packages and configs that were in the original repo but removed during
# the modularization cleanup.  Import this module (or cherry-pick sections)
# to restore them.

{

  # ── Nix extras ─────────────────────────────────────────────────────
  nix.settings = {
    extra-sandbox-paths = [ "/home/nixchroot" ];
    require-sigs = true;
  };
  nix.extraOptions = lib.optionalString (config.nix.package == pkgs.nixVersions.stable) ''
    gc-keep-outputs         = true
    gc-keep-derivations     = true
    env-keep-derivations    = false
    stalled-download-timeout = 600
  '';

  # ── Walker dependency ──────────────────────────────────────────────
  # services.elephant.enable = true;

  # ── Packages ───────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [

    # ── debugging / profiling ─────────────────────────────────────
    gdb
    rr
    ncurses
    ltrace
    stress
    hyperfine

    # ── system / hardware ─────────────────────────────────────────
    usbutils
    pciutils
    lsof
    psmisc
    linuxPackages.cpupower
    hdparm
    testdisk
    mesa-demos
    libva-utils
    unetbootin

    # ── network tools ─────────────────────────────────────────────
    mosh
    sshfs-fuse
    iftop
    nethogs
    trippy
    inetutils
    speedtest-cli

    # ── version control extras ────────────────────────────────────
    mercurial
    subversion
    hub
    diff-so-fancy
    diffoscope
    gitui
    gist
    bfg-repo-cleaner

    # ── file tools / search ───────────────────────────────────────
    bfs
    broot
    nnn
    fasd
    grex
    rdfind
    fselect
    jdupes
    which

    # ── ranger / yazi preview dependencies ────────────────────────
    atool
    highlight
    file
    libcaca
    odt2txt
    perlPackages.ImageExifTool
    ffmpegthumbnailer
    poppler-utils
    lynx
    mediainfo
    fontforge
    libsixel
    chafa
    resvg
    _7zz
    ffmpeg
    imagemagick

    # ── terminals / shells ────────────────────────────────────────
    rxvt-unicode-unwrapped
    zsh
    nix-zsh-completions

    # ── editors / writing ─────────────────────────────────────────
    geany
    (vim-full.customize {
      vimrcConfig.packages.myVimPackage = with pkgs.vimPlugins; {
        start = [
          "vim-sensible"
          "vim-sleuth"
        ];
      };
      vimrcConfig.customRC = ''
        set clipboard=unnamedplus
        set number relativenumber
        syntax on
      '';
    })
    texlive.combined.scheme-medium
    wordnet
    wkhtmltopdf
    haskellPackages.markdown
    gnuplot
    languagetool

    # ── info / TUI ────────────────────────────────────────────────
    asciinema
    fastfetch
    tuir
    wiki-tui
    navi
    so
    ts

    # ── monitoring extras ─────────────────────────────────────────
    iotop
    sysstat
    dysk

    # ── crypto / security ─────────────────────────────────────────
    libressl
    cryptsetup
    ntfs3g
    paperkey
    gpa

    # ── runtime / lang support ────────────────────────────────────
    openjdk
    ruby
    rusty-man
    expect

    # ── packaging helpers ─────────────────────────────────────────
    makeWrapper
    patchelf
    steam-run
    sessreg
    heimdall

    # ── desktop apps ──────────────────────────────────────────────
    i3status # (you have i3status-rust; this is the simpler one)
    rofi-systemd
    iwmenu
    dzen2
    xpra
    xcalib
    sselp
    xinit
    xfontsel
    uutils-coreutils-noprefix

    # ── browsers / web ────────────────────────────────────────────
    i2pd
    # python3Packages.pyperclip # for qutebrowser code-hint
    sqlitebrowser

    # ── media ─────────────────────────────────────────────────────
    yewtube
    shotwell
    kodi
    radiance-vj
    kdePackages.kdenlive
    diff-pdf

    # ── communication ─────────────────────────────────────────────
    gajim
    irssi

    # ── office / productivity ─────────────────────────────────────
    freemind
    gtypist
    kdePackages.kcolorchooser
    filezilla
    openscad

    # ── calculators / converters ──────────────────────────────────
    calc
    units
    rink

    # ── spelling extras ───────────────────────────────────────────
    aspellDicts.en-computers
    aspellDicts.en-science
    hunspellDicts.en_US-large
    hunspellDicts.nl_NL
    hunspellDicts.de_DE

    # ── iOS device support ────────────────────────────────────────
    usbmuxd
    libimobiledevice
    ifuse

    # ── xdg / mime ────────────────────────────────────────────────
    xdg-utils
    shared-mime-info
    perlPackages.MIMETypes

    # ── contacts / calendar sync ──────────────────────────────────
    khard
    vdirsyncer

    # ── backup extras ─────────────────────────────────────────────
    storeBackup
    hostsblock

    # ── busybox (usleep only, for brightness scripts) ─────────────
    (busybox.overrideAttrs (old: {
      postFixup = ''
        mkdir -p /tmp/bb-trim
        cp $out/bin/usleep /tmp/bb-trim
        cp $out/bin/busybox /tmp/bb-trim
        rm $out/bin/*
        cp /tmp/bb-trim/usleep $out/bin/
        cp /tmp/bb-trim/busybox $out/bin/
      '';
    }))
  ];

  # ── ZSH NixOS management functions ─────────────────────────────────
  # These were in repo common.nix programs.zsh.interactiveShellInit.
  # Aliases like `up`, `te`, `sw` for nixos-rebuild, generation
  # management (lg, nga, ngd, dgs, dgr), etc.
  # If you want them back, uncomment the block below.
  #
  # programs.zsh.interactiveShellInit = ''
  #   alias  up='unbuffer nixos-rebuild test --upgrade  |& nom '
  #   alias no=nixos-option
  #   alias  te='unbuffer nixos-rebuild build   -p rt ...'
  #   alias  sw='unbuffer nixos-rebuild boot -p rt ...'
  #   alias man=batman
  #   # ... (see repo common.nix for the full block)
  # '';
}
