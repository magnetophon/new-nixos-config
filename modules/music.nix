{
  pkgs,
  lib,
  config,
  ...
}:

let
  pd_plugins = with pkgs; [
    helmholtz
    timbreid
    maxlib
    zexy
    puremapping
    cyclone
    # mrpeach // unmaintained
  ];
  fullPD = pkgs.puredata-with-plugins pd_plugins;
in
{

  # ── Overrides ──────────────────────────────────────────────────────
  nixpkgs.config.packageOverrides = pkgs: {
    guitarix = pkgs.guitarix.override { enableOptimization = true; };
  };

  # ── Audio plugin paths ─────────────────────────────────────────────
  # environment.variables = {
  # DSSI_PATH = "$HOME/.dssi:$HOME/.nix-profile/lib/dssi:/run/current-system/sw/lib/dssi";
  # LADSPA_PATH = "$HOME/.ladspa:$HOME/.nix-profile/lib/ladspa:/run/current-system/sw/lib/ladspa";
  # LV2_PATH = "$HOME/.lv2:$HOME/.nix-profile/lib/lv2:/run/current-system/sw/lib/lv2";
  # LXVST_PATH = "$HOME/.lxvst:$HOME/.nix-profile/lib/lxvst:/run/current-system/sw/lib/lxvst";
  # VST_PATH = "$HOME/.vst:$HOME/.nix-profile/lib/vst:/run/current-system/sw/lib/vst";
  # };

  environment.systemPackages = with pkgs; [
    # ── Plugins ────────────────────────────────────────────────────
    airwin2rack
    airwindows
    airwindows-lv2
    AMB-plugins
    fil-plugins
    adlplug
    aeolus
    aether-lv2
    artyFX
    x42-avldrums
    bchoppr
    bespokesynth
    bjumblr
    bristol
    bsequencer
    bshapr
    bslizr
    bschaffl
    bolliedelayxt-lv2
    calf
    caps
    cardinal
    chow-kick
    chow-phaser
    chow-tape-model
    chow-centaur
    csa
    cmt
    dexed
    diopser
    distrho-ports
    dragonfly-reverb
    drumgizmo
    drumkv1
    ensemble-chorus
    eq10q
    fire

    open-music-kontrollers.eteroj
    open-music-kontrollers.jit
    open-music-kontrollers.mephisto
    open-music-kontrollers.midi_matrix
    open-music-kontrollers.moony
    open-music-kontrollers.orbit
    open-music-kontrollers.patchmatrix
    open-music-kontrollers.router
    open-music-kontrollers.sherlock
    open-music-kontrollers.synthpod
    open-music-kontrollers.vm

    fluidsynth
    fomp
    freqtweak
    fverb
    geonkick
    ripplerx
    melmatcheq-lv2
    gxmatcheq-lv2
    gxplugins-lv2
    helm
    hybridreverb2
    hydrogen
    industrializer
    infamousPlugins
    ir.lv2
    jaaa
    jack_oscrolloscope
    jackmeter
    jack-example-tools
    japa
    ladspa-header
    ladspaPlugins
    lsp-plugins
    librearp
    librearp-lv2
    mda_lv2
    molot-lite
    ctagdrc
    mod-arpeggiator-lv2
    ninjas2
    noise-repellent
    nova-filters
    odin2
    oxefmsynth
    padthv1
    quadrafuzz
    plugin-torture
    pluginval
    proteus
    qsampler
    qsynth
    rkrlv2
    samplv1
    setbfree
    sfizz
    sg-323
    sorcer
    spectmorph
    speech-denoiser
    stochas
    stone-phaser
    master_me
    qdelay
    string-machine
    swh_lv2
    synthv1
    # surge
    surge-xt
    vaporizer2
    tamgamp.lv2
    tetraproc
    uhhyou-plugins
    uhhyou-plugins-juce
    vocproc
    wolf-shaper
    x42-plugins
    yoshimi
    zam-plugins
    zlcompressor
    zlequalizer
    zlsplitter
    zynaddsubfx

    # ── Faust ──────────────────────────────────────────────────────
    magnetophonDSP.MBdistortion
    magnetophonDSP.CharacterCompressor
    magnetophonDSP.ConstantDetuneChorus
    magnetophonDSP.LazyLimiter
    magnetophonDSP.RhythmDelay
    magnetophonDSP.VoiceOfFaust
    magnetophonDSP.faustCompressors
    magnetophonDSP.pluginUtils
    magnetophonDSP.shelfMultiBand
    tambura
    faust
    faust2alqt
    faust2alsa
    faust2firefox
    faust2jack
    faust2jackrust
    faust2jaqt
    faust2lv2
    faust2sndfile
    faustlive
    faustfmt
    faustlsp
    kapitonov-plugins-pack
    mooSpace

    # ── Hosts / DAWs ──────────────────────────────────────────────
    ardour
    ardour_8
    xjadeo
    helio-workstation
    carla
    audacity
    jalv
    mod-distortion
    # petrifoo
    guitarix
    zrythm
    bitwig-studio
    reaper

    # ── Utilities ──────────────────────────────────────────────────
    a2jmidid
    cuetools
    jack2
    jack-link
    lilv
    lv2bm
    mamba
    qjackctl
    # sonic-lineup
    vmpk
    qmidinet

    # ── Analyzers ─────────────────────────────────────────────────
    # squishyball
    shntool

    # ── Converters ────────────────────────────────────────────────
    flac
    lame
    sox

    # ── Various ───────────────────────────────────────────────────
    polyphone
    dfasma
    freewheeling
    MMA
    mixxx
    fullPD
    real_time_config_quick_scan
    (pkgs.fmit.override { jackSupport = true; })
    sooperlooper
    vimpc
    x32edit

    # ── Development ───────────────────────────────────────────────
    octave
    graphviz
    leiningen
    ladspa-sdk
  ];

}
