{ config, pkgs, lib, modulesPath, inputs, myAgda, ... }:
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  networking.hostName = "olimpo"; # Define your hostname.
  networking.enableIPv6 = false;

  time.timeZone = "America/Mexico_City";

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    alsa-utils
    kvmtool
    kdenlive
    myAgda
    brave
    sd
    fd
    virt-manager
    slack
    cmatrix
    bat
    jq
    zip
    rename
    parallel
    pywal
    direnv
    nix-direnv-flakes
    ripgrep
    sox
    zoom-us
    discord-ptb
    signal-desktop
    unetbootin
    any-nix-shell
    wget
    vim
    emacs
    emacs-all-the-icons-fonts
    tmux
    curl
    gist
    git
    lambda-mod-zsh-theme
    oh-my-zsh
    zsh
    scrot
    xclip
    feh
    firefox
    dmenu
    tabbed
    st
    haskellPackages.xmobar
    ranger
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
    htop
    google-chrome
    ffmpeg
    xdotool
    nix-prefetch-git
    xvkbd
    hunspell
    hunspellDicts.es-any
    hunspellDicts.es-mx
    hunspellDicts.en-us
    (aspellWithDicts (dicts: with dicts; [ es en en-computers en-science ]))
    inkscape
    unrar
    unzip
    hack-font
    cachix
    tree
    gnumake
    zlib
    msmtp
    gmp
  ];

  environment.pathsToLink = [
    "/share/nix-direnv"
    "/share/zsh"
  ];

  fonts.packages = with pkgs; [
    hack-font
  ];

  systemd.extraConfig = ''
    DefaultTimeoutStartSec=20m
    DefaultTimeoutStopSec=20m
    DefaultTimeoutAbortSec=20m
  '';
  systemd.user.services.home-manager-hhefesto = {
    serviceConfig = {
      TimeoutStartSec = "20m";
      TimeoutStopSec = "20m";
      Nice = 19;
      IOSchedulingClass = "idle";
      IOSchedulingPriority = 7;
    };
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
  };

  # for vir-manager: https://nixos.wiki/wiki/Virt-manager
  programs.dconf.enable = true;

  programs.light.enable = true;

  # programs.steam.enable = true;
  programs.nix-index.enableZshIntegration = true;
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    ohMyZsh.enable = true;
    ohMyZsh.plugins = ["git" "sudo" "colorize" "extract" "history" "postgres"];
    ohMyZsh.theme = "intheloop";

    # shellInit = ''
    #   # ssh
    #   # export SSH_KEY_PATH="~/.ssh/dsa_id"
    #   export SSH_AUTH_SOCK=~/.ssh/ssh-agent.$HOSTNAME.sock

    #   # Verify if ssh-agent is running
    #   ssh-add -l 2>/dev/null >/dev/null

    #   # if it was running, ssh-add will use it and return 1 (no keys)
    #   # if it was not running, it will return 2, so we proceed to execute the ssh-agent
    #   # and tell it where to create the Unix  socket (SSH_AUTH_SOCK):

    #   if [ $? -ge 2 ]; then
    #      ssh-agent -a "$SSH_AUTH_SOCK" >/dev/null
    #   fi

    #   ssh-add ~/.ssh/xpsoasis-ed25519
    # '';

    interactiveShellInit = ''
      save_aliases=$(alias -L)
      eval $save_aliases; unset save_aliases
    '';
    promptInit = ''
      any-nix-shell zsh --info-right | source /dev/stdin
    '';
  };

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 3000 5432 587 5938 ];
  networking.firewall.allowedUDPPorts = [ 5938 ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # sound.enable = true;
  services.pulseaudio = {
      # enable = true;
      enable = false;
      # package = pkgs.pulseaudioFull;
      # support32Bit = true;
      # extraModules = [ pkgs.pulseaudio-modules-bt ];
  };

  hardware.bluetooth.enable = true;

  # security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # hardware.pulseaudio.enable = true;

  # List services that you want to enable:

  # services.hercules-ci-agent.enable = true;
  # services.hercules-ci-agent.concurrentTasks = 4; # Number of jobs to run
  # services.hercules-ci-agent.patchNix = true;

  services.blueman.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  services.sshd.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.xkb.layout = "us";
  services.xserver.xkb.options = "ctrl:nocaps";
  services.xserver.xkb.variant = "altgr-intl";
  services.xserver.windowManager.xmonad = {
    enable = true;
    config = pkgs.lib.readFile ./xmonad.hs;
    enableContribAndExtras = true;
    extraPackages = haskellPackages:[
      haskellPackages.xmonad-contrib
      haskellPackages.xmonad-extras
      haskellPackages.xmonad
    ];
  };
  services.displayManager.defaultSession = "none+xmonad";
  services.xserver.displayManager = {
    # defaultSession = "none+xmonad";
    gdm.enable = true;
    sessionCommands = let myCustomLayout = pkgs.writeText "xkb-layout" ''
                        ! swap Caps_Lock and Control_R
                        remove Lock = Caps_Lock
                        remove Control = Control_R
                        keysym Control_R = Caps_Lock
                        keysym Caps_Lock = Control_R
                        add Lock = Caps_Lock
                        add Control = Control_R
                      '';
                      in "${pkgs.xorg.xmodmap}/bin/xmodmap ${myCustomLayout}";
    # autoLogin.user = "hhefesto";
  };
  services.xserver.desktopManager.gnome.enable = true;

  services.postgresql = {
      enable = true;
      package = pkgs.postgresql;
      enableTCPIP = true;
      # ensureUsers."analyzer".ensureDBOwnership = true;
      authentication = pkgs.lib.mkOverride 10 ''
        #type database DBuser origin-address auth-method
        local all      all                    trust
        # ipv4
        host  all      all     127.0.0.1/32   trust
        # ipv6
        host all       all     ::1/128        trust
      '';
      initialScript = pkgs.writeText "backend-initScript" ''
        CREATE ROLE analyzer WITH LOGIN PASSWORD 'anapass';
        CREATE DATABASE aanalyzer_yesod;
        GRANT ALL PRIVILEGES ON DATABASE aanalyzer_yesod TO analyzer;
        GRANT ALL ON SCHEMA public TO analyzer;
      '';
    };

  location.provider = "manual";
  location.latitude = 20.59;
  location.longitude = -100.39;
  services.redshift = {
    enable = true;
    brightness = {
      # Note the string values below.
      day = "1";
      night = "0.4";
    };
    temperature = {
      day = 5500;
      night = 3700;
    };
  };


  # for virt-manager: https://nixos.wiki/wiki/Virt-manager
  virtualisation.libvirtd.enable = true;

  virtualisation.docker.enable = true;
  # virtualisation.virtualbox.host.enable = true;

  # Enable touchpad support.
  # services.xserver.libinput.enable = true;

  # Enable the KDE Desktop Environment.
  # services.xserver.displayManager.sddm.enable = true;
  # services.xserver.desktopManager.plasma5.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # users.users.jane = {
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  # };

  # $6$JuZni5Aqesp.z5yj$KUO2eAgrma2FXDWWIBqGfOSLf65twcIj4SHFiv7MIGRcaHQxx1nZ.vXmyE5MKq0WS7OwyfdEr8D0URhDt161A/
  # $6$JuZni5Aqesp.z5yj$KUO2eAgrma2FXDWWIBqGfOSLf65twcIj4SHFiv7MIGRcaHQxx1nZ.vXmyE5MKq0WS7OwyfdEr8D0URhDt161A/

  users.mutableUsers = false;

  # Password generated with ```mkpasswd -m sha-512```
  users.users.root.initialHashedPassword = "$6$/RvS0Se.iCx$A0eA/8PzgMj.Ms9ohNamfu53c9S.zdG30hEmUHLjmWP0CaXTPVA6QxGIZ6fy.abkjSOTJMAq7fFL6LUBGs4BU0";
  users.users.hhefesto.initialHashedPassword = "$6$/RvS0Se.iCx$A0eA/8PzgMj.Ms9ohNamfu53c9S.zdG30hEmUHLjmWP0CaXTPVA6QxGIZ6fy.abkjSOTJMAq7fFL6LUBGs4BU0"; # this may be redundant
  # users.defaultUserShell = pkgs.zsh;
  users.extraUsers.hhefesto = {
    createHome = true;
    isNormalUser = true;
    home = "/home/hhefesto";
    description = "Daniel Herrera";
    extraGroups = [ "video" "wheel" "networkmanager" "docker" "libvirtd" ];
    hashedPassword = "$6$/RvS0Se.iCx$A0eA/8PzgMj.Ms9ohNamfu53c9S.zdG30hEmUHLjmWP0CaXTPVA6QxGIZ6fy.abkjSOTJMAq7fFL6LUBGs4BU0";
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJcDIsto/6GS7XwTl+uVo4ABeRlRjDwAU0HHy8irqLaB hhefesto@olimpo" ];
    shell = pkgs.zsh; #"/run/current-system/sw/bin/bash";
  };

  nix.settings.auto-optimise-store = true;
  nix.settings.allow-import-from-derivation = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # For nix flakes
  nix.package = inputs.nix.packages.x86_64-linux.default;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
    keep-outputs = true
    keep-derivations = true
    accept-flake-config = true
    allow-import-from-derivation = true
  '';

  nix.settings.trusted-public-keys = [ "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
                                       "telomare.cachix.org-1:H0qRjVstxtb9oyEPvDDpmPSLyJ9oViAsTgwR02ra6Dk="
                                       "ryantrinkle.com-1:JJiAKaRv9mWgpVAz8dwewnZe0AzzEAzPkagE9SP5NWI="
                                     ];

  nix.settings.trusted-substituters = [ "https://nixcache.reflex-frp.org"
                                        "https://cache.iog.io"
                                        "https://telomare.cachix.org"
                                      ];

  nix.settings.substituters = [ "https://telomare.cachix.org"
                                "https://nixcache.reflex-frp.org"
                              ];

  nix.settings.allowed-users = [ "@wheel" "hhefesto" ];

  nix.settings.trusted-users = [ "root" "hhefesto" ];

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "23.11"; # Did you read the comment?

  # Let 'nixos-version --json' know about the Git revision
  # of this flake.
  # system.configurationRevision = inputs.nixpkgs.lib.mkIf (inputs.self ? rev) inputs.self.rev;
}
