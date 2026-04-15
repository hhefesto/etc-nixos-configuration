{ pkgs, lib, xmonadShortenLength ? 50, ... }:
{
  networking.networkmanager.enable = true;

  environment.systemPackages = with pkgs; [
    localsend
    insomnia
    brightnessctl
    alsa-utils
    kvmtool
    kdePackages.kdenlive
    brave
    virt-manager
    slack
    pywal
    sox
    zoom-us
    discord-ptb
    signal-desktop
    unetbootin
    scrot
    libnotify
    dunst
    xclip
    feh
    firefox
    dmenu
    tabbed
    st
    haskellPackages.xmobar
    obs-studio
    qbittorrent
    libreoffice
    vlc
    dropbox-cli
    nautilus
    gnome-terminal
    calibre
    sshpass
    gimp
    gparted
    google-chrome
    ffmpeg
    xdotool
    xvkbd
    inkscape
  ];

  fonts.packages = with pkgs; [
    source-code-pro
    noto-fonts-cjk-sans
    ipafont
    kochi-substitute
    font-awesome
    hack-font
  ] ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);

  fonts.fontconfig.enable = true;
  fonts.enableDefaultPackages = true;

  i18n.supportedLocales = [
    "en_US.UTF-8/UTF-8"
    "ja_JP.UTF-8/UTF-8"
  ];

  xdg.mime.defaultApplications = {
    "text/html" = "brave-browser.desktop";
    "x-scheme-handler/http" = "brave-browser.desktop";
    "x-scheme-handler/https" = "brave-browser.desktop";
    "x-scheme-handler/about" = "brave-browser.desktop";
    "x-scheme-handler/unknown" = "brave-browser.desktop";
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  programs.dconf.enable = true;
  programs.light.enable = true;

  hardware.bluetooth.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };
  services.blueman.enable = true;

  services.xserver.enable = true;
  services.xserver.xkb.layout = "us";
  services.xserver.xkb.options = "ctrl:nocaps";
  services.xserver.xkb.variant = "altgr-intl";
  services.xserver.windowManager.xmonad = {
    enable = true;
    enableConfiguredRecompile = true;
    config = builtins.replaceStrings [ "@xmonadShortenLength@" ] [ "${toString xmonadShortenLength}" ] (pkgs.lib.readFile ./xmonad.hs);
    enableContribAndExtras = true;
    extraPackages = haskellPackages: [
      haskellPackages.xmonad-contrib
      haskellPackages.xmonad-extras
      haskellPackages.xmonad
    ];
  };

  services.displayManager.defaultSession = "none+xmonad";
  services.displayManager.gdm.enable = true;
  services.xserver.displayManager.sessionCommands =
    let
      myCustomLayout = pkgs.writeText "xkb-layout" ''
        remove Lock = Caps_Lock
        remove Control = Control_R
        keysym Control_R = Caps_Lock
        keysym Caps_Lock = Control_R
        add Lock = Caps_Lock
        add Control = Control_R
      '';
    in ''
      ${pkgs.xorg.xmodmap}/bin/xmodmap ${myCustomLayout}
      ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd --all
      exec >>"$HOME/.xsession.log" 2>&1
      echo "[XSESSION] Started at $(date)"
    '';

  services.desktopManager.gnome.enable = true;

  location.provider = "manual";
  location.latitude = 20.59;
  location.longitude = -100.39;

  virtualisation.libvirtd.enable = true;

  networking.firewall.allowedTCPPorts = [ 3000 5432 587 5938 53317 ];
  networking.firewall.allowedUDPPorts = [ 5938 53317 ];

  users.users.hhefesto.extraGroups = lib.mkAfter [ "video" "networkmanager" "libvirtd" "kvm" ];
}
