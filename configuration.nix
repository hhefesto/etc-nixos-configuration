{ config, pkgs, lib, modulesPath, inputs, ... }:
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # nixpkgs.overlays = [
  #   (final: prev: {
  #      unstable = final.unstable;
  #      # zoom-us = final.unstable.zoom-us;
  #    }
  #   )
  # ];
  # nixpkgs.overlays = [ inputs.unstable.overlay ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "olimpo"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n = {
  #   consoleFont = "Lat2-Terminus16";
  #   consoleKeyMap = "us";
  #   defaultLocale = "en_US.UTF-8";
  # };

  # Set your time zone.
  time.timeZone = "America/Mexico_City";

  # environment.variables = {
  #   TERMINAL = [ "st" ];
  #   OH_MY_ZSH = [ "${pkgs.oh-my-zsh}/share/oh-my-zsh" ];
  # };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  nixpkgs.config.allowUnfree = true;

  environment.interactiveShellInit = ''
    # alias fn='cabal repl' #TODO:Fix
    # alias 'cabal run'='cabal new-run' #TODO:Fix
    # alias 'cabal build'='cabal new-build' #TODO:Fix
    alias cat='bat'
    alias _cat='cat'
    alias crun='cabal new-run'
    alias ct='cabal new-test'
    alias cr='cabal new-repl'
    alias cb='cabal new-build'
    alias tr='cd ~/src/telomare && cabal new-run telomare-mini-repl -- --haskell'
    alias telomare-repl='cd ~/src/telomare && cabal new-run telomare-mini-repl -- --haskell'
    alias gs='git status'
    alias ga='git add -A'
    alias gd='git diff'
    alias gc='git commit -am'
    alias gcs='git commit -am "squash"'
    alias gbs='git branch --sort=-committerdate'
    alias sendmail='/run/current-system/sw/bin/msmtp --debug --from=default --file=/etc/msmtp/laurus -t'
    alias xclip='xclip -selection c'
    alias please='sudo'
    alias n='nix-shell shell.nix'
    # alias nod='nixops deploy -d laurus-nobilis-gce'
    alias sn='sudo nixos-rebuild switch'
    alias gr='grep -R --exclude='TAGS' --exclude-dir={.stack-work,dist-newstyle,result,result-2} -n'
    alias where='pwd'
    alias nd='nix develop'
  '';

  environment.systemPackages = with pkgs; [
    virt-manager
    slack
    teams
    cmatrix
    bat
    jq
    # steam
    zip
    # teams
    rename
    parallel
    pywal
    stylish-haskell
    # python
    direnv
    nix-direnv-flakes
    ripgrep
    sox
    # unstable.zoom-us
    zoom-us
    discord
    spotifywm
    # pgadmin
    # pgmanage
    # unstable.signal-desktop
    signal-desktop
    unetbootin
    any-nix-shell
    texlive.combined.scheme-basic
    rxvt_unicode
    wget
    vim
    emacs
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
    # unstable.firefox
    firefox
    dmenu
    tabbed
    st
    haskellPackages.xmobar
    ranger
    # fish
    obs-studio
    qbittorrent
    libreoffice
    vlc
    dropbox-cli
    gnome3.nautilus
    gnome.gnome-terminal
    calibre
    # nixpkgs-19-03.taffybar
    sshpass
    gimp
    gparted
    octave
    htop
    # stack
    # nixops
    # skypeforlinux
    google-chrome
    # spotify # this loops `nixos-rebuild switch`
    # stack2nix
    # unstable.ghc
    ffmpeg
    xdotool
    # cabal2nix
    # cabal-install
    nix-prefetch-git
    xvkbd
    # system-sendmail
    hunspell
    hunspellDicts.es-any
    hunspellDicts.es-mx
    hunspellDicts.en-us
    aspell
    aspellDicts.en
    aspellDicts.en-computers
    aspellDicts.en-science
    aspellDicts.es
    inkscape
    # haskellPackages.keter
    # nixos.zathura
    unrar
    unzip
    # teamviewer
    hack-font
    cachix
    tree
    gnumake
    # nodejs
    # nodePackages.yarn
    # nixpkgs-19-03.yarn2nix
    # nodePackages.typescript
    # nodePackages.create-react-app
    # for laurus-nobilis
    zlib
    postgresql_11
    haskellPackages.yesod-bin
    msmtp
    gmp
    # zip
    # \for laurus-nobilis
  ];

  environment.pathsToLink = [
    "/share/nix-direnv"
  ];

  # TODO: see about this.
  nixpkgs.config.permittedInsecurePackages = [
    "google-chrome-81.0.4044.138"
    "openssl-1.0.2u"
  ];

  fonts.fonts = with pkgs; [
    hack-font
  ];

  # services.lorri.enable = true;

  systemd.user.services.dropbox = {
    restartIfChanged = true;
    enable = true;
    serviceConfig = {
      ExecStart = "${pkgs.dropbox}/bin/dropbox";
      PassEnvironment = "DISPLAY";
    };
  };

  # TODO: turn off?
  systemd.user.services."urxvtd" = {
    enable = true;
    description = "rxvt unicode daemon";
    wantedBy = [ "default.target" ];
    path = [ pkgs.rxvt_unicode ];
    serviceConfig.Restart = "always";
    serviceConfig.RestartSec = 2;
    serviceConfig.ExecStart = "${pkgs.rxvt_unicode}/bin/urxvtd -q -o";
  };

  # programs.nm-applet.enable = true;

  # for vir-manager: https://nixos.wiki/wiki/Virt-manager
  programs.dconf.enable = true;

  programs.light.enable = true;

  # programs.steam.enable = true;

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    interactiveShellInit = ''
      # z - jump around
      # source ${pkgs.fetchurl {url = "https://github.com/rupa/z/raw/2ebe419ae18316c5597dd5fb84b5d8595ff1dde9/z.sh"; sha256 = "0ywpgk3ksjq7g30bqbhl9znz3jh6jfg8lxnbdbaiipzgsy41vi10";}}
      save_aliases=$(alias -L)
      export ZSH=${pkgs.oh-my-zsh}/share/oh-my-zsh
      export ZSH_THEME="bira" #"lambda"
      plugins=(git sudo colorize extract history postgres)
      source $ZSH/oh-my-zsh.sh
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
  hardware.pulseaudio.enable = true;

  # List services that you want to enable:

  # services.hercules-ci-agent.enable = true;
  # services.hercules-ci-agent.concurrentTasks = 4; # Number of jobs to run
  # services.hercules-ci-agent.patchNix = true;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  services.sshd.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.layout = "us";
  services.xserver.xkbOptions = "ctrl:nocaps";
  services.xserver.xkbVariant = "altgr-intl";
  services.xserver.windowManager.xmonad = {
    enable = true;
    enableContribAndExtras = true;
    extraPackages = haskellPackages:[
      haskellPackages.xmonad-contrib
      haskellPackages.xmonad-extras
      haskellPackages.xmonad
    ];
  };
  services.xserver.displayManager = {
    defaultSession = "none+xmonad";
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
      package = pkgs.postgresql_11;
      enableTCPIP = true;
      authentication = pkgs.lib.mkOverride 10 ''
        local all all trust
        host all all ::1/128 trust
      '';
      initialScript = pkgs.writeText "backend-initScript" ''
        CREATE ROLE analyzer WITH LOGIN PASSWORD 'anapass';
        CREATE DATABASE aanalyzer_yesod;
        GRANT ALL PRIVILEGES ON DATABASE aanalyzer_yesod TO analyzer;
      '';
    };

  # for virt-manager: https://nixos.wiki/wiki/Virt-manager
  virtualisation.libvirtd.enable = true;

  virtualisation.docker.enable = true;
  virtualisation.virtualbox.host.enable = true;

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
    shell = pkgs.zsh; #"/run/current-system/sw/bin/bash";
  };

  # texlive.combine {
  #   inherit (texlive) scheme-small algorithms cm-super;
  # };

  # For nix flakes
  nix.package = pkgs.nixFlakes;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
    keep-outputs = true
    keep-derivations = true
  '';

  nix.settings.trusted-public-keys = [ "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
                                       # "telomare.cachix.org-1:H0qRjVstxtb9oyEPvDDpmPSLyJ9oViAsTgwR02ra6Dk="
                                     ];

  nix.settings.substituters = [ "https://cache.iog.io"
                                # "https://telomare.cachix.org"
                              ];

  nix.settings.allowed-users = [ "@wheel" "hhefesto" ];
  # nix.allowedUsers =  [ "@wheel" "hhefesto" ];

  nix.settings.trusted-users = [ "root" "hhefesto" ];
  # nix.trustedUsers = [ "root" "hhefesto" ];

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  # system.stateVersion = "20.09"; # Did you read the comment?

  # Let 'nixos-version --json' know about the Git revision
  # of this flake.
  system.configurationRevision = inputs.nixpkgs.lib.mkIf (inputs.self ? rev) inputs.self.rev;
}
